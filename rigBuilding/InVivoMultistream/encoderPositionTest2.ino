// converts gray code from rotary encoder to PWM
// reports distance traveled in 20ms bins

// PWM runs at 122 instead of 490 Hz, and count values are multiplied by 4 to prevent aliasing

// Minimum sampling rate with this program:
// pwm period = 122Hz.  
// Minimum pulse width = 1/122/255*4 = .129 ms 
// Minimum sampling rate (Open Ephys) = 2*1/1.29e-4 = 15,555 Hz

#include <EnableInterrupt.h>
#include <digitalWriteFast.h>
 
#define encoderIntPin 2 
#define encoderPinB 3
#define outputPin 11

int voltageOut = 0;
volatile int addDistance = 0;
volatile bool encoderReadB = 0;

void setup()
{
  Serial.begin(9600);
  TCCR2B = TCCR2B & 0b11111000 | 0x06;
  pinMode(encoderPinB, INPUT_PULLUP);
  digitalWrite(encoderPinB, LOW);
  pinMode(outputPin, OUTPUT);
  pinMode(encoderIntPin, INPUT_PULLUP);
  enableInterrupt(encoderIntPin, encoderInterrupt, RISING);
}

void loop()
{
  delay(20);
  //voltageOut = addDistance % 1024;
  //voltageOut = voltageOut/1024*255;
  addDistance = addDistance * 4;
  if (addDistance>255)
  {voltageOut = 255;}
  else
  {voltageOut = addDistance;}
  analogWrite(outputPin, voltageOut);
  Serial.print(addDistance);
  Serial.print("\t");
  addDistance = 0;
}

//checks pin a to see if it was simultaneously activated
//only registers movement in single direction
void encoderInterrupt()
{
  encoderReadB = digitalReadFast(encoderPinB);
  if (!encoderReadB)
  addDistance++;
}
