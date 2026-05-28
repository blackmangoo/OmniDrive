import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Sends ELM327 AT commands over a WiFi TCP socket and streams vehicle speed.
///
/// OBD-II WiFi dongles create their own hotspot.
/// Connect the phone to that network, then call [connect()].
///
/// Default IP: 192.168.0.10  Port: 35000
/// (same for most ELM327 WiFi clones — Veepeak, Vgate, ScanTool, etc.)
class ObdWifiService {
  static const String _defaultHost = '192.168.0.10';
  static const int    _defaultPort = 35000;
  static const Duration _connectTimeout  = Duration(seconds: 5);
  static const Duration _commandTimeout  = Duration(milliseconds: 500);
  static const Duration _pollInterval    = Duration(milliseconds: 200); // ~5 Hz (realistic ELM327 throughput)

  Socket? _socket;
  Timer?  _pollTimer;
  String  _rxBuffer = '';

  final _speedController = StreamController<double>.broadcast();

  /// Emits vehicle speed in km/h from the ECU (OBD PID 010D).
  Stream<double> get speedStream => _speedController.stream;

  bool get isConnected => _socket != null;

  // ── Connection ─────────────────────────────────────────────────────────────

  /// Connects to the OBD-II WiFi dongle and initialises the ELM327.
  /// Throws a [SocketException] if the phone is not on the OBD WiFi network.
  Future<void> connect({
    String host = _defaultHost,
    int    port = _defaultPort,
  }) async {
    _socket = await Socket.connect(host, port, timeout: _connectTimeout);
    _socket!.encoding = const AsciiCodec(); // ELM327 is ASCII
    _socket!.listen(
      _onData,
      onError: (e) => disconnect(),
      onDone: () => disconnect(),
      cancelOnError: false,
    );

    // ELM327 initialisation sequence
    await _sendCmd('ATZ');   // soft reset
    await Future.delayed(const Duration(milliseconds: 500));
    await _sendCmd('ATE0');  // echo off
    await _sendCmd('ATL0');  // linefeed off
    await _sendCmd('ATH0');  // headers off
    await _sendCmd('ATSP0'); // auto-detect protocol

    // Start polling vehicle speed
    _startPolling();
  }

  void disconnect() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _socket?.destroy();
    _socket = null;
    _rxBuffer = '';
  }

  void dispose() {
    disconnect();
    _speedController.close();
  }

  // ── Polling ────────────────────────────────────────────────────────────────

  void _startPolling() {
    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      if (_socket == null) return;
      _socket!.write('010D\r'); // PID 010D = vehicle speed
    });
  }

  void _onData(List<int> raw) {
    _rxBuffer += String.fromCharCodes(raw);

    // ELM327 responses terminate with '>'
    while (_rxBuffer.contains('>')) {
      final idx = _rxBuffer.indexOf('>');
      final response = _rxBuffer.substring(0, idx).trim();
      _rxBuffer = _rxBuffer.substring(idx + 1);
      _parseSpeed(response);
    }
  }

  void _parseSpeed(String response) {
    // Expected format: "41 0D XX" where XX is speed in hex (km/h)
    // Strip whitespace / junk characters
    final clean = response.replaceAll(RegExp(r'[^0-9A-Fa-f\s]'), '').trim();
    final parts  = clean.split(RegExp(r'\s+'));

    // Locate '41 0D' prefix (mode 0x41 = response to mode 0x01, PID 0x0D)
    for (int i = 0; i < parts.length - 2; i++) {
      if (parts[i].toUpperCase() == '41' &&
          parts[i + 1].toUpperCase() == '0D') {
        final speedHex = parts[i + 2];
        final speed = int.tryParse(speedHex, radix: 16);
        if (speed != null && !_speedController.isClosed) {
          _speedController.add(speed.toDouble());
        }
        return;
      }
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<void> _sendCmd(String cmd) async {
    if (_socket == null) return;
    _socket!.write('$cmd\r');
    await Future.delayed(_commandTimeout);
  }
}

class AsciiCodec extends Encoding {
  const AsciiCodec();
  @override
  Converter<List<int>, String> get decoder => const AsciiDecoder();
  @override
  Converter<String, List<int>> get encoder => const AsciiEncoder();
  @override
  String get name => 'ascii';
}

class AsciiDecoder extends Converter<List<int>, String> {
  const AsciiDecoder();
  @override
  String convert(List<int> input) => String.fromCharCodes(input);
}

class AsciiEncoder extends Converter<String, List<int>> {
  const AsciiEncoder();
  @override
  List<int> convert(String input) => input.codeUnits;
}
