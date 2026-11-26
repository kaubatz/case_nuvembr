## NuvemBR 

**Engine:** SQL Server 2019+ (SQL Server Express + SSMS) · **BI:** Power BI

## Arquitetura
```
CSVs → raw (cópia fiel, texto) → stg (limpeza por tabela) → dw (star schema + métricas) → Power BI
                               ↘ dq (perfilamento, evidências e testes)
```

## Arquivos 
| Arquivo | Conteúdo |
|---|---|
| `1_sql/` | scripts SQL comentados (raw, stg, dw, dq) |
| `2_modelo_dimensional.pdf` | star schema com o grão de cada fato |
| `3_relatorio_executivo.pdf` | achados, recomendações e premissas |
| `4_Relatorio_Anomalias.xlsx` | problema, evidência, impacto R$, tratamento e dono |
| `5_dicionario_metricas.md` | definição, fórmula, origem e regras de cada métrica |
| `6_Painel Executivo.pbix` / `.pdf` | painel de 1 página |
| `7_log_uso_ia.md` | uso de IA e validação |
| `00docs/` | exploração dos dados, premissas e modelo |
| `00 arquivos/` | DDL de referência e leia-me do case |
| `00dados/` | os 7 CSVs |

## Como executar
1. Copie os CSVs de `00dados/` para `C:\dados\` (pasta que o serviço do SQL Server consiga ler) ou ajuste `@pasta` em `1_sql/01_raw/02_carga_raw.sql`.
2. Extraia o SQL em um diretório e troque o início dos caminhos das linhas `:r` em `1_sql/run_all.sql`.
3. Rode um dos dois:
   - SSMS: abra `1_sql/run_all.sql`, ative *Query → SQLCMD Mode* e pressione F5;
   - linha de comando: `1_sql/executar_pipeline.bat` (grava o log em `1_sql/logs/`).

O pipeline recria tudo do zero e para se algum teste falhar (`04_dq/10_testes_stg.sql` e `04_dq/20_testes_dw.sql`).

## Estrutura do SQL
| Pasta | Conteúdo |
|---|---|
| `1_sql/00_setup.sql` | banco e schemas |
| `1_sql/01_raw/` | tabelas da raw e carga dos CSVs |
| `1_sql/02_stg/` | 7 views de limpeza (uma por tabela de origem) |
| `1_sql/03_dw/` | dimensões, fatos e views de métricas |
| `1_sql/04_dq/` | perfilamento, queries de evidência DQ-01 a DQ-10 e testes |
