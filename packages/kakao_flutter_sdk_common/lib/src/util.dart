import 'dart:async';

import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_common/src/constants.dart';
import 'package:kakao_flutter_sdk_common/src/kakao_error.dart';

const MethodChannel _channel = MethodChannel(CommonConstants.methodChannel);

/// @nodoc
/// Launches a given url with platform-specific default browser tab.
Future<String> launchBrowserTab(Uri uri, {String? redirectUri}) async {
  if (uri.scheme != CommonConstants.http &&
      uri.scheme != CommonConstants.scheme) {
    throw KakaoClientException(
      'Default browsers only supports URL of http or https scheme.',
    );
  }
  var args = {
    CommonConstants.url: uri.toString(),
    CommonConstants.redirectUri: redirectUri
  };
  args.removeWhere((k, v) => v == null);
  final redirectUriWithParams = await _channel.invokeMethod<String>(
      CommonConstants.launchBrowserTab, args);

  if (redirectUriWithParams != null) return redirectUriWithParams;
  throw KakaoClientException(
      "OAuth 2.0 redirect uri was null, which should not happen.");
}

/// @nodoc
/// Determines whether KakaoTalk is installed on this device.
Future<bool> isKakaoTalkInstalled() async {
  final isInstalled =
      await _channel.invokeMethod<bool>(CommonConstants.isKakaoTalkInstalled) ??
          false;
  return isInstalled;
}

/// @nodoc
/// Collection of utility methods, usually for converting data types.
class Util {
  static DateTime? fromTimeStamp(int? timestamp) => timestamp == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

  static int? fromDateTime(DateTime? dateTime) =>
      dateTime == null ? null : dateTime.millisecondsSinceEpoch ~/ 1000;

  static String? dateTimeWithoutMillis(DateTime? dateTime) => dateTime == null
      ? null
      : "${dateTime.toIso8601String().substring(0, dateTime.toIso8601String().length - 5)}Z";

  static String? mapToString(Map<String, String>? params) => params == null
      ? null
      : Uri(queryParameters: params.map((key, value) => MapEntry(key, value)))
          .query;

  static Map<String, String>? stringToMap(String? params) {
    if (params == null) {
      return null;
    }
    var paramMap = <String, String>{};
    params.split('&').forEach((element) {
      paramMap[element.split('=').first] = element.split('=').last;
    });
    return paramMap;
  }
}
