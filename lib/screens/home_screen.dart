import 'package:flutter/material.dart';
import '../models/artwork.dart';
import 'gallery_screen.dart';
import 'studio_screen.dart';
import 'tv_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<StudioScreenState> _studioKey = GlobalKey<StudioScreenState>();

  void _onSelectArtworkFromGallery(Artwork art) {
    setState(() {
      _currentIndex = 0; // Chuyển về tab Studio
    });
    // Nạp tranh vừa chọn vào Studio
    _studioKey.currentState?.loadArtwork(art);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          StudioScreen(key: _studioKey),
          GalleryScreen(onSelectArtwork: _onSelectArtworkFromGallery),
          const TvScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.crop),
            selectedIcon: Icon(Icons.crop_outlined),
            label: 'Art Studio',
          ),
          NavigationDestination(
            icon: Icon(Icons.palette_outlined),
            selectedIcon: Icon(Icons.palette),
            label: 'Bảo Tàng',
          ),
          NavigationDestination(
            icon: Icon(Icons.tv_outlined),
            selectedIcon: Icon(Icons.tv),
            label: 'TV The Frame',
          ),
        ],
      ),
    );
  }
}
