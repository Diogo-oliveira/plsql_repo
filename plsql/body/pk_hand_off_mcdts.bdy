/*-- Last Change Revision: $Rev: 2027188 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:25 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_hand_off_mcdts AS

    /**********************************************************************************************
    * return procedures information to the hand off report
    * 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    * @param o_on_hold                on hold
    * @param o_last_24h               last 24 hours
    * @param o_in_progress            in progress
    * @param o_to_be_done             to be done
    * @param o_hand_off               cursor
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         João Ribeiro
    * @version                        1.0
    * @since                          23/10/2009
    **********************************************************************************************/

    FUNCTION get_h_off_rep_proc
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        o_on_hold     OUT pk_types.cursor_type,
        o_last_24h    OUT pk_types.cursor_type,
        o_in_progress OUT pk_types.cursor_type,
        o_to_be_done  OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_H_OFF_REP_PROC';
    BEGIN
    
        pk_context_api.set_parameter('ID_LANG', i_lang);
        pk_context_api.set_parameter('ID_PROFESSIONAL', i_prof.id);
        pk_context_api.set_parameter('ID_INSTITUTION', i_prof.institution);
        pk_context_api.set_parameter('ID_SOFTWARE', i_prof.software);
        pk_context_api.set_parameter('ID_EPISODE', i_episode);
    
        OPEN o_on_hold FOR
            SELECT *
              FROM v_proc_hand_off_on_hold;
    
        OPEN o_last_24h FOR
            SELECT *
              FROM v_proc_hand_off_last_24h;
    
        OPEN o_in_progress FOR
            SELECT *
              FROM v_proc_hand_off_in_progress;
    
        OPEN o_to_be_done FOR
            SELECT *
              FROM v_proc_hand_off_to_be_done;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            pk_types.open_my_cursor(o_on_hold);
            pk_types.open_my_cursor(o_last_24h);
            pk_types.open_my_cursor(o_in_progress);
            pk_types.open_my_cursor(o_to_be_done);
        
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END get_h_off_rep_proc;

    /**********************************************************************************************
    * return lab tests information to the hand off report
    * 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    * @param o_on_hold                on hold
    * @param o_last_24h               last 24 hours
    * @param o_in_progress            in progress
    * @param o_to_be_done             to be done
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         João Ribeiro
    * @version                        1.0
    * @since                          23/10/2009
    **********************************************************************************************/

    FUNCTION get_h_off_rep_lab
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        o_on_hold     OUT pk_types.cursor_type,
        o_last_24h    OUT pk_types.cursor_type,
        o_in_progress OUT pk_types.cursor_type,
        o_to_be_done  OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_H_OFF_REP_LAB';
    BEGIN
    
        OPEN o_on_hold FOR
            SELECT *
              FROM TABLE(pk_hand_off_mcdts.get_lab_hand_off(i_lang, i_prof, i_episode, g_flg_status_hold));
    
        OPEN o_last_24h FOR
            SELECT *
              FROM TABLE(pk_hand_off_mcdts.get_lab_hand_off(i_lang, i_prof, i_episode, g_flg_status_last_24h));
    
        OPEN o_in_progress FOR
            SELECT *
              FROM TABLE(pk_hand_off_mcdts.get_lab_hand_off(i_lang, i_prof, i_episode, g_flg_status_progress));
    
        OPEN o_to_be_done FOR
            SELECT *
              FROM TABLE(pk_hand_off_mcdts.get_lab_hand_off(i_lang, i_prof, i_episode, g_flg_status_to_be_done));
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            pk_types.open_my_cursor(o_on_hold);
            pk_types.open_my_cursor(o_last_24h);
            pk_types.open_my_cursor(o_in_progress);
            pk_types.open_my_cursor(o_to_be_done);
        
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END get_h_off_rep_lab;

    /**********************************************************************************************
    * return exams information to the hand off report
    * 
    *
    * @param i_lang                            the id language
    * @param i_prof                            professional, software and institution ids
    * @param i_episode                         episode id
    * @param o_image_exams_on_hold             on hold
    * @param o_image_exams_last_24h            last 24 hours
    * @param o_image_exams_in_progress         in progress
    * @param o_image_exams_to_be_done          to be done
    * @param o_other_exams_on_hold             on hold
    * @param o_other_exams_last_24h            last 24 hours
    * @param o_other_exams_in_progress         in progress
    * @param o_other_exams_to_be_done          to be done
    *
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         João Ribeiro
    * @version                        1.0
    * @since                          23/10/2009
    **********************************************************************************************/

    FUNCTION get_h_off_rep_exam
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        o_image_exams_on_hold     OUT pk_types.cursor_type,
        o_image_exams_last_24h    OUT pk_types.cursor_type,
        o_image_exams_in_progress OUT pk_types.cursor_type,
        o_image_exams_to_be_done  OUT pk_types.cursor_type,
        o_other_exams_on_hold     OUT pk_types.cursor_type,
        o_other_exams_last_24h    OUT pk_types.cursor_type,
        o_other_exams_in_progress OUT pk_types.cursor_type,
        o_other_exams_to_be_done  OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_H_OFF_REP_EXAM';
    BEGIN
    
        OPEN o_image_exams_on_hold FOR
            SELECT *
              FROM TABLE(pk_hand_off_mcdts.get_i_oe_hand_off(i_lang, i_prof, i_episode, g_flg_status_hold, g_image));
    
        OPEN o_image_exams_last_24h FOR
            SELECT *
              FROM TABLE(pk_hand_off_mcdts.get_i_oe_hand_off(i_lang, i_prof, i_episode, g_flg_status_last_24h, g_image));
    
        OPEN o_image_exams_in_progress FOR
            SELECT *
              FROM TABLE(pk_hand_off_mcdts.get_i_oe_hand_off(i_lang, i_prof, i_episode, g_flg_status_progress, g_image));
    
        OPEN o_image_exams_to_be_done FOR
            SELECT *
              FROM TABLE(pk_hand_off_mcdts.get_i_oe_hand_off(i_lang,
                                                             i_prof,
                                                             i_episode,
                                                             g_flg_status_to_be_done,
                                                             g_image));
    
        --
    
        OPEN o_other_exams_on_hold FOR
            SELECT *
              FROM TABLE(pk_hand_off_mcdts.get_i_oe_hand_off(i_lang, i_prof, i_episode, g_flg_status_hold, g_oth_exm));
    
        OPEN o_other_exams_last_24h FOR
            SELECT *
              FROM TABLE(pk_hand_off_mcdts.get_i_oe_hand_off(i_lang,
                                                             i_prof,
                                                             i_episode,
                                                             g_flg_status_last_24h,
                                                             g_oth_exm));
    
        OPEN o_other_exams_in_progress FOR
            SELECT *
              FROM TABLE(pk_hand_off_mcdts.get_i_oe_hand_off(i_lang,
                                                             i_prof,
                                                             i_episode,
                                                             g_flg_status_progress,
                                                             g_oth_exm));
    
        OPEN o_other_exams_to_be_done FOR
            SELECT *
              FROM TABLE(pk_hand_off_mcdts.get_i_oe_hand_off(i_lang,
                                                             i_prof,
                                                             i_episode,
                                                             g_flg_status_to_be_done,
                                                             g_oth_exm));
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            pk_types.open_my_cursor(o_image_exams_on_hold);
            pk_types.open_my_cursor(o_image_exams_last_24h);
            pk_types.open_my_cursor(o_image_exams_in_progress);
            pk_types.open_my_cursor(o_image_exams_to_be_done);
            --
            pk_types.open_my_cursor(o_other_exams_on_hold);
            pk_types.open_my_cursor(o_other_exams_last_24h);
            pk_types.open_my_cursor(o_other_exams_in_progress);
            pk_types.open_my_cursor(o_other_exams_to_be_done);
        
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END get_h_off_rep_exam;

    /**********************************************************************************************
    * return medication information to the hand off report
    * 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    * @param o_on_hold                on hold
    * @param o_last_24h               last 24 hours
    * @param o_in_progress            in progress
    * @param o_to_be_done             to be done
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         João Ribeiro
    * @version                        1.0
    * @since                          23/10/2009
    **********************************************************************************************/

    FUNCTION get_h_off_rep_med
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        o_on_hold     OUT pk_types.cursor_type,
        o_last_24h    OUT pk_types.cursor_type,
        o_in_progress OUT pk_types.cursor_type,
        o_to_be_done  OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_H_OFF_REP_MED';
    BEGIN
    
        OPEN o_on_hold FOR
            SELECT *
              FROM TABLE(pk_api_pfh_in.get_hand_off_med(i_lang, i_prof, i_episode, g_flg_status_hold));
    
        OPEN o_last_24h FOR
            SELECT *
              FROM TABLE(pk_api_pfh_in.get_hand_off_med(i_lang, i_prof, i_episode, g_flg_status_last_24h));
    
        OPEN o_in_progress FOR
            SELECT *
              FROM TABLE(pk_api_pfh_in.get_hand_off_med(i_lang, i_prof, i_episode, g_flg_status_progress));
    
        OPEN o_to_be_done FOR
            SELECT *
              FROM TABLE(pk_api_pfh_in.get_hand_off_med(i_lang, i_prof, i_episode, g_flg_status_to_be_done));
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            pk_types.open_my_cursor(o_on_hold);
            pk_types.open_my_cursor(o_last_24h);
            pk_types.open_my_cursor(o_in_progress);
            pk_types.open_my_cursor(o_to_be_done);
        
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END get_h_off_rep_med;

    FUNCTION get_i_oe_hand_off
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    episode.id_episode%TYPE,
        i_flg_status IN VARCHAR2,
        i_flg_type   IN VARCHAR2
    ) RETURN t_coll_tab_i_oe
        PIPELINED IS
        l_i_oe t_rec_i_oe;
        CURSOR c_i_oe IS
            SELECT eea.flg_type,
                   eea.flg_status_det flg_status,
                   pk_exams_api_db.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || eea.id_exam, NULL) ||
                   decode(e.id_epis_type,
                          nvl(t_ti_log.get_epis_type(i_lang,
                                                     i_prof,
                                                     e.id_epis_type,
                                                     eea.flg_status_req,
                                                     eea.id_exam_req,
                                                     g_exm_req),
                              e.id_epis_type),
                          '',
                          ' - (' || pk_message.get_message(i_lang,
                                                           profissional(i_prof.id,
                                                                        i_prof.institution,
                                                                        t_ti_log.get_epis_type_soft(i_lang,
                                                                                                    i_prof,
                                                                                                    e.id_epis_type,
                                                                                                    eea.flg_status_req,
                                                                                                    eea.id_exam_req,
                                                                                                    g_exm_req)),
                                                           'IMAGE_T009') || ')') desc_exam
              FROM exams_ea eea, episode e
             WHERE e.id_episode = i_episode
               AND eea.id_episode = e.id_episode
               AND eea.flg_type = i_flg_type
               AND eea.flg_time != g_flg_time_r
               AND eea.flg_status_det != g_flg_status_c
                  -- THE STATUS!
               AND (
                   -- HOLD
                    (i_flg_status = g_flg_status_hold AND
                    eea.flg_status_det IN
                    (g_flg_status_r, g_flg_status_d, g_flg_status_pa, g_flg_status_a, g_flg_status_x)) OR
                   -- LAST 24H
                    (i_flg_status = g_flg_status_last_24h AND
                    eea.flg_status_det IN (g_flg_status_p, g_flg_status_f, g_flg_status_l, g_flg_status_ex) AND
                    pk_date_utils.compare_dates_tsz(i_prof,
                                                     nvl(eea.end_time, eea.start_time),
                                                     pk_date_utils.add_days_to_tstz(current_timestamp, -1)) =
                    g_dt_compare_g) OR
                   -- IN PROGRESS
                    (i_flg_status = g_flg_status_progress AND eea.flg_status_det = g_flg_status_e) OR
                   -- TO BE DONE
                    (i_flg_status = g_flg_status_to_be_done AND
                    eea.flg_status_det IN
                    (g_flg_status_r, g_flg_status_d, g_flg_status_pa, g_flg_status_a, g_flg_status_x)));
    
    BEGIN
        OPEN c_i_oe;
        LOOP
            FETCH c_i_oe
                INTO l_i_oe;
            EXIT WHEN c_i_oe%NOTFOUND;
            PIPE ROW(l_i_oe);
        END LOOP;
        CLOSE c_i_oe;
        RETURN;
    
    END get_i_oe_hand_off;

    FUNCTION get_lab_hand_off
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    episode.id_episode%TYPE,
        i_flg_status IN VARCHAR2
    ) RETURN t_coll_tab_lab
        PIPELINED IS
        l_lab t_rec_lab;
        CURSOR c_lab IS
            SELECT ltea.flg_status_det flg_status,
                   ltea.flg_referral,
                   concat(pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                    i_prof,
                                                                    'A',
                                                                    'ANALYSIS.CODE_ANALYSIS.' || ltea.id_analysis,
                                                                    'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                    ltea.id_sample_type,
                                                                    NULL),
                          decode(epi.id_epis_type,
                                 nvl(t_ti_log.get_epis_type(i_lang,
                                                            i_prof,
                                                            epi.id_epis_type,
                                                            ltea.flg_status_det,
                                                            ltea.id_analysis_req_det,
                                                            g_anl_det),
                                     epi.id_epis_type),
                                 '',
                                 ' - (' || pk_message.get_message(i_lang,
                                                                  profissional(i_prof.id,
                                                                               i_prof.institution,
                                                                               t_ti_log.get_epis_type_soft(i_lang,
                                                                                                           i_prof,
                                                                                                           epi.id_epis_type,
                                                                                                           ltea.flg_status_det,
                                                                                                           ltea.id_analysis_req_det,
                                                                                                           g_anl_det)),
                                                                  'IMAGE_T009') || ')')) analysis_desc,
                   pk_translation.get_translation(i_lang, 'EXAM_CAT.CODE_EXAM_CAT.' || ltea.id_exam_cat) desc_dep
              FROM lab_tests_ea ltea, episode epi
             WHERE ltea.id_episode = i_episode
               AND ltea.id_episode = epi.id_episode
               AND ltea.flg_status_det != g_flg_status_c
                  -- THE STATUS!
               AND (
                   -- HOLD
                    (i_flg_status = g_flg_status_hold AND
                    ltea.flg_status_det IN (g_flg_status_d, g_flg_status_r, g_flg_status_x) AND
                    (ltea.flg_referral IN (g_flg_status_r, g_flg_status_s) OR ltea.flg_referral IS NULL)) OR
                   -- LAST 24H
                    (i_flg_status = g_flg_status_last_24h AND ltea.flg_status_det IN (g_flg_status_f, g_flg_status_l) AND
                    pk_date_utils.compare_dates_tsz(i_prof,
                                                     ltea.dt_analysis_result,
                                                     pk_date_utils.add_days_to_tstz(current_timestamp, -1)) =
                    g_dt_compare_g) OR
                   -- IN PROGRESS
                    (i_flg_status = g_flg_status_progress AND ltea.flg_status_det = g_flg_status_e) OR
                   -- TO BE DONE
                    (i_flg_status = g_flg_status_to_be_done AND
                    (ltea.flg_status_det IN (g_flg_status_d, g_flg_status_r, g_flg_status_x) AND
                    (ltea.flg_referral IN (flg_referral_d, flg_referral_s) OR ltea.flg_referral IS NULL))));
    
    BEGIN
        OPEN c_lab;
        LOOP
            FETCH c_lab
                INTO l_lab;
            EXIT WHEN c_lab%NOTFOUND;
            PIPE ROW(l_lab);
        END LOOP;
        CLOSE c_lab;
        RETURN;
    
    END get_lab_hand_off;

    FUNCTION get_monit_hand_off
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    episode.id_episode%TYPE,
        i_flg_status IN VARCHAR2
    ) RETURN t_coll_tab_monit
        PIPELINED IS
        l_monit t_rec_monit;
        CURSOR c_monit IS
            SELECT mea.flg_status,
                   pk_vital_sign.get_vs_desc(i_lang, mea.id_vital_sign) ||
                   decode(epi.id_epis_type,
                          nvl(t_ti_log.get_epis_type(i_lang,
                                                     i_prof,
                                                     epi.id_epis_type,
                                                     mea.flg_status,
                                                     mea.id_monitorization,
                                                     g_monit),
                              epi.id_epis_type),
                          '',
                          ' - (' || pk_message.get_message(i_lang,
                                                           profissional(i_prof.id,
                                                                        i_prof.institution,
                                                                        t_ti_log.get_epis_type_soft(i_lang,
                                                                                                    i_prof,
                                                                                                    epi.id_epis_type,
                                                                                                    mea.flg_status,
                                                                                                    mea.id_monitorization,
                                                                                                    g_monit)),
                                                           'IMAGE_T009') || ')') desc_vital_sign
              FROM monitorizations_ea mea, episode epi
             WHERE mea.id_episode = epi.id_episode
               AND epi.id_episode = i_episode
               AND mea.flg_status != g_flg_status_c
                  -- THE STATUS!
               AND (
                   -- HOLD
                    (i_flg_status = g_flg_status_hold AND mea.flg_status = g_flg_status_d) OR
                   -- TO BE DONE
                    (i_flg_status = g_flg_status_to_be_done AND mea.flg_status = g_flg_status_a AND
                    NOT EXISTS((SELECT *
                                  FROM vital_sign_read vsr
                                 WHERE (vsr.id_vital_sign = mea.id_vital_sign OR
                                       vsr.id_vital_sign IN
                                       (SELECT vsrel.id_vital_sign_detail
                                           FROM vital_sign_relation vsrel
                                          WHERE vsrel.id_vital_sign_parent = mea.id_vital_sign
                                            AND vsrel.relation_domain != pk_alert_constant.g_vs_rel_percentile))
                                   AND vsr.id_episode = epi.id_episode))) OR
                   -- LAST 24H
                    (i_flg_status = g_flg_status_last_24h AND mea.flg_status IN (g_flg_status_f, g_flg_status_i) AND
                    EXISTS (SELECT *
                              FROM vital_sign_read vsr
                             WHERE (vsr.id_vital_sign = mea.id_vital_sign OR
                                   vsr.id_vital_sign IN
                                   (SELECT vsrel.id_vital_sign_detail
                                       FROM vital_sign_relation vsrel
                                      WHERE vsrel.id_vital_sign_parent = mea.id_vital_sign
                                        AND vsrel.relation_domain != pk_alert_constant.g_vs_rel_percentile))
                               AND vsr.id_episode = epi.id_episode
                               AND pk_date_utils.compare_dates_tsz(i_prof,
                                                                   vsr.dt_vital_sign_read_tstz,
                                                                   pk_date_utils.add_days_to_tstz(current_timestamp, -1)) =
                                   g_dt_compare_g)) OR
                   -- IN PROGRESS
                    (i_flg_status = g_flg_status_progress AND mea.flg_status = g_flg_status_a) AND
                    EXISTS((SELECT *
                             FROM vital_sign_read vsr
                            WHERE (vsr.id_vital_sign = mea.id_vital_sign OR
                                  vsr.id_vital_sign IN
                                  (SELECT vsrel.id_vital_sign_detail
                                      FROM vital_sign_relation vsrel
                                     WHERE vsrel.id_vital_sign_parent = mea.id_vital_sign
                                       AND vsrel.relation_domain != pk_alert_constant.g_vs_rel_percentile))
                              AND vsr.id_episode = epi.id_episode)));
    
    BEGIN
        OPEN c_monit;
        LOOP
            FETCH c_monit
                INTO l_monit;
            EXIT WHEN c_monit%NOTFOUND;
            PIPE ROW(l_monit);
        END LOOP;
        CLOSE c_monit;
        RETURN;
    
    END get_monit_hand_off;

    FUNCTION get_h_off_rep_monit
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        o_on_hold     OUT pk_types.cursor_type,
        o_last_24h    OUT pk_types.cursor_type,
        o_in_progress OUT pk_types.cursor_type,
        o_to_be_done  OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_H_OFF_REP_MONIT';
    BEGIN
    
        OPEN o_on_hold FOR
            SELECT *
              FROM TABLE(pk_hand_off_mcdts.get_monit_hand_off(i_lang, i_prof, i_episode, g_flg_status_hold));
    
        OPEN o_last_24h FOR
            SELECT *
              FROM TABLE(pk_hand_off_mcdts.get_monit_hand_off(i_lang, i_prof, i_episode, g_flg_status_last_24h));
    
        OPEN o_in_progress FOR
            SELECT *
              FROM TABLE(pk_hand_off_mcdts.get_monit_hand_off(i_lang, i_prof, i_episode, g_flg_status_progress));
    
        OPEN o_to_be_done FOR
            SELECT *
              FROM TABLE(pk_hand_off_mcdts.get_monit_hand_off(i_lang, i_prof, i_episode, g_flg_status_to_be_done));
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            pk_types.open_my_cursor(o_on_hold);
            pk_types.open_my_cursor(o_last_24h);
            pk_types.open_my_cursor(o_in_progress);
            pk_types.open_my_cursor(o_to_be_done);
        
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END get_h_off_rep_monit;

BEGIN
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);

END pk_hand_off_mcdts;
/
