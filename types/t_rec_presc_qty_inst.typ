CREATE TYPE t_rec_presc_qty_inst AS OBJECT
(
    flg_type                   VARCHAR2(1),
    qty_min                    NUMBER(24, 4),
    qty_max                    NUMBER(24, 4),
    id_unit_measure_qty_min    NUMBER(24),
    descr_unit_measure_qty_min VARCHAR2(1000),
    id_unit_measure_qty_max    NUMBER(24),
    descr_unit_measure_qty_max VARCHAR2(1000),
    id_sliding_scale           NUMBER(24),
    desc_sliding_scale         VARCHAR2(1000)
);
/