-- DQ-03: consumo de Kubernetes medido e não faturado (conciliação medido x faturado).
USE NuvemBR;
SELECT c.conta_id,
       COUNT(*)                         AS meses,
       SUM(f.diferenca_medido_faturado) AS valor_nao_faturado,
       SUM(f.receita_medida_kubernetes) AS kubernetes_medido
FROM dw.fato_conciliacao_mensal f
JOIN dw.dim_conta c ON c.conta_sk = f.conta_sk
WHERE f.status_conciliacao = 'FATURADO A MENOR'
GROUP BY c.conta_id;
