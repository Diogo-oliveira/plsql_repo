CREATE OR REPLACE VIEW V_ALL_PAT_DEFAULT_SERVICE AS
SELECT epis.id_episode, 
       epis.id_visit,
       epis.id_patient,
       epis.flg_status flg_status_e,
       epis.flg_ehr,
       epis.id_epis_type,
       ei.id_first_nurse_resp,
       ei.id_professional,
       epis.id_institution,
       epis.dt_begin_tstz,
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
       ro.id_room,
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
       dch.flg_status flg_disch_status,
       nvl(dch.dt_med_tstz, dch.dt_admin_tstz) dt_med_tstz,
       epis.id_clinical_service,
       pat.identity_code,
       epis.dt_begin_tstz dt_admission,
     epis.id_prev_episode,
     dch.dt_pend_tstz
  FROM episode epis
  JOIN patient pat
    ON epis.id_patient = pat.id_patient
  JOIN epis_info ei
    ON epis.id_episode = ei.id_episode
  JOIN dep_clin_serv dcs
    ON ei.id_dep_clin_serv = dcs.id_dep_clin_serv
  LEFT JOIN discharge dch
    ON (dch.id_episode = epis.id_episode AND dch.flg_status IN ('A', 'P')  and dch.dt_admin_tstz is null )
  LEFT JOIN bed bd
    ON ei.id_bed = bd.id_bed
  LEFT JOIN room ro
    ON bd.id_room = ro.id_room
  LEFT JOIN department dpt
    ON ro.id_department = dpt.id_department
  JOIN (SELECT DISTINCT bab.id_episode
          FROM v_all_pat_bab_aux1 bab
         WHERE rownum > 0
           AND ((bab.dt_release IS NULL) OR
               (bab.dt_release BETWEEN
               pk_date_utils.trunc_insttimezone(i_inst      => sys_context('ALERT_CONTEXT', 'i_id_institution'),
                                                  i_soft      => sys_context('ALERT_CONTEXT', 'i_id_software'),
                                                  i_timestamp => current_timestamp +
                                                                 numtodsinterval(- (sys_context('ALERT_CONTEXT',
                                                                                               'i_days_back')) * 24,
                                                                                 'HOUR')) AND current_timestamp))) xsql
    ON epis.id_episode = xsql.id_episode;
