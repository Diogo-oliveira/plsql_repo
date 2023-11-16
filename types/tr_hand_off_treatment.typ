CREATE OR REPLACE TYPE tr_hand_off_treatment AS OBJECT (
  id_drug_presc_det NUMBER(24),
  desc_treat_manag  VARCHAR2(4000),
  flg_type_mm       VARCHAR2(1 CHAR),
  med_type          VARCHAR2(1 CHAR),
  id_episode        NUMBER(24),
  id_prev_episode   NUMBER(24),
  flg_status_det    VARCHAR2(1 CHAR),
  id_protocols      NUMBER(24),
  id_drug_protocols NUMBER(24),
  last_dt           TIMESTAMP(6) WITH LOCAL TIME ZONE,
  id_professional   NUMBER(24)
)
/