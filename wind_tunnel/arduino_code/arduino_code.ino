const int potPin = A3;      // Analog input for the potentiometer (pot 3590s-2-103L)

// Constants for the pot specs
const long STEPS_PER_REV = 10000; 
const float DEGREES_PER_REV = 3600.0;  // Total degrees per revolution

float offsetAngle = 0;      // Zero offset
bool testActive = false;    // Flag to control test logging

unsigned long lastLogTime = 0;
const unsigned long logInterval = 300;  // Log data every 1 ms

// Reads the potentiometer and converts the ADC value (0–1023) to angle in degrees
float readAngle() {
  int rawValue = analogRead(potPin);
  // Map rawValue to steps then convert to degrees:
  // steps = (rawValue / 1023.0) * STEPS_PER_REV, so angle = (rawValue / 1023.0) * DEGREES_PER_REV
  float angle = (rawValue / 1023.0) * DEGREES_PER_REV;
  return angle;
}

// Wrap the angle into the range -DEGREES_PER_REV/2 to +DEGREES_PER_REV/2 (i.e. -1800° to +1800°)
float wrapAngle(float angle) {
  while (angle > DEGREES_PER_REV / 2) angle -= DEGREES_PER_REV;
  while (angle < -DEGREES_PER_REV / 2) angle += DEGREES_PER_REV;
  return angle;
}

void setup() {
  Serial.begin(9600);
  // Print a header for CSV logging
  Serial.println("Timestamp,DeltaAngle");
  Serial.println("Ready. Commands: 'z' to zero, 's' to start, 'e' to end.");
}

void loop() {
  // Process incoming serial commands
  if (Serial.available() > 0) {
    char c = Serial.read();
    if (c == 'z' || c == 'Z') {
      offsetAngle = readAngle();
      Serial.print("Zero set at: ");
      Serial.println(offsetAngle);
    }
    else if (c == 's' || c == 'S') {
      testActive = true;
      Serial.println("Test started");
    }
    else if (c == 'e' || c == 'E') {
      testActive = false;
      Serial.println("Test ended");
      Serial.println("STOP"); // Marker for Python to stop logging
    }
  }
  
  // Log data if test is active
  if (testActive) {
    float currentAngle = readAngle();
    float deltaAngle = wrapAngle(currentAngle - offsetAngle);
    unsigned long now = millis();
    if (now - lastLogTime >= logInterval) {
      Serial.print(now);
      Serial.print(",");
      Serial.println(deltaAngle);
      lastLogTime = now;
    }
  }
  delay(10);
}
