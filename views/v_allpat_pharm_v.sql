CREATE OR REPLACE VIEW V_ALLPAT_PHARM_V AS
SELECT id_episode,
       id_visit,
       id_patient,
       flg_status_e,
       flg_ehr,
       id_epis_type,
       code_epis_type,
       id_software,
       id_first_nurse_resp,
       id_professional,
       id_institution,
       dt_begin_tstz,
       dt_cancel_tstz,
       id_bed,
       desc_bed,
       code_bed,
       bed_rank,
       desc_room_abbreviation,
       code_abbreviation,
       code_room,
       room_rank,
       desc_room,
       abbreviation,
       code_department,
       id_department,
       dep_rank,
       id_dep_clin_serv,
       gender,
       dt_birth,
       dt_deceased,
       age,
       dt_first_obs_tstz,
       allocated,
       status_rank,
       flg_status_ei,
       drug_presc,
       drug_req,
       pha_date,
       disp_ivroom,
       disp_task,
       id_dispense_method
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
               decode(epis.id_department_requested,
                      -1,
                      nvl(dpt.id_department, dcs.id_department),
                      decode(bd.id_bed, NULL, epis.id_department_requested, nvl(dpt.id_department, dcs.id_department))) id_department,
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
               NULL pha_date,
               gt.disp_ivroom,
               gt.disp_task,
               pm.id_dispense_method
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
            ON epis.id_patient = pat.id_patient
          JOIN epis_info ei
            ON epis.id_episode = ei.id_episode
          LEFT JOIN dep_clin_serv dcs
            ON ei.id_dep_clin_serv = dcs.id_dep_clin_serv
          LEFT JOIN bed bd
            ON ei.id_bed = bd.id_bed
          LEFT JOIN room ro
            ON bd.id_room = ro.id_room
          LEFT JOIN department dpt
            ON ro.id_department = dpt.id_department
          LEFT JOIN grid_task gt
            ON gt.id_episode = epis.id_episode
        -----
          JOIN presc p
            ON (p.id_last_episode = epis.id_episode AND p.id_workflow IN (13, 20, 15) AND
               p.id_status NOT IN (62, 76, 77, 70) AND
               p.id_workflow IN
               (SELECT /*+ OPT_ESTIMATE(TABLE ts ROWS=3)*/
                  column_value s
                   FROM TABLE(pk_utils.str_split_n(sys_context('ALERT_CONTEXT', 'id_presc_wf'))) ts))
          JOIN presc_med pm
            ON pm.id_presc = p.id_presc
          JOIN presc_dir pd
            ON (p.id_presc_directions = pd.id_presc_directions AND
               pd.id_home_care_presc IN
               (SELECT /*+ OPT_ESTIMATE(TABLE th ROWS=3)*/
                  column_value h
                   FROM TABLE(pk_utils.str_split_n(sys_context('ALERT_CONTEXT', 'id_home_care_presc'))) th))
          JOIN v_pha_review vpr
            ON p.id_presc = vpr.id_task
           AND vpr.id_task_type = 45
           AND vpr.id_workflow = 57
           AND vpr.id_institution = sys_context('ALERT_CONTEXT', 'i_id_institution')
           AND vpr.id_status IN
               (SELECT /*+ OPT_ESTIMATE(TABLE t ROWS=4) */
                 column_value AS id_status
                  FROM TABLE(pk_utils.str_split_n(sys_context('ALERT_CONTEXT', 'id_review_status'))) t)
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
                                       vpr.dt_status))
 GROUP BY id_episode,
          id_visit,
          id_patient,
          flg_status_e,
          flg_ehr,
          id_epis_type,
          code_epis_type,
          id_software,
          id_first_nurse_resp,
          id_professional,
          id_institution,
          dt_begin_tstz,
          dt_cancel_tstz,
          id_bed,
          desc_bed,
          code_bed,
          bed_rank,
          desc_room_abbreviation,
          code_abbreviation,
          code_room,
          room_rank,
          desc_room,
          abbreviation,
          code_department,
          id_department,
          dep_rank,
          id_dep_clin_serv,
          gender,
          dt_birth,
          dt_deceased,
          age,
          dt_first_obs_tstz,
          allocated,
          status_rank,
          flg_status_ei,
          drug_presc,
          drug_req,
          pha_date,
          disp_ivroom,
          disp_task,
          id_dispense_method;
