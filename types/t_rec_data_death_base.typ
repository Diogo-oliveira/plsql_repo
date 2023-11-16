begin
	pk_versioning.drop_types( table_varchar('T_TBL_DATA_DEATH_BASE', 'T_REC_DATA_DEATH_BASE') );
end;
/
CREATE OR REPLACE TYPE T_REC_DATA_DEATH_BASE FORCE AS OBJECT
(
id_institution      number
,id_patient             number
,dt_death               timestamp with local time zone
,id_episode             number
,id_prev_episode        number
,id_epis_type           number
,id_death_registry      number
,id_dep_clin_serv       number
,id_software            number
,deceased_motive    varchar2(4000)
,deceased_place         varchar2(4000)
,DT_LAST_UPDATE_TSTZ   timestamp with local time zone
)
;
/

CREATE OR REPLACE TYPE T_TBL_DATA_DEATH_BASE AS TABLE OF T_REC_DATA_DEATH_BASE;

