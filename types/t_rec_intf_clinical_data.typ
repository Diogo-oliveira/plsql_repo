-- CHANGED BY: Ana Monteiro
-- CHANGED DATE: 2010-JAN-12
-- CHANGED REASON: 
-- Utilizado para receber dados de interface (PK_P1_URL)
CREATE OR REPLACE TYPE t_rec_intf_clinical_data AS OBJECT
(
    internal_number NUMBER(8),
    institution     VARCHAR2(20 CHAR),
    speciality      NUMBER(5),
    urgent          VARCHAR2(5 CHAR),
    justification   VARCHAR2(4000 CHAR),
    symptoms        VARCHAR2(4000 CHAR),
    evolution       VARCHAR2(4000 CHAR),
    examination     VARCHAR2(4000 CHAR)
)
/
-- CHANGE END: Ana Monteiro