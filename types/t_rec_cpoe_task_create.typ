check_tasks_creation
check_drafts_activation
create_cpoe

CREATE OR REPLACE TYPE t_rec_cpoe_task_create AS OBJECT
(
    id_task_type NUMBER(24),
    id_request   VARCHAR2(200 CHAR),
    flg_status   VARCHAR2(1 CHAR)
)



-- CHANGE END: Pedro Henriques