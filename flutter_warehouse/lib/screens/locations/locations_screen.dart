import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_service.dart';
import '../../models/location.dart';
import '../../widgets/error_view.dart';

class LocationsScreen extends ConsumerStatefulWidget {
  const LocationsScreen({super.key});

  @override
  ConsumerState<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends ConsumerState<LocationsScreen> {
  final _searchCtrl = TextEditingController();
  final _locationService = LocationService();
  List<Location> _locations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load([String? search]) async {
    setState(() { _loading = true; _error = null; });
    try {
      _locations = await _locationService.getAll(search: search);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAddDialog() {
    final codeCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新增位置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(
                  labelText: '位置代码 *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                  labelText: '描述', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => ctx.pop(), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              if (codeCtrl.text.trim().isEmpty) return;
              try {
                await _locationService.create(
                  code: codeCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                );
                if (ctx.mounted) ctx.pop();
                _load();
              } on DioException catch (e) {
                final msg = e.response?.data?['message'];
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(msg ?? '创建失败')));
                }
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('位置管理'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SearchBar(
              controller: _searchCtrl,
              hintText: '搜索位置代码...',
              leading: const Icon(Icons.search),
              onChanged: (v) => _load(v),
            ),
          ),
        ),
      ),
      floatingActionButton: user?.canEdit == true
          ? FloatingActionButton(
              onPressed: _showAddDialog,
              child: const Icon(Icons.add),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _locations.isEmpty
                  ? const Center(child: Text('暂无位置'))
                  : ListView.builder(
                      itemCount: _locations.length,
                      itemBuilder: (_, i) {
                        final loc = _locations[i];
                        return ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.location_on)),
                          title: Text(loc.code,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: loc.description != null
                              ? Text(loc.description!)
                              : null,
                          onTap: () => context
                              .push('/locations/${loc.id}')
                              .then((_) => _load()),
                        );
                      },
                    ),
    );
  }
}
