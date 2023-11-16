CREATE OR REPLACE TYPE t_rec_cipe_advanced_input AS OBJECT
(
    id_advanced_input           NUMBER(24),
    id_advanced_input_field     NUMBER(24),
    id_advanced_input_field_det NUMBER(24),
    descr                       VARCHAR2(1000)
);