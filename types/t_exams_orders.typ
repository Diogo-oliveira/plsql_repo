CREATE OR REPLACE TYPE t_exams_orders force AS OBJECT
(
    id_exam_req         NUMBER(24),
    id_exam_req_det     NUMBER(24),
    id_exam             NUMBER(24),
    flg_status          VARCHAR2(2 CHAR),
    flg_time            VARCHAR2(2 CHAR),
    desc_exam           VARCHAR2(1000 CHAR),
    msg_notes           VARCHAR2(200 CHAR),
    notes               VARCHAR2(1000 CHAR),
    notes_patient       VARCHAR2(1000 CHAR),
    notes_technician    VARCHAR2(1000 CHAR),
    icon_name           VARCHAR2(200 CHAR),
    desc_diagnosis      VARCHAR2(1000 CHAR),
    priority            VARCHAR2(200 CHAR),
    hr_begin            VARCHAR2(200 CHAR),
    dt_begin            VARCHAR2(200 CHAR),
    to_be_perform       VARCHAR2(200 CHAR),
    status_string       VARCHAR2(200 CHAR),
    id_codification     NUMBER(24),
    id_task_dependency  NUMBER(24),
    flg_timeout         VARCHAR2(2 CHAR),
    avail_button_ok     VARCHAR2(2 CHAR),
    avail_button_cancel VARCHAR2(2 CHAR),
    avail_button_action VARCHAR2(2 CHAR),
    avail_button_read   VARCHAR2(2 CHAR),
    avail_button_det    VARCHAR2(2 CHAR),
    flg_current_episode VARCHAR2(2 CHAR),
    rank                NUMBER(12),
    dt_ord              VARCHAR2(200 CHAR)
);
/
-- CHANGED BY: teresa.coutinho
-- CHANGE DATE: 25/11/2013 10:22
-- CHANGE REASON: [ALERT-268453 ] 
CREATE OR REPLACE TYPE t_exams_orders force AS OBJECT
(
    id_exam_req         NUMBER(24),
    id_exam_req_det     NUMBER(24),
    id_exam             NUMBER(24),
    flg_status          VARCHAR2(2 CHAR),
    flg_time            VARCHAR2(2 CHAR),
    desc_exam           VARCHAR2(1000 CHAR),
    msg_notes           VARCHAR2(200 CHAR),
    notes               VARCHAR2(1000 CHAR),
    notes_patient       VARCHAR2(1000 CHAR),
    notes_technician    VARCHAR2(1000 CHAR),
    icon_name           VARCHAR2(200 CHAR),
    desc_diagnosis      VARCHAR2(1000 CHAR),
    priority            VARCHAR2(200 CHAR),
    hr_begin            VARCHAR2(200 CHAR),
    dt_begin            VARCHAR2(200 CHAR),
    to_be_perform       VARCHAR2(200 CHAR),
    status_string       VARCHAR2(200 CHAR),
    id_codification     NUMBER(24),
    id_task_dependency  NUMBER(24),
    flg_timeout         VARCHAR2(2 CHAR),
    avail_button_ok     VARCHAR2(2 CHAR),
    avail_button_cancel VARCHAR2(2 CHAR),
    avail_button_edit   VARCHAR2(2 CHAR),
    avail_button_action VARCHAR2(2 CHAR),
    avail_button_read   VARCHAR2(2 CHAR),
    flg_current_episode VARCHAR2(2 CHAR),
    rank                NUMBER(12),
    dt_ord              VARCHAR2(200 CHAR),
id_exam_cat         NUMBER(24)
);
/