CREATE OR REPLACE TYPE t_rec_mcdt force AS OBJECT
(
    id               NUMBER(24),
    id_2             NUMBER(24),
    name_aux         VARCHAR2(4000),
    name             VARCHAR2(4000),
    values_desc      table_varchar,
    flg_missing_data VARCHAR2(1)
);
/
