import 'dart:async';

import 'package:built_value/iso_8601_date_time_serializer.dart';
import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart';
import 'package:dio_brotli_transformer/dio_brotli_transformer.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:logging/logging.dart';
import 'package:nephrogo/authentication/authentication_provider.dart';
import 'package:nephrogo/models/date.dart';
import 'package:nephrogo_api_client/api.dart';
import 'package:nephrogo_api_client/api/health_status_api.dart';
import 'package:nephrogo_api_client/api/nutrition_api.dart';
import 'package:nephrogo_api_client/api/user_api.dart';
import 'package:nephrogo_api_client/model/daily_health_status.dart';
import 'package:nephrogo_api_client/model/daily_health_status_request.dart';
import 'package:nephrogo_api_client/model/health_status_screen_response.dart';
import 'package:nephrogo_api_client/model/health_status_weekly_screen_response.dart';
import 'package:nephrogo_api_client/model/intake.dart';
import 'package:nephrogo_api_client/model/intake_request.dart';
import 'package:nephrogo_api_client/model/nutrient_screen_response.dart';
import 'package:nephrogo_api_client/model/nutrient_weekly_screen_response.dart';
import 'package:nephrogo_api_client/model/product.dart';
import 'package:nephrogo_api_client/model/user_profile.dart';
import 'package:nephrogo_api_client/model/user_profile_request.dart';
import 'package:nephrogo_api_client/serializers.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:stream_transform/stream_transform.dart';

enum _AppStateChangeEvent { healthStatus, nutrition }

class ApiService {
  static const _baseApiUrl = "https://api.nephrogo.com/";
  static const _connectionIdleTimeout = Duration(minutes: 1);

  static final ApiService _singleton = ApiService._internal();

  final _appEventsStreamController =
      StreamController<_AppStateChangeEvent>.broadcast();

