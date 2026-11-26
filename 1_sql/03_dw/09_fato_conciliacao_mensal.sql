/* =====================================================================
   Script : 03_dw/09_fato_conciliacao_mensal.sql
   Engine : SQL Server 2019+ | Camada: dw
   Grão   : 1 linha por CONTA x COMPETÊNCIA (fato agregada)
   
   Origem : dw.fato_consumo_diario, dw.fato_fatura (válidas), dw.fato_credito
   
   Objetivo: a reconciliação consumo medido x valor faturado x créditos

   Colunas principais:
   - diferenca_medido_faturado = receita_medida − valor_bruto (positivo = faturado a menor = receita não cobrada)

   - credito_nao_aplicado = créditos concedidos − créditos na fatura
   
   - status_conciliacao: OK | FATURADO A MENOR | FATURADO A MAIOR | SEM FATURA | SEM CONSUMO (tolerância de R$ 0,05)
   ===================================================================== */
USE NuvemBR;
GO

--drop table if exists dw.fato_conciliacao_mensal 
--go

CREATE TABLE dw.fato_conciliacao_mensal (
    conta_sk                   INT           NOT NULL REFERENCES dw.dim_conta (conta_sk),
    competencia_key            INT           NOT NULL REFERENCES dw.dim_data (data_key),
    cliente_sk                 INT           NOT NULL REFERENCES dw.dim_cliente (cliente_sk),
    fatura_id                  NVARCHAR(50)  NULL,
    receita_medida             DECIMAL(19,2) NOT NULL,
    receita_medida_kubernetes  DECIMAL(19,2) NOT NULL,
    valor_bruto_faturado       DECIMAL(14,2) NOT NULL,
    diferenca_medido_faturado  DECIMAL(19,2) NOT NULL,
    creditos_concedidos        DECIMAL(14,2) NOT NULL,
    creditos_na_fatura         DECIMAL(14,2) NOT NULL,
    credito_nao_aplicado       DECIMAL(14,2) NOT NULL,
    status_conciliacao         VARCHAR(20)   NOT NULL,
    CONSTRAINT pk_fato_conciliacao PRIMARY KEY (conta_sk, competencia_key)
);

WITH medido AS (
    SELECT f.conta_sk,
           (f.data_key / 100) * 100 + 1           AS competencia_key,   -- aaaamm01
           SUM(f.receita_medida)                  AS receita_medida,
           SUM(CASE WHEN p.produto = 'KUBERNETES' THEN f.receita_medida ELSE 0 END) AS receita_k8s
    FROM dw.fato_consumo_diario f
    JOIN dw.dim_produto p ON p.produto_sk = f.produto_sk
    GROUP BY f.conta_sk, (f.data_key / 100) * 100 + 1
),
faturado AS (
    SELECT conta_sk, competencia_key, fatura_id, valor_bruto, valor_creditos
    FROM dw.fato_fatura
    WHERE is_valida = 1
),
creditos AS (
    SELECT conta_sk, competencia_key, SUM(valor) AS creditos_concedidos
    FROM dw.fato_credito
    GROUP BY conta_sk, competencia_key
),
base AS (
    SELECT COALESCE(m.conta_sk, fa.conta_sk)               AS conta_sk,
           COALESCE(m.competencia_key, fa.competencia_key) AS competencia_key,
           fa.fatura_id,
           ROUND(COALESCE(m.receita_medida, 0), 2)         AS receita_medida,
           ROUND(COALESCE(m.receita_k8s, 0), 2)            AS receita_k8s,
           COALESCE(fa.valor_bruto, 0)                     AS valor_bruto,
           COALESCE(fa.valor_creditos, 0)                  AS valor_creditos,
           CASE WHEN m.conta_sk  IS NULL THEN 'SEM CONSUMO'
                WHEN fa.conta_sk IS NULL THEN 'SEM FATURA' END AS status_ausencia
    FROM medido m
    FULL OUTER JOIN faturado fa
      ON fa.conta_sk = m.conta_sk AND fa.competencia_key = m.competencia_key
)
INSERT INTO dw.fato_conciliacao_mensal
SELECT b.conta_sk,
       b.competencia_key,
       COALESCE(cli.cliente_sk, -1),
       b.fatura_id,
       b.receita_medida,
       b.receita_k8s,
       b.valor_bruto,
       b.receita_medida - b.valor_bruto,
       COALESCE(c.creditos_concedidos, 0),
       b.valor_creditos,
       COALESCE(c.creditos_concedidos, 0) - b.valor_creditos,
       COALESCE(b.status_ausencia,
                CASE WHEN b.receita_medida - b.valor_bruto >  0.05 THEN 'FATURADO A MENOR'
                     WHEN b.receita_medida - b.valor_bruto < -0.05 THEN 'FATURADO A MAIOR'
                     ELSE 'OK' END)
FROM base b
LEFT JOIN creditos c
       ON c.conta_sk = b.conta_sk AND c.competencia_key = b.competencia_key
LEFT JOIN dw.dim_conta dc ON dc.conta_sk = b.conta_sk
OUTER APPLY (SELECT TOP 1 x.cliente_sk
             FROM dw.dim_cliente x
             WHERE x.cliente_id = dc.cliente_id
               AND EOMONTH(DATEFROMPARTS(b.competencia_key / 10000, (b.competencia_key / 100) % 100, 1))
                   BETWEEN x.valido_de AND x.valido_ate
             ORDER BY x.valido_de DESC) cli;
GO