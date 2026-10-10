# Puthu Lanang Flutter Native

Versi native Flutter dari mobile UI Puthu Lanang. Desain mengacu pada frontend Next.js di project asli.

## 1. Buat project Flutter shell

Jika folder ini dibuat sebagai source manual, jalankan `flutter create .` di folder ini untuk menghasilkan folder platform/default Flutter. Jangan menimpa `lib/`, `assets/`, dan `pubspec.yaml` setelah itu.

## 2. Jalankan backend

Masuk ke `PuthuLanang_Backend` dari project asli:

```bash
npm install
npm run dev
```

## 3. API Android

Emulator Android memakai `http://10.0.2.2:5000/api`.
Untuk HP fisik, ubah `baseUrl` di `lib/services/api_service.dart` menjadi IP LAN PC, misalnya `http://192.168.1.10:5000/api`.

## 4. Flutter

```bash
flutter pub get
flutter run
flutter build apk --release
```

Fitur yang sudah disiapkan: login/register, home, menu, cart, smart takeaway, order ticket + QR, story heritage, profile, local session, dan koneksi ke backend Express yang sudah ada.
