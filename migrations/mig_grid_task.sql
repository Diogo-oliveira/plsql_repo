DECLARE
    l_grid_task   grid_task%ROWTYPE;
    l_short_presc sys_shortcut.id_sys_shortcut%TYPE;
    l_prof        profissional;
    o_error       t_error_out;
    --
    -- This Cursor returns all the episodes of current visit
    CURSOR c_episodes IS
        SELECT DISTINCT (gt.id_episode) id_episode
          FROM grid_task gt
         WHERE gt.hidrics_reg IS NOT NULL;

    FUNCTION get_oldest_hid(i_episode episode.id_episode%TYPE) RETURN epis_hidrics_balance.id_epis_hidrics%TYPE IS
        l_epis_hidrics epis_hidrics_balance.id_epis_hidrics%TYPE;
    BEGIN
        SELECT t.id_epis_hidrics
          INTO l_epis_hidrics
          FROM (SELECT ehb.id_epis_hidrics,
                       row_number() over(ORDER BY eh.dt_next_balance, ehb.dt_open_tstz, eh.dt_initial_tstz, eh.dt_creation_tstz) line_number
                  FROM epis_hidrics eh
                  JOIN epis_hidrics_balance ehb ON ehb.id_epis_hidrics = eh.id_epis_hidrics
                                               AND ehb.flg_status IN
                                                   (pk_inp_hidrics_constant.g_epis_hid_balance_r,
                                                    pk_inp_hidrics_constant.g_epis_hid_balance_e)
                 WHERE eh.flg_status IN
                       (pk_inp_hidrics_constant.g_epis_hidric_r, pk_inp_hidrics_constant.g_epis_hidric_e)
                   AND eh.id_episode IN (SELECT e.id_episode
                                           FROM episode e
                                          WHERE e.id_visit = (SELECT e2.id_visit
                                                                FROM episode e2
                                                               WHERE e2.id_episode = i_episode))) t
         WHERE t.line_number = 1;
    
        RETURN l_epis_hidrics;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_oldest_hid;

    --
    FUNCTION get_oldest_prof(i_episode episode.id_episode%TYPE) RETURN profissional IS
        l_id_prof_last_change epis_hidrics_balance.id_prof_last_change%TYPE;
        l_id_inst             episode.id_institution%TYPE;
    BEGIN
        SELECT eh2.id_prof_last_change, epi.id_institution
          INTO l_id_prof_last_change, l_id_inst
          FROM epis_hidrics eh2
          JOIN episode epi ON epi.id_episode = eh2.id_episode
         WHERE eh2.id_epis_hidrics =
               (SELECT t.id_epis_hidrics
                  FROM (SELECT ehb.id_epis_hidrics,
                               row_number() over(ORDER BY eh.dt_next_balance, ehb.dt_open_tstz, eh.dt_initial_tstz, eh.dt_creation_tstz) line_number
                          FROM epis_hidrics eh
                          JOIN epis_hidrics_balance ehb ON ehb.id_epis_hidrics = eh.id_epis_hidrics
                                                       AND ehb.flg_status IN
                                                           (pk_inp_hidrics_constant.g_epis_hid_balance_r,
                                                            pk_inp_hidrics_constant.g_epis_hid_balance_e)
                         WHERE eh.flg_status IN
                               (pk_inp_hidrics_constant.g_epis_hidric_r, pk_inp_hidrics_constant.g_epis_hidric_e)
                           AND eh.id_episode IN (SELECT e.id_episode
                                                   FROM episode e
                                                  WHERE e.id_visit = (SELECT e2.id_visit
                                                                        FROM episode e2
                                                                       WHERE e2.id_episode = i_episode))) t
                 WHERE t.line_number = 1);
    
        RETURN profissional(l_id_prof_last_change, l_id_inst, 11);
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_oldest_prof;

    PROCEDURE backup_grid_task IS
    BEGIN
        NULL;
		--EXECUTE IMMEDIATE 'DROP TABLE GRID_TASK_BCK_2603';
        --EXECUTE IMMEDIATE 'CREATE TABLE GRID_TASK_BCK_2603 AS SELECT * FROM GRID_TASK';
    END backup_grid_task;

BEGIN
    --BACKUP EPIS_HIDRICS_DET TABLE
    backup_grid_task;

    l_short_presc := 598;
    --

    --
    FOR c_epis IN c_episodes
    LOOP
        l_prof := get_oldest_prof(c_epis.id_episode);
    
        l_grid_task.hidrics_reg := pk_inp_hidrics_pbl.get_epis_hid_status_string(1,
                                                                                 l_prof,
                                                                                 get_oldest_hid(c_epis.id_episode));
    
        UPDATE grid_task
           SET hidrics_reg = l_grid_task.hidrics_reg
         WHERE id_episode = c_epis.id_episode;
    END LOOP;

    --
    --COMMIT;
    RETURN;
END;
/


