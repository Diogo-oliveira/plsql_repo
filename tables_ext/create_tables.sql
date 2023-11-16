-- CHANGED BY Filipe Faria
-- CHANGE DATE: 2011-MAI-10
-- CHANGE REASON: ALERT-177312
--CREATE--
create table A_177312_drug_clin_serv
(
  DOSAGE VARCHAR2(100), 
  DURATION NUMBER(24), 
  FLG_TAKE_TYPE VARCHAR2(1), 
  FLG_TYPE VARCHAR2(1), 
  FREQUENCY NUMBER(24), 
  ID_CLINICAL_SERVICE NUMBER(24), 
  ID_DRUG VARCHAR2(255), 
  ID_DRUG_CLIN_SERV NUMBER(24), 
  ID_MARKET NUMBER(24), 
  ID_SOFTWARE NUMBER(24), 
  INTERVAL NUMBER(12), 
  QTY_INST NUMBER(24), 
  TAKES NUMBER(12), 
  UNIT_MEASURE_DUR NUMBER(24), 
  UNIT_MEASURE_FREQ NUMBER(24), 
  UNIT_MEASURE_INST NUMBER(24), 
  VERSION VARCHAR2(100)
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
    location ('A_177312_drug_clin_serv.csv')
  )
REJECT LIMIT 0;
-- END CHANGE BY Filipe Faria


-- CHANGED BY: Artur Costa
-- CHANGE DATE: 01/02/2017
-- CHANGE REASON: ALERT-325529 
-- S3U10
BEGIN

    -- allergy_inst_soft_market
    pk_frmw_objects.insert_into_frmw_objects(i_owner             => 'ALERT',
                                             i_obj_name          => 's3u10_aism',
                                             i_obj_type          => 'TABLE',
                                             i_flg_category      => 'DPC',
                                             i_flg_alert_default => 'N',
                                             i_delete_script     => NULL,
                                             i_flg_default_child => 'N',
                                             i_responsible_team  => 'MEDICATION');

    -- allergy
    pk_frmw_objects.insert_into_frmw_objects(i_owner             => 'ALERT',
                                             i_obj_name          => 's3u10_allergy',
                                             i_obj_type          => 'TABLE',
                                             i_flg_category      => 'DPC',
                                             i_flg_alert_default => 'N',
                                             i_delete_script     => NULL,
                                             i_flg_default_child => 'N',
                                             i_responsible_team  => 'MEDICATION');

    -- translation : id_lang ->17
    pk_frmw_objects.insert_into_frmw_objects(i_owner             => 'ALERT',
                                             i_obj_name          => 's3u10_translation_17',
                                             i_obj_type          => 'TABLE',
                                             i_flg_category      => 'DPC',
                                             i_flg_alert_default => 'N',
                                             i_delete_script     => NULL,
                                             i_flg_default_child => 'N',
                                             i_responsible_team  => 'MEDICATION');

END;
/


-- allergy_inst_soft_market
CREATE TABLE s3u10_aism
(
     --Nome das colunas da tabela    
     FLG_FREQ VARCHAR2(1 CHAR), 
     ID_ALLERGY NUMBER(12), 
     ID_ALLERGY_PARENT NUMBER(12), 
     ID_INSTITUTION NUMBER(12), 
     ID_MARKET NUMBER(12), 
     ID_SOFTWARE NUMBER(12)
)
organization external
(
       DEFAULT directory DATA_IMP_DIR
       access parameters
       (
              records delimited by '\r\n' CHARACTERSET WE8MSWIN1252
              fields terminated by ';'
              optionally enclosed by '"'
       )
       location('v3f10aism.csv')   -- nome do ficheiro csv correspondente
)
reject limit 0;


-- allergy
CREATE TABLE s3u10_allergy
(
     CODE_ALLERGY VARCHAR2(200 CHAR), 
     FLG_ACTIVE VARCHAR2(1 CHAR), 
     FLG_AVAILABLE VARCHAR2(1 CHAR), 
     FLG_OTHER VARCHAR2(2 CHAR), 
     FLG_SELECT VARCHAR2(1 CHAR), 
     FLG_WITHOUT VARCHAR2(2 CHAR), 
     ID_ALLERGY NUMBER(12), 
     ID_ALLERGY_PARENT NUMBER(12), 
     ID_ALLERGY_STANDARD VARCHAR2(80 CHAR), 
     ID_CONTENT VARCHAR2(200 CHAR), 
     MARKET VARCHAR2(50 CHAR), 
     RANK NUMBER(12),
     ID_PRODUCT VARCHAR2(200 CHAR),
     ID_ING_GROUP VARCHAR2(200 CHAR),
     ID_INGREDIENTS VARCHAR2(200 CHAR)
)
organization external
(
       DEFAULT directory DATA_IMP_DIR
       access parameters
       (
              records delimited by '\r\n' CHARACTERSET WE8MSWIN1252
              fields terminated by ';'
              optionally enclosed by '"'
       )
       location('v3f10allergy.csv')   -- nome do ficheiro csv correspondente
)
reject limit 0;


