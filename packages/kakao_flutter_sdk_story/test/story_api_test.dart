import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakao_flutter_sdk_story/kakao_flutter_sdk_story.dart';

import '../../kakao_flutter_sdk_common/test/helper.dart';
import '../../kakao_flutter_sdk_common/test/mock_adapter.dart';

void main() {
  late MockAdapter _adapter;
  late StoryApi _api;
  late Dio _dio;
  setUp(() {
    _dio = Dio();
    _adapter = MockAdapter();
    _dio.httpClientAdapter = _adapter;
    _api = StoryApi(_dio);
  });

  test("/v1/api/story/isstoryuser 200", () async {
    String body = jsonEncode({"isStoryUser": true});
    _adapter.setResponseString(body, 200);
    bool isUser = await _api.isStoryUser();
    expect(isUser, true);
  });

  test("/v1/api/story/profile", () async {
    String body = await loadJson("story/profile.json");
    _adapter.setResponseString(body, 200);
    var map = jsonDecode(body);
    var profile = await _api.profile();
    expect(profile.nickname, map["nickName"]);
    expect(profile.profileImageUrl.toString(), map["profileImageURL"]);
    expect(profile.thumbnailUrl.toString(), map["thumbnailURL"]);
    expect(profile.permalink.toString(), map["permalink"]);
    expect(profile.birthday, map["birthday"]);
    expect(profile.birthdayType, map["birthdayType"]);
  });

  test("/v1/api/story/mystories 200", () async {
    String body = await loadJson("story/stories.json");
    _adapter.setResponseString(body, 200);
    var stories = await _api.stories();
    expect(stories.length, 3);
  });

  test("/v1/api/story/mystory 200", () async {
    String body = await loadJson("story/story.json");
    _adapter.setResponseString(body, 200);

    var story = await _api.story("AAAAAAA.CCCCCCCCCCC");
    var likes = story.likes;
    print("${story}");
    expect(story.mediaType, StoryType.photo);
    expect(likes?[0].emotion, Emotion.cool);
    expect(story.permission, StoryPermission.public);
  });

  group("/v1/api/story/delete/mystory", () {
    test("with id", () async {
      _adapter.setResponseString("", 200);
      var storyId = "AAAAAAA.CCCCCCCCCCC";
      _adapter.requestAssertions = (RequestOptions options) {
        expect(options.method, "DELETE");
        expect(options.path, "/v1/api/story/delete/mystory");
        var params = options.queryParameters;
        expect(params["id"], storyId);
      };
      await _api.delete(storyId);
    });
  });

  test("/v1/api/story/linkinfo 200", () async {
    var body = await loadJson("story/linkinfo.json");
    var map = jsonDecode(body);
    _adapter.setResponseString(body, 200);

    var url = "https://developers.kakao.com";
    _adapter.requestAssertions = (RequestOptions options) {
      expect(options.method, "GET");
      expect(options.path, "/v1/api/story/linkinfo");
      var params = options.queryParameters;
      expect(params["url"], url);
    };
    var info = await _api.linkInfo(url);

    expect(info.url.toString(), map["url"]);
    expect(info.requestedUrl.toString(), map["requested_url"]);
    expect(info.section, map["section"]);
    expect(info.title, map["title"]);
    expect(info.type, map["type"]);
    expect(info.description, map["description"]);
    expect(info.host, map["host"]);
  });

  group("/v1/api/story/post", () {
    Map<String, String>? map;
    setUp(() async {
      map = {"id": "AAAAAAA.DDDDDDDDDDD"};
      _adapter.setResponseString(jsonEncode(map), 200);
    });
    test("/note with minimal params", () async {
      var content = "Story posting...";
      _adapter.requestAssertions = (RequestOptions options) {
        expect(options.method, "POST");
        expect(options.path, "/v1/api/story/post/note");
        Map<String, dynamic> params = options.data;
        expect(params.keys.length, 3);
      };
      var storyPostResult = await _api.postNote(content: content);
      expect(storyPostResult.id, map!["id"]);
    });

    test("/photo", () async {
      var images = [
        "https://developers.kakao.com/image1.png",
        "https://developers.kakao.com/image1.png",
        "https://developers.kakao.com/image1.png"
      ];

      _adapter.requestAssertions = (RequestOptions options) {
        expect(options.method, "POST");
        expect(options.path, "/v1/api/story/post/photo");
        Map<String, dynamic> params = options.data;
        expect(params.keys.length, 2);

        var urls = jsonDecode(params["image_url_list"]) as List<dynamic>;
        expect(urls.length, 3);
      };
      var storyPostResult = await _api.postPhoto(
          images: images, permission: StoryPermission.friend);
      expect(storyPostResult.id, map!["id"]);
    });

    test("/link", () async {
      var bodyMap = jsonDecode(await loadJson("story/linkinfo.json"));
      var linkInfo = LinkInfo.fromJson(bodyMap);
      _adapter.requestAssertions = (RequestOptions options) {
        expect(options.method, "POST");
        expect(options.path, "/v1/api/story/post/link");
        Map<String, dynamic> params = options.data;
        expect(params.length, 3);
      };
      var storyPostResult = await _api.postLink(
        linkInfo: linkInfo,
        enableShare: false,
        androidExecParam: {"key1": "value1", "key2": "value2"},
      );
      expect(storyPostResult.id, map!["id"]);
    });
  });

  group("/v1/api/story/upload/multi", () {
    test("200", () async {
      var body = await loadJson("story/multi.json");
      var urls = jsonDecode(body);

      _adapter.requestAssertions = (RequestOptions options) {
        expect(options.method, "POST");
        expect(options.path, "/v1/api/story/upload/multi");
      };
      _adapter.setResponseString(body, 200);
      var files = [
        File("../../test_resources/images/cat1.png"),
        File("../../test_resources/images/cat2.png")
      ];

      var res = await _api.upload(files);
      expect(res, urls);
    });
  });
}
