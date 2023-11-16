
-- CHANGED BY: Carlos Loureiro
-- CHANGED DATE: 16-AUG-2010
-- CHANGED REASON: [ALERT-117300] Combined tasks for Order Sets (DDL)
CREATE OR REPLACE TYPE t_rec_odst_dependency AS OBJECT
(
    id_order_set_process_task    NUMBER(24),
    id_task_type                 NUMBER(24),
    id_request                   NUMBER(24),
    flg_create_dependency        VARCHAR2(1 CHAR),
    flg_schedule                 VARCHAR2(1 CHAR),
    flg_start_depending          VARCHAR2(1 CHAR),
    id_task_dependency           NUMBER(24)
);
-- CHANGE END: Carlos Loureiro
