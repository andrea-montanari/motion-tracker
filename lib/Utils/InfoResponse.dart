import 'dart:convert';

class InfoResponse {
  late Map _parsedInfo;
  get infoResponse => _parsedInfo;
  get sampleRates => _parsedInfo["Content"]["SampleRates"];
  get accRanges => _parsedInfo["Content"]["AccRanges"];
  get gyroRanges => _parsedInfo["Content"]["GyroRanges"];
  get magnRanges => _parsedInfo["Content"]["MagnRanges"];

  InfoResponse(String info) {
    _parsedInfo = jsonDecode(info);
  }
}