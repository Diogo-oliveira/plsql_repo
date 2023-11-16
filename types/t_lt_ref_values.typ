CREATE OR REPLACE TYPE t_lt_ref_values force AS OBJECT
(
    id_analysis           NUMBER(12),
    id_sample_type        NUMBER(12),
    id_analysis_parameter NUMBER(24),
    id_unit_measure       NUMBER(24),
    desc_unit_measure     VARCHAR2(200 CHAR),
    ref_val_min           NUMBER(24, 3),
    ref_val_max           NUMBER(24, 3),
    interval_min          NUMBER(24, 5),
    interval_max          NUMBER(24, 5)
);
/
-- CHANGE END: Pedro Maia 
