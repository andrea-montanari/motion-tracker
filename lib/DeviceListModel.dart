import 'dart:async';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'DeviceModel.dart';
import 'Utils/BodyPositions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';


class DeviceListModel extends ChangeNotifier {
  List<DeviceModel> _devices = [];
  static const int MAXIMUM_RUNNING_TIME_FOR_MOVEMENT_CHECK = 10000;
  static const int INITIAL_DELAY_FOR_MOVEMENT_CHECK = 2000;
  late String _nowFormatted;
  late String userId;
  late String currentActivity;

  List<DeviceModel> get devices => _devices;

  void addDevice(DeviceModel deviceToAdd) {
    devices.add(deviceToAdd);
    notifyListeners();
  }

  void removeDevice(DeviceModel deviceToRemove) {
    for (var device in devices) {
      if (device.serial == deviceToRemove.serial) {
        devices.remove(device);
        break;
      }
    }
    notifyListeners();
  }

  void removeAllDevices() {
    devices.clear();
  }

  void addAllDevices(Iterable<DeviceModel> devicesToAdd) {
    removeAllDevices();
    devices.addAll(devicesToAdd);
    notifyListeners();
  }

  Future<void> subscribeAllDevicesToAccelerometerCheckForMovement() async {
    Completer completer = Completer();
    for (final device in devices) {
      // Check for movement only if position not yet assigned
      if (device.bodyPosition == null) {
        device.subscribeToAccelerometerCheckForMovement(
            onMovementDetected: () async => {
              await unsubscribeAllDevicesToAccelerometer(),
              completer.complete(),
            }
        );
      }
    }
    notifyListeners();
    return completer.future;
  }

  Future<void> unsubscribeAllDevicesToAccelerometer() async {
    Completer completer = Completer();
    devices.forEach((device) => device.unsubscribeFromAccelerometer());
    notifyListeners();
    completer.complete();
    return completer.future;
  }

  Future<List<DeviceModel>?> checkForDevicesMovement() async {
    // return await Future.delayed(const Duration(milliseconds: INITIAL_DELAY_FOR_MOVEMENT_CHECK), () async {
    await subscribeAllDevicesToAccelerometerCheckForMovement();
    devices.sort((b, a) => a.stdSum.compareTo(b.stdSum));
    notifyListeners();
    return devices;
    // });
  }

  Future<bool> synchronizeDevices() async {
    List<bool> setTimeSucceeded = [];
    for (final device in devices) {
      // Set time three times to account for metadata exchange in the first few communications with the sensors
      setTimeSucceeded.add(await device.setTime());
      setTimeSucceeded.add(await device.setTime());
      setTimeSucceeded.add(await device.setTime());
    }
    if (setTimeSucceeded.every((element) => element == true)) {
      return true;
    }
    return false;
  }

  startRecording(var rate, String activity) {
    currentActivity = activity;
    for (final  device in devices) {
      device.subscribeToIMU9(rate, activity);
    }
  }

  stopRecording() async {
    final DateTime now = DateTime.now();
    final DateFormat dateFormat = DateFormat("yyyy-MM-dd_HH-mm-ss");
    _nowFormatted = dateFormat.format(now);
    for (final device in devices) {
      await device.unsubscribeFromIMU9();
      writeImuDataToCsvFile(device);
    }
  }

  Future<void> writeImuDataToCsvFile(DeviceModel device) async {
    debugPrint("Writing data to csv file");
    String csvDirectoryImu9 = await createExternalDirectory();
    List<List<String>> csvDataImu9 = device.csvDataImu9;
    String csvData = const ListToCsvConverter().convert(csvDataImu9);
    String partialSerial = device.serial!.substring(device.serial!.length - 4);
    String path = "$csvDirectoryImu9/User${userId}_${currentActivity}_${_nowFormatted}_IMU9Data-$partialSerial.csv";
    final File file = await File(path).create(recursive: true);
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
    await file.writeAsString(csvData);
    debugPrint("File written");
  }

  Future<void> writeHrDataToCsvFile(DeviceModel device) async {
    String csvDirectoryHr = await createExternalDirectory();
    List<List<String>> csvDataHr = device.csvDataHr;
    String csvData = const ListToCsvConverter().convert(csvDataHr);
    String partialSerial = device.serial!.substring(
        device.serial!.length - 4);
    String path = "$csvDirectoryHr/${userId}_${_nowFormatted}_HrData-$partialSerial.csv";
    final File file = await File(path).create(recursive: true);
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
    await file.writeAsString(csvData);
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
        debugPrint("Dir exists, path: ${dir.path}");
        return dir.path;
      } else {
        debugPrint("Dir doesn't exist, creating...");
        dir.create();
        return dir.path;
      }
    } else {
      throw Exception('Platform not supported');
    }
  }
}