DECLARE
    l_grid_task   grid_task%ROWTYPE;
    l_short_presc sys_shortcut.id_sys_shortcut%TYPE;
    l_prof        profissional;
    o_error       t_error_out;
    --
    -- This Cursor returns all the episodes of current visit
    CURSOR c_episodes IS
        SELECT DISTINCT (gt.id_episode) id_episode
          FROM grid_task gt
         WHERE gt.hidrics_reg IS NOT NULL;

    FUNCTION get_oldest_hid(i_episode episode.id_episode%TYPE) RETURN epis_hidrics_balance.id_epis_hidrics%TYPE IS
        l_epis_hidrics epis_hidrics_balance.id_epis_hidrics%TYPE;
    BEGIN
        SELECT t.id_epis_hidrics
          INTO l_epis_hidrics
          FROM (SELECT ehb.id_epis_hidrics,
                       row_number() over(ORDER BY eh.dt_next_balance, ehb.dt_open_tstz, eh.dt_initial_tstz, eh.dt_creation_tstz) line_number
                  FROM epis_hidrics eh
                  JOIN epis_hidrics_balance ehb ON ehb.id_epis_hidrics = eh.id_epis_hidrics
                                               AND ehb.flg_status IN
                                                   (pk_inp_hidrics_constant.g_epis_hid_balance_r,
                                                    pk_inp_hidrics_constant.g_epis_hid_balance_e)
                 WHERE eh.flg_status IN
                       (pk_inp_hidrics_constant.g_epis_hidric_r, pk_inp_hidrics_constant.g_epis_hidric_e)
                   AND eh.id_episode IN (SELECT e.id_episode
                                           FROM episode e
                                          WHERE e.id_visit = (SELECT e2.id_visit
                                                                FROM episode e2
                                                               WHERE e2.id_episode = i_episode))) t
         WHERE t.line_number = 1;
    
        RETURN l_epis_hidrics;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_oldest_hid;

    --
    FUNCTION get_oldest_prof(i_episode episode.id_episode%TYPE) RETURN profissional IS
        l_id_prof_last_change epis_hidrics_balance.id_prof_last_change%TYPE;
        l_id_inst             episode.id_institution%TYPE;
    BEGIN
        SELECT eh2.id_prof_last_change, epi.id_institution
          INTO l_id_prof_last_change, l_id_inst
          FROM epis_hidrics eh2
          JOIN episode epi ON epi.id_episode = eh2.id_episode
         WHERE eh2.id_epis_hidrics =
               (SELECT t.id_epis_hidrics
                  FROM (SELECT ehb.id_epis_hidrics,
                               row_number() over(ORDER BY eh.dt_next_balance, ehb.dt_open_tstz, eh.dt_initial_tstz, eh.dt_creation_tstz) line_number
                          FROM epis_hidrics eh
                          JOIN epis_hidrics_balance ehb ON ehb.id_epis_hidrics = eh.id_epis_hidrics
                                                       AND ehb.flg_status IN
                                                           (pk_inp_hidrics_constant.g_epis_hid_balance_r,
                                                            pk_inp_hidrics_constant.g_epis_hid_balance_e)
                         WHERE eh.flg_status IN
                               (pk_inp_hidrics_constant.g_epis_hidric_r, pk_inp_hidrics_constant.g_epis_hidric_e)
                           AND eh.id_episode IN (SELECT e.id_episode
                                                   FROM episode e
                                                  WHERE e.id_visit = (SELECT e2.id_visit
                                                                        FROM episode e2
                                                                       WHERE e2.id_episode = i_episode))) t
                 WHERE t.line_number = 1);
    
        RETURN profissional(l_id_prof_last_change, l_id_inst, 11);
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_oldest_prof;

    PROCEDURE backup_grid_task IS
    BEGIN
        NULL;
		--EXECUTE IMMEDIATE 'DROP TABLE GRID_TASK_BCK_2603';
        --EXECUTE IMMEDIATE 'CREATE TABLE GRID_TASK_BCK_2603 AS SELECT * FROM GRID_TASK';
    END backup_grid_task;

BEGIN
    --BACKUP EPIS_HIDRICS_DET TABLE
    backup_grid_task;

    l_short_presc := 598;
    --

    --
    FOR c_epis IN c_episodes
    LOOP
        l_prof := get_oldest_prof(c_epis.id_episode);
    
        l_grid_task.hidrics_reg := pk_inp_hidrics_pbl.get_epis_hid_status_string(1,
                                                                                 l_prof,
                                                                                 get_oldest_hid(c_epis.id_episode));
    
        UPDATE grid_task
           SET hidrics_reg = l_grid_task.hidrics_reg
         WHERE id_episode = c_epis.id_episode;
    END LOOP;

    --
    --COMMIT;
    RETURN;
END;
/


