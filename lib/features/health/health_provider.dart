import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kStepGoal = 'health_step_goal';
const _kStepsBase = 'health_steps_base';
const _kStepsBaseDate = 'health_steps_base_date';
const _kManualCalories = 'health_manual_calories_';

class HealthState {
  final int stepsToday;
  final int stepGoal;
  final double caloriesBurnt;
  final int manualCalories;
  final bool isAvailable;
  final bool permissionDenied;

  const HealthState({
    this.stepsToday = 0,
    this.stepGoal = 8000,
    this.caloriesBurnt = 0,
    this.manualCalories = 0,
    this.isAvailable = false,
    this.permissionDenied = false,
  });

  int get totalCalories => caloriesBurnt.round() + manualCalories;

  double get stepProgress =>
      stepGoal == 0 ? 0 : (stepsToday / stepGoal).clamp(0.0, 1.0);

  HealthState copyWith({
    int? stepsToday,
    int? stepGoal,
    double? caloriesBurnt,
    int? manualCalories,
    bool? isAvailable,
    bool? permissionDenied,
  }) {
    return HealthState(
      stepsToday: stepsToday ?? this.stepsToday,
      stepGoal: stepGoal ?? this.stepGoal,
      caloriesBurnt: caloriesBurnt ?? this.caloriesBurnt,
      manualCalories: manualCalories ?? this.manualCalories,
      isAvailable: isAvailable ?? this.isAvailable,
      permissionDenied: permissionDenied ?? this.permissionDenied,
    );
  }
}

class HealthNotifier extends StateNotifier<HealthState> {
  HealthNotifier() : super(const HealthState()) {
    _init();
  }

  StreamSubscription<StepCount>? _stepSub;
  SharedPreferences? _prefs;

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    final goal = _prefs!.getInt(_kStepGoal) ?? 8000;
    final manualCals = _prefs!.getInt('$_kManualCalories$_todayKey') ?? 0;

    state = state.copyWith(
      stepGoal: goal,
      manualCalories: manualCals,
    );

    await _startPedometer();
  }

  Future<void> _startPedometer() async {
    try {
      final status = await Permission.activityRecognition.request();
      if (!status.isGranted) {
        state = state.copyWith(
          isAvailable: false,
          permissionDenied: true,
        );
        return;
      }

      // Listen to step count stream
      _stepSub = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepError,
        cancelOnError: false,
      );

      // MIUI fix: also try reading step count immediately
      // by triggering a dummy listen to force the sensor awake
      await Future.delayed(const Duration(milliseconds: 500));

    } catch (e) {
      state = state.copyWith(isAvailable: false);
    }
  }

  void _onStepCount(StepCount event) async {
    if (_prefs == null) return;

    final today = _todayKey;
    final savedDate = _prefs!.getString(_kStepsBaseDate);
    int base = _prefs!.getInt(_kStepsBase) ?? 0;

    if (savedDate != today) {
      // New day — save current total as baseline
      base = event.steps;
      await _prefs!.setString(_kStepsBaseDate, today);
      await _prefs!.setInt(_kStepsBase, base);
    }

    final stepsToday = (event.steps - base).clamp(0, 999999);
    final calories = stepsToday * 0.04;

    state = state.copyWith(
      stepsToday: stepsToday,
      caloriesBurnt: calories,
      isAvailable: true,
    );
  }

  void _onStepError(dynamic error) {
    state = state.copyWith(isAvailable: false);
  }

  Future<void> addManualCalories(int calories) async {
    if (_prefs == null) {
      // prefs not ready yet, init it
      _prefs = await SharedPreferences.getInstance();
    }
    final current = _prefs!.getInt('$_kManualCalories$_todayKey') ?? 0;
    final updated = current + calories;
    await _prefs!.setInt('$_kManualCalories$_todayKey', updated);
    // Force state update
    state = HealthState(
      stepsToday: state.stepsToday,
      stepGoal: state.stepGoal,
      caloriesBurnt: state.caloriesBurnt,
      manualCalories: updated,
      isAvailable: state.isAvailable,
      permissionDenied: state.permissionDenied,
    );
  }

  Future<void> setStepGoal(int goal) async {
    if (_prefs == null) _prefs = await SharedPreferences.getInstance();
    await _prefs!.setInt(_kStepGoal, goal);
    state = state.copyWith(stepGoal: goal);
  }

  Future<void> resetManualCalories() async {
    if (_prefs == null) _prefs = await SharedPreferences.getInstance();
    await _prefs!.setInt('$_kManualCalories$_todayKey', 0);
    state = state.copyWith(manualCalories: 0);
  }

  @override
  void dispose() {
    _stepSub?.cancel();
    super.dispose();
  }
}

final healthProvider =
    StateNotifierProvider<HealthNotifier, HealthState>((ref) {
  return HealthNotifier();
});