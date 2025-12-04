# �� Estrutura de Documentação

> **Guia rápido** para navegar pela documentação do projeto

---

## 🎯 Documentação Principal (COMECE AQUI)

### 🚀 [como_executar.md](como_executar.md)
**O QUE É:** Guia completo de execução do zero  
**QUANDO USAR:** Primeira vez executando o projeto ou precisa de instruções passo a passo  
**CONTEÚDO:**
- Pré-requisitos de hardware/software
- Execução B1 (Hadoop) - 6 passos
- Execução B2 (Spark Streaming) - 6 passos  
- Extensão ML (opcional)
- Troubleshooting completo
- Estrutura de resultados

### 📖 [README.md](README.md)
**O QUE É:** Visão geral do projeto  
**QUANDO USAR:** Entender o que o projeto faz  
**CONTEÚDO:**
- Visão geral B1/B2/ML
- Início rápido (comandos básicos)
- Requisitos
- Estrutura do projeto
- Links para documentação detalhada

### �� [STATUS_IMPLEMENTACAO.md](STATUS_IMPLEMENTACAO.md)
**O QUE É:** Status de conclusão de cada requisito  
**QUANDO USAR:** Verificar o que está implementado  
**CONTEÚDO:**
- Checklist B1 (Hadoop)
- Checklist B2 (Spark)
- Checklist ML
- Pendências

---

## 📂 Documentação por Componente

### B1 - Hadoop

#### Execução e Resultados
- **[como_executar.md](como_executar.md)** → Seção "B1: Apache Hadoop"
- **[resultados/B1/RELATORIO_FINAL_COMPLETO.md](resultados/B1/RELATORIO_FINAL_COMPLETO.md)** → Relatório consolidado com resultados

#### Documentação Técnica
- **[docs/hadoop.md](docs/hadoop.md)** → Arquitetura, configurações, troubleshooting
- **[docs/CONFIGURACOES_XML.md](docs/CONFIGURACOES_XML.md)** → Detalhes dos XMLs de configuração
- **[IMPLEMENTACAO_B1_COMPLETA.md](IMPLEMENTACAO_B1_COMPLETA.md)** → Documentação detalhada da implementação

#### Outros Relatórios B1
- `resultados/B1/RELATORIO_COMPARATIVO_B1.md` → Comparação entre testes
- `resultados/B1/RESUMO_FINAL_B1.md` → Resumo executivo
- `resultados/B1/STATUS_TESTES.md` → Status de cada teste
- `resultados/B1/INDICE_EVIDENCIAS.md` → Índice de evidências/screenshots

### B2 - Spark Streaming

#### Execução
- **[como_executar.md](como_executar.md)** → Seção "B2: Apache Spark Streaming"
- **[spark/notebooks/B2_SPARK_STREAMING_COMPLETO.ipynb](spark/notebooks/B2_SPARK_STREAMING_COMPLETO.ipynb)** → Notebook principal (65 células)

#### Documentação
- **[resultados_spark/IMPLEMENTACAO_B2_COMPLETA.md](resultados_spark/IMPLEMENTACAO_B2_COMPLETA.md)** → Documentação detalhada da implementação
- **[resultados_spark/VALIDACAO_B2_DETALHADA.md](resultados_spark/VALIDACAO_B2_DETALHADA.md)** → Checklist de validação

#### Documentação Técnica
- **[docs/spark.md](docs/spark.md)** → Arquitetura, configurações, troubleshooting

### Extensão ML (Opcional)

- **[como_executar.md](como_executar.md)** → Seção "Extensão ML: Análise de Sentimentos"
- **[resultados_spark/EXTENSAO_ML_SENTIMENTOS.md](resultados_spark/EXTENSAO_ML_SENTIMENTOS.md)** → Documentação completa da extensão ML

---

## 🗺️ Fluxo de Navegação Sugerido