DECLARE
    l_grid_task   grid_task%ROWTYPE;
    l_short_presc sys_shortcut.id_sys_shortcut%TYPE;
    l_prof        profissional;
    o_error       t_error_out;
    --
    -- This Cursor returns all the episodes of current visit
    CURSOR c_episodes IS
        SELECT DISTINCT (gt.id_episode) id_episode
          FROM grid_task gt
         WHERE gt.hidrics_reg IS NOT NULL;

    FUNCTION get_oldest_hid(i_episode episode.id_episode%TYPE) RETURN epis_hidrics_balance.id_epis_hidrics%TYPE IS
        l_epis_hidrics epis_hidrics_balance.id_epis_hidrics%TYPE;
    BEGIN
        SELECT t.id_epis_hidrics
          INTO l_epis_hidrics
          FROM (SELECT ehb.id_epis_hidrics,
                       row_number() over(ORDER BY eh.dt_next_balance, ehb.dt_open_tstz, eh.dt_initial_tstz, eh.dt_creation_tstz) line_number
                  FROM epis_hidrics eh
                  JOIN epis_hidrics_balance ehb ON ehb.id_epis_hidrics = eh.id_epis_hidrics
                                               AND ehb.flg_status IN
                                                   (pk_inp_hidrics_constant.g_epis_hid_balance_r,
                                                    pk_inp_hidrics_constant.g_epis_hid_balance_e)
                 WHERE eh.flg_status IN
                       (pk_inp_hidrics_constant.g_epis_hidric_r, pk_inp_hidrics_constant.g_epis_hidric_e)
                   AND eh.id_episode IN (SELECT e.id_episode
                                           FROM episode e
                                          WHERE e.id_visit = (SELECT e2.id_visit
                                                                FROM episode e2
                                                               WHERE e2.id_episode = i_episode))) t
         WHERE t.line_number = 1;
    
        RETURN l_epis_hidrics;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_oldest_hid;

    --
    FUNCTION get_oldest_prof(i_episode episode.id_episode%TYPE) RETURN profissional IS
        l_id_prof_last_change epis_hidrics_balance.id_prof_last_change%TYPE;
        l_id_inst             episode.id_institution%TYPE;
    BEGIN
        SELECT eh2.id_prof_last_change, epi.id_institution
          INTO l_id_prof_last_change, l_id_inst
          FROM epis_hidrics eh2
          JOIN episode epi ON epi.id_episode = eh2.id_episode
         WHERE eh2.id_epis_hidrics =
               (SELECT t.id_epis_hidrics
                  FROM (SELECT ehb.id_epis_hidrics,
                               row_number() over(ORDER BY eh.dt_next_balance, ehb.dt_open_tstz, eh.dt_initial_tstz, eh.dt_creation_tstz) line_number
                          FROM epis_hidrics eh
                          JOIN epis_hidrics_balance ehb ON ehb.id_epis_hidrics = eh.id_epis_hidrics
                                                       AND ehb.flg_status IN
                                                           (pk_inp_hidrics_constant.g_epis_hid_balance_r,
                                                            pk_inp_hidrics_constant.g_epis_hid_balance_e)
                         WHERE eh.flg_status IN
                               (pk_inp_hidrics_constant.g_epis_hidric_r, pk_inp_hidrics_constant.g_epis_hidric_e)
                           AND eh.id_episode IN (SELECT e.id_episode
                                                   FROM episode e
                                                  WHERE e.id_visit = (SELECT e2.id_visit
                                                                        FROM episode e2
                                                                       WHERE e2.id_episode = i_episode))) t
                 WHERE t.line_number = 1);
    
        RETURN profissional(l_id_prof_last_change, l_id_inst, 11);
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_oldest_prof;

    PROCEDURE backup_grid_task IS
    BEGIN
        NULL;
		--EXECUTE IMMEDIATE 'DROP TABLE GRID_TASK_BCK_2603';
        --EXECUTE IMMEDIATE 'CREATE TABLE GRID_TASK_BCK_2603 AS SELECT * FROM GRID_TASK';
    END backup_grid_task;

BEGIN
    --BACKUP EPIS_HIDRICS_DET TABLE
    backup_grid_task;

    l_short_presc := 598;
    --

    --
    FOR c_epis IN c_episodes
    LOOP
        l_prof := get_oldest_prof(c_epis.id_episode);
    
        l_grid_task.hidrics_reg := pk_inp_hidrics_pbl.get_epis_hid_status_string(1,
                                                                                 l_prof,
                                                                                 get_oldest_hid(c_epis.id_episode));
    
        UPDATE grid_task
           SET hidrics_reg = l_grid_task.hidrics_reg
         WHERE id_episode = c_epis.id_episode;
    END LOOP;

    --
    COMMIT;
    RETURN;
END;
/

-- CHANGED BY: Ana Matos
-- CHANGE DATE: 13/03/2015 17:37
-- CHANGE REASON: [ALERT-307519] 
-->mig_grid_task|migration
DECLARE

    CURSOR c_grid_task IS
        SELECT gt.id_episode, e.id_patient, e.id_institution, ei.id_software, ia.id_language
          FROM grid_task gt, episode e, epis_info ei, institution_language ia
         WHERE gt.exam_d IS NOT NULL
           AND gt.id_episode = e.id_episode
           AND e.id_episode = ei.id_episode
           AND e.id_institution = ia.id_institution
        UNION
        SELECT gt.id_episode, e.id_patient, e.id_institution, ei.id_software, ia.id_language
          FROM grid_task gt, episode e, epis_info ei, institution_language ia
         WHERE gt.exam_n IS NOT NULL
           AND gt.id_episode = e.id_episode
           AND e.id_episode = ei.id_episode
           AND e.id_institution = ia.id_institution;

    l_grid_task grid_task%ROWTYPE;

    l_shortcut NUMBER;

    l_show_all_icon_tracking VARCHAR2(200 CHAR);

