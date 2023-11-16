-- CHANGED BY: Ana Monteiro
-- CHANGED DATE: 2010-JAN-12
-- CHANGED REASON: 
-- Utilizado para receber dados de interface (PK_P1_URL)
CREATE OR REPLACE TYPE t_rec_intf_clin_history AS OBJECT
(
    name           VARCHAR2(500 CHAR),
    code           VARCHAR2(50 CHAR),
    notes          VARCHAR2(4000 CHAR),
    data_ini_year  NUMBER(4),
    data_ini_month NUMBER(2),
    data_ini_day   NUMBER(2),
    data_end_year  NUMBER(4),
    data_end_month NUMBER(2),
    data_end_day   NUMBER(2)
)
/
-- CHANGE END: Ana Monteiro