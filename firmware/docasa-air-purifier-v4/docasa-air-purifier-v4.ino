#define FASTLED_ESP32_I2S true
#include <FastLED.h>
#include <SPI.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_ST7789.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_BME680.h>
#include "Adafruit_PM25AQI.h"

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
