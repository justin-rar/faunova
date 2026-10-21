// ==============================================================================
// FAUNOVA PRESENTATION: SearchPage
// Halaman Pencarian Komunitas: Tab Akun Pengguna & Tab Katalog Spesies Satwa
// Sesuai Plan 5.2, 5.4, 5.7 & AGENTS.md (Sesi S11)
// Catatan Keras: Akun Centang Biru diprioritaskan di atas; koordinat privat tidak pernah bocor.
// ==============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/search_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/glass_app_bar.dart';
import '../../profile/models/public_profile_model.dart';
import '../../profile/presentation/public_profile_page.dart';
import '../models/species_catalog_model.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  AppViewStatus _currentStatus = AppViewStatus.content;
  String _selectedCategory = 'Semua';
  Timer? _debounceTimer;

  List<PublicProfileModel> _searchedAccounts = [];
  List<SpeciesCatalogModel> _searchedSpecies = [];
  bool _isLoading = false;
  String? _searchError;

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
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _executeSearch();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _executeSearch();
    });
  }

  Future<void> _executeSearch() async {
    final query = _searchController.text.trim();
    setState(() {
      _isLoading = true;
      _searchError = null;
    });

    try {
      final accountsFuture = SearchService.instance.searchAccounts(query);
      final speciesFuture = SearchService.instance.searchSpecies(query, category: _selectedCategory);

      final results = await Future.wait([accountsFuture, speciesFuture]);

      if (mounted) {
        setState(() {
          _searchedAccounts = results[0] as List<PublicProfileModel>;
          _searchedSpecies = results[1] as List<SpeciesCatalogModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchError = e.toString();
          _isLoading = false;
        });
      }
    }
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
        emptyTitle: 'Hasil Tidak Ditemukan',
        emptyMessage: 'Coba gunakan kata kunci lain atau periksa ejaan.',
        errorMessage: 'Gagal melakukan pencarian server. Periksa sambungan data.',
        offlineMessage: 'Pencarian daring terbatas dalam mode luring.',
        onRetry: _executeSearch,
        child: Column(
          children: [
            SizedBox(height: topPadding),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSearchInput(),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAccountsTab(),
                  _buildSpeciesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sage.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onQueryChanged,
        style: const TextStyle(fontSize: 14, color: AppColors.teksGelap, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: _tabController.index == 0
              ? 'Cari nama kolektor atau @username...'
              : 'Cari nama lokal satwa atau nama binomial...',
          hintStyle: TextStyle(
            fontSize: 13,
            color: AppColors.teksGelap.withValues(alpha: 0.5),
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.sageTua, size: 22),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.teksGelap),
                  onPressed: () {
                    _searchController.clear();
                    _executeSearch();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildAccountsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.sageTua));
    }

    if (_searchError != null && _searchedAccounts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.merahStatus, size: 40),
              const SizedBox(height: 10),
              Text(_searchError!, style: const TextStyle(fontSize: 13, color: AppColors.teksGelap), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _executeSearch,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.sageTua),
                child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_searchedAccounts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_search_rounded, size: 48, color: AppColors.sage),
              const SizedBox(height: 12),
              const Text(
                'Akun Tidak Ditemukan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.teksGelap),
              ),
              const SizedBox(height: 6),
              Text(
                'Tidak ada penjelajah yang cocok dengan kata kunci "${_searchController.text.trim()}".',
                style: TextStyle(fontSize: 13, color: AppColors.teksGelap.withValues(alpha: 0.7)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
      children: [
        _buildStateSwitcherCard(),
        const SizedBox(height: 12),
        const Row(
          children: [
            Icon(Icons.verified_rounded, size: 16, color: Color(0xFF1E88E5)),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Hasil Akun (Prioritas Centang Biru Teratas)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.teksGelap,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._searchedAccounts.map((account) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildAccountCard(account),
            )),
      ],
    );
  }

  Widget _buildAccountCard(PublicProfileModel account) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: account.isVerified
              ? const Color(0xFF1E88E5).withValues(alpha: 0.35)
              : AppColors.sage.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PublicProfilePage(
                  userId: account.id,
                  initialAuthorName: account.displayName,
                  initialAuthorUsername: account.username,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: account.isVerified ? AppColors.sageTua : AppColors.sage,
                  child: Text(
                    account.displayName.isNotEmpty ? account.displayName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: AppColors.teksPutih,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
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
                          Expanded(
                            child: Text(
                              account.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.teksGelap,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (account.isVerified) ...[
                            const SizedBox(width: 5),
                            const Icon(
                              Icons.verified_rounded,
                              color: Color(0xFF1E88E5),
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${account.username}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.teksGelap.withValues(alpha: 0.65),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (account.bio.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          account.bio,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.teksGelap.withValues(alpha: 0.8),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.sageMuda.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${account.capturesCount} Obs',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.teksGelap,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${account.followersCount} pengikut',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.teksGelap.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpeciesTab() {
    return Column(
      children: [
        _buildCategoryFilterBar(),
        const SizedBox(height: 6),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.sageTua))
              : _searchedSpecies.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(30),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.pets_outlined, size: 48, color: AppColors.sage),
                            const SizedBox(height: 12),
                            const Text(
                              'Spesies Tidak Ditemukan',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.teksGelap),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Coba gunakan nama lokal Indonesia atau nama ilmiah binomial latin.',
                              style: TextStyle(fontSize: 13, color: AppColors.teksGelap.withValues(alpha: 0.7)),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
                      children: [
                        _buildStateSwitcherCard(),
                        const SizedBox(height: 10),
                        ..._searchedSpecies.map((species) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildSpeciesCard(species),
                            )),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilterBar() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          return ChoiceChip(
            label: Text(cat),
            selected: isSelected,
            onSelected: (_) {
              setState(() {
                _selectedCategory = cat;
              });
              _executeSearch();
            },
            selectedColor: AppColors.sageTua,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected ? AppColors.sageTua : AppColors.sage.withValues(alpha: 0.35),
            ),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.teksPutih : AppColors.teksGelap,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }

  Widget _buildSpeciesCard(SpeciesCatalogModel sp) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sage.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.sageMuda,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.pets_rounded, color: AppColors.sageTua, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        sp.speciesName,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.teksGelap,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: _getConservationBadgeColor(sp.conservationStatus).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        sp.conservationStatus,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: _getConservationBadgeColor(sp.conservationStatus),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  sp.scientificName,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.teksGelap.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  sp.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.3,
                    color: AppColors.teksGelap.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.gading,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        sp.taxonomyClass,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.sageTua,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${sp.observationsCount} observasi tercatat',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.teksGelap.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getConservationBadgeColor(String status) {
    if (status.contains('Kritis') || status.contains('CR')) {
      return AppColors.merahStatus;
    }
    if (status.contains('Terancam') || status.contains('EN')) {
      return const Color(0xFFD84315);
    }
    if (status.contains('Rentan') || status.contains('VU')) {
      return AppColors.emasTua;
    }
    return AppColors.sageTua;
  }

  Widget _buildStateSwitcherCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              Icon(Icons.tune_rounded, size: 15, color: AppColors.teksGelap),
              SizedBox(width: 8),
              Text(
                'Pengujian State Fitur (AGENTS.md)',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppColors.teksGelap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
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
}
