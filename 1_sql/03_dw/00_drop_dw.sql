/* =====================================================================
   Script : 03_dw/00_drop_dw.sql
   Engine : SQL Server 2019+ | Camada: dw
   Objetivo: apagar a camada dw para recriá-la do zero
   Ordem: views → fatos → dimensões (as fatos têm FK para as dimensões).
   ===================================================================== */
USE NuvemBR;
GO
DROP VIEW  IF EXISTS dw.vw_suporte_mensal, dw.vw_concentracao_clientes,
                     dw.vw_kpis_mensais,   dw.vw_cliente_mes,
                     dw.vw_receita_mensal;

DROP TABLE IF EXISTS dw.fato_conciliacao_mensal, dw.fato_ticket, dw.fato_credito,
                     dw.fato_fatura, dw.fato_consumo_diario;

DROP TABLE IF EXISTS dw.dim_produto, dw.dim_conta, dw.dim_cliente, dw.dim_data;
GO
