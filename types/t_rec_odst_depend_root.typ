-- CHANGED BY: Tiago Silva
-- CHANGED DATE: 06-JUL-2010
-- CHANGED REASON: [ALERT-111979] Order Sets Combined Tasks
CREATE OR REPLACE TYPE t_rec_odst_depend_root AS OBJECT
(
    id_dependency NUMBER(24),
    id_root       NUMBER(24),
    order_num     NUMBER(24)
);
/
-- CHANGE END: Tiago Silva