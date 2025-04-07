import 'package:flutter/material.dart';
import '../models/artist.dart';
import '../service/artist_service.dart';

class ArtistProvider with ChangeNotifier {
  List<Artist> _artists = [];
  bool _isLoading = false;

  List<Artist> get artists => _artists;
  bool get isLoading => _isLoading;

  final ArtistService _artistService = ArtistService();

  Future<void> fetchArtists() async {
    try {
      _isLoading = true;
      notifyListeners(); // Thông báo đang tải

      _artists = await _artistService.fetchArtists();
      print("Artists loaded: ${_artists.map((a) => a.title).toList()}");

      _isLoading = false;
      notifyListeners(); // Thông báo hoàn tất
    } catch (e) {
      print("Error loading artists: $e");
      _artists = [];
      _isLoading = false;
      notifyListeners(); // Thông báo lỗi (nếu cần)
    }
  }

  String getArtistNameById(String? artistId) {
    if (artistId == null) return 'Unknown Artist';
    final artist = _artists.firstWhere(
          (a) => a.id == artistId,
      orElse: () => Artist(
        id: '',
        title: 'Unknown Artist',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return artist.title;
  }
}