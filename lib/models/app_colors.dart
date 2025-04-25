import 'package:flutter/material.dart';

class AppColors {
  // Ana Renkler
  static const Color primary = Color(0xFF4B9EF4); // Canlı Bebek Mavisi
  static const Color secondary = Color(0xFFFF8FAB); // Canlı Pembe
  static const Color accent = Color(0xFF5BD6B8); // Canlı Nane Yeşili

  // Nötr Renkler
  static const Color background = Color(0xFFF5F6F8); // Açık Gri Arka Plan
  static const Color surface = Color(0xFFFFFFFF); // Beyaz Yüzey
  static const Color textPrimary = Color(0xFF2D3142); // Koyu Metin
  static const Color textSecondary = Color(0xFF6B7280); // İkincil Metin

  // Durum Renkleri
  static const Color success = Color(0xFF4CD964); // Canlı Yeşil
  static const Color error = Color(0xFFFF5A5A); // Canlı Kırmızı
  static const Color warning = Color(0xFFFFB340); // Canlı Turuncu

  // Gradient Renkler
  static const List<Color> primaryGradient = [
    Color(0xFF4B9EF4), // Canlı Bebek Mavisi
    Color(0xFF5BD6B8), // Canlı Nane Yeşili
  ];

  // Alternatif Gradient
  static const List<Color> secondaryGradient = [
    Color(0xFFFF8FAB), // Canlı Pembe
    Color(0xFFFFB340), // Canlı Turuncu
  ];
}
