import 'package:socket_io_client/socket_io_client.dart' as IO;

//service for real-time sync using Socket.IO and WebSocket
class SocketService {
  static IO.Socket? _socket;

//backend socket server URL
  static const String _baseUrl = 'http://10.0.2.2:3000';

  //connect to backend socket server after login
  static void connect(int userId) {
    _socket = IO.io(
      _baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    //join user-specific room after connection
    _socket!.onConnect((_) {
      print('socket connected');
      _socket!.emit('join', userId);
    });

    //triggered when socket disconnects
    _socket!.onDisconnect((_) {
      print('socket disconnected');
    });

    //handle connection errors
    _socket!.onConnectError((error) {
      print('connection error: $error');
    });
  }

  //listen for realtime updates from backend
  static void onDataUpdated(Function(dynamic) callback) {
    if (_socket == null) return;

    _socket!.on('data_updated', (data) {
      print('update received: $data');
      callback(data);
    });
  }

  //close socket connection on logout
  static void disconnect() {
    _socket?.disconnect();
    _socket = null;
    print('socket closed');
  }
}
