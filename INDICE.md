# 📚 Índice de Documentação - Hadoop B1

## 🎯 Início Rápido

**Primeira vez?** Comece aqui:
1. [STATUS_IMPLEMENTACAO.md](STATUS_IMPLEMENTACAO.md) - Ver o que foi feito
2. [COMANDOS_RAPIDOS.md](COMANDOS_RAPIDOS.md) - Executar em 3 comandos
3. [docs/GUIA_EXECUCAO_HADOOP.md](docs/GUIA_EXECUCAO_HADOOP.md) - Guia completo

---

## 📖 Documentação por Propósito

### Entender o que foi feito
- **[STATUS_IMPLEMENTACAO.md](STATUS_IMPLEMENTACAO.md)** ⭐ COMECE AQUI
  - Checklist completo de requisitos
  - Status de cada item
  - Resumo executivo

- **[RESUMO_IMPLEMENTACAO_B1.md](RESUMO_IMPLEMENTACAO_B1.md)**
  - Detalhes técnicos de cada implementação
  - Estrutura de resultados
  - Próximos passos

### Executar os testes
- **[COMANDOS_RAPIDOS.md](COMANDOS_RAPIDOS.md)** ⭐ MAIS USADO
  - 3 comandos para executar tudo
  - Referência rápida de comandos
  - Troubleshooting comum

- **[docs/GUIA_EXECUCAO_HADOOP.md](docs/GUIA_EXECUCAO_HADOOP.md)** ⭐ COMPLETO
  - Passo a passo detalhado
  - Execução modular
  - Análise de resultados
  - Solução de problemas

### Entender o projeto
- **[README.md](README.md)**
  - Visão geral do projeto
  - Requisitos
  - Instalação
  - Links para outras docs

---

## 🔧 Scripts Disponíveis

### Automação Completa
- **`scripts/run_all_tests.sh`** ⭐ PRINCIPAL
  - Executa todos os testes em sequência
  - Modo interativo
  - Gera relatório consolidado
  - **Duração**: 30-40 minutos

### Scripts Individuais
- **`scripts/generate_large_dataset.sh`**
  - Gera dataset massivo (500MB+)
  - Garante 3-4+ minutos de execução
  - Uso: `./generate_large_dataset.sh 500`

- **`scripts/test_fault_tolerance.sh`**
  - 4 cenários de tolerância a falhas
  - Remove/adiciona nós durante execução
  - **Duração**: 15-20 minutos

- **`scripts/test_concurrency.sh`**
  - Testa 2, 3 e 4 jobs simultâneos
  - Análise de contenção YARN
  - **Duração**: 10-15 minutos

- **`scripts/collect_metrics.sh`**
  - Sistema padronizado de métricas
  - Uso: `./collect_metrics.sh <app_id> <output_dir> [dataset_mb]`
  - Gera CSV e relatórios

---

## 📁 Configurações

### Testes de Configuração
1. `config/teste1_memoria/` - Memória YARN
2. `config/teste2_replicacao/` - Replicação HDFS
3. `config/teste3_blocksize/` - Tamanho de bloco
4. `config/teste4_reducers/` - Número de reducers
5. **`config/teste5_speculative/`** - Execução especulativa ⭐ NOVO

---

## 📊 Resultados

### Estrutura de Resultados
```
resultados/B1/
├── teste0_baseline/              # Referência
├── teste1_memoria/               # Memória YARN
├── teste2_replicacao/            # Replicação HDFS
├── teste3_blocksize/             # Block size
├── teste4_reducers/              # Número de reducers
├── teste5_speculative/           # Speculative execution ⭐ NOVO
├── teste_tolerancia_falhas/      # Cenários de falha
│   └── run_TIMESTAMP/
└── teste_concorrencia/           # Jobs concorrentes
    └── run_TIMESTAMP/
```

### Arquivos em Cada Resultado
- `job_output.txt` - Log completo do job
- `app_id.txt` - Application ID YARN
- `time_stats.txt` - Tempo de execução
- `config.txt` - Configuração utilizada
- `metrics_summary.txt` - Resumo de métricas
- `metrics_summary.csv` - Métricas em CSV
- `throughput_metrics.txt` - Throughput detalhado
- `performance_metrics.txt` - Performance geral

---

## 🎓 Documentação Técnica

