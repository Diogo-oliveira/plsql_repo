CREATE OR REPLACE TYPE t_rec_ost_clinical_questions force AS OBJECT
(
    id_order_set_process_task NUMBER(24),
    id_task                   NUMBER(24),
    id_task_type              NUMBER(24),
    id_task_questionnaire     NUMBER(24),
    id_questionnaire          NUMBER(24),
    id_questionnaire_parent   NUMBER(24),
    id_response_parent        NUMBER(24),
    desc_questionnaire        VARCHAR2(1000 CHAR),
    flg_type                  VARCHAR2(2 CHAR),
    flg_mandatory             VARCHAR2(1 CHAR),
    flg_apply_to_all          VARCHAR2(1 CHAR),
    id_unit_measure           NUMBER(24),
    desc_response             table_varchar,
    episode_id_response       VARCHAR2(1000 CHAR),
    episode_desc_response     VARCHAR2(1000 CHAR)
);