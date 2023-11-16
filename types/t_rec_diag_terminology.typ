CREATE OR REPLACE TYPE t_rec_diag_terminology AS OBJECT
(
    id_diagnosis       NUMBER(24),
    desc_diagnosis     VARCHAR2(1000 CHAR),
    id_alert_diagnosis NUMBER(24),
    code_icd           VARCHAR2(200 CHAR),
    flg_other          VARCHAR2(200 CHAR),
    rank               NUMBER(24)
)
;