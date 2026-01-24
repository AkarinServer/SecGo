import 'package:flutter/material.dart';
import 'package:kiosk/db/database_helper.dart';
import 'package:kiosk/models/product.dart';
import 'package:kiosk/l10n/app_localizations.dart';

class NoBarcodeProductsDialog extends StatefulWidget {
  final ValueChanged<Product> onAdd;

  const NoBarcodeProductsDialog({super.key, required this.onAdd});

  @override
  State<NoBarcodeProductsDialog> createState() => _NoBarcodeProductsDialogState();
}

class _NoBarcodeProductsDialogState extends State<NoBarcodeProductsDialog> {
  late final Future<List<Product>> _futureProducts;
  String _selectedCategory = '';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _futureProducts = DatabaseHelper.instance.getAllProducts();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: 980,
        height: 640,
        child: FutureBuilder<List<Product>>(
          future: _futureProducts,
          builder: (context, snapshot) {
            final all = snapshot.data ?? const <Product>[];
            final noBarcode =
                all.where((p) => p.barcode.startsWith('NB-')).toList(growable: false);
            final categories = <String>[
              l10n.categoryAll,
              ...{
                for (final p in noBarcode)
                  (p.type == null || p.type!.trim().isEmpty)
                      ? l10n.categoryUncategorized
                      : p.type!.trim(),
              }
            ]..sort((a, b) {
                if (a == l10n.categoryAll) return -1;
                if (b == l10n.categoryAll) return 1;
                if (a == l10n.categoryUncategorized) return 1;
                if (b == l10n.categoryUncategorized) return -1;
                return a.toLowerCase().compareTo(b.toLowerCase());
              });

            final effectiveCategory =
                _selectedCategory.isEmpty ? l10n.categoryAll : _selectedCategory;
            final filtered = noBarcode.where((p) {
              final name = p.name.toLowerCase();
              final q = _query.trim().toLowerCase();
              if (q.isNotEmpty && !name.contains(q)) return false;
              if (effectiveCategory == l10n.categoryAll) return true;
              final type = p.type?.trim();
              if (effectiveCategory == l10n.categoryUncategorized) {
                return type == null || type.isEmpty;
              }
              return type == effectiveCategory;
            }).toList()
              ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.noBarcodeProductsTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 200,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  l10n.categories,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            Expanded(
                              child: ListView.builder(
                                itemCount: categories.length,
                                itemBuilder: (context, index) {
                                  final c = categories[index];
                                  final selected = c == effectiveCategory;
                                  return ListTile(
                                    dense: true,
                                    selected: selected,
                                    title: Text(c),
                                    onTap: () => setState(() => _selectedCategory = c),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              TextField(
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.search),
                                  hintText: l10n.searchProducts,
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onChanged: (v) => setState(() => _query = v),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: snapshot.connectionState == ConnectionState.waiting
                                    ? const Center(child: CircularProgressIndicator())
                                    : filtered.isEmpty
                                        ? Center(child: Text(l10n.noBarcodeProductsEmpty))
                                        : GridView.builder(
                                            gridDelegate:
                                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                              maxCrossAxisExtent: 220,
                                              mainAxisSpacing: 12,
                                              crossAxisSpacing: 12,
                                              childAspectRatio: 2.6,
                                            ),
                                            itemCount: filtered.length,
                                            itemBuilder: (context, index) {
                                              final p = filtered[index];
                                              return ElevatedButton(
                                                onPressed: () => widget.onAdd(p),
                                                style: ElevatedButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 10,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                ),
                                                child: Text(
                                                  p.name,
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              );
                                            },
                                          ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
