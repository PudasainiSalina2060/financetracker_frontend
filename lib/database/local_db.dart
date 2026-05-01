import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class LocalDB {
  static Database? _database;

 //Get database (create once, reuse)
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

 // Opening database file
  static Future<Database> _initDB() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = join(dir.path, 'financetracker.db');

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _createTables,
    );
  }

  //Create tables (runs first time only)
  static Future<void> _createTables(Database db, int version) async {

    //Accounts
    await db.execute('''
      CREATE TABLE accounts (
        account_id       INTEGER PRIMARY KEY,
        user_id          INTEGER NOT NULL,
        type             TEXT NOT NULL,
        name             TEXT NOT NULL,
        initial_balance  REAL NOT NULL,
        current_balance  REAL NOT NULL,
        created_at       TEXT
      )
    ''');
    //Categories
    await db.execute('''
      CREATE TABLE categories (
        category_id  INTEGER PRIMARY KEY,
        user_id      INTEGER,
        name         TEXT NOT NULL,
        type         TEXT NOT NULL,
        color        TEXT,
        icon         TEXT
      )
    ''');

    // Transactions
    await db.execute('''
      CREATE TABLE transactions (
        transaction_id  INTEGER PRIMARY KEY,
        user_id         INTEGER NOT NULL,
        account_id      INTEGER NOT NULL,
        category_id     INTEGER NOT NULL,
        type            TEXT NOT NULL,
        amount          REAL NOT NULL,
        notes           TEXT,
        date            TEXT NOT NULL,
        is_recurring    INTEGER DEFAULT 0,
        created_at      TEXT,
        updated_at      TEXT,
        category_name   TEXT DEFAULT 'Unknown',
        account_name    TEXT DEFAULT 'Unknown'
      )
    ''');

    //Recurring transactions
    await db.execute('''
      CREATE TABLE recurring_transactions (
        recurring_id    INTEGER PRIMARY KEY,
        user_id         INTEGER NOT NULL,
        transaction_id  INTEGER NOT NULL,
        frequency       TEXT NOT NULL,
        next_run_date   TEXT NOT NULL
      )
    ''');

    //Budgets
    await db.execute('''
      CREATE TABLE budgets (
        budget_id       INTEGER PRIMARY KEY,
        user_id         INTEGER NOT NULL,
        category_id     INTEGER NOT NULL,
        limit_amount    REAL NOT NULL,
        period          TEXT NOT NULL,
        start_date      TEXT NOT NULL,
        alert_sent_80   INTEGER DEFAULT 0,
        alert_sent_100  INTEGER DEFAULT 0,
        created_at      TEXT
      )
    ''');

    //Groups
    await db.execute('''
      CREATE TABLE groups (
        group_id    INTEGER PRIMARY KEY,
        user_id     INTEGER NOT NULL,
        name        TEXT NOT NULL,
        created_at  TEXT
      )
    ''');


    //Group members
    await db.execute('''
      CREATE TABLE group_members (
        member_id            INTEGER PRIMARY KEY,
        group_id             INTEGER NOT NULL,
        user_id              INTEGER,
        external_contact_id  INTEGER,
        joined_at            TEXT
      )
    ''');

    //Group expenses
    await db.execute('''
      CREATE TABLE group_expenses (
        group_expense_id   INTEGER PRIMARY KEY,
        group_id           INTEGER NOT NULL,
        paid_by_member_id  INTEGER NOT NULL,
        amount             REAL NOT NULL,
        note               TEXT,
        date               TEXT NOT NULL
      )
    ''');

    //Split shares
    await db.execute('''
      CREATE TABLE split_shares (
        share_id          INTEGER PRIMARY KEY,
        group_expense_id  INTEGER NOT NULL,
        member_id         INTEGER NOT NULL,
        amount            REAL NOT NULL,
        is_settled        INTEGER DEFAULT 0
      )
    ''');

    //Settlements
    await db.execute('''
      CREATE TABLE settlements (
        settlement_id   INTEGER PRIMARY KEY,
        group_id        INTEGER NOT NULL,
        from_member_id  INTEGER NOT NULL,
        to_member_id    INTEGER NOT NULL,
        amount          REAL NOT NULL,
        method          TEXT NOT NULL,
        date            TEXT NOT NULL
      )
    ''');

    //Notifications
    await db.execute('''
      CREATE TABLE notifications (
        notification_id  INTEGER PRIMARY KEY,
        user_id          INTEGER NOT NULL,
        type             TEXT NOT NULL,
        message          TEXT NOT NULL,
        icon             TEXT,
        timestamp        TEXT,
        is_read          INTEGER DEFAULT 0
      )
    ''');

    // Sync log (offline support)
    await db.execute('''
      CREATE TABLE sync_log (
        sync_id       INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name    TEXT NOT NULL,
        record_id     INTEGER NOT NULL,
        operation     TEXT NOT NULL,
        is_synced     INTEGER DEFAULT 0,
        last_updated  TEXT NOT NULL
      )
    ''');

    print("Tables created");
  }

  //Debug helper
  static Future<void> checkTables() async {
    final db = await database;
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'"
    );
    for (var table in tables) {
      print("${table['name']}");
    }
  }
}