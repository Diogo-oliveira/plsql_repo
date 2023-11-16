CREATE OR REPLACE VIEW V_BMNG_ALLOCATION_BED AS
SELECT bab.id_bmng_allocation_bed,
       bab.id_episode,
       bab.id_patient,
       bab.id_bed,
       bab.allocation_notes,
       bab.id_room,
       bab.id_prof_creation,
       bab.dt_creation,
       bab.id_prof_release,
       bab.dt_release,
       bab.flg_outdated,
       bab.id_epis_nch
  FROM bmng_allocation_bed bab;
