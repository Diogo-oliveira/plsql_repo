-- CHANGED BY: Daniel Conceicao
-- CHANGED DATE: 2011-Nov-08
-- CHANGED REASON: ALERT-164878  

create table a_164878_alert_diagnosis
(
	ID_ALERT_DIAGNOSIS	NUMBER(12),
ID_DIAGNOSIS	NUMBER(12),
CODE_ALERT_DIAGNOSIS	VARCHAR2(200),
FLG_TYPE	VARCHAR2(2),
FLG_ICD9	VARCHAR2(2),
FLG_AVAILABLE	VARCHAR2(2),
GENDER	VARCHAR2(1),
AGE_MIN	NUMBER(3),
AGE_MAX	NUMBER(3),
ID_CONTENT	VARCHAR2(200)
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
    location ('a_164878_alert_diagnosis.csv')
  )
REJECT LIMIT 0;


-- CHANGE END: Daniel Conceicao