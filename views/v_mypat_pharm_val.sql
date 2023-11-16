CREATE OR REPLACE VIEW V_MYPAT_PHARM_VAL AS
SELECT z.id_episode,
       z.id_visit,
       z.id_patient,
       z.flg_status_e,
       z.flg_ehr,
       z.id_epis_type,
       z.code_epis_type,
       z.id_software,
       z.id_first_nurse_resp,
       z.id_professional,
       z.id_institution,
       z.dt_begin_tstz,
       z.dt_cancel_tstz,
       z.id_bed,
       z.desc_bed,
       z.code_bed,
       z.bed_rank,
       z.desc_room_abbreviation,
       z.code_abbreviation,
       z.code_room,
       z.room_rank,
       z.desc_room,
       z.abbreviation,
       z.code_department,
       z.id_department,
       z.dep_rank,
       z.id_dep_clin_serv,
       z.gender,
       z.dt_birth,
       z.dt_deceased,
       z.age,
       z.dt_first_obs_tstz,
       z.allocated,
       z.status_rank,
       z.flg_status_ei,
       z.drug_presc,
       z.drug_req,
       z.pha_date,
       z.disp_task,
       z.disp_ivroom
  FROM (SELECT epis.id_episode,
               epis.id_visit,
               epis.id_patient,
               epis.flg_status flg_status_e,
               epis.flg_ehr,
               epis.id_epis_type,
               'EPIS_TYPE.CODE_EPIS_TYPE.' || epis.id_epis_type code_epis_type,
               ei.id_software,
               ei.id_first_nurse_resp,
               ei.id_professional,
               epis.id_institution,
               epis.dt_begin_tstz dt_begin_tstz,
               epis.dt_cancel_tstz,
               bd.id_bed,
               bd.desc_bed,
               bd.code_bed,
               bd.rank bed_rank,
               ro.desc_room_abbreviation,
               ro.code_abbreviation,
               ro.code_room,
               ro.rank room_rank,
               ro.desc_room,
               dpt.abbreviation,
               dpt.code_department,
               dcs.id_department,
               dpt.rank dep_rank,
               dcs.id_dep_clin_serv,
               pat.gender,
               pat.dt_birth,
               pat.dt_deceased,
               pat.age,
               ei.dt_first_obs_tstz,
               nvl2(bd.id_bed, 1, 0) allocated,
               0 status_rank,
               ei.flg_status flg_status_ei,
               gt.drug_presc,
               gt.drug_req,
               MAX(vpr.dt_status) pha_date,
               gt.disp_task,
               gt.disp_ivroom
          FROM (SELECT /*+ index(e EPIS_SEARCH10_IDX) */
                 *
                  FROM episode e
                 WHERE e.flg_status = 'A'
                   AND e.id_institution = sys_context('ALERT_CONTEXT', 'i_id_institution')
                UNION
                SELECT /*+ index(e EPIS_SEARCH11_IDX) */
                 *
                  FROM episode e
                 WHERE e.flg_status = 'I'
                   AND e.id_institution = sys_context('ALERT_CONTEXT', 'i_id_institution')
                   AND nvl(dt_end_tstz, dt_begin_tstz) >=
                       CAST(trunc(current_timestamp -
                                  numtodsinterval(sys_context('ALERT_CONTEXT', 'inactive_episode_nr_days'), 'DAY')) AS
                            TIMESTAMP WITH LOCAL TIME ZONE)) epis
          JOIN patient pat
            ON (epis.id_patient = pat.id_patient)
          JOIN epis_info ei
            ON epis.id_episode = ei.id_episode
          JOIN dep_clin_serv dcs
            ON ei.id_dep_clin_serv = dcs.id_dep_clin_serv
          LEFT JOIN bed bd
            ON ei.id_bed = bd.id_bed
          LEFT JOIN room ro
            ON bd.id_room = ro.id_room
          LEFT JOIN department dpt
            ON ro.id_department = dpt.id_department
          LEFT JOIN grid_task gt
            ON (gt.id_episode = epis.id_episode)
        -----
          JOIN presc p
            ON (p.id_last_episode = epis.id_episode AND p.id_workflow IN (13, 20, 15) AND
               p.id_status NOT IN (62, 76, 77, 70) AND
               p.id_workflow IN
               (SELECT /*+ OPT_ESTIMATE(TABLE ts ROWS=2)*/
                  column_value s
                   FROM TABLE(pk_utils.str_split_n(sys_context('ALERT_CONTEXT', 'id_presc_wf'))) ts))
          JOIN presc_dir pd
            ON (p.id_presc_directions = pd.id_presc_directions AND
               pd.id_home_care_presc = sys_context('ALERT_CONTEXT', 'id_home_care_presc'))
          JOIN v_pha_review vpr
            ON p.id_presc = vpr.id_task
           AND vpr.id_task_type = 45
           AND vpr.id_workflow = 57
           AND vpr.id_institution = sys_context('ALERT_CONTEXT', 'i_id_institution')
           AND vpr.id_status IN
               (SELECT /*+ OPT_ESTIMATE(TABLE t ROWS=2) */
                 column_value AS id_status
                  FROM TABLE(pk_utils.str_split_n(sys_context('ALERT_CONTEXT', 'id_review_status'))) t)
        -----
         WHERE pat.flg_status = 'A'
           AND nvl(dpt.id_department, dcs.id_department) = dcs.id_department
           AND vpr.dt_status >= decode(sys_context('ALERT_CONTEXT', 'i_validation_time_interval'),
                                       1,
                                       CAST((SELECT pk_date_utils.trunc_insttimezone(i_inst      => sys_context('ALERT_CONTEXT',
                                                                                                                'i_id_institution'),
                                                                                     i_soft      => sys_context('ALERT_CONTEXT',
                                                                                                                'i_id_software'),
                                                                                     i_timestamp => current_timestamp)
                                               FROM dual) AS TIMESTAMP WITH LOCAL TIME ZONE),
                                       vpr.dt_status)
              ----
           AND vpr.dt_status <= decode(sys_context('ALERT_CONTEXT', 'i_validation_time_interval'),
                                       1,
                                       CAST((SELECT pk_date_utils.trunc_insttimezone(i_inst      => sys_context('ALERT_CONTEXT',
                                                                                                                'i_id_institution'),
                                                                                     i_soft      => sys_context('ALERT_CONTEXT',
                                                                                                                'i_id_software'),
                                                                                     i_timestamp => current_timestamp + 1)
                                               FROM dual) AS TIMESTAMP WITH LOCAL TIME ZONE),
                                       vpr.dt_status)
              ----------
           AND ei.id_dep_clin_serv IN (SELECT id_dep_clin_serv
                                         FROM prof_dep_clin_serv p
                                        WHERE p.id_institution = sys_context('ALERT_CONTEXT', 'i_id_institution')
                                          AND p.id_professional = sys_context('ALERT_CONTEXT', 'i_id_prof')
                                          AND p.flg_status = 'S')
         GROUP BY epis.id_episode,
                  epis.id_visit,
                  epis.id_patient,
                  epis.flg_status,
                  epis.flg_ehr,
                  epis.id_epis_type,
                  ei.id_software,
                  ei.id_first_nurse_resp,
                  ei.id_professional,
                  epis.id_institution,
                  epis.dt_begin_tstz,
                  epis.dt_cancel_tstz,
                  bd.id_bed,
                  bd.desc_bed,
                  bd.code_bed,
                  bd.rank,
                  ro.desc_room_abbreviation,
                  ro.code_abbreviation,
                  ro.code_room,
                  ro.rank,
                  ro.desc_room,
                  dpt.abbreviation,
                  dpt.code_department,
                  dcs.id_department,
                  dpt.rank,
                  dcs.id_dep_clin_serv,
                  pat.gender,
                  pat.dt_birth,
                  pat.dt_deceased,
                  pat.age,
                  ei.dt_first_obs_tstz,
                  ei.flg_status,
                  gt.drug_presc,
                  gt.drug_req,
                  gt.disp_task,
                  gt.disp_ivroom) z;
