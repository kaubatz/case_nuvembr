/* =====================================================================
   Script : 03_dw/01_dim_data.sql
   Engine : SQL Server 2019+ | Camada: dw
   Grão   : 1 linha por dia, de 01/01/2025 a 31/12/2026
            (cobre o início dos clientes mais antigos e o período do case).
   data_key no formato aaaammdd (ex.: 20260514), padrão de mercado para
   chave de data: legível e ordenável.
   dia_semana: 1 = segunda ... 7 = domingo, calculado sem depender do
   SET DATEFIRST do servidor.
   ===================================================================== */
USE NuvemBR;
GO
-- drop table if exists dw.dim_data
-- go

CREATE TABLE dw.dim_data (
    data_key          INT          NOT NULL PRIMARY KEY,
    data              DATE         NOT NULL,
    ano               SMALLINT     NOT NULL,
    trimestre         TINYINT      NOT NULL,
    mes               TINYINT      NOT NULL,
    nome_mes          VARCHAR(10)  NOT NULL,
    ano_mes           CHAR(7)      NOT NULL,   -- 'aaaa-mm', igual à competência
    primeiro_dia_mes  DATE         NOT NULL,
    ultimo_dia_mes    DATE         NOT NULL,
    dia_semana        TINYINT      NOT NULL,
    nome_dia_semana   VARCHAR(10)  NOT NULL
);

WITH numeros AS (
    SELECT TOP (DATEDIFF(DAY, '2025-01-01', '2026-12-31') + 1)
           ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
),
dias AS (
    SELECT DATEADD(DAY, n, CAST('2025-01-01' AS DATE)) AS d FROM numeros
)
INSERT INTO dw.dim_data
SELECT YEAR(d) * 10000 + MONTH(d) * 100 + DAY(d),
       d,
       YEAR(d),
       DATEPART(QUARTER, d),
       MONTH(d),
       CHOOSE(MONTH(d), 'jan','fev','mar','abr','mai','jun','jul','ago','set','out','nov','dez'),
       CONVERT(CHAR(7), d, 126),
       DATEFROMPARTS(YEAR(d), MONTH(d), 1),
       EOMONTH(d),
       DATEDIFF(DAY, '19000101', d) % 7 + 1,     -- 01/01/1900 foi segunda-feira
       CHOOSE(DATEDIFF(DAY, '19000101', d) % 7 + 1,
              'segunda','terça','quarta','quinta','sexta','sábado','domingo')
FROM dias;
GO