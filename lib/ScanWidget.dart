import 'dart:async';
import 'package:flutter/material.dart';
import 'package:multi_sensor_collector/Device.dart';
import 'package:multi_sensor_collector/DeviceConnectionStatus.dart';
import 'package:multi_sensor_collector/AppModel.dart';
import 'package:multi_sensor_collector/DevicesConfigurationPage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class ScanWidget extends StatefulWidget {
  @override
  _ScanWidgetState createState() => _ScanWidgetState();
}

class _ScanWidgetState extends State<ScanWidget> {
  late AppModel model;
  bool allDevicesConnected = false;

  @override
  void initState() {
    super.initState();
    initPlatformState();
    model = Provider.of<AppModel>(context, listen: false);
    model.onDeviceMdsConnected((device) => {
      print("Deviced connected: ${model.connectedDeviceList.length} Devices to connect num: ${model.DEVICES_TO_CONNECT_NUM}"),
      model.connectedDeviceList.length == model.DEVICES_TO_CONNECT_NUM ? allDevicesConnected = true : allDevicesConnected = false,
    });
    model.onDeviceMdsDisconnected((device) => model.connectedDeviceList.length == model.DEVICES_TO_CONNECT_NUM ? allDevicesConnected = true : allDevicesConnected = false,);
  }

  Future<void> initPlatformState() async {
    if (!mounted) return;

    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
    debugPrint("PermissionStatus: $statuses");
  }

  Widget _buildDeviceItem(BuildContext context, int index) {
    return Card(
      child: ListTile(
        title: Text(model.deviceList[index].name!),
        subtitle: Text(model.deviceList[index].address!),
        trailing: Text(model.deviceList[index].connectionStatus.statusName),
        onTap: () => {
          if (model.deviceList[index].connectionStatus == DeviceConnectionStatus.NOT_CONNECTED) {
            model.connectToDevice(model.deviceList[index])
          } else {
            model.disconnectFromDevice(model.deviceList[index])
          }
        },
      ),
    );
  }

  Widget _buildDeviceList(List<Device> deviceList) {
    return new Expanded(
        child: new ListView.builder(
            itemCount: model.deviceList.length,
            itemBuilder: (BuildContext context, int index) =>
                _buildDeviceItem(context, index)));
  }

  void onScanButtonPressed() {
    if (model.isScanning) {
      model.stopScan();
    } else {
      model.startScan();
    }
  }

  void onConfigButtonPressed() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => DevicesConfigurationPage()
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Mds Flutter Example'),
        ),
        body: Consumer<AppModel>(
          builder: (context, model, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ElevatedButton(
                  onPressed: onScanButtonPressed,
                  child: Text(model.scanButtonText),
                ),
                _buildDeviceList(model.deviceList),
                ElevatedButton(
                  onPressed: allDevicesConnected ? onConfigButtonPressed : null,
                  child: Text(model.configButtonText),
                ),
              ],
            );
          },
        ));
  }
}
