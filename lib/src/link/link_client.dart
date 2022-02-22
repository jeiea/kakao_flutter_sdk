import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk/link.dart';
import 'package:kakao_flutter_sdk/src/common/kakao_context.dart';
import 'package:kakao_flutter_sdk/src/link/link_api.dart';
import 'package:kakao_flutter_sdk/src/link/model/image_upload_result.dart';
import 'package:kakao_flutter_sdk/src/link/model/link_result.dart';
import 'package:kakao_flutter_sdk/src/template/default_template.dart';
import 'package:platform/platform.dart';

class LinkClient {
  LinkClient(this.api, {Platform? platform})
      : _platform = platform ?? LocalPlatform();
  LinkApi api;
  Platform _platform;

  static final MethodChannel _channel = MethodChannel("kakao_flutter_sdk");

  /// singleton instance of this class.
  static final LinkClient instance = LinkClient(LinkApi.instance);

  Future<bool> isKakaoLinkAvailable() async {
    return await _channel.invokeMethod('isKakaoLinkAvailable') ?? false;
  }

  /// Send KakaoLink messages with custom templates.
  Future<Uri> customWithWeb(int templateId,
      {Map<String, String>? templateArgs,
      Map<String, String>? serverCallbackArgs}) async {
    final response = await api.custom(templateId, templateArgs: templateArgs);
    return _sharerWithResponse(response,
        serverCallbackArgs: serverCallbackArgs);
  }

  Future<Uri> defaultWithWeb(DefaultTemplate template,
      {Map<String, String>? serverCallbackArgs}) async {
    final response = await api.defaultTemplate(template);
    return _sharerWithResponse(response,
        serverCallbackArgs: serverCallbackArgs);
  }

  Future<Uri> scrapWithWeb(String url,
      {int? templateId,
      Map<String, String>? templateArgs,
      Map<String, String>? serverCallbackArgs}) async {
    final response = await api.scrap(url,
        templateId: templateId, templateArgs: templateArgs);
    return _sharerWithResponse(response,
        serverCallbackArgs: serverCallbackArgs);
  }

  /// Send KakaoLink messages with custom templates.
  Future<Uri> customWithTalk(int templateId,
      {Map<String, String>? templateArgs,
      Map<String, String>? serverCallbackArgs}) async {
    final response = await api.custom(templateId, templateArgs: templateArgs);
    return _talkWithResponse(response, serverCallbackArgs: serverCallbackArgs);
  }

  Future<Uri> defaultWithTalk(DefaultTemplate template,
      {Map<String, String>? serverCallbackArgs}) async {
    final response = await api.defaultTemplate(template);
    return _talkWithResponse(response, serverCallbackArgs: serverCallbackArgs);
  }

  Future<Uri> scrapWithTalk(String url,
      {int? templateId,
      Map<String, String>? templateArgs,
      Map<String, String>? serverCallbackArgs}) async {
    final response = await api.scrap(url,
        templateId: templateId, templateArgs: templateArgs);
    return _talkWithResponse(response, serverCallbackArgs: serverCallbackArgs);
  }

  /// Upload the local image to the Kakao Image Server to use it as a KakaoLink content image.
  Future<ImageUploadResult> uploadImage(File image,
      {bool secureResource = true}) async {
    return await api.uploadImage(image, secureResource: secureResource);
  }

  /// Upload remote image to Kakao Image Server to use as KakaoLink content image.
  Future<ImageUploadResult> scrapImage(String imageUrl,
      {bool secureResource = true}) async {
    return await api.scrapImage(imageUrl, secureResource: secureResource);
  }

  Future<void> launchKakaoTalk(Uri uri) {
    return _channel.invokeMethod("launchKakaoTalk", {"uri": uri.toString()});
  }

  Future<Uri> _sharerWithResponse(LinkResult response,
      {Map<String, String>? serverCallbackArgs}) async {
    final params = {
      "app_key": KakaoContext.clientId,
      "ka": await KakaoContext.kaHeader,
      "validation_action": "custom",
      "validation_params": jsonEncode({
        "template_id": response.templateId,
        "template_args": response.templateArgs,
        "link_ver": "4.0"
      }),
      "lcba": serverCallbackArgs == null ? null : jsonEncode(serverCallbackArgs)
    };

    params.removeWhere((k, v) => v == null);
    return Uri.https(
        KakaoContext.hosts.sharer, "talk/friends/picker/easylink", params);
  }

  Future<Uri> _talkWithResponse(LinkResult response,
      {String? clientId, Map<String, String>? serverCallbackArgs}) async {
    final attachmentSize = await _attachmentSize(response,
        clientId: clientId, serverCallbackArgs: serverCallbackArgs);
    if (attachmentSize > 10 * 1024) {
      throw KakaoClientException(
          "Exceeded message template v2 size limit (${attachmentSize / 1024}kb > 10kb).");
    }
    Map<String, String> params = {
      "linkver": "4.0",
      "appkey": clientId ?? KakaoContext.clientId,
      "appver": await KakaoContext.appVer,
      "template_id": response.templateId.toString(),
      "template_args": jsonEncode(response.templateArgs),
      "template_json": jsonEncode(response.templateMsg),
      "extras": jsonEncode(await _extras(serverCallbackArgs))
    };
    var uri = Uri(scheme: "kakaolink", host: "send", queryParameters: params);
    return Uri.parse(uri.toString().replaceAll('+', '%20'));
  }

  Future<Map<String, String?>> _extras(
      [Map<String, String>? serverCallbackArgs]) async {
    Map<String, String?> extras = {
      "KA": await KakaoContext.kaHeader,
      "lcba":
          serverCallbackArgs == null ? null : jsonEncode(serverCallbackArgs),
      ...(_platform.isAndroid
          ? {
              "appPkg": await KakaoContext.packageName,
              "keyHash": await KakaoContext.origin
            }
          : _platform.isIOS
              ? {"iosBundleId": await KakaoContext.origin}
              : {}),
    };
    extras.removeWhere((k, v) => v == null);
    return extras;
  }

  Future<int> _attachmentSize(LinkResult response,
      {String? clientId, Map<String, String>? serverCallbackArgs}) async {
    final templateMsg = response.templateMsg;
    final attachment = {
      "lv": "4.0",
      "av": "4.0",
      "ak": clientId ?? KakaoContext.clientId,
      "P": templateMsg["P"],
      "C": templateMsg["C"],
      "template_id": response.templateId,
      "template_args": response.templateArgs,
      "extras": jsonEncode(await _extras(serverCallbackArgs))
    };
    return utf8.encode(jsonEncode(attachment)).length;
  }
}
