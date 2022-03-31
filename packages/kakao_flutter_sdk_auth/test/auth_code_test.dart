import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakao_flutter_sdk_auth/kakao_flutter_sdk_auth.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var appKey = "sampleappkey";
  KakaoSdk.init(nativeAppKey: appKey);

  var channel = const MethodChannel("kakao_flutter_sdk");
  setUp(() async {});

  tearDown(() async {
    channel.setMockMethodCallHandler(null);
  });

  group("/oauth/authorize", () {
    var redirectUri = "kakao$appKey://oauth";
    var expectedCode = "sample_auth_code";
    var state = "state";
    test("200", () async {
      channel.setMockMethodCallHandler((MethodCall call) async {
        return "$redirectUri?code=$expectedCode";
      });

      var code = await AuthCodeClient.instance.request(
          clientId: appKey,
          redirectUri: redirectUri,
          scopes: ["profile", "account_email"]);
      expect(code, expectedCode);
    });

    test("access denied", () async {
      channel.setMockMethodCallHandler((MethodCall call) async {
        return "$redirectUri?error_description=User%20denied%20access&error=access_denied&state=$state";
      });

      try {
        await AuthCodeClient.instance
            .request(clientId: appKey, redirectUri: redirectUri);
        fail("should not reach here");
      } on KakaoAuthException catch (e) {
        expect(e.error, AuthErrorCause.accessDenied);
      }
    });
  });
}
