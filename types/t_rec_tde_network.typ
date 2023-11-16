
-- CHANGED BY: Carlos Loureiro
-- CHANGED DATE: 13-JUL-2010
-- CHANGED REASON: [ALERT-110938] TDE for Order Sets versioning (DDL+PKG)
CREATE OR REPLACE TYPE t_rec_tde_network AS OBJECT
(
    id_relationship_type    NUMBER(24),
    id_task_dependency_from NUMBER(24),
    id_task_dependency_to   NUMBER(24),
    id_task_type_from       NUMBER(24),
    id_task_type_to         NUMBER(24)
);
-- CHANGE END: Carlos Loureiro

