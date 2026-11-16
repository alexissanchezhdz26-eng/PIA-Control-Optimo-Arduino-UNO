
/*
====================================================
 UANL - FIME
 PIA CONTROL OPTIMO
 Arduino UNO - Planta RC de segundo orden

 PLANTA:
 R1 = R2 = R3 = 1 MOhm
 C1 = C2 = 1 uF

 FILTRO PWM:
 R = 1 kOhm
 C = 10 uF

 CONTROLADORES:
 1 = LQR
 2 = Asignacion de polos
 3 = Integral
 4 = LQI

 CONEXIONES:
 PWM   = D5
 X1    = A0
 X2    = A1
 REF   = A2
 START = D7
 STOP  = D8
 RESET = D9

 LCD 16x2:
 RS = D12
 E  = D11
 D4 = D6
 D5 = D4
 D6 = D3
 D7 = D2

 COMUNICACION SERIAL:
 115200 baudios

 FORMATOS:
 PLOT = Graficas en tiempo real
 CSV  = Registro experimental
====================================================
*/

#include <Arduino.h>
#include <LiquidCrystal.h>
#include <math.h>

// ===============================================
// PANTALLA LCD
// ===============================================

LiquidCrystal lcd(12, 11, 6, 4, 3, 2);

// ===============================================
// PINES
// ===============================================

const byte PIN_PWM = 5;

const byte PIN_X1 = A0;
const byte PIN_X2 = A1;
const byte PIN_REF = A2;

const byte PIN_START = 7;
const byte PIN_STOP = 8;
const byte PIN_RESET = 9;

// ===============================================
// PARAMETROS
// ===============================================

const float V_ADC = 4.99f;
const float V_PWM = 5.0f;
const float REF_MAX = 1.0f;

const float TS = 0.020f;

const unsigned long PERIODO_US = 20000UL;
const unsigned long LCD_MS = 250UL;

// ===============================================
// MODOS DE REGISTRO
// ===============================================

enum TipoRegistro {
  REGISTRO_PLOT,
  REGISTRO_CSV
};

TipoRegistro registro = REGISTRO_PLOT;

// ===============================================
// VARIABLES DEL SISTEMA
// ===============================================

// LQR seleccionado inicialmente
byte modo = 1;

bool activo = false;

float integral = 0.0f;

float r = 0.0f;
float x1 = 0.0f;
float x2 = 0.0f;
float u = 0.0f;

int pwm = 0;

unsigned long siguienteUs = 0;
unsigned long ultimoLcdMs = 0;
unsigned long inicioMs = 0;

// ===============================================
// ESTRUCTURA DE BOTONES
// ===============================================

struct Boton {
  byte pin;
  bool lecturaAnterior;
  bool estable;
  unsigned long cambioMs;
};

Boton bStart = {PIN_START, HIGH, HIGH, 0};
Boton bStop  = {PIN_STOP, HIGH, HIGH, 0};
Boton bReset = {PIN_RESET, HIGH, HIGH, 0};

// ===============================================
// DETECCION DE PULSADORES
// ===============================================

bool fuePulsado(Boton &b) {

  bool lectura = digitalRead(b.pin);
  unsigned long ahora = millis();

  if (lectura != b.lecturaAnterior) {
    b.lecturaAnterior = lectura;
    b.cambioMs = ahora;
  }

  if ((ahora - b.cambioMs >= 35UL) &&
      lectura != b.estable) {

    b.estable = lectura;

    return lectura == LOW;
  }

  return false;
}

// ===============================================
// LECTURA ANALOGICA
// ===============================================

float leerVoltaje(byte pin) {

  // Seleccionar canal analogico
  analogRead(pin);

  // Descartar conversiones iniciales
  for (byte i = 0; i < 8; i++) {
    analogRead(pin);
  }

  // Promedio de 16 muestras
  unsigned long suma = 0;

  for (byte i = 0; i < 16; i++) {
    suma += analogRead(pin);
  }

  float promedio = suma / 16.0f;

  return promedio * V_ADC / 1023.0f;
}

// ===============================================
// APAGAR PWM
// ===============================================

void salidaCero() {

  pwm = 0;
  u = 0.0f;

  analogWrite(PIN_PWM, 0);
}

// ===============================================
// GANANCIAS DE CONTROL
// ===============================================

