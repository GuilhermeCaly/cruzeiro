CREATE OR REPLACE EXTERNAL TABLE `projeto_cruzeiro.marketing_ext.ga_comportamento`
OPTIONS (
  format = 'CSV',
  uris = ['gs://bucket-cruzeiro-marketing/data_base/ga_comportamento.csv'],
  skip_leading_rows = 1,
  field_delimiter = ','
);
