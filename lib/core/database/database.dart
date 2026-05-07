import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../features/invoices/domain/entities/invoice_status.dart';

part 'database.g.dart';

@DataClassName('ClientData')
class Clients extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('InvoiceData')
class Invoices extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get clientId => integer().references(Clients, #id)();
  TextColumn get invoiceNumber => text().withLength(min: 1, max: 20)();
  IntColumn get status => intEnum<InvoiceStatus>()();
  DateTimeColumn get issueDate => dateTime()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  RealColumn get subtotal => real().withDefault(const Constant(0.0))();
  RealColumn get taxRate => real().withDefault(const Constant(0.0))();
  RealColumn get discountAmount => real().withDefault(const Constant(0.0))();
  RealColumn get total => real().withDefault(const Constant(0.0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('InvoiceItemData')
class InvoiceItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get invoiceId => integer().references(Invoices, #id, onDelete: KeyAction.cascade)();
  TextColumn get description => text()();
  RealColumn get quantity => real().withDefault(const Constant(1.0))();
  RealColumn get unitPrice => real().withDefault(const Constant(0.0))();
  RealColumn get amount => real().withDefault(const Constant(0.0))();
}

class BusinessSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get companyName => text().withLength(min: 1, max: 100)();
  TextColumn get address => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get website => text().nullable()();
  TextColumn get logoPath => text().nullable()(); // path to logo image file
}

@DataClassName('PaymentData')
class Payments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get invoiceId => integer().references(Invoices, #id, onDelete: KeyAction.cascade)();
  IntColumn get clientId => integer().references(Clients, #id, onDelete: KeyAction.cascade)();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  TextColumn get method => text().nullable()();
  TextColumn get notes => text().nullable()();
}

@DataClassName('ArticleData')
class Articles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get code => text().nullable()();
  RealColumn get price => real().withDefault(const Constant(0.0))();
  TextColumn get unit => text()(); // kg, m2, m3, pieces
  TextColumn get type => text().withDefault(const Constant('physical'))(); // physical, service
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Clients, Invoices, InvoiceItems, BusinessSettings, Payments, Articles])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(businessSettings);
      }
      if (from < 3) {
        await m.addColumn(businessSettings, businessSettings.logoPath);
      }
      if (from < 4) {
        await m.createTable(payments);
      }
      if (from < 5) {
        await m.createTable(articles);
      }
      if (from < 6) {
        // Added type column to Articles in v6
        await m.addColumn(articles, articles.type);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'invoice_manager.db'));
    return NativeDatabase.createInBackground(file);
  });
}