void seleccionarGanancias(
  byte m,
  float &k1,
  float &k2,
  float &ki
) {

  switch (m) {

    case 1:
      // CONTROL LQR
      k1 = 0.41421356f;
      k2 = 0.41421356f;
      ki = 0.0f;
      break;

    case 2:
      // ASIGNACION DE POLOS
      k1 = 1.0f;
      k2 = 1.0f;
      ki = 0.0f;
      break;

    case 3:
      // CONTROL INTEGRAL
      k1 = 0.8f;
      k2 = 2.35f;
      ki = 3.0f;
      break;

    case 4:
      // CONTROL LQI
      k1 = 0.71101988f;
      k2 = 1.17481439f;
      ki = 1.41421356f;
      break;

    default:
      k1 = 0.0f;
      k2 = 0.0f;
      ki = 0.0f;
      break;
  }
}

// ===============================================
// ENCABEZADO CSV
// ===============================================

void encabezadoCSV() {

  Serial.println(
    F("t_ms,modo,r,x1,x2,u,pwm")
  );
}

// ===============================================
// REGISTRO EXPERIMENTAL
// ===============================================

void registrarDatos() {

  if (registro == REGISTRO_PLOT) {

    // Formato compatible con Serial Plotter

    Serial.print(F("REF:"));
    Serial.print(r, 4);

    Serial.print(F("\tX1:"));
    Serial.print(x1, 4);

    Serial.print(F("\tX2:"));
    Serial.print(x2, 4);

    Serial.print(F("\tU:"));
    Serial.println(u, 4);

  }

  else {

    // Formato CSV con tiempo real medido

    Serial.print(millis() - inicioMs);

    Serial.print(',');
    Serial.print(modo);

    Serial.print(',');
    Serial.print(r, 4);

    Serial.print(',');
    Serial.print(x1, 4);

    Serial.print(',');
    Serial.print(x2, 4);

    Serial.print(',');
    Serial.print(u, 4);

    Serial.print(',');
    Serial.println(pwm);
  }
}

// ===============================================
// CAMBIAR FORMATO DE REGISTRO
// ===============================================

void cambiarRegistro(TipoRegistro nuevo) {

  registro = nuevo;

  if (registro == REGISTRO_CSV) {
    encabezadoCSV();
  }
}

// ===============================================
// SELECCIONAR CONTROLADOR
// ===============================================

void cambiarModo(byte nuevoModo) {

  if (nuevoModo < 1 || nuevoModo > 4) {
    return;
  }

  activo = false;

  modo = nuevoModo;

  integral = 0.0f;

  salidaCero();

  if (registro == REGISTRO_CSV) {
    encabezadoCSV();
  }
}

// ===============================================
// INICIAR SISTEMA
// ===============================================

void iniciarSistema() {

  if (modo < 1 || modo > 4) {
    return;
  }

  integral = 0.0f;

  inicioMs = millis();

  activo = true;

  // Encabezado al iniciar una prueba CSV
  if (registro == REGISTRO_CSV) {
    encabezadoCSV();
  }
}

// ===============================================
// DETENER SISTEMA
// ===============================================

void detenerSistema() {

  activo = false;

  salidaCero();
}

// ===============================================
// REINICIAR SISTEMA
// ===============================================

void reiniciarSistema() {

  activo = false;

  integral = 0.0f;

  modo = 1;

  salidaCero();

  if (registro == REGISTRO_CSV) {
    encabezadoCSV();
  }
}

// ===============================================
// COMANDOS DEL MONITOR SERIE
// ===============================================

void gestionarComandos() {

  while (Serial.available() > 0) {

    char c = (char)Serial.read();

    if (c >= '1' && c <= '4') {

      cambiarModo((byte)(c - '0'));

    }

    else if (c == 'p' || c == 'P') {

      cambiarRegistro(REGISTRO_PLOT);

    }

    else if (c == 'c' || c == 'C') {

      cambiarRegistro(REGISTRO_CSV);

    }

    else if (c == 's' || c == 'S') {

      iniciarSistema();

    }

    else if (c == 'x' || c == 'X' || c == '0') {

      detenerSistema();

    }

    else if (c == 'z' || c == 'Z') {

      reiniciarSistema();
    }
  }
}

// ===============================================
// CONTROL DE PULSADORES
// ===============================================

void gestionarBotones() {

  bool reset = fuePulsado(bReset);
  bool stop = fuePulsado(bStop);
  bool start = fuePulsado(bStart);

  if (reset) {

    reiniciarSistema();

  }

  else if (stop) {

    detenerSistema();

  }

  else if (start) {

    iniciarSistema();
  }
}

