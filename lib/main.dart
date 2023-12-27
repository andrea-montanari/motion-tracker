import 'package:flutter/material.dart';
import 'package:multi_sensor_collector/AppModel.dart';
import 'package:provider/provider.dart';

import 'package:multi_sensor_collector/ScanWidget.dart';

void main() {
  runApp(
      ChangeNotifierProvider(
        create: (context) => AppModel(),
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: ScanWidget(),
        ),
      )
  );
}
