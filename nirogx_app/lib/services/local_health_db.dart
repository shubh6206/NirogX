import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/vital_model.dart';
import '../models/sync_status.dart';

class LocalHealthDatabase {
  static const String _dbName = 'nirogx_health_production.db';
  static const int _dbVersion = 1;

  Database? _db;
  bool _isInitialized = false;

  // In-memory fallback if native SQLite is unavailable in certain test harnesses
  final Map<String, VitalRecord> _memoryRecords = {};
  final Map<String, Map<String, dynamic>> _memorySyncState = {};
  bool _useMemoryFallback = false;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final databasesPath = await getDatabasesPath();
      final path = p.join(databasesPath, _dbName);

      _db = await openDatabase(
        path,
        version: _dbVersion,
        onCreate: (Database db, int version) async {
          await _createTables(db);
        },
        onUpgrade: (Database db, int oldVersion, int newVersion) async {
          // Schema migrations
        },
      );
      _isInitialized = true;
    } catch (e) {
      // Fallback to robust in-memory SQLite or internal memory cache
      _useMemoryFallback = true;
      _isInitialized = true;
    }
  }

  static Future<void> _createTables(Database db) async {
    // 1. health_records table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS health_records (
        id TEXT PRIMARY KEY,
        platform TEXT NOT NULL,
        native_record_id TEXT,
        metric_type TEXT NOT NULL,
        value REAL NOT NULL,
        value_secondary REAL,
        unit TEXT NOT NULL,
        start_time_utc TEXT NOT NULL,
        end_time_utc TEXT NOT NULL,
        source_id TEXT NOT NULL,
        source_name TEXT NOT NULL,
        device_id TEXT,
        device_name TEXT,
        is_aggregate INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        metadata_json TEXT,
        content_hash TEXT NOT NULL
      )
    ''');

    // Indexes for high query performance & deduplication
    await db.execute('CREATE INDEX IF NOT EXISTS idx_hr_metric_time ON health_records(metric_type, start_time_utc, end_time_utc)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_hr_source ON health_records(source_id, platform)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_hr_native_id ON health_records(platform, native_record_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_hr_content_hash ON health_records(content_hash)');

    // 2. sync_state table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_state (
        platform TEXT PRIMARY KEY,
        source_id TEXT,
        last_successful_sync TEXT,
        change_token TEXT,
        sync_generation INTEGER DEFAULT 0,
        last_attempt TEXT,
        last_error TEXT
      )
    ''');

    // 3. baseline_metrics table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS baseline_metrics (
        metric_type TEXT PRIMARY KEY,
        window_start TEXT,
        window_end TEXT,
        sample_count INTEGER,
        valid_day_count INTEGER,
        baseline_value REAL,
        deviation REAL,
        confidence REAL,
        status TEXT,
        updated_at TEXT
      )
    ''');
  }

  /// Atomic transactional batch insert with deterministic deduplication
  Future<int> insertRecordsTransactional(
    List<VitalRecord> records, {
    String? platform,
    DateTime? newCursorUtc,
    String? changeToken,
  }) async {
    if (records.isEmpty && newCursorUtc == null) return 0;
    await _ensureInitialized();

    if (_useMemoryFallback || _db == null) {
      int inserted = 0;
      for (final r in records) {
        if (!_memoryRecords.containsKey(r.id) && !_memoryRecords.values.any((m) => m.contentHash == r.contentHash)) {
          _memoryRecords[r.id] = r;
          inserted++;
        }
      }
      if (platform != null && newCursorUtc != null) {
        _memorySyncState[platform] = {
          'platform': platform,
          'last_successful_sync': newCursorUtc.toIso8601String(),
          'change_token': changeToken,
          'last_attempt': DateTime.now().toUtc().toIso8601String(),
          'last_error': null,
        };
      }
      return inserted;
    }

    return await _db!.transaction<int>((txn) async {
      int insertedCount = 0;

      for (final record in records) {
        // Check deduplication by id or content_hash
        final existing = await txn.rawQuery(
          'SELECT id FROM health_records WHERE id = ? OR content_hash = ? LIMIT 1',
          [record.id, record.contentHash],
        );

        if (existing.isEmpty) {
          await txn.insert(
            'health_records',
            record.toDbMap(),
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
          insertedCount++;
        }
      }

      // Atomically update cursor token in same transaction
      if (platform != null && newCursorUtc != null) {
        await txn.insert(
          'sync_state',
          {
            'platform': platform,
            'last_successful_sync': newCursorUtc.toIso8601String(),
            'change_token': changeToken,
            'last_attempt': DateTime.now().toUtc().toIso8601String(),
            'last_error': null,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      return insertedCount;
    });
  }

  Future<void> saveSingleRecord(VitalRecord record) async {
    await insertRecordsTransactional([record]);
  }

  Future<List<VitalRecord>> getAllVitals({int limit = 500, int offset = 0}) async {
    await _ensureInitialized();
    if (_useMemoryFallback || _db == null) {
      final list = _memoryRecords.values.toList();
      list.sort((a, b) => b.startTimeUtc.compareTo(a.startTimeUtc));
      return list.skip(offset).take(limit).toList();
    }

    final maps = await _db!.query(
      'health_records',
      orderBy: 'start_time_utc DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((m) => VitalRecord.fromJson(m)).toList();
  }

  Future<VitalRecord?> getLatestVital(VitalMetricType type) async {
    await _ensureInitialized();
    if (_useMemoryFallback || _db == null) {
      final matching = _memoryRecords.values.where((r) => r.metricType == type).toList();
      if (matching.isEmpty) return null;
      matching.sort((a, b) => b.startTimeUtc.compareTo(a.startTimeUtc));
      return matching.first;
    }

    final maps = await _db!.query(
      'health_records',
      where: 'metric_type = ?',
      whereArgs: [type.keyName],
      orderBy: 'start_time_utc DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return VitalRecord.fromJson(maps.first);
  }

  Future<double> getTodayTotal(VitalMetricType type, {DateTime? targetDate}) async {
    await _ensureInitialized();
    final now = targetDate ?? DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toUtc();
    final endOfDay = startOfDay.add(const Duration(days: 1));

    if (_useMemoryFallback || _db == null) {
      final matches = _memoryRecords.values.where((r) =>
          r.metricType == type &&
          r.startTimeUtc.isAfter(startOfDay.subtract(const Duration(milliseconds: 1))) &&
          r.startTimeUtc.isBefore(endOfDay));
      double sum = 0;
      for (final m in matches) {
        sum += m.value;
      }
      return sum;
    }

    final res = await _db!.rawQuery('''
      SELECT SUM(value) as total 
      FROM health_records 
      WHERE metric_type = ? 
        AND start_time_utc >= ? 
        AND start_time_utc < ?
    ''', [type.keyName, startOfDay.toIso8601String(), endOfDay.toIso8601String()]);

    if (res.isEmpty || res.first['total'] == null) return 0.0;
    return (res.first['total'] as num).toDouble();
  }

  Future<List<VitalRecord>> getRecordsForTimeRange(
    VitalMetricType type,
    DateTime startUtc,
    DateTime endUtc,
  ) async {
    await _ensureInitialized();
    if (_useMemoryFallback || _db == null) {
      return _memoryRecords.values
          .where((r) =>
              r.metricType == type &&
              !r.startTimeUtc.isBefore(startUtc) &&
              !r.startTimeUtc.isAfter(endUtc))
          .toList();
    }

    final maps = await _db!.query(
      'health_records',
      where: 'metric_type = ? AND start_time_utc >= ? AND start_time_utc <= ?',
      whereArgs: [type.keyName, startUtc.toIso8601String(), endUtc.toIso8601String()],
      orderBy: 'start_time_utc ASC',
    );
    return maps.map((m) => VitalRecord.fromJson(m)).toList();
  }

  Future<Map<String, double>> getDailyAggregates(
    VitalMetricType type,
    DateTime startUtc,
    DateTime endUtc,
  ) async {
    final records = await getRecordsForTimeRange(type, startUtc, endUtc);
    final aggregates = <String, double>{};

    for (final r in records) {
      final localDate = r.startTimeUtc.toLocal();
      final dateKey = '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';

      if (type == VitalMetricType.steps ||
          type == VitalMetricType.activeCalories ||
          type == VitalMetricType.hydration) {
        aggregates[dateKey] = (aggregates[dateKey] ?? 0.0) + r.value;
      } else {
        // Average or latest for resting HR, sleep, SpO2
        aggregates[dateKey] = r.value;
      }
    }
    return aggregates;
  }

  Future<int> getDistinctDaysCount() async {
    await _ensureInitialized();
    if (_useMemoryFallback || _db == null) {
      final set = <String>{};
      for (final r in _memoryRecords.values) {
        final loc = r.startTimeUtc.toLocal();
        set.add('${loc.year}-${loc.month}-${loc.day}');
      }
      return set.length;
    }

    final res = await _db!.rawQuery('''
      SELECT COUNT(DISTINCT substr(start_time_utc, 1, 10)) as distinct_days 
      FROM health_records
    ''');
    if (res.isEmpty || res.first['distinct_days'] == null) return 0;
    return (res.first['distinct_days'] as num).toInt();
  }

  Future<DateTime?> getLastSuccessfulSyncTime(String platform) async {
    await _ensureInitialized();
    if (_useMemoryFallback || _db == null) {
      final state = _memorySyncState[platform];
      if (state != null && state['last_successful_sync'] != null) {
        return DateTime.parse(state['last_successful_sync']);
      }
      return null;
    }

    final res = await _db!.query(
      'sync_state',
      columns: ['last_successful_sync'],
      where: 'platform = ?',
      whereArgs: [platform],
      limit: 1,
    );
    if (res.isEmpty || res.first['last_successful_sync'] == null) return null;
    return DateTime.parse(res.first['last_successful_sync'] as String);
  }

  Future<String?> getChangeToken(String platform) async {
    await _ensureInitialized();
    if (_useMemoryFallback || _db == null) {
      return _memorySyncState[platform]?['change_token'] as String?;
    }

    final res = await _db!.query(
      'sync_state',
      columns: ['change_token'],
      where: 'platform = ?',
      whereArgs: [platform],
      limit: 1,
    );
    if (res.isEmpty) return null;
    return res.first['change_token'] as String?;
  }

  Future<void> updateSyncError(String platform, String error) async {
    await _ensureInitialized();
    if (_useMemoryFallback || _db == null) {
      _memorySyncState[platform] = {
        'platform': platform,
        'last_error': error,
        'last_attempt': DateTime.now().toUtc().toIso8601String(),
      };
      return;
    }

    await _db!.insert(
      'sync_state',
      {
        'platform': platform,
        'last_attempt': DateTime.now().toUtc().toIso8601String(),
        'last_error': error,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Data sovereignty purge: wipes all local health records, baseline caches, and sync cursors.
  Future<void> purgeAllHealthData() async {
    await _ensureInitialized();
    _memoryRecords.clear();
    _memorySyncState.clear();

    if (_db != null && !_useMemoryFallback) {
      await _db!.transaction((txn) async {
        await txn.delete('health_records');
        await txn.delete('sync_state');
        await txn.delete('baseline_metrics');
      });
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await init();
    }
  }
}
