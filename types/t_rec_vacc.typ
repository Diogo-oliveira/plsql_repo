CREATE OR REPLACE TYPE t_rec_vacc AS OBJECT
(
    id          NUMBER(24),
    name        VARCHAR2(4000),
    values_desc table_varchar
)
;
