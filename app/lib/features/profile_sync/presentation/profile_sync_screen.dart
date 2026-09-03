import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../state/app_state.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/user_facing_error.dart';
import '../../../widgets/app_decorations.dart';
import '../application/profile_sync_service.dart';
import '../domain/profile_sync_code.dart';
import '../domain/profile_sync_link.dart';
import '../domain/profile_sync_repository.dart';

class ProfileSyncScreen extends StatefulWidget {
  const ProfileSyncScreen({super.key});

  @override
  State<ProfileSyncScreen> createState() => _ProfileSyncScreenState();
}

class _ProfileSyncScreenState extends State<ProfileSyncScreen> {
  final _codeController = TextEditingController();
  ProfileSyncLink? _link;
  String _baseUrl = '';
  var _busy = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final user = context.read<AppState>().activeUser;
    if (user == null) return;
    final service = context.read<ProfileSyncService>();
    final link = await service.linkFor(user.id);
    final uri = await service.mongoUri();
    if (!mounted) return;
    setState(() {
      _link = link;
      _baseUrl = uri;
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      await action();
    } on ProfileSyncException catch (e) {
      setState(() => _status = e.message);
    } on FormatException catch (e) {
      setState(() => _status = e.message);
    } catch (e) {
      setState(() => _status = UserFacingError.message(e, context: UserErrorContext.sync));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        await _reload();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().activeUser;
    final linked = _link != null;
    final code = _link == null ? null : ProfileSyncCode(syncId: _link!.syncId, token: _link!.token);

    return Scaffold(
      backgroundColor: AppTheme.pageBlue,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GradientHeader(
            title: 'Sincronizar perfil',
            subtitle: user == null ? '' : 'Solo la cuenta «${user.name}»',
            onBack: () => Navigator.pop(context),
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
                  label: 'Cómo funciona',
                  child: Text(
                    'Activa la sincronización en este usuario y copia el código. '
                    'En el otro dispositivo, entra en la misma cuenta local (o créala) y pega el código. '
                    'Los demás usuarios de este aparato no se mezclan.\n\n'
                    'En Configuración no hace falta pegar Atlas si compilaste con mongo_atlas.env.json. Sin red, el progreso sigue solo en el dispositivo.',
                    style: TextStyle(color: Colors.black.withValues(alpha: 0.55), height: 1.35),
                  ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  label: 'Estado',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _baseUrl.isEmpty
                            ? 'Atlas: no configurado'
                            : 'Atlas configurado',
                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      if (_link?.lastError != null) ...[
                        const SizedBox(height: 8),
                        Text(_link!.lastError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                      ],
                      if (_link?.lastSyncedAt != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Última sincronización: ${_link!.lastSyncedAt!.toLocal()}',
                          style: const TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (!linked) ...[
                  SectionCard(
                    label: 'Este es el primer dispositivo',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Genera un código y úsalo en el teléfono, la tablet o el PC.',
                          style: TextStyle(color: Colors.black54, height: 1.35),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: user == null || _busy
                              ? null
                              : () => _run(() async {
                                    final generated = await context.read<ProfileSyncService>().enableFor(user);
                                    await Clipboard.setData(ClipboardData(text: generated.compact));
                                    setState(() => _status = 'Código copiado. Pégalo en el otro dispositivo.');
                                  }),
                          icon: const Icon(Icons.link),
                          label: const Text('Activar y copiar código'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SectionCard(
                    label: 'Ya tengo un código',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _codeController,
                          enabled: !_busy,
                          decoration: const InputDecoration(
                            hintText: 'ot1.…',
                            prefixIcon: Icon(Icons.vpn_key_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: user == null || _busy
                              ? null
                              : () => _run(() async {
                                    final service = context.read<ProfileSyncService>();
                                    final appState = context.read<AppState>();
                                    await service.joinWithCode(
                                      user: user,
                                      rawCode: _codeController.text,
                                    );
                                    final result = await service.syncUser(user, force: true);
                                    if (!mounted) return;
                                    appState.notifyProgressChanged();
                                    setState(() => _status = _messageFor(result));
                                  }),
                          child: const Text('Vincular este usuario'),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  SectionCard(
                    label: 'Código de este perfil',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SelectableText(
                          code!.compact,
                          style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () async {
                                  await Clipboard.setData(ClipboardData(text: code.compact));
                                  setState(() => _status = 'Código copiado.');
                                },
                          icon: const Icon(Icons.copy),
                          label: const Text('Copiar código'),
                        ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: user == null || _busy
                              ? null
                              : () => _run(() async {
                                    final service = context.read<ProfileSyncService>();
                                    final appState = context.read<AppState>();
                                    final result = await service.syncUser(user, force: true);
                                    if (!mounted) return;
                                    appState.notifyProgressChanged();
                                    setState(() => _status = _messageFor(result));
                                  }),
                          icon: const Icon(Icons.sync),
                          label: const Text('Sincronizar ahora'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: user == null || _busy
                              ? null
                              : () => _run(() async {
                                    await context.read<ProfileSyncService>().unlink(user.id);
                                    setState(() => _status = 'Este dispositivo ya no sincroniza este usuario.');
                                  }),
                          child: const Text('Dejar de sincronizar aquí'),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_status != null) ...[
                  const SizedBox(height: 16),
                  Text(_status!, style: const TextStyle(height: 1.35)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _messageFor(ProfileSyncResult result) {
    return switch (result.status) {
      ProfileSyncStatus.synced => 'Perfil actualizado.',
      ProfileSyncStatus.disabled => 'Pega la URI de Atlas en Configuración.',
      ProfileSyncStatus.skipped => 'Nada que sincronizar ahora.',
      ProfileSyncStatus.error => result.message ?? 'No se pudo sincronizar.',
    };
  }
}
