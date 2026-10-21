// ==============================================================================
// FAUNOVA MODEL: ChainVerificationResult
// Mewakili hasil evaluasi verifikasi rantai kanonis SHA-256 (verify_chain & verify_block)
// Sesuai Plan 5.2 & AGENTS.md (Sesi S7)
// ==============================================================================

class ChainVerificationResult {
  final bool isValid;
  final int totalBlocks;
  final int? brokenSeq;
  final String message;

  const ChainVerificationResult({
    required this.isValid,
    required this.totalBlocks,
    this.brokenSeq,
    required this.message,
  });

  factory ChainVerificationResult.fromJson(Map<String, dynamic> json) {
    final bool valid = json['is_valid'] == true;
    final int count = (json['total_blocks'] as num?)?.toInt() ?? 0;
    final int? broken = (json['broken_seq'] as num?)?.toInt();
    final String reason = json['failure_reason']?.toString() ??
        (valid
            ? 'Rantai hash SHA-256 kanonis utuh dan terverifikasi sempurna.'
            : 'Integritas rantai hash tidak valid.');

    return ChainVerificationResult(
      isValid: valid,
      totalBlocks: count,
      brokenSeq: broken,
      message: reason,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_valid': isValid,
      'total_blocks': totalBlocks,
      'broken_seq': brokenSeq,
      'failure_reason': message,
    };
  }
}
