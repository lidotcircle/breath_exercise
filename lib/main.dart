import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _languageKey = 'app_language';
const _themeSettingKey = 'app_theme_setting';

void main() {
  runApp(const BreathingApp());
}

class BreathingApp extends StatefulWidget {
  const BreathingApp({super.key});

  @override
  State<BreathingApp> createState() => _BreathingAppState();
}

class _BreathingAppState extends State<BreathingApp> {
  AppThemeSetting _themeSetting = AppThemeSetting.auto;

  @override
  void initState() {
    super.initState();
    _loadThemeSetting();
  }

  Future<void> _loadThemeSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_themeSettingKey);
    if (!mounted) {
      return;
    }
    setState(() {
      _themeSetting = _parseThemeSetting(saved);
    });
  }

  Future<void> _setThemeSetting(AppThemeSetting setting) async {
    setState(() {
      _themeSetting = setting;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeSettingKey, setting.code);
  }

  ThemeMode get _themeMode {
    switch (_themeSetting) {
      case AppThemeSetting.light:
        return ThemeMode.light;
      case AppThemeSetting.dark:
        return ThemeMode.dark;
      case AppThemeSetting.auto:
        final hour = DateTime.now().hour;
        final isDayTime = hour >= 6 && hour < 18;
        return isDayTime ? ThemeMode.light : ThemeMode.dark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Breathing Exercise',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      home: HomePage(
        themeSetting: _themeSetting,
        onThemeSettingChanged: _setThemeSetting,
      ),
    );
  }
}

class BreathingPreset {
  const BreathingPreset({
    required this.name,
    required this.inhaleSeconds,
    required this.exhaleSeconds,
    required this.pauseSeconds,
    required this.inhaleMusic,
    required this.exhaleMusic,
    required this.pauseMusic,
    required this.repeatInhaleAudio,
    required this.repeatExhaleAudio,
    required this.repeatPauseAudio,
    required this.inhaleVolume,
    required this.exhaleVolume,
    required this.pauseVolume,
  });

  final String name;
  final int inhaleSeconds;
  final int exhaleSeconds;
  final int pauseSeconds;
  final String inhaleMusic;
  final String exhaleMusic;
  final String pauseMusic;
  final bool repeatInhaleAudio;
  final bool repeatExhaleAudio;
  final bool repeatPauseAudio;
  final double inhaleVolume;
  final double exhaleVolume;
  final double pauseVolume;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'inhaleSeconds': inhaleSeconds,
      'exhaleSeconds': exhaleSeconds,
      'pauseSeconds': pauseSeconds,
      'inhaleMusic': inhaleMusic,
      'exhaleMusic': exhaleMusic,
      'pauseMusic': pauseMusic,
      'repeatInhaleAudio': repeatInhaleAudio,
      'repeatExhaleAudio': repeatExhaleAudio,
      'repeatPauseAudio': repeatPauseAudio,
      'inhaleVolume': inhaleVolume,
      'exhaleVolume': exhaleVolume,
      'pauseVolume': pauseVolume,
    };
  }

  factory BreathingPreset.fromJson(Map<String, dynamic> json) {
    return BreathingPreset(
      name: json['name'] as String? ?? 'Unnamed Preset',
      inhaleSeconds: json['inhaleSeconds'] as int? ?? 4,
      exhaleSeconds: json['exhaleSeconds'] as int? ?? 4,
      pauseSeconds: json['pauseSeconds'] as int? ?? 2,
      inhaleMusic: json['inhaleMusic'] as String? ?? '',
      exhaleMusic: json['exhaleMusic'] as String? ?? '',
      pauseMusic: json['pauseMusic'] as String? ?? '',
      repeatInhaleAudio: json['repeatInhaleAudio'] as bool? ?? false,
      repeatExhaleAudio: json['repeatExhaleAudio'] as bool? ?? false,
      repeatPauseAudio: json['repeatPauseAudio'] as bool? ?? false,
      inhaleVolume: _normalizedVolume(json['inhaleVolume']),
      exhaleVolume: _normalizedVolume(json['exhaleVolume']),
      pauseVolume: _normalizedVolume(json['pauseVolume']),
    );
  }

  BreathingPreset copyWith({
    String? name,
    int? inhaleSeconds,
    int? exhaleSeconds,
    int? pauseSeconds,
    String? inhaleMusic,
    String? exhaleMusic,
    String? pauseMusic,
    bool? repeatInhaleAudio,
    bool? repeatExhaleAudio,
    bool? repeatPauseAudio,
    double? inhaleVolume,
    double? exhaleVolume,
    double? pauseVolume,
  }) {
    return BreathingPreset(
      name: name ?? this.name,
      inhaleSeconds: inhaleSeconds ?? this.inhaleSeconds,
      exhaleSeconds: exhaleSeconds ?? this.exhaleSeconds,
      pauseSeconds: pauseSeconds ?? this.pauseSeconds,
      inhaleMusic: inhaleMusic ?? this.inhaleMusic,
      exhaleMusic: exhaleMusic ?? this.exhaleMusic,
      pauseMusic: pauseMusic ?? this.pauseMusic,
      repeatInhaleAudio: repeatInhaleAudio ?? this.repeatInhaleAudio,
      repeatExhaleAudio: repeatExhaleAudio ?? this.repeatExhaleAudio,
      repeatPauseAudio: repeatPauseAudio ?? this.repeatPauseAudio,
      inhaleVolume: inhaleVolume ?? this.inhaleVolume,
      exhaleVolume: exhaleVolume ?? this.exhaleVolume,
      pauseVolume: pauseVolume ?? this.pauseVolume,
    );
  }

  static double _normalizedVolume(Object? value) {
    if (value is num) {
      return value.toDouble().clamp(0.0, 1.0);
    }
    return 1.0;
  }
}

