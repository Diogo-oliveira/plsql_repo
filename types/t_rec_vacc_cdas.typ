-- CHANGED BY: Joel Lopes
-- CHANGE DATE: 31/03/2014
-- CREATE REASON:  - CDA - Vaccine
CREATE OR REPLACE TYPE t_rec_vacc_cdas force AS OBJECT
(
    id_vacc                NUMBER(24),
    id_vacc_manufacturer   VARCHAR2(200),
    vacc_manufacturer_name VARCHAR2(4000),
    dt_pat_vacc_adm        VARCHAR2(14),
    dt_format              VARCHAR2(100 CHAR),
    flg_status             VARCHAR2(1 CHAR),
    desc_status            VARCHAR2(4000),
    code_vacc_us           VARCHAR2(1000 CHAR),
    code_desc_vacc_us      VARCHAR2(4000),
    code_cvx               VARCHAR2(200),
    n_dose                 NUMBER(19,3),
    unit_measure           VARCHAR2(255),
    unit_measure_trans     VARCHAR2(4000),
    lot_number             VARCHAR2(100)
);
/
