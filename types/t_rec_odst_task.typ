-- CHANGED BY: Tiago Silva
-- CHANGED DATE: 15-NOV-2013
-- CHANGED REASON: [ALERT-269777]
CREATE OR REPLACE TYPE t_rec_odst_task AS OBJECT
(
    id_order_set_task      NUMBER(24),
    id_task_type           NUMBER(24),
	id_task_link           VARCHAR2(200 CHAR),
    task_desc              varchar2(1000 CHAR)
);
/
-- CHANGE END: Tiago Silva