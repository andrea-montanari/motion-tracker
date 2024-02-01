import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:mdsflutter/Mds.dart';
import 'package:multi_sensor_collector/Utils/BodyPositions.dart';
import 'package:multi_sensor_collector/Utils/DataLoggerConfig.dart';
import 'package:multi_sensor_collector/Utils/RunningStat.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'Utils/InfoResponse.dart';

class DeviceModel extends ChangeNotifier {
  static const double MOVEMENT_THRESHOLD = 4.0;
  int sampleRate = 26;

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
  List<String> csvHeaderImu9 = ["Timestamp","AccX","AccY","AccZ","GyroX","GyroY","GyroZ","MagnX","MagnY","MagnZ", "position", "UTC_start-end", "relativeTime_start-end"];
  List<List<String>> csvDataImu9 = [];
  late String csvDirectoryImu9;

  BodyPositions? bodyPosition;

  Map<String, String> get imu9Data => _imu9Data;

  bool get imu9Subscribed => _imu9Subscription != null;

  List<RunningStat> get runningStats =>
      [runningStatX, runningStatY, runningStatZ];

  StreamSubscription? _hrSubscription;
  String _hrData = "";
  List<String> csvHeaderHr = ["Timestamp","hr", "position"];
  List<List<String>> csvDataHr = [];
  late String csvDirectoryHr;

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

