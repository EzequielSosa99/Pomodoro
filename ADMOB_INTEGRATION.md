# Google AdMob Integration - Pomodoro Timer

## 📱 Configuración de AdMob

### 1. Crear Cuenta y App en AdMob

1. Ve a [Google AdMob Console](https://apps.admob.com/)
2. Crea una nueva app o selecciona una existente
3. Obtén tu **AdMob App ID** (formato: `ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY`)

### 2. Crear Ad Units

Crea 3 Ad Units en tu app de AdMob:

1. **Banner - Home Screen**
   - Tipo: Banner
   - Nombre: "Home Timer Banner"
   - Copia el **Ad Unit ID** (formato: `ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY`)

2. **Banner - Calendar Screen**
   - Tipo: Banner
   - Nombre: "Calendar Banner"
   - Copia el **Ad Unit ID**

3. **Interstitial - Timer Completion**
   - Tipo: Interstitial
   - Nombre: "Phase Completion Interstitial"
   - Copia el **Ad Unit ID**

## 🔧 Configuración de Producción

### Paso 1: Actualizar AndroidManifest.xml

Edita `android/app/src/main/AndroidManifest.xml` y reemplaza el App ID de prueba:

```xml
<!-- Reemplazar este meta-data con tu AdMob App ID real -->
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY"/>
```

### Paso 2: Actualizar AdService con IDs Reales

Edita `lib/services/ad_service.dart` y reemplaza los IDs de producción:

```dart
// BANNER - Reemplazar con tu Ad Unit ID real
static const String _bannerAdUnitId = kDebugMode
    ? 'ca-app-pub-3940256099942544/6300978111' // Test ID (dejar como está)
    : 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY'; // ⚠️ REEMPLAZAR CON TU ID REAL

// INTERSTITIAL - Reemplazar con tu Ad Unit ID real
static const String _interstitialAdUnitId = kDebugMode
    ? 'ca-app-pub-3940256099942544/1033173712' // Test ID (dejar como está)
    : 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY'; // ⚠️ REEMPLAZAR CON TU ID REAL
```

## 🎯 Funcionamiento de los Anuncios

### Banners

- **Home Screen (Timer)**: Banner fijo en la parte inferior
  - Se carga automáticamente al abrir la pantalla
  - Reintenta cargar cada 30 segundos si falla
  - No bloquea la funcionalidad del timer

- **Calendar Screen**: Banner fijo en la parte inferior
  - Se carga al abrir la pantalla de calendario
  - Mismo comportamiento de reintento

- **Settings Screen**: NO tiene banner (según especificación)

### Interstitial Ads

Se muestran **SOLO** cuando finaliza un bloque del timer:

1. ✅ **Focus completado** → Interstitial → Short Break o Long Break
2. ✅ **Short Break completado** → Interstitial → Focus
3. ✅ **Long Break completado** → Interstitial → Focus

**Características:**
- Pre-carga automática al iniciar la app
- Se recarga automáticamente después de mostrarse
- Si falla o no está listo, continúa sin bloquear
- Reintenta cada 60 segundos si falla la carga
- El timer avanza SOLO después de cerrar el anuncio

## 🛡️ Manejo de Errores

La integración es **fail-safe**:

- ❌ **Sin internet**: Los anuncios no se cargan, pero la app funciona normal
- ❌ **Fallo de carga**: Se reintenta automáticamente sin mostrar error al usuario
- ❌ **Interstitial no listo**: El timer avanza sin mostrar anuncio
- ✅ **Logs detallados**: Todos los eventos se registran en consola con emojis para debug

## 📊 Testing

### IDs de Prueba (Ya configurados para Debug)

Los siguientes IDs de prueba de Google están activos en modo Debug:

- **App ID**: `ca-app-pub-3940256099942544~3347511713`
- **Banner**: `ca-app-pub-3940256099942544/6300978111`
- **Interstitial**: `ca-app-pub-3940256099942544/1033173712`

### Cómo Probar

1. **Modo Debug** (usa IDs de prueba automáticamente):
   ```bash
   flutter run
   ```

2. **Verificar Banners**:
   - Abre Home → Deberías ver banner "Test Ad" en la parte inferior
   - Abre Calendar → Deberías ver banner "Test Ad" en la parte inferior
   - Abre Settings → NO debería haber banner

3. **Verificar Interstitials**:
   - Inicia un timer (puedes reducir la duración en Settings para pruebas rápidas)
   - Deja que termine el countdown
   - Deberías ver un interstitial de prueba
   - Al cerrar, el timer avanza a la siguiente fase

4. **Verificar Logs**:
   ```
   🟢 [AdService] Inicializando Mobile Ads SDK...
   ✅ [AdService] Mobile Ads SDK inicializado correctamente
   🔄 [AdService] Cargando Home banner...
   ✅ [AdService] Home banner cargado exitosamente
   📺 [AdService] Mostrando interstitial...
   ```

## 🚀 Compilar para Producción

```bash
# Android Release
flutter build apk --release

# O para App Bundle (recomendado para Play Store)
flutter build appbundle --release
```

En modo Release, se usan automáticamente los IDs de producción que configuraste.

## 📝 Notas Importantes

1. **No publicar con IDs de prueba**: Google puede suspender tu cuenta
2. **Tiempo de aprobación**: Los anuncios reales pueden tardar ~24h en activarse
3. **Política de AdMob**: Lee las [políticas de AdMob](https://support.google.com/admob/answer/6128543)
4. **Frecuencia**: Actualmente muestra interstitial en CADA fin de bloque
   - Puedes agregar un límite de frecuencia (ej: 1 cada 5 minutos) si es necesario

## 🐛 Troubleshooting

### "Ad failed to load" en producción
- Verifica que los Ad Unit IDs sean correctos
- Espera ~24h después de crear los Ad Units
- Verifica que la app esté publicada en Play Store

### Banner no aparece
- Verifica logs en consola
- Asegúrate de tener conexión a internet
- Verifica permisos en AndroidManifest.xml

### Interstitial no se muestra
- Normal si se mostró recientemente (se está recargando)
- Verifica logs: debe decir "✅ Interstitial cargado exitosamente"
- En producción, puede tardar en cargar la primera vez

## 📞 Soporte

Para más información sobre AdMob:
- [Documentación oficial de Google Mobile Ads](https://developers.google.com/admob/flutter/quick-start)
- [Flutter google_mobile_ads package](https://pub.dev/packages/google_mobile_ads)
