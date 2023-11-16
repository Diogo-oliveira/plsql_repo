CREATE OR REPLACE TYPE t_rec_dep_clin_serv_info AS OBJECT
(
    data        VARCHAR2(1000 CHAR),
    label       VARCHAR2(1000 CHAR),
    flg_select  VARCHAR2(1 CHAR),
    order_field NUMBER(12)
)
;
/
