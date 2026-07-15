/// Mirrors the backend's derived history status exactly — see
/// `ListDealsByProfileUseCase.ResolveHistoryStatus` in the backend for how
/// `DealStatus` + `InviteStatus` + signature timestamps collapse into one
/// of these five buckets.
enum DealHistoryStatus { draft, waitingSecondParty, waitingYourSignature, signed, cancelled }

/// One card's worth of data for the Deal History list.
class DealSummary {
  const DealSummary({
    required this.id,
    required this.templateKey,
    required this.templateTitle,
    required this.templateDomain,
    required this.status,
    required this.secondPartyName,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String templateKey;
  final String templateTitle;
  final String templateDomain;
  final DealHistoryStatus status;
  final String? secondPartyName;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory DealSummary.fromJson(Map<String, dynamic> json) => DealSummary(
    id: json['id'] as String,
    templateKey: json['templateKey'] as String,
    templateTitle: json['templateTitle'] as String,
    templateDomain: json['templateDomain'] as String? ?? '',
    status: _statusFromJson(json['historyStatus'] as String),
    secondPartyName: json['secondPartyName'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  static DealHistoryStatus _statusFromJson(String value) => switch (value) {
    'Draft' => DealHistoryStatus.draft,
    'WaitingSecondParty' => DealHistoryStatus.waitingSecondParty,
    'WaitingYourSignature' => DealHistoryStatus.waitingYourSignature,
    'Signed' => DealHistoryStatus.signed,
    'Cancelled' => DealHistoryStatus.cancelled,
    _ => DealHistoryStatus.draft,
  };
}

class DealHistoryPage {
  const DealHistoryPage({required this.items, required this.totalCount, required this.page, required this.pageSize});

  final List<DealSummary> items;
  final int totalCount;
  final int page;
  final int pageSize;

  bool get hasMore => page * pageSize < totalCount;

  factory DealHistoryPage.fromJson(Map<String, dynamic> json) => DealHistoryPage(
    items: (json['items'] as List).cast<Map<String, dynamic>>().map(DealSummary.fromJson).toList(),
    totalCount: json['totalCount'] as int,
    page: json['page'] as int,
    pageSize: json['pageSize'] as int,
  );
}
