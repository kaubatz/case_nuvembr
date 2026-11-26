# Dicionário de dados e linhagem

`CSV → raw (texto) → stg (tipos e correções) → dw (dimensões e fatos) → Power BI`

## Colunas em comum nas camadas
| Origem → dw | Colunas |
|---|---|
| crm_clientes + crm_segmento_historico → dim_cliente | cliente_id, razao_social, cnpj_raiz, canal, uf, data_inicio, segmento, valido_de, valido_ate |
| billing_contas → dim_conta | conta_id, cliente_id, cnpj_raiz, data_criacao |
| consumo_diario → dim_produto, fato_consumo_diario | produto, unidade, preco_unitario, regiao, quantidade, lote_id |
| faturas → fato_fatura | fatura_id, status, valor_bruto, valor_creditos, valor_liquido, fatura_substituta_id |
| creditos → fato_credito | credito_id, tipo, valor |
| tickets → fato_ticket | ticket_id, aberto_em, resolvido_em, severidade, categoria |

Nos fatos, `conta_id`, `cliente_id` e `produto` viram `conta_sk`, `cliente_sk` e `produto_sk`. As datas viram `data_key`, `competencia_key`, `emissao_key` e `abertura_key`.

## Colunas calculadas
- `stg.consumo_diario.quantidade`: quantidade em unidade-base; ×1024 quando veio em TB-dia (DQ-02). Vem de quantidade e unidade.
- `stg.consumo_diario.receita` → `fato_consumo_diario.receita_medida`: quantidade × preço, só do lote mais recente (DQ-01). Vem de quantidade, preco_unitario e carregado_em.
- `stg.consumo_diario.flag_unidade_convertida`: 1 quando veio em TB-dia. Vem de unidade.
- `stg.faturas.valor_liquido`: bruto − créditos, recalculado (DQ-04). Vem de valor_bruto e valor_creditos.
- `stg.faturas.flag_liquido_recalculado`: 1 quando o líquido original estava diferente. Vem de valor_liquido.
- `stg.faturas.is_valida`: 0 para fatura cancelada. Vem de status.
- `stg.faturas.is_reemissao`: 1 para a fatura que substitui uma cancelada. Vem de fatura_substituta_id.
- `stg.billing_contas.cliente_id`: cliente recuperado pelo CNPJ quando vazio (DQ-05). Vem de billing_contas.cnpj_raiz e crm_clientes.
- `stg.crm_segmento_historico.valido_ate_fim` / `is_vigente`: vigência aberta = 31/12/9999 e vigente = 1. Vem de valido_ate.
- `stg.creditos.ticket_id`: código TK-… do chamado. Vem de descricao.
- `stg.tickets.aberto_em`: abertura convertida de UTC para UTC−3 (DQ-09). Vem de aberto_em.
- `stg.tickets.horas_resolucao`: horas entre abertura e resolução. Vem de aberto_em e resolvido_em.
- `stg.tickets.severidade_nivel`: número da severidade (S1 = 1). Vem de severidade.
- `fato_credito.flag_sla_sem_indisponibilidade`: crédito SLA de ticket que não é de indisponibilidade (DQ-07). Vem de creditos e tickets.categoria.
- `fato_credito.flag_credito_fora_regra`: promocional depois do 1º mês; informativa, porque a DQ-06 foi descartada. Vem de creditos e crm_clientes.data_inicio.
- `fato_ticket.flag_ticket_antes_da_conta`: chamado aberto antes da criação da conta (DQ-10). Vem de tickets e billing_contas.data_criacao.
- `fato_ticket.tem_credito_sla`: o chamado gerou crédito SLA. Vem de creditos.descricao.
- `fato_conciliacao_mensal.diferenca_medido_faturado`: consumo medido − bruto faturado, por conta × mês (DQ-03). Vem de consumo_diario e faturas.
- `fato_conciliacao_mensal.credito_nao_aplicado`: crédito concedido − crédito na fatura (DQ-08). Vem de creditos e faturas.
- `fato_conciliacao_mensal.status_conciliacao`: OK, FATURADO A MENOR, FATURADO A MAIOR, SEM FATURA ou SEM CONSUMO (tolerância de R$ 0,05). Vem da diferença acima.

## Métricas
- Receita bruta: consumo cobrado antes dos créditos - SUM(valor_bruto) - fato_fatura - só faturas válidas
- Créditos aplicados: créditos descontados nas faturas - SUM(valor_creditos); % = créditos ÷ bruto - fato_fatura - só faturas válidas
- Receita líquida: receita oficial, valor cobrado - bruto − créditos - fato_fatura - líquido recalculado (DQ-04)
- Crescimento MoM: variação da líquida contra o mês anterior - líquida ÷ líquida anterior − 1 - vw_kpis_mensais - vazio no 1º mês
- Inadimplência: faturas vencidas e não pagas - SUM(valor_liquido) com status VENCIDA - fato_fatura - out/26 ainda no prazo
- Receita não faturada: consumo medido e não cobrado - medido − bruto, quando positivo - fato_conciliacao_mensal - tolerância R$ 0,05 (DQ-03)
- Créditos SLA a revisar: SLA de ticket que não é de indisponibilidade - SUM(valor) com a flag - fato_credito - DQ-07
- Clientes ativos: clientes com receita no mês - contagem com bruta > 0 - vw_cliente_mes - por cliente, não por conta
- Clientes novos: clientes que começaram no mês - contagem por data_inicio - stg.crm_clientes - mês de data_inicio
- Churn: ativo no mês anterior e sem receita no mês - contagem com anterior > 0 e atual = 0 - vw_cliente_mes - receita bruta
- NRR (mensal): retenção da receita dos clientes do mês anterior - bruta atual ÷ bruta anterior dos clientes com anterior > 0 - vw_cliente_mes - inclui quem saiu, exclui novos
- Receita por segmento: líquida pelo segmento do cliente no mês - SUM(valor_liquido) por segmento - fato_fatura + dim_cliente - segmento no último dia do mês (SCD2)
- Top 10 clientes: participação dos 10 maiores na receita do período - receita do cliente ÷ total, posição ≤ 10 - vw_concentracao_clientes - por cliente_id
- Consumo medido: quantidade × preço por produto e região - SUM(receita_medida) - fato_consumo_diario - DQ-01 e DQ-02; não é receita faturada
