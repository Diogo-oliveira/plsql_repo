CREATE OR REPLACE TYPE t_rehab_question_response force AS OBJECT
(
    id_intervention  NUMBER(24),
    id_questionnaire NUMBER(24),
    id_response      NUMBER(24),
    notes            VARCHAR2(1000),
    rank             NUMBER(24)
)
;
/
