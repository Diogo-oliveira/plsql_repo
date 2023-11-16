-- CHANGED BY: Ana Matos
-- CHANGE DATE: 06/11/2015 14:37
-- CHANGE REASON: [ALERT-316241] 
DECLARE

    CURSOR c_grid_task IS
        SELECT gt.id_episode, e.id_patient, e.id_institution, ei.id_software, ia.id_language
          FROM grid_task gt, episode e, epis_info ei, institution_language ia
         WHERE gt.analysis_d IS NOT NULL
           AND gt.id_episode = e.id_episode
           AND e.id_episode = ei.id_episode
           AND e.id_institution = ia.id_institution
        UNION
        SELECT gt.id_episode, e.id_patient, e.id_institution, ei.id_software, ia.id_language
          FROM grid_task gt, episode e, epis_info ei, institution_language ia
         WHERE gt.analysis_n IS NOT NULL
           AND gt.id_episode = e.id_episode
           AND e.id_episode = ei.id_episode
           AND e.id_institution = ia.id_institution;

    l_grid_task grid_task%ROWTYPE;

    l_short_analysis sys_shortcut.id_sys_shortcut%TYPE := 8;
    l_short_harvest  sys_shortcut.id_sys_shortcut%TYPE := 9;
    l_short_result   sys_shortcut.id_sys_shortcut%TYPE := 801001;

    l_show_all_icon_tracking VARCHAR2(200 CHAR);
    l_ref                    VARCHAR2(200 CHAR);

