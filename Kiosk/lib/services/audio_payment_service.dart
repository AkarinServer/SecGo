import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart';

class AudioPaymentService {
  OnlineRecognizer? _recognizer;
  OnlineStream? _stream;
  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _micSubscription;

  final StreamController<double> _amountController =
      StreamController<double>.broadcast();
  final StreamController<String> _logController =
      StreamController<String>.broadcast();

  Stream<double> get amountStream => _amountController.stream;
  Stream<String> get logStream => _logController.stream;

  bool _isListening = false;
  bool _isInitialized = false;

  int _wavBytesProcessed = 0;
  int _chunkCount = 0;
  String _lastRecognizedText = '';
  DateTime _lastLevelLogAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _expectWavHeader = false;

  void _log(String message) {
    debugPrint(message);
    _logController.add(message);
  }

  Future<void> init() async {
    if (_isInitialized) return;

    final status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }

    initBindings();
    await _ensureModelFiles();

    final appDir = await getApplicationDocumentsDirectory();
    final modelDir = Directory('${appDir.path}/models');

    final config = OnlineRecognizerConfig(
      model: OnlineModelConfig(
        transducer: OnlineTransducerModelConfig(
          encoder: '${modelDir.path}/encoder-epoch-99-avg-1.int8.onnx',
          decoder: '${modelDir.path}/decoder-epoch-99-avg-1.int8.onnx',
          joiner: '${modelDir.path}/joiner-epoch-99-avg-1.int8.onnx',
        ),
        tokens: '${modelDir.path}/tokens.txt',
        numThreads: 2,
        debug: true,
        modelType: 'zipformer',
      ),
      decodingMethod: 'modified_beam_search',
      maxActivePaths: 4,
      enableEndpoint: true,
      rule1MinTrailingSilence: 1.2,
      rule2MinTrailingSilence: 0.8,
      rule3MinUtteranceLength: 6.0,
    );

