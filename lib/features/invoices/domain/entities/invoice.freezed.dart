// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invoice.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Invoice _$InvoiceFromJson(Map<String, dynamic> json) {
  return _Invoice.fromJson(json);
}

/// @nodoc
mixin _$Invoice {
  int? get id => throw _privateConstructorUsedError;
  int get clientId => throw _privateConstructorUsedError;
  String get invoiceNumber => throw _privateConstructorUsedError;
  InvoiceStatus get status => throw _privateConstructorUsedError;
  DateTime get issueDate => throw _privateConstructorUsedError;
  DateTime? get dueDate => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  double get subtotal => throw _privateConstructorUsedError;
  double get taxRate => throw _privateConstructorUsedError;
  double get discountAmount => throw _privateConstructorUsedError;
  double get total => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  List<InvoiceItem> get items => throw _privateConstructorUsedError;
  Client? get client => throw _privateConstructorUsedError;

  /// Serializes this Invoice to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Invoice
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InvoiceCopyWith<Invoice> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InvoiceCopyWith<$Res> {
  factory $InvoiceCopyWith(Invoice value, $Res Function(Invoice) then) =
      _$InvoiceCopyWithImpl<$Res, Invoice>;
  @useResult
  $Res call({
    int? id,
    int clientId,
    String invoiceNumber,
    InvoiceStatus status,
    DateTime issueDate,
    DateTime? dueDate,
    String? notes,
    double subtotal,
    double taxRate,
    double discountAmount,
    double total,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<InvoiceItem> items,
    Client? client,
  });

  $ClientCopyWith<$Res>? get client;
}

/// @nodoc
class _$InvoiceCopyWithImpl<$Res, $Val extends Invoice>
    implements $InvoiceCopyWith<$Res> {
  _$InvoiceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Invoice
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? clientId = null,
    Object? invoiceNumber = null,
    Object? status = null,
    Object? issueDate = null,
    Object? dueDate = freezed,
    Object? notes = freezed,
    Object? subtotal = null,
    Object? taxRate = null,
    Object? discountAmount = null,
    Object? total = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? items = null,
    Object? client = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int?,
            clientId: null == clientId
                ? _value.clientId
                : clientId // ignore: cast_nullable_to_non_nullable
                      as int,
            invoiceNumber: null == invoiceNumber
                ? _value.invoiceNumber
                : invoiceNumber // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as InvoiceStatus,
            issueDate: null == issueDate
                ? _value.issueDate
                : issueDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            dueDate: freezed == dueDate
                ? _value.dueDate
                : dueDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            subtotal: null == subtotal
                ? _value.subtotal
                : subtotal // ignore: cast_nullable_to_non_nullable
                      as double,
            taxRate: null == taxRate
                ? _value.taxRate
                : taxRate // ignore: cast_nullable_to_non_nullable
                      as double,
            discountAmount: null == discountAmount
                ? _value.discountAmount
                : discountAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            total: null == total
                ? _value.total
                : total // ignore: cast_nullable_to_non_nullable
                      as double,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<InvoiceItem>,
            client: freezed == client
                ? _value.client
                : client // ignore: cast_nullable_to_non_nullable
                      as Client?,
          )
          as $Val,
    );
  }

  /// Create a copy of Invoice
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ClientCopyWith<$Res>? get client {
    if (_value.client == null) {
      return null;
    }

    return $ClientCopyWith<$Res>(_value.client!, (value) {
      return _then(_value.copyWith(client: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$InvoiceImplCopyWith<$Res> implements $InvoiceCopyWith<$Res> {
  factory _$$InvoiceImplCopyWith(
    _$InvoiceImpl value,
    $Res Function(_$InvoiceImpl) then,
  ) = __$$InvoiceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int? id,
    int clientId,
    String invoiceNumber,
    InvoiceStatus status,
    DateTime issueDate,
    DateTime? dueDate,
    String? notes,
    double subtotal,
    double taxRate,
    double discountAmount,
    double total,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<InvoiceItem> items,
    Client? client,
  });

  @override
  $ClientCopyWith<$Res>? get client;
}

/// @nodoc
class __$$InvoiceImplCopyWithImpl<$Res>
    extends _$InvoiceCopyWithImpl<$Res, _$InvoiceImpl>
    implements _$$InvoiceImplCopyWith<$Res> {
  __$$InvoiceImplCopyWithImpl(
    _$InvoiceImpl _value,
    $Res Function(_$InvoiceImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Invoice
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? clientId = null,
    Object? invoiceNumber = null,
    Object? status = null,
    Object? issueDate = null,
    Object? dueDate = freezed,
    Object? notes = freezed,
    Object? subtotal = null,
    Object? taxRate = null,
    Object? discountAmount = null,
    Object? total = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? items = null,
    Object? client = freezed,
  }) {
    return _then(
      _$InvoiceImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int?,
        clientId: null == clientId
            ? _value.clientId
            : clientId // ignore: cast_nullable_to_non_nullable
                  as int,
        invoiceNumber: null == invoiceNumber
            ? _value.invoiceNumber
            : invoiceNumber // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as InvoiceStatus,
        issueDate: null == issueDate
            ? _value.issueDate
            : issueDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        dueDate: freezed == dueDate
            ? _value.dueDate
            : dueDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        subtotal: null == subtotal
            ? _value.subtotal
            : subtotal // ignore: cast_nullable_to_non_nullable
                  as double,
        taxRate: null == taxRate
            ? _value.taxRate
            : taxRate // ignore: cast_nullable_to_non_nullable
                  as double,
        discountAmount: null == discountAmount
            ? _value.discountAmount
            : discountAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        total: null == total
            ? _value.total
            : total // ignore: cast_nullable_to_non_nullable
                  as double,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<InvoiceItem>,
        client: freezed == client
            ? _value.client
            : client // ignore: cast_nullable_to_non_nullable
                  as Client?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$InvoiceImpl implements _Invoice {
  const _$InvoiceImpl({
    this.id,
    required this.clientId,
    required this.invoiceNumber,
    this.status = InvoiceStatus.draft,
    required this.issueDate,
    this.dueDate,
    this.notes,
    this.subtotal = 0.0,
    this.taxRate = 0.0,
    this.discountAmount = 0.0,
    this.total = 0.0,
    this.createdAt,
    this.updatedAt,
    final List<InvoiceItem> items = const [],
    this.client,
  }) : _items = items;

  factory _$InvoiceImpl.fromJson(Map<String, dynamic> json) =>
      _$$InvoiceImplFromJson(json);

  @override
  final int? id;
  @override
  final int clientId;
  @override
  final String invoiceNumber;
  @override
  @JsonKey()
  final InvoiceStatus status;
  @override
  final DateTime issueDate;
  @override
  final DateTime? dueDate;
  @override
  final String? notes;
  @override
  @JsonKey()
  final double subtotal;
  @override
  @JsonKey()
  final double taxRate;
  @override
  @JsonKey()
  final double discountAmount;
  @override
  @JsonKey()
  final double total;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;
  final List<InvoiceItem> _items;
  @override
  @JsonKey()
  List<InvoiceItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final Client? client;

  @override
  String toString() {
    return 'Invoice(id: $id, clientId: $clientId, invoiceNumber: $invoiceNumber, status: $status, issueDate: $issueDate, dueDate: $dueDate, notes: $notes, subtotal: $subtotal, taxRate: $taxRate, discountAmount: $discountAmount, total: $total, createdAt: $createdAt, updatedAt: $updatedAt, items: $items, client: $client)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InvoiceImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.clientId, clientId) ||
                other.clientId == clientId) &&
            (identical(other.invoiceNumber, invoiceNumber) ||
                other.invoiceNumber == invoiceNumber) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.issueDate, issueDate) ||
                other.issueDate == issueDate) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.subtotal, subtotal) ||
                other.subtotal == subtotal) &&
            (identical(other.taxRate, taxRate) || other.taxRate == taxRate) &&
            (identical(other.discountAmount, discountAmount) ||
                other.discountAmount == discountAmount) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.client, client) || other.client == client));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    clientId,
    invoiceNumber,
    status,
    issueDate,
    dueDate,
    notes,
    subtotal,
    taxRate,
    discountAmount,
    total,
    createdAt,
    updatedAt,
    const DeepCollectionEquality().hash(_items),
    client,
  );

  /// Create a copy of Invoice
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InvoiceImplCopyWith<_$InvoiceImpl> get copyWith =>
      __$$InvoiceImplCopyWithImpl<_$InvoiceImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$InvoiceImplToJson(this);
  }
}

abstract class _Invoice implements Invoice {
  const factory _Invoice({
    final int? id,
    required final int clientId,
    required final String invoiceNumber,
    final InvoiceStatus status,
    required final DateTime issueDate,
    final DateTime? dueDate,
    final String? notes,
    final double subtotal,
    final double taxRate,
    final double discountAmount,
    final double total,
    final DateTime? createdAt,
    final DateTime? updatedAt,
    final List<InvoiceItem> items,
    final Client? client,
  }) = _$InvoiceImpl;

  factory _Invoice.fromJson(Map<String, dynamic> json) = _$InvoiceImpl.fromJson;

  @override
  int? get id;
  @override
  int get clientId;
  @override
  String get invoiceNumber;
  @override
  InvoiceStatus get status;
  @override
  DateTime get issueDate;
  @override
  DateTime? get dueDate;
  @override
  String? get notes;
  @override
  double get subtotal;
  @override
  double get taxRate;
  @override
  double get discountAmount;
  @override
  double get total;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  List<InvoiceItem> get items;
  @override
  Client? get client;

  /// Create a copy of Invoice
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InvoiceImplCopyWith<_$InvoiceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
