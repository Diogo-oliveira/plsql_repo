BEGIN
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'A_186008_ICD9_DXID', 'TABLE', 'CNT', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'A_186008_ME_DXID_ATC_CONTRA', 'TABLE', 'CNT', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'A_186008_me_med_atc_inter', 'TABLE', 'CNT', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'A_186008_ME_MED_INGRED', 'TABLE', 'CNT', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'A_186008_MI_DXID_ATC_CONTRA', 'TABLE', 'CNT', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'A_186008_mi_med_atc_inter', 'TABLE', 'CNT', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'A_186008_MI_MED_INGRED', 'TABLE', 'CNT', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'A_186008_MED_INGRED', 'TABLE', 'CNT', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'A_186008_MED_ALRGN_GRP_INGRED', 'TABLE', 'CNT', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'A_186008_MED_ALRGN_GRP', 'TABLE', 'CNT', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'A_186008_MED_ALRGN_CROSS', 'TABLE', 'CNT', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'A_186008_MED_ALRGN_CROSS_GRP', 'TABLE', 'CNT', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'A_186008_med_alrgn_pick_lt', 'TABLE', 'CNT', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'A_186008_MED_ALRGN_PICK_LIST', 'TABLE', 'CNT', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'A_186008_med_alrgn_aller_l', 'TABLE', 'CNT', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'ERR$_ICD9_DXID', 'TABLE', 'CNT', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'ERR$_ME_DXID_ATC_CONTRA', 'TABLE', 'CNT', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'ERR$_ME_MED_ATC_INTERACTION', 'TABLE', 'CNT', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'ERR$_ME_MED_INGRED', 'TABLE', 'CNT', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'ERR$_MI_DXID_ATC_CONTRA', 'TABLE', 'CNT', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'ERR$_MI_MED_ATC_INTERACTION', 'TABLE', 'CNT', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'ERR$_MI_MED_INGRED', 'TABLE', 'CNT', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'ERR$_MED_INGRED', 'TABLE', 'CNT', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'ERR$_MED_ALRGN_GRP_INGRED', 'TABLE', 'CNT', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'ERR$_MED_ALRGN_GRP', 'TABLE', 'CNT', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'ERR$_MED_ALRGN_CROSS', 'TABLE', 'CNT', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'ERR$_MED_ALRGN_CROSS_GRP', 'TABLE', 'CNT', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'ERR$_MED_ALRGN_PICK_LIST_TYP', 'TABLE', 'CNT', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'ERR$_MED_ALRGN_PICK_LIST', 'TABLE', 'CNT', 'N', '', 'N');
PK_FRMW_OBJECTS.insert_into_frmw_objects('ALERT', 'ERR$_MED_ALRGN_ALLERGY_LINK', 'TABLE', 'CNT', 'N', '', 'N');
END;
/


--CREATE--
create table A_186008_mi_med_ingred
(
  DCI_DESC VARCHAR2(255), 
  DCI_ID VARCHAR2(255), 
  FLG_AVAILABLE VARCHAR2(1), 
  ID_DRUG VARCHAR2(255), 
  ID_INGRED NUMBER(24), 
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
    location ('A_186008_mi_med_ingred.csv')
  )
REJECT LIMIT 0;
--CREATE--
create table A_186008_mi_med_atc_inter
(
  ATCD VARCHAR2(255), 
  ATCDESCD VARCHAR2(255), 
  DDI VARCHAR2(255), 
  DDI_DESD VARCHAR2(255), 
  DDI_SLD VARCHAR2(255), 
  ID_DRUG VARCHAR2(255), 
  ID_DRUG_INTERACT VARCHAR2(255), 
  ID_INTERACT_MESSAGE NUMBER(24), 
  ID_INTERACT_MESSAGE_FORMAT NUMBER(24), 
  INTERDDI VARCHAR2(255), 
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
    location ('A_186008_mi_med_atc_inter.csv')
  )
REJECT LIMIT 0;
--CREATE--
create table A_186008_mi_dxid_atc_contra
(
  ATC VARCHAR2(255), 
  ATC_DESC VARCHAR2(255), 
  DDXCN_SL VARCHAR2(255), 
  DDXCN_SN VARCHAR2(255), 
  DXID VARCHAR2(255), 
  DXID_DESC VARCHAR2(255), 
  FLG_CI_ALL_AGE VARCHAR2(4), 
  FLG_CI_BOTH_GENDER VARCHAR2(4), 
  FLG_SHOW_WHEN_NO_CI VARCHAR2(4), 
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
    location ('A_186008_mi_dxid_atc_contra.csv')
  )
REJECT LIMIT 0;
--CREATE--
create table A_186008_me_med_ingred
(
  DCI_DESC VARCHAR2(255), 
  DCI_ID VARCHAR2(255), 
  EMB_ID VARCHAR2(255), 
  FLG_AVAILABLE VARCHAR2(1), 
  ID_INGRED NUMBER(24), 
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
    location ('A_186008_me_med_ingred.csv')
  )
