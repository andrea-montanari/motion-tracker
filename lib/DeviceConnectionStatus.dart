enum DeviceConnectionStatus { NOT_CONNECTED, CONNECTING, CONNECTED }

extension DeviceConnectionStatusExtenstion on DeviceConnectionStatus {
  String get statusName {
    switch (this) {
      case DeviceConnectionStatus.NOT_CONNECTED:
        return "Non connesso";
      case DeviceConnectionStatus.CONNECTING:
        return "Connessione in corso";
      case DeviceConnectionStatus.CONNECTED:
        return "MDS connesso";
    }
  }
}
