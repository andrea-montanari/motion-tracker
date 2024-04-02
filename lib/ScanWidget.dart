import 'dart:async';
import 'package:flutter/material.dart';
import 'package:multi_sensor_collector/Device.dart';
import 'package:multi_sensor_collector/DeviceConnectionStatus.dart';
import 'package:multi_sensor_collector/AppModel.dart';
import 'package:multi_sensor_collector/DevicesConfigurationPage.dart';
import 'package:multi_sensor_collector/Utils/BodyPositions.dart';
import 'package:multi_sensor_collector/Utils/InfoResponse.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'DeviceListModel.dart';
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
  late var sampleRatesDropdownValue;

  List activitiesList = [];
  late var activityDropdownValue;

  bool hrActive = false;
  String hrData = "";

  static const String appBarTitle = "Motion Tracker";
  static const String devicesSynchronization = "Devices synchronization...";
  static const String synchronizationFailed = "Devices synchronization failed, try again.";
  static const String savingData = "Saving data...";
  static const String ok = "Ok";

  @override
  void initState() {
    super.initState();
    initPlatformState();
    model = Provider.of<AppModel>(context, listen: false);
    InfoResponse imuInfo;
    DeviceModel deviceModel;
    model.onDeviceMdsConnected((device) async {
      model.connectedDeviceList.length >= model.DEVICES_TO_CONNECT_NUM ? allDevicesConnected = true : allDevicesConnected = false;

      // Get available sample rates on first connection
      if (sampleRates.isEmpty) {
        deviceModel = DeviceModel(device.name, device.serial);
        imuInfo = await deviceModel.getImuInfo();
        updateDropdownElements(imuInfo.sampleRates);
      }
    });

    activitiesList = [
      "Walking",
      "Sitting",
      "Upstairs",
      "Downstairs",
      "Office"
    ];
    activityDropdownValue = activitiesList[0];

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

  void catchHrDataCallbacks() {
    if (model.configuredDeviceList.devices.isNotEmpty) {
      model.configuredDeviceList.devices
          .where((element) => element.bodyPosition == BodyPositions.chest)
          .first
          .onHrStart(() => setState(() {
        hrActive = true;
      }));
      model.configuredDeviceList.devices
          .where((element) => element.bodyPosition == BodyPositions.chest)
          .first
          .onHrStop(() => setState(() {
        hrActive = false;
      }));
      model.configuredDeviceList.devices
          .where((element) => element.bodyPosition == BodyPositions.chest)
          .first
          .onHrDataReceived((device) { setState(() {
        hrData = device.hrData;
      }); });
    }
  }

  void updateDropdownElements(List sampleRates) {
    setState(() {
      this.sampleRates = sampleRates;
      sampleRatesDropdownValue = this.sampleRates[0];  // Defaults to 26Hz
    });
  }

  Widget _buildDeviceItem(BuildContext context, int index, List<Device> deviceList) {
    return Card(
      child: ListTile(
        title: Text(deviceList[index].name!),
        subtitle: Text(deviceList[index].address!),
        trailing: Text(deviceList[index].connectionStatus.statusName),
        enabled: !recording,
        onTap: () =>
            {
              if (deviceList[index].connectionStatus == DeviceConnectionStatus.NOT_CONNECTED) {
                model.connectToDevice(deviceList[index])
              } else {
                model.disconnectFromDevice(deviceList[index]),
                model.configuredDeviceList = DeviceListModel(),
              }
            },
      ),
    );
  }

  Widget _buildDeviceList(List<Device> deviceList) {
    return new Expanded(
        child: new ListView.builder(
            itemCount: deviceList.length,
            itemBuilder: (BuildContext context, int index) =>
                _buildDeviceItem(context, index, deviceList)));
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
    ).then((_) {
      setState(() {});
    });
  }

  Future<bool?> _showSynchronizationDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return const AlertDialog(
          title: Text(devicesSynchronization),
        );
      },
    );
  }

  Future<bool?> _showSynchronizationFailedDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(synchronizationFailed),
          actions: <Widget>[
            TextButton(
              child: const Text(ok),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showSavingDataDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return const AlertDialog(
          title: Text(savingData),
        );
      },
    );
  }

  Future<void> onRecordButtonPressed(var rate, String activity) async {
    if (recording) {
      _showSavingDataDialog();
      await model.configuredDeviceList.stopRecording();
      Navigator.pop(context);
      setState(() {
        recording = !recording;
      });
    } else {
      _showSynchronizationDialog();
      bool synchronizationSucceeded = await model.configuredDeviceList.synchronizeDevices();
      Navigator.pop(context);
      if (!synchronizationSucceeded) {
        await _showSynchronizationFailedDialog();
        return;
      }
      model.configuredDeviceList.startRecording(rate, activity);
      setState(() {
        recording = !recording;
      });
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(appBarTitle),
        ),
        body: Consumer<AppModel>(
          builder: (context, model, child) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(0,0,0,50),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[

                  // Scan button
                  if (model.configuredDeviceList.devices.isEmpty)
                    ElevatedButton(
                      onPressed: onScanButtonPressed,
                      child: Text(model.scanButtonText),
                    ),

                  // Connected devices count
                  Text(model.connectedDevicesText + model.connectedDeviceList.length.toString()),

                  // Active devices
                  model.configuredDeviceList.devices.isEmpty ?
                    _buildDeviceList(model.deviceList)
                  :
                    _buildDeviceList(model.connectedDeviceList),

                  // Configure devices button
                  ElevatedButton(
                    onPressed: allDevicesConnected ? onConfigButtonPressed : null,
                    child: Text(model.configButtonText),
                  ),
                  Stack(
                    children: [

                      // Start/stop recording button
                      Center(
                        child: ElevatedButton(
                          onPressed:
                            (model.configuredDeviceList.devices.length >= model.DEVICES_TO_CONNECT_NUM &&
                            model.connectedDeviceList.length >= model.DEVICES_TO_CONNECT_NUM)
                                ? () => onRecordButtonPressed(sampleRatesDropdownValue, activityDropdownValue)
                                : null,
                          child: recording ? Text(model.stopRecordingButtonText) : Text(model.startRecordingButtonText),
                        ),
                      ),

                      // Sample rates dropdown
                      if (sampleRates.isNotEmpty) Column(
                        children:  [
                          Text(model.dropdownRateSelHint),
                          DropdownButton<String>(
                            alignment: Alignment.center,
                            value: sampleRatesDropdownValue.toString(),
                            icon: const Icon(Icons.arrow_downward),
                            elevation: 16,
                            underline: Container(
                              color: Colors.black12,
                              height: 2,
                            ),
                            onChanged: (String? value) {
                              // This is called when the user selects an item.
                              setState(() {
                                sampleRatesDropdownValue = value!;
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
                  if (hrActive)
                    // &&
                  // model.configuredDeviceList.devices.where((element) => element.bodyPosition == BodyPositions.chest).first.isActive)
                    Column(
                      children: [
                        Text(model.hrDataText),
                        Text(hrData)
                      ],
                  ),

                  // Activities dropdown
                  Column(
                      children:  [
                        Text(model.dropdownActivitiesSelHint),
                        DropdownButton<String>(
                          alignment: Alignment.center,
                          value: activityDropdownValue.toString(),
                          icon: const Icon(Icons.arrow_downward),
                          elevation: 16,
                          underline: Container(
                            color: Colors.black12,
                            height: 2,
                          ),
                          onChanged: (String? value) {
                            // This is called when the user selects an item.
                            setState(() {
                              activityDropdownValue = value!;
                            });
                          },
                          items: activitiesList.map<DropdownMenuItem<String>>((var value) {
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
            );
          },
        ));
  }
}
