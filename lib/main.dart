import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const BreathingApp());
}

class BreathingApp extends StatelessWidget {
  const BreathingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '呼吸练习',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomePage(),
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
  });

  final String name;
  final int inhaleSeconds;
  final int exhaleSeconds;
  final int pauseSeconds;
  final String inhaleMusic;
  final String exhaleMusic;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'inhaleSeconds': inhaleSeconds,
      'exhaleSeconds': exhaleSeconds,
      'pauseSeconds': pauseSeconds,
      'inhaleMusic': inhaleMusic,
      'exhaleMusic': exhaleMusic,
    };
  }

  factory BreathingPreset.fromJson(Map<String, dynamic> json) {
    return BreathingPreset(
      name: json['name'] as String? ?? '未命名预设',
      inhaleSeconds: json['inhaleSeconds'] as int? ?? 4,
      exhaleSeconds: json['exhaleSeconds'] as int? ?? 4,
      pauseSeconds: json['pauseSeconds'] as int? ?? 2,
      inhaleMusic: json['inhaleMusic'] as String? ?? '',
      exhaleMusic: json['exhaleMusic'] as String? ?? '',
    );
  }

  BreathingPreset copyWith({
    String? name,
    int? inhaleSeconds,
    int? exhaleSeconds,
    int? pauseSeconds,
    String? inhaleMusic,
    String? exhaleMusic,
  }) {
    return BreathingPreset(
      name: name ?? this.name,
      inhaleSeconds: inhaleSeconds ?? this.inhaleSeconds,
      exhaleSeconds: exhaleSeconds ?? this.exhaleSeconds,
      pauseSeconds: pauseSeconds ?? this.pauseSeconds,
      inhaleMusic: inhaleMusic ?? this.inhaleMusic,
      exhaleMusic: exhaleMusic ?? this.exhaleMusic,
    );
  }
}

enum BreathPhase { inhale, exhale, pause }

class _AudioChoice {
  const _AudioChoice({required this.value, required this.label});

  final String value;
  final String label;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _presetsKey = 'breathing_presets';
  static const _selectedPresetIndexKey = 'selected_preset_index';
  static const Map<String, String> _builtInAudioLabels = {
    'audio/calm_inhale.wav': '平静吸气 (内置)',
    'audio/calm_exhale.wav': '平静呼气 (内置)',
    'audio/wiki_light_rainfall.ogg': '轻雨声 (内置)',
    'audio/wiki_meditation_gong.ogg': '冥想钟声 (内置)',
    'audio/wiki_meditation_vii.ogg': '冥想音乐 VII (内置)',
    'audio/wiki_meditation_louise_jones.ogg': '冥想音乐 Louise Jones (内置)',
  };

  final List<BreathingPreset> _presets = [];

  int _selectedIndex = 0;
  int _tabIndex = 0;
  bool _isRunning = false;
  BreathPhase _phase = BreathPhase.inhale;
  int _remainingSeconds = 0;
  Timer? _timer;

