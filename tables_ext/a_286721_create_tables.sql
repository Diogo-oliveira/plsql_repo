create table a_286721_doc_element
(
  id_doc_element number(24), 
  id_documentation number(24), 
  id_doc_dimension number(24), 
  internal_name varchar2(200), 
  flg_type varchar2(2), 
  flg_gender varchar2(1), 
  position varchar2(1), 
  age_max number(6,2), 
  age_min number(6,2), 
  rank number, 
  flg_available varchar2(1), 
  flg_behavior varchar2(1), 
  input_mask varchar2(200), 
  flg_optional_value varchar2(1), 
  code_element_domain varchar2(200), 
  flg_element_domain_type varchar2(1), 
  min_value varchar2(200), 
  max_value varchar2(200), 
  id_content varchar2(200), 
  score number(24,3), 
  id_unit_measure_type number(24), 
  id_unit_measure_subtype number(24), 
  id_unit_measure_reference number(24), 
  display_format varchar2(200 char), 
  separator varchar2(10 char), 
  flg_ref_op_min varchar2(2 char), 
  ref_val_min number(24,3), 
  flg_ref_op_max varchar2(2 char), 
  ref_val_max number(24,3), 
  id_master_item number(24)
)
  organization external 
  (
    default directory DATA_IMP_DIR
    access parameters
    (
      records delimited by '\r\n'
      fields terminated by ';'
      OPTIONALLY ENCLOSED BY '"'
    )
    location ('a_286721_doc_element.csv')
  )
reject limit UNLIMITED; 

create table a_286721_doc_element_crit
(
  id_doc_element_crit number(24), 
  id_doc_element number(24), 
  id_doc_criteria number(24), 
  code_element_close varchar2(200), 
  code_element_open varchar2(200), 
  flg_view varchar2(1), 
  flg_default varchar2(1), 
  flg_available varchar2(1), 
  code_element_view varchar2(200), 
  flg_mandatory varchar2(1), 
  id_content varchar2(200) 
)
  organization external 
  (
    default directory DATA_IMP_DIR
    access parameters
    (
      records delimited by '\r\n'
      fields terminated by ';'
      OPTIONALLY ENCLOSED BY '"'
    )
    location ('a_286721_doc_element_crit.csv')
  )
reject limit UNLIMITED; 
