BEGIN
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'e1_20alr_is_mkr', 'TABLE', 'DPC', 'N', '', 'N','','MEDICATION');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'ERR$_allergy_inst_soft_market', 'TABLE', 'TRS', 'N', '', 'N','','MEDICATION');

PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'e1_20allergy', 'TABLE', 'DPC', 'N', '', 'N','','MEDICATION');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'ERR$_allergy', 'TABLE', 'TRS', 'N', '', 'N','','MEDICATION');

PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'e1_20unit_measure', 'TABLE', 'DPC', 'N', '', 'N','','MEDICATION');

PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'e1_20translation_6', 'TABLE', 'DPC', 'N', '', 'N','','MEDICATION');
END;
/
--CREATE--
create table e1_20translation_6
(
  CODE_TRANSLATION	VARCHAR2(255), 
  DESCR            VARCHAR2(1000)
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
    location ('e1_20translation_6.csv')
  )
REJECT LIMIT 0;

--CREATE--
create table e1_20alr_is_mkr
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
    location ('e1_20alr_is_mkr.csv')
  )
REJECT LIMIT 0;

--CREATE--
create table e1_20allergy
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
  RANK NUMBER(12),
  ID_PRODUCT VARCHAR2(200),
  ID_ING_GROUP VARCHAR2(200),
  ID_INGREDIENTS VARCHAR2(200)
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
    location ('e1_20allergy.csv')
  )
REJECT LIMIT 0;

--CREATE--
create table e1_20unit_measure
(
  ID_UNIT_MEASURE       NUMBER(24),
  CODE_UNIT_MEASURE     VARCHAR2(200),
  ID_UNIT_MEASURE_TYPE  NUMBER(24),
  INTERNAL_NAME         VARCHAR2(200),
  ENUMERATED            VARCHAR2(1),
  FLG_AVAILABLE         VARCHAR2(1),
  CODE_UNIT_MEASURE_ABRV    VARCHAR2(200),        
  ID_CONTENT            VARCHAR2(200)
)
  organization external 
  (
    default directory DATA_IMP_DIR
    access parameters
    (
      records delimited by newline CHARACTERSET WE8MSWIN1252
      fields terminated by ';'
      OPTIONALLY ENCLOSED BY '"'
    )
    location ('e1_20unit_measure.csv')
  )
REJECT LIMIT 0;
