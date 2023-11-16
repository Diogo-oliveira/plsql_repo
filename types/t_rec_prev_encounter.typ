CREATE OR REPLACE TYPE t_rec_prev_encounter force AS OBJECT
(
    id_episode    NUMBER(24),
    id_schedule   NUMBER(24),
    id_epis_type  NUMBER(12),
    enc_data      table_clob,
    id_prof_med   NUMBER(24),
    dt_change_med TIMESTAMP WITH LOCAL TIME ZONE,
    id_prof_nur   NUMBER(24),
    dt_change_nur TIMESTAMP WITH LOCAL TIME ZONE
)
;
/
