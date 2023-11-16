CREATE OR REPLACE TYPE t_epis_hid AS OBJECT
(
    id_epis_hidrics        NUMBER(24),
    id_episode             NUMBER(24),
    id_professional        NUMBER(24),
    flg_type               VARCHAR2(1 CHAR),
    id_hidrics             NUMBER(24),
    id_epis_hid_ftxt_fluid NUMBER(24),
    id_way                 NUMBER(24),
    id_epis_hid_ftxt_way   NUMBER(24),
    id_epis_hidrics_line   NUMBER(24),
    rank                   NUMBER(24),
    acronym                VARCHAR2(10 CHAR),
    dt_initial_tstz        TIMESTAMP(6) WITH LOCAL TIME ZONE
);
/