    _recognizer = OnlineRecognizer(config);
    _recorder = AudioRecorder();
    final recognizer = _recognizer!;
    final hotwords =
        '支付宝 到账 到帐 支付宝到账 元 0 1 2 3 4 5 6 7 8 9 十 一 二 三 四 五 六 七 八 九 零';
    try {
      final s = recognizer.createStream(hotwords: hotwords);
      if (s.ptr == nullptr) {
        _log('AudioPaymentService: Hotwords stream is nullptr, fallback');
        _stream = recognizer.createStream();
      } else {
        _stream = s;
      }
    } catch (e) {
      _log('AudioPaymentService: createStream(hotwords) failed: $e');
      _stream = recognizer.createStream();
    }
    _isInitialized = true;
    _log('AudioPaymentService: Initialized');
  }

  Future<void> startListening() async {
    if (_isListening) return;
    await init();

    final recognizer = _recognizer;
    final stream = _stream;
    final recorder = _recorder;
    if (recognizer == null || stream == null || recorder == null) {
      _log('AudioPaymentService: Missing recognizer/stream/recorder');
      return;
    }

    if (!await recorder.hasPermission()) {
      _log('AudioPaymentService: Microphone permission not granted');
      return;
    }

    _wavBytesProcessed = 0;
    _chunkCount = 0;
    _lastRecognizedText = '';

    Stream<Uint8List> micStream;
    try {
      _expectWavHeader = false;
      micStream = await recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
          autoGain: true,
          androidConfig: AndroidRecordConfig(
            audioSource: AndroidAudioSource.unprocessed,
          ),
          streamBufferSize: 4096,
        ),
      );
    } catch (e) {
      _log('AudioPaymentService: startStream failed: $e');
      rethrow;
    }

    _isListening = true;
    _log('AudioPaymentService: Started listening');

    _micSubscription = micStream.listen((Uint8List bytes) {
      final pcmBytes = _stripWavHeaderIfNeeded(bytes);
      if (pcmBytes.isEmpty) return;

      final floatSamples = _pcm16leToFloat32(pcmBytes);
      _maybeLogInputLevel(floatSamples);

      stream.acceptWaveform(samples: floatSamples, sampleRate: 16000);

      while (recognizer.isReady(stream)) {
        recognizer.decode(stream);
        final result = recognizer.getResult(stream);
        final text = result.text.trim();
        if (text.isNotEmpty && text != _lastRecognizedText) {
          _lastRecognizedText = text;
          _log('AudioPaymentService: Recognized="$text"');
          _processText(text);
        }
      }

      if (recognizer.isEndpoint(stream)) {
        recognizer.reset(stream);
        _lastRecognizedText = '';
        _log('AudioPaymentService: Endpoint');
      }
    }, onError: (Object e) {
      _log('AudioPaymentService: Mic stream error: $e');
    }, onDone: () {
      _log('AudioPaymentService: Mic stream done');
    });
  }

  void stopListening() {
    if (!_isListening) return;
    _micSubscription?.cancel();
    _micSubscription = null;
    _recorder?.stop();
    _isListening = false;
    _log('AudioPaymentService: Stopped listening');
  }

  void dispose() {
    stopListening();
    _recorder?.dispose();
    _recorder = null;
    _stream?.free();
    _stream = null;
    _recognizer?.free();
    _recognizer = null;
    _amountController.close();
    _logController.close();
  }

  Uint8List _stripWavHeaderIfNeeded(Uint8List bytes) {
    if (!_expectWavHeader) return bytes;

    if (_looksLikeWavHeader(bytes)) {
      if (bytes.length <= 44) return Uint8List(0);
      return bytes.sublist(44);
    }

    if (_wavBytesProcessed >= 44) {
      _wavBytesProcessed += bytes.length;
      return bytes;
    }

    final remaining = 44 - _wavBytesProcessed;
    if (bytes.length <= remaining) {
      _wavBytesProcessed += bytes.length;
      return Uint8List(0);
    }

    _wavBytesProcessed += remaining;
    final sliced = bytes.sublist(remaining);
    _wavBytesProcessed += sliced.length;
    return sliced;
  }

  bool _looksLikeWavHeader(Uint8List bytes) {
    if (bytes.length < 12) return false;
    return bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x41 &&
        bytes[10] == 0x56 &&
        bytes[11] == 0x45;
  }

  Float32List _pcm16leToFloat32(Uint8List bytes) {
    final sampleCount = bytes.length ~/ 2;
    final floats = Float32List(sampleCount);
    final data = ByteData.sublistView(bytes);
    for (int i = 0; i < sampleCount; i++) {
      final v = data.getInt16(i * 2, Endian.little);
      floats[i] = v / 32768.0;
    }
    return floats;
  }

  void _maybeLogInputLevel(Float32List samples) {
    _chunkCount++;
    if (_chunkCount == 1) {
      _log('AudioPaymentService: First PCM chunk samples=${samples.length}');
    }
    if (_chunkCount % 6 != 0) return;

    double sumSq = 0;
    double maxAbs = 0;
    for (final v in samples) {
      final a = v.abs();
      if (a > maxAbs) maxAbs = a;
      sumSq += v * v;
    }
    final rms = samples.isEmpty ? 0.0 : math.sqrt(sumSq / samples.length);
    final now = DateTime.now();
    if (now.difference(_lastLevelLogAt).inMilliseconds < 800) return;
    _lastLevelLogAt = now;
    _log('AudioPaymentService: Mic level rms=$rms max=$maxAbs');
  }

  void _processText(String text) {
    final amount = parseAlipayAmount(text);
    if (amount == null) {
      _log('AudioPaymentService: No amount parsed');
      return;
    }
    _log('AudioPaymentService: Detected amount $amount');
    _amountController.add(amount);
  }

  double? parseAlipayAmount(String text) {
    final normalized = _normalizeRecognitionText(text);
    if (!normalized.contains('到账')) return null;

    final afterKeyword = normalized.contains('到账')
        ? normalized.split('到账').last
        : normalized;

    final arabic = _parseArabicAmount(afterKeyword);
    if (arabic != null) return arabic;

    final chinese = _parseChineseAmount(afterKeyword);
    if (chinese != null) return chinese;

    final fallbackArabic = _parseArabicAmount(normalized);
    if (fallbackArabic != null) return fallbackArabic;

    final fallbackChinese = _parseChineseAmount(normalized);
    if (fallbackChinese != null) return fallbackChinese;

    return null;
  }

  String _normalizeRecognitionText(String text) {
    var s = text.trim();
    s = s.replaceAll('到帐', '到账');
    s = s.replaceAll('點', '点');
    s = s.replaceAll('点', '.');
    s = s.replaceAll('元', '');
    s = s.replaceAll(RegExp(r'\s+'), '');

    s = s
        .replaceAll('０', '0')
        .replaceAll('１', '1')
        .replaceAll('２', '2')
        .replaceAll('３', '3')
        .replaceAll('４', '4')
        .replaceAll('５', '5')
        .replaceAll('６', '6')
        .replaceAll('７', '7')
        .replaceAll('８', '8')
        .replaceAll('９', '9');

    s = s.replaceAll('O', '0').replaceAll('o', '0');
    s = s.replaceAll('I', '1').replaceAll('l', '1');

    return s;
  }

  double? _parseArabicAmount(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9\.\s]'), '');
    final condensed = cleaned.replaceAll(RegExp(r'\s+'), '');
    final match = RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(condensed);
    if (match == null) return null;
    final s = match.group(1);
    if (s == null) return null;
    final v = double.tryParse(s);
    if (v == null) return null;
    if (v <= 0 || v >= 100000) return null;
    return v;
  }

  double? _parseChineseAmount(String text) {
    final match = RegExp(r'([零〇一二三四五六七八九十百千两壹贰叁肆伍陆柒捌玖拾佰仟\.]+)')
        .firstMatch(text);
    if (match == null) return null;
    final s = match.group(1);
    if (s == null) return null;
    return _parseChineseNumber(s);
  }

  double? _parseChineseNumber(String s) {
    final cleaned = s.replaceAll('元', '').trim();
    if (cleaned.isEmpty) return null;

    final parts = cleaned.split('.');
    final intPart = parts[0];
    final fracPart = parts.length > 1 ? parts[1] : '';

    final intValue = _parseChineseInt(intPart);
    if (intValue == null) return null;

    if (fracPart.isEmpty) return intValue.toDouble();

    final fracDigits = StringBuffer();
    for (final ch in fracPart.split('')) {
      final d = _chineseDigit(ch);
      if (d == null) break;
      fracDigits.write(d);
    }
    if (fracDigits.isEmpty) return intValue.toDouble();

    final frac = double.tryParse('0.${fracDigits.toString()}');
    if (frac == null) return intValue.toDouble();
    return intValue + frac;
  }

  int? _parseChineseInt(String s) {
    final chars = s.split('');
    if (chars.isEmpty) return null;

    int total = 0;
    int current = 0;

    for (final ch in chars) {
      if (ch == '十' || ch == '拾') {
        if (current == 0) current = 1;
        total += current * 10;
        current = 0;
        continue;
      }
      if (ch == '百' || ch == '佰') {
        if (current == 0) current = 1;
        total += current * 100;
        current = 0;
        continue;
      }
      if (ch == '千' || ch == '仟') {
        if (current == 0) current = 1;
        total += current * 1000;
        current = 0;
        continue;
      }

      final d = _chineseDigit(ch);
      if (d == null) return null;
      current = d;
    }

    return total + current;
  }

  int? _chineseDigit(String ch) {
    switch (ch) {
      case '〇':
      case '零':
      case '０':
        return 0;
      case '一':
      case '壹':
        return 1;
      case '二':
      case '两':
      case '贰':
        return 2;
      case '三':
      case '叁':
        return 3;
      case '四':
      case '肆':
        return 4;
      case '五':
      case '伍':
        return 5;
      case '六':
      case '陆':
        return 6;
      case '七':
      case '柒':
        return 7;
      case '八':
      case '捌':
        return 8;
      case '九':
      case '玖':
        return 9;
    }
    return null;
  }

  Future<void> _ensureModelFiles() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelDir = Directory('${appDir.path}/models');
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }

    final expectedLengths = <String, int>{
      'tokens.txt': 48697,
      'encoder-epoch-99-avg-1.int8.onnx': 21621684,
      'decoder-epoch-99-avg-1.int8.onnx': 1888682,
      'joiner-epoch-99-avg-1.int8.onnx': 1795562,
    };

    final assets = <String>[
      'tokens.txt',
      'encoder-epoch-99-avg-1.int8.onnx',
      'decoder-epoch-99-avg-1.int8.onnx',
      'joiner-epoch-99-avg-1.int8.onnx',
    ];

    for (final assetName in assets) {
      final file = File('${modelDir.path}/$assetName');
      if (await file.exists()) {
        final expected = expectedLengths[assetName];
        if (expected == null) continue;
        try {
          final currentLen = await file.length();
          if (currentLen == expected) continue;
        } catch (_) {
          // Fall through to re-copy.
        }
      }

      final data = await rootBundle.load('assets/models/$assetName');
      final bytes = data.buffer.asUint8List();
      await file.writeAsBytes(bytes, flush: true);
      _log('AudioPaymentService: Copied $assetName (${bytes.length} bytes)');
    }
  }
}