-- translation_17
CREATE TABLE s3u10_translation_17
(
  CODE_TRANSLATION      VARCHAR2(255), 
  DESCR            VARCHAR2(4000)
)
  organization external 
  (
    DEFAULT directory DATA_IMP_DIR
    access parameters
    (
      records delimited BY '\r\n' CHARACTERSET WE8MSWIN1252
      FIELDS terminated BY ';'
      OPTIONALLY ENCLOSED BY '"'
    )
    location ('v3f10translation_17.csv')
  )
reject limit 0;

-- END CHANGE BY: Artur Costa



-- CHANGED BY: Joao Coutinho
-- CHANGED DATE: 2017-7-6
-- CHANGED REASON: ALERT-320975

-- s4u1
BEGIN
    -- allergy_inst_soft_market
    pk_frmw_objects.insert_into_frmw_objects(i_owner             => 'ALERT',
                                             i_obj_name          => 's4u1_aism',
                                             i_obj_type          => 'TABLE',
                                             i_flg_category      => 'DPC',
                                             i_flg_alert_default => 'N',
                                             i_delete_script     => NULL,
                                             i_flg_default_child => 'N',
                                             i_responsible_team  => 'MEDICATION');

    -- allergy
    pk_frmw_objects.insert_into_frmw_objects(i_owner             => 'ALERT',
                                             i_obj_name          => 's4u1_allergy', 
                                             i_obj_type          => 'TABLE',
                                             i_flg_category      => 'DPC',
                                             i_flg_alert_default => 'N',
                                             i_delete_script     => NULL,
                                             i_flg_default_child => 'N',
                                             i_responsible_team  => 'MEDICATION');

    -- translation
    pk_frmw_objects.insert_into_frmw_objects(i_owner             => 'ALERT',
                                             i_obj_name          => 's4u1_translation_16',
                                             i_obj_type          => 'TABLE',
                                             i_flg_category      => 'DPC',
                                             i_flg_alert_default => 'N',
                                             i_delete_script     => NULL,
                                             i_flg_default_child => 'N',
                                             i_responsible_team  => 'MEDICATION');
END;
/

-- allergy_inst_soft_market
CREATE TABLE s4u1_aism
(
     --Nome das colunas da tabela    
     FLG_FREQ VARCHAR2(1 CHAR), 
     ID_ALLERGY NUMBER(12), 
     ID_ALLERGY_PARENT NUMBER(12), 
     ID_INSTITUTION NUMBER(12), 
     ID_MARKET NUMBER(12), 
     ID_SOFTWARE NUMBER(12)
)
organization external
(
       DEFAULT directory DATA_IMP_DIR
       access parameters
       (
              records delimited by '\r\n' CHARACTERSET WE8MSWIN1252
              fields terminated by ';'
              optionally enclosed by '"'
       )
       location('v4f1aism.csv')   -- nome do ficheiro csv correspondente
)
reject limit 0;

-- allergy
CREATE TABLE s4u1_allergy
(
     CODE_ALLERGY VARCHAR2(200 CHAR), 
     FLG_ACTIVE VARCHAR2(1 CHAR), 
     FLG_AVAILABLE VARCHAR2(1 CHAR), 
     FLG_OTHER VARCHAR2(2 CHAR), 
     FLG_SELECT VARCHAR2(1 CHAR), 
     FLG_WITHOUT VARCHAR2(2 CHAR), 
     ID_ALLERGY NUMBER(12), 
     ID_ALLERGY_PARENT NUMBER(12), 
     ID_ALLERGY_STANDARD VARCHAR2(80 CHAR), 
     ID_CONTENT VARCHAR2(200 CHAR), 
     MARKET VARCHAR2(50 CHAR), 
     RANK NUMBER(12),
     ID_PRODUCT VARCHAR2(200 CHAR),
     ID_ING_GROUP VARCHAR2(200 CHAR),
     ID_INGREDIENTS VARCHAR2(200 CHAR)
)
organization external
(
       DEFAULT directory DATA_IMP_DIR
       access parameters
       (
              records delimited by '\r\n' CHARACTERSET WE8MSWIN1252
              fields terminated by ';'
              optionally enclosed by '"'
       )
       location('v4f1allergy.csv')   -- nome do ficheiro csv correspondente
)
reject limit 0;

