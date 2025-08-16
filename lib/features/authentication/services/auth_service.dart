import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/user_repository.dart';

// AuthService الآن مسؤول فقط عن المصادقة
class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final UserRepository _userRepository;

  AuthService({
    required FirebaseAuth auth,
    required GoogleSignIn googleSignIn,
    required UserRepository userRepository,
  })  : _auth = auth,
        _googleSignIn = googleSignIn,
        _userRepository = userRepository;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        // نستدعي المستودع للقيام بعملية الحفظ
        await _userRepository.saveNewUser(userCredential.user!);
      }
      return userCredential.user;
    } catch (e) {
      print('خطأ في تسجيل الدخول باستخدام Google: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}

// --- Providers المحدثة ---
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    auth: FirebaseAuth.instance,
    googleSignIn: GoogleSignIn(scopes: ['email']),
    userRepository: ref.watch(userRepositoryProvider),
  );
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});
