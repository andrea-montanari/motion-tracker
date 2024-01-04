import 'dart:async';
import 'package:flutter/material.dart';
import 'package:multi_sensor_collector/Device.dart';
import 'package:multi_sensor_collector/DeviceConnectionStatus.dart';
import 'package:multi_sensor_collector/AppModel.dart';
import 'package:multi_sensor_collector/DevicesConfigurationPage.dart';
import 'package:multi_sensor_collector/Utils/InfoResponse.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'DeviceModel.dart';

class ScanWidget extends StatefulWidget {
  @override
  _ScanWidgetState createState() => _ScanWidgetState();
}

class _ScanWidgetState extends State<ScanWidget> {
  late AppModel model;
  bool allDevicesConnected = false;
  bool recording = false;

  List sampleRates = [];
  late var dropdownValue;

  @override
  void initState() {
    super.initState();
    initPlatformState();
    model = Provider.of<AppModel>(context, listen: false);
    InfoResponse imuInfo;
    model.onDeviceMdsConnected((device) async => {
      print("Deviced connected: ${model.connectedDeviceList.length} Devices to connect num: ${model.DEVICES_TO_CONNECT_NUM}"),
      model.connectedDeviceList.length == model.DEVICES_TO_CONNECT_NUM ? allDevicesConnected = true : allDevicesConnected = false,
      if (sampleRates.isEmpty) {
        imuInfo = await model.connectedDeviceList.first.getImuInfo(),
        print("Sample rates: ${imuInfo.sampleRates}"),
        updateDropdownElements(imuInfo.sampleRates),
      }
    });
    model.onDeviceMdsDisconnected((device) => model.connectedDeviceList.length == model.DEVICES_TO_CONNECT_NUM ? allDevicesConnected = true : allDevicesConnected = false,);
  }

  Future<void> initPlatformState() async {
    if (!mounted) return;

    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.storage,
      Permission.manageExternalStorage,
    ].request();
    debugPrint("PermissionStatus: $statuses");
  }

  void updateDropdownElements(List sampleRates) {
    setState(() {
      this.sampleRates = sampleRates;
      dropdownValue = this.sampleRates.first;
    });
  }

  Widget _buildDeviceItem(BuildContext context, int index) {
    return Card(
      child: ListTile(
        title: Text(model.deviceList[index].name!),
        subtitle: Text(model.deviceList[index].device.address!),
        trailing: Text(model.deviceList[index].device.connectionStatus.statusName),
        onTap: () => {
          if (model.deviceList[index].device.connectionStatus == DeviceConnectionStatus.NOT_CONNECTED) {
            model.connectToDevice(model.deviceList[index])
          } else {
            model.disconnectFromDevice(model.deviceList[index])
          }
        },
      ),
    );
  }

  Widget _buildDeviceList(List<DeviceModel> deviceList) {
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

  void onRecordButtonPressed(var rate) {
    recording ? model.configuredDeviceList.stopRecording() :
    model.configuredDeviceList.startRecording(rate);
    setState(() {
      recording = !recording;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Mds Flutter Example'),
        ),
        body: Consumer<AppModel>(
          builder: (context, model, child) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(0,0,0,50),
              child: Column(
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
                  Stack(
                    children: [

                      Center(
                        child: ElevatedButton(
                          onPressed: () => {
                            if (model.configuredDeviceList.devices.length == model.DEVICES_TO_CONNECT_NUM &&
                            model.connectedDeviceList.length == model.DEVICES_TO_CONNECT_NUM)
                            {
                              onRecordButtonPressed(dropdownValue)
                            } else {
                              null
                            }
                          },
                          child: recording ? Text(model.stopRecordingButtonText) : Text(model.recordingButtonText),
                        ),
                      ),
                      if (sampleRates.isNotEmpty) Column(
                        children:  [
                          Text(model.dropdownRateSelHint),
                          DropdownButton<String>(
                            alignment: Alignment.center,
                            // hint: Text(model.dropdownRateSelHint),
                            value: dropdownValue.toString(),
                            icon: const Icon(Icons.arrow_downward),
                            elevation: 16,
                            underline: Container(
                              color: Colors.black12,
                              height: 2,
                            ),
                            onChanged: (String? value) {
                              // This is called when the user selects an item.
                              setState(() {
                                dropdownValue = value!;
                              });
                            },
                            items: sampleRates.map<DropdownMenuItem<String>>((var value) {
                              return DropdownMenuItem(
                                value: value.toString(),
                                child: Text(value.toString()),
                              );
                            }).toList(),
                          ),
                        ]
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ));
  }
}