-- translation_16
CREATE TABLE s4u1_translation_16
(
  CODE_TRANSLATION      VARCHAR2(255), 
  DESCR            VARCHAR2(4000)
)
  organization external 
  (
    DEFAULT directory DATA_IMP_DIR
    access parameters
    (
      records delimited BY '\r\n' CHARACTERSET WE8MSWIN1252
      FIELDS terminated BY ';'
      OPTIONALLY ENCLOSED BY '"'
    )
    location ('v4f1translation_16.csv')
  )
reject limit 0;
-- CHANGE END: Joao Coutinho



-- CHANGED BY: Joao Coutinho
-- CHANGED DATE: 2017-7-28
-- CHANGED REASON: ALERT-331101

-- s1u4
BEGIN
    -- allergy_inst_soft_market
    pk_frmw_objects.insert_into_frmw_objects(i_owner             => 'ALERT',
                                             i_obj_name          => 's1u4_aism',
                                             i_obj_type          => 'TABLE',
                                             i_flg_category      => 'DPC',
                                             i_flg_alert_default => 'N',
                                             i_delete_script     => NULL,
                                             i_flg_default_child => 'N',
                                             i_responsible_team  => 'MEDICATION');

    -- allergy
    pk_frmw_objects.insert_into_frmw_objects(i_owner             => 'ALERT',
                                             i_obj_name          => 's1u4_allergy', 
                                             i_obj_type          => 'TABLE',
                                             i_flg_category      => 'DPC',
                                             i_flg_alert_default => 'N',
                                             i_delete_script     => NULL,
                                             i_flg_default_child => 'N',
                                             i_responsible_team  => 'MEDICATION');

    -- translation : id_lang ->17
    pk_frmw_objects.insert_into_frmw_objects(i_owner             => 'ALERT',
                                             i_obj_name          => 's1u4_translation_6',
                                             i_obj_type          => 'TABLE',
                                             i_flg_category      => 'DPC',
                                             i_flg_alert_default => 'N',
                                             i_delete_script     => NULL,
                                             i_flg_default_child => 'N',
                                             i_responsible_team  => 'MEDICATION');
											 
    pk_frmw_objects.insert_into_frmw_objects(i_owner             => 'ALERT',
                                             i_obj_name          => 's1u4_um',
                                             i_obj_type          => 'TABLE',
                                             i_flg_category      => 'DPC',
                                             i_flg_alert_default => 'N',
                                             i_delete_script     => NULL,
                                             i_flg_default_child => 'N',
                                             i_responsible_team  => 'MEDICATION');

END;
/

-- allergy_inst_soft_market
CREATE TABLE s1u4_aism
(
     --Nome das colunas da tabela    
     FLG_FREQ 			VARCHAR2(1 CHAR), 
     ID_ALLERGY 		NUMBER(12), 
     ID_ALLERGY_PARENT  NUMBER(12), 
     ID_INSTITUTION 	NUMBER(12), 
     ID_MARKET 			NUMBER(12), 
     ID_SOFTWARE 		NUMBER(12)
)
organization external
(
       DEFAULT directory DATA_IMP_DIR
       access parameters
       (
              records delimited by '\r\n' CHARACTERSET WE8MSWIN1252
              fields terminated by ';'
              optionally enclosed by '"'
       )
       location('v1f4aism.csv')   -- nome do ficheiro csv correspondente
)
reject limit 0;


-- allergy
CREATE TABLE s1u4_allergy
(
     CODE_ALLERGY 		 VARCHAR2(200 CHAR), 
     FLG_ACTIVE 		 VARCHAR2(1 CHAR), 
     FLG_AVAILABLE 		 VARCHAR2(1 CHAR), 
     FLG_OTHER 			 VARCHAR2(2 CHAR), 
     FLG_SELECT 		 VARCHAR2(1 CHAR), 
     FLG_WITHOUT 		 VARCHAR2(2 CHAR), 
     ID_ALLERGY 		 NUMBER(12), 
     ID_ALLERGY_PARENT   NUMBER(12), 
     ID_ALLERGY_STANDARD VARCHAR2(80 CHAR), 
     ID_CONTENT 		 VARCHAR2(200 CHAR), 
     MARKET 			 VARCHAR2(50 CHAR), 
     RANK 				 NUMBER(12),
     ID_PRODUCT 		 VARCHAR2(200 CHAR),
     ID_ING_GROUP 		 VARCHAR2(200 CHAR),
     ID_INGREDIENTS 	 VARCHAR2(200 CHAR)
)
organization external
(
       DEFAULT directory DATA_IMP_DIR
       access parameters
       (
              records delimited by '\r\n' CHARACTERSET WE8MSWIN1252
              fields terminated by ';'
              optionally enclosed by '"'
       )
       location('v1f4allergy.csv')   -- nome do ficheiro csv correspondente
)
reject limit 0;


