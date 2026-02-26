# Depuración de Audio - Notificación de Pomodoro

## Cambios Realizados

### 1. Configuración del AudioPlayer
- Agregado `AudioContext` con configuración específica para Android
- Configurado como `AndroidUsageType.alarm` para máxima prioridad
- Configurado `audioFocus: AndroidAudioFocus.gain` para obtener foco de audio
- Configurado `stayAwake: true` para mantener el dispositivo activo

### 2. Permisos de Android
Agregados en `AndroidManifest.xml`:
- `WAKE_LOCK` - Mantener dispositivo activo durante reproducción
- `FOREGROUND_SERVICE` - Permitir servicios en primer plano

### 3. Logs de Depuración
El código ahora imprime logs detallados:
- "Attempting to play alarm audio..." cuando inicia
- "Audio playback started successfully" si tiene éxito
- Stack trace completo si hay errores

## Cómo Probar

### Opción 1: Ver Logs en Tiempo Real
```bash
flutter run --release
# En otra terminal:
adb logcat | grep -i "audio\|alarm"
```

### Opción 2: Verificar que el archivo está incluido
```bash
# Extraer el APK y verificar assets
unzip -l build/app/outputs/flutter-apk/app-release.apk | grep notification.mp3
```

### Opción 3: Probar Audio Manualmente
```bash
# Enviar archivo al dispositivo y reproducir
adb push assets/notification/notification.mp3 /sdcard/test_notification.mp3
adb shell am start -a android.intent.action.VIEW -d file:///sdcard/test_notification.mp3 -t audio/mp3
```

## Posibles Problemas y Soluciones

### 1. El volumen del dispositivo está bajo/silencioso
**Solución:** Verifica que el volumen de alarmas esté alto (no el volumen de multimedia)

### 2. Modo No Molestar activado
**Solución:** Desactiva el modo No Molestar o configura excepciones para la app

### 3. El archivo de audio es muy grande (1.9 MB)
**Posible solución:** Considera usar un archivo más pequeño si hay problemas de rendimiento

### 4. Problemas de codec
**Verificar:** El archivo MP3 debe ser compatible con Android
```bash
ffmpeg -i assets/notification/notification.mp3
```

## Próximos Pasos Si No Funciona

1. **Ejecuta la app en modo debug con logs:**
   ```bash
   flutter run --release
   adb logcat *:E | grep -i "audio\|AudioPlayer\|alarm"
   ```

2. **Verifica el estado del AudioPlayer:**
   Los logs mostrarán exactamente qué está pasando

3. **Alternativa: Usar notificación con sonido**
   Si el AudioPlayer falla, podríamos hacer que la notificación reproduzca el sonido
