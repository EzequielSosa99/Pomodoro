// =============================================================================
// EJEMPLO DE INTEGRACIÓN DE GOOGLE ADMOB EN FLUTTER
// Pomodoro Timer App
// =============================================================================

// =============================================================================
// 1. ESTRUCTURA DEL ADSERVICE (lib/services/ad_service.dart)
// =============================================================================

import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  // Singleton pattern
  static final AdService instance = AdService._();
  
  // Banner Ads
  BannerAd? _homeBanner;
  BannerAd? _calendarBanner;
  
  // Interstitial Ad
  InterstitialAd? _interstitialAd;
  bool _isInterstitialReady = false;
  
  // Métodos principales:
  // - Future<void> init()                    → Inicializa SDK
  // - Future<void> loadHomeBanner()          → Carga banner Home
  // - Future<void> loadCalendarBanner()      → Carga banner Calendar
  // - Widget getHomeBannerWidget()           → Devuelve widget banner
  // - Widget getCalendarBannerWidget()       → Devuelve widget banner
  // - Future<void> loadInterstitial()        → Precarga interstitial
  // - Future<void> showInterstitialIfReady() → Muestra interstitial
}

// =============================================================================
// 2. INICIALIZACIÓN EN MAIN (lib/main.dart)
// =============================================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ... otros servicios ...
  
  // 🎯 PASO CRÍTICO: Inicializar AdMob antes de runApp
  await AdService.instance.init();
  
  runApp(MyApp());
}

// =============================================================================
// 3. INTEGRACIÓN DE BANNER EN HOME SCREEN
// =============================================================================

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // 📱 Cargar banner al entrar a la pantalla
    Future.microtask(() => AdService.instance.loadHomeBanner());
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: /* Contenido del timer */,
          ),
          
          // 🎯 Banner en la parte inferior
          AdService.instance.getHomeBannerWidget(),
        ],
      ),
    );
  }
}

// =============================================================================
// 4. INTEGRACIÓN DE INTERSTITIAL EN POMODORO SERVICE
// =============================================================================

class PomodoroService extends ChangeNotifier {
  
  Future<void> _onTimerComplete() async {
    // Guardar modo actual (Focus, Short Break, Long Break)
    final completedMode = _state.mode;
    
    // Notificación y vibración
    await _showNotification();
    await _playVibration();
    
    // 🎯 MOSTRAR INTERSTITIAL antes de cambiar de fase
    await AdService.instance.showInterstitialIfReady(
      onClosed: () {
        // Este callback se ejecuta cuando el usuario cierra el ad
        // o si el ad no se pudo mostrar
        _proceedToNextPhase(completedMode);
      },
    );
  }
  
  void _proceedToNextPhase(PomodoroMode completedMode) {
    // Cambiar a la siguiente fase:
    // Focus → Short Break / Long Break
    // Short Break → Focus
    // Long Break → Focus
    
    _state = /* nuevo estado */;
    notifyListeners();
  }
}

// =============================================================================
// 5. FLUJO DE ANUNCIOS INTERSTITIAL
// =============================================================================

/*
  TIMELINE DEL TIMER:
  
  1. Usuario inicia Focus (25 min)
     │
     ├─ AdService precarga interstitial en background
     │
  2. Focus termina (countdown llega a 0)
     │
     ├─ _onTimerComplete() se ejecuta
     ├─ Notificación: "Focus completado"
     ├─ Vibración
     │
  3. showInterstitialIfReady() se llama
     │
     ├─ SI está listo: Muestra interstitial a pantalla completa
     │   │
     │   ├─ Usuario ve el anuncio
     │   ├─ Usuario cierra el anuncio (tap en X)
     │   └─ onClosed() callback se ejecuta
     │
     └─ SI NO está listo: onClosed() se ejecuta inmediatamente
     
  4. onClosed() → _proceedToNextPhase()
     │
     └─ Timer cambia a "Short Break" (estado idle)
     
  5. AdService recarga el siguiente interstitial en background
  
  RESULTADO: Timer nunca se bloquea, y el anuncio se muestra
             SOLO al finalizar un bloque completo.
*/

