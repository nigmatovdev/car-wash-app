import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/api_constants.dart';

class WebSocketClient {
  WebSocketChannel? _channel;
  
  WebSocketChannel? get channel => _channel;
  
  // Connect to WebSocket
  Future<void> connect(String token) async {
    try {
      final uri = Uri.parse('${ApiConstants.wsUrl}?token=$token');
      _channel = WebSocketChannel.connect(uri);
    } catch (e) {
      throw Exception('Failed to connect to WebSocket: $e');
    }
  }
  
  // Send message
  void send(dynamic message) {
    if (_channel != null) {
      _channel!.sink.add(message);
    } else {
      throw Exception('WebSocket is not connected');
    }
  }
  
  // Listen to messages
  Stream<dynamic> get stream {
    if (_channel != null) {
      return _channel!.stream;
    }
    throw Exception('WebSocket is not connected');
  }
  
  // Close connection
  Future<void> close() async {
    await _channel?.sink.close();
    _channel = null;
  }
  
  // Check if connected
  bool get isConnected => _channel != null;
}

