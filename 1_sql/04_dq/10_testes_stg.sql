/* =====================================================================
   Script : 04_dq/10_testes_stg.sql
   Engine : SQL Server 2019+ | Camada: stg
   Objetivo: provar que cada tratamento da stg funcionou.
             É a mesma lógica das queries de evidência (DQ-xx), agora
             rodando na stg: o que antes mostrava o problema agora tem que
             voltar ZERO. Estes testes são os que rodariam todo dia na
             automação (Tarefa 5).

   Como ler: coluna "problemas" tem que ser 0 em todas as linhas e
   "resultado" = 'OK'. Se algum falhar, o script gera um erro no fim
   (usado pelo run_all/executar_pipeline.bat para parar a execução).
   ===================================================================== */

USE NuvemBR;
GO

DROP TABLE IF EXISTS #testes_stg;

WITH testes AS (

    -- DQ-01: nenhuma combinação dia x conta x produto x região repetida
    SELECT 'DQ-01 consumo sem duplicidade de lote' AS teste,
           COUNT(*) AS problemas
    FROM (SELECT data, conta_id, produto, regiao
          FROM stg.consumo_diario
          GROUP BY data, conta_id, produto, regiao
          HAVING COUNT(*) > 1) x

    UNION ALL
    -- DQ-02: nenhuma linha em TB-dia
    SELECT 'DQ-02 consumo sem TB-dia', COUNT(*)
    FROM stg.consumo_diario
    WHERE unidade = 'TB-dia'

    UNION ALL
    -- DQ-04: líquido = bruto − créditos em todas as faturas
    SELECT 'DQ-04 líquido consistente', COUNT(*)
    FROM stg.faturas
    WHERE ABS(valor_bruto - valor_creditos - valor_liquido) > 0.01

    UNION ALL
    -- DQ-05: toda conta com cliente, e todo cliente existe no CRM
    SELECT 'DQ-05 conta sem cliente', COUNT(*)
    FROM stg.billing_contas b
    LEFT JOIN stg.crm_clientes c ON c.cliente_id = b.cliente_id
    WHERE c.cliente_id IS NULL

    UNION ALL
    -- DQ-09: nenhum tempo de resolução negativo
    SELECT 'DQ-09 ticket com tempo negativo', COUNT(*)
    FROM stg.tickets
    WHERE horas_resolucao < 0

    UNION ALL
    -- P-02: 1 fatura válida por conta x competência
    SELECT 'P-02 1 fatura válida por conta x mês', COUNT(*)
    FROM (SELECT conta_id, competencia
          FROM stg.faturas
          WHERE is_valida = 1
          GROUP BY conta_id, competencia
          HAVING COUNT(*) > 1) x

    UNION ALL
    -- P-05: 1 segmento vigente por cliente
    SELECT 'P-05 1 segmento vigente por cliente', COUNT(*)
    FROM (SELECT cliente_id
          FROM stg.crm_segmento_historico
          GROUP BY cliente_id
          HAVING SUM(is_vigente) <> 1) x

    UNION ALL
    -- Conversão de tipos: nenhum valor virou NULL na conversão
    SELECT 'Tipos: conversão sem perda',
           (SELECT COUNT(*) FROM stg.consumo_diario
             WHERE data IS NULL OR quantidade IS NULL OR preco_unitario IS NULL)
         + (SELECT COUNT(*) FROM stg.faturas
             WHERE competencia_data IS NULL OR valor_bruto IS NULL OR valor_creditos IS NULL)
         + (SELECT COUNT(*) FROM stg.creditos WHERE valor IS NULL OR competencia_data IS NULL)
         + (SELECT COUNT(*) FROM stg.tickets  WHERE aberto_em IS NULL OR resolvido_em IS NULL)
)
SELECT teste, problemas INTO #testes_stg FROM testes;

SELECT teste,
       problemas,
       CASE WHEN problemas = 0 THEN 'OK' ELSE 'FALHOU' END AS resultado
FROM #testes_stg;

-- Para automação: erro se algum teste falhou (o sqlcmd -b para a execução)
IF EXISTS (SELECT 1 FROM #testes_stg WHERE problemas <> 0)
    RAISERROR('Testes da stg falharam. Veja o resultado acima.', 16, 1);

-- Totais de controle: conferem com os números esperados no cabeçalho de cada view.
--    Esperado: consumo 91.098 linhas / R$ 16.724.847,29 / 5.721 convertidas
SELECT COUNT(*)                     AS consumo_linhas,
       ROUND(SUM(receita), 2)       AS consumo_receita,
       SUM(flag_unidade_convertida) AS linhas_convertidas
FROM stg.consumo_diario;

--    Esperado: 780 faturas válidas / bruto R$ 16.622.076,42 / créditos R$ 105.183,48 /
--              líquido R$ 16.516.892,94 / 11 recalculadas / 5 reemissões
SELECT SUM(is_valida)                                          AS faturas_validas,
       SUM(CASE WHEN is_valida = 1 THEN valor_bruto    END)    AS bruto,
       SUM(CASE WHEN is_valida = 1 THEN valor_creditos END)    AS creditos,
       SUM(CASE WHEN is_valida = 1 THEN valor_liquido  END)    AS liquido,
       SUM(flag_liquido_recalculado)                           AS recalculadas,
       SUM(is_reemissao)                                       AS reemissoes
FROM stg.faturas;

--    Esperado: 14 créditos com ticket | média 20,56 h
SELECT (SELECT COUNT(*) FROM stg.creditos WHERE ticket_id IS NOT NULL)       AS creditos_com_ticket,
       (SELECT ROUND(AVG(horas_resolucao), 2) FROM stg.tickets)              AS media_horas_resolucao;
GO
