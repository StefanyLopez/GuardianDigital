import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../kid/models/profile_model.dart';
import '../../kid/providers/profile_provider.dart';

// Pantalla reutilizable para crear Y editar perfiles
// Si recibe un [profile], entra en modo edición
// Si no, entra en modo creación
class ProfileFormScreen extends ConsumerStatefulWidget {
  final ProfileModel? profile; // null = crear, non-null = editar
  const ProfileFormScreen({super.key, this.profile});

  @override
  ConsumerState<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends ConsumerState<ProfileFormScreen> {
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _ageRange = AppConstants.ageRangeKid;
  int _selectedAvatar = 0;
  final Set<String> _selectedGoals = {};

  bool get _isEditing => widget.profile != null;

  @override
  void initState() {
    super.initState();
    // Si es edición, pre-llenar con los datos existentes
    if (_isEditing) {
      _nameCtrl.text = widget.profile!.name;
      _ageRange = widget.profile!.ageRange;
      _selectedAvatar = widget.profile!.avatarId;
      _selectedGoals.addAll(widget.profile!.goals);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(profileNotifierProvider.notifier);

    if (_isEditing) {
      await notifier.updateProfile(
        profileId: widget.profile!.id,
        name: _nameCtrl.text.trim(),
        ageRange: _ageRange,
        avatarId: _selectedAvatar,
        goals: _selectedGoals.toList(),
      );
    } else {
      await notifier.createProfile(
        name: _nameCtrl.text.trim(),
        ageRange: _ageRange,
        avatarId: _selectedAvatar,
        goals: _selectedGoals.toList(),
      );
    }

    if (!mounted) return;
    final state = ref.read(profileNotifierProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: ${state.error}')),
      );
    } else {
      context.pop(); // vuelve al panel familiar
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar perfil?'),
        content: Text(
          'Se eliminarán todos los datos de ${widget.profile!.name}. '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar',
                style: TextStyle(color: GDColors.error)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    await ref
        .read(profileNotifierProvider.notifier)
        .deleteProfile(widget.profile!.id);
    if (mounted) context.go('/guardian');
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(profileNotifierProvider).isLoading;
    final avatarEmojis = ['🦁', '🐼', '🦊', '🐬', '🦋', '🌟'];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Editar perfil' : 'Nuevo perfil',
          style: GDTypography.headlineMedium,
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: GDColors.error),
              onPressed: _delete,
              tooltip: 'Eliminar perfil',
            ),
        ],
      ),
      // resizeToAvoidBottomInset resuelve el overflow del teclado
      resizeToAvoidBottomInset: true,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          // Padding extra en el bottom para que el teclado no tape el botón
          padding: EdgeInsets.fromLTRB(
            GDSpacing.lg,
            GDSpacing.md,
            GDSpacing.lg,
            MediaQuery.of(context).viewInsets.bottom + GDSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre
              Text('Nombre', style: GDTypography.titleLarge),
              const Gap(GDSpacing.sm),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Nombre del menor',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'El nombre es obligatorio'
                    : null,
              ),

              const Gap(GDSpacing.lg),

              // Edad
              Text('Edad', style: GDTypography.titleLarge),
              const Gap(GDSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _AgeChip(
                      label: '8–12 años',
                      isSelected: _ageRange == AppConstants.ageRangeKid,
                      onTap: () =>
                          setState(() => _ageRange = AppConstants.ageRangeKid),
                    ),
                  ),
                  const Gap(GDSpacing.md),
                  Expanded(
                    child: _AgeChip(
                      label: '13–17 años',
                      isSelected: _ageRange == AppConstants.ageRangeTeen,
                      onTap: () =>
                          setState(() => _ageRange = AppConstants.ageRangeTeen),
                    ),
                  ),
                ],
              ),

              const Gap(GDSpacing.lg),

              // Avatar
              Text('Avatar', style: GDTypography.titleLarge),
              const Gap(GDSpacing.sm),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: GDSpacing.sm,
                  crossAxisSpacing: GDSpacing.sm,
                ),
                itemCount: avatarEmojis.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => setState(() => _selectedAvatar = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: _selectedAvatar == i
                          ? GDColors.primaryLight
                          : GDColors.surfaceVariant,
                      borderRadius: GDRadius.mdAll,
                      border: Border.all(
                        color: _selectedAvatar == i
                            ? GDColors.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        avatarEmojis[i],
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                ),
              ),

              const Gap(GDSpacing.lg),

              // Metas
              Row(
                children: [
                  Expanded(
                    child: Text('Metas', style: GDTypography.titleLarge),
                  ),
                  Text(
                    '${_selectedGoals.length}/3',
                    style: GDTypography.bodySmall,
                  ),
                ],
              ),
              const Gap(GDSpacing.sm),
              Wrap(
                spacing: GDSpacing.sm,
                runSpacing: GDSpacing.sm,
                children: AppConstants.onboardingGoals.map((goal) {
                  final id = goal['id']!;
                  final isSelected = _selectedGoals.contains(id);
                  final isDisabled =
                      _selectedGoals.length >= 3 && !isSelected;
                  return GestureDetector(
                    onTap: isDisabled
                        ? null
                        : () => setState(() {
                              if (isSelected) {
                                _selectedGoals.remove(id);
                              } else {
                                _selectedGoals.add(id);
                              }
                            }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: GDSpacing.md,
                        vertical: GDSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? GDColors.primaryLight
                            : isDisabled
                                ? GDColors.surfaceVariant.withValues(alpha: 0.5)
                                : GDColors.surfaceVariant,
                        borderRadius: GDRadius.fullAll,
                        border: Border.all(
                          color: isSelected
                              ? GDColors.primary
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        goal['label']!,
                        style: GDTypography.bodySmall.copyWith(
                          color: isDisabled
                              ? GDColors.textTertiary
                              : isSelected
                                  ? GDColors.primaryDark
                                  : GDColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const Gap(GDSpacing.xl),

              // Botón guardar
              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isEditing ? 'Guardar cambios' : 'Crear perfil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _AgeChip(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: GDSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? GDColors.primary : GDColors.surfaceVariant,
          borderRadius: GDRadius.lgAll,
        ),
        child: Center(
          child: Text(
            label,
            style: GDTypography.titleLarge.copyWith(
              color: isSelected ? Colors.white : GDColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}