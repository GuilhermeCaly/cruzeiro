# 📊 Projeto de Engenharia de Dados – Cruzeiro (Case Técnico)

## 🎯 Objetivo
Integrar dados de CRM, Google Analytics 4 e Funil de Vendas para gerar insights estratégicos de marketing no GCP, utilizando BigQuery e visualizações analíticas.

---

## 🗃️ Fontes de Dados

| Fonte            | Tipo           | Descrição Principal                           |
|------------------|----------------|-----------------------------------------------|
| CRM              | CSV / GCS      | Leads, data de captação, origem               |
| Google Analytics | GA4 + BigQuery | Dados de sessões, campanhas, comportamento     |
| Funil de Vendas  | CSV / GCS      | Etapas da jornada e status de conversão       |

---

## 🔄 Integração e Transformação

- **Chave comum:** `id_lead`
- **GA4 via BigQuery Export:** dados de eventos extraídos diretamente
- **Sessões reconstruídas** via CTEs com `session_start`, `page_view`
- **Conversão** definida por `status_etapa = 'Ganhou'`
- **Engajamento** calculado por tempo e páginas por sessão

---

## Métricas e Insights

1. **Taxa de conversão por canal**
2. **Tempo médio até conversão**
3. **Conversão por campanha GA4**
4. **Engajamento médio (sessão e páginas)**

---

## Exemplo de Insights

| Canal          | Conversão | Tempo Médio | Engajamento |
|----------------|-----------|-------------|-------------|
| Facebook Ads   | 60%       | 5 dias      | 210s        |
| Indicação      | 50%       | 4 dias      | 200s        |
| Orgânico       | 20%       | 8 dias      | 160s        |

---

## Stack de Implementação

- **Cloud Storage:** ingestão dos dados CRM e Funil
- **BigQuery External Tables:** leitura direta dos CSVs
- **BigQuery GA4 Export:** análise nativa dos eventos
