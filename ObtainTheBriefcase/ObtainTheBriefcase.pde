//Important sketch permissions: ACCESS_FINE_LOCATION, ACCESS_COURSE_LOCATION, SEND_SMS, VIBRATE
//General import
import android.content.Context;
//GPS imports
import android.location.Location;
import android.location.LocationManager;
import android.location.LocationListener;
import android.location.GpsStatus.Listener;
import android.os.Bundle;
//Vibration imports
import android.app.Notification;
import android.app.NotificationManager;
//SMS imports
import android.telephony.gsm.SmsManager;

//Adjust these variables too match your local needs
String endLocation = "SOMArts"; //where people should gather at the end of the game.

//This array should contain the GPS coordinates of every intersection within your play area. First latitude then longitude
double[][] landmarks = {
  {37.773800, -122.411590}, //9th & Folsom
  {37.775022, -122.410048}, //8th & Folsom
  {37.775916, -122.408922}, //Rausch & Folsom
  {37.776342, -122.408374}, //Langton & Folsom
  {37.776771, -122.407834}, //7th & Folsom
  {37.776341, -122.407271}, //7th & Cleveland
  {37.774571, -122.409500}, //8th & Ringold
  {37.773336, -122.411069}, //9th & Ringold
  {37.772552, -122.410038}, //9th & Harrison
  {37.773760, -122.408504}, //8th & Harrison
  {37.775115, -122.406806}, //Langton & Harrison
  {37.775526, -122.406281}, //7th & Harrison
  {37.774293, -122.404737}, //7th & Bryant
  {37.773875, -122.405258}, //Langton & Bryant
  {37.772554, -122.406945}, //8th & Bryant
  {37.771319, -122.408501}, //9th & Bryant
  {37.770086, -122.407009}, //9th & Brannan
  {37.771329, -122.405408}, //8th & Brannan
  {37.772649, -122.403750}, //Langton & Brannan
  {37.773082, -122.403180}, //7th & Brannan
  {37.774227, -122.409050}, //8th & Heron
  {37.774783, -122.408319}, //Berick & Heron
  {37.774365, -122.407755}  //Berick & Harrison
};

//This contains the names of every intersection. They should be in the same order as the GPS cordinants
String[] landmarkNames = {
  "9th & Folsom",
  "8th & Folsom",
  "Rausch & Folsom",
  "Langton & Folsom",
  "7th & Folsom",
  "7th & Cleveland",
  "8th & Ringold",
  "9th & Ringold",
  "9th & Harrison",
  "8th & Harrison",
  "Langton & Harrison",
  "7th & Harrison",
  "7th & Bryant",
  "Langton & Bryant",
  "8th & Bryant",
  "9th & Bryant",
  "9th & Brannan",
  "8th & Brannan",
  "Langton & Brannan",
  "7th & Brannan",
  "8th & Heron",
  "Berick & Heron",
  "Berick & Harrison",
  "nothing"
};
/* This array should contain the GPS coordinators of play area's corners.
The points should be arranged as follows:
1--2
|  |
4--3
*/
float[][] playArea = {
  {37.773851, -122.412644},
  {37.777395, -122.407698},
  {37.772973, -122.402202},
  {37.769625, -122.406920}
};

//something to add too the tweets so you don't post the same tweet twice.
//It's is only relevant if you're playing more than one game in a day. If not, just leave it blank.
//If you're play multiple games over the course of a multiple days, update this number at the start of each day
int unique = 1;

int gameLength = 1800; //how long does the game last in seconds. 30 minutes = 1800, 1 hour = 3600
int updateFreq = 180; //how often does the game post to twitter in seconds. five minutes = 300, 3 minutes = 180, 10 minutes = 60
int captureDelay = 15; //the period where you can't capture the briefcase after it's been captured, in seconds.

//These variables do not need to be altered to match local conditions
//Colors
color blueTeam = color(20, 144, 255);
color redTeam = color(200, 0, 0);
color orangeTeam = color(255, 160, 0);
color greenTeam= color(10, 500, 10);
color noTeam = color(150, 150, 150);
color teamColors[] = {blueTeam, redTeam, orangeTeam, greenTeam, noTeam};

