import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Import the unified model files we created
import 'package:nirogx_app/models/health_data.dart';
import 'package:nirogx_app/models/symptom_log.dart';

class DatabaseHelper {
  // Singleton instance setup
  static final DatabaseHelper instance = DatabaseHelper._internal();
  factory DatabaseHelper() => instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'nirogx.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Table for Dashboard Data (Home Screen)
        // Columns strictly match the keys in HealthData.toMap()
        await db.execute('''
          CREATE TABLE health_data(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            score INTEGER,
            insight_text TEXT,
            date TEXT
          )
        ''');
        
        // Table for AI Analyses (Analyze Screen)
        // Columns strictly match the keys in SymptomLog.toMap()
        await db.execute('''
          CREATE TABLE symptom_logs(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            symptom TEXT,
            severity INTEGER,
            analysis TEXT,
            timestamp TEXT
          )
        ''');
      },
    );
  }

  // ==========================================
  // --- Health Data Methods ---
  // ==========================================
  
  Future<void> saveHealthData(HealthData healthData) async {
    final db = await database;
    await db.insert(
      'health_data', 
      healthData.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<HealthData?> getLatestHealthData() async {
    final db = await database;
    final maps = await db.query(
      'health_data',
      orderBy: 'date DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return HealthData.fromMap(maps.first);
    }
    return null;
  }

  // ==========================================
  // --- Symptom Log Methods ---
  // ==========================================
  
  Future<void> saveSymptomLog(SymptomLog symptomLog) async {
    final db = await database;
    await db.insert(
      'symptom_logs', 
      symptomLog.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SymptomLog>> getAllSymptomLogs() async {
    final db = await database;
    final maps = await db.query('symptom_logs', orderBy: 'timestamp DESC');
    
    return List.generate(maps.length, (i) => SymptomLog.fromMap(maps[i]));
  }

  // ==========================================
  // --- Utility Methods ---
  // ==========================================
  
  /// Generic QueryAll for Repository flexibility
  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await database;
    return await db.query(table, orderBy: 'id DESC');
  }

  /// Delete a specific symptom log (Useful for a "swipe to delete" UI feature)
  Future<int> deleteSymptomLog(int id) async {
    final db = await database;
    return await db.delete(
      'symptom_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}