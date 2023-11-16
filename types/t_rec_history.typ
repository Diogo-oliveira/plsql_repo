CREATE OR REPLACE TYPE t_rec_history AS OBJECT
(
    id_rec         NUMBER(24),
    date_rec       TIMESTAMP(6)
        WITH LOCAL TIME ZONE,
    tbl_labels      table_varchar,
    tbl_types       table_varchar,
    tbl_status      table_varchar
);


CREATE OR REPLACE TYPE t_rec_history AS OBJECT
(
    id_rec         NUMBER(24),
    flg_status     VARCHAR2(1),
    date_rec       TIMESTAMP(6)
        WITH LOCAL TIME ZONE,
    tbl_labels      table_varchar,
    tbl_types       table_varchar,
    tbl_status      table_varchar
);