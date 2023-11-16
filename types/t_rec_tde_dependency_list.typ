-- CHANGED BY: Carlos Loureiro
-- CHANGED DATE: 04-JUL-2010
-- CHANGED REASON: [ALERT-109296] TDE Core versioning (DDL)
CREATE OR REPLACE TYPE t_rec_tde_dependency_list AS OBJECT
(
    task_dependency_id_anchor NUMBER(24),
    task_dependency_id        NUMBER(24),
    task_type_id              NUMBER(24),
    task_request_id           NUMBER(24),
    flg_allow_action          VARCHAR2(1 CHAR)
);
-- CHANGE END: Carlos Loureiro
