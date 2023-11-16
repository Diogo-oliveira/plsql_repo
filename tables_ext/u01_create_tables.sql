BEGIN
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'u01_alr_is_mkr', 'TABLE', 'DPC', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'ERR$_allergy_inst_soft_market', 'TABLE', 'TRS', 'N', '', 'N');

PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'u01_allergy', 'TABLE', 'DPC', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'ERR$_allergy', 'TABLE', 'TRS', 'N', '', 'N');

PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'u01_med_alr_allergy_lnk', 'TABLE', 'DPC', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'ERR$_med_alr_allergy_lnk', 'TABLE', 'TRS', 'N', '', 'N');
END;
/


--CREATE--
create table u01_alr_is_mkr
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
    location ('u01_alr_is_mkr.csv')
  )
REJECT LIMIT 0;


--CREATE--
create table u01_allergy
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
    location ('u01_allergy.csv')
  )
REJECT LIMIT 0;

--CREATE--
create table u01_med_alr_allergy_lnk
(
  ID_ALRGN NUMBER(24), 
  ID_CCPT_ALRGN_TYP NUMBER(24), 
  ID_ALLERGY NUMBER(24), 
  VERS VARCHAR2(255), 
  ID_ALRG_NEW_MODEL VARCHAR2(255)
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
    location ('u01_med_alr_allergy_lnk.csv')
  )
REJECT LIMIT 0;


--ALERT-267736 (b) 20131024

BEGIN
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'U01_CDR_MESSAGE_CLEAN', 'TABLE', 'DPC', 'N', '', 'N');

END;
/

create table U01_CDR_MESSAGE_CLEAN
(
  ID_CDR_MESSAGE_1 NUMBER(24), 
  ID_CDR_INST_PAR_ACTION_2 NUMBER(24), 
  ID_CDR_MESSAGE_2 NUMBER(24)
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
    location ('U01_CDR_MESSAGE_CLEAN.csv')
  )
REJECT LIMIT 0;

--ALERT-267736 (e)

--ALERT-267771 (b) 20131024
BEGIN
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'U01_TRANSLATION_7', 'TABLE', 'DPC', 'N', '', 'N');

END;
/

create table U01_TRANSLATION_7
(
  ID_CDR_MESSAGE	NUMBER(24), 
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
    location ('U01_TRANSLATION_7.csv')
  )
REJECT LIMIT 0;


--ALERT-267771 (e)



-- ALERT-268245 (b) 

BEGIN
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'U01_CDR_MESSAGE_CLEANING_INT_', 'TABLE', 'DPC', 'N', '', 'N');

END;
/

create table U01_CDR_MESSAGE_CLEANING_INT_
(
  ID_CDR_MESSAGE_1 NUMBER(24), 
  ID_CDR_MESSAGE_2 NUMBER(24)
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
    location ('U01_CDR_MESSAGE_CLEANING_INT_TUPL.csv')
  )
REJECT LIMIT 0;

-- ALERT-268245 (e)