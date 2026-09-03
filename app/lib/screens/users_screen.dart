import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/app_database.dart';
import '../features/backup/application/progress_backup_service.dart';
import '../features/backup/data/backup_file_io.dart';
import '../features/backup/domain/backup_validation.dart';
import '../features/profile_sync/application/profile_sync_service.dart';
import '../features/profile_sync/domain/profile_sync_link.dart';
import '../models/local_user.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/user_facing_error.dart';
import '../widgets/app_decorations.dart';
import '../widgets/staggered_entry.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _controller = TextEditingController();
  late Future<List<LocalUser>> _usersFuture;
  var _initialized = false;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _usersFuture = Future.value([]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _reload();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _reload() {
    _usersFuture = context.read<AppDatabase>().getUsers();
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _usersFuture;
  }

  Future<void> _create() async {
    if (_busy) return;
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    await context.read<AppState>().createUser(name);
    _controller.clear();
    await _refresh();
  }

  Future<void> _selectUser(LocalUser user) async {
    await context.read<AppState>().selectUser(user);
    if (!mounted) return;
    final result = await context.read<ProfileSyncService>().syncUser(user, force: true);
    if (!mounted) return;
    if (result.status == ProfileSyncStatus.synced) {
      context.read<AppState>().notifyProgressChanged();
    }
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  Future<void> _importProfile() async {
    if (_busy) return;
    setState(() => _busy = true);
    final db = context.read<AppDatabase>();
    final progressService = context.read<ProgressBackupService>();
    final appState = context.read<AppState>();
    try {
      final existing = await db.getUsers();
      var replace = false;
      if (existing.isNotEmpty) {
        final choice = await _confirmReplaceUsers();
        if (!mounted || choice == null) return;
        replace = choice;
      }
      final result = await progressService.importFromPicker(
        replaceExistingUsers: replace,
      );
      if (!mounted) return;
      if (result.users == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El archivo no contiene ningún perfil.')),
        );
        return;
      }
      await appState.activateImportedProfile();
    } on BackupFileCancelledException {
      return;
    } on BackupValidationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserFacingError.message(e, context: UserErrorContext.backup))),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        await _refresh();
      }
    }
  }

  Future<bool?> _confirmReplaceUsers() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importar perfil'),
        content: const Text(
          'Ya hay cuentas en este dispositivo.\n\n'
          '• Fusionar: añade el progreso sin borrar lo existente\n'
          '• Reemplazar: borra los intentos previos de cada perfil importado',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Fusionar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reemplazar')),
        ],
      ),
    );
  }

  Future<void> _deleteUser(LocalUser user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: Text('¿Borrar "${user.name}" y todo su progreso en este dispositivo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Borrar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<AppState>().deleteUser(user);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final activeId = context.watch<AppState>().activeUser?.id;
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: AppTheme.pageBlue,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GradientHeader(
            title: 'Cuentas locales',
            subtitle: 'Crea una cuenta o importa un perfil que ya hayas exportado',
            onBack: canPop ? () => Navigator.pop(context) : null,
            trailing: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.people_outline, color: Colors.white),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_busy) ...[
                  const LinearProgressIndicator(color: AppTheme.primary),
                  const SizedBox(height: 12),
                ],
                SectionCard(
                  label: 'Importar perfil',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Si ya exportaste el progreso a Drive, correo u otra app, restáuralo aquí sin crear una cuenta nueva.',
                        style: TextStyle(color: Colors.black.withValues(alpha: 0.55), height: 1.35),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _importProfile,
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('IMPORTAR PERFIL'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SectionCard(
                  label: 'Nueva cuenta',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _controller,
                        enabled: !_busy,
                        decoration: const InputDecoration(
                          hintText: 'Nombre de usuario',
                          prefixIcon: Icon(Icons.person_add_outlined),
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: _busy ? null : (_) => _create(),
                      ),
                      const SizedBox(height: 12),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: AppDecorations.headerGradient,
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          onPressed: _busy ? null : _create,
                          child: const Text('CREAR CUENTA'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('TUS CUENTAS', style: AppDecorations.sectionLabel(context)),
                const SizedBox(height: 10),
                FutureBuilder<List<LocalUser>>(
                  future: _usersFuture,
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final users = snap.data!;
                    if (users.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: AppDecorations.card(color: AppTheme.primary.withValues(alpha: 0.05)),
                        child: const Column(
                          children: [
                            Icon(Icons.account_circle_outlined, size: 48, color: AppTheme.primary),
                            SizedBox(height: 12),
                            Text(
                              'Crea tu primera cuenta o importa un perfil exportado',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (var i = 0; i < users.length; i++)
                          StaggeredEntry(
                            index: i,
                            child: _UserCard(
                              user: users[i],
                              active: users[i].id == activeId,
                              onTap: () => _selectUser(users[i]),
                              onDelete: () => _deleteUser(users[i]),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.active,
    required this.onTap,
    required this.onDelete,
  });

  final LocalUser user;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final date = '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: active ? Border.all(color: AppTheme.primary, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: active ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.15),
                  child: Text(
                    user.name[0].toUpperCase(),
                    style: TextStyle(
                      color: active ? Colors.white : AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (active) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Activa',
                                style: TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Creada $date', style: const TextStyle(color: Colors.black45, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.black38),
                  tooltip: 'Eliminar cuenta',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
