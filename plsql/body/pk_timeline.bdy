/*-- Last Change Revision: $Rev: 2027791 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:19 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_timeline IS

    k_epis_type_oris      CONSTANT NUMBER := pk_alert_constant.g_epis_type_operating;
    k_epis_type_inpatient CONSTANT NUMBER := pk_alert_constant.g_epis_type_inpatient;

    /**************************************************************************************
    * GET_TOKEN              Function that returns STRING in position X separated by one delimitator Y
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_LIST                   Strings (with an list of strings separated by one delimitator)
    * @param I_INDEX                  Desired position in string
    * 
      * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} 
    *                 '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns DATE STRING in position X of I_LIST
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/04/19
      *************************************************************************************/
    FUNCTION get_token
    (
        i_lang  IN language.id_language%TYPE,
        i_list  IN VARCHAR2,
        i_index IN NUMBER,
        i_delim IN VARCHAR2 DEFAULT ','
    ) RETURN VARCHAR2 IS
        start_pos NUMBER;
        end_pos   NUMBER;
    BEGIN
        IF i_index = 1
        THEN
            start_pos := 1;
        ELSE
            start_pos := instr(i_list, i_delim, 1, i_index - 1);
            IF start_pos = 0
            THEN
                RETURN NULL;
            ELSE
                start_pos := start_pos + length(i_delim);
            END IF;
        END IF;
    
        end_pos := instr(i_list, i_delim, start_pos, 1);
    
        IF end_pos = 0
        THEN
            RETURN substr(i_list, start_pos);
        ELSE
            RETURN substr(i_list, start_pos, end_pos - start_pos);
        END IF;
    END get_token;

    /*****************************************************************************************
    * Name:                           GET_TASK_TIMELINE_DOMAIN
    * Description:                    Function that internally return the oldest and newer (future) task to be done to patients list
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional information Vector: (professional ID, institution ID, software ID)
    * @param I_VISIT_LIST             TABLE_NUMBER with all ID_VISIT that should be searched in Task Timeline information (available visits in current grid)
    * @param I_EPISODE_LIST           TABLE_NUMBER with all ID_EPISODE that should be searched in Task Timeline information (available episodes in current grid)
    * @param I_PATIENT_LIST           TABLE_NUMBER with all ID_PATIENT that should be searched in Task Timeline information (available patients in current grid)
    * @param I_TL_TASK_LIST           TABLE_NUMBER with all ID_TL_TASK that should be searched in Task Timeline information (available TL_TASKS in current institution)
    * @param C_GET_EXTREME_INFO       Cursor with information about the oldest and newest task to stored (presented) in timeline
    * @param O_ERROR                  Error information
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/06/06
    *****************************************************************************************/
    FUNCTION get_task_timeline_domain
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_visit_list       IN table_number DEFAULT NULL,
        i_episode_list     IN table_number DEFAULT NULL,
        i_patient_list     IN table_number DEFAULT NULL,
        i_tl_task_list     IN table_number DEFAULT NULL,
        i_id_patient       IN NUMBER DEFAULT NULL,
        i_ori_type_list    IN table_number DEFAULT NULL,
        o_get_extreme_info OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name VARCHAR2(200) := 'GET_TASK_TIMELINE_DOMAIN';
        l_dt_server     VARCHAR2(50);
        l_dt_day_begin  task_timeline_ea.dt_begin%TYPE;
        l_inst          table_number;
    BEGIN
    
        --
        l_dt_server    := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
        l_dt_day_begin := pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, NULL);
    
        --
        g_error := l_function_name || ' - CALL pk_utils.get_institutions_sib';
        IF NOT pk_utils.get_institutions_sib(i_lang  => i_lang,
                                             i_prof  => i_prof,
                                             i_inst  => i_prof.institution,
                                             o_list  => l_inst,
                                             o_error => o_error)
        THEN
            RETURN FALSE;
        ELSE
            IF l_inst.count = 0
            THEN
                l_inst.extend;
                l_inst(1) := i_prof.institution;
            END IF;
        END IF;
    
        --
        g_error := l_function_name || ' - OPEN CURSOR';
        OPEN o_get_extreme_info FOR
            SELECT to_char(dt_minim - 24 / 3, pk_alert_constant.g_date_hour_send_format) dt_min_value, -- Begin date for Task Timeline
                   to_char(decode(pk_date_utils.compare_dates_tsz(i_prof, dt_max_bgn, dt_max_end),
                                  'G',
                                  decode(pk_date_utils.compare_dates_tsz(i_prof, dt_max_bgn, current_timestamp),
                                         'G',
                                         dt_max_bgn,
                                         current_timestamp),
                                  decode(pk_date_utils.compare_dates_tsz(i_prof, dt_max_end, current_timestamp),
                                         'G',
                                         dt_max_end,
                                         current_timestamp)) + 24 / 3,
                           pk_alert_constant.g_date_hour_send_format) dt_max_value, -- End date for Task Timeline dt_end
                   l_dt_server dt_server -- Server actual time
              FROM (SELECT nvl(MIN(dt_begin), current_timestamp) dt_minim,
                           nvl(MAX(dt_end_bgn), current_timestamp) dt_max_bgn,
                           nvl(MAX(dt_end), current_timestamp) dt_max_end
                      FROM --
                           (SELECT /*+ opt_estimate(table t_epis rows=10)*/
                             MIN(tte.dt_begin) dt_begin, MAX(tte.dt_begin) dt_end_bgn, MAX(tte.dt_end) dt_end
                              FROM tl_task tt
                             INNER JOIN task_timeline_ea tte
                                ON (tt.id_tl_task = tte.id_tl_task)
                             INNER JOIN TABLE(i_episode_list) t_epi
                                ON (t_epi.column_value = tte.id_episode AND
                                   tte.flg_show_method = pk_alert_constant.g_tl_oriented_episode)
                            --
                            UNION
                            --
                            SELECT /*+ opt_estimate(table t_epis rows=10)*/
                             MIN(tte.dt_begin) dt_begin, MAX(tte.dt_begin) dt_end_bgn, MAX(tte.dt_end) dt_end
                              FROM tl_task tt
                             INNER JOIN task_timeline_ea tte
                                ON (tt.id_tl_task = tte.id_tl_task)
                             INNER JOIN TABLE(i_episode_list) t_vis
                                ON (t_vis.column_value = tte.id_episode AND
                                   tte.flg_show_method = pk_alert_constant.g_tl_oriented_episode)
                            --
                            UNION
                            --
                            SELECT /*+ opt_estimate(table t_vis rows=10)*/
                             MIN(tte.dt_begin) dt_begin, MAX(tte.dt_begin) dt_end_bgn, MAX(tte.dt_end) dt_end
                              FROM tl_task tt
                             INNER JOIN task_timeline_ea tte
                                ON (tt.id_tl_task = tte.id_tl_task)
                             INNER JOIN TABLE(i_patient_list) t_vis
                                ON (t_vis.column_value = tte.id_patient AND
                                   tte.flg_show_method = pk_alert_constant.g_tl_oriented_patient)
                             WHERE tte.dt_begin >= l_dt_day_begin
                            --
                            UNION
                            --
                            -- This union get POSITIONING tasks
                            SELECT /*+ opt_estimate(table t_epis rows=10)*/
                             MIN(epp.dt_prev_plan_tstz) dt_begin, MAX(epp.dt_prev_plan_tstz) dt_end_bgn, NULL dt_end
                            --
                              FROM epis_positioning ep
                             INNER JOIN epis_positioning_det epd
                                ON (ep.id_epis_positioning = epd.id_epis_positioning)
                             INNER JOIN epis_positioning_plan epp
                                ON (epd.id_epis_positioning_det = epp.id_epis_positioning_det)
                             INNER JOIN episode epi
                                ON (epi.id_episode = ep.id_episode)
                             INNER JOIN TABLE(i_episode_list) t_epi
                                ON (t_epi.column_value = ep.id_episode)
                             WHERE epp.flg_status = 'E'
                               AND ep.flg_status IN ('R', 'E')
                            --
                            UNION
                            --
                            -- This union get HIDRICS tasks
                            SELECT /*+ opt_estimate(table t_epis rows=10)*/
                             MIN(eh.dt_initial_tstz) dt_begin,
                             MAX(eh.dt_initial_tstz) dt_end_bgn,
                             MAX(eh.dt_end_tstz) dt_end
                            --
                              FROM epis_hidrics eh
                             INNER JOIN hidrics_type ht
                                ON (ht.id_hidrics_type = eh.id_hidrics_type)
                             INNER JOIN episode epi
                                ON (epi.id_episode = eh.id_episode)
                             INNER JOIN TABLE(i_episode_list) t_epi
                                ON (t_epi.column_value = epi.id_visit)
                             WHERE eh.flg_status IN ('R', 'E') -- (Required, In execution)
                            --
                            UNION
                            SELECT MIN(dt_begin) dt_begin, MAX(dt_end_bgn) dt_end_bgn, NULL dt_end
                              FROM (SELECT de.dt_inserted dt_begin, de.dt_inserted dt_end_bgn
                                      FROM doc_external de
                                      JOIN doc_ori_type dot
                                        ON de.id_doc_ori_type = dot.id_doc_ori_type
                                     WHERE de.id_patient = i_id_patient
                                       AND de.flg_status = pk_doc.g_doc_active -- ok
                                       AND dot.flg_available = pk_doc.g_doc_ori_type_available_y -- ok
                                       AND (i_ori_type_list IS NULL OR
                                           dot.id_doc_ori_type IN (SELECT column_value
                                                                      FROM TABLE(i_ori_type_list)))
                                       AND de.id_institution IN (SELECT column_value
                                                                   FROM TABLE(l_inst))
                                    UNION ALL
                                    SELECT de.dt_inserted dt_begin, de.dt_inserted dt_end_bgn
                                      FROM doc_external de
                                      JOIN doc_ori_type dot
                                        ON de.id_doc_ori_type = dot.id_doc_ori_type
                                     WHERE de.id_episode IN (SELECT /*+opt_estimate(table t rows=10)*/
                                                              column_value
                                                               FROM TABLE(i_episode_list) t)
                                       AND de.flg_status = pk_doc.g_doc_active -- ok
                                       AND dot.flg_available = pk_doc.g_doc_ori_type_available_y -- ok
                                       AND (i_ori_type_list IS NULL OR
                                           dot.id_doc_ori_type IN (SELECT column_value
                                                                      FROM TABLE(i_ori_type_list)))
                                       AND de.id_institution IN (SELECT column_value
                                                                   FROM TABLE(l_inst)))));
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_get_extreme_info);
            RETURN FALSE;
    END get_task_timeline_domain;

    /************************************************************************************
    * Name:                           GET_EPISODES_TIMELINE_DOMAIN
    * Description:                    Function that internally return the oldest date with relevant information to be represented in episode timeline sctructure
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional information Vector: (professional ID, institution ID, software ID)
    * @param I_ID_TL_TIMELINE         Timeline ID: 1-Episode timeline; 2-Task timeline
    * @param I_ID_PATIENT             Patient ID
    * @param C_GET_EXTREME_INFO       Cursor with information about the oldest information to store in timeline
    * @param O_ERROR                  Error information
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value I_ID_TL_TIMELINE         {*} '1' Episode timeline {*} '2' Task timeline
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/03/26
    **************************************************************************************/
    FUNCTION get_episodes_timeline_domain
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_tl_timeline   IN tl_timeline.id_tl_timeline%TYPE,
        i_id_patient       IN patient.id_patient%TYPE,
        o_get_extreme_info OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name VARCHAR2(200) := 'GET_EPISODES_TIMELINE_DOMAIN';
        user_exception EXCEPTION;
    BEGIN
    
        pk_alertlog.log_debug('OPEN c_get_extreme_info FOR EPISODE TIMELINE');
        OPEN o_get_extreme_info FOR
            SELECT to_char(p.dt_birth, pk_alert_constant.g_date_hour_send_format) dt_min_value, -- Patient date of birth
                   to_char(pk_date_utils.get_timestamp_insttimezone(i_lang, i_prof.institution),
                           pk_alert_constant.g_date_hour_send_format) dt_max_value, -- Current server date
                   to_char(pk_date_utils.get_timestamp_insttimezone(i_lang, i_prof.institution),
                           pk_alert_constant.g_date_hour_send_format) dt_server -- Server actual time
              FROM patient p
             WHERE p.id_patient = i_id_patient;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_get_extreme_info);
            RETURN FALSE;
    END get_episodes_timeline_domain;

    /*********************************************************************************
    * Name:                           GET_TL_AVAILABLE_SCALES
    * Description:                    Function that internally return the scales available for current timeline and professional in the correct order
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional information Vector: (professional ID, institution ID, software ID)
    * @param I_ID_TL_TIMELINE         Timeline ID: 1-Episode timeline; 2-Task timeline
    * @param I_ID_PATIENT             Patient ID
    * @param C_GET_SCALES             Cursor with information about the scales available for current timeline and professional
    * @param O_ERROR                  Error information
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value I_ID_TL_TIMELINE         {*} '1' Episode timeline {*} '2' Task timeline {*} '3' Lab Tests timeline
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * @raises                         PL/SQL generic erro "OTHERS"
    * @raises                         shift_duration_exception Ocours when there is not defined an shift duration for current institution
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/03/26
    **********************************************************************************/
    FUNCTION get_tl_available_scales
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_tl_timeline IN tl_timeline.id_tl_timeline%TYPE,
        i_id_patient     IN patient.id_patient%TYPE,
        c_get_scale      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_inst_shift_duration VARCHAR2(4);
        shift_duration_exception EXCEPTION;
        l_error_message VARCHAR2(4000);
        l_function_name VARCHAR2(200) := 'GET_TL_AVAILABLE_SCALES';
    
        -- Institution software and market configuration variables
        l_institution institution.id_institution%TYPE;
        l_software    software.id_software%TYPE;
        l_market      market.id_market%TYPE;
        l_prof_market NUMBER;
        r_pat         patient%ROWTYPE;
    
        -- Get config cursor
        CURSOR c_config_ism(i_market IN NUMBER) IS
            SELECT tls_aism.id_institution, tls_aism.id_software, tls_aism.id_market
              FROM tl_scale_inst_soft_market tls_aism
             WHERE tls_aism.id_institution IN (0, i_prof.institution)
               AND tls_aism.id_software IN (0, i_prof.software)
               AND tls_aism.id_market IN (0, i_market)
               AND tls_aism.id_tl_timeline = i_id_tl_timeline
             ORDER BY tls_aism.id_institution DESC, tls_aism.id_software DESC, tls_aism.id_market DESC;
    
    BEGIN
        -- Get first line of cursor that will cotaign the configuration for the main query
        pk_alertlog.log_debug('Get configuration');
    
        l_prof_market := pk_core.get_inst_mkt(i_prof.institution);
    
        g_error := 'GET VERTICAL AXIS CONFIG';
        OPEN c_config_ism(l_prof_market);
        FETCH c_config_ism
            INTO l_institution, l_software, l_market;
    
        IF c_config_ism%NOTFOUND
        THEN
            g_error := 'NO TL_VA_INST_SOFT_MARKET CONFIGURATION';
            RAISE g_exception;
        END IF;
    
        CLOSE c_config_ism;
    
        BEGIN
            SELECT pat.*
              INTO r_pat
              FROM patient pat
             WHERE pat.id_patient = i_id_patient;
        EXCEPTION
            WHEN no_data_found THEN
                r_pat := NULL;
        END;
    
        IF i_id_tl_timeline = g_tl_episodes -- EPISODE TIMELINE
        THEN
            pk_alertlog.log_debug('OPEN c_get_scale FOR EPISODE TIMELINE');
        
            OPEN c_get_scale FOR
                SELECT ts.id_tl_scale,
                       pk_translation.get_translation(i_lang, ts.code_scale) desc_translation,
                       ts.num_columns,
                       pk_timeline.enable_disable_scale(i_lang, i_prof, r_pat.dt_birth, ts.id_tl_scale) flg_show,
                       tls_ism.flg_default
                  FROM tl_scale ts
                  JOIN tl_scale_inst_soft_market tls_ism
                    ON ts.id_tl_scale = tls_ism.id_tl_scale_xlower
                 WHERE tls_ism.id_tl_timeline = i_id_tl_timeline
                   AND tls_ism.id_institution = l_institution
                   AND tls_ism.id_software = l_software
                   AND tls_ism.id_market = l_market
                 ORDER BY tls_ism.rank;
        
        ELSIF i_id_tl_timeline = g_tl_tasks -- TASK TIMELINE
        THEN
            -- Get shift duration to current institution
            pk_alertlog.log_debug('GET institution shift duration');
            l_inst_shift_duration := pk_sysconfig.get_config('TIMELINE_CARDEX_SHIFT_DURATION', i_prof);
            IF l_inst_shift_duration IS NULL
            THEN
                g_error := pk_message.get_message(i_lang, 'TL_INITIALIZE_SHIFT_DURATION');
                RAISE shift_duration_exception;
            END IF;
        
            -- Get available time scales for current timeline and professional
            pk_alertlog.log_debug('OPEN c_get_scale FOR TASK TIMELINE');
            OPEN c_get_scale FOR
                SELECT ts.id_tl_scale,
                       -- This change was done to allow the appearence of variable shift duration (ex: 6h, 8h, ..)
                       REPLACE(pk_translation.get_translation(i_lang, ts.code_scale), '@1', l_inst_shift_duration) desc_translation,
                       decode(ts.id_tl_scale,
                              pk_alert_constant.g_shift,
                              to_number(l_inst_shift_duration),
                              ts.num_columns) num_columns,
                       g_flg_yes flg_show,
                       tls_ism.flg_default
                  FROM tl_scale ts
                  JOIN tl_scale_inst_soft_market tls_ism
                    ON ts.id_tl_scale = tls_ism.id_tl_scale_xlower
                 WHERE tls_ism.id_tl_timeline = i_id_tl_timeline
                   AND tls_ism.id_institution = l_institution
                   AND tls_ism.id_software = l_software
                   AND tls_ism.id_market = l_market
                 ORDER BY tls_ism.rank;
        
        ELSIF i_id_tl_timeline = g_tl_lab_tests -- LABTEST GRAPH TIMELINE
        THEN
        
            -- Get available time scales for current timeline and professional
            pk_alertlog.log_debug('OPEN c_get_scale FOR LABTEST GRAPH TIMELINE');
            OPEN c_get_scale FOR
                SELECT ts.id_tl_scale,
                       pk_translation.get_translation(i_lang, ts.code_scale) desc_translation,
                       CASE
                            WHEN (i_prof.software IN (pk_alert_constant.g_soft_outpatient,
                                                      pk_alert_constant.g_soft_primary_care,
                                                      pk_alert_constant.g_soft_private_practice,
                                                      pk_alert_constant.g_soft_psychologist,
                                                      pk_alert_constant.g_soft_social,
                                                      pk_alert_constant.g_soft_nutritionist,
                                                      pk_alert_constant.g_soft_rehab,
                                                      pk_alert_constant.g_soft_case_manager,
                                                      pk_alert_constant.g_soft_home_care) AND ts.id_tl_scale = 3) THEN
                             g_flg_yes
                            WHEN (i_prof.software IN (pk_alert_constant.g_soft_edis,
                                                      pk_alert_constant.g_soft_ubu,
                                                      pk_alert_constant.g_soft_triage,
                                                      pk_alert_constant.g_soft_inpatient,
                                                      pk_alert_constant.g_soft_oris,
                                                      pk_alert_constant.g_soft_pharmacy,
                                                      pk_alert_constant.g_soft_labtech,
                                                      pk_alert_constant.g_soft_imgtech,
                                                      pk_alert_constant.g_soft_extech,
                                                      pk_alert_constant.g_soft_resptherap) AND ts.id_tl_scale = 4) THEN
                             g_flg_yes
                            ELSE
                             g_flg_no
                        END AS flg_show,
                       tls_ism.flg_default
                  FROM tl_scale ts
                  JOIN tl_scale_inst_soft_market tls_ism
                    ON ts.id_tl_scale = tls_ism.id_tl_scale_xlower
                 WHERE tls_ism.id_tl_timeline = i_id_tl_timeline
                   AND tls_ism.id_institution = l_institution
                   AND tls_ism.id_software = l_software
                   AND tls_ism.id_market = l_market
                 ORDER BY tls_ism.rank;
        
        ELSIF i_id_tl_timeline = g_tl_docs
        THEN
            -- document archive timeline
            pk_alertlog.log_debug('OPEN c_get_scale FOR DOCUMENTS ARCHIVE TIMELINE');
            OPEN c_get_scale FOR
                SELECT ts.id_tl_scale,
                       pk_translation.get_translation(i_lang, ts.code_scale) desc_translation,
                       ts.num_columns,
                       pk_timeline.enable_disable_scale(i_lang, i_prof, r_pat.dt_birth, ts.id_tl_scale) flg_show,
                       tls_ism.flg_default
                  FROM tl_scale ts
                  JOIN tl_scale_inst_soft_market tls_ism
                    ON ts.id_tl_scale = tls_ism.id_tl_scale_xlower
                 WHERE tls_ism.id_tl_timeline = i_id_tl_timeline
                   AND tls_ism.id_institution = l_institution
                   AND tls_ism.id_software = l_software
                   AND tls_ism.id_market = l_market
                 ORDER BY tls_ism.rank;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN shift_duration_exception THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_message := pk_message.get_message(i_lang, g_general_error);
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   'ERROR_SHIFT_DURATION_NOT_DEFINED',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   l_function_name);
                pk_utils.undo_changes; -- undo changes quando aplicável-> só faz ROLLBACK
                l_error_in.set_action(l_error_message, 'U');
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error); -- execute error processing
            
                pk_types.open_my_cursor(c_get_scale);
                RETURN FALSE; -- return failure of function_dummy
            END;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_types.open_my_cursor(c_get_scale);
            RETURN FALSE;
    END get_tl_available_scales;

    /****************************************************************************************
    *GET_TIMELINE_DETAILS This function return detail form the timeline data                                                                   *
    *                                                                                                                                          *
    * @param I_LANG                   ID language for translations                                                                             *
    * @param I_PROF                   ID professional, ID institution and ID software information                                              *
    * @param I_TL_TIMELINE            Timeline ID                                                                                              *
    * @param I_PATIENT                Patient id                                                                                               *
    * @param O_X_DATA                 Output cursor data                                                                                       *
    * @param O_ERROR                  Output error                                                                                             *
    *                                                                                                                                          *
    *                                                                                                                                          *
    * @return                         False in error case true in other case                                                                   *
    *                                                                                                                                          *
    * @raises                         Genéric oracle error                                                                                     *
    *                                                                                                                                          *
    * @author                         Carlos Vieira                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2008/05/09                                                                                               *
    *****************************************************************************************/
    FUNCTION get_timeline_details
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_tl_timeline IN tl_timeline.id_tl_timeline%TYPE,
        i_patient     IN patient.id_patient%TYPE,
        o_x_data      OUT pk_timeline.t_cur_timeline_detail,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_return BOOLEAN := TRUE;
        user_exception EXCEPTION;
        --
        l_id_social_software   software.id_software%TYPE;
        l_code_social_software software.code_software%TYPE;
        l_function             VARCHAR2(200) := 'GET_TIMELINE_DETAILS';
        CURSOR c_get_social_software IS
            SELECT s.code_software
              FROM software s
             WHERE id_software = l_id_social_software;
    BEGIN
        l_id_social_software := pk_sysconfig.get_config(g_software_assist, i_prof.institution, i_prof.software);
    
        OPEN c_get_social_software;
        FETCH c_get_social_software
            INTO l_code_social_software;
        CLOSE c_get_social_software;
    
        IF nvl(i_tl_timeline, g_timeline_episode) = g_timeline_episode
        THEN
            pk_alertlog.log_debug('initialize');
            IF NOT pk_timeline_core.initialize(i_lang, i_prof, o_error)
            THEN
                g_error := pk_message.get_message(i_lang, 'TL_INITIALIZE');
                RAISE user_exception;
            END IF;
        
            pk_alertlog.log_debug('o_x_data');
            -- This select returns the necessary data to the 2ª view timeline screen: id_episode,id_professional,visit_type,visit_information,nick_name,
            -- date begin and date end.
            OPEN o_x_data FOR
                SELECT a.id_episode,
                       a.id_professional,
                       a.visit_type,
                       a.visit_information,
                       a.nick_name,
                       a.id_report,
                       a.dt_begin,
                       a.dt_end,
                       a.dt_begin_tstz,
                       a.dt_end_tstz,
                       a.id_software,
                       a.visit_type || ' - ' || pk_date_utils.dt_chr_tsz(i_lang, a.dt_begin_tstz, i_prof) || ' (' ||
                       to_char(a.id_episode) || ')' desc_timeline
                  FROM (SELECT epis.id_episode,
                               decode(ei.id_professional, NULL, ei.id_first_nurse_resp, ei.id_professional) id_professional,
                               pk_ehr_common.get_visit_name_by_epis(i_lang,
                                                                    profissional(ei.id_professional,
                                                                                 epis.id_institution,
                                                                                 ei.id_software),
                                                                    epis.id_epis_type) visit_type,
                               pk_ehr_common.get_visit_type_by_epis(i_lang,
                                                                    profissional(ei.id_professional,
                                                                                 epis.id_institution,
                                                                                 ei.id_software),
                                                                    epis.id_episode,
                                                                    epis.id_epis_type,
                                                                    chr(10)) visit_information,
                            /*   pk_prof_utils.get_name_signature(i_lang,
                                                                i_prof,
                                                                decode(ei.id_professional,
                                                                       NULL,
                                                                       ei.id_first_nurse_resp,
                                                                       ei.id_professional)) nick_name,*/
                                                                       get_visit_prof_name(i_lang,
                                                                    profissional(ei.id_professional,
                                                                                 epis.id_institution,
                                                                                 ei.id_software),
                                                                    epis.id_episode,
                                                                    epis.id_epis_type) nick_name,
                               pk_sysconfig.get_config(g_tl_report, i_prof.institution, tls.id_tl_software) id_report,
                               pk_date_utils.date_send_tsz(i_lang,
                                                           epis.dt_begin_tstz,
                                                           i_prof.institution,
                                                           i_prof.software) dt_begin,
                               pk_date_utils.date_send_tsz(i_lang, epis.dt_end_tstz, i_prof.institution, i_prof.software) dt_end,
                               epis.dt_begin_tstz,
                               epis.dt_end_tstz,
                               ei.id_software
                          FROM episode epis
                          JOIN epis_info ei
                            ON (epis.id_episode = ei.id_episode)
                          JOIN tl_software tls
                            ON (tls.id_tl_software = ei.id_software)
                          LEFT JOIN room r
                            ON (r.id_room = ei.id_room)
                         WHERE ei.id_patient = i_patient
                           AND epis.flg_status != g_flg_cancel
                           AND epis.flg_ehr = g_flg_normal
                           AND ei.id_software != g_oris_soft
                        UNION
                        -- Oris episode professional responsible is in a different table
                        SELECT epis.id_episode,
                               ei.id_professional,
                               pk_ehr_common.get_visit_name_by_epis(i_lang,
                                                                    profissional(p.id_professional,
                                                                                 epis.id_institution,
                                                                                 ei.id_software),
                                                                    epis.id_epis_type) visit_type,
                               pk_ehr_common.get_visit_type_by_epis(i_lang,
                                                                    profissional(p.id_professional,
                                                                                 epis.id_institution,
                                                                                 ei.id_software),
                                                                    epis.id_episode,
                                                                    epis.id_epis_type,
                                                                    chr(10)) visit_information,
                               pk_prof_utils.get_name_signature(i_lang, i_prof, ei.id_professional) nick_name,
                               pk_sysconfig.get_config(g_tl_report, i_prof.institution, tls.id_tl_software) id_report,
                               pk_date_utils.date_send_tsz(i_lang,
                                                           epis.dt_begin_tstz,
                                                           i_prof.institution,
                                                           i_prof.software) dt_begin,
                               pk_date_utils.date_send_tsz(i_lang, epis.dt_end_tstz, i_prof.institution, i_prof.software) dt_end,
                               epis.dt_begin_tstz,
                               epis.dt_end_tstz,
                               ei.id_software
                          FROM episode epis
                          JOIN epis_info ei
                            ON (epis.id_episode = ei.id_episode)
                          JOIN tl_software tls
                            ON (tls.id_tl_software = ei.id_software)
                          LEFT JOIN room r
                            ON (r.id_room = ei.id_room)
                        -- there are episode that have more than one responsible
                          LEFT JOIN (
                                    -- init cmf
                                    /*
                                    SELECT MAX(td.id_professional) id_professional, td.id_episode id_episode
                                      FROM sr_prof_team_det td
                                     WHERE td.id_category_sub = g_catg_surg_resp
                                       AND td.flg_status != g_cancel
                                               GROUP BY td.id_episode
                                     */
                                    SELECT s001.id_professional, s001.id_episode
                                      FROM (SELECT td.id_professional,
                                                    td.id_episode_context id_episode,
                                                    row_number() over(PARTITION BY td.id_episode_context ORDER BY td.dt_reg_tstz DESC) rn
                                               FROM sr_prof_team_det td
                                               JOIN sr_epis_interv sei
                                                 ON sei.id_sr_epis_interv = td.id_sr_epis_interv
                                              WHERE td.id_category_sub = g_catg_surg_resp
                                                AND td.flg_status != g_cancel) s001
                                     WHERE rn = 1) sptd
                            ON (sptd.id_episode = epis.id_episode)
                        -- end cmf
                          LEFT JOIN professional p
                            ON (sptd.id_professional = p.id_professional)
                         WHERE ei.id_patient = i_patient
                           AND epis.flg_status != g_flg_cancel
                           AND epis.flg_ehr = g_flg_normal
                           AND ei.id_software = g_oris_soft) a
                 ORDER BY a.dt_begin_tstz desc, a.dt_end_tstz;
            --
            l_return := TRUE;
        ELSE
            l_return := FALSE;
        END IF;
        RETURN l_return;
    
    EXCEPTION
        WHEN user_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function,
                                              'U',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TIMELINE_DETAILS',
                                              o_error);
            RETURN FALSE;
    END get_timeline_details;

  -- **************************************************************
    FUNCTION get_id_prof_oris(i_episode IN NUMBER) RETURN NUMBER IS
    tbl_id  table_number;
    l_return number;
  begin
  
    select id_professional 
          BULK COLLECT
          INTO tbl_id
          FROM (SELECT td.id_professional,
                       td.id_episode_context,
                       row_number() over(PARTITION BY td.id_episode_context ORDER BY td.dt_reg_tstz DESC) rn
      FROM sr_prof_team_det td
                  JOIN sr_epis_interv sei
                    ON sei.id_sr_epis_interv = td.id_sr_epis_interv
      WHERE td.id_category_sub = 1
      and sei.flg_type = 'P'
      and td.id_episode_context = i_episode
                   AND td.flg_status != 'C')
         WHERE rn = 1;
  
        IF tbl_id.count > 0
        THEN
      l_return := tbl_id(1);
    end if;
    
    return l_return;

  end get_id_prof_oris;

  -- *************************************************************
    FUNCTION get_id_prof_epis_type
    (
        i_epis_type    IN NUMBER,
        i_episode      IN NUMBER,
        i_professional IN NUMBER,
        i_nurse        IN NUMBER
    ) RETURN NUMBER IS
    l_epis_type number;
    l_return  number;
    
    -- ***********************************
        FUNCTION get_epis_type(i_epis_type IN NUMBER) RETURN NUMBER IS
      l_return number := i_epis_type;
    begin
    
            IF i_epis_type IS NULL
            THEN
                SELECT id_epis_type
                  INTO l_return
                  FROM episode
                 WHERE id_episode = i_episode;
      end if;
      
      return l_return;
    
    end get_epis_type;
    
  begin
  
        l_epis_type := get_epis_type(i_epis_type);
  
    case l_epis_type 
    when k_epis_type_oris then

                l_return := get_id_prof_oris(i_episode);
                l_return := nvl(l_return, i_professional);
      
    else
                l_return := nvl(i_professional, i_nurse);
    end case;
    
    return l_return;
  
  end get_id_prof_epis_type;
  
  -- *****************************************************************
    FUNCTION get_timeline_det_inp_oris
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_tl_timeline IN tl_timeline.id_tl_timeline%TYPE,
        i_patient     IN patient.id_patient%TYPE,
        o_x_data      OUT pk_timeline.t_cur_timeline_detail,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_return BOOLEAN := TRUE;
        user_exception EXCEPTION;
        --
    l_bool boolean;
        l_function             VARCHAR2(200 char) := 'GET_TIMELINE_DET_INP_ORIS';
  begin
  
        l_bool :=  nvl(i_tl_timeline, g_timeline_episode) = g_timeline_episode;
    
        IF l_bool
        THEN
            
            IF NOT pk_timeline_core.initialize(i_lang, i_prof, o_error)
            THEN
                g_error := pk_message.get_message(i_lang, 'TL_INITIALIZE');
                RAISE user_exception;
            END IF;
      
            OPEN o_x_data FOR
                SELECT xdata.id_episode,
          xdata.id_professional,
          xdata.visit_type,
          xdata.visit_information,
          xdata.nick_name,
          xdata.id_report,
          xdata.dt_begin,
          xdata.dt_end,
          xdata.dt_begin_tstz,
          xdata.dt_end_tstz,
          xdata.id_software,
                       xdata.visit_type || ' - ' || pk_date_utils.dt_chr_tsz(i_lang, xdata.dt_begin_tstz, i_prof) || ' (' ||
                       to_char(xdata.id_episode) || ')' desc_timeline
                  FROM (SELECT xmain.id_episode,
            xmain.id_professional id_professional,   
                               pk_ehr_common.get_visit_name_by_epis(i_lang,
                                                                    profissional(xmain.id_professional,
                                                                                 xmain.id_institution,
                                                                                 xmain.id_software),
                xmain.id_epis_type) visit_type, -- inp urg
                               pk_ehr_common.get_visit_type_by_epis(i_lang,
                                                                    profissional(xmain.id_professional,
                                                                                 xmain.id_institution,
                                                                                 xmain.id_software),
                xmain.id_episode,
                xmain.id_epis_type,
                chr(10)) visit_information, 
            pk_prof_utils.get_name_signature(i_lang, i_prof, xmain.id_professional) nick_name,
            pk_sysconfig.get_config(g_tl_report, i_prof.institution, xmain.id_tl_software) id_report,
                               pk_date_utils.date_send_tsz(i_lang,
                                                           xmain.dt_begin_tstz,
                                                           i_prof.institution,
                                                           i_prof.software) dt_begin,
                               pk_date_utils.date_send_tsz(i_lang,
                                                           xmain.dt_end_tstz,
                                                           i_prof.institution,
                                                           i_prof.software) dt_end,
            xmain.dt_begin_tstz,
            xmain.dt_end_tstz,
            xmain.id_software
                          FROM (SELECT xinfo.id_institution,
                                       xinfo.id_episode,
                                       xinfo.id_epis_type,
                                       xinfo.dt_begin_tstz,
                                       xinfo.dt_end_tstz,
                                       ei.id_software,
                                       tls.id_tl_software,
                                       ei.id_first_nurse_resp,
                                       pk_timeline.get_id_prof_epis_type(xinfo.id_epis_type,
                                                                         ei.id_episode,
                                                                         ei.id_professional,
                                                                         ei.id_first_nurse_resp) id_professional
              from  ( 
                -- inp episodes
                                        SELECT v.id_institution,
                                                inp.id_episode,
                                                inp.id_epis_type,
                                                inp.dt_begin_tstz,
                                                inp.dt_end_tstz,
                                                inp.flg_ehr,
                                                inp.flg_status
                from episode inp 
                                          JOIN visit v
                                            ON v.id_visit = inp.id_visit
                where inp.id_epis_type = k_epis_type_inpatient 
                and v.id_patient = i_patient
                union all
                -- oris episode not originated by inp
                                        SELECT v.id_institution,
                                                sr.id_episode,
                                                sr.id_epis_type,
                                                sr.dt_begin_tstz,
                                                sr.dt_end_tstz,
                                                sr.flg_ehr,
                                                sr.flg_status
                from episode sr 
                                          JOIN visit v
                                            ON v.id_visit = sr.id_visit
                                          JOIN episode prv
                                            ON prv.id_episode = sr.id_prev_episode
                                           AND prv.id_visit != sr.id_visit
                where sr.id_epis_type = k_epis_type_oris
                                           --AND prv.id_epis_type != k_epis_type_inpatient
                                           AND v.id_patient = i_patient) xinfo
                                  JOIN epis_info ei
                                    ON ei.id_episode = xinfo.id_episode
                                  JOIN tl_software tls
                                    ON (tls.id_tl_software = ei.id_software)
              WHERE xinfo.flg_status != g_flg_cancel
                                   AND xinfo.flg_ehr = g_flg_normal) xmain) xdata
        ORDER BY xdata.dt_begin_tstz, xdata.dt_end_tstz;

      l_return := true;
      
    else
      l_return := false;
    end if;
    
    return l_return;
  
    EXCEPTION
        WHEN user_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function,
                                              'U',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function,
                                              o_error);
            RETURN FALSE;
  end get_timeline_det_inp_oris;

    /*************************************************************************
    *enable_disable_scale Returns a flag to enable or disable scales                                                                           *
    *                                                                                                                                          *
    * @param I_LANG                   ID da linguagem para traduções                                                                           *
    * @param I_PROF                   Vector com a informação relativa  ao profissional, instituição e software                                *
    * @param I_DT_BIRTH               birth date                                                                                               *
    * @param   I_ID_SCALE             Scale ID                                                                                                 *
    *                                                                                                                                          *
    *                                                                                                                                          *
    * @return                         flag to enable or disable scales                                                                         *
    *                                                                                                                                          *
    * @raises                                                                                                                                  *
    *                                                                                                                                          *
    * @author                         Carlos Vieira                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2008/05/08                                                                                               *
    ****************************************************************************/
    FUNCTION enable_disable_scale
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_dt_birth IN DATE,
        i_id_scale IN NUMBER
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(1);
        o_error  t_error_out;
    BEGIN
        pk_alertlog.log_debug('Mark 1');
        --
        IF -- tem mais de 10 anos
         nvl(i_dt_birth, SYSDATE - g_days_of_two_dec) <= add_months(SYSDATE, g_months_of_dec)
        THEN
            l_return := g_flg_yes;
        ELSIF
        -- tem mais de 1 ano e menos de 10
         nvl(i_dt_birth, SYSDATE - g_days_of_two_dec) > add_months(SYSDATE, g_months_of_dec)
         AND nvl(i_dt_birth, SYSDATE - g_days_of_two_dec) <= add_months(SYSDATE, -12)
        THEN
            IF i_id_scale = pk_alert_constant.g_decade
            THEN
                l_return := g_flg_no;
            ELSE
                l_return := g_flg_yes;
            END IF;
            -- tem mais de 1 mês e menos de 1 ano
        ELSIF nvl(i_dt_birth, SYSDATE - g_days_of_two_dec) <= add_months(SYSDATE, -1)
              AND nvl(i_dt_birth, SYSDATE - g_days_of_two_dec) > add_months(SYSDATE, -12)
        THEN
            IF i_id_scale = pk_alert_constant.g_decade
               OR i_id_scale = pk_alert_constant.g_year
            THEN
                l_return := g_flg_no;
            ELSE
                l_return := g_flg_yes;
            END IF;
            -- tem mais de 1 semana e menos de 1 mês
        ELSIF nvl(i_dt_birth, SYSDATE - g_days_of_two_dec) <= SYSDATE - 7
              AND nvl(i_dt_birth, SYSDATE - g_days_of_two_dec) > add_months(SYSDATE, -1)
        THEN
            IF i_id_scale = pk_alert_constant.g_decade
               OR i_id_scale = pk_alert_constant.g_year
               OR i_id_scale = pk_alert_constant.g_month
            THEN
                l_return := g_flg_no;
            ELSE
                l_return := g_flg_yes;
            END IF;
            -- tem menos de 1 semana
        ELSIF nvl(i_dt_birth, SYSDATE - g_days_of_two_dec) > SYSDATE - 7
              AND nvl(i_dt_birth, SYSDATE - g_days_of_two_dec) <= SYSDATE
        THEN
            IF i_id_scale = pk_alert_constant.g_decade
               OR i_id_scale = pk_alert_constant.g_year
               OR i_id_scale = pk_alert_constant.g_month
               OR i_id_scale = pk_alert_constant.g_week
            THEN
                l_return := g_flg_no;
            ELSE
                l_return := g_flg_yes;
            END IF;
        END IF;
        --
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'ENABLE_DISABLE_SCALE',
                                              o_error);
            RETURN NULL;
    END;

    /*******************************************************************************************
    * Nome :                          GET_TIMELINE_SCALE                                                                                       *
    * Descrição:                      Função que devolve as escalas temporais, parametrizadas para a timeline em questão                                           *
    *                                                                                                                                          *
    * @param I_LANG                   ID da linguagem para traduções                                                                           *
    * @param I_PROF                   Vector com a informação relativa  ao profissional, instituição e software                                *
    * @param I_ID_TL_TIMELINE         ID da timeline que esta a ser executada                                                                  *
    * @param I_ID_PATIENT             ID do paciente                                                                                           *
    * @param I_LIST_VISIT             visit ID from all patients available in current grid                                                     *
    * @param C_GET_SCALE              Cursor que devolve a informação para output                                                              *
    * @param O_ERROR                  Devolução do erro                                                                                        *
    *                                                                                                                                          *
    *                                                                                                                                          *
    * @return                         Retorna False se der erro e true caso contrário                                                          *
    * @raises                         Erro genérico de plsql                                                                                   *
    *                                                                                                                                          *
    * @author                         Carlos Vieira                                                                                            *
    * @version                        1.0                                                                                                     *
    * @since                          2008/04/16                                                                                               *
    **********************************************************************************************/
    FUNCTION get_time_scale
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_tl_timeline   IN tl_timeline.id_tl_timeline%TYPE,
        i_id_patient       IN patient.id_patient%TYPE,
        i_list_visit       IN table_number DEFAULT NULL,
        c_get_scale        OUT pk_types.cursor_type,
        c_get_patient_info OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        --
        l_error_message VARCHAR2(4000);
        user_exception EXCEPTION;
        l_function_name VARCHAR2(200) := 'GET_TIME_SCALE';
    BEGIN
        ---- Initialize timeline
        pk_alertlog.log_debug('CALL initialize');
        IF NOT pk_timeline_core.initialize(i_lang, i_prof, o_error)
        THEN
            g_error := pk_message.get_message(i_lang, 'TL_INITIALIZE');
            RAISE user_exception;
        END IF;
    
        ---- Get oldest info to represent in timeline and current server date
        pk_alertlog.log_debug('CALL get_episodes_timeline_domain');
        IF NOT get_episodes_timeline_domain(i_lang, i_prof, i_id_tl_timeline, i_id_patient, c_get_patient_info, o_error)
        THEN
            g_error := pk_message.get_message(i_lang, 'TL_ERROR_GET_EXTREME_VALUES');
            RAISE user_exception;
        END IF;
    
        ---- Get timeline scales for current timeline and professional
        pk_alertlog.log_debug('CALL get_tl_available_scales');
        IF NOT get_tl_available_scales(i_lang, i_prof, i_id_tl_timeline, i_id_patient, c_get_scale, o_error)
        THEN
            g_error := pk_message.get_message(i_lang, 'TL_ERROR_GET_AVAILABLE_SCALES');
            RAISE user_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN user_exception THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_message := pk_message.get_message(i_lang, g_general_error);
                l_error_in.set_all(i_lang,
                                   'ERROR_INITIALIZE_TIMELINE',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   l_function_name);
                pk_utils.undo_changes; -- undo changes quando aplicável-> só faz ROLLBACK
                l_error_in.set_action(l_error_message, 'U');
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error); -- execute error processing
                --
                pk_types.open_my_cursor(c_get_patient_info);
                pk_types.open_my_cursor(c_get_scale);
                RETURN FALSE; -- return failure of function_dummy
            END;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            --
            pk_types.open_my_cursor(c_get_patient_info);
            pk_types.open_my_cursor(c_get_scale);
            RETURN FALSE;
    END get_time_scale;

    /*********************************************************************************************
    * Nome :                          GET_TASKS_TIMELINE_SCALE
    * Descrição:                      Function that returns temporal scales parametrized for task timeline
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional information Vector: (professional ID, institution ID, software ID)
    * @param I_VISIT_LIST             TABLE_NUMBER with all ID_VISIT that should be searched in Task Timeline information (available visits in current grid)
    * @param I_EPISODE_LIST           TABLE_NUMBER with all ID_EPISODE that should be searched in Task Timeline information (available episodes in current grid)
    * @param I_PATIENT_LIST           TABLE_NUMBER with all ID_PATIENT that should be searched in Task Timeline information (available patients in current grid)
    * @param I_TL_TASK_LIST           TABLE_NUMBER with all ID_TL_TASK that should be searched in Task Timeline information (available TL_TASKS in current institution)
    * @param C_GET_SCALE              Cursor with information about temporal scales parametrized for task timeline
    * @param C_GET_PATIENT_INFO       Cursor with information about the oldest and newest task to stored (presented) in timeline
    * @param O_ERROR                  Error information
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/06/06
    *********************************************************************************************/
    FUNCTION get_tasks_time_scale
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_tl_timeline   IN tl_timeline.id_tl_timeline%TYPE,
        i_id_patient       IN patient.id_patient%TYPE DEFAULT NULL,
        i_visit_list       IN table_number DEFAULT NULL,
        i_episode_list     IN table_number DEFAULT NULL,
        i_patient_list     IN table_number DEFAULT NULL,
        i_tl_task_list     IN table_number DEFAULT NULL,
        i_ori_type_list    IN table_number DEFAULT NULL,
        c_get_scale        OUT pk_types.cursor_type,
        c_get_patient_info OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        --
        l_error_message VARCHAR2(4000);
        user_exception EXCEPTION;
        l_function_name VARCHAR2(200) := 'GET_TIME_SCALE';
    BEGIN
        ---- Initialize timeline
        pk_alertlog.log_debug('CALL initialize');
        IF NOT pk_timeline_core.initialize(i_lang, i_prof, o_error)
        THEN
            g_error := pk_message.get_message(i_lang, 'TL_INITIALIZE');
            RAISE user_exception;
        END IF;
    
        ---- Get oldest info to represent in timeline and current server date
        pk_alertlog.log_debug('CALL get_task_timeline_domain');
        IF NOT get_task_timeline_domain(i_lang,
                                        i_prof,
                                        i_visit_list,
                                        i_episode_list,
                                        i_patient_list,
                                        i_tl_task_list,
                                        i_id_patient,
                                        i_ori_type_list,
                                        c_get_patient_info,
                                        o_error)
        THEN
            g_error := pk_message.get_message(i_lang, 'TL_ERROR_GET_EXTREME_VALUES');
            RAISE user_exception;
        END IF;
    
        ---- Get timeline scales for current timeline and professional
        pk_alertlog.log_debug('CALL get_tl_available_scales');
        IF NOT get_tl_available_scales(i_lang, i_prof, i_id_tl_timeline, i_id_patient, c_get_scale, o_error)
        
        THEN
            g_error := pk_message.get_message(i_lang, 'TL_ERROR_GET_AVAILABLE_SCALES');
            RAISE user_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN user_exception THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_message := pk_message.get_message(i_lang, g_general_error);
                l_error_in.set_all(i_lang,
                                   'ERROR_INITIALIZE_TIMELINE',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   l_function_name);
                pk_utils.undo_changes; -- undo changes quando aplicável-> só faz ROLLBACK
                l_error_in.set_action(l_error_message, 'U');
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error); -- execute error processing
                --
                pk_types.open_my_cursor(c_get_patient_info);
                pk_types.open_my_cursor(c_get_scale);
                RETURN FALSE; -- return failure of function_dummy
            END;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            --
            pk_types.open_my_cursor(c_get_patient_info);
            pk_types.open_my_cursor(c_get_scale);
            RETURN FALSE;
    END get_tasks_time_scale;

    /*********************************************************************************************
    * Nome :                          GET_VERTICAL_AXIS                                                                                        *
    * Descrição:                      Return the y axis elements                                                                                                   *
    *                                                                                                                                          *
    * @param I_LANG                   ID da linguagem para traduções                                                                           *
    * @param I_PROF                   ID professional, ID institution and ID software information                                              *
    * @param I_ID_TL_TIMELINE         ID da TIMELINE                                                                                           *
    * @param I_ID_PATIENT             ID patient                                                                                               *
    * @param O_ERROR                  Error return                                                                                             *
    * @param O_CURSOR_OUT             Output cursor                                                                                            *
    *                                                                                                                                          *
    *                                                                                                                                          *
    * @return                         Return false if an error occurred and true otherowise                                                    *
    * @raises                         Generic oracle error                                                                                     *
    *                                                                                                                                          *
    * @author                         Carlos Vieira                                                                                            *
    * @version                        1.0                                                                                                     *
    * @since                          2008/04/17                                                                                               *
    *********************************************************************************************/
    FUNCTION get_vertical_axis
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_tl_timeline IN tl_timeline.id_tl_timeline%TYPE,
        i_id_patient     IN NUMBER,
        o_error          OUT t_error_out,
        o_cursor_out     OUT pk_types.cursor_type
    ) RETURN BOOLEAN IS
        l_return BOOLEAN := TRUE;
    
        -- Institution software and market configuration variables
        l_institution institution.id_institution%TYPE;
        l_software    software.id_software%TYPE;
        l_market      market.id_market%TYPE;
    
        -- Get config cursor
        CURSOR c_config_ism IS
            SELECT tlv_aism.id_institution, tlv_aism.id_software, tlv_aism.id_market
              FROM tl_va_inst_soft_market tlv_aism
             WHERE tlv_aism.id_institution IN (0, i_prof.institution)
               AND tlv_aism.id_software IN (0, i_prof.software)
               AND tlv_aism.id_market IN (0, pk_core.get_inst_mkt(i_prof.institution))
             ORDER BY tlv_aism.id_institution DESC, tlv_aism.id_software DESC, tlv_aism.id_market DESC;
    
    BEGIN
        -- Get first line of cursor that will cotaign the configuration for the main query
        pk_alertlog.log_debug('Get configuration');
        g_error := 'GET VERTICAL AXIS CONFIG';
        OPEN c_config_ism;
        FETCH c_config_ism
            INTO l_institution, l_software, l_market;
        IF c_config_ism%NOTFOUND
        THEN
            g_error := 'NO TL_VA_INST_SOFT_MARKET CONFIGURATION';
            RAISE g_exception;
        END IF;
        CLOSE c_config_ism;
    
        -- Get output cursor
        pk_alertlog.log_debug('Get output cursor o_cursor_out');
        OPEN o_cursor_out FOR
            SELECT tls.id_tl_timeline id,
                   tls.id_tl_software id_software,
                   REPLACE(pk_translation.get_translation(i_lang, tls.code_tl_software), '<br>', ' ') code_softw,
                   tls.colour,
                   icon,
                   pk_sysconfig.get_config('TIMELINE_REPORT', i_prof.institution, tls.id_tl_software) id_report,
                   decode(nvl(l_count, 0), 0, 'N', 'Y') flg_show,
                   l_count,
                   pk_translation.get_translation(i_lang, s.code_software) || ':' multichoice_epis,
                   l_market,
                   l_software,
                   l_institution
              FROM tl_software tls
              JOIN tl_va_inst_soft_market tlv_aism
                ON (tlv_aism.id_tl_timeline = tls.id_tl_timeline AND tlv_aism.id_tl_software = tls.id_tl_software)
              LEFT JOIN software s
                ON s.id_software = tls.id_tl_software
              LEFT JOIN (SELECT COUNT(*) l_count, id_software
                           FROM tl_transaction_data td
                          WHERE id_patient = i_id_patient
                          GROUP BY id_software) td
                ON (td.id_software = tls.id_tl_software)
             WHERE tls.id_tl_timeline = i_id_tl_timeline
               AND l_market = tlv_aism.id_market
               AND l_software = tlv_aism.id_software
               AND l_institution = tlv_aism.id_institution
               and tlv_aism.flg_available=pk_alert_constant.g_yes
             ORDER BY tlv_aism.rank ASC;
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_VERTICAL_AXIS',
                                              o_error);
            pk_types.open_my_cursor(o_cursor_out);
            RETURN FALSE;
        
    END;

    /*************************************************************************************
    * GET_EPISODES                    Função que devolve a informação relativa a episodios                                                                         *
    *                                                                                                                                          *
    * @param I_LANG                   ID da linguagem para traduções                                                                           *
    * @param I_PROF                   Vector com a informação relativa  ao profissional, instituição e software                                *
    * @param I_PATIENT                Número de blocos de informação pedidos                                                                   *
    * @param O_EPISODE                Info about episodes                                                                                      *
    *                                                                                                                                          *
    *                                                                                                                                          *
    * @return                         Devolve false em caso de erro e true caso contrário                                                      *
    *                                                                                                                                          *
    * @raises                         Erro genérico de oracle                                                                                  *
    *                                                                                                                                          *
    * @author                         Carlos Vieira                                                                                            *
    * @version                        1.0                                                                                                     *
    * @since                          2008/05/26                                                                                               *
    ***********************************************************************************/
    FUNCTION get_episodes
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN NUMBER,
        id_tl_scale IN NUMBER,
        i_episode   IN NUMBER DEFAULT 0,
        o_episode   OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        user_exception EXCEPTION;
        --
        l_return                     BOOLEAN := TRUE;
        g_error                      VARCHAR2(4000);
        l_date_begin                 DATE;
        l_date_end                   DATE;
        l_intersected_intervals      NUMBER(6);
        l_software                   software.id_software%TYPE;
        l_parent_episode             episode.id_episode%TYPE;
        l_last_date_begin            DATE;
        l_last_date_end              DATE;
        l_last_date_first_obs        DATE;
        l_last_date_last_interaction DATE;
        l_format varchar2(0050 char);
    
        CURSOR c_get_episodes IS
            SELECT id_software,
                   id_patient,
                   id_transaction id_episode,
                   CAST(dt_begin_tstz at TIME ZONE(pk_timeline_core.g_tl_timezone) AS DATE) date_begin,
                   CAST(dt_end_tstz at TIME ZONE(pk_timeline_core.g_tl_timezone) AS DATE) date_end,
                   CAST(dt_first_obs_tstz at TIME ZONE(pk_timeline_core.g_tl_timezone) AS DATE) date_first_obs,
                   CAST(dt_last_interaction_tstz at TIME ZONE(pk_timeline_core.g_tl_timezone) AS DATE) date_last_interaction
              FROM tl_transaction_data td
             WHERE id_patient = i_patient
               AND td.id_transaction >= decode(i_episode, 0, td.id_transaction, i_episode)
             ORDER BY id_software, date_begin;
        rec_get_episodes c_get_episodes%ROWTYPE;
        l_same_parent    BOOLEAN := TRUE;
        -- truncate_dates
        PROCEDURE truncate_dates(id_tl_scale NUMBER) IS
            i_format_mask VARCHAR2(100);
        BEGIN
            IF id_tl_scale = pk_alert_constant.g_decade
            THEN
                i_format_mask := g_format_mask_year;
                --YEAR
            ELSIF id_tl_scale = pk_alert_constant.g_year
            THEN
                i_format_mask := g_format_mask_short_month;
                -- MONTH
            ELSIF id_tl_scale = pk_alert_constant.g_month
            THEN
                i_format_mask := g_format_mask_short_day;
                --WEEK
            ELSIF id_tl_scale = pk_alert_constant.g_week
            THEN
                --DAY
                i_format_mask := g_format_mask_short_day;
            ELSIF id_tl_scale = pk_alert_constant.g_day
            THEN
                i_format_mask := g_format_mask_short_hour;
            END IF;
            --
            l_last_date_begin            := trunc(rec_get_episodes.date_begin, i_format_mask);
            l_last_date_end              := trunc(rec_get_episodes.date_end, i_format_mask);
            l_last_date_first_obs        := trunc(rec_get_episodes.date_first_obs, i_format_mask);
            l_last_date_last_interaction := trunc(rec_get_episodes.date_last_interaction, i_format_mask);
        
        END truncate_dates;
    
    BEGIN
        -- Initialize timeline
        pk_alertlog.log_debug('CALL initialize');
        IF NOT pk_timeline_core.initialize(i_lang, i_prof, o_error)
        THEN
            g_error := pk_message.get_message(i_lang, 'TL_INITIALIZE');
            RAISE user_exception;
        END IF;
    
        pk_alertlog.log_debug('Mark 1');
        g_tab_inters_interval.delete;
        OPEN c_get_episodes;
        FETCH c_get_episodes
            INTO rec_get_episodes;
        l_date_begin            := nvl(rec_get_episodes.date_begin, rec_get_episodes.date_first_obs);
        l_date_end              := nvl(nvl(rec_get_episodes.date_end, rec_get_episodes.date_last_interaction),
                                       nvl(rec_get_episodes.date_begin, rec_get_episodes.date_first_obs));
        l_intersected_intervals := 1;
        l_parent_episode        := rec_get_episodes.id_episode;
        l_software              := rec_get_episodes.id_software;
    
        g_tab_inters_interval.extend;
        truncate_dates(id_tl_scale);
        g_tab_inters_interval(g_tab_inters_interval.last) := tl_intersect_interval(l_parent_episode,
                                                                                   rec_get_episodes.id_software,
                                                                                   rec_get_episodes.id_episode,
                                                                                   rec_get_episodes.date_begin,
                                                                                   rec_get_episodes.date_end,
                                                                                   rec_get_episodes.date_first_obs,
                                                                                   rec_get_episodes.date_last_interaction,
                                                                                   l_last_date_begin,
                                                                                   l_last_date_end,
                                                                                   l_last_date_first_obs,
                                                                                   l_last_date_last_interaction,
                                                                                   l_intersected_intervals);
    
        LOOP
            FETCH c_get_episodes
                INTO rec_get_episodes;
            EXIT WHEN c_get_episodes%NOTFOUND;
            truncate_dates(id_tl_scale);
        
            CASE id_tl_scale
                WHEN pk_alert_constant.g_decade THEN
                    l_format := g_format_mask_year;
                WHEN pk_alert_constant.g_year THEN
                    l_format := g_format_mask_month;
                WHEN pk_alert_constant.g_month THEN
                    l_format := g_format_mask_day;
                WHEN pk_alert_constant.g_week THEN
                    l_format := g_format_mask_day;
                WHEN pk_alert_constant.g_day THEN
                    l_format := g_format_mask_hour;
                ELSE
                    l_format := NULL;
            END CASE;
        
            l_same_parent := (nvl(to_number(to_char(rec_get_episodes.date_begin, l_format)),
                                  to_number(to_char(rec_get_episodes.date_first_obs, l_format))) BETWEEN
                             to_number(to_char(l_date_begin, l_format)) AND to_number(to_char(l_date_end, l_format))) AND
                             l_software = rec_get_episodes.id_software;
        
            /*
            IF id_tl_scale = pk_alert_constant.g_decade
            THEN
                pk_alertlog.log_debug('GET_DECADE_CURSOR');
            
                      l_same_parent := (nvl(to_number(to_char(rec_get_episodes.date_begin, g_format_mask_year)),
                        to_number(to_char(rec_get_episodes.date_first_obs, g_format_mask_year)))
                   
                   BETWEEN to_number(to_char(l_date_begin, g_format_mask_year)) AND
                   to_number(to_char(l_date_end, g_format_mask_year)))
                         AND l_software = rec_get_episodes.id_software;
                
                --YEAR
            ELSIF id_tl_scale = pk_alert_constant.g_year
            THEN
                pk_alertlog.log_debug('GET_YEAR_CURSOR');
                      l_same_parent := nvl(to_number(to_char(rec_get_episodes.date_begin, g_format_mask_month)),
                       to_number(to_char(rec_get_episodes.date_first_obs, g_format_mask_month)))
                  
                   BETWEEN to_number(to_char(l_date_begin, g_format_mask_month)) AND
                   to_number(to_char(l_date_end, g_format_mask_month))
                         AND l_software = rec_get_episodes.id_software;
            
                -- MONTH
            ELSIF id_tl_scale = pk_alert_constant.g_month
            THEN
                pk_alertlog.log_debug('GET_MONTH_CURSOR');
                      l_same_parent := nvl(to_number(to_char(rec_get_episodes.date_begin, g_format_mask_day)),
                       to_number(to_char(rec_get_episodes.date_first_obs, g_format_mask_day)))
                  
                   BETWEEN to_number(to_char(l_date_begin, g_format_mask_day)) AND
                   to_number(to_char(l_date_end, g_format_mask_day))
                         AND l_software = rec_get_episodes.id_software;
            
                --WEEK
            ELSIF id_tl_scale = pk_alert_constant.g_week
            THEN
                      l_same_parent := nvl(to_number(to_char(rec_get_episodes.date_begin, g_format_mask_day)),
                       to_number(to_char(rec_get_episodes.date_first_obs, g_format_mask_day)))
                  
                   BETWEEN to_number(to_char(l_date_begin, g_format_mask_day)) AND
                   to_number(to_char(l_date_end, g_format_mask_day))
                         AND l_software = rec_get_episodes.id_software;
            
                pk_alertlog.log_debug('GET_WEEK_CURSOR');
                --DAY
            ELSIF id_tl_scale = pk_alert_constant.g_day
            THEN
                pk_alertlog.log_debug('GET_DAY_CURSOR');
                      l_same_parent := nvl(to_number(to_char(rec_get_episodes.date_begin, g_format_mask_hour)),
                       to_number(to_char(rec_get_episodes.date_first_obs, g_format_mask_hour)))
                  
                   BETWEEN to_number(to_char(l_date_begin, g_format_mask_hour)) AND
                   to_number(to_char(l_date_end, g_format_mask_hour))
                         AND l_software = rec_get_episodes.id_software;
                END IF;
            
            */
        
            IF l_same_parent
            THEN
                l_intersected_intervals := l_intersected_intervals + 1;
                IF nvl(nvl(rec_get_episodes.date_end, rec_get_episodes.date_last_interaction),
                       nvl(rec_get_episodes.date_begin, rec_get_episodes.date_first_obs)) > l_date_end
                THEN
                    l_date_end := nvl(nvl(rec_get_episodes.date_end, rec_get_episodes.date_last_interaction),
                                      nvl(rec_get_episodes.date_begin, rec_get_episodes.date_first_obs));
                END IF;
            ELSE
                l_same_parent    := TRUE;
                l_parent_episode := rec_get_episodes.id_episode;
                l_date_begin     := nvl(rec_get_episodes.date_begin, rec_get_episodes.date_first_obs);
                l_date_end       := nvl(nvl(rec_get_episodes.date_end, rec_get_episodes.date_last_interaction),
                                        nvl(rec_get_episodes.date_begin, rec_get_episodes.date_first_obs));
            
            END IF;
            l_software := rec_get_episodes.id_software;
            g_tab_inters_interval.extend;
            g_tab_inters_interval(g_tab_inters_interval.last) := tl_intersect_interval(l_parent_episode,
                                                                                       rec_get_episodes.id_software,
                                                                                       rec_get_episodes.id_episode,
                                                                                       rec_get_episodes.date_begin,
                                                                                       rec_get_episodes.date_end,
                                                                                       rec_get_episodes.date_first_obs,
                                                                                       rec_get_episodes.date_last_interaction,
                                                                                       l_last_date_begin,
                                                                                       l_last_date_end,
                                                                                       l_last_date_first_obs,
                                                                                       l_last_date_last_interaction,
                                                                                       l_intersected_intervals);
        
        END LOOP;
        CLOSE c_get_episodes;
        --
        --
        OPEN o_episode FOR
            SELECT id_parent_episode,
                   id_software,
                   id_episode,
                   to_char(date_begin, pk_alert_constant.g_date_hour_send_format) date_begin,
                   to_char(date_end, pk_alert_constant.g_date_hour_send_format) date_end,
                   to_char(date_first_obs, pk_alert_constant.g_date_hour_send_format) date_first_obs,
                   to_char(date_last_interaction, pk_alert_constant.g_date_hour_send_format) date_last_interaction,
                   to_char(trunc_date_begin, pk_alert_constant.g_date_hour_send_format) trunc_date_begin,
                   to_char(trunc_date_end, pk_alert_constant.g_date_hour_send_format) trunc_date_end,
                   to_char(trunc_date_first_obs, pk_alert_constant.g_date_hour_send_format) trunc_date_first_obs,
                   to_char(trunc_date_last_interaction, pk_alert_constant.g_date_hour_send_format) trunc_date_last_interaction,
                   number_intersected_int
              FROM (TABLE(g_tab_inters_interval));
        RETURN l_return;
    EXCEPTION
        WHEN user_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPISODES',
                                              'U',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_episode);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPISODES',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_episode);
            RETURN FALSE;
        
    END get_episodes;

    /***************************************************************************************
    *GET_EPISODES Função que devolve a informação relativa a episodios                                                                         *
    *                                                                                                                                          *
    * @param I_LANG                   ID da linguagem para traduções                                                                           *
    * @param I_PROF                   Vector com a informação relativa  ao profissional, instituição e software                                *
    * @param I_PATIENT                Número de blocos de informação pedidos                                                                   *
    * @param I_EPISODE                Número de blocos de informação pedidos                                                                   *
    * @param O_EPISODE                ID do episodio a partir do qual a informação será retornada                                                                   *
    *                                                                                                                                          *
    *                                                                                                                                          *
    * @return                         Devolve false em caso de erro e true caso contrário                                                      *
    *                                                                                                                                          *
    * @raises                         Erro genérico de oracle                                                                                  *
    *                                                                                                                                          *
    * @author                         Carlos Vieira                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2008/05/26                                                                                               *
    *******************************************************************************/
    FUNCTION get_episodes
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN NUMBER,
        id_tl_scale IN NUMBER,
        o_episode   OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        g_error VARCHAR2(4000);
    BEGIN
        IF NOT get_episodes(i_lang, i_prof, i_patient, id_tl_scale, 0, o_episode, o_error)
        THEN
            RAISE no_data_found;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPISODES',
                                              o_error);
            pk_types.open_my_cursor(o_episode);
            RETURN FALSE;
    END;

    /**********************************************************************************************
    *GET_MULTICHOICE_DATA Output the multichoice lables and values                                                                             *
    *                                                                                                                                          *
    * @param I_PROF                   Profissional, institution and software ID's                                                              *
    * @param I_LANG                   Language id                                                                                              *
    * @param I_ID_TIMELINE            Timeline ID                                                                                              *
    * @param I_ID_EPISODE             Episode ID                                                                                               *
    * @param I_ID_PATIENT             Patient ID                                                                                               *
    * @param I_ID_TL_SCALE            Scale ID                                                                                               *
    * @param O_DT_PRESENT             Present date                                                                                             *
    * @param O_DT_MOST_RECENT_EPIS    Most recent episode date                                                                                 *
    * @param O_DT_PREVIUS_EPISODE     previus episode date                                                                                     *
    * @param O_DT_NEXT_EPISODE        next episode date                                                                                        *
    * @param O_EPISODE_PREVIOUS       id previous episode                                                                                 *
    * @param O_EPISODE_NEXT           id next episode                                                                                   *
    * @param O_EPISODE_MOST_RECENT    id most recent episode                                                                                     *
    * @param O_ERROR                  output error                                                                                             *
    *                                                                                                                                          *
    *                                                                                                                                          *
    * @return                         Return false if exist an error and true otherwise                                                        *
    *                                                                                                                                          *
    * @raises                         Raise an exception in generic oracle error                                                               *
    *                                                                                                                                          *
    * @author                         Carlos Vieira                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2008/04/30                                                                                               *
    **************************************************************************/
    FUNCTION get_multichoice_data
    (
        i_prof                IN profissional,
        i_lang                IN language.id_language%TYPE,
        i_id_timeline         IN NUMBER,
        i_id_episode          IN NUMBER,
        i_id_patient          IN NUMBER,
        i_id_tl_scale         IN NUMBER,
        o_dt_present          OUT VARCHAR2,
        o_dt_most_recent_epis OUT VARCHAR2,
        o_dt_previus_episode  OUT VARCHAR2,
        o_dt_next_episode     OUT VARCHAR2,
        o_episode_previous    OUT NUMBER,
        o_episode_next        OUT NUMBER,
        o_episode_most_recent OUT NUMBER,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_return                   BOOLEAN := TRUE;
        g_error                    VARCHAR2(4000);
        l_episode                  pk_types.cursor_type;
        l_id_parent_episode        episode.id_episode%TYPE;
        l_id_parent_episode_actual episode.id_episode%TYPE;
    
        CURSOR c_most_recent IS
            SELECT to_char(e.dt_begin_tstz, pk_alert_constant.g_date_hour_send_format),
                   e.id_episode id_episode_most_recent
              FROM episode e, epis_info ei, tl_software ts
             WHERE e.id_patient = i_id_patient
               AND e.flg_status != g_flg_cancel
               AND e.flg_ehr = g_flg_normal
               AND e.dt_begin_tstz <= CAST(current_timestamp AS TIMESTAMP WITH LOCAL TIME ZONE)
               AND ts.id_tl_software = ei.id_software
               AND ei.id_episode = e.id_episode
             ORDER BY e.dt_begin_tstz DESC;
    
        CURSOR c_previus_episode IS
            SELECT to_char(e.dt_begin_tstz, pk_alert_constant.g_date_hour_send_format),
                   e.id_episode id_episode_previous
              FROM episode e, epis_info ei, tl_software ts
             WHERE e.id_patient = i_id_patient
               AND e.flg_status != g_flg_cancel
               AND e.flg_ehr = g_flg_normal
               AND e.dt_begin_tstz <= CAST(current_timestamp AS TIMESTAMP WITH LOCAL TIME ZONE)
               AND e.id_episode < i_id_episode
               AND ts.id_tl_software = ei.id_software
               AND ei.id_episode = e.id_episode
             ORDER BY e.dt_begin_tstz DESC;
    
        CURSOR c_next_episode IS
            SELECT to_char(e.dt_begin_tstz, pk_alert_constant.g_date_hour_send_format)
              FROM episode e, epis_info ei, tl_software ts
             WHERE e.id_patient = i_id_patient
               AND e.id_episode = l_id_parent_episode
               AND e.flg_status != g_flg_cancel
               AND e.flg_ehr = g_flg_normal
               AND e.id_episode > i_id_episode
               AND ts.id_tl_software = ei.id_software
               AND ei.id_episode = e.id_episode
             ORDER BY e.dt_begin_tstz ASC;
    
        user_exception EXCEPTION;
    
    BEGIN
    
        --initialize retirar apos ser chamado do flash
        pk_alertlog.log_debug('initialize');
        IF NOT pk_timeline_core.initialize(i_lang, i_prof, o_error)
        THEN
            g_error := pk_message.get_message(i_lang, 'TL_INITIALIZE');
            RAISE user_exception;
        END IF;
    
        pk_alertlog.log_debug('o_dt_present');
    
        o_dt_present := to_char(current_timestamp, pk_alert_constant.g_date_hour_send_format);
    
        pk_alertlog.log_debug('o_dt_most_recent_epis');
        OPEN c_most_recent;
        FETCH c_most_recent
            INTO o_dt_most_recent_epis, o_episode_most_recent;
        CLOSE c_most_recent;
    
        pk_alertlog.log_debug('o_dt_previus_episode');
        OPEN c_previus_episode;
        FETCH c_previus_episode
            INTO o_dt_previus_episode, o_episode_previous;
        CLOSE c_previus_episode;
    
        pk_alertlog.log_debug('o_dt_next_episode');
        IF NOT get_episodes(i_lang, i_prof, i_id_patient, i_id_tl_scale, i_id_episode, l_episode, o_error)
        THEN
            RAISE user_exception;
            RETURN FALSE;
        END IF;
    
        IF i_id_timeline = 1
        THEN
            -- ID Parent episode
            FOR i IN g_tab_inters_interval.first .. g_tab_inters_interval.last
            LOOP
                IF g_tab_inters_interval(i) . id_episode = i_id_episode
                THEN
                    l_id_parent_episode_actual := g_tab_inters_interval(i).id_parent_episode;
                    EXIT;
                END IF;
            END LOOP;
            l_id_parent_episode := g_dummy_short_number;
        
            --Previous episode
            FOR i IN g_tab_inters_interval.first .. g_tab_inters_interval.last
            LOOP
                IF g_tab_inters_interval(i).id_episode < i_id_episode
                    AND g_tab_inters_interval(i).id_episode = g_tab_inters_interval(i).id_parent_episode
                THEN
                    IF g_tab_inters_interval(i).id_parent_episode < l_id_parent_episode_actual
                    THEN
                        IF g_tab_inters_interval(i).id_parent_episode > l_id_parent_episode
                        THEN
                            l_id_parent_episode := g_tab_inters_interval(i).id_parent_episode;
                        END IF;
                    END IF;
                END IF;
            END LOOP;
        
            IF l_id_parent_episode = g_dummy_short_number
            THEN
                o_episode_next := NULL;
            ELSE
                o_episode_next := l_id_parent_episode;
                OPEN c_next_episode;
                FETCH c_next_episode
                    INTO o_dt_next_episode;
                CLOSE c_next_episode;
            END IF;
            --Next episode
            l_id_parent_episode := g_dummy_big_number;
            FOR i IN g_tab_inters_interval.first .. g_tab_inters_interval.last
            LOOP
                IF g_tab_inters_interval(i).id_episode > i_id_episode
                    AND g_tab_inters_interval(i).id_episode = g_tab_inters_interval(i).id_parent_episode
                THEN
                    IF g_tab_inters_interval(i).id_parent_episode > l_id_parent_episode_actual
                    THEN
                        IF g_tab_inters_interval(i).id_parent_episode < l_id_parent_episode
                        THEN
                            l_id_parent_episode := g_tab_inters_interval(i).id_parent_episode;
                        END IF;
                    END IF;
                END IF;
            END LOOP;
        
            IF l_id_parent_episode = g_dummy_big_number
            THEN
                o_episode_next := NULL;
            ELSE
                o_episode_next := l_id_parent_episode;
                OPEN c_next_episode;
                FETCH c_next_episode
                    INTO o_dt_next_episode;
                CLOSE c_next_episode;
            END IF;
        END IF;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN user_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_MULTICHOICE_DATA',
                                              'U',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_MULTICHOICE_DATA',
                                              o_error);
            RETURN FALSE;
    END get_multichoice_data;

    /***********************************************************************************
    * Name:                           GET_TL_TASKS
    * Description:                    Function that return the list of available tasks in table TL_TASK for current timeline and professional
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional information Vector: (professional ID, institution ID, software ID)
    * @param I_ID_TL_TIMELINE         Timeline ID: 1-Episode timeline; 2-Task timeline
    * @param O_TL_TASKS               Cursor with information about available tasks in selected task timeline for current professional
    * @param O_ERROR                  Error information
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value I_ID_TL_TIMELINE         {*} '1' Episode timeline {*} '2' Task timeline
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/03/27
    *********************************************************************************/
    FUNCTION get_tl_tasks
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_tl_timeline IN tl_timeline.id_tl_timeline%TYPE,
        o_tl_tasks       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name       VARCHAR2(200) := 'GET_TL_TASKS';
        l_id_profile_template NUMBER(24);
        user_exception EXCEPTION;
    BEGIN
        --
        g_error := 'GET PROFILE TEMPLATE';
        pk_alertlog.log_debug('GET l_id_prof_template');
        --IF THIS CALL RETURM FALSE PRESENTS AN ERROR MESSAGE
        IF NOT pk_clinical_notes.get_profile_template(i_lang, i_prof, l_id_profile_template, o_error)
        THEN
            g_error := 'PROFESSIONAL NEED A PROFILE';
            RAISE user_exception;
        END IF;
    
        --
        g_error := 'GET LIST OF TASKS AVAILABLE IN TASK TIMELINE';
        pk_alertlog.log_debug('OPEN o_tl_tasks');
        OPEN o_tl_tasks FOR
            SELECT ttk.id_tl_task,
                   pk_translation.get_translation(i_lang, ttk.code_tl_task) tl_task_name,
                   nvl(tte.flg_default_value, ttt.flg_default_value) flg_default_value,
                   ttk.layer,
                   ttk.icon,
                   ttk.default_back_color,
                   nvl(tte.rank, nvl(ttt.rank, ttk.rank)) final_rank
              FROM tl_task ttk
             INNER JOIN tl_task_timeline ttt
                ON (ttt.id_tl_task = ttk.id_tl_task)
              FULL OUTER JOIN tl_task_timeline_exception tte
                ON (tte.id_tl_timeline = ttt.id_tl_timeline AND tte.id_profile_template = ttt.id_profile_template AND
                   tte.id_tl_task = ttt.id_tl_task)
             WHERE ttt.id_tl_timeline = i_id_tl_timeline
               AND ttt.id_profile_template = l_id_profile_template
               AND ttt.flg_available = pk_alert_constant.g_yes
               AND (tte.flg_available IS NULL OR tte.flg_available = pk_alert_constant.g_yes)
             ORDER BY final_rank, tte.rank, ttt.rank, ttk.rank;
    
        RETURN TRUE;
    EXCEPTION
        WHEN user_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              'U',
                                              o_error);
            pk_types.open_my_cursor(o_tl_tasks);
            RETURN FALSE;
            --
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_tl_tasks);
            RETURN FALSE;
    END get_tl_tasks;

    /************************************************************************************
    * GET_PATIENTS_TASKS              Function that returns all the information that should be sent to FLASH concerning TASK TIMELINE functionality (internal function)
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPISODE_LIST           TABLE_NUMBER with all ID_EPISODE that should be searched in Task Timeline information (available episodes in current grid)
    * @param I_VISIT_LIST             TABLE_NUMBER with all ID_VISIT that should be searched in Task Timeline information (available visits in current grid)
    * @param I_PATIENT_LIST           TABLE_NUMBER with all ID_PATIENT that should be searched in Task Timeline information (available patients in current grid)
    * @param I_TL_TASK_LIST           TABLE_NUMBER with all ID_TL_TASK that should be searched in Task Timeline information (available TL_TASKS in current institution)
    * @param I_ID_TL_TIMELINE         Timeline ID (This variable should always be 2 - "Task Timeline")
    * @param I_ID_TL_SCALE            Timeline Scales ID
    * @param I_PROFILE_TEMPLATE       Profile template ID from current professional
    * @param O_DATE_SERVER            Parameter that returns current server date as a VARCHAR2
    * @param O_PATIENTS_TASK          Cursor that returns available tasks for current visit's and available tl_task's
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value I_ID_TL_TIMELINE         {*} '1' Episode timeline {*} '2' Task timeline
    * @value I_ID_TL_SCALE            {*} '7' Shift (variable duration) {*} '5' Day {*} '4' Week
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS" and "user_exception"
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/04/02
    ***************************************************************************/
    FUNCTION get_patients_tasks
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode_list     IN table_number DEFAULT NULL,
        i_visit_list       IN table_number DEFAULT NULL,
        i_patient_list     IN table_number DEFAULT NULL,
        i_tl_task_list     IN table_number DEFAULT NULL,
        i_id_tl_timeline   IN tl_timeline.id_tl_timeline%TYPE,
        i_id_tl_scale      IN NUMBER,
        i_profile_template IN profile_template.id_profile_template%TYPE,
        o_patients_tasks   OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        g_error           VARCHAR2(4000);
        l_function_name   VARCHAR2(200) := 'GET_PATIENTS_TASKS';
        l_format_mask     VARCHAR2(100);
        l_hidri_task_desc VARCHAR2(200) := pk_translation.get_translation(i_lang, 'TL_TASK.CODE_TL_TASK.3');
        l_dt_day_begin    task_timeline_ea.dt_begin%TYPE;
        --
        -- truncate_dates
        PROCEDURE truncate_dates(id_tl_scale NUMBER) IS
            i_format_mask VARCHAR2(100);
        BEGIN
            IF id_tl_scale = pk_alert_constant.g_decade
            THEN
                i_format_mask := g_format_mask_year;
                --YEAR
            ELSIF id_tl_scale = pk_alert_constant.g_year
            THEN
                i_format_mask := g_format_mask_short_month;
                -- MONTH
            ELSIF id_tl_scale = pk_alert_constant.g_month
            THEN
                i_format_mask := g_format_mask_short_day;
                --WEEK
            ELSIF id_tl_scale = pk_alert_constant.g_week
            THEN
                --DAY
                i_format_mask := g_format_mask_short_day;
            ELSIF id_tl_scale = pk_alert_constant.g_day
            THEN
                --HOUR
                i_format_mask := g_format_mask_short_hour;
            ELSIF id_tl_scale = pk_alert_constant.g_shift
            THEN
                --HOUR
                i_format_mask := g_format_mask_short_hour;
            END IF;
            --
            l_format_mask := i_format_mask;
        END truncate_dates;
    
    BEGIN
        --
        pk_alertlog.log_debug('Truncate dates');
        truncate_dates(i_id_tl_scale);
    
        --
        l_dt_day_begin := pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, NULL);

        pk_alertlog.log_debug('GET O_PATIENTS_TASKS INFORMATION');
        --    
        OPEN o_patients_tasks FOR
            SELECT res.id_tl_task,
                   res.task_identifier,
                   res.id_episode id_episode_origin,
                   res.id_visit,
                   res.id_patient,
                   res.layer,
                   (SELECT pk_date_utils.date_send_tsz(i_lang, res.date_begin, i_prof)
                      FROM dual) date_begin,
                   (SELECT pk_date_utils.date_send_tsz(i_lang, res.date_end, i_prof)
                      FROM dual) date_end,
                   --
                   decode(res.is_to_show_hour,
                          pk_alert_constant.g_yes,
                          (SELECT pk_date_utils.to_char_insttimezone(i_lang,
                                                                     i_prof,
                                                                     res.date_begin,
                                                                     g_format_mask_task_time)
                             FROM dual),
                          NULL) task_begin_label,
                   (SELECT pk_date_utils.to_char_insttimezone(i_lang, i_prof, res.date_end, g_format_mask_task_time)
                      FROM dual) task_end_label,
                   --
                   (SELECT pk_date_utils.date_send_tsz(i_lang, trunc(res.date_begin, l_format_mask), i_prof)
                      FROM dual) trunc_date_begin,
                   (SELECT pk_date_utils.date_send_tsz(i_lang, trunc(res.date_end, l_format_mask), i_prof)
                      FROM dual) trunc_date_end,
                   res.desc_task,
                   res.icon,
                   res.info_icon,
                   res.id_episode_req id_episode
            --
              FROM (SELECT /*+opt_estimate(table,t_vis,scale_rows=0.1)*/ /*+opt_estimate(table,t_epi,scale_rows=0.1)*/
                     tte.id_task_refid task_identifier,
                     tte.id_tl_task,
                     tte.id_patient,
                     tte.id_episode,
                     tte.id_visit,
                     tte.id_institution,
                     tte.dt_req date_req,
                     tte.id_prof_req,
                     tte.dt_begin date_begin,
                     tte.dt_end date_end,
                     tte.flg_status_req,
                     tte.table_name,
                     tte.status_str,
                     tte.status_msg,
                     tte.status_icon,
                     tte.status_flg,
                     CASE
                          WHEN dbms_lob.getlength(tte.universal_desc_clob) > 0 THEN
                           (SELECT pk_translation.get_translation(i_lang, tt.code_tl_task)
                              FROM dual) || ' - ' || tte.universal_desc_clob
                          ELSE
                           CASE
                               WHEN tte.id_tl_task = pk_prog_notes_constants.g_task_medic_here THEN
                                to_clob(pk_api_pfh_in.get_prod_desc_by_presc(i_lang, i_prof, tte.id_task_refid))
                               ELSE
                                to_clob((SELECT pk_translation.get_translation(i_lang, tte.code_description)
                                          FROM dual))
                           END
                      
                      END desc_task,
                     tt.icon,
                     decode(tte.status_flg,
                            'X',
                            NULL,
                            (SELECT pk_sysdomain.get_img(i_lang, tte.status_icon, tte.status_flg)
                               FROM dual)) info_icon,
                     decode(tte.id_tl_task,
                            pk_prog_notes_constants.g_task_surgery,
                            0,
                            pk_prog_notes_constants.g_task_schedule_inp,
                            0,
                            pk_prog_notes_constants.g_task_prev_dischage_dt,
                            0,
                            NULL) layer,
                     t_epi.column_value id_episode_req,
                     pk_alert_constant.g_yes is_to_show_hour
                      FROM tl_task tt
                     INNER JOIN task_timeline_ea tte
                        ON (tt.id_tl_task = tte.id_tl_task)
                     INNER JOIN TABLE(i_visit_list) t_vis
                        ON (t_vis.column_value = tte.id_visit AND
                           tte.flg_show_method = pk_alert_constant.g_tl_oriented_visit)
                     INNER JOIN episode epi
                        ON (epi.id_visit = t_vis.column_value)
                     INNER JOIN TABLE(i_episode_list) t_epi
                        ON (t_epi.column_value = epi.id_episode)
                    INNER JOIN TABLE(i_tl_task_list) t_t
                        ON tte.id_tl_task = t_t.column_value                        
                     WHERE tte.flg_outdated = 0
                       AND tte.flg_sos <> pk_alert_constant.g_yes
                          --Temporary code: till the adaptation of hidrics and positionings in the task_timeline_ea to be used in TASK TIMELINE
                       AND tte.id_tl_task NOT IN
                           (pk_prog_notes_constants.g_task_positioning, pk_prog_notes_constants.g_task_intake_output)

                    --
                    UNION ALL
                    --
                    SELECT /*+opt_estimate(table,t_vis,scale_rows=0.0001)*/
                     tte.id_task_refid task_identifier,
                     tte.id_tl_task,
                     tte.id_patient,
                     tte.id_episode,
                     tte.id_visit,
                     tte.id_institution,
                     tte.dt_req date_req,
                     tte.id_prof_req,
                     tte.dt_begin date_begin,
                     tte.dt_end date_end,
                     tte.flg_status_req,
                     tte.table_name,
                     tte.status_str,
                     tte.status_msg,
                     tte.status_icon,
                     tte.status_flg,
                     CASE
                         WHEN dbms_lob.getlength(tte.universal_desc_clob) > 0 THEN
                          (SELECT pk_translation.get_translation(i_lang, tt.code_tl_task)
                             FROM dual) || ' - ' || tte.universal_desc_clob
                         ELSE
                          CASE
                              WHEN tte.id_tl_task = pk_prog_notes_constants.g_task_medic_here THEN
                               to_clob(pk_api_pfh_in.get_prod_desc_by_presc(i_lang, i_prof, tte.id_task_refid))
                              ELSE
                               to_clob((SELECT pk_translation.get_translation(i_lang, tte.code_description)
                                         FROM dual))
                          END
                     END desc_task,
                     tt.icon,
                     (SELECT pk_sysdomain.get_img(i_lang, tte.status_icon, tte.status_flg)
                        FROM dual) info_icon,
                     decode(tte.id_tl_task,
                            pk_prog_notes_constants.g_task_surgery,
                            0,
                            pk_prog_notes_constants.g_task_schedule_inp,
                            0,
                            pk_prog_notes_constants.g_task_prev_dischage_dt,
                            0,
                            NULL) layer,
                     t_vis.column_value id_episode_req,
                     pk_alert_constant.g_yes is_to_show_hour
                      FROM tl_task tt
                     INNER JOIN task_timeline_ea tte
                        ON (tt.id_tl_task = tte.id_tl_task)
                     INNER JOIN TABLE(i_episode_list) t_vis
                        ON (t_vis.column_value = tte.id_episode AND
                           tte.flg_show_method = pk_alert_constant.g_tl_oriented_episode)
                    INNER JOIN TABLE(i_tl_task_list) t_t
                        ON tte.id_tl_task = t_t.column_value                           
                     WHERE tte.flg_outdated = 0
                       AND tte.flg_sos <> pk_alert_constant.g_yes
                          --Temporary code: till the adaptation of hidrics and positionings in the task_timeline_ea to be used in TASK TIMELINE
                       AND tte.id_tl_task NOT IN
                           (pk_prog_notes_constants.g_task_positioning, pk_prog_notes_constants.g_task_intake_output)
                                    
                    --                    
                    UNION ALL
                    --                    
                    SELECT info_pat.*, epi.id_episode id_episode_req, pk_alert_constant.g_yes is_to_show_hour
                      FROM episode epi
                     INNER JOIN (SELECT /*+opt_estimate(table,t_vis,scale_rows=0.0001)*/
                                 tte.id_task_refid task_identifier,
                                 tte.id_tl_task,
                                 tte.id_patient,
                                 tte.id_episode,
                                 tte.id_visit,
                                 tte.id_institution,
                                 tte.dt_req date_req,
                                 tte.id_prof_req,
                                 tte.dt_begin date_begin,
                                 tte.dt_end date_end,
                                 tte.flg_status_req,
                                 tte.table_name,
                                 tte.status_str,
                                 tte.status_msg,
                                 tte.status_icon,
                                 tte.status_flg,
                                 CASE
                                      WHEN dbms_lob.getlength(tte.universal_desc_clob) > 0 THEN
                                       (SELECT pk_translation.get_translation(i_lang, tt.code_tl_task)
                                          FROM dual) || ' - ' || tte.universal_desc_clob
                                      ELSE
                                       CASE
                                           WHEN tte.id_tl_task = pk_prog_notes_constants.g_task_medic_here THEN
                                            to_clob(pk_api_pfh_in.get_prod_desc_by_presc(i_lang, i_prof, tte.id_task_refid))
                                           ELSE
                                            to_clob((SELECT pk_translation.get_translation(i_lang, tte.code_description)
                                                      FROM dual))
                                       END
                                  END desc_task,
                                 tt.icon,
                                 (SELECT pk_sysdomain.get_img(i_lang, tte.status_icon, tte.status_flg)
                                    FROM dual) info_icon,
                                 decode(tte.id_tl_task,
                                        pk_prog_notes_constants.g_task_surgery,
                                        0,
                                        pk_prog_notes_constants.g_task_schedule_inp,
                                        0,
                                        pk_prog_notes_constants.g_task_prev_dischage_dt,
                                        0,
                                        NULL) layer
                                  FROM tl_task tt
                                 INNER JOIN task_timeline_ea tte
                                    ON (tt.id_tl_task = tte.id_tl_task)
                                 INNER JOIN TABLE(i_patient_list) t_vis
                                    ON (t_vis.column_value = tte.id_patient AND
                                       tte.flg_show_method = pk_alert_constant.g_tl_oriented_patient)
                                 INNER JOIN TABLE(i_tl_task_list) t_t
                                    ON tte.id_tl_task = t_t.column_value                                          
                                 WHERE tte.dt_begin >= l_dt_day_begin
                                   AND tte.flg_outdated = 0
                                   AND tte.flg_sos <> pk_alert_constant.g_yes
                                      --Temporary code: till the adaptation of hidrics and positionings in the task_timeline_ea to be used in TASK TIMELINE
                                   AND tte.id_tl_task NOT IN
                                       (pk_prog_notes_constants.g_task_positioning,
                                        pk_prog_notes_constants.g_task_intake_output)) info_pat
                        ON (epi.id_patient = info_pat.id_patient)
                     WHERE epi.id_episode IN (SELECT *
                                                FROM TABLE(i_episode_list))
                                            
                    --
                    UNION ALL
                    --
                    -- THIS BLOCK OF CODE IS TEMPORARY
                    SELECT /*+opt_estimate(table,t_vis,scale_rows=0.0001)*/
                     epp.id_epis_positioning_plan task_identifier,
                     pk_prog_notes_constants.g_task_positioning id_tl_task,
                     NULL id_patient,
                     ep.id_episode id_episode,
                     epi.id_visit id_visit,
                     epi.id_institution,
                     ep.dt_creation_tstz date_req,
                     ep.id_professional id_prof_req,
                     epp.dt_prev_plan_tstz date_begin,
                     NULL date_end,
                     epp.flg_status flg_status_req,
                     pk_alert_constant.g_tl_table_name_posit table_name,
                     NULL status_str,
                     NULL status_msg,
                     NULL status_icon,
                     NULL status_flg,
                     to_clob((SELECT (SELECT pk_translation.get_translation(i_lang, p.code_positioning)
                                       FROM dual)
                               FROM positioning p
                              INNER JOIN epis_positioning_det epd1
                                 ON (p.id_positioning = epd1.id_positioning)
                              WHERE p.flg_available = pk_alert_constant.g_yes
                                AND epd1.id_epis_positioning_det = epp.id_epis_positioning_next)) desc_task,
                     g_posit_icon icon,
                     NULL info_icon,
                     NULL layer,
                     t_vis.column_value id_episode_req,
                     pk_alert_constant.g_yes is_to_show_hour
                      FROM epis_positioning ep
                     INNER JOIN epis_positioning_det epd
                        ON (ep.id_epis_positioning = epd.id_epis_positioning)
                     INNER JOIN epis_positioning_plan epp
                        ON (epd.id_epis_positioning_det = epp.id_epis_positioning_det)
                     INNER JOIN episode epi
                        ON (epi.id_episode = ep.id_episode)
                     INNER JOIN TABLE(i_episode_list) t_vis
                        ON (t_vis.column_value = ep.id_episode)
                     WHERE epp.flg_status = g_epis_posit_plan_flg_e
                       AND ep.flg_status IN (g_epis_posit_flg_statu_e, g_epis_posit_flg_statu_r)
                    --
                    UNION ALL
                    --
                    -- This union get HIDRICS tasks
                    -- THIS BLOCK OF CODE IS TEMPORARY
                    SELECT hidrics.task_identifier,
                           pk_prog_notes_constants.g_task_intake_output id_tl_task,
                           hidrics.id_patient,
                           hidrics.id_episode,
                           hidrics.id_visit,
                           hidrics.id_institution,
                           hidrics.date_req,
                           hidrics.id_prof_req,
                           hidrics.dt_begin,
                           hidrics.date_end,
                           hidrics.flg_status_req,
                           pk_alert_constant.g_tl_table_name_hidrics table_name,
                           NULL status_str,
                           NULL status_msg,
                           NULL status_icon,
                           NULL status_flg,
                           to_clob(l_hidri_task_desc) desc_task,
                           g_hidrics_icon icon,
                           hidrics.info_icon,
                           NULL layer,
                           hidrics.id_episode_req,
                           hidrics.is_to_show_hour
                      FROM (SELECT /*+opt_estimate(table,t_epi,scale_rows=0.1)*/ /*+opt_estimate(table,t_vis,scale_rows=0.01)*/
                             eh.id_epis_hidrics task_identifier,
                             NULL id_patient,
                             eh.id_episode id_episode,
                             epi.id_visit id_visit,
                             epi.id_institution,
                             eh.dt_creation_tstz date_req,
                             eh.id_professional id_prof_req,
                             decode(eh.id_hidrics_interval,
                                     -1,
                                     CASE
                                         WHEN eh.dt_initial_tstz > current_timestamp THEN
                                          eh.dt_initial_tstz
                                         ELSE
                                          current_timestamp
                                     END,
                                     decode(ehb.flg_status,
                                            pk_inp_hidrics_constant.g_epis_hidric_r,
                                            (nvl(pk_inp_hidrics.get_dt_next_balance(i_lang, i_prof, eh.id_epis_hidrics),
                                                 eh.dt_initial_tstz)),
                                            pk_inp_hidrics_constant.g_epis_hidric_e,
                                            nvl(pk_inp_hidrics.get_dt_next_balance(i_lang, i_prof, eh.id_epis_hidrics),
                                                eh.dt_initial_tstz))) dt_begin,
                             eh.dt_end_tstz date_end,
                             eh.flg_status flg_status_req,
                             t_epi.column_value id_episode_req,
                             decode(eh.id_hidrics_interval, -1, g_hidrics_icon) info_icon,
                             decode(eh.id_hidrics_interval,
                                    -1,
                                    decode(eh.dt_end_tstz, NULL, pk_alert_constant.g_no, pk_alert_constant.g_yes),
                                    pk_alert_constant.g_yes) is_to_show_hour
                            
                              FROM (SELECT MAX(ehb1.id_epis_hidrics_balance) max_balance, eh1.id_epis_hidrics
                                      FROM epis_hidrics_balance ehb1, epis_hidrics eh1
                                     WHERE eh1.id_episode IN
                                           (SELECT epi.id_episode
                                              FROM episode epi
                                             WHERE epi.id_visit IN (SELECT /*+opt_estimate(table,t,scale_rows=0.0001)*/
                                                                     t.column_value
                                                                      FROM TABLE(i_visit_list) t))
                                       AND eh1.id_epis_hidrics = ehb1.id_epis_hidrics
                                     GROUP BY eh1.id_epis_hidrics) ehb2
                             INNER JOIN epis_hidrics_balance ehb
                                ON (ehb.id_epis_hidrics_balance = ehb2.max_balance AND
                                   ehb.id_epis_hidrics = ehb2.id_epis_hidrics)
                             INNER JOIN epis_hidrics eh
                                ON (eh.id_epis_hidrics = ehb2.id_epis_hidrics)
                             INNER JOIN hidrics_interval hi
                                ON (hi.id_hidrics_interval = eh.id_hidrics_interval)
                             INNER JOIN hidrics_type ht
                                ON (ht.id_hidrics_type = eh.id_hidrics_type)
                             INNER JOIN episode epi
                                ON (epi.id_episode = eh.id_episode)
                             INNER JOIN TABLE(i_visit_list) t_vis
                                ON (t_vis.column_value = epi.id_visit)
                             INNER JOIN episode epi2
                                ON (epi2.id_visit = t_vis.column_value)
                             INNER JOIN TABLE(i_episode_list) t_epi
                                ON (t_epi.column_value = epi2.id_episode)
                             WHERE eh.flg_status IN ('R', 'E')) hidrics -- (Required, In execution)
                    ) res;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_patients_tasks);
            RETURN FALSE;
        
    END get_patients_tasks;

    /********************************************************************************
    * GET_patients_tasks              Function that returns all the information that should be sent to FLASH concerning TASK TIMELINE functionality (function to be call by FLASH)
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPISODE_LIST           TABLE_NUMBER with all ID_EPISODE that should be searched in Task Timeline information (available visits in current grid)
    * @param I_VISIT_LIST             TABLE_NUMBER with all ID_VISIT that should be searched in Task Timeline information (available visits in current grid)
    * @param I_PATIENT_LIST           TABLE_NUMBER with all ID_PATIENT that should be searched in Task Timeline information (available patients in current grid)
    * @param I_TL_TASK_LIST           TABLE_NUMBER with all ID_TL_TASK that should be searched in Task Timeline information (available TL_TASKS in current institution)
    * @param I_ID_TL_TIMELINE         Timeline ID (This variable should always be 2 - "Task Timeline")
    * @param I_ID_TL_SCALE            Timeline Scales ID
    * @param O_DATE_SERVER            Parameter that returns current server date as a VARCHAR2
    * @param O_PATIENTS_TASK          Cursor that returns available tasks for current visit's and available tl_task's
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value I_ID_TL_TIMELINE         {*} '1' Episode timeline {*} '2' Task timeline
    * @value I_ID_TL_SCALE            {*} '7' Shift (variable duration) {*} '5' Day {*} '4' Week
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS" and "user_exception"
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/04/02
    *******************************************************************************/
    FUNCTION get_patients_tasks
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode_list   IN table_number DEFAULT NULL,
        i_visit_list     IN table_number DEFAULT NULL,
        i_patient_list   IN table_number DEFAULT NULL,
        i_tl_task_list   IN table_number DEFAULT NULL,
        i_id_tl_timeline IN tl_timeline.id_tl_timeline%TYPE,
        i_id_tl_scale    IN NUMBER,
        o_date_server    OUT VARCHAR2,
        o_patients_tasks OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        g_error               VARCHAR2(4000);
        l_function_name       VARCHAR2(200) := 'GET_PATIENTS_TASKS';
        l_id_profile_template profile_template.id_profile_template%TYPE;
        user_exception EXCEPTION;
    BEGIN
        --
        g_error := 'VALIDATE PARAMETERS';
        IF i_lang IS NULL
           OR i_prof IS NULL
           OR i_visit_list IS NULL
           OR i_tl_task_list IS NULL
           OR i_id_tl_timeline IS NULL
           OR i_id_tl_scale IS NULL
        THEN
            g_error := 'INVALID PARAMETERS';
            RAISE user_exception;
        END IF;
        --
        g_error := 'GET PROFILE TEMPLATE';
        pk_alertlog.log_debug('GET l_id_prof_template');
        --IF THIS CALL RETURN FALSE, PRESENTS AN ERROR MESSAGE
        IF NOT pk_clinical_notes.get_profile_template(i_lang, i_prof, l_id_profile_template, o_error)
        THEN
            g_error := 'PROFESSIONAL NEED A PROFILE';
            RAISE user_exception;
        END IF;
    
        pk_alertlog.log_debug('CALL get_patients_tasks');
        g_error := 'CALL GET_PATIENTS_TASKS';
        IF NOT get_patients_tasks(i_lang             => i_lang,
                                  i_prof             => i_prof,
                                  i_episode_list     => i_episode_list,
                                  i_visit_list       => i_visit_list,
                                  i_patient_list     => i_patient_list,
                                  i_tl_task_list     => i_tl_task_list,
                                  i_id_tl_timeline   => i_id_tl_timeline,
                                  i_id_tl_scale      => i_id_tl_scale,
                                  i_profile_template => l_id_profile_template,
                                  o_patients_tasks   => o_patients_tasks,
                                  o_error            => o_error)
        THEN
            RAISE no_data_found;
        END IF;
        --
        pk_alertlog.log_debug('GET O_DATE_SERVER INFORMATION');
        g_error       := 'GET O_DATE_SERVER INFORMATION';
        o_date_server := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
        --
    
        RETURN TRUE;
    EXCEPTION
        WHEN user_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              'U',
                                              o_error);
            pk_types.open_my_cursor(o_patients_tasks);
            RETURN FALSE;
            --
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_patients_tasks);
            RETURN FALSE;
    END get_patients_tasks;

    /*******************************************************************************************************************************************
    * GET_TASKS_SHORTCUTS             Function that returns information about the id_shortcut related with each id_tl_task (task timeline)
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param O_TL_TASKS_SHORTCUTS     Cursor that returns shortcuts (and identifier) for all diferent types of tasks existent in task timeline functionality
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS" and "user_exception"
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/07/01
    *******************************************************************************************************************************************/
    FUNCTION get_tasks_shortcuts
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        o_tl_tasks_shortcuts OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        g_error VARCHAR2(4000);
        l_task  table_index_data;
        --
        l_shortcuts  table_number := table_number();
        l_id_tl_task table_number := table_number();
        i            PLS_INTEGER := 1;
        l_access     pk_types.cursor_type;
        --  l_parent     table_number;
        l_parent         pk_types.cursor_type;
        g_found          BOOLEAN;
        l_id_parent      sys_button_prop.id_sys_button_prop%TYPE;
        l_id_screen_area sys_screen_area.id_sys_screen_area%TYPE;
        --
        l_tl_tasks_shortcuts t_tl_tasks_shortcuts := t_tl_tasks_shortcuts(NULL, NULL);
        l_new_st             t_tbl_tl_tasks_shortcuts;
        l_rec_index          PLS_INTEGER := 0;
        l_admiss_inten       sys_shortcut.intern_name%TYPE;
        l_surg_inten         sys_shortcut.intern_name%TYPE;
        l_prof               professional.id_professional%TYPE;
    BEGIN
    
        BEGIN
            SELECT ppt.id_professional
              INTO l_prof
              FROM prof_profile_template ppt
             INNER JOIN profile_templ_access pta
                ON (pta.id_profile_template = ppt.id_profile_template)
             INNER JOIN sys_shortcut ss
                ON (ss.id_sys_shortcut = pta.id_sys_shortcut AND ss.id_shortcut_pk = pta.id_shortcut_pk)
             WHERE ppt.id_professional = i_prof.id
               AND ppt.id_software = i_prof.software
               AND ppt.id_institution = i_prof.institution
               AND ss.intern_name = pk_alert_constant.g_shortcut_admiss_inten_adm;
        EXCEPTION
            WHEN no_data_found THEN
                l_prof := NULL;
        END;
    
        IF l_prof IS NULL
        THEN
            l_admiss_inten := pk_alert_constant.g_shortcut_admiss_inten;
            l_surg_inten   := pk_alert_constant.g_shortcut_surg_inten;
        ELSE
            l_admiss_inten := pk_alert_constant.g_shortcut_admiss_inten_adm;
            l_surg_inten   := pk_alert_constant.g_shortcut_surg_inten_adm;
        END IF;
    
        l_new_st := t_tbl_tl_tasks_shortcuts();
    
        l_task := table_index_data(index_data(pk_prog_notes_constants.g_task_positioning,
                                              pk_alert_constant.g_shortcut_position_inten),
                                   index_data(pk_prog_notes_constants.g_task_intake_output,
                                              pk_alert_constant.g_shortcut_hidrics_inten),
                                   index_data(pk_prog_notes_constants.g_task_img_exams_req,
                                              pk_alert_constant.g_shortcut_exams_inten),
                                   index_data(pk_prog_notes_constants.g_task_other_exams_req,
                                              pk_alert_constant.g_shortcut_exams_inten),
                                   index_data(pk_prog_notes_constants.g_task_lab,
                                              pk_alert_constant.g_shortcut_analisys_inten),
                                   index_data(pk_prog_notes_constants.g_task_monitoring,
                                              pk_alert_constant.g_shortcut_monit_inten),
                                   index_data(pk_prog_notes_constants.g_task_medic_here,
                                              pk_alert_constant.g_shortcut_prescrip_inten),
                                   index_data(pk_prog_notes_constants.g_task_procedures,
                                              pk_alert_constant.g_shortcut_procedur_inten),
                                   index_data(pk_prog_notes_constants.g_task_transports,
                                              pk_alert_constant.g_shortcut_transp_inten),
                                   index_data(pk_prog_notes_constants.g_task_surgery, l_surg_inten),
                                   index_data(pk_prog_notes_constants.g_task_schedule_inp, l_admiss_inten),
                                   index_data(pk_prog_notes_constants.g_task_prev_dischage_dt, 'MEDICAL_DISCHARGE'));
    
        pk_alertlog.log_debug('Get tasks shortcuts and identifier');
    
        g_error := 'GET SHORTCUTS INFORMATION';
        SELECT shortcut, id_tl_task
          BULK COLLECT
          INTO l_shortcuts, l_id_tl_task
          FROM (SELECT /*+ CARDINALITY(task 12) */
                 t.id_sys_shortcut shortcut,
                 t.id id_tl_task,
                 row_number() over(PARTITION BY t.id ORDER BY t.id_institution DESC) rn
                  FROM (SELECT *
                          FROM TABLE(l_task) task
                          LEFT JOIN sys_shortcut ss
                            ON task.descr = ss.intern_name
                           AND ss.id_software = i_prof.software
                           AND ss.id_institution IN (0, i_prof.institution)
                         ORDER BY ss.id_parent DESC) t)
         WHERE rn = 1
         ORDER BY id_tl_task;
    
        FOR i IN l_id_tl_task.first .. l_id_tl_task.last
        LOOP
            IF NOT pk_access.get_shortcut(i_lang   => i_lang,
                                          i_prof   => i_prof,
                                          i_patient => null,
                                          i_episode => null,
                                          i_short  => l_shortcuts(i),
                                          o_access => l_access,
                                          o_prt    => l_parent,
                                          o_error  => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            FETCH l_parent
                INTO l_id_parent, l_id_screen_area;
            g_found := l_parent%FOUND;
        
            IF g_found = TRUE
            THEN
                l_new_st.extend;
                l_rec_index := l_rec_index + 1;
            
                l_tl_tasks_shortcuts.shortcut   := l_shortcuts(i);
                l_tl_tasks_shortcuts.id_tl_task := l_id_tl_task(i);
            
                l_new_st(l_rec_index) := l_tl_tasks_shortcuts;
            END IF;
        END LOOP;
    
        g_error := 'OPEN o_tl_tasks_shortcuts';
        OPEN o_tl_tasks_shortcuts FOR
            SELECT tl_shortcuts.shortcut, tl_shortcuts.id_tl_task
              FROM TABLE(CAST(l_new_st AS t_tbl_tl_tasks_shortcuts)) tl_shortcuts;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TASKS_SHORTCUTS',
                                              o_error);
            pk_types.open_my_cursor(o_tl_tasks_shortcuts);
            RETURN FALSE;
    END get_tasks_shortcuts;

    /***********************************************************************************
    * GET_DATES_DESCRIPTION           Function that returns date information to FLASH in the apropriate format (VARCHAR2)
    *                                 [Example: "12:33h - 14:50h (07-Jan-2009)" (example in portuguese date format)]
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_PARENTESIS             Indicates if day date should appear inside parentesis after hour
    * @param I_DT_BEGIN               Expected start date
    * @param I_DT_END                 Expected end date
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns STRING with date information if success, otherwise returns '' (empty string)
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/04/14
    *********************************************************************/
    FUNCTION get_dates_description
    (
        i_lang       language.id_language%TYPE,
        i_prof       profissional,
        i_parentesis IN VARCHAR2,
        i_dt_begin   IN VARCHAR2,
        i_dt_end     IN VARCHAR2
    ) RETURN VARCHAR2 IS
        --
        l_format_min_date_day sys_message.desc_message%TYPE := '';
        l_format_max_date_day sys_message.desc_message%TYPE := '';
        l_format_date_time    sys_message.desc_message%TYPE := '';
        l_format_date         sys_message.desc_message%TYPE := '';
        --
        l_min_date_section_str VARCHAR2(4000) := '';
        l_max_date_section_str VARCHAR2(4000) := '';
        l_session_summary      VARCHAR2(4000) := '';
        l_left_parentisis      VARCHAR2(1) := '(';
        l_right_parentisis     VARCHAR2(1) := ')';
    BEGIN
    
        -- Get summary information about current session.
        -- This information should be returned in parameter o_session_summary with the format:
        -- "12:33h - 14:50h (07-Jan-2009)" (example in portuguese date format)
    
        -- FORMAT INIT and END TIME
        l_format_date_time     := pk_message.get_message(i_lang, 'DATE_FORMAT_M010');
        l_min_date_section_str := pk_date_utils.to_char_insttimezone(i_lang, i_prof, i_dt_begin, l_format_date_time);
        l_max_date_section_str := pk_date_utils.to_char_insttimezone(i_lang, i_prof, i_dt_end, l_format_date_time);
    
        -- FORMAT INIT DAY
        -- Variable "l_format_min_date_day" get date (day) from the first note of this section in correct language format
        l_format_date         := pk_message.get_message(i_lang, 'DATE_FORMAT_M006');
        l_format_min_date_day := pk_date_utils.to_char_insttimezone(i_lang, i_prof, i_dt_begin, l_format_date);
    
        -- FORMAT END DAY
        -- Variable "l_format_max_date_day" get date (day) from the last note of this section in correct language format
        l_format_max_date_day := pk_date_utils.to_char_insttimezone(i_lang, i_prof, i_dt_end, l_format_date);
    
        -- IF date should present (or not) curve parentesis
        IF i_parentesis = 'N'
        THEN
            l_left_parentisis  := NULL;
            l_right_parentisis := NULL;
        END IF;
    
        -- Concatenate Final Session time and date information
        IF i_dt_end IS NULL -- IF there is only 1 date (dt_begin)
        THEN
            l_session_summary := l_min_date_section_str || 'h ' || l_left_parentisis || l_format_min_date_day ||
                                 l_right_parentisis;
        ELSE
            IF l_format_min_date_day = l_format_max_date_day -- IF first and last note were done in the same day
            THEN
                l_session_summary := l_min_date_section_str || 'h - ' || l_max_date_section_str || 'h ' ||
                                     l_left_parentisis || l_format_min_date_day || l_right_parentisis;
            ELSE
                -- IF first and last note were done in diferent days
                l_session_summary := l_min_date_section_str || 'h ' || l_left_parentisis || l_format_min_date_day ||
                                     l_right_parentisis || ' - ' || l_max_date_section_str || 'h ' || l_left_parentisis ||
                                     l_format_max_date_day || l_right_parentisis;
            END IF;
        END IF;
    
        RETURN l_session_summary;
    
    END get_dates_description;

    /****************************************************************************
    * GET_patient_tasks              Function that returns all the information that should be sent to FLASH concerning TASK TIMELINE functionality
    *                                  for only one patient (episode and visit)
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_EPISODE             ID_EPISODE that should be searched in Task Timeline information (available visits in current grid)
    * @param I_ID_VISIT               ID_VISIT that should be searched in Task Timeline information (available visits in current grid)
    * @param I_ID_PATIENT             ID_PATIENT that should be searched in Task Timeline information (available visits in current grid)
    * @param I_TL_TASK_LIST           TABLE_NUMBER with all ID_TL_TASK that should be searched in Task Timeline information (available TL_TASKS in current institution)
    * @param O_DATE_SERVER            Parameter that returns current server date as a VARCHAR2
    * @param O_PATIENTS_TASK          Cursor that returns available tasks for current visit's and available tl_task's
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/04/14
    **************************************************************/
    FUNCTION get_patient_tasks
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN task_timeline_ea.id_episode%TYPE DEFAULT NULL,
        i_id_visit      IN task_timeline_ea.id_visit%TYPE DEFAULT NULL,
        i_id_patient    IN task_timeline_ea.id_patient%TYPE DEFAULT NULL,
        i_tl_task_list  IN table_number DEFAULT NULL,
        o_date_server   OUT VARCHAR2,
        o_patient_tasks OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        g_error         VARCHAR2(4000);
        l_function_name VARCHAR2(200) := 'GET_PATIENT_TASKS';
        --
        l_institution_code   VARCHAR2(200) := 'AB_INSTITUTION.CODE_INSTITUTION.';
        l_flg_status_name    VARCHAR2(200) := '.FLG_STATUS';
        l_inform_detail_desc VARCHAR2(200);
        l_dt_day_begin       task_timeline_ea.dt_begin%TYPE;
        --
        l_label_viewer_exams VARCHAR2(200) := pk_message.get_message(i_lang, 'EHR_VIEWER_T175');
        l_label_viewer_analy VARCHAR2(200) := pk_message.get_message(i_lang, 'EHR_VIEWER_T176');
        l_label_viewer_presc VARCHAR2(200) := pk_message.get_message(i_lang, 'EHR_VIEWER_T177');
        l_label_viewer_proce VARCHAR2(200) := pk_message.get_message(i_lang, 'EHR_VIEWER_T178');
        --
        l_posit_task_desc VARCHAR2(200) := pk_translation.get_translation(i_lang, 'TL_TASK.CODE_TL_TASK.1');
        l_hidri_task_desc VARCHAR2(200) := pk_translation.get_translation(i_lang, 'TL_TASK.CODE_TL_TASK.3');
    
    BEGIN
        l_inform_detail_desc := pk_message.get_message(i_lang, 'INP_MAIN_GRID_CARDEX_T019');
        l_dt_day_begin       := pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, NULL);
    
        --
        -- Used tbl_temp because this table has all collumns indexed, so it is faster search results from an temporary 
        -- and indexed table, than CAST a TABLE_NUMBER to TABLE.
        pk_alertlog.log_debug('Insert registries in temporary table tbl_temp');
        DELETE FROM tbl_temp;
        insert_tbl_temp(i_num_1 => i_tl_task_list);
    
        --
        pk_alertlog.log_debug('GET O_PATIENT_TASKS INFORMATION');
        OPEN o_patient_tasks FOR
            SELECT CASE
                        WHEN dbms_lob.getlength(tte.universal_desc_clob) > 0 THEN
                         pk_translation.get_translation(i_lang, tt.code_tl_task) || ' - ' || tte.universal_desc_clob
                        ELSE
                         CASE
                             WHEN tte.id_tl_task = pk_prog_notes_constants.g_task_medic_here THEN
                              to_clob(pk_api_pfh_in.get_prod_desc_by_presc(i_lang, i_prof, tte.id_task_refid))
                             WHEN tte.id_tl_task = pk_prog_notes_constants.g_task_intake_output THEN
                              to_clob(pk_translation.get_translation(i_lang, tte.code_desc_group))
                             ELSE
                              to_clob(pk_translation.get_translation(i_lang, tte.code_description))
                         END
                    
                    END desc_task,
                   tte.id_task_refid task_identifier,
                   tt.icon,
                   tt.default_back_color,
                   get_dates_description(i_lang, i_prof, pk_alert_constant.g_no, tte.dt_begin, tte.dt_end) desc_date,
                   pk_date_utils.date_send_tsz(i_lang, tte.dt_begin, i_prof) date_begin,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, tte.id_prof_req) professional_name,
                   pk_translation.get_translation(i_lang, l_institution_code || tte.id_institution) institution,
                   decode(tte.id_tl_task,
                          pk_prog_notes_constants.g_task_surgery,
                          l_inform_detail_desc,
                          pk_prog_notes_constants.g_task_schedule_inp,
                          l_inform_detail_desc,
                          pk_prog_notes_constants.g_task_prev_dischage_dt,
                          l_inform_detail_desc,
                          pk_sysdomain.get_desc_domain_set(i_lang,
                                                           tte.table_name || l_flg_status_name,
                                                           tte.flg_status_req)) flg_status_description,
                   decode(tte.id_tl_task,
                          pk_prog_notes_constants.g_task_surgery,
                          pk_alert_constant.g_yes,
                          pk_prog_notes_constants.g_task_schedule_inp,
                          pk_alert_constant.g_yes,
                          pk_prog_notes_constants.g_task_prev_dischage_dt,
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_no) flg_informative_task,
                   decode(tte.id_tl_task,
                          pk_prog_notes_constants.g_task_medic_here,
                          pk_api_pfh_in.get_presc_status_icon(i_lang, i_prof, tte.id_task_refid),
                          pk_utils.get_status_string(i_lang,
                                                     i_prof,
                                                     tte.status_str,
                                                     tte.status_msg,
                                                     tte.status_icon,
                                                     tte.status_flg)) desc_status,
                   get_dates_description(i_lang, i_prof, pk_alert_constant.g_no, tte.dt_req, NULL) date_request,
                   pk_translation.get_translation(i_lang, tt.code_tl_task) desc_tl_task,
                   decode(tte.id_tl_task,
                          pk_prog_notes_constants.g_task_img_exams_req,
                          l_label_viewer_exams,
                          pk_prog_notes_constants.g_task_other_exams_req,
                          l_label_viewer_exams,
                          pk_prog_notes_constants.g_task_lab,
                          l_label_viewer_analy,
                          pk_prog_notes_constants.g_task_medic_here,
                          l_label_viewer_presc,
                          pk_prog_notes_constants.g_task_procedures,
                          l_label_viewer_proce,
                          NULL) associated_label,
                   decode(tte.id_tl_task,
                          pk_prog_notes_constants.g_task_img_exams_req,
                          pk_alert_constant.g_yes,
                          pk_prog_notes_constants.g_task_other_exams_req,
                          pk_alert_constant.g_yes,
                          pk_prog_notes_constants.g_task_lab,
                          pk_alert_constant.g_yes,
                          pk_prog_notes_constants.g_task_medic_here,
                          pk_alert_constant.g_yes,
                          pk_prog_notes_constants.g_task_procedures,
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_no) has_association,
                   tte.flg_type_viewer task_type,
                   tte.dt_begin dt_begin,
                   tte.flg_status_req flg_status,
                   tte.id_tl_task,
                   tte.id_episode id_episode_origin,
                   i_id_episode id_episode
              FROM tl_task tt
             INNER JOIN task_timeline_ea tte
                ON (tt.id_tl_task = tte.id_tl_task)
             WHERE (tte.id_visit = i_id_visit AND tte.flg_show_method = pk_alert_constant.g_tl_oriented_visit -- Filter id_visit that are available for current search (patient's grid)
                    OR tte.id_episode = i_id_episode AND tte.flg_show_method = pk_alert_constant.g_tl_oriented_episode -- Filter id_episode that are available for current search (patient's grid)
                   OR tte.id_patient = i_id_patient AND tte.flg_show_method = pk_alert_constant.g_tl_oriented_patient AND
                   tte.dt_begin >= l_dt_day_begin) -- Filter id_patient that are available for current search (patient's grid)
               AND EXISTS
             (SELECT 0 -- Filter id_tl_task that are available for current search (institution)
                      FROM tbl_temp ttmp
                     WHERE ttmp.num_1 = tte.id_tl_task)
               AND tte.flg_outdated = 0
               AND tte.flg_sos <> pk_alert_constant.g_yes
                  --Temporary code: till the adaptation of hidrics and positionings in the task_timeline_ea to be used in TASK TIMELINE
               AND tte.id_tl_task NOT IN
                   (pk_prog_notes_constants.g_task_positioning, pk_prog_notes_constants.g_task_intake_output)
            --
            UNION ALL
            --
            -- This union get POSITIONING tasks
            -- THIS BLOCK OF CODE IS TEMPORARY
            SELECT to_clob(pk_inp_positioning.get_all_posit_desc(i_lang, i_prof, ep.id_epis_positioning)) desc_task,
                   epp.id_epis_positioning_plan id_task_refid,
                   g_posit_icon icon,
                   NULL default_back_color,
                   get_dates_description(i_lang, i_prof, pk_alert_constant.g_no, epp.dt_prev_plan_tstz, NULL) desc_date,
                   pk_date_utils.date_send_tsz(i_lang, epp.dt_prev_plan_tstz, i_prof) date_begin,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ep.id_professional) professional_name,
                   pk_translation.get_translation(i_lang, l_institution_code || epi.id_institution) institution,
                   pk_sysdomain.get_desc_domain_set(i_lang,
                                                    pk_alert_constant.g_tl_table_name_posit || l_flg_status_name,
                                                    epp.flg_status) flg_status_description,
                   pk_alert_constant.g_no flg_informative_task,
                   pk_utils.get_status_string_immediate(i_lang,
                                                        i_prof,
                                                        g_image_value,
                                                        ep.flg_status,
                                                        pk_alert_constant.g_tl_table_name_posit || l_flg_status_name,
                                                        to_char(epp.dt_prev_plan_tstz,
                                                                pk_alert_constant.g_dt_yyyymmddhh24miss),
                                                        pk_alert_constant.g_tl_table_name_posit || l_flg_status_name,
                                                        NULL,
                                                        NULL,
                                                        NULL,
                                                        NULL,
                                                        NULL,
                                                        NULL,
                                                        current_timestamp) desc_status,
                   get_dates_description(i_lang, i_prof, pk_alert_constant.g_no, ep.dt_creation_tstz, NULL) date_request,
                   l_posit_task_desc desc_tl_task,
                   NULL associated_label,
                   pk_alert_constant.g_no has_association,
                   NULL task_type,
                   epp.dt_prev_plan_tstz dt_begin,
                   epp.flg_status,
                   pk_prog_notes_constants.g_task_positioning id_tl_task,
                   ep.id_episode id_episode_origin,
                   i_id_episode id_episode
              FROM epis_positioning ep
             INNER JOIN epis_positioning_det epd
                ON (ep.id_epis_positioning = epd.id_epis_positioning)
             INNER JOIN epis_positioning_plan epp
                ON (epd.id_epis_positioning_det = epp.id_epis_positioning_det)
             INNER JOIN episode epi
                ON (epi.id_episode = ep.id_episode)
             WHERE epp.flg_status = g_epis_posit_plan_flg_e
               AND ep.flg_status IN (g_epis_posit_flg_statu_e, g_epis_posit_flg_statu_r)
               AND ep.id_episode = i_id_episode
            --
            UNION ALL
            --
            -- This union get HIDRICS tasks
            -- THIS BLOCK OF CODE IS TEMPORARY
            SELECT to_clob(hidrics.desc_task) desc_task,
                   hidrics.id_task_refid,
                   g_hidrics_icon icon,
                   NULL default_back_color,
                   get_dates_description(i_lang, i_prof, pk_alert_constant.g_no, hidrics.dt_begin, NULL) desc_date,
                   pk_date_utils.date_send_tsz(i_lang, hidrics.dt_begin, i_prof) date_begin,
                   hidrics.professional_name,
                   hidrics.institution,
                   hidrics.flg_status_description,
                   pk_alert_constant.g_no flg_informative_task,
                   hidrics.desc_status,
                   hidrics.date_request,
                   l_hidri_task_desc desc_tl_task,
                   NULL associated_label,
                   pk_alert_constant.g_no has_association,
                   NULL task_type,
                   hidrics.dt_begin,
                   hidrics.flg_status,
                   pk_prog_notes_constants.g_task_intake_output id_tl_task,
                   hidrics.id_episode_origin,
                   i_id_episode id_episode
              FROM (SELECT pk_translation.get_translation(i_lang, ht.code_hidrics_type) desc_task,
                           eh.id_epis_hidrics id_task_refid,
                           decode(ehb.flg_status,
                                  'R',
                                  nvl(pk_inp_hidrics.get_dt_next_balance(i_lang, i_prof, eh.id_epis_hidrics),
                                      eh.dt_initial_tstz),
                                  'E',
                                  nvl(pk_inp_hidrics.get_dt_next_balance(i_lang, i_prof, eh.id_epis_hidrics),
                                      eh.dt_initial_tstz)) dt_begin,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, eh.id_professional) professional_name,
                           pk_translation.get_translation(i_lang, l_institution_code || epi.id_institution) institution,
                           pk_sysdomain.get_desc_domain_set(i_lang,
                                                            pk_alert_constant.g_tl_table_name_hidrics ||
                                                            l_flg_status_name,
                                                            eh.flg_status) flg_status_description,
                           pk_inp_hidrics.get_epis_status_string(i_lang, i_prof, eh.id_epis_hidrics) desc_status,
                           get_dates_description(i_lang, i_prof, pk_alert_constant.g_no, eh.dt_creation_tstz, NULL) date_request,
                           l_hidri_task_desc desc_tl_task,
                           pk_alert_constant.g_no has_association,
                           eh.flg_status,
                           eh.id_episode id_episode_origin
                      FROM (SELECT MAX(ehb1.id_epis_hidrics_balance) max_balance, eh1.id_epis_hidrics
                              FROM epis_hidrics_balance ehb1, epis_hidrics eh1
                             WHERE eh1.id_episode IN (SELECT epi.id_episode
                                                        FROM episode epi
                                                       WHERE epi.id_visit IN (i_id_visit))
                               AND eh1.id_epis_hidrics = ehb1.id_epis_hidrics
                             GROUP BY eh1.id_epis_hidrics) ehb2
                     INNER JOIN epis_hidrics_balance ehb
                        ON (ehb.id_epis_hidrics_balance = ehb2.max_balance AND
                           ehb.id_epis_hidrics = ehb2.id_epis_hidrics)
                     INNER JOIN epis_hidrics eh
                        ON (eh.id_epis_hidrics = ehb2.id_epis_hidrics)
                     INNER JOIN hidrics_interval hi
                        ON (hi.id_hidrics_interval = eh.id_hidrics_interval)
                     INNER JOIN hidrics_type ht
                        ON (ht.id_hidrics_type = eh.id_hidrics_type)
                     INNER JOIN episode epi
                        ON (epi.id_episode = eh.id_episode)
                     WHERE eh.flg_status IN (g_epis_hidrics_flg_sta_e, g_epis_hidrics_flg_sta_r)
                       AND epi.id_visit = i_id_visit
                     ORDER BY dt_begin) hidrics;
    
        pk_alertlog.log_debug('GET O_DATE_SERVER INFORMATION');
        g_error       := 'GET O_DATE_SERVER INFORMATION';
        o_date_server := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_patient_tasks);
            RETURN FALSE;
    END get_patient_tasks;

    /********************************************************************************************
    * Create for configuration of timeline verticla axis(softwares)
    *
    * @author                                  Rui Duarte
    * @version                                 0.1
    * @since                                   2010/11/09
    ********************************************************************************************/

    FUNCTION insert_into_tl_vertical_axis
    (
        i_tl_software    IN software.id_software%TYPE,
        i_rank           IN tl_va_inst_soft_market.rank%TYPE DEFAULT NULL,
        i_id_institution IN institution.id_institution%TYPE DEFAULT 0,
        i_id_software    IN software.id_software%TYPE DEFAULT 0,
        i_id_market      IN market.id_market%TYPE DEFAULT 0,
        i_flg_available  IN tl_va_inst_soft_market.flg_available%TYPE DEFAULT 'Y',
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name VARCHAR2(30) := 'INSERT_INTO_TL_VERTICAL_AXIS';
        l_lang          language.id_language%TYPE := 2; -- Olny used for error message in process_error
        l_id_timeline   tl_timeline.id_tl_timeline%TYPE := 1; -- Function only used for EHR episodes
        l_rank          tl_va_inst_soft_market.rank%TYPE;
    
    BEGIN
        g_error := 'INSERT_INTO_REPORT_SCOPE';
        -- if no rank is provided make rank sequencial
        IF i_rank IS NULL
        THEN
            SELECT COUNT(rank) + 1 new_rank
              INTO l_rank
              FROM tl_va_inst_soft_market tl_va_ism
             WHERE tl_va_ism.id_tl_timeline = l_id_timeline
               AND tl_va_ism.id_institution = i_id_institution
               AND tl_va_ism.id_software = i_id_software
               AND tl_va_ism.id_market = i_id_market;
        ELSE
            -- if rank is provided update rank value
            l_rank := i_rank;
        END IF;
    
        MERGE INTO tl_va_inst_soft_market tl_va_ism
        USING (SELECT i_tl_software    id_tl_software,
                      l_rank           rank,
                      i_id_institution id_institution,
                      i_id_software    id_software,
                      i_id_market      id_market
                 FROM dual) args
        ON (tl_va_ism.id_tl_timeline = l_id_timeline AND tl_va_ism.id_tl_software = args.id_tl_software AND tl_va_ism.id_institution = args.id_institution AND tl_va_ism.id_software = args.id_software AND tl_va_ism.id_market = args.id_market)
        WHEN MATCHED THEN
            UPDATE
               SET tl_va_ism.rank = i_rank, tl_va_ism.flg_available = i_flg_available
        WHEN NOT MATCHED THEN
            INSERT
                (--,
                 id_tl_timeline,
                 flg_available,
                 id_tl_software,
                 rank,
                 id_institution,
                 id_software,
                 id_market)
            VALUES
                (--sec_tl_va_ism.nextval,
                 l_id_timeline,
                 i_flg_available,
                 args.id_tl_software,
                 args.rank,
                 args.id_institution,
                 args.id_software,
                 args.id_market);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(l_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            RETURN FALSE;
    END insert_into_tl_vertical_axis;

    /*******************************************************************************************************************************************
    * GET_patient_tasks_pdms          Function that returns all the information that should be sent to FLASH concerning TASK TIMELINE functionality
    *                                 for only one patient (episode and visit)
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_EPISODE             ID_EPISODE that should be searched in Task Timeline information (available visits in current grid)
    * @param I_ID_VISIT               ID_VISIT that should be searched in Task Timeline information (available visits in current grid)
    * @param I_TL_TASK_LIST           TABLE_NUMBER with all ID_TL_TASK that should be searched in Task Timeline information (available TL_TASKS in current institution)
    * @param O_DATE_SERVER            Parameter that returns current server date as a VARCHAR2
    * @param O_PATIENTS_TASK          Cursor that returns available tasks for current visit's and available tl_task's
    * @param O_CUR_LAST_INFO          Cursor that returns the last identifier for each task
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Luís Maia
    * @version                        2.6.0.4
    * @since                          2010/09/27
    * @dependencies                   PDMS
    *******************************************************************************************************************************************/
    FUNCTION get_patient_tasks_pdms
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN task_timeline_ea.id_episode%TYPE DEFAULT NULL,
        i_id_visit      IN task_timeline_ea.id_visit%TYPE DEFAULT NULL,
        i_tl_task_list  IN table_number DEFAULT NULL,
        i_flg_method    IN VARCHAR2,
        i_dt_start      IN VARCHAR2,
        i_dt_end        IN VARCHAR2,
        o_date_server   OUT VARCHAR2,
        o_patient_tasks OUT pk_types.cursor_type,
        o_cur_last_info OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_last_info t_timeline_pdms_last_table;
    
        g_error         VARCHAR2(4000);
        l_function_name VARCHAR2(200) := 'GET_PATIENT_TASKS_PDMS';
    
        l_institution_code   VARCHAR2(200) := 'AB_INSTITUTION.CODE_INSTITUTION.';
        l_code_analysis_name VARCHAR2(200) := 'ANALYSIS.CODE_ANALYSIS.';
        l_harvest_table_name VARCHAR2(200) := 'HARVEST';
        l_flg_status_name    VARCHAR2(200) := '.FLG_STATUS';
        l_flg_exam_ref       VARCHAR2(200) := 'EXAM_REQ_DET.FLG_REFERRAL';
        l_inform_detail_desc VARCHAR2(200);
        l_mon_plan_table     VARCHAR2(100) := 'MONITORIZATION_VS_PLAN';
    
        l_dt_start task_timeline_ea.dt_begin%TYPE;
        l_dt_end   task_timeline_ea.dt_end%TYPE;
    
        l_label_viewer_exams VARCHAR2(200) := pk_message.get_message(i_lang, 'EHR_VIEWER_T175');
        l_label_viewer_analy VARCHAR2(200) := pk_message.get_message(i_lang, 'EHR_VIEWER_T176');
        l_label_viewer_presc VARCHAR2(200) := pk_message.get_message(i_lang, 'EHR_VIEWER_T177');
        l_label_viewer_proce VARCHAR2(200) := pk_message.get_message(i_lang, 'EHR_VIEWER_T178');
    
        l_posit_task_desc VARCHAR2(200) := pk_translation.get_translation(i_lang, 'TL_TASK.CODE_TL_TASK.1');
        l_lab_task_desc   VARCHAR2(200) := pk_translation.get_translation(i_lang, 'TL_TASK.CODE_TL_TASK.5');
    
        l_yes_no VARCHAR2(20) := 'YES_NO';
    
    BEGIN
        l_inform_detail_desc := pk_message.get_message(i_lang, 'INP_MAIN_GRID_CARDEX_T019');
    
        l_dt_start := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_start, NULL);
        l_dt_end   := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_end, NULL);
    
        pk_alertlog.log_debug('GET L_LAST_INFO');
    
        SELECT t_timeline_pdms_last(tx.id_task_refid, tx.id_tl_task) BULK COLLECT
         INTO l_last_info
         FROM (SELECT ttex.id_task_refid id_task_refid,
                      ttex.id_tl_task    id_tl_task,
                      row_number() over(PARTITION BY ttex.id_tl_task ORDER BY
                      CASE
                           WHEN (ttex.id_tl_task = pk_prog_notes_constants.g_task_transports AND ttex.flg_status_req IN ('R'))
                                OR (ttex.id_tl_task IN
                                (pk_prog_notes_constants.g_task_img_exams_req, pk_prog_notes_constants.g_task_other_exams_req) AND
                                ttex.flg_status_req IN ('R', 'D'))
                                OR (ttex.id_tl_task = pk_prog_notes_constants.g_task_lab AND ttex.flg_status_req IN ('R', 'D'))
                                OR (ttex.id_tl_task = pk_prog_notes_constants.g_task_procedures AND ttex.flg_status_req IN ('D', 'R')) THEN
                            to_number(to_char(ttex.dt_begin, 'yyyymmddhh24miss'))
                           ELSE
                            1000000000000000 + to_number(to_char(ttex.dt_begin, 'yyyymmddhh24miss')) - 99991231000000
                       END ASC) rn
                 FROM (SELECT tte.id_task_refid  id_task_refid,
                              tte.id_tl_task     id_tl_task,
                              tte.dt_begin       dt_begin,
                              tte.flg_status_req flg_status_req
                         FROM task_timeline_ea tte
                        WHERE tte.id_visit = i_id_visit
                          AND tte.id_tl_task IN (pk_prog_notes_constants.g_task_img_exams_req,
                                                 pk_prog_notes_constants.g_task_other_exams_req,
                                                 pk_prog_notes_constants.g_task_lab,
                                                 pk_prog_notes_constants.g_task_procedures,
                                                 pk_prog_notes_constants.g_task_transports)
                          AND tte.id_tl_task IN (SELECT *
                                                   FROM TABLE(i_tl_task_list))
                          AND tte.dt_begin IS NOT NULL
                       UNION ALL
                       SELECT h.id_harvest                            id_task_refid,
                              pk_prog_notes_constants.g_task_lab id_tl_task,
                              h.dt_harvest_tstz                       dt_begin,
                              h.flg_status                            flg_status_req
                         FROM harvest h
                         JOIN analysis_harvest ah
                           ON ah.id_harvest = h.id_harvest
                         JOIN analysis_req_det ard
                           ON ard.id_analysis_req_det = ah.id_analysis_req_det
                        WHERE h.id_visit = i_id_visit
                          AND ard.flg_status NOT IN
                              (pk_alert_constant.g_analysis_det_canc, pk_alert_constant.g_analysis_det_result)
                          AND h.flg_status = pk_alert_constant.g_harvest_harv) ttex
               UNION ALL
               -- monitoring
               SELECT p.id_monitorization_vs_plan               id_task_refid,
											pk_prog_notes_constants.g_task_monitoring id_tl_task,
											row_number() over(PARTITION BY pk_prog_notes_constants.g_task_monitoring ORDER BY
											CASE
													WHEN (p.flg_status IN (pk_alert_constant.g_monitor_vs_exec, pk_alert_constant.g_monitor_vs_pend)) THEN
													 to_number(to_char(mon_vs.dt_monitorization_vs_tstz, 'yyyymmddhh24miss'))
													ELSE
													 1000000000000000 + to_number(to_char(mon_vs.dt_monitorization_vs_tstz, 'yyyymmddhh24miss')) - 99991231000000
											END ASC) rn
                 FROM monitorization mon
                INNER JOIN monitorization_vs mon_vs
                   ON (mon_vs.id_monitorization = mon.id_monitorization)
                 JOIN monitorization_vs_plan p
                   ON p.id_monitorization_vs = mon_vs.id_monitorization_vs
                 JOIN episode epi
                   ON (epi.id_episode = mon.id_episode)
                WHERE epi.id_visit = i_id_visit
                  AND p.flg_status NOT IN (pk_alert_constant.g_monitor_vs_canc, pk_alert_constant.g_monitor_vs_draft)
               UNION ALL
               -- positioning
               SELECT epp.id_epis_positioning_plan               id_task_refid,
											pk_prog_notes_constants.g_task_positioning id_tl_task,
											row_number() over(PARTITION BY pk_prog_notes_constants.g_task_monitoring 
											ORDER BY  
											CASE
													WHEN (epp.flg_status IN (g_epis_posit_plan_flg_e)) THEN
													 to_number(to_char(decode(epp.dt_execution_tstz, NULL, epp.dt_prev_plan_tstz, epp.dt_execution_tstz),
																						 'yyyymmddhh24miss'))
													ELSE
													 1000000000000000 +
													 to_number(to_char(decode(epp.dt_execution_tstz, NULL, epp.dt_prev_plan_tstz, epp.dt_execution_tstz),
																						 'yyyymmddhh24miss')) - 99991231000000
											END ASC) rn
                 FROM epis_positioning ep
                INNER JOIN rotation_interval ri
                   ON (ep.id_rotation_interval = ri.id_rotation_interval)
                INNER JOIN epis_positioning_det epd
                   ON (ep.id_epis_positioning = epd.id_epis_positioning)
                INNER JOIN epis_positioning_plan epp
                   ON (epd.id_epis_positioning_det = epp.id_epis_positioning_det)
                INNER JOIN episode epi
                   ON (epi.id_episode = ep.id_episode)
                WHERE epp.flg_status IN (g_epis_posit_plan_flg_e, g_epis_posit_plan_flg_f)
                  AND ep.flg_status IN (g_epis_posit_flg_statu_e,
                                        g_epis_posit_flg_statu_r,
                                        g_epis_posit_flg_statu_f,
                                        g_epis_posit_flg_statu_i)
                  AND epi.id_visit = i_id_visit) tx
        WHERE tx.rn = 1;
    
        OPEN o_cur_last_info FOR
            SELECT *
              FROM TABLE(l_last_info);
    
        pk_alertlog.log_debug('GET O_PATIENT_TASKS INFORMATION');
        OPEN o_patient_tasks FOR
            SELECT CASE
                        WHEN dbms_lob.getlength(tte.universal_desc_clob) > 0 THEN
                         pk_translation.get_translation(i_lang, tt.code_tl_task) || ' - ' || tte.universal_desc_clob
                        ELSE
                         CASE
                             WHEN tte.id_tl_task = pk_prog_notes_constants.g_task_medic_here THEN
                              to_clob(pk_api_pfh_in.get_prod_desc_by_presc(i_lang, i_prof, tte.id_task_refid))
                             ELSE
                              to_clob(pk_translation.get_translation(i_lang, tte.code_description))
                         END
                    END desc_task,
                   tte.id_task_refid task_identifier,
                   NULL task_parent,
                   tt.icon,
                   tt.default_back_color,
                   get_dates_description(i_lang, i_prof, pk_alert_constant.g_no, tte.dt_begin, tte.dt_end) desc_date,
                   pk_date_utils.date_send_tsz(i_lang, tte.dt_begin, i_prof) date_begin,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, tte.id_prof_req) professional_name,
                   pk_translation.get_translation(i_lang, l_institution_code || tte.id_institution) institution,
                   CASE
                        WHEN tte.id_tl_task = pk_prog_notes_constants.g_task_surgery THEN
                         l_inform_detail_desc
                        WHEN tte.id_tl_task = pk_prog_notes_constants.g_task_schedule_inp THEN
                         l_inform_detail_desc
                        WHEN tte.id_tl_task = pk_prog_notes_constants.g_task_prev_dischage_dt THEN
                         l_inform_detail_desc
                        WHEN tte.id_tl_task = pk_prog_notes_constants.g_task_img_exams_req
                             OR tte.id_tl_task = pk_prog_notes_constants.g_task_other_exams_req THEN
                         CASE
                             WHEN erd.flg_referral IS NULL THEN
                              pk_sysdomain.get_desc_domain_set(i_lang, tte.table_name || l_flg_status_name, tte.flg_status_req)
                             ELSE
                              pk_sysdomain.get_desc_domain_set(i_lang, l_flg_exam_ref, erd.flg_referral)
                         END
                        ELSE
                         pk_sysdomain.get_desc_domain_set(i_lang, tte.table_name || l_flg_status_name, tte.flg_status_req)
                    END flg_status_description,
                   decode(tte.id_tl_task,
                          pk_prog_notes_constants.g_task_surgery,
                          pk_alert_constant.g_yes,
                          pk_prog_notes_constants.g_task_schedule_inp,
                          pk_alert_constant.g_yes,
                          pk_prog_notes_constants.g_task_prev_dischage_dt,
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_no) flg_informative_task,
                   decode(tte.id_tl_task,
                          pk_prog_notes_constants.g_task_medic_here,
                          pk_api_pfh_in.get_presc_status_icon(i_lang, i_prof, tte.id_task_refid),
                          pk_utils.get_status_string(i_lang,
                                                     i_prof,
                                                     tte.status_str,
                                                     tte.status_msg,
                                                     tte.status_icon,
                                                     tte.status_flg)) desc_status,
                   get_dates_description(i_lang, i_prof, pk_alert_constant.g_no, tte.dt_req, NULL) date_request,
                   pk_translation.get_translation(i_lang, tt.code_tl_task) desc_tl_task,
                   decode(tte.id_tl_task,
                          pk_prog_notes_constants.g_task_img_exams_req,
                          l_label_viewer_exams,
                          pk_prog_notes_constants.g_task_other_exams_req,
                          l_label_viewer_exams,
                          pk_prog_notes_constants.g_task_lab,
                          l_label_viewer_analy,
                          pk_prog_notes_constants.g_task_medic_here,
                          l_label_viewer_presc,
                          pk_prog_notes_constants.g_task_procedures,
                          l_label_viewer_proce,
                          NULL) associated_label,
                   decode(tte.id_tl_task,
                          pk_prog_notes_constants.g_task_img_exams_req,
                          pk_alert_constant.g_yes,
                          pk_prog_notes_constants.g_task_other_exams_req,
                          pk_alert_constant.g_yes,
                          pk_prog_notes_constants.g_task_lab,
                          pk_alert_constant.g_yes,
                          pk_prog_notes_constants.g_task_medic_here,
                          pk_alert_constant.g_yes,
                          pk_prog_notes_constants.g_task_procedures,
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_no) has_association,
                   tte.flg_type_viewer task_type,
                   CASE
                        WHEN erd.flg_referral IS NULL THEN
                         tte.flg_status_req
                        ELSE
                         tte.flg_status_req || erd.flg_referral
                    END flg_status,
                   tte.id_tl_task,
                   tte.id_episode id_episode_origin,
                   i_id_episode id_episode,
                   NULL executionnotes
              FROM tl_task tt
             INNER JOIN task_timeline_ea tte
                ON (tt.id_tl_task = tte.id_tl_task)
              LEFT JOIN exam_req_det erd
                ON erd.id_exam_req_det = tte.id_task_refid
              LEFT JOIN analysis_req_det ard
                ON ard.id_analysis_req_det = tte.id_task_refid
               AND tte.id_tl_task = pk_prog_notes_constants.g_task_lab
              LEFT JOIN analysis_result_par arp
                ON arp.id_analysis_result_par = tte.id_task_refid
               AND tte.id_tl_task = pk_prog_notes_constants.g_task_lab_results
             WHERE (tte.id_visit = i_id_visit) --Filter id_visit that are available for current search (patient's grid)
               AND (tte.flg_sos <> pk_alert_constant.g_yes OR
                   (pk_prog_notes_constants.g_task_procedures = tte.id_tl_task AND tte.flg_status_req = 'E'))
               AND (((((i_flg_method = 'R' AND tte.dt_req BETWEEN l_dt_start AND l_dt_end) OR -- Filter by requisition date
                   (i_flg_method = 'E' AND tte.dt_begin BETWEEN l_dt_start AND l_dt_end)) -- Filter by execution date
                   AND (tte.id_tl_task IN (pk_prog_notes_constants.g_task_img_exams_req,
                                              pk_prog_notes_constants.g_task_other_exams_req,
                                              pk_prog_notes_constants.g_task_lab,
                                              pk_prog_notes_constants.g_task_procedures) OR
                   tte.id_task_refid IN
                   (SELECT tli.id_task_refid
                              FROM TABLE(l_last_info) tli
                             WHERE tli.id_tl_task = tte.id_tl_task
                               AND tli.id_tl_task IN (pk_prog_notes_constants.g_task_img_exams_req,
                                                      pk_prog_notes_constants.g_task_other_exams_req,
                                                      pk_prog_notes_constants.g_task_lab,
                                                      pk_prog_notes_constants.g_task_procedures))))))
               AND ((((SELECT pk_lab_tests_api_db.get_lab_test_access_permission(i_lang,
                                                                                i_prof,
                                                                                nvl(ard.id_analysis,
                                                                                    arp.id_analysis_result_par))
                         FROM dual) = pk_alert_constant.g_yes) AND
                   tte.id_tl_task IN (pk_prog_notes_constants.g_task_lab, pk_prog_notes_constants.g_task_lab_results)) OR
                   (tte.id_tl_task NOT IN
                   (pk_prog_notes_constants.g_task_lab, pk_prog_notes_constants.g_task_lab_results)))
            --
            -- MONITORING
            --
            UNION ALL
            SELECT to_clob(pk_translation.get_translation(i_lang, vs.code_vital_sign)) desc_task,
                   p.id_monitorization_vs_plan task_identifier,
                   p.id_monitorization_vs task_parent,
                   pk_sysdomain.get_img(i_lang, l_mon_plan_table || l_flg_status_name, p.flg_status) icon,
                   NULL default_back_color,
                   decode(p.start_time,
                          NULL,
                          pk_timeline.get_dates_description(i_lang, i_prof, pk_alert_constant.g_no, p.dt_plan_tstz, NULL),
                          pk_timeline.get_dates_description(i_lang,
                                                            i_prof,
                                                            pk_alert_constant.g_no,
                                                            p.start_time,
                                                            p.end_time)) desc_date,
                   
                   pk_date_utils.date_send_tsz(i_lang, nvl(p.start_time, p.dt_plan_tstz), i_prof) date_begin,
                   pk_prof_utils.get_name_signature(i_lang,
                                                    i_prof,
                                                    decode(p.id_prof_performed,
                                                           NULL,
                                                           mon_vs.id_prof_order,
                                                           p.id_prof_performed)) professional_name,
                   pk_translation.get_translation(i_lang, l_institution_code || epi.id_institution) institution,
                   pk_sysdomain.get_desc_domain_set(i_lang, l_mon_plan_table || l_flg_status_name, p.flg_status) flg_status_description,
                   pk_alert_constant.g_no flg_informative_task,
                   pk_utils.get_status_string_immediate(i_lang,
                                                        i_prof,
                                                        g_image_value,
                                                        p.flg_status,
                                                        l_mon_plan_table || l_flg_status_name,
                                                        to_char(nvl(p.start_time, p.dt_plan_tstz),
                                                                pk_alert_constant.g_dt_yyyymmddhh24miss),
                                                        l_mon_plan_table || l_flg_status_name,
                                                        NULL,
                                                        NULL,
                                                        NULL,
                                                        NULL,
                                                        NULL,
                                                        NULL,
                                                        current_timestamp) desc_status,
                   pk_timeline.get_dates_description(i_lang,
                                                     i_prof,
                                                     pk_alert_constant.g_no,
                                                     mon_vs.dt_monitorization_vs_tstz,
                                                     NULL) date_request,
                   pk_translation.get_translation(i_lang, vs.code_vital_sign) desc_tl_task,
                   NULL associated_label,
                   pk_alert_constant.g_no has_association,
                   NULL task_type,
                   p.flg_status flg_status,
                   pk_prog_notes_constants.g_task_monitoring id_tl_task,
                   mon.id_episode id_episode_origin,
                   mon.id_episode id_episode,
                   NULL executionnotes
              FROM monitorization mon
             INNER JOIN monitorization_vs mon_vs
                ON (mon_vs.id_monitorization = mon.id_monitorization)
              JOIN monitorization_vs_plan p
                ON p.id_monitorization_vs = mon_vs.id_monitorization_vs
              JOIN vital_sign vs
                ON vs.id_vital_sign = mon_vs.id_vital_sign
              JOIN episode epi
                ON (epi.id_episode = mon.id_episode)
             WHERE epi.id_visit = i_id_visit
               AND (mon_vs.dt_monitorization_vs_tstz BETWEEN l_dt_start AND l_dt_end AND
                   p.flg_status NOT IN (pk_alert_constant.g_monitor_vs_canc, pk_alert_constant.g_monitor_vs_draft) OR
                   p.id_monitorization_vs_plan IN
                   (SELECT tli.id_task_refid
                       FROM TABLE(l_last_info) tli
                      WHERE tli.id_tl_task = pk_prog_notes_constants.g_task_monitoring))
            --
            -- MOVEMENTS
            --
            UNION ALL
            SELECT to_clob(pk_translation.get_translation(i_lang, dep.code_department) || ', ' ||
                           nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) ||
                           decode(mov.id_necessity,
                                  NULL,
                                  '',
                                  ' (' || pk_translation.get_translation(i_lang, n.code_necessity) || ')')) desc_task,
                   tte.id_task_refid task_identifier,
                   NULL task_parent,
                   tt.icon,
                   tt.default_back_color,
                   get_dates_description(i_lang, i_prof, pk_alert_constant.g_no, tte.dt_begin, tte.dt_end) desc_date,
                   pk_date_utils.date_send_tsz(i_lang, tte.dt_begin, i_prof) date_begin,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, tte.id_prof_req) professional_name,
                   pk_translation.get_translation(i_lang, l_institution_code || tte.id_institution) institution,
                   decode(tte.id_tl_task,
                          pk_prog_notes_constants.g_task_surgery,
                          l_inform_detail_desc,
                          pk_prog_notes_constants.g_task_schedule_inp,
                          l_inform_detail_desc,
                          pk_prog_notes_constants.g_task_prev_dischage_dt,
                          l_inform_detail_desc,
                          pk_sysdomain.get_desc_domain_set(i_lang,
                                                           tte.table_name || l_flg_status_name,
                                                           tte.flg_status_req)) flg_status_description,
                   decode(tte.id_tl_task,
                          pk_prog_notes_constants.g_task_surgery,
                          pk_alert_constant.g_yes,
                          pk_prog_notes_constants.g_task_schedule_inp,
                          pk_alert_constant.g_yes,
                          pk_prog_notes_constants.g_task_prev_dischage_dt,
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_no) flg_informative_task,
                   decode(tte.id_tl_task,
                          pk_prog_notes_constants.g_task_medic_here,
                          pk_api_pfh_in.get_presc_status_icon(i_lang, i_prof, tte.id_task_refid),
                          pk_utils.get_status_string(i_lang,
                                                     i_prof,
                                                     tte.status_str,
                                                     tte.status_msg,
                                                     tte.status_icon,
                                                     tte.status_flg)) desc_status,
                   get_dates_description(i_lang, i_prof, pk_alert_constant.g_no, tte.dt_req, NULL) date_request,
                   pk_translation.get_translation(i_lang, tt.code_tl_task) desc_tl_task,
                   decode(tte.id_tl_task,
                          pk_prog_notes_constants.g_task_img_exams_req,
                          l_label_viewer_exams,
                          pk_prog_notes_constants.g_task_other_exams_req,
                          l_label_viewer_exams,
                          pk_prog_notes_constants.g_task_lab,
                          l_label_viewer_analy,
                          pk_prog_notes_constants.g_task_medic_here,
                          l_label_viewer_presc,
                          pk_prog_notes_constants.g_task_procedures,
                          l_label_viewer_proce,
                          NULL) associated_label,
                   decode(tte.id_tl_task,
                          pk_prog_notes_constants.g_task_img_exams_req,
                          pk_alert_constant.g_yes,
                          pk_prog_notes_constants.g_task_other_exams_req,
                          pk_alert_constant.g_yes,
                          pk_prog_notes_constants.g_task_lab,
                          pk_alert_constant.g_yes,
                          pk_prog_notes_constants.g_task_medic_here,
                          pk_alert_constant.g_yes,
                          pk_prog_notes_constants.g_task_procedures,
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_no) has_association,
                   tte.flg_type_viewer task_type,
                   tte.flg_status_req flg_status,
                   tte.id_tl_task,
                   tte.id_episode id_episode_origin,
                   i_id_episode id_episode,
                   NULL executionnotes
              FROM tl_task tt
             INNER JOIN task_timeline_ea tte
                ON (tt.id_tl_task = tte.id_tl_task)
              JOIN movement mov
                ON mov.id_movement = tte.id_task_refid
              JOIN room r
                ON r.id_room = mov.id_room_to
              JOIN department dep
                ON dep.id_department = r.id_department
              LEFT JOIN necessity n
                ON n.id_necessity = mov.id_necessity
             WHERE (tte.id_visit = i_id_visit) --Filter id_visit that are available for current search (patient's grid)
               AND ((((i_flg_method = 'R' AND tte.dt_req BETWEEN l_dt_start AND l_dt_end) OR -- Filter by requisition date
                   (i_flg_method = 'E' AND tte.dt_begin BETWEEN l_dt_start AND l_dt_end)) -- Filter by execution date
                   AND tte.id_tl_task IN (pk_prog_notes_constants.g_task_transports)) OR
                   tte.id_task_refid IN
                   (SELECT tli.id_task_refid
                       FROM TABLE(l_last_info) tli
                      WHERE tli.id_tl_task = pk_prog_notes_constants.g_task_transports))
            --
            --
            UNION ALL
            --
            -- This union get POSITIONING tasks
            -- THIS BLOCK OF CODE IS TEMPORARY
            SELECT to_clob((SELECT pk_translation.get_translation(i_lang, p.code_positioning)
                              FROM positioning p, epis_positioning_det epd1
                             WHERE p.id_positioning = epd1.id_positioning
                               AND p.flg_available = pk_alert_constant.g_available
                               AND epd1.id_epis_positioning_det = epp.id_epis_positioning_det) || ', ' ||
                           (SELECT pk_translation.get_translation(i_lang, p.code_positioning)
                              FROM positioning p, epis_positioning_det epd1
                             WHERE p.id_positioning = epd1.id_positioning
                               AND p.flg_available = pk_alert_constant.g_available
                               AND epd1.id_epis_positioning_det = epp.id_epis_positioning_next) || '|' ||
                           ep.rot_interval || '|' || pk_sysdomain.get_domain(l_yes_no, ep.flg_massage, i_lang)) desc_task,
                   ep.id_epis_positioning task_identifier,
                   ep.id_epis_positioning task_parent,
                   pk_sysdomain.get_img(i_lang,
                                        pk_alert_constant.g_tl_table_name_posit || l_flg_status_name,
                                        epp.flg_status) icon,
                   NULL default_back_color,
                   get_dates_description(i_lang, i_prof, pk_alert_constant.g_no, epp.dt_prev_plan_tstz, NULL) desc_date,
                   pk_date_utils.date_send_tsz(i_lang, nvl(epp.dt_execution_tstz, epp.dt_prev_plan_tstz), i_prof) date_begin,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ep.id_professional) professional_name,
                   pk_translation.get_translation(i_lang, l_institution_code || epi.id_institution) institution,
                   pk_sysdomain.get_desc_domain_set(i_lang,
                                                    pk_alert_constant.g_tl_table_name_posit || l_flg_status_name,
                                                    epp.flg_status) flg_status_description,
                   pk_alert_constant.g_no flg_informative_task,
                   pk_utils.get_status_string_immediate(i_lang,
                                                        i_prof,
                                                        g_image_value,
                                                        ep.flg_status,
                                                        pk_alert_constant.g_tl_table_name_posit || l_flg_status_name,
                                                        to_char(epp.dt_prev_plan_tstz,
                                                                pk_alert_constant.g_dt_yyyymmddhh24miss),
                                                        pk_alert_constant.g_tl_table_name_posit || l_flg_status_name,
                                                        NULL,
                                                        NULL,
                                                        NULL,
                                                        NULL,
                                                        NULL,
                                                        NULL,
                                                        current_timestamp) desc_status,
                   get_dates_description(i_lang, i_prof, pk_alert_constant.g_no, ep.dt_creation_tstz, NULL) date_request,
                   l_posit_task_desc desc_tl_task,
                   NULL associated_label,
                   pk_alert_constant.g_no has_association,
                   NULL task_type,
                   epp.flg_status,
                   pk_prog_notes_constants.g_task_positioning id_tl_task,
                   ep.id_episode id_episode_origin,
                   i_id_episode id_episode,
                   ep.notes executionnotes
              FROM epis_positioning ep
             INNER JOIN rotation_interval ri
                ON (ep.id_rotation_interval = ri.id_rotation_interval)
             INNER JOIN epis_positioning_det epd
                ON (ep.id_epis_positioning = epd.id_epis_positioning)
             INNER JOIN epis_positioning_plan epp
                ON (epd.id_epis_positioning_det = epp.id_epis_positioning_det)
             INNER JOIN episode epi
                ON (epi.id_episode = ep.id_episode)
             WHERE epi.id_visit = i_id_visit
               AND ((epp.flg_status IN (g_epis_posit_plan_flg_e, g_epis_posit_plan_flg_f) AND
                   ep.flg_status IN (g_epis_posit_flg_statu_e,
                                       g_epis_posit_flg_statu_r,
                                       g_epis_posit_flg_statu_f,
                                       g_epis_posit_flg_statu_i) AND
                   decode(epp.dt_execution_tstz, NULL, epp.dt_prev_plan_tstz, epp.dt_execution_tstz) BETWEEN
                   l_dt_start AND l_dt_end) OR
                   epp.id_epis_positioning_plan IN
                   (SELECT tli.id_task_refid
                       FROM TABLE(l_last_info) tli
                      WHERE tli.id_tl_task = pk_prog_notes_constants.g_task_positioning))
            -- Harvest
            UNION ALL
            SELECT to_clob(pk_translation.get_translation(i_lang, l_code_analysis_name || ard.id_analysis)) desc_task,
                   h.id_harvest task_identifier,
                   NULL task_parent,
                   pk_sysdomain.get_img(i_lang, l_harvest_table_name || l_flg_status_name, h.flg_status) icon,
                   NULL default_back_color,
                   pk_timeline.get_dates_description(i_lang, i_prof, pk_alert_constant.g_no, h.dt_harvest_tstz, NULL) desc_date,
                   pk_date_utils.date_send_tsz(i_lang, h.dt_harvest_tstz, i_prof) date_begin,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, h.id_prof_harvest) professional_name,
                   pk_translation.get_translation(i_lang, l_institution_code || h.id_institution) institution,
                   pk_sysdomain.get_desc_domain_set(i_lang, l_harvest_table_name || l_flg_status_name, h.flg_status) flg_status_description,
                   pk_alert_constant.g_yes flg_informative_task,
                   NULL desc_status,
                   pk_timeline.get_dates_description(i_lang, i_prof, pk_alert_constant.g_no, h.dt_harvest_tstz, NULL) date_request,
                   l_lab_task_desc desc_tl_task,
                   NULL associated_label,
                   pk_alert_constant.g_no has_association,
                   NULL task_type,
                   h.flg_status flg_status,
                   pk_prog_notes_constants.g_task_lab id_tl_task,
                   h.id_episode id_episode_origin,
                   i_id_episode id_episode,
                   h.notes
              FROM harvest h
              JOIN analysis_harvest ah
                ON ah.id_harvest = h.id_harvest
              JOIN analysis_req_det ard
                ON ard.id_analysis_req_det = ah.id_analysis_req_det
             WHERE h.id_visit = i_id_visit
               AND ((ard.flg_status NOT IN
                   (pk_alert_constant.g_analysis_det_canc, pk_alert_constant.g_analysis_det_result) AND
                   h.flg_status = pk_alert_constant.g_harvest_harv AND h.dt_harvest_tstz BETWEEN l_dt_start AND
                   l_dt_end) OR
                   h.id_harvest IN (SELECT tli.id_task_refid
                                       FROM TABLE(l_last_info) tli
                                      WHERE tli.id_tl_task = pk_prog_notes_constants.g_task_lab))
              AND (SELECT pk_lab_tests_api_db.get_lab_test_access_permission(i_lang, i_prof, ard.id_analysis) from dual) = pk_alert_constant.g_yes	                        ;
    
        pk_alertlog.log_debug('GET O_DATE_SERVER INFORMATION');
        g_error       := 'GET O_DATE_SERVER INFORMATION';
        o_date_server := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_patient_tasks);
            pk_types.open_my_cursor(o_cur_last_info);
            RETURN FALSE;
    END get_patient_tasks_pdms;

    /*******************************************************************************************************************************************
    * get_pdms_task_list              Function that returns all the information that should be sent to FLASH concerning TASK TIMELINE functionality
    *                                 for only one patient (episode and visit)
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param i_id_tl_timeline         Timeline identifier
    * @param O_TASKS                  Cursor that returns the tasks collection
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Rui Teixeira & Miguel Gomes
    * @version                        2.6.3.9
    * @since                          2013/08/28
    * @dependencies                   PDMS
    *******************************************************************************************************************************************/
    FUNCTION get_pdms_task_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_tl_timeline IN tl_task_timeline.id_tl_timeline%TYPE DEFAULT NULL,
        o_tasks          OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        g_error         VARCHAR2(4000);
        l_function_name VARCHAR2(200) := 'GET_PATIENT_TASKS_PDMS';
    BEGIN
        pk_alertlog.log_debug(l_function_name);
    
        OPEN o_tasks FOR
            SELECT id_tl_task, pk_translation.get_translation(i_lang, tt.code_tl_task) description, tt.rank
              FROM tl_task tt
             WHERE EXISTS (SELECT DISTINCT (id_tl_task)
                      FROM tl_task_timeline ttl
                     WHERE ttl.id_tl_timeline = i_id_tl_timeline
                       AND ttl.id_tl_task = tt.id_tl_task)
             ORDER BY tt.rank;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            RETURN FALSE;
    END get_pdms_task_list;