BEGIN

    FOR r_cur IN c_grid_task
    LOOP
    
        BEGIN
            SELECT t.value
              INTO l_show_all_icon_tracking
              FROM (SELECT sc.value, row_number() over(ORDER BY sc.id_institution DESC, sc.id_software DESC) rn
                      FROM sys_config sc
                     WHERE sc.id_sys_config = 'SHOW_IMAGE_TRACKING_IN_GRIDS'
                       AND sc.id_institution IN (0, r_cur.id_institution)
                       AND sc.id_software IN (0, r_cur.id_software)) t
             WHERE rn = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_show_all_icon_tracking := 'N';
        END;
    
        l_grid_task := NULL;
    
        FOR rec IN (SELECT t.flg_type,
                           REPLACE(decode(substr(t.status_string_med, 2, 1),
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
                                                                      'YYYYMMDDHH24MISS TZR')) status_string_enf
                      FROM (SELECT flg_type,
                                   MAX(status_string_med) status_string_med,
                                   MAX(status_string_enf) status_string_enf
                              FROM (SELECT flg_type,
                                           decode(rank_med,
                                                  1,
                                                  pk_utils.get_status_string(r_cur.id_language,
                                                                             profissional(NULL,
                                                                                          r_cur.id_institution,
                                                                                          r_cur.id_software),
                                                                             pk_ea_logic_exams.get_exam_status_str_det(r_cur.id_language,
                                                                                                                       profissional(NULL,
                                                                                                                                    r_cur.id_institution,
                                                                                                                                    r_cur.id_software),
                                                                                                                       id_episode,
                                                                                                                       flg_time,
                                                                                                                       flg_status,
                                                                                                                       flg_referral,
                                                                                                                       flg_status_result,
                                                                                                                       dt_req_tstz,
                                                                                                                       dt_pend_req_tstz,
                                                                                                                       dt_begin_tstz),
                                                                             pk_ea_logic_exams.get_exam_status_msg_det(r_cur.id_language,
                                                                                                                       profissional(NULL,
                                                                                                                                    r_cur.id_institution,
                                                                                                                                    r_cur.id_software),
                                                                                                                       id_episode,
                                                                                                                       flg_time,
                                                                                                                       flg_status,
                                                                                                                       flg_referral,
                                                                                                                       flg_status_result,
                                                                                                                       dt_req_tstz,
                                                                                                                       dt_pend_req_tstz,
                                                                                                                       dt_begin_tstz),
                                                                             pk_ea_logic_exams.get_exam_status_icon_det(r_cur.id_language,
                                                                                                                        profissional(NULL,
                                                                                                                                     r_cur.id_institution,
                                                                                                                                     r_cur.id_software),
                                                                                                                        id_episode,
                                                                                                                        flg_time,
                                                                                                                        flg_status,
                                                                                                                        flg_referral,
                                                                                                                        flg_status_result,
                                                                                                                        dt_req_tstz,
                                                                                                                        dt_pend_req_tstz,
                                                                                                                        dt_begin_tstz),
                                                                             pk_ea_logic_exams.get_exam_status_flg_det(r_cur.id_language,
                                                                                                                       profissional(NULL,
                                                                                                                                    r_cur.id_institution,
                                                                                                                                    r_cur.id_software),
                                                                                                                       id_episode,
                                                                                                                       flg_time,
                                                                                                                       flg_status,
                                                                                                                       flg_referral,
                                                                                                                       flg_status_result,
                                                                                                                       dt_req_tstz,
                                                                                                                       dt_pend_req_tstz,
                                                                                                                       dt_begin_tstz)),
                                                  NULL) status_string_med,
                                           decode(rank_enf,
                                                  1,
                                                  pk_utils.get_status_string(r_cur.id_language,
                                                                             profissional(NULL,
                                                                                          r_cur.id_institution,
                                                                                          r_cur.id_software),
                                                                             pk_ea_logic_exams.get_exam_status_str_det(r_cur.id_language,
                                                                                                                       profissional(NULL,
                                                                                                                                    r_cur.id_institution,
                                                                                                                                    r_cur.id_software),
                                                                                                                       id_episode,
                                                                                                                       flg_time,
                                                                                                                       flg_status,
                                                                                                                       flg_referral,
                                                                                                                       flg_status_result,
                                                                                                                       dt_req_tstz,
                                                                                                                       dt_pend_req_tstz,
                                                                                                                       dt_begin_tstz),
                                                                             pk_ea_logic_exams.get_exam_status_msg_det(r_cur.id_language,
                                                                                                                       profissional(NULL,
                                                                                                                                    r_cur.id_institution,
                                                                                                                                    r_cur.id_software),
                                                                                                                       id_episode,
                                                                                                                       flg_time,
                                                                                                                       flg_status,
                                                                                                                       flg_referral,
                                                                                                                       flg_status_result,
                                                                                                                       dt_req_tstz,
                                                                                                                       dt_pend_req_tstz,
                                                                                                                       dt_begin_tstz),
                                                                             pk_ea_logic_exams.get_exam_status_icon_det(r_cur.id_language,
                                                                                                                        profissional(NULL,
                                                                                                                                     r_cur.id_institution,
                                                                                                                                     r_cur.id_software),
                                                                                                                        id_episode,
                                                                                                                        flg_time,
                                                                                                                        flg_status,
                                                                                                                        flg_referral,
                                                                                                                        flg_status_result,
                                                                                                                        dt_req_tstz,
                                                                                                                        dt_pend_req_tstz,
                                                                                                                        dt_begin_tstz),
                                                                             pk_ea_logic_exams.get_exam_status_flg_det(r_cur.id_language,
                                                                                                                       profissional(NULL,
                                                                                                                                    r_cur.id_institution,
                                                                                                                                    r_cur.id_software),
                                                                                                                       id_episode,
                                                                                                                       flg_time,
                                                                                                                       flg_status,
                                                                                                                       flg_referral,
                                                                                                                       flg_status_result,
                                                                                                                       dt_req_tstz,
                                                                                                                       dt_pend_req_tstz,
                                                                                                                       dt_begin_tstz)),
                                                  NULL) status_string_enf
                                      FROM (SELECT t.id_exam_req_det,
                                                   t.id_episode,
                                                   t.flg_type,
                                                   t.flg_time,
                                                   t.flg_status,
                                                   t.flg_referral,
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
                                                                                                'EXAM_REQ_DET.FLG_STATUS.URGENT',
                                                                                                t.flg_status) + 1000,
                                                                          pk_sysdomain.get_rank(r_cur.id_language,
                                                                                                'EXAM_REQ_DET.FLG_STATUS',
                                                                                                t.flg_status)) rank
                                                              FROM (SELECT erd.id_exam_req_det,
                                                                           er.id_episode,
                                                                           e.flg_type,
                                                                           er.flg_time,
                                                                           erd.flg_status,
                                                                           erd.flg_referral,
                                                                           CASE
                                                                                WHEN erd.flg_status = 'F' THEN
                                                                                 CASE
                                                                                     WHEN er.priority != 'N'
                                                                                          OR (eres.id_abnormality IS NOT NULL AND
                                                                                          eres.id_abnormality != 7) THEN
                                                                                      rs.value || 'U'
                                                                                     ELSE
                                                                                      rs.value
                                                                                 END
                                                                                ELSE
                                                                                 rs.value
                                                                            END flg_status_result,
                                                                           er.dt_req_tstz,
                                                                           er.dt_pend_req_tstz,
                                                                           er.dt_begin_tstz,
                                                                           CASE
                                                                                WHEN er.priority != 'N'
                                                                                     OR (eres.id_abnormality IS NOT NULL AND
                                                                                     eres.id_abnormality != 7) THEN
                                                                                 'Y'
                                                                                ELSE
                                                                                 'N'
                                                                            END flg_urgent
                                                                      FROM exam_req      er,
                                                                           exam_req_det  erd,
                                                                           exam          e,
                                                                           exam_result   eres,
                                                                           result_status rs
                                                                     WHERE (er.id_episode = r_cur.id_episode OR
                                                                           er.id_prev_episode = r_cur.id_episode OR
                                                                           er.id_episode_origin = r_cur.id_episode)
                                                                       AND er.id_exam_req = erd.id_exam_req
                                                                       AND ((l_show_all_icon_tracking = 'Y' AND
                                                                           erd.flg_status IN
                                                                           ('S', 'X', 'R', 'D', 'PA', 'E', 'EX', 'F')) OR
                                                                           erd.flg_status IN ('X', 'R', 'D', 'PA', 'F'))
                                                                       AND (erd.flg_referral NOT IN ('R', 'S', 'I') OR
                                                                           erd.flg_referral IS NULL)
                                                                       AND erd.id_exam = e.id_exam
                                                                       AND erd.id_exam_req_det = eres.id_exam_req_det(+)
                                                                       AND eres.id_result_status = rs.id_result_status(+)
                                                                    UNION ALL
                                                                    SELECT erd.id_exam_req_det,
                                                                           er.id_episode,
                                                                           e.flg_type,
                                                                           er.flg_time,
                                                                           erd.flg_status,
                                                                           erd.flg_referral,
                                                                           CASE
                                                                               WHEN er.priority != 'N'
                                                                                    OR (eres.id_abnormality IS NOT NULL AND
                                                                                    eres.id_abnormality != 7) THEN
                                                                                rs.value || 'U'
                                                                               ELSE
                                                                                rs.value
                                                                           END flg_status_result,
                                                                           er.dt_req_tstz,
                                                                           er.dt_pend_req_tstz,
                                                                           er.dt_begin_tstz,
                                                                           CASE
                                                                               WHEN er.priority != 'N'
                                                                                    OR (eres.id_abnormality IS NOT NULL AND
                                                                                    eres.id_abnormality != 7) THEN
                                                                                'Y'
                                                                               ELSE
                                                                                'N'
                                                                           END flg_urgent
                                                                      FROM exam_req      er,
                                                                           exam_req_det  erd,
                                                                           exam          e,
                                                                           exam_result   eres,
                                                                           result_status rs,
                                                                           episode       epis
                                                                     WHERE er.id_patient = r_cur.id_patient
                                                                       AND er.id_episode != r_cur.id_episode
                                                                       AND er.id_exam_req = erd.id_exam_req
                                                                       AND (erd.flg_referral NOT IN ('R', 'S', 'I') OR
                                                                           erd.flg_referral IS NULL)
                                                                       AND er.flg_status = 'F'
                                                                       AND erd.id_exam = e.id_exam
                                                                       AND erd.id_exam_req_det = eres.id_exam_req_det
                                                                       AND eres.id_result_status = rs.id_result_status(+)
                                                                       AND (er.id_episode = epis.id_episode OR
                                                                           er.id_prev_episode = epis.id_episode OR
                                                                           er.id_episode_origin = epis.id_episode)
                                                                       AND epis.id_epis_type NOT IN (2, 4, 5)) t) t) t)
                                     WHERE rank_med = 1
                                        OR rank_enf = 1)
                             GROUP BY flg_type) t)
        LOOP
        
            IF rec.flg_type = 'I'
            THEN
                BEGIN
                    SELECT id_sys_shortcut
                      INTO l_shortcut
                      FROM (SELECT s.id_sys_shortcut,
                                   row_number() over(PARTITION BY s.id_sys_shortcut ORDER BY s.id_institution DESC, s.id_software DESC) rn
                              FROM sys_shortcut s
                             WHERE s.intern_name = 'GRID_IMAGE'
                               AND s.id_software = r_cur.id_software
                               AND s.id_parent IS NULL)
                     WHERE rn = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_shortcut := 0;
                END;
            ELSE
                BEGIN
                    SELECT id_sys_shortcut
                      INTO l_shortcut
                      FROM (SELECT s.id_sys_shortcut,
                                   row_number() over(PARTITION BY s.id_sys_shortcut ORDER BY s.id_institution DESC, s.id_software DESC) rn
                              FROM sys_shortcut s
                             WHERE s.intern_name = 'GRID_OTH_EXAM'
                               AND s.id_software = r_cur.id_software
                               AND s.id_parent IS NULL)
                     WHERE rn = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_shortcut := 0;
                END;
            END IF;
        
            IF rec.status_string_med IS NOT NULL
            THEN
                IF rec.flg_type = 'I'
                THEN
                    l_grid_task.img_exam_d := l_shortcut || rec.status_string_med;
                ELSE
                    l_grid_task.oth_exam_d := l_shortcut || rec.status_string_med;
                END IF;
            END IF;
        
            IF rec.status_string_enf IS NOT NULL
            THEN
                IF rec.flg_type = 'I'
                THEN
                    l_grid_task.img_exam_n := l_shortcut || rec.status_string_enf;
                ELSE
                    l_grid_task.oth_exam_n := l_shortcut || rec.status_string_enf;
                END IF;
            END IF;
        
            l_grid_task.id_episode := r_cur.id_episode;
        
            IF l_grid_task.id_episode IS NOT NULL
            THEN
                UPDATE grid_task gt
                   SET gt.img_exam_d = l_grid_task.img_exam_d,
                       gt.img_exam_n = l_grid_task.img_exam_n,
                       gt.oth_exam_d = l_grid_task.oth_exam_d,
                       gt.oth_exam_n = l_grid_task.oth_exam_n
                 WHERE gt.id_episode = l_grid_task.id_episode;
            END IF;
        END LOOP;
    END LOOP;
