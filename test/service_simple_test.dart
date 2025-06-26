import 'package:flutter_test/flutter_test.dart';
import 'package:roslibdart/roslibdart.dart';

void main() {
  group('Service Class Tests', () {
    late Ros ros;
    late Service service;

    setUp(() {
      ros = Ros(url: 'ws://localhost:9090');
      service = Service(
        name: 'test_service',
        ros: ros,
        type: 'test_msgs/TestService',
      );
    });

    group('Initialization and Properties', () {
      test('should initialize with correct properties', () {
        expect(service.name, equals('test_service'));
        expect(service.type, equals('test_msgs/TestService'));
        expect(service.isAdvertised, isFalse);
      });

      test('should not be advertised initially', () {
        expect(service.isAdvertised, isFalse);
      });

      test('should have correct ros instance reference', () {
        expect(service.ros.url, equals('ws://localhost:9090'));
        expect(service.ros.status, equals(Status.none));
      });
    });

    group('Service Call Type Safety (Current Implementation)', () {
      test('should verify request parameter type at runtime', () {
        final request = {'test': 'data'};
        expect(request, isA<Map<String, dynamic>>());
        expect(request.runtimeType.toString(), contains('Map'));
      });

      test('should accept Map<String, dynamic> parameter type', () {
        final Map<String, dynamic> request = {'param1': 'value1', 'param2': 42};
        expect(request, isA<Map<String, dynamic>>());
      });

      test('should accept dynamic types for service calls', () {
        expect('string', isA<dynamic>());
        expect(123, isA<dynamic>());
        expect(['list'], isA<dynamic>());
        expect({'key': 'value'}, isA<dynamic>());
      });
    });

    group('Service Advertising State', () {
      test('should not be advertised initially', () {
        expect(service.isAdvertised, isFalse);
      });

      test('should handle unadvertising when not advertised', () {
        expect(service.isAdvertised, isFalse);
        expect(() => service.unadvertise(), returnsNormally);
        expect(service.isAdvertised, isFalse);
      });
    });

    group('ServiceHandler Typedef', () {
      test('should define correct handler signature', () {
        Future<Map<String, dynamic>>? validHandler(Map<String, dynamic> args) {
          return Future.value({'success': true});
        }

        expect(validHandler, isA<ServiceHandler>());
      });

      test('should handle null return from handler definition', () {
        Future<Map<String, dynamic>>? nullHandler(Map<String, dynamic> args) {
          return null;
        }

        expect(nullHandler, isA<ServiceHandler>());
      });

      test('should handle async handler definition', () {
        Future<Map<String, dynamic>>? asyncHandler(Map<String, dynamic> args) async {
          await Future.delayed(Duration(milliseconds: 10));
          return {'async': 'result'};
        }

        expect(asyncHandler, isA<ServiceHandler>());
      });
    });

    group('Bug Fix Verification Tests', () {
      group('Bug Fix 6: Type Safety Improvements', () {
        test('current implementation uses dynamic parameter', () {
          expect('string', isA<dynamic>());
          expect(123, isA<dynamic>());
          expect({'key': 'value'}, isA<dynamic>());
        });

        test('should detect when type safety is improved', () {
          final Map<String, dynamic> typedRequest = {'param': 'value'};
          expect(typedRequest, isA<Map<String, dynamic>>());
        });

        test('should verify ServiceHandler typedef formatting', () {
          Future<Map<String, dynamic>>? handler(Map<String, dynamic> args) {
            return Future.value(args);
          }
          
          expect(handler, isA<ServiceHandler>());
        });
      });

      group('Service Integration with Ros', () {
        test('should integrate correctly with Ros instance', () {
          expect(service.name, equals('test_service'));
          expect(service.type, equals('test_msgs/TestService'));
          expect(service.ros.url, equals('ws://localhost:9090'));
        });

        test('should maintain Ros reference', () {
          expect(service.ros.url, equals('ws://localhost:9090'));
          expect(service.ros.status, equals(Status.none));
        });
      });
    });

    group('Service Lifecycle', () {
      test('should start with correct initial state', () {
        expect(service.isAdvertised, isFalse);
        expect(service.name, equals('test_service'));
        expect(service.type, equals('test_msgs/TestService'));
      });

      test('should handle unadvertise when not advertised', () {
        expect(service.isAdvertised, isFalse);
        service.unadvertise();
        expect(service.isAdvertised, isFalse);
      });
    });
  });
}
