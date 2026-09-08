import 'package:flutter/material.dart';
import '../models/artwork.dart';
import '../services/museum_service.dart';

class GalleryScreen extends StatefulWidget {
  final Function(Artwork) onSelectArtwork;

  const GalleryScreen({super.key, required this.onSelectArtwork});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final _searchController = TextEditingController();
  List<Artwork> _artworks = [];
  bool _isLoading = false;
  String _activeCategory = 'curated';

  @override
  void initState() {
    super.initState();
    _loadArtworks();
  }

  Future<void> _loadArtworks() async {
    setState(() => _isLoading = true);
    List<Artwork> results = [];

    if (_activeCategory == 'curated') {
      results = MuseumService.getCuratedArtworks();
    } else if (_activeCategory == 'chicago') {
      results = await MuseumService.fetchChicagoArtworks();
    } else if (_activeCategory == 'met') {
      results = await MuseumService.fetchMetHighlights();
    } else if (_activeCategory == 'vangogh') {
      results = await MuseumService.fetchChicagoArtworks(query: 'Van Gogh');
    } else if (_activeCategory == 'monet') {
      results = await MuseumService.fetchChicagoArtworks(query: 'Monet');
    }

    if (mounted) {
      setState(() {
        _artworks = results.isNotEmpty ? results : MuseumService.getCuratedArtworks();
        _isLoading = false;
      });
    }
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      _loadArtworks();
      return;
    }
    setState(() => _isLoading = true);
    final results = await MuseumService.fetchChicagoArtworks(query: query);
    if (mounted) {
      setState(() {
        _artworks = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kho Tranh Nghệ Thuật Mở',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Tìm tranh theo tên, họa sĩ (Van Gogh, Monet...)...',
              leading: const Icon(Icons.search, size: 20),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      _loadArtworks();
                    },
                  ),
              ],
              onSubmitted: _search,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Danh mục nhanh
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                _buildCategoryChip('curated', 'Kiệt tác chọn lọc', Icons.star),
                const SizedBox(width: 8),
                _buildCategoryChip('chicago', 'Art Institute of Chicago', Icons.museum),
                const SizedBox(width: 8),
                _buildCategoryChip('met', 'The Met Museum', Icons.account_balance),
                const SizedBox(width: 8),
                _buildCategoryChip('vangogh', 'Vincent van Gogh', Icons.brush),
                const SizedBox(width: 8),
                _buildCategoryChip('monet', 'Claude Monet', Icons.palette),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _artworks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.image_not_supported_outlined, size: 48, color: Colors.grey.shade500),
                            const SizedBox(height: 8),
                            const Text('Không tìm thấy tác phẩm nào'),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(12.0),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _artworks.length,
                        itemBuilder: (context, index) {
                          final art = _artworks[index];
                          return _buildArtCard(art);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String key, String label, IconData icon) {
    final isSelected = _activeCategory == key;
    return FilterChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() => _activeCategory = key);
          _loadArtworks();
        }
      },
    );
  }

  Widget _buildArtCard(Artwork art) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () => _showArtDetails(art),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    art.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade900,
                      child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                    ),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: Colors.grey.shade900,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        art.source,
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    art.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    art.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showArtDetails(Artwork art) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade700,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      art.imageUrl,
                      width: double.infinity,
                      height: 260,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    art.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${art.artist} • ${art.date}',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  ),
                  if (art.medium.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      art.medium,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onSelectArtwork(art);
                      },
                      icon: const Icon(Icons.tune),
                      label: const Text(
                        'Mở Trong Art Studio & Cắt Viền',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(padding: const EdgeInsets.all(14)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
