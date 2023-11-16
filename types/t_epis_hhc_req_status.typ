CREATE OR REPLACE TYPE t_epis_hhc_req_status AS OBJECT
(
    id_epis_hhc_req   NUMBER(24),
    id_professional NUMBER(24),
    flg_status      VARCHAR2(0010 CHAR),
    dt_status       TIMESTAMP WITH LOCAL TIME ZONE,
    id_reason       NUMBER,
    reason_notes    CLOB
);
/