CREATE OR REPLACE TYPE t_procedure_review force AS OBJECT
(
    id_interv_presc_det NUMBER(24),
    registry            VARCHAR2(1000 CHAR),
    desc_procedure      VARCHAR2(4000 CHAR),
    review_notes        VARCHAR(2000 CHAR),
    dt_ord              VARCHAR2(200 CHAR)
)
;
/