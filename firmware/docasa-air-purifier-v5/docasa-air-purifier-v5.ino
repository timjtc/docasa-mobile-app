#define FASTLED_ESP32_I2S true
#include <FastLED.h>
#include <SPI.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_ST7789.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_BME680.h>
#include "Adafruit_PM25AQI.h"
// --- DOCASA IoT (v4.1): BLE + NVS + JSON for the appended IoT block (Plan §1.4 additive) ---
#include <Preferences.h>
#include <NimBLEDevice.h>
#include <ArduinoJson.h>
#include <esp_partition.h>   // v4.2 (D-028): raw partition access for the offline ring

// --- Pin Definitions ---
#define BATT_SENSE_PIN   33
#define CHARGE_STAT_PIN  14
#define FAN_PWM_PIN      27
#define LED_DATA_PIN     13
#define TFT_CS           15
#define TFT_DC           2
#define TFT_RST          4

// --- Configuration ---
#define NUM_LEDS         30
#define FAN_PWM_FREQ     25000 // 25 kHz standard frequency for 4-pin PWM fans (ARCTIC P8 Max)
#define FAN_PWM_RES      8
#define MAX_PARTICLES    16

// --- Battery Configuration (4S Li-ion Calibrated) ---
const float BATT_V_EMPTY = 13.0;     // Safe 0% cutoff (3.25V per cell)
const float BATT_V_FULL  = 16.41;    // Full resting voltage ceiling
const float BATT_MULTIPLIER = 6.040; // Calibrated multiplier

// --- Particle Physics Structure ---
struct Particle {
  float x, y;
  float vx, vy;
  uint8_t radius;
};

// --- Hardware Objects ---
Adafruit_ST7789 tft = Adafruit_ST7789(TFT_CS, TFT_DC, TFT_RST);
CRGB leds[NUM_LEDS];
Adafruit_BME680 bme;
Adafruit_PM25AQI aqi = Adafruit_PM25AQI();
Particle particles[MAX_PARTICLES];

// --- Sensor & Battery State Variables ---
int pm10Value = 0, pm25Value = 0, pm100Value = 0;
float temperature = 0.0, humidity = 0.0, gasResistance = 0.0;
int batteryPct = 0;
bool isCharging = false;
bool isTrulyFull = false;
unsigned long maxVoltageStartTime = 0;
float smoothedVoltage = 0.0;
float smoothedPct = -1.0;
bool firstRead = true;

// --- Async BME680 Variables ---
unsigned long bmeEndTime = 0;
bool bmeReading = false;

// --- System State Variables ---
int overallStage = 1;
int currentFanRpm = 0;
uint16_t currentBgColor = 0x0821;
uint16_t particleColor  = ST77XX_GREEN;

// --- Display Tracking Variables ---
int displayPage = 0;
unsigned long lastPageToggle = 0;
bool forceRedraw = true;
int lastStage = -1;
int lastPm10 = -1, lastPm25 = -1, lastPm100 = -1;
int lastTemp = -1, lastHum = -1, lastVoc = -1;
int lastBatt = -1, lastFan = -1;
bool lastChargeState = false;
bool lastTrulyFull = false;

// --- Function Declarations ---
void showBootScreen();
void initParticleEngine();
void readSensorsAsync();
void calculateCompositeAQI();
void updateFan();
void updateLEDs();
void handleDisplayTransitions();
void updateDisplay();
void updateAirQualityDynamic();
void updateSystemDynamic();
void updateAndDrawParticles();
void drawTempIcon(int x, int y);
void drawHumIcon(int x, int y);
void drawVocIcon(int x, int y);
void drawFanIcon(int x, int y);
void drawBattIcon(int x, int y, int pct, bool charging, bool trulyFull);

void setup() {
  Serial.begin(115200);
  Serial2.begin(9600, SERIAL_8N1, 16, 17);

  pinMode(CHARGE_STAT_PIN, INPUT);

  ledcAttach(FAN_PWM_PIN, FAN_PWM_FREQ, FAN_PWM_RES);
  ledcWrite(FAN_PWM_PIN, 255); // Start fan OFF (Transistor fully active, pulling PWM line low)

  if (!bme.begin(0x77)) {
    Serial.println("BME680 not found!");
  } else {
    bme.setTemperatureOversampling(BME680_OS_8X);
    bme.setHumidityOversampling(BME680_OS_2X);
    bme.setIIRFilterSize(BME680_FILTER_SIZE_3);
  }

  if (!aqi.begin_UART(&Serial2)) {
    Serial.println("PMS7003 not found!");
  }

  FastLED.addLeds<WS2812B, LED_DATA_PIN, GRB>(leds, NUM_LEDS);
  FastLED.setBrightness(100);

  pinMode(TFT_RST, OUTPUT);
  digitalWrite(TFT_RST, LOW); delay(20);
  digitalWrite(TFT_RST, HIGH); delay(150);
  tft.init(240, 320);
  tft.setRotation(1);
  tft.invertDisplay(false);

  // --- DOCASA IoT (v4.1): BLE + NVS init — pre-approved setup() insertion (Plan §7.6) ---
  docasaIoBegin();

  // --- Run Cinematic Boot Screen Animation ---
  showBootScreen();

  initParticleEngine();
}

void loop() {
  readSensorsAsync();
  calculateCompositeAQI();
  updateFan();
  updateLEDs();
  handleDisplayTransitions();

  if (overallStage != lastStage) {
    forceRedraw = true;
    lastStage = overallStage;
  }

  updateDisplay();
  updateAndDrawParticles();

  // --- DOCASA IoT (v4.1): telemetry/persistence scheduler — pre-approved loop() insertion ---
  docasaIoService();

  delay(15);
}

// --- Cinematic Boot Screen Animation ---
void showBootScreen() {
  tft.fillScreen(0x0000);

  unsigned long bootStartTime = millis();
  unsigned long bootDuration = 5000;
  int bootLedHead = 0;
  unsigned long lastBootLedUpdate = 0;
  bool textRendered = false;

  while (millis() - bootStartTime < bootDuration) {
    unsigned long elapsed = millis() - bootStartTime;

    if (!textRendered && elapsed < 1500) {
      if (elapsed < 600) {
        int lineWidth = map(elapsed, 0, 600, 0, 150);
        tft.drawFastHLine(160 - lineWidth, 75, lineWidth * 2, 0x07FF);
      } else {
        tft.drawFastHLine(10, 75, 300, 0x0410);
      }

      int yPos = map(constrain(elapsed, 300, 1200), 300, 1200, 15, 40);
      tft.fillRect(90, 10, 150, 60, 0x0000);

      tft.setTextSize(3);
      tft.setTextColor(0x001F);
      tft.setCursor(107, yPos + 2);
      tft.print("DOCASA");

      tft.setTextColor(elapsed > 900 ? ST77XX_WHITE : 0x07FF);
      tft.setCursor(105, yPos);
      tft.print("DOCASA");

      if (elapsed > 1000) {
        tft.setTextSize(1);
        tft.setTextColor(0xC618);
        tft.setCursor(42, 85);
        tft.print("Do Clean Air with Smarter Living Anywhere");
        textRendered = true;
      }
    }

    int barX = 40, barY = 190, barW = 240, barH = 12;
    if (elapsed == 0) {
      tft.drawRoundRect(barX, barY, barW, barH, 4, ST77XX_WHITE);
    }

    int fillW = map(elapsed, 0, bootDuration, 0, barW - 4);
    tft.fillRoundRect(barX + 2, barY + 2, fillW, barH - 4, 3, ST77XX_CYAN);

    float angleStep = TWO_PI / 5.0;
    float globalAngle = (elapsed / 200.0);
    int centerX = 160, centerY = 145;
    int radius = 25;

    uint16_t stageColors[5] = {ST77XX_GREEN, ST77XX_YELLOW, ST77XX_ORANGE, ST77XX_RED, 0xF81F};
    int colorShift = (elapsed / 1000) % 5;

    for (int i = 0; i < 5; i++) {
      float a = globalAngle + (i * angleStep);
      int px = centerX + cos(a) * radius;
      int py = centerY + sin(a) * radius;

      tft.fillCircle(px, py, 4, 0x0000);
      int activeColorIdx = (i + colorShift) % 5;
      tft.fillCircle(px, py, 3, stageColors[activeColorIdx]);
    }

    tft.fillRect(40, 115, 240, 20, 0x0000);
    tft.setTextSize(1);
    tft.setTextColor(ST77XX_YELLOW);
    tft.setCursor(85, 115);
    int stageSec = (elapsed / 1000) % 5;
    if (stageSec == 0) tft.print("Initializing Sensors...");
    else if (stageSec == 1) tft.print("Calibrating Air Quality...");
    else if (stageSec == 2) tft.print("Checking 4S Battery Pack...");
    else if (stageSec == 3) tft.print("Starting Particle Engine...");
    else tft.print("System Ready...");

    if (millis() - lastBootLedUpdate > 60) {
      bootLedHead++;
      if (bootLedHead >= NUM_LEDS) bootLedHead = 0;
      lastBootLedUpdate = millis();

      FastLED.clear();
      int tailLen = 8;
      for (int i = 0; i < tailLen; i++) {
        int pos = bootLedHead - i;
        if (pos < 0) pos += NUM_LEDS;
        uint8_t bootHue = (elapsed / 15) + (i * 8);
        leds[pos] = CHSV(bootHue, 255, 255);
        leds[pos].nscale8(255 - (i * 255 / tailLen));
      }
      FastLED.show();
    }
    delay(15);
  }

  currentBgColor = 0x0821;
  tft.fillScreen(currentBgColor);
}

