import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/glass_app_bar.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AppViewStatus _currentStatus = AppViewStatus.content;
  String _selectedCategory = 'Semua';

  final List<String> _categories = const [
    'Semua',
    'Mamalia',
    'Aves (Burung)',
    'Reptilia',
    'Amfibi',
  ];

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
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 12;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        centerTitle: true,
        title: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.label,
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(width: 3.0, color: Colors.white),
            insets: EdgeInsets.symmetric(horizontal: 10),
            borderRadius: BorderRadius.all(Radius.circular(3)),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.60),
          labelStyle: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          tabs: const [
            Tab(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('Akun Pengguna'),
              ),
            ),
            Tab(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('Katalog Spesies'),
              ),
            ),
          ],
        ),
      ),
      body: AppStateView(
        status: _currentStatus,
        loadingMessage: 'Mencari entri dalam basis data...',
        emptyTitle: 'Spesimen Tidak Ditemukan',
        emptyMessage: 'Coba gunakan nama lokal atau nama ilmiah binomial latin.',
        errorMessage: 'Gagal melakukan pencarian server. Periksa sambungan data.',
        offlineMessage: 'Pencarian daring terbatas dalam mode luring.',
        onRetry: () {
          setState(() {
            _currentStatus = AppViewStatus.content;
          });
        },
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, topPadding, 16, 110),
          children: [
            _buildSearchInput(),
            const SizedBox(height: 12),
            _buildCategoryFilterBar(),
            const SizedBox(height: 12),
            _buildStateSwitcherCard(),
            const SizedBox(height: 16),
            const Text(
              'Akun Terverifikasi (Prioritas Centang Biru)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.teksGelap,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 10),
            _buildCuratedAccountCard(
              name: 'Balai Konservasi Sumber Daya Alam',
              username: 'bksda_official',
              roleTitle: 'Lembaga Konservasi Resmi',
              isVerified: true,
              badgeCount: 8,
              observationsCount: 520,
            ),
            const SizedBox(height: 10),
            _buildCuratedAccountCard(
              name: 'drh. Anindya Putri',
              username: 'anindya_vet',
              roleTitle: 'Dokter Satwa Liar & Peneliti Primata',
              isVerified: true,
              badgeCount: 6,
              observationsCount: 84,
            ),
            const SizedBox(height: 10),
            _buildCuratedAccountCard(
              name: 'Fauna Watch Indonesia',
              username: 'faunawatch_id',
              roleTitle: 'Komunitas Pengamat Burung Endemik',
              isVerified: true,
              badgeCount: 7,
              observationsCount: 312,
            ),
            const SizedBox(height: 10),
            _buildCuratedAccountCard(
              name: 'Farhan Rimba',
              username: 'farhan_explorer',
              roleTitle: 'Fotografer Satwa Liar Hutan Hujan',
              isVerified: false,
              badgeCount: 3,
              observationsCount: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sageMuda,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.sage.withValues(alpha: 0.4), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: const Row(
        children: [
          Icon(Icons.search_rounded, color: AppColors.teksGelap, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari nama lokal, nama latin, atau akun...',
                hintStyle: TextStyle(
                  color: AppColors.teksGelap,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterBar() {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = cat;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.sageTua : AppColors.sageMuda,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.sageTua : AppColors.sage.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.teksPutih : AppColors.teksGelap,
                ),
              ),
            ),
          );
        },
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

  Widget _buildCuratedAccountCard({
    required String name,
    required String username,
    required String roleTitle,
    required bool isVerified,
    required int badgeCount,
    required int observationsCount,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sageMuda,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sage.withValues(alpha: 0.3), width: 1),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.sageTua,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: AppColors.teksPutih,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: AppColors.teksGelap,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified_rounded,
                        color: Color(0xFF1E88E5),
                        size: 16,
                      ),
                    ],
                  ],
                ),
                Text(
                  '@$username',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.teksGelap.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  roleTitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.emasTua,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$observationsCount Observasi • $badgeCount Badge',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.teksGelap.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: const Size(64, 34),
            ),
            child: const Text('Ikuti', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
