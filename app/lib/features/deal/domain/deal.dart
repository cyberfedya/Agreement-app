enum DealStatus { draft, pendingSignature, completed }

class Deal {
  const Deal({required this.id, required this.status});

  final String id;
  final DealStatus status;
}