void initParticleEngine() {
  for(int i = 0; i < MAX_PARTICLES; i++) {
    particles[i].x = random(185, 305);
    particles[i].y = random(45, 215);
    particles[i].vx = (random(-15, 16) / 10.0);
    particles[i].vy = (random(-15, 16) / 10.0);
    if (particles[i].vx == 0) particles[i].vx = 1.0;
    if (particles[i].vy == 0) particles[i].vy = 1.0;
    particles[i].radius = random(3, 7);
  }
}

void readSensorsAsync() {
  PM25_AQI_Data data;
  if (aqi.read(&data)) {
    pm10Value = data.pm10_env;
    pm25Value = data.pm25_env;
    pm100Value = data.pm100_env;
  }

  if (!bmeReading) {
    bmeEndTime = bme.beginReading();
    if (bmeEndTime != 0) bmeReading = true;
  } else if (millis() >= bmeEndTime) {
    if (bme.endReading()) {
      temperature = bme.temperature;
      humidity = bme.humidity;
      gasResistance = bme.gas_resistance / 1000.0;
    }
    bmeReading = false;
  }

  long adcSum = 0;
  for (int i = 0; i < 32; i++) {
    adcSum += analogRead(BATT_SENSE_PIN);
  }
  float rawADC = adcSum / 32.0;

  float pinVoltage = (rawADC / 4095.0) * 3.3;
  float actualBattVoltage = pinVoltage * BATT_MULTIPLIER;

  if (firstRead) {
    smoothedVoltage = actualBattVoltage;
    firstRead = false;
  }
  smoothedVoltage = (smoothedVoltage * 0.92) + (actualBattVoltage * 0.08);

  float rawPct = (smoothedVoltage - BATT_V_EMPTY) / (BATT_V_FULL - BATT_V_EMPTY) * 100.0;
  rawPct = constrain(rawPct, 0.0, 100.0);

  isCharging = (digitalRead(CHARGE_STAT_PIN) == HIGH);

  if (isCharging) {
    if (!isTrulyFull && rawPct > 95.0) {
      rawPct = 95.0;
    }

    if (smoothedVoltage >= (BATT_V_FULL - 0.10)) {
      if (maxVoltageStartTime == 0) {
        maxVoltageStartTime = millis();
      } else if (millis() - maxVoltageStartTime >= 300000) {
        isTrulyFull = true;
      }
    } else {
      maxVoltageStartTime = 0;
      isTrulyFull = false;
    }
  } else {
    maxVoltageStartTime = 0;
    isTrulyFull = false;
  }

  if (smoothedPct < 0) {
    smoothedPct = rawPct;
  } else {
    smoothedPct = (smoothedPct * 0.92) + (rawPct * 0.08);
  }

  int newPct = (int)(smoothedPct + 0.5);
  if (abs(newPct - batteryPct) >= 1) {
    batteryPct = newPct;
  }
}

void calculateCompositeAQI() {
  int pm25Stage = 1, pm100Stage = 1;

  if (pm25Value <= 12) pm25Stage = 1;
  else if (pm25Value <= 35) pm25Stage = 2;
  else if (pm25Value <= 55) pm25Stage = 3;
  else if (pm25Value <= 150) pm25Stage = 4;
  else pm25Stage = 5;

  if (pm100Value <= 54) pm100Stage = 1;
  else if (pm100Value <= 154) pm100Stage = 2;
  else if (pm100Value <= 254) pm100Stage = 3;
  else if (pm100Value <= 424) pm100Stage = 4;
  else pm100Stage = 5;

  overallStage = max(pm25Stage, pm100Stage);

  if (gasResistance < 30.0 && gasResistance > 0 && overallStage < 5) overallStage++;
}

void updateFan() {
  int targetRpm = 0;
  switch(overallStage) {
    case 1: targetRpm = 0;    break; // Green  -> 0 RPM (Fan OFF)
    case 2: targetRpm = 1000; break; // Yellow -> 1000 RPM
    case 3: targetRpm = 2000; break; // Orange -> 2000 RPM
    case 4: targetRpm = 3000; break; // Red    -> 3000 RPM
    case 5: targetRpm = 4000; break; // Purple -> 4000 RPM (Maximum Capped)
  }

  currentFanRpm = targetRpm;

  // Map target RPM to 0-255 PWM scale
  int rawPwm = map(currentFanRpm, 0, 5000, 0, 255);

  // Corrected Inverted PWM mapping for transistor driver:
  // 0 RPM -> 255 (Transistor fully active, grounds fan PWM line -> OFF)
  // 4000 RPM -> 51 (Transistor mostly off, allows fan to run at 80% capacity)
  int correctedPwm = 255 - rawPwm;

  ledcWrite(FAN_PWM_PIN, correctedPwm);
}

void updateLEDs() {
  CRGB statusColor;
  switch(overallStage) {
    case 1: statusColor = CRGB::Green;  particleColor = ST77XX_GREEN;  break;
    case 2: statusColor = CRGB::Yellow; particleColor = ST77XX_YELLOW; break;
    case 3: statusColor = CRGB::Orange; particleColor = ST77XX_ORANGE; break;
    case 4: statusColor = CRGB::Red;    particleColor = ST77XX_RED;    break;
    case 5: statusColor = CRGB::Purple; particleColor = 0xF81F;        break;
  }

  FastLED.clear();
  static int head = 0;
  int tailLength = 6;
  int speedDelay = map(overallStage, 1, 5, 120, 40);
  static unsigned long lastLedUpdate = 0;

  if (millis() - lastLedUpdate > speedDelay) {
    head++;
    if (head >= NUM_LEDS) head = 0;
    lastLedUpdate = millis();
  }

  for(int i = 0; i < tailLength; i++) {
    int pos = head - i;
    if (pos < 0) pos += NUM_LEDS;
    leds[pos] = statusColor;
    leds[pos].nscale8(255 - (i * 255 / tailLength));
  }
  FastLED.show();
}

void handleDisplayTransitions() {
  if (millis() - lastPageToggle > 6000) {
    displayPage = (displayPage == 0) ? 1 : 0;
    forceRedraw = true;
    lastPageToggle = millis();
  }
}

