create table A_274397_DOC_ELEMENT_CRIT
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
    location ('A_274397_DOC_ELEMENT_CRIT.csv')
  )
reject limit UNLIMITED; 

create table A_274397_DOC_ELEMENT_QUALIF
(
	id_doc_element_qualif number(24), 
	id_doc_element_crit number(24), 
	id_doc_qualification number, 
	flg_available varchar2(1), 
	id_doc_criteria number(24), 
	id_doc_quantification number(24), 
	code_doc_elem_qualif_close varchar2(200), 
	code_doc_elem_qualif_view varchar2(200), 
	id_doc_criteria_quant number(24), 
	rank number(6), 
	id_content varchar2(200), 
	code_doc_element_quantif_close varchar2(200 char)
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
    location ('A_274397_DOC_ELEMENT_QUALIF.csv')
  )
reject limit UNLIMITED; 



create table A_274397_TRANSLATION_6
(
  CODE_TRANSLATION	VARCHAR2(200 CHAR), 
  DESC_LANG_6       VARCHAR2(4000)
)
  organization external 
  (
    default directory DATA_IMP_DIR
    access parameters
    (
      records delimited by '\r\n' CHARACTERSET WE8MSWIN1252
      fields terminated by ';'
      OPTIONALLY ENCLOSED BY '"'
    )
    location ('A_274397_TRANSLATION_6.csv')
  )
reject limit UNLIMITED;