import 'dart:async';

import 'package:async/async.dart';
import 'package:dio/dio.dart';
import 'package:dio_brotli_transformer/dio_brotli_transformer.dart';
import 'package:dio_firebase_performance/dio_firebase_performance.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:flutter/foundation.dart' show kDebugMode, required;
import 'package:logging/logging.dart';
import 'package:nephrogo/authentication/authentication_provider.dart';
import 'package:nephrogo_api_client/api.dart';
import 'package:nephrogo_api_client/api/general_recommendations_api.dart';
import 'package:nephrogo_api_client/api/health_status_api.dart';
import 'package:nephrogo_api_client/api/nutrition_api.dart';
import 'package:nephrogo_api_client/api/peritoneal_dialysis_api.dart';
import 'package:nephrogo_api_client/api/user_api.dart';
import 'package:nephrogo_api_client/model/automatic_peritoneal_dialysis.dart';
import 'package:nephrogo_api_client/model/automatic_peritoneal_dialysis_request.dart';
import 'package:nephrogo_api_client/model/automatic_peritoneal_dialysis_screen_response.dart';
import 'package:nephrogo_api_client/model/blood_pressure.dart';
import 'package:nephrogo_api_client/model/blood_pressure_request.dart';
import 'package:nephrogo_api_client/model/daily_health_status.dart';
import 'package:nephrogo_api_client/model/daily_health_status_request.dart';
import 'package:nephrogo_api_client/model/daily_intakes_report_response.dart';
import 'package:nephrogo_api_client/model/daily_intakes_reports_response.dart';
import 'package:nephrogo_api_client/model/general_recommendations_response.dart';
import 'package:nephrogo_api_client/model/health_status_screen_response.dart';
import 'package:nephrogo_api_client/model/health_status_weekly_screen_response.dart';
import 'package:nephrogo_api_client/model/intake.dart';
import 'package:nephrogo_api_client/model/intake_request.dart';
import 'package:nephrogo_api_client/model/manual_peritoneal_dialysis.dart';
import 'package:nephrogo_api_client/model/manual_peritoneal_dialysis_request.dart';
import 'package:nephrogo_api_client/model/manual_peritoneal_dialysis_screen_response.dart';
import 'package:nephrogo_api_client/model/meal_type_enum.dart';
import 'package:nephrogo_api_client/model/nutrient_weekly_screen_response.dart';
import 'package:nephrogo_api_client/model/nutrition_screen_v2_response.dart';
import 'package:nephrogo_api_client/model/product_search_response.dart';
import 'package:nephrogo_api_client/model/pulse.dart';
import 'package:nephrogo_api_client/model/pulse_request.dart';
import 'package:nephrogo_api_client/model/user.dart';
import 'package:nephrogo_api_client/model/user_app_review.dart';
import 'package:nephrogo_api_client/model/user_profile.dart';
import 'package:nephrogo_api_client/model/user_profile_request.dart';
import 'package:nephrogo_api_client/model/user_request.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:time_machine/time_machine.dart';

enum _AppStateChangeEvent { healthStatus, nutrition }

class ApiService {
  static const _baseApiUrl = 'https://api.nephrogo.com/';
  static const _connectionIdleTimeout = Duration(minutes: 1);

  static final ApiService _singleton = ApiService._internal();

  final _appEventsStreamController =
      StreamController<_AppStateChangeEvent>.broadcast();

  NephrogoApiClient _apiClient;

  NutritionApi _nutritionApi;
  HealthStatusApi _healthStatusApi;
  PeritonealDialysisApi _peritonealDialysisApi;
  UserApi _userApi;
  GeneralRecommendationsApi _generalRecommendationsApi;

  Stream<_AppStateChangeEvent> get appEventsStreamRemove =>
      _appEventsStreamController.stream;

  factory ApiService() {
    return _singleton;
  }

  ApiService._internal() {
    _apiClient = _buildNephrogoApiClient();

    _nutritionApi = _apiClient.getNutritionApi();
    _healthStatusApi = _apiClient.getHealthStatusApi();
    _userApi = _apiClient.getUserApi();
    _generalRecommendationsApi = _apiClient.getGeneralRecommendationsApi();
    _peritonealDialysisApi = _apiClient.getPeritonealDialysisApi();
  }

