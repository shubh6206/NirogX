import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/vital_model.dart';
import '../models/health_score_model.dart';
import '../models/sync_status.dart';
import '../models/personal_baseline.dart';
import '../models/ai_context.dart';
import '../services/health_sync_service.dart';
import '../services/local_health_db.dart';
import '../services/health_score_engine.dart';
import '../services/baseline_engine.dart';
import '../services/telemetry_service.dart';

class HealthProvider with ChangeNotifier {
  late final HealthSyncService _syncService;
  final LocalHealthDatabase _db = LocalHealthDatabase();
  final TelemetryService _telemetry = TelemetryService();

  SyncMetadata _syncMetadata = const SyncMetadata();
  HealthScoreResult? _healthScore;
  UserPersonalBaseline _personalBaseline = UserPersonalBaseline.empty();
  bool _isConnected = false;
  Timer? _staleCheckTimer;

  // In-memory cache for fast UI rendering
  List<VitalRecord> _cachedVitals = [];
  final Map<VitalMetricType, VitalRecord?> _latestVitalsCache = {};
  final Map<VitalMetricType, double> _todayTotalsCache = {};
  final List<String> _medicalHistory = [];

  SyncMetadata get syncMetadata => _syncMetadata;
  HealthScoreResult? get healthScore => _healthScore;
  UserPersonalBaseline get personalBaseline => _personalBaseline;
  bool get isConnected => _isConnected;
  bool get isSyncing => _syncMetadata.state == SyncState.syncing;
  DateTime? get lastSyncTimeUtc => _syncMetadata.lastSuccessfulSyncTimeUtc;

  List<VitalRecord> get vitals => _cachedVitals;
  List<String> get medicalHistory => List.unmodifiable(_medicalHistory);

  HealthProvider() {
    _syncService = HealthSyncService(_db);
    _init();
  }