BEGIN

    FOR r_cur IN c_grid_task
    LOOP
    
        BEGIN
            SELECT t.value
              INTO l_show_all_icon_tracking
              FROM (SELECT sc.value, row_number() over(ORDER BY sc.id_institution DESC, sc.id_software DESC) rn
                      FROM sys_config sc
                     WHERE sc.id_sys_config = 'SHOW_SAMPLE_TRACKING_IN_GRIDS'
                       AND sc.id_institution IN (0, r_cur.id_institution)
                       AND sc.id_software IN (0, r_cur.id_software)) t
             WHERE rn = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_show_all_icon_tracking := 'N';
        END;
    
        BEGIN
            SELECT t.value
              INTO l_ref
              FROM (SELECT sc.value, row_number() over(ORDER BY sc.id_institution DESC, sc.id_software DESC) rn
                      FROM sys_config sc
                     WHERE sc.id_sys_config = 'REFERRAL_AVAILABILITY'
                       AND sc.id_institution IN (0, r_cur.id_institution)
                       AND sc.id_software IN (0, r_cur.id_software)) t
             WHERE rn = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_ref := 'N';
        END;
    
        l_grid_task := NULL;
    
        FOR rec IN (SELECT REPLACE(decode(substr(t.status_string_med, 2, 1),
                                          'D',
                                          REPLACE(t.status_string_med,
                                                  substr(t.status_string_med,
                                                         instr(t.status_string_med, '|', 1, 2) + 1,
                                                         instr(substr(t.status_string_med,
                                                                      instr(t.status_string_med, '|', 1, 2) + 1),
                                                               '|') - 1),
                                                  pk_date_utils.to_char_insttimezone(profissional(NULL,
                                                                                                  r_cur.id_institution,
                                                                                                  r_cur.id_software),
                                                                                     pk_date_utils.get_string_tstz(r_cur.id_language,
                                                                                                                   profissional(NULL,
                                                                                                                                r_cur.id_institution,
                                                                                                                                r_cur.id_software),
                                                                                                                   decode(substr(t.status_string_med,
                                                                                                                                 2,
                                                                                                                                 1),
                                                                                                                          'D',
                                                                                                                          substr(t.status_string_med,
                                                                                                                                 instr(t.status_string_med,
                                                                                                                                       '|',
                                                                                                                                       1,
                                                                                                                                       2) + 1,
                                                                                                                                 instr(substr(t.status_string_med,
                                                                                                                                              instr(t.status_string_med,
                                                                                                                                                    '|',
                                                                                                                                                    1,
                                                                                                                                                    2) + 1),
                                                                                                                                       '|') - 1),
                                                                                                                          t.status_string_med),
                                                                                                                   NULL),
                                                                                     'YYYYMMDDHH24MISS TZR')),
                                          t.status_string_med),
                                   substr(t.status_string_med,
                                          instr(t.status_string_med, '|', 1, 9) + 1,
                                          instr(substr(t.status_string_med, instr(t.status_string_med, '|', 1, 9) + 1),
                                                '|') - 1),
                                   pk_date_utils.to_char_insttimezone(profissional(NULL,
                                                                                   r_cur.id_institution,
                                                                                   r_cur.id_software),
                                                                      pk_date_utils.get_string_tstz(r_cur.id_language,
                                                                                                    profissional(NULL,
                                                                                                                 r_cur.id_institution,
                                                                                                                 r_cur.id_software),
                                                                                                    substr(t.status_string_med,
                                                                                                           instr(t.status_string_med,
                                                                                                                 '|',
                                                                                                                 1,
                                                                                                                 9) + 1,
                                                                                                           instr(substr(t.status_string_med,
                                                                                                                        instr(t.status_string_med,
                                                                                                                              '|',
                                                                                                                              1,
                                                                                                                              9) + 1),
                                                                                                                 '|') - 1),
                                                                                                    NULL),
                                                                      'YYYYMMDDHH24MISS TZR')) status_string_med,
                           flg_status_med,
                           REPLACE(decode(substr(t.status_string_enf, 2, 1),
                                          'D',
                                          REPLACE(t.status_string_enf,
                                                  substr(t.status_string_enf,
                                                         instr(t.status_string_enf, '|', 1, 2) + 1,
                                                         instr(substr(t.status_string_enf,
                                                                      instr(t.status_string_enf, '|', 1, 2) + 1),
                                                               '|') - 1),
                                                  pk_date_utils.to_char_insttimezone(profissional(NULL,
                                                                                                  r_cur.id_institution,
                                                                                                  r_cur.id_software),
                                                                                     pk_date_utils.get_string_tstz(r_cur.id_language,
                                                                                                                   profissional(NULL,
                                                                                                                                r_cur.id_institution,
                                                                                                                                r_cur.id_software),
                                                                                                                   decode(substr(t.status_string_enf,
                                                                                                                                 2,
                                                                                                                                 1),
                                                                                                                          'D',
                                                                                                                          substr(t.status_string_enf,
                                                                                                                                 instr(t.status_string_enf,
                                                                                                                                       '|',
                                                                                                                                       1,
                                                                                                                                       2) + 1,
                                                                                                                                 instr(substr(t.status_string_enf,
                                                                                                                                              instr(t.status_string_enf,
                                                                                                                                                    '|',
                                                                                                                                                    1,
                                                                                                                                                    2) + 1),
                                                                                                                                       '|') - 1),
                                                                                                                          t.status_string_enf),
                                                                                                                   NULL),
                                                                                     'YYYYMMDDHH24MISS TZR')),
                                          t.status_string_enf),
                                   substr(t.status_string_enf,
                                          instr(t.status_string_enf, '|', 1, 9) + 1,
                                          instr(substr(t.status_string_enf, instr(t.status_string_enf, '|', 1, 9) + 1),
                                                '|') - 1),
                                   pk_date_utils.to_char_insttimezone(profissional(NULL,
                                                                                   r_cur.id_institution,
                                                                                   r_cur.id_software),
                                                                      pk_date_utils.get_string_tstz(r_cur.id_language,
                                                                                                    profissional(NULL,
                                                                                                                 r_cur.id_institution,
                                                                                                                 r_cur.id_software),
                                                                                                    substr(t.status_string_enf,
                                                                                                           instr(t.status_string_enf,
                                                                                                                 '|',
                                                                                                                 1,
                                                                                                                 9) + 1,
                                                                                                           instr(substr(t.status_string_enf,
                                                                                                                        instr(t.status_string_enf,
                                                                                                                              '|',
                                                                                                                              1,
                                                                                                                              9) + 1),
                                                                                                                 '|') - 1),
                                                                                                    NULL),
                                                                      'YYYYMMDDHH24MISS TZR')) status_string_enf,
                           flg_status_enf
                      FROM (SELECT MAX(status_string_med) status_string_med,
                                   MAX(status_string_enf) status_string_enf,
                                   MAX(flg_status_med) flg_status_med,
                                   MAX(flg_status_enf) flg_status_enf
                              FROM (SELECT decode(rank_med,
                                                  1,
                                                  pk_utils.get_status_string(r_cur.id_language,
                                                                             profissional(NULL,
                                                                                          r_cur.id_institution,
                                                                                          r_cur.id_software),
                                                                             pk_ea_logic_analysis.get_analysis_status_str_det(r_cur.id_language,
                                                                                                                              profissional(NULL,
                                                                                                                                           r_cur.id_institution,
                                                                                                                                           r_cur.id_software),
                                                                                                                              id_episode,
                                                                                                                              flg_time,
                                                                                                                              flg_status,
                                                                                                                              flg_referral,
                                                                                                                              flg_status_harvest,
                                                                                                                              flg_status_result,
                                                                                                                              NULL,
                                                                                                                              dt_req_tstz,
                                                                                                                              dt_pend_req_tstz,
                                                                                                                              dt_begin_tstz),
                                                                             pk_ea_logic_analysis.get_analysis_status_msg_det(r_cur.id_language,
                                                                                                                              profissional(NULL,
                                                                                                                                           r_cur.id_institution,
                                                                                                                                           r_cur.id_software),
                                                                                                                              id_episode,
                                                                                                                              flg_time,
                                                                                                                              flg_status,
                                                                                                                              flg_referral,
                                                                                                                              flg_status_harvest,
                                                                                                                              flg_status_result,
                                                                                                                              NULL,
                                                                                                                              dt_req_tstz,
                                                                                                                              dt_pend_req_tstz,
                                                                                                                              dt_begin_tstz),
                                                                             pk_ea_logic_analysis.get_analysis_status_icon_det(r_cur.id_language,
                                                                                                                               profissional(NULL,
                                                                                                                                            r_cur.id_institution,
                                                                                                                                            r_cur.id_software),
                                                                                                                               id_episode,
                                                                                                                               flg_time,
                                                                                                                               flg_status,
                                                                                                                               flg_referral,
                                                                                                                               flg_status_harvest,
                                                                                                                               flg_status_result,
                                                                                                                               NULL,
                                                                                                                               dt_req_tstz,
                                                                                                                               dt_pend_req_tstz,
                                                                                                                               dt_begin_tstz),
                                                                             pk_ea_logic_analysis.get_analysis_status_flg_det(r_cur.id_language,
                                                                                                                              profissional(NULL,
                                                                                                                                           r_cur.id_institution,
                                                                                                                                           r_cur.id_software),
                                                                                                                              id_episode,
                                                                                                                              flg_time,
                                                                                                                              flg_status,
                                                                                                                              flg_referral,
                                                                                                                              flg_status_harvest,
                                                                                                                              flg_status_result,
                                                                                                                              NULL,
                                                                                                                              dt_req_tstz,
                                                                                                                              dt_pend_req_tstz,
                                                                                                                              dt_begin_tstz)),
                                                  NULL) status_string_med,
                                           decode(rank_med, 1, flg_status, NULL) flg_status_med,
                                           decode(rank_enf,
                                                  1,
                                                  pk_utils.get_status_string(r_cur.id_language,
                                                                             profissional(NULL,
                                                                                          r_cur.id_institution,
                                                                                          r_cur.id_software),
                                                                             pk_ea_logic_analysis.get_analysis_status_str_det(r_cur.id_language,
                                                                                                                              profissional(NULL,
                                                                                                                                           r_cur.id_institution,
                                                                                                                                           r_cur.id_software),
                                                                                                                              id_episode,
                                                                                                                              flg_time,
                                                                                                                              flg_status,
                                                                                                                              flg_referral,
                                                                                                                              flg_status_harvest,
                                                                                                                              flg_status_result,
                                                                                                                              NULL,
                                                                                                                              dt_req_tstz,
                                                                                                                              dt_pend_req_tstz,
                                                                                                                              dt_begin_tstz),
                                                                             pk_ea_logic_analysis.get_analysis_status_msg_det(r_cur.id_language,
                                                                                                                              profissional(NULL,
                                                                                                                                           r_cur.id_institution,
                                                                                                                                           r_cur.id_software),
                                                                                                                              id_episode,
                                                                                                                              flg_time,
                                                                                                                              flg_status,
                                                                                                                              flg_referral,
                                                                                                                              flg_status_harvest,
                                                                                                                              flg_status_result,
                                                                                                                              NULL,
                                                                                                                              dt_req_tstz,
                                                                                                                              dt_pend_req_tstz,
                                                                                                                              dt_begin_tstz),
                                                                             pk_ea_logic_analysis.get_analysis_status_icon_det(r_cur.id_language,
                                                                                                                               profissional(NULL,
                                                                                                                                            r_cur.id_institution,
                                                                                                                                            r_cur.id_software),
                                                                                                                               id_episode,
                                                                                                                               flg_time,
                                                                                                                               flg_status,
                                                                                                                               flg_referral,
                                                                                                                               flg_status_harvest,
                                                                                                                               flg_status_result,
                                                                                                                               NULL,
                                                                                                                               dt_req_tstz,
                                                                                                                               dt_pend_req_tstz,
                                                                                                                               dt_begin_tstz),
                                                                             pk_ea_logic_analysis.get_analysis_status_flg_det(r_cur.id_language,
                                                                                                                              profissional(NULL,
                                                                                                                                           r_cur.id_institution,
                                                                                                                                           r_cur.id_software),
                                                                                                                              id_episode,
                                                                                                                              flg_time,
                                                                                                                              flg_status,
                                                                                                                              flg_referral,
                                                                                                                              flg_status_harvest,
                                                                                                                              flg_status_result,
                                                                                                                              NULL,
                                                                                                                              dt_req_tstz,
                                                                                                                              dt_pend_req_tstz,
                                                                                                                              dt_begin_tstz)),
                                                  NULL) status_string_enf,
                                           decode(rank_enf, 1, flg_status, NULL) flg_status_enf
                                      FROM (SELECT t.id_analysis_req_det,
                                                   t.id_episode,
                                                   t.flg_time,
                                                   t.flg_status,
                                                   t.flg_referral,
                                                   t.flg_status_harvest,
                                                   t.flg_status_result,
                                                   t.dt_req_tstz,
                                                   t.dt_pend_req_tstz,
                                                   t.dt_begin_tstz,
                                                   row_number() over(ORDER BY t.rank_med) rank_med,
                                                   row_number() over(ORDER BY t.rank_enf) rank_enf
                                              FROM (SELECT t.*,
                                                           decode(t.flg_status,
                                                                  'F',
                                                                  row_number() over(ORDER BY t.rank DESC),
                                                                  'R',
                                                                  row_number() over(ORDER BY coalesce(t.dt_pend_req_tstz,
                                                                                t.dt_begin_tstz,
                                                                                t.dt_req_tstz)) + 10000,
                                                                  row_number() over(ORDER BY coalesce(t.dt_pend_req_tstz,
                                                                                t.dt_begin_tstz,
                                                                                t.dt_req_tstz) DESC) + 20000) rank_med,
                                                           decode(t.flg_status,
                                                                  'R',
                                                                  row_number() over(ORDER BY coalesce(t.dt_pend_req_tstz,
                                                                                t.dt_begin_tstz,
                                                                                t.dt_req_tstz)),
                                                                  row_number() over(ORDER BY coalesce(t.dt_pend_req_tstz,
                                                                                t.dt_begin_tstz,
                                                                                t.dt_req_tstz) DESC) + 20000) rank_enf
                                                      FROM (SELECT t.*,
                                                                   decode(flg_urgent,
                                                                          'Y',
                                                                          pk_sysdomain.get_rank(r_cur.id_language,
                                                                                                'ANALYSIS_REQ_DET.FLG_STATUS.URGENT',
                                                                                                t.flg_status) + 1000,
                                                                          pk_sysdomain.get_rank(r_cur.id_language,
                                                                                                'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                                                t.flg_status)) rank
                                                              FROM (SELECT ard.id_analysis_req_det,
                                                                           ar.id_episode,
                                                                           ard.flg_time_harvest flg_time,
                                                                           ard.flg_status,
                                                                           ard.flg_status flg_status_harvest,
                                                                           ard.flg_referral,
                                                                           CASE
                                                                                WHEN ard.flg_status = 'F' THEN
                                                                                 CASE
                                                                                     WHEN ard.flg_urgency != 'N'
                                                                                          OR ares.flg_urgent = 'Y' THEN
                                                                                      rs.value || 'U'
                                                                                     ELSE
                                                                                      rs.value
                                                                                 END
                                                                                ELSE
                                                                                 rs.value
                                                                            END flg_status_result,
                                                                           ar.dt_req_tstz,
                                                                           ard.dt_pend_req_tstz,
                                                                           ard.dt_target_tstz dt_begin_tstz,
                                                                           CASE
                                                                                WHEN ard.flg_urgency != 'N'
                                                                                     OR ares.flg_urgent = 'Y' THEN
                                                                                 'Y'
                                                                                ELSE
                                                                                 'N'
                                                                            END flg_urgent
                                                                      FROM analysis_req ar,
                                                                           analysis_req_det ard,
                                                                           (SELECT ar.id_analysis_req_det,
                                                                                   ar.id_result_status,
                                                                                   CASE
                                                                                        WHEN pk_utils.is_number(dbms_lob.substr(ar.desc_analysis_result,
                                                                                                                                3800)) = 'Y'
                                                                                             AND
                                                                                             ar.analysis_result_value_2 IS NULL THEN
                                                                                         CASE
                                                                                             WHEN ar.analysis_result_value_1 <
                                                                                                  ar.ref_val_min THEN
                                                                                              'Y'
                                                                                             WHEN ar.analysis_result_value_1 >
                                                                                                  ar.ref_val_max THEN
                                                                                              'Y'
                                                                                             ELSE
                                                                                              'N'
                                                                                         END
                                                                                        ELSE
                                                                                         CASE
                                                                                             WHEN ar.id_abnormality IS NOT NULL
                                                                                                  AND ar.id_abnormality != 7 THEN
                                                                                              'Y'
                                                                                             ELSE
                                                                                              'N'
                                                                                         END
                                                                                    END flg_urgent
                                                                              FROM (SELECT ar.id_analysis_req_det,
                                                                                           ar.id_result_status,
                                                                                           arp.desc_analysis_result,
                                                                                           arp.analysis_result_value_1,
                                                                                           arp.analysis_result_value_2,
                                                                                           arp.ref_val_min,
                                                                                           arp.ref_val_max,
                                                                                           arp.id_abnormality,
                                                                                           row_number() over(PARTITION BY id_harvest, id_analysis_req_par ORDER BY dt_ins_result_tstz DESC) rn
                                                                                      FROM analysis_result     ar,
                                                                                           analysis_result_par arp
                                                                                     WHERE ar.id_episode_orig = r_cur.id_episode
                                                                                       AND ar.id_analysis_result =
                                                                                           arp.id_analysis_result) ar
                                                                             WHERE ar.rn = 1) ares,
                                                                           result_status rs,
                                                                           episode e
                                                                     WHERE (ar.id_episode = r_cur.id_episode OR
                                                                           ar.id_prev_episode = r_cur.id_episode OR
                                                                           ar.id_episode_origin = r_cur.id_episode)
                                                                       AND ar.id_analysis_req = ard.id_analysis_req
                                                                       AND ((l_show_all_icon_tracking = 'Y' AND
                                                                           ard.flg_status IN
                                                                           ('S', 'X', 'R', 'D', 'PA', 'A', 'CC', 'E', 'F')) OR
                                                                           ard.flg_status IN ('X', 'R', 'D', 'PA', 'F'))
                                                                       AND (ard.flg_referral NOT IN ('R', 'S', 'I') OR
                                                                           ard.flg_referral IS NULL)
                                                                       AND ard.id_analysis_req_det =
                                                                           ares.id_analysis_req_det(+)
                                                                       AND ares.id_result_status = rs.id_result_status(+)
                                                                       AND (ar.id_episode = e.id_episode OR
                                                                           ar.id_prev_episode = e.id_episode OR
                                                                           ar.id_episode_origin = e.id_episode)
                                                                    UNION ALL
                                                                    SELECT ard.id_analysis_req_det,
                                                                           ar.id_episode,
                                                                           ard.flg_time_harvest flg_time,
                                                                           ard.flg_status,
                                                                           ard.flg_status flg_status_harvest,
                                                                           ard.flg_referral,
                                                                           CASE
                                                                               WHEN ard.flg_urgency != 'N'
                                                                                    OR ares.flg_urgent = 'Y' THEN
                                                                                rs.value || 'U'
                                                                               ELSE
                                                                                rs.value
                                                                           END flg_status_result,
                                                                           ar.dt_req_tstz,
                                                                           ard.dt_pend_req_tstz,
                                                                           ard.dt_target_tstz dt_begin_tstz,
                                                                           CASE
                                                                               WHEN ard.flg_urgency != 'N'
                                                                                    OR ares.flg_urgent = 'Y' THEN
                                                                                'Y'
                                                                               ELSE
                                                                                'N'
                                                                           END flg_urgent
                                                                      FROM analysis_req ar,
                                                                           analysis_req_det ard,
                                                                           (SELECT ar.id_analysis_req_det,
                                                                                   ar.id_result_status,
                                                                                   CASE
                                                                                        WHEN pk_utils.is_number(dbms_lob.substr(ar.desc_analysis_result,
                                                                                                                                3800)) = 'Y'
                                                                                             AND
                                                                                             ar.analysis_result_value_2 IS NULL THEN
                                                                                         CASE
                                                                                             WHEN ar.analysis_result_value_1 <
                                                                                                  ar.ref_val_min THEN
                                                                                              'Y'
                                                                                             WHEN ar.analysis_result_value_1 >
                                                                                                  ar.ref_val_max THEN
                                                                                              'Y'
                                                                                             ELSE
                                                                                              'N'
                                                                                         END
                                                                                        ELSE
                                                                                         CASE
                                                                                             WHEN ar.id_abnormality IS NOT NULL
                                                                                                  AND ar.id_abnormality != 7 THEN
                                                                                              'Y'
                                                                                             ELSE
                                                                                              'N'
                                                                                         END
                                                                                    END flg_urgent
                                                                              FROM (SELECT ar.id_analysis_req_det,
                                                                                           ar.id_result_status,
                                                                                           arp.desc_analysis_result,
                                                                                           arp.analysis_result_value_1,
                                                                                           arp.analysis_result_value_2,
                                                                                           arp.ref_val_min,
                                                                                           arp.ref_val_max,
                                                                                           arp.id_abnormality,
                                                                                           row_number() over(PARTITION BY id_harvest, id_analysis_req_par ORDER BY dt_ins_result_tstz DESC) rn
                                                                                      FROM analysis_result     ar,
                                                                                           analysis_result_par arp
                                                                                     WHERE ar.id_patient = r_cur.id_patient
                                                                                       AND ar.id_episode_orig !=
                                                                                           r_cur.id_episode
                                                                                       AND ar.id_analysis_result =
                                                                                           arp.id_analysis_result) ar
                                                                             WHERE ar.rn = 1) ares,
                                                                           result_status rs,
                                                                           episode e
                                                                     WHERE ar.id_patient = r_cur.id_patient
                                                                       AND ar.id_episode != r_cur.id_episode
                                                                       AND ar.id_analysis_req = ard.id_analysis_req
                                                                       AND (ard.flg_referral NOT IN ('R', 'S', 'I') OR
                                                                           ard.flg_referral IS NULL)
                                                                       AND ard.flg_status = 'F'
                                                                       AND ard.id_analysis_req_det = ares.id_analysis_req_det
                                                                       AND ares.id_result_status = rs.id_result_status(+)
                                                                       AND (ar.id_episode = e.id_episode OR
                                                                           ar.id_prev_episode = e.id_episode OR
                                                                           ar.id_episode_origin = e.id_episode)
                                                                       AND e.id_epis_type NOT IN (2, 4, 5)) t
                                                             WHERE l_ref = 'Y'
                                                                OR (l_ref = 'N' AND t.flg_status != 'X')) t) t)
                                     WHERE rank_med = 1
                                        OR rank_enf = 1) t) t)
        LOOP
        
            IF rec.status_string_med IS NOT NULL
            THEN
                IF rec.flg_status_med = 'R'
                THEN
                    l_grid_task.analysis_d := l_short_harvest || rec.status_string_med;
                ELSIF rec.flg_status_med = 'F'
                THEN
                    l_grid_task.analysis_d := l_short_result || rec.status_string_med;
                ELSE
                    l_grid_task.analysis_d := l_short_analysis || rec.status_string_med;
                END IF;
            END IF;
        
            IF rec.status_string_enf IS NOT NULL
            THEN
                IF rec.flg_status_enf = 'R'
                THEN
                    l_grid_task.analysis_n := l_short_harvest || rec.status_string_enf;
                ELSIF rec.flg_status_enf = 'F'
                THEN
                    l_grid_task.analysis_n := l_short_result || rec.status_string_enf;
                ELSE
                    l_grid_task.analysis_n := l_short_analysis || rec.status_string_enf;
                END IF;
            END IF;
        
            l_grid_task.id_episode := r_cur.id_episode;
        
            IF l_grid_task.id_episode IS NOT NULL
            THEN
                UPDATE grid_task gt
                   SET gt.analysis_d = l_grid_task.analysis_d, gt.analysis_n = l_grid_task.analysis_n
                 WHERE gt.id_episode = l_grid_task.id_episode;
            END IF;
        END LOOP;
    END LOOP;
END;
/
-- CHANGE END: Ana Matos