  NephrogoApiClient _buildNephrogoApiClient() {
    final dio = Dio(BaseOptions(
      baseUrl: _baseApiUrl,
      connectTimeout: 8000,
      receiveTimeout: 5000,
      headers: {
        'time-zone-name': DateTimeZone.local.id,
        'accept-encoding': 'br',
      },
    ));

    dio.transformer = DioBrotliTransformer();
    dio.httpClientAdapter = Http2Adapter(
      ConnectionManager(idleTimeout: _connectionIdleTimeout.inMilliseconds),
    );

    return NephrogoApiClient(
      dio: dio,
      basePathOverride: _baseApiUrl,
      interceptors: _buildDioInterceptors(dio),
    );
  }

  List<Interceptor> _buildDioInterceptors(Dio dio) {
    final interceptors = <Interceptor>[
      DioFirebasePerformanceInterceptor(),
      _FirebaseAuthenticationInterceptor(dio)
    ];

    if (kDebugMode) {
      interceptors.add(
        PrettyDioLogger(
          responseBody: false,
        ),
      );
    }

    return interceptors;
  }

  void _postAppStateChangeEvent(_AppStateChangeEvent event) {
    _appEventsStreamController.add(event);
  }

  Stream<_AppStateChangeEvent> _buildAppEventsStreamWithInitialEmit(
      _AppStateChangeEvent event) {
    return StreamGroup.merge(
      [_appEventsStreamController.stream, Stream.value(event)],
    ).where((e) => e == event);
  }

  Future<NutritionScreenV2Response> getNutritionScreen() {
    return _nutritionApi.nutritionScreenV2Retrieve().then((r) => r.data);
  }

  Stream<NutritionScreenV2Response> getNutritionScreenStream() {
    return _buildAppEventsStreamWithInitialEmit(_AppStateChangeEvent.nutrition)
        .asyncMap((_) => getNutritionScreen());
  }

  Future<DailyIntakesReportsResponse> getLightDailyIntakeReports(
    LocalDate from,
    LocalDate to,
  ) {
    return _nutritionApi
        .nutritionDailyReportsLightRetrieve(
          from: _HackedOffsetDate(from),
          to: _HackedOffsetDate(to),
        )
        .then((r) => r.data);
  }

  Stream<DailyIntakesReportsResponse> getLightDailyIntakeReportsStream(
    LocalDate from,
    LocalDate to,
  ) {
    return _buildAppEventsStreamWithInitialEmit(_AppStateChangeEvent.nutrition)
        .asyncMap((_) => getLightDailyIntakeReports(from, to));
  }

  Future<DailyIntakesReportResponse> getDailyIntakesReport(LocalDate date) {
    return _nutritionApi
        .nutritionDailyReportsRetrieve(_HackedOffsetDate(date))
        .then((r) => r.data)
        .catchError(
          (e) => null,
          test: (e) => e is DioError && e.response?.statusCode == 404,
        );
  }

  Stream<DailyIntakesReportResponse> getDailyIntakesReportStream(
      LocalDate date) {
    return _buildAppEventsStreamWithInitialEmit(_AppStateChangeEvent.nutrition)
        .asyncMap((_) => getDailyIntakesReport(date));
  }

  Future<NutrientWeeklyScreenResponse> getWeeklyDailyIntakesReport(
      LocalDate from, LocalDate to) {
    return _nutritionApi
        .nutritionWeeklyRetrieve(
          _HackedOffsetDate(from),
          _HackedOffsetDate(to),
        )
        .then((r) => r.data);
  }

  Stream<NutrientWeeklyScreenResponse> getWeeklyDailyIntakesReportStream(
      LocalDate from, LocalDate to) {
    return _buildAppEventsStreamWithInitialEmit(_AppStateChangeEvent.nutrition)
        .asyncMap((_) => getWeeklyDailyIntakesReport(from, to));
  }

  Future<ProductSearchResponse> getProducts(
    String query, {
    @required bool submit,
    @required List<int> excludeProductIds,
    @required MealTypeEnum mealType,
  }) {
    final excludeProductIdsStr = excludeProductIds?.join(',');

    return _nutritionApi
        .nutritionProductsSearchRetrieve(
          query: query,
          submit: submit,
          excludeProducts: excludeProductIdsStr,
          mealType: mealType.name,
        )
        .then((r) => r.data);
  }

