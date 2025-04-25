import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'screens/dashboard_screen.dart';
import 'screens/student_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(const ClassManagerApp());
}

class ClassManagerApp extends StatelessWidget {
  const ClassManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Class Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFE0F7FA),
        textTheme: GoogleFonts.poppinsTextTheme(),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan),
        appBarTheme: AppBarTheme(
          toolbarHeight: 65,
          backgroundColor: Colors.cyan,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 27,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyan.shade600,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      home: const MainTabController(),
    );
  }
}

class MainTabController extends StatefulWidget {
  const MainTabController({super.key});

  @override
  State<MainTabController> createState() => _MainTabControllerState();
}

class _MainTabControllerState extends State<MainTabController> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    DashboardScreen(),
     StudentScreen(),
     ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: SizedBox(
        height: 100,
        child: Stack(
          children: [
            // Wave background
            Positioned.fill(
              child: CustomPaint(
                painter: WavePainter(),
              ),
            ),
            // Icons in nav bar
            Align(
              alignment: Alignment.center,
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: _onTabTapped,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: Colors.white,
                unselectedItemColor: Colors.white70,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(FontAwesomeIcons.home),
                    label: 'Dashboard',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(FontAwesomeIcons.users),
                    label: 'Students',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(FontAwesomeIcons.gear),
                    label: 'Settings',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.fill;

    Path path = Path();
    path.moveTo(0, 10);
    path.quadraticBezierTo(size.width / 4, 0, size.width / 2, 12);
    path.quadraticBezierTo(size.width * 3 / 4, 24, size.width, 10);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
