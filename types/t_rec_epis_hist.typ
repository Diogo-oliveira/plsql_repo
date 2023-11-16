--LMAIA 08-Fev-2011
CREATE OR REPLACE TYPE t_rec_epis_hist AS OBJECT
(
    id_history       NUMBER(24),
    dt_history       TIMESTAMP(6) WITH LOCAL TIME ZONE,
    tbl_labels table_varchar,
    tbl_values table_varchar,
    tbl_types         table_varchar,
    tbl_info_labels  table_varchar,
    tbl_info_values  table_varchar
)
;
/
