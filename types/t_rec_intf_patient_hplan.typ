-- CHANGED BY: Ana Monteiro
-- CHANGED DATE: 2010-JAN-12
-- CHANGED REASON: 
-- Utilizado para receber dados de interface (PK_P1_URL)
CREATE OR REPLACE TYPE t_rec_intf_patient_hplan AS OBJECT
(
    health_plan_code   VARCHAR2(5 CHAR),
    health_plan_number VARCHAR2(20 CHAR)
)
/
-- CHANGE END: Ana Monteiro