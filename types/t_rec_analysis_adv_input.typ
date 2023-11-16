CREATE OR REPLACE TYPE t_rec_analysis_adv_input AS OBJECT
(
    id_advanced_input           NUMBER(6),
    id_advanced_input_field     NUMBER(24),
    id_advanced_input_field_det NUMBER(24),
    descr                       VARCHAR2(1000)
);
/