  int? _currentLogId;

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
          print("Time set for sensor $_serial. Data: $data");
          completer.complete(true);
        },
            (error, statusCode) {
          /* onError */
          print("Error on time set for sensor $_serial");
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
          print("Time detailed for sensor $_serial. Data: $data");
          Map timeDetailedData = jsonDecode(data);
          timeDetailed["utc"] = timeDetailedData["Content"]["utcTime"];
          timeDetailed["relativeTime"] = timeDetailedData["Content"]["relativeTime"];
          completer.complete(timeDetailed);
        },
            (error, statusCode) {
          /* onError */
          print("Error on get time detailed for sensor $_serial");
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
    print("Subscribe to accelerometer");
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
          print("IMU info: $data");
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

  Future<void> subscribeToIMU9(var rate) async {
    sampleRate = rate;
    print("Subscribe to IMU 9");
    _imu9Data = Map();
    print("Subscribing to IMU9. Rate: $sampleRate");

    await initImu9DataStructure();

    _imu9Subscription = MdsAsync.subscribe(
        Mds.createSubscriptionUri(_serial!, "/Meas/IMU9/$rate"), "{}")
        .handleError((error) {
      print("Error: $error");
    })
        .listen((event) {
      _onNewIMU9Data(event);
    });
  }

  void _onNewIMU9Data(dynamic imuData) {
    Map<String, dynamic> body = imuData["Body"];
    registerImu9Data(body);
  }

  void unsubscribeFromIMU9(String currentDate) async {
    if (_imu9Subscription != null) {
      _imu9Subscription!.cancel();
    }
    _imu9Subscription = null;

    writeImu9DataToCsv(currentDate);

    notifyListeners();
  }

  void getEcgConfig() {
    InfoResponse imuInfoResponse;
    Mds.get(Mds.createRequestUri(_serial!, "/Meas/ECG/Config"),
        "{}",
            (data, statusCode) {
          /* onSuccess */
          print("ECG Config: $data");
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
      print("_onHrStart");
    }
    _hrData = "";

    csvDataHr = [];
    csvDataHr.add(csvHeaderHr);

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
    csvDataHr.add(csvRow);

    print("--- HR:\n\tTimestamp: ${body["Timestamp"]}\n\tData: ${body["average"]}");
    print('_onNewHrData() executed in ${stopwatch.elapsedMilliseconds - previousTimestamp}');
    previousTimestamp = stopwatch.elapsedMilliseconds;
    if (_onHrDataReceived != null) {
      _onHrDataReceived!.call(this);
    }
    notifyListeners();
  }

  Future<void> unsubscribeFromHr(String currentDate) async {
    if (_onHrStop != null) {
      _onHrStop!.call();
    }

    if (_hrSubscription != null) {
      _hrSubscription!.cancel();
    }
    _hrSubscription = null;
    stopwatch.stop();

    // Write data to csv file
    print("Writing hr data to csv file");
    csvDirectoryHr = await createExternalDirectory();
    print("Directory Hr: $csvDirectoryHr");
    String csvData = const ListToCsvConverter().convert(csvDataHr);
    print("Csv data hr: $csvData");
    String path = "$csvDirectoryHr/${currentDate}_HrData-$serial.csv";
    final File file = await File(path).create(recursive: true);
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
    await file.writeAsString(csvData);

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


  // -------------------------- Data handling -------------------------

  Future<void> initImu9DataStructure() async {
    csvDataImu9 = [];
    csvDataImu9.add(csvHeaderImu9);
    timeDetailedStart = await getTimeDetailed();
  }

  void registerImu9Data(Map imu9Data) {
    print("registerImu9Data start");
    List<dynamic> accArray = imu9Data["ArrayAcc"];
    List<dynamic> gyroArray = imu9Data["ArrayGyro"];
    List<dynamic> magnArray = imu9Data["ArrayMagn"];

    var sampleInterval = 1000 / sampleRate;

    for (var probeIdx = 0; probeIdx < accArray.length; probeIdx++) {

      // Interpolate timestamp within update
      int timestamp = imu9Data["Timestamp"] +
          (sampleInterval * probeIdx).round();

      List<String> csvRow = [
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
        // bodyPosition!.name,
      ];
      print("csvRow: $csvRow");
      csvDataImu9.add(csvRow);
    }
    print("registerImu9Data end");
  }

  Future<String> createExternalDirectory() async {
    Directory? dir;
    if (Platform.isAndroid) {
      dir = Directory('/storage/emulated/0/Movesense'); // For Android
    } else if (Platform.isIOS) {
      dir = await getApplicationSupportDirectory(); // For iOS
    }
    if (dir != null) {
      if ((await dir.exists())) {
        print("Dir exists, path: ${dir.path}");
        return dir.path;
      } else {
        print("Dir doesn't exist, creating...");
        dir.create();
        return dir.path;
      }
    } else {
      throw Exception('Platform not supported');
    }
  }

  Future<void> writeImu9DataToCsv(var currentDate) async {
    timeDetailedEnd = await getTimeDetailed();
    print("csvDataImu9: $csvDataImu9");

    // Add start time, end time and body position to csv data
    csvDataImu9[1].add(timeDetailedStart["utc"].toString());
    csvDataImu9[1].add(timeDetailedStart["relativeTime"].toString());
    csvDataImu9[2].add(timeDetailedEnd["utc"].toString());
    csvDataImu9[2].add(timeDetailedEnd["relativeTime"].toString());
    print("-- first row csv: ${csvDataImu9[1]}");
    print("-- second row csv: ${csvDataImu9[2]}");

    // Write data to csv file
    print("Writing data to csv file");
    csvDirectoryImu9 = await createExternalDirectory();
    print("Directory: $csvDirectoryImu9");
    String csvData = const ListToCsvConverter().convert(csvDataImu9);
    print("Csv data: $csvData");
    String path = "$csvDirectoryImu9/${currentDate}_IMU9Data-$serial.csv";
    final File file = await File(path).create(recursive: true);
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
    await file.writeAsString(csvData);
    print("File written");
  }


  // --------------------------- DataLogger ---------------------------

  Future<void> configDataLogger(var rate) async {
    sampleRate = rate;
    Completer completer = Completer();
    String config = DataLoggerConfig.getDataLoggerConfig("/Meas/Acc/$rate");
    Mds.put(Mds.createRequestUri(_serial!, "/Mem/DataLogger/Config/"),
        config,
            (data, statusCode) {
          /* onSuccess */
          print("Result of datalogger configuration: $data");
          completer.complete();
        },
            (error, statusCode) {
          /* onError */
              print("Error in configDataLogger: $error");
              completer.complete();
        }
    );
    return completer.future;
  }

  Future<void> _setLoggingState(var state) async {
    Completer completer = Completer();
    Mds.put(Mds.createRequestUri(_serial!, "/Mem/DataLogger/State/"),
        "{\"newState\":$state}",  // 3 = start logging, 2 = stop logging
            (data, statusCode) {
          /* onSuccess */
          print("Result of setLoggingState: $data");
          completer.complete();
        },
            (error, statusCode) {
          /* onError */
          print("Error in setLoggingState: $error");
          completer.complete();
        }
    );
    return completer.future;
  }

  Future<void> startLogging() async {
    await initImu9DataStructure();
    await _setLoggingState(3);
  }

  Future<void> stopLogging() async {
    await _setLoggingState(2);
  }

  Future<void> createNewLog() async {
    print("Create new log");
    Completer completer = Completer();
    Mds.post(Mds.createRequestUri(_serial!, "/Mem/Logbook/Entries/"),
        "{}",
            (data, statusCode) {
          /* onSuccess */
          print("Result of createNewLog: $data");
          Map newLogData = jsonDecode(data);
          _currentLogId = newLogData["Content"];
          print("current log id: $_currentLogId");
          completer.complete();
        },
            (error, statusCode) {
          /* onError */
          print("Error in createNewLog: $error");
          completer.complete();
        }
    );
    return completer.future;
  }

  Future<void> fetchLogEntry(var currentDate) async {
    Completer completer = Completer();
    print("Fetching log entry");
    print("Current log id (fetchLogEntry): $_currentLogId");
    String fetchLogEntryUri = "suunto://MDS/Logbook/${_serial!}/ById/${_currentLogId!-1}/Data";
    final stopwatch = Stopwatch()..start();
    Mds.get(fetchLogEntryUri,
        "{}",
            (data, statusCode) {
          /* onSuccess */
          print("Fetch Time: ${stopwatch.elapsedMilliseconds}");
          print("Result of fetchLogEntry: $data");

          Map logData = jsonDecode(data)['Meas'];
          print("logData: $logData");
          print("logData[imu9]: ${logData['IMU9']}");
          print("logData[imu9][0]: ${logData['IMU9'][0]}");
          print("ArrayAcc: ${logData['IMU9'][0]['ArrayAcc']}");
          for (Map imuData in logData['IMU9']) {
            registerImu9Data(imuData);
           }

          writeImu9DataToCsv(currentDate);

          completer.complete();
        },
            (error, statusCode) {
          /* onError */
          print("Error in fetchLogEntry: $error");
          completer.complete();
        }
    );
    return completer.future;
  }

  Future<void> eraseLogbook() async {
    Completer completer = Completer();
    Mds.del(Mds.createRequestUri(_serial!, "/Mem/Logbook/Entries/"),
        "{}",
            (data, statusCode) {
          /* onSuccess */
          print("Result of eraseLogbook: $data");
          completer.complete();
        },
            (error, statusCode) {
          /* onError */
          print("Error in eraseLogbook: $error");
          completer.complete();
        }
    );
    return completer.future;
  }

}