-- translation_6
CREATE TABLE s1u4_translation_6
(
  CODE_TRANSLATION 	VARCHAR2(255), 
  DESCR             VARCHAR2(4000)
)
  organization external 
  (
    DEFAULT directory DATA_IMP_DIR
    access parameters
    (
      records delimited BY '\r\n' CHARACTERSET WE8MSWIN1252
      FIELDS terminated BY ';'
      OPTIONALLY ENCLOSED BY '"'
    )
    location ('v1f4translation_6.csv')
  )
reject limit 0;

CREATE TABLE s1u4_um
(
    ID_UNIT_MEASURE NUMBER(24),
	CODE_UNIT_MEASURE VARCHAR2(200),
	ID_UNIT_MEASURE_TYPE  NUMBER(24),
	INTERNAL_NAME VARCHAR2(200),
	ENUMERATED  VARCHAR2(1),
	FLG_AVAILABLE VARCHAR2(1),
	CODE_UNIT_MEASURE_ABRV  VARCHAR2(200)
)
  organization external 
  (
    DEFAULT directory DATA_IMP_DIR
    access parameters
    (
      records delimited BY '\r\n' CHARACTERSET WE8MSWIN1252
      FIELDS terminated BY ';'
      OPTIONALLY ENCLOSED BY '"'
    )
    location ('v1f4um.csv')
  )
reject limit 0;
-- CHANGE END: Joao Coutinho



-- CHANGED BY: Ana Moita
-- CHANGED DATE: 2017-9-21
-- CHANGED REASON: ALERT-332379

BEGIN

    pk_frmw_objects.insert_into_frmw_objects('ALERT',
                                             'C1_CAT_LOCALIDAD',
                                             'TABLE',
                                             'CNT',
                                             'N',
                                             '',
                                             'N',
                                             '',
                                             'CONTENT');

END;
/
--CREATE--
create table C1_CAT_LOCALIDAD
(
  CATALOG_KEY VARCHAR2(10 CHAR), 
  LOCALIDAD VARCHAR2(200 CHAR),
  EFE_KEY VARCHAR2(10 CHAR),
  MUN_KEY VARCHAR2(10 CHAR),
  ID_ALERT NUMBER(20 CHAR)
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
    location ('c1_cat_localidad.csv')
  )
REJECT LIMIT 0;

-- CHANGE END: Ana Moita



-- CHANGED BY: Ana Moita
-- CHANGED DATE: 2017-9-27
-- CHANGED REASON: ALERT-332373

BEGIN

    pk_frmw_objects.insert_into_frmw_objects('ALERT', 'C1_CAT_CP', 'TABLE', 'CNT', 'N', '', 'N', '', 'CONTENT');

END;
/

CREATE TABLE c1_cat_cp(catalog_key VARCHAR2(500 CHAR),
                       d_asenta VARCHAR2(500 CHAR),
                       d_tipo_asenta VARCHAR2(500 CHAR),
                       d_mnpio VARCHAR2(500 CHAR),
                       d_estado VARCHAR2(500 CHAR),
                       d_ciudad VARCHAR2(500 CHAR),
					   d_cp VARCHAR2(500 CHAR),
                       efe_key VARCHAR2(500 CHAR),
                       c_oficina VARCHAR2(500 CHAR),
                       c_tipo_asenta VARCHAR2(500 CHAR),
                       mun_key VARCHAR2(500 CHAR),
                       id_asenta_cpcons VARCHAR2(500 CHAR),
                       d_zona VARCHAR2(500 CHAR),
                       c_cve_ciudad VARCHAR2(500 CHAR),
                       id_alert VARCHAR2(500 CHAR)) organization EXTERNAL(DEFAULT directory data_imp_dir access
                                                                                  PARAMETERS(records delimited BY
                                                                                             '\r\n' characterset
                                                                                             we8mswin1252 fields
                                                                                             terminated BY ';'
                                                                                             optionally enclosed BY '"')
                                                                                  location('c1_cat_cp.csv')) reject LIMIT 0;
