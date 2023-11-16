CREATE TYPE t_rec_presc_freq_inst AS OBJECT
(
    id_presc_dir_dosefreq   NUMBER(24),
    flg_freq_type           VARCHAR2(2),
    frequency               NUMBER(24),
    id_unit_measure_freq    NUMBER(24),
    descr_unit_measure_freq VARCHAR2(1000),
    id_presc_dir_freq       NUMBER(24),
    df_id_freq              NUMBER(24),
    explicit_times          t_table_presc_explicit_times,
    flg_meal_related        VARCHAR2(1),
    meal                    t_table_presc_meal,
    qty_inst                t_table_presc_qty_inst
);
/