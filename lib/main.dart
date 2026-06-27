import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'auth/auth_service.dart';
import 'screens/chat_list_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'Вечный Мессенджер',
        theme: ThemeData.dark(), // Стильный черный фон
        home: Consumer<AuthService>(
          builder: (context, auth, _) {
            if (auth.user == null) return LoginScreen();
            return ChatListScreen();
          },
        ),
      ),
    );
  }
}