-- CHANGE END: Ana Moita



-- CHANGED BY: Joao Coutinho
-- CHANGED DATE: 2017-10-19
-- CHANGED REASON: ALERT-333036

-- s1u5
BEGIN
    -- allergy_inst_soft_market
    pk_frmw_objects.insert_into_frmw_objects(i_owner             => 'ALERT',
                                             i_obj_name          => 's1u5_aism',
                                             i_obj_type          => 'TABLE',
                                             i_flg_category      => 'DPC',
                                             i_flg_alert_default => 'N',
                                             i_delete_script     => NULL,
                                             i_flg_default_child => 'N',
                                             i_responsible_team  => 'MEDICATION');

    -- allergy
    pk_frmw_objects.insert_into_frmw_objects(i_owner             => 'ALERT',
                                             i_obj_name          => 's1u5_allergy', 
                                             i_obj_type          => 'TABLE',
                                             i_flg_category      => 'DPC',
                                             i_flg_alert_default => 'N',
                                             i_delete_script     => NULL,
                                             i_flg_default_child => 'N',
                                             i_responsible_team  => 'MEDICATION');

    -- translation : id_lang ->17
    pk_frmw_objects.insert_into_frmw_objects(i_owner             => 'ALERT',
                                             i_obj_name          => 's1u5_translation_6',
                                             i_obj_type          => 'TABLE',
                                             i_flg_category      => 'DPC',
                                             i_flg_alert_default => 'N',
                                             i_delete_script     => NULL,
                                             i_flg_default_child => 'N',
                                             i_responsible_team  => 'MEDICATION');
											 
    pk_frmw_objects.insert_into_frmw_objects(i_owner             => 'ALERT',
                                             i_obj_name          => 's1u5_um',
                                             i_obj_type          => 'TABLE',
                                             i_flg_category      => 'DPC',
                                             i_flg_alert_default => 'N',
                                             i_delete_script     => NULL,
                                             i_flg_default_child => 'N',
                                             i_responsible_team  => 'MEDICATION');

END;
/

-- allergy_inst_soft_market
CREATE TABLE s1u5_aism
(
     --Nome das colunas da tabela    
     FLG_FREQ 			VARCHAR2(1 CHAR), 
     ID_ALLERGY 		NUMBER(12), 
     ID_ALLERGY_PARENT  NUMBER(12), 
     ID_INSTITUTION 	NUMBER(12), 
     ID_MARKET 			NUMBER(12), 
     ID_SOFTWARE 		NUMBER(12)
)
organization external
(
       DEFAULT directory DATA_IMP_DIR
       access parameters
       (
              records delimited by '\r\n' CHARACTERSET WE8MSWIN1252
              fields terminated by ';'
              optionally enclosed by '"'
       )
       location('v1f5aism.csv')   -- nome do ficheiro csv correspondente
)
reject limit 0;


-- allergy
CREATE TABLE s1u5_allergy
(
     CODE_ALLERGY 		 VARCHAR2(200 CHAR), 
     FLG_ACTIVE 		 VARCHAR2(1 CHAR), 
     FLG_AVAILABLE 		 VARCHAR2(1 CHAR), 
     FLG_OTHER 			 VARCHAR2(2 CHAR), 
     FLG_SELECT 		 VARCHAR2(1 CHAR), 
     FLG_WITHOUT 		 VARCHAR2(2 CHAR), 
     ID_ALLERGY 		 NUMBER(12), 
     ID_ALLERGY_PARENT   NUMBER(12), 
     ID_ALLERGY_STANDARD VARCHAR2(80 CHAR), 
     ID_CONTENT 		 VARCHAR2(200 CHAR), 
     MARKET 			 VARCHAR2(50 CHAR), 
     RANK 				 NUMBER(12),
     ID_PRODUCT 		 VARCHAR2(200 CHAR),
     ID_ING_GROUP 		 VARCHAR2(200 CHAR),
     ID_INGREDIENTS 	 VARCHAR2(200 CHAR)
)
organization external
(
       DEFAULT directory DATA_IMP_DIR
       access parameters
       (
              records delimited by '\r\n' CHARACTERSET WE8MSWIN1252
              fields terminated by ';'
              optionally enclosed by '"'
       )
       location('v1f5allergy.csv')   -- nome do ficheiro csv correspondente
)
reject limit 0;