void updateDisplay() {
  if (forceRedraw) {
    tft.fillScreen(currentBgColor);
    tft.setTextColor(ST77XX_WHITE);

    tft.setTextSize(2);
    tft.setCursor(15, 10);
    if (displayPage == 0) {
      tft.print("AIR MONITOR");
    } else {
      tft.print("SYSTEM STATUS");
    }

    tft.drawLine(10, 32, 310, 32, ST77XX_WHITE);
    tft.drawRoundRect(175, 40, 138, 185, 8, ST77XX_WHITE);

    if (displayPage == 1) {
      tft.setTextSize(1);
      tft.setTextColor(0xC618);
      tft.setCursor(15, 38);  tft.print("TEMPERATURE");
      tft.setCursor(15, 74);  tft.print("HUMIDITY");
      tft.setCursor(15, 110); tft.print("VOC (GAS kOhm)");
      tft.setCursor(15, 146); tft.print("FAN SPEED (RPM)");
      tft.setCursor(15, 182); tft.print("BATTERY %");
    }

    lastPm10 = -1; lastPm25 = -1; lastPm100 = -1;
    lastTemp = -1; lastHum = -1; lastVoc = -1;
    lastBatt = -1; lastFan = -1;
    forceRedraw = false;
  }

  if (displayPage == 0) updateAirQualityDynamic();
  else updateSystemDynamic();
}

void updateAirQualityDynamic() {
  tft.setTextSize(1); tft.setTextColor(0xC618);
  tft.setCursor(15, 42); tft.print("PM2.5 (ug/m3)");

  if (pm25Value != lastPm25) {
    tft.fillRect(15, 55, 150, 35, currentBgColor);
    tft.setTextSize(4); tft.setTextColor(ST77XX_WHITE);
    tft.setCursor(15, 55); tft.print(pm25Value);
    lastPm25 = pm25Value;
  }

  tft.setTextSize(1); tft.setTextColor(0xC618);
  tft.setCursor(15, 102); tft.print("PM1.0/PM10 (ug/m3)");

  if (pm10Value != lastPm10 || pm100Value != lastPm100) {
    tft.fillRect(15, 115, 150, 20, currentBgColor);
    tft.setTextSize(2); tft.setTextColor(ST77XX_WHITE);
    tft.setCursor(15, 115); tft.print(pm10Value);
    tft.setCursor(85, 115); tft.print(pm100Value);
    lastPm10 = pm10Value; lastPm100 = pm100Value;
  }

  tft.setTextSize(1); tft.setTextColor(0xC618);
  tft.setCursor(15, 150); tft.print("AIR STATUS");

  tft.setTextSize(3); tft.setTextColor(particleColor);
  tft.setCursor(15, 165);
  switch(overallStage) {
    case 1: tft.print("GOOD"); break;
    case 2: tft.print("FAIR"); break;
    case 3: tft.print("POOR"); break;
    case 4: tft.print("BAD"); break;
    case 5: tft.print("HAZARD"); break;
  }
}

// --- Icon Drawing Helper Functions ---
void drawTempIcon(int x, int y) {
  tft.fillRect(x + 10, y, 4, 12, ST77XX_WHITE);
  tft.fillCircle(x + 12, y + 13, 4, ST77XX_ORANGE);
  tft.fillRect(x + 11, y + 2, 2, 9, ST77XX_ORANGE);
}

void drawHumIcon(int x, int y) {
  tft.fillTriangle(x + 12, y, x + 7, y + 9, x + 17, y + 9, 0x07FF);
  tft.fillCircle(x + 12, y + 10, 5, 0x07FF);
}

void drawVocIcon(int x, int y) {
  tft.drawFastHLine(x + 4, y + 2, 16, ST77XX_YELLOW);
  tft.drawFastHLine(x + 6, y + 6, 14, ST77XX_YELLOW);
  tft.drawFastHLine(x + 4, y + 10, 16, ST77XX_YELLOW);
  tft.drawFastHLine(x + 6, y + 14, 14, ST77XX_YELLOW);
}

void drawFanIcon(int x, int y) {
  tft.drawCircle(x + 12, y + 8, 7, ST77XX_CYAN);
  tft.drawFastVLine(x + 12, y + 3, 10, ST77XX_CYAN);
  tft.drawFastHLine(x + 7, y + 8, 10, ST77XX_CYAN);
}
void drawBattIcon(int x, int y, int pct, bool charging, bool trulyFull) {
  tft.drawRect(x + 2, y + 2, 24, 12, ST77XX_WHITE);
  tft.fillRect(x + 26, y + 5, 3, 6, ST77XX_WHITE);

  int fillW = map(constrain(pct, 0, 100), 0, 100, 0, 20);
  if (trulyFull) fillW = 20;

  uint16_t fillColor = trulyFull ? ST77XX_GREEN : (charging ? ST77XX_YELLOW : ST77XX_GREEN);
  tft.fillRect(x + 4, y + 4, fillW, 8, fillColor);
}

void updateSystemDynamic() {
  int currentTemp = (int)temperature;
  int currentHum = (int)humidity;
  int currentVoc = (int)gasResistance;
  int currentBatt = batteryPct;
  int currentFan = currentFanRpm;
  bool charging = isCharging;
  bool trulyFull = isTrulyFull;

  // 1. Temperature Row & Icon
  if (currentTemp != lastTemp || forceRedraw) {
    tft.fillRect(15, 49, 65, 18, currentBgColor);
    tft.setTextSize(2);
    tft.setTextColor(ST77XX_WHITE);
    tft.setCursor(15, 49);
    tft.print(currentTemp);
    tft.print("C");

    tft.fillRect(88, 47, 72, 16, currentBgColor);
    drawTempIcon(88, 48);
    lastTemp = currentTemp;
  }

  // 2. Humidity Row & Icon
  if (currentHum != lastHum || forceRedraw) {
    tft.fillRect(15, 85, 65, 18, currentBgColor);
    tft.setTextSize(2);
    tft.setTextColor(0x07FF);
    tft.setCursor(15, 85);
    tft.print(currentHum);
    tft.print("%");

    tft.fillRect(88, 83, 72, 16, currentBgColor);
    drawHumIcon(88, 84);
    lastHum = currentHum;
  }

  // 3. VOC Row & Icon
  if (currentVoc != lastVoc || forceRedraw) {
    tft.fillRect(15, 121, 65, 18, currentBgColor);
    tft.setTextSize(2);
    tft.setTextColor(ST77XX_YELLOW);
    tft.setCursor(15, 121);
    tft.print(currentVoc);

    tft.fillRect(88, 119, 72, 16, currentBgColor);
    drawVocIcon(88, 120);
    lastVoc = currentVoc;
  }

  // 4. Fan RPM Row & Icon
  if (currentFan != lastFan || forceRedraw) {
    tft.fillRect(15, 157, 70, 18, currentBgColor);
    tft.setTextSize(2);
    tft.setTextColor(ST77XX_CYAN);
    tft.setCursor(15, 157);
    tft.print(currentFan);

    tft.fillRect(88, 155, 72, 16, currentBgColor);
    drawFanIcon(88, 156);
    lastFan = currentFan;
  }

  // 5. Battery % Row & Battery Icon
  if (currentBatt != lastBatt || charging != lastChargeState || trulyFull != lastTrulyFull || forceRedraw) {
    tft.fillRect(15, 193, 72, 18, currentBgColor);
    tft.setTextSize(2);

    if (trulyFull) {
      tft.setTextColor(ST77XX_GREEN);
      tft.setCursor(15, 193);
      tft.print("FULL");
    } else {
      if (charging) tft.setTextColor(ST77XX_YELLOW);
      else tft.setTextColor(ST77XX_GREEN);

      tft.setCursor(15, 193);
      tft.print(currentBatt);
      tft.print("%");
    }

    tft.fillRect(88, 191, 72, 16, currentBgColor);
    drawBattIcon(88, 192, currentBatt, charging, trulyFull);

    lastBatt = currentBatt;
    lastChargeState = charging;
    lastTrulyFull = trulyFull;
  }
}

