CREATE OR REPLACE TYPE t_rec_fast_track_cfg AS OBJECT
(
    id_fast_track       NUMBER(24),
    id_triage           NUMBER(24),
    id_institution      NUMBER(24),
    rank                NUMBER(24),
    flg_activation_type VARCHAR2(1 CHAR),
    id_action           NUMBER(24),
    flg_action_active   VARCHAR2(1 CHAR)
);
/