  Future<Intake> createIntake(IntakeRequest intakeRequest) {
    return _nutritionApi.nutritionIntakeCreate(intakeRequest).then(
      (r) {
        _postAppStateChangeEvent(_AppStateChangeEvent.nutrition);
        return r.data;
      },
    );
  }

  Future<Intake> updateIntake(int intakeId, IntakeRequest intakeRequest) {
    return _nutritionApi.nutritionIntakeUpdate(intakeId, intakeRequest).then(
      (r) {
        _postAppStateChangeEvent(_AppStateChangeEvent.nutrition);
        return r.data;
      },
    );
  }

  Future<void> deleteIntake(int intakeId) {
    return _nutritionApi.nutritionIntakeDestroy(intakeId).then(
      (r) {
        _postAppStateChangeEvent(_AppStateChangeEvent.nutrition);
      },
    );
  }

  Future<DailyHealthStatus> createOrUpdateDailyHealthStatus(
      DailyHealthStatusRequest dailyHealthStatusRequest) {
    return _healthStatusApi.healthStatusUpdate(dailyHealthStatusRequest).then(
      (r) {
        _postAppStateChangeEvent(_AppStateChangeEvent.healthStatus);
        return r.data;
      },
    ).catchError(
      (e) => _healthStatusApi.healthStatusCreate(dailyHealthStatusRequest).then(
        (r) {
          _postAppStateChangeEvent(_AppStateChangeEvent.healthStatus);
          return r.data;
        },
      ),
      test: (e) => e is DioError && e.response?.statusCode == 404,
    );
  }

  Future<DailyHealthStatus> partialUpdateDailyHealthStatus(
    DailyHealthStatusRequest dailyHealthStatusRequest,
  ) {
    return _healthStatusApi
        .healthStatusPartialUpdate(dailyHealthStatusRequest)
        .then(
      (r) {
        _postAppStateChangeEvent(_AppStateChangeEvent.healthStatus);
        return r.data;
      },
    );
  }

  Future<DailyHealthStatus> getDailyHealthStatus(LocalDate date) {
    return _healthStatusApi
        .healthStatusRetrieve(_HackedOffsetDate(date))
        .then((r) => r.data)
        .catchError(
          (e) => null,
          test: (e) => e is DioError && e.response?.statusCode == 404,
        );
  }

  Future<User> getUser() {
    return _userApi.userRetrieve().then((r) => r.data);
  }

  Stream<User> getUserStream() {
    return _buildAppEventsStreamWithInitialEmit(_AppStateChangeEvent.nutrition)
        .asyncMap((_) => getUser());
  }

  Future<User> updateUser({@required bool marketingAllowed}) {
    final userRequestBuilder = UserRequestBuilder();

    userRequestBuilder.isMarketingAllowed = marketingAllowed;

    return _userApi
        .userUpdate(userRequest: userRequestBuilder.build())
        .then((r) => r.data);
  }

  Future<UserAppReview> getUserAppReview() {
    return _userApi.userAppReviewRetrieve().then((r) => r.data);
  }

  Future<UserProfile> createOrUpdateUserProfile(
    UserProfileRequest userProfile,
  ) {
    return _userApi.userProfileUpdate(userProfile).then(
      (r) {
        _postAppStateChangeEvent(_AppStateChangeEvent.healthStatus);
        _postAppStateChangeEvent(_AppStateChangeEvent.nutrition);

        return r.data;
      },
    ).catchError(
      (e) => _userApi
          .userProfileCreate(
        userProfile,
      )
          .then(
        (r) {
          _postAppStateChangeEvent(_AppStateChangeEvent.healthStatus);
          _postAppStateChangeEvent(_AppStateChangeEvent.nutrition);

          return r.data;
        },
      ),
      test: (e) => e is DioError && e.response?.statusCode == 404,
    );
  }

  Future<UserProfile> getUserProfile() {
    return _userApi.userProfileRetrieve().then((r) => r.data).catchError(
          (e) => null,
        );
  }

  Future<GeneralRecommendationsResponse> getGeneralRecommendations() {
    return _generalRecommendationsApi
        .generalRecommendationsRetrieve()
        .then((r) => r.data);
  }

