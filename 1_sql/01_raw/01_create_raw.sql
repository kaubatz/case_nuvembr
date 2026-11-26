/* =====================================================================
   Script : 01_raw/01_create_raw.sql
   Engine : SQL Server 2019+
   Objetivo: criar tabelas para depois carregar os arquivos .csv via bulk insert
   ===================================================================== */
USE NuvemBR;
GO

DROP TABLE IF EXISTS raw.crm_clientes,
	raw.crm_segmento_historico,
	raw.billing_contas,
	raw.consumo_diario,
	raw.faturas,
	raw.creditos,
	raw.tickets;
GO

CREATE TABLE raw.crm_clientes (
    cliente_id    NVARCHAR(50),
    razao_social  NVARCHAR(300),
    cnpj_raiz     NVARCHAR(50),
    segmento      NVARCHAR(100),
    canal         NVARCHAR(100),
    uf            NVARCHAR(10),
    data_inicio   NVARCHAR(50)
);

CREATE TABLE raw.crm_segmento_historico (
    cliente_id  NVARCHAR(50),
    segmento    NVARCHAR(100),
    valido_de   NVARCHAR(50),
    valido_ate  NVARCHAR(50)
);

CREATE TABLE raw.billing_contas (
    conta_id      NVARCHAR(50),
    cliente_id    NVARCHAR(50),
    cnpj_raiz     NVARCHAR(50),
    data_criacao  NVARCHAR(50)
);

CREATE TABLE raw.consumo_diario (
    data            NVARCHAR(50),
    conta_id        NVARCHAR(50),
    produto         NVARCHAR(100),
    regiao          NVARCHAR(100),
    quantidade      NVARCHAR(50),
    unidade         NVARCHAR(50),
    preco_unitario  NVARCHAR(50),
    lote_id         NVARCHAR(50),
    carregado_em    NVARCHAR(50)
);

CREATE TABLE raw.faturas (
    fatura_id             NVARCHAR(50),
    conta_id              NVARCHAR(50),
    competencia           NVARCHAR(20),
    valor_bruto           NVARCHAR(50),
    valor_creditos        NVARCHAR(50),
    valor_liquido         NVARCHAR(50),
    status                NVARCHAR(50),
    data_emissao          NVARCHAR(50),
    fatura_substituta_id  NVARCHAR(50)
);

CREATE TABLE raw.creditos (
    credito_id   NVARCHAR(50),
    conta_id     NVARCHAR(50),
    competencia  NVARCHAR(20),
    tipo         NVARCHAR(50),
    valor        NVARCHAR(50),
    descricao    NVARCHAR(400)
);

CREATE TABLE raw.tickets (
    ticket_id     NVARCHAR(50),
    conta_id      NVARCHAR(50),
    aberto_em     NVARCHAR(50),
    resolvido_em  NVARCHAR(50),
    severidade    NVARCHAR(20),
    categoria     NVARCHAR(100)
);
GO