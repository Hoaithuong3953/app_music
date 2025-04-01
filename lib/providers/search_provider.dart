import 'package:flutter/material.dart';
import '../models/song.dart';
import 'dart:collection';

class SearchProvider extends ChangeNotifier {
  List<Song> _allSongs = [];
  List<Song> _filteredSongs = [];
  String _searchQuery = "";

  List<Song> get allSongs => UnmodifiableListView(_allSongs);
  List<Song> get filteredSongs => UnmodifiableListView(_filteredSongs);

  void setSongs(List<Song> songs) {
    if (_allSongs != songs) {
      _allSongs = songs;
      _filterSongs();
      notifyListeners();
    }
  }

  void updateSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      _filterSongs();
      notifyListeners();
    }
  }

  void _filterSongs() {
    if (_searchQuery.isEmpty) {
      _filteredSongs = _allSongs;
    } else {
      _filteredSongs = _allSongs
          .where((song) => song.title.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
  }
}
