
CREATE OR REPLACE VIEW V_DUMMY_EPISODE AS
SELECT e.id_patient, e.id_visit, ei.id_episode, ei.id_schedule
  FROM episode e,
       epis_info ei,
       (SELECT pk_reset.get_dummy_patient id_patient, pk_reset.get_dummy_instit id_institution
          FROM dual) tt
 WHERE (e.id_institution = tt.id_institution OR e.id_patient = tt.id_patient OR
       ei.id_instit_requested = tt.id_institution)
   AND e.id_episode = ei.id_episode;

