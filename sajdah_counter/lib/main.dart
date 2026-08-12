import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

late List<CameraDescription> _cameras;

final Map<String, Map<String, String>> _translations = {
  'English': {
    'app_name': 'Rakat Counter',
    'title': 'Select Language',
    'rakat': 'RAKAT',
    'sajdah': 'SAJDAH',
    'start': 'START PRAYER',
    'stop': 'STOP',
    'tap_start': 'SELECT RAKATS & TAP START',
    'calibrating': 'CALIBRATING ENVIRONMENT...',
    'ready_dim': 'READY (DIM LIGHT MODE)',
    'ready_stand': 'READY - STAND AT MAT EDGE',
    'counted': 'SAJDAH {num} COUNTED',
    'complete': 'PRAYER COMPLETE',
    'stand_up': 'STAND UP FOR RAKAT {num}',
    'detecting_2': 'DETECTING SAJDAH 2...',
    'ready_rakat': 'RAKAT {num} - READY',
    'select_rakat': 'SELECT TOTAL RAKATS',
    'tashahhud': 'TASHAHHUD - RAKAT 3 IN {num}s',
    'chip_label': '{num} RAKAT',
  },
  'Hindi (हिंदी)': {
    'app_name': 'रक़ात काउंटर',
    'title': 'भाषा चुनें',
    'rakat': 'रक़ात',
    'sajdah': 'सजदा',
    'start': 'नमाज़ शुरू करें',
    'stop': 'रोकें',
    'tap_start': 'रक़ात चुनें और शुरू करें',
    'calibrating': 'सेटिंग हो रही है...',
    'ready_dim': 'तैयार (कम रोशनी मोड)',
    'ready_stand': 'तैयार - जायनमाज़ के किनारे खड़े हों',
    'counted': 'सजदा {num} दर्ज हुआ',
    'complete': 'नमाज़ पूरी हुई',
    'stand_up': 'रक़ात {num} के लिए खड़े हों',
    'detecting_2': 'दूसरा सजदा चेक हो रहा है...',
    'ready_rakat': 'रक़ात {num} - तैयार',
    'select_rakat': 'कुल रक़ात चुनें',
    'tashahhud': 'तशह्हुद - रक़ात 3 ({num} से.)',
    'chip_label': '{num} रक़ात',
  },
  'Arabic (العربية)': {
    'app_name': 'عداد الركعات',
    'title': 'اختر اللغة',
    'rakat': 'الركعة',
    'sajdah': 'السجدة',
    'start': 'بدء الصلاة',
    'stop': 'إيقاف',
    'tap_start': 'اختر عدد الركعات واضغط بدء',
    'calibrating': 'جاري معايرة البيئة...',
    'ready_dim': 'جاهز (وضع الإضاءة المنخفضة)',
    'ready_stand': 'جاهز - قف على طرف السجادة',
    'counted': 'تم احتساب السجدة {num}',
    'complete': 'اكتملت الصلاة',
    'stand_up': 'قم للركعة {num}',
    'detecting_2': 'جاري كشف السجدة الثانية...',
    'ready_rakat': 'الركعة {num} - جاهز',
    'select_rakat': 'اختر عدد الركعات',
    'tashahhud': 'التشهّد - الركعة الثالثة بعد {num} ثانية',
    'chip_label': '{num} ركعات',
  },
  'Urdu (اردو)': {
    'app_name': 'رکعت کاؤنٹر',
    'title': 'زبان منتخب کریں',
    'rakat': 'رکعت',
    'sajdah': 'سجدہ',
    'start': 'نماز شروع کریں',
    'stop': 'روکیں',
    'tap_start': 'رکعتیں منتخب کریں اور شروع کریں',
    'calibrating': 'سیٹنگ ہو رہی ہے...',
    'ready_dim': 'تیار (مدم روشنی)',
    'ready_stand': 'تیار - مصلے کے کنارے کھڑے ہوں',
    'counted': 'سجدہ {num} ریکارڈ ہو گیا',
    'complete': 'نماز مکمل ہو گئی',
    'stand_up': 'رکعت {num} کے لیے کھڑے ہوں',
    'detecting_2': 'دوسرا سجدہ چیک ہو رہا ہے...',
    'ready_rakat': 'رکعت {num} - تیار',
    'select_rakat': 'کل رکعتیں منتخب کریں',
    'tashahhud': 'تشہد - رکعت 3 ({num} سیکنڈ)',
    'chip_label': '{num} رکعت',
  },
  'Bengali (বাংলা)': {
    'app_name': 'রাকাত কাউন্টার',
    'title': 'ভাষা নির্বাচন করুন',
    'rakat': 'রাকাত',
    'sajdah': 'সিজদা',
    'start': 'নামাজ শুরু করুন',
    'stop': 'থামুন',
    'tap_start': 'রাকাত নির্বাচন করে শুরু করুন',
    'calibrating': 'পরিবেশ পরীক্ষা হচ্ছে...',
    'ready_dim': 'প্রস্তুত (কম আলো মোড)',
    'ready_stand': 'প্রস্তুত - জায়নামাজের প্রান্তে দাঁড়ান',
    'counted': 'সিজদা {num} গণনা করা হয়েছে',
    'complete': 'নামাজ সম্পন্ন হয়েছে',
    'stand_up': 'রাকাত {num} এর জন্য দাঁড়ান',
    'detecting_2': '২য় সিজদা পরীক্ষা করা হচ্ছে...',
    'ready_rakat': 'রাকাত {num} - প্রস্তুত',
    'select_rakat': 'মোট রাকাত নির্বাচন করুন',
    'tashahhud': 'তাশাহহুদ - ৩য় রাকাত {num} সেকেন্ডে',
    'chip_label': '{num} রাকাত',
  },
  'Turkish (Türkçe)': {
    'app_name': 'Rekat Sayacı',
    'title': 'Dil Seçin',
    'rakat': 'REKAT',
    'sajdah': 'SECDE',
    'start': 'NAMAZA BAŞLA',
    'stop': 'DURDUR',
    'tap_start': 'REKAT SEÇİN VE BAŞLAYIN',
    'calibrating': 'ÇEVRE KALİBRE EDİLİYOR...',
    'ready_dim': 'HAZIR (DÜŞÜK IŞIK MODU)',
    'ready_stand': 'HAZIR - SECCADE KENARINDA DURUN',
    'counted': 'SECDE {num} SAYILDI',
    'complete': 'NAMAZ TAMAMLANDI',
    'stand_up': 'REKAT {num} İÇİN AĞAĞA KALKIN',
    'detecting_2': '2. SECDE ALGILANIYOR...',
    'ready_rakat': 'REKAT {num} - HAZIR',
    'select_rakat': 'TOPLAM REKAT SEÇİN',
    'tashahhud': 'TEŞEHHÜD - 3. REKAT {num} sn',
    'chip_label': '{num} REKAT',
  },
  'Indonesian (Bahasa)': {
    'app_name': 'Penghitung Rakaat',
    'title': 'Pilih Bahasa',
    'rakat': 'RAKAAT',
    'sajdah': 'SUJUD',
    'start': 'MULAI SHALAT',
    'stop': 'BERHENTI',
    'tap_start': 'PILIH RAKAAT DAN TEKAN MULAI',
    'calibrating': 'MENGKALIBRASI LINGKUNGAN...',
    'ready_dim': 'SIAP (MODE CAHAYA REDUP)',
    'ready_stand': 'SIAP - BERDIRI DI TEPI SAJADAH',
    'counted': 'SUJUD {num} TERHITUNG',
    'complete': 'SHALAT SELESAI',
    'stand_up': 'BERDIRI UNTUK RAKAAT {num}',
    'detecting_2': 'MENDETEKSI SUJUD 2...',
    'ready_rakat': 'RAKAAT {num} - SIAP',
    'select_rakat': 'PILIH TOTAL RAKAAT',
    'tashahhud': 'TASHAHHUD - RAKAAT 3 DALAM {num}s',
    'chip_label': '{num} RAKAAT',
  },
  'Persian (فارسی)': {
    'app_name': 'رکعت شمار',
    'title': 'انتخاب زبان',
    'rakat': 'رکعت',
    'sajdah': 'سجده',
    'start': 'شروع نماز',
    'stop': 'توقف',
    'tap_start': 'تعداد رکعت را انتخاب و شروع کنید',
    'calibrating': 'در حال تنظیم محیط...',
    'ready_dim': 'آماده (حالت نور کم)',
    'ready_stand': 'آماده - لبه سجاده بایستید',
    'counted': 'سجده {num} ثبت شد',
    'complete': 'نماز به پایان رسید',
    'stand_up': 'برای رکعت {num} بایستید',
    'detecting_2': 'در حال شناسایی سجده دوم...',
    'ready_rakat': 'رکعت {num} - آماده',
    'select_rakat': 'انتخاب تعداد کل رکعت‌ها',
    'tashahhud': 'تشهد - رکعت ۳ در {num} ثانیه',
    'chip_label': '{num} رکعت',
  },
  'French (Français)': {
    'app_name': 'Compteur de Rakat',
    'title': 'Choisir la langue',
    'rakat': 'RAKAT',
    'sajdah': 'PROSTERNATION',
    'start': 'COMMENCER LA PRIÈRE',
    'stop': 'ARRÊTER',
    'tap_start': 'SÉLECTIONNEZ LES RAKATS ET DÉMARREZ',
    'calibrating': 'CALIBRAGE EN COURS...',
    'ready_dim': 'PRÊT (FAIBLE LUMINOSITÉ)',
    'ready_stand': 'PRÊT - DEBOUT AU BORD DU TAPIS',
    'counted': 'PROSTERNATION {num} COMPTÉE',
    'complete': 'PRIÈRE TERMINÉE',
    'stand_up': 'LEVEZ-VOUS POUR LA RAKAT {num}',
    'detecting_2': 'DÉTECTION PROSTERNATION 2...',
    'ready_rakat': 'RAKAT {num} - PRÊT',
    'select_rakat': 'SÉLECTIONNER NOMBRE DE RAKATS',
    'tashahhud': 'TASHAHHUD - RAKAT 3 DANS {num}s',
    'chip_label': '{num} RAKAT',
  },
  'Spanish (Español)': {
    'app_name': 'Contador de Rakat',
    'title': 'Seleccionar idioma',
    'rakat': 'RAKAT',
    'sajdah': 'POSTRACIÓN',
    'start': 'INICIAR ORACIÓN',
    'stop': 'DETENER',
    'tap_start': 'SELECCIONE RAKATS E INICIE',
    'calibrating': 'CALIBRANDO ENTORNO...',
    'ready_dim': 'LISTO (LUZ TENUE)',
    'ready_stand': 'LISTO - DE PIE EN EL BORDE',
    'counted': 'POSTRACIÓN {num} CONTADA',
    'complete': 'ORACIÓN COMPLETA',
    'stand_up': 'LEVÁNTESE PARA RAKAT {num}',
    'detecting_2': 'DETECTANDO POSTRACIÓN 2...',
    'ready_rakat': 'RAKAT {num} - LISTO',
    'select_rakat': 'SELECCIONAR TOTAL DE RAKATS',
    'tashahhud': 'TASHAHHUD - RAKAT 3 EN {num}s',
    'chip_label': '{num} RAKAT',
  },
  'German (Deutsch)': {
    'app_name': 'Rakat Zähler',
    'title': 'Sprache Auswählen',
    'rakat': 'RAKAT',
    'sajdah': 'SAJDAH',
    'start': 'GEBET STARTEN',
    'stop': 'STOPP',
    'tap_start': 'RAKATS WÄHLEN UND STARTEN',
    'calibrating': 'UMGEBUNG WIRD KALIBRIERT...',
    'ready_dim': 'BEREIT (SCHWACHES LICHT)',
    'ready_stand': 'BEREIT - AM MATTENRAND STEHEN',
    'counted': 'SAJDAH {num} GEZÄHLT',
    'complete': 'GEBET BEENDET',
    'stand_up': 'AUFSTEHEN FÜR RAKAT {num}',
    'detecting_2': '2. SAJDAH WIRD ERKANNT...',
    'ready_rakat': 'RAKAT {num} - BEREIT',
    'select_rakat': 'GESAMTE RAKATS WÄHLEN',
    'tashahhud': 'TASHAHHUD - RAKAT 3 IN {num}s',
    'chip_label': '{num} RAKAT',
  },
  'Russian (Русский)': {
    'app_name': 'Счетчик Ракатов',
    'title': 'Выберите язык',
    'rakat': 'РАКАТ',
    'sajdah': 'САДЖДА',
    'start': 'НАЧАТЬ МОЛИТВУ',
    'stop': 'СТОП',
    'tap_start': 'ВЫБЕРИТЕ РАКАТЫ И НАЖМИТЕ СТАРТ',
    'calibrating': 'КАЛИБРОВКА ОКРУЖЕНИЯ...',
    'ready_dim': 'ГОТОВО (СЛАБЫЙ СВЕТ)',
    'ready_stand': 'ГОТОВО - ВСТАНЬТЕ У КРАЯ КОВРИКА',
    'counted': 'САДЖДА {num} ЗАСЧИТАНА',
    'complete': 'МОЛИТВА ЗАВЕРШЕНА',
    'stand_up': 'ВСТАНЬТЕ НА РАКАТ {num}',
    'detecting_2': 'ОПРЕДЕЛЕНИЕ 2-Й САДЖДА...',
    'ready_rakat': 'РАКАТ {num} - ГОТОВО',
    'select_rakat': 'ВЫБЕРИТЕ КОЛИЧЕСТВО РАКАТОВ',
    'tashahhud': 'ТАШАХХУД - РАКАТ 3 ЧЕРЕЗ {num}с',
    'chip_label': '{num} РАКАТ',
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

  final prefs = await SharedPreferences.getInstance();
  final savedLanguage = prefs.getString('app_language');

  runApp(SajdahCounterApp(initialLanguage: savedLanguage));
}

class SajdahCounterApp extends StatelessWidget {
  final String? initialLanguage;
  const SajdahCounterApp({super.key, this.initialLanguage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rakat Counter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: initialLanguage != null
          ? CounterScreen(selectedLanguage: initialLanguage!)
          : const LanguageSelectionScreen(),
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

  Future<void> _saveLanguageAndContinue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', _selectedLanguage);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CounterScreen(selectedLanguage: _selectedLanguage),
        ),
      );
    }
  }

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
              const SizedBox(height: 20),
              const Text(
                'Rakat Counter / زبان منتخب کریں',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'اختر لغة التطبيق للبدء',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: _translations.keys.length,
                  itemBuilder: (context, index) {
                    final lang = _translations.keys.elementAt(index);
                    final isSelected = lang == _selectedLanguage;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
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
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _saveLanguageAndContinue,
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

  int _totalSajdas = 0;
  int _currentRakat = 1;
  int _currentSajdah = 0;
  int _targetRakats = 4;

  List<int>? _previousFrameBytes;
  DateTime? _sajdahStartTime;
  DateTime? _standingStartTime;
  bool _inCooldown = false;
  bool _isMotionActive = false;
  bool _awaitingStandingPosition = false;
  bool _isLowLightMode = false;

  Timer? _tashahhudTimer;
  int _tashahhudSecondsLeft = 0;

  double _baselineLuminance = -1.0;
  final List<double> _luminanceBuffer = [];

  static const Duration _requiredSajdahHold = Duration(milliseconds: 400);
  static const Duration _cooldownDuration = Duration(seconds: 2, milliseconds: 500);

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
      _standingStartTime = null;
      _isLowLightMode = false;
      _statusText = _getLabel('calibrating');
    });

    _cameraController!.startImageStream(_processCameraFrame);
  }

  void _processCameraFrame(CameraImage image) async {
    int maxSajdasForSession = _targetRakats * 2;
    if (_isProcessingFrame || !_isSessionActive || _inCooldown || _totalSajdas >= maxSajdasForSession) {
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

      if (_luminanceBuffer.length < 15) {
        _luminanceBuffer.add(currentLuminance);
        if (_luminanceBuffer.length == 15) {
          _baselineLuminance = _luminanceBuffer.reduce((a, b) => a + b) / 15;
          _isLowLightMode = _baselineLuminance <= 15.0;

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

      bool isCloseToMat = _isLowLightMode
          ? true
          : (currentLuminance < (_baselineLuminance * 0.85));

      // 1. STANDING TRANSITION GUARD
      if (_awaitingStandingPosition) {
        bool isFullySettledStanding = _isLowLightMode
            ? (frameMotionScore < 4.0)
            : (currentLuminance > (_baselineLuminance * 0.70) && frameMotionScore < 8.0);

        if (isFullySettledStanding) {
          _standingStartTime ??= DateTime.now();
          if (DateTime.now().difference(_standingStartTime!) >= const Duration(milliseconds: 500)) {
            _awaitingStandingPosition = false;
            _standingStartTime = null;
            _isMotionActive = false;
            _sajdahStartTime = null;
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
      double motionTriggerThreshold = _isLowLightMode ? 8.0 : 10.0;
      double motionSettleThreshold = _isLowLightMode ? 6.0 : 8.0;

      if (frameMotionScore > motionTriggerThreshold) {
        _isMotionActive = true;
      }

      if (_isMotionActive && frameMotionScore < motionSettleThreshold && isCloseToMat) {
        _sajdahStartTime ??= DateTime.now();

        if (DateTime.now().difference(_sajdahStartTime!) >= _requiredSajdahHold) {
          _onSajdahDetected();
        }
      } else if (!isCloseToMat && !_isLowLightMode) {
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

    int maxSajdasForSession = _targetRakats * 2;

    setState(() {
      _totalSajdas++;
      _currentSajdah = (_totalSajdas % 2 == 0) ? 2 : 1;
      
      if (_currentSajdah == 2) {
        _currentRakat = ((_totalSajdas ~/ 2) + 1).clamp(1, _targetRakats);
      } else {
        _currentRakat = (((_totalSajdas - 1) ~/ 2) + 1).clamp(1, _targetRakats);
      }

      _statusText = _getLabel('counted', param: '$_currentSajdah');
    });

    // Automatically complete and stop session when target rakats are finished
    if (_totalSajdas >= maxSajdasForSession) {
      setState(() {
        _statusText = _getLabel('complete');
      });
      _stopSession();
      return;
    }

    if (_currentSajdah == 2) {
      _awaitingStandingPosition = true;
      _standingStartTime = null;
    }

    bool isEndOfRakat2 = (_totalSajdas == 4) && (_targetRakats > 2);

    if (isEndOfRakat2) {
      _startTashahhudDelay();
    } else {
      Timer(_cooldownDuration, () {
        _inCooldown = false;
        if (mounted) {
          _isMotionActive = false;
          _sajdahStartTime = null;

          if (_currentSajdah == 2) {
            setState(() {
              _currentSajdah = 0;
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
  }

  void _startTashahhudDelay() {
    _tashahhudSecondsLeft = 20;
    _tashahhudTimer?.cancel();

    setState(() {
      _statusText = _getLabel('tashahhud', param: '$_tashahhudSecondsLeft');
    });

    _tashahhudTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _tashahhudSecondsLeft--;
        if (_tashahhudSecondsLeft > 0) {
          _statusText = _getLabel('tashahhud', param: '$_tashahhudSecondsLeft');
        } else {
          timer.cancel();
          _inCooldown = false;
          _isMotionActive = false;
          _sajdahStartTime = null;
          _currentSajdah = 0;
          _statusText = _getLabel('stand_up', param: '$_currentRakat');
        }
      });
    });
  }

  void _stopSession() {
    _tashahhudTimer?.cancel();
    WakelockPlus.disable();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();

    if (mounted) {
      setState(() {
        _isSessionActive = false;
        _cameraController = null;
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
                  '$_currentRakat / $_targetRakats',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 72,
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
            if (!_isSessionActive) ...[
              Column(
                children: [
                  Text(
                    _getLabel('select_rakat'),
                    style: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [2, 3, 4].map((count) {
                      final isSelected = _targetRakats == count;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: ChoiceChip(
                          label: Text(
                            _getLabel('chip_label', param: '$count'),
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: Colors.white,
                          backgroundColor: Colors.grey[900],
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _targetRakats = count;
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
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