//Buttons
Button buttons[] = new Button[4];
Button start;

//Game values
int caseOwner = 4; //this the team that has currently obtained the briefcase. 0 = blue, 1 = red, 2 = orange, 3 = yellow, 4 = no one
int winningTeam = 4;
int scores[] = {0, 0, 0, 0, 0};

//Game state/timing variables
long gameStart; //when did the game start?
long lastUpdate; //the last time we sent out a location update
long lastCheck; //the last time we updated the score
long lastCaptured; //the time when the briefcase was captured
boolean playing = false; //are we playing the game?
Boolean recentlyCaptured = false; //has anyone captured the briefcase recently?

//SMS variables
SmsManager sm = SmsManager.getDefault();
String number = "40404"; //The number I'm sending too

//GPS variables
LocationManager locationManager;
MyLocationListener locationListener;
float latit, longi; //the set place where the longitude and latitude will be put
float[] results = new float[3];
Location location;

//Vibration variables
NotificationManager gNotificationManager;
Notification gNotification;
long[] gVibrate = {0,10}; //vibrates for 10 milliseconds. Isn't very long, because it should shut off pretty quickly

//Text variables
String[] fontList;
PFont f;
String updates = "NEW GAME BUTTON, DO NOT TOUCH";

void setup() {
  orientation(LANDSCAPE);

  buttons[0] = new Button(20, 20, height/2 - 40, width/2 - 40, blueTeam, "1");
  buttons[0].off();
  buttons[1] = new Button(width/2 + 20, 20, height/2 - 40, width/2 - 40, redTeam, "2");
  buttons[1].off();
  buttons[2] = new Button(20, height/2 + 20, height/2 - 40, width/2 - 40, orangeTeam, "3");
  buttons[2].off();
  buttons[3] = new Button(width/2 + 20, height/2 + 20, height/2 - 40, width/2 - 40, greenTeam, "4");
  buttons[3].off();

  start = new Button(50, 50, 50, 50, 45, 45, 45, "");

  fontList = PFont.list();
  f = createFont(fontList[4], 40, true);
  textFont(f);
  
  location = new Location("");
  
  for(int i = 0; i < 3; i++)
  {
    results[i] = 0;
  }
}

void onResume() {
  super.onResume();
  // Acquire a reference to the system Location Manager
  locationManager = (LocationManager)getSystemService(Context.LOCATION_SERVICE);
  // Build Listener
  locationListener = new MyLocationListener();
  locationManager.requestLocationUpdates(LocationManager.GPS_PROVIDER, 0, 0, locationListener);
  
  gNotificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
  
  // Creates a new notifaction object.
  gNotification = new Notification();
  // Defines the vibrate variable in the notifaction as the pattern we defined above
  gNotification.vibrate = gVibrate;
}

void onPause(){
  super.onPause();
  locationManager.removeUpdates(locationListener);
}

void draw() {
  //What the phone does when the game is running
  if (playing) {
    background(teamColors[caseOwner]);
    
    for(int i = 0; i < buttons.length; i++){
      buttons[i].display();
    }

    if(!inPlayArea(latit, longi)){
      gNotificationManager.notify(1, gNotification);
    }
    if (millis() - lastCheck >= 100) {
      scores[caseOwner]++;
      lastCheck = millis();
    }

    //sends the current location to twitter
    if (millis() - lastUpdate >= (updateFreq * 1000)){      
      //then we tell people about it
      if (caseOwner < 4) {
        sendText("The " + teamName(caseOwner) + " Team has obtained the briefcase. It is near " + closestLandmark(latit, longi) + ". " + formatTime((int)(gameLength*1000 + gameStart) - millis() + 10) + " remain.");
      }
      else {
        sendText("Neither team has obtained the briefcase. It is near " + closestLandmark(latit, longi) + ". " + formatTime((int)((gameLength*1000 + gameStart - millis())) + 10) + " remain.");
      }
      lastUpdate = millis();
    }
    
    if(millis() - lastCaptured >= (captureDelay * 1000) && recentlyCaptured == true)
    {
      recentlyCaptured = false;
    }

    //ends the game once enough time has passed
    if(millis() - gameStart >= (gameLength * 1000)){
      playing = false;
      for(int i = 0; i < buttons.length; i++){
        buttons[i].off();
      }
      start.on();
      decideWinner();
      updates = "NEW GAME BUTTON, DO NOT TOUCH";
    }
  }
  //this is what the program does when the game is not playing
  else {
    background(teamColors[winningTeam]);
    start.display();
  }
  fill(0);
  text(updates, 110, 65, 750, 450);
}

