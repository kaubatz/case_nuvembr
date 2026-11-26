/* =====================================================================
   Script : 03_dw/06_fato_fatura.sql
   Engine : SQL Server 2019+ | Camada: dw
   
   Grão   : 1 linha por FATURA EMITIDA (canceladas -> is_valida = 0)
   
   Origem : stg.faturas (líquido já recalculado)
   
   Medidas: valor_bruto, valor_creditos, valor_liquido (recalculado),
            valor_liquido_original (como veio do billing).

   cliente_sk: pk do cliente vigente no ÚLTIMO DIA da competência 
   ===================================================================== */
USE NuvemBR;
GO

--drop table if exists dw.fato_fatura
--go

CREATE TABLE dw.fato_fatura (
    fatura_id                 NVARCHAR(50)  NOT NULL PRIMARY KEY,   
    competencia_key           INT           NOT NULL REFERENCES dw.dim_data (data_key),
    emissao_key               INT           NULL     REFERENCES dw.dim_data (data_key),
    conta_sk                  INT           NOT NULL REFERENCES dw.dim_conta (conta_sk),
    cliente_sk                INT           NOT NULL REFERENCES dw.dim_cliente (cliente_sk),
    status                    NVARCHAR(50)  NOT NULL,
    valor_bruto               DECIMAL(14,2) NOT NULL,
    valor_creditos            DECIMAL(14,2) NOT NULL,
    valor_liquido             DECIMAL(14,2) NOT NULL,
    valor_liquido_original    DECIMAL(14,2) NOT NULL,
    is_valida                 BIT           NOT NULL,
    is_reemissao              BIT           NOT NULL,
    flag_liquido_recalculado  BIT           NOT NULL,
    fatura_substituta_id      NVARCHAR(50)  NULL
);

INSERT INTO dw.fato_fatura
SELECT s.fatura_id,
       YEAR(s.competencia_data) * 10000 + MONTH(s.competencia_data) * 100 + 1,
       YEAR(s.data_emissao) * 10000 + MONTH(s.data_emissao) * 100 + DAY(s.data_emissao),
       COALESCE(dc.conta_sk, -1),
       COALESCE(cli.cliente_sk, -1),
       s.status,
       s.valor_bruto,
       s.valor_creditos,
       s.valor_liquido,
       s.valor_liquido_original,
       s.is_valida,
       s.is_reemissao,
       s.flag_liquido_recalculado,
       s.fatura_substituta_id
FROM stg.faturas s
LEFT JOIN dw.dim_conta dc ON dc.conta_id = s.conta_id
OUTER APPLY (SELECT TOP 1 c.cliente_sk
             FROM dw.dim_cliente c
             WHERE c.cliente_id = dc.cliente_id
               AND EOMONTH(s.competencia_data) BETWEEN c.valido_de AND c.valido_ate
             ORDER BY c.valido_de DESC) cli;
GO
