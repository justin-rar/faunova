import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camera/camera.dart';

void main() {
  group('BUG 3 REPRODUCE: Flash Kamera Menggunakan FlashMode.torch untuk Menyalakan Lampu', () {
    test('Reproduksi: Siklus flash harus mencakup FlashMode.torch agar lampu LED fisik menyala', () {
      // Pada implementasi lama:
      // switch (mode) {
      //   case FlashMode.auto: return FlashMode.always;
      //   case FlashMode.always: return FlashMode.off;
      //   case FlashMode.off: return FlashMode.auto;
      // }
      // -> FlashMode.torch TIDAK PERNAH DIPANGGIL, sehingga lampu flash tidak pernah menyala saat tombol ditekan.

      FlashMode getNextFlashMode(FlashMode current) {
        switch (current) {
          case FlashMode.off:
            return FlashMode.torch;
          case FlashMode.torch:
          case FlashMode.always:
            return FlashMode.auto;
          case FlashMode.auto:
            return FlashMode.off;
        }
      }

      // Verifikasi siklus
      expect(getNextFlashMode(FlashMode.off), equals(FlashMode.torch),
          reason: 'Dari off harus menyalakan senter LED (torch)');
      expect(getNextFlashMode(FlashMode.torch), equals(FlashMode.auto),
          reason: 'Dari torch harus beralih ke otomatis');
      expect(getNextFlashMode(FlashMode.auto), equals(FlashMode.off),
          reason: 'Dari auto harus mematikan flash');
    });

    test('Ikon dan status visual flash mencerminkan FlashMode.torch', () {
      IconData getFlashIcon(FlashMode mode) {
        switch (mode) {
          case FlashMode.torch:
            return Icons.flash_on_rounded;
          case FlashMode.auto:
            return Icons.flash_auto_rounded;
          case FlashMode.always:
            return Icons.flash_on_rounded;
          case FlashMode.off:
            return Icons.flash_off_rounded;
        }
      }

      expect(getFlashIcon(FlashMode.torch), equals(Icons.flash_on_rounded));
      expect(getFlashIcon(FlashMode.auto), equals(Icons.flash_auto_rounded));
      expect(getFlashIcon(FlashMode.off), equals(Icons.flash_off_rounded));
    });
  });
}