void updateAndDrawParticles() {
  int activeParticles = map(overallStage, 1, 5, 4, MAX_PARTICLES);
  float speedMultiplier = map(overallStage, 1, 5, 8, 30) / 10.0;

  for (int i = 0; i < activeParticles; i++) {
    tft.fillCircle((int)particles[i].x, (int)particles[i].y, particles[i].radius, currentBgColor);

    particles[i].x += particles[i].vx * speedMultiplier;
    particles[i].y += particles[i].vy * speedMultiplier;

    if (particles[i].x - particles[i].radius <= 180 || particles[i].x + particles[i].radius >= 305) {
      particles[i].vx *= -1;
    }
    if (particles[i].y - particles[i].radius <= 45 || particles[i].y + particles[i].radius >= 215) {
      particles[i].vy *= -1;
    }

    tft.fillCircle((int)particles[i].x, (int)particles[i].y, particles[i].radius, particleColor);
  }
}

// ============================================================================
// === DOCASA IoT ADDITIONS (v4.1) ============================================
// === Scope: Plan §1.4 — BLE capability + NVS persistence + data transmis- ===
// === sion ONLY. No hardware-control, display, LED, fan or sensor logic is  ===
// === modified. Changes to the original v3 code are strictly additive: the  ===
// === three includes at the top of this file, the two pre-approved inser-   ===
// === tion calls (docasaIoBegin() in setup(), docasaIoService() in loop()), ===
// === and this appended block. Verify with tools/firmware-diff-check.sh     ===
// === (must report 0 removed/changed lines).                                ===
// === Interface spec: docs/BLE-Protocol-Contract.md v1.0 (frozen, D-002).   ===
// ============================================================================

// --- Identity & protocol constants (Contract §1–§2) ---
#define DOCASA_BLE_NAME         "DOCASA-AirPurifier"
#define DOCASA_PROTOCOL_VERSION 1
const char* DOCASA_FW_VERSION = "4.2.0";  // D-005/D-015/D-022/D-028: NVS + BLE + resetFilter + offline ring
// --- v4.2 = Contract v1.1 (D-027/D-028): sketch lives in docasa-air-purifier-v5/,
// seeded byte-identical from the FROZEN v4.1.1 `docasa-air-purifier-v4/` (D-028e).

#define DOCASA_UUID_SERVICE "d0ca5a0e-975a-4408-9059-a93d3207072f"
#define DOCASA_UUID_AIR     "d0ca5a22-27ed-4fbe-aa36-dd1ffdc66f7f"
#define DOCASA_UUID_ENV     "d0ca5acb-dcfc-4d8f-8a52-b21558697f7e"
#define DOCASA_UUID_SYS     "d0ca5a8f-1160-4c49-a9ee-138998d9c402"
#define DOCASA_UUID_FILTER  "d0ca5a7a-fd2b-4dbf-932a-855cb6d3ddf0"
#define DOCASA_UUID_CMD     "d0ca5abd-8a7e-4412-9e96-a01d4656f3f7"
#define DOCASA_UUID_OFFLINE "d0ca5a79-bb2b-478b-abed-9ac1441cd635"  // v1.1 (D-028, Contract §2)

// --- v4.2 offline-history ring constants (Contract v1.1 §10, D-028) ---
#define DOCASA_RING_SLOT_SEC      600UL                    // 10-min envelope windows (§10.1)
#define DOCASA_RING_RECORD_BYTES  16                       // pmMin/pmMean/pmMax u16 + stSec 5×u16 (LE)
#define DOCASA_RING_PAGE_BYTES    4096                     // one erase page = 256 records
#define DOCASA_RING_RECS_PER_PAGE (DOCASA_RING_PAGE_BYTES / DOCASA_RING_RECORD_BYTES)
#define DOCASA_RING_CAP_RECORDS   (64UL * DOCASA_RING_RECS_PER_PAGE)  // 256 KB partition = 16,384 records
#define DOCASA_RING_PART_NAME     "docasa_ring"
#define DOCASA_RING_PM_VALID_MAX  999                      // sensor domain cap; > this ⇒ invalid/torn record

// --- NVS persistence state (Plan §4.2 / D-004: both integrals uint64) ---
Preferences docasaPrefs;
uint64_t docasaFanSeconds       = 0;  // Σ commanded-RPM × dt          [RPM·s]
uint64_t docasaPmWeightedFanSec = 0;  // Σ commanded-RPM × PM2.5 × dt [RPM·µg·s]
uint32_t docasaPowerOnSeconds   = 0;  // powered time — device lifecycle (never filter-reset)
uint32_t docasaMsResidual       = 0;  // shared sub-second residual (no drift, exact dt accounting)
uint32_t docasaEpoch            = 0;  // app-supplied time (reboot-volatile — Contract §6.7)

// --- BLE GATT objects ---
NimBLEServer*          docasaServer       = nullptr;
NimBLEService*         docasaTelemetrySvc = nullptr;
NimBLECharacteristic*  docasaAirChr       = nullptr;
NimBLECharacteristic*  docasaEnvChr       = nullptr;
NimBLECharacteristic*  docasaSysChr       = nullptr;
NimBLECharacteristic*  docasaFilterChr    = nullptr;
NimBLECharacteristic*  docasaCmdChr       = nullptr;
NimBLECharacteristic*  docasaBattChr      = nullptr;
NimBLECharacteristic*  docasaOfflineChr   = nullptr;   // v1.1 (D-028, §10.3)

// --- Scheduler & on-change tracking (unsigned-delta millis — rollover-safe, Plan §7.2) ---
unsigned long docasaLastTickMs     = 0;
unsigned long docasaLastNvsWriteMs = 0;
uint32_t      docasaTickCount      = 0;
int           docasaLastStageSent  = -1;
bool          docasaLastChgSent    = false;
bool          docasaLastFullSent   = false;

// CCCD subscription tracking (NimBLE 2.x has no getSubscribedCount — onSubscribe
// callback maintains these flags; risk 7.22. Reset on disconnect.)
volatile bool docasaAirSubscribed  = false;
volatile bool docasaEnvSubscribed  = false;
volatile bool docasaSysSubscribed  = false;
volatile bool docasaBattSubscribed = false;

// --- v4.2 offline-history state (Contract v1.1 §10, D-028) ---
static uint8_t docasaRingPageBuf[DOCASA_RING_PAGE_BYTES];   // shared 4 KB page read buffer
// (BLE-host task only — never races the loop-side writer)
const esp_partition_t* docasaRingPart = nullptr; // docasa_ring data partition (0x40)
uint32_t         docasaRingBootId      = 1;             // NVS "boot" counter — +1 per boot
uint32_t         docasaRingHeadSlot    = 0;             // next window slot to write (per boot)
uint32_t         docasaRingLastPage    = 0xFFFFFFFFU;   // currently-erased page (erase-ahead)
uint32_t         docasaStSeconds[5]    = {0, 0, 0, 0, 0};   // NVS st1..st5 (§4.4, since replacement)
uint16_t         docasaWinMinPm        = 0xFFFF;        // in-flight window: PM min (0xFFFF = unset)
uint16_t         docasaWinMaxPm        = 0;             // in-flight window: PM max
uint32_t         docasaWinPmSum        = 0;             // in-flight window: Σ pm samples (mean = Σ/600)
uint16_t         docasaWinSec          = 0;             // in-flight window: seconds accumulated
uint32_t         docasaWinStSec[5]     = {0, 0, 0, 0, 0};   // in-flight window: per-stage seconds
// App-initiated drain cursor — connection-scoped, never persisted (§10.3):
bool     docasaOfflineCursorArmed    = false;
bool     docasaOfflineStatusPending  = false;   // first read after arm delivers ring status JSON
uint32_t docasaOfflineNextSlot       = 0;       // next record to serve
uint32_t docasaOfflineEndSlot        = 0;       // exclusive drain bound (= head at arm time)
uint32_t docasaOfflineFirstSlot      = 0;       // first valid record served (status JSON "first")

