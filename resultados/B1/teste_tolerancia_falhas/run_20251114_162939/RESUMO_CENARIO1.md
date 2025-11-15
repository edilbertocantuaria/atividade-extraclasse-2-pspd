# Teste de Tolerância a Falhas - Cenário 1: Baseline

**Data:** 2025-11-14
**Timestamp:** 20251114_162939

## Configuração

- **Cenário:** Baseline (sem falhas, todos os workers ativos)
- **Cluster:** 1 Master + 2 Workers
- **Config:** Speculative execution habilitado
- **Dataset:** 100MB (~14.6M palavras)

## Resultados

### Application: application_1763130949673_0009

- **Início:** 1763148586705 (16:29:46)
- **Término:** 1763152604796 (17:36:44)
- **Duração:** 4018.09s (66min 58s)
- **Status:** SUCCEEDED ✓
- **Progresso:** 100%
- **AM Host:** worker2
- **Resource Allocation:** 8215379 MB-seconds, 8014 vcore-seconds

## Análise

**Observação crítica:** Este teste levou 67 minutos, muito mais que o esperado (78s do teste speculative standalone).

**Possíveis causas:**
1. Cluster pode ter ficado sem speculative execution ativo nesta execução
2. Contenção de recursos após múltiplos testes anteriores  
3. Necessidade de restart do cluster para liberar memória

**Comparações:**
- vs. Baseline original (teste0): 4018s vs. 2735s (+47% mais lento)
- vs. Speculative (teste5): 4018s vs. 79s (50x mais lento!)

**Conclusão:** Este resultado anômalo sugere que o cluster estava degradado. Recomenda-se restart do cluster antes de continuar os testes de falha.
