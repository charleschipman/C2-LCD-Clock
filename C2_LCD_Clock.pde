/*
   C2 Clock V1
   Charles Chipman Electronics 2013
   http://www.charleschipman.com
*/

#include <TinyWireM.h>
#include <ShiftRegLCD123.h>
#include <EEPROM.h>

char dayofweek[8][4] = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"};
char monthofyear[13][4] = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul","Aug", "Sep", "Oct", "Nov", "Dec"};
char menuItem[4][14] = {"Run Clock    ", "Run Big Clock", "Set Clock    "};
byte button, scale, half, temp, a;
byte weekDay, month, monthDay, year;
int hour;
int minute;
int second;
unsigned long startTime;
byte x=0;
byte LT[8]={B00111,B01111,B11111,B11111,B11111,B11111,B11111,B11111};
byte UB[8]={B11111,B11111,B11111,B00000,B00000,B00000,B00000,B00000};
byte RT[8]={B11100,B11110,B11111,B11111,B11111,B11111,B11111,B11111};
byte LL[8]={B11111,B11111,B11111,B11111,B11111,B11111,B01111,B00111};
byte LB[8]={B00000,B00000,B00000,B00000,B00000,B11111,B11111,B11111};
byte LR[8]={B11111,B11111,B11111,B11111,B11111,B11111,B11110,B11100};
byte UMB[8]={B11111,B11111,B11111,B00000,B00000,B00000,B11111,B11111};
byte LMB[8]={B11111,B00000,B00000,B00000,B00000,B11111,B11111,B11111};
ShiftRegLCD123 srlcd(1, 4, SRLCD123);

void setup(){
   TinyWireM.begin();
   srlcd.begin(16,2);
   pinMode(3, INPUT);
    
   srlcd.createChar(8,LT);
   srlcd.createChar(1,UB);
   srlcd.createChar(2,RT);
   srlcd.createChar(3,LL);
   srlcd.createChar(4,LB);
   srlcd.createChar(5,LR);
   srlcd.createChar(6,UMB);
   srlcd.createChar(7,LMB);

   srlcd.backlightOn(); // Fix circuit
   charlesChipman();
   srlcd.clear();

}

void loop(){
   signed int menu=0;
   scale = EEPROM.read(0);
   startTime = millis();
   delay(50);

   while ( 1 ) {

     srlcd.setCursor(0,0);
     srlcd.print("Select Option");
     srlcd.setCursor(0,1);
     srlcd.print(menuItem[menu]);
     button = buttonCheck();
     if ( millis() - startTime >= 10000) {
       menu=0;
       break;
     }
     if ( button == 2 ) menu--;
     if ( button == 3 ) menu++;
     if ( button == 1 ) break;
     delay(200);
     if ( menu < 0 ) menu=2;
     if ( menu > 2 ) menu=0;
   }
   delay(200);
   
   switch (menu) {
     case 0:
       srlcd.clear();
       runClock();
       break;
     case 1:
       srlcd.clear();
       while(1) {
          bigClock( scale );
          button = buttonCheck();
          if ( button == 1 ) break;
           delay(200);
       }
       break;
     case 2:
       readRTC();
       srlcd.clear();
       printClock(0);
       setClock();
       break;
     default: 
       break;
   }
   delay(200);
   srlcd.clear();
}

byte buttonCheck() {
    int buttonVal = analogRead(3);
    if ( buttonVal >= 300 && buttonVal <= 340 ) {
      return 1;
    } else if ( buttonVal >= 620 && buttonVal <= 660 ) {
      return 2;
    } else if ( buttonVal >= 1000 ) {
      return 3;
    } else {
      return 0;
    }
}

byte decToBcd(byte val) {
  return ( (val/10*16) + (val%10) );
}

byte bcdToDec(byte val) {
  return ( (val/16*10) + (val%16) );
}

void readRTC() {
    TinyWireM.beginTransmission(0x68);
    TinyWireM.send(0x00);
    TinyWireM.endTransmission();
    TinyWireM.requestFrom(0x68, 7);
    second = bcdToDec(TinyWireM.receive());
    minute = bcdToDec(TinyWireM.receive());
    hour = bcdToDec(TinyWireM.receive());
    weekDay = bcdToDec(TinyWireM.receive());
    monthDay = bcdToDec(TinyWireM.receive());
    month = bcdToDec(TinyWireM.receive());
    year = bcdToDec(TinyWireM.receive());
}

