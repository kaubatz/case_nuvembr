/* =====================================================================
   Script : 02_stg/07_stg_tickets.sql
   Engine : SQL Server 2019+ | Camada: stg
   Origem : raw.tickets
   
   - converte aberto_em para UTC−3, para as duas colunas ficarem no mesmo fuso
   - guarda o valor UTC original.
   - calcula horas_resolucao 
   - severidade_nivel: 1 (S1, mais grave) a 4 (S4)
   ===================================================================== */

USE NuvemBR;
GO

CREATE OR ALTER VIEW stg.tickets AS
WITH tipado AS (
    SELECT
        ticket_id,
        conta_id,
        TRY_CAST(REPLACE(REPLACE(aberto_em, 'T', ' '), 'Z', '') AS DATETIME2(0)) AS aberto_em_utc,
        TRY_CAST(resolvido_em AS DATETIME2(0)) AS resolvido_em,
        severidade,
        categoria
    FROM raw.tickets
)
SELECT
    ticket_id,
    conta_id,
    DATEADD(HOUR, -3, aberto_em_utc) AS aberto_em,  
    aberto_em_utc,
    resolvido_em,
    DATEDIFF(MINUTE, DATEADD(HOUR, -3, aberto_em_utc), resolvido_em) / 60.0 AS horas_resolucao,
    severidade,
    CAST(RIGHT(severidade, 1) AS INT) AS severidade_nivel,
    categoria
FROM tipado;
GO
