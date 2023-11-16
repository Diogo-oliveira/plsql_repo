BEGIN
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'fr01_alr_is_mkr', 'TABLE', 'DPC', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'fr01_allergy', 'TABLE', 'DPC', 'N', '', 'N');

PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'fr01_allergy_translation_6', 'TABLE', 'DPC', 'N', '', 'N');
END;
/
--CREATE--
create table fr01_allergy_translation_6
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
    location ('fr02_allergy_translation_6.csv')
  )
REJECT LIMIT 0;
--CREATE--
create table fr01_allergy
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
    location ('fr02_allergy.csv')
  )
REJECT LIMIT 0;


--ALERT-272584 (begin)

BEGIN
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'fr01_allergy_translation_6', 'TABLE', 'DPC', 'N', '', 'N');
END;
/
--CREATE--
create table fr01_allergy_translation_6
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
    location ('fr02_allergy_translation_6.csv')
  )
REJECT LIMIT 0;


--ALERT-272584 (end)

-- CMF 27-12-2013
BEGIN
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'fr01_alr_is_mkr', 'TABLE', 'DPC', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'fr01_allergy', 'TABLE', 'DPC', 'N', '', 'N');

PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'fr01_allergy_translation_6', 'TABLE', 'DPC', 'N', '', 'N');
END;
/
--CREATE--
declare
pl  constant varchar2(0050 char) := '''';
lf  constant varchar2(0050 char) := chr(10);
l_SQL varchar2(1000 char) := 
'create table fr01_allergy_translation_6'
||lf||'('
||lf||'  ID_CDR_MESSAGE  NUMBER(24), '
||lf||'  DESCR            VARCHAR2(255)'
||lf||')'
||lf||'  organization external '
||lf||'  ('
||lf||'    default directory DATA_IMP_DIR'
||lf||'    access parameters'
||lf||'    ('
||lf||'      records delimited by '||pl||'\r\n'||pl||' CHARACTERSET WE8MSWIN1252'
||lf||'      fields terminated by '||pl||';'||pl
||lf||'      OPTIONALLY ENCLOSED BY '||pl||'"'||pl
||lf||'    )'
||lf||'    location ('||pl||'fr02_allergy_translation_6.csv'||pl||')'
||lf||'  )'
||lf||'REJECT LIMIT 0';
begin
pk_versioning.run( l_sql);
end;
/




--CREATE--
declare
pl  constant varchar2(0050 char) := '''';
lf  constant varchar2(0050 char) := chr(10);
l_sql  varchar2(4000) :=
'create table fr01_allergy'
||lf||'('
||lf||'  CODE_ALLERGY VARCHAR2(200), '
||lf||'  FLG_ACTIVE VARCHAR2(1), '
||lf||'  FLG_AVAILABLE VARCHAR2(1), '
||lf||'  FLG_OTHER VARCHAR2(2), '
||lf||'  FLG_SELECT VARCHAR2(1), '
||lf||'  FLG_WITHOUT VARCHAR2(2), '
||lf||'  ID_ALLERGY NUMBER(12), '
||lf||'  ID_ALLERGY_PARENT NUMBER(12), '
||lf||'  ID_ALLERGY_STANDARD VARCHAR2(80), '
||lf||'  ID_CONTENT VARCHAR2(200), '
||lf||'  MARKET VARCHAR2(50), '
||lf||'  RANK NUMBER(12),'
||lf||'  ID_PRODUCT VARCHAR2(200),'
||lf||'  ID_ING_GROUP VARCHAR2(200),'
||lf||'  ID_INGREDIENTS VARCHAR2(200)'
||lf||')'
||lf||'  organization external '
||lf||'  ('
||lf||'    default directory DATA_IMP_DIR'
||lf||'    access parameters'
||lf||'    ('
||lf||'      records delimited by newline'
||lf||'      fields terminated by '||pl||';'||pl
||lf||'      OPTIONALLY ENCLOSED BY '||pl||'"'||pl
||lf||'    )'
||lf||'    location ('||pl||'fr02_allergy.csv'||pl||')'
||lf||'  )'
||lf||'REJECT LIMIT 0';
begin
pk_versioning.run( l_sql);
end;
/



--ALERT-272584 (begin)

BEGIN
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'fr01_allergy_translation_6', 'TABLE', 'DPC', 'N', '', 'N');
END;
/
--CREATE--
declare
pl  constant varchar2(0050 char) := '''';
lf  constant varchar2(0050 char) := chr(10);
l_sql  varchar2(4000) :=
'create table fr01_allergy_translation_6'
||lf||'('
||lf||'  ID_CDR_MESSAGE  NUMBER(24), '
||lf||'  DESCR            VARCHAR2(255)'
||lf||')'
||lf||'  organization external '
||lf||'  ('
||lf||'    default directory DATA_IMP_DIR'
||lf||'    access parameters'
||lf||'    ('
||lf||'      records delimited by '||pl||'\r\n'||pl||' CHARACTERSET WE8MSWIN1252'
||lf||'      fields terminated by '||pl||';'||pl
||lf||'      OPTIONALLY ENCLOSED BY '||pl||'"'||pl
||lf||'    )'
||lf||'    location ('||pl||'fr02_allergy_translation_6.csv'||pl||')'
||lf||'  )'
||lf||'REJECT LIMIT 0';
begin
pk_versioning.run( l_sql);
end;
/



--ALERT-272584 (end)

--- CMF 02
BEGIN
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'fr01_allergy_translation_6', 'TABLE', 'DPC', 'N', '', 'N');
END;
/
--CREATE--
declare
pl  constant varchar2(0050 char) := '''';
lf  constant varchar2(0050 char) := chr(10);
l_sql  varchar2(4000) :=
'create table fr01_allergy_translation_6'
||lf||'('
||lf||'  ID_CDR_MESSAGE  NUMBER(24), '
||lf||'  DESCR            VARCHAR2(255)'
||lf||')'
||lf||'  organization external '
||lf||'  ('
||lf||'    default directory DATA_IMP_DIR'
||lf||'    access parameters'
||lf||'    ('
||lf||'      records delimited by '||pl||'\r\n'||pl||' CHARACTERSET WE8MSWIN1252'
||lf||'      fields terminated by '||pl||';'||pl
||lf||'      OPTIONALLY ENCLOSED BY '||pl||'"'||pl
||lf||'    )'
||lf||'    location ('||pl||'fr02_allergy_translation_6.csv'||pl||')'
||lf||'  )'
||lf||'REJECT LIMIT 0';
begin
pk_versioning.run( l_sql);
end;
/