void printClock( byte ck ) {
    if ( ck == 1 ) {
       if ( scale == 12 ) srlcd.setCursor(2,0);
       if ( scale == 24 ) srlcd.setCursor(4,0);
    } else {
       srlcd.setCursor(0,0);
    }
    if ( hour <= 12 ) half=0;
    if ( hour >= 12 ) half=1;
    temp=hour;
    if ( scale == 12 ) {
       if ( temp >= 13 ) temp=temp-12;
       if ( temp == 0 ) temp=12;
    }
    if ( temp <= 9 ) srlcd.print("0");
    srlcd.print(temp);
    srlcd.print(":");
    if ( minute <= 9 ) srlcd.print("0");
    srlcd.print(minute);
    srlcd.print(":");
    if ( second <= 9 ) srlcd.print("0");
    srlcd.print(second);
    srlcd.print(" ");
    if ( scale == 12 ) {
       if (half == 1 ) {
          srlcd.print("PM");
       } else {
          srlcd.print("AM");
       }
    }
    srlcd.setCursor(0,1);
    srlcd.print(dayofweek[weekDay-1]);
    srlcd.print(" ");
    srlcd.print(monthofyear[month-1]);
    srlcd.print(" ");
    if ( monthDay <= 9 ) srlcd.print("0");
    srlcd.print(monthDay);
    srlcd.print(" 20");
    srlcd.print(year);
}

void runClock() {
   while ( 1 ) {
      readRTC();
      printClock(1);
      srlcd.setCursor(0,1);
      srlcd.print(dayofweek[weekDay-1]);
      srlcd.print(" ");
      srlcd.print(monthofyear[month-1]);
      srlcd.print(" ");
      if ( monthDay <= 9 ) srlcd.print("0");
      srlcd.print(monthDay);
      srlcd.print(" 20");
      srlcd.print(year);
      button = buttonCheck();
      if ( button == 2 ) minute--;
      if ( button == 3 ) minute++;
      if ( button == 1 ) break;
   }
}

void setClock() {
     srlcd.blink();
     srlcd.setCursor(9,0);
     srlcd.print(scale);
   while ( 1 ) {                             // Set Weekday
     srlcd.setCursor(0,1);
     srlcd.print(dayofweek[weekDay-1]);
     srlcd.setCursor(0,1);
     button = buttonCheck();
     if ( button == 2 ) weekDay--;
     if ( button == 3 ) weekDay++;
     if ( button == 1 ) break;
     delay(200);
     if ( weekDay < 1 ) weekDay=7;
     if ( weekDay > 7 ) weekDay=1;
   }
   delay(200);
   while ( 1 ) {                             // Set Month
     srlcd.setCursor(4,1);
     srlcd.print(monthofyear[month-1]);
     srlcd.setCursor(4,1);
     button = buttonCheck();
     if ( button == 2 ) month--;
     if ( button == 3 ) month++;
     if ( button == 1 ) break;
     delay(200);
     if ( month < 1 ) month=12;
     if ( month > 13 ) month=1;
   }
   delay(200);
     
   while ( 1 ) {                             // Set Day
     srlcd.setCursor(8,1);
     if ( monthDay <= 9 ) srlcd.print("0");
     srlcd.print(monthDay);
     srlcd.setCursor(8,1);
     button = buttonCheck();
     if ( button == 2 ) monthDay--;
     if ( button == 3 ) monthDay++;
     if ( button == 1 ) break;
     delay(200);
     if ( monthDay < 1 ) monthDay=31;
     if ( monthDay > 31 ) monthDay=1;
   }
   delay(200);
   
   while ( 1 ) {                             // Set Year
     srlcd.setCursor(13,1);
     if ( year <= 9 ) srlcd.print("0");
     srlcd.print(year);
     srlcd.setCursor(11,1);
     button = buttonCheck();
     if ( button == 2 ) year--;
     if ( button == 3 ) year++;
     if ( button == 1 ) break;
     delay(200);
     if ( year < 0 ) year=99;
     if ( year > 99 ) year=0;
   }
   delay(200);

   while ( 1 ) {                             // Set Hour
     srlcd.setCursor(0,0);
     if ( hour <= 9 ) srlcd.print("0");
     srlcd.print(hour);
     srlcd.setCursor(0,0);
     button = buttonCheck();
     if ( button == 2 ) hour--;
     if ( button == 3 ) hour++;
     if ( button == 1 ) break;
     delay(200);
     if ( hour < 0 ) hour=23;
     if ( hour > 23 ) hour=0;
   }
   delay(200);
     
   while ( 1 ) {                             // Set Minute
     srlcd.setCursor(3,0);
     if ( minute <= 9 ) srlcd.print("0");
     srlcd.print(minute);
     srlcd.setCursor(3,0);
     button = buttonCheck();
     if ( button == 2 ) minute--;
     if ( button == 3 ) minute++;
     if ( button == 1 ) break;
     delay(200);
     if ( minute <= -1 ) minute=59;
     if ( minute >= 60 ) minute=0;
     }
   delay(200);
   
   while ( 1 ) {                             // Set Second
     srlcd.setCursor(6,0);
     if ( second <= 9 ) srlcd.print("0");
     srlcd.print(second);
     srlcd.setCursor(6,0);
     button = buttonCheck();
     if ( button == 2 ) second--;
     if ( button == 3 ) second++;
     if ( button == 1 ) break;
     delay(200);
     if ( second <= -1 ) second=59;
     if ( second >= 60 ) second=0;
     }
     delay(200);
     
     while ( 1 ) {                           // Set 12 / 24
     srlcd.setCursor(9,0);
     if ( scale == 12 ) {
        srlcd.print("12");
     } else {
        srlcd.print("24");
     }
     srlcd.setCursor(9,0);
     button = buttonCheck();
     if ( button == 2 ) scale=12;
     if ( button == 3 ) scale=24;
     if ( button == 1 ) break;
     delay(200);
   }
   delay(100);
   EEPROM.write(0, scale);
   delay(100);
   TinyWireM.beginTransmission(0x68);
   TinyWireM.send(0x00);
   TinyWireM.send(decToBcd(second));
   TinyWireM.send(decToBcd(minute));
   TinyWireM.send(decToBcd(hour));
   TinyWireM.send(decToBcd(weekDay));
   TinyWireM.send(decToBcd(monthDay));
   TinyWireM.send(decToBcd(month));
   TinyWireM.send(decToBcd(year));
   TinyWireM.send(0x00);
   TinyWireM.endTransmission();
   srlcd.clear();
   srlcd.noBlink();
   delay(500);
}

