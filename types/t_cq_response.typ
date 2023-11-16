CREATE OR REPLACE TYPE t_cq_response force AS OBJECT
(
    response VARCHAR2(1000),
    rn       NUMBER(24)
)
;
/
