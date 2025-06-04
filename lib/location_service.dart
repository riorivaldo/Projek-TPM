import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationService {
  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  /// Reverse geocode untuk mendapatkan nama negara dari koordinat
  static Future<String?> getCountryFromPosition(Position pos) async {
    final url =
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${pos.latitude}&lon=${pos.longitude}&zoom=3&addressdetails=1';

    final response = await http.get(Uri.parse(url), headers: {
      'User-Agent': 'CryptoApp/1.0 (email@example.com)', // ganti sesuai app/email Anda
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['address']?['country'];
    } else {
      return null;
    }
  }
}
