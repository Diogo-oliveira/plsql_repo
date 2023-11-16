BEGIN
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'A_183778_mi_med', 'TABLE', 'CNT', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'ERR$_mi_med', 'TABLE', 'CNT', 'N', '', 'N');

PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'A_183778_mi_med_pharm_group', 'TABLE', 'CNT', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'ERR$_mi_med_pharm_group', 'TABLE', 'CNT', 'N', '', 'N');

PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'A_183778_mi_med_route', 'TABLE', 'CNT', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'ERR$_mi_med_route', 'TABLE', 'CNT', 'N', '', 'N');
END;
/




--CREATE--
create table A_183778_mi_med
(
  AGE_MAX VARCHAR2(255), 
  AGE_MIN VARCHAR2(255), 
  CHNM_ID VARCHAR2(255), 
  CODE_CVX VARCHAR2(200), 
  DCI_DESCR VARCHAR2(255), 
  DCI_ID VARCHAR2(255), 
  DOSAGEM VARCHAR2(1000), 
  FLG_AVAILABLE VARCHAR2(1), 
  FLG_CONTROLLED_DRUG VARCHAR2(255), 
  FLG_JUSTIFY VARCHAR2(1), 
  FLG_MIX_FLUID VARCHAR2(255), 
  FLG_MULTIDOSE VARCHAR2(1), 
  FLG_TYPE VARCHAR2(1), 
  FORM_FARM_ABRV VARCHAR2(255), 
  FORM_FARM_DESCR VARCHAR2(255), 
  FORM_FARM_ID VARCHAR2(255), 
  FORM_FARM_ID_ID NUMBER(5), 
  GENDER VARCHAR2(1), 
  ID_CONTENT VARCHAR2(200), 
  ID_DRUG VARCHAR2(255), 
  ID_DRUG_BRAND VARCHAR2(255), 
  ID_UNIT_MEASURE VARCHAR2(255), 
  MDM_CODING VARCHAR2(255), 
  MED_BRAND_NAME VARCHAR2(255), 
  MED_DESCR VARCHAR2(255), 
  MED_DESCR_FORMATED VARCHAR2(255), 
  NOTES VARCHAR2(2000), 
  QT_DOS_COMP VARCHAR2(255), 
  ROUTE_ABRV VARCHAR2(255), 
  ROUTE_DESCR VARCHAR2(255), 
  ROUTE_ID VARCHAR2(255), 
  SHORT_MED_DESCR VARCHAR2(255), 
  UNIT_DOS_COMP VARCHAR2(255), 
  VERS VARCHAR2(255)
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
    location ('A_183778_mi_med.csv')
  )
REJECT LIMIT 0;
--CREATE--
create table A_183778_mi_med_pharm_group
(
  GROUP_ID VARCHAR2(255), 
  ID_DRUG VARCHAR2(255), 
  VERS VARCHAR2(255)
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
    location ('A_183778_mi_med_pharm_group.csv')
  )
REJECT LIMIT 0;
--CREATE--
create table A_183778_mi_med_route
(
  FLG_AVAILABLE VARCHAR2(1), 
  ID_DRUG VARCHAR2(255), 
  ROUTE_ID VARCHAR2(255), 
  VERS VARCHAR2(255)
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
    location ('A_183778_mi_med_route.csv')
  )
REJECT LIMIT 0;
