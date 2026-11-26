/* =====================================================================
   Script : 03_dw/10_vw_receita_mensal.sql
   Engine : SQL Server 2019+ | Camada: dw
   Grão   : 1 linha por COMPETÊNCIA x SEGMENTO

   Origem : dw.fato_fatura + dw.dim_cliente
   Uso    : receita por segmento no painel
   ===================================================================== */
USE NuvemBR;
GO
CREATE OR ALTER VIEW dw.vw_receita_mensal AS
SELECT d.ano_mes                       AS competencia,
       f.competencia_key,
       c.segmento,
       COUNT(*)                        AS faturas,
       COUNT(DISTINCT c.cliente_id)    AS clientes,
       SUM(f.valor_bruto)              AS receita_bruta,
       SUM(f.valor_creditos)           AS creditos_aplicados,
       SUM(f.valor_liquido)            AS receita_liquida
FROM dw.fato_fatura f
JOIN dw.dim_data    d ON d.data_key   = f.competencia_key
JOIN dw.dim_cliente c ON c.cliente_sk = f.cliente_sk
WHERE f.is_valida = 1
GROUP BY d.ano_mes, f.competencia_key, c.segmento;
GO
