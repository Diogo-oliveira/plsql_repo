CREATE OR REPLACE TYPE t_recurr_exec_times force AS OBJECT
(
    id_order_recurr_plan    NUMBER(24),
    exec_time_parent_option NUMBER(24),
    exec_time_option        NUMBER(24),
    exec_time               VARCHAR2(1000 CHAR),
    exec_time_desc          VARCHAR2(1000 CHAR)
);
/
