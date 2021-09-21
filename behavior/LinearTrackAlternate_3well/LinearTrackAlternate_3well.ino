/*
  LinearTrackAlternate_3well

  For use on a linear track with two end wells and one well in the middle of the track. Rat must
  follow the sequence end 1 -> middle -> end 2 -> middle -> end 1 to obtain reward. Note that rat
  will get double reward at one end if it visits the middle well first as code is written on 
  19 FEB 2020.

  obtained 10 Oct 2019 (for 2 water wells)
  from Bapun Giri
  modified by 19 Feb 2020 (for 3 water wells)
  by Nat Kinsky
 */
int sensor1 = 2; // end well 1
int sensor2 = 3; // end well 2
int sensor3 = 10; // middle well
int OpenEphys = 4;

int valve1 = 8; // end valve 1
int valve2 = 9; // end valve 2
int valve3 = 11; // middle valve

int sensorTrig = 0; // 0 = start (no wells visited), 1 = thereafter (at least one well has been visited)
int SensorConf=0; // legacy code to track water well delivery and id false positives - not checked recently (2/19/2020)
int pumpOpen = 500; // ms, time each valve is open after a lick.
int next_well = 0; // initialize next and last well values
int last_well = 0;
 
// the setup routine runs once when you press reset:
void setup() {                
  // initialize the digital pin as an output.
  Serial.begin(9600); 
  pinMode(valve1, OUTPUT);  
  pinMode(valve2, OUTPUT);
  pinMode(valve3, OUTPUT);
  pinMode(OpenEphys,OUTPUT);

  pinMode(sensor1, INPUT);
  pinMode(sensor2, INPUT);
  pinMode(sensor3, INPUT);
      
}
 
// the loop routine runs over and over again forever:


void loop() {


// Leftover tidbits
//  digitalWrite(valve1, HIGH);   // turn the LED on (HIGH is the voltage level)
//    delay(pumpOpen);               // wait for a second
//    digitalWrite(valve1, LOW);    // turn the LED off by making the voltage LOW 
//
//delay(1000);
//     digitalWrite(valve2, HIGH);   // turn the LED on (HIGH is the voltage level)
//    delay(pumpOpen);               // wait for a second
//    digitalWrite(valve2, LOW);    // turn the LED off by making the voltage LOW 

//========================== sensor 1 =====================================================


  // first well visited is end 1 -> open middle and end 1
  if (digitalRead(sensor1)==HIGH && sensorTrig ==0)
{
    digitalWrite(valve1, HIGH);   // turn the LED on (HIGH is the voltage level) for end 2
    digitalWrite(valve3, HIGH);   // turn the LED on (HIGH is the voltage level) for middle
    digitalWrite(OpenEphys, HIGH);
    delay(pumpOpen);               // wait for a second
    digitalWrite(valve1, LOW);    // turn the LED off by making the voltage LOW 
    digitalWrite(valve3, LOW);
    digitalWrite(OpenEphys, LOW);
    next_well = 3; // initialize next and last well tracking
    last_well = 1;
    SensorConf = 1;
    Serial.println(SensorConf); // write water delivery info to serial port
    delay(pumpOpen);
    sensorTrig = 1;
}

  // visits to 1 from middle -> open middle only
  if (digitalRead(sensor1)==HIGH && (next_well ==1 || next_well==0) && last_well ==3)
{
    digitalWrite(valve3, HIGH);   // turn the LED on (HIGH is the voltage level) at middle well
    digitalWrite(OpenEphys, HIGH);
    delay(pumpOpen);               // wait for a second
    digitalWrite(valve3, LOW);    // turn the LED off by making the voltage LOW
    digitalWrite(OpenEphys, LOW); 
    next_well = 3; // update last well visited and next well to visit
    last_well = 1;
    SensorConf = 1; // write water delivery info to serial port
    Serial.println(SensorConf);
    delay(pumpOpen);
}

  // don't do anything if not next designated well & not first visit
  if (digitalRead(sensor1)==HIGH && next_well !=1 && sensorTrig == 1)  // don't do anything if licking continually or at wrong port
{

    SensorConf = 2; 
    Serial.println(SensorConf); // write water delivery info to serial port
    delay(100);
}




//========================== sensor 2 =====================================================

  // first well visited is end 2 - open middle and 2
  if (digitalRead(sensor2)==HIGH && sensorTrig ==0)  
{
    digitalWrite(valve2, HIGH);   // turn the LED on (HIGH is the voltage level) and open middle port
    digitalWrite(valve3, HIGH);
    digitalWrite(OpenEphys, HIGH);
    delay(pumpOpen);               // wait for a second
    digitalWrite(valve2, LOW);    // turn the LED off by making the voltage LOW 
    digitalWrite(valve3, LOW);
    digitalWrite(OpenEphys, LOW);
    next_well = 3;
    last_well = 2;
    SensorConf = 3; 
    Serial.println(SensorConf); // write water delivery info to serial port
    delay(pumpOpen);
    sensorTrig = 1;
}


  // visits to 2 from middle -> open middle only
  if (digitalRead(sensor2)==HIGH && (next_well == 0 || next_well ==2) && last_well==3)
{
    digitalWrite(valve3, HIGH);   // turn the LED on (HIGH is the voltage level)
    digitalWrite(OpenEphys, HIGH);
    delay(pumpOpen);               // wait for a second
    digitalWrite(valve3, LOW);    // turn the LED off by making the voltage LOW
    digitalWrite(OpenEphys, LOW); 
    next_well = 3;
    last_well = 2;
    SensorConf = 3;
    Serial.println(SensorConf); // write water delivery info to serial port
    delay(pumpOpen);
}

  // don't do anything if not next designated well & not first visit
  if (digitalRead(sensor2)==HIGH && next_well !=2 && sensorTrig ==1)
{

    SensorConf = 4;
    Serial.println(SensorConf); // write water delivery info to serial port
    delay(100);
}

//========================== sensor 3 =====================================================

  // first visit is to middle - open both ends and middle (will get double reward at second end visited...)
  if (digitalRead(sensor3)==HIGH && sensorTrig ==0)  // first well visited is middle
{
    digitalWrite(valve1, HIGH);   // turn the LED on (HIGH is the voltage level) and open port 
    digitalWrite(valve2, HIGH);
    digitalWrite(valve3, HIGH);   // ditto for middle
    digitalWrite(OpenEphys, HIGH);
    delay(pumpOpen);               // wait for a second
    digitalWrite(valve1, LOW);    // turn the LED off by making the voltage LOW 
    digitalWrite(valve2, LOW);
    digitalWrite(valve3, LOW);
    digitalWrite(OpenEphys, LOW);
    next_well = 0;
    last_well = 3;
    SensorConf = 3; 
    Serial.println(SensorConf); // write water delivery info to serial port
    delay(pumpOpen);
    sensorTrig = 1;
}

  // visits to middle from end 1 -> open 2 only
  if (digitalRead(sensor3)==HIGH && next_well ==3 && last_well==1)
{
    digitalWrite(valve2, HIGH);   // turn the LED on (HIGH is the voltage level)
    digitalWrite(OpenEphys, HIGH);
    delay(pumpOpen);               // wait for a second
    digitalWrite(valve2, LOW);    // turn the LED off by making the voltage LOW
    digitalWrite(OpenEphys, LOW); 
    next_well = 2;
    last_well = 3;
    SensorConf = 3;
    Serial.println(SensorConf); // write water delivery info to serial port
    delay(pumpOpen);
}

  // visits to middle from 2 -> open 1 only
  if (digitalRead(sensor3)==HIGH && next_well ==3 && last_well==2)
{
    digitalWrite(valve1, HIGH);   // turn the LED on (HIGH is the voltage level)
    digitalWrite(OpenEphys, HIGH);
    delay(pumpOpen);               // wait for a second
    digitalWrite(valve1, LOW);    // turn the LED off by making the voltage LOW
    digitalWrite(OpenEphys, LOW); 
    next_well = 1;
    last_well = 3;
    SensorConf = 3;
    Serial.println(SensorConf); // write water delivery info to serial port
    delay(pumpOpen);
}

  // don't do anything if not next designated well & not first visit
  if (digitalRead(sensor2)==HIGH && next_well !=3 && sensorTrig ==1)
{

    SensorConf = 4;
    Serial.println(SensorConf); // write water delivery info to serial port
    delay(100);
}




SensorConf = 0;
  // wait a bit for the analog-to-digital converter to stabilize after the last
  // reading:
  //delay(100);
}
