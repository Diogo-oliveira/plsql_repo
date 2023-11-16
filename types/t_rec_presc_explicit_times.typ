CREATE TYPE t_rec_presc_explicit_times AS OBJECT
(
    monthday_interval NUMBER(24),
    weekday_interval  NUMBER(24),
    hour_interval     NUMBER(24),
    min_interval      NUMBER(24),
    sec_interval      NUMBER(24)
)
;
/