import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../pluto_app_controller.dart';
import '../../../pluto_note_repository.dart';
import '../domain/audio_note.dart';

class PlutoSearchAndFilters extends StatefulWidget {
  const PlutoSearchAndFilters({super.key, required this.controller});

  final PlutoAppController controller;

  @override
  State<PlutoSearchAndFilters> createState() => _PlutoSearchAndFiltersState();
}

class _PlutoSearchAndFiltersState extends State<PlutoSearchAndFilters> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.controller.activeFilter.query,
    );
  }

  @override
  void didUpdateWidget(PlutoSearchAndFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller.activeFilter.query != _searchController.text) {
      _searchController.text = widget.controller.activeFilter.query;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = widget.controller;
    final currentFilter = controller.activeFilter;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Field
          TextField(
            controller: _searchController,
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Search notes, tags, or voice content…',
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 20,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        controller.updateFilter(
                          PlutoNoteFilter(
                            query: '',
                            categoryId: currentFilter.categoryId,
                            tag: currentFilter.tag,
                            onlyFavorites: currentFilter.onlyFavorites,
                            syncStatus: currentFilter.syncStatus,
                            createdAfter: currentFilter.createdAfter,
                            createdBefore: currentFilter.createdBefore,
                          ),
                        );
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onChanged: (query) {
              controller.updateFilter(
                PlutoNoteFilter(
                  query: query,
                  categoryId: currentFilter.categoryId,
                  tag: currentFilter.tag,
                  onlyFavorites: currentFilter.onlyFavorites,
                  syncStatus: currentFilter.syncStatus,
                  createdAfter: currentFilter.createdAfter,
                  createdBefore: currentFilter.createdBefore,
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          // Categories Horizontal Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // All Categories chip
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: const Text('All'),
                    selected: currentFilter.categoryId == null,
                    showCheckmark: false,
                    onSelected: (_) {
                      controller.updateFilter(
                        PlutoNoteFilter(
                          query: currentFilter.query,
                          categoryId: null,
                          tag: currentFilter.tag,
                          onlyFavorites: currentFilter.onlyFavorites,
                          syncStatus: currentFilter.syncStatus,
                          createdAfter: currentFilter.createdAfter,
                          createdBefore: currentFilter.createdBefore,
                        ),
                      );
                    },
                  ),
                ),
                ...controller.categories.map((category) {
                  final isSelected = currentFilter.categoryId == category.id;
                  final categoryColor = Color(category.colorValue);

                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      avatar: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: categoryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      label: Text(category.name),
                      selected: isSelected,
                      showCheckmark: false,
                      onSelected: (selected) {
                        controller.updateFilter(
                          PlutoNoteFilter(
                            query: currentFilter.query,
                            categoryId: selected ? category.id : null,
                            tag: currentFilter.tag,
                            onlyFavorites: currentFilter.onlyFavorites,
                            syncStatus: currentFilter.syncStatus,
                            createdAfter: currentFilter.createdAfter,
                            createdBefore: currentFilter.createdBefore,
                          ),
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Quick Filter Actions (Favorites, Sync status, Time ranges)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Favorites
                FilterChip(
                  avatar: Icon(
                    currentFilter.onlyFavorites ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 16,
                    color: currentFilter.onlyFavorites ? AppColors.amber : null,
                  ),
                  label: const Text('Favorites'),
                  selected: currentFilter.onlyFavorites,
                  showCheckmark: false,
                  onSelected: (selected) {
                    controller.updateFilter(
                      PlutoNoteFilter(
                        query: currentFilter.query,
                        categoryId: currentFilter.categoryId,
                        tag: currentFilter.tag,
                        onlyFavorites: selected,
                        syncStatus: currentFilter.syncStatus,
                        createdAfter: currentFilter.createdAfter,
                        createdBefore: currentFilter.createdBefore,
                      ),
                    );
                  },
                ),

                const SizedBox(width: 6),

                // Sync Failed
                FilterChip(
                  avatar: const Icon(Icons.sync_problem_rounded, size: 15, color: AppColors.error),
                  label: const Text('Needs Sync'),
                  selected: currentFilter.syncStatus == PlutoSyncStatus.failed,
                  showCheckmark: false,
                  onSelected: (selected) {
                    controller.updateFilter(
                      PlutoNoteFilter(
                        query: currentFilter.query,
                        categoryId: currentFilter.categoryId,
                        tag: currentFilter.tag,
                        onlyFavorites: currentFilter.onlyFavorites,
                        syncStatus: selected ? PlutoSyncStatus.failed : null,
                        createdAfter: currentFilter.createdAfter,
                        createdBefore: currentFilter.createdBefore,
                      ),
                    );
                  },
                ),

                const SizedBox(width: 6),

                // Last 7 days
                ChoiceChip(
                  label: const Text('Last 7d'),
                  selected: isLastDaysFilter(currentFilter, 7),
                  onSelected: (selected) {
                    final now = DateTime.now();
                    controller.updateFilter(
                      PlutoNoteFilter(
                        query: currentFilter.query,
                        categoryId: currentFilter.categoryId,
                        tag: currentFilter.tag,
                        onlyFavorites: currentFilter.onlyFavorites,
                        syncStatus: currentFilter.syncStatus,
                        createdAfter: selected ? now.subtract(const Duration(days: 7)) : null,
                        createdBefore: selected ? now : null,
                      ),
                    );
                  },
                ),

                const SizedBox(width: 6),

                // Last 30 days
                ChoiceChip(
                  label: const Text('Last 30d'),
                  selected: isLastDaysFilter(currentFilter, 30),
                  onSelected: (selected) {
                    final now = DateTime.now();
                    controller.updateFilter(
                      PlutoNoteFilter(
                        query: currentFilter.query,
                        categoryId: currentFilter.categoryId,
                        tag: currentFilter.tag,
                        onlyFavorites: currentFilter.onlyFavorites,
                        syncStatus: currentFilter.syncStatus,
                        createdAfter: selected ? now.subtract(const Duration(days: 30)) : null,
                        createdBefore: selected ? now : null,
                      ),
                    );
                  },
                ),

                if (hasActivePlutoFilters(currentFilter)) ...[
                  const SizedBox(width: 6),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: AppColors.error,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      controller.updateFilter(const PlutoNoteFilter());
                    },
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                    label: const Text('Clear'),
                  ),
                ],
              ],
            ),
          ),

          // Top Tags (if any exist in visible notes)
          if (topPlutoTags(controller.visibleNotes).isNotEmpty) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: topPlutoTags(controller.visibleNotes).map((tag) {
                  final isSelected = currentFilter.tag == tag;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text('#$tag'),
                      selected: isSelected,
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      onSelected: (selected) {
                        controller.updateFilter(
                          PlutoNoteFilter(
                            query: currentFilter.query,
                            categoryId: currentFilter.categoryId,
                            tag: selected ? tag : null,
                            onlyFavorites: currentFilter.onlyFavorites,
                            syncStatus: currentFilter.syncStatus,
                            createdAfter: currentFilter.createdAfter,
                            createdBefore: currentFilter.createdBefore,
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
