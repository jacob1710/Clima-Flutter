import 'package:flutter/material.dart';
import 'package:flutter_statusbarcolor/flutter_statusbarcolor.dart';
import 'package:clima/utilities/constants.dart';
import 'package:clima/services/weather.dart';
import 'package:flutter/cupertino.dart';
import 'city_screen.dart';
import 'dart:async';

// The base class for the different types of items the list can contain.
abstract class ListItem {}

// A ListItem that contains data to display a heading.
class HeadingItem implements ListItem {
  final theTemp;
  final String theTime;
  final String weatherPicCode;

  HeadingItem(this.theTemp,this.theTime,this.weatherPicCode);
}



class LocationScreen extends StatefulWidget {

  LocationScreen({this.locationWeather,this.locationForecast});

  final locationWeather;
  final locationForecast;

  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {

  WeatherModel weather = WeatherModel();

  int temperature;
  int condition;
  var timeZoneShift;
  String localTime;
  String cityName;
  String weatherIcon;
  String weatherMessage;
  List<ListItem> fiveDayList;

  var theBackgroundImage = 'images/location_background.jpg';


  @override
  void initState() {
    // TODO: implement initState
    getBackground(widget.locationWeather);
    generateItems(widget.locationForecast);
    super.initState();
    changeStatusBarTint();
    updateUI(widget.locationWeather);
    Timer.periodic(kOneSec, (Timer t) => updateTime());
  }
 void generateItems(weatherData){
    print(weatherData["timezone"]);
    print(weatherData);
    if (weatherData != null) {
      fiveDayList = List<ListItem>.generate(
          36, (i) =>
          HeadingItem(
              weatherData["list"][i]["main"]["temp"].toInt(),
              getFinalTime(weatherData["city"]["timezone"],
                  weatherData["list"][i]["dt_txt"]),
              weather.getWeatherIcon(weatherData["list"][i]["weather"][0]["id"])
          )
      );
    }else{
      List<ListItem>.generate(
          1, (i) =>
          HeadingItem("","Error","")
      );
    }
}

  String getFinalTime(timeshift, currentTime){
    var year = int.parse(currentTime.toString().substring(0,4));
    var month = int.parse(currentTime.toString().substring(5,7));
    var day = int.parse(currentTime.toString().substring(8,10));
    var hour = int.parse(currentTime.toString().substring(11,13));
    var minute = int.parse(currentTime.toString().substring(14,16));
    var second = int.parse(currentTime.toString().substring(17,19));
    var timeOfWeather = DateTime(year,month,day,hour,minute,second);
    var finalTime = timeOfWeather.add(Duration(seconds: timeshift));
    return finalTime.toString();
  }

  void getBackground(weatherData){
    timeZoneShift = weatherData["timezone"];
    localTime = getTimeShift(timeZoneShift);
    var hours = int.parse(localTime.substring(0, 2));
    setState(() {
      if (hours < 2) {
        theBackgroundImage = 'images/12-Late-Night.png';
      } else if (hours < 5) {
        theBackgroundImage = "images/12-Late-Night.png";
      } else if (hours < 7) {
        theBackgroundImage = "images/01-Early-Morning.png";
      } else if (hours < 9) {
        theBackgroundImage = "images/02-Mid-Morning.png";
      } else if (hours < 12) {
        theBackgroundImage = "images/04-Early-Afternoon.png";
      } else if (hours < 15) {
        theBackgroundImage = "images/05-Mid-Afternoon.png";
      } else if (hours < 17) {
        theBackgroundImage = "images/06-Late-Afternoon.png";
      } else if (hours < 19) {
        theBackgroundImage = "images/07-Early-Evening.png";
      } else if (hours < 21) {
        theBackgroundImage = "images/08-Mid-Evening.png";
      } else if (hours < 22) {
        theBackgroundImage = "images/10-Early-Night.png";
      } else {
        theBackgroundImage = "images/11-Mid-Night.png";
      }
    });
  }

  void _showDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: new Text("Error"),
          content: new Text("Unable to get weather data, check your location settings."),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Close",style: TextStyle(color: Colors.black)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String getTimeShift(utcS){
    final myFinal = DateTime.now().toUtc();
    final added = myFinal.add(new Duration(seconds: utcS));
    var hourStr = "";
    var minStr = "";
    if(added.hour.toString().length == 1){
      hourStr = "0"+added.hour.toString();
    }else{
      hourStr = added.hour.toString();
    }
    if(added.minute.toString().length == 1){
      minStr = "0"+added.minute.toString();
    }else{
      minStr = added.minute.toString();
    }
    final localT =  "$hourStr:$minStr";
    return localT;
  }