// --- v4.2 offline-history ring module (Contract v1.1 §10, D-028) ---
// Additive-only per Plan §1.4: new NVS keys, partitions.csv (docasa_ring,
// 256 KB data/0x40) and the characteristics below; no v3/v4 line is modified.

// Partition lookup + boot id. The ring slot numbering restarts at 0 every
// boot (slots are boot-scoped — the phone maps (bootId, slot) → wall-clock,
// Plan §7.13 time authority unchanged).
void docasaRingBegin() {
  docasaRingPart = esp_partition_find_first(ESP_PARTITION_TYPE_DATA,
      (esp_partition_subtype_t)0x40, DOCASA_RING_PART_NAME);
  if (docasaRingPart == nullptr) {
    Serial.println("[DOCASA IO] ring partition 'docasa_ring' not found — offline history off");
    Serial.println("[DOCASA IO] (flash with the sketch partitions.csv: custom partition scheme)");
    return;
  }
  docasaRingBootId = docasaPrefs.getUInt("boot", 0) + 1;
  docasaPrefs.putUInt("boot", docasaRingBootId);      // 1 write per boot — negligible wear
  for (int i = 0; i < 5; i++)                         // v1.1 "st" counters (D-027/D-028)
    docasaStSeconds[i] = docasaPrefs.getUInt((String("st") + (i + 1)).c_str(), 0);
  Serial.printf("[DOCASA IO] ring '%s': %lukb, boot=%lu, cap=%lu records\n",
                DOCASA_RING_PART_NAME,
                (unsigned long)(docasaRingPart->size / 1024UL),
                (unsigned long)docasaRingBootId,
                (unsigned long)DOCASA_RING_CAP_RECORDS);
}

// Record validity (§10.1): pm fields must sit in the sensor domain. A torn
// power-loss write leaves 0xFF bytes → pm reads 65535 → immediately invalid,
// so a checksum is unnecessary; the drain stops at the first invalid slot and
// the phone renders that window as a gap (power-cut loss ≤ 1 window, §10.3).
static bool docasaRingValid(const uint8_t* r) {
  for (int i = 0; i < 6; i += 2) {                       // pmMin/pmMean/pmMax
    uint16_t v = (uint16_t)(r[i] | (r[i + 1] << 8));
    if (v > DOCASA_RING_PM_VALID_MAX) return false;
  }
  for (int s = 0; s < 5; s++) {                          // stSec[5] ≤ 600 s per window
    uint16_t v = (uint16_t)(r[6 + 2 * s] | (r[7 + 2 * s] << 8));
    if (v > DOCASA_RING_SLOT_SEC) return false;
  }
  return true;
}

bool docasaRingRead(uint32_t slot, uint8_t* out) {
  if (docasaRingPart == nullptr || slot >= docasaRingHeadSlot) return false;
  uint32_t idx  = slot % DOCASA_RING_CAP_RECORDS;
  uint32_t addr = (idx / DOCASA_RING_RECS_PER_PAGE) * DOCASA_RING_PAGE_BYTES +
                  (idx % DOCASA_RING_RECS_PER_PAGE) * DOCASA_RING_RECORD_BYTES;
  if (esp_partition_read(docasaRingPart, addr, out, DOCASA_RING_RECORD_BYTES) != ESP_OK)
    return false;
  return docasaRingValid(out);
}

// Close the current window: assemble 16 B LE, erase-ahead on page transitions
// (~1 erase per 2.56 days — brief flash stall, LCD/LED/fan cadence unaffected;
// verified at the bench gate), advance head. History never resets on
// resetFilter — health (st counters) and history (ring) are two append-only
// strands; replacement is a phone-side timeline marker (D-027/D-028).
void docasaRingWinClose() {
  if (docasaRingPart == nullptr) return;
  uint8_t rec[DOCASA_RING_RECORD_BYTES] = {0};
  uint16_t pmMin = (docasaWinMinPm > DOCASA_RING_PM_VALID_MAX)
                       ? DOCASA_RING_PM_VALID_MAX : docasaWinMinPm;
  uint16_t pmMax = (docasaWinMaxPm > DOCASA_RING_PM_VALID_MAX)
                       ? DOCASA_RING_PM_VALID_MAX : docasaWinMaxPm;
  uint32_t sec = docasaWinSec ? docasaWinSec : 1;
  uint16_t pmMean = (uint16_t)constrain(docasaWinPmSum / sec, 0, DOCASA_RING_PM_VALID_MAX);
  rec[0] = (uint8_t)(pmMin & 0xFF);  rec[1] = (uint8_t)(pmMin >> 8);
  rec[2] = (uint8_t)(pmMean & 0xFF); rec[3] = (uint8_t)(pmMean >> 8);
  rec[4] = (uint8_t)(pmMax & 0xFF);  rec[5] = (uint8_t)(pmMax >> 8);
  for (int s = 0; s < 5; s++) {
    rec[6 + 2 * s]     = (uint8_t)(docasaWinStSec[s] & 0xFF);
    rec[7 + 2 * s]     = (uint8_t)(docasaWinStSec[s] >> 8);
    docasaWinStSec[s]  = 0;
  }
  uint32_t slot = docasaRingHeadSlot;
  uint32_t idx  = slot % DOCASA_RING_CAP_RECORDS;
  uint32_t page = idx / DOCASA_RING_RECS_PER_PAGE;
  uint32_t addr = page * DOCASA_RING_PAGE_BYTES +
                  (idx % DOCASA_RING_RECS_PER_PAGE) * DOCASA_RING_RECORD_BYTES;
  if (page != docasaRingLastPage) {
    esp_partition_erase_range(docasaRingPart, page * DOCASA_RING_PAGE_BYTES,
                              DOCASA_RING_PAGE_BYTES);
    docasaRingLastPage = page;
  }
  esp_partition_write(docasaRingPart, addr, rec, DOCASA_RING_RECORD_BYTES);
  docasaRingHeadSlot = slot + 1;
}

// 1 Hz slice: attribute whole seconds to (a) the global per-stage counters
// (§4.4 "st" — health basis, reset by resetFilter) and (b) the in-flight
// envelope window (§10.1 — never reset by resetFilter).
void docasaRingTick(uint32_t wholeSec) {
  int stage = constrain(overallStage, 1, 5) - 1;
  docasaStSeconds[stage] += wholeSec;
  int pm = pm25Value > (int)DOCASA_RING_PM_VALID_MAX ? (int)DOCASA_RING_PM_VALID_MAX
           : (pm25Value < 0 ? 0 : pm25Value);
  uint32_t fill = wholeSec;
  while (fill > 0) {
    uint32_t need = DOCASA_RING_SLOT_SEC - docasaWinSec;
    uint32_t take = (fill < need) ? fill : need;
    if (pm < (int)docasaWinMinPm) docasaWinMinPm = (uint16_t)pm;   // 0xFFFF = unset
    if (pm > (int)docasaWinMaxPm) docasaWinMaxPm = (uint16_t)pm;
    docasaWinPmSum += (uint32_t)pm * take;
    docasaWinStSec[stage] += take;
    docasaWinSec += take;
    fill -= take;
    if (docasaWinSec >= DOCASA_RING_SLOT_SEC) {
      docasaRingWinClose();
      docasaWinSec   = 0;          // window restarts; min sentinel back to unset
      docasaWinPmSum = 0;
      docasaWinMaxPm = 0;
      docasaWinMinPm = 0xFFFF;
    }
  }
}

// Arm the drain cursor (app-initiated, once per connect — §10.3): serve slots
// (after, head); absent/0 "after" → drain from the oldest available record.
void docasaOfflineArm(uint32_t afterSlot) {
  docasaOfflineNextSlot      = afterSlot;
  docasaOfflineEndSlot       = docasaRingHeadSlot;
  docasaOfflineFirstSlot     = docasaOfflineNextSlot;
  docasaOfflineStatusPending = true;
  docasaOfflineCursorArmed   = true;
}

