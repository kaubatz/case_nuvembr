/* =====================================================================
   Script : 03_dw/12_vw_kpis_mensais.sql
   Engine : SQL Server 2019+ | Camada: dw
   Grão   : 1 linha por COMPETÊNCIA (visão da diretoria)

   Responde às duas perguntas do case:
   "Crescemos de forma saudável?"
     receita_liquida, 
	 crescimento_mom, 
	 clientes_ativos, 
	 clientes_novos,
     clientes_churn, 
	 receita_perdida_churn, 
	 nrr
   "Onde perdemos receita?"
     receita_nao_faturada (DQ-03), 
	 creditos por tipo e % sobre o bruto,
     inadimplencia (faturas VENCIDAS, líquido recalculado)
   ===================================================================== */

USE NuvemBR;
GO
CREATE OR ALTER VIEW dw.vw_kpis_mensais AS
WITH faturas AS (
    SELECT competencia_key,
           SUM(valor_bruto)    AS receita_bruta,
           SUM(valor_creditos) AS creditos_aplicados,
           SUM(valor_liquido)  AS receita_liquida,
           SUM(CASE WHEN status = 'VENCIDA' THEN valor_liquido ELSE 0 END) AS inadimplencia
    FROM dw.fato_fatura
    WHERE is_valida = 1
    GROUP BY competencia_key
),
creditos AS (
    SELECT competencia_key,
           SUM(CASE WHEN tipo = 'PROMOCIONAL' THEN valor ELSE 0 END) AS creditos_promocional,
           SUM(CASE WHEN tipo = 'SLA'         THEN valor ELSE 0 END) AS creditos_sla,
           SUM(CASE WHEN tipo = 'COMERCIAL'   THEN valor ELSE 0 END) AS creditos_comercial,
           SUM(CASE WHEN flag_sla_sem_indisponibilidade = 1 THEN valor ELSE 0 END) AS creditos_a_revisar
    FROM dw.fato_credito
    GROUP BY competencia_key
),
clientes AS (
    SELECT competencia_key,
           SUM(is_ativo) AS clientes_ativos,
           SUM(CASE WHEN receita_bruta_mes_anterior > 0 AND receita_bruta = 0 THEN 1 ELSE 0 END) AS clientes_churn, -- quant cliente faturou no mes anterior e nesse mes nao
           SUM(CASE WHEN receita_bruta_mes_anterior > 0 AND receita_bruta = 0
                    THEN receita_bruta_mes_anterior ELSE 0 END) AS receita_perdida_churn, -- -- receita anterior de cliente que faturou no mes anterior e nesse mes nao
           SUM(CASE WHEN receita_bruta_mes_anterior > 0 THEN receita_bruta ELSE 0 END) AS nrr_numerador, -- soma receita bruta atual de clientes que faturaram no mes anterior 
           SUM(CASE WHEN receita_bruta_mes_anterior > 0 THEN receita_bruta_mes_anterior ELSE 0 END) AS nrr_denominador -- soma receita bruta anterior de clientes que faturaram no mes anterior 
		   ---- calculo da retenção de receita bruta 
    FROM dw.vw_cliente_mes
    GROUP BY competencia_key
),
novos AS ( -- clientes novos de cada mes
    SELECT DATEFROMPARTS(YEAR(data_inicio), MONTH(data_inicio), 1) AS mes, COUNT(*) AS clientes_novos
    FROM stg.crm_clientes
    GROUP BY DATEFROMPARTS(YEAR(data_inicio), MONTH(data_inicio), 1)
),
conciliacao AS (
    SELECT competencia_key,
           SUM(CASE WHEN status_conciliacao = 'FATURADO A MENOR' THEN diferenca_medido_faturado ELSE 0 END) AS receita_nao_faturada,
           SUM(credito_nao_aplicado) AS credito_nao_aplicado
    FROM dw.fato_conciliacao_mensal
    GROUP BY competencia_key
)
SELECT d.ano_mes AS competencia,
       f.competencia_key,
       f.receita_bruta,
       f.creditos_aplicados,
       f.receita_liquida,
       f.receita_liquida / NULLIF(LAG(f.receita_liquida) OVER (ORDER BY f.competencia_key), 0) - 1 AS crescimento_mom, -- calcula receita atual / anterior = % MoM
       cl.clientes_ativos,
       COALESCE(n.clientes_novos, 0) AS clientes_novos,
       cl.clientes_churn,
       cl.receita_perdida_churn,
       CAST(cl.nrr_numerador / NULLIF(cl.nrr_denominador, 0) AS DECIMAL(9,4)) AS nrr,
       COALESCE(cr.creditos_promocional, 0) AS creditos_promocional,
       COALESCE(cr.creditos_sla, 0) AS creditos_sla,
       COALESCE(cr.creditos_comercial, 0) AS creditos_comercial,
       COALESCE(cr.creditos_a_revisar, 0) AS creditos_a_revisar,
       f.creditos_aplicados / NULLIF(f.receita_bruta, 0)  AS pct_creditos_sobre_bruto,
       COALESCE(co.receita_nao_faturada, 0) AS receita_nao_faturada,
       COALESCE(co.credito_nao_aplicado, 0) AS credito_nao_aplicado,
       f.inadimplencia
FROM faturas f

JOIN dw.dim_data d       ON d.data_key = f.competencia_key
LEFT JOIN creditos cr    ON cr.competencia_key = f.competencia_key
LEFT JOIN clientes cl    ON cl.competencia_key = f.competencia_key
LEFT JOIN novos n        ON n.mes = d.data
LEFT JOIN conciliacao co ON co.competencia_key = f.competencia_key;
GO
