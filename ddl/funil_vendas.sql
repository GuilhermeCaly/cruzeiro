CREATE OR REPLACE EXTERNAL TABLE `projeto_cruzeiro.marketing_ext.funil_vendas`
OPTIONS (
  format = 'CSV',
  uris = ['gs://bucket-cruzeiro-marketing/data_base/funil_vendas.csv'],
  skip_leading_rows = 1,
  field_delimiter = ','
);
