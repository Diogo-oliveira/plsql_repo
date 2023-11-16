-- CHANGED BY: hugo.madureira
-- CHANGED DATE: 2014-10-02
-- CHANGE REASON: CODING-2477

CREATE OR REPLACE VIEW ALERT.V_SURGICAL_DETAILS AS
SELECT --sri.flg_coding,
       NULL flg_coding,
       sri.code_intervention code_intervention,
       --sri.icd,
			 srid.standard_code,
       srei.id_prof_req,
       srei.id_episode_context,
       srei.flg_type,
       sstd_out.dt_surgery_time_det_tstz dt_end_surgery,
       sstd_out.id_professional,
       srei.name_interv uncoded_description,
       ed.id_epis_diagnosis,
       ed.id_alert_diagnosis,
       ed.id_diagnosis,
       nvl(ed.id_alert_diagnosis, ed.id_diagnosis) id_diagnosis_diag,
       nvl(ad.code_alert_diagnosis, d.code_diagnosis) code_diagnosis_diag,
       nvl(ad.flg_type, d.flg_type) flg_type_diag,
       d.code_icd,
       ad.flg_icd9,
       d.flg_other,
       e.id_episode,
       e.id_visit,
       e.id_patient,
       e.id_prev_episode,
       srei.id_sr_epis_interv,
       sri.id_intervention,
       e.id_institution,
       (SELECT /*+opt_estimate(table,srptd,scale_rows=1)*/
         srptd.id_prof_team_leader
          FROM sr_prof_team_det srptd
         WHERE srptd.id_sr_epis_interv = srei.id_sr_epis_interv
           AND srptd.flg_status = 'A'
           AND srptd.id_prof_cancel IS NULL
           AND rownum = 1) id_prof_team_leader,
       pk_hand_off.get_epis_dcs(i_lang           => NULL,
                                i_prof           => NULL,
                                i_episode        => e.id_episode,
                                i_dt_target      => NULL,
                                i_dt_target_tstz => sstd_out.dt_surgery_time_det_tstz) id_dep_clin_serv,
       srei.id_sr_cancel_reason,
       srei.id_prof_cancel,
       srei.dt_cancel_tstz,
       srei.notes_cancel,
       srid.id_codification,
       pk_prof_utils.get_reg_prof_id_dcs(srei.id_prof_req,
                                         srei.dt_req_tstz,
                                         e.id_episode) req_prof_dcs,
       srei.name_interv free_text_desc,
       srei.laterality laterality,
       srei.notes,
       (SELECT /*+opt_estimate(table srptd scale_rows=1)*/
         srptd.id_prof_team
          FROM sr_prof_team_det srptd
         WHERE srptd.id_sr_epis_interv = srei.id_sr_epis_interv
           AND srptd.flg_status = 'A'
           AND srptd.id_prof_cancel IS NULL
           AND rownum = 1) id_prof_team
  FROM sr_epis_interv srei
 INNER JOIN episode e
    ON srei.id_episode = e.id_episode
  LEFT OUTER JOIN intervention sri
    ON srei.id_sr_intervention = sri.id_intervention
  LEFT OUTER JOIN sr_surgery_time_det sstd_out
    ON srei.id_episode_context = sstd_out.id_episode
   AND sstd_out.flg_status = 'A'
   AND sstd_out.id_sr_surgery_time IN
       (SELECT /*+opt_estimate(table,sst_out,scale_rows=1)*/
         sst_out.id_sr_surgery_time
          FROM sr_surgery_time sst_out
         WHERE sst_out.flg_type = 'FC'
           AND sst_out.flg_available = 'Y')
  LEFT OUTER JOIN epis_diagnosis ed
    ON ed.id_epis_diagnosis = srei.id_epis_diagnosis
  LEFT OUTER JOIN alert_diagnosis ad
    ON ed.id_alert_diagnosis = ad.id_alert_diagnosis
  LEFT OUTER JOIN diagnosis d
    ON nvl(ad.id_diagnosis, ed.id_diagnosis) = d.id_diagnosis
  LEFT OUTER JOIN interv_codification srid
    ON srid.id_intervention = sri.id_intervention

-- END
