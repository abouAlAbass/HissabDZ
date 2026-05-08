import 'package:freezed_annotation/freezed_annotation.dart';
import 'invoice_item.dart';
import 'invoice_status.dart';
import '../../../clients/domain/entities/client.dart';

part 'invoice.freezed.dart';
part 'invoice.g.dart';

@freezed
class Invoice with _$Invoice {
  const factory Invoice({
    int? id,
    required int clientId,
    int? projectId,
    required String invoiceNumber,
    @Default(InvoiceStatus.draft) InvoiceStatus status,
    required DateTime issueDate,
    DateTime? dueDate,
    DateTime? lastReminderAt,
    String? notes,
    @Default(0.0) double subtotal,
    @Default(0.0) double taxRate,
    @Default(0.0) double discountAmount,
    @Default(0.0) double total,
    DateTime? createdAt,
    DateTime? updatedAt,
    @Default([]) List<InvoiceItem> items,
    Client? client,
    String? projectName,
  }) = _Invoice;

  factory Invoice.fromJson(Map<String, dynamic> json) =>
      _$InvoiceFromJson(json);
}
