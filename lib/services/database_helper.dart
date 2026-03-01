import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/donation.dart';
import '../models/payment_method.dart';

/// Singleton helper that manages the local SQLite database.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'danakita.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE donations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            campaign TEXT NOT NULL,
            amount REAL NOT NULL,
            tip REAL NOT NULL,
            total REAL NOT NULL,
            paymentMethod TEXT NOT NULL,
            transactionId TEXT NOT NULL,
            note TEXT DEFAULT '',
            date TEXT NOT NULL
          )
        ''');
        await _createPaymentMethodsTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createPaymentMethodsTable(db);
        }
      },
    );
  }

  // ── CREATE ──────────────────────────────────────────────────────────────

  /// Insert a new donation and return its id.
  Future<int> insertDonation(Donation donation) async {
    final db = await database;
    return db.insert('donations', donation.toMap());
  }

  // ── READ ────────────────────────────────────────────────────────────────

  /// Get all donations, newest first.
  Future<List<Donation>> getAllDonations() async {
    final db = await database;
    final rows = await db.query('donations', orderBy: 'date DESC');
    return rows.map((row) => Donation.fromMap(row)).toList();
  }

  /// Get a single donation by id.
  Future<Donation?> getDonation(int id) async {
    final db = await database;
    final rows = await db.query('donations', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Donation.fromMap(rows.first);
  }

  /// Get the total donated amount.
  Future<double> getTotalDonated() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT SUM(total) as total FROM donations');
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  /// Get the total donated for a specific campaign.
  Future<double> getTotalForCampaign(String campaign) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(total) as total FROM donations WHERE campaign = ?',
      [campaign],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  /// Get the number of donations for a specific campaign.
  Future<int> getDonorCountForCampaign(String campaign) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM donations WHERE campaign = ?',
      [campaign],
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  // ── UPDATE ──────────────────────────────────────────────────────────────

  /// Update an existing donation. Returns number of rows affected.
  Future<int> updateDonation(Donation donation) async {
    final db = await database;
    return db.update(
      'donations',
      donation.toMap(),
      where: 'id = ?',
      whereArgs: [donation.id],
    );
  }

  // ── DELETE ──────────────────────────────────────────────────────────────

  /// Delete a donation by id. Returns number of rows deleted.
  Future<int> deleteDonation(int id) async {
    final db = await database;
    return db.delete('donations', where: 'id = ?', whereArgs: [id]);
  }

  /// Delete all donations. Returns number of rows deleted.
  Future<int> deleteAllDonations() async {
    final db = await database;
    return db.delete('donations');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAYMENT METHODS
  // ══════════════════════════════════════════════════════════════════════════

  static Future<void> _createPaymentMethodsTable(Database db) async {
    await db.execute('''
      CREATE TABLE payment_methods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        label TEXT NOT NULL
      )
    ''');
    // Seed defaults
    await db.insert('payment_methods', {'type': 'Card', 'label': 'Visa ending in 4242'});
    await db.insert('payment_methods', {'type': 'e-Wallet', 'label': 'Touch \'n Go / e-Wallet'});
  }

  /// Insert a new payment method.
  Future<int> insertPaymentMethod(PaymentMethod method) async {
    final db = await database;
    return db.insert('payment_methods', method.toMap());
  }

  /// Get all payment methods.
  Future<List<PaymentMethod>> getAllPaymentMethods() async {
    final db = await database;
    final rows = await db.query('payment_methods', orderBy: 'id ASC');
    return rows.map((row) => PaymentMethod.fromMap(row)).toList();
  }

  /// Delete a payment method by id.
  Future<int> deletePaymentMethod(int id) async {
    final db = await database;
    return db.delete('payment_methods', where: 'id = ?', whereArgs: [id]);
  }
}