void custom0() {
   srlcd.setCursor(x, 0);
   srlcd.write(8);
   srlcd.write(1);
   srlcd.write(2);
   srlcd.setCursor(x, 1);
   srlcd.write(3);
   srlcd.write(4);
   srlcd.write(5);
}

void custom1() {
   srlcd.setCursor(x,0);
   srlcd.print(" ");
   srlcd.write(1);
   srlcd.write(2);
   srlcd.setCursor(x,1);
   srlcd.print("  ");
   srlcd.write(5);
}

void custom2() {
   srlcd.setCursor(x,0);
   srlcd.write(6);
   srlcd.write(6);
   srlcd.write(2);
   srlcd.setCursor(x, 1);
   srlcd.write(3);
   srlcd.write(7);
   srlcd.write(7);
}

void custom3() {
   srlcd.setCursor(x,0);
   srlcd.write(6);
   srlcd.write(6);
   srlcd.write(2);
   srlcd.setCursor(x, 1);
   srlcd.write(7);
   srlcd.write(7);
   srlcd.write(5); 
}

void custom4() {
   srlcd.setCursor(x,0);
   srlcd.write(3);
   srlcd.write(4);
   srlcd.write(2);
   srlcd.setCursor(x, 1);
   srlcd.print("  ");
   srlcd.write(5);
}

void custom5() {
   srlcd.setCursor(x,0);
   srlcd.write(8);
   srlcd.write(6);
   srlcd.write(6);
   srlcd.setCursor(x, 1);
   srlcd.write(7);
   srlcd.write(7);
   srlcd.write(5);
}

void custom6() {
   srlcd.setCursor(x,0);
   srlcd.write(8);
   srlcd.write(6);
   srlcd.write(6);
   srlcd.setCursor(x, 1);
   srlcd.write(3);
   srlcd.write(7);
   srlcd.write(5);
}

void custom7() {
   srlcd.setCursor(x,0);
   srlcd.write(1);
   srlcd.write(1);
   srlcd.write(2);
   srlcd.setCursor(x, 1);
   srlcd.print("  ");
   srlcd.write(8);
}

