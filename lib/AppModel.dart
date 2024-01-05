import 'dart:collection';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:mdsflutter/Mds.dart';
import 'package:multi_sensor_collector/DeviceConnectionStatus.dart';
import 'package:multi_sensor_collector/Utils/BodyPositions.dart';

import 'Device.dart';
import 'DeviceListModel.dart';

class AppModel extends ChangeNotifier {
  final int _DEVICES_TO_CONNECT_NUM = BodyPositions.values.length;
  int get DEVICES_TO_CONNECT_NUM => _DEVICES_TO_CONNECT_NUM;
  final Set<Device> _deviceList = Set();
  final Set<Device> _connectedDeviceList = Set();
  DeviceListModel _configuredDeviceList = DeviceListModel();
  bool _isScanning = false;
  void Function(Device)? _onDeviceMdsConnectedCb;
  void Function(Device)? _onDeviceDisonnectedCb;

  UnmodifiableListView<Device> get deviceList =>
      UnmodifiableListView(_deviceList);
  UnmodifiableListView<Device> get connectedDeviceList =>
      UnmodifiableListView(_connectedDeviceList);
  DeviceListModel get configuredDeviceList => _configuredDeviceList;
  void set configuredDeviceList (DeviceListModel configuredDevices) => {
    _configuredDeviceList = configuredDevices,
    notifyListeners(),
  };
  void clearConfiguredDevices () => {
    _configuredDeviceList.devices.clear(),
    notifyListeners(),
  };

  bool get isScanning => _isScanning;

  String get scanButtonText => _isScanning ? "Stop scansione" : "Avvia scansione";
  String get configButtonText => "Configura sensori";
  String get recordingButtonText => "Avvia registrazione";
  String get stopRecordingButtonText => "Ferma registrazione";
  String get dropdownRateSelHint => "Data rate";

  void onDeviceMdsConnected(void Function(Device) cb) {
    _onDeviceMdsConnectedCb = cb;
  }

  void onDeviceMdsDisconnected(void Function(Device) cb) {
    _onDeviceDisonnectedCb = cb;
  }

  void startScan() {
    _deviceList.forEach((device) {
      if (device.connectionStatus == DeviceConnectionStatus.CONNECTED) {
        disconnectFromDevice(device);
      }
    });

    _deviceList.clear();
    notifyListeners();

    try {
      Mds.startScan((name, address) {
        Device device = Device(name, address);
        if (!_deviceList.contains(device)) {
          _deviceList.add(device);
          notifyListeners();
        }
      });
      _isScanning = true;
      notifyListeners();
    } on PlatformException {
      _isScanning = false;
      notifyListeners();
    }
  }

  void stopScan() {
    Mds.stopScan();
    _isScanning = false;
    notifyListeners();
  }

  void connectToDevice(Device device) {
    device.onConnecting();
    notifyListeners();
    Mds.connect(
        device.address!,
            (serial) => _onDeviceMdsConnected(device.address, serial),
            () => _onDeviceDisconnected(device.address),
            () => _onDeviceConnectError(device.address));
  }

  void disconnectFromDevice(Device device) {
    Mds.disconnect(device.address!);
    _onDeviceDisconnected(device.address);
  }

  void _onDeviceMdsConnected(String? address, String serial) {
    Device foundDevice =
    _deviceList.firstWhere((device) => device.address == address);

    if (!_connectedDeviceList.contains(foundDevice)) {
      _connectedDeviceList.add(foundDevice);
    }

    foundDevice.onMdsConnected(serial);
    notifyListeners();
    if (_onDeviceMdsConnectedCb != null) {
      _onDeviceMdsConnectedCb!.call(foundDevice);
    }
  }

  void _onDeviceDisconnected(String? address) {
    Device foundDevice =
    _deviceList.firstWhere((device) => device.address == address);

    if (_connectedDeviceList.contains(foundDevice)) {
      _connectedDeviceList.remove(foundDevice);
    }

    foundDevice.onDisconnected();
    notifyListeners();
    if (_onDeviceDisonnectedCb != null) {
      _onDeviceDisonnectedCb!.call(foundDevice);
    }
  }

  void _onDeviceConnectError(String? address) {
    _onDeviceDisconnected(address);
  }

}