END;
/
-- CHANGE END: Ana Matos

-- CHANGED BY: Ana Matos
-- CHANGE DATE: 16/03/2015 09:55
-- CHANGE REASON: [ALERT-307519] 
DECLARE

    CURSOR c_grid_task IS
        SELECT gt.id_episode, e.id_patient, e.id_institution, ei.id_software, ia.id_language
          FROM grid_task gt, episode e, epis_info ei, institution_language ia
         WHERE gt.exam_d IS NOT NULL
           AND gt.id_episode = e.id_episode
           AND e.id_episode = ei.id_episode
           AND e.id_institution = ia.id_institution
        UNION
        SELECT gt.id_episode, e.id_patient, e.id_institution, ei.id_software, ia.id_language
          FROM grid_task gt, episode e, epis_info ei, institution_language ia
         WHERE gt.exam_n IS NOT NULL
           AND gt.id_episode = e.id_episode
           AND e.id_episode = ei.id_episode
           AND e.id_institution = ia.id_institution;

    l_grid_task grid_task%ROWTYPE;

    l_shortcut NUMBER;

    l_show_all_icon_tracking VARCHAR2(200 CHAR);

BEGIN

    FOR r_cur IN c_grid_task
    LOOP
    
        BEGIN
            SELECT t.value
              INTO l_show_all_icon_tracking
              FROM (SELECT sc.value, row_number() over(ORDER BY sc.id_institution DESC, sc.id_software DESC) rn
                      FROM sys_config sc
                     WHERE sc.id_sys_config = 'SHOW_IMAGE_TRACKING_IN_GRIDS'
                       AND sc.id_institution IN (0, r_cur.id_institution)
                       AND sc.id_software IN (0, r_cur.id_software)) t
             WHERE rn = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_show_all_icon_tracking := 'N';
        END;
    
        l_grid_task := NULL;
    
        FOR rec IN (SELECT t.flg_type,
                           REPLACE(decode(substr(t.status_string_med, 2, 1),
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
                                                                      'YYYYMMDDHH24MISS TZR')) status_string_enf
                      FROM (SELECT flg_type,
                                   MAX(status_string_med) status_string_med,
                                   MAX(status_string_enf) status_string_enf
                              FROM (SELECT flg_type,
                                           decode(rank_med,
                                                  1,
                                                  pk_utils.get_status_string(r_cur.id_language,
                                                                             profissional(NULL,
                                                                                          r_cur.id_institution,
                                                                                          r_cur.id_software),
                                                                             pk_ea_logic_exams.get_exam_status_str_det(r_cur.id_language,
                                                                                                                       profissional(NULL,
                                                                                                                                    r_cur.id_institution,
                                                                                                                                    r_cur.id_software),
                                                                                                                       id_episode,
                                                                                                                       flg_time,
                                                                                                                       flg_status,
                                                                                                                       flg_referral,
                                                                                                                       flg_status_result,
                                                                                                                       dt_req_tstz,
                                                                                                                       dt_pend_req_tstz,
                                                                                                                       dt_begin_tstz),
                                                                             pk_ea_logic_exams.get_exam_status_msg_det(r_cur.id_language,
                                                                                                                       profissional(NULL,
                                                                                                                                    r_cur.id_institution,
                                                                                                                                    r_cur.id_software),
                                                                                                                       id_episode,
                                                                                                                       flg_time,
                                                                                                                       flg_status,
                                                                                                                       flg_referral,
                                                                                                                       flg_status_result,
                                                                                                                       dt_req_tstz,
                                                                                                                       dt_pend_req_tstz,
                                                                                                                       dt_begin_tstz),
                                                                             pk_ea_logic_exams.get_exam_status_icon_det(r_cur.id_language,
                                                                                                                        profissional(NULL,
                                                                                                                                     r_cur.id_institution,
                                                                                                                                     r_cur.id_software),
                                                                                                                        id_episode,
                                                                                                                        flg_time,
                                                                                                                        flg_status,
                                                                                                                        flg_referral,
                                                                                                                        flg_status_result,
                                                                                                                        dt_req_tstz,
                                                                                                                        dt_pend_req_tstz,
                                                                                                                        dt_begin_tstz),
                                                                             pk_ea_logic_exams.get_exam_status_flg_det(r_cur.id_language,
                                                                                                                       profissional(NULL,
                                                                                                                                    r_cur.id_institution,
                                                                                                                                    r_cur.id_software),
                                                                                                                       id_episode,
                                                                                                                       flg_time,
                                                                                                                       flg_status,
                                                                                                                       flg_referral,
                                                                                                                       flg_status_result,
                                                                                                                       dt_req_tstz,
                                                                                                                       dt_pend_req_tstz,
                                                                                                                       dt_begin_tstz)),
                                                  NULL) status_string_med,
                                           decode(rank_enf,
                                                  1,
                                                  pk_utils.get_status_string(r_cur.id_language,
                                                                             profissional(NULL,
                                                                                          r_cur.id_institution,
                                                                                          r_cur.id_software),
                                                                             pk_ea_logic_exams.get_exam_status_str_det(r_cur.id_language,
                                                                                                                       profissional(NULL,
                                                                                                                                    r_cur.id_institution,
                                                                                                                                    r_cur.id_software),
                                                                                                                       id_episode,
                                                                                                                       flg_time,
                                                                                                                       flg_status,
                                                                                                                       flg_referral,
                                                                                                                       flg_status_result,
                                                                                                                       dt_req_tstz,
                                                                                                                       dt_pend_req_tstz,
                                                                                                                       dt_begin_tstz),
                                                                             pk_ea_logic_exams.get_exam_status_msg_det(r_cur.id_language,
                                                                                                                       profissional(NULL,
                                                                                                                                    r_cur.id_institution,
                                                                                                                                    r_cur.id_software),
                                                                                                                       id_episode,
                                                                                                                       flg_time,
                                                                                                                       flg_status,
                                                                                                                       flg_referral,
                                                                                                                       flg_status_result,
                                                                                                                       dt_req_tstz,
                                                                                                                       dt_pend_req_tstz,
                                                                                                                       dt_begin_tstz),
                                                                             pk_ea_logic_exams.get_exam_status_icon_det(r_cur.id_language,
                                                                                                                        profissional(NULL,
                                                                                                                                     r_cur.id_institution,
                                                                                                                                     r_cur.id_software),
                                                                                                                        id_episode,
                                                                                                                        flg_time,
                                                                                                                        flg_status,
                                                                                                                        flg_referral,
                                                                                                                        flg_status_result,
                                                                                                                        dt_req_tstz,
                                                                                                                        dt_pend_req_tstz,
                                                                                                                        dt_begin_tstz),
                                                                             pk_ea_logic_exams.get_exam_status_flg_det(r_cur.id_language,
                                                                                                                       profissional(NULL,
                                                                                                                                    r_cur.id_institution,
                                                                                                                                    r_cur.id_software),
                                                                                                                       id_episode,
                                                                                                                       flg_time,
                                                                                                                       flg_status,
                                                                                                                       flg_referral,
                                                                                                                       flg_status_result,
                                                                                                                       dt_req_tstz,
                                                                                                                       dt_pend_req_tstz,
                                                                                                                       dt_begin_tstz)),
                                                  NULL) status_string_enf
                                      FROM (SELECT t.id_exam_req_det,
                                                   t.id_episode,
                                                   t.flg_type,
                                                   t.flg_time,
                                                   t.flg_status,
                                                   t.flg_referral,
                                                   t.flg_status_result,
                                                   t.dt_req_tstz,
                                                   t.dt_pend_req_tstz,
                                                   t.dt_begin_tstz,
                                                   row_number() over(PARTITION BY t.flg_type ORDER BY t.rank_med) rank_med,
                                                   row_number() over(PARTITION BY t.flg_type ORDER BY t.rank_enf) rank_enf
                                              FROM (SELECT t.*,
                                                           decode(t.flg_status,
                                                                  'F',
                                                                  row_number()
                                                                  over(PARTITION BY t.flg_type ORDER BY t.rank DESC),
                                                                  'R',
                                                                  row_number() over(PARTITION BY t.flg_type ORDER BY
                                                                       coalesce(t.dt_pend_req_tstz,
                                                                                t.dt_begin_tstz,
                                                                                t.dt_req_tstz)) + 10000,
                                                                  row_number() over(PARTITION BY t.flg_type ORDER BY
                                                                       coalesce(t.dt_pend_req_tstz,
                                                                                t.dt_begin_tstz,
                                                                                t.dt_req_tstz) DESC) + 20000) rank_med,
                                                           decode(t.flg_status,
                                                                  'R',
                                                                  row_number() over(PARTITION BY t.flg_type ORDER BY
                                                                       coalesce(t.dt_pend_req_tstz,
                                                                                t.dt_begin_tstz,
                                                                                t.dt_req_tstz)),
                                                                  row_number() over(PARTITION BY t.flg_type ORDER BY
                                                                       coalesce(t.dt_pend_req_tstz,
                                                                                t.dt_begin_tstz,
                                                                                t.dt_req_tstz) DESC) + 20000) rank_enf
                                                      FROM (SELECT t.*,
                                                                   decode(flg_urgent,
                                                                          'Y',
                                                                          pk_sysdomain.get_rank(r_cur.id_language,
                                                                                                'EXAM_REQ_DET.FLG_STATUS.URGENT',
                                                                                                t.flg_status) + 1000,
                                                                          pk_sysdomain.get_rank(r_cur.id_language,
                                                                                                'EXAM_REQ_DET.FLG_STATUS',
                                                                                                t.flg_status)) rank
                                                              FROM (SELECT erd.id_exam_req_det,
                                                                           er.id_episode,
                                                                           e.flg_type,
                                                                           er.flg_time,
                                                                           erd.flg_status,
                                                                           erd.flg_referral,
                                                                           CASE
                                                                                WHEN erd.flg_status = 'F' THEN
                                                                                 CASE
                                                                                     WHEN er.priority != 'N'
                                                                                          OR (eres.id_abnormality IS NOT NULL AND
                                                                                          eres.id_abnormality != 7) THEN
                                                                                      rs.value || 'U'
                                                                                     ELSE
                                                                                      rs.value
                                                                                 END
                                                                                ELSE
                                                                                 rs.value
                                                                            END flg_status_result,
                                                                           er.dt_req_tstz,
                                                                           er.dt_pend_req_tstz,
                                                                           er.dt_begin_tstz,
                                                                           CASE
                                                                                WHEN er.priority != 'N'
                                                                                     OR (eres.id_abnormality IS NOT NULL AND
                                                                                     eres.id_abnormality != 7) THEN
                                                                                 'Y'
                                                                                ELSE
                                                                                 'N'
                                                                            END flg_urgent
                                                                      FROM exam_req      er,
                                                                           exam_req_det  erd,
                                                                           exam          e,
                                                                           exam_result   eres,
                                                                           result_status rs
                                                                     WHERE (er.id_episode = r_cur.id_episode OR
                                                                           er.id_prev_episode = r_cur.id_episode OR
                                                                           er.id_episode_origin = r_cur.id_episode)
                                                                       AND er.id_exam_req = erd.id_exam_req
                                                                       AND ((l_show_all_icon_tracking = 'Y' AND
                                                                           erd.flg_status IN
                                                                           ('S', 'X', 'R', 'D', 'PA', 'E', 'EX', 'F')) OR
                                                                           erd.flg_status IN ('X', 'R', 'D', 'PA', 'F'))
                                                                       AND (erd.flg_referral NOT IN ('R', 'S', 'I') OR
                                                                           erd.flg_referral IS NULL)
                                                                       AND erd.id_exam = e.id_exam
                                                                       AND erd.id_exam_req_det = eres.id_exam_req_det(+)
                                                                       AND eres.id_result_status = rs.id_result_status(+)
                                                                    UNION ALL
                                                                    SELECT erd.id_exam_req_det,
                                                                           er.id_episode,
                                                                           e.flg_type,
                                                                           er.flg_time,
                                                                           erd.flg_status,
                                                                           erd.flg_referral,
                                                                           CASE
                                                                               WHEN er.priority != 'N'
                                                                                    OR (eres.id_abnormality IS NOT NULL AND
                                                                                    eres.id_abnormality != 7) THEN
                                                                                rs.value || 'U'
                                                                               ELSE
                                                                                rs.value
                                                                           END flg_status_result,
                                                                           er.dt_req_tstz,
                                                                           er.dt_pend_req_tstz,
                                                                           er.dt_begin_tstz,
                                                                           CASE
                                                                               WHEN er.priority != 'N'
                                                                                    OR (eres.id_abnormality IS NOT NULL AND
                                                                                    eres.id_abnormality != 7) THEN
                                                                                'Y'
                                                                               ELSE
                                                                                'N'
                                                                           END flg_urgent
                                                                      FROM exam_req      er,
                                                                           exam_req_det  erd,
                                                                           exam          e,
                                                                           exam_result   eres,
                                                                           result_status rs,
                                                                           episode       epis
                                                                     WHERE er.id_patient = r_cur.id_patient
                                                                       AND er.id_episode != r_cur.id_episode
                                                                       AND er.id_exam_req = erd.id_exam_req
                                                                       AND (erd.flg_referral NOT IN ('R', 'S', 'I') OR
                                                                           erd.flg_referral IS NULL)
                                                                       AND er.flg_status = 'F'
                                                                       AND erd.id_exam = e.id_exam
                                                                       AND erd.id_exam_req_det = eres.id_exam_req_det
                                                                       AND eres.id_result_status = rs.id_result_status(+)
                                                                       AND (er.id_episode = epis.id_episode OR
                                                                           er.id_prev_episode = epis.id_episode OR
                                                                           er.id_episode_origin = epis.id_episode)
                                                                       AND epis.id_epis_type NOT IN (2, 4, 5)) t) t) t)
                                     WHERE rank_med = 1
                                        OR rank_enf = 1)
                             GROUP BY flg_type) t)
        LOOP
        
            IF rec.flg_type = 'I'
            THEN
                BEGIN
                    SELECT id_sys_shortcut
                      INTO l_shortcut
                      FROM (SELECT s.id_sys_shortcut,
                                   row_number() over(PARTITION BY s.id_sys_shortcut ORDER BY s.id_institution DESC, s.id_software DESC) rn
                              FROM sys_shortcut s
                             WHERE s.intern_name = 'GRID_IMAGE'
                               AND s.id_software = r_cur.id_software
                               AND s.id_parent IS NULL)
                     WHERE rn = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_shortcut := 0;
                END;
            ELSE
                BEGIN
                    SELECT id_sys_shortcut
                      INTO l_shortcut
                      FROM (SELECT s.id_sys_shortcut,
                                   row_number() over(PARTITION BY s.id_sys_shortcut ORDER BY s.id_institution DESC, s.id_software DESC) rn
                              FROM sys_shortcut s
                             WHERE s.intern_name = 'GRID_OTH_EXAM'
                               AND s.id_software = r_cur.id_software
                               AND s.id_parent IS NULL)
                     WHERE rn = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_shortcut := 0;
                END;
            END IF;
        
            IF rec.status_string_med IS NOT NULL
            THEN
                IF rec.flg_type = 'I'
                THEN
                    l_grid_task.img_exam_d := l_shortcut || rec.status_string_med;
                ELSE
                    l_grid_task.oth_exam_d := l_shortcut || rec.status_string_med;
                END IF;
            END IF;
        
            IF rec.status_string_enf IS NOT NULL
            THEN
                IF rec.flg_type = 'I'
                THEN
                    l_grid_task.img_exam_n := l_shortcut || rec.status_string_enf;
                ELSE
                    l_grid_task.oth_exam_n := l_shortcut || rec.status_string_enf;
                END IF;
            END IF;
        
            l_grid_task.id_episode := r_cur.id_episode;
        
            IF l_grid_task.id_episode IS NOT NULL
            THEN
                UPDATE grid_task gt
                   SET gt.img_exam_d = l_grid_task.img_exam_d,
                       gt.img_exam_n = l_grid_task.img_exam_n,
                       gt.oth_exam_d = l_grid_task.oth_exam_d,
                       gt.oth_exam_n = l_grid_task.oth_exam_n
                 WHERE gt.id_episode = l_grid_task.id_episode;
            END IF;
        END LOOP;
    END LOOP;
END;
/

-- CHANGE END: Ana Matos