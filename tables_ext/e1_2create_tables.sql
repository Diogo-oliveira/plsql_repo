BEGIN
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'e1_2translation_6', 'TABLE', 'DPC', 'N', '', 'N');

PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'e1_2unit_measure', 'TABLE', 'DPC', 'N', '', 'N');

END;
/
--CREATE--
create table e1_2translation_6
(
  CODE_TRANSLATION	VARCHAR2(255), 
  DESCR            VARCHAR2(255)
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
    location ('e1_2translation_6.csv')
  )
REJECT LIMIT 0;
--CREATE--
create table e1_2unit_measure
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
      records delimited by newline
      fields terminated by ';'
      OPTIONALLY ENCLOSED BY '"'
    )
    location ('e1_2unit_measure.csv')
  )
REJECT LIMIT 0;