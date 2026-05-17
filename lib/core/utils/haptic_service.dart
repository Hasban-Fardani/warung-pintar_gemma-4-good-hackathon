import 'package:vibration/vibration.dart';

/// Haptic feedback matrix per PRD §12.6 (ACT-72).
///
/// 6 pola haptic via `vibration` package:
/// - Parse sukses: 1×50ms
/// - Masuk pending: 2×30-50ms
/// - Ambigu: 3× ringan cepat
/// - Bulk confirm: 1×120ms
/// - Error: 3× berat
/// - Delete: 1×100ms
class HapticService {
  HapticService._();

  static Future<bool> _canVibrate() async {
    return Vibration.hasVibrator();
  }

  /// AI parse sukses, langsung confirmed — 1 vibrasi pendek (50ms).
  static Future<void> parseSukses() async {
    if (!await _canVibrate()) return;
    await Vibration.vibrate(duration: 50);
  }

  /// AI parse sukses, masuk pending — 2 vibrasi ringan (30ms–50ms).
  static Future<void> masukPending() async {
    if (!await _canVibrate()) return;
    await Vibration.vibrate(pattern: [0, 30, 80, 50]);
  }

  /// Item ambigu, perlu klarifikasi — 3 vibrasi ringan cepat.
  static Future<void> ambigu() async {
    if (!await _canVibrate()) return;
    await Vibration.vibrate(pattern: [0, 20, 40, 20, 40, 20]);
  }

  /// Konfirmasi bulk selesai — 1 vibrasi panjang (120ms).
  static Future<void> bulkConfirm() async {
    if (!await _canVibrate()) return;
    await Vibration.vibrate(duration: 120);
  }

  /// Error / validasi gagal — 3 vibrasi berat.
  static Future<void> error() async {
    if (!await _canVibrate()) return;
    await Vibration.vibrate(
      pattern: [0, 80, 60, 80, 60, 80],
      intensities: [0, 255, 0, 255, 0, 255],
    );
  }

  /// Aksi destruktif (delete) — 1 vibrasi berat (100ms).
  static Future<void> delete() async {
    if (!await _canVibrate()) return;
    await Vibration.vibrate(duration: 100, intensities: [255]);
  }
}
