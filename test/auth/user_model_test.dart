import 'package:flutter_test/flutter_test.dart';
import 'package:moneyplan_pro/features/auth/data/models/user_model.dart';

void main() {
  group('UserModel authorization', () {
    test('maps an active super admin profile', () {
      final user = UserModel.fromJson({
        'id': '58017688-0989-40ec-a0d7-2409d8ea54fa',
        'email': 'trgy.ycl@gmail.com',
        'role': 'super_admin',
        'is_active': true,
        'is_banned': false,
      });

      expect(user.isAdmin, isTrue);
      expect(user.isSuperAdmin, isTrue);
      expect(user.canUseAccount, isTrue);
    });

    test('denies access to banned or deleted profiles', () {
      final banned = UserModel.fromJson({
        'id': 'banned-user',
        'email': 'banned@example.com',
        'role': 'admin',
        'is_active': true,
        'is_banned': true,
      });
      final deleted = banned.copyWith(
        isBanned: false,
        deletedAt: DateTime.utc(2026, 7, 19),
      );

      expect(banned.canUseAccount, isFalse);
      expect(deleted.canUseAccount, isFalse);
    });
  });
}
