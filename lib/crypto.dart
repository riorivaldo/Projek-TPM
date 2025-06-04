class CryptoTicker {
  final String pairId;
  final String name;
  final String urlLogoPng;
  final String last;
  final String high;
  final String low;
  final String buy;
  final String sell;
  final int serverTime;

  CryptoTicker({
    required this.pairId,
    required this.name,
    required this.urlLogoPng,
    required this.last,
    required this.high,
    required this.low,
    required this.buy,
    required this.sell,
    required this.serverTime,
  });

  factory CryptoTicker.fromJson(String pairId, Map<String, dynamic> json) {
    return CryptoTicker(
      pairId: pairId,
      name: json['name'] ?? '',
      urlLogoPng:
          'https://indodax.com/v2/logo/png/color/${pairId.split('_')[0]}.png',
      last: json['last'] ?? '0',
      high: json['high'] ?? '0',
      low: json['low'] ?? '0',
      buy: json['buy'] ?? '0',
      sell: json['sell'] ?? '0',
      serverTime: json['server_time'] ?? 0,
    );
  }
}
