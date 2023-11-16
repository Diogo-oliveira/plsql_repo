--ALERT-272156 (begin)
BEGIN
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'E2_4CDR_DOC', 'TABLE', 'DPC', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'E2_4CDR_DOC_INSTANCE', 'TABLE', 'DPC', 'N', '', 'N');

PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'E2_4TRANSLATION_2', 'TABLE', 'DPC', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'E2_4CDR_INST_PAR_ACTION', 'TABLE', 'DPC', 'N', '', 'N');
END;
/
--CREATE--
create table e2_4cdr_inst_par_action
(
  ID_CDR_INST_PAR_ACTION	NUMBER(24), 
  ID_CDR_DOC_INSTANCE       NUMBER(24)
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
    location ('e2_4cdr_inst_par_action.csv')
  )
REJECT LIMIT 0;
--CREATE--
create table e2_4translation_2
(
  CODE_TRANSLATION	VARCHAR2(255), 
  DESCR            VARCHAR2(4000)
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
    location ('e2_4translation_2.csv')
  )
REJECT LIMIT 0;
--CREATE--
create table e2_4cdr_doc
(
  ID_CDR_DOC            NUMBER(24),
  ID_CDR_DOC_INSTANCE   NUMBER(24),
  ID_CDR_DOC_TYPE       NUMBER(24),
  ID_CDR_DOC_ITEM_TYPE  NUMBER(24),
  RANK                  NUMBER(24),
  FLG_AVAILABLE         VARCHAR2(1 CHAR)
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
    location ('e2_4cdr_doc.csv')
  )
REJECT LIMIT 0;

--CREATE--
create table e2_4cdr_doc_instance
(
  ID_CDR_DOC_INSTANCE NUMBER(24)
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
    location ('e2_4cdr_doc_instance.csv')
  )
REJECT LIMIT 0;
--ALERT-272156 (END)