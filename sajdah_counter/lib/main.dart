import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:permission_handler/permission_handler.dart';

late List<CameraDescription> _cameras;

// Language Translations Map
final Map<String, Map<String, String>> _translations = {
  'English': {
    'title': 'Select Language',
    'rakat': 'RAKAT',
    'sajdah': 'SAJDAH',
    'start': 'START PRAYER',
    'stop': 'STOP',
    'tap_start': 'TAP START TO BEGIN',
    'calibrating': 'CALIBRATING ENVIRONMENT...',
    'ready_dim': 'READY (DIM LIGHT MODE)',
    'ready_stand': 'READY - STAND AT MAT EDGE',
    'counted': 'SAJDAH {num} COUNTED',
    'complete': 'PRAYER COMPLETE',
    'stand_up': 'STAND UP FOR RAKAT {num}',
    'detecting_2': 'DETECTING SAJDAH 2...',
    'ready_rakat': 'RAKAT {num} - READY',
  },
  'Arabic (العربية)': {
    'title': 'اختر اللغة',
    'rakat': 'الركعة',
    'sajdah': 'السجدة',
    'start': 'بدء الصلاة',
    'stop': 'إيقاف',
    'tap_start': 'اضغط ابدأ للبدء',
    'calibrating': 'جاري معايرة البيئة...',
    'ready_dim': 'جاهز (وضع الإضاءة المنخفضة)',
    'ready_stand': 'جاهز - قف على طرف السجادة',
    'counted': 'تم احتساب السجدة {num}',
    'complete': 'اكتملت الصلاة',
    'stand_up': 'قم للركعة {num}',
    'detecting_2': 'جاري كشف السجدة الثانية...',
    'ready_rakat': 'الركعة {num} - جاهز',
  },
  'Urdu (اردو)': {
    'title': 'زبان منتخب کریں',
    'rakat': 'رکعت',
    'sajdah': 'سجدہ',
    'start': 'نماز شروع کریں',
    'stop': 'روکیں',
    'tap_start': 'شروع کرنے کے لیے دبائیں',
    'calibrating': 'سیٹنگ ہو رہی ہے...',
    'ready_dim': 'تیار (مدم روشنی)',
    'ready_stand': 'تیار - مصصلے کے کنارے کھڑے ہوں',
    'counted': 'سجدہ {num} ریکارڈ ہو گیا',
    'complete': 'نماز مکمل ہو گئی',
    'stand_up': 'رکعت {num} کے لیے کھڑے ہوں',
    'detecting_2': 'دوسرا سجدہ چیک ہو رہا ہے...',
    'ready_rakat': 'رکعت {num} - تیار',
  },
  'Turkish (Türkçe)': {
    'title': 'Dil Seçين',
    'rakat': 'REKAT',
    'sajdah': 'SECDE',
    'start': 'NAMAZA BAŞLA',
    'stop': 'DURDUR',
    'tap_start': 'BAŞLAMAK İÇİN BAŞLA\'YA BASIN',
    'calibrating': 'ÇEVRE KALİBRE EDİLİYOR...',
    'ready_dim': 'HAZIR (DÜŞÜK IŞIK MODU)',
    'ready_stand': 'HAZIR - SECCADE KENARINDA DURUN',
    'counted': 'SECDE {num} SAYILDI',
    'complete': 'NAMAZ TAMAMLANDI',
    'stand_up': 'REKAT {num} İÇİN AĞAĞA KALKIN',
    'detecting_2': '2. SECDE ALGILANIYOR...',
    'ready_rakat': 'REKAT {num} - HAZIR',
  },
  'Indonesian (Bahasa)': {
    'title': 'Pilih Bahasa',
    'rakat': 'RAKAAT',
    'sajdah': 'SUJUD',
    'start': 'MULAI SHALAT',
    'stop': 'BERHENTI',
    'tap_start': 'TEKAN MULAI UNTUK MEMULAI',
    'calibrating': 'MENGKALIBRASI LINGKUNGAN...',
    'ready_dim': 'SIAP (MODE CAHAYA REDUP)',
    'ready_stand': 'SIAP - BERDIRI DI TEPI SAJADAH',
    'counted': 'SUJUD {num} TERHITUNG',
    'complete': 'SHALAT SELESAI',
    'stand_up': 'BERDIRI UNTUK RAKAAT {num}',
    'detecting_2': 'MENDETEKSI SUJUD 2...',
    'ready_rakat': 'RAKAAT {num} - SIAP',
  },
  'French (Français)': {
    'title': 'Choisir la langue',
    'rakat': 'RAKAT',
    'sajdah': 'PROSTERNATION',
    'start': 'COMMENCER LA PRIÈRE',
    'stop': 'ARRÊTER',
    'tap_start': 'APPUYEZ SUR DÉMARRER',
    'calibrating': 'CALIBRAGE EN COURS...',
    'ready_dim': 'PRÊT (FAIBLE LUMINOSITÉ)',
    'ready_stand': 'PRÊT - DEBOUT AU BORD DU TAPIS',
    'counted': 'PROSTERNATION {num} COMPTÉE',
    'complete': 'PRIÈRE TERMINÉE',
    'stand_up': 'LEVEZ-VOUS POUR LA RAKAT {num}',
    'detecting_2': 'DÉTECTION PROSTERNATION 2...',
    'ready_rakat': 'RAKAT {num} - PRÊT',
  },
  'Spanish (Español)': {
    'title': 'Seleccionar idioma',
    'rakat': 'RAKAT',
    'sajdah': 'POSTRACIÓN',
    'start': 'INICIAR ORACIÓN',
    'stop': 'DETENER',
    'tap_start': 'PRESIONE INICIAR',
    'calibrating': 'CALIBRANDO ENTORNO...',
    'ready_dim': 'LISTO (LUZ TENUE)',
    'ready_stand': 'LISTO - DE PIE EN EL BORDE',
    'counted': 'POSTRACIÓN {num} CONTADA',
    'complete': 'ORACIÓN COMPLETA',
    'stand_up': 'LEVÁNTESE PARA RAKAT {num}',
    'detecting_2': 'DETECTANDO POSTRACIÓN 2...',
    'ready_rakat': 'RAKAT {num} - LISTO',
  },
};

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  try {
    _cameras = await availableCameras();
  } catch (e) {
    _cameras = [];
  }
  runApp(const SajdahCounterApp());
}