### Hadoop
- [docs/hadoop.md](docs/hadoop.md) - Conceitos Hadoop
- [docs/tests.md](docs/tests.md) - Metodologia de testes

### Outros
- [CHANGELOG.md](CHANGELOG.md) - Histórico de mudanças
- [CONTRIBUTING.md](CONTRIBUTING.md) - Como contribuir
- [SUMMARY.md](SUMMARY.md) - Sumário do projeto

---

## 🚀 Fluxo de Trabalho Recomendado

### 1. Primeira Execução
```bash
# Ler status
cat STATUS_IMPLEMENTACAO.md

# Ver comandos rápidos
cat COMANDOS_RAPIDOS.md

# Executar tudo
cd hadoop && docker-compose up -d && cd ..
./scripts/run_all_tests.sh
```

### 2. Análise de Resultados
```bash
# Ver relatório final
cat resultados/B1/relatorio_final_completo.md

# Ver tolerância a falhas
cat resultados/B1/teste_tolerancia_falhas/run_*/relatorio_tolerancia_falhas.md

# Ver concorrência
cat resultados/B1/teste_concorrencia/run_*/relatorio_concorrencia.md
```

### 3. Testes Adicionais
```bash
# Consultar guia completo
cat docs/GUIA_EXECUCAO_HADOOP.md

# Executar testes específicos conforme necessário
```

---

## 🔍 Busca Rápida

### Preciso de...
- **Ver o que foi implementado**: [STATUS_IMPLEMENTACAO.md](STATUS_IMPLEMENTACAO.md)
- **Executar rapidamente**: [COMANDOS_RAPIDOS.md](COMANDOS_RAPIDOS.md)
- **Guia detalhado**: [docs/GUIA_EXECUCAO_HADOOP.md](docs/GUIA_EXECUCAO_HADOOP.md)
- **Entender estrutura**: [RESUMO_IMPLEMENTACAO_B1.md](RESUMO_IMPLEMENTACAO_B1.md)
- **Resolver problemas**: Seção Troubleshooting em [COMANDOS_RAPIDOS.md](COMANDOS_RAPIDOS.md)
- **Ver resultados**: `resultados/B1/relatorio_final_completo.md`

### Quero executar...
- **Tudo automaticamente**: `./scripts/run_all_tests.sh`
- **Gerar dataset**: `./scripts/generate_large_dataset.sh 500`
- **Teste de falhas**: `./scripts/test_fault_tolerance.sh`
- **Teste de concorrência**: `./scripts/test_concurrency.sh`
- **Coletar métricas**: `./scripts/collect_metrics.sh <app_id> <dir> <mb>`

---

## 📞 Ajuda Rápida

### Cluster não inicia?
```bash
# Ver COMANDOS_RAPIDOS.md seção "Troubleshooting"
cat COMANDOS_RAPIDOS.md | grep -A 20 "Troubleshooting"
```

### Job não executa?
```bash
# Ver logs
docker logs hadoop-master --tail 50
# Verificar HDFS
docker exec hadoop-master hdfs dfsadmin -report
```

### Não sei por onde começar?
```bash
# Leia nesta ordem:
cat STATUS_IMPLEMENTACAO.md           # 1. O que foi feito
cat COMANDOS_RAPIDOS.md              # 2. Como executar
cat docs/GUIA_EXECUCAO_HADOOP.md     # 3. Detalhes completos
```

---

## ✅ Checklist de Uso

- [ ] Li [STATUS_IMPLEMENTACAO.md](STATUS_IMPLEMENTACAO.md)
- [ ] Cluster Hadoop iniciado (`docker ps | grep hadoop`)
- [ ] Executei `./scripts/run_all_tests.sh` OU testes individuais
- [ ] Revisei relatórios em `resultados/B1/`
- [ ] Analisei métricas CSV
- [ ] Documentei conclusões

---

## 🏆 Resumo

**Tudo pronto para uso!**

- ✅ 5 configurações diferentes
- ✅ Dataset massivo (3-4+ min)
- ✅ Tolerância a falhas (4 cenários)
- ✅ Concorrência (3 níveis)
- ✅ Métricas padronizadas
- ✅ Automação completa
- ✅ Documentação extensiva

**Próximo passo**: 
```bash
./scripts/run_all_tests.sh
```

---

**Última atualização**: $(date '+%Y-%m-%d %H:%M:%S')
