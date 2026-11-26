/* =====================================================================
   Script : 04_dq/20_testes_dw.sql
   Engine : SQL Server 2019+ | Camada: dw
   Objetivo: provar que o DW está íntegro e bate com a stg.
   Tipos de teste:
   - Contagem: cada fato tem o número de linhas esperado (o JOIN com a
     SCD2 não duplicou nem perdeu linhas).
   - Soma: os totais do DW são iguais aos da stg (nada se perdeu no caminho).
   - Chave: nenhum fato caiu no membro desconhecido (-1).
   - Regra: as marcações e a conciliação dão os números das DQs.
   Como ler: "resultado" = OK em todas as linhas. Se algum teste falhar, o
   script gera um erro no fim: o run_all/executar_pipeline.bat para e avisa.
   ===================================================================== */
USE NuvemBR;
GO

DROP TABLE IF EXISTS #testes;
CREATE TABLE #testes (teste VARCHAR(80), esperado DECIMAL(19,2), obtido DECIMAL(19,2));

-- Ordem: contagens, somas DW = stg, membro -1, regras das DQs, views de métricas
INSERT INTO #testes (teste, esperado, obtido)
SELECT 'dim_cliente: versões do cliente', 99, (SELECT COUNT(*) FROM dw.dim_cliente)
UNION ALL SELECT 'dim_conta: contas', 94, (SELECT COUNT(*) FROM dw.dim_conta)
UNION ALL SELECT 'dim_produto: produtos', 7, (SELECT COUNT(*) FROM dw.dim_produto)
UNION ALL SELECT 'fato_consumo = linhas da stg',
     (SELECT COUNT(*) FROM stg.consumo_diario), (SELECT COUNT(*) FROM dw.fato_consumo_diario)
UNION ALL SELECT 'fato_fatura = linhas da stg',
     (SELECT COUNT(*) FROM stg.faturas),        (SELECT COUNT(*) FROM dw.fato_fatura)
UNION ALL SELECT 'fato_credito = linhas da stg',
     (SELECT COUNT(*) FROM stg.creditos),       (SELECT COUNT(*) FROM dw.fato_credito)
UNION ALL SELECT 'fato_ticket = linhas da stg',
     (SELECT COUNT(*) FROM stg.tickets),        (SELECT COUNT(*) FROM dw.fato_ticket)
UNION ALL SELECT 'fato_conciliacao: pares conta x mês',           780, (SELECT COUNT(*) FROM dw.fato_conciliacao_mensal)
UNION ALL SELECT 'receita medida DW = stg',
     (SELECT ROUND(SUM(receita), 2) FROM stg.consumo_diario),
     (SELECT ROUND(SUM(receita_medida), 2) FROM dw.fato_consumo_diario)
UNION ALL SELECT 'receita bruta válida DW = stg',
     (SELECT SUM(valor_bruto) FROM stg.faturas WHERE is_valida = 1),
     (SELECT SUM(valor_bruto) FROM dw.fato_fatura WHERE is_valida = 1)
UNION ALL SELECT 'receita líquida válida (R$ 16.516.892,94)',  16516892.94,
     (SELECT SUM(valor_liquido) FROM dw.fato_fatura WHERE is_valida = 1)
UNION ALL SELECT 'créditos concedidos (R$ 105.190,83)',          105190.83, (SELECT SUM(valor) FROM dw.fato_credito)
UNION ALL SELECT 'fatos com cliente -1', 0,
     (SELECT COUNT(*) FROM dw.fato_consumo_diario WHERE cliente_sk = -1)
   + (SELECT COUNT(*) FROM dw.fato_fatura         WHERE cliente_sk = -1)
   + (SELECT COUNT(*) FROM dw.fato_credito        WHERE cliente_sk = -1)
   + (SELECT COUNT(*) FROM dw.fato_ticket         WHERE cliente_sk = -1)
   + (SELECT COUNT(*) FROM dw.fato_conciliacao_mensal WHERE cliente_sk = -1)
UNION ALL SELECT 'fatos com conta ou produto -1', 0,
     (SELECT COUNT(*) FROM dw.fato_consumo_diario WHERE conta_sk = -1 OR produto_sk = -1)
   + (SELECT COUNT(*) FROM dw.fato_fatura  WHERE conta_sk = -1)
   + (SELECT COUNT(*) FROM dw.fato_credito WHERE conta_sk = -1)
   + (SELECT COUNT(*) FROM dw.fato_ticket  WHERE conta_sk = -1)
UNION ALL SELECT 'conciliação OK',                                761, (SELECT COUNT(*) FROM dw.fato_conciliacao_mensal WHERE status_conciliacao = 'OK')
UNION ALL SELECT 'conciliação FATURADO A MENOR (DQ-03)',           19, (SELECT COUNT(*) FROM dw.fato_conciliacao_mensal WHERE status_conciliacao = 'FATURADO A MENOR')
UNION ALL SELECT 'receita não faturada R$ 102.771,02 (DQ-03)', 102771.02,
     (SELECT SUM(diferenca_medido_faturado) FROM dw.fato_conciliacao_mensal WHERE status_conciliacao = 'FATURADO A MENOR')
UNION ALL SELECT 'crédito não aplicado R$ 7,35 (DQ-08)',             7.35, (SELECT SUM(credito_nao_aplicado) FROM dw.fato_conciliacao_mensal)
UNION ALL SELECT 'líquido recalculado (DQ-04)',                     11, (SELECT COUNT(*) FROM dw.fato_fatura WHERE flag_liquido_recalculado = 1)
UNION ALL SELECT 'crédito fora da regra R$ 28.500 (DQ-06)',   28500.00, (SELECT SUM(valor) FROM dw.fato_credito WHERE flag_credito_fora_regra = 1)
UNION ALL SELECT 'SLA sem indisponibilidade (DQ-07)',               14, (SELECT COUNT(*) FROM dw.fato_credito WHERE flag_sla_sem_indisponibilidade = 1)
UNION ALL SELECT 'ticket antes da conta, horário local (DQ-10)',    48, (SELECT COUNT(*) FROM dw.fato_ticket WHERE flag_ticket_antes_da_conta = 1)
UNION ALL SELECT 'KPIs: líquido total = fato_fatura',
     (SELECT SUM(valor_liquido) FROM dw.fato_fatura WHERE is_valida = 1),
     (SELECT SUM(receita_liquida) FROM dw.vw_kpis_mensais)
UNION ALL SELECT 'receita por segmento = fato_fatura',
     (SELECT SUM(valor_liquido) FROM dw.fato_fatura WHERE is_valida = 1),
     (SELECT SUM(receita_liquida) FROM dw.vw_receita_mensal)
UNION ALL SELECT 'grade cliente x mês (90 x 10)',                  900, (SELECT COUNT(*) FROM dw.vw_cliente_mes);

SELECT teste, esperado, obtido,
       CASE WHEN ABS(esperado - obtido) <= 0.05 THEN 'OK' ELSE 'FALHOU' END AS resultado
FROM #testes;

-- Para automação: erro se algum teste falhou (o sqlcmd -b para a execução)
IF EXISTS (SELECT 1 FROM #testes WHERE ABS(esperado - obtido) > 0.05 OR obtido IS NULL)
    RAISERROR('Testes do DW falharam. Veja o resultado acima.', 16, 1);
GO
