#include "DynamixelSerial1.h"
#include "StringStream.h"
#include "TimerThree.h"

/*
HOW TO CONNECT THE ARDUINO

This needs a Mega or something with at least three serial ports.
The default serial port (class Serial) is used for communication with the computer.
The first serial port (class Serial1) is used for transmitting to the Dynamixels.
The second serial port (class Serial2) is used for receiving from the Dynamixels.
We need two serial ports for the Dynamixels because they use only one pin for TX
and RX (full duplex), but the Arduino cannot deal with TX1 and RX1 shorted together.

Connect things as follows:
- Arduino pin TX1 to Dynamixel data pin (yellow)
- Arduino pin RX2 to Dynamixel data pin (yellow)
- Ground to Dynamixel ground pin
- Arduino ground to the same ground!
- Probably just power the Arduino from the computer, as it will be connected
  anyway for receiving commands
- Power the Dynamixels with 12V or appropriate (we use AX-18A motors). Also use
  the same ground!
  
By the way, if you are using a Seeeduino Mega, you need to push all three switches
towards the center of the board so that it will let you program it.

*/

#define LED 13
#define SPEED 100

int g_record[100][10], g_record_index, g_record_motors[10];
bool g_recording = false;
int g_motors[32] = { 0 };
int g_speed = SPEED;
struct Joint
{
  String name; // if strcmp(name, "")==0 this joint is free
  int motors[5];
  int signs[5];
  int homes[5];
} g_joints[10];

void setup()
{
  pinMode(LED, OUTPUT);
  Serial.begin(9600);
  Dynamixel.begin(1000000, 2); // 1 Mbps, ignored direction pin
  Timer3.initialize(1000000);
  Timer3.attachInterrupt(isr);
  Serial.println("=== Dynamixel controller initialized ===");
}

void isr()
{
  if (g_recording)
  {
    Serial.println("boo");
    for (int i = 0; i < 10; ++i)
    {
      if (g_record_motors[i] == 0) break;
      g_record[g_record_index][i] = Dynamixel.readPosition(g_record_motors[i]);
    }
    g_record_index++;
  }
}

void add_to_list(int *list, int item)
{
    int i;
    for (i = 0; list[i] > 0; ++i)
    {
      if (list[i] == item)
      {
        return;
      }
    }
    list[i] = item;
}

int find_joint(String name)
{
    for (int i = 0; i < sizeof(g_joints)/sizeof(Joint); ++i)
    {
        if (name == g_joints[i].name)
        {
            return i;
        }
    }
    return -1;
}

void shut_down_everything()
{
  for (int i = 0; g_motors[i] > 0; ++i)
  {
    // the only way to stop a dynamixel is to command it to its current position, very slowly
    Dynamixel.moveSpeed(g_motors[i], Dynamixel.readPosition(g_motors[i]), 1);
  }
  Serial.println("== EMERGENCY STOP ==");
}

void read_motor_position(int motor)
{
    Serial.print("Motor #");
    Serial.print(motor);
    Serial.print(" position = ");
    Serial.print(Dynamixel.readPosition(motor));
    Serial.print(", load = ");
    Serial.println(Dynamixel.readLoad(motor));
}

void move_motor_to(int motor, int goal)
{
  add_to_list(g_motors, motor);
  Dynamixel.moveSpeed(motor, goal, g_speed);
  Serial.print("Moving motor #");
  Serial.print(motor);
  Serial.print(" to position ");
  Serial.println(goal);
}

