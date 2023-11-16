-- CHANGED BY: Lillian Lu
-- CHANGE DATE: 2018-05-25
-- CHANGE REASON: 
CREATE OR REPLACE TYPE t_rec_bmng_bed_transf AS OBJECT
(
    id_room     NUMBER(24),
    id_bed      NUMBER(24),
    dt_creation TIMESTAMP WITH LOCAL TIME ZONE,
    dt_release  TIMESTAMP WITH LOCAL TIME ZONE,
    rank        NUMBER(3, 0),
    flg_icu     VARCHAR2(1)
)
/
-- CHANGE END: Lillian Lu