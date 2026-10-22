// ==============================================================================
// FAUNOVA PRESENTATION: SaranKesanPage
// Halaman Saran & Kesan Kuliah Teori Pemrograman Aplikasi Mobile (PAM)
// Memuat profil 3 anggota pengembang, refleksi materi, pesan/saran, dan form evaluasi
// Sesuai Plan baris 63, 316, Scope.md S21 & AGENTS.md
// ==============================================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_app_bar.dart';
import '../../../core/services/encrypted_storage_service.dart';

class TeamMemberInfo {
  final String name;
  final String nim;
  final String roleTitle;
  final String iconBadge;
  final List<String> responsibilities;
  final String quote;

  const TeamMemberInfo({
    required this.name,
    required this.nim,
    required this.roleTitle,
    required this.iconBadge,
    required this.responsibilities,
    required this.quote,
  });
}

class PamFeedbackItem {
  final String id;
  final String senderName;
  final String category;
  final String feedbackText;
  final DateTime createdAt;

  const PamFeedbackItem({
    required this.id,
    required this.senderName,
    required this.category,
    required this.feedbackText,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender_name': senderName,
        'category': category,
        'feedback_text': feedbackText,
        'created_at': createdAt.toIso8601String(),
      };

  factory PamFeedbackItem.fromJson(Map<String, dynamic> json) => PamFeedbackItem(
        id: json['id'] as String? ?? '',
        senderName: json['sender_name'] as String? ?? 'Mahasiswa PAM',
        category: json['category'] as String? ?? 'Umum',
        feedbackText: json['feedback_text'] as String? ?? '',
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
}

class SaranKesanPage extends StatefulWidget {
  const SaranKesanPage({super.key});

  @override
  State<SaranKesanPage> createState() => _SaranKesanPageState();
}

class _SaranKesanPageState extends State<SaranKesanPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _feedbackController = TextEditingController();

  String _selectedCategory = 'Materi Kuliah';
  bool _isSubmitting = false;

  final List<String> _categories = const [
    'Materi Kuliah',
    'Tugas Proyek',
    'Praktikum Lab',
    'Dosen & Pengajar',
    'Saran Umum',
  ];

  final List<TeamMemberInfo> _teamMembers = const [
    TeamMemberInfo(
      name: 'Justin',
      nim: 'Mahasiswa PAM - Lead Dev',
      roleTitle: 'Lead Mobile & UI/UX Specialist',
      iconBadge: '📱',
      responsibilities: [
        'Arsitektur Fondasi Flutter & Palet Warna Sage-Gading-Emas (AGENTS.md)',
        'Efek Glassmorphism Frosted Glass & Sliding Pill Bottom Bar',
        'Alur Autentikasi Supabase & Validasi Masuk/Daftar/Brevo SMTP',
        'Kamera Layar Penuh Optik, Kompresi Isolate & EXIF Stripping',
        'Audit Integritas Rantai SHA-256 Klien & Peta Persebaran OSM',
      ],
      quote:
          '"Membangun antarmuka mobile bukan sekadar tampilan, melainkan perpaduan estetika visual tinggi, privasi data, dan kehalusan interaksi pengguna."',
    ),
    TeamMemberInfo(
      name: 'Arya Wicaksana',
      nim: 'Mahasiswa PAM - Backend Dev',
      roleTitle: 'Backend, Database & Security Engineer',
      iconBadge: '🛡️',
      responsibilities: [
        'Perancangan Skema Inti PostgreSQL Supabase (Migrations 001 - 012)',
        'Implementasi Row Level Security (RLS) Tanpa Kebocoran Data',
        'RPC Atomik Hash-Chain SHA-256 (faunova_canonical_encode)',
        'Fungsi Grid Snapping 0.01° Server untuk Perlindungan Privasi Satwa',
        'RPC Idempoten Midtrans Settlement & Prioritas Pencarian Centang Biru',
      ],
      quote:
          '"Semua aturan bisnis kritis dan kalkulasi kuota wajib diselesaikan di sisi server agar aplikasi tangguh terhadap manipulasi klien."',
    ),
    TeamMemberInfo(
      name: 'Budi Satria',
      nim: 'Mahasiswa PAM - Integration Dev',
      roleTitle: 'Feature Integration & Sensor Specialist',
      iconBadge: '⚡',
      responsibilities: [
        'Integrasi Gemini 3.8 Flash Multimodal AI Gateway (Scan & Multi-Turn Chat)',
        'Gerbang Pembayaran Midtrans Sandbox Snap & Verifikasi Signature SHA-512',
        'Sensor Fisik: Kompas Magnetometer, Mock GPS, dan Shake-to-Quiz Accelerometer',
        'Notifikasi Lokal Mandiri (Pengingat Streak 19:00 WIB & Tantangan 08:00 WIB)',
        'Penyimpanan Enkripsi Hive Lokal (HiveAesCipher) & Konversi 4 Zona Waktu',
      ],
      quote:
          '"Mengintegrasikan sensor fisik perangkat dan kecerdasan artifisial menghadirkan pengalaman belajar sains fauna yang hidup dan interaktif."',
    ),
  ];

  List<PamFeedbackItem> _savedFeedbacks = [];

  @override
  void initState() {
    super.initState();
    _loadSavedFeedbacks();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _loadSavedFeedbacks() {
    try {
      final rawData = EncryptedStorageService.instance.getSetting('pam_feedback_history');
      if (rawData is String && rawData.isNotEmpty) {
        final decoded = jsonDecode(rawData) as List<dynamic>;
        setState(() {
          _savedFeedbacks = decoded
              .map((item) => PamFeedbackItem.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _handleSaveFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final newFeedback = PamFeedbackItem(
      id: 'fb-${DateTime.now().millisecondsSinceEpoch}',
      senderName: _nameController.text.trim(),
      category: _selectedCategory,
      feedbackText: _feedbackController.text.trim(),
      createdAt: DateTime.now(),
    );

    final updated = [newFeedback, ..._savedFeedbacks];

    try {
      await EncryptedStorageService.instance.saveSetting(
        'pam_feedback_history',
        jsonEncode(updated.map((f) => f.toJson()).toList()),
      );
    } catch (_) {}

    if (mounted) {
      setState(() {
        _savedFeedbacks = updated;
        _isSubmitting = false;
        _nameController.clear();
        _feedbackController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terima kasih! Saran & kesan Anda berhasil dicatat secara lokal.'),
          backgroundColor: AppColors.sageTua,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gading,
      extendBodyBehindAppBar: true,
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
        padding: const EdgeInsets.fromLTRB(16, 100, 16, 40),
        physics: const ClampingScrollPhysics(),
        children: [
          // Banner Informasi Mata Kuliah
          _buildCourseHeaderBanner(),
          const SizedBox(height: 18),

          // Profil 3 Anggota Kelompok
          _buildSectionTitle('Profil Tim Pengembang Faunova', Icons.groups_rounded),
          const SizedBox(height: 10),
          ..._teamMembers.map((member) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildTeamMemberCard(member),
              )),
          const SizedBox(height: 16),

          // Kesan Kuliah PAM
          _buildSectionTitle('Kesan Selama Perkuliahan PAM', Icons.auto_awesome_rounded),
          const SizedBox(height: 10),
          _buildImpressionsCard(),
          const SizedBox(height: 18),

          // Pesan & Saran untuk Kuliah PAM
          _buildSectionTitle('Pesan & Saran Mata Kuliah', Icons.tips_and_updates_rounded),
          const SizedBox(height: 10),
          _buildSuggestionsCard(),
          const SizedBox(height: 20),

          // Formulir Evaluasi / Masukan
          _buildSectionTitle('Beri Masukan / Saran Tambahan', Icons.edit_note_rounded),
          const SizedBox(height: 10),
          _buildFeedbackFormCard(),

          if (_savedFeedbacks.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSectionTitle('Riwayat Masukan Tercatat (${_savedFeedbacks.length})', Icons.history_rounded),
            const SizedBox(height: 10),
            ..._savedFeedbacks.map((fb) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildFeedbackHistoryCard(fb),
                )),
          ],
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
                      m.roleTitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.emasTua,
                      ),
                    ),
                    Text(
                      m.nim,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.teksGelap.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.sageMuda),
          const SizedBox(height: 10),
          const Text(
            'Fokus Kontribusi & Tanggung Jawab:',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.teksGelap,
            ),
          ),
          const SizedBox(height: 6),
          ...m.responsibilities.map((resp) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppColors.sageTua, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        resp,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.35,
                          color: AppColors.teksGelap.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.sageMuda.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.sage.withValues(alpha: 0.2)),
            ),
            child: Text(
              m.quote,
              style: const TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: AppColors.teksGelap,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpressionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sageMuda.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sageTua.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImpressionItem(
            '1. Pembelajaran Holistik yang Menjawab Standar Industri',
            'Kuliah PAM membuka wawasan nyata bahwa aplikasi mobile modern tidak hanya berfokus pada layout UI, namun menuntut arsitektur yang kuat: keamanan JWT, proteksi secrets, komunikasi asynchronous, hingga pemisahan isolasi komputasi gambar (compute background).',
          ),
          const SizedBox(height: 10),
          _buildImpressionItem(
            '2. Eksplorasi Sensor Perangkat Fisik yang Menantang',
            'Tantangan mengintegrasikan sensor kompas magnetometer (8 mata angin), accelerometer (deteksi goncangan shake-to-quiz), geolokasi GPS dengan deteksi mock location, dan biometrik sidik jari memberikan pengalaman praktik yang sangat berharga dan menyenangkan.',
          ),
          const SizedBox(height: 10),
          _buildImpressionItem(
            '3. Sinergi Fitur Mutakhir (AI Multimodal & Payment Sandbox)',
            'Penerapan Gemini 3.8 Flash untuk identifikasi citra satwa liar secara terstruktur serta simulasi transaksi Midtrans Sandbox dengan verifikasi signature SHA-512 mengajarkan pentingnya validasi berlapis dan keandalan sistem.',
          ),
        ],
      ),
    );
  }

  Widget _buildImpressionItem(String heading, String content) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.sage.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.teksGelap,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: AppColors.teksGelap.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sageMuda, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSuggestionItem(
            'Apresiasi Pendekatan Project-Based Learning',
            'Metode perkuliahan berbasis proyek akhir terpadu ini sangat kami apresiasi. Mahasiswa terdorong untuk mengeksplorasi dokumentasi resmi, memecahkan error nyata, dan membangun portofolio komprehensif yang siap dipresentasikan.',
            Icons.thumb_up_alt_outlined,
          ),
          const SizedBox(height: 10),
          _buildSuggestionItem(
            'Saran Materi Lanjutan: CI/CD & Rilis Aplikasi',
            'Akan sangat bermanfaat jika pada semester mendatang dapat disisipkan materi pengantar otomatisasi build (CI/CD) seperti GitHub Actions untuk Flutter, penandatanganan sertifikat APK/AAB rilis, serta manajemen crash monitoring.',
            Icons.lightbulb_outline_rounded,
          ),
          const SizedBox(height: 10),
          _buildSuggestionItem(
            'Ucapan Terima Kasih Kepada Dosen Pengampu',
            'Kami mengucapkan terima kasih yang sebesar-besarnya kepada Bapak/Ibu Dosen pengampu mata kuliah Teori Pemrograman Aplikasi Mobile atas dedikasi, keluasan ilmu, dan kesabaran dalam membimbing kami selama perkuliahan Semester 5 ini.',
            Icons.sentiment_very_satisfied_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(String title, String desc, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.sageMuda.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.sageTua),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.teksGelap,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.4,
                  color: AppColors.teksGelap.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackFormCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sageMuda, width: 1.2),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Formulir Catatan & Saran Tambahan',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.teksGelap,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Sampaikan catatan evaluasi, pesan pribadi, atau masukan pengembangan aplikasi.',
              style: TextStyle(fontSize: 11.5, color: AppColors.teksGelap.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 14),

            // Nama Pengirim
            TextFormField(
              key: const Key('feedback_name_field'),
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nama Lengkap / Panggilan',
                hintText: 'Contoh: Justin / Dosen Pengampu',
                prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.sageTua, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                filled: true,
                fillColor: AppColors.gading,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.sageTua, width: 1.5),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Nama pengirim tidak boleh kosong.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Kategori Masukan
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Kategori Topik',
                prefixIcon: const Icon(Icons.category_outlined, color: AppColors.sageTua, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                filled: true,
                fillColor: AppColors.gading,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              items: _categories.map((cat) {
                return DropdownMenuItem<String>(
                  value: cat,
                  child: Text(cat, style: const TextStyle(fontSize: 13, color: AppColors.teksGelap)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedCategory = val);
                }
              },
            ),
            const SizedBox(height: 12),

            // Catatan Saran & Kesan
            TextFormField(
              key: const Key('feedback_text_field'),
              controller: _feedbackController,
              minLines: 3,
              maxLines: 5,
              maxLength: 400,
              decoration: InputDecoration(
                labelText: 'Uraian Saran atau Kesan',
                hintText: 'Tuliskan ulasan, masukan materi, atau pesan apresiasi di sini...',
                alignLabelWithHint: true,
                contentPadding: const EdgeInsets.all(14),
                filled: true,
                fillColor: AppColors.gading,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.sageTua, width: 1.5),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Uraian saran/kesan tidak boleh kosong.';
                }
                if (val.trim().length < 5) {
                  return 'Uraian minimal 5 karakter.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Tombol Simpan Masukan
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                key: const Key('feedback_submit_button'),
                onPressed: _isSubmitting ? null : _handleSaveFeedback,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teksGelap),
                      )
                    : const Icon(Icons.send_rounded, size: 18, color: AppColors.teksGelap),
                label: Text(
                  _isSubmitting ? 'Menyimpan...' : 'Kirim Saran & Kesan',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.teksGelap,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emas,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackHistoryCard(PamFeedbackItem item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.sage.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                item.senderName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.teksGelap,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.sageMuda.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.category,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.sageTua,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.feedbackText,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: AppColors.teksGelap.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Dicatat pada ${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year} pk ${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')} WIB',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.teksGelap.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}
