import 'package:testea_local/database/app_database.dart';
import 'package:testea_local/features/random_tests/application/random_test_context.dart';
import 'package:testea_local/models/local_user.dart';

import '../../helpers/database_helper.dart';

Future<({AppDatabase db, RandomTestContext context, LocalUser user})> setUpRandomTestContext({
  String userId = 'user-random',
  String userName = 'Ana',
}) async {
  final db = await setUpTestDatabase();
  final user = LocalUser(
    id: userId,
    name: userName,
    createdAt: DateTime.parse('2026-01-01T00:00:00'),
  );
  await db.upsertUser(user);
  return (db: db, context: RandomTestContext(db), user: user);
}
