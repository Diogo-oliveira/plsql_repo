CREATE OR REPLACE VIEW V_MY_PAT_INP_GRID_ANCILIARY AS
SELECT e.id_episode,
       e.id_visit,
       e.id_patient,
       pat.gender,
       pat.dt_birth,
       pat.dt_deceased,
       pat.age,
       --
       e.dt_begin_tstz        dt_admission,
       e.flg_status           flg_status_e,
       ei.flg_status          flg_status_ei,
       ei.id_first_nurse_resp,
       ei.id_professional,
       e.id_institution,
       e.dt_begin_tstz,
       ei.dt_first_obs_tstz,
       e.id_epis_type,
       e.flg_ehr,
       --
       bd.id_bed,
       bd.desc_bed,
       bd.code_bed,
       bd.rank bed_rank,
       nvl2(bd.id_bed, 1, 0) allocated,
       ro.desc_room_abbreviation,
       ro.code_abbreviation,
       ro.code_room,
       ro.rank room_rank,
       ro.desc_room,
       dpt.abbreviation,
       dpt.code_department,
       dpt.rank dep_rank,
       --
       gt.drug_transp,
       gt.movement,
       gt.hemo_req,
       gt.supplies    desc_supplies
  FROM episode e
  JOIN epis_info ei
    ON e.id_episode = ei.id_episode
  JOIN patient pat
    ON e.id_patient = pat.id_patient
  LEFT OUTER JOIN professional p
    ON ei.id_professional = p.id_professional
  LEFT OUTER JOIN professional pn
    ON ei.id_first_nurse_resp = pn.id_professional
  JOIN grid_task gt
    ON e.id_episode = gt.id_episode
   AND (gt.movement IS NOT NULL OR gt.harvest IS NOT NULL OR gt.drug_transp IS NOT NULL OR gt.supplies IS NOT NULL OR
       gt.hemo_req IS NOT NULL)
  LEFT OUTER JOIN bed bd
    ON ei.id_bed = bd.id_bed
  LEFT OUTER JOIN room ro
    ON bd.id_room = ro.id_room
  LEFT OUTER JOIN department dpt
    ON ro.id_department = dpt.id_department
 WHERE e.flg_status = 'A'
   AND e.id_epis_type = 5
   AND ei.id_dep_clin_serv IN (SELECT dcs1.id_dep_clin_serv
                                 FROM prof_dep_clin_serv pdc1
                                INNER JOIN dep_clin_serv dcs1
                                   ON pdc1.id_dep_clin_serv = dcs1.id_dep_clin_serv
                                INNER JOIN department dpt
                                   ON dcs1.id_department = dpt.id_department
                                  AND pdc1.id_institution = sys_context('ALERT_CONTEXT', 'i_id_institution')
                                  AND instr(dpt.flg_type, 'I') > 0
                                WHERE pdc1.flg_status = 'S');
