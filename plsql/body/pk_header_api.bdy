/*-- Last Change Revision: $Rev: 1960064 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2020-07-31 19:01:55 +0100 (sex, 31 jul 2020) $*/

CREATE OR REPLACE PACKAGE BODY pk_header_api IS

    /**
    * Resets the state of the auxiliar packages.
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    PROCEDURE reset_var IS
    BEGIN
        pk_hea_prv_ehr.reset_var;
        pk_hea_prv_epis.reset_var;
        pk_hea_prv_inst.reset_var;
        pk_hea_prv_pat.reset_var;
        pk_hea_prv_prof.reset_var;
        pk_hea_prv_ref.reset_var;
        pk_hea_prv_aud.reset_var;
    END;

    /**
    * Returns the header Id for the context set by the variables given as parameters.
    *
    * @param i_prof              Professional
    * @param i_id_epis_type      Episode type Id
    * @param i_id_profile        Profile template Id
    * @param i_screen_mode       Screen mode
    *
    * @return                    The header Id
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_header_id
    (
        i_prof         IN profissional,
        i_id_epis_type IN epis_type.id_epis_type%TYPE,
        i_id_profile   IN profile_template.id_profile_template%TYPE,
        i_screen_mode  IN header.flg_screen_mode%TYPE
    ) RETURN NUMBER IS
        l_func_name VARCHAR2(64) := 'GET_HEADER_ID';
        l_header_id header.id_header%TYPE;
        l_id_market market.id_market%TYPE := pk_core.get_inst_mkt(i_prof.institution);
    
    BEGIN
    
        g_error := 'OPEN CURSOR O_HEADER';
        SELECT id_header
          INTO l_header_id
          FROM (SELECT h.id_header
                  FROM header h
                  JOIN header_cfg hc
                    ON (hc.id_header = h.id_header AND hc.id_software IN (0, i_prof.software) AND
                       hc.id_epis_type IN (0, nvl(i_id_epis_type, 0)) AND
                       hc.id_profile_template IN (0, nvl(i_id_profile, 0)) AND hc.id_market IN (0, nvl(l_id_market, 0)))
                 WHERE h.flg_screen_mode = i_screen_mode
                   AND hc.flg_available = pk_alert_constant.g_yes
                 ORDER BY hc.id_epis_type DESC, hc.id_profile_template DESC, hc.id_software DESC, hc.id_market DESC)
         WHERE rownum < 2;
    
        RETURN l_header_id;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.error_handling(i_func_proc_name => l_func_name,
                                               i_package_name   => g_package_name,
                                               i_package_error  => g_error,
                                               i_sql_error      => SQLERRM);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
    END;

    /**
    * Returns the episode type of the episode id or schedule id givens as parameter
    */
    FUNCTION get_epis_type
    (
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN epis_type.id_epis_type%TYPE IS
    
        l_id_epis_type epis_type.id_epis_type%TYPE;
        l_id_episode   episode.id_episode%TYPE;
    
    BEGIN
    
        IF i_id_episode <> -1
        THEN
            l_id_episode := i_id_episode;
        END IF;
    
        SELECT id_epis_type
          INTO l_id_epis_type
          FROM (SELECT e.id_epis_type
                  FROM episode e
                 WHERE e.id_episode = l_id_episode
                UNION ALL
                SELECT so.id_epis_type
                  FROM schedule_outp so
                 WHERE so.id_schedule = i_id_schedule
                   AND l_id_episode IS NULL)
         WHERE rownum < 2;
    
        RETURN l_id_epis_type;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_epis_type;

    FUNCTION get_id_header
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_screen_mode IN header.flg_screen_mode%TYPE,
        o_id_header   OUT header.id_header%TYPE
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(64) := 'get_id_header';
    
        l_header_id    header.id_header%TYPE;
        l_id_market    market.id_market%TYPE := pk_core.get_inst_mkt(i_prof.institution);
        l_id_epis_type epis_type.id_epis_type%TYPE := get_epis_type(i_id_episode, i_id_schedule); -- This must be in a core package! 
        l_id_profile   profile_template.id_profile_template%TYPE := pk_tools.get_prof_profile_template(i_prof);
    
    BEGIN
    
        g_error := 'before get_id_header query';
        SELECT id_header
          INTO l_header_id
          FROM (SELECT h.id_header
                  FROM header h
                  JOIN header_cfg hc
                    ON (hc.id_header = h.id_header AND hc.id_software IN (0, i_prof.software) AND
                       hc.id_epis_type IN (0, nvl(l_id_epis_type, 0)) AND
                       hc.id_profile_template IN (0, nvl(l_id_profile, 0)) AND hc.id_market IN (0, nvl(l_id_market, 0)))
                 WHERE h.flg_screen_mode = i_screen_mode
                   AND hc.flg_available = pk_alert_constant.g_yes
                 ORDER BY hc.id_epis_type DESC, hc.id_profile_template DESC, hc.id_software DESC, hc.id_market DESC)
         WHERE rownum < 2;
    
        o_id_header := l_header_id;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.error_handling(i_func_proc_name => l_func_name,
                                               i_package_name   => g_package_name,
                                               i_package_error  => g_error,
                                               i_sql_error      => SQLERRM);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            RETURN FALSE;
    END get_id_header;

    /**
    * Returns the value to be replaced by the tag given all context variables as parameters.
    *
    * @param i_lang                   Language
    * @param i_prof                   Professional
    * @param i_id_episode             Episode Id
    * @param i_id_child_episode       Child Episode Id: to be used when the header is shown info about the parent and the child episode
    * @param i_id_patient             Patient Id
    * @param i_id_schedule            Schedule Id
    * @param i_id_epis_type           Episode type Id
    * @param i_id_profile             Profile template Id
    * @param i_flg_area               System application area flag
    * @param i_id_prof                Professional Id (Backoffice only)
    * @param i_id_institution         Institution Id (Backoffice only)
    * @param i_id_external_request    External request Id (Referral only)
    * @param i_id_audit_req           Audit request Id (Manchester audit only)
    * @param i_id_audit_req_prof      Audit request professional Id (Manchester audit only)
    * @param i_id_audit_req_prof_epis Audit request professional episode Id (Manchester audit only)
    * @param i_id_announced_arrival   Announced Arrival Id (EDIS NL only)
    * @param i_grp                    Tag group to be retrieved from the respective package
    * @param i_tag                    Tag to be replaced in the Header
    * @param o_text                   Tag's text
    * @param o_description            Tag's description
    * @param o_icon                   Tag's icon
    * @param o_action                 Tag's action
    * @param o_shortcut               Tag's shortcut
    * @param o_source                 Tag's source
    
    * @return                         The value associated to the tag
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_value
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_episode             IN episode.id_episode%TYPE,
        i_id_child_episode       IN episode.id_episode%TYPE,
        i_id_patient             IN patient.id_patient%TYPE,
        i_id_schedule            IN schedule.id_schedule%TYPE,
        i_id_epis_type           IN epis_type.id_epis_type%TYPE,
        i_id_profile             IN profile_template.id_profile_template%TYPE,
        i_flg_area               IN sys_application_area.flg_area%TYPE,
        i_id_prof                IN professional.id_professional%TYPE,
        i_id_institution         IN institution.id_institution%TYPE,
        i_id_external_request    IN p1_external_request.id_external_request%TYPE,
        i_id_audit_req           IN audit_req.id_audit_req%TYPE,
        i_id_audit_req_prof      IN audit_req_prof.id_audit_req_prof%TYPE,
        i_id_audit_req_prof_epis IN audit_req_prof_epis.id_audit_req_prof_epis%TYPE,
        i_id_announced_arrival   IN announced_arrival.id_announced_arrival%TYPE,
        i_id_pat_identifier      IN pat_identifier.id_pat_identifier%TYPE,
        i_id_epis_encounter      IN epis_encounter.id_epis_encounter%TYPE,
        i_grp                    IN header_tag_grp.internal_name%TYPE,
        i_tag                    IN header_tag.internal_name%TYPE,
        o_data_rec               OUT t_rec_header_data
    ) RETURN BOOLEAN IS
    
        l_data_rec t_rec_header_data := t_rec_header_data(NULL,
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
        l_ret      BOOLEAN := FALSE;
    
    BEGIN
        g_error := 'GET_PATIENT_VALUE';
        CASE i_grp
            WHEN 'PATIENT' THEN
                l_ret := pk_hea_prv_pat.get_value_html(i_lang                 => i_lang,
                                                       i_prof                 => i_prof,
                                                       i_id_profile           => i_id_profile,
                                                       i_id_patient           => i_id_patient,
                                                       i_id_episode           => i_id_episode,
                                                       i_id_schedule          => i_id_episode,
                                                       i_id_announced_arrival => i_id_announced_arrival,
                                                       i_tag                  => i_tag,
                                                       o_data_rec             => l_data_rec);
            
            WHEN 'EPISODE' THEN
                l_ret := pk_hea_prv_epis.get_value_html(i_lang              => i_lang,
                                                        i_prof              => i_prof,
                                                        i_id_patient        => i_id_patient,
                                                        i_id_episode        => i_id_episode,
                                                        i_id_child_episode  => i_id_child_episode,
                                                        i_id_schedule       => i_id_schedule,
                                                        i_id_epis_type      => i_id_epis_type,
                                                        i_id_pat_identifier => i_id_pat_identifier,
                                                        i_flg_area          => i_flg_area,
                                                        i_tag               => i_tag,
                                                        o_data_rec          => l_data_rec);
            
            WHEN 'PROFESSIONAL' THEN
                l_ret := pk_hea_prv_prof.get_value_html(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_id_professional => i_id_prof,
                                                        i_id_institution  => i_id_institution,
                                                        i_tag             => i_tag,
                                                        o_data_rec        => l_data_rec);
            
            WHEN 'EHR' THEN
                l_ret := pk_hea_prv_ehr.get_value_html(i_lang             => i_lang,
                                                       i_prof             => i_prof,
                                                       i_id_patient       => i_id_patient,
                                                       i_id_episode       => i_id_episode,
                                                       i_id_child_episode => i_id_child_episode,
                                                       i_id_epis_type     => i_id_epis_type,
                                                       i_id_profile       => i_id_profile,
                                                       i_flg_area         => i_flg_area,
                                                       i_tag              => i_tag,
                                                       o_data_rec         => l_data_rec);
            
            WHEN 'INSTITUTION' THEN
                l_ret := pk_hea_prv_inst.get_value_html(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_id_institution => i_id_institution,
                                                        i_tag            => i_tag,
                                                        o_data_rec       => l_data_rec);
            
            WHEN 'USER' THEN
                l_ret := pk_hea_prv_user.get_value_html(i_lang     => i_lang,
                                                        i_prof     => i_prof,
                                                        i_flg_area => i_flg_area,
                                                        i_tag      => i_tag,
                                                        o_data_rec => l_data_rec);
            
            WHEN 'LABEL' THEN
                IF i_id_episode IS NULL
                   AND i_id_patient IS NULL
                   AND i_id_schedule IS NULL
                   AND i_id_audit_req_prof_epis IS NULL
                THEN
                    RETURN FALSE;
                END IF;
                l_ret := pk_hea_prv_label.get_value_html(i_lang     => i_lang,
                                                         i_prof     => i_prof,
                                                         i_tag      => i_tag,
                                                         o_data_rec => l_data_rec);
            
            WHEN 'REFERRAL' THEN
                l_ret := pk_hea_prv_ref.get_value_html(i_lang                => i_lang,
                                                       i_prof                => i_prof,
                                                       i_id_external_request => i_id_external_request,
                                                       i_tag                 => i_tag,
                                                       o_data_rec            => l_data_rec);
            
            WHEN 'TRIAGE_AUDIT' THEN
                l_ret := pk_hea_prv_aud.get_value_html(i_lang                   => i_lang,
                                                       i_prof                   => i_prof,
                                                       i_id_audit_req           => i_id_audit_req,
                                                       i_id_audit_req_prof      => i_id_audit_req_prof,
                                                       i_id_audit_req_prof_epis => i_id_audit_req_prof_epis,
                                                       i_tag                    => i_tag,
                                                       o_data_rec               => l_data_rec);
            
            WHEN 'ENCOUNTER' THEN
                l_ret := pk_hea_prv_encounter.get_value_html(i_lang         => i_lang,
                                                             i_prof         => i_prof,
                                                             i_id_patient   => i_id_patient,
                                                             i_id_episode   => i_id_episode,
                                                             i_id_encounter => i_id_epis_encounter,
                                                             i_id_epis_type => i_id_epis_type,
                                                             i_flg_area     => i_flg_area,
                                                             i_tag          => i_tag,
                                                             o_data_rec     => l_data_rec);
            
            ELSE
                RETURN FALSE;
        END CASE;
    
        o_data_rec := l_data_rec;
    
        RETURN l_ret;
    
    END get_value;

    PROCEDURE resolve_variables
    (
        i_id_keys                IN table_varchar,
        i_id_values              IN table_varchar,
        o_id_professional        OUT professional.id_professional%TYPE,
        o_id_institution         OUT institution.id_institution%TYPE,
        o_id_license             OUT license.id_license%TYPE,
        o_id_external_request    OUT p1_external_request.id_external_request%TYPE,
        o_id_audit_req           OUT audit_req.id_audit_req%TYPE,
        o_id_audit_req_prof      OUT audit_req_prof.id_audit_req_prof%TYPE,
        o_id_audit_req_prof_epis OUT audit_req_prof_epis.id_audit_req_prof_epis%TYPE,
        o_id_unidose_car         OUT unidose_car.id_unidose_car%TYPE,
        o_id_ann_arrival         OUT announced_arrival.id_announced_arrival%TYPE,
        o_id_pat_identifier      OUT pat_identifier.id_pat_identifier%TYPE,
        o_id_epis_encounter      OUT epis_encounter.id_epis_encounter%TYPE
        
    ) IS
    
        l_key   VARCHAR2(100);
        l_value VARCHAR2(100);
    
    BEGIN
    
        IF i_id_keys IS NOT NULL
           AND i_id_keys.count > 0
        THEN
            g_error := 'GET_VARIABLES';
            FOR i IN 1 .. i_id_keys.count
            LOOP
                l_key   := upper(i_id_keys(i));
                l_value := i_id_values(i);
                CASE l_key
                    WHEN 'ID_PROFESSIONAL' THEN
                        IF l_value IS NOT NULL
                        THEN
                            o_id_professional := to_number(l_value);
                        END IF;
                    WHEN 'ID_INSTITUTION' THEN
                        IF l_value IS NOT NULL
                        THEN
                            o_id_institution := to_number(l_value);
                        END IF;
                    WHEN 'ID_LICENSE' THEN
                        IF l_value IS NOT NULL
                        THEN
                            o_id_license := to_number(l_value);
                        END IF;
                    WHEN 'ID_EXTERNAL_REQUEST' THEN
                        IF l_value IS NOT NULL
                        THEN
                            o_id_external_request := to_number(l_value);
                        END IF;
                    WHEN 'ID_AUDIT_REQ' THEN
                        IF l_value IS NOT NULL
                        THEN
                            o_id_audit_req := to_number(l_value);
                        END IF;
                    WHEN 'ID_AUDIT_REQ_PROF' THEN
                        IF l_value IS NOT NULL
                        THEN
                            o_id_audit_req_prof := to_number(l_value);
                        END IF;
                    WHEN 'ID_AUDIT_REQ_PROF_EPIS' THEN
                        IF l_value IS NOT NULL
                        THEN
                            o_id_audit_req_prof_epis := to_number(l_value);
                        END IF;
                    WHEN 'ID_UNIDOSE_CAR' THEN
                        IF l_value IS NOT NULL
                        THEN
                            o_id_unidose_car := to_number(l_value);
                        END IF;
                    WHEN 'ID_ANNOUNCED_ARRIVAL' THEN
                        IF l_value IS NOT NULL
                        THEN
                            o_id_ann_arrival := to_number(l_value);
                        END IF;
                    WHEN 'ID_PAT_IDENTIFIER' THEN
                        IF l_value IS NOT NULL
                        THEN
                            o_id_pat_identifier := to_number(l_value);
                        END IF;
                    WHEN 'ID_FOLLOW_UP' THEN
                        IF l_value IS NOT NULL
                        THEN
                            o_id_epis_encounter := to_number(l_value);
                        END IF;
                    
                    ELSE
                        NULL;
                END CASE;
            END LOOP;
        END IF;
    
    END resolve_variables;

    /**
    * Returns the data to be shown in the header
    *
    * @param i_arr_tag           List of tags     
    * @param i_lang              Language identifier
    * @param i_prof              Professional
    * @param i_id_episode        Episode Id
    * @param i_id_patient        Patient Id
    * @param i_id_schedule       Schedule Id
    * @param i_flg_area          System application area flag
    * @param i_id_keys           List of additional keys
    * @param i_id_values         List of values to be mapped with the list of keys
    *
    * @param o_data              List of tags and values to be replaced in the header.
    * @param o_error             Error object
    *
    * @return                    TRUE if succeeded. FALSE otherwise.
    *
    * @author   Joao Sa
    * @version  2.7.1
    * @since    2017/03/07
    */
    FUNCTION get_header_data
    (
        i_arr_tag     IN table_varchar,
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_patient  IN patient.id_patient%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_flg_area    IN sys_application_area.flg_area%TYPE,
        i_id_keys     IN table_varchar,
        i_id_values   IN table_varchar,
        o_data        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tag                    VARCHAR2(128);
        l_grp                    VARCHAR2(128);
        l_count                  NUMBER;
        l_id_professional        professional.id_professional%TYPE;
        l_id_institution         institution.id_institution%TYPE;
        l_id_license             license.id_license%TYPE;
        l_id_external_request    p1_external_request.id_external_request%TYPE;
        l_id_epis_type           epis_type.id_epis_type%TYPE := get_epis_type(i_id_episode, i_id_schedule);
        l_id_profile             profile_template.id_profile_template%TYPE := pk_tools.get_prof_profile_template(i_prof);
        l_id_audit_req           audit_req.id_audit_req%TYPE;
        l_id_audit_req_prof      audit_req_prof.id_audit_req_prof%TYPE;
        l_id_audit_req_prof_epis audit_req_prof_epis.id_audit_req_prof_epis%TYPE;
        l_id_unidose_car         unidose_car.id_unidose_car%TYPE;
        l_id_ann_arrival         announced_arrival.id_announced_arrival%TYPE;
        l_id_pat_identifier      pat_identifier.id_pat_identifier%TYPE;
        l_id_epis_encounter      epis_encounter.id_epis_encounter%TYPE;
        l_id_patient             episode.id_patient%TYPE;
        l_id_schedule            schedule.id_schedule%TYPE := i_id_schedule;
        l_id_episode             episode.id_episode%TYPE := i_id_episode;
        l_internal_error EXCEPTION;
    
        err_timestamp_error EXCEPTION;
        l_timestamp        TIMESTAMP WITH TIME ZONE;
        l_timestamp_val    VARCHAR2(0100 CHAR);
        l_timestamp_tag    VARCHAR2(0100 CHAR) := 'TIMESTAMP_STR';
        l_return           BOOLEAN;
        l_id_child_episode episode.id_episode%TYPE := NULL;
    
        l_ret      BOOLEAN;
        l_data     t_tbl_header_data;
        l_data_rec t_rec_header_data := t_rec_header_data(NULL,
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
    
        g_error := 'RESOLVE_VARIABLES';
        resolve_variables(i_id_keys,
                          i_id_values,
                          l_id_professional,
                          l_id_institution,
                          l_id_license,
                          l_id_external_request,
                          l_id_audit_req,
                          l_id_audit_req_prof,
                          l_id_audit_req_prof_epis,
                          l_id_unidose_car,
                          l_id_ann_arrival,
                          l_id_pat_identifier,
                          l_id_epis_encounter);
    
        g_error := 'RESET_VAR';
        reset_var;
    
        l_count := i_arr_tag.count;
    
        --in the activity therapist should be shown on header the inpatient info. Therefore, the inpatient
        -- episode will be used to get the header info
        IF l_id_epis_type = pk_act_therap_constant.g_activ_therap_epis_type
           AND i_id_episode IS NOT NULL
        THEN
            g_error := 'CALL PK_ACTIVITY_THERAPIST.GET_EPIS_PARENT with id_episode: ' || i_id_episode;
            IF NOT pk_activity_therapist.get_epis_parent(i_lang       => i_lang,
                                                         i_prof       => i_prof,
                                                         i_id_episode => i_id_episode,
                                                         o_id_episode => l_id_episode,
                                                         o_error      => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
            l_id_child_episode := i_id_episode;
        
            IF l_id_episode IS NULL
            THEN
                l_id_episode := i_id_episode;
            END IF;
        END IF;
    
        l_id_patient := i_id_patient;
        IF i_id_episode IS NOT NULL
           AND l_id_episode > 0
           AND (i_id_patient IS NULL OR i_id_patient = 0)
        THEN
            SELECT pk_episode.get_epis_patient(i_lang, i_prof, i_id_episode)
              INTO l_id_patient
              FROM dual;
        END IF;
        IF i_id_schedule IS NULL
           AND i_id_episode IS NOT NULL
        THEN
            SELECT id_schedule
              INTO l_id_schedule
              FROM epis_info
             WHERE id_episode = i_id_episode;
        END IF;
        l_data := t_tbl_header_data();
        l_data.extend(l_count);
    
        g_error := 'FOR l_count = ' || l_count;
        FOR i IN 1 .. l_count
        LOOP
            -- Get group from tag id
            l_grp := pk_utils.str_token(i_arr_tag(i), 1, '.');
            l_tag := pk_utils.str_token(i_arr_tag(i), 2, '.');
        
            IF i_prof.software = pk_alert_constant.g_soft_act_therapist
               AND i_id_episode IS NULL
               AND (l_grp = 'EHR' AND l_tag = 'EHR_ADVANCE_DIRECTIVES_SHORTCUT')
            THEN
                l_data_rec := t_rec_header_data(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
            ELSE
                g_error := 'get_value(' || l_grp || ',' || l_tag || ')';
                l_ret   := get_value(i_lang,
                                     i_prof,
                                     l_id_episode,
                                     l_id_child_episode,
                                     l_id_patient,
                                     l_id_schedule,
                                     l_id_epis_type,
                                     l_id_profile,
                                     i_flg_area,
                                     l_id_professional,
                                     l_id_institution,
                                     l_id_external_request,
                                     l_id_audit_req,
                                     l_id_audit_req_prof,
                                     l_id_audit_req_prof_epis,
                                     l_id_ann_arrival,
                                     l_id_pat_identifier,
                                     l_id_epis_encounter,
                                     l_grp,
                                     l_tag,
                                     l_data_rec);
            
                l_data(i) := l_data_rec;
            END IF;
        END LOOP;
    
        -- call to reassesss time for watch syncro bt Flash component
        l_return := pk_date_utils.get_timestamp_anytimezone(i_lang          => i_lang,
                                                            i_prof          => i_prof,
                                                            i_timestamp     => NULL,
                                                            i_timestamp_str => NULL,
                                                            i_timezone      => NULL,
                                                            o_timestamp     => l_timestamp,
                                                            o_timestamp_str => l_timestamp_val,
                                                            o_error         => o_error);
        IF l_return = FALSE
        THEN
            RAISE err_timestamp_error;
        END IF;
    
        g_error := 'OPEN O_DATA';
        OPEN o_data FOR
            SELECT tag,
                   t_data.text,
                   t_data.description,
                   t_data.status,
                   t_data.icon,
                   t_data.action,
                   t_data.action_param,
                   t_data.shortcut,
                   t_data.source,
                   t_data.tooltip_title,
                   t_data.tooltip_text,
                   t_data.tooltip_status,
                   t_data.tooltip_icon
              FROM (SELECT rownum r, t_tag.column_value tag
                      FROM TABLE(i_arr_tag) t_tag) t_tag
              JOIN (SELECT rownum r,
                           text,
                           description,
                           status,
                           icon,
                           action,
                           action_param,
                           shortcut,
                           SOURCE,
                           tooltip_title,
                           tooltip_text,
                           tooltip_status,
                           tooltip_icon
                      FROM TABLE(CAST(l_data AS t_tbl_header_data)) t_data) t_data
                ON t_tag.r = t_data.r
            UNION ALL
            SELECT l_timestamp_tag tag,
                   l_timestamp_val text,
                   NULL            description,
                   NULL            status,
                   NULL            icon,
                   NULL            action,
                   NULL            action_param,
                   NULL            shortcut,
                   NULL            SOURCE,
                   NULL            tooltip_title,
                   NULL            tooltip_text,
                   NULL            tooltip_status,
                   NULL            tooltip_icon
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_HEADER',
                                              o_error);
            pk_types.open_my_cursor(o_data);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_header_data;

BEGIN
    -- Log initialization.
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);
END pk_header_api;
/
