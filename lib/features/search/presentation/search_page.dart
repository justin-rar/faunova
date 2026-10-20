import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_state_view.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
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
        title: const Text('Eksplorasi & Pencarian'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppColors.sageTua,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.emas,
              indicatorWeight: 3,
              labelColor: AppColors.teksPutih,
              unselectedLabelColor: AppColors.sageMuda,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: const [
                Tab(text: 'Akun Pengguna'),
                Tab(text: 'Spesies Hewan'),
              ],
            ),
          ),
        ),
      ),
      body: AppStateView(
        status: _currentStatus,
        loadingMessage: 'Mencari entri...',
        emptyTitle: 'Hasil Tidak Ditemukan',
        emptyMessage: 'Coba gunakan kata kunci pencarian yang berbeda.',
        errorMessage: 'Gagal melakukan pencarian. Silakan coba kembali.',
        offlineMessage: 'Pencarian daring tidak tersedia dalam mode luring.',
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
              _buildSearchBar(),
              const SizedBox(height: 14),
              _buildStateSwitcherCard(),
              const SizedBox(height: 18),
              const Text(
                'Akun Rekomendasi (Prioritas Centang Biru)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.teksGelap,
                ),
              ),
              const SizedBox(height: 10),
              _buildAccountTile(
                name: 'Fauna Watch Indonesia',
                username: 'faunawatch_id',
                isVerified: true,
                badgeCount: 7,
              ),
              const SizedBox(height: 8),
              _buildAccountTile(
                name: 'drh. Anindya Putri',
                username: 'anindya_vet',
                isVerified: true,
                badgeCount: 5,
              ),
              const SizedBox(height: 8),
              _buildAccountTile(
                name: 'Riko Penjelajah',
                username: 'riko_explorer',
                isVerified: false,
                badgeCount: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sageMuda,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: const Row(
        children: [
          Icon(Icons.search, color: AppColors.teksGelap),
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari akun atau spesies hewan...',
                hintStyle: TextStyle(color: AppColors.teksGelap, fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
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

  Widget _buildAccountTile({
    required String name,
    required String username,
    required bool isVerified,
    required int badgeCount,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sageMuda,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.sageTua,
            child: Icon(Icons.person, color: AppColors.teksPutih, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.teksGelap,
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified_rounded,
                        color: Colors.blueAccent,
                        size: 16,
                      ),
                    ],
                  ],
                ),
                Text(
                  '@$username • $badgeCount Badge',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.teksGelap,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text('Ikuti', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
