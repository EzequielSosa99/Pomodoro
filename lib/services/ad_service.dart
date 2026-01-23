import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Servicio centralizado para gestionar todos los anuncios de AdMob
/// Maneja banners (Home y Calendar) e interstitials (fin de bloque del timer)
class AdService extends ChangeNotifier {
  AdService._();
  static final AdService instance = AdService._();

  // ==================== Ad Unit IDs ====================

  // BANNER - IDs de prueba de Google (funcionan siempre)
  // Cuando tengas tus IDs reales de AdMob, reemplaza estos valores
  static const String _bannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111'; // Test ID de Google

  // INTERSTITIAL - IDs de prueba de Google (funcionan siempre)
  // Cuando tengas tus IDs reales de AdMob, reemplaza estos valores
  static const String _interstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712'; // Test ID de Google

  // ==================== Banner Ads ====================

  BannerAd? _homeBanner;
  BannerAd? _calendarBanner;

  bool _isHomeBannerLoaded = false;
  bool _isCalendarBannerLoaded = false;

  // ==================== Interstitial Ad ====================

  InterstitialAd? _interstitialAd;
  bool _isInterstitialReady = false;
  bool _isLoadingInterstitial = false;

  // ==================== Getters ====================

  bool get isHomeBannerLoaded => _isHomeBannerLoaded;
  bool get isCalendarBannerLoaded => _isCalendarBannerLoaded;
  bool get isInterstitialReady => _isInterstitialReady;

  // ==================== Inicialización ====================

  /// Inicializa el SDK de Google Mobile Ads y precarga anuncios
  Future<void> init() async {
    try {
      debugPrint('🟢 [AdService] Inicializando Mobile Ads SDK...');
      await MobileAds.instance.initialize();
      debugPrint('✅ [AdService] Mobile Ads SDK inicializado correctamente');

      // Precargar interstitial para tenerlo listo
      await loadInterstitial();
    } catch (e) {
      debugPrint('❌ [AdService] Error al inicializar Mobile Ads: $e');
    }
  }

  // ==================== Banner: Home Screen ====================

  /// Carga el banner para la pantalla Home (Timer)
  Future<void> loadHomeBanner() async {
    if (_isHomeBannerLoaded) {
      debugPrint('⚠️ [AdService] Home banner ya está cargado');
      return;
    }

    try {
      debugPrint('🔄 [AdService] Cargando Home banner...');

      _homeBanner = BannerAd(
        adUnitId: _bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            debugPrint('✅ [AdService] Home banner cargado exitosamente');
            _isHomeBannerLoaded = true;
            notifyListeners(); // Notificar que el banner está listo
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint(
                '❌ [AdService] Error al cargar Home banner: ${error.message}');
            debugPrint('❌ [AdService] Error code: ${error.code}');
            debugPrint('❌ [AdService] Error domain: ${error.domain}');
            _isHomeBannerLoaded = false;
            ad.dispose();
            _homeBanner = null;
            notifyListeners();

            // Reintentar después de 30 segundos
            Future.delayed(const Duration(seconds: 30), () {
              if (!_isHomeBannerLoaded) {
                debugPrint('🔄 [AdService] Reintentando cargar Home banner...');
                loadHomeBanner();
              }
            });
          },
          onAdOpened: (ad) {
            debugPrint('👆 [AdService] Home banner abierto por el usuario');
          },
          onAdClosed: (ad) {
            debugPrint('🔙 [AdService] Home banner cerrado');
          },
        ),
      );

