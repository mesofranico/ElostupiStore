# Funcionalidades de Upload de Imagens - ElosTupi

## Visão Geral

O sistema agora suporta duas formas de adicionar imagens aos produtos:

1. **📁 Upload de Imagem Local** - Carregar ficheiros diretamente do computador
2. **🌐 URL da Imagem** - Fornecer um link para uma imagem online

## Funcionalidades Implementadas

### ✅ Upload de Imagens Locais

- **Formatos Suportados**: JPG, JPEG, PNG, GIF, WebP
- **Tamanho Máximo**: 5MB por imagem
- **Validação**: Verificação automática de tipo e tamanho de ficheiro
- **Armazenamento**: As imagens são guardadas na pasta `web/imagens/`
- **Nomenclatura**: `{ID_DO_PRODUTO}.{EXTENSÃO}` (ex: `PROD001.jpg`)

### ✅ URL de Imagens

- **Compatibilidade**: Mantida a funcionalidade existente
- **Download Automático**: Imagens de URLs são automaticamente descarregadas e guardadas localmente
- **Fallback**: Se o upload local falhar, o sistema tenta usar o URL

### ✅ Interface Melhorada

- **Pré-visualização**: Visualização instantânea da imagem selecionada
- **Design Responsivo**: Interface adaptada para dispositivos móveis
- **Feedback Visual**: Indicadores claros de estado e progresso
- **Validação em Tempo Real**: Verificação imediata de formatos e tamanhos

## Ficheiros Modificados

### 1. `add_product.php`
- Adicionado suporte para upload de ficheiros
- Interface com duas opções: upload local ou URL
- Validação de ficheiros
- Pré-visualização de imagens

### 2. `edit_product.php`
- Suporte para atualizar imagens existentes
- Mostra a imagem atual do produto
- Opção de manter, substituir ou adicionar nova imagem
- Preserva a imagem atual se nenhuma nova for fornecida

### 3. `duplicate_product.php`
- Suporte para upload de imagens ao duplicar produtos
- Copia automaticamente a imagem do produto original
- Permite substituir por uma nova imagem

### 4. `web/imagens/.htaccess`
- Proteção da pasta de imagens
- Permite apenas acesso a ficheiros de imagem
- Configurações de cache e compressão

## Como Utilizar

### Adicionar Novo Produto
1. Aceda a "Adicionar Produto"
2. Preencha os campos obrigatórios
3. Na secção "Imagem do Produto":
   - **Opção A**: Clique em "Carregar Imagem Local" e selecione um ficheiro
   - **Opção B**: Introduza um URL de imagem
4. A imagem será automaticamente processada e guardada

### Editar Produto Existente
1. Aceda à lista de produtos e clique em "Editar"
2. A imagem atual será mostrada
3. Pode:
   - Manter a imagem atual (não fazer nada)
   - Carregar uma nova imagem local
   - Fornecer um novo URL
4. As alterações serão aplicadas ao guardar

### Duplicar Produto
1. Na lista de produtos, clique em "Duplicar"
2. A imagem do produto original será copiada automaticamente
3. Pode optar por substituir por uma nova imagem
4. O novo produto será criado com a imagem escolhida

## Segurança

- **Validação de Tipos**: Apenas ficheiros de imagem são aceites
- **Limite de Tamanho**: Máximo 5MB por ficheiro
- **Proteção da Pasta**: Acesso restrito apenas a ficheiros de imagem
- **Sanitização**: Nomes de ficheiro são limpos e seguros

## Estrutura de Ficheiros

```
web/
├── imagens/           # Pasta para imagens carregadas
│   ├── .htaccess     # Proteção da pasta
│   ├── PROD001.jpg   # Exemplo de imagem
│   └── PROD002.png   # Exemplo de imagem
├── add_product.php   # Adicionar produtos com upload
├── edit_product.php  # Editar produtos com upload
├── duplicate_product.php # Duplicar produtos com upload
└── ...
```

## Notas Técnicas

- **Compatibilidade**: Funciona com todos os navegadores modernos
- **Performance**: Imagens são otimizadas automaticamente
- **Backup**: Imagens antigas são preservadas até serem substituídas
- **Erro Handling**: Mensagens de erro claras e informativas

## Suporte

Para questões ou problemas relacionados com o upload de imagens, verifique:
1. Se o ficheiro é um formato suportado
2. Se o tamanho não excede 5MB
3. Se a pasta `web/imagens/` tem permissões de escrita
4. Se o servidor suporta upload de ficheiros 