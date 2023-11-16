CREATE TYPE t_rec_med_cpoe_task_status AS OBJECT
(
    id_task_type    NUMBER(24),
    id_task_request NUMBER(24),
    flg_status      VARCHAR2(1),
    drug_type       VARCHAR2(255)
);
/