  Future<void> _init() async {
    await _db.init();

    // Check actual permissions and stored cursor
    final platformKey = kIsWeb ? 'web' : 'health_connect';
    final lastCursor = await _db.getLastSuccessfulSyncTime(platformKey);
    final hasPerms = await _syncService.hasActivePermissions();
    _isConnected = hasPerms;

    if (lastCursor != null) {
      _syncMetadata = _syncMetadata.copyWith(
        lastSuccessfulSyncTimeUtc: lastCursor,
        state: SyncState.latestSynced,
      );
    } else {
      _syncMetadata = const SyncMetadata(
        lastSuccessfulSyncTimeUtc: null,
        state: SyncState.idle,
      );
    }

    await _refreshLocalCaches();
    await _recalculateBaseline();
    await _recalculateScore();

    // Periodic freshness timer
    _staleCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      notifyListeners();
    });

    notifyListeners();
  }

  @override
  void dispose() {
    _staleCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshLocalCaches() async {
    _cachedVitals = await _db.getAllVitals(limit: 100);
    for (final type in VitalMetricType.values) {
      _latestVitalsCache[type] = await _db.getLatestVital(type);
      _todayTotalsCache[type] = await _db.getTodayTotal(type);
    }
  }

  /// Request permissions and connect to platform
  Future<void> connectHealthPlatform() async {
    _syncMetadata = _syncMetadata.copyWith(state: SyncState.syncing);
    notifyListeners();

    final bool granted = await _syncService.requestPermissions();
    _isConnected = granted;

    if (granted) {
      final syncResult = await _syncService.performIncrementalSync();
      _syncMetadata = syncResult;
      await _refreshLocalCaches();
      await _recalculateBaseline();
      await _recalculateScore();
    } else {
      _syncMetadata = _syncMetadata.copyWith(
        state: SyncState.permissionRequired,
        lastError: 'Permission not granted by system health platform.',
      );
    }

    notifyListeners();
  }

  /// Manual foreground refresh
  Future<void> syncNow() async {
    if (!_isConnected) {
      await connectHealthPlatform();
      return;
    }

    _syncMetadata = _syncMetadata.copyWith(state: SyncState.syncing);
    notifyListeners();

    final syncResult = await _syncService.performIncrementalSync();
    _syncMetadata = syncResult;
    await _refreshLocalCaches();
    await _recalculateBaseline();
    await _recalculateScore();

    notifyListeners();
  }

  /// Disconnect without purging data
  void disconnectPlatform() {
    _isConnected = false;
    _syncMetadata = _syncMetadata.copyWith(
      state: SyncState.unavailable,
      lastError: 'Platform synchronization halted by user.',
    );
    _telemetry.logEvent('health_platform_disconnected');
    notifyListeners();
  }

  /// One-click Local Data Purge
  Future<void> purgeLocalData() async {
    await _db.purgeAllHealthData();
    _cachedVitals.clear();
    _latestVitalsCache.clear();
    _todayTotalsCache.clear();
    _syncMetadata = const SyncMetadata(state: SyncState.idle, lastSuccessfulSyncTimeUtc: null);
    _personalBaseline = UserPersonalBaseline.empty();
    _healthScore = HealthScoreResult.insufficientData();
    _telemetry.logEvent('local_health_data_purged');
    notifyListeners();
  }

  /// Manual Vital Entry
  Future<void> logManualVital(VitalMetricType type, double value, String unit) async {
    final record = VitalRecord(
      platform: 'manual',
      metricType: type,
      value: value,
      unit: unit,
      sourceName: 'Manual Entry',
      sourceId: 'manual_patient_entry',
      startTime: DateTime.now(),
    );

    await _db.saveSingleRecord(record);
    await _refreshLocalCaches();
    await _recalculateBaseline();
    await _recalculateScore();
    notifyListeners();
  }

  /// Manual Blood Pressure Log
  Future<void> logBloodPressure(int systolic, int diastolic, {int? pulse}) async {
    final record = VitalRecord(
      platform: 'manual',
      metricType: VitalMetricType.bloodPressure,
      value: systolic.toDouble(),
      valueSecondary: diastolic.toDouble(),
      unit: 'mmHg',
      sourceName: 'Manual Entry',
      sourceId: 'manual_patient_entry',
      startTime: DateTime.now(),
      metadata: pulse != null ? {'pulse': pulse} : {},
    );

    await _db.saveSingleRecord(record);
    await _refreshLocalCaches();
    await _recalculateBaseline();
    await _recalculateScore();
    notifyListeners();
  }

  /// Medical History Management
  void addMedicalCondition(String condition) {
    if (condition.trim().isNotEmpty && !_medicalHistory.contains(condition.trim())) {
      _medicalHistory.add(condition.trim());
      notifyListeners();
    }
  }

  void removeMedicalCondition(int index) {
    if (index >= 0 && index < _medicalHistory.length) {
      _medicalHistory.removeAt(index);
      notifyListeners();
    }
  }

  Future<void> _recalculateScore() async {
    _healthScore = await HealthScoreEngine.evaluate(_db, baseline: _personalBaseline);
  }

  Future<void> _recalculateBaseline() async {
    _personalBaseline = await BaselineEngine.computeBaseline(_db);
  }

  VitalRecord? getLatestVital(VitalMetricType type) => _latestVitalsCache[type];
  double getTodayTotal(VitalMetricType type) => _todayTotalsCache[type] ?? 0.0;

  /// Builds a sanitized, strictly allowlisted AI Health Context DTO
  AIHealthContext buildAIContext() {
    final hr = getLatestVital(VitalMetricType.heartRate);
    final rhr = getLatestVital(VitalMetricType.restingHeartRate);
    final sleep = getLatestVital(VitalMetricType.sleep);
    final spO2 = getLatestVital(VitalMetricType.spO2);
    final bp = getLatestVital(VitalMetricType.bloodPressure);

    return AIHealthContext(
      dailyHealthScore: _healthScore?.score,
      scoreDelta: _healthScore?.changeDelta,
      restingHeartRate: rhr?.value ?? hr?.value,
      dailySteps: getTodayTotal(VitalMetricType.steps).toInt(),
      sleepDurationHours: sleep != null ? (sleep.value / 60.0) : null,
      hydrationLiters: (getTodayTotal(VitalMetricType.hydration) / 1000.0),
      systolicBp: bp?.value.toInt(),
      diastolicBp: bp?.valueSecondary?.toInt(),
      spO2: spO2?.value,
      activeCalories: getTodayTotal(VitalMetricType.activeCalories),
      baselineStatus: _personalBaseline.statusDisplay,
      medicalHistory: _medicalHistory,
    );
  }
}
