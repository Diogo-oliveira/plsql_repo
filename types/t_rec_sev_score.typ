drop type t_tab_sev_score;
drop type T_REC_SEV_SCORE;

CREATE OR REPLACE TYPE T_REC_SEV_SCORE AS OBJECT (
	ID_MTOS_SCORE				NUMBER
	,FLG_SCORE_TYPE             VARCHAR2(0010 CHAR)
	,SCORE_DESC                 VARCHAR2(1000 CHAR)
	,ID_MTOS_PARAM              NUMBER
	,PARAM_DESC                 VARCHAR2(1000 CHAR)
	,FLG_FILL_TYPE              VARCHAR2(0100 CHAR)
	,SCORE_RANK                 NUMBER
	,PARAM_RANK                 NUMBER
	,INTERNAL_NAME              VARCHAR2(0200 CHAR)
	,REGISTERED_VALUE           TABLE_NUMBER
	,REGISTERED_VALUE_DESC      TABLE_VARCHAR
	,DESC_UNIT_MEASURE          VARCHAR2(0200 CHAR)
	,RELATION                   NUMBER
	,RELATED_SCORES             NUMBER
	,ID_VITAL_SIGN              NUMBER
	,ID_UNIT_MEASURE            NUMBER
	,VAL_MIN                    NUMBER
	,VAL_MAX                    NUMBER
	,FORMAT_NUM                 VARCHAR2(0200 CHAR)
	,ID_VITAL_SIGN_READ         NUMBER
	,FLG_MANDATORY              VARCHAR2(0010 CHAR)
	, id_mtos_score_group       number
	, group_desc				varchar2(4000)
);


create or replace type t_tab_sev_score as TABLE OF T_REC_SEV_SCORE;