# Modelo dimensional

Diagrama: `2_modelo_dimensional.pdf` · Implementação: `1_sql/03_dw/`

## Objetivo
Uma base única para responder: **estamos crescendo de forma saudável?** e **onde estamos perdendo receita?**

## Fatos e grão
| Fato | Grão (1 linha por...) | Medidas |
|---|---|---|
| `fato_consumo_diario` | dia × conta × produto × região | quantidade, receita_medida |
| `fato_fatura` | fatura emitida | valor_bruto, valor_creditos, valor_liquido |
| `fato_credito` | crédito concedido | valor |
| `fato_ticket` | chamado | horas_resolucao |
| `fato_conciliacao_mensal` | conta × competência (agregada) | receita_medida, valor_bruto_faturado, diferença, créditos |

Cada evento tem um grão próprio; juntar numa fato só obrigaria a ratear valores. A conciliação é agregada porque a comparação medido × faturado só faz sentido no grão da fatura (conta × mês).

## Dimensões
| Dimensão | Grão | Tipo |
|---|---|---|
| `dim_data` | dia (2025–2026) | `data_key` = aaaammdd |
| `dim_cliente` | cliente × período do segmento | **SCD tipo 2** (98 versões; 8 clientes mudaram de segmento) |
| `dim_conta` | conta | SCD tipo 1 (`cliente_id` recuperado pelo CNPJ quando vazio, DQ-05) |
| `dim_produto` | produto | categoria de negócio; unidade-base única após DQ-02 |

`fatura_id`, `credito_id` e `ticket_id` ficam nas fatos como dimensões degeneradas.

## Mudança de atributos no tempo
- **Segmento → SCD2:** cada fato aponta para a versão do cliente vigente na data do fato, e a receita antiga fica no segmento da época.
- **Data usada:** consumo e ticket usam a data do evento; fatura, crédito e conciliação usam o último dia da competência (clientes novos começam no meio do mês).
- **Canal, UF e razão social → SCD1:** a origem não tem histórico.

## Views de métricas
| View | Grão | Uso |
|---|---|---|
| `vw_kpis_mensais` | mês | receita, crescimento, clientes, NRR, perdas |
| `vw_receita_mensal` | mês × segmento | receita por segmento |
| `vw_cliente_mes` | cliente × mês | base de churn e NRR |
| `vw_concentracao_clientes` | cliente | ranking e participação |
| `vw_suporte_mensal` | mês | chamados e tempo de resolução (sem DQ-10) |

## Fora do escopo
Dimensão de região (só 3 valores; ficou como coluna), histórico de canal, UF e preço (a origem não tem) e fato de pagamento (não há data de pagamento).
