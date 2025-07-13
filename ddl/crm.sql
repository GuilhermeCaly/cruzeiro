CREATE OR REPLACE EXTERNAL TABLE `projeto_cruzeiro.marketing_ext.crm_leads`
OPTIONS (
  format = 'CSV',
  uris = ['gs://bucket-cruzeiro-marketing/data_base/crm_leads.csv'],
  skip_leading_rows = 1,
  field_delimiter = ','
);
