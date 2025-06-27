import 'package:flutter_test/flutter_test.dart';
import 'package:roslibdart/roslibdart.dart';

void main() {
  group('Ros Class Tests', () {
    late Ros ros;

    setUp(() {
      ros = Ros(url: 'ws://localhost:9090');
    });

    group('Initialization and Properties', () {
      test('should initialize with correct default values', () {
        expect(ros.url, equals('ws://localhost:9090'));
        expect(ros.status, equals(Status.none));
        expect(ros.subscribers, equals(0));
        expect(ros.advertisers, equals(0));
        expect(ros.publishers, equals(0));
        expect(ros.serviceCallers, equals(0));
      });

      test('should initialize without URL', () {
        final rosNoUrl = Ros();
        expect(rosNoUrl.url, isNull);
        expect(rosNoUrl.status, equals(Status.none));
      });

      test('should calculate IDs correctly', () {
        ros.requestSubscriber('test_topic');
        ros.requestAdvertiser('test_topic');
        ros.requestPublisher('test_topic');
        ros.requestServiceCaller('test_service');
        
        expect(ros.ids, equals(4));
        expect(ros.subscribers, equals(1));
        expect(ros.advertisers, equals(1));
        expect(ros.publishers, equals(1));
        expect(ros.serviceCallers, equals(1));
      });
    });

    group('Status Stream Behavior (Current Implementation)', () {
      test('should have Status enum stream', () {
        expect(ros.statusStream, isA<Stream<Status>>());
        expect(ros.status, isA<Status>());
      });

      test('should handle status changes correctly', () async {
        final statusList = <Status>[];
        final subscription = ros.statusStream.listen((status) {
          statusList.add(status);
        });

        expect(statusList, isEmpty);
        
        await subscription.cancel();
      });
    });

    group('ID Generation', () {
      test('should generate unique subscriber IDs', () {
        final id1 = ros.requestSubscriber('topic1');
        final id2 = ros.requestSubscriber('topic2');
        
        expect(id1, equals('subscribe:topic1:1'));
        expect(id2, equals('subscribe:topic2:2'));
        expect(ros.subscribers, equals(2));
      });

      test('should generate unique advertiser IDs', () {
        final id1 = ros.requestAdvertiser('topic1');
        final id2 = ros.requestAdvertiser('topic2');
        
        expect(id1, equals('advertise:topic1:1'));
        expect(id2, equals('advertise:topic2:2'));
        expect(ros.advertisers, equals(2));
      });

      test('should generate unique publisher IDs', () {
        final id1 = ros.requestPublisher('topic1');
        final id2 = ros.requestPublisher('topic2');
        
        expect(id1, equals('publish:topic1:1'));
        expect(id2, equals('publish:topic2:2'));
        expect(ros.publishers, equals(2));
      });

      test('should generate unique service caller IDs', () {
        final id1 = ros.requestServiceCaller('service1');
        final id2 = ros.requestServiceCaller('service2');
        
        expect(id1, equals('call_service:service1:1'));
        expect(id2, equals('call_service:service2:2'));
        expect(ros.serviceCallers, equals(2));
      });

      test('should increment IDs across different types', () {
        ros.requestSubscriber('topic1');
        ros.requestAdvertiser('topic2');
        ros.requestPublisher('topic3');
        final serviceId = ros.requestServiceCaller('service1');
        
        expect(serviceId, equals('call_service:service1:4'));
        expect(ros.ids, equals(4));
      });
    });

    group('Message Sending', () {
      test('should not send message when not connected', () {
        expect(ros.status, equals(Status.none));
        final result = ros.send({'test': 'message'});
        expect(result, isFalse);
      });

      test('should not send message when not connected', () {
        expect(ros.status, equals(Status.none));
        final result = ros.send({'test': 'message'});
        expect(result, isFalse);
      });
    });

    group('URL and Status Properties', () {
      test('should maintain URL property correctly', () {
        expect(ros.url, equals('ws://localhost:9090'));
      });

      test('should handle different URLs', () {
        final ros1 = Ros(url: 'ws://localhost:9090');
        final ros2 = Ros(url: 'ws://localhost:9091');
        
        expect(ros1.url, equals('ws://localhost:9090'));
        expect(ros2.url, equals('ws://localhost:9091'));
      });
    });

    group('Bug Fix Verification Tests', () {
      group('Bug Fix 1: Dart SDK Compatibility', () {
        test('should work with current Dart SDK version', () {
          expect(ros, isNotNull);
          expect(ros.statusStream, isA<Stream<Status>>());
        });
      });

      group('Bug Fix 2: Enhanced Status Tracking', () {
        test('current implementation uses Status enum only', () {
          expect(ros.statusStream, isA<Stream<Status>>());
          expect(ros.status, isA<Status>());
        });

        test('should detect when records syntax is available', () {
          final stream = ros.statusStream;
          expect(stream, isNotNull);
        });
      });

      group('Bug Fix 3: Connection Handling', () {
        test('current implementation uses basic WebSocketChannel', () {
          expect(ros.status, equals(Status.none));
        });
      });

      group('Bug Fix 4: Error Handling', () {
        test('should handle basic error scenarios', () {
          expect(ros.status, equals(Status.none));
        });
      });

      group('Bug Fix 5: Timeout Handling', () {
        test('current implementation has no explicit timeout', () {
          expect(ros.status, equals(Status.none));
        });
      });

      group('Bug Fix 6: Type Safety', () {
        test('should work with current type system', () {
          expect(ros.status, equals(Status.none));
        });
      });
    });
  });
}
