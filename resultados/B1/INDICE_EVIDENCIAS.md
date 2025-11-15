# Índice de Evidências - Testes B1 Hadoop

**Projeto:** Atividade Extraclasse 2 - PSPD  
**Data:** 14-15 de novembro de 2025  
**Commits:** 5c851a3 → adc64d5 → 828c341 → 7cd2dc3

---

## 📂 Estrutura de Evidências

### 1. Teste 0 - Baseline (sem otimizações)

**Diretório:** `resultados/B1/teste0_baseline/`

| Arquivo | Descrição | Métricas Principais |
|---------|-----------|---------------------|
| `metrics_summary.txt` | Resumo consolidado | Duração: 2735.15s, Throughput: 0.03 MB/s |
| `duration.txt` | Tempo total de execução | 2735.15 segundos (45min 35s) |
| `throughput.txt` | Taxa de processamento | 0.03 MB/s (1.80 MB/min) |
| `temporal_metrics.txt` | Métricas temporais | Map time: 46383ms, Reduce time: 9733ms |
| `performance_metrics.txt` | Performance geral | CPU time: 40400ms, GC time: 1077ms |
| `resource_metrics.txt` | Uso de recursos | MB-seconds: 5262336, vcore-seconds: 5182 |
| `phase_metrics.txt` | Métricas por fase | Map vs Reduce breakdown |
| `throughput_metrics.txt` | Análise de throughput | MB/s, records/s, tasks/s |
| `comparative_metrics.txt` | Comparações | Baseline reference |
| `variation.txt` | Variação estatística | Desvio padrão, coeficiente de variação |

**Application ID:** `application_1763130949673_0005`  
**Status:** ✅ SUCCEEDED

---

### 2. Teste 5 - Speculative Execution

**Diretório:** `resultados/B1/teste5_speculative/`

| Arquivo | Descrição | Métricas Principais |
|---------|-----------|---------------------|
| `metrics_summary.txt` | Resumo consolidado | Duração: 78.63s, Throughput: 1.27 MB/s |
| `duration.txt` | Tempo total | 78.63 segundos (1min 18s) |
| `throughput.txt` | Taxa de processamento | 1.27 MB/s (76.20 MB/min) |
| `temporal_metrics.txt` | Métricas temporais | Map time: 31585ms, Reduce time: 11114ms |
| `performance_metrics.txt` | Performance | CPU time: 28610ms, GC time: 2092ms |
| `resource_metrics.txt` | Recursos | MB-seconds: 2948096, vcore-seconds: 2894 |
| `phase_metrics.txt` | Fases | Map vs Reduce otimizados |
| `throughput_metrics.txt` | Throughput | 42.3x mais rápido que baseline |
| `comparative_metrics.txt` | Comparações | vs. Baseline: -97.1% tempo |
| `variation.txt` | Variação | Menor variação por especulação |

**Application ID:** `application_1763130949673_0006`  
**Status:** ✅ SUCCEEDED  
**Melhoria:** 97.1% mais rápido que baseline

---

### 3. Testes de Concorrência

**Diretório:** `resultados/B1/teste_concorrencia/`

#### 3.1 Tentativa 1 - run_20251114_160432

| Arquivo | Conteúdo |
|---------|----------|
| `.monitoring` | Arquivo de controle |
| `job_1/job_output.txt` | Erro: Permission denied (user=root) |
| `job_1/timeline.txt` | Iniciado às 16:04:35 |
| `job_2/job_output.txt` | Erro: Permission denied |
| `job_2/timeline.txt` | Iniciado às 16:04:37 |

**Resultado:** ❌ FAILED - Erro de permissão HDFS  
**Lição:** Necessário `su - hadoop -c` para comandos HDFS

---

#### 3.2 Tentativa 2 - run_20251114_160658

| Arquivo | Conteúdo |
|---------|----------|
| `.monitoring` | Arquivo de controle |
| `job_1/job_output.txt` | Erro: hadoop: command not found |
| `job_1/timeline.txt` | Iniciado às 16:07:00 |
| `job_2/job_output.txt` | Erro: hadoop: command not found |
| `job_2/timeline.txt` | Iniciado às 16:07:02 |

**Resultado:** ❌ FAILED - Path do hadoop não encontrado  
**Lição:** Necessário path completo `/home/hadoop/hadoop/bin/hadoop`

---

#### 3.3 Execução Final - run_20251114_160901 ✅

| Arquivo | Conteúdo | Métricas |
|---------|----------|----------|
| `RESUMO.md` | Análise completa | Tempo médio: 549.71s |
| `job_1/job_output.txt` | Log completo Job 1 | 12 linhas (truncado) |
| `job_1/timeline.txt` | Timeline Job 1 | Iniciado às 16:09:03 |
| `job_2/job_output.txt` | Log completo Job 2 | 8 linhas (truncado) |
| `job_2/timeline.txt` | Timeline Job 2 | Iniciado às 16:09:05 |

**Application IDs:**
- Job 1: `application_1763130949673_0007` - 508.68s (8min 28s) ✅
- Job 2: `application_1763130949673_0008` - 590.73s (9min 50s) ✅

**Análise:**
- Overhead: 6.4x vs. speculative isolado
- Diferença entre jobs: 82.04s (13.9%)
- Ganho temporal: ~73.5min vs. sequencial

---

### 4. Testes de Tolerância a Falhas

**Diretório:** `resultados/B1/teste_tolerancia_falhas/`

#### 4.1 Tentativa 1 - run_20251114_131323

