/* =====================================================================
   Script : 03_dw/07_fato_credito.sql
   Engine : SQL Server 2019+ | Camada: dw
   Grão   : 1 linha por CRÉDITO CONCEDIDO
   Origem : stg.creditos (+ dw.dim_conta, stg.crm_clientes e stg.tickets
            para as marcações que dependem de outras tabelas)
   
   Medida : valor
   
   creditos sinalizados: 
   - flag_credito_fora_regra: PROMOCIONAL em competência posterior ao mês de início do cliente.
   - flag_sla_sem_indisponibilidade: SLA cujo ticket citado não é de categoria Indisponibilidade.
   ===================================================================== */
USE NuvemBR;
GO

--drop table if exists dw.fato_credito
--go

CREATE TABLE dw.fato_credito (
    credito_id                      NVARCHAR(50)  NOT NULL PRIMARY KEY,
    competencia_key                 INT           NOT NULL REFERENCES dw.dim_data (data_key),
    conta_sk                        INT           NOT NULL REFERENCES dw.dim_conta (conta_sk),
    cliente_sk                      INT           NOT NULL REFERENCES dw.dim_cliente (cliente_sk),
    tipo                            NVARCHAR(50)  NOT NULL,
    valor                           DECIMAL(14,2) NOT NULL,
    ticket_id                       NVARCHAR(50)  NULL,
    flag_credito_fora_regra         BIT           NOT NULL,
    flag_sla_sem_indisponibilidade  BIT           NOT NULL
);

INSERT INTO dw.fato_credito
SELECT s.credito_id,
       YEAR(s.competencia_data) * 10000 + MONTH(s.competencia_data) * 100 + 1,
       COALESCE(dc.conta_sk, -1),
       COALESCE(cli.cliente_sk, -1),
       s.tipo,
       s.valor,
       s.ticket_id,
       CASE WHEN s.tipo = 'PROMOCIONAL'
             AND s.competencia_data > DATEFROMPARTS(YEAR(cc.data_inicio), MONTH(cc.data_inicio), 1)
            THEN 1 ELSE 0 END,
       CASE WHEN s.tipo = 'SLA'
             AND COALESCE(t.categoria, '') <> 'Indisponibilidade'
            THEN 1 ELSE 0 END
FROM stg.creditos s
LEFT JOIN dw.dim_conta     dc ON dc.conta_id   = s.conta_id
LEFT JOIN stg.crm_clientes cc ON cc.cliente_id = dc.cliente_id
LEFT JOIN stg.tickets      t  ON t.ticket_id   = s.ticket_id
OUTER APPLY (SELECT TOP 1 c.cliente_sk
             FROM dw.dim_cliente c
             WHERE c.cliente_id = dc.cliente_id
               AND EOMONTH(s.competencia_data) BETWEEN c.valido_de AND c.valido_ate
             ORDER BY c.valido_de DESC) cli;
GO
