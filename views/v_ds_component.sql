create or replace view v_ds_component as
select
 d.ID_DS_COMPONENT
,d.INTERNAL_NAME
,d.CODE_DS_COMPONENT
,d.FLG_COMPONENT_TYPE
,d.FLG_DATA_TYPE
,d.FLG_WRAP_TEXT
,d.INTERNAL_SAMPLE_TEXT_TYPE
,case
when slg_internal_name is not null and multi_option_column is null and CODE_DOMAIN is null and service_name is null then
  'SLG'
when slg_internal_name is null and multi_option_column is not null and CODE_DOMAIN is null and service_name is null then
  'MUL'
when slg_internal_name is null and multi_option_column is null and CODE_DOMAIN is not null and service_name is null then
  'DOM'
when slg_internal_name is null and multi_option_column is null and CODE_DOMAIN is null and service_name is not null then
  'SRV'
ELSE
  null
END FLG_MULTICHOICE
,case
when slg_internal_name is not null and multi_option_column is null and CODE_DOMAIN is null and service_name is null then
  SLG_INTERNAL_NAME
when slg_internal_name is null and multi_option_column is not null and CODE_DOMAIN is null and service_name is null then
  MULTI_OPTION_COLUMN
when slg_internal_name is null and multi_option_column is null and CODE_DOMAIN is not null and service_name is null then
  CODE_DOMAIN
when slg_internal_name is null and multi_option_column is null and CODE_DOMAIN is null and service_name is not null then
  SERVICE_NAME
ELSE
  NULL
END MULTICHOICE_SERVICE
,'DS_COMPONENT.CODE_COMPONENT_H_NEW.' ||to_char(D.ID_DS_COMPONENT) code_component_h_NEW
,'DS_COMPONENT.CODE_COMPONENT_H_EDIT.'||to_char(D.ID_DS_COMPONENT) code_component_h_EDIT
,'DS_COMPONENT.CODE_COMPONENT_H_DEL.' ||to_char(D.ID_DS_COMPONENT) code_component_h_DEL
,'DS_COMPONENT.CODE_ROOT_TITLE_ADD.' ||TO_CHAR(D.ID_DS_COMPONENT) CODE_ROOT_TITLE_ADD
,'DS_COMPONENT.CODE_ROOT_TITLE_EDIT.' ||TO_CHAR(D.ID_DS_COMPONENT) CODE_ROOT_TITLE_EDIT
, d.flg_repeatable
from ds_component d;