      await _homeBanner!.load();
    } catch (e) {
      debugPrint('❌ [AdService] Excepción al cargar Home banner: $e');
      _isHomeBannerLoaded = false;
      _homeBanner = null;
    }
  }

  /// Widget para mostrar el banner del Home
  /// Devuelve un SizedBox vacío si el banner no está listo
  Widget getHomeBannerWidget() {
    if (_homeBanner == null || !_isHomeBannerLoaded) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: _homeBanner!.size.width.toDouble(),
      height: _homeBanner!.size.height.toDouble(),
      child: AdWidget(ad: _homeBanner!),
    );
  }

  // ==================== Banner: Calendar Screen ====================

  /// Carga el banner para la pantalla Calendar
  Future<void> loadCalendarBanner() async {
    if (_isCalendarBannerLoaded) {
      debugPrint('⚠️ [AdService] Calendar banner ya está cargado');
      return;
    }

    try {
      debugPrint('🔄 [AdService] Cargando Calendar banner...');

      _calendarBanner = BannerAd(
        adUnitId: _bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            debugPrint('✅ [AdService] Calendar banner cargado exitosamente');
            _isCalendarBannerLoaded = true;
            notifyListeners(); // Notificar que el banner está listo
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint(
                '❌ [AdService] Error al cargar Calendar banner: ${error.message}');
            debugPrint('❌ [AdService] Error code: ${error.code}');
            debugPrint('❌ [AdService] Error domain: ${error.domain}');
            _isCalendarBannerLoaded = false;
            ad.dispose();
            _calendarBanner = null;
            notifyListeners();

            // Reintentar después de 30 segundos
            Future.delayed(const Duration(seconds: 30), () {
              if (!_isCalendarBannerLoaded) {
                debugPrint(
                    '🔄 [AdService] Reintentando cargar Calendar banner...');
                loadCalendarBanner();
              }
            });
          },
          onAdOpened: (ad) {
            debugPrint('👆 [AdService] Calendar banner abierto por el usuario');
          },
          onAdClosed: (ad) {
            debugPrint('🔙 [AdService] Calendar banner cerrado');
          },
        ),
      );

      await _calendarBanner!.load();
    } catch (e) {
      debugPrint('❌ [AdService] Excepción al cargar Calendar banner: $e');
      _isCalendarBannerLoaded = false;
      _calendarBanner = null;
    }
  }

  /// Widget para mostrar el banner del Calendar
  /// Devuelve un SizedBox vacío si el banner no está listo
  Widget getCalendarBannerWidget() {
    if (_calendarBanner == null || !_isCalendarBannerLoaded) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: _calendarBanner!.size.width.toDouble(),
      height: _calendarBanner!.size.height.toDouble(),
      child: AdWidget(ad: _calendarBanner!),
    );
  }

  // ==================== Interstitial Ad ====================

  /// Carga un anuncio interstitial para mostrarlo al finalizar un bloque del timer
  Future<void> loadInterstitial() async {
    if (_isLoadingInterstitial) {
      debugPrint('⚠️ [AdService] Ya se está cargando un interstitial');
      return;
    }

    if (_isInterstitialReady) {
      debugPrint('⚠️ [AdService] Interstitial ya está listo');
      return;
    }

    _isLoadingInterstitial = true;
    debugPrint('🔄 [AdService] Cargando interstitial...');

    try {
      await InterstitialAd.load(
        adUnitId: _interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('✅ [AdService] Interstitial cargado exitosamente');
            _interstitialAd = ad;
            _isInterstitialReady = true;
            _isLoadingInterstitial = false;

            // Configurar callbacks de pantalla completa
            _interstitialAd!.fullScreenContentCallback =
                FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {
                debugPrint('📺 [AdService] Interstitial mostrado');
              },
              onAdDismissedFullScreenContent: (ad) {
                debugPrint(
                    '🔙 [AdService] Interstitial cerrado por el usuario');
                ad.dispose();
                _interstitialAd = null;
                _isInterstitialReady = false;

                // Precargar el siguiente interstitial
                loadInterstitial();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint(
                    '❌ [AdService] Error al mostrar interstitial: ${error.message}');
                ad.dispose();
                _interstitialAd = null;
                _isInterstitialReady = false;

                // Reintentar carga
                loadInterstitial();
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint(
                '❌ [AdService] Error al cargar interstitial: ${error.message}');
            _isInterstitialReady = false;
            _isLoadingInterstitial = false;
            _interstitialAd = null;

            // Reintentar después de 60 segundos
            Future.delayed(const Duration(seconds: 60), () {
              if (!_isInterstitialReady) {
                debugPrint(
                    '🔄 [AdService] Reintentando cargar interstitial...');
                loadInterstitial();
              }
            });
          },
        ),
      );
    } catch (e) {
      debugPrint('❌ [AdService] Excepción al cargar interstitial: $e');
      _isLoadingInterstitial = false;
      _isInterstitialReady = false;
      _interstitialAd = null;
    }
  }

  /// Muestra el interstitial si está listo
  /// [onClosed] se ejecuta cuando el anuncio se cierra o si no se puede mostrar
  Future<void> showInterstitialIfReady({VoidCallback? onClosed}) async {
    if (!_isInterstitialReady || _interstitialAd == null) {
      debugPrint(
          '⚠️ [AdService] Interstitial no está listo. Continuando sin mostrar anuncio...');
      onClosed?.call();
      return;
    }

    try {
      debugPrint('📺 [AdService] Mostrando interstitial...');

      // Configurar callback para cuando se cierre
      final originalCallback = _interstitialAd!.fullScreenContentCallback;
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent:
            originalCallback?.onAdShowedFullScreenContent,
        onAdDismissedFullScreenContent: (ad) {
          originalCallback?.onAdDismissedFullScreenContent?.call(ad);
          onClosed?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          originalCallback?.onAdFailedToShowFullScreenContent?.call(ad, error);
          onClosed?.call();
        },
      );

      await _interstitialAd!.show();
      _isInterstitialReady = false;
    } catch (e) {
      debugPrint('❌ [AdService] Excepción al mostrar interstitial: $e');
      onClosed?.call();
    }
  }

  // ==================== Limpieza ====================

  /// Libera todos los recursos de banners
  void disposeBanners() {
    debugPrint('🧹 [AdService] Liberando banners...');

    _homeBanner?.dispose();
    _homeBanner = null;
    _isHomeBannerLoaded = false;

    _calendarBanner?.dispose();
    _calendarBanner = null;
    _isCalendarBannerLoaded = false;
  }

  /// Libera el interstitial actual
  void disposeInterstitial() {
    debugPrint('🧹 [AdService] Liberando interstitial...');
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialReady = false;
  }

  /// Libera todos los recursos
  void dispose() {
    debugPrint('🧹 [AdService] Liberando todos los recursos...');
    disposeBanners();
    disposeInterstitial();
  }
}
