<p align="center">
  <img src="assets/images/logo.png" alt="Logo FloraPulse" width="120">
</p>

<h1 align="center">FloraPulse</h1>

<p align="center"><b>Kebun Pintar, Siram Otomatis</b><br>
Aplikasi Flutter untuk memantau dan mengontrol alat penyiram kebun berbasis ESP32 lewat internet (MQTT).</p>

---

## Fitur

- **Setup 3 langkah**: sambutan dan persiapan alat, hubungkan kotak alat, atur jalur tanaman, lalu uji coba.
- **Pencarian alat sungguhan**: app mengirim ping, dan yang muncul hanya kotak alat yang benar-benar menjawab. Tidak ada data dummy.
- **Beranda Kebun**
  - Siram manual dengan satu tombol power besar (nyala/mati), plus timer mati otomatis 10/30/60 detik.
  - Status alat (online/offline, sinyal WiFi), kartu aki dan tangki, serta daftar jalur kran di Rak 1.
  - Status kran mengikuti laporan alat, bukan tebakan app.
- **Uji coba kran** dengan panel log data mentah yang dikirim dan diterima (MQTT).
- **Notifikasi di dalam app** dari kejadian asli: alat terhubung, offline, online kembali, kran dibuka/ditutup, aki lemah, tangki hampir habis, dan koneksi server.
- Splash/bootup dengan logo, ikon app, dan font yang sudah dibundel sehingga bisa offline.
- Ringan untuk HP kelas bawah karena tanpa efek blur.

## Cara kerja

```
┌──────────────┐        MQTT (internet)        ┌──────────────┐
│  App Flutter │ ◄──────── broker.emqx.io ───► │    ESP32     │
│ (HP Android) │                               │ + relay/pompa│
└──────────────┘                               └──────────────┘
```

HP dan ESP32 **tidak perlu satu WiFi**. Keduanya cukup terhubung ke internet.

### Topik MQTT

| Topik | Arah | Isi |
|---|---|---|
| `florapulse/discover` | App → Alat | Ping. Alat membalas dengan status. |
| `florapulse/pompa/kontrol` | App → Alat | `1` = pompa nyala, `0` = pompa mati |
| `florapulse/device/<ID>/status` | Alat → App | JSON status (lihat di bawah) |

### Format status alat

Dikirim alat tiap 10 detik, saat ada ping, dan saat pompa berubah:

```json
{
  "id": "FP-Desa-01",
  "name": "Kotak Kebun Utama",
  "online": true,
  "valves": 1,
  "battery": null,
  "rssi": -58,
  "pump": false
}
```

Field opsional, kirim kalau sensornya ada: `battery_v` (volt aki), `tank` (isi tangki %), `tank_l` & `tank_cap_l` (liter), `flow` (L/menit). Kalau tidak dikirim, app menampilkan "sensor belum terpasang", bukan angka karangan.

Kalau ESP32 mati mendadak, broker mengirim pesan *Last Will* `{"id":"...","online":false}`, dan app menandai alat offline.

## Menjalankan app

Kebutuhan: [Flutter](https://docs.flutter.dev/get-started/install) (stable), Android SDK + NDK (lewat Android Studio), dan HP Android 7.0+.

```bash
flutter pub get
flutter run --release
```

> Mode debug (tombol ▶ biasa) memang terasa lambat. Untuk menilai performa, pakai `--release`.

### Build APK

```bash
flutter build apk --release
```

Hasilnya ada di `build/app/outputs/flutter-apk/app-release.apk`. Untuk langsung memasang ke HP lewat kabel USB:

```bash
flutter install --release
```

## Menyiapkan ESP32

1. Buka `firmware/florapulse_esp32/florapulse_esp32.ino` di Arduino IDE.
2. Pasang library **PubSubClient** (Nick O'Leary).
3. Ubah bagian atas file:
   ```cpp
   const char* ssid = "NAMA_WIFI";
   const char* password = "PASSWORD_WIFI";
   const char* DEVICE_ID = "FP-Desa-01";
   const int VALVES = 1;        // jumlah jalur kran
   const int RELAY_PIN = -1;    // isi pin relay (mis. 26), -1 = hanya print ke Serial
   ```
4. Upload, lalu buka Serial Monitor (115200). Harus muncul `Terhubung!` dan `Status terkirim: {...}`.

> **Jangan commit password WiFi asli.** Repo ini publik.

## Struktur proyek

```
lib/
├── main.dart                     # Entry point
├── screens/
│   ├── splash_screen.dart        # Loading: font, gambar, koneksi server
│   ├── welcome_screen.dart       # Sambutan & persiapan alat
│   ├── connect_device_screen.dart# Langkah 1: cari & pilih kotak alat
│   ├── plant_zones_screen.dart   # Langkah 2: atur jalur & durasi siram
│   ├── test_finish_screen.dart   # Langkah 3: uji kran + log data
│   ├── home_screen.dart          # Beranda Kebun
│   └── notifications_screen.dart # Daftar notifikasi
├── services/
│   ├── mqtt_service.dart         # Koneksi MQTT, data alat, notifikasi
│   └── mqtt_client_factory*.dart # TCP (HP) / WebSocket (web)
├── theme/app_theme.dart          # Warna & font dari desain Figma
└── widgets/common.dart           # Komponen bersama (logo, tombol, kartu)
firmware/florapulse_esp32/        # Sketch Arduino untuk ESP32
assets/                           # Logo, gambar, ikon, font
```

## Mengganti ikon app

Ganti `assets/icon/app_icon.png` (dan `app_icon_foreground.png` untuk adaptive icon), lalu:

```bash
dart run flutter_launcher_icons
```

## Batasan saat ini

- Broker yang dipakai **publik** (`broker.emqx.io`). Siapa pun yang tahu topiknya bisa mengirim perintah. Untuk pemakaian nyata, gunakan broker sendiri dengan login.
- Notifikasi hanya muncul selama app terbuka. Belum ada push notification.
- Pengaturan jalur belum disimpan, jadi setup diulang saat app dibuka lagi.
- Satu pompa untuk semua jalur. Saklar per baris baru berlaku di app.
- Halaman Jadwal, Rak Kebun, dan Pengaturan belum dibuat.
- WiFi ESP32 masih ditulis langsung di kode. Pindah WiFi berarti upload ulang.

## Desain

Tampilan mengikuti desain Figma **florapulse** (Sambutan, Hubungkan Alat, Atur Jalur, Uji Coba, Beranda Kebun).
