# Testes de Visualização - Kibana Dashboard

## Objetivo
Validar a visualização em tempo real dos dados processados pelo Spark no dashboard Kibana.

## Status
🔄 **Em execução**

## Passos para Validação

### 1. Acessar Kibana
- URL: http://localhost:5601
- Status esperado: Interface do Kibana carregada

### 2. Criar Data View
1. Acessar: Stack Management → Data Views
2. Criar novo data view:
   - Nome: `wordcount*`
   - Timestamp field: @timestamp (ou none)

### 3. Verificar Dados no Discover
1. Acessar: Analytics → Discover
2. Selecionar data view `wordcount*`
3. Verificar se os documentos estão aparecendo

### 4. Criar Visualização Word Cloud
1. Acessar: Analytics → Visualize Library
2. Criar nova visualização
3. Tipo: Tag Cloud ou Bar Chart
4. Configurar:
   - Bucket: Terms aggregation
   - Field: `word.keyword`
   - Metric: Count ou Sum of `count`

### 5. Criar Dashboard
1. Acessar: Analytics → Dashboard
2. Adicionar a visualização criada
3. Configurar auto-refresh (5s ou 10s)

## Resultados Esperados

- [ ] Kibana acessível em http://localhost:5601
- [ ] Data view `wordcount*` criado com sucesso
- [ ] Documentos visíveis no Discover
- [ ] Word Cloud exibindo palavras processadas
- [ ] Dashboard atualizando em tempo real

## Capturas de Tela
_(Adicionar screenshots após validação)_

---
**Data do teste:** _Pendente_
**Testado por:** _Pendente_
