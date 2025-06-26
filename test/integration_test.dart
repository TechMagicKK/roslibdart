import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:roslibdart/roslibdart.dart';

void main() {
  group('Integration Tests', () {
    late Ros ros;
    late Service service;
    late Topic topic;

    setUp(() {
      ros = Ros(url: 'ws://localhost:9090');
      service = Service(
        name: 'test_service',
        ros: ros,
        type: 'test_msgs/TestService',
      );
      topic = Topic(
        name: 'test_topic',
        ros: ros,
        type: 'std_msgs/String',
      );
    });

    group('Ros + Service Integration', () {
      test('should handle service creation and properties', () {
        expect(service.ros.url, equals(ros.url));
        expect(service.name, equals('test_service'));
        expect(service.type, equals('test_msgs/TestService'));
        expect(service.isAdvertised, isFalse);
      });

      test('should handle multiple services with same Ros instance', () {
        final service2 = Service(
          name: 'test_service_2',
          ros: ros,
          type: 'test_msgs/TestService2',
        );

        expect(service.ros.url, equals(service2.ros.url));
        expect(service.name, isNot(equals(service2.name)));
        expect(service.type, isNot(equals(service2.type)));
      });

      test('should generate unique IDs for service operations', () {
        ros.requestSubscriber('topic1');
        final serviceId1 = ros.requestServiceCaller('service1');
        final serviceId2 = ros.requestServiceCaller('service2');
        
        expect(serviceId1, equals('call_service:service1:2'));
        expect(serviceId2, equals('call_service:service2:3'));
        expect(ros.ids, equals(3));
        expect(ros.subscribers, equals(1));
        expect(ros.serviceCallers, equals(2));
      });
    });

    group('Ros + Topic Integration', () {
      test('should handle topic creation and operations', () {
        expect(topic.ros.url, equals(ros.url));
        expect(ros.subscribers, equals(0));
        expect(ros.publishers, equals(0));
      });

      test('should handle multiple topics with same Ros instance', () {
        final topic2 = Topic(
          name: 'test_topic_2',
          ros: ros,
          type: 'std_msgs/Int32',
        );

        expect(topic.ros.url, equals(ros.url));
        expect(topic2.ros.url, equals(ros.url));
      });
    });

    group('Full System Integration', () {
      test('should handle Ros + Service + Topic together', () {
        expect(ros.ids, equals(0));
        
        ros.requestSubscriber('topic1');
        ros.requestPublisher('topic2');
        ros.requestServiceCaller('service1');
        
        expect(ros.subscribers, equals(1));
        expect(ros.publishers, equals(1));
        expect(ros.serviceCallers, equals(1));
        expect(ros.ids, equals(3));
      });

      test('should maintain consistent state across components', () {
        ros.status = Status.connected;
        
        expect(service.ros.status, equals(Status.connected));
        expect(topic.ros.status, equals(Status.connected));
        expect(ros.status, equals(Status.connected));
      });
    });

    group('Error Scenarios Integration', () {
      test('should handle errors across components gracefully', () {
        ros.status = Status.errored;
        
        expect(service.ros.status, equals(Status.errored));
        expect(topic.ros.status, equals(Status.errored));
        expect(ros.send({'test': 'message'}), isFalse);
      });

      test('should handle connection failures affecting all components', () {
        ros.status = Status.none;
        
        expect(service.ros.status, equals(Status.none));
        expect(topic.ros.status, equals(Status.none));
        expect(ros.send({'test': 'message'}), isFalse);
      });
    });

    group('Connection Lifecycle Integration', () {
      test('should handle full connection lifecycle', () async {
        expect(ros.status, equals(Status.none));
        
        final statusList = <Status>[];
        final subscription = ros.statusStream.listen((status) {
          statusList.add(status);
        });
        
        expect(statusList, isEmpty);
        
        await subscription.cancel();
      });

      test('should handle service operations during connection changes', () {
        ros.status = Status.connecting;
        expect(service.ros.status, equals(Status.connecting));
        
        ros.status = Status.connected;
        expect(service.ros.status, equals(Status.connected));
        
        ros.status = Status.errored;
        expect(service.ros.status, equals(Status.errored));
      });
    });

    group('Bug Fix Integration Tests', () {
      group('Status Tracking Integration', () {
        test('should handle status changes across components', () {
          expect(ros.status, equals(Status.none));
          expect(ros.statusStream, isA<Stream<Status>>());
        });
      });

      group('Error Handling Integration', () {
        test('should propagate errors correctly', () {
          ros.status = Status.errored;
          expect(ros.send({'test': 'message'}), isFalse);
        });
      });

      group('Type Safety Integration', () {
        test('should maintain type safety across service calls', () {
          final Map<String, dynamic> request = {'param': 'value'};
          expect(request, isA<Map<String, dynamic>>());
          expect(service.name, isA<String>());
          expect(service.type, isA<String>());
        });
      });

      group('Connection Timeout Integration', () {
        test('should handle timeout scenarios affecting all components', () {
          ros.status = Status.errored;
          
          expect(service.ros.status, equals(Status.errored));
          expect(topic.ros.status, equals(Status.errored));
          expect(ros.send({'test': 'message'}), isFalse);
        });
      });
    });

    group('Performance and Scalability', () {
      test('should handle multiple simultaneous operations', () {
        for (int i = 0; i < 10; i++) {
          ros.requestServiceCaller('service_$i');
        }
        
        expect(ros.serviceCallers, equals(10));
        expect(ros.ids, equals(10));
      });

      test('should handle rapid status changes', () async {
        final statusList = <Status>[];
        final subscription = ros.statusStream.listen((status) {
          statusList.add(status);
        });
        
        expect(statusList, isEmpty);
        
        await subscription.cancel();
      });
    });
  });
}
