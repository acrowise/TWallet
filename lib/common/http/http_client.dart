import 'package:dio/dio.dart';
import 'package:optional/optional.dart';
import 'package:tw_wallet_ui/common/http/loading_interceptor.dart';
import 'package:tw_wallet_ui/store/env_store.dart';
import 'package:tw_wallet_ui/widgets/hint_dialog.dart';

void showErrorDialog(DioError err) {
  String errorMessage = '未知错误';

  switch (err.type) {
    case DioErrorType.CONNECT_TIMEOUT:
      errorMessage = '连接超时';
      break;

    case DioErrorType.SEND_TIMEOUT:
      errorMessage = '发送超时';
      break;

    case DioErrorType.RECEIVE_TIMEOUT:
      errorMessage = '接收超时';
      break;

    case DioErrorType.CANCEL:
      errorMessage = '用户取消';
      break;

    default:
      if (err.response != null) {
        if (err.response.statusCode == 400) {
          if (err.response.data['code'] == 40000) {
            errorMessage = err.response.data['msg'] as String;
          } else {
            errorMessage = '请求失败';
          }
        }
        if (err.response.statusCode >= 500) {
          errorMessage = '服务端不响应';
        }
      }
      break;
  }
  showDialogSample(DialogType.error, '$errorMessage，请稍后再试。。。');
}

class HttpClient {
  final Dio _dio = Dio()
    ..options = BaseOptions(
      baseUrl: globalEnv().apiGatewayBaseUrl,
      connectTimeout: globalEnv().apiGatewayConnectTimeout,
      responseType: ResponseType.json,
    )
    ..interceptors.add(LoadingInterceptor())
    ..interceptors.add(LogInterceptor(requestBody: true, responseBody: true));

  Future<Optional<Response>> get(String url,
      {bool loading = true, bool throwError = false}) async {
    return _dio
        .get(url, options: Options(extra: {'withoutLoading': !loading}))
        .then((response) => Optional.of(response))
        .catchError((err) {
      if (throwError) {
        throw Exception(err);
      } else {
        showErrorDialog(err as DioError);
        return Future.value(const Optional.empty() as Optional<Response>);
      }
    });
  }

  Future<Optional<Response>> post(String url, Map<String, dynamic> data,
      {bool loading = true, bool throwError = false}) async {
    Optional<Response> res = const Optional.empty();
    try {
      res = Optional.of(await _dio.post(url,
          options: Options(extra: {'withoutLoading': !loading}), data: data));
    } catch (err) {
      if (throwError) {
        throw Exception(err);
      } else {
        showErrorDialog(err as DioError);
      }
    }
    return res;
  }
}
