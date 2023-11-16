CREATE OR REPLACE TYPE t_rec_hidrics AS OBJECT
(
    id              NUMBER(24),
    name            VARCHAR2(4000),
    values_desc     table_varchar,
    id_hidrics_type NUMBER(24)
);
