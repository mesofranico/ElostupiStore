import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_controller.dart';
import '../controllers/product_controller.dart';
import '../controllers/app_controller.dart';
import '../models/product.dart';

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
  
  // Variáveis para filtro
  String? _selectedCategory;

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

  void _clearForm() {
    _formKey.currentState?.reset();
    _idController.clear();
    _nameController.clear();
    _priceController.clear();
    _price2Controller.clear();
    _descriptionController.clear();
    _imageUrlController.clear();
    _categoryController.clear();
    _stockController.clear();
  }

  Future<void> _deleteProduct(String productId) async {
    // Primeiro, pedir confirmação
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja deletar este produto?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Agora pedir o PIN de segurança
      final pinController = TextEditingController();
      final pinConfirmed = await Get.dialog<bool>(
        AlertDialog(
          title: Row(
            children: [
              Icon(Icons.security, color: Colors.red[600], size: 24),
              const SizedBox(width: 8),
              const Text('Código de Segurança'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Para remover este produto, introduza o código PIN:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                decoration: const InputDecoration(
                  labelText: 'Código PIN',
                  border: OutlineInputBorder(),
                  hintText: '5614',
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (pinController.text == '5614') {
                  Get.back(result: true);
                } else {
                  Get.snackbar(
                    'Erro',
                    'Código PIN incorreto!',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red.withValues(alpha: 0.8),
                    colorText: Colors.white,
                    duration: const Duration(seconds: 2),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      );

      if (pinConfirmed == true) {
        final success = await adminController.deleteProduct(productId);
        if (success) {
          await productController.refreshProducts();
          Get.snackbar(
            'Sucesso',
            adminController.successMessage.value,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.withValues(alpha: 0.8),
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        } else {
          Get.snackbar(
            'Erro',
            adminController.errorMessage.value,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withValues(alpha: 0.8),
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        }
      }
    }
  }

  void _showProductForm({Product? editProduct}) {
    final isEditing = editProduct != null;
    if (isEditing) {
      _idController.text = editProduct.id;
      _nameController.text = editProduct.name;
      _priceController.text = editProduct.price.toString();
      _price2Controller.text = editProduct.price2?.toString() ?? '';
      _descriptionController.text = editProduct.description;
      _imageUrlController.text = editProduct.imageUrl;
      _categoryController.text = editProduct.category ?? '';
      _stockController.text = editProduct.stock?.toString() ?? '';
    } else {
      _clearForm();
    }
    
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Icon(
              isEditing ? Icons.edit : Icons.add_box,
              color: isEditing ? Colors.blue[600] : Colors.green[600],
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              isEditing ? 'Editar Produto' : 'Novo Produto',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: isEditing ? Colors.blue[700] : Colors.green[700],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Campos obrigatórios
                  const Text('Campos obrigatórios', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                  const SizedBox(height: 8),
                  // ID
                  TextFormField(
                    controller: _idController,
                    decoration: const InputDecoration(
                      labelText: 'ID do Produto *',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !isEditing, // Não permite editar ID
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'ID é obrigatório';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Nome
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Produto *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nome é obrigatório';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Preço
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
                  const SizedBox(height: 24),
                  // Campos opcionais
                  const Text('Campos opcionais', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
                  const SizedBox(height: 8),
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
                  // Descrição
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  // URL da Imagem
                  TextFormField(
                    controller: _imageUrlController,
                    decoration: const InputDecoration(
                      labelText: 'URL da Imagem',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Categoria
                  Obx(() {
                    final categories = productController.categories.where((c) => c != 'Todas').toList();
                    return DropdownButtonFormField<String>(
                      value: _categoryController.text.isNotEmpty ? _categoryController.text : null,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      items: [
                        ...categories.map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            )),
                        const DropdownMenuItem(
                          value: '__nova__',
                          child: Text('Criar nova categoria...'),
                        ),
                      ],
                      onChanged: (value) async {
                        if (value == '__nova__') {
                          // Limpa para digitar nova
                          _categoryController.text = '';
                          await Future.delayed(const Duration(milliseconds: 100));
                          if (mounted) {
                            FocusScope.of(context).requestFocus(FocusNode());
                          }
                        } else if (value != null) {
                          _categoryController.text = value;
                        }
                      },
                      onSaved: (value) {
                        if (value != null && value != '__nova__') {
                          _categoryController.text = value;
                        }
                      },
                      selectedItemBuilder: (context) {
                        return [
                          ...categories.map((cat) => Text(cat)),
                          const Text('Criar nova categoria...'),
                        ];
                      },
                    );
                  }),
                  const SizedBox(height: 8),
                  // Campo para digitar nova categoria (só aparece se _categoryController.text estiver vazio)
                  if (_categoryController.text.isEmpty)
                    TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Nova Categoria',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Stock
                  TextFormField(
                    controller: _stockController,
                    decoration: const InputDecoration(
                      labelText: 'Stock',
                      border: OutlineInputBorder(),
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
                  const SizedBox(height: 24), // Espaçamento extra antes dos botões
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearForm();
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: adminController.isLoading.value ? null : () async {
              // Fechar o modal imediatamente
              Navigator.of(context).pop();
              
              // Processar a operação em background
              await _saveProduct(isEditing: isEditing);
            },
            icon: adminController.isLoading.value
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Icon(isEditing ? Icons.save : Icons.check),
            label: Text(isEditing ? 'Atualizar' : 'Criar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isEditing ? Colors.blue[600] : Colors.green[600],
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

  Future<bool> _saveProduct({required bool isEditing}) async {
    try {
      if (!_formKey.currentState!.validate()) {
        return false;
      }

      // Ativar wake lock temporariamente durante a operação
      final appController = Get.find<AppController>();
      appController.enableWakeLockTemporarily();

      final product = Product(
        id: _idController.text.trim(),
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text),
        price2: _price2Controller.text.isNotEmpty ? double.parse(_price2Controller.text) : null,
        description: _descriptionController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
        category: _categoryController.text.trim().isNotEmpty ? _categoryController.text.trim() : null,
        stock: _stockController.text.isNotEmpty ? int.parse(_stockController.text) : 0,
      );

      bool success;
      if (isEditing) {
        success = await adminController.updateProduct(product);
      } else {
        success = await adminController.createProduct(product);
      }

      if (success) {
        await productController.refreshProducts();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  // Função utilitária para montar a URL completa da imagem
  String getFullImageUrl(String imageUrl) {
    if (imageUrl.isEmpty) return '';
    if (imageUrl.startsWith('http')) return imageUrl;
    return 'https://elostupi.csmpanel.ovh/$imageUrl';
  }

  // Função para obter produtos filtrados por categoria
  List<Product> getFilteredProducts() {
    if (_selectedCategory == null || _selectedCategory == 'Todas') {
      return productController.products;
    }
    return productController.products.where((product) => 
      product.category == _selectedCategory
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Produtos'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => productController.refreshProducts(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar produtos',
          ),
          IconButton(
            onPressed: () => _showProductForm(),
            icon: const Icon(Icons.add),
            tooltip: 'Adicionar novo produto',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Filtro de categorias
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
                    Icon(Icons.filter_list, color: Colors.blue[600], size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Categorias:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 16),
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
                            setState(() {
                              _selectedCategory = value;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(width: 12),
                    // Botão para limpar filtro
                    if (_selectedCategory != null && _selectedCategory != 'Todas')
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _selectedCategory = null;
                          });
                        },
                        icon: Icon(Icons.clear, color: Colors.red[600]),
                        tooltip: 'Limpar filtro',
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
                  
                  final filteredProducts = getFilteredProducts();
                  
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
                                setState(() {
                                  _selectedCategory = null;
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
                                      // Preço e botões de ação
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey[200]!),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Preço
                                            Flexible(
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: Colors.green[50],
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: Colors.green[200]!,
                                                  ),
                                                ),
                                                child: Text(
                                                  '€${product.price.toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green[700],
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Botões de ação
                                            Row(
                                              children: [
                                                // Botão Editar
                                                Container(
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [Colors.blue[400]!, Colors.blue[600]!],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    ),
                                                    borderRadius: BorderRadius.circular(8),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.blue.withValues(alpha: 0.3),
                                                        blurRadius: 4,
                                                        offset: const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      borderRadius: BorderRadius.circular(8),
                                                      onTap: () => _showProductForm(editProduct: product),
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                        child: const Icon(
                                                          Icons.edit,
                                                          size: 16,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                // Botão Excluir
                                                Container(
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [Colors.red[400]!, Colors.red[600]!],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    ),
                                                    borderRadius: BorderRadius.circular(8),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.red.withValues(alpha: 0.3),
                                                        blurRadius: 4,
                                                        offset: const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      borderRadius: BorderRadius.circular(8),
                                                      onTap: () => _deleteProduct(product.id),
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                        child: const Icon(
                                                          Icons.delete,
                                                          size: 16,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
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