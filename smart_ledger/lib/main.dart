import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'navigation/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FlutterNaverMap().init(clientId: AppConfig.naverMapsClientId);
  try {
    final credential = await FirebaseAuth.instance.signInAnonymously();
    debugPrint('[Auth] 익명 로그인 성공 uid=${credential.user?.uid}');
  } catch (e) {
    debugPrint('[Auth] 익명 로그인 실패: $e');
  }
  debugPrint('[Auth] currentUser=${FirebaseAuth.instance.currentUser?.uid}');
  runApp(const ProviderScope(child: SmartLedgerApp()));
}

class SmartLedgerApp extends StatelessWidget {
  const SmartLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartLedger',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const MainNavigation(),
    );
  }
}
