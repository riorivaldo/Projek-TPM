class SecurityTipsService {
  /// Simulasi pengambilan tips keamanan dari sumber data (bisa diubah ke API atau lokal file)
  static Future<List<String>> getSecurityTips() async {
    // Bisa ditambahkan delay untuk simulasi request async
    await Future.delayed(const Duration(milliseconds: 300));

    return [
      'Gunakan autentikasi dua faktor untuk keamanan tambahan.',
      'Jangan pernah berbagi password dengan orang lain.',
      'Selalu perbarui aplikasi untuk mendapatkan fitur keamanan terbaru.',
      'Waspadai email phishing dan link mencurigakan.',
      'Gunakan password yang kuat dan unik untuk setiap akun.',
    ];
  }
}
