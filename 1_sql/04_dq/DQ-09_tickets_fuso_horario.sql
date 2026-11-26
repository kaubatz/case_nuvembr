-- DQ-09: aberto_em em UTC e resolvido_em no horário local (tempo de resolução negativo).
USE NuvemBR;
WITH t AS (
    SELECT TRY_CAST(REPLACE(REPLACE(aberto_em, 'T', ' '), 'Z', '') AS DATETIME2(0)) AS aberto,
           TRY_CAST(resolvido_em AS DATETIME2(0))                                    AS resolvido
    FROM raw.tickets
)
SELECT COUNT(*) AS tickets,
       SUM(CASE WHEN resolvido < aberto                    THEN 1 ELSE 0 END) AS negativos_sem_ajuste,
       SUM(CASE WHEN resolvido < DATEADD(HOUR, -3, aberto) THEN 1 ELSE 0 END) AS negativos_com_ajuste
FROM t;
