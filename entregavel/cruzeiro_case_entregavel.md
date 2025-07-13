
#### Tabela: crm\_leads

| Coluna           | Tipo   | Descrição                          |
| ---------------- | ------ | ---------------------------------- |
| id\_lead         | STRING | Identificador do lead              |
| nome             | STRING | Nome do lead                       |
| email            | STRING | Email de contato                   |
| data\_captacao   | DATE   | Data da captação                   |
| origem\_captacao | STRING | Canal de origem (ex: Facebook Ads) |

#### Tabela: ga\_comportamento (simulada para visualização)

| Coluna             | Tipo   | Descrição                     |
| ------------------ | ------ | ----------------------------- |
| id\_lead           | STRING | Identificador do lead         |
| campanha           | STRING | Nome da campanha digital      |
| pagina\_entrada    | STRING | URL da página inicial         |
| tempo\_sessao\_s   | INT64  | Duração da sessão em segundos |
| paginas\_visitadas | INT64  | Total de páginas acessadas    |
| data\_visita       | DATE   | Data da visita                |

#### Tabela: funil\_vendas

| Coluna        | Tipo   | Descrição                                       |
| ------------- | ------ | ----------------------------------------------- |
| id\_lead      | STRING | Identificador do lead                           |
| etapa         | STRING | Etapa da jornada (Captação, Qualificação, etc.) |
| data\_etapa   | DATE   | Data da etapa                                   |
| status\_etapa | STRING | Status da etapa (Ganhou, Perdido, etc.)         |

---

### 2. Lógica de Integração e Transformação

#### Visão Geral

Os dados das três fontes (CRM, GA4 e Funil de Vendas) são integrados via a chave lógica `id_lead`. Essa integração permite acompanhar toda a jornada do lead: desde a origem da captação até a conversão no funil e o comportamento digital.

#### Origem Google Analytics 4 (GA4)

Utilizamos a integração nativa do GA4 com o BigQuery por meio do recurso **BigQuery Export**. Essa funcionalidade exporta dados brutos de eventos em tempo quase real, possibilitando total controle analítico sobre sessões, cliques e campanhas.

#### Exemplo de transformação GA4 para sessões agregadas:

```sql
WITH visitas AS (
  SELECT
    user_pseudo_id AS id_lead,
    MIN(event_timestamp) AS session_start,
    COUNTIF(event_name = 'page_view') AS paginas_visitadas,
    MAX(event_timestamp) - MIN(event_timestamp) AS tempo_sessao_ms,
    ANY_VALUE(traffic_source.source) AS origem_trafego,
    ANY_VALUE(traffic_source.medium) AS midia,
    ANY_VALUE(traffic_source.name) AS campanha
  FROM `projeto_cruzeiro.analytics_XXXXXX.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20250601' AND '20250630'
    AND event_name IN ('page_view', 'session_start')
  GROUP BY user_pseudo_id
)
```

> Importante: a correspondência entre `user_pseudo_id` e `id_lead` pode ser feita por meio de estratégias como consentimento ativo, login, ou envio explícito do ID via GTM/GA4 tag.

#### Transformações adicionais:

- **Conversão**: definida quando o lead atinge a etapa "Fechamento" com status "Ganhou".
- **Tempo até conversão**: `DATEDIFF(data_etapa, data_captacao)`.
- **Engajamento**: baseado em tempo de sessão e número de páginas por visita.

---

### 3. Consultas SQL Utilizadas

#### a) Taxa de conversão por canal de origem

```sql
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
    / COUNT(DISTINCT crm.id_lead), 2
  ) AS taxa_conversao
FROM `projeto_cruzeiro.marketing_ext.crm_leads` AS crm
LEFT JOIN `projeto_cruzeiro.marketing_ext.funil_vendas` AS f
  ON crm.id_lead = f.id_lead
GROUP BY crm.origem_captacao
ORDER BY taxa_conversao DESC;
```

#### b) Tempo médio até conversão

```sql
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
```

#### c) Conversão por campanha GA

```sql
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
```

#### d) Engajamento por canal (tempo de sessão)

```sql
SELECT
  crm.origem_captacao,
  ROUND(AVG(ga.tempo_sessao_s)) AS tempo_medio_sessao,
  ROUND(AVG(ga.paginas_visitadas)) AS media_paginas
FROM `projeto_cruzeiro.marketing_ext.crm_leads` AS crm
JOIN `projeto_cruzeiro.marketing_ext.ga_comportamento` AS ga
  ON crm.id_lead = ga.id_lead
GROUP BY crm.origem_captacao
ORDER BY tempo_medio_sessao DESC;
```

---

### 4. Visualização dos Resultados

#### a) Gráfico: Taxa de Conversão por Canal

```text
Facebook Ads     ████████████████████████████████ 60%
Indicação        ███████████████████████████      50%
Google Ads       ████████████████████             40%
LinkedIn         ███████████████                  30%
Orgânico         ██████████                       20%
```

#### b) Gráfico: Tempo Médio até Conversão por Canal

```text
Indicação        ███████████                      4 dias
Facebook Ads     ██████████████                   5 dias
LinkedIn         ███████████████                  6 dias
Google Ads       ██████████████████               7 dias
Orgânico         ████████████████████             8 dias
```

#### c) Gráfico: Conversão por Campanha GA

```text
Campanha Julho       ███████████████████████████ 60%
LinkedIn Growth      ███████████████████████     50%
Campanha Mid-Year    █████████████████           40%
Campanha B2B         █████████████               30%
Google Julho         █████████                   20%
```

#### d) Gráfico: Engajamento por Canal (Tempo Médio de Sessão)

```text
Facebook Ads     ████████████████████████████    210s
Indicação        ██████████████████████████      200s
LinkedIn         ███████████████████████         190s
Google Ads       ██████████████████              180s
Orgânico         ████████████████                160s
```

- **Taxa de Conversão por Canal**: Facebook Ads lidera com 60%
- **Tempo médio por canal**: canais com captação mais rápida → Indicação
- **Conversão por Campanha**: Campanha Julho > LinkedIn Growth > Mid-Year
- **Engajamento**: Facebook Ads e Indicação com melhor tempo de sessão e páginas

Visualizações foram feitas com gráficos de barra (matplotlib) para:

- Conversão por canal
- Conversão por campanha
- Tempo até conversão
- Engajamento

---

### 5. Implementação no GCP

#### Ingestão:

- **CRM/Funil**: arquivos `.csv` carregados em **Cloud Storage**
- **GA4**: integração nativa do **Google Analytics 4 → BigQuery Export**

#### Armazenamento:

- Tabelas externas no **BigQuery** com base nos arquivos CSV (CRM e Funil)
- Tabelas particionadas por data no GA4 (eventos diários)

#### Transformação:

- SQLs com `JOIN`, `GROUP BY`, `CASE`, `AVG`, `DATE_DIFF`
- Pode ser modelado em camadas via **DBT** ou **BigQuery Views**

#### Governança:

- **Data Catalog** para metadados
- **IAM Roles** para controle de acesso

#### Visualização:

- **Looker Studio** integrado ao BigQuery para dashboards com taxa de conversão, engajamento e funil

---