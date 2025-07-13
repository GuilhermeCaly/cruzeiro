
-------------------------- CONVERSAO ------------------------------
SELECT
  crm.origem_captacao,
  COUNT(DISTINCT crm.id_lead) AS total_leads,
  COUNT(DISTINCT CASE 
    WHEN f.etapa = 'Fechamento' AND f.status_etapa = 'Ganhou' 
    THEN crm.id_lead 
  END) AS leads_convertidos,
  ROUND(
    COUNT(DISTINCT CASE 
      WHEN f.etapa = 'Fechamento' AND f.status_etapa = 'Ganhou' 
      THEN crm.id_lead 
    END) 
    / COUNT(DISTINCT crm.id_lead), 
    2
  ) AS taxa_conversao
FROM `projeto_cruzeiro.marketing_ext.crm_leads` AS crm
LEFT JOIN `projeto_cruzeiro.marketing_ext.funil_vendas` AS f
  ON crm.id_lead = f.id_lead
GROUP BY crm.origem_captacao
ORDER BY taxa_conversao DESC;


------------------- TEMPO MEDIO PARA CAPTACAO ----------------------
SELECT
  crm.origem_captacao,
  ROUND(AVG(DATE_DIFF(f.data_etapa, crm.data_captacao, DAY))) AS tempo_medio_dias
FROM `projeto_cruzeiro.marketing_ext.crm_leads` AS crm
JOIN `projeto_cruzeiro.marketing_ext.funil_vendas` AS f
  ON crm.id_lead = f.id_lead
WHERE f.etapa = 'Fechamento'
  AND f.status_etapa = 'Ganhou'
GROUP BY crm.origem_captacao
ORDER BY tempo_medio_dias;

------------------- LEADS POR CAMPANHA ------------------------------
SELECT
  ga.campanha,
  COUNT(DISTINCT ga.id_lead) AS total_leads,
  COUNT(DISTINCT CASE 
    WHEN f.etapa = 'Fechamento' AND f.status_etapa = 'Ganhou' 
    THEN ga.id_lead 
  END) AS leads_convertidos,
  ROUND(
    COUNT(DISTINCT CASE 
      WHEN f.etapa = 'Fechamento' AND f.status_etapa = 'Ganhou' 
      THEN ga.id_lead 
    END) 
    / COUNT(DISTINCT ga.id_lead), 
    2
  ) AS taxa_conversao
FROM `projeto_cruzeiro.marketing_ext.ga_comportamento` AS ga
LEFT JOIN `projeto_cruzeiro.marketing_ext.funil_vendas` AS f
  ON ga.id_lead = f.id_lead
GROUP BY ga.campanha
ORDER BY taxa_conversao DESC;

---------------- CANAIS POR TEMPO MEDIO --------------------------
SELECT
  crm.origem_captacao,
  ROUND(AVG(ga.tempo_sessao_s)) AS tempo_medio_sessao,
  ROUND(AVG(ga.paginas_visitadas)) AS media_paginas
FROM `projeto_cruzeiro.marketing_ext.crm_leads` AS crm
JOIN `projeto_cruzeiro.marketing_ext.ga_comportamento` AS ga
  ON crm.id_lead = ga.id_lead
GROUP BY crm.origem_captacao
ORDER BY tempo_medio_sessao DESC;
