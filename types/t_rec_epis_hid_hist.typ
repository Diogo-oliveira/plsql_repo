CREATE OR REPLACE TYPE t_rec_epis_hid_hist AS OBJECT
(
    id_history       NUMBER(24),
    dt_history       TIMESTAMP(6)
        WITH LOCAL TIME ZONE,
    tbl_left_columns table_varchar,
    tbl_left_values  table_varchar,
    tbl_right_labels table_varchar,
    tbl_right_values table_varchar,
    tbl_info_labels  table_varchar,
    tbl_info_values  table_varchar
)
;
