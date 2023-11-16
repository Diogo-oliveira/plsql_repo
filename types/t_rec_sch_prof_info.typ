CREATE OR REPLACE TYPE t_rec_sch_prof_info AS OBJECT
(
    data        NUMBER(24),
    label       VARCHAR2(1000 CHAR),
    flg_select  VARCHAR2(1 CHAR),
    order_field NUMBER(12)
)
;
/
