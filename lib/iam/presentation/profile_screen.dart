import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/session_controller.dart';
import '../../core/presentation/format.dart';
import '../../core/presentation/widgets/error_view.dart';
import '../../maintenance/presentation/dialogs.dart';
import '../domain/user.dart';
import 'profile_providers.dart';

String roleLabel(String role) => switch (role) {
      'MAINTENANCE_MANAGER' => 'Gerente de mantenimiento',
      'TECHNICIAN' => 'Técnico',
      'OPERATOR' => 'Operador',
      _ => role,
    };

/// Perfil del usuario (US-23): ver, editar el nombre y cerrar sesión.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(profileActionsProvider);
    ref.listen(profileActionsProvider, (_, state) {
      if (state.hasError) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(describeActionFailure(state.error!))));
      }
    });

    return ref.watch(profileProvider).when(
          skipLoadingOnRefresh: false,
          skipLoadingOnReload: false,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorView(
            message: 'No se pudo cargar el perfil: $e',
            onRetry: () => ref.invalidate(profileProvider),
          ),
          data: (user) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ProfileCard(user: user),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _editName(context, ref, user),
                icon: const Icon(Icons.edit),
                label: const Text('Editar nombre'),
              ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: () => _logout(context, ref),
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
              ),
            ],
          ),
        );
  }

  Future<void> _editName(BuildContext context, WidgetRef ref, User user) async {
    final name = await askRequiredText(
      context,
      title: 'Editar nombre',
      label: 'Nombre',
      confirmLabel: 'Guardar',
      maxLength: 120,
      initialText: user.displayName,
    );
    if (name != null) await ref.read(profileActionsProvider.notifier).rename(name);
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final ok = await askConfirmation(
      context,
      title: 'Cerrar sesión',
      message: '¿Quieres cerrar tu sesión en este dispositivo?',
      confirmLabel: 'Cerrar sesión',
    );
    // Borra la sesión del almacén seguro; el router vuelve al login.
    if (ok) await ref.read(sessionControllerProvider.notifier).logout();
  }
}

class _ProfileCard extends StatelessWidget {
  final User user;

  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(radius: 28, child: Icon(Icons.person, size: 32)),
              const SizedBox(height: 12),
              Text(user.displayName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(user.email),
              const SizedBox(height: 8),
              Wrap(spacing: 6, children: [
                for (final r in user.roles) Chip(label: Text(roleLabel(r))),
              ]),
            ],
          ),
        ),
      );
}