enum BreathPhase { inhale, exhale, pause }
enum AppLanguage { zh, en }
enum AppThemeSetting { auto, light, dark }

extension on AppLanguage {
  String get code {
    switch (this) {
      case AppLanguage.zh:
        return 'zh';
      case AppLanguage.en:
        return 'en';
    }
  }
}

extension on AppThemeSetting {
  String get code {
    switch (this) {
      case AppThemeSetting.auto:
        return 'auto';
      case AppThemeSetting.light:
        return 'light';
      case AppThemeSetting.dark:
        return 'dark';
    }
  }
}

AppThemeSetting _parseThemeSetting(String? value) {
  for (final setting in AppThemeSetting.values) {
    if (setting.code == value) {
      return setting;
    }
  }
  return AppThemeSetting.auto;
}

class _AudioChoice {
  const _AudioChoice({required this.value, required this.label});

  final String value;
  final String label;
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.themeSetting,
    required this.onThemeSettingChanged,
  });

  final AppThemeSetting themeSetting;
  final Future<void> Function(AppThemeSetting setting) onThemeSettingChanged;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _presetsKey = 'breathing_presets';
  static const _selectedPresetIndexKey = 'selected_preset_index';
  static const _backgroundMusicEnabledKey = 'background_music_enabled';
  static const _backgroundMusicSourceKey = 'background_music_source';
  static const _backgroundMusicVolumeKey = 'background_music_volume';
  static const List<String> _fallbackBuiltInAudioPaths = [
    'audio/transitive/meditation_inhale.wav',
    'audio/transitive/meditation_exhale.wav',
    'audio/transitive/meditation_hold.wav',
    'audio/background/wiki_light_rainfall.ogg',
    'audio/background/wiki_meditation_gong.ogg',
  ];
  static const Map<AppLanguage, Map<String, String>> _localizedText = {
    AppLanguage.zh: {
      'appTitle': '呼吸练习',
      'defaultPreset': '默认预设',
      'unnamedPreset': '未命名预设',
      'phaseInhale': '吸气',
      'phaseExhale': '呼气',
      'phasePause': '暂停',
      'notSet': '未设置',
      'keepAtLeastOnePreset': '至少保留一个预设',
      'required': '必填',
      'secondsInvalid': '请输入大于0的整数',
      'newPreset': '新建预设',
      'editPreset': '编辑预设',
      'presetName': '预设名称',
      'inhaleSeconds': '吸气秒数',
      'exhaleSeconds': '呼气秒数',
      'pauseSeconds': '暂停秒数',
      'inhaleMusic': '吸气音乐',
      'exhaleMusic': '呼气音乐',
      'holdMusic': '屏息音乐',
      'repeatInhaleAudio': '吸气音乐循环播放',
      'repeatExhaleAudio': '呼气音乐循环播放',
      'repeatHoldAudio': '屏息音乐循环播放',
      'inhaleVolume': '吸气音量',
      'exhaleVolume': '呼气音量',
      'holdVolume': '屏息音量',
      'noMusic': '不播放音乐',
      'importLocalAudio': '导入本地音频',
      'webImportUnsupported': 'Web 端暂不支持导入本地文件',
      'cancel': '取消',
      'save': '保存',
      'usePreset': '使用此预设',
      'delete': '删除',
      'currentPreset': '当前预设',
      'phase': '阶段',
      'remaining': '剩余',
      'secondsUnit': '秒',
      'phaseMusic': '阶段音乐',
      'start': '开始',
      'pause': '暂停',
      'reset': '重置',
      'practice': '练习',
      'presets': '预设',
      'settings': '设置',
      'language': '语言',
      'theme': '主题',
      'themeAuto': '跟随时间（默认）',
      'themeLight': '浅色',
      'themeDark': '深色',
      'backgroundMusic': '背景音乐',
      'enableBackgroundMusic': '启用背景音乐',
      'backgroundMusicSource': '背景音乐源',
      'backgroundMusicVolume': '背景音乐音量',
      'chinese': '中文',
      'english': 'English',
      'localFilePrefix': '本地文件',
      'builtinSuffix': ' (内置)',
      'audioCalmInhale': '平静吸气',
      'audioCalmExhale': '平静呼气',
      'audioLightRain': '轻雨声',
      'audioMeditationGong': '冥想钟声',
      'audioMeditationVII': '冥想音乐 VII',
      'audioMeditationLouise': '冥想音乐 Louise Jones',
      'patternDurations': '吸气 {inhale}s · 呼气 {exhale}s · 暂停 {pause}s',
      'patternInhaleMusic': '吸气音乐: {music}',
      'patternExhaleMusic': '呼气音乐: {music}',
      'patternHoldMusic': '屏息音乐: {music}',
      'patternCurrentPreset': '当前预设: {name}',
      'patternPhase': '阶段: {phase}',
      'patternRemaining': '剩余: {seconds} 秒',
      'patternPhaseMusic': '阶段音乐: {music}',
      'patternEnterName': '请输入预设名称',
    },
    AppLanguage.en: {
      'appTitle': 'Breathing Exercise',
      'defaultPreset': 'Default Preset',
      'unnamedPreset': 'Unnamed Preset',
      'phaseInhale': 'Inhale',
      'phaseExhale': 'Exhale',
      'phasePause': 'Pause',
      'notSet': 'Not set',
      'keepAtLeastOnePreset': 'Keep at least one preset',
      'required': 'Required',
      'secondsInvalid': 'Enter an integer greater than 0',
      'newPreset': 'New Preset',
      'editPreset': 'Edit Preset',
      'presetName': 'Preset Name',
      'inhaleSeconds': 'Inhale Seconds',
      'exhaleSeconds': 'Exhale Seconds',
      'pauseSeconds': 'Pause Seconds',
      'inhaleMusic': 'Inhale Audio',
      'exhaleMusic': 'Exhale Audio',
      'holdMusic': 'Hold Audio',
      'repeatInhaleAudio': 'Repeat inhale audio',
      'repeatExhaleAudio': 'Repeat exhale audio',
      'repeatHoldAudio': 'Repeat hold audio',
      'inhaleVolume': 'Inhale volume',
      'exhaleVolume': 'Exhale volume',
      'holdVolume': 'Hold volume',
      'noMusic': 'No audio',
      'importLocalAudio': 'Import local audio',
      'webImportUnsupported': 'Local file import is not supported on web',
      'cancel': 'Cancel',
      'save': 'Save',
      'usePreset': 'Use this preset',
      'delete': 'Delete',
      'currentPreset': 'Current preset',
      'phase': 'Phase',
      'remaining': 'Remaining',
      'secondsUnit': 'seconds',
      'phaseMusic': 'Phase audio',
      'start': 'Start',
      'pause': 'Pause',
      'reset': 'Reset',
      'practice': 'Practice',
      'presets': 'Presets',
      'settings': 'Settings',
      'language': 'Language',
      'theme': 'Theme',
      'themeAuto': 'Auto by time (Default)',
      'themeLight': 'Light',
      'themeDark': 'Dark',
      'backgroundMusic': 'Background Music',
      'enableBackgroundMusic': 'Enable background music',
      'backgroundMusicSource': 'Background music source',
      'backgroundMusicVolume': 'Background music volume',
      'chinese': 'Chinese',
      'english': 'English',
      'localFilePrefix': 'Local file',
      'builtinSuffix': ' (Built-in)',
      'audioCalmInhale': 'Calm Inhale',
      'audioCalmExhale': 'Calm Exhale',
      'audioLightRain': 'Light Rain',
      'audioMeditationGong': 'Meditation Gong',
      'audioMeditationVII': 'Meditation VII',
      'audioMeditationLouise': 'Meditation Louise Jones',
      'patternDurations': 'Inhale {inhale}s · Exhale {exhale}s · Pause {pause}s',
      'patternInhaleMusic': 'Inhale audio: {music}',
      'patternExhaleMusic': 'Exhale audio: {music}',
      'patternHoldMusic': 'Hold audio: {music}',
      'patternCurrentPreset': 'Current preset: {name}',
      'patternPhase': 'Phase: {phase}',
      'patternRemaining': 'Remaining: {seconds} seconds',
      'patternPhaseMusic': 'Phase audio: {music}',
      'patternEnterName': 'Please enter a preset name',
    },
  };

  final List<BreathingPreset> _presets = [];

  int _selectedIndex = 0;
  int _tabIndex = 0;
  AppLanguage _language = AppLanguage.zh;
  bool _backgroundMusicEnabled = false;
  String _backgroundMusicSource = 'audio/background/wiki_light_rainfall.ogg';
  double _backgroundMusicVolume = 0.35;
  bool _isRunning = false;
  BreathPhase _phase = BreathPhase.inhale;
  int _remainingSeconds = 0;
  Timer? _timer;
  final List<String> _builtInAudioPaths = [..._fallbackBuiltInAudioPaths];

  static const BreathingPreset _defaultPreset = BreathingPreset(
    name: 'Default Preset',
    inhaleSeconds: 4,
    exhaleSeconds: 4,
    pauseSeconds: 2,
    inhaleMusic: 'audio/transitive/meditation_inhale.wav',
    exhaleMusic: 'audio/transitive/meditation_exhale.wav',
    pauseMusic: '',
    repeatInhaleAudio: false,
    repeatExhaleAudio: false,
    repeatPauseAudio: false,
    inhaleVolume: 1.0,
    exhaleVolume: 1.0,
    pauseVolume: 1.0,
  );
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _backgroundAudioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    unawaited(_backgroundAudioPlayer.setReleaseMode(ReleaseMode.loop));
    _loadData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    _backgroundAudioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    await _loadBuiltInAudioCatalog();
    final saved = prefs.getString(_presetsKey);
    final selected = prefs.getInt(_selectedPresetIndexKey);
    final languageCode = prefs.getString(_languageKey);
    final backgroundMusicEnabled = prefs.getBool(_backgroundMusicEnabledKey);
    final backgroundMusicSource = prefs.getString(_backgroundMusicSourceKey);
    final backgroundMusicVolume = prefs.getDouble(_backgroundMusicVolumeKey);
    _language = _parseLanguage(languageCode);
    _backgroundMusicEnabled = backgroundMusicEnabled ?? false;
    _backgroundMusicSource = _normalizeMusicAsset(
      backgroundMusicSource ?? 'audio/background/wiki_light_rainfall.ogg',
    );
    _backgroundMusicVolume = (backgroundMusicVolume ?? 0.35).clamp(0.0, 1.0);
    var shouldSave = false;

    if (saved == null) {
      _setDefaultPreset();
      shouldSave = true;
    } else {
      try {
        final decoded = jsonDecode(saved);
        if (decoded is! List) {
          throw const FormatException('Preset payload must be a list.');
        }
        _presets
          ..clear()
          ..addAll(
            decoded.map(
              (item) => BreathingPreset.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            ),
          );
        var migrated = false;
        for (var i = 0; i < _presets.length; i++) {
          final preset = _presets[i];
          final normalized = _normalizePresetMusic(preset);
          if (normalized.inhaleMusic != preset.inhaleMusic ||
              normalized.exhaleMusic != preset.exhaleMusic) {
            _presets[i] = normalized;
            migrated = true;
          }
        }

        if (_presets.isEmpty) {
          _setDefaultPreset();
          shouldSave = true;
        } else {
          _selectedIndex = (selected ?? 0).clamp(0, _presets.length - 1);
          shouldSave = shouldSave || migrated;
        }
      } catch (e) {
        debugPrint('Failed to load presets from storage, resetting: $e');
        _setDefaultPreset();
        shouldSave = true;
      }
    }

    _resetSession();
    if (shouldSave) {
      await _saveData();
    }
  }

  void _setDefaultPreset() {
    _presets
      ..clear()
      ..add(_defaultPreset.copyWith(name: t('defaultPreset')));
    _selectedIndex = 0;
  }

  BreathingPreset _normalizePresetMusic(BreathingPreset preset) {
    return preset.copyWith(
      inhaleMusic: _normalizeMusicAsset(preset.inhaleMusic),
      exhaleMusic: _normalizeMusicAsset(preset.exhaleMusic),
      pauseMusic: _normalizeMusicAsset(preset.pauseMusic),
    );
  }

  String _normalizeMusicAsset(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    if (trimmed.startsWith('file://') || trimmed.contains('://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/')) {
      return Uri.file(trimmed).toString();
    }
    if (trimmed == 'calm_inhale.mp3') {
      return 'audio/transitive/meditation_inhale.wav';
    }
    if (trimmed == 'calm_exhale.mp3') {
      return 'audio/transitive/meditation_exhale.wav';
    }
    if (trimmed == 'audio/calm_inhale.wav') {
      return 'audio/transitive/meditation_inhale.wav';
    }
    if (trimmed == 'audio/calm_exhale.wav') {
      return 'audio/transitive/meditation_exhale.wav';
    }
    if (trimmed == 'audio/wiki_light_rainfall.ogg') {
      return 'audio/background/wiki_light_rainfall.ogg';
    }
    if (trimmed == 'audio/wiki_meditation_gong.ogg') {
      return 'audio/background/wiki_meditation_gong.ogg';
    }
    if (trimmed.startsWith('assets/')) {
      return trimmed.substring(7);
    }
    if (trimmed.startsWith('audio/')) {
      return trimmed;
    }
    if (trimmed.contains('/')) {
      return trimmed;
    }
    return 'audio/$trimmed';
  }

  Future<void> _loadBuiltInAudioCatalog() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets = manifest.listAssets();
      final audioAssets = assets
          .where((path) => path.startsWith('assets/audio/'))
          .where(_isAudioAssetPath)
          .map((path) => path.substring(7))
          .toSet()
          .toList()
        ..sort();
      if (audioAssets.isEmpty) {
        return;
      }
      _builtInAudioPaths
        ..clear()
        ..addAll(audioAssets);
    } catch (e) {
      debugPrint('Failed to load audio asset catalog: $e');
    }
  }

  bool _isAudioAssetPath(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.wav') ||
        lower.endsWith('.ogg') ||
        lower.endsWith('.mp3') ||
        lower.endsWith('.m4a') ||
        lower.endsWith('.aac') ||
        lower.endsWith('.flac');
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_presets.map((e) => e.toJson()).toList());
    await prefs.setString(_presetsKey, data);
    await prefs.setInt(_selectedPresetIndexKey, _selectedIndex);
    await prefs.setString(_languageKey, _language.code);
    await prefs.setBool(_backgroundMusicEnabledKey, _backgroundMusicEnabled);
    await prefs.setString(_backgroundMusicSourceKey, _backgroundMusicSource);
    await prefs.setDouble(_backgroundMusicVolumeKey, _backgroundMusicVolume);
  }

  String t(String key) {
    return _localizedText[_language]?[key] ?? key;
  }

  String tf(String key, Map<String, String> replacements) {
    var result = t(key);
    replacements.forEach((name, value) {
      result = result.replaceAll('{$name}', value);
    });
    return result;
  }

  AppLanguage _parseLanguage(String? value) {
    for (final language in AppLanguage.values) {
      if (language.code == value) {
        return language;
      }
    }
    return AppLanguage.zh;
  }

  BreathingPreset get _activePreset => _presets[_selectedIndex];

  int _phaseDuration(BreathPhase phase) {
    switch (phase) {
      case BreathPhase.inhale:
        return _activePreset.inhaleSeconds;
      case BreathPhase.exhale:
        return _activePreset.exhaleSeconds;
      case BreathPhase.pause:
        return _activePreset.pauseSeconds;
    }
  }

  String _phaseLabel(BreathPhase phase) {
    switch (phase) {
      case BreathPhase.inhale:
        return t('phaseInhale');
      case BreathPhase.exhale:
        return t('phaseExhale');
      case BreathPhase.pause:
        return t('phasePause');
    }
  }

  String _phaseMusic(BreathPhase phase) {
    final music = _phaseMusicAsset(phase);
    if (music == null || music.isEmpty) {
      return phase == BreathPhase.pause ? '-' : t('notSet');
    }
    return _audioLabel(music);
  }

  String? _phaseMusicAsset(BreathPhase phase) {
    switch (phase) {
      case BreathPhase.inhale:
        final music = _normalizeMusicAsset(_activePreset.inhaleMusic);
        return music.isEmpty ? null : music;
      case BreathPhase.exhale:
        final music = _normalizeMusicAsset(_activePreset.exhaleMusic);
        return music.isEmpty ? null : music;
      case BreathPhase.pause:
        final music = _normalizeMusicAsset(_activePreset.pauseMusic);
        return music.isEmpty ? null : music;
    }
  }

  bool _phaseShouldRepeat(BreathPhase phase) {
    switch (phase) {
      case BreathPhase.inhale:
        return _activePreset.repeatInhaleAudio;
      case BreathPhase.exhale:
        return _activePreset.repeatExhaleAudio;
      case BreathPhase.pause:
        return _activePreset.repeatPauseAudio;
    }
  }

  double _phaseVolume(BreathPhase phase) {
    switch (phase) {
      case BreathPhase.inhale:
        return _activePreset.inhaleVolume;
      case BreathPhase.exhale:
        return _activePreset.exhaleVolume;
      case BreathPhase.pause:
        return _activePreset.pauseVolume;
    }
  }

  Future<void> _playPhaseMusic(BreathPhase phase) async {
    final assetPath = _phaseMusicAsset(phase);
    final targetVolume = _phaseVolume(phase);
    try {
      await _syncBackgroundMusicLevel(phase);
      await _audioPlayer.stop();
      if (assetPath == null) {
        await _audioPlayer.setReleaseMode(ReleaseMode.release);
        return;
      }
      await _audioPlayer.setReleaseMode(
        _phaseShouldRepeat(phase) ? ReleaseMode.loop : ReleaseMode.release,
      );
      if (_isFileMusic(assetPath)) {
        final filePath = _decodeFileUri(assetPath);
        await _audioPlayer.play(DeviceFileSource(filePath));
      } else {
        await _audioPlayer.play(AssetSource(assetPath));
      }
      // Some platforms reset volume when a new source starts; apply again after play.
      await _audioPlayer.setVolume(targetVolume);
    } catch (e) {
      debugPrint('Failed to play "$assetPath": $e');
    }
  }

  Future<void> _startBackgroundMusic() async {
    if (!_backgroundMusicEnabled) {
      return;
    }
    final source = _normalizeMusicAsset(_backgroundMusicSource);
    if (source.isEmpty) {
      return;
    }
    try {
      await _backgroundAudioPlayer.stop();
      await _backgroundAudioPlayer.setReleaseMode(ReleaseMode.loop);
      await _backgroundAudioPlayer.setVolume(_backgroundMusicVolume);
      if (_isFileMusic(source)) {
        final filePath = _decodeFileUri(source);
        await _backgroundAudioPlayer.play(DeviceFileSource(filePath));
      } else {
        await _backgroundAudioPlayer.play(AssetSource(source));
      }
    } catch (e) {
      debugPrint('Failed to play background music "$source": $e');
    }
  }

  Future<void> _stopAudio() async {
    try {
      await _audioPlayer.stop();
      await _backgroundAudioPlayer.stop();
    } catch (e) {
      debugPrint('Failed to stop audio: $e');
    }
  }

  Future<void> _syncBackgroundMusicLevel(BreathPhase phase) async {
    if (!_backgroundMusicEnabled || !_isRunning) {
      return;
    }
    final phaseHasAudio = (_phaseMusicAsset(phase) ?? '').isNotEmpty;
    final target = phaseHasAudio
        ? (_backgroundMusicVolume * 0.35).clamp(0.0, 1.0).toDouble()
        : _backgroundMusicVolume;
    try {
      await _backgroundAudioPlayer.setVolume(target);
    } catch (e) {
      debugPrint('Failed to set background volume: $e');
    }
  }

  bool _isFileMusic(String source) {
    return source.startsWith('file://');
  }

  String _decodeFileUri(String fileUri) {
    final parsed = Uri.tryParse(fileUri);
    if (parsed == null) {
      return fileUri;
    }
    return Uri.decodeComponent(parsed.path);
  }

  String _audioLabel(String source) {
    final normalized = _normalizeMusicAsset(source);
    final builtIn = _builtInAudioLabel(normalized);
    if (builtIn != null) {
      return builtIn;
    }
    if (_isFileMusic(normalized)) {
      return '${t('localFilePrefix')}: ${_extractFileName(normalized)}';
    }
    return normalized;
  }

  String? _builtInAudioLabel(String source) {
    final base = switch (source) {
      'audio/transitive/meditation_inhale.wav' => t('audioCalmInhale'),
      'audio/transitive/meditation_exhale.wav' => t('audioCalmExhale'),
      'audio/background/wiki_light_rainfall.ogg' => t('audioLightRain'),
      'audio/background/wiki_meditation_gong.ogg' => t('audioMeditationGong'),
      _ => null,
    };
    final resolved = base ?? _humanizeAudioName(source);
    return '$resolved${t('builtinSuffix')}';
  }

  String _humanizeAudioName(String source) {
    final fileName = source.split('/').last;
    final nameWithoutExt = fileName.replaceFirst(RegExp(r'\.[^./]+$'), '');
    return nameWithoutExt
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _extractFileName(String fileUri) {
    final path = Uri.tryParse(fileUri)?.path ?? fileUri;
    final segments = path.split(RegExp(r'[\\/]'));
    if (segments.isEmpty) {
      return path;
    }
    return Uri.decodeComponent(segments.last);
  }

  List<_AudioChoice> _audioChoices(String selectedValue) {
    final available = <String, String>{};
    for (final path in _builtInAudioPaths) {
      available[path] = _builtInAudioLabel(path) ?? path;
    }

    for (final preset in _presets) {
      final inhale = _normalizeMusicAsset(preset.inhaleMusic);
      final exhale = _normalizeMusicAsset(preset.exhaleMusic);
      final pause = _normalizeMusicAsset(preset.pauseMusic);
      if (inhale.isNotEmpty) {
        available[inhale] = _audioLabel(inhale);
      }
      if (exhale.isNotEmpty) {
        available[exhale] = _audioLabel(exhale);
      }
      if (pause.isNotEmpty) {
        available[pause] = _audioLabel(pause);
      }
    }

    final normalizedSelected = _normalizeMusicAsset(selectedValue);
    if (normalizedSelected.isNotEmpty) {
      available[normalizedSelected] = _audioLabel(normalizedSelected);
    }

    return available.entries
        .map((entry) => _AudioChoice(value: entry.key, label: entry.value))
        .toList();
  }

  String _safeDropdownValue(String currentValue, List<_AudioChoice> choices) {
    final normalized = _normalizeMusicAsset(currentValue);
    if (normalized.isEmpty) {
      return '';
    }
    for (final choice in choices) {
      if (choice.value == normalized) {
        return normalized;
      }
    }
    return '';
  }

  Future<String?> _pickAudioFile() async {
    if (kIsWeb) {
      if (!mounted) {
        return null;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('webImportUnsupported'))),
      );
      return null;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'wav', 'ogg', 'm4a', 'aac', 'flac'],
    );
    final filePath = result?.files.single.path;
    if (filePath == null || filePath.isEmpty) {
      return null;
    }
    return Uri.file(filePath).toString();
  }

  void _startSession() {
    if (_isRunning) {
      return;
    }
    if (_remainingSeconds <= 0) {
      _remainingSeconds = _phaseDuration(_phase);
    }
    setState(() {
      _isRunning = true;
    });
    unawaited(_startBackgroundMusic());
    unawaited(_playPhaseMusic(_phase));

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _remainingSeconds -= 1;
        if (_remainingSeconds <= 0) {
          _nextPhase();
        }
      });
    });
  }

  void _pauseSession() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _isRunning = false;
    });
    unawaited(_stopAudio());
  }

  void _resetSession() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _applySessionReset();
    });
    unawaited(_stopAudio());
  }

  void _applySessionReset() {
    _isRunning = false;
    _phase = BreathPhase.inhale;
    _remainingSeconds = _activePreset.inhaleSeconds;
  }

  void _nextPhase() {
    switch (_phase) {
      case BreathPhase.inhale:
        _phase = BreathPhase.exhale;
      case BreathPhase.exhale:
        _phase = BreathPhase.pause;
      case BreathPhase.pause:
        _phase = BreathPhase.inhale;
    }
    _remainingSeconds = _phaseDuration(_phase);
    if (_isRunning) {
      unawaited(_playPhaseMusic(_phase));
    }
  }

  Future<void> _openPresetEditor(
      {BreathingPreset? existing, int? index}) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final inhaleCtrl = TextEditingController(
      text: (existing?.inhaleSeconds ?? 4).toString(),
    );
    final exhaleCtrl = TextEditingController(
      text: (existing?.exhaleSeconds ?? 4).toString(),
    );
    final pauseCtrl = TextEditingController(
      text: (existing?.pauseSeconds ?? 2).toString(),
    );
    var inhaleMusicValue = _normalizeMusicAsset(existing?.inhaleMusic ?? '');
    var exhaleMusicValue = _normalizeMusicAsset(existing?.exhaleMusic ?? '');
    var holdMusicValue = _normalizeMusicAsset(existing?.pauseMusic ?? '');
    var repeatInhaleAudio = existing?.repeatInhaleAudio ?? false;
    var repeatExhaleAudio = existing?.repeatExhaleAudio ?? false;
    var repeatHoldAudio = existing?.repeatPauseAudio ?? false;
    var inhaleVolume =
        (existing?.inhaleVolume ?? 1.0).clamp(0.0, 1.0).toDouble();
    var exhaleVolume =
        (existing?.exhaleVolume ?? 1.0).clamp(0.0, 1.0).toDouble();
    var holdVolume = (existing?.pauseVolume ?? 1.0).clamp(0.0, 1.0).toDouble();

    final result = await showDialog<BreathingPreset>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final inhaleChoices = _audioChoices(inhaleMusicValue);
            final exhaleChoices = _audioChoices(exhaleMusicValue);
            final holdChoices = _audioChoices(holdMusicValue);
            final inhaleDropdownValue = _safeDropdownValue(
              inhaleMusicValue,
              inhaleChoices,
            );
            final exhaleDropdownValue = _safeDropdownValue(
              exhaleMusicValue,
              exhaleChoices,
            );
            final holdDropdownValue = _safeDropdownValue(
              holdMusicValue,
              holdChoices,
            );

            return AlertDialog(
              title: Text(existing == null ? t('newPreset') : t('editPreset')),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: InputDecoration(labelText: t('presetName')),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return t('patternEnterName');
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: inhaleCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            InputDecoration(labelText: t('inhaleSeconds')),
                        validator: _validatePositiveSeconds,
                      ),
                      TextFormField(
                        controller: exhaleCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            InputDecoration(labelText: t('exhaleSeconds')),
                        validator: _validatePositiveSeconds,
                      ),
                      TextFormField(
                        controller: pauseCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            InputDecoration(labelText: t('pauseSeconds')),
                        validator: _validatePositiveSeconds,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: inhaleDropdownValue,
                        decoration: InputDecoration(labelText: t('inhaleMusic')),
                        items: [
                          DropdownMenuItem(
                            value: '',
                            child: Text(t('noMusic')),
                          ),
                          ...inhaleChoices.map(
                            (choice) => DropdownMenuItem(
                              value: choice.value,
                              child: Text(choice.label),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            inhaleMusicValue = value ?? '';
                          });
                        },
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () async {
                            final imported = await _pickAudioFile();
                            if (imported == null || !context.mounted) {
                              return;
                            }
                            setDialogState(() {
                              inhaleMusicValue = imported;
                            });
                          },
                          icon: const Icon(Icons.upload_file),
                          label: Text(t('importLocalAudio')),
                        ),
                      ),
                      DropdownButtonFormField<String>(
                        value: exhaleDropdownValue,
                        decoration: InputDecoration(labelText: t('exhaleMusic')),
                        items: [
                          DropdownMenuItem(
                            value: '',
                            child: Text(t('noMusic')),
                          ),
                          ...exhaleChoices.map(
                            (choice) => DropdownMenuItem(
                              value: choice.value,
                              child: Text(choice.label),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            exhaleMusicValue = value ?? '';
                          });
                        },
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () async {
                            final imported = await _pickAudioFile();
                            if (imported == null || !context.mounted) {
                              return;
                            }
                            setDialogState(() {
                              exhaleMusicValue = imported;
                            });
                          },
                          icon: const Icon(Icons.upload_file),
                          label: Text(t('importLocalAudio')),
                        ),
                      ),
                      DropdownButtonFormField<String>(
                        value: holdDropdownValue,
                        decoration: InputDecoration(labelText: t('holdMusic')),
                        items: [
                          DropdownMenuItem(
                            value: '',
                            child: Text(t('noMusic')),
                          ),
                          ...holdChoices.map(
                            (choice) => DropdownMenuItem(
                              value: choice.value,
                              child: Text(choice.label),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            holdMusicValue = value ?? '';
                          });
                        },
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () async {
                            final imported = await _pickAudioFile();
                            if (imported == null || !context.mounted) {
                              return;
                            }
                            setDialogState(() {
                              holdMusicValue = imported;
                            });
                          },
                          icon: const Icon(Icons.upload_file),
                          label: Text(t('importLocalAudio')),
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(t('repeatInhaleAudio')),
                        value: repeatInhaleAudio,
                        onChanged: (value) {
                          setDialogState(() {
                            repeatInhaleAudio = value;
                          });
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(t('repeatExhaleAudio')),
                        value: repeatExhaleAudio,
                        onChanged: (value) {
                          setDialogState(() {
                            repeatExhaleAudio = value;
                          });
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(t('repeatHoldAudio')),
                        value: repeatHoldAudio,
                        onChanged: (value) {
                          setDialogState(() {
                            repeatHoldAudio = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Text('${t('inhaleVolume')}: ${(inhaleVolume * 100).round()}%'),
                      Slider(
                        value: inhaleVolume,
                        min: 0,
                        max: 1,
                        divisions: 20,
                        onChanged: (value) {
                          setDialogState(() {
                            inhaleVolume = value;
                          });
                        },
                      ),
                      Text('${t('exhaleVolume')}: ${(exhaleVolume * 100).round()}%'),
                      Slider(
                        value: exhaleVolume,
                        min: 0,
                        max: 1,
                        divisions: 20,
                        onChanged: (value) {
                          setDialogState(() {
                            exhaleVolume = value;
                          });
                        },
                      ),
                      Text('${t('holdVolume')}: ${(holdVolume * 100).round()}%'),
                      Slider(
                        value: holdVolume,
                        min: 0,
                        max: 1,
                        divisions: 20,
                        onChanged: (value) {
                          setDialogState(() {
                            holdVolume = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    Navigator.pop(context);
                  },
                  child: Text(t('cancel')),
                ),
                FilledButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }
                    FocusManager.instance.primaryFocus?.unfocus();
                    final preset = _normalizePresetMusic(
                      BreathingPreset(
                        name: nameCtrl.text.trim(),
                        inhaleSeconds: int.parse(inhaleCtrl.text.trim()),
                        exhaleSeconds: int.parse(exhaleCtrl.text.trim()),
                        pauseSeconds: int.parse(pauseCtrl.text.trim()),
                        inhaleMusic: inhaleMusicValue,
                        exhaleMusic: exhaleMusicValue,
                        pauseMusic: holdMusicValue,
                        repeatInhaleAudio: repeatInhaleAudio,
                        repeatExhaleAudio: repeatExhaleAudio,
                        repeatPauseAudio: repeatHoldAudio,
                        inhaleVolume: inhaleVolume,
                        exhaleVolume: exhaleVolume,
                        pauseVolume: holdVolume,
                      ),
                    );
                    Navigator.pop(
                      context,
                      preset,
                    );
                  },
                  child: Text(t('save')),
                ),
              ],
            );
          },
        );
      },
    );

    await WidgetsBinding.instance.endOfFrame;
    nameCtrl.dispose();
    inhaleCtrl.dispose();
    exhaleCtrl.dispose();
    pauseCtrl.dispose();

    if (result == null) {
      return;
    }

    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      return;
    }

    setState(() {
      if (index == null) {
        _presets.add(result);
        _selectedIndex = _presets.length - 1;
      } else {
        _presets[index] = result;
      }
      _timer?.cancel();
      _timer = null;
      _applySessionReset();
    });
    unawaited(_stopAudio());
    await _saveData();
  }

  String? _validatePositiveSeconds(String? value) {
    if (value == null || value.trim().isEmpty) {
      return t('required');
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      return t('secondsInvalid');
    }
    return null;
  }

  Future<void> _deletePreset(int index) async {
    if (_presets.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('keepAtLeastOnePreset'))),
      );
      return;
    }

    setState(() {
      _presets.removeAt(index);
      if (_selectedIndex >= _presets.length) {
        _selectedIndex = _presets.length - 1;
      }
      _timer?.cancel();
      _timer = null;
      _applySessionReset();
    });
    unawaited(_stopAudio());
    await _saveData();
  }

  Future<void> _selectPreset(int index) async {
    setState(() {
      _selectedIndex = index;
      _timer?.cancel();
      _timer = null;
      _applySessionReset();
    });
    unawaited(_stopAudio());
    await _saveData();
  }

  Future<void> _setLanguage(AppLanguage language) async {
    if (_language == language) {
      return;
    }
    setState(() {
      _language = language;
    });
    await _saveData();
  }

  Future<void> _setBackgroundMusicEnabled(bool enabled) async {
    setState(() {
      _backgroundMusicEnabled = enabled;
    });
    await _saveData();
    if (!_isRunning) {
      return;
    }
    if (_backgroundMusicEnabled && _backgroundMusicSource.isNotEmpty) {
      await _startBackgroundMusic();
      await _syncBackgroundMusicLevel(_phase);
    } else {
      await _backgroundAudioPlayer.stop();
    }
  }

  Future<void> _setBackgroundMusicSource(String source) async {
    setState(() {
      _backgroundMusicSource = _normalizeMusicAsset(source);
    });
    await _saveData();
    if (!_isRunning) {
      return;
    }
    if (_backgroundMusicEnabled && _backgroundMusicSource.isNotEmpty) {
      await _startBackgroundMusic();
      await _syncBackgroundMusicLevel(_phase);
    } else {
      await _backgroundAudioPlayer.stop();
    }
  }

  Future<void> _setBackgroundMusicVolume(double value) async {
    setState(() {
      _backgroundMusicVolume = value.clamp(0.0, 1.0).toDouble();
    });
    await _saveData();
    if (!_isRunning || !_backgroundMusicEnabled) {
      return;
    }
    await _syncBackgroundMusicLevel(_phase);
  }

  String _themeLabel(AppThemeSetting setting) {
    switch (setting) {
      case AppThemeSetting.auto:
        return t('themeAuto');
      case AppThemeSetting.light:
        return t('themeLight');
      case AppThemeSetting.dark:
        return t('themeDark');
    }
  }

  Widget _buildPresetTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _presets.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == _presets.length) {
          return OutlinedButton.icon(
            onPressed: _openPresetEditor,
            icon: const Icon(Icons.add),
            label: Text(t('newPreset')),
          );
        }

        final preset = _presets[index];
        final selected = index == _selectedIndex;

        return Card(
          color:
              selected ? Theme.of(context).colorScheme.primaryContainer : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        preset.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  tf('patternDurations', {
                    'inhale': '${preset.inhaleSeconds}',
                    'exhale': '${preset.exhaleSeconds}',
                    'pause': '${preset.pauseSeconds}',
                  }),
                ),
                Text(
                  tf('patternInhaleMusic', {
                    'music': preset.inhaleMusic.isEmpty
                        ? t('notSet')
                        : _audioLabel(preset.inhaleMusic),
                  }),
                ),
                Text(
                  tf('patternExhaleMusic', {
                    'music': preset.exhaleMusic.isEmpty
                        ? t('notSet')
                        : _audioLabel(preset.exhaleMusic),
                  }),
                ),
                Text(
                  tf('patternHoldMusic', {
                    'music': preset.pauseMusic.isEmpty
                        ? t('notSet')
                        : _audioLabel(preset.pauseMusic),
                  }),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    FilledButton.tonal(
                      onPressed: () => _selectPreset(index),
                      child: Text(t('usePreset')),
                    ),
                    OutlinedButton(
                      onPressed: () => _openPresetEditor(
                        existing: preset,
                        index: index,
                      ),
                      child: Text(t('editPreset')),
                    ),
                    TextButton(
                      onPressed: () => _deletePreset(index),
                      child: Text(t('delete')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSessionTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tf('patternCurrentPreset', {'name': _activePreset.name}),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(tf('patternPhase', {'phase': _phaseLabel(_phase)})),
                  Text(
                    tf('patternRemaining', {'seconds': '$_remainingSeconds'}),
                  ),
                  Text(
                    tf('patternPhaseMusic', {'music': _phaseMusic(_phase)}),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: Text(
                _phaseLabel(_phase),
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ),
          ),
          Text(
            '$_remainingSeconds',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton(
                onPressed: _isRunning ? null : _startSession,
                child: Text(t('start')),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _isRunning ? _pauseSession : null,
                child: Text(t('pause')),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: _resetSession,
                child: Text(t('reset')),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t('language'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<AppLanguage>(
                  value: _language,
                  items: [
                    DropdownMenuItem(
                      value: AppLanguage.zh,
                      child: Text(t('chinese')),
                    ),
                    DropdownMenuItem(
                      value: AppLanguage.en,
                      child: Text(t('english')),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    unawaited(_setLanguage(value));
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t('theme'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<AppThemeSetting>(
                  value: widget.themeSetting,
                  items: AppThemeSetting.values
                      .map(
                        (setting) => DropdownMenuItem(
                          value: setting,
                          child: Text(_themeLabel(setting)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    unawaited(widget.onThemeSettingChanged(value));
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t('backgroundMusic'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t('enableBackgroundMusic')),
                  value: _backgroundMusicEnabled,
                  onChanged: (value) {
                    unawaited(_setBackgroundMusicEnabled(value));
                  },
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final choices = _audioChoices(_backgroundMusicSource);
                    final safeValue = _safeDropdownValue(
                      _backgroundMusicSource,
                      choices,
                    );
                    return DropdownButtonFormField<String>(
                      value: safeValue,
                      decoration: InputDecoration(
                        labelText: t('backgroundMusicSource'),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: '',
                          child: Text(t('noMusic')),
                        ),
                        ...choices.map(
                          (choice) => DropdownMenuItem(
                            value: choice.value,
                            child: Text(choice.label),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        unawaited(_setBackgroundMusicSource(value ?? ''));
                      },
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  '${t('backgroundMusicVolume')}: ${(_backgroundMusicVolume * 100).round()}%',
                ),
                Slider(
                  value: _backgroundMusicVolume,
                  min: 0,
                  max: 1,
                  divisions: 20,
                  onChanged: (value) {
                    unawaited(_setBackgroundMusicVolume(value));
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () async {
                      final imported = await _pickAudioFile();
                      if (imported == null || !mounted) {
                        return;
                      }
                      await _setBackgroundMusicSource(imported);
                    },
                    icon: const Icon(Icons.upload_file),
                    label: Text(t('importLocalAudio')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_presets.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t('appTitle')),
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _buildSessionTab(),
          _buildPresetTab(),
          _buildSettingsTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) {
          setState(() {
            _tabIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.air),
            label: t('practice'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.tune),
            label: t('presets'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.language),
            label: t('settings'),
          ),
        ],
      ),
    );
  }
}
