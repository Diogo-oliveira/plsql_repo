/*-- Last Change Revision: $Rev: 2026853 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:12 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_case_management IS

    CURSOR c_curr_plan(i_episode IN management_plan.id_episode%TYPE) IS
        SELECT COUNT(1)
          FROM management_plan mp
         WHERE mp.id_episode = i_episode
           AND mp.flg_status = g_mnp_flg_status_a;

    CURSOR c_mng_plan(i_mng_plan IN management_plan.id_management_plan%TYPE) IS
        SELECT mp.flg_status
          FROM management_plan mp
         WHERE mp.id_management_plan = i_mng_plan
           FOR UPDATE;

    CURSOR c_mng_followup(i_mng_followup IN management_follow_up.id_management_follow_up%TYPE) IS
        SELECT mfu.flg_status
          FROM management_follow_up mfu
         WHERE mfu.id_management_follow_up = i_mng_followup
           FOR UPDATE;

    CURSOR c_enc_disch(i_disch IN epis_encounter_disch.id_epis_encounter_disch%TYPE) IS
        SELECT eed.flg_status
          FROM epis_encounter_disch eed
         WHERE eed.id_epis_encounter_disch = i_disch
           FOR UPDATE;

    CURSOR c_encounter(i_epis_encounter IN epis_encounter.id_epis_encounter%TYPE) IS
        SELECT ee.flg_status
          FROM epis_encounter ee
         WHERE ee.id_epis_encounter = i_epis_encounter
           FOR UPDATE;

    /********************************************************************************************
    * Process outdated record manipulation errors!
    *
    * @param i_lang                  language identifier
    * @param i_func                  name of function processing error
    * @param o_error                 error message
    *
    * @return                        false
    *
    * @author                        Pedro Carneiro
    * @version                        2.5.0.7  
    * @since                         14/09/2009
    ********************************************************************************************/
    FUNCTION process_outdated
    (
        i_lang  IN language.id_language%TYPE,
        i_func  IN VARCHAR2,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_error_in     t_error_in := t_error_in();
        l_error_msg    sys_message.desc_message%TYPE;
        l_error_action sys_message.desc_message%TYPE;
        l_ret          BOOLEAN;
    BEGIN
        l_error_msg    := pk_message.get_message(i_lang, 'CASE_MANAGER_M004');
        l_error_action := pk_message.get_message(i_lang, 'CASE_MANAGER_M005');
        l_error_in.set_all(i_id_lang       => i_lang,
                           i_sqlcode       => 'CASE_MANAGER_M003',
                           i_sqlerrm       => l_error_msg,
                           i_user_err      => g_error,
                           i_owner         => g_package_owner,
                           i_pck_name      => g_package_name,
                           i_function_name => i_func,
                           i_action        => l_error_action,
                           i_flg_action    => 'D');
        l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
        pk_alert_exceptions.reset_error_state();
        RETURN l_ret;
    END process_outdated;

    /**********************************************************************************************
    * Grelha do case manager com os encontros 
    *      i_type= D -  encontros do dia
    *      i_type= A -  Todos os case managements
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_type                  Tipo de pesquisa: D - os encontros do dia
    *                                A - Todos os case managements
    * @param i_prof_cat_type         Tipo de categoria do profissional, tal
    *                               como é retornada em PK_LOGIN.GET_PROF_PREF
    *
    * @param o_consult               Cursor with encounters
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/08/18
    **********************************************************************************************/

    FUNCTION check_day_encounter
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_encounter IN epis_encounter.id_epis_encounter%TYPE
    ) RETURN BOOLEAN IS
        l_dt_begin     TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end       TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_encounter epis_encounter.dt_epis_encounter%TYPE;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        l_dt_begin := pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz);
        l_dt_end   := pk_date_utils.add_days_to_tstz(l_dt_begin, 1);
        SELECT dt_epis_encounter
          INTO l_dt_encounter
          FROM epis_encounter ee
         WHERE ee.id_epis_encounter = i_id_encounter;
    
        IF l_dt_encounter BETWEEN l_dt_begin AND l_dt_end -- day encouter
        THEN
            RETURN TRUE;
        ELSIF pk_date_utils.compare_dates_tsz(i_prof,
                                              pk_date_utils.trunc_insttimezone(i_prof, l_dt_encounter),
                                              l_dt_begin) = 'L' -- late encounter
        THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
        RETURN FALSE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END check_day_encounter;

    /**********************************************************************************************
    * Grelha do case manager com os encontros 
    *      i_type= D -  encontros do dia
    *      i_type= A -  Todos os case managements
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_type                  Tipo de pesquisa: D - os encontros do dia
    *                                A - Todos os case managements
    * @param i_prof_cat_type         Tipo de categoria do profissional, tal
    *                               como é retornada em PK_LOGIN.GET_PROF_PREF
    *
    * @param o_consult               Cursor with encounters
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/08/18
    **********************************************************************************************/

    FUNCTION get_case_manager
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_type          IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_consult       OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dt_begin TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end   TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_not_defined sys_message.desc_message%TYPE;
    
        l_handoff_type sys_config.value%TYPE;
        l_prof_cat     category.flg_type%TYPE;
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        alertlog.pk_alertlog.log_debug('PARAMS[:i_type:' || i_type || ']', g_package_name, 'GET_CASE_MANAGER');
    
        g_error := 'GET G_SYSDATE';
    
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
    
        g_error := 'DATES';
    
        l_dt_begin := pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz);
        l_dt_end   := pk_date_utils.add_days_to_tstz(l_dt_begin, 1);
    
        l_not_defined := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'CASE_MANAGER_T020');
        IF i_type = g_type_grid_d
           OR i_type IS NULL
        THEN
            -- encounters of the day
            g_error := 'GET CURSOR DAY';
            OPEN o_consult FOR
                SELECT e.id_episode,
                       e.id_patient,
                       ec.id_epis_encounter,
                       pk_patient.get_pat_name(i_lang, i_prof, e.id_patient, e.id_episode, NULL) patient_name,
                       pk_patient.get_pat_name_to_sort(i_lang, i_prof, e.id_patient, e.id_episode, NULL) patient_name_to_sort,
                       pk_adt.get_pat_non_disc_options(i_lang, i_prof, e.id_patient) pat_ndo,
                       pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, e.id_patient) pat_nd_icon,
                       (SELECT pk_sysdomain.get_domain('PATIENT.GENDER.ABBR', pat.gender, i_lang) gender
                          FROM patient pat
                         WHERE e.id_patient = pat.id_patient) gender,
                       pk_patient.get_pat_age(i_lang, e.id_patient, i_prof) pat_age,
                       pk_patphoto.get_pat_photo(i_lang, i_prof, e.id_patient, e.id_episode, NULL) photo,
                       (SELECT concatenate(pk_diagnosis.std_diag_desc(i_lang         => i_lang,
                                                                      i_prof         => i_prof,
                                                                      i_id_diagnosis => d.id_diagnosis,
                                                                      i_id_task_type => pk_alert_constant.g_task_problems,
                                                                      i_code         => d.code_icd,
                                                                      i_flg_other    => d.flg_other,
                                                                      i_flg_std_diag => pk_alert_constant.g_yes) || ';')
                          FROM opinion_reason opr, diagnosis d
                         WHERE opr.id_opinion = o.id_opinion
                           AND opr.id_diagnosis = d.id_diagnosis) request_reason,
                       ec.flg_type,
                       ec.flg_status,
                       (SELECT sd.desc_val
                          FROM sys_domain sd
                         WHERE sd.code_domain = g_domain_enc_flg_type
                           AND sd.domain_owner = pk_sysdomain.k_default_schema
                           AND sd.val = ec.flg_type
                           AND sd.id_language = i_lang) type_encounter,
                       pk_utils.query_to_string('SELECT PK_TRANSLATION.get_translation(' || i_lang ||
                                                ',RE.CODE_REASON)
												FROM EPIS_ENCOUNTER_REASON ECR, REASON_ENCOUNTER RE												
												WHERE ECR.ID_EPIS_ENCOUNTER = ' || ec.id_epis_encounter || '
												AND ECR.ID_REASON = RE.ID_REASON',
                                                '; ') encounter_reason,
                       pk_date_utils.dt_chr_tsz(i_lang, ec.dt_epis_encounter, i_prof) encounter_date,
                       pk_date_utils.dt_chr_hour_tsz(i_lang, ec.dt_epis_encounter, i_prof) encounter_hour,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questions) origin_prof,
                       pk_opinion.get_cm_req_origin(i_lang, i_prof, o.id_episode) origin_software,
                       g_no flg_ehr,
                       decode(ec.flg_status, g_enc_flg_status_c, 4, g_enc_flg_status_i, 3, 2) rank,
                       (SELECT sd.img_name
                          FROM sys_domain sd
                         WHERE sd.code_domain = g_domain_enc_flg_status
                           AND sd.domain_owner = pk_sysdomain.k_default_schema
                           AND sd.val = ec.flg_status
                           AND sd.id_language = i_lang) icon_name_field,
                       NULL background_color,
                       decode(ec.flg_status,
                              g_enc_flg_status_c,
                              pk_alert_constant.g_color_icon_medium_grey,
                              pk_alert_constant.g_color_icon_dark_grey) icon_color_field,
                       pk_date_utils.to_char_insttimezone(i_prof, ec.dt_epis_encounter, 'YYYYMMDDHH24MISS') dt_epis_encounter,
                       decode(ec.flg_status, g_enc_flg_status_r, g_yes, g_no) flg_cancel,
                       decode(ec.flg_status, g_enc_flg_status_r, g_yes, g_no) flg_function,
                       o.id_opinion,
                       pk_date_utils.to_char_insttimezone(i_prof, ec.dt_epis_encounter, 'YYYYMMDDHH24MISS') date_encounter,
                       decode(ec.flg_status,
                              g_enc_flg_status_c,
                              7,
                              g_enc_flg_status_a,
                              1,
                              g_enc_flg_status_r,
                              2,
                              g_enc_flg_status_i,
                              3) rank_image
                  FROM episode e, epis_encounter ec, opinion o
                 WHERE e.id_episode = ec.id_episode
                   AND e.id_episode = o.id_episode_answer
                   AND e.id_epis_type = g_epis_type_cm
                   AND ec.id_professional = i_prof.id
                   AND e.id_institution = i_prof.institution
                   AND e.flg_status NOT IN
                       (pk_alert_constant.g_epis_status_cancel, pk_alert_constant.g_epis_status_inactive)
                   AND ec.flg_status IN
                       (g_enc_flg_status_r, g_enc_flg_status_a, g_enc_flg_status_c, g_enc_flg_status_i)
                   AND ec.dt_epis_encounter BETWEEN l_dt_begin AND l_dt_end
                UNION
                SELECT e.id_episode,
                       e.id_patient,
                       ec.id_epis_encounter,
                       pk_patient.get_pat_name(i_lang, i_prof, e.id_patient, e.id_episode, NULL) patient_name,
                       pk_patient.get_pat_name_to_sort(i_lang, i_prof, e.id_patient, e.id_episode, NULL) patient_name_to_sort,
                       pk_adt.get_pat_non_disc_options(i_lang, i_prof, e.id_patient) pat_ndo,
                       pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, e.id_patient) pat_nd_icon,
                       (SELECT pk_sysdomain.get_domain('PATIENT.GENDER.ABBR', pat.gender, i_lang) gender
                          FROM patient pat
                         WHERE e.id_patient = pat.id_patient) gender,
                       pk_patient.get_pat_age(i_lang, e.id_patient, i_prof) pat_age,
                       pk_patphoto.get_pat_photo(i_lang, i_prof, e.id_patient, e.id_episode, NULL) photo,
                       (SELECT concatenate(pk_diagnosis.std_diag_desc(i_lang         => i_lang,
                                                                      i_prof         => i_prof,
                                                                      i_id_diagnosis => d.id_diagnosis,
                                                                      i_id_task_type => pk_alert_constant.g_task_problems,
                                                                      i_code         => d.code_icd,
                                                                      i_flg_other    => d.flg_other,
                                                                      i_flg_std_diag => pk_alert_constant.g_yes) || ';')
                          FROM opinion_reason opr, diagnosis d
                         WHERE opr.id_opinion = o.id_opinion
                           AND opr.id_diagnosis = d.id_diagnosis) request_reason,
                       ec.flg_type,
                       ec.flg_status,
                       (SELECT sd.desc_val
                          FROM sys_domain sd
                         WHERE sd.code_domain = g_domain_enc_flg_type
                           AND sd.domain_owner = pk_sysdomain.k_default_schema
                           AND sd.val = ec.flg_type
                           AND sd.id_language = i_lang) type_encounter,
                       pk_utils.query_to_string('SELECT PK_TRANSLATION.get_translation(' || i_lang ||
                                                ',RE.CODE_REASON)
												FROM EPIS_ENCOUNTER_REASON ECR, REASON_ENCOUNTER RE												
												WHERE ECR.ID_EPIS_ENCOUNTER = ' || ec.id_epis_encounter || '
												AND ECR.ID_REASON = RE.ID_REASON',
                                                '; ') encounter_reason,
                       pk_date_utils.dt_chr_tsz(i_lang, ec.dt_epis_encounter, i_prof) encounter_date,
                       pk_date_utils.dt_chr_hour_tsz(i_lang, ec.dt_epis_encounter, i_prof) encounter_hour,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questions) origin_prof,
                       pk_opinion.get_cm_req_origin(i_lang, i_prof, o.id_episode) origin_software,
                       g_no flg_ehr,
                       1 rank,
                       (SELECT sd.img_name
                          FROM sys_domain sd
                         WHERE sd.code_domain = g_domain_enc_flg_status
                           AND sd.domain_owner = pk_sysdomain.k_default_schema
                           AND sd.val = ec.flg_status
                           AND sd.id_language = i_lang) icon_name_field,
                       pk_alert_constant.g_color_red background_color,
                       pk_alert_constant.g_color_icon_light_grey icon_color_field,
                       pk_date_utils.to_char_insttimezone(i_prof, ec.dt_epis_encounter, 'YYYYMMDDHH24MISS') dt_epis_encounter,
                       decode(ec.flg_status, g_enc_flg_status_a, g_no, g_yes) flg_cancel,
                       decode(ec.flg_status, g_enc_flg_status_r, g_yes, g_no) flg_function,
                       o.id_opinion,
                       pk_date_utils.to_char_insttimezone(i_prof, ec.dt_epis_encounter, 'YYYYMMDDHH24MISS') date_encounter,
                       decode(ec.flg_status, g_enc_flg_status_r, 5, g_enc_flg_status_a, 4) rank_image
                  FROM episode e, epis_encounter ec, opinion o
                 WHERE e.id_episode = ec.id_episode
                   AND e.id_episode = o.id_episode_answer
                   AND e.id_epis_type = g_epis_type_cm
                   AND ec.id_professional = i_prof.id
                   AND e.id_institution = i_prof.institution
                   AND e.flg_status NOT IN
                       (pk_alert_constant.g_epis_status_cancel, pk_alert_constant.g_epis_status_inactive)
                   AND ec.flg_status IN (g_enc_flg_status_r, g_enc_flg_status_a)
                   AND pk_date_utils.compare_dates_tsz(i_prof,
                                                       pk_date_utils.trunc_insttimezone(i_prof, ec.dt_epis_encounter),
                                                       l_dt_begin) = 'L'
                
                 ORDER BY rank, dt_epis_encounter;
        ELSE
            g_error := 'GET HANDOFF TYPE';
            alertlog.pk_alertlog.log_info(text => g_error);
            pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
        
            g_error := 'GET PROF CAT';
            alertlog.pk_alertlog.log_info(text => g_error);
            l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
        
            -- all encounters
            g_error := 'GET CURSOR ALL';
            OPEN o_consult FOR
                SELECT e.id_episode,
                       e.id_patient,
                       decode(ec.flg_encounter_status, g_enc_grid_status_n, NULL, ec.id_epis_encounter) id_epis_encounter,
                       pk_patient.get_pat_name(i_lang, i_prof, e.id_patient, e.id_episode, NULL) patient_name,
                       pk_patient.get_pat_name_to_sort(i_lang, i_prof, e.id_patient, e.id_episode, NULL) patient_name_to_sort,
                       pk_adt.get_pat_non_disc_options(i_lang, i_prof, e.id_patient) pat_ndo,
                       pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, e.id_patient) pat_nd_icon,
                       (SELECT pk_sysdomain.get_domain('PATIENT.GENDER.ABBR', pat.gender, i_lang) gender
                          FROM patient pat
                         WHERE e.id_patient = pat.id_patient) gender,
                       pk_patient.get_pat_age(i_lang, e.id_patient, i_prof) pat_age,
                       pk_patphoto.get_pat_photo(i_lang, i_prof, e.id_patient, e.id_episode, NULL) photo,
                       (SELECT concatenate(pk_diagnosis.std_diag_desc(i_lang         => i_lang,
                                                                      i_prof         => i_prof,
                                                                      i_id_diagnosis => d.id_diagnosis,
                                                                      i_id_task_type => pk_alert_constant.g_task_problems,
                                                                      i_code         => d.code_icd,
                                                                      i_flg_other    => d.flg_other,
                                                                      i_flg_std_diag => pk_alert_constant.g_yes) || ';')
                          FROM opinion_reason opr, diagnosis d
                         WHERE opr.id_opinion = o.id_opinion
                           AND opr.id_diagnosis = d.id_diagnosis) request_reason,
                       ec.flg_type,
                       ec.flg_status,
                       decode(ec.flg_encounter_status,
                              g_enc_grid_status_n,
                              l_not_defined,
                              (SELECT sd.desc_val
                                 FROM sys_domain sd
                                WHERE sd.code_domain = g_domain_enc_flg_type
                                  AND sd.domain_owner = pk_sysdomain.k_default_schema
                                  AND sd.val = ec.flg_type
                                  AND sd.id_language = i_lang)) type_encounter,
                       decode(ec.flg_encounter_status,
                              g_enc_grid_status_n,
                              NULL,
                              pk_utils.query_to_string('SELECT PK_TRANSLATION.get_translation(' || i_lang ||
                                                       ',RE.CODE_REASON)
                        FROM EPIS_ENCOUNTER_REASON ECR, REASON_ENCOUNTER RE                        
                        WHERE ECR.ID_EPIS_ENCOUNTER = ' ||
                                                       ec.id_epis_encounter || '
                        AND ECR.ID_REASON = RE.ID_REASON',
                                                       '; ')) encounter_reason,
                       decode(ec.flg_encounter_status,
                              g_enc_grid_status_n,
                              l_not_defined,
                              pk_date_utils.dt_chr_tsz(i_lang, ec.dt_epis_encounter, i_prof)) encounter_date,
                       decode(ec.flg_encounter_status,
                              g_enc_grid_status_n,
                              NULL,
                              pk_date_utils.dt_chr_hour_tsz(i_lang, ec.dt_epis_encounter, i_prof)) encounter_hour,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questions) origin_prof,
                       pk_opinion.get_cm_req_origin(i_lang, i_prof, o.id_episode) origin_software,
                       decode(ec.flg_encounter_status, g_enc_grid_status_n, g_yes, g_no) flg_ehr,
                       decode(ec.flg_status, g_enc_flg_status_c, 4, g_enc_flg_status_i, 3, 2) rank,
                       decode(ec.flg_encounter_status,
                              g_enc_grid_status_f, -- FUTURE
                              NULL,
                              g_enc_grid_status_n, -- NOT DEFINED
                              NULL,
                              (SELECT sd.img_name
                                 FROM sys_domain sd
                                WHERE sd.code_domain = g_domain_enc_flg_status
                                  AND sd.domain_owner = pk_sysdomain.k_default_schema
                                  AND sd.val = ec.flg_status
                                  AND sd.id_language = i_lang)) icon_name_field,
                       decode(ec.flg_encounter_status, g_enc_grid_status_l, pk_alert_constant.g_color_red, NULL) background_color,
                       decode(ec.flg_encounter_status,
                              g_enc_grid_status_l,
                              pk_alert_constant.g_color_icon_light_grey,
                              g_enc_grid_status_c,
                              decode(ec.flg_status,
                                     g_enc_flg_status_c,
                                     pk_alert_constant.g_color_icon_medium_grey,
                                     pk_alert_constant.g_color_icon_dark_grey),
                              NULL) icon_color_field,
                       pk_date_utils.to_char_insttimezone(i_prof, ec.dt_epis_encounter, 'YYYYMMDDHH24MISS') dt_epis_encounter,
                       decode(ec.flg_encounter_status,
                              g_enc_grid_status_n,
                              g_no,
                              decode(ec.flg_status, g_enc_flg_status_r, g_yes, g_no)) flg_cancel,
                       decode(ec.flg_encounter_status,
                              g_enc_grid_status_n,
                              g_no,
                              ec.flg_encounter_status,
                              g_enc_grid_status_f,
                              g_no,
                              decode(ec.flg_status, g_enc_flg_status_r, g_yes, g_no)) flg_function,
                       o.id_opinion,
                       pk_date_utils.to_char_insttimezone(i_prof, ec.dt_epis_encounter, 'YYYYMMDDHH24MISS') date_encounter,
                       rank_image
                
                  FROM episode   e,
                       epis_info ei,
                       -- ENCOUNTERS OF THE DAY
                       (SELECT ee.id_epis_encounter,
                                ee.id_episode,
                                ee.dt_create,
                                ee.dt_epis_encounter,
                                ee.flg_status,
                                ee.flg_type,
                                g_enc_grid_status_c flg_encounter_status,
                                ee.id_professional,
                                decode(ee.flg_status,
                                       g_enc_flg_status_r,
                                       1,
                                       g_enc_flg_status_a,
                                       2,
                                       g_enc_flg_status_c,
                                       7,
                                       g_enc_flg_status_i,
                                       3) rank_image
                         
                           FROM epis_encounter ee
                          WHERE ee.dt_epis_encounter BETWEEN l_dt_begin AND l_dt_end
                            AND ee.flg_status IN
                                (g_enc_flg_status_r, g_enc_flg_status_a, g_enc_flg_status_c, g_enc_flg_status_i)
                         UNION
                         -- LATE ENCOUNTERS
                         SELECT ee.id_epis_encounter,
                                ee.id_episode,
                                ee.dt_create,
                                ee.dt_epis_encounter,
                                ee.flg_status,
                                ee.flg_type,
                                g_enc_grid_status_l flg_encounter_status,
                                ee.id_professional,
                                decode(ee.flg_status, g_enc_flg_status_r, 5, g_enc_flg_status_a, 4) rank_image
                         
                           FROM epis_encounter ee
                          WHERE ee.flg_status IN (g_enc_flg_status_r, g_enc_flg_status_a)
                            AND pk_date_utils.compare_dates_tsz(i_prof,
                                                                pk_date_utils.trunc_insttimezone(i_prof,
                                                                                                 ee.dt_epis_encounter),
                                                                pk_date_utils.trunc_insttimezone(i_prof, current_timestamp)) = 'L'
                         UNION
                         -- FUTURE ENCOUNTERS
                         SELECT id_epis_encounter,
                                id_episode,
                                dt_create,
                                dt_epis_encounter,
                                flg_status,
                                flg_type,
                                g_enc_grid_status_f flg_encounter_status,
                                id_professional,
                                6                   rank_image
                         
                           FROM (SELECT ee.id_epis_encounter,
                                        ee.id_episode,
                                        ee.dt_create,
                                        ee.dt_epis_encounter,
                                        ee.flg_status,
                                        ee.flg_type,
                                        ee.id_professional,
                                        row_number() over(PARTITION BY ee.id_episode ORDER BY ee.dt_epis_encounter) rn
                                   FROM epis_encounter ee
                                  WHERE pk_date_utils.compare_dates_tsz(i_prof,
                                                                        pk_date_utils.trunc_insttimezone(i_prof,
                                                                                                         ee.dt_epis_encounter),
                                                                        pk_date_utils.trunc_insttimezone(i_prof,
                                                                                                         current_timestamp)) = 'G'
                                    AND ee.flg_status = g_enc_flg_status_r
                                    AND id_episode NOT IN
                                        (SELECT id_episode
                                           FROM epis_encounter ee1
                                          WHERE ee1.dt_epis_encounter BETWEEN l_dt_begin AND l_dt_end
                                            AND ee1.flg_status IN (g_enc_flg_status_r,
                                                                   g_enc_flg_status_a,
                                                                   g_enc_flg_status_c,
                                                                   g_enc_flg_status_i))
                                 
                                 --  AND rownum = 1
                                 )
                          WHERE rn = 1
                         UNION
                         -- EPISODE THAT DON'T HAVE AN ENCOUNTER
                        SELECT DISTINCT NULL                id_epis_encounter,
                                        ee.id_episode,
                                        NULL                dt_create,
                                        NULL                dt_epis_encounter,
                                        NULL                flg_status,
                                        NULL                flg_type,
                                        g_enc_grid_status_n flg_encounter_status,
                                        NULL                id_professional,
                                        6                   rank_image
                        
                          FROM epis_encounter ee
                         WHERE ee.flg_status <> g_enc_flg_status_r
                           AND id_episode NOT IN
                               (SELECT id_episode
                                  FROM epis_encounter ee1
                                 WHERE ee1.dt_epis_encounter BETWEEN l_dt_begin AND l_dt_end
                                   AND ee1.flg_status IN
                                       (g_enc_flg_status_r, g_enc_flg_status_a, g_enc_flg_status_c, g_enc_flg_status_i)
                                UNION
                                SELECT id_episode
                                  FROM epis_encounter ee1
                                 WHERE ee1.flg_status IN (g_enc_flg_status_r, g_enc_flg_status_a)
                                   AND pk_date_utils.compare_dates_tsz(i_prof,
                                                                       pk_date_utils.trunc_insttimezone(i_prof,
                                                                                                        ee1.dt_epis_encounter),
                                                                       pk_date_utils.trunc_insttimezone(i_prof,
                                                                                                        current_timestamp)) = 'G')
                        
                        -- AND rownum = 1
                        ) ec,
                       opinion o
                 WHERE e.id_episode = ec.id_episode
                   AND e.id_episode = o.id_episode_answer
                   AND e.id_episode = ei.id_episode
                   AND e.id_epis_type = g_epis_type_cm
                   AND i_prof.id IN (ec.id_professional,
                                     (SELECT column_value id_prof
                                        FROM TABLE(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                       i_prof,
                                                                                       ei.id_episode,
                                                                                       l_prof_cat,
                                                                                       l_handoff_type))))
                   AND e.id_institution = i_prof.institution
                   AND e.flg_status NOT IN
                       (pk_alert_constant.g_epis_status_cancel, pk_alert_constant.g_epis_status_inactive)
                   AND o.flg_state = g_opn_flg_state_e
                 ORDER BY patient_name, rank, ec.dt_epis_encounter;
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
                                              'GET_CASE_MANAGER',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_consult);
            RETURN FALSE;
    END get_case_manager;

    /**********************************************************************************************
    * Grelha dos pedidos de case manager por responder 
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    *
    * @param o_opinion               Cursor with the opinion request
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/08/19
    **********************************************************************************************/

    FUNCTION get_pending_case_manager
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_opinion OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_type_opinion opinion_type.id_opinion_type%TYPE;
        l_category     category.id_category%TYPE;
    
        CURSOR c_type_request IS
            SELECT ot.id_opinion_type
              FROM opinion_type ot
             WHERE ot.id_category = l_category;
    
    BEGIN
        alertlog.pk_alertlog.log_debug('PARAMS[i_prof.id:' || i_prof.id || ']',
                                       g_package_name,
                                       'GET_PENDING_CASE_MANAGER');
    
        g_error    := 'GET PROF CATEGORY';
        l_category := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
    
        g_error := 'OPEN C_TYPE_REQUEST';
        OPEN c_type_request;
        FETCH c_type_request
            INTO l_type_opinion;
        CLOSE c_type_request;
    
        g_error := 'GET CURSOR O_OPINION';
        OPEN o_opinion FOR
            SELECT e.id_episode,
                   e.id_patient,
                   pk_patient.get_pat_name(i_lang, i_prof, e.id_patient, e.id_episode, NULL) patient_name,
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, e.id_patient, e.id_episode, NULL) patient_name_to_sort,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, e.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, e.id_patient) pat_nd_icon,
                   (SELECT pk_sysdomain.get_domain('PATIENT.GENDER.ABBR', pat.gender, i_lang) gender
                      FROM patient pat
                     WHERE e.id_patient = pat.id_patient) gender,
                   pk_patient.get_pat_age(i_lang, e.id_patient, i_prof) pat_age,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, e.id_patient, e.id_episode, NULL) photo,
                   (SELECT concatenate(pk_diagnosis.std_diag_desc(i_lang         => i_lang,
                                                                  i_prof         => i_prof,
                                                                  i_id_diagnosis => d.id_diagnosis,
                                                                  i_id_task_type => pk_alert_constant.g_task_problems,
                                                                  i_code         => d.code_icd,
                                                                  i_flg_other    => d.flg_other,
                                                                  i_flg_std_diag => pk_alert_constant.g_yes) || ';')
                      FROM opinion_reason opr, diagnosis d
                     WHERE opr.id_opinion = o.id_opinion
                       AND opr.id_diagnosis = d.id_diagnosis) request_reason,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questions) origin_prof,
                   pk_opinion.get_cm_req_origin(i_lang, i_prof, o.id_episode) origin_software,
                   --    (SELECT sd.desc_val
                   --       FROM sys_domain sd
                   --      WHERE sd.code_domain = g_domain_opn_flg_state
                   --        AND sd.val = o.flg_state
                   --        AND sd.id_language = i_lang) status,
                   pk_sysdomain.get_domain(g_domain_opn_flg_state, g_opn_flg_state_r, i_lang) status,
                   o.id_opinion
              FROM episode e, opinion o, epis_info ei
             WHERE e.id_episode = o.id_episode
               AND e.id_episode = ei.id_episode
               AND e.id_institution = i_prof.institution
               AND o.id_opinion_type = l_type_opinion
               AND (o.id_prof_questioned = i_prof.id OR o.id_prof_questioned IS NULL)
               AND (o.flg_state IN (pk_opinion.g_opinion_approved) OR
                   (o.flg_state = pk_opinion.g_opinion_req AND
                   pk_opinion.check_approval_need(profissional(o.id_prof_questions, e.id_institution, ei.id_software),
                                                    l_type_opinion) = pk_alert_constant.g_no))
             ORDER BY patient_name;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PENDING_CASE_MANAGER',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_opinion);
            RETURN FALSE;
        
    END get_pending_case_manager;

    FUNCTION get_cm_request_reason
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_opinion IN opinion.id_opinion%TYPE
    ) RETURN VARCHAR2 AS
        l_ret VARCHAR2(1000 CHAR);
    BEGIN
        SELECT concatenate(pk_diagnosis.std_diag_desc(i_lang         => i_lang,
                                                      i_prof         => i_prof,
                                                      i_id_diagnosis => d.id_diagnosis,
                                                      i_id_task_type => pk_alert_constant.g_task_problems,
                                                      i_code         => d.code_icd,
                                                      i_flg_other    => d.flg_other,
                                                      i_flg_std_diag => pk_alert_constant.g_yes) || ';')
          INTO l_ret
          FROM opinion_reason opr, diagnosis d
         WHERE opr.id_opinion = i_opinion
           AND opr.id_diagnosis = d.id_diagnosis;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_cm_request_reason;

    /**********************************************************************************************
    * Function for urgency level  
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    *
    * @param o_level               Cursor with the urgency level 
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/08/20
    **********************************************************************************************/

    FUNCTION get_list_mng_level
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_level OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[i_prof.id:' || i_prof.id || ']', g_package_name, 'GET_LIST_MNG_LEVEL');
        g_error := 'OPEN O_LEVEL';
        OPEN o_level FOR
            SELECT ml.id_management_level,
                   pk_translation.get_translation(i_lang, ml.code_management_level) mng_level,
                   mli.time || ' ' ||
                   decode(pk_translation.get_translation(i_lang, u.code_unit_measure),
                          NULL,
                          pk_translation.get_translation(i_lang, u.code_unit_measure_abrv),
                          pk_translation.get_translation(i_lang, u.code_unit_measure)) time_spent
              FROM management_level ml, management_level_inst mli, unit_measure u
             WHERE ml.id_management_level = mli.id_management_level
               AND mli.id_unit_time = u.id_unit_measure
               AND ml.flg_available = g_yes
               AND mli.flg_available = g_yes
               AND nvl(mli.id_institution, 0) IN (0, i_prof.institution);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PENDING_CASE_MANAGER',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_level);
            RETURN FALSE;
        
    END get_list_mng_level;

    /**********************************************************************************************
    * Gets the summary of plan
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient
    * @param i_episode               ID Episode
    * @param i_id_encounter           ID encounter
    *
    * @param o_create                flag that indicates if button + is active(Y/N)
    * @param o_plan                  Cursor with the plan
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/08/20
    **********************************************************************************************/

    FUNCTION get_mng_plan_summary
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_id_encounter  IN epis_encounter.id_epis_encounter%TYPE,
        o_create        OUT VARCHAR2,
        o_plan_register OUT pk_types.cursor_type,
        o_plan          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_urgency_title   sys_message.desc_message%TYPE;
        l_admission_title sys_message.desc_message%TYPE;
        l_needs_title     sys_message.desc_message%TYPE;
        l_goals_title     sys_message.desc_message%TYPE;
        l_plan_title      sys_message.desc_message%TYPE;
        l_time_title      sys_message.desc_message%TYPE;
        l_count           PLS_INTEGER;
    BEGIN
        alertlog.pk_alertlog.log_debug('PARAMS[i_patient:' || i_patient || '; i_episode:' || i_episode ||
                                       '; i_id_encounter:' || i_id_encounter || ' ]',
                                       g_package_name,
                                       'GET_MNG_PLAN_SUMMARY');
        g_error := 'GET MESSAGES';
    
        l_urgency_title   := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T038');
        l_admission_title := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T040');
        l_needs_title     := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T041');
        l_goals_title     := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T042');
        l_plan_title      := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T043');
        l_time_title      := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T039');
    
        -- check for active plans!
        -- if active plans exist, one cannot create more plans
        g_error := 'OPEN c_curr_plan';
        OPEN c_curr_plan(i_episode);
        FETCH c_curr_plan
            INTO l_count;
        CLOSE c_curr_plan;
        IF l_count = 0
        THEN
            o_create := g_yes;
        ELSE
            o_create := g_no;
        END IF;
        g_error := 'OPEN CURSOR O_PLAN';
        OPEN o_plan_register FOR
            SELECT mp.id_management_plan,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, dt_register, i_prof) dt_register,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, mp.id_professional) nick_name,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, mp.id_professional, mp.dt_register, NULL) desc_speciality,
                   mp.flg_status,
                   decode(mp.flg_status, g_mnp_flg_status_c, g_no, g_yes) flg_cancel,
                   decode(mp.flg_status, g_mnp_flg_status_c, g_no, g_yes) flg_action,
                   decode(mp.flg_status, g_mnp_flg_status_c, 2, 1) rank
              FROM management_plan mp, management_level ml, management_level_inst mli, unit_measure u
             WHERE mp.id_episode = i_episode
               AND mp.flg_status IN (g_mnp_flg_status_a, g_mnp_flg_status_c)
               AND mp.id_management_level = ml.id_management_level
               AND ml.id_management_level = mli.id_management_level
               AND nvl(mli.id_institution, 0) IN (0, i_prof.institution)
               AND mli.id_unit_time = u.id_unit_measure
             ORDER BY rank, mp.dt_register;
    
        g_error := 'OPEN CURSOR O_PLAN';
        OPEN o_plan FOR
            SELECT mp.id_management_plan,
                   l_urgency_title urgency_title,
                   pk_translation.get_translation(i_lang, ml.code_management_level) urgency_level,
                   l_time_title time_title,
                   mli.time || ' ' ||
                   decode(pk_translation.get_translation(i_lang, u.code_unit_measure),
                          NULL,
                          pk_translation.get_translation(i_lang, u.code_unit_measure_abrv),
                          pk_translation.get_translation(i_lang, u.code_unit_measure)) required_time,
                   l_admission_title admission_title,
                   mp.admission_notes,
                   l_needs_title needs_title,
                   mp.immediate_needs,
                   l_goals_title goals_title,
                   mp.goals,
                   l_plan_title plan_title,
                   mp.plan,
                   decode(mp.flg_status, g_mnp_flg_status_c, 2, 1) rank
              FROM management_plan mp, management_level ml, management_level_inst mli, unit_measure u
             WHERE mp.id_episode = i_episode
               AND mp.flg_status IN (g_mnp_flg_status_a, g_mnp_flg_status_c)
               AND mp.id_management_level = ml.id_management_level
               AND ml.id_management_level = mli.id_management_level
               AND nvl(mli.id_institution, 0) IN (0, i_prof.institution)
               AND mli.id_unit_time = u.id_unit_measure
             ORDER BY rank, mp.dt_register;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PENDING_CASE_MANAGER',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_plan);
            pk_types.open_my_cursor(o_plan_register);
            RETURN FALSE;
        
    END get_mng_plan_summary;

    /**********************************************************************************************
    * Gets the detail of a plan
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    *
    * @param o_plan                  Cursor with the plan
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/08/21
    **********************************************************************************************/

    FUNCTION get_mng_plan_detail
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_management_plan IN management_plan.id_management_plan%TYPE,
        o_plan_register      OUT pk_types.cursor_type,
        o_plan               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_urgency_title   sys_message.desc_message%TYPE;
        l_admission_title sys_message.desc_message%TYPE;
        l_needs_title     sys_message.desc_message%TYPE;
        l_goals_title     sys_message.desc_message%TYPE;
        l_plan_title      sys_message.desc_message%TYPE;
        l_time_title      sys_message.desc_message%TYPE;
        l_motive_title    sys_message.desc_message%TYPE;
        l_notes_title     sys_message.desc_message%TYPE;
    
        l_msg_oper_add  sys_message.desc_message%TYPE;
        l_msg_oper_edit sys_message.desc_message%TYPE;
        l_msg_oper_canc sys_message.desc_message%TYPE;
    
    BEGIN
        alertlog.pk_alertlog.log_debug('PARAMS[i_id_management_plan:' || i_id_management_plan || ']',
                                       g_package_name,
                                       'GET_MNG_PLAN_DETAIL');
    
        g_error           := 'GET MESSAGES';
        l_urgency_title   := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T038');
        l_admission_title := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T040');
        l_needs_title     := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T041');
        l_goals_title     := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T042');
        l_plan_title      := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T043');
        l_time_title      := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T039');
        l_motive_title    := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T059');
        l_notes_title     := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T060');
        l_msg_oper_add    := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T054');
        l_msg_oper_edit   := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T055');
        l_msg_oper_canc   := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T056');
    
        g_error := 'OPEN CURSOR O_PLAN_REGISTER';
        OPEN o_plan_register FOR
            SELECT mp.id_management_plan,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, dt_register, i_prof) dt_register,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, mp.id_professional) nick_name,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, mp.id_professional, mp.dt_register, NULL) desc_speciality,
                   decode(mp.id_parent,
                          NULL,
                          l_msg_oper_add,
                          decode(mp.flg_status,
                                 g_mnp_flg_status_o,
                                 l_msg_oper_edit,
                                 g_mnp_flg_status_a,
                                 l_msg_oper_edit,
                                 l_msg_oper_canc)) desc_title
              FROM management_plan mp
            CONNECT BY PRIOR mp.id_parent = mp.id_management_plan
             START WITH mp.id_management_plan = i_id_management_plan;
    
        g_error := 'OPEN CURSOR O_PLAN';
        OPEN o_plan FOR
            SELECT mp.id_management_plan,
                   decode(mp.flg_status, g_mnp_flg_status_c, NULL, l_urgency_title) urgency_title,
                   decode(mp.flg_status,
                          g_mnp_flg_status_c,
                          NULL,
                          pk_translation.get_translation(i_lang, ml.code_management_level)) urgency_level,
                   decode(mp.flg_status, g_mnp_flg_status_c, NULL, l_time_title) time_title,
                   decode(mp.flg_status,
                          g_mnp_flg_status_c,
                          NULL,
                          mli.time || ' ' ||
                          decode(pk_translation.get_translation(i_lang, u.code_unit_measure_abrv),
                                 NULL,
                                 pk_translation.get_translation(i_lang, u.code_unit_measure),
                                 pk_translation.get_translation(i_lang, u.code_unit_measure_abrv))) required_time,
                   decode(mp.flg_status, g_mnp_flg_status_c, NULL, l_admission_title) admission_title,
                   decode(mp.flg_status, g_mnp_flg_status_c, NULL, mp.admission_notes) admission_notes,
                   decode(mp.flg_status, g_mnp_flg_status_c, NULL, l_needs_title) needs_title,
                   decode(mp.flg_status, g_mnp_flg_status_c, NULL, mp.immediate_needs) immediate_needs,
                   decode(mp.flg_status, g_mnp_flg_status_c, NULL, l_goals_title) goals_title,
                   decode(mp.flg_status, g_mnp_flg_status_c, NULL, mp.goals) goals,
                   decode(mp.flg_status, g_mnp_flg_status_c, NULL, l_plan_title) plan_title,
                   decode(mp.flg_status, g_mnp_flg_status_c, NULL, mp.plan) plan,
                   decode(mp.flg_status, g_mnp_flg_status_c, l_motive_title, NULL) motive_title,
                   (SELECT pk_translation.get_translation(i_lang,
                                                          'CANCEL_REASON.CODE_CANCEL_REASON.' || mp.id_cancel_reason)
                      FROM dual) cancel_reason,
                   decode(mp.flg_status, g_mnp_flg_status_c, l_notes_title, NULL) notes_title,
                   mp.notes_cancel
              FROM management_plan mp, management_level ml, management_level_inst mli, unit_measure u
             WHERE mp.id_management_level = ml.id_management_level(+)
               AND ml.id_management_level = mli.id_management_level(+)
               AND nvl(mli.id_institution, 0) IN (0, i_prof.institution)
               AND mli.id_unit_time = u.id_unit_measure(+)
               AND mp.id_management_plan IN
                   (SELECT id_management_plan
                      FROM management_plan mp1
                    CONNECT BY PRIOR mp1.id_parent = mp1.id_management_plan
                     START WITH mp1.id_management_plan = i_id_management_plan)
             ORDER BY mp.dt_register DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_MNG_PLAN_DETAIL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_plan);
            pk_types.open_my_cursor(o_plan_register);
        
            RETURN FALSE;
        
    END get_mng_plan_detail;

    /**********************************************************************************************
    * Create/Edit management plan
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient
    * @param i_episode               ID Episode
    * @param i_id_encounter          ID encounter
    * @param i_id_mng_plan           ID Management plan (in case od edit)
    * @param i_level                 ID of level
    * @param i_admission             Admission notes
    * @param i_needs                 Immediate needs
    * @param i_goals                 Goals
    * @param i_plan                  Plan
    
    *
    * @param o_id_management_plan    ID of plan 
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/08/21
    **********************************************************************************************/

    FUNCTION create_mng_plan
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_id_encounter       IN epis_encounter.id_epis_encounter%TYPE,
        i_id_mng_plan        IN management_plan.id_management_plan%TYPE,
        i_level              IN management_plan.id_management_level%TYPE,
        i_admission          IN management_plan.admission_notes%TYPE,
        i_needs              IN management_plan.immediate_needs%TYPE,
        i_goals              IN management_plan.goals%TYPE,
        i_plan               IN management_plan.plan%TYPE,
        o_id_management_plan OUT management_plan.id_management_plan%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows   table_varchar;
        l_status management_plan.flg_status%TYPE;
    BEGIN
        g_sysdate_tstz := current_timestamp;
        alertlog.pk_alertlog.log_debug('PARAMS[i_patient:' || i_patient || ';i_episode:' || i_episode ||
                                       ';i_id_encounter:' || i_id_encounter || ';i_id_mng_plan:' || i_id_mng_plan ||
                                       '; i_level:' || i_level || ' ]',
                                       g_package_name,
                                       'CREATE_MNG_PLAN');
        IF i_id_mng_plan IS NOT NULL -- EDIT A PLAN
        THEN
            OPEN c_mng_plan(i_id_mng_plan);
            FETCH c_mng_plan
                INTO l_status;
            CLOSE c_mng_plan;
        
            IF l_status != g_mnp_flg_status_a
            THEN
                RAISE g_outdated;
            END IF;
            g_error := 'CALL TS_MANAGEMENT_PLAN.UPD';
            l_rows  := table_varchar();
            ts_management_plan.upd(id_management_plan_in => i_id_mng_plan,
                                   flg_status_in         => g_mnp_flg_status_o,
                                   rows_out              => l_rows);
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'MANAGEMENT_PLAN',
                                          i_rowids       => l_rows,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_STATUS'));
        END IF;
        l_rows  := table_varchar();
        g_error := 'CALL TS_MANAGEMENT_PLAN.INS';
        ts_management_plan.ins(id_episode_in          => i_episode,
                               id_epis_encounter_in   => i_id_encounter,
                               id_professional_in     => i_prof.id,
                               id_management_level_in => i_level,
                               flg_status_in          => g_mnp_flg_status_a,
                               dt_register_in         => g_sysdate_tstz,
                               admission_notes_in     => i_admission,
                               immediate_needs_in     => i_needs,
                               goals_in               => i_goals,
                               plan_in                => i_plan,
                               id_parent_in           => i_id_mng_plan,
                               id_management_plan_out => o_id_management_plan,
                               rows_out               => l_rows);
    
        g_error := 'CALL t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'MANAGEMENT_PLAN',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        g_error := 'CALL PK_VISIT.SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL set_encounter_status';
        IF NOT set_encounter_status(i_lang         => i_lang,
                                    i_prof         => i_prof,
                                    i_patient      => i_patient,
                                    i_id_encounter => i_id_encounter,
                                    o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_outdated THEN
            pk_utils.undo_changes;
            RETURN process_outdated(i_lang => i_lang, i_func => 'CREATE_MNG_PLAN', o_error => o_error);
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_MNG_PLAN',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END create_mng_plan;

    /**********************************************************************************************
    * Gets the information of a plan for edit
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient
    * @param i_id_encounter          ID encounter
    * @param i_id_management_plan    ID management plan
    
    *
    * @param o_plan                  Cursor with the plan
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/08/21
    **********************************************************************************************/

    FUNCTION get_mng_plan
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_id_encounter       IN epis_encounter.id_epis_encounter%TYPE,
        i_id_management_plan IN management_plan.id_management_plan%TYPE,
        o_plan               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[i_patient:' || i_patient || '; i_id_encounter:' || i_id_encounter ||
                                       '; i_id_management_plan:' || i_id_management_plan || ' ]',
                                       g_package_name,
                                       'GET_MNG_PLAN');
        g_error := 'OPEN CURSOR O_PLAN';
        OPEN o_plan FOR
            SELECT mp.id_management_plan,
                   mp.id_management_level,
                   pk_translation.get_translation(i_lang, ml.code_management_level) urgency_level,
                   mli.time || ' ' ||
                   decode(pk_translation.get_translation(i_lang, u.code_unit_measure),
                          NULL,
                          pk_translation.get_translation(i_lang, u.code_unit_measure_abrv),
                          pk_translation.get_translation(i_lang, u.code_unit_measure)) required_time,
                   mp.admission_notes,
                   mp.immediate_needs,
                   mp.goals,
                   mp.plan
              FROM management_plan mp, management_level ml, management_level_inst mli, unit_measure u
             WHERE mp.id_management_plan = i_id_management_plan
               AND mp.id_management_level = ml.id_management_level
               AND ml.id_management_level = mli.id_management_level
               AND mli.id_unit_time = u.id_unit_measure;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_MNG_PLAN',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_plan);
            RETURN FALSE;
        
    END get_mng_plan;

    /**********************************************************************************************
    * Cancels a case management plan.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_episode               episode identifier
    * @param i_epis_encounter        epis_encounter identifier
    * @param i_id_management_plan    case management plan identifier
    * @param i_cancel_reason         cancel reason identifier
    * @param i_notes                 cancellation notes
    * @param o_id_management_plan    case management plan identifier
    * @param o_error                 error message
    *
    * @return                        false, if errors occur, or true otherwise
    *                        
    * @author                        Pedro Carneiro
    * @version                        2.5.0.7
    * @since                         2009/08/26
    **********************************************************************************************/
    FUNCTION cancel_mng_plan
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_epis_encounter     IN management_follow_up.id_epis_encounter%TYPE,
        i_id_management_plan IN management_plan.id_management_plan%TYPE,
        i_cancel_reason      IN management_plan.id_cancel_reason%TYPE,
        i_notes              IN management_plan.notes_cancel%TYPE,
        o_id_management_plan OUT management_plan.id_management_plan%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows_out table_varchar := table_varchar();
        l_status   management_plan.flg_status%TYPE;
        CURSOR c_mng_plan_row IS
            SELECT *
              FROM management_plan
             WHERE id_management_plan = i_id_management_plan;
    
        r_mng_plan c_mng_plan_row%ROWTYPE;
    BEGIN
        g_sysdate_tstz := current_timestamp;
        alertlog.pk_alertlog.log_debug('PARAMS[i_episode:' || i_episode || '; i_epis_encounter:' || i_epis_encounter ||
                                       '; i_id_management_plan:' || i_id_management_plan || ' ; i_cancel_reason:' ||
                                       i_cancel_reason || ' ]',
                                       g_package_name,
                                       'CANCEL_MNG_PLAN');
    
        g_error := 'OPEN c_mng_plan_status';
        OPEN c_mng_plan(i_id_management_plan);
        FETCH c_mng_plan
            INTO l_status;
        CLOSE c_mng_plan;
        IF l_status <> g_mnp_flg_status_a -- status not ACTIVE
        THEN
            RAISE g_outdated;
        END IF;
        g_error := 'CALL ts_management_follow_up.upd';
        ts_management_plan.upd(id_management_plan_in => i_id_management_plan,
                               flg_status_in         => g_mnp_flg_status_o,
                               rows_out              => l_rows_out);
        g_error := 'CALL t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'MANAGEMENT_PLAN',
                                      i_rowids       => l_rows_out,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_STATUS'));
    
        l_rows_out := table_varchar();
        g_error    := 'OPEN C_MNG_PLAN';
        OPEN c_mng_plan_row;
        FETCH c_mng_plan_row
            INTO r_mng_plan;
        g_error := 'CALL ts_management_plan.ins';
        ts_management_plan.ins(id_management_plan_out => o_id_management_plan,
                               id_episode_in          => i_episode,
                               id_epis_encounter_in   => i_epis_encounter,
                               id_management_level_in => r_mng_plan.id_management_level,
                               id_professional_in     => i_prof.id,
                               flg_status_in          => g_mnp_flg_status_c,
                               dt_register_in         => g_sysdate_tstz,
                               admission_notes_in     => r_mng_plan.admission_notes,
                               immediate_needs_in     => r_mng_plan.immediate_needs,
                               goals_in               => r_mng_plan.goals,
                               plan_in                => r_mng_plan.plan,
                               id_cancel_reason_in    => i_cancel_reason,
                               notes_cancel_in        => i_notes,
                               id_parent_in           => i_id_management_plan,
                               rows_out               => l_rows_out);
        CLOSE c_mng_plan_row;
        g_error := 'CALL t_data_gov_mnt.process_insert';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'MANAGEMENT_PLAN',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_outdated THEN
            pk_utils.undo_changes;
            RETURN process_outdated(i_lang => i_lang, i_func => 'CREATE_MNG_PLAN', o_error => o_error);
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_MNG_PLAN',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_mng_plan;

    /**********************************************************************************************
    * Gets the summary of FOLLOW-UP
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient
    * @param i_episode               ID Episode
    * @param i_id_encounter          ID encounter
    *
    * @param O_FOLLOW_UP_register    Cursor with the  follow-up register   
    * @param O_FOLLOW_UP             Cursor with the follow-up
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/08/24
    **********************************************************************************************/

    FUNCTION get_mng_fu_summary
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_id_encounter       IN epis_encounter.id_epis_encounter%TYPE,
        o_total_time         OUT VARCHAR2,
        o_follow_up_register OUT pk_types.cursor_type,
        o_follow_up          OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_type_title       sys_message.desc_message%TYPE;
        l_time_title       sys_message.desc_message%TYPE;
        l_notes_title      sys_message.desc_message%TYPE;
        l_total_time_title sys_message.desc_message%TYPE;
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[i_episode:' || i_episode || '; i_id_encounter:' || i_id_encounter ||
                                       '; i_patient:' || i_patient || ']',
                                       g_package_name,
                                       'GET_MNG_FU_SUMMARY');
    
        l_type_title       := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T046');
        l_time_title       := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T047');
        l_notes_title      := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T048');
        l_total_time_title := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T049');
    
        o_total_time := pk_case_management.get_time_spent(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
        g_error      := 'OPEN CURSOR o_follow_up_register';
        OPEN o_follow_up_register FOR
            SELECT mfu.id_management_follow_up,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, mfu.dt_register, i_prof) dt_register,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ee.id_professional) nick_name,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, mfu.id_professional, mfu.dt_register, NULL) desc_speciality,
                   mfu.flg_status,
                   g_yes flg_create,
                   decode(mfu.id_epis_encounter,
                          i_id_encounter,
                          decode(mfu.id_professional,
                                 i_prof.id,
                                 decode(mfu.flg_status, g_mnp_flg_status_c, g_no, g_yes),
                                 g_no),
                          g_no) flg_cancel,
                   decode(mfu.flg_status,
                          g_mnp_flg_status_c,
                          g_no,
                          decode(mfu.id_epis_encounter,
                                 i_id_encounter,
                                 decode(mfu.id_professional, i_prof.id, g_yes, g_no),
                                 g_no)) flg_action,
                   decode(mfu.flg_status, g_mnp_flg_status_c, 2, 1) rank,
                   pk_date_utils.to_char_insttimezone(i_prof, mfu.dt_register, 'YYYYMMDDHH24MISS') date_followup
              FROM management_follow_up mfu, epis_encounter ee
             WHERE mfu.id_episode = i_episode
               AND mfu.id_epis_encounter = ee.id_epis_encounter
               AND mfu.flg_status IN (g_mnp_flg_status_a, g_mnp_flg_status_c)
             ORDER BY rank ASC, mfu.dt_register DESC;
    
        g_error := 'OPEN CURSOR o_follow_up';
        OPEN o_follow_up FOR
            SELECT mfu.id_management_follow_up,
                   l_type_title encounter_reason_title,
                   ee.flg_type,
                   pk_utils.query_to_string('SELECT PK_TRANSLATION.get_translation(' || i_lang ||
                                            ',RE.CODE_REASON)
												FROM MANAGEMENT_FOLLOW_REASON MFR, REASON_ENCOUNTER RE												
												WHERE MFR.ID_MANAGEMENT_FOLLOW_UP = ' ||
                                            mfu.id_management_follow_up || '
												AND MFR.ID_REASON = RE.ID_REASON',
                                            ';') encounter_reason,
                   l_time_title time_title,
                   mfu.time_spent || ' ' ||
                   decode(pk_translation.get_translation(i_lang, u.code_unit_measure),
                          NULL,
                          pk_translation.get_translation(i_lang, u.code_unit_measure_abrv),
                          pk_translation.get_translation(i_lang, u.code_unit_measure)) time_spent,
                   l_notes_title notes_title,
                   mfu.notes,
                   decode(mfu.flg_status, g_mnp_flg_status_c, 2, 1) rank,
                   pk_date_utils.to_char_insttimezone(i_prof, mfu.dt_register, 'YYYYMMDDHH24MISS') date_followup
              FROM management_follow_up mfu, epis_encounter ee, unit_measure u
             WHERE mfu.id_episode = i_episode
               AND mfu.id_epis_encounter = ee.id_epis_encounter
               AND mfu.flg_status IN (g_mnp_flg_status_a, g_mnp_flg_status_c)
               AND mfu.id_unit_time = u.id_unit_measure(+)
             ORDER BY rank ASC, mfu.dt_register DESC;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_MNG_FU_SUMMARY',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_follow_up);
            pk_types.open_my_cursor(o_follow_up_register);
            RETURN FALSE;
    END get_mng_fu_summary;

    /**********************************************************************************************
    * Retrieves a case management follow up reasons.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_mng_plan_followup     management followup identifier
    * @param i_sep                   reason separator
    *
    * @return                        case management follow up reasons
    *                        
    * @author                        Pedro Carneiro
    * @version                        2.5.0.7
    * @since                         2009/08/25
    **********************************************************************************************/
    FUNCTION get_mng_fu_reason
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_mng_plan_followup IN management_follow_up.id_management_follow_up%TYPE,
        i_sep               IN VARCHAR2 DEFAULT ','
    ) RETURN VARCHAR2 IS
        l_space CONSTANT VARCHAR2(1) := ' ';
        l_ret     VARCHAR2(4000);
        l_reasons table_varchar := table_varchar();
    
        CURSOR c_reason IS
            SELECT pk_translation.get_translation(i_lang, re.code_reason)
              FROM management_follow_reason mfr
              JOIN reason_encounter re
             USING (id_reason)
             WHERE mfr.id_management_follow_up = i_mng_plan_followup
             ORDER BY 1;
    BEGIN
        alertlog.pk_alertlog.log_debug('PARAMS[i_mng_plan_followup:' || i_mng_plan_followup || ']',
                                       g_package_name,
                                       'GET_MNG_FU_REASON');
        IF i_mng_plan_followup IS NULL
        THEN
            l_ret := NULL;
        ELSE
            OPEN c_reason;
            FETCH c_reason BULK COLLECT
                INTO l_reasons;
            CLOSE c_reason;
        
            l_ret := NULL;
            FOR i IN 1 .. l_reasons.count
            LOOP
                IF i = 1
                THEN
                    l_ret := l_reasons(i);
                ELSE
                    l_ret := l_ret || i_sep || l_space || l_reasons(i);
                END IF;
            END LOOP;
        END IF;
    
        RETURN l_ret;
    END get_mng_fu_reason;

    /**********************************************************************************************
    * Retrieves a case management follow up data (prior to creation/edition).
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_mng_plan_followup     management followup identifier
    * @param i_episode               episode identifier
    * @param i_epis_encounter        episode encounter identifier
    * @param o_reasons               management followup reasons (id, desc, flg_select)
    * @param o_time_spent            time spent (id, desc, value)
    * @param o_notes                 management followup notes
    * @param o_error                 error
    *
    * @return                        false, if errors occur, or true, otherwise.
    *                        
    * @author                        Pedro Carneiro
    * @version                        2.5.0.7
    * @since                         2009/08/25
    **********************************************************************************************/
    FUNCTION get_mng_followup
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_mng_plan_followup IN management_follow_up.id_management_follow_up%TYPE,
        i_episode           IN management_follow_up.id_episode%TYPE,
        i_epis_encounter    IN management_follow_up.id_epis_encounter%TYPE,
        o_reasons           OUT pk_types.cursor_type,
        o_time_spent        OUT pk_types.cursor_type,
        o_notes             OUT management_follow_up.notes%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_mfu IS
            SELECT mfu.time_spent, mfu.id_unit_time, mfu.notes
              FROM management_follow_up mfu
             WHERE mfu.id_management_follow_up = i_mng_plan_followup;
        r_mfu c_mfu%ROWTYPE;
    BEGIN
        alertlog.pk_alertlog.log_debug('PARAMS[i_episode:' || i_episode || '; i_epis_encounter:' || i_epis_encounter ||
                                       '; i_mng_plan_followup:' || i_mng_plan_followup || ']',
                                       g_package_name,
                                       'GET_MNG_FOLLOWUP');
        -- if no management_follow_up id is provided,
        -- we are creating a new record...
        IF i_mng_plan_followup IS NULL
        THEN
            -- get reasons for current encounter
            g_error := 'OPEN o_reasons 1';
            OPEN o_reasons FOR
                SELECT re.id_reason,
                       pk_translation.get_translation(i_lang, re.code_reason) desc_reason,
                       decode(eer.id_reason, NULL, g_no, g_yes) flg_select
                  FROM reason_encounter re
                  LEFT JOIN (SELECT eer.id_reason
                               FROM epis_encounter_reason eer
                              WHERE eer.id_epis_encounter = i_epis_encounter) eer
                    ON (re.id_reason = eer.id_reason)
                  JOIN epis_encounter ee
                    ON (re.flg_type = ee.flg_type)
                 WHERE ee.id_epis_encounter = i_epis_encounter;
        
            g_error := 'OPEN o_time_spent 1';
            OPEN o_time_spent FOR
                SELECT 10353 id_unit_measure,
                       pk_translation.get_translation(i_lang, 'UNIT_MEASURE.CODE_UNIT_MEASURE.10353') desc_unit_measure,
                       NULL VALUE
                  FROM dual;
        
            o_notes := '';
        
            -- ... otherwise, we are editing a previous record
        ELSE
            -- get reasons for current follow up record
            g_error := 'OPEN o_reasons 2';
            OPEN o_reasons FOR
                SELECT re.id_reason,
                       pk_translation.get_translation(i_lang, re.code_reason) desc_reason,
                       decode(mfr.id_reason, NULL, g_no, g_yes) flg_select
                  FROM reason_encounter re
                  LEFT JOIN (SELECT mfr.id_reason
                               FROM management_follow_reason mfr
                              WHERE mfr.id_management_follow_up = i_mng_plan_followup) mfr
                    ON (re.id_reason = mfr.id_reason);
            -- retrieve follow up data       
            g_error := 'OPEN c_mfu';
            OPEN c_mfu;
            FETCH c_mfu
                INTO r_mfu;
            CLOSE c_mfu;
        
            g_error := 'OPEN o_time_spent 2';
            OPEN o_time_spent FOR
                SELECT r_mfu.id_unit_time id_unit_measure,
                       pk_translation.get_translation(i_lang, 'UNIT_MEASURE.CODE_UNIT_MEASURE.' || r_mfu.id_unit_time) desc_unit_measure,
                       r_mfu.time_spent VALUE
                  FROM dual;
        
            o_notes := r_mfu.notes;
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
                                              'GET_MNG_FOLLOWUP',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_reasons);
            pk_types.open_my_cursor(o_time_spent);
            RETURN FALSE;
    END get_mng_followup;

    /**********************************************************************************************
    * Retrieves a case management follow up history of operations.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_mng_plan_followup     management followup identifier
    * @param o_hist                  cursor
    * @param o_error                 error
    *
    * @return                        false, if errors occur, or true, otherwise.
    *                        
    * @author                        Pedro Carneiro
    * @version                        2.5.0.7
    * @since                         2009/08/25
    **********************************************************************************************/
    FUNCTION get_mng_followup_hist
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_mng_plan_followup IN management_follow_up.id_management_follow_up%TYPE,
        o_hist              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_na CONSTANT VARCHAR2(2) := '--';
        l_br CONSTANT VARCHAR2(4) := '<br>';
        l_msg_oper_add   sys_message.desc_message%TYPE;
        l_msg_oper_edit  sys_message.desc_message%TYPE;
        l_msg_oper_canc  sys_message.desc_message%TYPE;
        l_msg_reasons    sys_message.desc_message%TYPE;
        l_msg_time       sys_message.desc_message%TYPE;
        l_msg_notes      sys_message.desc_message%TYPE;
        l_msg_canc_rea   sys_message.desc_message%TYPE;
        l_msg_canc_notes sys_message.desc_message%TYPE;
    BEGIN
        alertlog.pk_alertlog.log_debug('PARAMS[i_mng_plan_followup:' || i_mng_plan_followup || ']',
                                       g_package_name,
                                       'GET_MNG_FOLLOWUP_HIST');
    
        l_msg_oper_add   := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T054');
        l_msg_oper_edit  := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T055');
        l_msg_oper_canc  := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T056');
        l_msg_reasons    := '<b>' || pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T061') || ' </b>';
        l_msg_time       := '<b>' || pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T057') || ' </b>';
        l_msg_notes      := '<b>' || pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T058') || ' </b>';
        l_msg_canc_rea   := '<b>' || pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T059') || ' </b>';
        l_msg_canc_notes := '<b>' || pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T060') || ' </b>';
    
        g_error := 'open o_hist';
        OPEN o_hist FOR
            SELECT decode(mfu.id_parent,
                          NULL,
                          l_msg_oper_add,
                          decode(mfu.flg_status, g_mfu_status_canc, l_msg_oper_canc, l_msg_oper_edit)) operation,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, mfu.dt_register, i_prof) reg_date,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, mfu.id_professional) prof_name,
                   decode(mfu.flg_status,
                          g_mfu_status_canc,
                          l_msg_canc_rea || (SELECT pk_translation.get_translation(i_lang,
                                                                                   'CANCEL_REASON.CODE_CANCEL_REASON.' ||
                                                                                   mfu.id_cancel_reason)
                                               FROM dual) || l_br || l_msg_canc_notes || nvl(mfu.notes_cancel, l_na),
                          l_msg_reasons || get_mng_fu_reason(i_lang, i_prof, mfu.id_management_follow_up) || l_br ||
                          l_msg_time || mfu.time_spent || ' ' ||
                          (SELECT pk_translation.get_translation(i_lang,
                                                                 'UNIT_MEASURE.CODE_UNIT_MEASURE.' || mfu.id_unit_time)
                             FROM dual) || l_br || l_msg_notes || nvl(mfu.notes, l_na)) history
              FROM management_follow_up mfu
            CONNECT BY PRIOR mfu.id_parent = mfu.id_management_follow_up
             START WITH mfu.id_management_follow_up = i_mng_plan_followup;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_MNG_FOLLOWUP_HIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_hist);
            RETURN FALSE;
    END get_mng_followup_hist;

    /**********************************************************************************************
    * Inserts a set management follow up reasons.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_mng_plan_followup     management followup identifier
    * @param i_reasons               management followup reasons
    * @param o_error                 error
    *
    * @return                        false, if errors occur, or true, otherwise.
    *                        
    * @author                        Pedro Carneiro
    * @version                        2.5.0.7
    * @since                         2009/09/28
    **********************************************************************************************/
    FUNCTION set_mng_followup_reas
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_mng_plan_followup IN management_follow_up.id_management_follow_up%TYPE,
        i_reasons           IN table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows_out     table_varchar := table_varchar();
        l_mfr_row      management_follow_reason%ROWTYPE;
        l_mfr_row_coll ts_management_follow_reason.management_follow_reason_tc;
    BEGIN
        alertlog.pk_alertlog.log_debug('PARAMS[i_mng_plan_followup:' || i_mng_plan_followup || ' ;Reason COUNT:' ||
                                       i_reasons.count || ' ]',
                                       g_package_name,
                                       'SET_MNG_FOLLOWUP_REAS');
    
        -- for every specified reason, fill a row, and add it to the collection
        -- (all rows will have the same followup identifier)
        l_mfr_row.id_management_follow_up := i_mng_plan_followup;
        FOR i IN i_reasons.first .. i_reasons.last
        LOOP
            l_mfr_row.id_reason := i_reasons(i);
            l_mfr_row_coll(i) := l_mfr_row;
        END LOOP;
    
        -- insert all rows, and process all inserts
        g_error := 'CALL ts_management_follow_reason.ins';
        ts_management_follow_reason.ins(rows_in => l_mfr_row_coll, rows_out => l_rows_out);
    
        g_error := 'CALL t_data_gov_mnt.process_insert';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'MANAGEMENT_FOLLOW_REASON',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_MNG_FOLLOWUP_REAS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_mng_followup_reas;

    /**********************************************************************************************
    * Creates or edits a case management follow up.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_mng_plan_followup     management followup identifier
    * @param i_episode               episode identifier
    * @param i_epis_encounter        episode encounter identifier
    * @param i_reasons               management followup reasons
    * @param i_time_spent            time spent
    * @param i_unit_time             time unit identifier
    * @param i_notes                 management followup notes
    * @param o_mng_plan_followup     management followup identifier
    * @param o_error                 error
    *
    * @return                        false, if errors occur, or true, otherwise.
    *                        
    * @author                        Pedro Carneiro
    * @version                        2.5.0.7
    * @since                         2009/08/25
    **********************************************************************************************/
    FUNCTION set_mng_followup
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_mng_plan_followup IN management_follow_up.id_management_follow_up%TYPE,
        i_episode           IN management_follow_up.id_episode%TYPE,
        i_epis_encounter    IN management_follow_up.id_epis_encounter%TYPE,
        i_reasons           IN table_number,
        i_time_spent        IN management_follow_up.time_spent%TYPE,
        i_unit_time         IN management_follow_up.id_unit_time%TYPE,
        i_notes             IN management_follow_up.notes%TYPE,
        o_mng_plan_followup OUT management_follow_up.id_management_follow_up%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows_out          table_varchar := table_varchar();
        l_mng_plan_followup management_follow_up.id_management_follow_up%TYPE;
        l_mfr_row_coll      ts_management_follow_reason.management_follow_reason_tc;
        l_mfr_row           management_follow_reason%ROWTYPE;
        l_status            management_follow_up.flg_status%TYPE;
        l_patient           epis_encounter.id_patient%TYPE;
    
        CURSOR c_encounter_patient IS
            SELECT id_patient
              FROM epis_encounter
             WHERE id_epis_encounter = i_epis_encounter;
    BEGIN
        alertlog.pk_alertlog.log_debug('PARAMS[i_mng_plan_followup:' || i_mng_plan_followup || ';i_episode:' ||
                                       i_episode || ' ;i_epis_encounter:' || i_epis_encounter || '; i_time_spent || ' ||
                                       i_time_spent || ' ;i_unit_time;' || i_unit_time || ' ]',
                                       g_package_name,
                                       'SET_MNG_FOLLOWUP');
        g_sysdate_tstz := current_timestamp;
    
        IF i_mng_plan_followup IS NOT NULL
        THEN
            g_error := 'CALL ts_management_follow_up.upd';
            ts_management_follow_up.upd(id_management_follow_up_in => i_mng_plan_followup,
                                        flg_status_in              => g_mfu_status_outd,
                                        rows_out                   => l_rows_out);
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'MANAGEMENT_FOLLOW_UP',
                                          i_rowids       => l_rows_out,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_STATUS'));
            l_rows_out := table_varchar();
        END IF;
    
        g_error := 'CALL ts_management_follow_up.ins';
        ts_management_follow_up.ins(id_management_follow_up_out => l_mng_plan_followup,
                                    id_episode_in               => i_episode,
                                    id_epis_encounter_in        => i_epis_encounter,
                                    time_spent_in               => i_time_spent,
                                    flg_status_in               => g_mfu_status_active,
                                    id_unit_time_in             => i_unit_time,
                                    dt_register_in              => g_sysdate_tstz,
                                    id_professional_in          => i_prof.id,
                                    notes_in                    => i_notes,
                                    id_parent_in                => i_mng_plan_followup,
                                    rows_out                    => l_rows_out);
        g_error := 'CALL t_data_gov_mnt.process_insert';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'MANAGEMENT_FOLLOW_UP',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        g_error := 'CALL set_mng_followup_reas';
        IF i_reasons.count > 0
        THEN
            IF NOT set_mng_followup_reas(i_lang              => i_lang,
                                         i_prof              => i_prof,
                                         i_mng_plan_followup => l_mng_plan_followup,
                                         i_reasons           => i_reasons,
                                         o_error             => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        g_error := 'OPEN c_encounter_patient';
        OPEN c_encounter_patient;
        FETCH c_encounter_patient
            INTO l_patient;
        CLOSE c_encounter_patient;
    
        g_error := 'CALL set_encounter_status';
        IF NOT set_encounter_status(i_lang         => i_lang,
                                    i_prof         => i_prof,
                                    i_patient      => l_patient,
                                    i_id_encounter => i_epis_encounter,
                                    o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        o_mng_plan_followup := l_mng_plan_followup;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_MNG_FOLLOWUP',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_mng_followup;

    /**********************************************************************************************
    * Creates or edits a case management follow up.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_mng_plan_followup     management followup identifier
    * @param i_episode               episode identifier
    * @param i_epis_encounter        episode encounter identifier
    * @param i_cancel_reason         cancel reason identifier
    * @param i_notes                 management followup cancellation notes
    * @param o_mng_plan_followup     management followup identifier
    * @param o_error                 error
    *
    * @return                        false, if errors occur, or true, otherwise.
    *                        
    * @author                        Pedro Carneiro
    * @version                        2.5.0.7
    * @since                         2009/08/25
    **********************************************************************************************/
    FUNCTION cancel_mng_followup
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_mng_plan_followup IN management_follow_up.id_management_follow_up%TYPE,
        i_episode           IN management_follow_up.id_episode%TYPE,
        i_epis_encounter    IN management_follow_up.id_epis_encounter%TYPE,
        i_cancel_reason     IN management_follow_up.id_cancel_reason%TYPE,
        i_notes             IN management_follow_up.notes_cancel%TYPE,
        o_mng_plan_followup OUT management_follow_up.id_management_follow_up%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_mng_plan_followup management_follow_up.id_management_follow_up%TYPE;
        l_rows_out          table_varchar := table_varchar();
        l_status            management_follow_up.flg_status%TYPE;
    
        CURSOR c_mng_follow_up IS
            SELECT *
              FROM management_follow_up
             WHERE id_management_follow_up = i_mng_plan_followup;
        CURSOR c_mng_follow_up_reason IS
            SELECT id_reason
              FROM management_follow_reason
             WHERE id_management_follow_up = i_mng_plan_followup;
    
        r_mng_follow_up c_mng_follow_up%ROWTYPE;
        l_reasons       table_number := table_number();
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[i_mng_plan_followup:' || i_mng_plan_followup || ';i_episode:' ||
                                       i_episode || ' ;i_epis_encounter:' || i_epis_encounter ||
                                       '; i_cancel_reason || ' || i_cancel_reason || ' ]',
                                       g_package_name,
                                       'CANCEL_MNG_FOLLOWUP');
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'OPEN c_mng_followup';
        OPEN c_mng_followup(i_mng_plan_followup);
        FETCH c_mng_followup
            INTO l_status;
        CLOSE c_mng_followup;
        IF l_status <> g_mfu_status_active -- status not ACTIVE
        THEN
            RAISE g_outdated;
        END IF;
    
        g_error := 'CALL ts_management_follow_up.upd';
        ts_management_follow_up.upd(id_management_follow_up_in => i_mng_plan_followup,
                                    flg_status_in              => g_mfu_status_outd,
                                    rows_out                   => l_rows_out);
        g_error := 'CALL t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'MANAGEMENT_FOLLOW_UP',
                                      i_rowids       => l_rows_out,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_STATUS'));
    
        l_rows_out := table_varchar();
        g_error    := 'OPEN c_mng_follow_up';
        OPEN c_mng_follow_up;
        FETCH c_mng_follow_up
            INTO r_mng_follow_up;
        CLOSE c_mng_follow_up;
    
        g_error := 'CALL ts_management_follow_up.ins';
        ts_management_follow_up.ins(id_management_follow_up_out => l_mng_plan_followup,
                                    id_episode_in               => i_episode,
                                    id_epis_encounter_in        => i_epis_encounter,
                                    flg_status_in               => g_mfu_status_canc,
                                    time_spent_in               => r_mng_follow_up.time_spent,
                                    id_unit_time_in             => r_mng_follow_up.id_unit_time,
                                    dt_register_in              => g_sysdate_tstz,
                                    notes_in                    => r_mng_follow_up.notes,
                                    id_cancel_reason_in         => i_cancel_reason,
                                    notes_cancel_in             => i_notes,
                                    id_parent_in                => i_mng_plan_followup,
                                    id_professional_in          => i_prof.id,
                                    dt_start_in                 => r_mng_follow_up.dt_start,
                                    dt_next_encounter_in        => r_mng_follow_up.dt_next_encounter,
                                    rows_out                    => l_rows_out);
        g_error := 'CALL t_data_gov_mnt.process_insert';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'MANAGEMENT_FOLLOW_UP',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        l_rows_out := table_varchar();
        g_error    := 'OPEN c_mng_follow_up_reason';
        OPEN c_mng_follow_up_reason;
        FETCH c_mng_follow_up_reason BULK COLLECT
            INTO l_reasons;
        CLOSE c_mng_follow_up_reason;
    
        IF l_reasons IS NOT NULL
           AND l_reasons.count > 0
        THEN
            g_error := 'CALL set_mng_followup_reas';
            IF NOT set_mng_followup_reas(i_lang              => i_lang,
                                         i_prof              => i_prof,
                                         i_mng_plan_followup => l_mng_plan_followup,
                                         i_reasons           => l_reasons,
                                         o_error             => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        o_mng_plan_followup := l_mng_plan_followup;
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_outdated THEN
            pk_utils.undo_changes;
            RETURN process_outdated(i_lang => i_lang, i_func => 'CANCEL_MNG_FOLLOWUP', o_error => o_error);
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_MNG_FOLLOWUP',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_mng_followup;

    /**********************************************************************************************
    * Retrieves available options for the create button.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_episode               episode identifier
    * @param o_options               cursor
    * @param o_error                 error
    *
    * @return                        false, if errors occur, or true, otherwise.
    *                        
    * @author                        Pedro Carneiro
    * @version                        2.5.0.7
    * @since                         2009/08/28
    **********************************************************************************************/
    FUNCTION get_summary_options
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN management_plan.id_episode%TYPE,
        o_options OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_action  CONSTANT VARCHAR2(20) := 'ADD_PLAN';
        l_action1 CONSTANT VARCHAR2(20) := 'ADD_FOLLOW';
        l_count       PLS_INTEGER;
        l_create_plan VARCHAR2(1);
    BEGIN
        alertlog.pk_alertlog.log_debug('PARAMS[i_episode:' || i_episode || ' ]', g_package_name, 'GET_SUMMARY_OPTIONS');
        -- check for active plans!
        -- if active plans exist, one cannot create more plans
        g_error := 'OPEN c_curr_plan';
        OPEN c_curr_plan(i_episode);
        FETCH c_curr_plan
            INTO l_count;
        CLOSE c_curr_plan;
        IF l_count = 0
        THEN
            l_create_plan := g_active;
        ELSE
            l_create_plan := g_inactive;
        END IF;
    
        g_error := 'OPEN o_options';
        OPEN o_options FOR
            SELECT 0 id_action,
                   NULL id_parent,
                   1 "LEVEL",
                   g_mnp_flg_status_a to_state,
                   pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T031') desc_action,
                   NULL icon,
                   l_create_plan flg_active,
                   l_action action
              FROM dual
            UNION ALL
            SELECT 1 id_action,
                   NULL id_parent,
                   1 "LEVEL",
                   g_mfu_status_active to_state,
                   pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T045') desc_action,
                   NULL icon,
                   g_yes flg_active,
                   l_action1 action
              FROM dual;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SUMMARY_OPTIONS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_options);
            RETURN FALSE;
    END get_summary_options;

    /**********************************************************************************************
    * Retrieves required data for the case management request's answer.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_opinion               opinion identifier
    * @param o_request               cursor (request data)
    * @param o_accept_list           cursor (acceptances list)
    * @param o_level_list            cursor (urgency levels list)
    * @param o_error                 error
    *
    * @return                        false, if errors occur, or true, otherwise.
    *                        
    * @author                        Pedro Carneiro
    * @version                        2.5.0.7
    * @since                         2009/09/02
    **********************************************************************************************/
    FUNCTION get_req_answer
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_opinion     IN opinion.id_opinion%TYPE,
        o_request     OUT pk_types.cursor_type,
        o_accept_list OUT pk_types.cursor_type,
        o_level_list  OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_br CONSTANT VARCHAR2(4) := '<br>';
        l_na CONSTANT VARCHAR2(2) := '--';
        l_msg_req        sys_message.desc_message%TYPE;
        l_msg_reas       sys_message.desc_message%TYPE;
        l_msg_cm         sys_message.desc_message%TYPE;
        l_msg_status     sys_message.desc_message%TYPE;
        l_msg_notes      sys_message.desc_message%TYPE;
        l_dmn_req        sys_domain.desc_val%TYPE;
        l_label_any_prof sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CONSULT_REQUEST_T021');
    BEGIN
        alertlog.pk_alertlog.log_debug('PARAMS[i_opinion:' || i_opinion || ' ]', g_package_name, 'GET_REQ_ANSWER');
        l_msg_req    := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T026');
        l_msg_reas   := '<b>' || pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T073') || ' </b>';
        l_msg_cm     := '<b>' || pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T074') || ' </b>';
        l_msg_status := '<b>' || pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T075') || ' </b>';
        l_msg_notes  := '<b>' || pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T013') || ' </b>';
        l_dmn_req    := pk_sysdomain.get_domain(g_domain_opn_flg_state, g_opn_flg_state_r, i_lang);
    
        g_error := 'OPEN o_request';
        OPEN o_request FOR
            SELECT l_msg_req operation,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, o.dt_problem_tstz, i_prof) reg_date,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questions) prof_name,
                   l_msg_reas || pk_opinion.get_cm_req_reason(i_lang, i_prof, i_opinion) || l_br || l_msg_cm ||
                   nvl2(o.id_prof_questioned,
                        pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questioned),
                        l_label_any_prof) || l_br || l_msg_status || l_dmn_req || l_br || l_msg_notes ||
                   nvl(o.desc_problem, nvl(o.notes, l_na)) request
              FROM opinion o
             WHERE o.id_opinion = i_opinion;
    
        g_error := 'OPEN o_accept_list';
        OPEN o_accept_list FOR
            SELECT sd.val flg_status, sd.desc_val desc_status
              FROM sys_domain sd
             WHERE sd.code_domain = g_domain_opn_flg_state
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.id_language = i_lang
               AND sd.val IN (pk_opinion.g_opinion_rejected, pk_opinion.g_opinion_accepted)
               AND sd.flg_available = g_yes;
    
        g_error := 'OPEN o_level_list';
        OPEN o_level_list FOR
            SELECT ml.id_management_level, pk_translation.get_translation(i_lang, ml.code_management_level) level_desc
              FROM management_level ml
             WHERE ml.flg_available = g_yes;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_REQ_ANSWER',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_request);
            pk_types.open_my_cursor(o_accept_list);
            pk_types.open_my_cursor(o_level_list);
            RETURN FALSE;
    END get_req_answer;

    /**********************************************************************************************
    * Inserts a set of episode encounter reasons.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_epis_encounter        episode encounter identifier
    * @param i_reasons               management followup reasons
    * @param o_error                 error
    *
    * @return                        false, if errors occur, or true, otherwise.
    *                        
    * @author                        Pedro Carneiro
    * @version                        2.5.0.7
    * @since                         2009/09/28
    **********************************************************************************************/
    FUNCTION set_encounter_reas
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_encounter IN epis_encounter.id_epis_encounter%TYPE,
        i_reasons        IN table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows_out     table_varchar := table_varchar();
        l_eer_row      epis_encounter_reason%ROWTYPE;
        l_eer_row_coll ts_epis_encounter_reason.epis_encounter_reason_tc;
    BEGIN
        alertlog.pk_alertlog.log_debug('PARAMS[i_epis_encounter:' || i_epis_encounter || '; Reason COUNT:' ||
                                       i_reasons.count || ' ]',
                                       g_package_name,
                                       'SET_ENCOUNTER_REAS');
        -- for every specified reason, fill a row, and add it to the collection
        -- (all rows will have the same encounter identifier)
        l_eer_row.id_epis_encounter := i_epis_encounter;
        IF i_reasons.count > 0
        THEN
            FOR i IN i_reasons.first .. i_reasons.last
            LOOP
                l_eer_row.id_reason := i_reasons(i);
                l_eer_row_coll(i) := l_eer_row;
            END LOOP;
        
            -- insert all rows, and process all inserts
            g_error := 'CALL ts_epis_encounter_reason.ins';
            ts_epis_encounter_reason.ins(rows_in => l_eer_row_coll, rows_out => l_rows_out);
        
            g_error := 'CALL t_data_gov_mnt.process_insert';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_ENCOUNTER_REASON',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
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
                                              'SET_ENCOUNTER_REAS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_encounter_reas;

    /**********************************************************************************************
    * Creates or edits an encounter.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_epis_encounter        episode encounter identifier
    * @param i_episode               episode identifier
    * @param i_patient               patient identifier
    * @param i_dt_begin              episode encounter start date
    * @param i_id_professional       episode encounter professional (CM)
    * @param i_flg_type              episode encounter type flag
    * @param i_notes                 episode encounter notes
    * @param i_reasons               episode encounter reasons
    * @param i_transaction_id        remote SCH 3.0 transaction id
    * @param o_epis_encounter        episode encounter identifier
    * @param o_error                 error
    *
    * @return                        false, if errors occur, or true, otherwise.
    *                        
    * @author                        Pedro Carneiro
    * @version                        2.5.0.7
    * @since                         2009/09/03
    **********************************************************************************************/
    FUNCTION set_encounter
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_epis_encounter  IN epis_encounter.id_epis_encounter%TYPE,
        i_episode         IN epis_encounter.id_episode%TYPE,
        i_patient         IN epis_encounter.id_patient%TYPE,
        i_dt_begin        IN VARCHAR2,
        i_id_professional IN professional.id_professional%TYPE,
        i_flg_type        IN epis_encounter.flg_type%TYPE,
        i_notes           IN epis_encounter.notes%TYPE,
        i_reasons         IN table_number,
        i_transaction_id  IN VARCHAR2,
        o_epis_encounter  OUT epis_encounter.id_epis_encounter%TYPE,
        o_episode         OUT episode.id_episode%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows_out       table_varchar := table_varchar();
        l_epis_encounter epis_encounter.id_epis_encounter%TYPE;
        l_dt_encounter   epis_encounter.dt_epis_encounter%TYPE;
        l_status         epis_encounter.flg_status%TYPE;
        l_episode        episode.id_episode%TYPE;
        l_none CONSTANT NUMBER(24) := -1;
        -- SCH 3.0 variable
        l_transaction_id VARCHAR2(4000);
    BEGIN
        alertlog.pk_alertlog.log_debug('PARAMS[i_epis_encounter:' || i_epis_encounter || '; i_episode:' || i_episode ||
                                       ';i_patient:' || i_patient || ';i_dt_begin:' || i_dt_begin ||
                                       '; i_id_professional:' || i_id_professional || ' ;i_flg_type:' || i_flg_type ||
                                       '  ]',
                                       g_package_name,
                                       'SET_ENCOUNTER');
        g_sysdate_tstz := current_timestamp;
    
        IF i_dt_begin IS NOT NULL
        THEN
            l_dt_encounter := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                            i_prof      => i_prof,
                                                            i_timestamp => i_dt_begin,
                                                            i_timezone  => NULL);
        ELSE
            l_dt_encounter := g_sysdate_tstz;
        END IF;
    
        IF i_episode IS NULL
        THEN
            -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
            g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
            l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
        
            -- If a patient is a result of "all patients" and not have a CM episode yet
            g_sysdate_tstz := current_timestamp;
            IF NOT pk_visit.call_create_visit(i_lang                 => i_lang,
                                              i_id_pat               => i_patient,
                                              i_id_institution       => i_prof.institution,
                                              i_id_sched             => NULL,
                                              i_id_professional      => i_prof,
                                              i_id_episode           => NULL,
                                              i_external_cause       => NULL,
                                              i_health_plan          => NULL,
                                              i_epis_type            => g_epis_type_cm,
                                              i_dep_clin_serv        => l_none,
                                              i_origin               => NULL,
                                              i_flg_ehr              => pk_visit.g_flg_ehr_n,
                                              i_dt_begin             => g_sysdate_tstz,
                                              i_flg_appointment_type => pk_visit.g_null_appointment_type,
                                              i_transaction_id       => l_transaction_id,
                                              o_episode              => l_episode,
                                              o_error                => o_error)
            THEN
                pk_utils.undo_changes;
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END IF;
        
        ELSE
            l_episode := i_episode;
        END IF;
    
        IF i_epis_encounter IS NOT NULL
        THEN
            --verify if the encounter is still active
            g_error := 'OPEN c_encounter';
            OPEN c_encounter(i_epis_encounter);
            FETCH c_encounter
                INTO l_status;
            CLOSE c_encounter;
            IF l_status <> g_enc_flg_status_r -- status not Requested
            THEN
                RAISE g_outdated;
            END IF;
            g_error := 'CALL ts_epis_encounter.upd';
            ts_epis_encounter.upd(id_epis_encounter_in => i_epis_encounter,
                                  flg_status_in        => g_enc_flg_status_o,
                                  rows_out             => l_rows_out);
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'EPIS_ENCOUNTER',
                                          i_rowids       => l_rows_out,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_STATUS'));
            l_rows_out := table_varchar();
        END IF;
    
        g_error := 'CALL ts_epis_encounter.ins';
        ts_epis_encounter.ins(id_epis_encounter_out => l_epis_encounter,
                              id_episode_in         => l_episode,
                              id_patient_in         => i_patient,
                              id_prof_create_in     => i_prof.id,
                              dt_create_in          => g_sysdate_tstz,
                              dt_epis_encounter_in  => l_dt_encounter,
                              id_professional_in    => i_id_professional,
                              flg_status_in         => g_enc_flg_status_r,
                              flg_type_in           => i_flg_type,
                              notes_in              => i_notes,
                              id_parent_in          => i_epis_encounter,
                              rows_out              => l_rows_out);
        g_error := 'CALL t_data_gov_mnt.process_insert 1';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPIS_ENCOUNTER',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        IF i_reasons.count > 0
        THEN
            g_error := 'CALL set_encounter_reas';
            IF NOT set_encounter_reas(i_lang           => i_lang,
                                      i_prof           => i_prof,
                                      i_epis_encounter => l_epis_encounter,
                                      i_reasons        => i_reasons,
                                      o_error          => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => l_episode,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => pk_alert_constant.g_cat_type_case_manager,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        o_epis_encounter := l_epis_encounter;
        o_episode        := l_episode;
    
        --remote scheduler commit. Doesn't affect PFH.
        IF i_transaction_id IS NULL
           AND l_transaction_id IS NOT NULL -- esta ultima condicao nao costuma existir. 
        --existe para garantir que o fluxo passou pelo if i_flg_state = pk_opinion.g_opinion_accepted
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
            COMMIT;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_outdated THEN
            pk_utils.undo_changes;
            RETURN process_outdated(i_lang => i_lang, i_func => 'SET_ENCOUNTER', o_error => o_error);
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ENCOUNTER',
                                              o_error);
            pk_utils.undo_changes;
            --remote scheduler rollback. Doesn't affect PFH.
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_encounter;

    /*******************************************************************************************
    * Answers (accepts/rejects) a case management request.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_opinion          opinion identifier
    * @param i_patient          patient identifier
    * @param i_flg_state        acceptance
    * @param i_management_level management level identifier
    * @param i_notes            answer notes
    * @param i_transaction_id   remote SCH 3.0 transaction id
    * @param o_opinion          opinion identifier
    * @param o_opinion_prof     opinion prof identifier
    * @param o_episode          episode identifier
    * @param o_epis_encounter   episode encounter dentifier
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @author                   Pedro Carneiro
    * @version                   2.5.0.7
    * @since                    2009/09/03
    ********************************************************************************************/
    FUNCTION set_cm_req_answer
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_opinion          IN opinion_prof.id_opinion%TYPE,
        i_patient          IN patient.id_patient%TYPE,
        i_flg_state        IN opinion.flg_state%TYPE,
        i_management_level IN opinion.id_management_level%TYPE,
        i_notes            IN opinion_prof.desc_reply%TYPE,
        i_transaction_id   IN VARCHAR2 DEFAULT NULL,
        o_opinion_prof     OUT opinion_prof.id_opinion_prof%TYPE,
        o_episode          OUT episode.id_episode%TYPE,
        o_epis_encounter   OUT epis_encounter.id_epis_encounter%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_none CONSTANT NUMBER(24) := -1;
        l_rows_out       table_varchar := table_varchar();
        l_opinion_prof   opinion_prof.id_opinion_prof%TYPE;
        l_episode        episode.id_episode%TYPE;
        l_epis_encounter epis_encounter.id_epis_encounter%TYPE;
        l_episode_out    episode.id_episode%TYPE;
    BEGIN
        -- STEP 1: answer the request
        -- create opinion answer
        alertlog.pk_alertlog.log_debug('PARAMS[i_opinion:' || i_opinion || '; i_patient:' || i_patient ||
                                       ';i_flg_state:' || i_flg_state || ';i_management_level:' || i_management_level ||
                                       '  ]',
                                       g_package_name,
                                       'SET_CM_REQ_ANSWER');
    
        IF NOT pk_opinion.set_request_answer(i_lang             => i_lang,
                                             i_prof             => i_prof,
                                             i_opinion          => i_opinion,
                                             i_patient          => i_patient,
                                             i_flg_state        => i_flg_state,
                                             i_management_level => i_management_level,
                                             i_notes            => i_notes,
                                             i_cancel_reason    => NULL,
                                             i_transaction_id   => i_transaction_id,
                                             o_opinion_prof     => o_opinion_prof,
                                             o_episode          => o_episode,
                                             o_epis_encounter   => o_epis_encounter,
                                             o_error            => o_error)
        THEN
            RETURN FALSE;
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
                                              'SET_CM_REQ_ANSWER',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_cm_req_answer;

    /**********************************************************************************************
    * Sets the status of encounter
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient
    * @param i_id_encounter          ID encounter
    *
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/09/7
    **********************************************************************************************/

    FUNCTION set_encounter_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_id_encounter IN epis_encounter.id_epis_encounter%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows table_varchar;
        --cursor c_day_encounter is
        --select 
        --from epis_encounter
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[i_patient:' || i_patient || '; i_id_encounter:' || i_id_encounter ||
                                       '  ]',
                                       g_package_name,
                                       'SET_ENCOUNTER_STATUS');
    
        IF check_day_encounter(i_lang => i_lang, i_prof => i_prof, i_id_encounter => i_id_encounter)
        THEN
            g_error        := 'SET EPIS_ENCOUNTER';
            g_sysdate_tstz := current_timestamp;
        
            ts_epis_encounter.upd(flg_status_in        => g_enc_flg_status_a,
                                  dt_init_encounter_in => g_sysdate_tstz,
                                  where_in             => 'id_epis_encounter = ' || i_id_encounter ||
                                                          ' and flg_status=''' || g_enc_flg_status_r || '''',
                                  rows_out             => l_rows);
        
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'EPIS_ENCOUNTER',
                                          i_rowids       => l_rows,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_STATUS'));
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_outdated THEN
            pk_utils.undo_changes;
            RETURN process_outdated(i_lang => i_lang, i_func => 'SET_ENCOUNTER_STATUS', o_error => o_error);
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ENCOUNTER_STATUS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_encounter_status;

    /**********************************************************************************************
    * Cancels a encounter
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_episode               episode identifier
    * @param i_epis_encounter        epis_encounter identifier
    * @param i_cancel_reason         cancel reason identifier
    * @param i_notes                 cancellation notes
    * @param o_id_management_plan    epis encounter
    *
    * @return                        false, if errors occur, or true otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         09-09-2009
    **********************************************************************************************/
    FUNCTION cancel_encounter
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_epis_encounter    IN epis_encounter.id_epis_encounter%TYPE,
        i_cancel_reason     IN epis_encounter.id_cancel_reason%TYPE,
        i_notes             IN epis_encounter.notes_cancel%TYPE,
        o_id_epis_encounter OUT epis_encounter.id_epis_encounter%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows    table_varchar := table_varchar();
        l_status  epis_encounter.flg_status%TYPE;
        l_reasons table_number := table_number();
    
        CURSOR c_epis_encounter IS
            SELECT *
              FROM epis_encounter
             WHERE id_epis_encounter = i_epis_encounter;
        CURSOR c_epis_encounter_reason IS
            SELECT id_reason
              FROM epis_encounter_reason
             WHERE id_epis_encounter = i_epis_encounter;
        r_epis_encounter c_epis_encounter%ROWTYPE;
        CURSOR c_count_followup IS
            SELECT COUNT(1)
              FROM management_follow_up
             WHERE id_epis_encounter = i_epis_encounter;
        l_num NUMBER;
        l_exception_follow EXCEPTION;
        l_error_msg sys_message.desc_message%TYPE;
        l_title     sys_message.desc_message%TYPE;
        l_error_in  t_error_in := t_error_in();
        l_ret       BOOLEAN;
    
    BEGIN
        alertlog.pk_alertlog.log_debug('PARAMS[i_episode:' || i_episode || '; i_epis_encounter:' || i_epis_encounter ||
                                       '; i_cancel_reason:' || i_cancel_reason || '  ]',
                                       g_package_name,
                                       'CANCEL_ENCOUNTER');
        g_sysdate_tstz := current_timestamp;
    
        --verify if the encounter is still active
        g_error := 'OPEN c_encounter';
        OPEN c_encounter(i_epis_encounter);
        FETCH c_encounter
            INTO l_status;
        CLOSE c_encounter;
        IF l_status <> g_enc_flg_status_r -- status not Requested
        THEN
            RAISE g_outdated;
        END IF;
    
        g_error := 'OPEN c_count_followup';
        OPEN c_count_followup;
        FETCH c_count_followup
            INTO l_num;
        CLOSE c_count_followup;
        IF l_num > 0
        THEN
            RAISE l_exception_follow;
        END IF;
        -- mark encounter as outdated
        g_error := 'CALL ts_epis_encounter.upd';
        ts_epis_encounter.upd(id_epis_encounter_in => i_epis_encounter,
                              flg_status_in        => g_enc_flg_status_o,
                              rows_out             => l_rows);
        g_error := 'CALL t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_ENCOUNTER',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_STATUS'));
    
        l_rows := table_varchar();
    
        -- insert "cancelled" record
        g_error := 'OPEN c_epis_encounter';
        OPEN c_epis_encounter;
        FETCH c_epis_encounter
            INTO r_epis_encounter;
        CLOSE c_epis_encounter;
    
        g_error := 'CALL ts_epis_encounter.ins';
        ts_epis_encounter.ins(id_episode_in         => i_episode,
                              id_patient_in         => r_epis_encounter.id_patient,
                              id_prof_create_in     => i_prof.id,
                              dt_create_in          => g_sysdate_tstz,
                              id_professional_in    => r_epis_encounter.id_professional,
                              dt_epis_encounter_in  => r_epis_encounter.dt_epis_encounter,
                              flg_status_in         => g_enc_flg_status_c,
                              flg_type_in           => r_epis_encounter.flg_type,
                              notes_in              => r_epis_encounter.notes,
                              id_cancel_reason_in   => i_cancel_reason,
                              notes_cancel_in       => i_notes,
                              id_parent_in          => i_epis_encounter,
                              id_epis_encounter_out => o_id_epis_encounter,
                              rows_out              => l_rows);
        g_error := 'CALL t_data_gov_mnt.process_insert (1)';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPIS_ENCOUNTER',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        -- copy reasons
        g_error := 'OPEN c_epis_encounter_reason';
        OPEN c_epis_encounter_reason;
        FETCH c_epis_encounter_reason BULK COLLECT
            INTO l_reasons;
        CLOSE c_epis_encounter_reason;
    
        g_error := 'CALL set_encounter_reas';
        IF NOT set_encounter_reas(i_lang           => i_lang,
                                  i_prof           => i_prof,
                                  i_epis_encounter => o_id_epis_encounter,
                                  i_reasons        => l_reasons,
                                  o_error          => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception_follow THEN
            pk_utils.undo_changes;
            l_error_msg := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_M009');
            l_title     := pk_message.get_message(i_lang, i_prof, 'COMMON_T013');
            l_error_in.set_all(i_id_lang       => i_lang,
                               i_sqlcode       => NULL,
                               i_sqlerrm       => l_error_msg,
                               i_user_err      => g_error,
                               i_owner         => g_package_owner,
                               i_pck_name      => g_package_name,
                               i_function_name => 'CANCEL_ENCOUNTER',
                               i_action        => NULL,
                               i_flg_action    => 'U');
            l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
        
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN g_outdated THEN
            pk_utils.undo_changes;
            RETURN process_outdated(i_lang => i_lang, i_func => 'CANCEL_ENCOUNTER', o_error => o_error);
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_ENCOUNTER',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_encounter;

    /********************************************************************************************
    * Retrieve options for creating/editing the end of an encounter.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_disch                 encounter discharge identifier
    * @param i_epis_encounter        encounter identifier
    * @param o_reasons               cursor
    * @param o_end_dt                encounter discharge date
    * @param o_notes                 encounter discharge notes
    * @param o_min_dt                encounter end date left bound
    * @param o_max_dt                encounter end date right bound
    * @param o_flg_warn              show "no encounter start date" warning (Y/N)
    * @param o_flg_type              flg_type of encounter
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Pedro Carneiro
    * @version                        2.5.0.7  
    * @since                         11/09/2009
    ********************************************************************************************/
    FUNCTION get_enc_discharge
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_disch          IN epis_encounter_disch.id_epis_encounter_disch%TYPE,
        i_epis_encounter IN epis_encounter.id_epis_encounter%TYPE,
        o_reasons        OUT pk_types.cursor_type,
        o_end_dt         OUT VARCHAR2,
        o_notes          OUT epis_encounter_disch.notes%TYPE,
        o_min_dt         OUT VARCHAR2,
        o_max_dt         OUT VARCHAR2,
        o_flg_warn       OUT VARCHAR2,
        o_flg_type       OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dt_init epis_encounter.dt_epis_encounter%TYPE;
        l_dt_end  epis_encounter_disch.dt_end%TYPE;
        l_dt_send VARCHAR2(32);
    
        CURSOR c_enc_init IS
            SELECT ee.dt_epis_encounter, flg_type
              FROM epis_encounter ee
             WHERE ee.id_epis_encounter = i_epis_encounter;
        CURSOR c_notes IS
            SELECT eed.notes, eed.dt_end
              FROM epis_encounter_disch eed
             WHERE eed.id_epis_encounter_disch = i_disch;
    BEGIN
        alertlog.pk_alertlog.log_debug('PARAMS[i_disch:' || i_disch || '; i_epis_encounter:' || i_epis_encounter ||
                                       '  ]',
                                       g_package_name,
                                       'GET_ENC_DISCHARGE');
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'OPEN c_enc_init';
        OPEN c_enc_init;
        FETCH c_enc_init
            INTO l_dt_init, o_flg_type;
        CLOSE c_enc_init;
    
        IF l_dt_init IS NOT NULL
        THEN
            -- encounter has start date: set it as end date left bound
            o_min_dt   := pk_date_utils.date_send_tsz(i_lang, l_dt_init, i_prof);
            o_flg_warn := pk_alert_constant.g_no;
        ELSE
            -- episode has no start date, prompt for warning
            o_min_dt   := NULL;
            o_flg_warn := pk_alert_constant.g_yes;
        END IF;
    
        -- end date right bound is current date
        l_dt_send := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
        o_max_dt  := l_dt_send;
    
        -- set default value for end date
    
        -- set default value for notes and reasons cursor
        IF i_disch IS NULL
        THEN
            o_notes  := NULL;
            o_end_dt := l_dt_send;
            pk_types.open_my_cursor(o_reasons);
        ELSE
            g_error := 'OPEN c_notes';
            OPEN c_notes;
            FETCH c_notes
                INTO o_notes, l_dt_end;
            CLOSE c_notes;
            IF l_dt_end IS NOT NULL
            THEN
                o_end_dt := pk_date_utils.date_send_tsz(i_lang, l_dt_end, i_prof);
            ELSE
                o_end_dt := l_dt_send;
            END IF;
            g_error := 'OPEN o_reasons';
            OPEN o_reasons FOR
                SELECT id_reason data, pk_translation.get_translation(i_lang, re.code_reason) label
                  FROM epis_enc_disch_reason eedr
                  JOIN reason_encounter re
                 USING (id_reason)
                 WHERE eedr.id_epis_encounter_disch = i_disch
                   AND re.flg_available = g_yes;
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
                                              'GET_ENC_DISCHARGE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_reasons);
            RETURN FALSE;
    END get_enc_discharge;

    /********************************************************************************************
    * Retrieve encounter discharges.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_epis_encounter        encounter identifier
    * @param o_disch                 cursor
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Pedro Carneiro
    * @version                        2.5.0.7  
    * @since                         11/09/2009
    ********************************************************************************************/
    FUNCTION get_enc_discharges
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_encounter IN epis_encounter.id_epis_encounter%TYPE,
        o_disch          OUT pk_types.cursor_type,
        o_flg_status     OUT epis_encounter.flg_status%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_br CONSTANT VARCHAR2(4) := '<br>';
        l_end_hour sys_message.desc_message%TYPE;
        l_reason   sys_message.desc_message%TYPE;
        l_notes    sys_message.desc_message%TYPE;
    
    BEGIN
        alertlog.pk_alertlog.log_debug('PARAMS[i_epis_encounter:' || i_epis_encounter || '  ]',
                                       g_package_name,
                                       'GET_ENC_DISCHARGES');
        l_end_hour := '<b>' || pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T093') || '</b> ';
        l_reason   := '<b>' || pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T061') || '</b> ';
        l_notes    := '<b>' || pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T048') || '</b> ';
    
        g_error := 'OPEN o_disch';
        OPEN o_disch FOR
            SELECT eed.id_epis_encounter_disch,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, eed.dt_register, i_prof) dt_begin,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, eed.id_professional) prof,
                   eed.flg_status,
                   l_end_hour ||
                   pk_date_utils.date_char_hour_tsz(i_lang, eed.dt_end, i_prof.institution, i_prof.software) || '<br>' ||
                   l_reason || pk_utils.query_to_string('SELECT pk_translation.get_translation(' || i_lang ||
                                                        ', re.code_reason )
                                                 FROM epis_enc_disch_reason eedr, reason_encounter re
                         WHERE eedr.id_epis_encounter_disch = ' ||
                                                        eed.id_epis_encounter_disch || '
                           AND eedr.id_reason = re.id_reason',
                                                        '; ') || '<br>' || l_notes || eed.notes encounter_reason
              FROM epis_encounter_disch eed
             WHERE eed.id_epis_encounter = i_epis_encounter
               AND eed.flg_status IN (g_disch_active, g_disch_canc)
             ORDER BY eed.dt_end DESC;
    
        g_error := 'OPEN c_encounter';
        OPEN c_encounter(i_epis_encounter);
        FETCH c_encounter
            INTO o_flg_status;
        CLOSE c_encounter;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ENC_DISCHARGES',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_disch);
            RETURN FALSE;
    END get_enc_discharges;

    /**********************************************************************************************
    * Inserts a set of discharge encounter reasons.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_epis_encounter        episode encounter identifier
    * @param i_reasons               management followup reasons
    * @param o_error                 error
    *
    * @return                        false, if errors occur, or true, otherwise.
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5.0.7
    * @since                         13-10-2009
    **********************************************************************************************/
    FUNCTION set_enc_disch_reas
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        id_epis_encounter_disch IN epis_encounter_disch.id_epis_encounter_disch%TYPE,
        i_reasons               IN table_number,
        o_discharge             OUT BOOLEAN,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows_out     table_varchar := table_varchar();
        l_eer_row      epis_enc_disch_reason%ROWTYPE;
        l_eer_row_coll ts_epis_enc_disch_reason.epis_enc_disch_reason_tc;
        l_id_discharge reason_encounter.id_reason%TYPE;
    BEGIN
        alertlog.pk_alertlog.log_debug('PARAMS[id_epis_encounter_disch:' || id_epis_encounter_disch ||
                                       ' i_reasons COUNT:' || i_reasons.count || '  ]',
                                       g_package_name,
                                       'SET_ENC_DISCH_REAS');
        -- for every specified reason, fill a row, and add it to the collection
        -- (all rows will have the same encounter_discharge identifier)
        o_discharge                       := FALSE;
        l_id_discharge                    := pk_sysconfig.get_config(i_code_cf => g_config_epis_discharge,
                                                                     i_prof    => i_prof);
        l_eer_row.id_epis_encounter_disch := id_epis_encounter_disch;
        IF i_reasons.count > 0
        THEN
            o_discharge := TRUE;
        
            -- insert all rows, and process all inserts
            g_error := 'CALL ts_epis_encounter_reason.ins';
            ts_epis_enc_disch_reason.ins(rows_in => l_eer_row_coll, rows_out => l_rows_out);
        
            g_error := 'CALL t_data_gov_mnt.process_insert';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_ENC_DISCH_REASON',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
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
                                              'SET_ENC_DISCH_REAS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_enc_disch_reas;

    /********************************************************************************************
    * Cancel an encounter discharge.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_epis_encounter        encounter identifier
    * @param i_disch                 encounter discharge identifier
    * @param i_canc_reas             cancel reason identifier
    * @param i_canc_notes            cancel notes
    * @param o_epis_encounter        encounter identifier
    * @param o_disch                 encounter discharge identifier
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Pedro Carneiro
    * @version                        2.5.0.7  
    * @since                         11/09/2009
    ********************************************************************************************/
    FUNCTION cancel_enc_discharge
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_encounter IN epis_encounter.id_epis_encounter%TYPE,
        i_disch          IN epis_encounter_disch.id_epis_encounter_disch%TYPE,
        i_canc_reas      IN epis_encounter_disch.id_cancel_reason%TYPE,
        i_canc_notes     IN epis_encounter_disch.notes%TYPE,
        o_epis_encounter OUT epis_encounter.id_epis_encounter%TYPE,
        o_disch          OUT epis_encounter_disch.id_epis_encounter_disch%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows_out          table_varchar := table_varchar();
        l_disch_status      epis_encounter_disch.flg_status%TYPE;
        l_disch             epis_encounter_disch.id_epis_encounter_disch%TYPE;
        l_enc_status        epis_encounter.flg_status%TYPE;
        l_id_epis_encounter epis_encounter_disch.id_epis_encounter%TYPE;
        CURSOR c_enc_discharge_reason IS
            SELECT id_reason
              FROM epis_enc_disch_reason ecdr
             WHERE ecdr.id_epis_encounter_disch = i_disch;
        l_reasons    table_number := table_number();
        l_disch_bool BOOLEAN := FALSE;
    
        CURSOR c_enc_discharge IS
            SELECT eed.dt_end, eed.notes, eed.id_epis_encounter
              FROM epis_encounter_disch eed
             WHERE eed.id_epis_encounter_disch = i_disch;
    
        r_enc_disch    c_enc_discharge%ROWTYPE;
        l_opinion      opinion.id_opinion%TYPE;
        l_opinion_prof opinion_prof.id_opinion_prof%TYPE;
        CURSOR c_opinion IS
            SELECT id_opinion
              FROM opinion o, episode e, epis_encounter ee
             WHERE e.id_episode = ee.id_epis_encounter
               AND ee.id_epis_encounter = i_epis_encounter
               AND o.flg_type = g_opn_flg_type_c
               AND e.id_episode = o.id_episode_answer;
    
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
    
        CURSOR c_discharge IS
            SELECT d.id_discharge
              FROM epis_encounter ee, episode e, discharge d
             WHERE id_epis_encounter = i_epis_encounter
               AND ee.id_episode = e.id_episode
               AND e.id_episode = d.id_episode;
    
        l_id_discharge discharge.id_discharge%TYPE;
    
    BEGIN
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(l_transaction_id, i_prof);
    
        alertlog.pk_alertlog.log_debug('PARAMS[i_epis_encounter:' || i_epis_encounter || ' ;i_disch:' || i_disch ||
                                       ';i_canc_reas:' || i_canc_reas || '  ]',
                                       g_package_name,
                                       'CANCEL_ENC_DISCHARGE');
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'OPEN c_enc_disch ' || i_disch;
        OPEN c_enc_disch(i_disch);
        FETCH c_enc_disch
            INTO l_disch_status;
        CLOSE c_enc_disch;
    
        IF l_disch_status != g_disch_active
        THEN
            RAISE g_outdated;
        END IF;
    
        OPEN c_enc_discharge;
        FETCH c_enc_discharge
            INTO r_enc_disch;
        CLOSE c_enc_discharge;
    
        IF i_epis_encounter IS NULL
        THEN
            l_id_epis_encounter := r_enc_disch.id_epis_encounter;
        ELSE
            l_id_epis_encounter := i_epis_encounter;
        END IF;
        g_error := 'CALL ts_epis_encounter_disch.upd';
        ts_epis_encounter_disch.upd(id_epis_encounter_disch_in => i_disch,
                                    flg_status_in              => g_disch_outd,
                                    rows_out                   => l_rows_out);
        g_error := 'CALL t_data_gov_mnt.process_update 1';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_ENCOUNTER_DISCH',
                                      i_rowids       => l_rows_out,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_STATUS'));
    
        l_rows_out := table_varchar();
        g_error    := 'CALL ts_epis_encounter_disch.ins';
        ts_epis_encounter_disch.ins(id_epis_encounter_disch_out => l_disch,
                                    id_epis_encounter_in        => l_id_epis_encounter,
                                    id_professional_in          => i_prof.id,
                                    dt_register_in              => g_sysdate_tstz,
                                    dt_end_in                   => r_enc_disch.dt_end,
                                    flg_status_in               => g_disch_canc,
                                    notes_in                    => r_enc_disch.notes,
                                    id_cancel_reason_in         => i_canc_reas,
                                    notes_cancel_in             => i_canc_notes,
                                    id_parent_in                => i_disch,
                                    rows_out                    => l_rows_out);
        g_error := 'CALL t_data_gov_mnt.process_insert 1';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPIS_ENCOUNTER_DISCH',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        -- copy reasons       
        g_error := 'OPEN c_epis_encounter_reason';
        OPEN c_enc_discharge_reason;
        FETCH c_enc_discharge_reason BULK COLLECT
            INTO l_reasons;
        CLOSE c_enc_discharge_reason;
    
        IF l_reasons IS NOT NULL
        THEN
            g_error := 'SET_ENC_DISCH_REAS ';
            IF NOT set_enc_disch_reas(i_lang                  => i_lang,
                                      i_prof                  => i_prof,
                                      id_epis_encounter_disch => l_disch,
                                      i_reasons               => l_reasons,
                                      o_discharge             => l_disch_bool,
                                      o_error                 => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        g_error := 'OPEN c_encounter ' || r_enc_disch.id_epis_encounter;
        OPEN c_encounter(l_id_epis_encounter);
        FETCH c_encounter
            INTO l_enc_status;
        CLOSE c_encounter;
    
        IF l_enc_status != g_enc_flg_status_i
        THEN
            RAISE g_outdated;
        END IF;
    
        l_rows_out := table_varchar();
        g_error    := 'CALL ts_epis_encounter.upd';
        ts_epis_encounter.upd(id_epis_encounter_in => l_id_epis_encounter,
                              flg_status_in        => g_enc_flg_status_a,
                              rows_out             => l_rows_out);
        g_error := 'CALL t_data_gov_mnt.process_update 2';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_ENCOUNTER',
                                      i_rowids       => l_rows_out,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_STATUS'));
    
        l_rows_out := table_varchar();
        g_error    := 'CALL ts_epis_encounter';
        g_error    := '';
        -- cancel the discharge from episode case it is 
        IF l_disch_bool
        THEN
            g_error := 'OPEN c_discharge ';
            OPEN c_discharge;
            FETCH c_discharge
                INTO l_id_discharge;
            CLOSE c_discharge;
        
            IF NOT pk_discharge.cancel_discharge(i_lang             => i_lang,
                                                 i_id_discharge     => l_id_discharge,
                                                 i_prof             => i_prof,
                                                 i_notes_cancel     => i_canc_notes,
                                                 i_id_cancel_reason => i_canc_reas,
                                                 i_transaction_id   => l_transaction_id,
                                                 o_error            => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'OPEN c_opinion';
            OPEN c_opinion;
            FETCH c_opinion
                INTO l_opinion;
            CLOSE c_opinion;
            IF l_opinion IS NOT NULL
            THEN
                g_error := 'CALL create_prof_conclusion_int';
                IF NOT pk_opinion.create_prof_conclusion_int(i_lang         => i_lang,
                                                             i_opinion      => l_opinion,
                                                             i_prof         => i_prof,
                                                             i_flg_type     => g_opn_prof_flg_type_a,
                                                             i_commit_data  => g_no,
                                                             o_opinion_prof => l_opinion_prof,
                                                             o_error        => o_error)
                THEN
                
                    RAISE g_exception;
                END IF;
            END IF;
        
        END IF;
    
        pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        COMMIT;
        o_epis_encounter := 0;
        o_disch          := l_disch;
        RETURN TRUE;
    EXCEPTION
        WHEN g_outdated THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes; -- ROLLBACK
            RETURN process_outdated(i_lang => i_lang, i_func => 'CANCEL_ENC_DISCHARGE', o_error => o_error);
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_ENC_DISCHARGE',
                                              o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes; -- ROLLBACK
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_enc_discharge;

    /********************************************************************************************
    * Set encounter discharge.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_prof_cat              logged professional category
    * @param i_disch                 encounter discharge identifier
    * @param i_episode               episode identifier
    * @param i_epis_encounter        encounter identifier
    * @param i_dt_end                discharge date
    * @param i_notes                 discharge notes_med
    * @param i_disch_reason          list of reasons of discharge
    * @param o_flg_show              warn
    * @param o_msg_title             warn
    * @param o_msg_text              warn
    * @param o_button                warn
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Pedro Carneiro
    * @version                        2.5.0.7  
    * @since                         11/09/2009
    ********************************************************************************************/
    FUNCTION set_enc_discharge
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_prof_cat       IN category.flg_type%TYPE,
        i_disch          IN epis_encounter_disch.id_epis_encounter_disch%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_epis_encounter IN epis_encounter.id_epis_encounter%TYPE,
        i_dt_end         IN VARCHAR2,
        i_notes          IN discharge.notes_med%TYPE,
        i_disch_reason   IN table_number,
        o_flg_show       OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_msg_text       OUT VARCHAR2,
        o_button         OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows_out           table_varchar := table_varchar();
        l_dt_end             epis_encounter_disch.dt_end%TYPE;
        l_status             epis_encounter_disch.flg_status%TYPE;
        l_disch              epis_encounter_disch.id_epis_encounter_disch%TYPE;
        l_discharge          BOOLEAN;
        l_disch_reas_dest_cm disch_reas_dest.id_disch_reas_dest%TYPE;
        l_opinion            opinion.id_opinion%TYPE;
        l_opinion_prof       opinion_prof.id_opinion_prof%TYPE;
        CURSOR c_opinion IS
            SELECT id_opinion
              FROM opinion o
             WHERE o.id_episode_answer = i_episode
               AND o.flg_type = g_opn_flg_type_c;
    
    BEGIN
        alertlog.pk_alertlog.log_debug('PARAMS[i_prof_cat:' || i_prof_cat || ' ;i_disch:' || i_disch || ';i_episode:' ||
                                       i_episode || ';i_epis_encounter:' || i_epis_encounter || '; i_dt_end:' ||
                                       i_dt_end || ' ]',
                                       g_package_name,
                                       'SET_ENC_DISCHARGE');
        g_sysdate_tstz := current_timestamp;
        l_dt_end       := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_timestamp => i_dt_end,
                                                        i_timezone  => NULL);
    
        IF i_disch IS NOT NULL
        THEN
            g_error := 'OPEN c_enc_disch ' || i_disch;
            OPEN c_enc_disch(i_disch);
            FETCH c_enc_disch
                INTO l_status;
            CLOSE c_enc_disch;
        
            IF l_status != g_disch_active
            THEN
                RAISE g_outdated;
            END IF;
        
            g_error := 'CALL ts_epis_encounter_disch.upd';
            ts_epis_encounter_disch.upd(id_epis_encounter_disch_in => i_disch,
                                        flg_status_in              => g_disch_outd,
                                        rows_out                   => l_rows_out);
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'EPIS_ENCOUNTER_DISCH',
                                          i_rowids       => l_rows_out,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_STATUS'));
        END IF;
    
        --verify if the encounter is still active
        IF i_epis_encounter IS NOT NULL
        THEN
            g_error := 'OPEN c_encounter';
            OPEN c_encounter(i_epis_encounter);
            FETCH c_encounter
                INTO l_status;
            CLOSE c_encounter;
        
            IF l_status IN (g_enc_flg_status_o, g_enc_flg_status_c)
               OR (l_status = g_enc_flg_status_i AND i_disch IS NULL) -- status not Requested/active
            THEN
                RAISE g_outdated;
            END IF;
        
            l_rows_out := table_varchar();
            g_error    := 'CALL ts_epis_encounter_disch.ins';
            ts_epis_encounter_disch.ins(id_epis_encounter_disch_out => l_disch,
                                        id_epis_encounter_in        => i_epis_encounter,
                                        id_professional_in          => i_prof.id,
                                        dt_register_in              => g_sysdate_tstz,
                                        dt_end_in                   => l_dt_end,
                                        flg_status_in               => g_disch_active,
                                        notes_in                    => i_notes,
                                        id_parent_in                => i_disch,
                                        rows_out                    => l_rows_out);
            g_error := 'CALL t_data_gov_mnt.process_insert';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_ENCOUNTER_DISCH',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        END IF;
    
        -- associate the reasons for discharge
        IF NOT set_enc_disch_reas(i_lang                  => i_lang,
                                  i_prof                  => i_prof,
                                  id_epis_encounter_disch => l_disch,
                                  i_reasons               => i_disch_reason,
                                  o_discharge             => l_discharge,
                                  o_error                 => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF i_epis_encounter IS NOT NULL
        THEN
            -- INACTIVAR O ENCOUNTRO
            l_rows_out := table_varchar();
            g_error    := 'CALL TS_EPIS_ENCOUNTER.UPD';
            ts_epis_encounter.upd(id_epis_encounter_in => i_epis_encounter,
                                  flg_status_in        => g_enc_flg_status_i,
                                  rows_out             => l_rows_out);
            g_error := 'CALL t_data_gov_mnt.process_insert';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_ENCOUNTER',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
        END IF;
        IF l_discharge
        THEN
            -- dar alta ao episódio
            g_error              := 'CALL set_discharge';
            l_disch_reas_dest_cm := pk_sysconfig.get_config('DEFAULT_DISCH_REAS_DEST_CASEMANAGER', i_prof);
            IF NOT pk_discharge.set_discharge(i_lang          => i_lang,
                                              i_episode       => i_episode,
                                              i_prof          => i_prof,
                                              i_reas_dest     => l_disch_reas_dest_cm,
                                              i_disch_type    => g_disch_type_f,
                                              i_flg_type      => g_disch_type_disch_c,
                                              i_notes         => i_notes,
                                              i_transp        => NULL,
                                              i_justify       => NULL,
                                              i_prof_cat_type => i_prof_cat,
                                              i_flg_surgery   => NULL,
                                              i_clin_serv     => NULL,
                                              i_department    => NULL,
                                              o_flg_show      => o_flg_show,
                                              o_msg_title     => o_msg_title,
                                              o_msg_text      => o_msg_text,
                                              o_button        => o_button,
                                              o_error         => o_error)
            THEN
                RETURN FALSE;
            END IF;
            OPEN c_opinion;
            FETCH c_opinion
                INTO l_opinion;
            CLOSE c_opinion;
            IF l_opinion IS NOT NULL
            THEN
                IF NOT pk_opinion.create_prof_conclusion_int(i_lang         => i_lang,
                                                             i_opinion      => l_opinion,
                                                             i_prof         => i_prof,
                                                             i_flg_type     => g_opn_prof_flg_type_c,
                                                             i_commit_data  => g_no,
                                                             o_opinion_prof => l_opinion_prof,
                                                             o_error        => o_error)
                THEN
                
                    RAISE g_exception;
                END IF;
            END IF;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_outdated THEN
            pk_utils.undo_changes;
            RETURN process_outdated(i_lang => i_lang, i_func => 'SET_ENC_DISCHARGE', o_error => o_error);
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ENC_DISCHARGE',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_enc_discharge;

    /********************************************************************************************
    * Retrieve encounter discharge reasons.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_epis_encounter        encounter identifier
    * @param o_reasons               cursor
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Pedro Carneiro
    * @version                        2.5.0.7  
    * @since                         11/09/2009
    ********************************************************************************************/
    FUNCTION get_enc_disch_reasons
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_encounter IN epis_encounter.id_epis_encounter%TYPE,
        o_reasons        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        alertlog.pk_alertlog.log_debug('PARAMS[i_epis_encounter:' || i_epis_encounter || ' ]',
                                       g_package_name,
                                       'GET_ENC_DISCH_REASONS');
        g_error := 'OPEN o_reasons';
        OPEN o_reasons FOR
            SELECT re.id_reason data, pk_translation.get_translation(i_lang, re.code_reason) label
              FROM epis_encounter ee
              JOIN reason_encounter re
             USING (flg_type)
             WHERE ee.id_epis_encounter = i_epis_encounter
               AND re.flg_available = g_yes;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ENC_DISCH_REASONS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_reasons);
            RETURN FALSE;
    END get_enc_disch_reasons;

    /********************************************************************************************
    * Retrieve an encounter discharge history of operations.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_disch                 discharge identifier
    * @param o_hist                  cursor
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Pedro Carneiro
    * @version                        2.5.0.7  
    * @since                         11/09/2009
    ********************************************************************************************/
    FUNCTION get_enc_disch_hist
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_disch IN epis_encounter_disch.id_epis_encounter_disch%TYPE,
        o_hist  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_na CONSTANT VARCHAR2(2) := '--';
        l_br CONSTANT VARCHAR2(4) := '<br>';
        l_msg_oper_add   sys_message.desc_message%TYPE;
        l_msg_oper_edit  sys_message.desc_message%TYPE;
        l_msg_oper_canc  sys_message.desc_message%TYPE;
        l_msg_reasons    sys_message.desc_message%TYPE;
        l_msg_time       sys_message.desc_message%TYPE;
        l_msg_notes      sys_message.desc_message%TYPE;
        l_msg_canc_rea   sys_message.desc_message%TYPE;
        l_msg_canc_notes sys_message.desc_message%TYPE;
    BEGIN
        alertlog.pk_alertlog.log_debug('PARAMS[i_disch:' || i_disch || ']', g_package_name, 'GET_ENC_DISCH_HIST');
    
        l_msg_oper_add   := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T054');
        l_msg_oper_edit  := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T055');
        l_msg_oper_canc  := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T056');
        l_msg_reasons    := '<b>' || pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T061') || ' </b>';
        l_msg_time       := '<b>' || pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T093') || ' </b>';
        l_msg_notes      := '<b>' || pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T058') || ' </b>';
        l_msg_canc_rea   := '<b>' || pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T059') || ' </b>';
        l_msg_canc_notes := '<b>' || pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T060') || ' </b>';
    
        g_error := 'open o_hist';
        OPEN o_hist FOR
            SELECT decode(eed.id_parent,
                          NULL,
                          l_msg_oper_add,
                          decode(eed.flg_status, g_disch_canc, l_msg_oper_canc, l_msg_oper_edit)) operation,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, eed.dt_register, i_prof) reg_date,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, eed.id_professional) prof_name,
                   decode(eed.flg_status,
                          g_disch_canc,
                          l_msg_canc_rea || (SELECT pk_translation.get_translation(i_lang,
                                                                                   'CANCEL_REASON.CODE_CANCEL_REASON.' ||
                                                                                   eed.id_cancel_reason)
                                               FROM dual) || l_br || l_msg_canc_notes || nvl(eed.notes_cancel, l_na),
                          l_msg_time ||
                          pk_date_utils.date_char_hour_tsz(i_lang, eed.dt_end, i_prof.institution, i_prof.software) || l_br ||
                          l_msg_reasons || pk_utils.query_to_string('SELECT pk_translation.get_translation(' || i_lang ||
                                                                    ', re.code_reason )
                                                 FROM epis_enc_disch_reason eedr, reason_encounter re
                         WHERE eedr.id_epis_encounter_disch = ' ||
                                                                    eed.id_epis_encounter_disch || '
                           AND eedr.id_reason = re.id_reason',
                                                                    '; ') || l_br || l_msg_notes || nvl(eed.notes, l_na)) history
              FROM epis_encounter_disch eed
            CONNECT BY PRIOR eed.id_parent = eed.id_epis_encounter_disch
             START WITH eed.id_epis_encounter_disch = i_disch;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ENC_DISCH_HIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_hist);
            RETURN FALSE;
    END get_enc_disch_hist;

    /**********************************************************************************************
    * Gets the list os encounters of a CM episode
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient
    * @param i_episode               ID Episode
    *
    * @param o_mng_followup          Cursor with all the encounters
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         11-09-2009
    **********************************************************************************************/

    FUNCTION get_mng_follow_up_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_mng_followup OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        alertlog.pk_alertlog.log_debug('PARAMS[i_patient:' || i_patient || '; i_episode:' || i_episode || ' ]',
                                       g_package_name,
                                       'GET_MNG_FOLLOW_UP_LIST');
        g_error := 'GET CURSOR O_MNG_FOLLOWUP';
        OPEN o_mng_followup FOR
            SELECT ee.id_epis_encounter,
                   ee.id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ee.id_professional) prof_name,
                   
                   pk_utils.query_to_string('SELECT PK_TRANSLATION.get_translation(' || i_lang ||
                                            ',RE.CODE_REASON)
												FROM EPIS_ENCOUNTER_REASON ECR, REASON_ENCOUNTER RE												
												WHERE ECR.ID_EPIS_ENCOUNTER = ' || ee.id_epis_encounter || '
												AND ECR.ID_REASON = RE.ID_REASON',
                                            '; ') encounter_reason,
                   pk_date_utils.dt_chr_hour_tsz(i_lang, ee.dt_epis_encounter, i_prof) encounter_hour,
                   pk_date_utils.dt_chr_tsz(i_lang, ee.dt_epis_encounter, i_prof) encounter_date,
                   ee.flg_status,
                   decode(ee.flg_status, g_enc_flg_status_c, 4, g_enc_flg_status_i, 3, g_enc_flg_status_r, 2, 1) rank,
                   decode(ee.flg_status, g_enc_flg_status_r, g_yes, g_no) flg_cancel,
                   decode(ee.flg_status, g_enc_flg_status_c, g_enc_flg_status_i, ee.flg_status) flg_status_action,
                   pk_date_utils.to_char_insttimezone(i_prof, ee.dt_epis_encounter, 'YYYYMMDDHH24MISS') date_encounter,
                   decode(ee.flg_status,
                          g_enc_flg_status_c,
                          decode(ee.notes_cancel, NULL, NULL, pk_message.get_message(i_lang, i_prof, 'COMMON_M008')),
                          decode(pk_string_utils.clob_to_sqlvarchar2(ee.notes),
                                 NULL,
                                 NULL,
                                 pk_message.get_message(i_lang, i_prof, 'COMMON_M008'))) notes_title,
                   pk_date_utils.dt_chr_date_hour(i_lang, ee.dt_epis_encounter, i_prof) encounter_date_hour
            
              FROM epis_encounter ee
             WHERE ee.id_episode = i_episode
               AND ee.id_patient = i_patient
               AND ee.flg_status <> g_enc_flg_status_o
             ORDER BY rank, ee.dt_epis_encounter;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_MNG_FOLLOW_UP_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_mng_followup);
            RETURN FALSE;
        
    END get_mng_follow_up_list;

    /**********************************************************************************************
    * Gets the list of encounter reasons
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_flg_type              FLG_TYPE (F - first encounter/ U - follow-up encounter)
    *
    * @param o_mng_followup          Cursor with all the encounters
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         11-09-2009
    **********************************************************************************************/
    FUNCTION get_reasons_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_type IN epis_encounter.flg_type%TYPE,
        o_reasons  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        alertlog.pk_alertlog.log_debug('PARAMS[i_flg_type:' || i_flg_type || ' ]', g_package_name, 'GET_REASONS_LIST');
        g_error := 'OPEN o_reasons';
        OPEN o_reasons FOR
            SELECT r.id_reason, pk_translation.get_translation(i_lang, r.code_reason) reason_desc
              FROM reason_encounter r
             WHERE r.flg_type = i_flg_type
               AND flg_available = g_yes;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_REASONS_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_reasons);
            RETURN FALSE;
        
    END get_reasons_list;

    /**********************************************************************************************
    * Retrieves a case management follow up history of operations.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_mng_plan_followup     management followup identifier
    *
    
    * @param o_follow_register       cursor with professional 
    * @param o_follow                cursor with the information of follow up 
    * @param o_error                 error
    *
    * @return                        false, if errors occur, or true, otherwise.
    *                        
    * @author                        Elisabere Bugalho
    * @version                        2.5.0.7
    * @since                         30-09-20009
    **********************************************************************************************/
    FUNCTION get_mng_followup_detail
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_mng_plan_followup IN management_follow_up.id_management_follow_up%TYPE,
        o_follow_register   OUT pk_types.cursor_type,
        o_follow            OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_msg_oper_add   sys_message.desc_message%TYPE;
        l_msg_oper_edit  sys_message.desc_message%TYPE;
        l_msg_oper_canc  sys_message.desc_message%TYPE;
        l_msg_reasons    sys_message.desc_message%TYPE;
        l_msg_time       sys_message.desc_message%TYPE;
        l_msg_notes      sys_message.desc_message%TYPE;
        l_msg_canc_rea   sys_message.desc_message%TYPE;
        l_msg_canc_notes sys_message.desc_message%TYPE;
    BEGIN
        alertlog.pk_alertlog.log_debug('PARAMS[i_mng_plan_followup:' || i_mng_plan_followup || ' ]',
                                       g_package_name,
                                       'GET_MNG_FOLLOWUP_DETAIL');
        l_msg_oper_add   := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T054');
        l_msg_oper_edit  := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T055');
        l_msg_oper_canc  := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T056');
        l_msg_reasons    := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T061');
        l_msg_time       := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T057');
        l_msg_notes      := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T058');
        l_msg_canc_rea   := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T059');
        l_msg_canc_notes := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T060');
    
        g_error := 'OPEN o_follow_register';
    
        OPEN o_follow_register FOR
            SELECT mfu.id_management_follow_up,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, dt_register, i_prof) dt_register,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, mfu.id_professional) nick_name,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, mfu.id_professional, mfu.dt_register, NULL) desc_speciality,
                   decode(mfu.id_parent,
                          NULL,
                          l_msg_oper_add,
                          decode(mfu.flg_status,
                                 g_mnp_flg_status_o,
                                 l_msg_oper_edit,
                                 g_mnp_flg_status_a,
                                 l_msg_oper_edit,
                                 l_msg_oper_canc)) desc_title
              FROM management_follow_up mfu
            CONNECT BY PRIOR mfu.id_parent = mfu.id_management_follow_up
             START WITH mfu.id_management_follow_up = i_mng_plan_followup;
    
        g_error := 'OPEN o_follow';
        OPEN o_follow FOR
            SELECT mfu.id_management_follow_up,
                   decode(mfu.flg_status, g_mfu_status_canc, NULL, l_msg_reasons) follow_reason_title,
                   decode(mfu.flg_status,
                          g_mfu_status_canc,
                          NULL,
                          pk_utils.query_to_string('SELECT PK_TRANSLATION.get_translation(' || i_lang ||
                                                   ',RE.CODE_REASON)
												FROM MANAGEMENT_FOLLOW_REASON MFR, REASON_ENCOUNTER RE												
												WHERE MFR.ID_MANAGEMENT_FOLLOW_UP = ' ||
                                                   mfu.id_management_follow_up || '
												AND MFR.ID_REASON = RE.ID_REASON',
                                                   ';')) encounter_reason,
                   decode(mfu.flg_status, g_mfu_status_canc, NULL, l_msg_time) time_title,
                   decode(mfu.flg_status,
                          g_mfu_status_canc,
                          NULL,
                          mfu.time_spent || ' ' ||
                          decode(pk_translation.get_translation(i_lang, u.code_unit_measure_abrv),
                                 NULL,
                                 pk_translation.get_translation(i_lang, u.code_unit_measure),
                                 pk_translation.get_translation(i_lang, u.code_unit_measure_abrv))) time_spent,
                   decode(mfu.flg_status, g_mfu_status_canc, NULL, l_msg_notes) notes_title,
                   decode(mfu.flg_status, g_mfu_status_canc, NULL, mfu.notes) notes,
                   decode(mfu.flg_status, g_mfu_status_canc, l_msg_canc_rea, NULL) cancel_reason_title,
                   decode(mfu.flg_status,
                          g_mfu_status_canc,
                          (SELECT pk_translation.get_translation(i_lang,
                                                                 'CANCEL_REASON.CODE_CANCEL_REASON.' ||
                                                                 mfu.id_cancel_reason)
                             FROM dual),
                          NULL) cancel_reason,
                   decode(mfu.flg_status, g_mfu_status_canc, l_msg_canc_notes, NULL) cancel_notes_title,
                   mfu.notes_cancel
              FROM management_follow_up mfu, unit_measure u
             WHERE mfu.id_unit_time = u.id_unit_measure
               AND mfu.id_management_follow_up IN
                   (SELECT id_management_follow_up
                      FROM management_follow_up mp1
                    CONNECT BY PRIOR mp1.id_parent = mp1.id_management_follow_up
                     START WITH mp1.id_management_follow_up = i_mng_plan_followup)
             ORDER BY mfu.dt_register DESC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_MNG_FOLLOWUP_DETAIL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_follow_register);
            pk_types.open_my_cursor(o_follow);
            RETURN FALSE;
    END get_mng_followup_detail;

    /**********************************************************************************************
    * Retrieves the time spent on CM Episode.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_episode               ID Episode
    *
    
    * @return                        String with time spent
    *                        
    * @author                        Elisabere Bugalho
    * @version                       2.5.0.7
    * @since                         12-10-2009
    **********************************************************************************************/
    FUNCTION get_time_spent
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN epis_encounter.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_id_unit_time unit_measure.id_unit_measure%TYPE;
        l_time         NUMBER;
        l_num          NUMBER;
        l_desc_unit    sys_message.desc_message%TYPE;
        l_time_spent   VARCHAR2(32767);
    BEGIN
        alertlog.pk_alertlog.log_debug('PARAMS[i_episode:' || i_episode || ' ]', g_package_name, 'GET_TIME_SPENT');
        l_id_unit_time := pk_sysconfig.get_config(i_code_cf => 'CASE_MANAGER_UNIT_TIME', i_prof => i_prof);
    
        -- determine if the episode has follow_up records
        g_error := 'DETERMINE FOLLOW-UP';
        SELECT COUNT(1)
          INTO l_num
          FROM management_follow_up mfu
         WHERE mfu.id_episode = i_episode
           AND mfu.flg_status IN (g_mnp_flg_status_a);
    
        -- calculate the time spent
        g_error := 'CALCULATE TIME SPENT';
        SELECT SUM(time_spent)
          INTO l_time
          FROM (SELECT decode(mfu.id_unit_time,
                              l_id_unit_time,
                              mfu.time_spent,
                              pk_unit_measure.get_unit_mea_conversion(mfu.time_spent, mfu.id_unit_time, l_id_unit_time)) time_spent
                
                  FROM management_follow_up mfu
                 WHERE mfu.id_episode = i_episode
                   AND mfu.flg_status IN (g_mnp_flg_status_a));
    
        IF l_num > 0 -- has records
        THEN
            g_error := 'DETERMINE UNIT TIME';
            SELECT decode(pk_translation.get_translation(i_lang, u.code_unit_measure),
                          NULL,
                          pk_translation.get_translation(i_lang, u.code_unit_measure_abrv),
                          pk_translation.get_translation(i_lang, u.code_unit_measure))
              INTO l_desc_unit
              FROM unit_measure u
             WHERE u.id_unit_measure = l_id_unit_time;
        
            l_time_spent := l_time || ' ' || l_desc_unit;
        END IF;
        RETURN l_time_spent;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    /********************************************************************************************
    * Checks the discharge
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_episode               episode identifier
    * @param i_epis_encounter        encounter identifier
    * @param O_FLG_SHOW              Y - existe msg para mostrar; N - ñ existe
    * @param O_MSG                   mensagem no caso se ir dar alta ao episódio
    * @param O_MSG_TITLE             Título da msg a mostrar ao utilizador, 
    * @param O_BUTTON                Botões a mostrar: N - não, R - lido, C - confirmado; NC - Não e Confirmado
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Elisabete Bugalho
    * @version                       2.5.0.7  
    * @since                         14-10-2009
    ********************************************************************************************/
    FUNCTION check_discharge
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN epis_encounter.id_episode%TYPE,
        i_encounter    IN epis_encounter.id_epis_encounter%TYPE,
        i_disch_reason IN table_number,
        o_flg_show     OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_msg_text     OUT VARCHAR2,
        o_button       OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exist_idx    NUMBER;
        l_id_discharge reason_encounter.id_reason%TYPE;
        CURSOR c_exist_encounter IS
            SELECT COUNT(1)
              FROM epis_encounter
             WHERE id_episode = i_episode
               AND flg_status IN (g_enc_flg_status_r, g_enc_flg_status_a)
               AND id_epis_encounter <> i_encounter;
        l_num NUMBER;
    BEGIN
        alertlog.pk_alertlog.log_debug('PARAMS[i_episode:' || i_episode || ';i_encounter:' || i_encounter || ' ]',
                                       g_package_name,
                                       'CHECK_DISCHARGE');
        o_flg_show     := g_no;
        l_id_discharge := pk_sysconfig.get_config(i_code_cf => g_config_epis_discharge, i_prof => i_prof);
        l_exist_idx    := pk_utils.search_table_number(i_table => i_disch_reason, i_search => l_id_discharge);
        IF l_exist_idx > 0
        THEN
            o_flg_show  := 'Y';
            o_button    := 'NC';
            o_msg_title := pk_message.get_message(i_lang, i_prof, 'COMMON_T013');
        
            -- determine if exists active encounters
            OPEN c_exist_encounter;
            FETCH c_exist_encounter
                INTO l_num;
            CLOSE c_exist_encounter;
            IF l_num > 0 -- there are encounters
            THEN
                o_msg_text := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_M007');
            ELSE
                o_msg_text := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_M006');
            END IF;
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
                                              'CHECK_DISCHARGE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END check_discharge;

    /**********************************************************************************************
    * Gets the information of a concat
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_epis_encounter        ID Encounter
    * @param i_episode               ID Episode
    *
    * @param o_encounter             Cursor with the information of concat
    * @param o_reasons               Cursor with the reason of concat
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         20-10-2009
    **********************************************************************************************/

    FUNCTION get_encounter
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_encounter IN epis_encounter.id_epis_encounter%TYPE,
        i_episode        IN epis_encounter.id_episode%TYPE,
        o_encounter      OUT pk_types.cursor_type,
        o_reasons        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        alertlog.pk_alertlog.log_debug('PARAMS[i_epis_encounter:' || i_epis_encounter || ' ]',
                                       g_package_name,
                                       'GET_ENCOUNTER');
        g_error := 'GET CURSOR O_ENCOUNTER';
        IF i_epis_encounter IS NOT NULL
        THEN
            OPEN o_encounter FOR
                SELECT ee.id_epis_encounter,
                       ee.id_professional,
                       pk_date_utils.to_char_insttimezone(i_prof, ee.dt_epis_encounter, 'YYYYMMDDHH24MISS') encounter_date,
                       ee.flg_status,
                       ee.flg_type,
                       (SELECT sd.desc_val
                          FROM sys_domain sd
                         WHERE sd.code_domain = g_domain_enc_flg_type
                           AND sd.domain_owner = pk_sysdomain.k_default_schema
                           AND sd.val = ee.flg_type
                           AND sd.id_language = i_lang) type_encounter,
                       ee.notes,
                       pk_date_utils.date_send_tsz(i_lang, e.dt_begin_tstz, i_prof) dt_min,
                       pk_prof_utils.get_name_signature(i_lang,
                                                        profissional(ee.id_professional, NULL, NULL),
                                                        ee.id_professional) prof_name
                  FROM epis_encounter ee, episode e
                 WHERE ee.id_epis_encounter = i_epis_encounter
                   AND ee.id_episode = e.id_episode;
        
            g_error := 'GET CURSOR O_REASONS';
            OPEN o_reasons FOR
                SELECT re.id_reason,
                       pk_translation.get_translation(i_lang, re.code_reason) desc_reason,
                       decode(eer.id_reason, NULL, g_no, g_yes) flg_select
                  FROM reason_encounter re, epis_encounter_reason eer
                 WHERE eer.id_epis_encounter = i_epis_encounter
                   AND re.id_reason = eer.id_reason;
        ELSE
            OPEN o_encounter FOR
                SELECT NULL id_epis_encounter,
                       NULL id_professional,
                       NULL encounter_date,
                       NULL flg_status,
                       g_enc_followup flg_type,
                       (SELECT sd.desc_val
                          FROM sys_domain sd
                         WHERE sd.code_domain = g_domain_enc_flg_type
                           AND sd.domain_owner = pk_sysdomain.k_default_schema
                           AND sd.val = g_enc_followup
                           AND sd.id_language = i_lang) type_encounter,
                       NULL notes,
                       pk_date_utils.date_send_tsz(i_lang, e.dt_begin_tstz, i_prof) dt_min,
                       NULL prof_name
                  FROM episode e
                 WHERE e.id_episode = i_episode;
        
            pk_types.open_my_cursor(o_reasons);
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
                                              'GET_ENCOUNTER',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_encounter);
            pk_types.open_my_cursor(o_reasons);
        
            RETURN FALSE;
    END get_encounter;

    /**********************************************************************************************
    * Gets the information of a concat
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_epis_encounter        ID Encounter
    * @param i_episode               ID Episode
    *
    * @param o_encounter             Cursor with the information of concat
    * @param o_reasons               Cursor with the reason of concat
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         20-10-2009
    **********************************************************************************************/

    FUNCTION get_encounter_detail
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_encounter IN epis_encounter.id_epis_encounter%TYPE,
        o_register       OUT pk_types.cursor_type,
        o_encounter      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_msg_oper_add   sys_message.desc_message%TYPE;
        l_msg_oper_edit  sys_message.desc_message%TYPE;
        l_msg_oper_canc  sys_message.desc_message%TYPE;
        l_encounter_date sys_message.desc_message%TYPE;
        l_case_manager   sys_message.desc_message%TYPE;
        l_reason         sys_message.desc_message%TYPE;
        l_notes          sys_message.desc_message%TYPE;
        l_msg_canc_rea   sys_message.desc_message%TYPE;
        l_msg_canc_notes sys_message.desc_message%TYPE;
    BEGIN
        alertlog.pk_alertlog.log_debug('PARAMS[i_epis_encounter:' || i_epis_encounter || ' ]',
                                       g_package_name,
                                       'GET_ENCOUNTER_DETAIL');
    
        l_msg_oper_add   := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T054');
        l_msg_oper_edit  := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T055');
        l_msg_oper_canc  := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T056');
        l_encounter_date := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T096');
        l_case_manager   := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T074');
        l_reason         := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T046');
        l_notes          := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T013');
    
        l_msg_canc_rea   := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T059');
        l_msg_canc_notes := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T060');
    
        g_error := 'GET CURSOR O_REGISTER';
        OPEN o_register FOR
            SELECT ee.id_epis_encounter,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, dt_create, i_prof) dt_register,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ee.id_prof_create) nick_name,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, ee.id_prof_create, ee.dt_create, NULL) desc_speciality,
                   decode(ee.id_parent,
                          NULL,
                          l_msg_oper_add,
                          decode(ee.flg_status,
                                 g_mnp_flg_status_o,
                                 l_msg_oper_edit,
                                 g_mnp_flg_status_c,
                                 l_msg_oper_canc,
                                 l_msg_oper_edit)) desc_title,
                   ee.flg_status
              FROM epis_encounter ee
            CONNECT BY PRIOR ee.id_parent = ee.id_epis_encounter
             START WITH ee.id_epis_encounter = i_epis_encounter;
    
        g_error := 'GET CURSOR O_ENCOUNTER';
        OPEN o_encounter FOR
            SELECT ee.id_epis_encounter,
                   ee.id_professional,
                   decode(ee.flg_status, g_mnp_flg_status_c, NULL, l_case_manager) case_manager_title,
                   decode(ee.flg_status,
                          g_mnp_flg_status_c,
                          NULL,
                          pk_prof_utils.get_name_signature(i_lang, i_prof, ee.id_professional)) case_manager,
                   decode(ee.flg_status, g_mnp_flg_status_c, NULL, l_encounter_date) encounter_date_title,
                   decode(ee.flg_status,
                          g_mnp_flg_status_c,
                          NULL,
                          pk_date_utils.dt_chr_tsz(i_lang, ee.dt_epis_encounter, i_prof)) encounter_date,
                   decode(ee.flg_status, g_mnp_flg_status_c, NULL, l_reason) reason_title,
                   decode(ee.flg_status,
                          g_mnp_flg_status_c,
                          NULL,
                          pk_utils.query_to_string('SELECT PK_TRANSLATION.get_translation(' || i_lang ||
                                                   ',RE.CODE_REASON)
												FROM EPIS_ENCOUNTER_REASON ECR, REASON_ENCOUNTER RE												
												WHERE ECR.ID_EPIS_ENCOUNTER = ' || ee.id_epis_encounter || '
												AND ECR.ID_REASON = RE.ID_REASON',
                                                   '; ')) encounter_reason,
                   decode(ee.flg_status, g_mnp_flg_status_c, NULL, l_notes) notes_title,
                   ee.notes,
                   decode(ee.flg_status, g_mnp_flg_status_c, l_msg_canc_rea, NULL) cancel_reason_title,
                   decode(ee.flg_status,
                          g_mnp_flg_status_c,
                          (SELECT pk_translation.get_translation(i_lang,
                                                                 'CANCEL_REASON.CODE_CANCEL_REASON.' ||
                                                                 ee.id_cancel_reason)
                             FROM dual),
                          NULL) cancel_reason,
                   decode(ee.flg_status, g_mnp_flg_status_c, l_msg_canc_notes, NULL) notes_cancel_title,
                   ee.notes_cancel notes_cancel
              FROM epis_encounter ee
            CONNECT BY PRIOR ee.id_parent = ee.id_epis_encounter
             START WITH ee.id_epis_encounter = i_epis_encounter;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ENCOUNTER_DETAIL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_encounter);
            pk_types.open_my_cursor(o_register);
            RETURN FALSE;
    END get_encounter_detail;

    /**********************************************************************************************
    * Retrieves a case management encounter reasons.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_epis_encounter        encounter identifier
    * @param i_sep                   reason separator
    *
    * @return                        case management encounter reasons
    *                        
    * @author                        Pedro Carneiro
    * @version                        2.5.0.7
    * @since                         2009/10/24
    **********************************************************************************************/
    FUNCTION get_encounter_reas
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_encounter IN epis_encounter.id_epis_encounter%TYPE,
        i_sep            IN VARCHAR2 DEFAULT ','
    ) RETURN VARCHAR2 IS
        l_space CONSTANT VARCHAR2(1) := ' ';
        l_ret     VARCHAR2(4000);
        l_reasons table_varchar := table_varchar();
    
        CURSOR c_reason IS
            SELECT pk_translation.get_translation(i_lang, re.code_reason)
              FROM epis_encounter_reason eer
              JOIN reason_encounter re
             USING (id_reason)
             WHERE eer.id_epis_encounter = i_epis_encounter
             ORDER BY 1;
    BEGIN
        alertlog.pk_alertlog.log_debug('PARAMS[i_epis_encounter:' || i_epis_encounter || ']',
                                       g_package_name,
                                       'GET_MNG_FU_REASON');
        IF i_epis_encounter IS NULL
        THEN
            l_ret := NULL;
        ELSE
            OPEN c_reason;
            FETCH c_reason BULK COLLECT
                INTO l_reasons;
            CLOSE c_reason;
        
            l_ret := NULL;
            FOR i IN 1 .. l_reasons.count
            LOOP
                IF i = 1
                THEN
                    l_ret := l_reasons(i);
                ELSE
                    l_ret := l_ret || i_sep || l_space || l_reasons(i);
                END IF;
            END LOOP;
        END IF;
    
        RETURN l_ret;
    END get_encounter_reas;

    /**********************************************************************************************
    * Creates or edits an encounter. overload created so that flash code keeps working unaltered.
    * This function simply calls the original one.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_epis_encounter        episode encounter identifier
    * @param i_episode               episode identifier
    * @param i_patient               patient identifier
    * @param i_dt_begin              episode encounter start date
    * @param i_id_professional       episode encounter professional (CM)
    * @param i_flg_type              episode encounter type flag
    * @param i_notes                 episode encounter notes
    * @param i_reasons               episode encounter reasons
    * @param o_epis_encounter        episode encounter identifier
    * @param o_error                 error
    *
    * @return                        false, if errors occur, or true, otherwise.
    *                        
    * @author                        Telmo Castro
    * @version                       2.6.0.1
    * @since                         27-04-2010
    **********************************************************************************************/
    FUNCTION set_encounter
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_epis_encounter  IN epis_encounter.id_epis_encounter%TYPE,
        i_episode         IN epis_encounter.id_episode%TYPE,
        i_patient         IN epis_encounter.id_patient%TYPE,
        i_dt_begin        IN VARCHAR2,
        i_id_professional IN professional.id_professional%TYPE,
        i_flg_type        IN epis_encounter.flg_type%TYPE,
        i_notes           IN epis_encounter.notes%TYPE,
        i_reasons         IN table_number,
        o_epis_encounter  OUT epis_encounter.id_epis_encounter%TYPE,
        o_episode         OUT episode.id_episode%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
        l_func_exception EXCEPTION;
    BEGIN
    
        -- get remote transaction
        g_error          := 'START REMOTE TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, i_prof);
    
        g_error := 'SET_ENCOUNTER - CALL ORIGINAL SET_ENCOUNTER';
        IF NOT set_encounter(i_lang            => i_lang,
                             i_prof            => i_prof,
                             i_epis_encounter  => i_epis_encounter,
                             i_episode         => i_episode,
                             i_patient         => i_patient,
                             i_dt_begin        => i_dt_begin,
                             i_id_professional => i_id_professional,
                             i_flg_type        => i_flg_type,
                             i_notes           => i_notes,
                             i_reasons         => i_reasons,
                             i_transaction_id  => l_transaction_id,
                             o_epis_encounter  => o_epis_encounter,
                             o_episode         => o_episode,
                             o_error           => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        -- fechar transacao
        pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_func_exception THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ENCOUNTER',
                                              o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_encounter;

    /*******************************************************************************************
    * Answers (accepts/rejects) a case management request. overload created so that flash code keeps working unaltered.
    * This function simply calls the original one.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_opinion          opinion identifier
    * @param i_patient          patient identifier
    * @param i_flg_state        acceptance
    * @param i_management_level management level identifier
    * @param i_notes            answer notes
    * @param o_opinion          opinion identifier
    * @param o_opinion_prof     opinion prof identifier
    * @param o_episode          episode identifier
    * @param o_epis_encounter   episode encounter dentifier
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @author                   Telmo Castro
    * @version                  2.6.0.1
    * @since                    27-04-2010
    ********************************************************************************************/
    FUNCTION set_cm_req_answer
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_opinion          IN opinion_prof.id_opinion%TYPE,
        i_patient          IN patient.id_patient%TYPE,
        i_flg_state        IN opinion.flg_state%TYPE,
        i_management_level IN opinion.id_management_level%TYPE,
        i_notes            IN opinion_prof.desc_reply%TYPE,
        o_opinion_prof     OUT opinion_prof.id_opinion_prof%TYPE,
        o_episode          OUT episode.id_episode%TYPE,
        o_epis_encounter   OUT epis_encounter.id_epis_encounter%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
        l_func_exception EXCEPTION;
    BEGIN
    
        -- get remote transaction
        g_error          := 'START REMOTE TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, i_prof);
    
        g_error := 'SET_CM_REQ_ANSWER - CALL ORIGINAL SET_CM_REQ_ANSWER';
        IF NOT set_cm_req_answer(i_lang             => i_lang,
                                 i_prof             => i_prof,
                                 i_opinion          => i_opinion,
                                 i_patient          => i_patient,
                                 i_flg_state        => i_flg_state,
                                 i_management_level => i_management_level,
                                 i_notes            => i_notes,
                                 i_transaction_id   => l_transaction_id,
                                 o_opinion_prof     => o_opinion_prof,
                                 o_episode          => o_episode,
                                 o_epis_encounter   => o_epis_encounter,
                                 o_error            => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        -- fechar transacao
        pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_func_exception THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_CM_REQ_ANSWER',
                                              o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_cm_req_answer;

    /********************************************************************************************
    * Retrieve encounter discharges.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_epis_encounter        encounter identifier
    * @param o_disch                 cursor
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Elisabete Bugalho
    * @version                        2.5.0.7  
    * @since                         27-04-2010
    ********************************************************************************************/
    FUNCTION get_enc_disch_rep
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_disch   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        alertlog.pk_alertlog.log_debug('PARAMS[i_episode:' || i_episode || '  ]', g_package_name, 'GET_ENC_DISCH_REP');
    
        g_error := 'OPEN o_disch';
        OPEN o_disch FOR
            SELECT eed.id_epis_encounter_disch,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, eed.dt_register, i_prof) dt_begin,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, eed.id_professional) prof,
                   eed.flg_status,
                   
                   pk_date_utils.date_char_hour_tsz(i_lang, eed.dt_end, i_prof.institution, i_prof.software) end_hour,
                   pk_utils.query_to_string('SELECT pk_translation.get_translation(' || i_lang ||
                                            ', re.code_reason )
                                                 FROM epis_enc_disch_reason eedr, reason_encounter re
                         WHERE eedr.id_epis_encounter_disch = ' ||
                                            eed.id_epis_encounter_disch || '
                           AND eedr.id_reason = re.id_reason',
                                            '; ') reason,
                   eed.notes notes,
                   pk_date_utils.to_char_insttimezone(i_prof, eed.dt_register, 'YYYYMMDDHH24MISS') date_discharge
              FROM epis_encounter_disch eed, epis_encounter ee
             WHERE ee.id_episode = i_episode
               AND ee.flg_status <> g_enc_flg_status_o
               AND eed.id_epis_encounter = ee.id_epis_encounter
               AND eed.flg_status IN (g_disch_active, g_disch_canc)
             ORDER BY eed.dt_end DESC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ENC_DISCH_REP',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_disch);
            RETURN FALSE;
    END get_enc_disch_rep;

    /**
     * This function returns all professionals associated with a determined
     * category of an institution with the login professional selected
     *
     * @param  IN  Language ID
     * @param  IN  Category Flag
     * @param  IN  Institution ID
     * @param  OUT Professional cursor
     * @param  OUT Error structure
     *
     * @return BOOLEAN
     *
     * @since   30/09/2010
     * @version 2.6.0.4
     * @author  Rita Lopes
    */
    FUNCTION get_cat_prof_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_category    IN category.flg_type%TYPE,
        i_institution IN institution.id_institution%TYPE,
        o_profs       OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        OPEN o_profs FOR
            SELECT pc.id_professional,
                   pk_prof_utils.get_name_signature(i_lang,
                                                    profissional(pc.id_professional, NULL, NULL),
                                                    pc.id_professional) prof_name,
                   decode(i_prof.id, pc.id_professional, g_yes, g_no) flg_default
              FROM prof_cat pc
              JOIN category c
             USING (id_category)
             WHERE pc.id_institution = i_institution
               AND c.flg_type = i_category;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CAT_PROF_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_profs);
            RETURN FALSE;
    END get_cat_prof_list;

    /********************************************************************************************
    *  Get current state of case management plan for viewer checlist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_mng_plan_viewer_check
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name     VARCHAR2(30 CHAR) := 'GET_MNG_PLAN_VIEWER_CHECK';
        l_episodes      table_number := table_number();
        l_cnt_completed NUMBER(24);
        l_flg_checklist VARCHAR2(1 CHAR);
    BEGIN
        g_error := 'GET SCOPE EPISODES';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        l_episodes := pk_episode.get_scope(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_patient    => i_patient,
                                           i_episode    => i_episode,
                                           i_flg_filter => i_scope_type);
    
        -- current case management plan records
        SELECT COUNT(*) cnt
          INTO l_cnt_completed
          FROM management_plan mp, management_level ml, management_level_inst mli
         WHERE mp.id_episode IN (SELECT *
                                   FROM TABLE(l_episodes))
           AND mp.flg_status = g_mnp_flg_status_a
           AND mp.id_management_level = ml.id_management_level
           AND ml.id_management_level = mli.id_management_level
           AND nvl(mli.id_institution, 0) IN (0, i_prof.institution);
    
        -- fill in viewer checklist flag
        IF l_cnt_completed > 0
        THEN
            l_flg_checklist := pk_viewer_checklist.g_checklist_completed;
        ELSE
            l_flg_checklist := pk_viewer_checklist.g_checklist_not_started;
        END IF;
    
        RETURN l_flg_checklist;
    END get_mng_plan_viewer_check;

    /********************************************************************************************
    *  Get current end of encounter for viewer checlist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_vwr_end_of_enc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_flg_checklist VARCHAR2(1 CHAR) := pk_viewer_checklist.g_checklist_not_started;
        l_episodes      table_number := table_number();
        l_count         NUMBER;
    BEGIN
    
        l_episodes := pk_episode.get_scope(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_patient    => i_patient,
                                           i_episode    => i_episode,
                                           i_flg_filter => i_scope_type);
    
        SELECT COUNT(*)
          INTO l_count
          FROM epis_encounter_disch eed
          JOIN epis_encounter ee
            ON ee.id_epis_encounter = eed.id_epis_encounter
         WHERE ee.id_episode IN (SELECT column_value
                                   FROM TABLE(l_episodes))
           AND eed.flg_status = pk_case_management.g_disch_active;
    
        IF l_count > 0
        THEN
            l_flg_checklist := pk_viewer_checklist.g_checklist_completed;
        END IF;
    
        RETURN l_flg_checklist;
    
    END get_vwr_end_of_enc;

    PROCEDURE init_params
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
        l_lang             CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof             CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                                 i_context_ids(g_prof_institution),
                                                                 i_context_ids(g_prof_software));
    
        l_type_opinion opinion_type.id_opinion_type%TYPE;
        l_category     category.id_category%TYPE;
    
        l_not_defined  sys_message.desc_message%TYPE;
        l_dt_begin     TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end       TIMESTAMP WITH LOCAL TIME ZONE;
        l_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_handoff_type sys_config.value%TYPE;
        l_prof_cat     category.flg_type%TYPE;
    
        CURSOR c_type_request IS
            SELECT ot.id_opinion_type
              FROM opinion_type ot
             WHERE ot.id_category = l_category;
    
        o_error t_error_out;
    
    BEGIN
    
        g_error        := 'GET PROF CATEGORY';
        l_sysdate_tstz := current_timestamp;
        l_category     := pk_prof_utils.get_id_category(i_lang => l_lang, i_prof => l_prof);
        l_prof_cat     := pk_prof_utils.get_category(i_lang => l_lang, i_prof => l_prof);
        pk_hand_off_core.get_hand_off_type(i_lang => l_lang, i_prof => l_prof, io_hand_off_type => l_handoff_type);
    
        l_dt_begin := pk_date_utils.trunc_insttimezone(l_prof, l_sysdate_tstz);
        l_dt_end   := pk_date_utils.add_days_to_tstz(l_dt_begin, 1);
    
        g_error := 'OPEN C_TYPE_REQUEST';
        OPEN c_type_request;
        FETCH c_type_request
            INTO l_type_opinion;
        CLOSE c_type_request;
    
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(l_lang, l_sysdate_tstz, l_prof);
    
        pk_context_api.set_parameter('i_lang', l_lang);
        pk_context_api.set_parameter('i_prof_id', l_prof.id);
        pk_context_api.set_parameter('i_prof_institution', l_prof.institution);
        pk_context_api.set_parameter('i_prof_software', l_prof.software);
        pk_context_api.set_parameter('i_type_opinion', l_type_opinion);
    
        pk_context_api.set_parameter('l_dt_begin', l_dt_begin);
        pk_context_api.set_parameter('l_dt_end', l_dt_end);
        pk_context_api.set_parameter('l_prof_cat', l_prof_cat);
        pk_context_api.set_parameter('l_handoff_type', l_handoff_type);
        pk_context_api.set_parameter('l_current_timestamp', l_sysdate_tstz);
    
        CASE i_name
            WHEN 'l_lang' THEN
                o_id := l_lang;
            WHEN 'l_prof_id' THEN
                o_id := l_prof.id;
            WHEN 'l_prof_institution' THEN
                o_id := l_prof.institution;
            WHEN 'l_prof_software' THEN
                o_id := l_prof.software;
            WHEN 'l_not_defined' THEN
                o_vc2 := pk_message.get_message(l_lang, l_prof, 'CASE_MANAGER_T020');
            ELSE
                NULL;
        END CASE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => l_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_CASE_MANAGEMENT',
                                              i_function => 'INIT_PARAMS',
                                              o_error    => o_error);
    END init_params;

BEGIN
    -- Initialization
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_case_management;
/
