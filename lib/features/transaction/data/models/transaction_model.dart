import 'package:warung_pintar_cimahi/features/transaction/domain/entities/transaction_entity.dart';

class TransactionModel {
  final String id;
  final String idempotencyKey;
  final String itemName;
  final int quantity;
  final int amountSen;
  final int priceAtTransactionSen;
  final String transactionType;
  final String status;
  final int needsClarification;
  final String inputMethod;
  final String? confirmedAt;
  final String createdAt;
  final String? rawInputSource;
  final String? aiRawOutput;

  const TransactionModel({
    required this.id,
    required this.idempotencyKey,
    required this.itemName,
    required this.quantity,
    required this.amountSen,
    required this.priceAtTransactionSen,
    required this.transactionType,
    required this.status,
    this.needsClarification = 0,
    required this.inputMethod,
    this.confirmedAt,
    required this.createdAt,
    this.rawInputSource,
    this.aiRawOutput,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      idempotencyKey: map['idempotency_key'] as String,
      itemName: map['item_name'] as String,
      quantity: map['quantity'] as int,
      amountSen: map['amount_sen'] as int,
      priceAtTransactionSen: map['price_at_transaction_sen'] as int,
      transactionType: map['transaction_type'] as String,
      status: map['status'] as String,
      needsClarification: (map['needs_clarification'] as int?) ?? 0,
      inputMethod: map['input_method'] as String,
      confirmedAt: map['confirmed_at'] as String?,
      createdAt: map['created_at'] as String,
      rawInputSource: map['raw_input_source'] as String?,
      aiRawOutput: map['ai_raw_output'] as String?,
    );
  }

  TransactionEntity toEntity() {
    return TransactionEntity(
      id: id,
      idempotencyKey: idempotencyKey,
      itemName: itemName,
      quantity: quantity,
      amountSen: amountSen,
      priceAtTransactionSen: priceAtTransactionSen,
      type: transactionType == 'sell'
          ? const TransactionSell()
          : const TransactionBuy(),
      status: TransactionStatus.values.firstWhere(
        (s) => s.name == status,
        orElse: () => TransactionStatus.pending,
      ),
      needsClarification: needsClarification == 1,
      inputMethod: switch (inputMethod) {
        'voice' => const InputVoice(),
        'image' => const InputImage(),
        _ => const InputManual(),
      },
      confirmedAt: confirmedAt != null ? DateTime.parse(confirmedAt!) : null,
      createdAt: DateTime.parse(createdAt),
      rawInputSource: rawInputSource,
      aiRawOutput: aiRawOutput,
    );
  }
}