// =============================================================================
// 6. MANEJO DE ERRORES
// =============================================================================

// El AdService maneja todos los errores automáticamente:

BannerAdListener(
  onAdLoaded: (ad) {
    print('✅ Banner cargado');
    _isHomeBannerLoaded = true;
  },
  onAdFailedToLoad: (ad, error) {
    print('❌ Error: ${error.message}');
    ad.dispose();
    
    // ♻️ REINTENTO AUTOMÁTICO después de 30 segundos
    Future.delayed(Duration(seconds: 30), () {
      loadHomeBanner(); // Vuelve a intentar
    });
  },
);

// Interstitial también tiene callbacks:
InterstitialAdLoadCallback(
  onAdLoaded: (ad) {
    print('✅ Interstitial listo');
    _interstitialAd = ad;
    _isInterstitialReady = true;
  },
  onAdFailedToLoad: (error) {
    print('❌ Error al cargar interstitial');
    // ♻️ REINTENTO después de 60 segundos
    Future.delayed(Duration(seconds: 60), loadInterstitial);
  },
);

// =============================================================================
// 7. IDS DE PRUEBA VS PRODUCCIÓN
// =============================================================================

static const String _bannerAdUnitId = kDebugMode
    ? 'ca-app-pub-3940256099942544/6300978111' // ✅ Test ID (Google)
    : 'ca-app-pub-1234567890123456/0987654321'; // ⚠️ CAMBIAR por tu ID real

// En DEBUG: usa IDs de prueba automáticamente
// En RELEASE: usa IDs de producción

// =============================================================================
// 8. CONFIGURACIÓN NECESARIA
// =============================================================================

// AndroidManifest.xml:
<manifest>
  <uses-permission android:name="android.permission.INTERNET"/>
  <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
  
  <application>
    <!-- AdMob App ID -->
    <meta-data
        android:name="com.google.android.gms.ads.APPLICATION_ID"
        android:value="ca-app-pub-3940256099942544~3347511713"/>
  </application>
</manifest>

// pubspec.yaml:
dependencies:
  google_mobile_ads: ^5.2.0

// =============================================================================
// 9. TESTING
// =============================================================================

/*
  CÓMO PROBAR:
  
  1. flutter run (modo debug)
     → Usa IDs de prueba automáticamente
     
  2. Navega a Home
     → Deberías ver un banner "Test Ad" en la parte inferior
     
  3. Inicia timer y espera que termine
     → Deberías ver un interstitial de prueba
     → Al cerrar, el timer avanza a la siguiente fase
     
  4. Verifica logs en consola:
     🟢 [AdService] Inicializando Mobile Ads SDK...
     ✅ [AdService] Mobile Ads SDK inicializado correctamente
     🔄 [AdService] Cargando Home banner...
     ✅ [AdService] Home banner cargado exitosamente
     📺 [AdService] Mostrando interstitial...
     🔙 [AdService] Interstitial cerrado por el usuario
*/

// =============================================================================
// 10. CHECKLIST DE PRODUCCIÓN
// =============================================================================

/*
  ✅ ANTES DE PUBLICAR:
  
  [ ] Crear cuenta en AdMob (https://apps.admob.com/)
  [ ] Crear app en AdMob
  [ ] Crear 2 Ad Units de tipo Banner (Home y Calendar)
  [ ] Crear 1 Ad Unit de tipo Interstitial
  [ ] Copiar AdMob App ID → AndroidManifest.xml
  [ ] Copiar Ad Unit IDs → lib/services/ad_service.dart
  [ ] Probar en modo Release: flutter build apk --release
  [ ] Verificar que NO uses IDs de prueba en producción
  [ ] Esperar ~24h para que los anuncios reales se activen
  [ ] Leer políticas de AdMob: https://support.google.com/admob/answer/6128543
*/
