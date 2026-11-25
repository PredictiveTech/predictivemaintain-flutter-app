import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/injection.dart';
import '../../core/error/failure.dart';
import '../../core/error/retry.dart';
import '../domain/user.dart';

final profileProvider = FutureProvider.autoDispose<User>(
  (ref) => ref.watch(getProfileUseCaseProvider)(),
  retry: noRetry,
);

class ProfileActions extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<bool> rename(String displayName) async {
    state = const AsyncLoading();
    try {
      await ref.read(updateDisplayNameUseCaseProvider)(displayName);
    } on Failure catch (f, st) {
      state = AsyncError(f, st);
      return false;
    }
    state = const AsyncData(null);
    ref.invalidate(profileProvider);
    return true;
  }
}

final profileActionsProvider =
    AsyncNotifierProvider.autoDispose<ProfileActions, void>(ProfileActions.new);
