import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_state_view.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.teksPutih),
            onSelected: (value) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Menu dipilih: $value'),
                  backgroundColor: AppColors.sageTua,
                ),
              );
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'saran_kesan',
                child: Row(
                  children: [
                    Icon(Icons.feedback_outlined, size: 20, color: AppColors.teksGelap),
                    SizedBox(width: 10),
                    Text('Saran & Kesan Kuliah PAM', style: TextStyle(color: AppColors.teksGelap)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'setting',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 20, color: AppColors.teksGelap),
                    SizedBox(width: 10),
                    Text('Pengaturan & Biometrik', style: TextStyle(color: AppColors.teksGelap)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 20, color: AppColors.merahStatus),
                    SizedBox(width: 10),
                    Text('Keluar Akun', style: TextStyle(color: AppColors.merahStatus)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: AppStateView(
        status: _currentStatus,
        loadingMessage: 'Memuat profil pengguna...',
        emptyTitle: 'Profil Belum Lengkap',
        emptyMessage: 'Silakan lengkapi data profil Anda untuk memulai.',
        errorMessage: 'Gagal memuat informasi profil pengguna.',
        offlineMessage: 'Mode luring. Menampilkan profil tersimpan dari memori lokal.',
        onRetry: () {
          setState(() {
            _currentStatus = AppViewStatus.content;
          });
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStateSwitcherCard(),
              const SizedBox(height: 16),
              _buildProfileHeaderCard(),
              const SizedBox(height: 14),
              _buildVerifiedBadgeSubscriptionCard(),
              const SizedBox(height: 14),
              _buildSubTabs(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStateSwitcherCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.sageMuda,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, size: 18, color: AppColors.teksGelap),
              SizedBox(width: 8),
              Text(
                'Simulasi State (AGENTS.md)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.teksGelap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
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
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppColors.teksPutih : AppColors.teksGelap,
      ),
    );
  }

  Widget _buildProfileHeaderCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sageMuda,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.sageTua,
                child: Icon(Icons.person, color: AppColors.teksPutih, size: 36),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text(
                          'Kolektor Satwa',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.teksGelap,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.verified_rounded,
                          color: Colors.blueAccent,
                          size: 18,
                        ),
                      ],
                    ),
                    const Text(
                      '@satwa_nusantara',
                      style: TextStyle(fontSize: 13, color: AppColors.teksGelap),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pecinta satwa endemik Indonesia & pelestari alam.',
                      style: TextStyle(fontSize: 12, color: AppColors.teksGelap),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.sage),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(label: 'Postingan', value: '12'),
              _StatItem(label: 'Pengikut', value: '148'),
              _StatItem(label: 'Mengikuti', value: '62'),
              _StatItem(label: 'Badge', value: '4/8'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedBadgeSubscriptionCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sageMuda,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: Colors.blueAccent, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Langganan Centang Biru',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.teksGelap,
                  ),
                ),
                Text(
                  'Rp 15.000 / bulan via Midtrans Sandbox',
                  style: TextStyle(fontSize: 12, color: AppColors.teksGelap),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Perpanjang'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabs() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sageMuda,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.sageTua,
            indicatorWeight: 3,
            labelColor: AppColors.teksGelap,
            unselectedLabelColor: AppColors.sage,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'Postingan Publik'),
              Tab(text: 'Koleksi Privat & Rantai'),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.gading,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: AppColors.sageTua, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Integritas Rantai Hash (Simple Blockchain)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.teksGelap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Rantai SHA-256 tersambung antar tangkapan dan divalidasi oleh database server.',
                  style: TextStyle(fontSize: 12, color: AppColors.teksGelap),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Verifikasi Rantai: Seluruh blok valid (seq 1..12)'),
                        backgroundColor: AppColors.sageTua,
                      ),
                    );
                  },
                  icon: const Icon(Icons.verified_user_rounded, size: 18),
                  label: const Text('Verifikasi Rantai'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.teksGelap,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.teksGelap,
          ),
        ),
      ],
    );
  }
}
