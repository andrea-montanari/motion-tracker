import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mdsflutter/Mds.dart';

class DeviceModel extends ChangeNotifier {
  String? _serial;
  String? _name;

  String? get name => _name;
  String? get serial => _serial;

  StreamSubscription? _accSubscription;
  String _accelerometerData = "";
  String get accelerometerData => _accelerometerData;
  bool get accelerometerSubscribed => _accSubscription != null;

  StreamSubscription? _IMU9Subscription;
  Map<String, String> _IMU9Data = Map();
  Map<String, String> get IMU9Data => _IMU9Data;
  bool get IMU9Subscribed => _IMU9Subscription != null;

  StreamSubscription? _hrSubscription;
  String _hrData = "";
  String get hrData => _hrData;
  bool get hrSubscribed => _hrSubscription != null;

  bool _ledStatus = false;
  bool get ledStatus => _ledStatus;

  String _temperature = "";
  String get temperature => _temperature;

  DeviceModel(this._name, this._serial);

  @override
  void dispose() {
    _accSubscription?.cancel();
    _hrSubscription?.cancel();
    super.dispose();
  }

  void subscribeToAccelerometer() {
    _accelerometerData = "";
    _accSubscription = MdsAsync.subscribe(
            Mds.createSubscriptionUri(_serial!, "/Meas/Acc/104"), "{}")
        .listen((event) {
      _onNewAccelerometerData(event);
    });

    notifyListeners();
  }

  void _onNewAccelerometerData(dynamic accData) {
    Map<String, dynamic> body = accData["Body"];
    List<dynamic> accArray = body["ArrayAcc"];
    dynamic acc = accArray.last;
    _accelerometerData = "x: " +
        acc["x"].toStringAsFixed(2) +
        "\ny: " +
        acc["y"].toStringAsFixed(2) +
        "\nz: " +
        acc["z"].toStringAsFixed(2);
    notifyListeners();
  }

  void unsubscribeFromAccelerometer() {
    if (_accSubscription != null) {
      _accSubscription!.cancel();
    }
    _accSubscription = null;
    notifyListeners();
  }

  void subscribeToIMU9({String rate = '104'}) {
    _IMU9Data = Map();
    _IMU9Subscription = MdsAsync.subscribe(
            Mds.createSubscriptionUri(_serial!, "/Meas/IMU9/" + rate), "{}")
        .listen((event) {
      _onNewIMU9Data(event);
    });

    notifyListeners();
  }

  void _onNewIMU9Data(dynamic imuData) {
    Map<String, dynamic> body = imuData["Body"];
    List<dynamic> accArray = body["ArrayAcc"];
    List<dynamic> gyroArray = body["ArrayGyro"];
    List<dynamic> magnArray = body["ArrayMagn"];
    dynamic acc = accArray.last;
    dynamic gyro = gyroArray.last;
    dynamic magn = magnArray.last;
    _IMU9Data["Timestamp"] = body["Timestamp"].toString();
    _IMU9Data["Acc"] = "x: " +
        acc["x"].toStringAsFixed(2) +
        "\ny: " +
        acc["y"].toStringAsFixed(2) +
        "\nz: " +
        acc["z"].toStringAsFixed(2);
    _IMU9Data["Gyro"] = "x: " +
        gyro["x"].toStringAsFixed(2) +
        "\ny: " +
        gyro["y"].toStringAsFixed(2) +
        "\nz: " +
        gyro["z"].toStringAsFixed(2);
    _IMU9Data["Magn"] = "x: " +
        magn["x"].toStringAsFixed(2) +
        "\ny: " +
        magn["y"].toStringAsFixed(2) +
        "\nz: " +
        magn["z"].toStringAsFixed(2);
    print("IMU9Data: \n$IMU9Data");
    notifyListeners();
  }

  void unsubscribeFromIMU9() {
    if (_IMU9Subscription != null) {
      _IMU9Subscription!.cancel();
    }
    _IMU9Subscription = null;
    notifyListeners();
  }

  void subscribeToHr() {
    _hrData = "";
    _hrSubscription = MdsAsync.subscribe(
            Mds.createSubscriptionUri(_serial!, "/Meas/HR"), "{}")
        .listen((event) {
      _onNewHrData(event);
    });
    notifyListeners();
  }

  void _onNewHrData(dynamic hrData) {
    Map<String, dynamic> body = hrData["Body"];
    double hr = body["average"];
    _hrData = hr.toStringAsFixed(1) + " bpm";
    notifyListeners();
  }

  void unsubscribeFromHr() {
    if (_hrSubscription != null) {
      _hrSubscription!.cancel();
    }
    _hrSubscription = null;
    notifyListeners();
  }

  void switchLed() {
    debugPrint("switchLed()");
    Map<String, bool> contract = new Map<String, bool>();
    contract["isOn"] = !_ledStatus;
    MdsAsync.put(Mds.createRequestUri(_serial!, "/Component/Led"),
            jsonEncode(contract))
        .then((value) {
      debugPrint("switchLed then: $value");
      _ledStatus = !_ledStatus;
      notifyListeners();
    });
  }

  void getTemperature() async {
    debugPrint("getTemperature()");
    MdsAsync.get(Mds.createRequestUri(_serial!, "/Meas/Temp"), "{}")
        .then((value) {
      debugPrint("getTemperature value: $value");
      double kelvin = value["Measurement"];
      double temperatureVal = kelvin - 273.15;
      _temperature = temperatureVal.toStringAsFixed(1) + " C";
      notifyListeners();
    });
  }
}
