CREATE OR REPLACE TYPE tr_fluid_balance_med_rep AS OBJECT
(
    id_epis_hidrics NUMBER,
    id_episode      NUMBER,
    id_visit        NUMBER,
    id_drug         NUMBER,
    id_fluid_det    NUMBER,
    id_fluid        NUMBER,
    desc_fluid      VARCHAR2(1000 char),
    desc_unit       VARCHAR2(1000 char),
    unit            NUMBER,
    route           VARCHAR2(1000 char),
    value_fluid     NUMBER,
    id_professional NUMBER,
    dt_execution    TIMESTAMP
        WITH LOCAL TIME ZONE,
    id_route        varchar2(200 char),
    route_id        varchar2(200 char)
)
;
/
