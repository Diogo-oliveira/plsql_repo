CREATE TYPE t_rec_presc_interval AS OBJECT
(
    id_presc_dir_interval  NUMBER(24),
    dt_begin_tstz          TIMESTAMP(6) WITH LOCAL TIME ZONE,
    dt_end_tstz            TIMESTAMP(6) WITH LOCAL TIME ZONE,
    duration               NUMBER(24),
    id_unit_measure_dur    NUMBER(24),
    descr_unit_measure_dur VARCHAR2(1000),
    qty_freq_inst          t_table_presc_freq_inst
);
/