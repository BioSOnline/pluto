import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../pluto_app_controller.dart';
import '../../pluto_providers.dart';

class PlutoCategoryManagerSheet extends ConsumerStatefulWidget {
  const PlutoCategoryManagerSheet({super.key, required this.controller});

  final PlutoAppController controller;

  @override
  ConsumerState<PlutoCategoryManagerSheet> createState() =>
      _PlutoCategoryManagerSheetState();
}

class _PlutoCategoryManagerSheetState
    extends ConsumerState<PlutoCategoryManagerSheet> {
  final TextEditingController _nameController = TextEditingController();
  int _selectedColorValue = AppColors.categoryColorOptions.first;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = ref.watch(plutoAppControllerProvider);
    final controller = ref.watch(plutoAppControllerProvider.notifier);
    final customCategories = appState.categories
        .where((category) => !category.isSystemDefault)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Manage Categories',
              style: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),

            // New Category Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightSurfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'New category name',
                      prefixIcon: Icon(Icons.folder_open_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Color Picker Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: AppColors.categoryColorOptions.map((color) {
                      final isSelected = _selectedColorValue == color;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedColorValue = color;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(color),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Color(color).withValues(alpha: 0.5),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  FilledButton.icon(
                    onPressed: controller.isBusy
                        ? null
                        : () async {
                            final name = _nameController.text.trim();
                            if (name.isNotEmpty) {
                              await controller.createCategory(
                                name: name,
                                colorValue: _selectedColorValue,
                              );
                              _nameController.clear();
                            }
                          },
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Create Category'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Custom Categories',
              style: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),

            if (customCategories.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No custom categories yet. Default categories cannot be modified.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
              )
            else
              ...customCategories.map((cat) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Color(cat.colorValue),
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(
                      cat.name,
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: IconButton(
                      tooltip: 'Rename category',
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () => _showRenameDialog(
                        context,
                        controller,
                        cat.id,
                        cat.name,
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    PlutoAppController controller,
    String categoryId,
    String currentName,
  ) async {
    final textController = TextEditingController(text: currentName);
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogCtx) {
          return AlertDialog(
            title: const Text('Rename category'),
            content: TextField(
              controller: textController,
              decoration: const InputDecoration(labelText: 'Category name'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  await controller.renameCategory(
                    categoryId,
                    textController.text,
                  );
                  if (dialogCtx.mounted) {
                    Navigator.of(dialogCtx).pop();
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    } finally {
      textController.dispose();
    }
  }
}
