import 'package:flutter/material.dart';
import 'crypto.dart';

class DetailPage extends StatefulWidget {
  final CryptoTicker crypto;

  const DetailPage({super.key, required this.crypto});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final TextEditingController _cryptoAmountController = TextEditingController();
  final TextEditingController _moneyAmountController = TextEditingController();

  String _selectedCurrency = 'IDR';
  String _selectedTimezone = 'WIB';

  static const Map<String, int> timezoneOffsets = {
    'WIB': 7,
    'WITA': 8,
    'WIT': 9,
    'London': 0,
  };

  static const Map<String, double> currencyRates = {
    'IDR': 1,
    'USD': 0.000067,
    'EUR': 0.000061,
  };

  String? _convertedTime;

  bool _isEditingCrypto = false;
  bool _isEditingMoney = false;

  @override
  void initState() {
    super.initState();
    _cryptoAmountController.addListener(_onCryptoChanged);
    _moneyAmountController.addListener(_onMoneyChanged);
    _convertTime();
  }

  void _onCryptoChanged() {
    if (_isEditingMoney) return;

    _isEditingCrypto = true;
    final input = double.tryParse(_cryptoAmountController.text);
    final lastPriceIDR = double.tryParse(widget.crypto.last) ?? 0;

    if (input != null) {
      double moneyInIDR = input * lastPriceIDR;
      double rate = currencyRates[_selectedCurrency] ?? 1;
      double converted = moneyInIDR * rate;

      _moneyAmountController.text = converted.toStringAsFixed(2);
    } else {
      _moneyAmountController.text = '';
    }
    _isEditingCrypto = false;
  }

  void _onMoneyChanged() {
    if (_isEditingCrypto) return;

    _isEditingMoney = true;
    final input = double.tryParse(_moneyAmountController.text);
    final lastPriceIDR = double.tryParse(widget.crypto.last) ?? 0;

    if (input != null && lastPriceIDR != 0) {
      double rate = currencyRates[_selectedCurrency] ?? 1;
      double moneyInIDR = input / rate;
      double converted = moneyInIDR / lastPriceIDR;

      _cryptoAmountController.text = converted.toStringAsFixed(8);
    } else {
      _cryptoAmountController.text = '';
    }
    _isEditingMoney = false;
  }

  void _convertTime() {
    final serverTimestampSec = widget.crypto.serverTime;
    final utcTime = DateTime.fromMillisecondsSinceEpoch(
      serverTimestampSec * 1000,
      isUtc: true,
    );
    final offset = timezoneOffsets[_selectedTimezone] ?? 0;
    final localTime = utcTime.add(Duration(hours: offset));
    setState(() {
      _convertedTime = localTime.toString();
    });
  }

  @override
  void dispose() {
    _cryptoAmountController.dispose();
    _moneyAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.crypto.name} Detail')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Center(
              child: (widget.crypto.urlLogoPng.isNotEmpty)
                  ? Image.network(
                      widget.crypto.urlLogoPng,
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.attach_money, size: 80);
                      },
                    )
                  : const Icon(Icons.attach_money, size: 80),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: const Text('Harga Terakhir'),
                trailing: Text('Rp ${widget.crypto.last}'),
              ),
            ),
            Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: const Text('Harga Tertinggi'),
                trailing: Text('Rp ${widget.crypto.high}'),
              ),
            ),
            Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: const Text('Harga Terendah'),
                trailing: Text('Rp ${widget.crypto.low}'),
              ),
            ),
            Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: const Text('Harga Beli'),
                trailing: Text('Rp ${widget.crypto.buy}'),
              ),
            ),
            Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: const Text('Harga Jual'),
                trailing: Text('Rp ${widget.crypto.sell}'),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Konversi Harga Koin ke Mata Uang',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: _selectedCurrency,
                    decoration: const InputDecoration(
                      labelText: 'Mata Uang',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCurrency = value;
                          _onCryptoChanged();
                          _onMoneyChanged();
                        });
                      }
                    },
                    items: currencyRates.keys
                        .map((cur) => DropdownMenuItem(
                            value: cur,
                            child: Text(cur,
                                style: const TextStyle(fontSize: 16))))
                        .toList(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: TextField(
                    controller: _cryptoAmountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah Kripto',
                      border: OutlineInputBorder(),
                      suffixText: 'Coin',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: TextField(
                    controller: _moneyAmountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Jumlah $_selectedCurrency',
                      border: const OutlineInputBorder(),
                      suffixText: _selectedCurrency,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: _selectedCurrency,
                    decoration: const InputDecoration(
                      labelText: 'Mata Uang',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCurrency = value;
                          _onCryptoChanged();
                          _onMoneyChanged();
                        });
                      }
                    },
                    items: currencyRates.keys
                        .map((cur) => DropdownMenuItem(
                            value: cur,
                            child: Text(cur,
                                style: const TextStyle(fontSize: 16))))
                        .toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Waktu Update Harga Koin',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButton<String>(
              value: _selectedTimezone,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedTimezone = value;
                    _convertTime();
                  });
                }
              },
              items: timezoneOffsets.keys
                  .map((zone) =>
                      DropdownMenuItem(value: zone, child: Text(zone)))
                  .toList(),
            ),
            if (_convertedTime != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Waktu Update: $_convertedTime'),
              ),
          ],
        ),
      ),
    );
  }
}