// Walk `from` → end until the first valid record. Page-granular: one 4 KB
// flash read covers 256 slots, so even a from-oldest scan stays well under a
// second and never risks the BLE supervision timeout inside a read callback.
uint32_t docasaOfflineFirstValid(uint32_t from) {
  if (docasaRingPart == nullptr || from >= docasaRingHeadSlot) return docasaRingHeadSlot;
  uint32_t page = (from % DOCASA_RING_CAP_RECORDS) / DOCASA_RING_RECS_PER_PAGE;
  uint32_t headPage = ((docasaRingHeadSlot - 1) % DOCASA_RING_CAP_RECORDS) / DOCASA_RING_RECS_PER_PAGE;
  for (uint32_t p = page; ; p = (p + 1) == DOCASA_RING_CAP_RECORDS / DOCASA_RING_RECS_PER_PAGE ? 0 : p + 1) {
    if (esp_partition_read(docasaRingPart, p * DOCASA_RING_PAGE_BYTES, docasaRingPageBuf,
                           DOCASA_RING_PAGE_BYTES) != ESP_OK)
      return docasaRingHeadSlot;
    for (uint32_t r = 0; r < DOCASA_RING_RECS_PER_PAGE; r++) {
      uint32_t slot = p * DOCASA_RING_RECS_PER_PAGE + r;
      if (slot < from) continue;                     // skip below-cursor records in the first page
      if (docasaRingValid(docasaRingPageBuf + r * DOCASA_RING_RECORD_BYTES)) return slot;
    }
    if (p == headPage) break;                        // scanned everything up to head
  }
  return docasaRingHeadSlot;
}

// Offline History read serving (read-only characteristic, §10.3): first read
// after arming = ring status JSON; further reads = packed records in slot
// order (≤ min(15, page-remaining) × 16 B per read); empty body = drained;
// the drain stops at the first invalid record (torn/power-loss → ≤1-window
// phone-side gap). Each read touches at most ONE flash page — bounded work
// inside the BLE host task, never risks the supervision timeout.
class DocasaOfflineReadCallbacks : public NimBLECharacteristicCallbacks {
  void onRead(NimBLECharacteristic* pCharacteristic, NimBLEConnInfo& connInfo) override {
    if (!docasaOfflineCursorArmed || docasaRingPart == nullptr) return;
    if (docasaOfflineStatusPending) {
      docasaOfflineStatusPending = false;
      docasaOfflineFirstSlot = docasaOfflineNextSlot < docasaOfflineEndSlot
          ? docasaOfflineFirstValid(docasaOfflineNextSlot) : docasaOfflineEndSlot;
      char statusJson[80];
      int n = snprintf(statusJson, sizeof(statusJson),
                       "{\"v\":%d,\"boot\":%lu,\"first\":%lu,\"count\":%lu}",
                       DOCASA_PROTOCOL_VERSION,
                       (unsigned long)docasaRingBootId,
                       (unsigned long)docasaOfflineFirstSlot,
                       (unsigned long)(docasaOfflineEndSlot > docasaOfflineFirstSlot
                            ? docasaOfflineEndSlot - docasaOfflineFirstSlot : 0));
      pCharacteristic->setValue((const uint8_t*)statusJson, (size_t)n);
      docasaOfflineNextSlot = docasaOfflineFirstSlot; // serve from the resolved start (skip holes)
      return;
    }
    if (docasaOfflineNextSlot >= docasaOfflineEndSlot) return;   // drained → empty body
    uint32_t idx  = docasaOfflineNextSlot % DOCASA_RING_CAP_RECORDS;
    uint32_t page = idx / DOCASA_RING_RECS_PER_PAGE;
    if (esp_partition_read(docasaRingPart, page * DOCASA_RING_PAGE_BYTES, docasaRingPageBuf,
                           DOCASA_RING_PAGE_BYTES) != ESP_OK) return;
    uint32_t serve = DOCASA_RING_RECS_PER_PAGE - (idx % DOCASA_RING_RECS_PER_PAGE); // page bound
    if (serve > docasaOfflineEndSlot - docasaOfflineNextSlot)
      serve = docasaOfflineEndSlot - docasaOfflineNextSlot;
    if (serve > 15) serve = 15;                                  // MTU-247 GATT bound
    uint8_t out[15 * DOCASA_RING_RECORD_BYTES];
    size_t n = 0;
    for (uint32_t r = 0; r < serve; r++) {
      uint32_t off = (idx % DOCASA_RING_RECS_PER_PAGE + r) * DOCASA_RING_RECORD_BYTES;
      if (!docasaRingValid(docasaRingPageBuf + off)) break;      // invalid stops the drain
      memcpy(out + n, docasaRingPageBuf + off, DOCASA_RING_RECORD_BYTES);
      n += DOCASA_RING_RECORD_BYTES;
      docasaOfflineNextSlot++;
    }
    if (n > 0) pCharacteristic->setValue(out, n);
  }
};

// Filter Counters payload with the v1.1 `"st"` array (§4.4). Parsed into a
// dedicated buffer so the shared v1 snapshot buffer stays untouched.
size_t docasaBuildFilterCountersFull(char* buf, size_t len) {
  JsonDocument doc;
  doc["v"]    = DOCASA_PROTOCOL_VERSION;
  doc["fs"]   = docasaFanSeconds;
  doc["pwfs"] = docasaPmWeightedFanSec;
  doc["on"]   = docasaPowerOnSeconds / 3600UL;         // whole hours (Contract §4.4)
  JsonArray st = doc["st"].to<JsonArray>();
  for (int i = 0; i < 5; i++) st.add(docasaStSeconds[i]);
  return serializeJson(doc, buf, len);
}

void docasaPublishFilterFull() {
  static char fbuf[192];   // base payload (~64 B) + worst-case "st" array (~52 B)
  docasaPublish(docasaFilterChr, fbuf, docasaBuildFilterCountersFull(fbuf, sizeof(fbuf)));
}

// --- Connection policy callbacks (data/flags only — never draw, Plan §3.3) ---
class DocasaServerCallbacks : public NimBLEServerCallbacks {
  void onConnect(NimBLEServer* pServer, NimBLEConnInfo& connInfo) override {
    NimBLEDevice::getAdvertising()->stop();   // single-central policy (Plan §7.9)
    Serial.println("[DOCASA IO] central connected — advertising paused");
  }
  void onDisconnect(NimBLEServer* pServer, NimBLEConnInfo& connInfo, int reason) override {
    NimBLEDevice::startAdvertising();         // auto re-advertise (Contract §6.5)
    docasaAirSubscribed  = false;             // subscriptions die with the connection
    docasaEnvSubscribed  = false;
    docasaSysSubscribed  = false;
    docasaBattSubscribed = false;
    docasaOfflineCursorArmed   = false;       // v1.1 (§10.3): the drain cursor is
    docasaOfflineStatusPending = false;       // connection-scoped and never persisted
    Serial.println("[DOCASA IO] central disconnected — advertising resumed");
  }
};

// --- CCCD subscription tracking callbacks (flags only — Plan §3.3) ---
class DocasaSubsCallbacks : public NimBLECharacteristicCallbacks {
  void onSubscribe(NimBLECharacteristic* pCharacteristic, NimBLEConnInfo& connInfo,
                   uint16_t subValue) override {
    bool on = (subValue & 0x01) != 0;   // bit 0 = notifications enabled
    if      (pCharacteristic == docasaAirChr)  docasaAirSubscribed  = on;
    else if (pCharacteristic == docasaEnvChr)  docasaEnvSubscribed  = on;
    else if (pCharacteristic == docasaSysChr)  docasaSysSubscribed  = on;
    else if (pCharacteristic == docasaBattChr) docasaBattSubscribed = on;
  }
};

