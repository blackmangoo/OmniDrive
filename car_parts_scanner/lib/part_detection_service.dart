import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'car_part.dart';

class PartDetectionResult {
  final CarPart? part;
  final double confidence;
  final String? error;
  final List<Map<String, dynamic>>? allPredictions;
  final double? inferenceTimeMs;
  final String? scanImageUrl; // URL of the image saved to Supabase Storage

  PartDetectionResult({
    this.part,
    required this.confidence,
    this.error,
    this.allPredictions,
    this.inferenceTimeMs,
    this.scanImageUrl,
  });
}

class PartDetectionService {
  // ─── API Configuration ───────────────────────────────────────────────────
  // Update this to your PC's local WiFi IP (run `ipconfig` to find it)
  static const String _baseUrl = 'http://172.20.10.13:8000';
  static const String _predictUrl = '$_baseUrl/predict';
  static const String _storageBucket = 'scan_images';
  // ─────────────────────────────────────────────────────────────────────────

  /// Quick health check — returns true if API is reachable and model is loaded.
  Future<bool> checkApiHealth() async {
    try {
      final resp = await http
          .get(Uri.parse(_baseUrl))
          .timeout(const Duration(seconds: 4));
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        return json['model_loaded'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Uploads [imageFile] to Supabase Storage and inserts a `scan_history` row.
  /// Called fire-and-forget after a confident prediction — does NOT block the UI.
  Future<String?> _saveScanHistory({
    required File imageFile,
    required String predictedClass,
    required double confidence,
    required double inferenceTimeMs,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${predictedClass.replaceAll(' ', '_')}.jpg';

      // Upload image bytes to Supabase Storage
      final imageBytes = await imageFile.readAsBytes();
      await supabase.storage.from(_storageBucket).uploadBinary(
            fileName,
            imageBytes,
            fileOptions:
                const FileOptions(contentType: 'image/jpeg', upsert: false),
          );

      // Get the public URL
      final imageUrl =
          supabase.storage.from(_storageBucket).getPublicUrl(fileName);

      // Insert record to scan_history
      await supabase.from('scan_history').insert({
        'image_url': imageUrl,
        'predicted_class': predictedClass,
        'confidence': confidence,
        'inference_time_ms': inferenceTimeMs,
        // 'user_id' left null until Phase 1.5 auth is added
      });

      return imageUrl;
    } catch (e) {
      // Non-critical — log but don't surface to user
      // ignore: avoid_print
      print('[ScanHistory] Failed to save scan: $e');
      return null;
    }
  }

  /// Sends [imageFile] to the YOLO11 FastAPI backend, then queries Supabase
  /// for the matched car part record. On success (confidence ≥ 60%) also
  /// saves the image + result to Supabase scan_history.
  Future<PartDetectionResult> analyzeAndFetchPart(File imageFile) async {
    try {
      // 1. Send image to FastAPI YOLO11 server
      final request =
          http.MultipartRequest('POST', Uri.parse(_predictUrl));
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        return PartDetectionResult(
          confidence: 0,
          error:
              'Server Error ${response.statusCode} — Make sure the API is running!',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final String predictedClass = json['top_prediction'] as String;
      final double confidence =
          (json['top_confidence'] as num).toDouble();
      final double inferenceMs =
          (json['inference_time_ms'] as num).toDouble();
      final List<Map<String, dynamic>> allPredictions =
          (json['all_predictions'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();

      // ── Confidence gate ────────────────────────────────────────────────
      // Reject predictions below 60% — saves Supabase quota + avoids bad data
      if (confidence < 60.0) {
        return PartDetectionResult(
          confidence: confidence,
          allPredictions: allPredictions,
          inferenceTimeMs: inferenceMs,
          error: 'Low confidence (${confidence.toStringAsFixed(1)}%) — '
              'fill the frame with the part, ensure good lighting, and hold steady.',
        );
      }

      // 2. Save scan image + result to Supabase (fire-and-forget, non-blocking)
      final scanImageUrl = await _saveScanHistory(
        imageFile: imageFile,
        predictedClass: predictedClass,
        confidence: confidence,
        inferenceTimeMs: inferenceMs,
      );

      // 3. Query Supabase for the database record
      final data = await Supabase.instance.client
          .from('car_parts')
          .select()
          .eq('class_name', predictedClass)
          .maybeSingle();

      if (data == null) {
        return PartDetectionResult(
          confidence: confidence,
          allPredictions: allPredictions,
          inferenceTimeMs: inferenceMs,
          scanImageUrl: scanImageUrl,
          error:
              'AI identified "$predictedClass" (${confidence.toStringAsFixed(1)}%) '
              'but it\'s not yet in the database.',
        );
      }

      // 4. Return unified result
      return PartDetectionResult(
        part: CarPart.fromJson(data),
        confidence: confidence,
        allPredictions: allPredictions,
        inferenceTimeMs: inferenceMs,
        scanImageUrl: scanImageUrl,
      );
    } on SocketException {
      return PartDetectionResult(
          confidence: 0,
          error: 'Cannot reach server — check WiFi and API IP address.');
    } catch (e) {
      return PartDetectionResult(
          confidence: 0, error: 'Unexpected error: $e');
    }
  }
}