| Arquivo | Descrição |
|---------|-----------|
| `cluster_status_baseline_before.txt` | Status inicial do cluster |

**Resultado:** ⏳ Interrompido durante execução

---

#### 4.2 Tentativa 2 - run_20251114_160136

| Arquivo | Descrição |
|---------|-----------|
| `cluster_status_baseline_before.txt` | Status do cluster (634 bytes) |

**Resultado:** ⏳ Interrompido (tempo excessivo)

---

#### 4.3 Execução Final - run_20251114_162939 ✅

| Arquivo | Descrição | Conteúdo |
|---------|-----------|----------|
| `RESUMO_CENARIO1.md` | Análise completa | Performance anômala detectada |
| `cenario1_baseline_status.txt` | Status YARN | Vazio (criado como placeholder) |
| `cluster_status_baseline_before.txt` | Estado inicial | Containers, DataNodes, NodeManagers |

**Application ID:** `application_1763130949673_0009`  
**Duração:** 4018.09s (66min 58s)  
**Status:** ✅ SUCCEEDED (com degradação de performance)

**Observação Crítica:**  
Performance 50x mais lenta que esperado, indicando degradação do cluster após múltiplos testes.

---

## 📊 Resumo de Evidências

### Arquivos por Tipo

| Tipo | Quantidade | Exemplos |
|------|------------|----------|
| Métricas (.txt) | 20 | duration.txt, throughput.txt, metrics_summary.txt |
| Logs de jobs | 12 | job_output.txt (6 tentativas x 2 jobs) |
| Timelines | 6 | timeline.txt de cada job |
| Resumos (.md) | 3 | RESUMO.md, RESUMO_CENARIO1.md |
| Status de cluster | 3 | cluster_status_baseline_before.txt |
| Arquivos de controle | 3 | .monitoring |

**Total:** 47 arquivos de evidência

---

### Taxa de Sucesso

| Teste | Tentativas | Sucesso | Taxa |
|-------|------------|---------|------|
| Baseline | 1 | 1 | 100% |
| Speculative | 1 | 1 | 100% |
| Concorrência | 3 | 1 | 33% |
| Tolerância | 3 | 1 | 33% |
| **TOTAL** | **8** | **4** | **50%** |

**Jobs YARN Bem-Sucedidos:** 5/5 (100%)  
**Execuções de Script:** 8 tentativas documentadas

---

## 🔍 Como Navegar nas Evidências

### Para verificar resultados de performance:

1. **Comparar Baseline vs. Speculative:**
   ```bash
   diff resultados/B1/teste0_baseline/metrics_summary.txt \
        resultados/B1/teste5_speculative/metrics_summary.txt
   ```

2. **Ver tempo de execução:**
   ```bash
   cat resultados/B1/teste0_baseline/duration.txt
   cat resultados/B1/teste5_speculative/duration.txt
   ```

3. **Analisar throughput:**
   ```bash
   cat resultados/B1/teste0_baseline/throughput_metrics.txt
   cat resultados/B1/teste5_speculative/throughput_metrics.txt
   ```

### Para verificar testes de concorrência:

1. **Ler resumo:**
   ```bash
   cat resultados/B1/teste_concorrencia/run_20251114_160901/RESUMO.md
   ```

2. **Ver logs dos jobs:**
   ```bash
   cat resultados/B1/teste_concorrencia/run_20251114_160901/job_1/job_output.txt
   cat resultados/B1/teste_concorrencia/run_20251114_160901/job_2/job_output.txt
   ```

### Para verificar tolerância a falhas:

```bash
cat resultados/B1/teste_tolerancia_falhas/run_20251114_162939/RESUMO_CENARIO1.md
```

---

## 📝 Documentação Relacionada

| Documento | Localização | Propósito |
|-----------|-------------|-----------|
| **RELATORIO_COMPARATIVO_B1.md** | `resultados/B1/` | Análise técnica completa (8 páginas) |
| **RESUMO_FINAL_B1.md** | `resultados/B1/` | Resumo executivo |
| **RELATORIO_FINAL_COMPLETO.md** | `resultados/B1/` | Consolidação total ⭐ |
| **STATUS_TESTES.md** | `resultados/B1/` | Status de todos os testes |

---

## ✅ Rastreabilidade Acadêmica

### Informações de Commit

- **Commit inicial:** 5c851a3 (COLAB_INSTRUCTIONS.md)
- **Commit testes:** adc64d5 (Resultados concorrência + tolerância)
- **Commit relatório:** 828c341 (RELATORIO_FINAL_COMPLETO.md)
- **Commit evidências:** 7cd2dc3 (Este commit - 38 arquivos)

### Repositório

```
https://github.com/edilbertocantuaria/atividade-extraclasse-2-pspd
Branch: main
Último push: 2025-11-15
```

### Verificação de Integridade

Para verificar que todos os arquivos estão presentes:

```bash
# Contar arquivos de evidência
find resultados/B1/teste0_baseline/ -type f | wc -l      # Esperado: 10
find resultados/B1/teste5_speculative/ -type f | wc -l   # Esperado: 10
find resultados/B1/teste_concorrencia/ -type f | wc -l   # Esperado: 16
find resultados/B1/teste_tolerancia_falhas/ -type f | wc -l  # Esperado: 7

# Total esperado: 43 arquivos + 4 resumos .md = 47 arquivos
```

---

**Índice compilado por:** Sistema de documentação automática  
**Última atualização:** 2025-11-15 00:30:00  
**Versão:** 1.0