  Future<HealthStatusScreenResponse> getHealthStatusScreen() {
    return _healthStatusApi.healthStatusScreenRetrieve().then((r) => r.data);
  }

  Stream<HealthStatusScreenResponse> getHealthStatusScreenStream() {
    return _buildAppEventsStreamWithInitialEmit(
            _AppStateChangeEvent.healthStatus)
        .asyncMap((_) => getHealthStatusScreen());
  }

  Future<HealthStatusWeeklyScreenResponse> getHealthStatuses(
    LocalDate from,
    LocalDate to,
  ) {
    return _healthStatusApi
        .healthStatusWeeklyRetrieve(
          _HackedOffsetDate(from),
          _HackedOffsetDate(to),
        )
        .then((r) => r.data);
  }

  Stream<HealthStatusWeeklyScreenResponse> getHealthStatusesStream(
    LocalDate from,
    LocalDate to,
  ) {
    return _buildAppEventsStreamWithInitialEmit(
            _AppStateChangeEvent.healthStatus)
        .asyncMap((_) => getHealthStatuses(from, to));
  }

  Future<BloodPressure> createBloodPressure(
    BloodPressureRequest bloodPressureRequest,
  ) {
    return _healthStatusApi
        .healthStatusBloodPressureCreate(bloodPressureRequest)
        .then(
      (r) {
        _postAppStateChangeEvent(_AppStateChangeEvent.healthStatus);

        return r.data;
      },
    );
  }

  Future<BloodPressure> updateBloodPressure(
    int id,
    BloodPressureRequest bloodPressureRequest,
  ) {
    return _healthStatusApi
        .healthStatusBloodPressureUpdate(id, bloodPressureRequest)
        .then(
      (r) {
        _postAppStateChangeEvent(_AppStateChangeEvent.healthStatus);

        return r.data;
      },
    );
  }

  Future<void> deleteBloodPressure(int id) {
    return _healthStatusApi.healthStatusBloodPressureDestroy(id).then(
      (r) {
        _postAppStateChangeEvent(_AppStateChangeEvent.healthStatus);
      },
    );
  }

  Future<Pulse> updatePulse(int id, PulseRequest pulseRequest) {
    return _healthStatusApi.healthStatusPulseUpdate(id, pulseRequest).then(
      (r) {
        _postAppStateChangeEvent(_AppStateChangeEvent.healthStatus);

        return r.data;
      },
    );
  }

  Future<Pulse> createPulse(PulseRequest pulseRequest) {
    return _healthStatusApi.healthStatusPulseCreate(pulseRequest).then(
      (r) {
        _postAppStateChangeEvent(_AppStateChangeEvent.healthStatus);

        return r.data;
      },
    );
  }

  Future<void> deletePulse(int id) {
    return _healthStatusApi.healthStatusPulseDestroy(id).then(
      (r) {
        _postAppStateChangeEvent(_AppStateChangeEvent.healthStatus);
      },
    );
  }

  Future<ManualPeritonealDialysis> createManualPeritonealDialysis(
      ManualPeritonealDialysisRequest request) {
    return _peritonealDialysisApi
        .peritonealDialysisManualDialysisCreateCreate(request)
        .then(
      (r) {
        _postAppStateChangeEvent(_AppStateChangeEvent.healthStatus);

        return r.data;
      },
    );
  }

  Future<ManualPeritonealDialysis> updateManualPeritonealDialysis(
      int id, ManualPeritonealDialysisRequest request) {
    return _peritonealDialysisApi
        .peritonealDialysisManualDialysisUpdate(id, request)
        .then(
      (r) {
        _postAppStateChangeEvent(_AppStateChangeEvent.healthStatus);

        return r.data;
      },
    );
  }

  Future<void> deleteManualPeritonealDialysis(int id) {
    return _peritonealDialysisApi
        .peritonealDialysisManualDialysisDestroy(id)
        .then(
      (r) {
        _postAppStateChangeEvent(_AppStateChangeEvent.healthStatus);
      },
    );
  }

  Future<ManualPeritonealDialysisScreenResponse>
      getManualPeritonealDialysisScreen() {
    return _peritonealDialysisApi
        .peritonealDialysisManualScreenV2Retrieve()
        .then((r) => r.data);
  }

