-- CHANGED BY: Carlos Loureiro
-- CHANGED DATE: 04-JUL-2010
-- CHANGED REASON: [ALERT-109296] TDE Core versioning (DDL)
CREATE OR REPLACE TYPE t_rec_dependencies_order AS OBJECT
(
    id_order_set_task NUMBER,
    dependency_order  NUMBER
);
-- CHANGE END: Carlos Loureiro
