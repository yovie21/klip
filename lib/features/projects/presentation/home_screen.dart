import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../tools/data/tool_catalog.dart';
import '../data/project_repository.dart';
import '../domain/media_project.dart';
import '../../editor/presentation/editor_screen.dart';
import '../../../core/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int tab = 0;
  String query = '';
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
            child: IndexedStack(index: tab, children: [
          editPage(),
          const _SimplePage('Templates', 'Template gallery'),
          const _SimplePage('AI Lab', 'AI features planned for later'),
          projectsPage(),
          const _SimplePage('Me', 'Klip · Local projects')
        ])),
        bottomNavigationBar: NavigationBar(
            backgroundColor: AppTheme.background,
            selectedIndex: tab,
            onDestinationSelected: (i) => setState(() => tab = i),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.movie_creation_outlined), label: 'Edit'),
              NavigationDestination(
                  icon: Icon(Icons.grid_view_rounded), label: 'Templates'),
              NavigationDestination(
                  icon: Icon(Icons.auto_awesome), label: 'AI Lab'),
              NavigationDestination(
                  icon: Icon(Icons.folder_open_outlined), label: 'Projects'),
              NavigationDestination(
                  icon: Icon(Icons.person_outline), label: 'Me')
            ]),
      );
  Widget editPage() {
    final items = context.watch<ProjectRepository>().items;
    return CustomScrollView(slivers: [
      SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
          sliver: SliverToBoxAdapter(
              child: Row(children: [
            const Text('Klip',
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
            const Spacer(),
            IconButton(onPressed: _allTools, icon: const Icon(Icons.search))
          ]))),
      SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
              child: Row(children: [
            Expanded(child: _createTile(Icons.add, 'New project', _newProject)),
            const SizedBox(width: 10),
            Expanded(
                child:
                    _createTile(Icons.image_outlined, 'New photo', _pickPhoto))
          ]))),
      SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
          sliver: SliverToBoxAdapter(
              child: Row(children: [
            const Text('Tools',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton(onPressed: _allTools, child: const Text('All tools'))
          ]))),
      SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, childAspectRatio: 1.13),
              itemCount: 9,
              itemBuilder: (_, i) => _tool([
                    'AutoCut',
                    'Retouch',
                    'AI generator',
                    'Photo tools',
                    'Shoot and record',
                    'Auto enhance',
                    'Cover maker',
                    'Auto captions',
                    'AI clipper'
                  ][i]))),
      SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 7),
          sliver: SliverToBoxAdapter(
              child: Row(children: [
            const Text('Projects',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton(
                onPressed: () => setState(() => tab = 3),
                child: const Text('See all'))
          ]))),
      if (items.isEmpty)
        const SliverToBoxAdapter(
            child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                    child: Text('No projects yet',
                        style: TextStyle(color: AppTheme.muted)))))
      else
        SliverList.builder(
            itemCount: items.length,
            itemBuilder: (_, i) => ListTile(
                leading: const Icon(Icons.movie_outlined),
                title: Text(items[i].name),
                subtitle: Text('${items[i].clips.length} clip(s)'),
                onTap: () => _open(items[i])))
    ]);
  }

  Widget _createTile(IconData icon, String title, VoidCallback action) =>
      InkWell(
          onTap: action,
          borderRadius: BorderRadius.circular(13),
          child: Container(
              height: 96,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(13)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, color: AppTheme.accent, size: 28),
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w700))
                  ])));
  Widget _tool(String name) => InkWell(
      onTap: () => _toolAction(name),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(18)),
            child: Icon(_icon(name), color: AppTheme.accent)),
        const SizedBox(height: 8),
        Text(name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12))
      ]));
  IconData _icon(String name) => switch (name) {
        'AutoCut' => Icons.auto_awesome,
        'Retouch' => Icons.face_retouching_natural,
        'Auto generator' => Icons.movie_filter_outlined,
        'Auto captions' => Icons.subtitles_outlined,
        'AI clipper' => Icons.content_cut,
        'Remove background' => Icons.person_remove_alt_1,
        'Adjust speed' => Icons.speed,
        'Audio tools' => Icons.graphic_eq,
        _ => Icons.photo_filter_outlined
      };
  void _allTools() => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      builder: (ctx) => StatefulBuilder(
          builder: (ctx, refresh) => SafeArea(
                  child: Column(children: [
                Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      const Text('All tools',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close))
                    ])),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                        onChanged: (v) => refresh(() => query = v),
                        decoration: const InputDecoration(
                            hintText: 'Search tools',
                            prefixIcon: Icon(Icons.search)))),
                Expanded(
                    child: ListView(
                        children: ToolCatalog.groups.entries.map((g) {
                  final filtered = g.value
                      .where(
                          (v) => v.toLowerCase().contains(query.toLowerCase()))
                      .toList();
                  if (filtered.isEmpty) return const SizedBox.shrink();
                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(g.key,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold))),
                        GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 4,
                            childAspectRatio: .8,
                            children: filtered.map(_tool).toList())
                      ]);
                }).toList()))
              ]))));
  Future<void> _newProject() async {
    final files = await ImagePicker().pickMultipleMedia();
    if (files.isEmpty || !mounted) return;
    final p = MediaProject(
        'Project ${context.read<ProjectRepository>().items.length + 1}',
        files.map((f) => f.path).toList());
    context.read<ProjectRepository>().add(p);
    _open(p);
  }

  Future<void> _pickPhoto() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (f == null || !mounted) return;
    final p = MediaProject('Photo project', [f.path]);
    context.read<ProjectRepository>().add(p);
    _open(p);
  }

  Future<void> _toolAction(String name) async {
    if (name == 'Shoot and record') {
      final f = await ImagePicker().pickVideo(source: ImageSource.camera);
      if (f != null && mounted) {
        final p = MediaProject('Recording', [f.path]);
        context.read<ProjectRepository>().add(p);
        _open(p);
      }
      return;
    }
    if (const {
      'AI generator',
      'AI photo editor',
      'AutoCut',
      'Smart ads',
      'AI video',
      'AI image',
      'AI effects',
      'AI trends',
      'Video to carousel',
      'Auto captions',
      'Video translator',
      'AI avatars',
      'AI dialogue scene',
      'AI fashion model',
      'Custom voice',
      'Noise reduction',
      'Text to speech',
      'Voice changer',
      'Remove background',
      'AI clipper'
    }.contains(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name dikerjakan di tahap AI berikutnya')));
      return;
    }
    await _newProject();
  }

  void _open(MediaProject p) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => EditorScreen(project: p)));
  Widget projectsPage() {
    final items = context.watch<ProjectRepository>().items;
    return items.isEmpty
        ? const _SimplePage('Projects', 'No projects yet')
        : ListView(
            children: items
                .map((p) => ListTile(
                    leading: const Icon(Icons.movie_outlined),
                    title: Text(p.name),
                    subtitle: Text('${p.clips.length} media'),
                    onTap: () => _open(p)))
                .toList());
  }
}

class _SimplePage extends StatelessWidget {
  const _SimplePage(this.title, this.subtitle);
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(subtitle,
            style: const TextStyle(color: AppTheme.muted),
            textAlign: TextAlign.center)
      ]));
}
