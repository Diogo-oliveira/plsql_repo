create or replace view v_ds_cmpt_mkt_rel as
select
   d.id_ds_cmpt_mkt_rel
  ,d.id_market
  ,d.id_ds_component_parent
  ,d.internal_name_parent
  ,d.flg_component_type_parent
  ,d.id_ds_component_child
  ,d.internal_name_child
  ,d.flg_component_type_child
  ,d.rank
  ,d.id_software
  ,d.gender
  ,d.age_min_value
  ,d.age_min_unit_measure
  ,d.age_max_value
  ,d.age_max_unit_measure
  ,d.id_unit_measure
  ,d.id_unit_measure_subtype
  ,d.max_len
  ,d.min_len
  ,d.min_value
  ,d.max_value
  ,d.flg_def_event_type
  ,d.id_profile_template
  ,d.position
  ,d.flg_configurable
  ,d.id_category
  ,d.comp_size
  ,d.ds_alias
  ,d.code_alt_desc
  ,d.desc_function
  ,
  case
  when d.slg_internal_name is not null and d.multi_option_column is null     and d.CODE_DOMAIN is null     and d.service_name is null then
    'SLG'
  when d.slg_internal_name is null     and d.multi_option_column is not null and d.CODE_DOMAIN is null     and d.service_name is null then
    'MUL'
  when d.slg_internal_name is null     and d.multi_option_column is null     and d.CODE_DOMAIN is not null and d.service_name is null then
    'DOM'
  when d.slg_internal_name is null     and d.multi_option_column is null     and d.CODE_DOMAIN is null     and d.service_name is not null then
    'SRV'
  ELSE
    null
  END FLG_MULTICHOICE
  ,case
  when d.slg_internal_name is not null and d.multi_option_column is null     and d.CODE_DOMAIN is null     and d.service_name is null then
    d.SLG_INTERNAL_NAME
  when d.slg_internal_name is null     and d.multi_option_column is not null and d.CODE_DOMAIN is null     and d.service_name is null then
    d.MULTI_OPTION_COLUMN
  when d.slg_internal_name is null     and d.multi_option_column is null     and d.CODE_DOMAIN is not null and d.service_name is null then
    d.CODE_DOMAIN
  when d.slg_internal_name is null     and d.multi_option_column is null     and d.CODE_DOMAIN is null     and d.service_name is not null then
    d.SERVICE_NAME
  ELSE
    NULL
  END MULTICHOICE_SERVICE
  ,d.service_params
  ,d.flg_Exp_type
  ,d.input_expression
  ,d.input_mask
  ,d.comp_offset
  ,d.flg_hidden
  ,'DS_MKT_REL_PLACEHOLDER.'       ||to_char(d.id_ds_cmpt_mkt_rel)  placeholder
  ,coalesce( d.code_validation_message, 'DS_MKT_REL_VALIDATION_MESSAGE.'||to_char(d.id_ds_cmpt_mkt_rel) ) code_validation_message
  ,d.flg_clearable
  , case
    when c.flg_data_type = 'MW' then d.service_name
    when c.flg_data_type = 'V'  then d.service_name
    else null
    end CRATE_IDENTIFIER
  , d.flg_label_visible
  , d.internal_sample_text_type
  , d.flg_data_type2
  , d.TEXT_LINE_NR
from DS_CMPT_MKT_REL D
join ds_component c on c.id_ds_component = d.id_ds_component_child;
