import 'package:flutter_test/flutter_test.dart';
import 'package:power6_mobile/utils/access.dart';

void main() {
  test('tier access matches launch subscription ladder', () {
    expect(hasAccess(UserTier.free, 'free'), isTrue);
    expect(hasAccess(UserTier.plus, 'free'), isFalse);
    expect(hasAccess(UserTier.plus, 'plus'), isTrue);
    expect(hasAccess(UserTier.pro, 'plus'), isFalse);
    expect(hasAccess(UserTier.pro, 'pro'), isTrue);
    expect(hasAccess(UserTier.elite, 'pro'), isFalse);
    expect(hasAccess(UserTier.elite, 'elite'), isTrue);
  });
}
