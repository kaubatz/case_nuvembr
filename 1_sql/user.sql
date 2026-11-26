USE master;
GO
-- Login = acesso ao SERVIDOR
CREATE LOGIN nathaly
WITH PASSWORD = '<senha>',   -- m�nimo 8 caracteres, com mai�scula, min�scula, n�mero e s�mbolo
     CHECK_POLICY = ON,
     CHECK_EXPIRATION = OFF,
     DEFAULT_DATABASE = NuvemBR;
GO

-- Permiss�o para BULK INSERT (carga dos CSVs)
ALTER SERVER ROLE bulkadmin ADD MEMBER nathaly;
GO

USE NuvemBR;
GO
-- Usu�rio = acesso ao BANCO, ligado ao login
CREATE USER nathaly FOR LOGIN nathaly;

-- db_owner: pode criar e excluir tabelas, views e schemas no banco do case
ALTER ROLE db_owner ADD MEMBER nathaly;
GO