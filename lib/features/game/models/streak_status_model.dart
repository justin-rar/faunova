// ==============================================================================
// FAUNOVA MODEL: StreakStatusModel
// Status check-in streak harian berbasis WIB (Plan 168-170, 543)
// ==============================================================================

class StreakStatusModel {
  final int streakCount;
  final String? lastClaimDate;
  final bool isClaimedToday;
  final String wibToday;
  final bool isNewClaim;
  final String message;

  const StreakStatusModel({
    required this.streakCount,
    this.lastClaimDate,
    required this.isClaimedToday,
    required this.wibToday,
    this.isNewClaim = false,
    this.message = '',
  });

  factory StreakStatusModel.fromJson(Map<String, dynamic> json) {
    return StreakStatusModel(
      streakCount: (json['streak_count'] as num?)?.toInt() ?? 0,
      lastClaimDate: json['last_streak_claim_date'] as String?,
      isClaimedToday: json['is_claimed_today'] as bool? ??
          (json['already_claimed'] as bool? ?? false),
      wibToday: json['wib_today'] as String? ?? '',
      isNewClaim: json['is_new_claim'] as bool? ?? false,
      message: json['message'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'streak_count': streakCount,
      'last_streak_claim_date': lastClaimDate,
      'is_claimed_today': isClaimedToday,
      'wib_today': wibToday,
      'is_new_claim': isNewClaim,
      'message': message,
    };
  }
}
