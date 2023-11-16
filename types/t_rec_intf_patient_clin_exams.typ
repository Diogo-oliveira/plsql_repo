-- CHANGED BY: Ana Monteiro
-- CHANGED DATE: 2010-JAN-12
-- CHANGED REASON: 
-- Utilizado para receber dados de interface (PK_P1_URL)
CREATE OR REPLACE TYPE t_rec_intf_patient_clin_exams AS OBJECT
(
    name       VARCHAR2(500 CHAR),
    code       VARCHAR2(50 CHAR),
    RESULT     VARCHAR2(4000 CHAR),
    data_year  NUMBER(4),
    data_month NUMBER(2),
    data_day   NUMBER(2)
)
/
-- CHANGE END: Ana Monteiro
