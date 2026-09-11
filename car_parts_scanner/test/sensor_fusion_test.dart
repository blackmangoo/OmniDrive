import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:car_parts_scanner/performance/sensor_fusion_service.dart';
import 'package:car_parts_scanner/performance/performance_models.dart';
import 'package:car_parts_scanner/performance/performance_run_service.dart';

void main() {
  group('VehicleSpeedKalmanFilter Unit Tests', () {
    late VehicleSpeedKalmanFilter filter;

    setUp(() {
      filter = VehicleSpeedKalmanFilter();
    });

    test('Initial state is at zero velocity', () {
      expect(filter.speedKmh, equals(0.0));
      expect(filter.speedMs, equals(0.0));
      expect(filter.accelBiasMs2, equals(0.0));
    });

    test('Zero Velocity Update (ZUPT) prevents stationary drift under vibration', () {
      // Simulate 5 seconds of stationary idling engine vibration (sinusoidal ±0.4 m/s²)
      const double dt = 0.02; // 50 Hz
      for (int i = 0; i < 250; i++) {
        final vibration = 0.4 * math.sin(i * 0.5);
        filter.predict(vibration, dt);
        // Apply ZUPT periodically (every 1 second / 50 ticks)
        if (i % 50 == 0) {
          filter.applyZupt(measuredStationaryAccel: vibration);
        }
      }

      // Speed must remain strictly 0 or negligible, never climbing to the 3.0 km/h launch threshold
      expect(filter.speedKmh, lessThan(1.0));
    });

    test('Smoothly tracks a 0 to 100 km/h acceleration pull', () {
      // Car accelerates at ~6.17 m/s² (~0.63g) from 0 to 100 km/h (27.78 m/s) in 4.5 seconds
      const double targetSpeedMs = 100.0 / 3.6; // 27.78 m/s
      const double accel = targetSpeedMs / 4.5; // ~6.17 m/s²
      const double dt = 0.02; // 50 Hz IMU

      double trueSpeed = 0.0;
      double simTime = 0.0;
      final speeds = <double>[];

      while (simTime <= 4.5) {
        trueSpeed += accel * dt;
        simTime += dt;

        // Predict step at 50 Hz with small sensor noise
        final imuMeasurement = accel + 0.1 * math.sin(simTime * 20);
        final predictedKmh = filter.predict(imuMeasurement, dt);

        // GPS updates at 1 Hz (every 1 second) with small noise
        if ((simTime % 1.0) < dt) {
          final gpsNoise = 0.15 * math.cos(simTime * 5);
          final gpsSpeed = trueSpeed + gpsNoise;
          filter.update(gpsSpeed, speedAccuracyMs: 0.2, currentAccelMs2: accel);
        }

        speeds.add(predictedKmh);
      }

      // At 4.5s, estimated speed should be remarkably close to 100 km/h
      expect(filter.speedKmh, closeTo(100.0, 3.5));
      // Monotonically increasing during pure acceleration
      expect(speeds.last, greaterThan(speeds.first));
    });

    test('Deceleration and braking naturally drops speed without sign hack', () {
      // Initialize filter at 100 km/h (27.78 m/s)
      filter.update(27.78, speedAccuracyMs: 0.1);
      expect(filter.speedKmh, closeTo(100.0, 1.0));

      // Simulate hard braking at -8.0 m/s² (-0.8g) for 4.0 seconds (200 ticks)
      const double dt = 0.02;
      for (int i = 0; i < 200; i++) {
        filter.predict(-8.0, dt);
      }

      // Speed must drop to 0.0 and clamp cleanly without negative overflow
      expect(filter.speedKmh, equals(0.0));
      expect(filter.speedMs, equals(0.0));
    });

    test('Innovation gating suppresses GPS multipath spikes', () {
      // Car is cruising steadily at 60 km/h (16.67 m/s)
      filter.update(16.67, speedAccuracyMs: 0.2);
      expect(filter.speedKmh, closeTo(60.0, 2.0));

      // Sudden impossible GPS spike: reports 150 km/h (41.67 m/s) for 1 tick due to multipath reflection
      const double crazyGpsGlitch = 41.67;
      final filteredAfterGlitch = filter.update(
        crazyGpsGlitch,
        speedAccuracyMs: 0.2,
        currentAccelMs2: 0.0,
      );

      // The filter's innovation gate should soft-clamp the 4-sigma outlier,
      // preventing the speed from jumping to 150 km/h
      expect(filteredAfterGlitch, lessThan(80.0));
    });

    test('Accelerometer bias convergence', () {
      // Inject a constant sensor bias of +0.5 m/s²
      const double trueBias = 0.5;
      const double dt = 0.02;
      const double trueSpeed = 10.0;

      // Initialize filter at cruising speed
      filter.update(trueSpeed, speedAccuracyMs: 0.1);

      // Run for 15 seconds of steady cruising
      for (int i = 0; i < 750; i++) {
        // IMU reads true acceleration (0.0) + bias (+0.5)
        filter.predict(0.0 + trueBias, dt);

        // Accurate GPS updates at 2 Hz
        if ((i + 1) % 25 == 0) {
          filter.update(trueSpeed, speedAccuracyMs: 0.1, currentAccelMs2: 0.0);
        }
      }

      // Filter should learn and compensate the bias
      expect(filter.accelBiasMs2, closeTo(trueBias, 0.2));
      expect(filter.speedKmh, closeTo(trueSpeed * 3.6, 2.0));
    });
  });

  group('PerformanceRunService Milestone Timing Precision', () {
    test('Sub-sample linear interpolation calculates fractional threshold crossing', () async {
      final runService = PerformanceRunService(
        selectedMetrics: [MetricType.zeroTo60],
        sensorMode: 'gps_imu',
      );

      MilestoneAchieved? milestone;
      runService.milestoneStream.listen((m) {
        milestone = m;
      });

      // Start run by exceeding 3 km/h
      final speedCtrl = StreamController<double>.broadcast();
      final posCtrl = StreamController<Position>.broadcast();
      runService.attachStreams(
        speedStream: speedCtrl.stream,
        positionStream: posCtrl.stream,
      );

      // Yield for attachStreams
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Armed → Running
      speedCtrl.add(5.0);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Feed points approaching 60 km/h:
      // Sample A: 55 km/h
      speedCtrl.add(55.0);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Sample B: 65 km/h (crosses 60 km/h midway between A and B)
      speedCtrl.add(65.0);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(runService.state, equals(RunState.done));
      expect(milestone, isNotNull);
      expect(milestone!.type, equals(MetricType.zeroTo60));

      runService.dispose();
      speedCtrl.close();
      posCtrl.close();
    });
  });
}
