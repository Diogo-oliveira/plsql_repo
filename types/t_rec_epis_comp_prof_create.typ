CREATE OR REPLACE TYPE t_rec_epis_comp_prof_create AS OBJECT
(
    id_epis_complication NUMBER(24),
    id_professional      NUMBER(24),
    prof_name            VARCHAR2(800 CHAR),
    id_prof_clin_serv    NUMBER(24),
    desc_clin_serv       VARCHAR2(1000 CHAR),
    dt_create            TIMESTAMP(6) WITH LOCAL TIME ZONE
)
/
