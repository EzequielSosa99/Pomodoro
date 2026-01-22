# Pomodoro Timer App

Una aplicación móvil minimalista de temporizador Pomodoro para estudiantes y trabajadores, construida con Flutter.

## Características

### ✨ Funcionalidades Principales

- **Temporizador Pomodoro**: Timer configurable con modos de enfoque, descanso corto y descanso largo
- **Gestión de Tareas**: Calendario diario para organizar notas y tareas
- **Configuración Flexible**: Personaliza duraciones y número de ciclos
- **Internacionalización**: Soporte para inglés, español y portugués
- **Notificaciones**: Alertas al completar cada bloque de trabajo/descanso
- **Temas**: Modo claro y oscuro con paleta de colores personalizada
- **Persistencia**: Guarda configuración y tareas localmente

### 📱 Pantallas

1. **Inicio (Timer)**
   - Timer grande y centrado
   - Controles: Start, Pause, Resume, Reset
   - Indicador de ciclo y modo actual
   - Configuración rápida embebida

2. **Calendario**
   - Selector de fecha
   - Lista de tareas con checkbox
   - CRUD completo (crear, editar, eliminar)
   - Contador de pomodoros completados por día

3. **Configuración**
   - Cambio de idioma (EN/ES/PT)
   - Toggle de sonido y vibración
   - Selector de tema (claro/oscuro/sistema)
   - Reset de datos con confirmación

## 🛠️ Stack Técnico

- **Framework**: Flutter 3.0+
- **State Management**: Provider
- **Persistencia**: SharedPreferences
- **Notificaciones**: flutter_local_notifications
- **Vibración**: vibration

## 📦 Instalación y Ejecución

### Requisitos Previos

- Flutter SDK 3.0 o superior
- Dart 3.0 o superior
- Android Studio / VS Code
- Dispositivo Android o iOS (o emulador)

### Pasos de Instalación

1. **Instalar dependencias**:
   ```bash
   flutter pub get
   ```

2. **Ejecutar la aplicación**:
   ```bash
   flutter run
   ```

3. **Generar APK (Android)**:
   ```bash
   flutter build apk --release
   ```

4. **Generar IPA (iOS)**:
   ```bash
   flutter build ios --release
   ```

## 📂 Estructura del Proyecto

```
lib/
├── config/
│   └── theme.dart              # Configuración de temas
├── models/
│   ├── pomodoro_config.dart    # Modelo de configuración
│   ├── pomodoro_state.dart     # Modelo de estado del timer
│   └── task.dart               # Modelo de tareas
├── services/
│   ├── storage_service.dart    # Persistencia local
│   ├── localization_service.dart # Internacionalización
│   └── pomodoro_service.dart   # Lógica del timer
├── screens/
│   ├── home_screen.dart        # Pantalla de timer
│   ├── calendar_screen.dart    # Pantalla de tareas
│   └── settings_screen.dart    # Pantalla de configuración
├── widgets/
│   ├── timer_display.dart      # Componente de display del timer
│   ├── primary_button.dart     # Botón reutilizable
│   ├── config_sheet.dart       # Bottom sheet de configuración
│   └── task_item.dart          # Item de tarea
└── main.dart                   # Punto de entrada

assets/
└── l10n/
    ├── en.json                 # Traducciones en inglés
    ├── es.json                 # Traducciones en español
    └── pt.json                 # Traducciones en portugués
```

## 🎨 Paleta de Colores

### Tema Claro
- **Background**: `#F7F7F8`
- **Surface**: `#FFFFFF`
- **Text Primary**: `#111827`
- **Text Secondary**: `#6B7280`
- **Accent**: `#2563EB`

### Tema Oscuro
- **Background**: `#0B1220`
- **Surface**: `#111827`
- **Text Primary**: `#F9FAFB`
- **Text Secondary**: `#9CA3AF`
- **Accent**: `#3B82F6`

## 🌍 Internacionalización

La aplicación soporta tres idiomas:
- 🇬🇧 Inglés (en)
- 🇪🇸 Español (es)
- 🇧🇷 Portugués (pt)

Todos los textos utilizan claves de traducción sin strings hardcodeadas. Los archivos JSON están en `assets/l10n/`.

## 🔧 Configuración del Timer

### Valores por Defecto
- **Duración de Enfoque**: 25 minutos
- **Descanso Corto**: 5 minutos
- **Descanso Largo**: 15 minutos
- **Ciclos antes del Descanso Largo**: 4

### Flujo del Timer
1. Al terminar un bloque de Enfoque → pasa automáticamente a Descanso
2. Al terminar un Descanso → vuelve a Enfoque y avanza el ciclo
3. Después de completar N ciclos → Descanso Largo
4. Notificación + vibración al finalizar cada bloque

## 📝 Notas Técnicas

### Persistencia
- Configuración del timer
- Estado actual (ciclo, modo, tiempo restante)
- Tareas organizadas por fecha (YYYY-MM-DD)
- Contador de pomodoros completados por día
- Preferencias de usuario (idioma, sonido, tema)

### Notificaciones
Para que las notificaciones funcionen en Android, se requiere:
- Permisos de notificación (Android 13+)
- Canal de notificación configurado

## 🚀 Próximas Mejoras (Opcionales)

- [ ] Estadísticas semanales/mensuales
- [ ] Gráficas de productividad
- [ ] Integración con calendario del sistema
- [ ] Sonidos personalizables
- [ ] Widget para pantalla de inicio
- [ ] Sincronización en la nube

## 📄 Licencia

Este proyecto es de código abierto y está disponible para uso educativo y personal.

## 👨‍💻 Desarrollo

Desarrollado con ❤️ usando Flutter.

**Versión**: 1.0.0
