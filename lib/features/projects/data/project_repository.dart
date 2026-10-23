import 'package:flutter/foundation.dart';
import '../domain/media_project.dart';

class ProjectRepository extends ChangeNotifier {
  final List<MediaProject> _items = [];
  List<MediaProject> get items => List.unmodifiable(_items);

  void add(MediaProject project) {
    _items.insert(0, project);
    notifyListeners();
  }
}