  Stream<ManualPeritonealDialysisScreenResponse>
      getManualPeritonealDialysisScreenStream() {
    return _buildAppEventsStreamWithInitialEmit(
            _AppStateChangeEvent.healthStatus)
        .asyncMap((_) => getManualPeritonealDialysisScreen());
  }

  Future<AutomaticPeritonealDialysisScreenResponse>
      getAutomaticPeritonealDialysisScreen() {
    return _peritonealDialysisApi
        .peritonealDialysisAutomaticScreenRetrieve()
        .then((r) => r.data);
  }

  Stream<AutomaticPeritonealDialysisScreenResponse>
      getAutomaticPeritonealDialysisScreenStream() {
    return _buildAppEventsStreamWithInitialEmit(
            _AppStateChangeEvent.healthStatus)
        .asyncMap((_) => getAutomaticPeritonealDialysisScreen());
  }

  Future<AutomaticPeritonealDialysis> createAutomaticPeritonealDialysis(
      AutomaticPeritonealDialysisRequest request) {
    return _peritonealDialysisApi
        .peritonealDialysisAutomaticDialysisCreateCreate(request)
        .then(
      (r) {
        _postAppStateChangeEvent(_AppStateChangeEvent.healthStatus);

        return r.data;
      },
    );
  }

  Future<AutomaticPeritonealDialysis> updateAutomaticPeritonealDialysis(
      LocalDate date, AutomaticPeritonealDialysisRequest request) {
    return _peritonealDialysisApi
        .peritonealDialysisAutomaticDialysisUpdate(
      _HackedOffsetDate(date),
      request,
    )
        .then(
      (r) {
        _postAppStateChangeEvent(_AppStateChangeEvent.healthStatus);

        return r.data;
      },
    );
  }

  Future<void> deleteAutomaticPeritonealDialysis(LocalDate date) {
    return _peritonealDialysisApi
        .peritonealDialysisAutomaticDialysisDestroy(_HackedOffsetDate(date))
        .then(
      (r) {
        _postAppStateChangeEvent(_AppStateChangeEvent.healthStatus);
      },
    );
  }

  Future dispose() async {
    await _appEventsStreamController.close();
  }
}

class _FirebaseAuthenticationInterceptor extends Interceptor {
  static const _tokenRegeneratedKey = 'tokenRegenerated';

  final logger = Logger('ApiService');
  final _authenticationProvider = AuthenticationProvider();

  final Dio dio;

  _FirebaseAuthenticationInterceptor(this.dio);

  Future<String> _getIdToken(bool forceRefresh) {
    return _authenticationProvider.idToken(forceRefresh: forceRefresh);
  }

  @override
  Future onRequest(RequestOptions options) async {
    try {
      dio.interceptors.requestLock.lock();
      final forceRegenerateToken =
          options.extra.containsKey(_tokenRegeneratedKey);

      final idToken = await _getIdToken(forceRegenerateToken);

      options.headers['authorization'] = 'Bearer $idToken';
    } finally {
      dio.interceptors.requestLock.unlock();
    }

    return options;
  }

  @override
  Future onError(DioError err) async {
    final statusCode = err.response?.statusCode;
    if (statusCode == 403 || statusCode == 401) {
      if (err.request.extra.containsKey(_tokenRegeneratedKey)) {
        logger.severe('Authentication error after regenerating token.');
      } else {
        logger.warning('Authentication error. Regenerating user id token.');

        err.request.extra.addAll({_tokenRegeneratedKey: true});

        try {
          // We retry with the updated options
          return await dio.request(
            err.request.path,
            cancelToken: err.request.cancelToken,
            data: err.request.data,
            onReceiveProgress: err.request.onReceiveProgress,
            onSendProgress: err.request.onSendProgress,
            queryParameters: err.request.queryParameters,
            options: err.request,
          );
        } catch (e) {
          return e;
        }
      }
    }
    return err;
  }
}

class _HackedOffsetDate extends OffsetDate {
  _HackedOffsetDate(LocalDate calendarDate) : super(calendarDate, Offset.zero);

  @override
  String toString([String patternText, Culture culture]) {
    return super.toString('yyyy-MM-dd');
  }
}
