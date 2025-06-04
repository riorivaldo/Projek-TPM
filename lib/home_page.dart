import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';

import 'crypto.dart';
import 'detail_page.dart';
import 'login_page.dart';
import 'location_service.dart';
import 'security_tips_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<CryptoTicker>> _cryptoListFuture;
  String? _username;
  int _currentIndex = 0;
  late final List<Widget> _pages;

  Position? _currentPosition;
  String? _localTimeZone;

  String? _userCountry;
  String? _popularCoin;

  List<String> _securityTips = [];

  @override
  void initState() {
    super.initState();
    _cryptoListFuture = fetchCryptoTickers();
    _loadUsername();
    _getUserLocation();
    _loadSecurityTips();

    _pages = [
      CryptoListPage(cryptoListFuture: _cryptoListFuture),
      const ProfilePage(),
      const FeedbackPage(),
      LogoutPage(onLogout: _logout),
    ];
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? 'User';
    });
  }

  Future<List<CryptoTicker>> fetchCryptoTickers() async {
    final pairsResponse =
        await http.get(Uri.parse('https://indodax.com/api/pairs'));
    final tickersResponse =
        await http.get(Uri.parse('https://indodax.com/api/ticker_all'));

    if (pairsResponse.statusCode == 200 && tickersResponse.statusCode == 200) {
      final pairsData = jsonDecode(pairsResponse.body) as List<dynamic>;
      final tickersData =
          jsonDecode(tickersResponse.body)['tickers'] as Map<String, dynamic>;

      final Map<String, Map<String, dynamic>> pairsMap = {
        for (var p in pairsData) p['ticker_id']: p
      };

      List<CryptoTicker> list = [];

      tickersData.forEach((pairId, ticker) {
        if (pairsMap.containsKey(pairId)) {
          final pairInfo = pairsMap[pairId]!;
          list.add(CryptoTicker(
            pairId: pairId,
            name: pairInfo['description'] ?? pairId.toUpperCase(),
            urlLogoPng: pairInfo['url_logo_png'] ?? '',
            last: ticker['last'] ?? '0',
            high: ticker['high'] ?? '0',
            low: ticker['low'] ?? '0',
            buy: ticker['buy'] ?? '0',
            sell: ticker['sell'] ?? '0',
            serverTime: ticker['server_time'] ?? 0,
          ));
        }
      });

      return list;
    } else {
      throw Exception('Failed to load data from Indodax');
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  Future<void> _getUserLocation() async {
    try {
      Position pos = await LocationService.getCurrentPosition();
      final nowUtc = DateTime.now().toUtc();
      final offsetHours = (pos.longitude / 15).round();
      final timezoneStr = _formatTimeZone(offsetHours);

      final country = await LocationService.getCountryFromPosition(pos);

      final Map<String, String> countryCoinMap = {
        'Indonesia': 'Indodax (IDR)',
        'United States': 'Bitcoin (BTC)',
        'Japan': 'Monacoin (MONA)',
        'South Korea': 'Klaytn (KLAY)',
        'China': 'N/A (Regulasi ketat)',
      };

      String popularCoin = 'Tidak tersedia';
      if (country != null && countryCoinMap.containsKey(country)) {
        popularCoin = countryCoinMap[country]!;
      }

      if (mounted) {
        setState(() {
          _currentPosition = pos;
          _localTimeZone = timezoneStr;
          _userCountry = country;
          _popularCoin = popularCoin;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentPosition = null;
          _localTimeZone = null;
          _userCountry = null;
          _popularCoin = null;
        });
      }
    }
  }

  String _formatTimeZone(int offsetHours) {
    String sign = offsetHours >= 0 ? '+' : '-';
    int hoursAbs = offsetHours.abs();
    return 'GMT$sign$hoursAbs:00';
  }

  Future<void> _loadSecurityTips() async {
    final tips = await SecurityTipsService.getSecurityTips();
    setState(() {
      _securityTips = tips;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Halo, ${_username ?? 'User'}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(90),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _currentPosition != null
                    ? Text(
                        'Lokasi: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)} | Zona waktu: ${_localTimeZone ?? '-'}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      )
                    : const Text(
                        'Lokasi: Tidak tersedia',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                if (_userCountry != null)
                  Text(
                    'Negara: $_userCountry',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                if (_popularCoin != null)
                  Text(
                    'Koin Populer di Negara Anda: $_popularCoin',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                const SizedBox(height: 6),
                _securityTips.isNotEmpty
                    ? Text(
                        'Tips Keamanan: ${_securityTips[0]}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      )
                    : const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.monetization_on), label: 'Kripto'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          BottomNavigationBarItem(icon: Icon(Icons.feedback), label: 'Saran'),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Logout'),
        ],
      ),
    );
  }
}

class CryptoListPage extends StatefulWidget {
  final Future<List<CryptoTicker>> cryptoListFuture;

  const CryptoListPage({super.key, required this.cryptoListFuture});

  @override
  State<CryptoListPage> createState() => _CryptoListPageState();
}

class _CryptoListPageState extends State<CryptoListPage> {
  List<CryptoTicker> _allCryptos = [];
  List<CryptoTicker> _filteredCryptos = [];
  bool _loading = true;
  String _searchQuery = '';

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  static const double shakeThreshold = 15.0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startListeningShake();
  }

  void _startListeningShake() {
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      double acceleration =
          sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (acceleration > shakeThreshold) {
        _refreshData();
      }
    });
  }

  Future<void> _refreshData() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }
    try {
      final list = await widget.cryptoListFuture;
      if (mounted) {
        setState(() {
          _allCryptos = list;
          _filteredCryptos = list;
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data kripto berhasil diperbarui!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui data: $e')),
        );
      }
    }
  }

  Future<void> _loadData() async {
    try {
      final list = await widget.cryptoListFuture;
      if (mounted) {
        setState(() {
          _allCryptos = list;
          _filteredCryptos = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _allCryptos = [];
          _filteredCryptos = [];
          _loading = false;
        });
      }
    }
  }

  void _filterCryptos(String query) {
    final filtered = _allCryptos.where((crypto) {
      final nameLower = crypto.name.toLowerCase();
      final pairLower = crypto.pairId.toLowerCase();
      final queryLower = query.toLowerCase();
      return nameLower.contains(queryLower) || pairLower.contains(queryLower);
    }).toList();

    setState(() {
      _searchQuery = query;
      _filteredCryptos = filtered;
    });
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Cari Kripto',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onChanged: _filterCryptos,
          ),
        ),
        Expanded(
          child: _filteredCryptos.isEmpty
              ? const Center(child: Text('Data tidak ditemukan'))
              : ListView.builder(
                  itemCount: _filteredCryptos.length,
                  itemBuilder: (context, index) {
                    final crypto = _filteredCryptos[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: (crypto.urlLogoPng.isNotEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  crypto.urlLogoPng,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.attach_money,
                                        size: 40);
                                  },
                                ),
                              )
                            : const Icon(Icons.attach_money, size: 40),
                        title: Text(
                          crypto.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        subtitle: Text('Harga terakhir: Rp ${crypto.last}'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => DetailPage(crypto: crypto)),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 100,
            backgroundImage: AssetImage('assets/Profile.jpg'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Rio Rivaldo Sinuhaji',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('NIM : 123220005'),
          const SizedBox(height: 4),
          const Text('Kelas : TPM-IF-B'),
        ],
      ),
    );
  }
}

class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Saran & Kesan Mata Kuliah Teknologi dan Pemrograman Mobile',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          Text(
            'Saran : Semoga kelas Teknologi dan Pemrograman Mobile menjadi lebih keren lagi',
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 16),
          Text(
            'Kesan : Sangat menyenangkan hehe',
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}

class LogoutPage extends StatelessWidget {
  final VoidCallback onLogout;

  const LogoutPage({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: onLogout,
      ),
    );
  }
}
