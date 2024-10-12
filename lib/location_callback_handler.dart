import 'dart:isolate';
import 'dart:ui';

import 'package:background_locator_2/location_dto.dart';
import 'location_service_repository.dart';
class LocationCallbackHandler {
  static const String isolateName = 'LocatorIsolate';
  static SendPort? uiSendPort;

  static void initCallback(Map<dynamic, dynamic> params) {
    print('Fon xizmati ishga tushdi');
    LocationServiceRepository myLocationCallbackRepository =
        LocationServiceRepository();
    myLocationCallbackRepository.init(params);
  }

  static void disposeCallback() {
    print('Fon xizmati to\'xtatildi');
    LocationServiceRepository myLocationCallbackRepository =
        LocationServiceRepository();
    myLocationCallbackRepository.dispose();
  }

  static void callback(LocationDto locationDto) async {
    print('Yangi joylashuv: ${locationDto.latitude}, ${locationDto.longitude}');

    // UI ga ma'lumot yuborish
    uiSendPort ??= IsolateNameServer.lookupPortByName(isolateName);
    uiSendPort?.send(locationDto);
  }
}
