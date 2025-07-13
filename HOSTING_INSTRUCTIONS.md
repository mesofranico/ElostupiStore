# 🌐 Instruções para Hospedar JSONs no ElosTupi.pt

## 📁 Arquivos para Hospedar

Você precisa hospedar os seguintes arquivos no seu servidor:

### **1. Arquivo Principal:**
- **Caminho:** `https://elostupi.pt/store/products.json`
- **Arquivo:** `products.json` (10 produtos completos)

### **2. Arquivo de Backup:**
- **Caminho:** `https://elostupi.pt/store/products-backup.json`
- **Arquivo:** `products-backup.json` (5 produtos essenciais)

## 🚀 Como Hospedar

### **Opção 1: Servidor Web (Apache/Nginx)**

1. **Crie a pasta:** `/store/` no seu servidor
2. **Faça upload dos arquivos:**
   ```
   /store/products.json
   /store/products-backup.json
   ```
3. **Configure CORS** (se necessário):
   ```apache
   # .htaccess
   Header set Access-Control-Allow-Origin "*"
   Header set Access-Control-Allow-Methods "GET, OPTIONS"
   Header set Access-Control-Allow-Headers "Content-Type"
   ```

### **Opção 2: CDN (Cloudflare, etc.)**

1. **Faça upload** dos arquivos para o CDN
2. **Configure as URLs** para apontar para:
   - `https://elostupi.pt/store/products.json`
   - `https://elostupi.pt/store/products-backup.json`

### **Opção 3: GitHub Pages**

1. **Crie um repositório** no GitHub
2. **Adicione os arquivos** na pasta `/store/`
3. **Configure GitHub Pages** para o domínio `elostupi.pt`

## 🔧 Configuração do Servidor

### **Headers Necessários:**
```
Content-Type: application/json
Access-Control-Allow-Origin: *
Cache-Control: public, max-age=300
```

### **Estrutura de Pastas:**
```
elostupi.pt/
├── store/
│   ├── products.json
│   └── products-backup.json
└── ... (outros arquivos do site)
```

## 📊 Testando

### **1. Teste no Navegador:**
Acesse: `https://elostupi.pt/store/products.json`

**Resposta esperada:**
```json
[
  {
    "id": "1",
    "name": "Smartphone Galaxy S23",
    "price": 2999.99,
    ...
  }
]
```

### **2. Teste com curl:**
```bash
curl -I https://elostupi.pt/store/products.json
```

**Headers esperados:**
```
HTTP/1.1 200 OK
Content-Type: application/json
Access-Control-Allow-Origin: *
```

## 🔄 Atualizando Produtos

### **Para adicionar/editar produtos:**

1. **Edite o arquivo** `products.json`
2. **Faça upload** para o servidor
3. **Limpe o cache** da aplicação (opcional)

### **Exemplo de novo produto:**
```json
{
  "id": "11",
  "name": "Novo Produto",
  "price": 999.99,
  "description": "Descrição do novo produto",
  "imageUrl": "https://exemplo.com/imagem.jpg",
  "category": "Nova Categoria",
  "stock": 10,
  "createdAt": "2024-01-15T10:00:00Z",
  "updatedAt": "2024-01-15T10:00:00Z"
}
```

## 🛡️ Segurança

### **Recomendações:**
- ✅ **HTTPS obrigatório** - Sempre use HTTPS
- ✅ **CORS configurado** - Permita acesso do app Flutter
- ✅ **Cache adequado** - Configure cache de 5 minutos
- ✅ **Backup automático** - Mantenha o arquivo de backup atualizado

### **Monitoramento:**
- **Logs de acesso** - Monitore requisições
- **Uptime** - Verifique disponibilidade
- **Performance** - Teste velocidade de carregamento

## 📱 Aplicação Flutter

A aplicação está configurada para:

1. **Tentar carregar** de `https://elostupi.pt/store/products.json`
2. **Se falhar** → tenta `https://elostupi.pt/store/products-backup.json`
3. **Se ambas falharem** → usa produtos padrão locais
4. **Cache local** de 5 minutos para performance

## 🎯 URLs Finais

- **Principal:** `https://elostupi.pt/store/products.json`
- **Backup:** `https://elostupi.pt/store/products-backup.json`

A aplicação Flutter já está configurada para usar essas URLs! 