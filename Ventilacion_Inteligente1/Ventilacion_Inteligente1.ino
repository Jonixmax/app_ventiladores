#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <DHT.h>

// --- CONFIGURACIÓN DE PINES ---
#define DHTPIN 15
#define DHTTYPE DHT22

#define PIN_SENSOR_SONIDO 13
#define PIN_RELE_SONIDO 32

// Array para MOSFET de ventiladores
const int pinesVentiladores[5] = {33, 26, 27, 14, 12}; 

// --- CONFIGURACIÓN OLED ---
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET -1 
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// --- OBJETOS Y VARIABLES GLOBALES ---
DHT dht(DHTPIN, DHTTYPE);

float temperaturaActual = 0.0;
float humedadActual = 0.0;
unsigned long tiempoUltimaLectura = 0;

// --- VARIABLES PARA EL SENSOR DE APLAUSOS ---

bool estadoReleSonido = false;
int contadorAplausos = 0;
unsigned long tiempoUltimoPico = 0;
unsigned long tiempoUltimoExito = 0; 
bool estadoAnteriorSonido = LOW;    

const unsigned long tiempoAntiRebote = 200; 
const unsigned long ventanaTiempoAplausos = 1000; 
const unsigned long cooldownExito = 1500; 

// --- VARIABLES DE CONTROL GENERAL ---
bool dispositivoConectado = false;
bool modoAuto = false;
int tempMinAuto = 20;
int tempMaxAuto = 28;
int velocidadAuto = 3; // Velocidad del Modo Auto (Defecto: Alto)

// --- VARIABLES TEMPORIZADOR ---
bool temporizadorActivo = false;
unsigned long tiempoInicioTemporizador = 0;
unsigned long duracionTemporizadorMs = 0;
unsigned long tiempoUltimoComandoTimer = 0; // Escudo anti-rebote Bluetooth

// --- CONFIGURACIÓN BLUETOOTH ---
#define SERVICIO_UUID "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define RX_UUID       "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
#define TX_UUID       "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

BLEServer* pServer = NULL;
BLECharacteristic* pTxCharacteristic;

// --- DECLARACIONES PREVIAS ---
void actualizarOLED();
void encenderTodosLosVentiladores(int velocidad);
void apagarTodosLosVentiladores();
int obtenerValorPWM(int nivel);

// --- CALLBACKS BLUETOOTH ---
class MisCallbacksServidor: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      dispositivoConectado = true;
      actualizarOLED();
    }
    void onDisconnect(BLEServer* pServer) {
      dispositivoConectado = false;
      actualizarOLED();
      BLEDevice::startAdvertising(); 
    }
};

class MisCallbacksCaracteristicas: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      String comando = String(pCharacteristic->getValue().c_str());
      comando.trim();
      
      if (comando.length() > 0) {
        Serial.print("Comando recibido: ");
        Serial.println(comando);

        // 1. Comando de Ventiladores Individuales
        if (comando.startsWith("V")) {
         
          if (temporizadorActivo && (millis() - tiempoUltimoComandoTimer < 2000)) return;

          modoAuto = false; // El control manual cancela el auto
          int numeroVentilador = comando.substring(1, 2).toInt(); 
          int velocidad = comando.substring(3).toInt(); 
          
          if (numeroVentilador >= 1 && numeroVentilador <= 5) {
            int indicePin = numeroVentilador - 1;
            analogWrite(pinesVentiladores[indicePin], obtenerValorPWM(velocidad));
          }
        }
        
        // 2. Comando Modo Auto
        else if (comando.startsWith("AUTO:")) {
          
          if (temporizadorActivo && (millis() - tiempoUltimoComandoTimer < 2000)) return;

          int idx1 = comando.indexOf(':');             
          int idx2 = comando.indexOf(':', idx1 + 1);   
          int idx3 = comando.indexOf(':', idx2 + 1);   
          int idx4 = comando.indexOf(':', idx3 + 1);   
          
          if (idx4 != -1) {
            bool nuevoEstadoAuto = comando.substring(idx1 + 1, idx2) == "1";
            
            // Si apagamos el Modo Auto, cortamos la energía (solo si no hay timer)
            if (modoAuto == true && nuevoEstadoAuto == false) {
              if (!temporizadorActivo) {
                apagarTodosLosVentiladores();
              }
            }
            
            tempMinAuto = comando.substring(idx2 + 1, idx3).toInt();
            tempMaxAuto = comando.substring(idx3 + 1, idx4).toInt();
            velocidadAuto = comando.substring(idx4 + 1).toInt(); 
            modoAuto = nuevoEstadoAuto;
          }
        }
        
        // 3. Comando Temporizador
        else if (comando.startsWith("TIME:")) {
          int minutos = comando.substring(5).toInt();
          if (minutos > 0) {
            duracionTemporizadorMs = minutos * 60000UL; 
            tiempoInicioTemporizador = millis();
            temporizadorActivo = true; 
            modoAuto = false; 
            
            tiempoUltimoComandoTimer = millis(); 

          } else {
            
            if (millis() - tiempoUltimoComandoTimer > 2000) {
              temporizadorActivo = false;
              apagarTodosLosVentiladores(); 
            }
          }
        }

        actualizarOLED();
      }
    }
};

