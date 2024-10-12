import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:geolocator/geolocator.dart' as geo;
import 'package:yandex_mapkit/yandex_mapkit.dart';

// Background Locator 2 paketidan importlar
import 'package:background_locator_2/background_locator.dart' as bl;
import 'package:background_locator_2/location_dto.dart';
import 'package:background_locator_2/settings/locator_settings.dart';
import 'package:background_locator_2/settings/android_settings.dart';
import 'package:background_locator_2/settings/ios_settings.dart';

// Mahalliy fayllar
import 'distance_calculator.dart';
import 'location_callback_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

enum TrackingStatus { idle, tracking, paused }

class HomePageState extends State<HomePage> {
  YandexMapController? _mapController;
  final DistanceCalculator _distanceCalculator = DistanceCalculator();
  final Stopwatch _stopwatch = Stopwatch();

  Timer? _timer;
  double _totalDistance = 0.0; // Masofa metrlarda
  TrackingStatus _trackingStatus = TrackingStatus.idle;

  List<latlng.LatLng> _locations = [];

  Point _currentPosition = Point(latitude: 0.0, longitude: 0.0);

  @override
  void initState() {
    super.initState();
    initPlatformState();
    bl.BackgroundLocator.initialize();
    bl.BackgroundLocator.registerLocationUpdate(
      LocationCallbackHandler.callback,
      initCallback: LocationCallbackHandler.initCallback,
      disposeCallback: LocationCallbackHandler.disposeCallback,
      iosSettings: IOSSettings(
        accuracy: LocationAccuracy.NAVIGATION,
        distanceFilter: 0,
      ),
      autoStop: false,
      androidSettings: AndroidSettings(
        accuracy: LocationAccuracy.NAVIGATION,
        interval: 5,
        distanceFilter: 0,
        client: LocationClient.google,
        androidNotificationSettings: AndroidNotificationSettings(
          notificationTitle: 'GPS Tracker',
          notificationMsg: 'Ilova joylashuvingizni kuzatmoqda',
          notificationIcon: '',
        ),
      ),
    );
  }

  Future<void> initPlatformState() async {
    // Ruxsatnomalarni tekshirish
    await _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    bool serviceEnabled;
    geo.LocationPermission permission;

    // Joylashuv xizmati yoqilganini tekshirish
    serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Joylashuv xizmati yoqilmagan
      return Future.error('Joylashuv xizmati yoqilmagan');
    }

    // Ruxsat holatini tekshirish
    permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
      if (permission == geo.LocationPermission.denied) {
        // Ruxsat berilmagan
        return Future.error('Joylashuv ruxsatlari berilmagan');
      }
    }

    if (permission == geo.LocationPermission.deniedForever) {
      // Ruxsatnomalar abadiy rad etilgan
      return Future.error(
          'Joylashuv ruxsatlari abadiy rad etilgan, ilova ruxsat so\'ray olmaydi.');
    }
  }

  void _startTracking() {
    setState(() {
      _trackingStatus = TrackingStatus.tracking;
      _totalDistance = 0.0;
      _locations.clear();
    });
    _startTimer();
  }

  void _stopTracking() {
    setState(() {
      _trackingStatus = TrackingStatus.idle;
      _stopwatch.reset();
      _timer?.cancel();
    });
    bl.BackgroundLocator.unRegisterLocationUpdate();
  }

  void _toggleWaiting() {
    if (_trackingStatus == TrackingStatus.tracking) {
      setState(() {
        _trackingStatus = TrackingStatus.paused;
      });
      _stopwatch.start();
      _startTimer();
    } else if (_trackingStatus == TrackingStatus.paused) {
      setState(() {
        _trackingStatus = TrackingStatus.tracking;
      });
      _stopwatch.stop();
      _timer?.cancel();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {});
    });
  }

  void _updateLocation(LocationDto locationDto) {
    final latlng.LatLng newLocation =
        latlng.LatLng(locationDto.latitude, locationDto.longitude);

    if (_locations.isNotEmpty) {
      final distance =
          _distanceCalculator.calculateDistance(_locations.last, newLocation);
      setState(() {
        _totalDistance += distance;
      });
    }

    setState(() {
      _locations.add(newLocation);
      _currentPosition = Point(
          latitude: locationDto.latitude, longitude: locationDto.longitude);
    });

    // Xaritada foydalanuvchining joylashuvini yangilash
    _mapController?.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _currentPosition, zoom: 14.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String formattedTime =
        '${_stopwatch.elapsed.inHours.toString().padLeft(2, '0')}:${(_stopwatch.elapsed.inMinutes % 60).toString().padLeft(2, '0')}:${(_stopwatch.elapsed.inSeconds % 60).toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Text('GPS Tracker'),
      ),
      body: Column(
        children: [
          SizedBox(height: 10),
          Text(
            'Umumiy masofa: ${(_totalDistance / 1000).toStringAsFixed(2)} km',
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 5),
          Text(
            'Kutish vaqti: $formattedTime',
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _trackingStatus == TrackingStatus.idle
                    ? _startTracking
                    : null,
                child: Text('Boshlash'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: _trackingStatus != TrackingStatus.idle
                    ? _stopTracking
                    : null,
                child: Text('To\'xtatish'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: _trackingStatus != TrackingStatus.idle
                    ? _toggleWaiting
                    : null,
                child: Text('Kutish'),
              ),
            ],
          ),
          SizedBox(height: 10),
          Expanded(
            child: YandexMap(
              onMapCreated: (YandexMapController controller) {
                _mapController = controller;
              },
              mapObjects: [
                PlacemarkMapObject(
                  mapId: MapObjectId('current_location'),
                  point: _currentPosition,
                  icon: PlacemarkIcon.single(
                    PlacemarkIconStyle(
                      image: BitmapDescriptor.fromAssetImage(
                          'assets/user_location.png'),
                      scale: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