FUNCTION get_visit_prof_name
(
    i_lang         IN language.id_language%TYPE,
    i_prof         IN profissional,
    i_id_episode   IN episode.id_episode%TYPE,
    i_id_epis_type IN episode.id_epis_type%TYPE
) RETURN VARCHAR2 IS
    l_name VARCHAR2(1000 CHAR);
BEGIN
    IF i_id_epis_type IN (pk_alert_constant.g_epis_type_exam, pk_alert_constant.g_epis_type_rad)
    THEN
    
        RETURN pk_exams_external_api_db.get_exam_for_episode_timeline(i_lang    => i_lang,
                                                                      i_prof    => i_prof,
                                                                      i_episode => i_id_episode,
                                                                      i_type    => 'P');
    ELSIF i_id_epis_type = pk_alert_constant.g_epis_type_lab
    THEN
        RETURN pk_lab_tests_external_api_db.get_lab_test_for_episode_timeline(i_lang    => i_lang,
                                                                              i_prof    => i_prof,
                                                                              i_episode => i_id_episode,
                                                                              i_type    => 'P');
    ELSIF i_id_epis_type = pk_alert_constant.g_epis_type_rehab_session
    THEN
    
        RETURN pk_rehab.get_visit_prof_by_epis(i_lang => i_lang, i_prof => i_prof, i_id_episode => i_id_episode);
    ELSE
        SELECT pk_prof_utils.get_name_signature(i_lang,
                                                i_prof,
                                                decode(ei.id_professional,
                                                       NULL,
                                                       ei.id_first_nurse_resp,
                                                       ei.id_professional))
          INTO l_name
          FROM epis_info ei
         WHERE ei.id_episode = i_id_episode;
        RETURN l_name;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
    
END get_visit_prof_name;
        

  
BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_timeline;
/