// ===============================================
// CONTROL DE LA PLANTA
// ===============================================

void controlar() {

  // Lecturas reales de la protoboard
  x1 = leerVoltaje(PIN_X1);
  x2 = leerVoltaje(PIN_X2);
  r = leerVoltaje(PIN_REF);

  r = constrain(r, 0.0f, REF_MAX);

  // ===========================================
  // REFERENCIAS DE EQUILIBRIO
  // ===========================================

  float e1 = x1 - 2.0f * r;
  float e2 = x2 - r;

  // ===========================================
  // GANANCIAS DEL CONTROLADOR
  // ===========================================

  float k1, k2, ki;

  seleccionarGanancias(
    modo,
    k1,
    k2,
    ki
  );

  // ===========================================
  // LEY DE CONTROL
  // ===========================================

  float uLibre =
      3.0f * r
      - k1 * e1
      - k2 * e2
      + ki * integral;

  // ===========================================
  // SATURACION DE VOLTAJE
  // ===========================================

  float uLimitada = constrain(
    uLibre,
    0.0f,
    V_PWM
  );

  // ===========================================
  // CONVERSION A PWM
  // ===========================================

  pwm = constrain(
    (int)roundf(
      255.0f * uLimitada / V_PWM
    ),
    0,
    255
  );

  analogWrite(PIN_PWM, pwm);

  u = V_PWM * pwm / 255.0f;

  // ===========================================
  // CONTROL INTEGRAL CON ANTIWINDUP
  // ===========================================

  float error = r - x2;

  bool satAlta =
      (uLibre > V_PWM && error > 0.0f);

  bool satBaja =
      (uLibre < 0.0f && error < 0.0f);

  if (ki > 0.0f && !satAlta && !satBaja) {

    integral += TS * error;

    integral = constrain(
      integral,
      -3.0f,
      3.0f
    );
  }

  // ===========================================
  // ENVIAR MEDICIONES REALES
  // ===========================================

  registrarDatos();
}

// ===============================================
// PANTALLA LCD
// ===============================================

void mostrarLCD() {

  if (!activo) {

    lcd.setCursor(0, 0);

    lcd.print(F("MODO "));
    lcd.print(modo);
    lcd.print(F(" LISTO      "));

    lcd.setCursor(0, 1);

    lcd.print(F("PULSE START     "));

  }

  else {

    // PRIMERA FILA
    // Referencia y salida X2

    lcd.setCursor(0, 0);

    lcd.print(F("R:"));
    lcd.print(r, 2);

    lcd.print(F(" X2:"));
    lcd.print(x2, 2);

    lcd.print(F("  "));

    // SEGUNDA FILA
    // Estado X1 y accion de control

    lcd.setCursor(0, 1);

    lcd.print(F("X1:"));
    lcd.print(x1, 2);

    lcd.print(F(" U:"));
    lcd.print(u, 2);

    lcd.print(F("  "));
  }
}

// ===============================================
// CONFIGURACION INICIAL
// ===============================================

void setup() {

  pinMode(PIN_PWM, OUTPUT);

  salidaCero();

  pinMode(PIN_START, INPUT_PULLUP);
  pinMode(PIN_STOP, INPUT_PULLUP);
  pinMode(PIN_RESET, INPUT_PULLUP);

  Serial.begin(115200);

  lcd.begin(16, 2);

  lcd.clear();

  lcd.setCursor(0, 0);
  lcd.print(F("PIA CONTROL OPT"));

  lcd.setCursor(0, 1);
  lcd.print(F("Arduino UNO"));

  delay(900);

  // LQR seleccionado inicialmente
  modo = 1;

  // Graficas en tiempo real inicialmente
  registro = REGISTRO_PLOT;

  activo = false;

  integral = 0.0f;

  siguienteUs = micros();

  ultimoLcdMs = millis();
}

// ===============================================
// PROGRAMA PRINCIPAL
// ===============================================

void loop() {

  gestionarComandos();

  gestionarBotones();

  unsigned long ahora = micros();

  if ((long)(ahora - siguienteUs) >= 0) {

    siguienteUs += PERIODO_US;

    if ((long)(micros() - siguienteUs) >= 0) {

      siguienteUs = micros() + PERIODO_US;
    }

    if (activo) {

      controlar();

    }

    else {

      salidaCero();
    }
  }

  if (millis() - ultimoLcdMs >= LCD_MS) {

    ultimoLcdMs = millis();

    mostrarLCD();
  }
}
