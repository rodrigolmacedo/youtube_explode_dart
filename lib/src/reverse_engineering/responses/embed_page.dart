import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as parser;
import 'package:youtube_explode_dart/src/retry.dart';
import 'package:youtube_explode_dart/src/reverse_engineering/reverse_engineering.dart';
import '../../extensions/extensions.dart';

class EmbedPage {
  static final _playerConfigExp =
      RegExp(r"yt\.setConfig\({'PLAYER_CONFIG':(.*)}\);");

  final Document _root;

  EmbedPage(this._root);

  _PlayerConfig get playerconfig => _PlayerConfig(json.decode(_playerConfigJson));

  String get _playerConfigJson => _root
      .getElementsByTagName('script')
      .map((e) => e.text)
      .map((e) => _playerConfigExp.firstMatch(e).group(1))
      .firstWhere((e) => !e.isNullOrWhiteSpace);

  EmbedPage.parse(String raw) : _root = parser.parse(raw);

  Future<EmbedPage> get(YoutubeHttpClient httpClient, String videoId) {
    var url = 'https://youtube.com/embed/$videoId?hl=en';
    return retry(() async {
      var raw = await httpClient.getString(url);
      return EmbedPage.parse(raw);
    });
  }
}

class _PlayerConfig {
  // Json parsed map.
  final Map<String, dynamic> _root;

  _PlayerConfig(this._root);

  String get sourceUrl => 'https://youtube.com ${_root['assets']['js']}';
}