-- DQ-10: tickets abertos antes da criação da conta (vínculo ticket x conta suspeito).
USE NuvemBR;
SELECT COUNT(*)                   AS tickets,
       COUNT(DISTINCT t.conta_id) AS contas
FROM raw.tickets t
JOIN raw.billing_contas b ON b.conta_id = t.conta_id
WHERE LEFT(t.aberto_em, 10) < b.data_criacao;
