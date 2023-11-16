CREATE OR REPLACE TYPE t_rec_departments_info AS OBJECT
(
    data        VARCHAR2(1000 CHAR),
    label       VARCHAR2(1000 CHAR),
    flg_type    VARCHAR2(2),
    flg_select  VARCHAR2(1),
    data_flag   VARCHAR2(50),
    order_field NUMBER(12),
    dep_type    VARCHAR2(100 CHAR)
)
;
/
