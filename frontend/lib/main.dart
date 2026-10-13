import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'state/app_state.dart';
import 'pages/auth_page.dart';
import 'pages/home_page.dart';
import 'pages/menu_page.dart';
import 'pages/story_page.dart';
import 'pages/ticket_page.dart';
import 'pages/profile_page.dart';

const brown = Color(0xFF17110C);
const brown2 = Color(0xFF241913);
const border = Color(0xFF3F2D23);
const cream = Color(0xFFF8F4EC);
const gold = Color.fromARGB(255, 230, 150, 22);
const green = Color(0xFF2E7D32);
const muted = Color(0xFFC5B8A8);

void main() {
  runApp(const PuthuLanangApp());
}

class PuthuLanangApp extends StatefulWidget {
  const PuthuLanangApp({super.key});

  @override
  State<PuthuLanangApp> createState() => _PuthuLanangAppState();
}

class _PuthuLanangAppState extends State<PuthuLanangApp> {
  final state = AppState();

  @override
  void initState() {
    super.initState();
    state.restore();
    state.loadMenu();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Puthu Lanang',
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: brown,
            colorScheme: ColorScheme.fromSeed(
              seedColor: green,
              brightness: Brightness.dark,
            ),
            fontFamily: GoogleFonts.poppins().fontFamily,
          ),
          home: MainShell(
            state: state,
          ),
        );
      },
    );
  }
}

class MainShell extends StatelessWidget {
  final AppState state;

  const MainShell({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(state: state),
      MenuPage(state: state),
      StoryPage(state: state),
      TicketPage(state: state),
      ProfilePage(state: state),
    ];

    return Scaffold(
      body: SafeArea(
        child: pages[state.tab],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: brown2,
        indicatorColor: green.withValues(alpha: 0.25),
        selectedIndex: state.tab,
        onDestinationSelected: (i) {
          // Jika pengguna memilih tab Pesanan (3) atau Profil (4) tetapi belum login,
          // arahkan terlebih dahulu ke halaman Auth (Masuk/Daftar).
          if ((i == 3 || i == 4) && !state.loggedIn) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AuthPage(
                  state: state,
                ),
              ),
            );
            return;
          }

          // Memperbarui tab aktif dan memicu pembaruan UI secara langsung
          state.setTab(i);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories),
            label: 'Cerita',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_num_outlined),
            selectedIcon: Icon(Icons.confirmation_num),
            label: 'Pesanan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

String rupiah(int n) {
  return 'Rp ${n.toString().replaceAllMapped(
        RegExp(r'(?=(\d{3})+(?!\d))'),
        (m) => '.',
      )}';
}