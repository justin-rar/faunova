import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_state_view.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> with SingleTickerProviderStateMixin {
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
        title: const Text('Faunova'),
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
                Tab(text: 'Untuk Kamu'),
                Tab(text: 'Mengikuti'),
              ],
            ),
          ),
        ),
      ),
      body: AppStateView(
        status: _currentStatus,
        loadingMessage: 'Memuat feed postingan...',
        emptyTitle: 'Belum Ada Postingan',
        emptyMessage: 'Ikuti pengguna lain atau bagikan tangkapan hewan pertamamu!',
        errorMessage: 'Gagal memuat feed. Periksa sambungan data Anda.',
        offlineMessage: 'Mode luring. Menampilkan postingan yang tersimpan di cache lokal.',
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
              _buildPlaceholderFeedItem(
                user: 'budi_satria',
                species: 'Burung Jalak Bali (Leucopsar rothschildi)',
                location: 'Denpasar Barat',
                timeAgo: '15 menit lalu',
                likes: 24,
                hasVerifiedChain: true,
              ),
              const SizedBox(height: 16),
              _buildPlaceholderFeedItem(
                user: 'siti_flora_fauna',
                species: 'Kucing Hutan (Prionailurus bengalensis)',
                location: 'Kuningan, Jawa Barat',
                timeAgo: '2 jam lalu',
                likes: 89,
                hasVerifiedChain: true,
              ),
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
                'Pengujian State Fitur (AGENTS.md)',
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

  Widget _buildPlaceholderFeedItem({
    required String user,
    required String species,
    required String location,
    required String timeAgo,
    required int likes,
    required bool hasVerifiedChain,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sageMuda,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.sageTua,
                child: Icon(Icons.person, color: AppColors.teksPutih, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.teksGelap,
                      ),
                    ),
                    Text(
                      '$location • $timeAgo',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.teksGelap,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasVerifiedChain)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.sageTua,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.link_rounded, size: 14, color: AppColors.teksPutih),
                      SizedBox(width: 4),
                      Text(
                        'Rantai Sah',
                        style: TextStyle(
                          color: AppColors.teksPutih,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 190,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.sage,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pets_rounded, size: 48, color: AppColors.gading),
                SizedBox(height: 8),
                Text(
                  'Pratinjau Tangkapan Foto',
                  style: TextStyle(color: AppColors.gading, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            species,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.teksGelap,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.favorite_rounded, color: AppColors.merahStatus, size: 20),
              const SizedBox(width: 6),
              Text(
                '$likes suka',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.teksGelap,
                ),
              ),
              const Spacer(),
              const Icon(Icons.share_outlined, color: AppColors.teksGelap, size: 20),
            ],
          ),
        ],
      ),
    );
  }
}