-- translation_6
CREATE TABLE s1u5_translation_6
(
  CODE_TRANSLATION 	VARCHAR2(255), 
  DESCR             VARCHAR2(4000)
)
  organization external 
  (
    DEFAULT directory DATA_IMP_DIR
    access parameters
    (
      records delimited BY '\r\n' CHARACTERSET WE8MSWIN1252
      FIELDS terminated BY ';'
      OPTIONALLY ENCLOSED BY '"'
    )
    location ('v1f5translation_6.csv')
  )
reject limit 0;
-- CHANGE END: Joao Coutinho

-- CHANGED BY: Ricardo Meira
-- CHANGED DATE: 2018-02-08
-- CHANGED REASON: EMR-313
BEGIN

    -- allergy_inst_soft_market
    pk_frmw_objects.insert_into_frmw_objects(i_owner             => 'ALERT',
                                             i_obj_name          => 'v7f12aism',
                                             i_obj_type          => 'TABLE',
                                             i_flg_category      => 'DPC',
                                             i_flg_alert_default => 'N',
                                             i_delete_script     => NULL,
                                             i_flg_default_child => 'N',
                                             i_responsible_team  => 'MEDICATION');

    -- allergy
    pk_frmw_objects.insert_into_frmw_objects(i_owner             => 'ALERT',
                                             i_obj_name          => 'v7f12allergy', 
                                             i_obj_type          => 'TABLE',
                                             i_flg_category      => 'DPC',
                                             i_flg_alert_default => 'N',
                                             i_delete_script     => NULL,
                                             i_flg_default_child => 'N',
                                             i_responsible_team  => 'MEDICATION');

    -- translation : id_lang ->17
    pk_frmw_objects.insert_into_frmw_objects(i_owner             => 'ALERT',
                                             i_obj_name          => 'v7f12translation_8',
                                             i_obj_type          => 'TABLE',
                                             i_flg_category      => 'DPC',
                                             i_flg_alert_default => 'N',
                                             i_delete_script     => NULL,
                                             i_flg_default_child => 'N',
                                             i_responsible_team  => 'MEDICATION');

END;
/


-- allergy_inst_soft_market
CREATE TABLE v7f12aism
(
     --Nome das colunas da tabela    
     FLG_FREQ VARCHAR2(1 CHAR), 
     ID_ALLERGY NUMBER(12), 
     ID_ALLERGY_PARENT NUMBER(12), 
     ID_INSTITUTION NUMBER(12), 
     ID_MARKET NUMBER(12), 
     ID_SOFTWARE NUMBER(12)
)
organization external
(
       DEFAULT directory DATA_IMP_DIR
       access parameters
       (
              records delimited by '\r\n' CHARACTERSET WE8MSWIN1252
              fields terminated by ';'
              optionally enclosed by '"'
       )
       location('v7f12aism.csv')   -- nome do ficheiro csv correspondente
)
reject limit 0;


-- allergy
CREATE TABLE v7f12allergy
(
     CODE_ALLERGY VARCHAR2(200 CHAR), 
     FLG_ACTIVE VARCHAR2(1 CHAR), 
     FLG_AVAILABLE VARCHAR2(1 CHAR), 
     FLG_OTHER VARCHAR2(2 CHAR), 
     FLG_SELECT VARCHAR2(1 CHAR), 
     FLG_WITHOUT VARCHAR2(2 CHAR), 
     ID_ALLERGY NUMBER(12), 
     ID_ALLERGY_PARENT NUMBER(12), 
     ID_ALLERGY_STANDARD VARCHAR2(80 CHAR), 
     ID_CONTENT VARCHAR2(200 CHAR), 
     MARKET VARCHAR2(50 CHAR), 
     RANK NUMBER(12),
     ID_PRODUCT VARCHAR2(200 CHAR),
     ID_ING_GROUP VARCHAR2(200 CHAR),
     ID_INGREDIENTS VARCHAR2(200 CHAR)
)
organization external
(
       DEFAULT directory DATA_IMP_DIR
       access parameters
       (
              records delimited by '\r\n' CHARACTERSET WE8MSWIN1252
              fields terminated by ';'
              optionally enclosed by '"'
       )
       location('v7f12allergy.csv')   -- nome do ficheiro csv correspondente
)
reject limit 0;


