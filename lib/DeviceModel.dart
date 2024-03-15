import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:mdsflutter/Mds.dart';
import 'package:multi_sensor_collector/Utils/BodyPositions.dart';
import 'package:multi_sensor_collector/Utils/RunningStat.dart';

import 'Utils/InfoResponse.dart';

class DeviceModel extends ChangeNotifier {
  static const double MOVEMENT_THRESHOLD = 8.0;
  static const double MOVEMENT_THRESHOLD_ANIMATION = 4.0;
  late int sampleRate;

  String? _serial;
  String? _name;

  String? get name => _name;

  String? get serial => _serial;

  StreamSubscription? _accSubscription;
  Map<String, double> _accelerometerData = Map();

  Map<String, double> get accelerometerData => _accelerometerData;

  bool get accelerometerSubscribed => _accSubscription != null;

  StreamSubscription? _imu9Subscription;
  Map<String, String> _imu9Data = Map();
  RunningStat runningStatX = RunningStat();
  RunningStat runningStatY = RunningStat();
  RunningStat runningStatZ = RunningStat();
  double stdSum = 0.0;
  List<String> csvHeaderImu9 = ["Userid", "UserAge", "UserSex", "UserHeight", "UserWeight", "Activity", "Timestamp","AccX","AccY","AccZ","GyroX","GyroY","GyroZ", "MagnX", "MagnY", "MagnZ", "position", "UTC_start-end", "relativeTime_start-end"];
  List<List<String>> _csvDataImu9 = [];
  List<List<String>> get csvDataImu9 => _csvDataImu9;

  BodyPositions? bodyPosition;
  String? userId;
  String? userAge;
  String? userSex;
  String? userHeight;
  String? userWeight;
  late String activity;

  Map<String, String> get imu9Data => _imu9Data;

  bool get imu9Subscribed => _imu9Subscription != null;

  List<RunningStat> get runningStats =>
      [runningStatX, runningStatY, runningStatZ];

  StreamSubscription? _hrSubscription;
  String _hrData = "";
  List<String> csvHeaderHr = ["Timestamp","hr", "position"];
  List<List<String>> _csvDataHr = [];
  List<List<String>> get csvDataHr => _csvDataHr;

  String get hrData => _hrData;

  bool get hrSubscribed => _hrSubscription != null;
  Function()? _onHrStart;
  Function()? _onHrStop;
  Function(DeviceModel device)? _onHrDataReceived;

  bool _ledStatus = false;

  bool get ledStatus => _ledStatus;

  String _temperature = "";

  String get temperature => _temperature;

  Stopwatch stopwatch = Stopwatch();
  int previousTimestamp = 0;

  Map timeDetailedStart = Map();
  Map timeDetailedEnd = Map();
  int localTimeOffset = DateTime.now().toLocal().timeZoneOffset.inMicroseconds;

  void onHrStart(void Function() cb) {
    _onHrStart = cb;
  }
  void onHrStop(void Function() cb) {
    _onHrStop = cb;
  }
  void onHrDataReceived(void Function(DeviceModel) cb) {
    _onHrDataReceived = cb;
  }

  DeviceModel(this._name, this._serial);

  @override
  void dispose() {
    _accSubscription?.cancel();
    _hrSubscription?.cancel();
    super.dispose();
  }


  Future<bool> setTime() {
    Completer<bool> completer = Completer<bool>();
    Mds.put(Mds.createRequestUri(_serial!, "/Time"),
        "{\"value\":${DateTime.now().microsecondsSinceEpoch+localTimeOffset}}",
            (data, statusCode) {
          /* onSuccess */
          completer.complete(true);
        },
            (error, statusCode) {
          /* onError */
          debugPrint("Error on time set for sensor $_serial");
          completer.complete(false);
        }
    );
    return completer.future;
  }

  Future<Map> getTimeDetailed() {
    Map timeDetailed = {};
    Completer<Map> completer = Completer<Map>();
    Mds.get(Mds.createRequestUri(_serial!, "/Time/Detailed"),
        "{}",
            (data, statusCode) {
          /* onSuccess */
          Map timeDetailedData = jsonDecode(data);
          timeDetailed["utc"] = timeDetailedData["Content"]["utcTime"];
          timeDetailed["relativeTime"] = timeDetailedData["Content"]["relativeTime"];
          completer.complete(timeDetailed);
        },
            (error, statusCode) {
          /* onError */
              debugPrint("Error on get time detailed for sensor $_serial");
          completer.complete(null);
        }
    );
    return completer.future;
  }

