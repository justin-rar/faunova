// ==============================================================================
// FAUNOVA PRESENTATION: SaranKesanPage
// Halaman Saran & Kesan Kuliah Teori Pemrograman Aplikasi Mobile (PAM)
// Memuat profil 3 anggota pengembang, refleksi materi, dan pesan/saran statis
// Sesuai Plan baris 63, 316, Scope.md S21 & AGENTS.md
// ==============================================================================

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_app_bar.dart';

class TeamMemberInfo {
  final String name;
  final String nim;
  final String iconBadge;
  final List<String> responsibilities;
  final String quote;

  const TeamMemberInfo({
    required this.name,
    required this.nim,
    required this.iconBadge,
    required this.responsibilities,
    required this.quote,
  });
}

class SaranKesanPage extends StatelessWidget {
  const SaranKesanPage({super.key});

  static const List<TeamMemberInfo> _teamMembers = [
    TeamMemberInfo(
      name: 'Daniel Roby Maldini',
      nim: 'NIM: 124240044',
      iconBadge: '🛡️',
      responsibilities: [
        'Perancangan Skema Inti PostgreSQL Supabase (Migrations 001 - 031)',
        'Implementasi Row Level Security (RLS) Tanpa Kebocoran Data',
        'RPC Atomik Hash-Chain SHA-256 (faunova_canonical_encode)',
        'Fungsi Grid Snapping 0.01° Server untuk Perlindungan Privasi Satwa',
        'RPC Idempoten Midtrans Settlement & Prioritas Pencarian Centang Biru',
      ],
      quote:
          '"Akhirnya bisa tidur normal 8 jam sehari lagi"',
    ),
    TeamMemberInfo(
      name: 'Kanza Widi Bagaskara',
      nim: 'NIM: 124240059',
      iconBadge: '⚡',
      responsibilities: [
        'Integrasi Gemini AI Vision & Chat Gateway (Scan & Multi-Turn Chat)',
        'Gerbang Pembayaran Midtrans Sandbox Snap & Verifikasi Signature SHA-512',
        'Sensor Fisik: Kompas Magnetometer, Mock GPS, dan Shake-to-Quiz Accelerometer',
        'Notifikasi Lokal Mandiri (Pengingat Streak 19:00 WIB & Tantangan 08:00 WIB)',
        'Penyimpanan Enkripsi Hive Lokal (HiveAesCipher) & Konversi 4 Zona Waktu',
      ],
      quote:
          '"Sudah habis 10 cangkir kopi dan 34 gorengan serta 7 indomie"',
    ),
    TeamMemberInfo(
      name: 'Justin',
      nim: 'NIM: 124240074',
      iconBadge: '📱',
      responsibilities: [
        'Arsitektur Fondasi Flutter & Palet Warna Sage-Gading-Emas (AGENTS.md)',
        'Efek Glassmorphism Frosted Glass & Sliding Pill Bottom Bar',
        'Alur Autentikasi Supabase & Validasi Masuk/Daftar/Brevo SMTP',
        'Kamera Layar Penuh Optik, Kompresi Isolate & EXIF Stripping',
        'Audit Integritas Rantai SHA-256 Klien & Peta Persebaran OSM',
      ],
      quote:
          '"Yang penting selesai dah programnya pak, udah abis 6 akun buat membantu mengerjakan aplikasi ini"',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gading,
      appBar: GlassAppBar(
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Saran & Kesan Kuliah PAM',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16.5,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        physics: const ClampingScrollPhysics(),
        children: [
          // Banner Informasi Mata Kuliah
          _buildCourseHeaderBanner(),
          const SizedBox(height: 18),

          // Profil 3 Anggota Kelompok beserta Saran & Kesan
          _buildSectionTitle('Profil Tim Pengembang Faunova', Icons.groups_rounded),
          const SizedBox(height: 10),
          ..._teamMembers.map((member) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildTeamMemberCard(member),
              )),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.sageTua,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.teksGelap,
          ),
        ),
      ],
    );
  }

  Widget _buildCourseHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.sageTua,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emas,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'SEMESTER 5',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.teksGelap,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.school_rounded, color: Colors.white, size: 22),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Teori Pemrograman Aplikasi Mobile (PAM)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Proyek Akhir Aplikasi: Faunova — Jurnal Sosial Satwa & Buku Besar Kriptografis',
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_outlined, size: 16, color: AppColors.emas),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Memenuhi seluruh kriteria kompetensi dosen pengampu & arsitektur standar industri.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMemberCard(TeamMemberInfo m) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sageMuda, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.sageMuda,
                child: Text(
                  m.iconBadge,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.teksGelap,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      m.nim,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.emasTua,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.sageMuda),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.sageMuda.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.sage.withValues(alpha: 0.2)),
            ),
            child: Text(
              m.quote,
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.teksGelap,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
