/* =====================================================================
   Script : 03_dw/11_vw_cliente_mes.sql
   Engine : SQL Server 2019+ | Camada: dw
   Grão   : 1 linha por CLIENTE x COMPETÊNCIA, para TODOS os meses do
            período 

   Origem : dw.fato_fatura + dw.dim_cliente
   
   Por que a grade completa: churn e NRR(retenção liquida de receita) comparam o mês com o anterior.
   
   Sem a linha "receita 0", o cliente que saiu simplesmente sumiria.

   Colunas de apoio:
   - receita_bruta_mes_anterior (LAG): base do churn e do NRR (P-13).
   - is_ativo: receita bruta > 0 no mês.
   Esperado: 90 clientes x 10 meses = 900 linhas.
   ===================================================================== */
USE NuvemBR;
GO
CREATE OR ALTER VIEW dw.vw_cliente_mes AS
WITH meses AS (
    SELECT DISTINCT competencia_key FROM dw.fato_fatura WHERE is_valida = 1
),
clientes AS (
    SELECT DISTINCT cliente_id FROM dw.dim_cliente WHERE cliente_sk <> -1
),
receita AS (
    SELECT c.cliente_id, 
			f.competencia_key,
           SUM(f.valor_bruto) AS receita_bruta,
           SUM(f.valor_liquido) AS receita_liquida
    FROM dw.fato_fatura f
    JOIN dw.dim_cliente c ON c.cliente_sk = f.cliente_sk
    WHERE f.is_valida = 1
    GROUP BY c.cliente_id, f.competencia_key
),
grade AS (
    SELECT cl.cliente_id, m.competencia_key,
           COALESCE(r.receita_bruta, 0)   AS receita_bruta,
           COALESCE(r.receita_liquida, 0) AS receita_liquida
    FROM clientes cl
    CROSS JOIN meses m
    LEFT JOIN receita r
           ON r.cliente_id = cl.cliente_id AND r.competencia_key = m.competencia_key
)
SELECT g.cliente_id,
       g.competencia_key,
       d.ano_mes AS competencia,
       g.receita_bruta,
       g.receita_liquida,
       LAG(g.receita_bruta, 1, 0) OVER (PARTITION BY g.cliente_id ORDER BY g.competencia_key) AS receita_bruta_mes_anterior, -- ve a linha anterior -> lag(campo,linhas antes, retorno padrao)
       CASE WHEN g.receita_bruta > 0 THEN 1 ELSE 0 END AS is_ativo
FROM grade g
JOIN dw.dim_data d ON d.data_key = g.competencia_key;
GO
