import 'package:flutter/material.dart';
import 'package:multi_sensor_collector/Utils/BodyPositions.dart';
import 'package:provider/provider.dart';
import 'package:timer_count_down/timer_count_down.dart';
import 'package:collection/collection.dart';
import 'AppModel.dart';
import 'DeviceListModel.dart';
import 'DeviceModel.dart';

class DevicesConfigurationPage extends StatefulWidget {

  @override
  State<StatefulWidget> createState() {
    return _DevicesConfigurationPageState();
  }
}

class _DevicesConfigurationPageState extends State<DevicesConfigurationPage> {
  late Map<BodyPositions, bool> _callbackSuccess;
  late ValueNotifier<bool> _configurationCompleted;
  late DeviceListModel deviceListModel;
  late AppModel model;

  @override
  void initState() {
    super.initState();
    model = Provider.of<AppModel>(context, listen: false);
    deviceListModel = DeviceListModel();
    _callbackSuccess = Map();
    DeviceModel deviceModel;
    if (model.configuredDeviceList.devices.length == model.DEVICES_TO_CONNECT_NUM) {
      deviceListModel.addAllDevices(model.configuredDeviceList.devices);
      _callbackSuccess = {
        for (var value in BodyPositions.values) value: true
      };
    } else {
      model.deviceList.forEach((device) => {
        deviceModel = DeviceModel(device.name, device.serial),
        deviceListModel.addDevice(deviceModel),
      });
      _callbackSuccess = {
        for (var value in BodyPositions.values) value: false
      };
    }
    _configurationCompleted = ValueNotifier<bool>(false);
  }

  Future<bool?> _showMovementDetectedDialog(BodyPositions bodyPart) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Movimento rilevato'),
          content:  SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Il dispositivo con il led accesso è quello in posizione ${bodyPart.name}?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Sì'),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showCountDownDialog(BodyPositions bodyPart) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Prepararsi alla configurazione del sensore in posizione ${bodyPart.name}'),
          content:  SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('Posizionarsi in piedi e con le braccia distese lungo il corpo ed eseguire il movimento al termine del countdown'),
                Align(
                  alignment: Alignment.center,
                  child:
                  Countdown(
                    seconds: 0,   // TODO: set this to 2/3
                    build: (BuildContext context, double time) => Text(
                      (time.toInt()+1).toString(),
                      style: TextStyle(
                        fontSize: 100,
                      ),),
                    interval: Duration(milliseconds: 1000),
                    onFinished: () {
                      print('Timer is done!');
                      Navigator.pop(context, true);
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annulla'),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showMotionDetectionDialog(BodyPositions bodyPart) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Rilevazione del movimento'),
          content:  SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Sollevare ${bodyPart.limb}'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annulla'),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confermi di voler resettare la configurazione?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Sì'),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
          ],
        );
      },
    );
  }


  Future<void> _onButtonPressed(BodyPositions bodyPart) async {
    bool? countDownDialogResult = await _showCountDownDialog(bodyPart);
    if (!countDownDialogResult!) {
      return;
    }

    // If user deletes operation from the dialog return, otherwise get result and continue
    Future<bool?> motionDetectionDialogResultFuture = _showMotionDetectionDialog(bodyPart);
    Future<List<DeviceModel>?> devicesSortedByMovementFuture = deviceListModel.checkForDevicesMovement();
    var futureResults = await Future.any([motionDetectionDialogResultFuture, devicesSortedByMovementFuture]);
    if (futureResults is bool && futureResults == false) {
      deviceListModel.unsubscribeAllDevicesToAccelerometer();
      return;
    }
    List<DeviceModel>? devicesSortedByMovement = await devicesSortedByMovementFuture;
    print("Movement detected");
    context.mounted ? Navigator.pop(context) : null;
    // deviceListModel.addAllDevices(devicesSortedByMovement!);
    print("Devices sorted b movement: ${devicesSortedByMovement!.length}");
    print("deviceListModel length: ${deviceListModel.devices.length}");

    // Show the device that registered the most movement and make the user chose if it's the correct one
    for (final device in deviceListModel.devices) {
      if (device.bodyPosition == null) { // Body part not yet defined
        device.switchLed();
        bool? movementDetectedDialogResult = await _showMovementDetectedDialog(bodyPart);
        device.switchLed();
        if (movementDetectedDialogResult != null && movementDetectedDialogResult) {
          deviceListModel.devices
              .where((element) => element.serial == device.serial)
              .first
              .bodyPosition = bodyPart;
          device.bodyPosition = bodyPart;
          setState(() {
            _callbackSuccess[bodyPart] = true;
          });
          break;
        } else {
          deviceListModel.unsubscribeAllDevicesToAccelerometer();
        }
      }
    }

    // If every other position has been configured, configure chest position by exclusion and complete configuration
    print("deviceListModel.devices.where((element) => element.bodyPosition != null).length : ${deviceListModel.devices.where((element) => element.bodyPosition != null).length}");
    print("deviceListModel.devices.length: ${deviceListModel.devices.length}");
    print("Body part: ${bodyPart.name}");
    BodyPositions? chestPosition = BodyPositions.values.firstWhereOrNull((element) => element.name == "petto");
    if (chestPosition != null && deviceListModel.devices.where((element) => element.bodyPosition != null).length == deviceListModel.devices.length - 1) {
      deviceListModel.devices.where((element) => element.bodyPosition == null).first.bodyPosition = chestPosition;
      model.configuredDeviceList = deviceListModel;
      print("Configuration complete");
      setState(() {
        _callbackSuccess[chestPosition] = true;
        _configurationCompleted.value = true;
      });
    }

    if (deviceListModel.devices.where((element) => element.bodyPosition != null).length == deviceListModel.devices.length) {
      model.configuredDeviceList = deviceListModel;
      _configurationCompleted.value = true;
    }

  }

  Future<void> _onResetButtonPressed() async {
    bool? confirmationDialogResult = await _showConfirmationDialog();
    if (confirmationDialogResult != null && confirmationDialogResult) {
      DeviceModel deviceModel;
      model.deviceList.forEach((device) => {
        deviceModel = DeviceModel(device.name, device.serial),
        deviceListModel.addDevice(deviceModel),
      });
      _callbackSuccess = {
        for (var value in BodyPositions.values) value: false
      };
      model.clearConfiguredDevices();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes in the state variable inside the build method
    _configurationCompleted.addListener(() {
      if (_configurationCompleted.value) {
        // Show a snackbar when the state variable changes to true
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Dispositivi configurati correttamente'),
            ),
          );
        });
        _configurationCompleted.value = false;
      }
    });

    return ChangeNotifierProvider(
        create: (context) => deviceListModel,
        child: Consumer<DeviceListModel>(
            builder: (context, model, child)
            {
              return Scaffold(
                  appBar: AppBar(
                    title: Text("Configurazione dispositivi"),
                    actions: [
                      IconButton(
                        icon: Icon(Icons.refresh),
                        onPressed: _callbackSuccess.values.where((element) => element == true).length > 0 ? _onResetButtonPressed : null,
                        tooltip: "Reset configurazione",
                      )
                    ],
                  ),
                  body: Material(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final bodyPart in BodyPositions.values)
                            Card(
                              child: ListTile(
                                title: Text(bodyPart.nameUpperCase),
                                tileColor: _callbackSuccess[bodyPart]! ? Colors.green : null,
                                enabled: !_callbackSuccess[bodyPart]! && !(bodyPart == BodyPositions.chest),
                                onTap: () => _onButtonPressed(bodyPart),
                              ),
                            ),
                        ],
                      )
                  )
              );
            }));
  }

}