void setup() {
  Serial.begin(115200);
  delay(1000); // Pequeña pausa para dar tiempo a abrir el monitor serie
  Serial.println("\n--- INICIANDO SISTEMA KITHER ---");

  // Inicializar Pines PWM para los MOSFETs
  for (int i = 0; i < 5; i++) {
    pinMode(pinesVentiladores[i], OUTPUT);
    analogWrite(pinesVentiladores[i], 0); // Aseguramos que inicien apagados (0%)
  }
  
  pinMode(PIN_SENSOR_SONIDO, INPUT);
  
  // CONFIGURACIÓN DEL RELÉ
  pinMode(PIN_RELE_SONIDO, OUTPUT);
  
  digitalWrite(PIN_RELE_SONIDO, HIGH); 
  

  estadoAnteriorSonido = digitalRead(PIN_SENSOR_SONIDO);
  

  dht.begin();

  if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println(F("Fallo al iniciar SSD1306 OLED"));
  } else {
    display.setRotation(2); 
    display.clearDisplay();
    display.setTextColor(WHITE);
    display.setTextSize(1);
    display.setCursor(10, 20);
    display.println("Iniciando KITHER...");
    display.display();
    Serial.println("Pantalla OLED iniciada correctamente.");
  }

  // Inicialización Bluetooth
  BLEDevice::init("KITHER"); 
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MisCallbacksServidor());

  BLEService *pService = pServer->createService(SERVICIO_UUID);

  pTxCharacteristic = pService->createCharacteristic(
                      TX_UUID,
                      BLECharacteristic::PROPERTY_NOTIFY
                    );
  pTxCharacteristic->addDescriptor(new BLE2902());

  BLECharacteristic *pRxCharacteristic = pService->createCharacteristic(
                                         RX_UUID,
                                         BLECharacteristic::PROPERTY_WRITE
                                       );
  pRxCharacteristic->setCallbacks(new MisCallbacksCaracteristicas());

  pService->start();
  pServer->getAdvertising()->start();
  Serial.println("Bluetooth iniciado. Esperando conexion...");
  Serial.println("--- FIN DEL SETUP. INICIANDO LOOP ---");
}