// --- Command characteristic callbacks (Contract §5) ---
class DocasaCmdCallbacks : public NimBLECharacteristicCallbacks {
  void onWrite(NimBLECharacteristic* pCharacteristic, NimBLEConnInfo& connInfo) override {
    std::string rx = pCharacteristic->getValue();
    JsonDocument doc;
    if (deserializeJson(doc, rx.data(), rx.size())) {
      Serial.println("[DOCASA IO] cmd ignored — malformed JSON");        // fixture X1
      return;
    }
    const char* cmd = doc["cmd"].is<const char*>() ? doc["cmd"].as<const char*>() : nullptr;
    if (cmd != nullptr && strcmp(cmd, "time") == 0 && doc["epoch"].is<uint32_t>()) {
      docasaEpoch = doc["epoch"].as<uint32_t>();   // re-synced on every app connect (Plan §5)
      Serial.printf("[DOCASA IO] time sync — epoch=%lu\n", (unsigned long)docasaEpoch);
    } else if (cmd != nullptr && strcmp(cmd, "resetFilter") == 0) {
      // Contract §5 (D-022): zero both usage integrals, keep onSec, persist
      // immediately (a cut right after replacement must not resurrect the
      // old counters from the 5-min throttle window).
      docasaFanSeconds       = 0;
      docasaPmWeightedFanSec = 0;
      for (int _si = 0; _si < 5; _si++) docasaStSeconds[_si] = 0;   // v1.1 (D-027/D-028): exposure basis resets with the cartridge
      docasaNvsPersist();
      Serial.println("[DOCASA IO] resetFilter — usage integrals zeroed (onSec preserved)");
    } else if (cmd != nullptr && strcmp(cmd, "offlineLog") == 0) {
      // v1.1 (D-028, §5/§10.3): arm the Offline History drain cursor.
      // Absent "after" → drain from the oldest valid record (§5 default);
      // invalid "after" → ignore silently (fixture X9).
      if (doc["after"].isNull()) {
        docasaOfflineArm(0);
        Serial.println("[DOCASA IO] offlineLog — drain from oldest");
      } else if (doc["after"].is<uint32_t>()) {
        docasaOfflineArm(doc["after"].as<uint32_t>());
        Serial.printf("[DOCASA IO] offlineLog — drain after slot %lu\n",
                      (unsigned long)doc["after"].as<uint32_t>());
      } else {
        Serial.println("[DOCASA IO] cmd ignored — offlineLog 'after' malformed");
      }
    } else {
      // Unknown or out-of-scope commands (fan → Plan §1.4 restricted list):
      // ignore silently, keep the connection (Contract §5 / fixtures X2, X3).
      Serial.printf("[DOCASA IO] cmd ignored — '%s'\n", cmd ? cmd : "(none)");
    }
  }
};

// --- Payload builders (Contract §4 — JSON v1, canonical key order) ---
size_t docasaBuildAirQuality(char* buf, size_t len) {
  JsonDocument doc;
  doc["v"]    = DOCASA_PROTOCOL_VERSION;
  doc["pm1"]  = pm10Value;    // ⚠ v3 variable name holds PM1.0 (Plan §1.2 — never rename)
  doc["pm25"] = pm25Value;
  doc["pm10"] = pm100Value;
  doc["st"]   = overallStage;
  return serializeJson(doc, buf, len);
}

size_t docasaBuildEnvironment(char* buf, size_t len) {
  JsonDocument doc;
  doc["v"]   = DOCASA_PROTOCOL_VERSION;
  doc["t"]   = roundf(temperature * 10.0f) / 10.0f;    // 1 decimal (Contract §4.2)
  doc["h"]   = roundf(humidity * 10.0f) / 10.0f;
  doc["voc"] = roundf(gasResistance * 10.0f) / 10.0f;
  return serializeJson(doc, buf, len);
}

size_t docasaBuildSystemStatus(char* buf, size_t len) {
  JsonDocument doc;
  doc["v"]    = DOCASA_PROTOCOL_VERSION;
  doc["fan"]  = currentFanRpm;                         // commanded target (Contract §4.3)
  doc["bat"]  = batteryPct;
  doc["chg"]  = isCharging ? 1 : 0;
  doc["full"] = isTrulyFull ? 1 : 0;
  doc["vb"]   = roundf(smoothedVoltage * 100.0f) / 100.0f;  // 2 decimals
  return serializeJson(doc, buf, len);
}

size_t docasaBuildFilterCounters(char* buf, size_t len) {
  JsonDocument doc;
  doc["v"]    = DOCASA_PROTOCOL_VERSION;
  doc["fs"]   = docasaFanSeconds;
  doc["pwfs"] = docasaPmWeightedFanSec;
  doc["on"]   = docasaPowerOnSeconds / 3600UL;         // whole hours (Contract §4.4)
  return serializeJson(doc, buf, len);
}

// --- Publish helper: update stored value (serves reads) and notify only when
//     the central has notifications enabled (CCCD-gated — risk 7.22). The
//     read-only counters characteristic has no flags → never notified. ---
void docasaPublish(NimBLECharacteristic* chr, const char* buf, size_t len) {
  chr->setValue((const uint8_t*)buf, len);
  bool subscribed =
      (chr == docasaAirChr  && docasaAirSubscribed)  ||
      (chr == docasaEnvChr  && docasaEnvSubscribed)  ||
      (chr == docasaSysChr  && docasaSysSubscribed);
  if (subscribed) chr->notify();
}

// --- NVS helpers (namespace "docasa", keys per Contract §4.4) ---
void docasaNvsRestore() {
  docasaPrefs.begin("docasa", false);
  docasaFanSeconds       = docasaPrefs.getULong64("fanSec", 0);
  docasaPmWeightedFanSec = docasaPrefs.getULong64("pwfs", 0);
  docasaPowerOnSeconds   = docasaPrefs.getUInt("onSec", 0);
}

void docasaNvsPersist() {
  docasaPrefs.putULong64("fanSec", docasaFanSeconds);
  docasaPrefs.putULong64("pwfs",   docasaPmWeightedFanSec);
  docasaPrefs.putUInt("onSec",     docasaPowerOnSeconds);
  for (int i = 0; i < 5; i++)                        // v1.1 (D-027): per-stage health basis
    docasaPrefs.putUInt((String("st") + (i + 1)).c_str(), docasaStSeconds[i]);
  docasaLastNvsWriteMs = millis();
}

