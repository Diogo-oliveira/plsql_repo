/*-- Last Change Revision: $Rev: 1960064 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2020-07-31 19:01:55 +0100 (sex, 31 jul 2020) $*/

CREATE OR REPLACE PACKAGE BODY pk_hea_prv_encounter IS

    /*
    * @author   Elisabete Bugalho
    * @version  2.5.0.7
    * @since    09-10-2009
    */
    FUNCTION get_episode_request_reason
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
        l_reason    VARCHAR2(32767);
        l_epis_type episode.id_epis_type%TYPE;
        CURSOR c_epis_type IS
            SELECT e.id_epis_type
              FROM episode e
             WHERE e.id_episode = i_id_episode;
    BEGIN
        OPEN c_epis_type;
        FETCH c_epis_type
            INTO l_epis_type;
        CLOSE c_epis_type;
        IF l_epis_type = pk_alert_constant.g_epis_type_case_manager
        THEN
        
            SELECT pk_utils.query_to_string('SELECT pk_diagnosis.std_diag_desc(i_lang => ' || i_lang ||
                                            ', i_prof => profissional(' || i_prof.id || ' ,' || i_prof.institution || ' ,' ||
                                            i_prof.software || ')' ||
                                            ', i_id_diagnosis => d.id_diagnosis,
                                                                               i_id_task_type => pk_alert_constant.g_task_problems,
                                                                               i_code => d.code_icd,
                                                                               i_flg_other => d.flg_other,
                                                                               i_flg_std_diag => pk_alert_constant.g_yes)
                                               FROM OPINION_REASON opr, diagnosis d
                                              WHERE opr.ID_OPINION = ' ||
                                            o.id_opinion || '
                                                AND opr.ID_diagnosis = D.ID_diagnosis',
                                            ';')
              INTO l_reason
              FROM episode e, opinion o
             WHERE e.id_episode = i_id_episode
               AND e.id_episode = o.id_episode_answer;
        ELSE
            SELECT pk_utils.query_to_string('SELECT pk_diagnosis.std_diag_desc(i_lang => ' || i_lang ||
                                            ', i_prof => profissional(' || i_prof.id || ' ,' || i_prof.institution || ' ,' ||
                                            i_prof.software || ')' ||
                                            ', i_id_diagnosis => d.id_diagnosis,
                                                                               i_id_task_type => pk_alert_constant.g_task_problems,
                                                                               i_code => d.code_icd,
                                                                               i_flg_other => d.flg_other,
                                                                               i_flg_std_diag => pk_alert_constant.g_yes)
                                               FROM OPINION_REASON opr, diagnosis d
                                              WHERE opr.ID_OPINION = ' ||
                                            o.id_opinion || '
                                                AND opr.ID_diagnosis = D.ID_diagnosis',
                                            ';')
              INTO l_reason
              FROM opinion o
             WHERE o.id_episode = i_id_episode
               AND o.flg_type = 'C';
        
        END IF;
        RETURN l_reason;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    /*
    * @author   Elisabete Bugalho
    * @version  2.5.0.7
    * @since    09-10-2009
    */
    FUNCTION get_episode_level
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
        l_urgency_level VARCHAR2(32767);
    BEGIN
    
        BEGIN
            SELECT pk_translation.get_translation(i_lang, ml.code_management_level)
              INTO l_urgency_level
              FROM management_plan mp, management_level ml
             WHERE mp.id_episode = i_id_episode
               AND mp.flg_status = g_mng_plan_a
               AND mp.id_management_level = ml.id_management_level;
        EXCEPTION
            WHEN no_data_found THEN
                -- GET THE VALUE FROM OPINION
                SELECT pk_translation.get_translation(i_lang, ml.code_management_level)
                  INTO l_urgency_level
                  FROM episode e, opinion o, management_level ml
                 WHERE e.id_episode = i_id_episode
                   AND e.id_episode = o.id_episode_answer
                   AND o.id_management_level = ml.id_management_level(+);
        END;
        IF l_urgency_level IS NOT NULL
        THEN
            l_urgency_level := '(' || l_urgency_level || ')';
        END IF;
        RETURN l_urgency_level;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    /*
    * @author   Elisabete Bugalho
    * @version  2.5.0.7
    * @since    09-10-2009
    */
    FUNCTION get_encounter_type
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_encounter IN epis_encounter.id_epis_encounter%TYPE
    ) RETURN VARCHAR IS
        l_encounter_type VARCHAR2(32767);
    BEGIN
    
        SELECT (SELECT sd.desc_val
                  FROM sys_domain sd
                 WHERE sd.code_domain = g_domain_enc_flg_type
                   AND sd.domain_owner = pk_sysdomain.k_default_schema
                   AND sd.val = ee.flg_type
                   AND sd.id_language = i_lang)
          INTO l_encounter_type
          FROM epis_encounter ee
         WHERE ee.id_epis_encounter = i_id_encounter
           AND ee.id_episode = i_id_episode;
    
        RETURN l_encounter_type;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    /*
    * @author   Elisabete Bugalho
    * @version  2.5.0.7
    * @since    09-10-2009
    */
    FUNCTION get_encounter_reason
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_encounter IN epis_encounter.id_epis_encounter%TYPE
    ) RETURN VARCHAR IS
        l_encounter_reason VARCHAR2(32767);
    BEGIN
    
        SELECT pk_utils.query_to_string('SELECT PK_TRANSLATION.get_translation(' || i_lang ||
                                        ',RE.CODE_REASON)
												FROM EPIS_ENCOUNTER_REASON ECR, REASON_ENCOUNTER RE
												WHERE ECR.ID_EPIS_ENCOUNTER = ' || ee.id_epis_encounter || '
												AND ECR.ID_REASON = RE.ID_REASON',
                                        ';')
          INTO l_encounter_reason
          FROM epis_encounter ee
         WHERE ee.id_epis_encounter = i_id_encounter
           AND ee.id_episode = i_id_episode;
        IF l_encounter_reason IS NOT NULL
        THEN
            l_encounter_reason := '(' || l_encounter_reason || ')';
        END IF;
        RETURN l_encounter_reason;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    /*
    * @author   Elisabete Bugalho
    * @version  2.5.0.7
    * @since    12-10-2009
    */
    FUNCTION get_encounter_date
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_encounter IN epis_encounter.id_epis_encounter%TYPE
    ) RETURN VARCHAR IS
        l_encounter_date epis_encounter.dt_epis_encounter%TYPE;
    BEGIN
    
        SELECT ee.dt_epis_encounter
          INTO l_encounter_date
          FROM epis_encounter ee
         WHERE ee.id_epis_encounter = i_id_encounter
           AND ee.id_episode = i_id_episode;
        RETURN pk_date_utils.dt_hour_chr_short_tsz(i_lang, l_encounter_date, i_prof);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '---';
    END;

    /**
    * Returns the label for 'Encounter date'
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    *
    * @return                      The label
    *
    * @author   Elisabete Bugalho
    * @version  2.5.0.7
    * @since    12-10-2009
    */
    FUNCTION get_encounter_date
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR IS
    BEGIN
        RETURN pk_message.get_message(i_lang, i_prof, 'ID_M011');
    END;

    /*
    * @author   Elisabete Bugalho
    * @version  2.5.0.7
    * @since    12-10-2009
    */
    FUNCTION get_encounter_time_spent
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
    BEGIN
    
        RETURN nvl(pk_case_management.get_time_spent(i_lang => i_lang, i_prof => i_prof, i_episode => i_id_episode),
                   '---');
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    /**
    * Returns the label for 'Encounter date'
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    *
    * @return                      The label
    *
    * @author   Elisabete Bugalho
    * @version  2.5.0.7
    * @since    12-10-2009
    */
    FUNCTION get_encounter_time_spent
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR IS
    BEGIN
        RETURN pk_message.get_message(i_lang, i_prof, 'ID_M012');
    END;

    /**
    * Returns the episode/encounter value for the tag given as parameter.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_patient           Patient Id
    * @param i_id_episode           Episode Id
    * @param i_id_encounter         Encounter ID
    * @param i_id_epis_type         Episode type Id
    * @param i_flg_area             System application area flag
    * @param i_tag                  Tag to be replaced
    * @param o_data_rec             Tag's data   
    *
    * @return                       The episode value
    *
    * @author   Joao Sa
    * @version  2.7.1
    * @since    2017/03/08
    */
    FUNCTION get_value_html
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_encounter IN epis_encounter.id_epis_encounter%TYPE,
        i_id_epis_type IN epis_type.id_epis_type%TYPE,
        i_flg_area     IN sys_application_area.flg_area%TYPE,
        i_tag          IN header_tag.internal_name%TYPE,
        o_data_rec     OUT t_rec_header_data
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(64) := 'GET_VALUE';
        l_data_rec  t_rec_header_data := t_rec_header_data(NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL,
                                                           NULL);
    BEGIN
        g_error := g_package_name || ' ' || l_func_name || ' ' || i_tag;
        pk_alertlog.log_debug(g_error);
        IF i_id_episode IS NULL
           AND i_id_encounter IS NULL
        THEN
            RETURN FALSE;
        END IF;
    
        CASE i_tag
        
            WHEN 'EPIS_ENC_REQ_REASON' THEN
                l_data_rec.text := get_episode_request_reason(i_lang, i_prof, i_id_episode);
            WHEN 'EPIS_ENC_LEVEL' THEN
                l_data_rec.text := get_episode_level(i_lang, i_prof, i_id_episode);
            WHEN 'EPIS_ENC_TYPE' THEN
                l_data_rec.text := get_encounter_type(i_lang, i_prof, i_id_episode, i_id_encounter);
            WHEN 'EPIS_ENC_REASON' THEN
                l_data_rec.text := get_encounter_reason(i_lang, i_prof, i_id_episode, i_id_encounter);
            WHEN 'EPIS_ENCOUNTER_DATE' THEN
                l_data_rec.text        := get_encounter_date(i_lang, i_prof, i_id_episode, i_id_encounter);
                l_data_rec.description := get_encounter_date(i_lang, i_prof);
            WHEN 'EPIS_ENCOUNTER_TIME_SPENT' THEN
                l_data_rec.text        := get_encounter_time_spent(i_lang, i_prof, i_id_episode);
                l_data_rec.description := get_encounter_time_spent(i_lang, i_prof);
            ELSE
                RETURN FALSE;
        END CASE;
    
        o_data_rec := l_data_rec;
        RETURN TRUE;
    END;

    /**
    * Returns the episode/encounter value for the tag given as parameter.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_patient           Patient Id
    * @param i_id_episode           Episode Id
    * @param i_id_encounter         Encounter ID
    * @param i_id_epis_type         Episode type Id
    * @param i_flg_area             System application area flag
    * @param i_tag                  Tag to be replaced
    *
    * @return                       The episode value
    *
    * @author   Elisabete Bugalho
    * @version  2.5.0.7
    * @since    09-10-2009
    */
    FUNCTION get_value
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_encounter IN epis_encounter.id_epis_encounter%TYPE,
        i_id_epis_type IN epis_type.id_epis_type%TYPE,
        i_flg_area     IN sys_application_area.flg_area%TYPE,
        i_tag          IN header_tag.internal_name%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(64) := 'GET_VALUE';
        l_ret       BOOLEAN;
        l_data_rec  t_rec_header_data;
    BEGIN
        g_error := g_package_name || ' ' || l_func_name || ' ' || i_tag;
        pk_alertlog.log_debug(g_error);
        IF i_id_episode IS NULL
           AND i_id_encounter IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        l_ret := get_value_html(i_lang,
                                i_prof,
                                i_id_patient,
                                i_id_episode,
                                i_id_encounter,
                                i_id_epis_type,
                                i_flg_area,
                                i_tag,
                                l_data_rec);
        CASE i_tag
        
            WHEN 'EPIS_ENC_REQ_REASON' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_ENC_LEVEL' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_ENC_TYPE' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_ENC_REASON' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_ENCOUNTER_DATE' THEN
                RETURN l_data_rec.text;
            WHEN 'EPIS_ENCOUNTER_TIME_SPENT' THEN
                RETURN l_data_rec.text;
            ELSE
                RETURN NULL;
        END CASE;
        RETURN NULL;
    END;

BEGIN
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);
END;
/
