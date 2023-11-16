-- CHANGED BY: Alexandre Santos
-- CHANGE DATE: 2009-07-31
-- CHANGE REASON: ALERT-38599
CREATE OR REPLACE TYPE t_rec_bmng_interval AS OBJECT
(
    id_department  NUMBER(24),
    id_bmng_action NUMBER(24),
    nch            NUMBER(24),
    dt_begin       TIMESTAMP WITH LOCAL TIME ZONE,
    dt_end         TIMESTAMP WITH LOCAL TIME ZONE
)
/
-- CHANGE END: Alexandre Santos