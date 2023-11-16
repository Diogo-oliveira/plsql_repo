/*-- Last Change Revision: $Rev: 2005690 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2022-01-17 16:26:18 +0000 (seg, 17 jan 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ehr_common IS
    /**
    * Returns the visit name based on the EPIS_TYPE identifier
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_epis_type EPIS_TYPE identifier.
    * @param i_is_event     'Y' if is an EHR event. 'N' if is a visit.
    *
    * @return  the visit name based on the EPIS_TYPE identifier
    *
    * @author   Eduardo Lourenço
    * @version  2.4.3
    * @since    2008/05/17
    */
    FUNCTION get_visit_name_by_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_epis_type IN episode.id_epis_type%TYPE,
        i_is_event     IN VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2 IS
    
        l_visit_name_from_epis_type pk_translation.t_desc_translation;
    BEGIN
    
        IF i_id_epis_type = g_epis_type_outp
        THEN
            IF i_is_event = 'N'
            THEN
                RETURN pk_message.get_message(i_lang, i_prof, 'EHR_VISITNAME_T001'); --'Outpatient visit';
            ELSE
                RETURN pk_message.get_message(i_lang, i_prof, 'EHR_VISITNAME_T007'); --'Outpatient event';
            END IF;
        ELSIF i_id_epis_type = g_epis_type_care
        THEN
            IF i_is_event = 'N'
            THEN
                RETURN pk_message.get_message(i_lang, i_prof, 'EHR_VISITNAME_T002'); --'Primary care visit';
            ELSE
                RETURN pk_message.get_message(i_lang, i_prof, 'EHR_VISITNAME_T008'); --'Primary care event';
            END IF;
        ELSIF i_id_epis_type = g_epis_type_pp
        THEN
            IF i_is_event = 'N'
            THEN
                RETURN pk_message.get_message(i_lang, i_prof, 'EHR_VISITNAME_T003'); --'Private practice visit';
            ELSE
                RETURN pk_message.get_message(i_lang, i_prof, 'EHR_VISITNAME_T009'); --'Private practice event';
            END IF;
        ELSIF i_id_epis_type = g_epis_type_edis
        THEN
            IF i_is_event = 'N'
            THEN
                RETURN pk_message.get_message(i_lang, i_prof, 'EHR_VISITNAME_T004'); --'Emergency visit';
            ELSE
                RETURN pk_message.get_message(i_lang, i_prof, 'EHR_VISITNAME_T010'); --'Emergency event';
            END IF;
        ELSIF i_id_epis_type = g_epis_type_inp
        THEN
            IF i_is_event = 'N'
            THEN
                RETURN pk_message.get_message(i_lang, i_prof, 'EHR_VISITNAME_T005'); --'Inpatient visit';
            ELSE
                RETURN pk_message.get_message(i_lang, i_prof, 'EHR_VISITNAME_T011'); --'Inpatient event';
            END IF;
        ELSIF i_id_epis_type = g_epis_type_oris
        THEN
            IF i_is_event = 'N'
            THEN
                RETURN pk_message.get_message(i_lang, i_prof, 'EHR_VISITNAME_T006'); --'Surgery visit';
            ELSE
                RETURN pk_message.get_message(i_lang, i_prof, 'EHR_VISITNAME_T012'); --'Surgery event';
            END IF;
        ELSIF i_id_epis_type = pk_alert_constant.g_epis_type_social
        THEN
            IF i_is_event = 'N'
            THEN
                RETURN pk_message.get_message(i_lang, i_prof, 'EHR_VISITNAME_T016'); --'Social visit';
            ELSE
                RETURN pk_message.get_message(i_lang, i_prof, 'EHR_VISITNAME_T017'); --'Social event';
            END IF;
            RETURN NULL;
        ELSIF i_id_epis_type = g_epis_type_sap
        THEN
            IF i_is_event = 'N'
            THEN
                RETURN pk_message.get_message(i_lang, i_prof, 'EHR_VISITNAME_T014'); --'SAP visit';
            ELSE
                RETURN pk_message.get_message(i_lang, i_prof, 'EHR_VISITNAME_T015'); --'SAP event';
            END IF;
            RETURN NULL;
        ELSIF (i_id_epis_type = g_epis_type_enf_care OR i_id_epis_type = g_epis_type_enf_outp OR
              i_id_epis_type = g_epis_type_enf_pp)
        THEN
            IF i_is_event = 'N'
            THEN
                RETURN pk_message.get_message(i_lang, i_prof, 'EHR_VISITNAME_T018'); --'Nursing visit';
            ELSE
                RETURN pk_message.get_message(i_lang, i_prof, 'EHR_VISITNAME_T019'); --'Nursing event';
            END IF;
            RETURN NULL;
        ELSIF (i_id_epis_type = pk_act_therap_constant.g_activ_therap_epis_type)
        THEN
            RETURN pk_message.get_message(i_lang, i_prof, 'AT_EHR_VISITNAME_T020'); --'Activity Therapist';
        ELSE
            --Caso não esteja configurado
            BEGIN
                SELECT pk_translation.get_translation(i_lang, et.code_epis_type)
                  INTO l_visit_name_from_epis_type
                  FROM epis_type et
                 WHERE et.id_epis_type = i_id_epis_type;
            EXCEPTION
                WHEN no_data_found THEN
                    RETURN '';
            END;
        
            RETURN l_visit_name_from_epis_type;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_visit_name_by_epis;

    /**
    * Returns ambulatory visit type based on the EPISODE identifier
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_episode   EPISODE identifier.
    * @param o_title        The title of the visit type.
    *
    * @param o_appointment  The appointment type.
    * @param o_event        The event type.
    * @param o_error        Message to be shown to the user in case of error.
    *
    * @return  TRUE if succedeed. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.3
    * @since    2008/05/17
    */
    FUNCTION get_amb_visit_type_by_epis
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        o_title       OUT VARCHAR2,
        o_appointment OUT VARCHAR2,
        o_event       OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(64) := 'GET_AMB_VISIT_TYPE_BY_EPIS';
    BEGIN
    
        SELECT pk_message.get_message(i_lang,
                                      profissional(i_prof.id, i_prof.institution, g_software_all),
                                      'EHR_VISITTYPE_T001'), --Type of visit:',
               pk_translation.get_translation(i_lang, cs.code_clinical_service),
               decode(sch_o.flg_type,
                      NULL,
                      NULL,
                      pk_sysdomain.get_domain('SCHEDULE_OUTP.FLG_TYPE', sch_o.flg_type, i_lang))
          INTO o_title, o_appointment, o_event
          FROM episode e, clinical_service cs, schedule_outp sch_o, epis_info ei
         WHERE e.id_episode = i_id_episode
           AND e.id_clinical_service = cs.id_clinical_service
           AND ei.id_episode = e.id_episode
           AND ei.id_schedule = sch_o.id_schedule(+);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', g_package_name, l_func_name);
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
    END get_amb_visit_type_by_epis;

    /**
    * Returns default visit type based on the EPISODE identifier
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_episode   EPISODE identifier.
    * @param o_title        The title of the visit type.
    *
    * @param o_appointment  The appointment type.
    * @param o_event        The event type.
    * @param o_error        Message to be shown to the user in case of error.
    *
    * @return  TRUE if succedeed. FALSE otherwise.
    *
    * @author   Sérgio Santos
    * @version  2.4.3
    * @since    2008/08/01
    */
    FUNCTION get_default_visit_type_by_epis
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_title      OUT VARCHAR2,
        o_value      OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(64) := 'GET_DEFAULT_VISIT_TYPE_BY_EPIS';
    
        l_epis_type_str pk_translation.t_desc_translation;
    BEGIN
        g_error := 'GET EPIS_TYPE FROM EPISODE';
        BEGIN
            SELECT pk_translation.get_translation(i_lang, et.code_epis_type)
              INTO l_epis_type_str
              FROM epis_type et
             WHERE et.id_epis_type IN (SELECT e.id_epis_type
                                         FROM episode e
                                        WHERE e.id_episode = i_id_episode
                                          AND rownum <= 1);
        EXCEPTION
            WHEN no_data_found THEN
                g_error := 'NO EPISODE EPIS_TYPE FOUND';
        END;
    
        SELECT l_epis_type_str, --Type of visit:',
               concatenate( -- ALERT-736 synonyms diagnosis
                           pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                      i_prof                => i_prof,
                                                      i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                                      i_id_diagnosis        => d.id_diagnosis,
                                                      i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                      i_code                => d.code_icd,
                                                      i_flg_other           => d.flg_other,
                                                      i_flg_std_diag        => ad.flg_icd9,
                                                      i_epis_diag           => ed.id_epis_diagnosis) || '; ')
          INTO o_title, o_value
          FROM episode e, epis_diagnosis ed, diagnosis d, alert_diagnosis ad
         WHERE e.id_episode = i_id_episode
           AND ed.id_episode = e.id_episode
           AND d.id_diagnosis = ed.id_diagnosis
           AND ad.id_alert_diagnosis(+) = ed.id_alert_diagnosis
           AND ed.flg_type IN (pk_diagnosis.g_diag_type_d, pk_diagnosis.g_diag_type_b)
           AND ed.flg_status IN
               (pk_diagnosis.g_ed_flg_status_d, pk_diagnosis.g_ed_flg_status_co, pk_diagnosis.g_ed_flg_status_b);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', g_package_name, l_func_name);
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
    END get_default_visit_type_by_epis;

    /**
    * Returns EDIS visit type based on the EPISODE identifier
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_episode   EPISODE identifier.
    * @param o_title        The title of the visit type.
    * @param o_value        The description of the visit type.
    * @param o_error        Message to be shown to the user in case of error.
    *
    * @return  TRUE if succedeed. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.3
    * @since    2008/05/17
    */
    FUNCTION get_edis_visit_type_by_epis
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_title      OUT VARCHAR2,
        o_value      OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(64) := 'GET_EDIS_VISIT_TYPE_BY_EPIS';
    BEGIN
    
        SELECT pk_message.get_message(i_lang,
                                      profissional(i_prof.id, i_prof.institution, g_software_edis),
                                      'EHR_VISITTYPE_T001'), --Type of visit:',
               concatenate(
                           -- ALERT-736 synonyms diagnosis
                           pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                      i_prof                => i_prof,
                                                      i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                                      i_id_diagnosis        => d.id_diagnosis,
                                                      i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                      i_code                => d.code_icd,
                                                      i_flg_other           => d.flg_other,
                                                      i_flg_std_diag        => ad.flg_icd9,
                                                      i_epis_diag           => ed.id_epis_diagnosis) || '; ')
          INTO o_title, o_value
          FROM episode e, epis_diagnosis ed, diagnosis d, alert_diagnosis ad
         WHERE e.id_episode = i_id_episode
           AND ed.id_episode = e.id_episode
           AND d.id_diagnosis = ed.id_diagnosis
           AND ad.id_alert_diagnosis(+) = ed.id_alert_diagnosis
           AND ed.flg_type IN (pk_diagnosis.g_diag_type_d, pk_diagnosis.g_diag_type_b)
           AND ed.flg_status IN
               (pk_diagnosis.g_ed_flg_status_d, pk_diagnosis.g_ed_flg_status_co, pk_diagnosis.g_ed_flg_status_b);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', g_package_name, l_func_name);
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
                RETURN FALSE;
            END;
    END get_edis_visit_type_by_epis;

    /**
    * Returns SAP visit type based on the EPISODE identifier
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_episode   EPISODE identifier.
    * @param o_title        The title of the visit type.
    * @param o_value        The description of the visit type.
    * @param o_error        Message to be shown to the user in case of error.
    *
    * @return  TRUE if succedeed. FALSE otherwise.
    *
    * @author   Sérgio Santos
    * @version  2.4.3
    * @since    2008/07/25
    */
    FUNCTION get_sap_visit_type_by_epis
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_title      OUT VARCHAR2,
        o_value      OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(64) := 'GET_SAP_VISIT_TYPE_BY_EPIS';
    BEGIN
    
        SELECT pk_message.get_message(i_lang,
                                      profissional(i_prof.id, i_prof.institution, g_software_sap),
                                      'EHR_VISITTYPE_T013'), --Type of visit:',
               concatenate( -- ALERT-736 synonyms diagnosis
                           pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                      i_prof                => i_prof,
                                                      i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                                      i_id_diagnosis        => d.id_diagnosis,
                                                      i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                      i_code                => d.code_icd,
                                                      i_flg_other           => d.flg_other,
                                                      i_flg_std_diag        => ad.flg_icd9,
                                                      i_epis_diag           => ed.id_epis_diagnosis) || '; ')
          INTO o_title, o_value
          FROM episode e, epis_diagnosis ed, diagnosis d, alert_diagnosis ad
         WHERE e.id_episode = i_id_episode
           AND ed.id_episode = e.id_episode
           AND d.id_diagnosis = ed.id_diagnosis
           AND ad.id_alert_diagnosis(+) = ed.id_alert_diagnosis
           AND ed.flg_type IN (pk_diagnosis.g_diag_type_d, pk_diagnosis.g_diag_type_b)
           AND ed.flg_status IN
               (pk_diagnosis.g_ed_flg_status_d, pk_diagnosis.g_ed_flg_status_co, pk_diagnosis.g_ed_flg_status_b);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', g_package_name, l_func_name);
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
    END get_sap_visit_type_by_epis;

    /**
    * Returns INPATIENT visit type based on the EPISODE identifier
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_episode   EPISODE identifier.
    * @param o_title        The title of the visit type.
    * @param o_value        The description of the visit type.
    * @param o_error        Message to be shown to the user in case of error.
    *
    * @return  TRUE if succedeed. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.3
    * @since    2008/05/17
    */
    FUNCTION get_inp_visit_type_by_epis
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_title      OUT VARCHAR2,
        o_department OUT VARCHAR2,
        o_clin_serv  OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(64) := 'GET_INP_VISIT_TYPE_BY_EPIS';
    BEGIN
    
        SELECT pk_message.get_message(i_lang,
                                      profissional(i_prof.id, i_prof.institution, g_software_inp),
                                      'EHR_VISITTYPE_T001'), --'Department:',
               pk_translation.get_translation(i_lang, d.code_department),
               pk_translation.get_translation(i_lang, cs1.code_clinical_service)
          INTO o_title, o_department, o_clin_serv
          FROM episode e, epis_info ei, department d, room r, clinical_service cs1
         WHERE e.id_episode = ei.id_episode
           AND ei.id_room = r.id_room(+)
           AND r.id_department = d.id_department(+)
           AND e.id_clinical_service = cs1.id_clinical_service
           AND ei.id_episode = i_id_episode;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', g_package_name, l_func_name);
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
    END get_inp_visit_type_by_epis;

    /**
    * Returns ORIS visit type based on the EPISODE identifier
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_episode   EPISODE identifier.
    * @param o_title        The title of the visit type.
    * @param o_value        The description of the visit type.
    * @param o_error        Message to be shown to the user in case of error.
    *
    * @return  the ORIS visit type based on the EPISODE identifier
    *
    * @author   Eduardo Lourenço
    * @version  2.4.3
    * @since    2008/05/17
    */
    FUNCTION get_oris_visit_type_by_epis
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_title      OUT VARCHAR2,
        o_value      OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(64) := 'GET_ORIS_VISIT_TYPE_BY_EPIS';
    BEGIN
        SELECT pk_message.get_message(i_lang,
                                      profissional(i_prof.id, i_prof.institution, g_software_oris),
                                      'EHR_VISITTYPE_T001'), --'Surgery:', 
               pk_sr_clinical_info.get_proposed_surgery(i_lang, i_id_episode, i_prof, pk_alert_constant.g_no)
          INTO o_title, o_value
          FROM dual;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', g_package_name, l_func_name);
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
    END get_oris_visit_type_by_epis;

    /**
    * Returns the visit type based on the EPISODE identifier
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_episode   EPISODE identifier.
    * @param i_sep          The separator for the visit type.
    * @param o_title        The title of the visit type.
    * @param o_value        The description of the visit type.
    * @param o_error        Message to be shown to the user in case of error.
    *
    * @return  the visit type based on the EPISODE identifier
    *
    * @author   Eduardo Lourenço
    * @version  2.4.3
    * @since    2008/05/17
    */
    FUNCTION get_visit_type_by_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_epis_type IN episode.id_epis_type%TYPE,
        i_sep          IN VARCHAR2,
        o_title        OUT VARCHAR2,
        o_value        OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(64) := 'GET_VISIT_TYPE_BY_EPIS';
        l_appointment VARCHAR2(200);
        l_event       VARCHAR2(200);
        l_department  VARCHAR2(200);
        l_clin_serv   VARCHAR2(200);
    BEGIN
        IF i_id_epis_type IN (g_epis_type_outp,
                              g_epis_type_care,
                              g_epis_type_pp,
                              g_epis_type_enf_care,
                              g_epis_type_enf_outp,
                              g_epis_type_enf_pp,
                              g_epis_type_social,
                              g_epis_type_dietitian,
                              g_epis_type_rehab_appointment,
                              g_epis_type_psychologist,
                              g_epis_type_resp_therapist,
                              g_epis_type_cdc_appointment,
                              g_epis_type_home_health_care,
                              g_epis_type_speech_therapy,
                              g_epis_type_occup_therapy)
        THEN
            IF NOT get_amb_visit_type_by_epis(i_lang        => i_lang,
                                              i_prof        => i_prof,
                                              i_id_episode  => i_id_episode,
                                              o_title       => o_title,
                                              o_appointment => l_appointment,
                                              o_event       => l_event,
                                              o_error       => o_error)
            THEN
                RETURN FALSE;
            ELSE
                o_value := pk_string_utils.concat_if_exists(l_appointment, l_event, i_sep);
                RETURN TRUE;
            END IF;
        ELSIF i_id_epis_type = g_epis_type_edis
        THEN
            RETURN get_edis_visit_type_by_epis(i_lang       => i_lang,
                                               i_prof       => i_prof,
                                               i_id_episode => i_id_episode,
                                               o_title      => o_title,
                                               o_value      => o_value,
                                               o_error      => o_error);
        ELSIF i_id_epis_type IN (g_epis_type_inp, pk_act_therap_constant.g_activ_therap_epis_type)
        THEN
            IF NOT get_inp_visit_type_by_epis(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_id_episode => i_id_episode,
                                              o_title      => o_title,
                                              o_department => l_department,
                                              o_clin_serv  => l_clin_serv,
                                              o_error      => o_error)
            THEN
                RETURN FALSE;
            ELSE
                o_value := pk_string_utils.concat_if_exists(l_department, l_clin_serv, i_sep);
                RETURN TRUE;
            END IF;
        
        ELSIF i_id_epis_type = g_epis_type_oris
        THEN
            RETURN get_oris_visit_type_by_epis(i_lang       => i_lang,
                                               i_prof       => i_prof,
                                               i_id_episode => i_id_episode,
                                               o_title      => o_title,
                                               o_value      => o_value,
                                               o_error      => o_error);
        ELSIF i_id_epis_type IN (g_epis_type_exam, g_epis_type_rad)
        THEN
        
            o_value := pk_exams_external_api_db.get_exam_for_episode_timeline(i_lang    => i_lang,
                                                                              i_prof    => i_prof,
                                                                              i_episode => i_id_episode,
                                                                              i_type    => 'E');
        ELSIF i_id_epis_type = g_epis_type_lab
        THEN
            o_value := pk_lab_tests_external_api_db.get_lab_test_for_episode_timeline(i_lang    => i_lang,
                                                                                      i_prof    => i_prof,
                                                                                      i_episode => i_id_episode,
                                                                                      i_type    => 'E');
        
        ELSIF i_id_epis_type = g_epis_type_rehab_session
        THEN
        
            o_value := pk_rehab.get_visit_type_by_epis(i_lang => i_lang, i_prof => i_prof, i_id_episode => i_id_episode);
        ELSE
            --caso nenhum se aplique vai-se usar a estratédia do ambulatório
            IF NOT get_default_visit_type_by_epis(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_id_episode => i_id_episode,
                                                  o_title      => o_title,
                                                  o_value      => o_value,
                                                  o_error      => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', g_package_name, l_func_name);
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
    END get_visit_type_by_epis;

    /**
    * Returns the visit type based on the EPISODE identifier
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_episode   EPISODE identifier.
    * @param i_sep          The separator for the visit type.
    * @param o_title        The title of the visit type.
    * @param o_value        The description of the visit type.
    * @param o_error        Message to be shown to the user in case of error.
    *
    * @return  the visit type based on the EPISODE identifier
    *
    * @author   Eduardo Lourenço
    * @version  2.4.3
    * @since    2008/05/17
    */
    FUNCTION get_visit_type_by_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_epis_type IN episode.id_epis_type%TYPE,
        i_sep          IN VARCHAR2
    ) RETURN VARCHAR IS
        l_title VARCHAR2(200);
        l_value VARCHAR2(200);
        internal_exception EXCEPTION;
        l_error t_error_out;
    BEGIN
        IF NOT get_visit_type_by_epis(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_id_episode   => i_id_episode,
                                      i_id_epis_type => i_id_epis_type,
                                      i_sep          => i_sep,
                                      o_title        => l_title,
                                      o_value        => l_value,
                                      o_error        => l_error)
        THEN
            g_error := 'No epis_type configured';
            RAISE internal_exception;
        END IF;
        RETURN l_value;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_visit_type_by_epis;

    /**
    * Returns the visit type based on the EPISODE identifier
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_episode   EPISODE identifier.
    * @param o_title        The title of the visit type.
    * @param o_value        The description of the visit type.
    * @param o_error        Message to be shown to the user in case of error.
    *
    * @return  the visit type based on the EPISODE identifier
    *
    * @author   Eduardo Lourenço
    * @version  2.4.3
    * @since    2008/05/17
    */
    FUNCTION get_doc_area_title
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_doc_area IN doc_area.id_doc_area%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
        IF i_id_doc_area = g_doc_area_hpi
        THEN
            RETURN pk_message.get_message(i_lang, i_prof, 'EHR_DOC_AREA_T001'); --'History of past illness';
        ELSIF i_id_doc_area = g_doc_area_phy
        THEN
            RETURN pk_message.get_message(i_lang, i_prof, 'EHR_DOC_AREA_T002'); --'Physical exams';
        ELSIF i_id_doc_area = g_doc_area_ros
        THEN
            RETURN pk_message.get_message(i_lang, i_prof, 'EHR_DOC_AREA_T003'); --'Review of systems';
        END IF;
        RETURN NULL;
    END get_doc_area_title;

    /**
    * Returns documentation elements for the given DOC_AREA identifier and the given EPISODE identifier 
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_episode   EPISODE identifier.
    * @param i_id_epis_type EPIS_TYPE identifier.
    * @param i_id_doc_area  DOC_AREA identifier.
    *
    * @return  a table of varchar with the documentation values
    *
    * @author   Eduardo Lourenço
    * @version  2.4.3
    * @since    2008/05/17
    */
    FUNCTION get_doc_area_by_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_epis_type IN episode.id_epis_type%TYPE,
        i_id_doc_area  IN doc_area.id_doc_area%TYPE
    ) RETURN table_varchar IS
        o_table       table_varchar;
        l_title       VARCHAR2(100);
        l_value       VARCHAR2(2000);
        l_error       t_error_out;
        l_id_doc_area doc_area.id_doc_area%TYPE;
        CURSOR c_cursor IS
        
            SELECT pk_date_utils.date_send_tsz(i_lang, ea.dt_epis_anamnesis_tstz, i_prof) dt_last,
                   '0' ord,
                   '' desc_title,
                   pk_string_utils.clob_to_sqlvarchar2(ea.desc_epis_anamnesis) desc_val,
                   1 rank
              FROM epis_anamnesis ea
             WHERE ea.id_episode = i_id_episode
               AND ea.flg_type = decode(i_id_doc_area, g_doc_area_hpi, pk_summary_page.g_epis_anam_flg_type_a, NULL)
               AND l_id_doc_area = g_doc_area_hpi
               AND ea.flg_status = pk_clinical_info.g_epis_active
            UNION ALL
            SELECT pk_date_utils.date_send_tsz(i_lang, ea.dt_epis_anamnesis_tstz, i_prof) dt_last,
                   '3' ord,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ea.id_professional) desc_title,
                   pk_date_utils.date_char_tsz(i_lang, ea.dt_epis_anamnesis_tstz, i_prof.institution, i_prof.software) desc_val,
                   1 rank
              FROM epis_anamnesis ea
             WHERE ea.id_episode = i_id_episode
               AND ea.flg_type = decode(l_id_doc_area, g_doc_area_hpi, pk_summary_page.g_epis_anam_flg_type_a, NULL)
               AND l_id_doc_area = g_doc_area_hpi
               AND ea.flg_status = pk_clinical_info.g_epis_active
            UNION ALL
            SELECT pk_date_utils.date_send_tsz(i_lang, ers.dt_creation_tstz, i_prof) dt_last,
                   '0' ord,
                   '' desc_title,
                   ers.desc_review_systems desc_val,
                   1 rank
              FROM epis_review_systems ers
             WHERE ers.id_episode = i_id_episode
               AND ers.flg_status = pk_clinical_info.g_epis_active
               AND l_id_doc_area = g_doc_area_ros
            UNION ALL
            SELECT pk_date_utils.date_send_tsz(i_lang, ers.dt_creation_tstz, i_prof) dt_last,
                   '3' ord,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ers.id_professional) desc_title,
                   pk_date_utils.date_char_tsz(i_lang, ers.dt_creation_tstz, i_prof.institution, i_prof.software) desc_val,
                   1 rank
              FROM epis_review_systems ers
             WHERE ers.id_episode = i_id_episode
               AND ers.flg_status = pk_clinical_info.g_epis_active
               AND l_id_doc_area = g_doc_area_ros
            UNION ALL
            SELECT pk_date_utils.date_send_tsz(i_lang, eo.dt_epis_observation_tstz, i_prof) dt_last,
                   '0' ord,
                   '' desc_title,
                   eo.desc_epis_observation desc_val,
                   1 rank
              FROM epis_observation eo
             WHERE eo.id_episode = i_id_episode
               AND eo.flg_status = pk_clinical_info.g_epis_active
               AND eo.flg_type = pk_clinical_info.g_observ_flg_type_e
               AND l_id_doc_area = g_doc_area_phy
            UNION ALL
            SELECT pk_date_utils.date_send_tsz(i_lang, eo.dt_epis_observation_tstz, i_prof) dt_last,
                   '3' ord,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, eo.id_professional) desc_title,
                   pk_date_utils.date_char_tsz(i_lang, eo.dt_epis_observation_tstz, i_prof.institution, i_prof.software) desc_val,
                   1 rank
              FROM epis_observation eo
             WHERE eo.id_episode = i_id_episode
               AND eo.flg_status = pk_clinical_info.g_epis_active
               AND eo.flg_type = pk_clinical_info.g_observ_flg_type_e
               AND l_id_doc_area = g_doc_area_phy
            UNION ALL
            SELECT pk_date_utils.date_send_tsz(i_lang, ed.dt_last_update_tstz, i_prof) dt_last,
                   '0' ord,
                   pk_message.get_message(i_lang, i_prof, 'EHR_DOC_AREA_T004') desc_title, -- Template
                   pk_translation.get_translation(i_lang, dt.code_doc_template) desc_val,
                   1 rank
              FROM epis_documentation ed, doc_template dt
             WHERE ed.id_episode = i_id_episode
               AND ed.id_doc_template = dt.id_doc_template
               AND ed.id_doc_area = l_id_doc_area
               AND ed.flg_status = pk_summary_page.g_active
            UNION ALL
            SELECT pk_date_utils.date_send_tsz(i_lang, dt_last, i_prof) dt_last, ord, desc_title, desc_val, rank
              FROM (SELECT DISTINCT dt_last, '1' ord, desc_title, VALUE desc_val, rank
                      FROM (SELECT t.dt_creation_tstz dt_last,
                                   t.desc_component || ': ' desc_title,
                                   rank,
                                   pk_touch_option.concat_element_list(CURSOR
                                                                       (SELECT pk_touch_option.get_epis_formatted_element(i_lang,
                                                                                                                          i_prof,
                                                                                                                          edd.id_epis_documentation_det) desc_element,
                                                                               CASE
                                                                                    WHEN de.separator IS NULL THEN
                                                                                     pk_touch_option.g_elem_separator_default
                                                                                    WHEN de.separator =
                                                                                         pk_touch_option.g_elem_separator_none THEN
                                                                                     NULL
                                                                                    ELSE
                                                                                     de.separator
                                                                                END delimiter
                                                                          FROM epis_documentation_det edd
                                                                         INNER JOIN doc_element de
                                                                            ON de.id_doc_element = edd.id_doc_element
                                                                         WHERE edd.id_epis_documentation =
                                                                               t.id_epis_documentation
                                                                           AND edd.id_documentation = t.id_documentation
                                                                         ORDER BY de.rank)) VALUE
                            
                              FROM (SELECT DISTINCT ed.id_epis_documentation,
                                                    ed.dt_creation_tstz,
                                                    edd.id_documentation,
                                                    dc.id_doc_component,
                                                    pk_translation.get_translation(i_lang, dc.code_doc_component) desc_component,
                                                    dtad.rank,
                                                    de.flg_type,
                                                    de.input_mask,
                                                    de.flg_optional_value,
                                                    de.flg_element_domain_type,
                                                    de.code_element_domain
                                      FROM epis_documentation_det edd
                                      JOIN epis_documentation ed
                                        ON ed.id_epis_documentation = edd.id_epis_documentation
                                      JOIN documentation d
                                        ON d.id_documentation = edd.id_documentation
                                      JOIN doc_template_area_doc dtad
                                        ON dtad.id_doc_template = ed.id_doc_template
                                       AND dtad.id_doc_area = ed.id_doc_area
                                       AND dtad.id_documentation = d.id_documentation
                                      JOIN doc_element de
                                        ON de.id_doc_element = edd.id_doc_element
                                      JOIN doc_element_crit DEC
                                        ON dec.id_doc_element_crit = edd.id_doc_element_crit
                                      JOIN doc_component dc
                                        ON dc.id_doc_component = d.id_doc_component
                                     WHERE ed.id_episode = i_id_episode
                                       AND ed.id_doc_area = l_id_doc_area
                                       AND ed.flg_status = pk_summary_page.g_active
                                     ORDER BY ed.dt_creation_tstz DESC, dtad.rank) t
                             ORDER BY t.dt_creation_tstz DESC, t.rank)
                     ORDER BY dt_last DESC, rank ASC)
            UNION ALL
            SELECT pk_date_utils.date_send_tsz(i_lang, ed.dt_last_update_tstz, i_prof) dt_last,
                   '2' ord,
                   NULL,
                   pk_string_utils.clob_to_sqlvarchar2(ed.notes) val,
                   1 rank
              FROM epis_documentation ed
             WHERE ed.id_episode = i_id_episode
               AND ed.id_doc_area = l_id_doc_area
               AND ed.flg_status = pk_summary_page.g_active
               AND coalesce(dbms_lob.getlength(ed.notes), 0) > 0
            UNION ALL
            SELECT pk_date_utils.date_send_tsz(i_lang, ed.dt_last_update_tstz, i_prof) dt_last,
                   '3' ord,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ed.id_professional) title,
                   pk_date_utils.date_char_tsz(i_lang, ed.dt_last_update_tstz, i_prof.institution, i_prof.software) val,
                   1 rank
              FROM epis_documentation ed
             WHERE ed.id_episode = i_id_episode
               AND ed.id_doc_area = l_id_doc_area
               AND ed.flg_status = pk_summary_page.g_active
             ORDER BY dt_last DESC, ord ASC, rank ASC;
        TYPE t_cursor_type IS TABLE OF c_cursor%ROWTYPE;
        l_values  t_cursor_type;
        l_counter NUMBER;
    BEGIN
        l_id_doc_area := i_id_doc_area;
        IF NOT get_visit_type_by_epis(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_id_episode   => i_id_episode,
                                      i_id_epis_type => i_id_epis_type,
                                      i_sep          => '; ',
                                      o_title        => l_title,
                                      o_value        => l_value,
                                      o_error        => l_error)
        THEN
            RETURN NULL;
        END IF;
        -- The table of varchar to be returned will be composed by a set of records. Each record contains three elements.
        -- The first element can be null or 'I'. If it is 'I', it will be placed in italics font.
        -- The second element will be the title of each record. It should be placed in bold font.
        -- The third element will be description. It should be placed in normal font.
        o_table := table_varchar();
        o_table.extend(6);
        o_table(1) := '';
        o_table(2) := l_title;
        o_table(3) := l_value;
        l_title := get_doc_area_title(i_lang, i_prof, l_id_doc_area);
        o_table(4) := '';
        o_table(5) := l_title;
        o_table(6) := '';
    
        OPEN c_cursor;
        LOOP
            FETCH c_cursor BULK COLLECT
                INTO l_values LIMIT 100;
            FOR i IN 1 .. l_values.count
            LOOP
                l_counter := o_table.count;
                o_table.extend(3);
                IF l_values(i).ord = '3'
                THEN
                    o_table(l_counter + 1) := 'I';
                ELSE
                    o_table(l_counter + 1) := '';
                END IF;
                o_table(l_counter + 2) := l_values(i).desc_title;
                o_table(l_counter + 3) := l_values(i).desc_val;
            END LOOP;
            EXIT WHEN c_cursor%NOTFOUND;
        END LOOP;
    
        IF i_id_doc_area = g_doc_area_phy
        THEN
            CLOSE c_cursor;
            l_id_doc_area := 1045;
            l_counter     := o_table.count;
            o_table.extend(3);
            l_title := get_doc_area_title(i_lang, i_prof, l_id_doc_area);
            o_table(l_counter + 1) := '';
            o_table(l_counter + 2) := l_title;
            o_table(l_counter + 3) := '';
        
            OPEN c_cursor;
            LOOP
                FETCH c_cursor BULK COLLECT
                    INTO l_values LIMIT 100;
                FOR i IN 1 .. l_values.count
                LOOP
                    l_counter := o_table.count;
                    o_table.extend(3);
                    IF l_values(i).ord = '3'
                    THEN
                        o_table(l_counter + 1) := 'I';
                    ELSE
                        o_table(l_counter + 1) := '';
                    END IF;
                    o_table(l_counter + 2) := l_values(i).desc_title;
                    o_table(l_counter + 3) := l_values(i).desc_val;
                END LOOP;
                EXIT WHEN c_cursor%NOTFOUND;
            END LOOP;
        END IF;
    
        RETURN o_table;
    END get_doc_area_by_epis;

BEGIN
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);

END pk_ehr_common;
/
