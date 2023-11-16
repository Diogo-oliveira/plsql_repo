CREATE OR REPLACE TYPE t_rec_bmng_total_beds force AS OBJECT
(
    id_institution      NUMBER(24),
    institution_name    VARCHAR2(200 CHAR),
    total_beds          NUMBER(24),
    total_active_beds   NUMBER(24),
    total_inactive_beds NUMBER(24),
    total_occupied_beds NUMBER(24)
)
;
/
