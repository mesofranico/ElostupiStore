# ElosTupi - Loja Flutter com GetX

Uma aplicação de loja moderna desenvolvida em Flutter usando GetX para gerenciamento de estado e GetStorage para persistência local.

## 🚀 Funcionalidades

### ✨ Interface Moderna
- Design responsivo que se adapta a diferentes tamanhos de tela
- Cards de produtos elegantes com gradientes e sombras
- Modo escuro/claro
- Animações suaves e feedback visual

### 🛒 Gerenciamento de Carrinho
- Adicionar/remover produtos
- Ajustar quantidades
- Cálculo automático de totais
- Persistência local com GetStorage

### 📱 Gerenciamento de Estado Robusto
- **GetX Controllers** para gerenciamento de estado reativo
- **GetStorage** para cache local e persistência
- **GetX Navigation** para navegação simplificada
- **GetX Snackbars** para notificações elegantes

### 🔧 Configurações
- Toggle de modo escuro/claro
- Configurações de notificações
- Atualização automática de produtos
- Interface de configurações intuitiva

### 🌐 Dados Dinâmicos
- Carregamento de produtos via JSON online
- Sistema de fallback para arquivo de backup
- Cache local inteligente
- Tratamento de erros robusto

## 🏗️ Arquitetura

### Controllers (GetX)
- **ProductController**: Gerencia produtos, filtros e cache
- **CartController**: Gerencia carrinho e persistência
- **AppController**: Gerencia configurações e tema

### Services
- **ProductService**: Busca produtos de APIs externas
- **StorageInit**: Inicialização do GetStorage

### Models
- **Product**: Modelo de produto com JSON serialization
- **CartItem**: Item do carrinho (definido no controller)

### Screens
- **ShopScreen**: Tela principal da loja
- **CartScreen**: Tela do carrinho
- **SettingsScreen**: Tela de configurações

## 📦 Dependências

```yaml
dependencies:
  flutter:
    sdk: flutter
  get: ^4.6.6          # Gerenciamento de estado e navegação
  get_storage: ^2.1.1  # Persistência local
  http: ^1.1.0         # Requisições HTTP
  cupertino_icons: ^1.0.8
```

## 🚀 Como Executar

1. **Clone o repositório**
   ```bash
   git clone <repository-url>
   cd elostupi
   ```

2. **Instale as dependências**
   ```bash
   flutter pub get
   ```

3. **Execute a aplicação**
   ```bash
   flutter run
   ```

## 🔧 Configuração

### URLs dos Produtos
A aplicação busca produtos das seguintes URLs:
- **Principal**: `https://elostupi.pt/products.json`
- **Backup**: `https://elostupi.pt/backup_products.json`

### Estrutura do JSON
```json
[
  {
    "id": "1",
    "name": "Nome do Produto",
    "description": "Descrição do produto",
    "price": 29.99,
    "imageUrl": "https://exemplo.com/imagem.jpg",
    "category": "Categoria"
  }
]
```

## 📱 Responsividade

A aplicação se adapta automaticamente a diferentes tamanhos de tela:

- **Smartphone** (< 600px): 2 colunas
- **Tablet** (600-900px): 3 colunas  
- **Desktop Pequeno** (900-1200px): 4 colunas
- **Desktop Grande** (> 1200px): 5 colunas

## 💾 Persistência Local

### GetStorage
- **Produtos**: Cache local com timestamp
- **Carrinho**: Persistência de itens e quantidades
- **Configurações**: Preferências do usuário

### Recuperação de Dados
- Carregamento automático do cache em caso de erro de rede
- Fallback inteligente entre URLs
- Notificações informativas sobre o estado dos dados

## 🎨 Temas

### Modo Claro
- Cores vibrantes e modernas
- Sombras sutis
- Gradientes azuis

### Modo Escuro
- Cores escuras elegantes
- Contraste otimizado
- Mesma funcionalidade visual

## 🔄 Atualizações

### Pull-to-Refresh
- Atualização manual na tela da loja
- Botão de refresh na AppBar
- Indicadores de loading

### Cache Inteligente
- Atualização automática quando possível
- Preservação de dados offline
- Sincronização transparente

## 🛠️ Desenvolvimento

### Estrutura de Pastas
```
lib/
├── controllers/     # GetX Controllers
├── services/        # Serviços de API
├── models/          # Modelos de dados
├── screens/         # Telas da aplicação
├── widgets/         # Widgets reutilizáveis
├── core/           # Configurações core
└── main.dart       # Ponto de entrada
```

### Padrões Utilizados
- **GetX Pattern**: Controllers reativos
- **Service Pattern**: Separação de responsabilidades
- **Repository Pattern**: Abstração de dados
- **Observer Pattern**: Reatividade com Obx

## 📈 Performance

- **Lazy Loading**: Carregamento sob demanda
- **Cache Local**: Redução de requisições
- **Widgets Otimizados**: Rebuilds seletivos
- **Navegação Eficiente**: GetX Navigation

## 🔒 Segurança

- **Validação de Dados**: Verificação de JSON
- **Tratamento de Erros**: Fallbacks robustos
- **Sanitização**: Limpeza de dados de entrada

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo LICENSE para mais detalhes.

## 🤝 Contribuição

Contribuições são bem-vindas! Por favor, leia as diretrizes de contribuição antes de submeter um pull request.

---

**ElosTupi** - Uma loja moderna e robusta desenvolvida com Flutter e GetX! 🛍️✨
