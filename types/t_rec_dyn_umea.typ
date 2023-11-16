CREATE OR REPLACE TYPE t_rec_dyn_umea AS OBJECT
            (
            id_ds_component           NUMBER(24),
            id_unit_measure           NUMBER(24),
            id_unit_measure_subtype   NUMBER(24),
            code_unit_measure         VARCHAR2(0200 char),
            desc_unit_measure         VARCHAR2(4000),
            order_rank                NUMBER(24)
            );
/
