import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Inisialisasi timezone dan plugin notifikasi
  static Future<void> initialize() async {
    tz.initializeTimeZones();

    final String timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  /// Ambil ringkasan harga kripto favorit dari API Indodax
  static Future<String> fetchFavoriteCryptoSummary() async {
    final favorites = ['btc_idr', 'eth_idr', 'xrp_idr'];

    final response =
        await http.get(Uri.parse('https://indodax.com/api/ticker_all'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final tickers = data['tickers'];

      List<String> summary = [];
      for (var pairId in favorites) {
        if (tickers[pairId] != null) {
          var ticker = tickers[pairId];
          // Hitung persentase perubahan (contoh sederhana)
          double last = double.tryParse(ticker['last']) ?? 0;
          double high = double.tryParse(ticker['high']) ?? 0;
          double low = double.tryParse(ticker['low']) ?? 0;
          double changePercent = 0;
          if (low != 0) {
            changePercent = ((last - low) / low) * 100;
          }

          summary.add(
              '${ticker['name'] ?? pairId.toUpperCase()}: Rp ${last.toStringAsFixed(0)} (${changePercent >= 0 ? "Naik" : "Turun"} ${changePercent.abs().toStringAsFixed(2)}%)');
        }
      }
      return summary.join('\n');
    } else {
      return 'Gagal mengambil data harga kripto.';
    }
  }

  /// Jadwalkan notifikasi harian pukul 08:00 pagi waktu lokal
  static Future<void> scheduleDailyNotification() async {
    final message = await fetchFavoriteCryptoSummary();

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Ringkasan Harga Kripto Harian',
      message,
      _nextInstanceOfEightAM(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_crypto_channel',
          'Daily Crypto Updates',
          channelDescription: 'Notifikasi harian harga kripto favorit',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Hitung waktu zoned DateTime pukul 08:00 pagi berikutnya
  static tz.TZDateTime _nextInstanceOfEightAM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 8);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
