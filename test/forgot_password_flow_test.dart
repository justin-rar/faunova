import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:faunova/core/theme/app_theme.dart';
import 'package:faunova/features/auth/presentation/forgot_password_page.dart';
import 'package:faunova/features/auth/presentation/login_page.dart';

void main() {
  group('Pengujian Alur Terpisah Lupa Password (ForgotPasswordPage)', () {
    testWidgets('Langkah 1/2 (Hanya Email) -> Langkah 2/2 (Hanya OTP) -> Verifikasi Berhasil -> Input Sandi Baru -> Sukses', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginPage(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Ketuk "Lupa kata sandi?" di LoginPage
      await tester.ensureVisible(find.text('Lupa kata sandi?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lupa kata sandi?'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordPage), findsOneWidget);
      expect(find.text('Lupa Kata Sandi?'), findsOneWidget);
      expect(find.text('Langkah 1/2'), findsOneWidget);
      expect(find.text('Kirim Tautan Pemulihan'), findsOneWidget);

      // Verifikasi Requirement 1: Bagian "Sudah punya kode OTP" TELAH DIHAPUS
      expect(find.text('Sudah punya kode OTP? Masukkan di sini'), findsNothing);

      // 2. Coba kirim email tanpa isi form (harus muncul validasi)
      await tester.tap(find.text('Kirim Tautan Pemulihan'));
      await tester.pumpAndSettle();
      expect(find.text('Alamat email wajib diisi'), findsOneWidget);

      // 3. Masukkan email valid ke field ForgotPasswordPage
      final emailField = find.descendant(
        of: find.byType(ForgotPasswordPage),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(emailField.first, 'peneliti@faunova.id');
      await tester.pumpAndSettle();

      // Ketuk Kirim Tautan Pemulihan
      await tester.tap(find.text('Kirim Tautan Pemulihan'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // 4. Verifikasi berpindah ke Langkah 2/2 Tahap 1: HANYA VERIFIKASI OTP (Requirement 2)
      expect(find.widgetWithText(ElevatedButton, 'Verifikasi Kode OTP'), findsOneWidget);
      expect(find.text('Langkah 2/2'), findsOneWidget);
      expect(find.text('Kode Verifikasi (OTP)'), findsOneWidget);
      expect(find.text('Ubah Email'), findsOneWidget);
      expect(find.text('Kirim Ulang Kode OTP'), findsNothing); // Masih dalam countdown timer
      expect(find.textContaining('Kirim ulang ('), findsOneWidget);

      // Pastikan field Kata Sandi Baru BELUM MUNCUL sebelum OTP lolos (Requirement 2)
      expect(find.text('Kata Sandi Baru'), findsNothing);
      expect(find.text('Konfirmasi Kata Sandi Baru'), findsNothing);
      expect(find.text('Simpan Kata Sandi Baru'), findsNothing);

      // 5. Coba verifikasi OTP kosong
      await tester.tap(find.widgetWithText(ElevatedButton, 'Verifikasi Kode OTP'));
      await tester.pumpAndSettle();
      expect(find.text('Kode verifikasi wajib diisi'), findsOneWidget);

      // 6. Masukkan OTP kurang dari 6 digit
      final otpField = find.descendant(
        of: find.byType(ForgotPasswordPage),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(otpField.first, '123');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Verifikasi Kode OTP'));
      await tester.pumpAndSettle();
      expect(find.text('Kode OTP minimal 6 digit'), findsOneWidget);

      // 7. Masukkan OTP valid (misal 6 atau 8 digit)
      await tester.enterText(otpField.first, '74161482');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Verifikasi Kode OTP'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // 8. Verifikasi: Sekarang barulah field Kata Sandi Baru MUNCUL! (Requirement 2)
      expect(find.text('Buat Kata Sandi Baru'), findsOneWidget);
      expect(find.text('Kode OTP terverifikasi. Masukkan kata sandi baru akun Anda di bawah ini.'), findsOneWidget);
      expect(find.text('Kata Sandi Baru'), findsOneWidget);
      expect(find.text('Konfirmasi Kata Sandi Baru'), findsOneWidget);
      expect(find.text('Simpan Kata Sandi Baru'), findsOneWidget);

      // 9. Coba submit password kosong
      await tester.tap(find.text('Simpan Kata Sandi Baru'));
      await tester.pumpAndSettle();
      expect(find.text('Kata sandi baru wajib diisi'), findsOneWidget);

      // 10. Masukkan password tidak cocok
      final passwordFields = find.descendant(
        of: find.byType(ForgotPasswordPage),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(passwordFields.at(0), 'passwordAman123');
      await tester.enterText(passwordFields.at(1), 'passwordBeda123');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Simpan Kata Sandi Baru'));
      await tester.pumpAndSettle();
      expect(find.text('Konfirmasi kata sandi tidak cocok'), findsOneWidget);

      // 11. Masukkan password yang cocok dan simpan
      await tester.enterText(passwordFields.at(0), 'passwordAman123');
      await tester.enterText(passwordFields.at(1), 'passwordAman123');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Simpan Kata Sandi Baru'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // 12. Layar Sukses
      expect(find.text('Kata Sandi Berhasil Diperbarui!'), findsOneWidget);
      expect(find.text('Kembali ke Halaman Masuk'), findsOneWidget);

      // 13. Kembali ke LoginPage
      await tester.tap(find.text('Kembali ke Halaman Masuk'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('peneliti@faunova.id'), findsOneWidget);
      expect(find.text('Kata sandi berhasil diperbarui! Silakan masuk dengan kata sandi baru Anda.'), findsOneWidget);
    });

    testWidgets('Direct Recovery Mode (dari deep link email) langsung membuka form kata sandi baru tanpa OTP', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ForgotPasswordPage(
            initialEmail: 'kolektor@faunova.id',
            isDirectRecovery: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Buat Kata Sandi Baru'), findsOneWidget);
      expect(find.text('Kode Verifikasi (OTP)'), findsNothing);
      expect(find.text('Kata Sandi Baru'), findsOneWidget);
      expect(find.text('Konfirmasi Kata Sandi Baru'), findsOneWidget);
      expect(find.text('Simpan Kata Sandi Baru'), findsOneWidget);

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'faunova2026!');
      await tester.enterText(textFields.at(1), 'faunova2026!');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Simpan Kata Sandi Baru'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('Kata Sandi Berhasil Diperbarui!'), findsOneWidget);
      expect(find.text('Kembali ke Halaman Masuk'), findsOneWidget);

      await tester.tap(find.text('Kembali ke Halaman Masuk'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('kolektor@faunova.id'), findsOneWidget);
      expect(find.text('Kata sandi berhasil diperbarui! Silakan masuk dengan kata sandi baru Anda.'), findsOneWidget);
    });

    testWidgets('Ubah Email di Langkah 2/2 mengembalikan alur ke Langkah 1/2 dengan state bersih', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ForgotPasswordPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Masukkan email dan kirim
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'lama@faunova.id');
      await tester.tap(find.text('Kirim Tautan Pemulihan'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ElevatedButton, 'Verifikasi Kode OTP'), findsOneWidget);

      // Ketuk Ubah Email
      await tester.tap(find.text('Ubah Email'));
      await tester.pumpAndSettle();

      // Kembali ke Langkah 1/2 dengan form bersih
      expect(find.text('Lupa Kata Sandi?'), findsOneWidget);
      expect(find.text('Langkah 1/2'), findsOneWidget);
      expect(find.text('Kirim Tautan Pemulihan'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Verifikasi Kode OTP'), findsNothing);
    });
  });
}