  static const BreathingPreset _defaultPreset = BreathingPreset(
    name: '默认预设',
    inhaleSeconds: 4,
    exhaleSeconds: 4,
    pauseSeconds: 2,
    inhaleMusic: 'audio/calm_inhale.wav',
    exhaleMusic: 'audio/calm_exhale.wav',
  );
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_presetsKey);
    final selected = prefs.getInt(_selectedPresetIndexKey);
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
      ..add(_defaultPreset);
    _selectedIndex = 0;
  }

  BreathingPreset _normalizePresetMusic(BreathingPreset preset) {
    return preset.copyWith(
      inhaleMusic: _normalizeMusicAsset(preset.inhaleMusic),
      exhaleMusic: _normalizeMusicAsset(preset.exhaleMusic),
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
      return 'audio/calm_inhale.wav';
    }
    if (trimmed == 'calm_exhale.mp3') {
      return 'audio/calm_exhale.wav';
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

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_presets.map((e) => e.toJson()).toList());
    await prefs.setString(_presetsKey, data);
    await prefs.setInt(_selectedPresetIndexKey, _selectedIndex);
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
        return '吸气';
      case BreathPhase.exhale:
        return '呼气';
      case BreathPhase.pause:
        return '暂停';
    }
  }

  String _phaseMusic(BreathPhase phase) {
    final music = _phaseMusicAsset(phase);
    if (music == null || music.isEmpty) {
      return phase == BreathPhase.pause ? '-' : '未设置';
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
        return null;
    }
  }

  Future<void> _playPhaseMusic(BreathPhase phase) async {
    final assetPath = _phaseMusicAsset(phase);
    if (assetPath == null) {
      return;
    }
    try {
      await _audioPlayer.stop();
      if (_isFileMusic(assetPath)) {
        final filePath = _decodeFileUri(assetPath);
        await _audioPlayer.play(DeviceFileSource(filePath));
      } else {
        await _audioPlayer.play(AssetSource(assetPath));
      }
    } catch (e) {
      debugPrint('Failed to play "$assetPath": $e');
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
    final builtIn = _builtInAudioLabels[normalized];
    if (builtIn != null) {
      return builtIn;
    }
    if (_isFileMusic(normalized)) {
      return '本地文件: ${_extractFileName(normalized)}';
    }
    return normalized;
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
    final available = <String, String>{..._builtInAudioLabels};

    for (final preset in _presets) {
      final inhale = _normalizeMusicAsset(preset.inhaleMusic);
      final exhale = _normalizeMusicAsset(preset.exhaleMusic);
      if (inhale.isNotEmpty) {
        available[inhale] = _audioLabel(inhale);
      }
      if (exhale.isNotEmpty) {
        available[exhale] = _audioLabel(exhale);
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
        const SnackBar(content: Text('Web 端暂不支持导入本地文件')),
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
  }

  void _resetSession() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _applySessionReset();
    });
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

    final result = await showDialog<BreathingPreset>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final inhaleChoices = _audioChoices(inhaleMusicValue);
            final exhaleChoices = _audioChoices(exhaleMusicValue);
            final inhaleDropdownValue = _safeDropdownValue(
              inhaleMusicValue,
              inhaleChoices,
            );
            final exhaleDropdownValue = _safeDropdownValue(
              exhaleMusicValue,
              exhaleChoices,
            );

            return AlertDialog(
              title: Text(existing == null ? '新建预设' : '编辑预设'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: '预设名称'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入预设名称';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: inhaleCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '吸气秒数'),
                        validator: _validatePositiveSeconds,
                      ),
                      TextFormField(
                        controller: exhaleCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '呼气秒数'),
                        validator: _validatePositiveSeconds,
                      ),
                      TextFormField(
                        controller: pauseCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '暂停秒数'),
                        validator: _validatePositiveSeconds,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: inhaleDropdownValue,
                        decoration: const InputDecoration(labelText: '吸气音乐'),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('不播放音乐'),
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
                          label: const Text('导入本地音频'),
                        ),
                      ),
                      DropdownButtonFormField<String>(
                        value: exhaleDropdownValue,
                        decoration: const InputDecoration(labelText: '呼气音乐'),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('不播放音乐'),
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
                          label: const Text('导入本地音频'),
                        ),
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
                  child: const Text('取消'),
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
                      ),
                    );
                    Navigator.pop(
                      context,
                      preset,
                    );
                  },
                  child: const Text('保存'),
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
    await _saveData();
  }

  String? _validatePositiveSeconds(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '必填';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      return '请输入大于0的整数';
    }
    return null;
  }

  Future<void> _deletePreset(int index) async {
    if (_presets.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('至少保留一个预设')),
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
    await _saveData();
  }

  Future<void> _selectPreset(int index) async {
    setState(() {
      _selectedIndex = index;
      _timer?.cancel();
      _timer = null;
      _applySessionReset();
    });
    await _saveData();
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
            label: const Text('新建预设'),
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
                    '吸气 ${preset.inhaleSeconds}s · 呼气 ${preset.exhaleSeconds}s · 暂停 ${preset.pauseSeconds}s'),
                Text(
                    '吸气音乐: ${preset.inhaleMusic.isEmpty ? '未设置' : _audioLabel(preset.inhaleMusic)}'),
                Text(
                    '呼气音乐: ${preset.exhaleMusic.isEmpty ? '未设置' : _audioLabel(preset.exhaleMusic)}'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    FilledButton.tonal(
                      onPressed: () => _selectPreset(index),
                      child: const Text('使用此预设'),
                    ),
                    OutlinedButton(
                      onPressed: () => _openPresetEditor(
                        existing: preset,
                        index: index,
                      ),
                      child: const Text('编辑'),
                    ),
                    TextButton(
                      onPressed: () => _deletePreset(index),
                      child: const Text('删除'),
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
                    '当前预设: ${_activePreset.name}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('阶段: ${_phaseLabel(_phase)}'),
                  Text('剩余: $_remainingSeconds 秒'),
                  Text('阶段音乐: ${_phaseMusic(_phase)}'),
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
                child: const Text('开始'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _isRunning ? _pauseSession : null,
                child: const Text('暂停'),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: _resetSession,
                child: const Text('重置'),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
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
        title: const Text('呼吸练习'),
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _buildSessionTab(),
          _buildPresetTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) {
          setState(() {
            _tabIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.air),
            label: '练习',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune),
            label: '预设',
          ),
        ],
      ),
    );
  }
}
