import 'package:flutter/services.dart';

/// Kumpulan validator `TextFormField` yang dipakai bersama di seluruh aplikasi.
/// Setiap fungsi mengembalikan pesan error (String) atau null bila input valid.
class Validators {
  Validators._();

  /// Formatter: hanya izinkan angka 0-9.
  static final List<TextInputFormatter> digitsOnly = [
    FilteringTextInputFormatter.digitsOnly,
  ];

  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    return null;
  }

  static String? name(String? value, {String fieldName = 'Nama'}) {
    final error = required(value, fieldName);
    if (error != null) return error;

    final v = value!.trim();
    if (v.length < 3) return '$fieldName minimal 3 karakter';
    if (v.length > 50) return '$fieldName maksimal 50 karakter';
    if (!RegExp(r"^[A-Za-z\s.'\-]+$").hasMatch(v)) {
      return '$fieldName hanya boleh berisi huruf';
    }
    return null;
  }

  /// Nomor telepon/WhatsApp: wajib, hanya angka, 9-15 digit.
  static String? phone(String? value, {String fieldName = 'Nomor WhatsApp'}) {
    final error = required(value, fieldName);
    if (error != null) return error;

    final v = value!.trim();
    if (!RegExp(r'^\d+$').hasMatch(v)) {
      return '$fieldName hanya boleh berisi angka';
    }
    if (v.length < 9) return '$fieldName minimal 9 digit';
    if (v.length > 15) return '$fieldName maksimal 15 digit';
    return null;
  }

  /// Password: wajib; [minLength] > 0 untuk memberlakukan panjang minimum.
  static String? password(String? value,
      {String fieldName = 'Password', int minLength = 0}) {
    final error = required(value, fieldName);
    if (error != null) return error;

    if (minLength > 0 && value!.trim().length < minLength) {
      return '$fieldName minimal $minLength karakter';
    }
    return null;
  }

  /// OTP: wajib, tepat [length] digit angka.
  static String? otp(String? value, {int length = 4}) {
    final error = required(value, 'Kode OTP');
    if (error != null) return error;

    final v = value!.trim();
    if (!RegExp(r'^\d+$').hasMatch(v) || v.length != length) {
      return 'Kode OTP harus $length digit angka';
    }
    return null;
  }

  /// Teks opsional dengan batas panjang maksimum.
  static String? optionalText(String? value,
      {required int maxLength, String fieldName = 'Catatan'}) {
    if (value != null && value.trim().length > maxLength) {
      return '$fieldName maksimal $maxLength karakter';
    }
    return null;
  }
}
