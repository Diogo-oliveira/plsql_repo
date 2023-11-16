BEGIN
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'a02_alr_is_mkr', 'TABLE', 'DPC', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'ERR$_allergy_inst_soft_market', 'TABLE', 'TRS', 'N', '', 'N');

PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'a02_allergy', 'TABLE', 'DPC', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'ERR$_allergy', 'TABLE', 'TRS', 'N', '', 'N');
END;
/


--CREATE--
create table a02_alr_is_mkr
(
  FLG_FREQ VARCHAR2(1), 
  ID_ALLERGY NUMBER(12), 
  ID_ALLERGY_PARENT NUMBER(12), 
  ID_INSTITUTION NUMBER(12), 
  ID_MARKET NUMBER(12), 
  ID_SOFTWARE NUMBER(12)
)
  organization external 
  (
    default directory DATA_IMP_DIR
    access parameters
    (
      records delimited by newline
      fields terminated by ';'
      OPTIONALLY ENCLOSED BY '"'
    )
    location ('a02_alr_is_mkr.csv')
  )
REJECT LIMIT 0;


--CREATE--
create table a02_allergy
(
  CODE_ALLERGY VARCHAR2(200), 
  FLG_ACTIVE VARCHAR2(1), 
  FLG_AVAILABLE VARCHAR2(1), 
  FLG_OTHER VARCHAR2(2), 
  FLG_SELECT VARCHAR2(1), 
  FLG_WITHOUT VARCHAR2(2), 
  ID_ALLERGY NUMBER(12), 
  ID_ALLERGY_PARENT NUMBER(12), 
  ID_ALLERGY_STANDARD VARCHAR2(80), 
  ID_CONTENT VARCHAR2(200), 
  MARKET VARCHAR2(50), 
  RANK NUMBER(12)
)
  organization external 
  (
    default directory DATA_IMP_DIR
    access parameters
    (
      records delimited by newline
      fields terminated by ';'
      OPTIONALLY ENCLOSED BY '"'
    )
    location ('a02_allergy.csv')
  )
REJECT LIMIT 0;
