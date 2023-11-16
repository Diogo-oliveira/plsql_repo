-- CHANGED BY: Pedro Teixeira
-- CHANGE DATE: 15/07/2011
-- CHANGE REASON: ALERT-185868
CREATE OR REPLACE VIEW V_PRESCRIPTION AS
SELECT p.id_prescription,
       p.flg_status,
       p.flg_type,
       p.id_patient,
       p.id_episode,
       p.dt_prof_print_tstz
  FROM prescription p;
-- CHANGE END: Pedro Teixeira