class SajdahCounterApp extends StatelessWidget {
  const SajdahCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const LanguageSelectionScreen(),
    );
  }
}

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              const Text(
                'Select Language',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'اختر لغة التطبيق للبدء',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: ListView.builder(
                  itemCount: _translations.keys.length,
                  itemBuilder: (context, index) {
                    final lang = _translations.keys.elementAt(index);
                    final isSelected = lang == _selectedLanguage;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withOpacity(0.15) : Colors.grey[900],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: ListTile(
                        title: Text(
                          lang,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[400],
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Colors.white)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedLanguage = lang;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CounterScreen(selectedLanguage: _selectedLanguage),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('CONTINUE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CounterScreen extends StatefulWidget {
  final String selectedLanguage;
  const CounterScreen({super.key, required this.selectedLanguage});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  CameraController? _cameraController;

  bool _isProcessingFrame = false;
  bool _isSessionActive = false;
  String _statusText = "";

  // Counter Variables
  int _totalSajdas = 0;
  int _currentRakat = 1;
  int _currentSajdah = 0;

  // Detection & Motion Memory
  List<int>? _previousFrameBytes;
  DateTime? _sajdahStartTime;
  DateTime? _standingStartTime;
  bool _inCooldown = false;
  bool _isMotionActive = false;
  bool _awaitingStandingPosition = false;
  bool _isLowLightMode = false;

  double _baselineLuminance = -1.0;
  final List<double> _luminanceBuffer = [];

  static const Duration _requiredSajdahHold = Duration(milliseconds: 700);
  static const Duration _requiredStandingHold = Duration(milliseconds: 900);
  static const Duration _cooldownDuration = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _statusText = _getLabel('tap_start');
    _checkPermissionOnStart();
  }

  String _getLabel(String key, {String? param}) {
    final langMap = _translations[widget.selectedLanguage] ?? _translations['English']!;
    String value = langMap[key] ?? _translations['English']![key] ?? '';
    if (param != null) {
      value = value.replaceAll('{num}', param);
    }
    return value;
  }

  Future<void> _checkPermissionOnStart() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      await Permission.camera.request();
    }
  }

  Future<void> _startSession() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
      if (!status.isGranted) {
        _showErrorSnackbar("Camera permission is required to detect Sajdah.");
        return;
      }
    }

    if (_cameras.isEmpty) {
      try {
        _cameras = await availableCameras();
      } catch (e) {
        _showErrorSnackbar("No camera detected on this device.");
        return;
      }
    }

    await WakelockPlus.enable();

    final frontCamera = _cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    try {
      await _cameraController!.initialize();
    } on CameraException catch (e) {
      _showErrorSnackbar("Camera error: ${e.description}");
      return;
    }

    setState(() {
      _isSessionActive = true;
      _totalSajdas = 0;
      _currentRakat = 1;
      _currentSajdah = 0;
      _previousFrameBytes = null;
      _baselineLuminance = -1.0;
      _luminanceBuffer.clear();
      _awaitingStandingPosition = false;
      _isLowLightMode = false;
      _statusText = _getLabel('calibrating');
    });

    _cameraController!.startImageStream(_processCameraFrame);
  }

  void _processCameraFrame(CameraImage image) async {
    if (_isProcessingFrame || !_isSessionActive || _inCooldown || _totalSajdas >= 8) {
      return;
    }

    _isProcessingFrame = true;

    try {
      final plane = image.planes.first;
      final bytes = plane.bytes;

      int step = 35;
      List<int> currentSampled = [];
      double totalBrightness = 0;
      for (int i = 0; i < bytes.length; i += step) {
        currentSampled.add(bytes[i]);
        totalBrightness += bytes[i];
      }
      double currentLuminance = totalBrightness / currentSampled.length;

      if (_luminanceBuffer.length < 12) {
        _luminanceBuffer.add(currentLuminance);
        if (_luminanceBuffer.length == 12) {
          _baselineLuminance = _luminanceBuffer.reduce((a, b) => a + b) / 12;
          _isLowLightMode = _baselineLuminance <= 8.0;

          if (mounted) {
            setState(() {
              _statusText = _isLowLightMode
                  ? _getLabel('ready_dim')
                  : _getLabel('ready_stand');
            });
          }
        }
        return;
      }

      if (_previousFrameBytes == null) {
        _previousFrameBytes = currentSampled;
        return;
      }

      double totalDelta = 0;
      for (int i = 0; i < currentSampled.length; i++) {
        totalDelta += (currentSampled[i] - _previousFrameBytes![i]).abs();
      }
      double frameMotionScore = totalDelta / currentSampled.length;
      _previousFrameBytes = currentSampled;

      bool isCloseToMat;
      if (_isLowLightMode) {
        isCloseToMat = true;
      } else {
        isCloseToMat = currentLuminance < (_baselineLuminance * 0.75);
      }

      // 1. STANDING UP RECOVERY CHECK
      if (_awaitingStandingPosition) {
        bool isStandingCondition = _isLowLightMode
            ? (frameMotionScore < 10.0)
            : (currentLuminance > (_baselineLuminance * 0.70) && frameMotionScore < 12.0);

        if (isStandingCondition) {
          _standingStartTime ??= DateTime.now();
          if (DateTime.now().difference(_standingStartTime!) >= _requiredStandingHold) {
            _awaitingStandingPosition = false;
            _standingStartTime = null;
            if (mounted) {
              setState(() {
                _statusText = _getLabel('ready_rakat', param: '$_currentRakat');
              });
            }
          }
        } else {
          _standingStartTime = null;
        }
        return;
      }

      // 2. SAJDAH MOTION SEQUENCE DETECTION
      double motionTriggerThreshold = _isLowLightMode ? 14.0 : 16.0;
      double motionSettleThreshold = _isLowLightMode ? 9.0 : 10.0;

      if (frameMotionScore > motionTriggerThreshold) {
        _isMotionActive = true;
      }

      if (_isMotionActive && frameMotionScore < motionSettleThreshold && isCloseToMat) {
        _sajdahStartTime ??= DateTime.now();

        if (DateTime.now().difference(_sajdahStartTime!) >= _requiredSajdahHold) {
          _onSajdahDetected();
        }
      } else if (frameMotionScore > (motionTriggerThreshold + 8.0) || (!isCloseToMat && !_isLowLightMode)) {
        _sajdahStartTime = null;
      }
    } catch (e) {
      debugPrint("Frame processing error: $e");
    } finally {
      _isProcessingFrame = false;
    }
  }

  void _onSajdahDetected() {
    _sajdahStartTime = null;
    _isMotionActive = false;
    _inCooldown = true;

    setState(() {
      _totalSajdas++;
      _currentSajdah = (_totalSajdas % 2 == 0) ? 2 : 1;
      
      // IMMEDIATE RAKAT PROGRESSION FIX:
      // Rakat increments immediately when 2nd Sajdah is registered
      _currentRakat = ((_totalSajdas - 1) ~/ 2) + 1;
      
      _statusText = _getLabel('counted', param: '$_currentSajdah');
    });

    if (_totalSajdas >= 8) {
      setState(() {
        _statusText = _getLabel('complete');
      });
      _stopSession();
      return;
    }

    if (_currentSajdah == 2) {
      _awaitingStandingPosition = true;
    }

    Timer(_cooldownDuration, () {
      _inCooldown = false;
      if (mounted) {
        if (_awaitingStandingPosition) {
          setState(() {
            _currentSajdah = 0;
            // Rakat increment is already active and displayed
            _statusText = _getLabel('stand_up', param: '$_currentRakat');
          });
        } else {
          setState(() {
            _statusText = _getLabel('detecting_2');
          });
        }
      }
    });
  }

  void _stopSession() {
    WakelockPlus.disable();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();

    if (mounted) {
      setState(() {
        _isSessionActive = false;
        _cameraController = null;
        _statusText = _getLabel('tap_start');
      });
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  void dispose() {
    _stopSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: IconButton(
                  icon: const Icon(Icons.language, color: Colors.white),
                  onPressed: () {
                    _stopSession();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LanguageSelectionScreen()),
                    );
                  },
                ),
              ),
            ),
            Column(
              children: [
                Text(
                  _getLabel('rakat'),
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.0,
                  ),
                ),
                Text(
                  '$_currentRakat',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 120,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Text(
                  _getLabel('sajdah'),
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$_currentSajdah',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                _statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isSessionActive)
                  ElevatedButton(
                    onPressed: _startSession,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(_getLabel('start'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  )
                else
                  OutlinedButton(
                    onPressed: _stopSession,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(_getLabel('stop'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}