
int sensor1 = 2;
int sensor2 = 3;
int OpenEphys = 4;

int valve1 = 8;
int valve2 = 9;

int sensorTrig = 0;
int SensorConf=0;
int pumpOpen = 120;
int flag = 0;
 
// the setup routine runs once when you press reset:
void setup() {                
  // initialize the digital pin as an output.
  Serial.begin(9600); 
  pinMode(valve1, OUTPUT);  
  pinMode(valve2, OUTPUT);
  pinMode(OpenEphys,OUTPUT);

  pinMode(sensor1, INPUT);
  pinMode(sensor2, INPUT);
      
}
 
// the loop routine runs over and over again forever:


void loop() {


//  digitalWrite(valve1, HIGH);   // turn the LED on (HIGH is the voltage level)
//    delay(pumpOpen);               // wait for a second
//    digitalWrite(valve1, LOW);    // turn the LED off by making the voltage LOW 
//
//delay(1000);
//     digitalWrite(valve2, HIGH);   // turn the LED on (HIGH is the voltage level)
//    delay(pumpOpen);               // wait for a second
//    digitalWrite(valve2, LOW);    // turn the LED off by making the voltage LOW 

  if (digitalRead(sensor1)==HIGH && sensorTrig ==0)
{
    digitalWrite(valve2, HIGH);   // turn the LED on (HIGH is the voltage level)
    digitalWrite(OpenEphys, HIGH);
    delay(pumpOpen);               // wait for a second
    digitalWrite(valve2, LOW);    // turn the LED off by making the voltage LOW 
    digitalWrite(OpenEphys, LOW);
    flag = 2;
    SensorConf = 1;
    Serial.println(SensorConf);
    delay(pumpOpen);
    sensorTrig = 1;
}


  if (digitalRead(sensor1)==HIGH && flag ==1)
{
    digitalWrite(valve2, HIGH);   // turn the LED on (HIGH is the voltage level)
    digitalWrite(OpenEphys, HIGH);
    delay(pumpOpen);               // wait for a second
    digitalWrite(valve2, LOW);    // turn the LED off by making the voltage LOW
    digitalWrite(OpenEphys, LOW); 
    flag = 2;
    SensorConf = 1;
    Serial.println(SensorConf);
    delay(pumpOpen);
}

  if (digitalRead(sensor1)==HIGH && flag !=1)
{

    SensorConf = 2;
    Serial.println(SensorConf);
    delay(100);
}




//========================== sensor 2 =====================================================

  if (digitalRead(sensor2)==HIGH && sensorTrig ==0)
{
    digitalWrite(valve1, HIGH);   // turn the LED on (HIGH is the voltage level)
    digitalWrite(OpenEphys, HIGH);
    delay(pumpOpen);               // wait for a second
    digitalWrite(valve1, LOW);    // turn the LED off by making the voltage LOW 
    digitalWrite(OpenEphys, LOW);
    flag = 1;
    SensorConf = 3;
    Serial.println(SensorConf);
    delay(pumpOpen);
    sensorTrig = 1;
}



  if (digitalRead(sensor2)==HIGH && flag ==2)
{
    digitalWrite(valve1, HIGH);   // turn the LED on (HIGH is the voltage level)
    digitalWrite(OpenEphys, HIGH);
    delay(pumpOpen);               // wait for a second
    digitalWrite(valve1, LOW);    // turn the LED off by making the voltage LOW
    digitalWrite(OpenEphys, LOW); 
    flag = 1;
    SensorConf = 3;
    Serial.println(SensorConf);
    delay(pumpOpen);
}

  if (digitalRead(sensor2)==HIGH && flag !=2)
{

    SensorConf = 4;
    Serial.println(SensorConf);
    delay(100);
}




SensorConf = 0;
  // wait a bit for the analog-to-digital converter to stabilize after the last
  // reading:
  //delay(100);
}
