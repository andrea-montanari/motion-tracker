import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'DeviceModel.dart';

class DeviceListModel extends ChangeNotifier {
  List<DeviceModel> _devices = [];
  static const int MAXIMUM_RUNNING_TIME_FOR_MOVEMENT_CHECK = 10000;
  static const int INITIAL_DELAY_FOR_MOVEMENT_CHECK = 2000;

  List<DeviceModel> get devices => _devices;

  void addDevice(DeviceModel deviceToAdd) {
    devices.add(deviceToAdd);
    notifyListeners();
  }

  void removeDevice(DeviceModel deviceToRemove) {
    devices.remove(deviceToRemove);
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

  subscribeAllDevicesToIMU9() {
    for (final device in devices) {
      device.subscribeToIMU9();
      break;
    }
  }

  unsubscribeAllDevicesToIMU9() {
    for (final device in devices) {
      device.unsubscribeFromIMU9();
    }
  }

  Future<void> subscribeAllDevicesToAccelerometerCheckForMovement() async {
    Completer completer = Completer();
    for (final device in devices) {
      // Check for movement only if position not yet assigned
      if (device.bodyPosition == null) {
        device.subscribeToAccelerometerCheckForMovement(
            onMovementDetected: () async => {
              print("Device ${device.serial} moved."),
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
}