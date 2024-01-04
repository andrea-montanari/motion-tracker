import 'dart:collection';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:mdsflutter/Mds.dart';
import 'package:multi_sensor_collector/DeviceConnectionStatus.dart';

import 'DeviceListModel.dart';
import 'DeviceModel.dart';

class AppModel extends ChangeNotifier {
  final int _DEVICES_TO_CONNECT_NUM = 7;
  int get DEVICES_TO_CONNECT_NUM => _DEVICES_TO_CONNECT_NUM;
  final Set<DeviceModel> _deviceList = Set();
  final Set<DeviceModel> _connectedDeviceList = Set();
  DeviceListModel _configuredDeviceList = DeviceListModel();
  bool _isScanning = false;
  void Function(DeviceModel)? _onDeviceMdsConnectedCb;
  void Function(DeviceModel)? _onDeviceDisonnectedCb;

  UnmodifiableListView<DeviceModel> get deviceList =>
      UnmodifiableListView(_deviceList);
  UnmodifiableListView<DeviceModel> get connectedDeviceList =>
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

  void onDeviceMdsConnected(void Function(DeviceModel) cb) {
    _onDeviceMdsConnectedCb = cb;
  }

  void onDeviceMdsDisconnected(void Function(DeviceModel) cb) {
    _onDeviceDisonnectedCb = cb;
  }

  void startScan() {
    _deviceList.forEach((deviceModel) {
      if (deviceModel.device.connectionStatus == DeviceConnectionStatus.CONNECTED) {
        disconnectFromDevice(deviceModel);
      }
    });

    _deviceList.clear();
    notifyListeners();

    try {
      Mds.startScan((name, address) {
        DeviceModel device = DeviceModel(name, address);
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

  void connectToDevice(DeviceModel deviceModel) {
    deviceModel.device.onConnecting();
    notifyListeners();
    Mds.connect(
        deviceModel.device.address!,
            (serial) => _onDeviceMdsConnected(deviceModel.device.address, serial),
            () => _onDeviceDisconnected(deviceModel.device.address),
            () => _onDeviceConnectError(deviceModel.device.address));
  }

  void disconnectFromDevice(DeviceModel deviceModel) {
    Mds.disconnect(deviceModel.device.address!);
    _onDeviceDisconnected(deviceModel.device.address);
  }

  void _onDeviceMdsConnected(String? address, String serial) {
    DeviceModel foundDevice =
    _deviceList.firstWhere((deviceModel) => deviceModel.device.address == address);

    if (!_connectedDeviceList.contains(foundDevice)) {
      _connectedDeviceList.add(foundDevice);
    }

    foundDevice.device.onMdsConnected(serial);
    notifyListeners();
    if (_onDeviceMdsConnectedCb != null) {
      _onDeviceMdsConnectedCb!.call(foundDevice);
    }
  }

  void _onDeviceDisconnected(String? address) {
    DeviceModel foundDevice =
    _deviceList.firstWhere((deviceModel) => deviceModel.device.address == address);

    if (_connectedDeviceList.contains(foundDevice)) {
      _connectedDeviceList.remove(foundDevice);
    }

    foundDevice.device.onDisconnected();
    notifyListeners();
    if (_onDeviceDisonnectedCb != null) {
      _onDeviceDisonnectedCb!.call(foundDevice);
    }
  }

  void _onDeviceConnectError(String? address) {
    _onDeviceDisconnected(address);
  }

}