### Primeira Vez no Projeto
```
1. README.md (visão geral)
   ↓
2. como_executar.md (executar passo a passo)
   ↓
3. Executar notebooks/scripts
   ↓
4. Consultar STATUS_IMPLEMENTACAO.md (verificar conclusão)
```

### Executar B1 (Hadoop)
```
1. como_executar.md → Seção B1
   ↓
2. Executar scripts conforme instruções
   ↓
3. resultados/B1/RELATORIO_FINAL_COMPLETO.md (ver resultados)
```

### Executar B2 (Spark)
```
1. como_executar.md → Seção B2
   ↓
2. spark/notebooks/B2_SPARK_STREAMING_COMPLETO.ipynb
   ↓
3. resultados_spark/VALIDACAO_B2_DETALHADA.md (validar)
```

### Troubleshooting
```
1. como_executar.md → Seção "Troubleshooting"
   ↓
2. Se não resolver:
   - B1: docs/hadoop.md
   - B2: docs/spark.md
```

---

## 📁 Estrutura Completa de Arquivos .md

```
atividade-extraclasse-2-pspd/
├── como_executar.md                   ⭐ PRINCIPAL - Guia de execução completo
├── README.md                          ⭐ Visão geral do projeto
├── STATUS_IMPLEMENTACAO.md            ⭐ Status das implementações
├── IMPLEMENTACAO_B1_COMPLETA.md       Documentação detalhada B1
├── ESTRUTURA_DOCUMENTACAO.md          Este arquivo (índice da documentação)
│
├── docs/
│   ├── hadoop.md                      Documentação técnica Hadoop
│   ├── spark.md                       Documentação técnica Spark
│   └── CONFIGURACOES_XML.md           Detalhes das configurações XML
│
├── resultados/B1/
│   ├── RELATORIO_FINAL_COMPLETO.md    ⭐ Relatório consolidado B1
│   ├── RELATORIO_COMPARATIVO_B1.md    Comparação entre testes
│   ├── RESUMO_FINAL_B1.md             Resumo executivo B1
│   ├── STATUS_TESTES.md               Status individual dos testes
│   ├── INDICE_EVIDENCIAS.md           Índice de evidências
│   └── teste_*/                       Relatórios específicos por teste
│
├── resultados_spark/
│   ├── IMPLEMENTACAO_B2_COMPLETA.md   ⭐ Documentação completa B2
│   ├── VALIDACAO_B2_DETALHADA.md      Checklist de validação B2
│   └── EXTENSAO_ML_SENTIMENTOS.md     Documentação extensão ML
│
└── spark/notebooks/
    ├── README.md                       Instruções dos notebooks
    └── COLAB_INSTRUCTIONS.md          Instruções para Google Colab
```

---

## 🎯 Arquivos Essenciais (Top 5)

1. **[como_executar.md](como_executar.md)** - Guia de execução completo
2. **[README.md](README.md)** - Visão geral
3. **[resultados/B1/RELATORIO_FINAL_COMPLETO.md](resultados/B1/RELATORIO_FINAL_COMPLETO.md)** - Resultados B1
4. **[resultados_spark/IMPLEMENTACAO_B2_COMPLETA.md](resultados_spark/IMPLEMENTACAO_B2_COMPLETA.md)** - Implementação B2
5. **[STATUS_IMPLEMENTACAO.md](STATUS_IMPLEMENTACAO.md)** - Status do projeto

---

## 💡 Dicas

- **Perdido?** Comece pelo [README.md](README.md)
- **Quer executar?** Vá direto para [como_executar.md](como_executar.md)
- **Problemas?** Consulte seção Troubleshooting em [como_executar.md](como_executar.md)
- **Dúvidas técnicas?** Veja `docs/hadoop.md` ou `docs/spark.md`
- **Ver resultados?** Confira `resultados/B1/` ou `resultados_spark/`

---

**Última atualização:** 29/11/2025  
**Versão:** 1.0
