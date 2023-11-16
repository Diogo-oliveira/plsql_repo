CREATE OR REPLACE VIEW V_NURSE_DISCHARGE AS
SELECT id_nurse_discharge,
       id_professional,
       id_episode,
       notes,
       id_prof_cancel,
       notes_cancel,
       dt_cancel_tstz,
       flg_temp,
       dt_nurse_discharge_tstz
  FROM nurse_discharge;