//Announces the winner, team scores from highest to lowest
//This method is based on the assumpition that ties are so unlikely that they're not worth checking for
//If there is a tie, it will fail to report correctly.
void decideWinner()
{
  winningTeam = 0;
  int scoreOrder[] = {4, 4, 4, 4}; //you can't give an array a variable size, so if you want more or less teams than four, you'll have to change this variable.
  int lessThan;
  for(int i = 0; i < scoreOrder.length; i++)
  {
    lessThan = 0;
    for(int j = 0; j < scores.length-1; j++)
    {
      if(scores[i] < scores[j])
      {
        lessThan++;
      }
    }
    scoreOrder[lessThan] = i;
  }
  winningTeam = scoreOrder[0];
  
  String winnerText = "The " + teamName(winningTeam) + " Team wins! Final scores: ";
  for(int i = 0; i < scoreOrder.length; i++)
  {
    winnerText += teamName(scoreOrder[i]) + " Team: " + formatTime(scores[scoreOrder[i]]*100);
    if(i < scoreOrder.length - 1)
    {
      winnerText += ", ";
    }
  }
  winnerText += ".";
  sendText(winnerText);
  sendText("Thank you for playing. Please gather at " + endLocation + ".");
}

//Returns the name of the team when given a number value
String teamName(int whichTeam)
{
  switch(whichTeam){
    case 0: return "Blue";
    case 1: return "Red";
    case 2: return "Orange";
    case 3: return "Green";
    default: return "No";
  }
}

//Resolves taps on the touch screen
void mousePressed()
{
  //Changes possession of the briefcase
  for(int i = 0; i < buttons.length; i++)
  {
    if(buttons[i].isWithin(mouseX, mouseY) && recentlyCaptured == false)
    {
      if(caseOwner > 3)
      {
        sendText("The " + teamName(i) + " Team has obtained the briefcase from the neutral party.");
      }
      
      if(caseOwner != i)
      {
        caseOwner = i;
        recentlyCaptured = true;
        lastCaptured = millis();
      }
    }
  }

  //Starts the game
  if (start.isWithin(mouseX, mouseY)) {
    playing = true;
    gameStart = millis();
    lastUpdate = millis();
    unique++;

    for(int i = 0; i < buttons.length; i++){
        buttons[i].on();
    }
    start.off();
    for(int i = 0; i < scores.length; i++){
      scores[i] = 0;
    }
    caseOwner = 4;
    sendText("The game has begun. The briefcase is at " + closestLandmark(latit, longi) + " and may now be obtained from the neutral party");
    updates = "";  
  } 
}

//takes milliseconds and converts them to minutes and seconds
String formatTime(int time)
{
  int minutes = 0;
  int seconds = 0;
  int decimalSeconds = 0;
  while (time >= 60000)
  {
    time -= 60000;
    minutes++;
  }
  while (time >= 1000)
  {
    time -= 1000;
    seconds++;
  }
  while(time >= 100)
  {
    time -= 100;
    decimalSeconds++;
  }
  if (seconds >= 10)
  {
    return minutes + ":" + seconds + "." + decimalSeconds;
  }
  else
  {
    return minutes + ":0" + seconds + "." + decimalSeconds;
  }
}

//Sends a message to twitter
//If you want give every message a hashtag, add it here
//Be sure to check that none of your messages will be too many characters!
void sendText(String message)
{
  //updates = message;
  sm.sendTextMessage(number, null, message + " (" + unique + ") #OtB", null, null);
}