  NephrogoApiClient _apiClient;
  NutritionApi _nutritionApi;
  HealthStatusApi _healthStatusApi;
  UserApi _userApi;

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
  }

  NephrogoApiClient _buildNephrogoApiClient() {
    final timeZoneName = DateTime.now().timeZoneName;

    final dio = Dio(BaseOptions(
      baseUrl: _baseApiUrl,
      connectTimeout: 8000,
      receiveTimeout: 5000,
      headers: {
        "time-zone-name": timeZoneName,
        'accept-encoding': 'br',
      },
    ));

    dio.transformer = DioBrotliTransformer();
    dio.httpClientAdapter = Http2Adapter(
        ConnectionManager(idleTimeout: _connectionIdleTimeout.inMilliseconds));

    return NephrogoApiClient(
      dio: dio,
      basePathOverride: _baseApiUrl,
      serializers: _buildDioSerializers(),
      interceptors: _buildDioInterceptors(dio),
    );
  }

  List<Interceptor> _buildDioInterceptors(Dio dio) {
    final interceptors = <Interceptor>[_FirebaseAuthenticationInterceptor(dio)];

    if (kDebugMode) {
      interceptors.add(
        PrettyDioLogger(
          request: true,
          responseBody: false,
          requestHeader: false,
          requestBody: false,
        ),
      );
    }

    return interceptors;
  }

  Serializers _buildDioSerializers() {
    final apiSerializersBuilder = standardSerializers.toBuilder()
      ..add(DateAndDateTimeUtcSerializer());

    return apiSerializersBuilder.build();
  }

  void _postAppStateChangeEvent(_AppStateChangeEvent event) {
    _appEventsStreamController.add(event);
  }

  Stream<_AppStateChangeEvent> _buildAppEventsStreamWithInitialEmit(
      _AppStateChangeEvent event) {
    return _appEventsStreamController.stream
        .startWith(event)
        .where((e) => e == event);
  }

  Future<NutrientScreenResponse> getNutritionScreen() {
    return _nutritionApi.nutritionScreenRetrieve().then((r) => r.data);
  }

  Stream<NutrientScreenResponse> getNutritionScreenStream() {
    return _buildAppEventsStreamWithInitialEmit(_AppStateChangeEvent.nutrition)
        .asyncMap((_) => getNutritionScreen());
  }

  Future<NutrientWeeklyScreenResponse> getWeeklyDailyIntakesReport(
      DateTime from, DateTime to) {
    return _nutritionApi
        .nutritionWeeklyRetrieve(Date(from), Date(to))
        .then((r) => r.data);
  }

  Stream<NutrientWeeklyScreenResponse> getWeeklyDailyIntakesReportStream(
      DateTime from, DateTime to) {
    return _buildAppEventsStreamWithInitialEmit(_AppStateChangeEvent.nutrition)
        .asyncMap((_) => getWeeklyDailyIntakesReport(from, to));
  }

  Future<List<Product>> getProducts(String query) {
    return _nutritionApi
        .nutritionProductsList(query)
        .then((r) => r.data.toList());
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

  Future<DailyHealthStatus> getDailyHealthStatus(
    DateTime date,
  ) {
    return _healthStatusApi
        .healthStatusRetrieve(Date(date))
        .then((r) => r.data)
        .catchError(
          (e) => null,
          test: (e) => e is DioError && e.response?.statusCode == 404,
        );
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

  Future<HealthStatusScreenResponse> getHealthStatusScreen() {
    return _healthStatusApi.healthStatusScreenRetrieve().then((r) => r.data);
  }

  Stream<HealthStatusScreenResponse> getHealthStatusScreenStream() {
    return _buildAppEventsStreamWithInitialEmit(
            _AppStateChangeEvent.healthStatus)
        .asyncMap((_) => getHealthStatusScreen());
  }

  Future<HealthStatusWeeklyScreenResponse> getWeeklyHealthStatusReport(
      DateTime from, DateTime to) {
    return _healthStatusApi
        .healthStatusWeeklyRetrieve(Date(from), Date(to))
        .then((r) => r.data);
  }

  Stream<HealthStatusWeeklyScreenResponse> getWeeklyHealthStatusReportsStream(
      DateTime from, DateTime to) {
    return _buildAppEventsStreamWithInitialEmit(
            _AppStateChangeEvent.healthStatus)
        .asyncMap((_) => getWeeklyHealthStatusReport(from, to));
  }

  Future dispose() async {
    await _appEventsStreamController.close();
  }
}

class _FirebaseAuthenticationInterceptor extends Interceptor {
  static const _tokenRegeneratedKey = "tokenRegenerated";

  final logger = Logger('ApiService');
  final _authenticationProvider = AuthenticationProvider();

  final Dio dio;

  _FirebaseAuthenticationInterceptor(this.dio);

  Future<String> _getIdToken(bool forceRefresh) {
    return _authenticationProvider.idToken(forceRefresh);
  }

  @override
  Future onRequest(RequestOptions options) async {
    try {
      dio.interceptors.requestLock.lock();
      final forceRegenerateToken =
          options.extra.containsKey(_tokenRegeneratedKey);

      final idToken = await _getIdToken(forceRegenerateToken);

      options.headers["authorization"] = "Bearer $idToken";
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
        logger.severe("Authentication error after regenerating token.");
      } else {
        logger.warning("Authentication error. Regenerating user id token.");

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

// Hack start
class DateAndDateTimeUtcSerializer extends Iso8601DateTimeSerializer {
  @override
  DateTime deserialize(Serializers serializers, Object serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final s = serialized as String;

    if (s.contains('T')) {
      return super.deserialize(serializers, serialized);
    }

    try {
      return Date(Date.dateFormat.parseStrict(s));
    } on FormatException {
      return super.deserialize(serializers, serialized);
    }
  }

  @override
  Object serialize(Serializers serializers, DateTime dateTime,
      {FullType specifiedType = FullType.unspecified}) {
    if (dateTime is Date) {
      return dateTime.toString();
    }

    return super.serialize(serializers, dateTime, specifiedType: specifiedType);
  }
}
// hack end