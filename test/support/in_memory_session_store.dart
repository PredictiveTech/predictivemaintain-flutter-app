import 'package:predictivemaintain_flutter_app/iam/domain/auth_session.dart';
import 'package:predictivemaintain_flutter_app/iam/domain/auth_session_store.dart';

class InMemorySessionStore implements AuthSessionStore {
  AuthSession? session;

  InMemorySessionStore([this.session]);

  @override
  Future<AuthSession?> read() async => session;

  @override
  Future<void> save(AuthSession s) async => session = s;

  @override
  Future<void> clear() async => session = null;
}
