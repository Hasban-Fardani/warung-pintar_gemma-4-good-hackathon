sealed class TransactionType {
  const TransactionType();
}

final class TransactionSell extends TransactionType {
  const TransactionSell();
}

final class TransactionBuy extends TransactionType {
  const TransactionBuy();
}

enum TransactionStatus { pending, confirmed, deleted }

sealed class InputMethod {
  const InputMethod();
}

final class InputVoice extends InputMethod {
  const InputVoice();
}

final class InputImage extends InputMethod {
  const InputImage();
}

final class InputManual extends InputMethod {
  const InputManual();
}

class TransactionEntity {
  final String id;
  final String idempotencyKey;
  final String itemName;
  final int quantity;
  final int amountSen;
  final int priceAtTransactionSen;
  final TransactionType type;
  final TransactionStatus status;
  final bool needsClarification;
  final InputMethod inputMethod;
  final DateTime? confirmedAt;
  final DateTime createdAt;
  final String? rawInputSource;
  final String? aiRawOutput;

  const TransactionEntity({
    required this.id,
    required this.idempotencyKey,
    required this.itemName,
    required this.quantity,
    required this.amountSen,
    required this.priceAtTransactionSen,
    required this.type,
    required this.status,
    this.needsClarification = false,
    required this.inputMethod,
    this.confirmedAt,
    required this.createdAt,
    this.rawInputSource,
    this.aiRawOutput,
  });
}
