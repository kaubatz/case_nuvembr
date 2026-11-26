# Medidas DAX – Painel Executivo

As regras de negócio ficam no SQL (views `dw.vw_*`). No DAX, as medidas só selecionam o mês e somam.
- **Mês:** vinculo da competencia_key com as respectivas tabelas, filtrado no visual Ano / Mês
- **Período:** ignora o filtro de mês (`ALL`).

```dax
-- Cartões do mês (vw_kpis_mensais)
Receita Bruta = vw_kpis_mensais[receita_bruta] 

Créditos Aplicados = vw_kpis_mensais[creditos_aplicados]

% Créditos = DIVIDE ( [Créditos Aplicados], [Receita Bruta] )

Receita Líquida = vw_kpis_mensais[receita_liquida]

Crescimento MoM = vw_kpis_mensais[crescimento_mom]

Inadimplência =
VAR mes = MAX ( vw_kpis_mensais[competencia_key] )
RETURN CALCULATE ( SUM ( vw_kpis_mensais[inadimplencia] ), vw_kpis_mensais[competencia_key] = mes )

Receita Não Faturada =
VAR mes = MAX ( vw_kpis_mensais[competencia_key] )
RETURN CALCULATE ( SUM ( vw_kpis_mensais[receita_nao_faturada] ), vw_kpis_mensais[competencia_key] = mes )

NRR = vw_kpis_mensais[nrr]

Clientes Ativos = vw_kpis_mensais[clientes_ativos]

Clientes Novos = vw_kpis_mensais[clientes_novos] 

Clientes Churn = vw_kpis_mensais[clientes_churn] 

-- Cartões do período (vw_kpis_mensais)
Líquido Período       = CALCULATE ( SUM ( vw_kpis_mensais[receita_liquida] ),      ALL ( vw_kpis_mensais ) )
Inadimplência Período = CALCULATE ( SUM ( vw_kpis_mensais[inadimplencia] ),        ALL ( vw_kpis_mensais ) )
Não Faturado Período  = CALCULATE ( SUM ( vw_kpis_mensais[receita_nao_faturada] ), ALL ( vw_kpis_mensais ) )

-- Concentração (vw_concentracao_clientes)
Top 10 % Receita =
CALCULATE ( SUM ( vw_concentracao_clientes[participacao] ), vw_concentracao_clientes[posicao] <= 10 )

-- Consumo por categoria e região (fato_consumo_diario)
fato_consumo_diario[receita_medida] 
```

## Visuais sem medida (campos direto da view)
| Visual | Campos |
|---|---|
| Receita líquida por segmento e MoM | `vw_receita_mensal[receita_liquida]` por `segmento`; linha `vw_kpis_mensais[crescimento_mom]` |
| Perda de receita | `vw_kpis_mensais[receita_nao_faturada]` e `[inadimplencia]` por `competencia` |
| Top 10 clientes | `vw_concentracao_clientes[receita_liquida]`, `[participacao]`, filtro `posicao <= 10` |

## Modelo
`dCalendario[data_key]` → `competencia_key` das views e `data_key` da `fato_consumo_diario` (muitos para um, filtro em direção única). `fato_consumo_diario[produto_sk]` → `dim_produto`.
