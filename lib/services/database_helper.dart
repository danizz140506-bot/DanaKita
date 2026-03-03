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
      version: 4,
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
        await _createPaymentMethodsTableV3(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // v1 → v2: create old payment_methods table (will be replaced in v3)
          await db.execute('''
            CREATE TABLE IF NOT EXISTS payment_methods (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              type TEXT NOT NULL,
              label TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 3) {
          // v2 → v3: recreate with provider + credential columns
          await db.execute('DROP TABLE IF EXISTS payment_methods');
          await _createPaymentMethodsTableV3(db);
        }
        if (oldVersion < 4) {
          // Version 4: Re-enforce schema in case device got stuck with an intermediate V3 state
          await db.execute('DROP TABLE IF EXISTS payment_methods');
          await _createPaymentMethodsTableV3(db);
        }
      },
    );
  }

  // ── CREATE ──────────────────────────────────────────────────────────────

  /// Insert a new donation and return its id.
  ///
  /// Throws [ArgumentError] if the total amount is negative or zero.
  Future<int> insertDonation(Donation donation) async {
    if (donation.total <= 0) {
      throw ArgumentError('Donation amount must be greater than zero.');
    }
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
  // PAYMENT METHODS (v3 schema)
  // ══════════════════════════════════════════════════════════════════════════

  static Future<void> _createPaymentMethodsTableV3(Database db) async {
    await db.execute('''
      CREATE TABLE payment_methods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        provider TEXT NOT NULL,
        label TEXT NOT NULL,
        credential TEXT NOT NULL DEFAULT ''
      )
    ''');
    // Seed a default card
    await db.insert('payment_methods', {
      'type': 'Card',
      'provider': 'Visa',
      'label': 'Visa ****4242',
      'credential': '****4242',
    });
  }

  // ── CREATE ────────────────────────────────────────────────────────────

  /// Insert a new payment method.
  Future<int> insertPaymentMethod(PaymentMethod method) async {
    final db = await database;
    return db.insert('payment_methods', method.toMap());
  }

  // ── READ ──────────────────────────────────────────────────────────────

  /// Get all payment methods.
  Future<List<PaymentMethod>> getAllPaymentMethods() async {
    final db = await database;
    final rows = await db.query('payment_methods', orderBy: 'id ASC');
    return rows.map((row) => PaymentMethod.fromMap(row)).toList();
  }

  // ── UPDATE ────────────────────────────────────────────────────────────

  /// Update an existing payment method's label and credential.
  Future<int> updatePaymentMethod(PaymentMethod method) async {
    final db = await database;
    return db.update(
      'payment_methods',
      method.toMap(),
      where: 'id = ?',
      whereArgs: [method.id],
    );
  }

  // ── DELETE ────────────────────────────────────────────────────────────

  /// Delete a payment method by id.
  Future<int> deletePaymentMethod(int id) async {
    final db = await database;
    return db.delete('payment_methods', where: 'id = ?', whereArgs: [id]);
  }

  /// Delete all payment methods.
  Future<int> deleteAllPaymentMethods() async {
    final db = await database;
    return db.delete('payment_methods');
  }
}
