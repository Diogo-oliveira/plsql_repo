CREATE OR REPLACE TYPE t_procedure_co_sign force AS OBJECT
(
    id_interv_presc_det NUMBER(24),
    registry            VARCHAR2(1000 CHAR),
    flg_status          VARCHAR2(1 CHAR),
    co_sign_notes       CLOB,
    rn                  NUMBER(12)
)
;
/