/* =====================================================================
   Script : 03_dw/13_vw_concentracao_clientes.sql
   Engine : SQL Server 2019+ | Camada: dw
   Grão   : 1 linha por CLIENTE (período inteiro, jan–out/26)
   
   Uso    : risco de concentração ("crescimento saudável" também é não
            depender de poucos clientes).
   ===================================================================== */
USE NuvemBR;
GO
CREATE OR ALTER VIEW dw.vw_concentracao_clientes AS

WITH receita AS (
    SELECT c.cliente_id, SUM(f.valor_liquido) AS receita_liquida
    FROM dw.fato_fatura f
    JOIN dw.dim_cliente c ON c.cliente_sk = f.cliente_sk
    WHERE f.is_valida = 1
    GROUP BY c.cliente_id
)
,ranking AS (
    SELECT r.cliente_id,
           r.receita_liquida,

           ROW_NUMBER() OVER (ORDER BY r.receita_liquida DESC)   AS posicao, -- 1= maior faturamento total

           r.receita_liquida / SUM(r.receita_liquida) OVER ()    AS participacao, -- receita liquida individual / receita liquida total

           SUM(r.receita_liquida) OVER (ORDER BY r.receita_liquida DESC ROWS UNBOUNDED PRECEDING) 
		   / SUM(r.receita_liquida) OVER ()                    
		   AS participacao_acumulada ---- soma acumulada de todas as linhas anteriores / receita liquida total -> traz o percentual acumulado das n primeiras posições
    FROM receita r
)
SELECT k.posicao, k.cliente_id, v.razao_social, v.segmento AS segmento_atual,
       k.receita_liquida, k.participacao, k.participacao_acumulada
FROM ranking k
JOIN dw.dim_cliente v ON v.cliente_id = k.cliente_id AND v.is_vigente = 1;

GO