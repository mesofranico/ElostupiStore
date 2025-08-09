import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_controller.dart';
import '../controllers/product_controller.dart';
import '../controllers/app_controller.dart';
import '../models/product.dart';

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
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Row(
        children: [
          Icon(
            Icons.sort_by_alpha,
            color: Colors.blue[600],
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            'Reordenar Categorias',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        height: 400,
        child: Column(
          children: [
            Text(
              'Arrasta as categorias para reordená-las:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ReorderableListView.builder(
                itemCount: _categories.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    // Ajustar índices para o onReorder
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    
                    // Reordenar a lista
                    final item = _categories.removeAt(oldIndex);
                    _categories.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return Container(
                    key: ValueKey(category),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.drag_handle,
                        color: Colors.grey[400],
                      ),
                      title: Text(
                        category,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
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
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            widget.onSave(_categories);
          },
          icon: const Icon(Icons.save),
          label: const Text('Guardar Ordem'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
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
  final AdminController adminController = Get.put(AdminController());
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
    // O campo de stock passa a ser um AJUSTE (delta). Deixar vazio por omissão.
    _stockController.text = '';
    
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Icon(
              Icons.edit,
              color: Colors.blue[600],
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Editar Produto',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.blue[700],
              ),
            ),
          ],
        ),
                 content: SizedBox(
           width: 350,
           child: Form(
             key: _formKey,
             child: Column(
               mainAxisSize: MainAxisSize.min,
               crossAxisAlignment: CrossAxisAlignment.stretch,
               children: [
                 // Informação do produto (apenas para referência)
                 Container(
                   padding: const EdgeInsets.all(16),
                   decoration: BoxDecoration(
                     color: Colors.grey[50],
                     borderRadius: BorderRadius.circular(8),
                     border: Border.all(color: Colors.grey[200]!),
                   ),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         'Produto: ${editProduct.name}',
                         style: const TextStyle(
                           fontWeight: FontWeight.bold,
                           fontSize: 16,
                         ),
                       ),
                       const SizedBox(height: 4),
                       Text(
                         'ID: ${editProduct.id}',
                         style: TextStyle(
                           fontSize: 12,
                           color: Colors.grey[600],
                         ),
                       ),
                     ],
                   ),
                 ),
                 const SizedBox(height: 24),
                 
                 // Preço principal
                 TextFormField(
                   controller: _priceController,
                   decoration: const InputDecoration(
                     labelText: 'Preço (€) *',
                     border: OutlineInputBorder(),
                     prefixText: '€',
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
                 const SizedBox(height: 16),
                 
                 // Preço de Revenda
                 TextFormField(
                   controller: _price2Controller,
                   decoration: const InputDecoration(
                     labelText: 'Preço de Revenda (€)',
                     border: OutlineInputBorder(),
                     prefixText: '€',
                   ),
                   keyboardType: TextInputType.number,
                   validator: (value) {
                     if (value != null && value.trim().isNotEmpty) {
                       if (double.tryParse(value) == null) {
                         return 'Preço deve ser um número válido';
                       }
                     }
                     return null;
                   },
                 ),
                 const SizedBox(height: 16),
                 
                 // Stock
                  TextFormField(
                    controller: _stockController,
                    decoration: InputDecoration(
                      labelText: 'Ajuste de Stock (+/-)',
                      helperText: 'Stock atual: ${editProduct.stock ?? 0}. Ex.: 10 para adicionar, -10 para remover',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        if (int.tryParse(value) == null) {
                          return 'Stock deve ser um número inteiro';
                        }
                      }
                      return null;
                    },
                  ),
                 const SizedBox(height: 24),
               ],
             ),
           ),
         ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: adminController.isLoading.value ? null : () async {
              // Fechar o modal imediatamente
              Navigator.of(context).pop();
              
              // Processar a operação em background
              await _saveProduct();
            },
            icon: adminController.isLoading.value
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save),
            label: const Text('Atualizar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
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
        Get.snackbar(
          'Erro',
          'O stock não pode ficar negativo. Ajuste o valor.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.85),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        return false;
      }

      final product = Product(
        id: _idController.text.trim(),
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text),
        price2: _price2Controller.text.isNotEmpty ? double.parse(_price2Controller.text) : null,
        description: _descriptionController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
        category: _categoryController.text.trim().isNotEmpty ? _categoryController.text.trim() : null,
        stock: calculatedStock,
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
        categories: productController.categories.where((c) => c != 'Todas').toList(),
        onSave: (newOrder) async {
          await productController.reorderCategories(newOrder);
          Get.back();
          
          // Mostrar confirmação
          Get.snackbar(
            'Sucesso',
            'Ordem das categorias atualizada!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.withValues(alpha: 0.8),
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        },
      ),
    );
  }

  // Função utilitária para montar a URL completa da imagem
  String getFullImageUrl(String imageUrl) {
    if (imageUrl.isEmpty) return '';
    if (imageUrl.startsWith('http')) return imageUrl;
    return 'https://elostupi.pt/loja/$imageUrl';
  }

  // Função para obter produtos filtrados por categoria e ordenados por stock
  List<Product> getFilteredProducts(List<Product> products) {
    List<Product> filteredProducts;
    
    // Filtrar por categoria
    if (_selectedCategory == null || _selectedCategory == 'Todas') {
      filteredProducts = List.from(products);
    } else {
      filteredProducts = products.where((product) => 
        product.category == _selectedCategory
      ).toList();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
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
              // Filtro de categorias e ordenação por stock
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                                child: Row(
                  children: [
                    // Filtro de categorias
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Icon(Icons.filter_list, color: Colors.blue[600], size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Obx(() {
                              final categories = ['Todas', ...productController.categories.where((c) => c != 'Todas')];
                              return DropdownButtonFormField<String>(
                                value: _selectedCategory ?? 'Todas',
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.blue[600]!),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                items: categories.map((category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                )).toList(),
                                onChanged: (value) {
                                  // Usar Future.microtask para evitar conflitos durante o build
                                  Future.microtask(() {
                                    setState(() {
                                      _selectedCategory = value;
                                    });
                                  });
                                },
                              );
                            }),
                          ),
                          const SizedBox(width: 8),
                          // Botão para limpar filtro
                          if (_selectedCategory != null && _selectedCategory != 'Todas')
                            IconButton(
                              onPressed: () {
                                // Usar Future.microtask para evitar conflitos durante o build
                                Future.microtask(() {
                                  setState(() {
                                    _selectedCategory = null;
                                  });
                                });
                              },
                              icon: Icon(Icons.clear, color: Colors.red[600]),
                              tooltip: 'Limpar filtro',
                            ),
                        ],
                      ),
                    ),
                    
                    // Separador vertical
                    Container(
                      width: 1,
                      height: 40,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      color: Colors.grey[300],
                    ),
                    
                    // Controlo de ordenação por stock
                    Expanded(
                      flex: 1,
                      child: Row(
                        children: [
                          Icon(Icons.sort, color: Colors.orange[600], size: 24),
                          const SizedBox(width: 8),
                          // Switch para ativar/desativar ordenação por stock
                          Switch(
                            value: _sortByStock,
                            onChanged: (value) {
                              // Usar Future.microtask para evitar conflitos durante o build
                              Future.microtask(() {
                                setState(() {
                                  _sortByStock = value;
                                });
                              });
                            },
                            activeColor: Colors.orange[600],
                            activeTrackColor: Colors.orange[200],
                          ),
                          const SizedBox(width: 8),
                          // Informação sobre a ordenação (apenas ícone quando ativado)
                          if (_sortByStock)
                            Icon(
                              Icons.trending_up,
                              size: 20,
                              color: Colors.orange[600],
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
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final filteredProducts = getFilteredProducts(productController.products);
                  
                  if (filteredProducts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedCategory != null && _selectedCategory != 'Todas'
                                ? 'Nenhum produto encontrado na categoria "$_selectedCategory"'
                                : 'Nenhum produto encontrado',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                                                     if (_selectedCategory != null && _selectedCategory != 'Todas') ...[
                             const SizedBox(height: 16),
                             ElevatedButton.icon(
                               onPressed: () {
                                 // Usar Future.microtask para evitar conflitos durante o build
                                 Future.microtask(() {
                                   setState(() {
                                     _selectedCategory = null;
                                   });
                                 });
                               },
                               icon: const Icon(Icons.clear),
                               label: const Text('Limpar Filtro'),
                               style: ElevatedButton.styleFrom(
                                 backgroundColor: Colors.blue[600],
                                 foregroundColor: Colors.white,
                               ),
                             ),
                           ],
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // 3 colunas
                      crossAxisSpacing: 8, // Espaçamento horizontal entre cards
                      mainAxisSpacing: 8, // Espaçamento vertical entre cards
                      childAspectRatio: 0.75, // Proporção largura/altura dos cards
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Imagem do produto
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(16),
                                          ),
                                          child: Image.network(
                                            getFullImageUrl(product.imageUrl),
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[100],
                                                child: const Icon(
                                                  Icons.image_not_supported,
                                                  size: 50,
                                                  color: Colors.grey,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        // Indicador de stock no canto superior direito
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: (product.stock ?? 0) > 0 ? Colors.green : Colors.red,
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.2),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              (product.stock ?? 0) > 0 ? 'Stock: ${product.stock}' : 'Sem Stock',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Overlay gradiente sutil
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            height: 30,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.black.withValues(alpha: 0.1),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Informações do produto
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: const BorderRadius.vertical(
                                      bottom: Radius.circular(16),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Nome do produto
                                      Text(
                                        product.name,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[800],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      // Descrição do produto
                                      Text(
                                        product.description,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[500],
                                          height: 1.2,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 12),
                                      // Separador visual
                                      Container(
                                        height: 1,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.grey[200]!,
                                              Colors.grey[300]!,
                                              Colors.grey[200]!,
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Botão Editar (preenche a largura)
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey[200]!),
                                        ),
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [Colors.blue[400]!, Colors.blue[600]!],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.circular(10),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.blue.withValues(alpha: 0.3),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              borderRadius: BorderRadius.circular(10),
                                              child: InkWell(
                                                borderRadius: BorderRadius.circular(10),
                                                onTap: () => _showEditProductForm(product),
                                                child: Container(
                                                  height: 40,
                                                  alignment: Alignment.center,
                                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: const [
                                                      Icon(
                                                        Icons.edit,
                                                        size: 18,
                                                        color: Colors.white,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        'Editar',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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