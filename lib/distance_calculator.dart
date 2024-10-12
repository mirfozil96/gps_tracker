
import 'package:latlong2/latlong.dart' as latlng;

class DistanceCalculator {
  final latlng.Distance _distance = latlng.Distance();

  double calculateDistance(latlng.LatLng start, latlng.LatLng end) {
    return _distance(
      latlng.LatLng(start.latitude, start.longitude),
      latlng.LatLng(end.latitude, end.longitude),
    );
  }
}
