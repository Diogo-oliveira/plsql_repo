CREATE OR REPLACE TYPE T_DOC_ACTIVITY AS OBJECT (
       PROFESSIONAL_NAME       VARCHAR2(200 CHAR),
       ID_PROFESSIONAL         NUMBER(24),
			 DT_OPERATION            VARCHAR2(200 CHAR),
			 DT_OPERATION_TSTZ       TIMESTAMP WITH TIME ZONE,
			 OPERATION_DESC          VARCHAR(200 CHAR),
			 OPERATION_NAME          VARCHAR(200 CHAR),
			 ID_INSTITUTION          NUMBER(24),
			 INSTITUTION_NAME        VARCHAR(200 CHAR),
			 ID_DOC                  NUMBER(24),
			 CODE_SOURCE             VARCHAR2(200 CHAR),
			 SOURCE_DESC             VARCHAR2(200 CHAR),
			 CODE_TARGET             VARCHAR2(200 CHAR),
			 TARGET_DESC             VARCHAR2(200 CHAR),
			 PARAMETERS_LIST         T_PARAM_LIST			 
)
NOT FINAL;
/
