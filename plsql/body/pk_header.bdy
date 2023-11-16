/*-- Last Change Revision: $Rev: 1940336 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2020-03-13 19:06:13 +0000 (sex, 13 mar 2020) $*/

CREATE OR REPLACE PACKAGE BODY pk_header IS

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
    * Returns the market for the institution given as parameter.
    *
    * @param i_id_institution    Institution Id
    *
    * @return                    The market Id
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_market_by_institution(i_id_institution IN institution.id_institution%TYPE) RETURN market.id_market%TYPE IS
        l_id_market market.id_market%TYPE;
    BEGIN
        SELECT i.id_market
          INTO l_id_market
          FROM institution i
         WHERE i.id_institution = i_id_institution;
    
        RETURN l_id_market;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END;

    /**
    * Returns the episode type of the episode Id or schedule Id givens as parameter.
    *
    * @param i_id_episode        Episode Id
    * @param i_id_schedule       Schedule Id
    *
    * @return                    The episode type Id
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
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
        l_id_market market.id_market%TYPE := get_market_by_institution(i_prof.institution);
    BEGIN
        g_error := 'OPEN CURSOR O_HEADER';
        alertlog.pk_alertlog.log_debug(g_error);
        SELECT id_header
          INTO l_header_id
          FROM (SELECT h.id_header
                  FROM header h
                  JOIN header_cfg hc
                    ON (hc.id_header = h.id_header AND hc.id_software IN (0, i_prof.software) AND
                       hc.id_epis_type IN (0, nvl(i_id_epis_type, 0)) AND
                       hc.id_profile_template IN (0, nvl(i_id_profile, 0)) AND hc.id_market IN (0, nvl(l_id_market, 0)))
                 WHERE --h.flg_screen_mode = i_screen_mode AND 
                 hc.flg_available = pk_alert_constant.g_yes
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
    * Returns the list of headers available for the logged professional.
    *
    * @param i_lang              Language identifier
    * @param i_prof              Professional
    *
    * @param o_headers           The list of headers available for the logged professional
    * @param o_error             Error object
    *
    * @return                    TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_header_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_headers OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name  VARCHAR2(64) := 'GET_HEADERS';
        l_id_profile profile_template.id_profile_template%TYPE := pk_tools.get_prof_profile_template(i_prof);
    BEGIN
    
        g_error := 'OPEN CURSOR O_HEADER';
        pk_alertlog.log_debug(g_error);
    
        OPEN o_headers FOR
            SELECT h.id_header, h.xml_format
              FROM header h
              JOIN (SELECT DISTINCT h.id_header
                      FROM header h
                      JOIN header_cfg hc
                        ON hc.id_header = h.id_header
                       AND hc.id_software IN (0, i_prof.software)
                       AND hc.id_profile_template IN (0, l_id_profile)
                      JOIN institution i
                        ON i.id_institution = i_prof.institution
                       AND hc.id_market IN (0, i.id_market)) aux
                ON aux.id_header = h.id_header;
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
            pk_types.open_my_cursor(o_headers);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

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
    *
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
        i_tag                    IN header_tag.internal_name%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(64) := 'GET_PATIENT_VALUE';
    BEGIN
        g_error := l_func_name;
        pk_alertlog.log_debug(g_error);
        CASE i_grp
            WHEN 'PATIENT' THEN
                RETURN pk_hea_prv_pat.get_value(i_lang,
                                                i_prof,
                                                i_id_profile,
                                                i_id_patient,
                                                i_id_episode,
                                                i_id_schedule,
                                                i_id_announced_arrival,
                                                i_tag);
            WHEN 'EPISODE' THEN
                RETURN pk_hea_prv_epis.get_value(i_lang,
                                                 i_prof,
                                                 i_id_patient,
                                                 i_id_episode,
                                                 i_id_child_episode,
                                                 i_id_schedule,
                                                 i_id_epis_type,
                                                 i_id_pat_identifier,
                                                 i_flg_area,
                                                 i_tag);
            WHEN 'PROFESSIONAL' THEN
                RETURN pk_hea_prv_prof.get_value(i_lang, i_prof, i_id_prof, i_id_institution, i_tag);
            WHEN 'EHR' THEN
                RETURN pk_hea_prv_ehr.get_value(i_lang,
                                                i_prof,
                                                i_id_patient,
                                                i_id_episode,
                                                i_id_child_episode,
                                                i_id_epis_type,
                                                i_id_profile,
                                                i_flg_area,
                                                i_tag);
            WHEN 'INSTITUTION' THEN
                RETURN pk_hea_prv_inst.get_value(i_lang, i_prof, i_id_institution, i_tag);
            WHEN 'USER' THEN
                RETURN pk_hea_prv_user.get_value(i_lang, i_prof, i_flg_area, i_tag);
            WHEN 'LABEL' THEN
                IF i_id_episode IS NULL
                   AND i_id_patient IS NULL
                   AND i_id_schedule IS NULL
                   AND i_id_audit_req_prof_epis IS NULL
                THEN
                    RETURN NULL;
                END IF;
                RETURN pk_hea_prv_label.get_value(i_lang, i_prof, i_tag);
            WHEN 'REFERRAL' THEN
                RETURN pk_hea_prv_ref.get_value(i_lang, i_prof, i_id_external_request, i_tag);
            WHEN 'TRIAGE_AUDIT' THEN
                RETURN pk_hea_prv_aud.get_value(i_lang,
                                                i_prof,
                                                i_id_audit_req,
                                                i_id_audit_req_prof,
                                                i_id_audit_req_prof_epis,
                                                i_tag);
            
            WHEN 'ENCOUNTER' THEN
                RETURN pk_hea_prv_encounter.get_value(i_lang,
                                                      i_prof,
                                                      i_id_patient,
                                                      i_id_episode,
                                                      i_id_epis_encounter,
                                                      i_id_epis_type,
                                                      i_flg_area,
                                                      i_tag);
            ELSE
                RETURN NULL;
        END CASE;
        RETURN NULL;
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
            pk_alertlog.log_debug(g_error);
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
    END;

    /**
    * Returns the header and the list of values to be filled in it.
    *
    * @param i_lang              Language identifier
    * @param i_prof              Professional
    *
    * @param i_id_episode        Episode Id
    * @param i_id_patient        Patient Id
    * @param i_id_schedule       Schedule Id
    * @param i_screen_mode       Screen mode [N-Normal, F-Fullscreen]
    * @param i_flg_area          System application area flag
    * @param i_id_keys           List of additional keys
    * @param i_id_values         List of values to be mapped with the list of keys
    *
    * @param o_id_header         The header Id to be shown
    * @param o_data              List of tags and values to be replaced in the header.
    * @param o_error             Error object
    *
    * @return                    TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_header
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_patient  IN patient.id_patient%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_screen_mode IN header.flg_screen_mode%TYPE,
        i_flg_area    IN sys_application_area.flg_area%TYPE,
        i_id_keys     IN table_varchar,
        i_id_values   IN table_varchar,
        o_id_header   OUT header.id_header%TYPE,
        o_data        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(64) := 'GET_HEADER';
        l_id_header header.id_header%TYPE;
        l_arr_tag   table_varchar;
        l_arr_grp   table_varchar;
        l_arr_val   table_varchar;
        CURSOR c_cursor IS
            SELECT DISTINCT ht.internal_name tag, htg.internal_name grp
              FROM hea_header_tag hht
              JOIN header_tag ht
                ON ht.id_header_tag = hht.id_header_tag
              JOIN header_tag_grp htg
                ON htg.id_header_tag_grp = ht.id_header_tag_grp
             WHERE hht.id_header = l_id_header
             ORDER BY grp, tag;
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
    
        l_id_episode episode.id_episode%TYPE := i_id_episode;
        l_internal_error EXCEPTION;
    
        err_timestamp_error EXCEPTION;
        l_timestamp        TIMESTAMP WITH TIME ZONE;
        l_timestamp_val    VARCHAR2(0100 CHAR);
        l_timestamp_tag    VARCHAR2(0100 CHAR) := 'TIMESTAMP_STR';
        l_return           BOOLEAN;
        l_id_child_episode episode.id_episode%TYPE := NULL;
    BEGIN
        g_error := 'INSIDE ' || l_func_name;
        pk_alertlog.log_debug(g_error);
    
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
    
        g_error := 'GET_HEADER_ID';
        pk_alertlog.log_debug(g_error);
        l_id_header := get_header_id(i_prof, l_id_epis_type, l_id_profile, i_screen_mode);
    
        g_error := 'RESET variables';
        pk_alertlog.log_debug(g_error);
    
        reset_var;
    
        g_error := 'OPEN c_cursor';
        pk_alertlog.log_debug(g_error);
        OPEN c_cursor;
        g_error := 'FETCH c_cursor BULK COLLECT';
        pk_alertlog.log_debug(g_error);
        FETCH c_cursor BULK COLLECT
            INTO l_arr_tag, l_arr_grp;
        CLOSE c_cursor;
    
        l_count := l_arr_tag.count;
        g_error := 'l_count = ' || l_count;
        pk_alertlog.log_debug(g_error);
    
        --in the activity therapist should be shown on header the inpatient info. Therefore, the inpatient 
        -- episode will be used to get the header info
        IF (l_id_epis_type = pk_act_therap_constant.g_activ_therap_epis_type AND i_id_episode IS NOT NULL)
        THEN
            g_error := 'CALL pk_activity_therapist.get_epis_parent with id_episode: ' || i_id_episode;
            pk_alertlog.log_debug(g_error);
            IF NOT pk_activity_therapist.get_epis_parent(i_lang       => i_lang,
                                                         i_prof       => i_prof,
                                                         i_id_episode => i_id_episode,
                                                         o_id_episode => l_id_episode,
                                                         o_error      => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
            l_id_child_episode := i_id_episode;
        
            IF (l_id_episode IS NULL)
            THEN
                l_id_episode := i_id_episode;
            END IF;
        END IF;
    
        l_id_patient := i_id_patient;
        IF (i_id_episode IS NOT NULL AND l_id_episode > 0 AND (i_id_patient IS NULL OR i_id_patient = 0))
        THEN
            SELECT pk_episode.get_epis_patient(i_lang, i_prof, i_id_episode)
              INTO l_id_patient
              FROM dual;
        END IF;
    
        l_arr_val := table_varchar();
        l_arr_val.extend(l_count);
        FOR i IN 1 .. l_count
        LOOP
            IF (i_prof.software = pk_alert_constant.g_soft_act_therapist AND i_id_episode IS NULL AND
               (l_arr_grp(i) = 'EHR' AND l_arr_tag(i) = 'EHR_ADVANCE_DIRECTIVES_SHORTCUT'))
            THEN
                l_arr_val(i) := NULL;
            ELSE
                g_error := 'get_value(' || l_arr_grp(i) || ',' || l_arr_tag(i) || ')';
                pk_alertlog.log_debug(g_error);
                l_arr_val(i) := get_value(i_lang,
                                          i_prof,
                                          l_id_episode,
                                          l_id_child_episode,
                                          l_id_patient,
                                          i_id_schedule,
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
                                          l_arr_grp(i),
                                          l_arr_tag(i));
            
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
    
        g_error := 'OPEN o_data';
        pk_alertlog.log_debug(g_error);
        OPEN o_data FOR
            SELECT tag, val
              FROM (SELECT rownum r1, table1.column_value tag
                      FROM TABLE(l_arr_tag) table1) table1,
                   (SELECT rownum r2, table2.column_value val
                      FROM TABLE(l_arr_val) table2) table2
             WHERE table1.r1 = table2.r2
            UNION ALL
            SELECT l_timestamp_tag tag, l_timestamp_val val
              FROM dual;
    
        o_id_header := l_id_header;
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
            pk_types.open_my_cursor(o_data);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_header;

    /**
    * Returns a list of header tags from a given xml
    *
    * @param i_xml     The cofiguration xml
    *
    * @param o_tags    A table_varchar with the list of header tags
    * @param o_error   Error object
    *
    * @return          TRUE if succeeded. FALSE otherwise.
    *
    * @author   Sérgio Santos
    * @version  2.5
    * @since    2009/03/07
    */
    FUNCTION get_header_tags_from_xml
    (
        i_lang  IN language.id_language%TYPE,
        i_xml   IN LONG,
        o_tags  OUT table_varchar,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(64) := 'GET_HEADER_TAGS_FROM_XML';
    
        l_p   xmlparser.parser;
        l_doc xmldom.domdocument;
    
        --This function checks if an input String is an header tag
        FUNCTION check_header_tag_str(input VARCHAR2) RETURN BOOLEAN IS
            l_result BOOLEAN := FALSE;
        BEGIN
            IF substr(input, 1, 2) = '${'
               AND substr(input, length(input), 1) = '}'
            THEN
                l_result := TRUE;
            ELSE
                l_result := FALSE;
            END IF;
            RETURN l_result;
        
        END check_header_tag_str;
    
        --This function removes the 1st,2nd and last char from the input string
        --the idea is transform something like '${SOME_TEXT}' into 'SOME_TEXT'
        FUNCTION treat_header_tag_str(input VARCHAR2) RETURN VARCHAR2 IS
            l_result VARCHAR2(4000);
        BEGIN
            l_result := substr(input, 3, length(input) - 3);
        
            RETURN l_result;
        END treat_header_tag_str;
    
        -- prints the attributes of each element in a document
        FUNCTION get_tags(doc xmldom.domdocument) RETURN table_varchar IS
            nl        xmldom.domnodelist;
            len1      NUMBER;
            len2      NUMBER;
            n         xmldom.domnode;
            nnm       xmldom.domnamednodemap;
            attrval   VARCHAR2(100);
            realvalue VARCHAR2(4000);
        
            l_tags_list table_varchar;
        BEGIN
            -- get all elements
            nl   := xmldom.getelementsbytagname(doc, '*');
            len1 := xmldom.getlength(nl);
        
            l_tags_list := table_varchar();
            -- loop through elements
            FOR j IN 0 .. len1 - 1
            LOOP
                n := xmldom.item(nl, j);
            
                -- get all attributes of element
                nnm := xmldom.getattributes(n);
            
                realvalue := xmldom.getnodevalue(xmldom.getfirstchild(n));
            
                IF check_header_tag_str(realvalue)
                THEN
                    l_tags_list.extend();
                    l_tags_list(l_tags_list.count) := treat_header_tag_str(realvalue);
                END IF;
            
                IF (xmldom.isnull(nnm) = FALSE)
                THEN
                    len2 := xmldom.getlength(nnm);
                
                    -- loop through attributes
                    FOR i IN 0 .. len2 - 1
                    LOOP
                        n       := xmldom.item(nnm, i);
                        attrval := xmldom.getnodevalue(n);
                    
                        IF check_header_tag_str(attrval)
                        THEN
                            l_tags_list.extend();
                            l_tags_list(l_tags_list.count) := treat_header_tag_str(attrval);
                        END IF;
                    END LOOP;
                END IF;
            END LOOP;
        
            RETURN l_tags_list;
        END get_tags;
    
    BEGIN
        -- new parser
        g_error := 'XMLPARSER.NEWPARSER';
        l_p     := xmlparser.newparser;
    
        -- set some characteristics
        g_error := 'XMLPARSER.SETVALIDATIONMODE';
        xmlparser.setvalidationmode(l_p, FALSE);
    
        -- parse input file
        g_error := 'XMLPARSER.PARSECLOB';
        xmlparser.parseclob(l_p, i_xml);
    
        -- get document
        g_error := 'XMLPARSER.GETDOCUMENT';
        l_doc   := xmlparser.getdocument(l_p);
    
        -- get tags 
        g_error := 'GET_TAGS';
        o_tags  := get_tags(l_doc);
    
        RETURN TRUE;
    EXCEPTION
    
        WHEN xmldom.index_size_err THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'Index Size error',
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        
        WHEN xmldom.domstring_size_err THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'String Size error',
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        
        WHEN xmldom.hierarchy_request_err THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'Hierarchy request error',
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        
        WHEN xmldom.wrong_document_err THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'Wrong doc error',
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        
        WHEN xmldom.invalid_character_err THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'Invalid Char error',
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        
        WHEN xmldom.no_data_allowed_err THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'Nod data allowed error',
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        
        WHEN xmldom.no_modification_allowed_err THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'No mod allowed error',
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        
        WHEN xmldom.not_found_err THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'Not found error',
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        
        WHEN xmldom.not_supported_err THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'Not supported error',
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        
        WHEN xmldom.inuse_attribute_err THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'In use attr error',
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_header_tags_from_xml;

    /**
    * Checks if a list of header tags are defined in header_tag table
    *
    * @param i_lang         Language identifier
    * @param i_tags_list    Tags list
    *
    * @param o_error        Error object
    *
    * @return               TRUE if the provided tags are in the header_tags table. FALSE otherwise or in case of a DB error.
    *
    * @author   Sérgio Santos
    * @version  2.5
    * @since    2009/03/07
    */
    FUNCTION check_header_tags
    (
        i_lang      IN language.id_language%TYPE,
        i_tags_list IN table_varchar,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(64) := 'CHECK_HEADER_TAGS';
    
        l_invalid_tags table_varchar;
    
        l_invalid_tags_error VARCHAR2(4000);
    
        l_e_invalid_tags EXCEPTION;
    BEGIN
        --get tags that are in the i_tags_list and do not exist in the header_tag table
        SELECT column_value
          BULK COLLECT
          INTO l_invalid_tags
          FROM TABLE(i_tags_list)
         WHERE column_value NOT IN (SELECT ht.internal_name
                                      FROM header_tag ht);
    
        IF l_invalid_tags.count > 0
        THEN
            l_invalid_tags_error := 'Missing tags in HEADER_TAGS table:';
            FOR i IN 1 .. l_invalid_tags.count
            LOOP
                l_invalid_tags_error := l_invalid_tags_error || ' ' || l_invalid_tags(i) || ';';
            END LOOP;
            RAISE l_e_invalid_tags;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_e_invalid_tags THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_invalid_tags_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END;

    /**
    * Checks if the tags of a given xml are defined in header_tag table
    *
    * @param i_lang         Language identifier
    * @param i_xml          XML to be checked
    *
    * @param o_error        Error object
    *
    * @return               TRUE if the provided tags are in the header_tags table. FALSE otherwise or in case of a DB error.
    *
    * @author   Sérgio Santos
    * @version  2.5
    * @since    2009/03/07
    */
    FUNCTION check_xml_header_tags
    (
        i_lang  IN language.id_language%TYPE,
        i_xml   IN LONG,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(64) := 'CHECK_XML_HEADER_TAGS';
    
        l_xml_tags_list table_varchar;
    
        l_exception EXCEPTION;
    BEGIN
        g_error := 'GET_HEADER_TAGS_FROM_XML';
        IF NOT get_header_tags_from_xml(i_lang => 1, i_xml => i_xml, o_tags => l_xml_tags_list, o_error => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'CHECK_HEADER_TAGS';
        IF NOT check_header_tags(i_lang => 1, i_tags_list => l_xml_tags_list, o_error => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END;

    /**
    * Generates the dml for a new header (inserts in the header table with the corresponding tags in the hea_header_tags table)
    * (the tags are read and validated from the xml provided)
    * (for development use only)
    *
    * @param i_lang              Language identifier
    * @param [i_id_header]       Header id - default null
    * @param i_internal_name     Header internal name
    * @param i_internal_desc     Header internal description
    * @param i_xml_format        XML used to construct the header
    * @param i_flg_screen_mode   Screen mode (Normal, Full-Screen)
    *
    * @param o_sql               The generated SQL script
    * @param o_id_header         The header id (created or updated)
    * @param o_error             Error object
    *
    * @return                    TRUE if succeeded. FALSE otherwise.
    *
    * @author   Sérgio Santos
    * @version  2.5
    * @since    2009/03/07
    */
    FUNCTION insert_into_header
    (
        i_lang            IN language.id_language%TYPE,
        i_id_header       IN header.id_header%TYPE DEFAULT NULL,
        i_internal_name   IN header.internal_name%TYPE,
        i_internal_desc   IN header.internal_desc%TYPE,
        i_xml_format      IN LONG,
        i_flg_screen_mode IN header.flg_screen_mode%TYPE,
        o_sql             OUT LONG,
        o_id_header       OUT header.id_header%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(64) := 'INSERT_INTO_HEADER';
    
        l_xml_tags_list     table_varchar;
        l_xml_tags_ids_list table_number;
    
        l_id_header  header.id_header%TYPE;
        l_sql_header LONG;
    
        l_id_header_exists BOOLEAN;
    
        l_garbage VARCHAR(1);
    
        l_exception EXCEPTION;
    BEGIN
    
        g_error := 'GET_HEADER_TAGS_FROM_XML';
        IF NOT
            get_header_tags_from_xml(i_lang => 1, i_xml => i_xml_format, o_tags => l_xml_tags_list, o_error => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'CHECK_HEADER_TAGS';
        IF NOT check_header_tags(i_lang => 1, i_tags_list => l_xml_tags_list, o_error => o_error)
        
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'GET XML TAGS IDS';
        SELECT ht.id_header_tag
          BULK COLLECT
          INTO l_xml_tags_ids_list
          FROM header_tag ht
         WHERE ht.internal_name IN (SELECT column_value
                                      FROM TABLE(l_xml_tags_list));
    
        IF i_id_header IS NULL
        THEN
            SELECT nvl(MAX(h.id_header), 0) + 1
              INTO l_id_header
              FROM header h;
        ELSE
            l_id_header := i_id_header;
        END IF;
    
        --checks if the provided header id exists
        BEGIN
            l_id_header_exists := TRUE;
        
            SELECT 'X'
              INTO l_garbage
              FROM header h
             WHERE h.id_header = i_id_header;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_header_exists := FALSE;
        END;
    
        --Begin sql construction
        l_sql_header := '';
        l_sql_header := l_sql_header || '-->header|dml' || chr(10);
        l_sql_header := l_sql_header || 'declare' || chr(10);
        l_sql_header := l_sql_header || 'l_xml long := ''' || i_xml_format || ''';' || chr(10);
        l_sql_header := l_sql_header || 'begin' || chr(10);
        --HEADER TABLE
        IF i_id_header IS NULL
           OR NOT l_id_header_exists
        THEN
            l_sql_header := l_sql_header ||
                            'insert into header (ID_HEADER, INTERNAL_NAME, INTERNAL_DESC, XML_FORMAT, FLG_SCREEN_MODE) values' ||
                            chr(10);
            l_sql_header := l_sql_header || '(' || l_id_header || ', ''' || i_internal_name || ''', ''' ||
                            i_internal_desc || ''', ' || 'l_xml' || ', ''' || i_flg_screen_mode || ''');' || chr(10);
        ELSE
            l_sql_header := l_sql_header || 'update header set internal_name = ''' || i_internal_name ||
                            ''', internal_desc = ''' || i_internal_desc ||
                            ''', xml_format = l_xml, flg_screen_mode = ''' || i_flg_screen_mode ||
                            '''where id_header = ' || l_id_header || ';' || chr(10);
        END IF;
        --END SQL construction
        l_sql_header := l_sql_header || 'end;' || chr(10);
        l_sql_header := l_sql_header || '/';
    
        --HEA_HEADER_TAG TABLE
        l_sql_header := l_sql_header || chr(10) || chr(10);
        l_sql_header := l_sql_header || '-->hea_header_tag|dml' || chr(10);
    
        l_sql_header := l_sql_header || 'delete from hea_header_tag where id_header = ' || l_id_header || ';' ||
                        chr(10) || chr(10);
    
        FOR i IN 1 .. l_xml_tags_ids_list.count
        LOOP
            l_sql_header := l_sql_header || 'insert into hea_header_tag (ID_HEADER, ID_HEADER_TAG) values'; -- || chr(10);
            l_sql_header := l_sql_header || '(' || l_id_header || ', ' || l_xml_tags_ids_list(i) || ');' || chr(10);
        END LOOP;
    
        o_id_header := l_id_header;
        o_sql       := l_sql_header;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END insert_into_header;

BEGIN
    -- Log initialization.
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);
END pk_header;
/