REJECT LIMIT 0;
--CREATE--
create table A_186008_me_med_atc_inter
(
  ATCD VARCHAR2(255), 
  ATCDESCD VARCHAR2(255), 
  DDI VARCHAR2(255), 
  DDI_DESD VARCHAR2(255), 
  DDI_SLD VARCHAR2(255), 
  EMB_ID VARCHAR2(255), 
  EMB_ID_INTERACT VARCHAR2(255), 
  ID_INTERACT_MESSAGE NUMBER(24), 
  ID_INTERACT_MESSAGE_FORMAT NUMBER(24), 
  INTERDDI VARCHAR2(255), 
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
    location ('A_186008_me_med_atc_inter.csv')
  )
REJECT LIMIT 0;
--CREATE--
create table A_186008_me_dxid_atc_contra
(
  ATC VARCHAR2(255), 
  ATC_DESC VARCHAR2(255), 
  DDXCN_SL VARCHAR2(255), 
  DDXCN_SN VARCHAR2(255), 
  DXID VARCHAR2(255), 
  DXID_DESC VARCHAR2(255), 
  EMB_ID VARCHAR2(255), 
  FLG_CI_ALL_AGE VARCHAR2(4), 
  FLG_CI_BOTH_GENDER VARCHAR2(4), 
  FLG_SHOW_WHEN_NO_CI VARCHAR2(4), 
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
    location ('A_186008_me_dxid_atc_contra.csv')
  )
REJECT LIMIT 0;
--CREATE--
create table A_186008_med_ingred
(
  FLG_AVAILABLE VARCHAR2(1), 
  FLG_HIC_POT_INACTIV VARCHAR2(1), 
  ID_INGRED NUMBER(24), 
  INGRED_DESC VARCHAR2(255), 
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
    location ('A_186008_med_ingred.csv')
  )
REJECT LIMIT 0;
--CREATE--
create table A_186008_med_alrgn_pick_lt
(
  CCPT_ALRGN_TYP_DESC VARCHAR2(255), 
  ID_CCPT_ALRGN_TYP NUMBER(24), 
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
    location ('A_186008_med_alrgn_pick_lt.csv')
  )
REJECT LIMIT 0;
--CREATE--
create table A_186008_med_alrgn_pick_list
(
  CCPT_ALRGN_DESC VARCHAR2(255), 
  FLG_AVAILABLE VARCHAR2(1), 
  ID_CCPT_ALRGN NUMBER(24), 
  ID_CCPT_ALRGN_TYP NUMBER(24), 
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
    location ('A_186008_med_alrgn_pick_list.csv')
  )
REJECT LIMIT 0;
--CREATE--
create table A_186008_med_alrgn_grp_ingred
(
  ID_ALRGN_GRP NUMBER(24), 
  ID_INGRED NUMBER(24), 
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
    location ('A_186008_med_alrgn_grp_ingred.csv')
  )
REJECT LIMIT 0;
--CREATE--
create table A_186008_med_alrgn_grp
(
  ALRGN_GRP_DESC VARCHAR2(255), 
  FLG_AVAILABLE VARCHAR2(1), 
  FLG_GRP_POT_INACTIV VARCHAR2(1), 
  ID_ALRGN_GRP NUMBER(24), 
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
    location ('A_186008_med_alrgn_grp.csv')
  )
REJECT LIMIT 0;
--CREATE--
create table A_186008_med_alrgn_cross_grp
(
  ALRGN_CROSS_GRP_DESC VARCHAR2(255), 
  FLG_AVAILABLE VARCHAR2(1), 
  FLG_GRP_POT_INACTIV VARCHAR2(1), 
  ID_ALRGN_CROSS_GRP NUMBER(24), 
  ID_ALRGN_GRP NUMBER(24), 
  ID_INGRED NUMBER(24), 
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
    location ('A_186008_med_alrgn_cross_grp.csv')
  )
REJECT LIMIT 0;
--CREATE--
create table A_186008_med_alrgn_cross
(
  FLG_AVAILABLE VARCHAR2(1), 
  FLG_HIC_POT_INACTIV VARCHAR2(1), 
  ID_ALRGN NUMBER(24), 
  ID_CROSS_INGRED NUMBER(24), 
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
    location ('A_186008_med_alrgn_cross.csv')
  )
REJECT LIMIT 0;
--CREATE--
create table A_186008_med_alrgn_aller_l
(
  ID_ALLERGY NUMBER(24), 
  ID_ALRGN NUMBER(24), 
  ID_CCPT_ALRGN_TYP NUMBER(24), 
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
    location ('A_186008_med_alrgn_aller_l.csv')
  )
REJECT LIMIT 0;
--CREATE--
create table A_186008_icd9_dxid
(
  DXID VARCHAR2(255), 
  ICD9CM_CODE VARCHAR2(255), 
  ICD9CM_DESC VARCHAR2(255), 
  NAV_CODE VARCHAR2(255), 
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
    location ('A_186008_icd9_dxid.csv')
  )
REJECT LIMIT 0;