-- translation_8
CREATE TABLE v7f12translation_8
(
  CODE_TRANSLATION      VARCHAR2(255), 
  DESCR            VARCHAR2(4000)
)
  organization external 
  (
    DEFAULT directory DATA_IMP_DIR
    access parameters
    (
      records delimited BY '\r\n' CHARACTERSET WE8MSWIN1252
      FIELDS terminated BY ';'
      OPTIONALLY ENCLOSED BY '"'
    )
    location ('v7f12translation_8.csv')
  )
reject limit 0;

-- CHANGE END: Ricardo Meira

-- CHANGED BY: rui.mendonca
-- CHANGE DATE: 19/10/2018 09:44
-- CHANGE REASON: [EMR-7725] [SE][SA] Update of VIDAL International VMP database
BEGIN
    -- allergy_inst_soft_market
    pk_frmw_objects.insert_into_frmw_objects(i_owner             => 'ALERT',
                                             i_obj_name          => 'v7f13aism',
                                             i_obj_type          => 'TABLE',
                                             i_flg_category      => 'DPC',
                                             i_flg_alert_default => 'N',
                                             i_delete_script     => NULL,
                                             i_flg_default_child => 'N',
                                             i_responsible_team  => 'MEDICATION');

    -- allergy
    pk_frmw_objects.insert_into_frmw_objects(i_owner             => 'ALERT',
                                             i_obj_name          => 'v7f13allergy', 
                                             i_obj_type          => 'TABLE',
                                             i_flg_category      => 'DPC',
                                             i_flg_alert_default => 'N',
                                             i_delete_script     => NULL,
                                             i_flg_default_child => 'N',
                                             i_responsible_team  => 'MEDICATION');

    -- translation : id_lang -> 8
    pk_frmw_objects.insert_into_frmw_objects(i_owner             => 'ALERT',
                                             i_obj_name          => 'v7f13translation_8',
                                             i_obj_type          => 'TABLE',
                                             i_flg_category      => 'DPC',
                                             i_flg_alert_default => 'N',
                                             i_delete_script     => NULL,
                                             i_flg_default_child => 'N',
                                             i_responsible_team  => 'MEDICATION');

END;
/


-- allergy_inst_soft_market
CREATE TABLE v7f13aism
(
     --Nome das colunas da tabela    
     FLG_FREQ VARCHAR2(1 CHAR), 
     ID_ALLERGY NUMBER(12), 
     ID_ALLERGY_PARENT NUMBER(12), 
     ID_INSTITUTION NUMBER(12), 
     ID_MARKET NUMBER(12), 
     ID_SOFTWARE NUMBER(12)
)
organization external
(
       DEFAULT directory DATA_IMP_DIR
       access parameters
       (
              records delimited by '\r\n' CHARACTERSET WE8MSWIN1252
              fields terminated by ';'
              optionally enclosed by '"'
       )
       location('v7f13aism.csv')   -- nome do ficheiro csv correspondente
)
reject limit 0;


-- allergy
CREATE TABLE v7f13allergy
(
     CODE_ALLERGY VARCHAR2(200 CHAR), 
     FLG_ACTIVE VARCHAR2(1 CHAR), 
     FLG_AVAILABLE VARCHAR2(1 CHAR), 
     FLG_OTHER VARCHAR2(2 CHAR), 
     FLG_SELECT VARCHAR2(1 CHAR), 
     FLG_WITHOUT VARCHAR2(2 CHAR), 
     ID_ALLERGY NUMBER(12), 
     ID_ALLERGY_PARENT NUMBER(12), 
     ID_ALLERGY_STANDARD VARCHAR2(80 CHAR), 
     ID_CONTENT VARCHAR2(200 CHAR), 
     MARKET VARCHAR2(50 CHAR), 
     RANK NUMBER(12),
     ID_PRODUCT VARCHAR2(200 CHAR),
     ID_ING_GROUP VARCHAR2(200 CHAR),
     ID_INGREDIENTS VARCHAR2(200 CHAR)
)
organization external
(
       DEFAULT directory DATA_IMP_DIR
       access parameters
       (
              records delimited by '\r\n' CHARACTERSET WE8MSWIN1252
              fields terminated by ';'
              optionally enclosed by '"'
       )
       location('v7f13allergy.csv')   -- nome do ficheiro csv correspondente
)
reject limit 0;


-- translation_8
CREATE TABLE v7f13translation_8
(
  CODE_TRANSLATION      VARCHAR2(255), 
  DESCR            VARCHAR2(4000)
)
  organization external 
  (
    DEFAULT directory DATA_IMP_DIR
    access parameters
    (
      records delimited BY '\r\n' CHARACTERSET WE8MSWIN1252
      FIELDS terminated BY ';'
      OPTIONALLY ENCLOSED BY '"'
    )
    location ('v7f13translation_8.csv')
  )
