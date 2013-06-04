#include "DynamixelSerial1.h"
#include "StringStream.h"

#define LED 13
#define SPEED 100

int g_motors[32] = { 0 };
int g_speed = SPEED;

void setup()
{
  pinMode(LED, OUTPUT);
  Serial.begin(9600);
  Dynamixel.begin(1000000, 2); // 1 Mbps, ignored direction pin
  Serial.println("=== Dynamixel controller initialized ===");
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
    Serial.print("Motor #"); Serial.print(motor); Serial.print(" position = "); Serial.println(Dynamixel.readPosition(motor));
}

void move_motor_to(int motor, int goal)
{
  Dynamixel.moveSpeed(motor, goal, g_speed);
  Serial.print("Moving motor #"); Serial.print(motor); Serial.print(" to position "); Serial.println(goal);
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
"Dynamixel Control Interface\n"
"\n"
"Commands:\n"
"    h               print this help message\n"
"                    repeat last command (just press enter)\n"
"    r [id]*         read positions (if no arguments, read all)\n"
"\n"
"    S               EMERGENCY STOP (all motors)\n"
"\n"
"    s [id goal]*    set positions\n"
"                      set motors to given values\n"
"                        e.g. 's 1 512 2 256'\n"
"    a [id rgoal]+   set relative positions\n"
"                      DANGER be careful that you don't make the motors fight each other!\n"
"\n"
"    J [name [id sign]+]    set up a joint (do a read just before)\n"
"                             no arguments: list all joints\n"
"                             one argument: show that joint\n"
"                             otherwise, define a joint\n"
"                               e.g. 'J base 1 +' or 'J shoulder 2 + 3 -'\n"
"\n"
"    H [name]*              re-home joint(s) (do a read just before)\n"
"\n"
"    j [name rgoal?]*       set joint positions\n"
"                             no arguments: set all joints to home\n"
"    k [name rgoal?]*       set relative joint positions\n"
"                             no arguments: set all joints to home\n"
"\n"
"    z [milliseconds]?    sleep (no argument: 1 second)\n"
"    m [speed]?      set speed (default 20)\n"
"\n"
"    F filename      start named script\n"
"    W               save in-progress script\n"
"    L               list saved scripts\n"
"    P filename      play named script\n");
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
                add_to_list(g_motors, motor);
                move_motor_to(motor, goal + (c == 's' ? 0 : Dynamixel.readPosition(motor)));
            }
        }
        break;

      case 'J': // set up a joint
      case 'H': // re-home joint(s)
      case 'j': // set joint(s) positions
      case 'k': // set joint(s) positions (relative)
        Serial.println("Not implemented yet!");
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
        buf[i] = '\0';
        process_command(buf);
        i = 0;
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