  subscribeToAccelerometer() {
    _accelerometerData = Map();
    _accSubscription = MdsAsync.subscribe(
        Mds.createSubscriptionUri(_serial!, "/Meas/Acc/104"), "{}")
        .handleError((error) => {
      debugPrint("Error on subscribeToAccelerometer: " + error.toString())
    })
        .listen((event) {
      _onNewAccelerometerData(event);
    });

    notifyListeners();
  }

  void _onNewAccelerometerData(dynamic accData) {
    Map<String, dynamic> body = accData["Body"];
    List<dynamic> accArray = body["ArrayAcc"];
    dynamic acc = accArray.last;
    _accelerometerData["x"] = acc["x"].toDouble();
    _accelerometerData["y"] = acc["y"].toDouble();
    _accelerometerData["z"] = acc["z"].toDouble();
    log("Acc data device $serial, timestamp: ${body["Timestamp"]}");
    notifyListeners();
  }

  void subscribeToAccelerometerCheckForMovement({required Function onMovementDetected}) {
    _accelerometerData = Map();
    runningStatX.clear();
    runningStatY.clear();
    runningStatZ.clear();
    stdSum = 0.0;

    _accSubscription = MdsAsync.subscribe(
        Mds.createSubscriptionUri(_serial!, "/Meas/Acc/13"), "{}")
        .handleError((error) => {
      debugPrint("Error on subscribeToAccelerometerCheckForMovement: $error")
    })
        .listen((event) {
      _onNewAccelerometerDataCheckMovement(event, onMovementDetected);
    });

    notifyListeners();
  }

  void _onNewAccelerometerDataCheckMovement(dynamic accData, Function onMovementDetected) {
    Map<String, dynamic> body = accData["Body"];
    List<dynamic> accArray = body["ArrayAcc"];
    dynamic acc = accArray.last;
    _accelerometerData["x"] = acc["x"].toDouble();
    _accelerometerData["y"] = acc["y"].toDouble();
    _accelerometerData["z"] = acc["z"].toDouble();
    runningStatX.push(_accelerometerData["x"]!);
    runningStatY.push(_accelerometerData["y"]!);
    runningStatZ.push(_accelerometerData["z"]!);
    stdSum = runningStatX.maxStd() + runningStatY.maxStd() + runningStatZ.maxStd();
    if (stdSum > MOVEMENT_THRESHOLD) {
      onMovementDetected();
    }
    notifyListeners();
  }

  void subscribeToAccelerometerCheckForMovementForAnimation({required Function onMovementDetected}) {
    _accelerometerData = Map();
    runningStatX.clear();
    runningStatY.clear();
    runningStatZ.clear();
    stdSum = 0.0;

    _accSubscription = MdsAsync.subscribe(
        Mds.createSubscriptionUri(_serial!, "/Meas/Acc/13"), "{}")
        .handleError((error) => {
      debugPrint("Error on subscribeToAccelerometerCheckForMovement: $error")
    })
        .listen((event) {
      _onNewAccelerometerDataCheckMovementForAnimation(event, onMovementDetected);
    });

    notifyListeners();
  }

  void _onNewAccelerometerDataCheckMovementForAnimation(dynamic accData, Function onMovementDetected) {
    Map<String, dynamic> body = accData["Body"];
    List<dynamic> accArray = body["ArrayAcc"];
    dynamic acc = accArray.last;
    _accelerometerData["x"] = acc["x"].toDouble();
    _accelerometerData["y"] = acc["y"].toDouble();
    _accelerometerData["z"] = acc["z"].toDouble();
    runningStatX.push(_accelerometerData["x"]!);
    runningStatY.push(_accelerometerData["y"]!);
    runningStatZ.push(_accelerometerData["z"]!);
    stdSum = runningStatX.maxStd() + runningStatY.maxStd() + runningStatZ.maxStd();
    if (stdSum > MOVEMENT_THRESHOLD_ANIMATION) {
      onMovementDetected();
      _accelerometerData = Map();
      runningStatX.clear();
      runningStatY.clear();
      runningStatZ.clear();
      stdSum = 0.0;
    }
    notifyListeners();
  }

  void unsubscribeFromAccelerometer() {
    if (_accSubscription != null) {
      _accSubscription!.cancel();
    }
    _accSubscription = null;
    notifyListeners();
  }

  Future<InfoResponse> getImuInfo() {
    InfoResponse imuInfoResponse;
    Completer<InfoResponse> completer = Completer<InfoResponse>();
    Mds.get(Mds.createRequestUri(_serial!, "/Meas/IMU/Info"),
        "{}",
            (data, statusCode) {
          /* onSuccess */
          imuInfoResponse = InfoResponse(data);
          completer.complete(imuInfoResponse);
        },
            (error, statusCode) {
          /* onError */
          completer.complete();
        }
    );
    return completer.future;
  }