reject limit 0;
-- CHANGE END: rui.mendonca


-- CHANGED BY: Rui Dagoberto
-- CHANGED DATE: 2019-4-18
-- CHANGED REASON: EMR-217

BEGIN
    -- allergy_inst_soft_market
    pk_frmw_objects.insert_into_frmw_objects(i_owner             => 'ALERT',
                                             i_obj_name          => 'v3f14aism',
                                             i_obj_type          => 'TABLE',
                                             i_flg_category      => 'DPC',
                                             i_flg_alert_default => 'N',
                                             i_delete_script     => NULL,
                                             i_flg_default_child => 'N',
                                             i_responsible_team  => 'MEDICATION');

    -- allergy
    pk_frmw_objects.insert_into_frmw_objects(i_owner             => 'ALERT',
                                             i_obj_name          => 'v3f14allergy', 
                                             i_obj_type          => 'TABLE',
                                             i_flg_category      => 'DPC',
                                             i_flg_alert_default => 'N',
                                             i_delete_script     => NULL,
                                             i_flg_default_child => 'N',
                                             i_responsible_team  => 'MEDICATION');

    -- translation : id_lang -> 8
    pk_frmw_objects.insert_into_frmw_objects(i_owner             => 'ALERT',
                                             i_obj_name          => 'v3f14translation_17',
                                             i_obj_type          => 'TABLE',
                                             i_flg_category      => 'DPC',
                                             i_flg_alert_default => 'N',
                                             i_delete_script     => NULL,
                                             i_flg_default_child => 'N',
                                             i_responsible_team  => 'MEDICATION');

END;
/


-- allergy_inst_soft_market
CREATE TABLE v3f14aism
(
     --Nome das colunas da tabela    
     FLG_FREQ VARCHAR2(1 CHAR), 
     ID_ALLERGY NUMBER(12), 
     ID_ALLERGY_PARENT NUMBER(12), 
     ID_INSTITUTION NUMBER(12), 
     ID_MARKET NUMBER(12), 
     ID_SOFTWARE NUMBER(12)
)
organization external
(
       DEFAULT directory DATA_IMP_DIR
       access parameters
       (
              records delimited by '\r\n' CHARACTERSET WE8MSWIN1252
              fields terminated by ';'
              optionally enclosed by '"'
       )
       location('v3f14aism.csv')   -- nome do ficheiro csv correspondente
)
reject limit 0;


-- allergy
CREATE TABLE v3f14allergy
(
     CODE_ALLERGY VARCHAR2(200 CHAR), 
     FLG_ACTIVE VARCHAR2(1 CHAR), 
     FLG_AVAILABLE VARCHAR2(1 CHAR), 
     FLG_OTHER VARCHAR2(2 CHAR), 
     FLG_SELECT VARCHAR2(1 CHAR), 
     FLG_WITHOUT VARCHAR2(2 CHAR), 
     ID_ALLERGY NUMBER(12), 
     ID_ALLERGY_PARENT NUMBER(12), 
     ID_ALLERGY_STANDARD VARCHAR2(80 CHAR), 
     ID_CONTENT VARCHAR2(200 CHAR), 
     MARKET VARCHAR2(50 CHAR), 
     RANK NUMBER(12),
     ID_PRODUCT VARCHAR2(200 CHAR),
     ID_ING_GROUP VARCHAR2(200 CHAR),
     ID_INGREDIENTS VARCHAR2(200 CHAR)
)
organization external
(
       DEFAULT directory DATA_IMP_DIR
       access parameters
       (
              records delimited by '\r\n' CHARACTERSET WE8MSWIN1252
              fields terminated by ';'
              optionally enclosed by '"'
       )
       location('v3f14allergy.csv')   -- nome do ficheiro csv correspondente
)
reject limit 0;


-- translation_17
CREATE TABLE v3f14translation_17
(
  CODE_TRANSLATION      VARCHAR2(255), 
  DESCR            VARCHAR2(4000)
)
  organization external 
  (
    DEFAULT directory DATA_IMP_DIR
    access parameters
    (
      records delimited BY '\r\n' CHARACTERSET WE8MSWIN1252
      FIELDS terminated BY ';'
      OPTIONALLY ENCLOSED BY '"'
    )
    location ('translation_17_ALLERGY.csv')
  )
reject limit 0;

-- CHANGE END: Rui Dagoberto
