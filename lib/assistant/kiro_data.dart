/// Una categoría de preguntas frecuentes. El [icono] se dibuja en el chip
/// del panel de Kiro, así que usa solo iconos de Material (import en el widget).
class CategoriaKiro {
  final String id;
  final String nombre;
  const CategoriaKiro({required this.id, required this.nombre});
}

class PreguntaKiro {
  final String pregunta;
  final String respuesta;
  final String categoriaId;
  const PreguntaKiro({required this.pregunta, required this.respuesta, required this.categoriaId});
}

const List<CategoriaKiro> categoriasKiro = [
  CategoriaKiro(id: 'bluetooth', nombre: 'Bluetooth'),
  CategoriaKiro(id: 'sensores', nombre: 'Temperatura'),
  CategoriaKiro(id: 'ventiladores', nombre: 'Ventiladores'),
  CategoriaKiro(id: 'auto', nombre: 'Modo Auto'),
  CategoriaKiro(id: 'temporizador', nombre: 'Temporizador'),
  CategoriaKiro(id: 'aplausos', nombre: 'Aplausos'),
];

const List<PreguntaKiro> preguntasKiro = [
  // --- Bluetooth / Conexión ---
  PreguntaKiro(
    categoriaId: 'bluetooth',
    pregunta: '¿Por qué no encuentra mi dispositivo KITHER?',
    respuesta: 'Revisa que el Bluetooth y la ubicación estén activados en tu celular, y que el '
        'dispositivo KITHER esté encendido y cerca (menos de 5-8 metros, sin paredes gruesas de por medio). '
        'Si ya estuvo conectado antes a otro celular, desconéctalo de ahí primero.',
  ),
  PreguntaKiro(
    categoriaId: 'bluetooth',
    pregunta: '¿Por qué se desconecta solo?',
    respuesta: 'Suele pasar si te alejas del rango de Bluetooth, si el celular entra en modo ahorro '
        'de energía agresivo, o si el KITHER se reinicia por un corte de luz. Solo vuelve a tocar el '
        'ícono de Bluetooth para reconectar.',
  ),
  PreguntaKiro(
    categoriaId: 'bluetooth',
    pregunta: '¿Necesito internet para usar la app?',
    respuesta: 'No. La comunicación entre la app y el KITHER es 100% Bluetooth local, sin pasar por '
        'internet. Solo necesitas Bluetooth activado.',
  ),

  // --- Temperatura y Humedad ---
  PreguntaKiro(
    categoriaId: 'sensores',
    pregunta: '¿Cada cuánto se actualiza la temperatura?',
    respuesta: 'El sensor del KITHER mide la temperatura y humedad cada 2 segundos y se lo envía a la '
        'app automáticamente mientras estén conectados por Bluetooth.',
  ),
  PreguntaKiro(
    categoriaId: 'sensores',
    pregunta: '¿Por qué la temperatura marca 0.0°C?',
    respuesta: 'Es el valor inicial antes de conectarte por Bluetooth. En cuanto el KITHER se conecte '
        'y envíe su primera lectura, el número va a actualizarse solo.',
  ),
  PreguntaKiro(
    categoriaId: 'sensores',
    pregunta: '¿Qué sensor usa el dispositivo?',
    respuesta: 'Un sensor DHT22, que mide temperatura y humedad relativa del ambiente en el mismo módulo.',
  ),

  // --- Ventiladores ---
  PreguntaKiro(
    categoriaId: 'ventiladores',
    pregunta: '¿Qué significan BAJO / MEDIO / ALTO?',
    respuesta: 'Son las 3 velocidades disponibles para cada ventilador: BAJO gira al 33%, MEDIO al 66% '
        'y ALTO al 100% de su potencia. "Apagado" es velocidad 0.',
  ),
  PreguntaKiro(
    categoriaId: 'ventiladores',
    pregunta: '¿Puedo controlar cada ventilador por separado?',
    respuesta: 'Sí. Entra a "Gestionar Ventiladores" desde el panel principal y ahí tienes un control '
        'deslizante independiente para cada uno de los 5 ventiladores.',
  ),
  PreguntaKiro(
    categoriaId: 'ventiladores',
    pregunta: '¿Por qué no puedo mover los sliders?',
    respuesta: 'Los controles manuales se bloquean automáticamente mientras el Modo Automático está '
        'activado, para que no compitan entre sí. Desactiva el Modo Auto para volver a controlarlos a mano.',
  ),

  // --- Modo Automático ---
  PreguntaKiro(
    categoriaId: 'auto',
    pregunta: '¿Cómo funciona el Modo Auto exactamente?',
    respuesta: 'Tú defines una temperatura mínima, una máxima y una velocidad fija. Cuando la '
        'temperatura ambiente llega a la máxima, el KITHER enciende los 5 ventiladores a esa velocidad. '
        'Cuando baja hasta la mínima, los apaga todos.',
  ),
  PreguntaKiro(
    categoriaId: 'auto',
    pregunta: '¿Por qué los ventiladores no se apagan apenas baja un poco la temperatura?',
    respuesta: 'Porque el Modo Auto funciona por umbrales, no de forma gradual: se apagan recién al '
        'llegar a tu temperatura mínima configurada, no antes. Si quieres que reaccione más rápido, '
        'sube el valor de "temperatura mínima" en los ajustes del Modo Auto.',
  ),
  PreguntaKiro(
    categoriaId: 'auto',
    pregunta: '¿Puedo usar Modo Auto y Temporizador al mismo tiempo?',
    respuesta: 'No al mismo tiempo: si activas un Temporizador, el Modo Auto se desactiva automáticamente '
        'para evitar que ambos peleen por controlar los ventiladores.',
  ),

  // --- Temporizador ---
  PreguntaKiro(
    categoriaId: 'temporizador',
    pregunta: '¿Qué pasa cuando se acaba el tiempo?',
    respuesta: 'Al llegar a 0, el KITHER apaga automáticamente los 5 ventiladores, sin importar en qué '
        'velocidad estaban.',
  ),
  PreguntaKiro(
    categoriaId: 'temporizador',
    pregunta: '¿Puedo cancelar el temporizador?',
    respuesta: 'Sí, abre el botón "Tiempo" en el panel principal y elige "Desactivar Temporizador".',
  ),

  // --- Aplausos ---
  PreguntaKiro(
    categoriaId: 'aplausos',
    pregunta: 'Escuché que puedo aplaudir para prender/apagar algo, ¿cómo funciona?',
    respuesta: 'El KITHER tiene un sensor de sonido independiente de la app: dos aplausos seguidos '
        '(en menos de 1 segundo) prenden o apagan un relé adicional. Funciona incluso con el Bluetooth '
        'desconectado, porque esa lógica vive directamente en el dispositivo.',
  ),
];
