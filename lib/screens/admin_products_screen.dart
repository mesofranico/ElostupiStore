import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_controller.dart';
import '../core/utils/ui_utils.dart';
import '../widgets/loading_view.dart';
import '../controllers/product_controller.dart';
import '../controllers/app_controller.dart';
import '../models/product.dart';
import '../widgets/standard_appbar.dart';

// Widget para reordenar categorias
class CategoryReorderDialog extends StatefulWidget {
  final List<String> categories;
  final Function(List<String>) onSave;

  const CategoryReorderDialog({
    super.key,
    required this.categories,
    required this.onSave,
  });

  @override
  State<CategoryReorderDialog> createState() => _CategoryReorderDialogState();
}

class _CategoryReorderDialogState extends State<CategoryReorderDialog> {
  late List<String> _categories;

  @override
  void initState() {
    super.initState();
    _categories = List.from(widget.categories);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Row(
        children: [
          Icon(Icons.sort_by_alpha, color: theme.colorScheme.primary, size: 24),
          const SizedBox(width: 10),
          Text(
            'Reordenar categorias',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 360,
        height: 360,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Arrasta para alterar a ordem:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ReorderableListView.builder(
                itemCount: _categories.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) newIndex -= 1;
                    final item = _categories.removeAt(oldIndex);
                    _categories.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return Container(
                    key: ValueKey(category),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                      leading: Icon(
                        Icons.drag_handle,
                        color: theme.colorScheme.outline,
                        size: 22,
                      ),
                      title: Text(
                        category,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => widget.onSave(_categories),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Guardar ordem'),
        ),
      ],
    );
  }
}

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final AdminController adminController = Get.find<AdminController>();
  final ProductController productController = Get.find<ProductController>();

  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _price2Controller = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _categoryController = TextEditingController();
  final _stockController = TextEditingController();

  // Produto atualmente em edição (necessário para calcular o novo stock com base no atual)
  Product? _editingProduct;

  // Variáveis para filtro
  String? _selectedCategory;
  bool _sortByStock = false; // Controlo para ordenar por stock
  bool _currentManageStock = true; // Valor temporário para o form

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _price2Controller.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _categoryController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _showEditProductForm(Product editProduct) {
    _editingProduct = editProduct;
    _idController.text = editProduct.id;
    _nameController.text = editProduct.name;
    _priceController.text = editProduct.price.toString();
    _price2Controller.text = editProduct.price2?.toString() ?? '';
    _descriptionController.text = editProduct.description;
    _imageUrlController.text = editProduct.imageUrl;
    _categoryController.text = editProduct.category ?? '';
    _currentManageStock = editProduct.manageStock;
    // O campo de stock passa a ser um AJUSTE (delta). Deixar vazio por omissão.
    _stockController.text = '';

    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.edit,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Editar produto',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          editProduct.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${editProduct.id}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration: InputDecoration(
                            labelText: 'Preço (€) *',
                            prefixText: '€ ',
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.4),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Preço é obrigatório';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Preço deve ser um número válido';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _price2Controller,
                          decoration: InputDecoration(
                            labelText: 'Revenda (€)',
                            prefixText: '€ ',
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.4),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null &&
                                value.trim().isNotEmpty &&
                                double.tryParse(value) == null) {
                              return 'Número inválido';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _stockController,
                    decoration: InputDecoration(
                      labelText: 'Ajuste de stock (+/-)',
                      helperText:
                          'Stock atual: ${editProduct.stock ?? 0}. Ex.: 10 ou -10',
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null &&
                          value.trim().isNotEmpty &&
                          int.tryParse(value) == null) {
                        return 'Stock deve ser um número inteiro';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  StatefulBuilder(
                    builder: (context, setSheetState) {
                      return SwitchListTile(
                        title: const Text('Gerir Stock'),
                        subtitle: Text(
                          _currentManageStock
                              ? 'O stock será decrementado nas vendas'
                              : 'Produto sempre disponível (stock ignorado)',
                        ),
                        value: _currentManageStock,
                        onChanged: (value) {
                          setSheetState(() => _currentManageStock = value);
                          setState(() => _currentManageStock = value);
                        },
                        secondary: Icon(
                          _currentManageStock
                              ? Icons.inventory
                              : Icons.all_inclusive,
                          color: theme.colorScheme.primary,
                        ),
                        contentPadding: EdgeInsets.zero,
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: adminController.isLoading.value
                              ? null
                              : () async {
                                  Navigator.of(sheetContext).pop();
                                  await _saveProduct();
                                },
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: adminController.isLoading.value
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                )
                              : const Text('Atualizar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _saveProduct() async {
    try {
      if (!_formKey.currentState!.validate()) {
        return false;
      }

      // Ativar wake lock temporariamente durante a operação
      final appController = Get.find<AppController>();
      appController.enableWakeLockTemporarily();

      // Calcular novo stock com base no stock atual + delta introduzido
      final int currentStock = _editingProduct?.stock ?? 0;
      final int deltaStock = _stockController.text.trim().isNotEmpty
          ? int.parse(_stockController.text.trim())
          : 0;
      final int calculatedStock = currentStock + deltaStock;

      // Impedir stock negativo
      if (calculatedStock < 0) {
        UiUtils.showError('O stock não pode ficar negativo. Ajuste o valor.');
        return false;
      }

      final product = Product(
        id: _idController.text.trim(),
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text),
        price2: _price2Controller.text.isNotEmpty
            ? double.parse(_price2Controller.text)
            : null,
        description: _descriptionController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
        category: _categoryController.text.trim().isNotEmpty
            ? _categoryController.text.trim()
            : null,
        stock: calculatedStock,
        manageStock: _currentManageStock,
      );

      final success = await adminController.updateProduct(product);

      if (success) {
        await productController.refreshProducts();
      }
      // Limpar estado de edição
      _editingProduct = null;
      _stockController.clear();
      return success;
    } catch (e) {
      _editingProduct = null;
      return false;
    }
  }

  void _showCategoryReorderDialog() {
    Get.dialog(
      CategoryReorderDialog(
        categories: productController.categories
            .where((c) => c != 'Todas')
            .toList(),
        onSave: (newOrder) async {
          await productController.reorderCategories(newOrder);
          Get.back();

          // Mostrar confirmação
          UiUtils.showSuccess('Ordem das categorias atualizada!');
        },
      ),
    );
  }

  // Função utilitária para montar a URL completa da imagem
  String getFullImageUrl(String imageUrl) {
    if (imageUrl.isEmpty) return '';
    if (imageUrl.startsWith('http')) return imageUrl;
    return 'https://gestao.elostupi.pt/$imageUrl';
  }

  // Função para obter produtos filtrados por categoria e ordenados por stock
  List<Product> getFilteredProducts(List<Product> products) {
    List<Product> filteredProducts;

    // Filtrar por categoria
    if (_selectedCategory == null || _selectedCategory == 'Todas') {
      filteredProducts = List.from(products);
    } else {
      filteredProducts = products
          .where((product) => product.category == _selectedCategory)
          .toList();
    }

    // Ordenar por stock se ativado
    if (_sortByStock) {
      filteredProducts.sort((a, b) {
        final stockA = a.stock ?? 0;
        final stockB = b.stock ?? 0;
        return stockA.compareTo(stockB); // Ordem crescente (menor para maior)
      });
    }

    return filteredProducts;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: StandardAppBar(
        title: 'Gestão de produtos',
        backgroundColor: theme.colorScheme.primary,
        showBackButton: true,
        actions: [
          IconButton(
            onPressed: () => _showCategoryReorderDialog(),
            icon: const Icon(Icons.sort_by_alpha),
            tooltip: 'Reordenar categorias',
          ),
          IconButton(
            onPressed: () => productController.refreshProducts(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar produtos',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Icon(
                            Icons.filter_list,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Obx(() {
                              final categories = [
                                'Todas',
                                ...productController.categories.where(
                                  (c) => c != 'Todas',
                                ),
                              ];
                              return DropdownButtonFormField<String>(
                                initialValue: _selectedCategory ?? 'Todas',
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: theme.colorScheme.outlineVariant
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  filled: true,
                                  fillColor: theme
                                      .colorScheme
                                      .surfaceContainerHighest
                                      .withValues(alpha: 0.4),
                                ),
                                items: categories
                                    .map(
                                      (category) => DropdownMenuItem(
                                        value: category,
                                        child: Text(
                                          category,
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  Future.microtask(
                                    () => setState(
                                      () => _selectedCategory = value,
                                    ),
                                  );
                                },
                              );
                            }),
                          ),
                          if (_selectedCategory != null &&
                              _selectedCategory != 'Todas') ...[
                            const SizedBox(width: 4),
                            IconButton(
                              onPressed: () => Future.microtask(
                                () => setState(() => _selectedCategory = null),
                              ),
                              icon: Icon(
                                Icons.clear,
                                size: 18,
                                color: theme.colorScheme.error,
                              ),
                              tooltip: 'Limpar filtro',
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Row(
                        children: [
                          Icon(
                            Icons.sort,
                            color: Colors.orange.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Switch(
                            value: _sortByStock,
                            onChanged: (value) => Future.microtask(
                              () => setState(() => _sortByStock = value),
                            ),
                          ),
                          if (_sortByStock)
                            Icon(
                              Icons.trending_up,
                              size: 18,
                              color: Colors.orange.shade700,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Lista de produtos
              Expanded(
                child: Obx(() {
                  if (productController.isLoading.value) {
                    return const LoadingView();
                  }

                  final filteredProducts = getFilteredProducts(
                    productController.products,
                  );

                  if (filteredProducts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 56,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selectedCategory != null &&
                                    _selectedCategory != 'Todas'
                                ? 'Nenhum produto em "$_selectedCategory"'
                                : 'Nenhum produto',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_selectedCategory != null &&
                              _selectedCategory != 'Todas') ...[
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () => Future.microtask(
                                () => setState(() => _selectedCategory = null),
                              ),
                              icon: Icon(
                                Icons.clear,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                              label: const Text('Limpar filtro'),
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 40),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 2.7,
                        ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final stock = product.stock ?? 0;
                      final stockColor = stock == 0
                          ? Colors.red.shade700
                          : (stock <= 5
                                ? Colors.orange.shade700
                                : Colors.green.shade700);
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final cardW = constraints.maxWidth;
                          final cardH = constraints.maxHeight;
                          const imageWidthFraction = 0.4;
                          final imageW = cardW * imageWidthFraction;
                          return Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.shadow.withValues(
                                    alpha: 0.06,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                                BoxShadow(
                                  color: theme.colorScheme.shadow.withValues(
                                    alpha: 0.02,
                                  ),
                                  blurRadius: 2,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.horizontal(
                                      left: Radius.circular(6),
                                    ),
                                    child: SizedBox(
                                      width: imageW,
                                      height: cardH,
                                      child: Image.network(
                                        getFullImageUrl(product.imageUrl),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Container(
                                          color: theme
                                              .colorScheme
                                              .surfaceContainerHighest
                                              .withValues(alpha: 0.5),
                                          child: Icon(
                                            Icons.image_not_supported,
                                            size: 22,
                                            color: theme.colorScheme.outline,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                product.name,
                                                style: theme
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: theme
                                                          .colorScheme
                                                          .onSurface,
                                                      height: 1.15,
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (product
                                                  .description
                                                  .isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  product.description,
                                                  style: theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: theme
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                        height: 1.15,
                                                      ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 3,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: stockColor,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: stockColor
                                                          .withValues(
                                                            alpha: 0.3,
                                                          ),
                                                      blurRadius: 1,
                                                      offset: const Offset(
                                                        0,
                                                        0,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: Text(
                                                  !product.manageStock
                                                      ? 'Sempre Disponível'
                                                      : (stock == 0
                                                            ? 'Sem stock'
                                                            : 'Stock: $stock'),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    height: 1.0,
                                                  ),
                                                ),
                                              ),
                                              Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: () =>
                                                      _showEditProductForm(
                                                        product,
                                                      ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 6,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: theme
                                                          .colorScheme
                                                          .primary,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: theme
                                                              .colorScheme
                                                              .primary
                                                              .withValues(
                                                                alpha: 0.25,
                                                              ),
                                                          blurRadius: 2,
                                                          offset: const Offset(
                                                            0,
                                                            1,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    child: const Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          Icons.edit,
                                                          size: 14,
                                                          color: Colors.white,
                                                        ),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          'Editar',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