//Returns the name of the landmark closest too the latitude and longitude given
String closestLandmark(float lat, float lng)
{
  float minDistance = 1000;
  int closest = 9999;
  for(int i = 0; i < landmarks.length; i++){
    location.distanceBetween((double)lat, (double)lng, landmarks[i][0], landmarks[i][1], results);
    if(results[0] < minDistance){
      closest = i;
      minDistance = results[0];
    }
  }
  if(closest >= landmarks.length){
    return "nowhere";
  }
  else{
    return landmarkNames[closest];
  }
}

//Returns true if the lat and long are within the play area, false if they are not
Boolean inPlayArea(float lat, float lng)
{
  int intersections = 0;
  intersections += lineCross(playArea[0][1], playArea[0][0], playArea[1][1], playArea[1][0], lng, lat);
  intersections += lineCross(playArea[1][1], playArea[1][0], playArea[2][1], playArea[2][0], lng, lat);
  intersections += lineCross(playArea[2][1], playArea[2][0], playArea[3][1], playArea[3][0], lng, lat);
  intersections += lineCross(playArea[3][1], playArea[3][0], playArea[0][1], playArea[0][0], lng, lat);
  
  if(intersections%2 == 1)
  {
    return true;
  }
  return false;
}

//Checks to see if a ray cast from point p will cross the line define by 1 and 2
//returns 1 if it does, returns 0 if it doesn't
//Latitude is the equivalent of Y, Longitutde is the equivalent of X
int lineCross(float x1, float y1, float x2, float y2, float px, float py)
{
  if ((py > y1) && (py > y2))
  {
    //whenOut = py + " is move than " + y1 + " and " + y2;
    return 0;
  }

  if (x1 > x2)
  {
    if ((x2 > px) || (px > x1))
    {
      //whenOut = py + " is not between " + x1 + " and " + x2;
      return 0;
    }
  }
  else
  {
    if((x1 > px) || (px > x2))
    {
      //whenOut = py + " is not between " + x2 + " and " + x1;
      return 0;
    }
  }

  float dx = x1 - x2;
  float dy = y1 - y2;
  float slope = dy/dx;

  float b = y1 - (slope * x1); //that's b as in y = ax + b
  float intersection = (slope * px) + b;

  if (py <= intersection)
  {
    //whenOut = py + " intersects with this line.";
    return 1;
  }
  else
  {
    //whenOut = "below the line and within range, but does not intersect";
    return 0;
  }
}

//Button objects create a square on the screen which you can press to do various things.
class Button {
  int x;
  int y;
  int height;
  int width;
  color shade; //the color of the button
  String label; //a label which will be put in the bottom left corner of the button.

  boolean active; //Allows you to turn the button on and off

  Button(int x, int y, int width, int height, String label)
  {
    this.x = x;
    this.y = y;
    this.height = height;
    this.width = width;
    shade = color(30, 30, 30);
    active = true;
    this.label = label;
  }

  Button(int x, int y, int height, int width, color shade, String label)
  {
    this.x = x;
    this.y = y;
    this.height = height;
    this.width = width;
    this.shade = shade;
    this.label = label;
    active = true;
  }

  Button(int x, int y, int height, int width, int r, int g, int b, String label)
  {
    this.x = x;
    this.y = y;
    this.height = height;
    this.width = width;
    shade = color(r, g, b);
    active = true;
    this.label = label;
  }

  void display()
  {
    fill(shade);
    rect(x, y, width, height);
    fill(0);
    text(label, x + 10, y + height - 10);
  }

  public boolean isWithin(int inputX, int inputY)
  {
    if (inputX >= x && inputX <= (x+width) && inputY >= y && inputY <= (y+height) && active)
    {
      return true;
    }
    else
    {
      return false;
    }
  }

  public void changeColor(int r, int g, int b)
  {
    shade = color(r, g, b);
  }

  public void on()
  {
    active = true;
  }

  public void off()
  {
    active = false;
  }
}

//Define a listener that responds to location updates
class MyLocationListener implements LocationListener {

  void onLocationChanged(Location location) {
    // Called when a new location is found by the network location provider.
    latit  = (float)location.getLatitude();
    longi = (float)location.getLongitude();
  }

  void onProviderDisabled (String provider) {
  }

  void onProviderEnabled (String provider) {
  }

  void onStatusChanged (String provider, int status, Bundle extras) {
  }
}
