import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/main_navigation_screen.dart';

import 'core/utils/permission_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Request Camera, Mic, Location, and Storage permissions on launch
  PermissionUtils.requestAllFieldPermissions();
  runApp(const ApexSignageApp());
}

class ApexSignageApp extends StatelessWidget {
  const ApexSignageApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuth()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'Apex Signage & Printing Operations',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: auth.isAuthenticated
                ? const MainNavigationScreen()
                : const LoginScreen(),
          );
        },
      ),
    );
  }
}
