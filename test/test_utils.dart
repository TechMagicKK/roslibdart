import 'dart:async';
import 'dart:convert';
import 'package:mockito/mockito.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:roslibdart/roslibdart.dart';

import 'ros_test.mocks.dart';

class TestUtils {
  static MockWebSocketChannel createMockWebSocketChannel() {
    final mockChannel = MockWebSocketChannel();
    final mockSink = MockWebSocketSink();
    final streamController = StreamController<dynamic>.broadcast();
    
    when(mockChannel.stream).thenAnswer((_) => streamController.stream);
    when(mockChannel.sink).thenReturn(mockSink);
    
    return mockChannel;
  }

  static StreamController<Map<String, dynamic>> createMockRosStream() {
    return StreamController<Map<String, dynamic>>.broadcast();
  }

  static Map<String, dynamic> createTestMessage({
    String? id,
    String? op,
    Map<String, dynamic>? values,
    bool? result,
  }) {
    return {
      if (id != null) 'id': id,
      if (op != null) 'op': op,
      if (values != null) 'values': values,
      if (result != null) 'result': result,
    };
  }

  static Map<String, dynamic> createServiceCallMessage({
    required String id,
    Map<String, dynamic>? values,
    bool result = true,
  }) {
    return {
      'id': id,
      'result': result,
      if (values != null) 'values': values,
    };
  }

  static Map<String, dynamic> createTopicMessage({
    required String topic,
    required Map<String, dynamic> msg,
  }) {
    return {
      'op': 'publish',
      'topic': topic,
      'msg': msg,
    };
  }

  static Future<List<T>> collectStreamValues<T>(
    Stream<T> stream, {
    int count = 1,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final values = <T>[];
    final completer = Completer<List<T>>();
    late StreamSubscription<T> subscription;
    
    subscription = stream.listen(
      (value) {
        values.add(value);
        if (values.length >= count) {
          subscription.cancel();
          completer.complete(values);
        }
      },
      onError: (error) {
        subscription.cancel();
        completer.completeError(error);
      },
    );
    
    Timer(timeout, () {
      if (!completer.isCompleted) {
        subscription.cancel();
        completer.complete(values);
      }
    });
    
    return completer.future;
  }

  static Future<void> simulateConnectionSequence(
    Ros ros,
    MockWebSocketChannel mockChannel,
    StreamController<dynamic> streamController, {
    bool shouldSucceed = true,
    Duration delay = const Duration(milliseconds: 100),
  }) async {
    await Future.delayed(delay);
    
    if (shouldSucceed) {
      streamController.add(json.encode({'op': 'status', 'level': 'info'}));
    } else {
      streamController.addError('Connection failed');
    }
  }

  static Future<void> simulateServiceResponse(
    StreamController<Map<String, dynamic>> streamController,
    String callId, {
    Map<String, dynamic>? responseValues,
    bool success = true,
    Duration delay = const Duration(milliseconds: 50),
  }) async {
    await Future.delayed(delay);
    
    streamController.add({
      'id': callId,
      'result': success,
      'values': responseValues ?? {'response': 'success'},
    });
  }

  static Future<void> simulateError(
    StreamController streamController, {
    String error = 'Test error',
    Duration delay = const Duration(milliseconds: 50),
  }) async {
    await Future.delayed(delay);
    streamController.addError(error);
  }

  static Map<String, dynamic> createAuthMessage({
    required String mac,
    required String client,
    required String dest,
    required String rand,
    required DateTime t,
    required String level,
    required DateTime end,
  }) {
    return {
      'mac': mac,
      'client': client,
      'dest': dest,
      'rand': rand,
      't': t.millisecondsSinceEpoch,
      'level': level,
      'end': end.millisecondsSinceEpoch,
    };
  }

  static Map<String, dynamic> createSetLevelMessage({
    String? level,
    int? id,
  }) {
    return {
      'op': 'set_level',
      'level': level,
      'id': id,
    };
  }

  static void verifyMessageSent(
    MockWebSocketSink mockSink,
    Map<String, dynamic> expectedMessage,
  ) {
    verify(mockSink.add(json.encode(expectedMessage))).called(1);
  }

  static void verifyNoMessageSent(MockWebSocketSink mockSink) {
    verifyNever(mockSink.add(any));
  }

  static Future<void> waitForAsync([Duration delay = const Duration(milliseconds: 10)]) {
    return Future.delayed(delay);
  }

  static String generateTestId(String prefix, String name, int count) {
    return '$prefix:$name:$count';
  }

  static bool isValidRosMessage(dynamic message) {
    if (message is! String) return false;
    
    try {
      final decoded = json.decode(message);
      return decoded is Map<String, dynamic>;
    } catch (e) {
      return false;
    }
  }

  static Map<String, dynamic> parseRosMessage(String message) {
    return json.decode(message) as Map<String, dynamic>;
  }
}

class StatusCollector {
  final List<Status> _statuses = [];
  late StreamSubscription<Status> _subscription;
  
  StatusCollector(Stream<Status> statusStream) {
    _subscription = statusStream.listen((status) {
      _statuses.add(status);
    });
  }
  
  List<Status> get statuses => List.unmodifiable(_statuses);
  
  Status? get latest => _statuses.isEmpty ? null : _statuses.last;
  
  bool hasStatus(Status status) => _statuses.contains(status);
  
  int countStatus(Status status) => _statuses.where((s) => s == status).length;
  
  void clear() => _statuses.clear();
  
  Future<void> dispose() async {
    await _subscription.cancel();
  }
  
  Future<Status> waitForStatus(Status expectedStatus, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (_statuses.contains(expectedStatus)) {
      return expectedStatus;
    }
    
    final completer = Completer<Status>();
    late StreamSubscription<Status> subscription;
    
    subscription = _subscription.asFuture().asStream().listen((status) {
      if (status == expectedStatus) {
        subscription.cancel();
        completer.complete(status);
      }
    });
    
    Timer(timeout, () {
      if (!completer.isCompleted) {
        subscription.cancel();
        completer.completeError(TimeoutException('Timeout waiting for status $expectedStatus', timeout));
      }
    });
    
    return completer.future;
  }
}

class MockRosBuilder {
  String? _url;
  Status _status = Status.none;
  int _subscribers = 0;
  int _advertisers = 0;
  int _publishers = 0;
  int _serviceCallers = 0;
  
  MockRosBuilder withUrl(String url) {
    _url = url;
    return this;
  }
  
  MockRosBuilder withStatus(Status status) {
    _status = status;
    return this;
  }
  
  MockRosBuilder withSubscribers(int count) {
    _subscribers = count;
    return this;
  }
  
  MockRosBuilder withAdvertisers(int count) {
    _advertisers = count;
    return this;
  }
  
  MockRosBuilder withPublishers(int count) {
    _publishers = count;
    return this;
  }
  
  MockRosBuilder withServiceCallers(int count) {
    _serviceCallers = count;
    return this;
  }
  
  Ros build() {
    final ros = Ros(url: _url);
    ros.status = _status;
    ros.subscribers = _subscribers;
    ros.advertisers = _advertisers;
    ros.publishers = _publishers;
    ros.serviceCallers = _serviceCallers;
    return ros;
  }
}