// --- BLE GATT server construction (Contract §2–§3) ---
void docasaBleBegin() {
  NimBLEDevice::init(DOCASA_BLE_NAME);
  NimBLEDevice::setMTU(247);   // payloads ≤ ~77 B; app requests 247 (Contract §1)
  docasaServer = NimBLEDevice::createServer();
  docasaServer->setCallbacks(new DocasaServerCallbacks());

  // Device Information Service (0x180A)
  NimBLEService* dis = docasaServer->createService(NimBLEUUID("180A"));
  dis->createCharacteristic(NimBLEUUID("2A29"), NIMBLE_PROPERTY::READ)
      ->setValue(std::string("DOCASA"));
  dis->createCharacteristic(NimBLEUUID("2A24"), NIMBLE_PROPERTY::READ)
      ->setValue(std::string("DOCASA Air Purifier"));
  dis->createCharacteristic(NimBLEUUID("2A26"), NIMBLE_PROPERTY::READ)
      ->setValue(std::string(DOCASA_FW_VERSION));
  dis->createCharacteristic(NimBLEUUID("2A27"), NIMBLE_PROPERTY::READ)
      ->setValue(std::string("ESP32-WROOM-v3"));
  dis->start();

  // Battery Service (0x180F / 0x2A19) — uint8 %
  NimBLEService* bas = docasaServer->createService(NimBLEUUID("180F"));
  docasaBattChr = bas->createCharacteristic(NimBLEUUID("2A19"),
                                            NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::NOTIFY);
  uint8_t battInit = (uint8_t)constrain(batteryPct, 0, 100);
  docasaBattChr->setValue(&battInit, 1);
  bas->start();

  // DOCASA Telemetry Service (custom 128-bit — UUIDs frozen, D-002)
  docasaTelemetrySvc = docasaServer->createService(NimBLEUUID(DOCASA_UUID_SERVICE));
  docasaAirChr    = docasaTelemetrySvc->createCharacteristic(
                      NimBLEUUID(DOCASA_UUID_AIR),    NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::NOTIFY);
  docasaEnvChr    = docasaTelemetrySvc->createCharacteristic(
                      NimBLEUUID(DOCASA_UUID_ENV),    NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::NOTIFY);
  docasaSysChr    = docasaTelemetrySvc->createCharacteristic(
                      NimBLEUUID(DOCASA_UUID_SYS),    NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::NOTIFY);
  docasaFilterChr = docasaTelemetrySvc->createCharacteristic(
                      NimBLEUUID(DOCASA_UUID_FILTER), NIMBLE_PROPERTY::READ);
  docasaCmdChr    = docasaTelemetrySvc->createCharacteristic(
                      NimBLEUUID(DOCASA_UUID_CMD),    NIMBLE_PROPERTY::WRITE);
  docasaCmdChr->setCallbacks(new DocasaCmdCallbacks());
  // v1.1 (D-028, §10.3): Offline History — read-only; drain cursor armed via
  // the Command characteristic; records served on subsequent reads.
  docasaOfflineChr = docasaTelemetrySvc->createCharacteristic(
                       NimBLEUUID(DOCASA_UUID_OFFLINE), NIMBLE_PROPERTY::READ);
  docasaOfflineChr->setCallbacks(new DocasaOfflineReadCallbacks());
  NimBLECharacteristicCallbacks* subsCb = new DocasaSubsCallbacks();
  docasaAirChr->setCallbacks(subsCb);
  docasaEnvChr->setCallbacks(subsCb);
  docasaSysChr->setCallbacks(subsCb);
  docasaBattChr->setCallbacks(subsCb);

  // Initial snapshot so first reads (e.g. connect during the boot screen) are valid
  char buf[96];
  docasaPublish(docasaAirChr,    buf, docasaBuildAirQuality(buf, sizeof(buf)));
  docasaPublish(docasaEnvChr,    buf, docasaBuildEnvironment(buf, sizeof(buf)));
  docasaPublish(docasaSysChr,    buf, docasaBuildSystemStatus(buf, sizeof(buf)));
  docasaPublish(docasaFilterChr, buf, docasaBuildFilterCounters(buf, sizeof(buf)));
  docasaPublishFilterFull();   // v1.1 (§4.4): overwrite with the "st"-augmented payload
  docasaTelemetrySvc->start();

  NimBLEAdvertising* adv = NimBLEDevice::getAdvertising();
  adv->setName(DOCASA_BLE_NAME);   // v1.1 (D-029): Contract §1 requires the name in ADV
  adv->addServiceUUID(NimBLEUUID(DOCASA_UUID_SERVICE));  // name in ADV, UUID in scan response (Contract §1)
  adv->start();
}

// --- One-time init — the single pre-approved setup() insertion (Plan §7.6) ---
void docasaIoBegin() {
  Serial.printf("\n[DOCASA IO] firmware %s (protocol v%d)\n",
                DOCASA_FW_VERSION, DOCASA_PROTOCOL_VERSION);
  docasaNvsRestore();
  docasaRingBegin();   // v4.2 (D-028): offline-history ring partition + boot id + st restore
  Serial.printf("[DOCASA IO] NVS restored: fs=%llu pwfs=%llu on=%luh\n",
                docasaFanSeconds, docasaPmWeightedFanSec,
                (unsigned long)(docasaPowerOnSeconds / 3600UL));
  docasaBleBegin();
  Serial.printf("[DOCASA IO] BLE advertising as '%s'\n", DOCASA_BLE_NAME);
  docasaLastTickMs     = millis();
  docasaLastNvsWriteMs = millis();
}

// --- 1 Hz work: accumulate → persist (throttled) → publish (Contract §3) ---
void docasaIoTick(unsigned long now) {
  unsigned long dtMs = now - docasaLastTickMs;   // unsigned delta — rollover-safe (Plan §7.2)
  docasaLastTickMs   = now;

  // Shared sub-second residual: exact whole-second accounting for all three counters
  docasaMsResidual += (uint32_t)dtMs;
  uint32_t wholeSec = docasaMsResidual / 1000UL;
  docasaMsResidual -= wholeSec * 1000UL;
  if (wholeSec > 0) {
    docasaFanSeconds       += (uint64_t)currentFanRpm * wholeSec;                        // RPM·s
    docasaPmWeightedFanSec += (uint64_t)currentFanRpm * (uint64_t)pm25Value * wholeSec;  // RPM·µg·s
    docasaPowerOnSeconds   += wholeSec;
    docasaRingTick(wholeSec);   // v4.2 (D-028): stage seconds + window envelope slice (§10.1)
  }

  // 5-min throttled persistence (Plan §4.2 flash-wear math)
  if (now - docasaLastNvsWriteMs >= 300000UL) docasaNvsPersist();

  // 1 Hz snapshot publish
  char buf[96];
  docasaPublish(docasaAirChr, buf, docasaBuildAirQuality(buf, sizeof(buf)));
  docasaPublish(docasaEnvChr, buf, docasaBuildEnvironment(buf, sizeof(buf)));
  docasaPublish(docasaSysChr, buf, docasaBuildSystemStatus(buf, sizeof(buf)));
  uint8_t batt = (uint8_t)constrain(batteryPct, 0, 100);
  docasaBattChr->setValue(&batt, 1);
  if (docasaBattSubscribed) docasaBattChr->notify();
  docasaPublish(docasaFilterChr, buf, docasaBuildFilterCounters(buf, sizeof(buf)));
  docasaPublishFilterFull();   // v1.1 (§4.4): "st"-augmented payload wins the stored value

  // 60 s serial verification dump (G1 observation point)
  docasaTickCount++;
  if (docasaTickCount % 60 == 0) {
    Serial.printf("[DOCASA IO] fs=%llu pwfs=%llu onSec=%lu\n",
                  docasaFanSeconds, docasaPmWeightedFanSec, (unsigned long)docasaPowerOnSeconds);
    // v1.1 (D-027/D-028): exposure basis + ring status in the same dump
    Serial.printf("[DOCASA IO] st=[%lu %lu %lu %lu %lu] dirtyH=%lu ringHead=%lu\n",
                  (unsigned long)docasaStSeconds[0], (unsigned long)docasaStSeconds[1],
                  (unsigned long)docasaStSeconds[2], (unsigned long)docasaStSeconds[3],
                  (unsigned long)docasaStSeconds[4],
                  (unsigned long)((docasaStSeconds[2] + docasaStSeconds[3] +
                                   docasaStSeconds[4]) / 3600UL),
                  (unsigned long)docasaRingHeadSlot);
  }
}

// --- Per-loop service — the single pre-approved loop() insertion ---
void docasaIoService() {
  // On-change extras: event-like transitions push an immediate notify (Plan §3.3)
  if (overallStage != docasaLastStageSent) {
    docasaLastStageSent = overallStage;
    char buf[96];
    docasaPublish(docasaAirChr, buf, docasaBuildAirQuality(buf, sizeof(buf)));
  }
  if (isCharging != docasaLastChgSent || isTrulyFull != docasaLastFullSent) {
    docasaLastChgSent  = isCharging;
    docasaLastFullSent = isTrulyFull;
    char buf[96];
    docasaPublish(docasaSysChr, buf, docasaBuildSystemStatus(buf, sizeof(buf)));
  }

  // 1 Hz scheduler (loop runs ~66 Hz — decimation per Plan §3.3)
  unsigned long now = millis();
  if (now - docasaLastTickMs >= 1000UL) docasaIoTick(now);
}
