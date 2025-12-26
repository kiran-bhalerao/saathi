/// Result of a sync operation
class SyncResult {
  final int sent;
  final int received;

  SyncResult({
    required this.sent,
    required this.received,
  });
}