void process_command(const char buf[])
{
  StringStream stream(buf);

  char c = stream.read(); // first char is the command
  stream.read(); // eat the space

  switch (c)
  {
    case 'h': // print help message
        Serial.print(
"Dynamixel Control Interface\r\n"
"\r\n"
"Commands:\r\n"
"    h               print this help message\r\n"
"                    repeat last command (just press enter)\r\n"
"    r [id]*         read positions (if no arguments, read all)\r\n"
"\r\n"
"    S               EMERGENCY STOP (all motors)\r\n"
"\r\n"
"    s [id goal]*    set positions\r\n"
"                      set motors to given values\r\n"
"                        e.g. 's 1 512 2 256'\r\n"
"    a [id rgoal]+   set relative positions\r\n"
"                      DANGER be careful that you don't make the motors fight each other!\r\n"
"\r\n"
"    J [name [id_sign]+]    set up a joint (do a read just before)\r\n"
"                             no arguments: list all joints\r\n"
"                             otherwise, define a joint\r\n"
"                               e.g. 'J base 1+' or 'J shoulder 2+ 3-'\r\n"
"                               maximum number of joints: 10\r\n"
"                               maximum number of motors in a joint: 5\r\n"
"                               by the way, you can't use a capital S in a joint name\r\n"
"                               because that would trigger an emergency stop\r\n"
"\r\n"
"    H [name]*              re-home joint(s) (do a read just before)\r\n"
"\r\n"
"    j [name rgoal?]*       set joint positions\r\n"
"                             no arguments: set all joints to home\r\n"
"    k [name rgoal?]*       set relative joint positions\r\n"
"                             no arguments: set all joints to home\r\n"
"\r\n"
"    z [milliseconds]?    sleep (no argument: 1 second)\r\n"
"    m [speed]?      set speed (default 100)\r\n"
"\r\n"
"    R [id]+         start recording given motors\r\n"
"    R               stop recording and dump data\r\n"
"    F filename      start named script\r\n"
"    W               save in-progress script\r\n"
"    L               list saved scripts\r\n"
"    P filename      play named script\r\n");
        break;

      case 'r': // read position(s)
        if (stream.available())
        {
            while (stream.available())
            {
                read_motor_position(stream.parseInt());
            }
        }
        else
        {
            for (int i = 0; g_motors[i] > 0; ++i)
            {
                read_motor_position(g_motors[i]);
            }
        }
        break;

      case 's': // set position(s)
      case 'a': // set position(s) (relative)
        if (stream.available())
        {
            int motor, goal;
            while (stream.available())
            {
                motor = stream.parseInt();
                goal = stream.parseInt();
                move_motor_to(motor, goal + (c == 's' ? 0 : Dynamixel.readPosition(motor)));
            }
        }
        break;

      case 'J': // set up a joint
          if (stream.available())
          { // create new joint
              int i = find_joint("");
              if (i == -1)
              {
                  Serial.println("No more room for joints!");
              }
              else
              {
                  g_joints[i].name = stream.readStringUntil(' ');
                  for (int j = 0; stream.available(); ++j)
                  {
                      g_joints[i].motors[j] = stream.parseInt();
                      g_joints[i].signs[j] = stream.read() == '+';
                      g_joints[i].homes[j] = Dynamixel.readPosition(g_joints[i].motors[j]);
                  }
                  Serial.println("Created joint " + g_joints[i].name);
              }
          }
          else
          { // list all joints
              for (int i = 0; i < sizeof(g_joints)/sizeof(Joint); ++i)
              {
                  if (g_joints[i].name != "")
                  {
                      Serial.print(g_joints[i].name);
                      Serial.print('\t');
                      for (int j = 0; j < sizeof(g_joints[i].motors)/sizeof(int); ++j)
                      {
                          if (g_joints[i].motors[j] == 0) break;
                          Serial.print(g_joints[i].motors[j]);
                          Serial.print(g_joints[i].signs[j] ? '+' : '-');
                          Serial.print('(');
                          Serial.print(g_joints[i].homes[j]);
                          Serial.print(')');
                          Serial.print(' ');
                      }
                      Serial.println();
                  }
              }
          }
          break;
      case 'D': // delete joint
      {
          String name = stream.readString();
          int i = find_joint(name);
          if (i > -1)
          {
              Serial.println("Deleted joint " + name);
              g_joints[i].name = "";
          }
          else
          {
              Serial.println("No such joint " + name + "!");
          }
          break;
      }
      case 'H': // re-home joint(s)
          while (stream.available())
          {
              String name = stream.readStringUntil(' ');
              int i = find_joint(name);
              if (i > -1)
              {
                  for (int j = 0; j < sizeof(g_joints[i].motors)/sizeof(int); ++j)
                  {
                      if (g_joints[i].motors[j] == 0) break;
                      move_motor_to(g_joints[i].motors[j], g_joints[i].homes[j]);
                  }
              }
              else
              {
                  Serial.println("No such joint " + name + "!");
              }
          }
          break;
      case 'j': // set joint(s) positions
      case 'k': // set joint(s) positions (relative)
        while (stream.available())
        {
            String name = stream.readStringUntil(' ');
            int i = find_joint(name);
            int n = stream.parseInt();
            if (i > -1)
            {
                for (int j = 0; j < sizeof(g_joints[i].motors)/sizeof(int); ++j)
                {
                    if (g_joints[i].motors[j] == 0) break;
                    move_motor_to(g_joints[i].motors[j], (n * (g_joints[i].signs[j] ? 1 : -1))
                                                         + (c == 'j'
                                                            ? g_joints[i].homes[j]
                                                            : Dynamixel.readPosition(g_joints[i].motors[j])));
                }
            }
            else
            {
                Serial.println("No such joint " + name + "!");
            }
        }
        break;
        
      case 'z': // sleep
      {
        int ms = stream.available() ? stream.parseInt() : 1000;
        Serial.print("Wake me up in "); Serial.print(ms); Serial.print(" ms... ");
        delay(ms);
        Serial.println("*yawn* good morning");
        break;
      }
        
      case 'm': // set speed
        if (stream.available())
        {
          g_speed = stream.parseInt();
          Serial.print("New speed: ");
          Serial.println(g_speed);
        }
        break;
        
      case 'R': // start/stop recording
        if (stream.available())
        {
          // start recording
          g_record_index = 0;
          for (int i = 0; i < 10; ++i)
          {
            g_record_motors[i] = 0;
            if (stream.available())
            {
              g_record_motors[i] = stream.parseInt();
            }
          }
          Serial.println("start recording");
          g_recording = true;
        }
        else
        {
          g_recording = false;
          Serial.println("stop recording");
          for (int i = 0; i < g_record_index; ++i)
          {
            Serial.print("pos ");
            for (int j = 0; j < 10; ++j)
            {
              if (g_record_motors[j] == 0) break;
              Serial.print(g_record[i][j]);
              Serial.print(" ");
            }
            Serial.println();
          }
        }
        break;
        
      case 'F': // start script
      case 'W': // write script
      case 'L': // list scripts
      case 'P': // play script
        Serial.println("Not implemented yet!");
        break;

      default:
        Serial.println("Unsupported command!");
        
  }
}

void loop()
{
  static char buf[200] = "";
  static int i = 0;
  
  while (Serial.available() > 0)
  {
    char c = Serial.read();
    Serial.print(c);
    switch (c)
    {
      case 'S':
        // this is the only command handled here instead of process_command
        // because emergency stop waits for no end of line
        shut_down_everything();
        break;
      case '\n':
      case '\r':
      case 'X': // the arduino serial monitor doesn't send linebreaks
        Serial.print("\r\n");
        buf[i] = '\0';
        process_command(buf);
        i = 0;
        break;
      case 0x7F: // backspace/delete
        if (i > 0)
        {
            --i;
            Serial.print("\b \b");
        }
        break;
      default:
        buf[i++] = c;
    }
  }
  /*
  Dynamixel.ledStatus(2, ON);
  Dynamixel.moveSpeed(6, 10, SPEED);
  digitalWrite(LED, HIGH);
  delay(5000);
  Dynamixel.ledStatus(2, OFF);
  Dynamixel.moveSpeed(6, 500, SPEED);
  digitalWrite(LED, LOW);
  delay(5000);
  */
}

