import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommonDropdown<T> extends ConsumerWidget {
  const CommonDropdown({
    super.key,
    required this.items,
    required this.provider,
    required this.labelBuilder,
  });

  final List<T> items;
  final StateProvider<T?> provider;
  final String Function(T) labelBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 注入されたプロバイダを監視
    final selectedItem = ref.watch(provider);

    return DropdownMenu<T>(
      initialSelection: selectedItem,
      onSelected: (T? newValue) {
        // 注入されたプロバイダを更新
        ref.read(provider.notifier).state = newValue;
      },
      dropdownMenuEntries: items
          .map<DropdownMenuEntry<T>>(
            (T item) => DropdownMenuEntry<T>(
              value: item,
              label: labelBuilder(item),
            ),
          )
          .toList(),
    );
  }
}