  Future<void> subscribeToIMU9(var rate, String activity) async {
    this.activity = activity;
    _imu9Data = Map();

    sampleRate = int.parse(rate.toString());
    debugPrint("Subscribing to IMU9. Rate: $sampleRate");

    _csvDataImu9 = [];
    _csvDataImu9.add(csvHeaderImu9);

    timeDetailedStart = await getTimeDetailed();

    _imu9Subscription = MdsAsync.subscribe(
        Mds.createSubscriptionUri(_serial!, "/Meas/IMU9/$rate"), "{}")
        .handleError((error) {
      debugPrint("Error: " + error.toString());
    })
        .listen((event) {
      _onNewIMU9Data(event);
    });
  }

  void _onNewIMU9Data(dynamic imuData) {
    Map<String, dynamic> body = imuData["Body"];
    List<dynamic> accArray = body["ArrayAcc"];
    List<dynamic> gyroArray = body["ArrayGyro"];
    List<dynamic> magnArray = body["ArrayMagn"];

    var sampleInterval = 1000 / sampleRate;

    for (var probeIdx = 0; probeIdx < accArray.length; probeIdx++) {

      // Interpolate timestamp within update
      int timestamp = body["Timestamp"] +
          (sampleInterval * probeIdx).round();

      List<String> csvRow = [
        userId!,
        userAge!,
        userSex!,
        userHeight!,
        userWeight!,
        activity,
        timestamp.toString(),
        accArray[probeIdx]["x"].toStringAsFixed(2),
        accArray[probeIdx]["y"].toStringAsFixed(2),
        accArray[probeIdx]["z"].toStringAsFixed(2),
        gyroArray[probeIdx]["x"].toStringAsFixed(2),
        gyroArray[probeIdx]["y"].toStringAsFixed(2),
        gyroArray[probeIdx]["z"].toStringAsFixed(2),
        magnArray[probeIdx]["x"].toStringAsFixed(2),
        magnArray[probeIdx]["y"].toStringAsFixed(2),
        magnArray[probeIdx]["z"].toStringAsFixed(2),
        bodyPosition!.name,
      ];
      _csvDataImu9.add(csvRow);
    }

  }

  Future<void> unsubscribeFromIMU9() async {
    if (_imu9Subscription != null) {
      _imu9Subscription!.cancel();
    }
    _imu9Subscription = null;

    timeDetailedEnd = await getTimeDetailed();

    // Add start time and end time to csv data
    _csvDataImu9[1].add(timeDetailedStart["utc"].toString());
    _csvDataImu9[1].add(timeDetailedStart["relativeTime"].toString());
    _csvDataImu9[2].add(timeDetailedEnd["utc"].toString());
    _csvDataImu9[2].add(timeDetailedEnd["relativeTime"].toString());

    notifyListeners();
  }

  void getEcgConfig() {
    InfoResponse imuInfoResponse;
    Mds.get(Mds.createRequestUri(_serial!, "/Meas/ECG/Config"),
        "{}",
            (data, statusCode) {
          /* onSuccess */
          imuInfoResponse = InfoResponse(data);
        },
            (error, statusCode) {
          /* onError */
        }
    );
  }

  void subscribeToHr() {
    if (_onHrStart != null) {
      _onHrStart!.call();
    }
    _hrData = "";

    _csvDataHr = [];
    _csvDataHr.add(csvHeaderHr);

    stopwatch.start();
    _hrSubscription = MdsAsync.subscribe(
      Mds.createSubscriptionUri(_serial!, "/Meas/HR"), "{}",)
        .listen((event) {
      _onNewHrData(event);
    });
    notifyListeners();
  }

  void _onNewHrData(dynamic hrData) {
    Map<String, dynamic> body = hrData["Body"];
    double hr = body["average"].toDouble();
    _hrData = hr.toStringAsFixed(1);
    int timestamp = DateTime.now().microsecondsSinceEpoch+localTimeOffset;

    List<String> csvRow = [
      timestamp.toString(),
      _hrData,
      bodyPosition!.name,
    ];
    _csvDataHr.add(csvRow);

    previousTimestamp = stopwatch.elapsedMilliseconds;
    if (_onHrDataReceived != null) {
      _onHrDataReceived!.call(this);
    }
    notifyListeners();
  }

  Future<void> unsubscribeFromHr() async {
    if (_onHrStop != null) {
      _onHrStop!.call();
    }

    if (_hrSubscription != null) {
      _hrSubscription!.cancel();
    }
    _hrSubscription = null;
    stopwatch.stop();

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