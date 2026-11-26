/* =====================================================================
   NuvemBR – Case Técnico Analista de Dados Sênior
   Script : 00_setup.sql
   Engine : SQL Server 2019+ (testado no SSMS)
   Objetivo: criar o banco e os schemas de cada camada.

   Arquitetura em camadas:
     raw  -> cópia fiel dos CSVs, tudo texto, sem tratamento
     stg  -> tipagem, limpeza, deduplicação e marcação de anomalias
     dw   -> star schema (dimensões e fatos) + views de métricas
     dq   -> testes de qualidade (cada query retorna as linhas com problema)
   ===================================================================== */

IF DB_ID('NuvemBR') IS NULL
    CREATE DATABASE NuvemBR;
GO

USE NuvemBR;
GO

-- CREATE SCHEMA precisa ser a única instrução do lote, por isso o EXEC.
IF SCHEMA_ID('raw') IS NULL EXEC('CREATE SCHEMA raw');
IF SCHEMA_ID('stg') IS NULL EXEC('CREATE SCHEMA stg');
IF SCHEMA_ID('dw')  IS NULL EXEC('CREATE SCHEMA dw');
IF SCHEMA_ID('dq')  IS NULL EXEC('CREATE SCHEMA dq');
GO
