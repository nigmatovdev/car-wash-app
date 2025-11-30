import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/constants/api_constants.dart';
import '../../core/models/location_model.dart';

/// WebSocket event types
enum WebSocketEventType {
  locationUpdate,
  statusUpdate,
  washerAssigned,
  bookingCancelled,
  connected,
  disconnected,
  error,
}

/// WebSocket message model
class WebSocketMessage {
  final WebSocketEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  WebSocketMessage({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      type: _parseEventType(json['type'] as String? ?? ''),
      data: json['data'] as Map<String, dynamic>? ?? {},
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  static WebSocketEventType _parseEventType(String type) {
    switch (type.toLowerCase()) {
      case 'location_update':
      case 'user:locationupdate':
        return WebSocketEventType.locationUpdate;
      case 'status_update':
        return WebSocketEventType.statusUpdate;
      case 'washer_assigned':
        return WebSocketEventType.washerAssigned;
      case 'booking_cancelled':
        return WebSocketEventType.bookingCancelled;
      default:
        return WebSocketEventType.statusUpdate;
    }
  }
}

/// WebSocket service for live tracking
class WebSocketService {
  static WebSocketService? _instance;
  WebSocketChannel? _channel;
  final _messageController = StreamController<WebSocketMessage>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  
  bool _isConnected = false;
  String? _currentBookingId;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  // Singleton
  factory WebSocketService() {
    _instance ??= WebSocketService._internal();
    return _instance!;
  }

  WebSocketService._internal();

  /// Stream of WebSocket messages
  Stream<WebSocketMessage> get messageStream => _messageController.stream;

  /// Stream of connection status
  Stream<bool> get connectionStream => _connectionController.stream;

  /// Check if connected
  bool get isConnected => _isConnected;

  /// Connect to WebSocket for a specific booking
  Future<void> connect(String bookingId, {String? token}) async {
    if (_isConnected && _currentBookingId == bookingId) {
      return; // Already connected to this booking
    }

    // Disconnect from previous connection
    await disconnect();

    _currentBookingId = bookingId;
    _reconnectAttempts = 0;

    await _establishConnection(bookingId, token);
  }

  Future<void> _establishConnection(String bookingId, String? token) async {
    try {
      final wsUrl = '${ApiConstants.wsUrl}/ws/location?bookingId=$bookingId${token != null ? '&token=$token' : ''}';
      
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
      );

      _isConnected = true;
      _connectionController.add(true);
      _startHeartbeat();

      _messageController.add(WebSocketMessage(
        type: WebSocketEventType.connected,
        data: {'bookingId': bookingId},
      ));
    } catch (e) {
      _handleError(e);
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final wsMessage = WebSocketMessage.fromJson(data);
      _messageController.add(wsMessage);
    } catch (e) {
      // Invalid message format, ignore
    }
  }

  void _handleError(dynamic error) {
    _isConnected = false;
    _connectionController.add(false);
    
    _messageController.add(WebSocketMessage(
      type: WebSocketEventType.error,
      data: {'error': error.toString()},
    ));

    _attemptReconnect();
  }

  void _handleDone() {
    _isConnected = false;
    _connectionController.add(false);
    
    _messageController.add(WebSocketMessage(
      type: WebSocketEventType.disconnected,
      data: {},
    ));

    _attemptReconnect();
  }

  void _attemptReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      Duration(seconds: 2 * (_reconnectAttempts + 1)),
      () {
        if (_currentBookingId != null) {
          _reconnectAttempts++;
          _establishConnection(_currentBookingId!, null);
        }
      },
    );
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (_isConnected) {
          sendMessage({'type': 'ping'});
        }
      },
    );
  }

  /// Send a message through WebSocket
  void sendMessage(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode(message));
    }
  }

  /// Send location update
  void sendLocationUpdate(LocationModel location) {
    sendMessage({
      'type': 'location_update',
      'data': {
        'latitude': location.latitude,
        'longitude': location.longitude,
        'timestamp': location.timestamp?.toIso8601String() ?? DateTime.now().toIso8601String(),
      },
    });
  }

  /// Disconnect from WebSocket
  Future<void> disconnect() async {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    
    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }

    _isConnected = false;
    _currentBookingId = null;
    _connectionController.add(false);
  }

  /// Dispose the service
  void dispose() {
    disconnect();
    _messageController.close();
    _connectionController.close();
    _instance = null;
  }
}