void loop() {
  unsigned long tiempoActual = millis();

  // 1. LEER DHT22 CADA 2 SEGUNDOS
  if (tiempoActual - tiempoUltimaLectura >= 2000) {
    tiempoUltimaLectura = tiempoActual;
    float nuevaHumedad = dht.readHumidity();
    float nuevaTemp = dht.readTemperature();

    if (!isnan(nuevaHumedad) && !isnan(nuevaTemp)) {
      temperaturaActual = nuevaTemp;
      humedadActual = nuevaHumedad;
      
      if (dispositivoConectado) {
        String mensajeTx = "T:" + String(temperaturaActual, 1) + "|H:" + String(humedadActual, 1);
        pTxCharacteristic->setValue(mensajeTx.c_str());
        pTxCharacteristic->notify();
      }
      
      actualizarOLED();
    }
  }

  // 2. LÓGICA DEL SENSOR DE SONIDO
  bool estadoActualSonido = digitalRead(PIN_SENSOR_SONIDO);

  if (estadoActualSonido == HIGH && estadoAnteriorSonido == LOW) {
    Serial.println("\n[SENSOR] !Pico de sonido detectado!");
    
    if (tiempoActual - tiempoUltimoExito > cooldownExito) {
      if (tiempoActual - tiempoUltimoPico > tiempoAntiRebote) {
        if (contadorAplausos == 0) {
          contadorAplausos = 1;
          tiempoUltimoPico = tiempoActual;
          Serial.println("[APLAUSO] Primer aplauso registrado. Esperando el segundo...");
        }
        else if (contadorAplausos == 1 && (tiempoActual - tiempoUltimoPico <= ventanaTiempoAplausos)) {
          estadoReleSonido = !estadoReleSonido;
          
          Serial.print("[APLAUSO] ¡Segundo aplauso a tiempo! Cambiando estado interno a: ");
          Serial.println(estadoReleSonido ? "VERDADERO" : "FALSO");
          
     
          digitalWrite(PIN_RELE_SONIDO, estadoReleSonido ? LOW : HIGH);
          
          Serial.print("[RELÉ] Señal enviada al pin: ");
          Serial.println(estadoReleSonido ? "HIGH" : "LOW");
          
          contadorAplausos = 0;
          tiempoUltimoPico = tiempoActual;
          tiempoUltimoExito = tiempoActual;
        }
      } else {
        Serial.println("[SENSOR] Ignorado por anti-rebote (muy rápido).");
      }
    } else {
      Serial.println("[SENSOR] Ignorado por cooldown de éxito (espera tras encender/apagar).");
    }
  }

  estadoAnteriorSonido = estadoActualSonido;

  // Reseteo del contador si no se escucha el segundo aplauso a tiempo
  if (contadorAplausos == 1 && (tiempoActual - tiempoUltimoPico > ventanaTiempoAplausos)) {
    contadorAplausos = 0;
    Serial.println("[APLAUSO] Tiempo agotado. Se resetea el contador (No hubo segundo aplauso).");
  }

  // 3. LÓGICA MODO AUTOMÁTICO 
  if (modoAuto) {
    if (temperaturaActual >= tempMaxAuto) {
      encenderTodosLosVentiladores(velocidadAuto);
    } else if (temperaturaActual <= tempMinAuto) {
      apagarTodosLosVentiladores();
    }
  }

  // 4. LÓGICA TEMPORIZADOR
  if (temporizadorActivo) {
    if (tiempoActual - tiempoInicioTemporizador >= duracionTemporizadorMs) {
      apagarTodosLosVentiladores();
      temporizadorActivo = false;
      modoAuto = false; 
      actualizarOLED();
    }
  }
}

// --- FUNCIONES AUXILIARES DE ENERGÍA Y PWM ---

// Convierte el nivel de la App (0, 1, 2, 3) a un valor eléctrico PWM de 0 a 255
int obtenerValorPWM(int nivel) {
  if (nivel == 1) return 85;  // ~33% de velocidad
  if (nivel == 2) return 170; // ~66% de velocidad
  if (nivel == 3) return 255; // 100% de velocidad (Máximo)
  return 0;                   // 0% (Apagado)
}

void encenderTodosLosVentiladores(int velocidad) {
  int valorPWM = obtenerValorPWM(velocidad);
  for (int i = 0; i < 5; i++) {
    analogWrite(pinesVentiladores[i], valorPWM);
  }
}

void apagarTodosLosVentiladores() {
  for (int i = 0; i < 5; i++) {
    analogWrite(pinesVentiladores[i], 0);
  }
}

void actualizarOLED() {
  display.clearDisplay();
  
  display.setTextSize(1);
  display.setCursor(0, 0);
  if (dispositivoConectado) display.print("BLE: Conectado");
  else display.print("BLE: Esperando...");

  display.setTextSize(2);
  display.setCursor(0, 20);
  display.print(temperaturaActual, 1);
  display.print(" C");

  display.setTextSize(1);
  display.setCursor(0, 40);
  display.print("Humedad: ");
  display.print(humedadActual, 1);
  display.print(" %");

  display.setCursor(0, 55);
  
  // 1. Primero verificamos si hay un temporizador corriendo (PRIORIDAD ALTA)
  if (temporizadorActivo) {
    display.print("MODO: TEMPORIZADOR");
  } 
  // 2. Si no hay temporizador, verificamos si está en automático
  else if (modoAuto) {
    display.print("MODO: AUTO");
  } 
  // 3. Si ninguno de los dos está activo, es manual
  else {
    display.print("MODO: MANUAL");
  }

  display.display();
}