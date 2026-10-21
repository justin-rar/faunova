import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/glass_app_bar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AppViewStatus _currentStatus = AppViewStatus.content;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.gading,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Keluar dari Akun?',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.teksGelap, fontSize: 17),
        ),
        content: const Text(
          'Sesi Anda akan dihapus dari perangkat ini. Anda perlu memasukkan email dan kata sandi kembali untuk masuk.',
          style: TextStyle(color: AppColors.teksGelap, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal', style: TextStyle(color: AppColors.teksGelap, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await AuthService.instance.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.merahStatus,
              foregroundColor: AppColors.teksPutih,
            ),
            child: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 14;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        centerTitle: true,
        title: const Text(
          'Profil Kolektor',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16.5,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                    width: 0.8,
                  ),
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
                  padding: EdgeInsets.zero,
                  color: AppColors.gading,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  onSelected: (value) {
                    if (value == 'logout') {
                      _showLogoutDialog(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Menu dipilih: $value'),
                          backgroundColor: AppColors.sageTua,
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'saran_kesan',
                      child: Row(
                        children: [
                          Icon(Icons.rate_review_outlined, size: 18, color: AppColors.teksGelap),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Saran & Kesan Kuliah PAM',
                              style: TextStyle(color: AppColors.teksGelap, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'setting_biometrik',
                      child: Row(
                        children: [
                          Icon(Icons.fingerprint_rounded, size: 18, color: AppColors.teksGelap),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Pengaturan & Sidik Jari',
                              style: TextStyle(color: AppColors.teksGelap, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout_rounded, size: 18, color: AppColors.merahStatus),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Keluar Akun',
                              style: TextStyle(color: AppColors.merahStatus, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: AppStateView(
        status: _currentStatus,
        loadingMessage: 'Memuat data portofolio koleksi...',
        emptyTitle: 'Profil Belum Terdaftar',
        emptyMessage: 'Silakan masuk atau buat akun baru untuk melihat portofolio Anda.',
        errorMessage: 'Gagal memuat profil pengguna dari server.',
        offlineMessage: 'Mode luring. Memuat data profil dari cache lokal terenkripsi.',
        onRetry: () {
          setState(() {
            _currentStatus = AppViewStatus.content;
          });
        },
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, topPadding, 16, 110),
          children: [
            _buildStateSwitcherCard(),
            const SizedBox(height: 14),

            // 1. Profile Header Card
            _buildProfileHeroCard(),
            const SizedBox(height: 14),

            // 2. Centang Biru Subscription Card (Plan 5.4)
            _buildVerifiedSubscriptionCard(),
            const SizedBox(height: 14),

            // 3. Badge Shelf (Grid Pencapaian)
            _buildBadgeShelfCard(),
            const SizedBox(height: 14),

            // 4. Sub-tab: Postingan Publik vs Koleksi Privat + Verifikasi Rantai
            _buildSubTabsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStateSwitcherCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.sageMuda,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.sage.withValues(alpha: 0.35), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, size: 16, color: AppColors.teksGelap),
              SizedBox(width: 8),
              Text(
                'Simulasi State (AGENTS.md)',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppColors.teksGelap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildStateChip('Normal', AppViewStatus.content),
              _buildStateChip('Memuat', AppViewStatus.loading),
              _buildStateChip('Kosong', AppViewStatus.empty),
              _buildStateChip('Galat', AppViewStatus.error),
              _buildStateChip('Luring', AppViewStatus.offline),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStateChip(String label, AppViewStatus status) {
    final isSelected = _currentStatus == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _currentStatus = status;
        });
      },
      selectedColor: AppColors.sageTua,
      backgroundColor: AppColors.gading,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppColors.teksPutih : AppColors.teksGelap,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildProfileHeroCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sageMuda,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sage.withValues(alpha: 0.35), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.sageTua,
                child: Text(
                  'A',
                  style: TextStyle(
                    color: AppColors.teksPutih,
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Arya Wicaksana',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.teksGelap,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 5),
                        Icon(Icons.verified_rounded, color: Color(0xFF1E88E5), size: 18),
                      ],
                    ),
                    Text(
                      '@arya_wallacea',
                      style: TextStyle(fontSize: 12.5, color: AppColors.teksGelap, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Kolektor Satwa Wallacea',
                      style: TextStyle(fontSize: 11.5, color: AppColors.emasTua, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Penjelajah biodiversitas Indonesia Timur. Mengarsipkan reptilia dan aves endemik ke dalam buku besar terenkripsi.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: AppColors.teksGelap.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.sage),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MetricItem(label: 'Postingan', value: '14'),
              _MetricItem(label: 'Pengikut', value: '218'),
              _MetricItem(label: 'Mengikuti', value: '64'),
              _MetricItem(label: 'Badge Sah', value: '4/8'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedSubscriptionCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sageMuda,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sage.withValues(alpha: 0.35), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E88E5).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_rounded, color: Color(0xFF1E88E5), size: 26),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Centang Biru Aktif',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: AppColors.teksGelap,
                  ),
                ),
                Text(
                  'Aktif s/d 30 Nov 2026 • Midtrans Sandbox',
                  style: TextStyle(fontSize: 11.5, color: AppColors.teksGelap),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: const Size(80, 36),
            ),
            child: const Text('Perpanjang', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeShelfCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sageMuda,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sage.withValues(alpha: 0.35), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lencana Gelar Pencapaian (MVP)',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: AppColors.teksGelap,
                ),
              ),
              Text(
                '4 Terbuka',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.emasTua,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBadgeItem(Icons.forest_rounded, 'Penjelajah', true),
              _buildBadgeItem(Icons.visibility_rounded, 'Mata Elang', true),
              _buildBadgeItem(Icons.auto_stories_rounded, 'Taksonomis', true),
              _buildBadgeItem(Icons.link_rounded, 'Penjaga Rantai', true),
              _buildBadgeItem(Icons.lock_outline_rounded, 'Terkunci', false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeItem(IconData icon, String label, bool isUnlocked) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isUnlocked ? AppColors.sageTua : AppColors.gading,
            shape: BoxShape.circle,
            border: Border.all(
              color: isUnlocked ? AppColors.emas : AppColors.sage.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            size: 22,
            color: isUnlocked ? AppColors.teksPutih : AppColors.sage,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isUnlocked ? FontWeight.w700 : FontWeight.w500,
            color: isUnlocked ? AppColors.teksGelap : AppColors.sage,
          ),
        ),
      ],
    );
  }

  Widget _buildSubTabsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sageMuda,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sage.withValues(alpha: 0.35), width: 1),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.sageTua,
            indicatorWeight: 3,
            labelColor: AppColors.teksGelap,
            unselectedLabelColor: AppColors.sage,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: const [
              Tab(text: 'Postingan Publik'),
              Tab(text: 'Koleksi & Peta'),
            ],
          ),
          const SizedBox(height: 14),

          // Blockchain Hash-Chain Verifier Banner (Plan 5.2)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.gading,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.sage.withValues(alpha: 0.4), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: AppColors.sageTua, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Integritas Buku Besar (Simple Blockchain)',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        color: AppColors.teksGelap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Setiap tangkapan dienkripsi dengan SHA-256 kanonis menyambung ke tangkapan sebelumnya.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.teksGelap, height: 1.35),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Verifikasi Rantai: Seluruh blok valid (seq 1..14). Tidak ada manipulasi data.'),
                        backgroundColor: AppColors.sageTua,
                      ),
                    );
                  },
                  icon: const Icon(Icons.verified_user_rounded, size: 18),
                  label: const Text('Verifikasi Rantai (verify_chain)'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;

  const _MetricItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.teksGelap,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.teksGelap.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}
