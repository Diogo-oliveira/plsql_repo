CREATE OR REPLACE TYPE t_rec_comp_col_diff AS OBJECT
(
    id_epis_comp_hist NUMBER(24),
    tbl_left_columns   table_varchar,
    tbl_left_values   table_varchar,
    tbl_right_labels  table_varchar,
    tbl_right_values  table_varchar,
    tbl_info_labels  table_varchar,
    tbl_info_values  table_varchar
)
/
