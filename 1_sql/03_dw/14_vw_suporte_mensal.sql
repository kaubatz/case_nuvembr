/* =====================================================================
   Script : 03_dw/14_vw_suporte_mensal.sql
   Engine : SQL Server 2019+ | Camada: dw
   Grão   : 1 linha por MÊS DE ABERTURA do chamado

   Origem : dw.fato_ticket, SEM os tickets abertos antes da conta 

   Uso    : saúde do atendimento e ligação com os créditos SLA.
   ===================================================================== */
USE NuvemBR;
GO
CREATE OR ALTER VIEW dw.vw_suporte_mensal AS
SELECT d.ano_mes                                                AS mes_abertura,
       COUNT(*)                                                 AS chamados,
       SUM(CASE WHEN t.severidade_nivel = 1 THEN 1 ELSE 0 END)  AS chamados_s1,
       SUM(CASE WHEN t.categoria = 'Indisponibilidade' THEN 1 ELSE 0 END) AS chamados_indisponibilidade,
       SUM(CAST(t.tem_credito_sla AS INT))                      AS chamados_com_credito_sla,
       AVG(t.horas_resolucao)                                   AS media_horas_resolucao
FROM dw.fato_ticket t
JOIN dw.dim_data d ON d.data_key = t.abertura_key
WHERE t.flag_ticket_antes_da_conta = 0
GROUP BY d.ano_mes;
GO
