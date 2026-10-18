# 🌀 KITHER – Ventilación Inteligente

Aplicación móvil hecha con **Flutter** para controlar por **Bluetooth Low Energy (BLE)** un sistema de ventilación basado en un **ESP32**. Permite encender y regular hasta 5 ventiladores, ver la temperatura y humedad en tiempo real, programar un temporizador y activar un modo automático según la temperatura.

El proyecto incluye dos partes:

- **App Flutter** (`lib/`): interfaz de usuario, control BLE y gestión de usuarios.
- **Firmware ESP32** (`Ventilacion_Inteligente1/`): sketch de Arduino que controla el hardware.

---

## ✨ Características

- 🔵 **Conexión Bluetooth LE** con el dispositivo `KITHER` (sin necesidad de internet).
- 🌡️ **Monitoreo en tiempo real** de temperatura y humedad (sensor DHT22), con color según la temperatura.
- 💨 **Control de 5 ventiladores** de forma individual, con 4 niveles de velocidad (apagado, bajo, medio, alto) mediante PWM.
- 🤖 **Modo Auto**: enciende los ventiladores según un rango de temperatura mínima y máxima y una velocidad configurables.
- ⏱️ **Temporizador**: apaga el sistema automáticamente tras el tiempo elegido.
- 👏 **Control por aplausos**: dos aplausos seguidos activan o desactivan un relé (sensor de sonido).
- 📟 **Pantalla OLED** en el dispositivo que muestra el estado del sistema.
- 👤 **Gestión de usuarios** con PIN y roles (`admin` / `usuario`), guardados localmente en SQLite (máximo 6 usuarios).
- 🦊 **Kiro**, asistente integrado con preguntas frecuentes sobre Bluetooth, sensores, ventiladores, modo auto, temporizador y aplausos.

---

## 🛠️ Tecnologías

| Área | Tecnología |
|------|------------|
| App móvil | Flutter / Dart (SDK `^3.12.2`) |
| Bluetooth | [`flutter_blue_plus`](https://pub.dev/packages/flutter_blue_plus) |
| Base de datos local | [`sqflite`](https://pub.dev/packages/sqflite) + `path_provider` |
| Permisos | [`permission_handler`](https://pub.dev/packages/permission_handler) |
| Microcontrolador | ESP32 (Arduino IDE) |
| Sensores y periféricos | DHT22, sensor de sonido, pantalla OLED SSD1306, MOSFETs, relé |

---

## 🔌 Hardware (ESP32)

| Componente | Pin ESP32 |
|------------|-----------|
| Sensor DHT22 | GPIO 15 |
| Sensor de sonido | GPIO 13 |
| Relé (aplausos) | GPIO 32 |
| Ventiladores 1 a 5 (MOSFET, PWM) | GPIO 33, 26, 27, 14, 12 |
| Pantalla OLED SSD1306 (I2C, 0x3C) | SDA / SCL por defecto |

**Librerías de Arduino necesarias:** `Adafruit GFX`, `Adafruit SSD1306`, `DHT sensor library` y las de BLE incluidas en el paquete de placas ESP32.

---

## 📡 Protocolo de comunicación BLE

El ESP32 se anuncia con el nombre **`KITHER`** y usa un servicio estilo Nordic UART:

| Elemento | UUID |
|----------|------|
| Servicio | `6E400001-B5A3-F393-E0A9-E50E24DCCA9E` |
| Escritura (app → ESP32) | `6E400002-B5A3-F393-E0A9-E50E24DCCA9E` |
| Notificación (ESP32 → app) | `6E400003-B5A3-F393-E0A9-E50E24DCCA9E` |

**Comandos que envía la app:**

| Comando | Formato | Descripción |
|---------|---------|-------------|
| Ventilador | `V<n>:<nivel>` | `n` = 1 a 5, `nivel` = 0 (apagado), 1, 2 o 3 |
| Modo Auto | `AUTO:<0/1>:<tempMin>:<tempMax>:<velocidad>` | Activa o desactiva el modo automático |
| Temporizador | `TIME:<minutos>` | `0` cancela el temporizador |

**Datos que recibe la app:** `T:<temperatura>|H:<humedad>`, enviados cada 2 segundos.

---

## 📁 Estructura del proyecto

```
app_ventiladores/
├── lib/
│   ├── main.dart / app.dart        # Punto de entrada y configuración de la app
│   ├── assistant/                  # Kiro: asistente de preguntas frecuentes
│   ├── core/                       # Constantes (colores, gradientes, UUIDs BLE) y tema
│   ├── data/database_helper.dart   # Base de datos SQLite de usuarios
│   ├── services/bluetooth_service.dart  # Lógica de conexión y comandos BLE
│   └── screens/                    # splash, login, dashboard, ventiladores y ajustes
├── Ventilacion_Inteligente1/       # Firmware del ESP32 (.ino)
├── assets/                         # Logo, ícono y imágenes de Kiro
├── android/ ios/ web/ linux/ macos/ windows/
└── pubspec.yaml
```

---

## 🚀 Instalación y ejecución

### Requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) compatible con Dart `^3.12.2`
- Un dispositivo **Android o iOS físico** (el emulador no soporta Bluetooth)
- Arduino IDE con soporte para ESP32 (para cargar el firmware)

### 1. Cargar el firmware

1. Abre `Ventilacion_Inteligente1/Ventilacion_Inteligente1.ino` en el Arduino IDE.
2. Instala las librerías indicadas arriba y selecciona tu placa ESP32.
3. Sube el sketch. El dispositivo comenzará a anunciarse como `KITHER`.

### 2. Ejecutar la app

```bash
git clone https://github.com/Jonixmax/app_ventiladores.git
cd app_ventiladores
flutter pub get
flutter run
```

Para regenerar el ícono de la app:

```bash
dart run flutter_launcher_icons
```

### 3. Permisos

Al conectar, la app solicitará permisos de **Bluetooth** y **ubicación** (requeridos por Android para escanear dispositivos BLE).

---

## 👤 Usuarios y roles

Al primer inicio se crea un usuario administrador por defecto. **Se recomienda cambiar su PIN** desde la pantalla de Ajustes.

- **admin**: puede ver, editar y eliminar usuarios desde Ajustes.
- **usuario**: acceso al control de ventiladores y al dashboard. Los usuarios que se registran desde el login tienen siempre este rol.

---

## 🗺️ Posibles mejoras

- Guardar el PIN cifrado en lugar de texto plano.
- Soporte para más de un dispositivo KITHER.
- Historial de temperatura y humedad.

---

## 👨‍💻 Autor

**Jonixmax** – [github.com/Jonixmax](https://github.com/Jonixmax)
