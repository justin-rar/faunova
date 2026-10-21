// ==============================================================================
// FAUNOVA SERVICE: BadgeService
// Pengelolaan Lencana Gelar Pencapaian (Plan 5.8: 202-217)
// Aturan Keras 2: Syarat & pembukaan dievaluasi di server
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/profile/models/badge_model.dart';
import 'encrypted_storage_service.dart';

class BadgeService {
  static final BadgeService instance = BadgeService._internal();
  BadgeService._internal();

  SupabaseClient? _client;
  final Set<String> _celebratedBadges = {};

  @visibleForTesting
  void setMockClient(SupabaseClient client) {
    _client = client;
  }

  SupabaseClient? get _supabase {
    if (_client != null) return _client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  String? _simulatedNewlyUnlockedBadgeId;

  @visibleForTesting
  void simulateNewlyUnlocked(String? badgeId) {
    _simulatedNewlyUnlockedBadgeId = badgeId;
  }

  @visibleForTesting
  void resetCelebrated() {
    _celebratedBadges.clear();
    _simulatedNewlyUnlockedBadgeId = null;
  }

  /// Mengambil daftar seluruh 8 badge beserta status pembukaan dan progres pengguna
  Future<List<BadgeModel>> getUserBadges() async {
    final client = _supabase;

    if (client != null && client.auth.currentUser != null) {
      try {
        final res = await client.rpc('get_user_badges');
        if (res is List) {
          final list = res.map((e) => BadgeModel.fromJson(e as Map<String, dynamic>)).toList();
          return _filterNewCelebrations(list);
        }
      } catch (e) {
        debugPrint('BadgeService getUserBadges Supabase error: $e. Fallback ke demo.');
      }
    }

    // Fallback mode demo / luring
    return _filterNewCelebrations(_getDemoBadges());
  }

  List<BadgeModel> _filterNewCelebrations(List<BadgeModel> badges) {
    final updated = <BadgeModel>[];
    for (final b in badges) {
      final isNew = b.isNewlyUnlocked && !_celebratedBadges.contains(b.id);
      updated.add(
        BadgeModel(
          id: b.id,
          name: b.name,
          description: b.description,
          targetCount: b.targetCount,
          currentProgress: b.currentProgress,
          actualProgress: b.actualProgress,
          isUnlocked: b.isUnlocked,
          unlockedAt: b.unlockedAt,
          iconName: b.iconName,
          category: b.category,
          isNewlyUnlocked: isNew,
        ),
      );
    }
    return updated;
  }

  /// Menandai badge telah ditampilkan dalam popup perayaan
  void markBadgeCelebrated(String badgeId) {
    _celebratedBadges.add(badgeId);
  }

  List<BadgeModel> _getDemoBadges() {
    // Ambil metrik lokal dari penyimpanan / cache
    final bestScore = EncryptedStorageService.instance.getBestQuizScore();
    final streak = (EncryptedStorageService.instance.getSetting('cached_streak_count', defaultValue: 5) as num).toInt();

    final defs = [
      {
        'id': 'pemula',
        'name': 'Pemula',
        'description': '1 tangkapan pertama disimpan ke koleksi kanonis.',
        'target_count': 1,
        'prog': 4, // demo memiliki 4 koleksi
        'icon': 'eco',
        'cat': 'Koleksi',
      },
      {
        'id': 'kolektor',
        'name': 'Kolektor',
        'description': 'Simpan 10 tangkapan hewan ke dalam koleksi.',
        'target_count': 10,
        'prog': 4,
        'icon': 'auto_stories',
        'cat': 'Koleksi',
      },
      {
        'id': 'rajin',
        'name': 'Rajin',
        'description': 'Lakukan check-in streak observasi 7 hari berturut-turut.',
        'target_count': 7,
        'prog': streak,
        'icon': 'local_fire_department',
        'cat': 'Observasi',
      },
      {
        'id': 'si_pintar',
        'name': 'Si Pintar',
        'description': 'Selesaikan 5 sesi kuis biologi di Arena Kuis.',
        'target_count': 5,
        'prog': 2,
        'icon': 'psychology',
        'cat': 'Kuis',
      },
      {
        'id': 'juara_kuis',
        'name': 'Juara Kuis',
        'description': 'Raih skor minimal 1000 dalam satu sesi kuis.',
        'target_count': 1000,
        'prog': bestScore,
        'icon': 'military_tech',
        'cat': 'Kuis',
      },
      {
        'id': 'sosialita',
        'name': 'Sosialita',
        'description': 'Dapatkan akumulasi minimal 5 pengikut atau 10 suka pada postingan.',
        'target_count': 5,
        'prog': 5,
        'icon': 'groups',
        'cat': 'Sosial',
      },
      {
        'id': 'rutin_menantang',
        'name': 'Rutin Menantang',
        'description': 'Jawab dengan benar Tantangan Hari Ini sebanyak 5 kali.',
        'target_count': 5,
        'prog': 1,
        'icon': 'stars',
        'cat': 'Tantangan',
      },
      {
        'id': 'si_goyang',
        'name': 'Si Goyang',
        'description': 'Jawab dengan benar 10 soal kuis goyang HP (Shake-to-Quiz).',
        'target_count': 10,
        'prog': 1,
        'icon': 'vibration',
        'cat': 'Sensor',
      },
    ];

    return defs.map((d) {
      final prog = d['prog'] as int;
      final target = d['target_count'] as int;
      final unlocked = prog >= target;
      final id = d['id'] as String;
      final newly = (id == _simulatedNewlyUnlockedBadgeId) && unlocked;

      return BadgeModel(
        id: id,
        name: d['name'] as String,
        description: d['description'] as String,
        targetCount: target,
        currentProgress: prog.clamp(0, target),
        actualProgress: prog,
        isUnlocked: unlocked,
        unlockedAt: unlocked ? DateTime(2026, 10, 21) : null,
        iconName: d['icon'] as String,
        category: d['cat'] as String,
        isNewlyUnlocked: newly,
      );
    }).toList();
  }

  /// Konversi string ikon ke IconData Material
  static IconData getBadgeIcon(String iconName) {
    switch (iconName) {
      case 'eco':
        return Icons.eco_rounded;
      case 'auto_stories':
        return Icons.auto_stories_rounded;
      case 'local_fire_department':
        return Icons.local_fire_department_rounded;
      case 'psychology':
        return Icons.psychology_rounded;
      case 'military_tech':
        return Icons.military_tech_rounded;
      case 'groups':
        return Icons.groups_rounded;
      case 'stars':
        return Icons.stars_rounded;
      case 'vibration':
        return Icons.vibration_rounded;
      default:
        return Icons.military_tech_rounded;
    }
  }
}