void custom8() {
   srlcd.setCursor(x,0);
   srlcd.write(8);
   srlcd.write(6);
   srlcd.write(2);
   srlcd.setCursor(x, 1);
   srlcd.write(3);
   srlcd.write(7);
   srlcd.write(5);
}

void custom9() {
   srlcd.setCursor(x,0);
   srlcd.write(8);
   srlcd.write(6);
   srlcd.write(2);
   srlcd.setCursor(x, 1);
   srlcd.print("  ");
   srlcd.write(5);
}

void bigClock( int mode ){
   readRTC();
   srlcd.setCursor(0, 0);
   byte hou = hour;
   if( scale == 12 ) {
      if ( hou >= 13 ) hou=hou-12;
   }
   if (hou == 0) {  
        custom0();
        x = x + 4;
        custom0();
      } else if (hou == 1) {
        custom0();
        x = x + 4;
        custom1();
      } else if (hou == 2) {
        custom0();
        x = x + 4;
        custom2();
      } else if (hou == 3) {
        custom0();
        x = x + 4;
        custom3();
      } else if (hou == 4) {
        custom0();
        x = x + 4;
        custom4();
      } else if (hou == 5) {
        custom0();
        x = x + 4;
        custom5();
      } else if (hou == 6) {
        custom0();
        x = x + 4;
        custom6();
      } else if (hou == 7) {
        custom0();
        x = x + 4;
        custom7();
      } else if (hou == 8) {
        custom0();
        x = x + 4;
        custom8();
      } else if (hou == 9) {
        custom0();
        x = x + 4;
        custom9();
      } else if (hou == 10) {
        custom1();
        x = x + 4;
        custom0();
      } else if (hou == 11) {
        custom1();
        x = x + 4;
        custom1();
      } else if (hou == 12) {
        custom1();
        x = x + 4;
        custom2();
      } else if (hou == 13) {
        custom1();
        x = x + 4;
        custom3();
      } else if (hou == 14) {
        custom1();
        x = x + 4;
        custom4();
      } else if (hou == 15) {
        custom1();
        x = x + 4;
        custom5();
      } else if (hou == 16) {
        custom1();
        x = x + 4;
        custom6();
      } else if (hou == 17) {
        custom1();
        x = x + 4;
        custom7();
      } else if (hou == 18) {
        custom1();
        x = x + 4;
        custom8();
      } else if (hou == 19) {
        custom1();
        x = x + 4;
        custom9();
      } else if (hou == 20) {
        custom2();
        x = x + 4;
        custom0();
      } else if (hou == 21) {
        custom2();
        x = x + 4;
        custom1();
      } else if (hou == 22) {
        custom2();
        x = x + 4;
        custom2();
      } else if (hou == 23) {
        custom2();
        x = x + 4;
        custom3();
      } else if (hou == 24) {
        custom2();
        x = x + 4;
        custom4();
      } 
   x=x+4;
   int y = minute/10;
   if (y == 0) { 
          custom0();
          x = x + 4;
      } else if (y == 1) {
          custom1();
          x = x + 4;
      } else if (y == 2) {
          custom2();
          x = x + 4;
      } else if (y == 3) {
          custom3();
          x = x + 4;
      } else if (y == 4) {
          custom4();
          x = x + 4;
      } else if (y == 5) {
          custom5();
          x = x + 4;
      }
   int m = minute - y*10;
   if (m == 0) {  
        custom0();
      } else if (m == 1) {
        custom1();
      } else if (m == 2) {
        custom2();
      } else if (m == 3) {
        custom3();
      } else if (m == 4) {
        custom4();
      } else if (m == 5) {
        custom5();
      } else if (m == 6) {
        custom6();
      } else if (m == 7) {
        custom7();
      } else if (m == 8) {
        custom8();
      } else if (m == 9) {
        custom9();
   }
   x=0;
}

void charlesChipman() {
    srlcd.clear();
    srlcd.setCursor(0,0);
    srlcd.print("Charles Chipman");
    srlcd.setCursor(0,1);
    srlcd.print("  Electronics  ");
    for( int x=0; x<10; x++ ) {
     srlcd.setCursor(0,1);
     srlcd.print("*");
     srlcd.setCursor(15,1);
     srlcd.print(" ");
     delay(300);
     srlcd.setCursor(0,1);
     srlcd.print(" ");
     srlcd.setCursor(15,1);
     srlcd.print("*");
     delay(300);
    }
}
