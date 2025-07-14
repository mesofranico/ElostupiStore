import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_controller.dart';
import '../controllers/product_controller.dart';
import '../controllers/app_controller.dart';
import '../models/product.dart';
import '../widgets/product_actions.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
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
      barrierDismissible: true,
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
          ),
        ],
      ),
      body: Stack(
        children: [
          Row(
            children: [
              // Lista de produtos (lado esquerdo)
              Expanded(
                flex: 1,
                child: Obx(() {
                  if (productController.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (productController.products.isEmpty) {
                    return const Center(
                      child: Text('Nenhum produto encontrado'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: productController.products.length,
                    itemBuilder: (context, index) {
                      final product = productController.products[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: product.imageUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      product.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Colors.blueGrey),
                                    ),
                                  )
                                : const Icon(Icons.image, color: Colors.blueGrey),
                          ),
                          title: Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              '€${product.price.toStringAsFixed(2)}  |  Stock: ${product.stock}',
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ),
                          trailing: ProductActions(
                            product: product,
                            onEdit: () => _showProductForm(editProduct: product),
                            onDelete: () => _deleteProduct(product.id),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
          // Botão flutuante para novo produto
          Positioned(
            bottom: 32,
            right: 32,
            child: FloatingActionButton.extended(
              onPressed: () => _showProductForm(),
              icon: const Icon(Icons.add),
              label: const Text('Novo Produto'),
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
} 