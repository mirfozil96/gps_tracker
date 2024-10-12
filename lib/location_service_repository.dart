import 'package:background_locator_2/location_dto.dart';

class LocationServiceRepository {
  late Map<dynamic, dynamic> _data;

  Future<void> init(Map<dynamic, dynamic> params) async {
    _data = params;
    // Boshlang'ich sozlamalar
  }

  Future<void> dispose() async {
    // Resurslarni tozalash
  }

  Future<void> callback(LocationDto locationDto) async {
    // Joylashuv ma'lumotlarini saqlash yoki serverga yuborish
  }
}
