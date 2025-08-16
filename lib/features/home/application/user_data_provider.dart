import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/authentication/data/user_repository.dart';
import '../../../features/authentication/domain/user_model.dart';
import '../../../features/authentication/services/auth_service.dart';

final userDataProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final userRepository = ref.watch(userRepositoryProvider);

  // إذا كان المستخدم مسجلاً، اذهب وجلب بياناته من المستودع
  if (authState.asData?.value != null) {
    return userRepository.getUserDataStream(authState.asData!.value!.uid);
  }
  return Stream.value(null);
});
