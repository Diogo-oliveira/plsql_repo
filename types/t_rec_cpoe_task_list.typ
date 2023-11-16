CREATE OR REPLACE TYPE t_rec_cpoe_task_list force AS OBJECT
(
    id_task_type        NUMBER(24), -- used only by CPOE
    id_target_task_type NUMBER(24),
    task_description    VARCHAR2(1000 CHAR),
    id_profissional     NUMBER(24),
    icon_warning        VARCHAR2(1000 CHAR),
    status_str          VARCHAR2(1000 CHAR),
    id_request          NUMBER(24),
    start_date_tstz     TIMESTAMP(6) WITH LOCAL TIME ZONE,
    end_date_tstz       TIMESTAMP(6) WITH LOCAL TIME ZONE,
    creation_date_tstz  TIMESTAMP(6) WITH LOCAL TIME ZONE,
    flg_status          VARCHAR2(10 CHAR),
    flg_cancel          VARCHAR2(1 CHAR),
    flg_conflict        VARCHAR2(1 CHAR),
    flg_current         VARCHAR2(1 CHAR), -- used only by CPOE
    flg_next            VARCHAR2(1 CHAR), -- used only by CPOE   
    rank                NUMBER(6), -- used only by CPOE
    id_task             VARCHAR2(200),
    task_title          VARCHAR2(1000 CHAR),
    task_instructions   VARCHAR2(10000 CHAR),
    task_notes          VARCHAR2(1000 CHAR),
    generic_text1       VARCHAR2(1000 CHAR),
    generic_text2       VARCHAR2(1000 CHAR),
    generic_text3       VARCHAR2(1000 CHAR),
    task_status         VARCHAR2(1000 CHAR),
    instr_bg_color      VARCHAR2(200 CHAR),
    instr_bg_alpha      VARCHAR2(200 CHAR),
    task_icon           VARCHAR2(1000 CHAR),
    flg_need_ack        VARCHAR2(1 CHAR),
    edit_icon           VARCHAR2(1000 CHAR),
    action_desc         VARCHAR2(1000 CHAR),
    previous_status     VARCHAR2(10 CHAR),
    visible_tabs        table_varchar,
    id_task_type_source NUMBER(24), -- task type ID used internally by the functionality and defined in TASK_TYPE table
    id_task_dependency  NUMBER(24),
    flg_rep_cancel      VARCHAR2(1 CHAR),
    flg_prn_conditional VARCHAR2(1 CHAR),
    CONSTRUCTOR FUNCTION t_rec_cpoe_task_list RETURN SELF AS RESULT,
    MEMBER FUNCTION to_string RETURN VARCHAR2
)
;
/