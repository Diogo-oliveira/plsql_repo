-- CHANGED BY: Diogo Oliveira
-- CHANGE DATE: 12/09/2018 16:00
-- CHANGE REASON: [EMR-6099] 
CREATE OR REPLACE TYPE t_blood_product_notes AS OBJECT
(
    l_id_blood_product_det  NUMBER(24),
    l_id_blod_product_execution number(24),
    l_id_epis_documentation NUMBER(24),
    l_notes                 CLOB
)
;
-- CHANGE END: Diogo Oliveira