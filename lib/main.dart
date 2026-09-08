import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FrameCropApp());
}

class FrameCropApp extends StatelessWidget {
  const FrameCropApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Frame Crop - Art Mode',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD4AF37), // Metallic Warm Gold accent
          onPrimary: Colors.black,
          secondary: Color(0xFFC5A059),
          surface: Color(0xFF181818),
          onSurface: Color(0xFFEDEADE),
        ),
        cardColor: const Color(0xFF1C1C1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF141414),
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF141414),
          indicatorColor: const Color(0xFFD4AF37).withOpacity(0.2),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              );
            }
            return TextStyle(color: Colors.grey.shade500, fontSize: 12);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Color(0xFFD4AF37));
            }
            return IconThemeData(color: Colors.grey.shade500);
          }),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
