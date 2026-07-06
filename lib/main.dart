import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'database/lodge_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/rooms_screen.dart';
import 'screens/bookings_screen.dart';
import 'screens/guests_screen.dart';
import 'screens/add_booking_screen.dart';
import 'screens/availability_screen.dart';

// Conditional database factory setup per platform
// ignore: undefined_import
import 'database/db_setup_stub.dart'
  // ignore: undefined_import
  if (dart.library.html) 'database/db_setup_web.dart'
  // ignore: undefined_import
  if (dart.library.io) 'database/db_setup_native.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupDatabase();
  runApp(const SriLakshmiNarasimhaLodgeApp());
}

class SriLakshmiNarasimhaLodgeApp extends StatelessWidget {
  const SriLakshmiNarasimhaLodgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LodgeProvider()..loadAll(),
      child: MaterialApp(
        title: 'Sri Lakshmi Narasimha Lodge',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF5A5F),
            brightness: Brightness.light,
            primary: const Color(0xFFFF5A5F),
            secondary: const Color(0xFF00C4CC),
            surface: Colors.white,
          ),
          scaffoldBackgroundColor: Colors.white,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF222222),
            centerTitle: true,
            elevation: 0,
            scrolledUnderElevation: 0.5,
            surfaceTintColor: Colors.transparent,
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            color: Colors.white,
            shadowColor: Colors.black12,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Color(0xFFEBEBEB)),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5A5F),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFF5A5F),
              side: const BorderSide(color: Color(0xFFFF5A5F)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF5A5F),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF7F7F7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFFF5A5F), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFFFF5A5F),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.white,
            elevation: 0,
            indicatorColor: const Color(0xFFFF5A5F).withValues(alpha: 0.1),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(color: Color(0xFFFF5A5F), fontSize: 11, fontWeight: FontWeight.w600);
              }
              return TextStyle(color: Colors.grey[500], fontSize: 11);
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(color: Color(0xFFFF5A5F), size: 22);
              }
              return IconThemeData(color: Colors.grey[400], size: 22);
            }),
          ),
          dividerTheme: DividerThemeData(
            color: const Color(0xFFEBEBEB),
            thickness: 1,
            space: 1,
          ),
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: Color(0xFFFF5A5F),
          ),
        ),
        home: const MainShell(),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    AvailabilityScreen(),
    BookingsScreen(),
    RoomsScreen(),
    GuestsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        elevation: 3,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.book_online_outlined), selectedIcon: Icon(Icons.book_online), label: 'Bookings'),
          NavigationDestination(icon: Icon(Icons.meeting_room_outlined), selectedIcon: Icon(Icons.meeting_room), label: 'Rooms'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Guests'),
        ],
      ),
      floatingActionButton: _currentIndex == 0 || _currentIndex == 1 || _currentIndex == 2
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddBookingScreen())),
              icon: const Icon(Icons.add),
              label: const Text('New Booking'),
            )
          : null,
    );
  }
}