  void changeStatusBarTint()async{
    await FlutterStatusbarcolor.setStatusBarWhiteForeground(true);
  }

  void updateTime(){
    print("Time Altered");
    setState(() {
      localTime = getTimeShift(timeZoneShift);
    });
  }
  
  void updateUI(dynamic weatherData){
    setState(() {
      if (weatherData == null){
        temperature = 0;
        weatherIcon = "";
        weatherMessage = "Error, Try getting location again";
        cityName = "";
        localTime = "12:00";
        return;
      }
      var temp = weatherData["main"]["temp"];
      timeZoneShift = weatherData["timezone"];
      temperature = temp.toInt();
      condition = weatherData["weather"][0]["id"];
      localTime = getTimeShift(timeZoneShift);
      WeatherModel weatherModel = WeatherModel();
      weatherIcon = weatherModel.getWeatherIcon(condition);
      weatherMessage = weatherModel.getMessage(temperature);
      cityName = "in ${weatherData["name"]}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(theBackgroundImage),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
                Colors.white.withOpacity(0.8), BlendMode.dstATop),
          ),
        ),
        constraints: BoxConstraints.expand(),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  FlatButton(
                    onPressed: () async {
                      var weatherData = await weather.getLocationWeather();
                      var weatherForecast = await weather.getLocationForecast();
                      if (weatherData == null){
                        _showDialog();
                      }else{
                        generateItems(weatherForecast);
                        updateUI(weatherData);
                        getBackground(weatherData);
                      }

                    },
                    child: Icon(
                      Icons.near_me,
                      size: 50.0,
                    ),
                  ),
                  FlatButton(
                    onPressed: () async {
                      var typedName = await Navigator.push(context, MaterialPageRoute(builder: (context){
                        return CityScreen();
                      }));
                      if (typedName != null){
                        var weatherData = await weather.getCityWeather(typedName);
                        var fivedayWeather = await weather.getCityForecast(typedName);
                        generateItems(fivedayWeather);
                        updateUI(weatherData);
                        getBackground(weatherData);
                      }
                    },
                    child: Icon(
                      Icons.location_city,
                      size: 50.0,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.only(left: 15.0),
                child: Row(
                  children: <Widget>[
                    Text(
                      '$temperature°C',
                      style: kTempTextStyle,
                    ),
                    Text(
                      '$weatherIcon',
                      style: kConditionTextStyle,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 15.0),
                child: Row(
                  children: <Widget>[
                    Text(
                      '$localTime',
                      style: kTimeTextStyle,
                    ),
                  ],
                ),
              ),
            Container(
              height: 100.0,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: fiveDayList.length,
                itemBuilder: (context, index) {
                  final item = fiveDayList[index];
                  if (item is HeadingItem) {
                    return Container(
                      width: 200,
                      child: Card(
                        color: Colors.transparent,
                        child: ListTile(
                          leading: Text(item.weatherPicCode,style: TextStyle(fontSize: 30),),
                          title: Text(
                            "${item.theTemp.toString()}°C",
                            style: kCardTitleTextStyle
                          ),
                          subtitle: Text(item.theTime.substring(5,16),style: kCardSubtitleTextStyle,),

                        ),
                      ),
                    );
                  }
                },
              ),
            ),
              Padding(
                padding: EdgeInsets.only(right: 15.0),
                child: Text(
                  "$weatherMessage $cityName!",
                  textAlign: TextAlign.right,
                  style: kMessageTextStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
//

