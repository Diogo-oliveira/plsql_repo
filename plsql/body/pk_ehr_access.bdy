/*-- Last Change Revision: $Rev: 2054642 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2023-01-20 15:40:36 +0000 (sex, 20 jan 2023) $*/
CREATE OR REPLACE PACKAGE BODY pk_ehr_access AS
    /**
    * check if an episode is cancelled
    *
    * @param i_lang        language preference
    * @param i_prof        professional identification
    * @param i_episode     episode identification
    * @param o_return      Y/N
    * @param o_error        error message
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2010-09-30
    * @version v2.6.0.3.3
    * @author paulo teixeira
    */
    FUNCTION check_episode_cancel
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_return  OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'CHECK_EPISODE_CANCEL';
    BEGIN
    
        BEGIN
            SELECT pk_alert_constant.g_yes
              INTO o_return
              FROM episode e
              JOIN epis_info ei
                ON ei.id_episode = e.id_episode
               AND ei.id_software IN (pk_alert_constant.g_soft_ubu,
                                      pk_alert_constant.g_soft_edis,
                                      pk_alert_constant.g_soft_inpatient,
                                      pk_alert_constant.g_soft_outpatient,
                                      pk_alert_constant.g_soft_private_practice)
             WHERE e.id_episode = i_episode
               AND e.flg_status = g_epis_cancelled;
        EXCEPTION
            WHEN OTHERS THEN
                o_return := pk_alert_constant.g_no;
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            o_return := NULL;
            RETURN FALSE;
    END check_episode_cancel;
    /**
    * This package is responsible for checking access to a patient EHR. Its main entry point
    * is through the function check_ehr_access() which returns the access type.
    *
    * @since 2008-05-08
    * @author rui.baeta
    */

    /**
    * Converts nested table of type 'access_rule_table' into an associative array,
    * indexed by id_ehr_access_rule.
    *
    * @param i_table    access_rule_table
    *
    * @return access_rule_map
    *
    * @since 2008-05-16
    * @version v2.4.3
    * @author rui.baeta
    */
    FUNCTION create_map(i_table IN access_rule_table) RETURN access_rule_map IS
        l_map  access_rule_map;
        l_elem access_rule_type;
    BEGIN
        FOR i IN i_table.first .. i_table.last
        LOOP
            l_elem := i_table(i);
            l_map(l_elem.id_ehr_access_rule) := l_elem;
        END LOOP;
    
        RETURN l_map;
    END;

    /**
    * Utility internal function that gets access_rules for a professional.
    *
    * @param i_lang        language preference
    * @param i_prof        professional identification
    *
    * @return              collection of access rules.
    *
    * @since 2008-05-08
    * @version v2.4.3
    * @author rui.baeta
    */
    FUNCTION get_access_rules
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN access_rule_table IS
        l_functions   access_rule_table;
        l_profile     profile_template.id_profile_template%TYPE;
        c_access_rule pk_types.cursor_type;
    BEGIN
        -- get profile_template for this professional
        l_profile := pk_tools.get_prof_profile_template(i_prof);
    
        -- get access rules for this professional
        OPEN c_access_rule FOR
            SELECT ear.id_ehr_access_rule,
                   ear.id_rule_succeed,
                   ear.id_rule_fail,
                   ear.flg_type,
                   rules_profile.function AS profile_function,
                   rules_prof.function    AS prof_function
              FROM ehr_access_rule ear
             INNER JOIN (SELECT eaf.*, eapr.id_profile_template, eapr.flg_available
                           FROM ehr_access_function eaf
                          INNER JOIN (SELECT *
                                       FROM ehr_access_profile_rule
                                      WHERE id_profile_template = 0
                                        AND id_institution IN (0, i_prof.institution)
                                        AND NOT EXISTS (SELECT 1
                                               FROM ehr_access_profile_rule
                                              WHERE id_profile_template = l_profile
                                                AND id_institution IN (0, i_prof.institution))
                                     UNION ALL
                                     SELECT *
                                       FROM ehr_access_profile_rule
                                      WHERE id_profile_template = l_profile) eapr
                             ON eaf.id_ehr_access_function = eapr.id_ehr_access_function) rules_profile
                ON ear.id_ehr_access_rule = rules_profile.id_ehr_access_rule
               AND rules_profile.flg_available = g_yes
               AND rules_profile.id_profile_template IN (0, l_profile)
              LEFT JOIN (SELECT eaf.id_ehr_access_function,
                                eaf.id_ehr_access_rule,
                                eaf.function,
                                eapr.id_professional,
                                eapr.id_institution,
                                eapr.id_software,
                                eapr.flg_available
                           FROM ehr_access_function eaf
                          INNER JOIN ehr_access_prof_rule eapr
                             ON eaf.id_ehr_access_function = eapr.id_ehr_access_function) rules_prof
                ON ear.id_ehr_access_rule = rules_prof.id_ehr_access_rule
               AND rules_prof.flg_available = g_yes
               AND rules_prof.id_professional = i_prof.id
               AND rules_prof.id_institution IN (0, i_prof.institution)
               AND rules_prof.id_software IN (0, i_prof.software)
             ORDER BY ear.id_ehr_access_rule;
    
        FETCH c_access_rule BULK COLLECT
            INTO l_functions;
        CLOSE c_access_rule;
    
        RETURN l_functions;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_access_rules;

    /**
    * Executes a specified rule. All rules must have the same interface, i.e., must declare the same arguments
    * even if they do not use them.
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to
    * @param i_flg_episode_reopen  flag that tells if an episode is to be reopened (used in EDIS) (Y - episode will be reopened
    *                                                                                              N - episode will NOT be reopened - default)
    * @param i_function            the access rule function to execute
    *
    * @param o_access_type access type to this patient EHR (B - Break the Glass
    *                                                       F - Free Access
    *                                                       N - Not allowed)
    * @param o_error       error message
    *
    * @return              true if access is granted (F - Free Access or B - Break the Glass), false otherwise
    *
    * @since 2008-05-12
    * @version v2.4.3
    * @author rui.baeta
    */
    FUNCTION execute_access_rule
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_episode_reopen IN VARCHAR2,
        i_id_episode         IN episode.id_episode%TYPE DEFAULT NULL,
        i_function           IN access_rule_type
    ) RETURN BOOLEAN IS
        l_plsql    VARCHAR2(2000) := '';
        l_function VARCHAR2(2000); -- function to execute
        o_result   NUMBER(6);
    BEGIN
        IF i_function.prof_function IS NOT NULL
        THEN
            -- maximum priority to function defined in ehr_access_prof_rule
            l_function := i_function.prof_function;
        ELSIF i_function.profile_function IS NOT NULL
        THEN
            -- lower priority to function defined in ehr_access_profile_rule
            l_function := i_function.profile_function;
        ELSE
            -- no function implemented!
            raise_application_error(g_access_no_rules_error_id, g_access_no_rules_error_msg);
        END IF;
    
        -- example:
        -- l_function := 'pk_ehr_access_rules.ckeck_ongoing_episode(:i_lang, :i_prof, :i_id_patient, :i_flg_episode_reopen, :i_id_episode)';
    
        l_plsql := 'begin';
        l_plsql := l_plsql || '    if ' || l_function || ' then';
        l_plsql := l_plsql || '        :o_result := 1;';
        l_plsql := l_plsql || '    else';
        l_plsql := l_plsql || '        :o_result := 0;';
        l_plsql := l_plsql || '    end if;';
        l_plsql := l_plsql || 'end;';
    
        pk_alertlog.log_info('executing rule... [prof ' || i_prof.id || ', ' || i_prof.institution || ', ' ||
                             i_prof.software || '] [patient ' || i_id_patient || '] [' || l_function || ']');
    
        g_error := l_plsql;
        EXECUTE IMMEDIATE l_plsql
            USING IN i_lang, IN i_prof, IN i_id_patient, IN i_flg_episode_reopen, IN i_id_episode, OUT o_result;
    
        pk_alertlog.log_info('execution result: [prof ' || i_prof.id || ', ' || i_prof.institution || ', ' ||
                             i_prof.software || '] [patient ' || i_id_patient || '] [' || l_function || '] [' ||
                             o_result || ']');
        RETURN(o_result = 1);
    
    END execute_access_rule;

    /**
    * Checks if this professional has access to this patient EHR.
    *
    * @param i_lang        language preference
    * @param i_prof        professional identification
    * @param i_id_patient  patient id that this professional wants to access to.
    *
    * @param o_access_type access type to this patient EHR (B - Break the Glass
    *                                                       F - Free Access
    *                                                       N - Not allowed)
    * @i_id_episode        episode id
    *
    * @param o_error       error message
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2008-05-08
    * @version v2.4.3
    * @author rui.baeta
    */
    FUNCTION check_ehr_access
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        i_id_episode  IN episode.id_episode%TYPE DEFAULT NULL,
        o_access_type OUT NOCOPY VARCHAR2,
        o_error       OUT NOCOPY VARCHAR2
    ) RETURN BOOLEAN IS
        l_error_out t_error_out;
    BEGIN
        --RETURN check_ehr_access(i_lang, i_prof, i_id_patient, 'N', o_access_type, o_error);
    
        RETURN check_ehr_access(i_lang               => i_lang,
                                i_prof               => i_prof,
                                i_id_patient         => i_id_patient,
                                i_flg_episode_reopen => 'N',
                                i_id_episode         => i_id_episode,
                                o_access_type        => o_access_type,
                                o_error              => l_error_out);
    
    END check_ehr_access;

    /**
    * Checks if this professional has access to this patient EHR.
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_flg_episode_reopen  flag that tells if an episode is to be reopened (used in EDIS) (Y - episode will be reopened
    *                                                                                              N - episode will NOT be reopened - default)
    *
    * @param o_access_type access type to this patient EHR (B - Break the Glass
    *                                                       F - Free Access
    *                                                       N - Not allowed)
    * @i_id_episode        episode id
    *
    * @param o_error       error message
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2008-05-08
    * @version v2.4.3
    * @author rui.baeta
    */
    FUNCTION check_ehr_access
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_episode_reopen IN VARCHAR2,
        i_id_episode         IN episode.id_episode%TYPE DEFAULT NULL,
        o_access_type        OUT NOCOPY VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_rule                ehr_access_rule.id_ehr_access_rule%TYPE;
        l_function               access_rule_type;
        l_function_list          access_rule_table;
        l_function_map           access_rule_map;
        l_function_eval          BOOLEAN := FALSE;
        l_has_ehr_manager_access ehr_access_category.flg_has_ehr_access%TYPE;
        l_justify                sys_config.value%TYPE;
    
        l_prof_cat    category.flg_type%TYPE;
        l_prof_cat_id category.id_category%TYPE;
    
        l_dummy VARCHAR2(1 CHAR);
    BEGIN
        --get initial data
        l_prof_cat    := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
        l_prof_cat_id := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
    
        --check if the professional must justify the ehr access
        l_justify := pk_sysconfig.get_config('EHR_ACCESS_JUSTIFY', i_prof);
    
        --check if the professional has access to the EHR manager
        g_error := 'Professional category not parameterized in ehr_access_category. ' || pk_utils.to_string(i_prof);
        SELECT flg_has_ehr_access
          INTO l_has_ehr_manager_access
          FROM (SELECT eay.flg_has_ehr_access
                  FROM ehr_access_category eay
                 WHERE eay.id_category = l_prof_cat_id
                   AND eay.id_institution IN (0, i_prof.institution)
                   AND eay.id_software IN (0, i_prof.software)
                 ORDER BY eay.id_software DESC, eay.id_institution DESC)
         WHERE rownum = 1;
    
        -- if the professional doesnt have permission to view the ehr access manager we stop here
        IF l_has_ehr_manager_access = g_no
           OR l_justify = g_no
        THEN
            o_access_type := 'F';
            RETURN TRUE;
        END IF;
    
        -- get list of rules that apply to this professional
        g_error         := 'getting rules to execute';
        l_function_list := get_access_rules(i_lang, i_prof);
    
        IF l_function_list.count = 0
        THEN
            raise_application_error(g_access_no_rules_error_id, g_access_no_rules_error_msg);
        END IF;
    
        -- create hash-map based on function list (indexed by id_ehr_access_rule)
        l_function_map := create_map(l_function_list);
    
        -- get first rule to execute
        l_id_rule := pk_sysconfig.get_config('ID_EHR_ACCESS_FIRST_RULE', i_prof);
        IF l_id_rule IS NULL
        THEN
            raise_application_error(g_access_no_frule_error_id, g_access_no_frule_error_msg);
        END IF;
    
        --check if exists in profile configuration
        BEGIN
            SELECT DISTINCT pk_alert_constant.get_available
              INTO l_dummy
              FROM ehr_access_profile_rule e
             WHERE e.id_ehr_access_function IN (SELECT ef.id_ehr_access_function
                                                  FROM ehr_access_function ef
                                                 WHERE ef.id_ehr_access_rule = l_id_rule)
               AND e.id_profile_template IN (0, pk_prof_utils.get_prof_profile_template(i_prof))
               AND e.id_institution IN (0, i_prof.institution)
               AND e.id_software IN (0, i_prof.software)
               AND e.flg_available = pk_alert_constant.g_yes;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_rule := 1;
        END;
    
        l_function := l_function_map(l_id_rule);
    
        -- iterate over rules and execute them!
        LOOP
            l_function_eval := execute_access_rule(i_lang,
                                                   i_prof,
                                                   i_id_patient,
                                                   i_flg_episode_reopen,
                                                   i_id_episode,
                                                   l_function);
        
            -- if rule succeds -> goto rule_succeed; if succeed is null -> exit;
            -- if rule fails   -> goto rule_fail;    if fail    is null -> exit;
            IF l_function_eval
            THEN
                IF l_function.id_rule_succeed IS NULL
                THEN
                    EXIT;
                ELSE
                    l_function := l_function_map(l_function.id_rule_succeed);
                END IF;
            ELSE
                IF l_function.id_rule_fail IS NULL
                THEN
                    EXIT;
                ELSE
                    l_function := l_function_map(l_function.id_rule_fail);
                END IF;
            END IF;
        
        END LOOP;
    
        -- check execution result and access type (free access; break the glass access; no access)
        IF NOT l_function_eval
        THEN
            -- all rules evaluate to false => no access!!!
            o_access_type := g_rule_access_not_allowed;
        ELSE
            -- at least one rule evaluate to true, let's return access type
            o_access_type := l_function.flg_type;
        END IF;
    
        --Special conditions:
        -- On a Signed off access, the Register has free access.
        IF o_access_type = pk_ehr_access.g_rule_access_sign_off
           AND l_prof_cat = pk_alert_constant.g_cat_type_registrar
        THEN
            o_access_type := pk_ehr_access.g_rule_free_access;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_EHR_ACCESS', 'CHECK_EHR_ACCESS');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- return failure   
                RETURN FALSE;
            END;
    END check_ehr_access;

    /**
    * Checks if this professional has to justify an EHR Access.
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient identifier
    * @param i_id_episode          episode id that this professional wants to access to.
    * @param i_id_schedule         schedule id that this professional wants to access to.
    * @param o_error               error message
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2008-05-22
    * @version v2.4.3
    * @author Sérgio Santos
    */
    FUNCTION check_log_need
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_log_need    OUT NOCOPY VARCHAR2,
        o_area        OUT NOCOPY ehr_access_context.id_ehr_access_context%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof_epis_type epis_type.id_epis_type%TYPE := pk_sysconfig.get_config('EPIS_TYPE', i_prof);
        l_id_epis_type   epis_type.id_epis_type%TYPE;
        l_area           VARCHAR2(1);
    
        --Professional category
        l_prof_category    category.id_category%TYPE;
        l_prof_is_clinical category.flg_clinical%TYPE;
        l_handoff_type     sys_config.value%TYPE;
    
        l_log_need_epis VARCHAR(1);
        l_log_need_sch  VARCHAR(1);
    
        l_has_ehr_manager_access VARCHAR2(1);
    
        --EHR ACCESS TYPE
        l_access_type VARCHAR2(1);
    
        --Justify Access
        l_justify VARCHAR2(1);
    
        --Go to old area
        l_to_old_area VARCHAR(1);
    
        --Episode sign-off
        l_epis_signed_off VARCHAR(1);
    
        --Episode state (Normal, Sched, EHR Event)
        l_epis_ehr_state episode.flg_ehr%TYPE;
    
        CURSOR c_epis IS
            SELECT g_yes
              FROM episode e
              JOIN epis_info ei
                ON (e.id_episode = ei.id_episode)
             WHERE e.id_episode = i_id_episode
                  --The professional must justify the access to an episode if:
               AND ((pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                      i_prof,
                                                                                      ei.id_episode,
                                                                                      pk_prof_utils.get_category(i_lang,
                                                                                                                 i_prof),
                                                                                      l_handoff_type),
                                                  i_prof.id) = -1 AND l_prof_epis_type <> e.id_epis_type) --i do not have direct access to the patient (its not mine and its not from my epis_type)
                   OR e.id_institution <> i_prof.institution -- is not from my institution
                   OR e.flg_status IN (g_epis_inactive, g_epis_cancelled) -- the episode is inactive or cancelled
                   OR e.flg_ehr IN (g_flg_ehr_ehr, g_flg_ehr_scheduled) -- is an ehr event or is an schedule preparation
                   );
    
        CURSOR c_sch IS
            SELECT g_yes
              FROM schedule s
              JOIN sch_group sg
                ON (s.id_schedule = sg.id_schedule)
              JOIN schedule_outp so
                ON (s.id_schedule = so.id_schedule)
              JOIN sch_prof_outp spo
                ON (spo.id_schedule_outp = so.id_schedule_outp)
             WHERE s.id_schedule = i_id_schedule
               AND (spo.id_professional <> i_prof.id OR
                   i_prof.id NOT IN (SELECT id_professional
                                        FROM sch_resource sr
                                       WHERE sr.id_schedule = s.id_schedule))
               AND s.flg_status != pk_schedule.g_sched_status_cache -- agendamentos temporários (SCH 3.0)
               AND s.id_schedule NOT IN (SELECT ei.id_schedule
                                           FROM epis_info ei
                                           JOIN episode e
                                             ON (ei.id_episode = e.id_episode)
                                            AND ei.id_schedule = i_id_schedule
                                            AND e.flg_ehr IN (g_flg_ehr_normal, g_flg_ehr_ehr));
    
        --    Access area check   --
    
        -- check if this is a previous episode
        CURSOR c_previous_check IS
            SELECT g_access_previous
              FROM episode e
             WHERE e.id_episode = i_id_episode
               AND e.flg_status IN (g_epis_inactive, g_epis_pending)
               AND e.flg_ehr = g_flg_ehr_normal
               AND e.id_epis_type <> pk_act_therap_constant.g_activ_therap_epis_type;
    
        CURSOR c_previous_check_at IS
            SELECT g_access_previous_at
              FROM episode e
             WHERE e.id_episode = i_id_episode
               AND e.flg_status IN (g_epis_inactive, g_epis_pending)
               AND e.flg_ehr = g_flg_ehr_normal
               AND e.id_epis_type = pk_act_therap_constant.g_activ_therap_epis_type;
    
        -- check if this is a ongoing episode
        CURSOR c_ongoing_check IS
            SELECT g_access_ongoing
              FROM episode e
             WHERE e.id_episode = i_id_episode
               AND e.flg_status IN (g_epis_active)
               AND e.flg_ehr = g_flg_ehr_normal;
    
        --check if this is a scheduled episode
        CURSOR c_scheduled_check IS
            SELECT g_access_scheduled
              FROM schedule s
             WHERE s.id_schedule = decode(i_id_episode, NULL, i_id_schedule, NULL)
               AND s.flg_status IN ('A', 'R', 'P')
               AND s.flg_status != pk_schedule.g_sched_status_cache -- agendamentos temporários (SCH 3.0)
               AND (i_id_episode IS NULL OR
                   s.id_schedule NOT IN (SELECT ei.id_schedule
                                            FROM epis_info ei
                                            JOIN episode e
                                              ON (ei.id_episode = e.id_episode)
                                             AND ei.id_schedule = decode(i_id_episode, NULL, i_id_schedule, NULL)
                                             AND e.flg_ehr = g_flg_ehr_scheduled))
            UNION
            SELECT g_access_scheduled
              FROM episode e
             WHERE e.id_episode = i_id_episode
               AND e.flg_ehr = g_flg_ehr_scheduled;
    
        --check if this is an EHR event
        CURSOR c_ehr_check IS
            SELECT g_access_ehr
              FROM episode e
             WHERE e.id_episode = i_id_episode
               AND i_id_episode IS NOT NULL
               AND e.flg_ehr = g_flg_ehr_ehr;
    
        --check if this is Cancelled episode
        CURSOR c_canceled_episode IS
            SELECT g_access_cancelled
              FROM episode e
             WHERE e.id_episode = i_id_episode
               AND i_id_episode IS NOT NULL
               AND e.flg_status = g_epis_cancelled;
    
    BEGIN
        g_error := 'GET HANDOFF TYPE';
        alertlog.pk_alertlog.log_info(text => g_error);
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
    
        SELECT cat.id_category
          INTO l_prof_category
          FROM category cat, professional prf, prof_cat prc
         WHERE prf.id_professional = i_prof.id
           AND prc.id_professional = prf.id_professional
           AND prc.id_institution = i_prof.institution
           AND cat.id_category = prc.id_category;
        -- 
        l_justify := pk_sysconfig.get_config('EHR_ACCESS_JUSTIFY', i_prof);
    
        l_to_old_area := pk_sysconfig.get_config('EHR_ACCESS_SC_OLD_AREA', i_prof);
    
        -- if we dont have an episode or a schedule, we stop here (referral)
        g_error := 'CHECK EPIS AND SCHED REFERRAL';
        IF i_id_episode IS NULL
           AND i_id_schedule IS NULL
           AND i_prof.software = pk_ehr_access.g_software_referral
        THEN
            o_log_need := 'N';
            o_area     := NULL;
            RETURN TRUE;
        END IF;
    
        -- if we dont have an episode or a schedule, we stop here
        g_error := 'CHECK EPIS AND SCHED';
        IF i_id_episode IS NULL
           AND i_id_schedule IS NULL
        THEN
            o_log_need := 'Y';
            o_area     := NULL;
            RETURN TRUE;
        END IF;
    
        --If we should go to the old area, no justfy is needed
        IF l_to_old_area = pk_alert_constant.g_yes
           AND i_id_episode IS NULL
        THEN
            o_log_need := 'N';
            o_area     := NULL;
            RETURN TRUE;
        END IF;
    
        --If the professional is not clinical he will not need to justify the access because he souldn´t see it
        SELECT c.flg_clinical
          INTO l_prof_is_clinical
          FROM category c
         WHERE c.id_category = l_prof_category;
    
        IF l_prof_is_clinical = pk_alert_constant.g_no
        THEN
            o_log_need := 'N';
            o_area     := NULL;
            RETURN TRUE;
        END IF;
    
        IF i_id_episode IS NOT NULL
           AND i_prof.software = pk_alert_constant.g_soft_home_care
        THEN
            SELECT id_epis_type
              INTO l_id_epis_type
              FROM episode
             WHERE id_episode = i_id_episode;
            IF l_id_epis_type = pk_hhc_constant.k_hhc_epis_type
            THEN
                o_log_need := 'N';
                o_area     := NULL;
                RETURN TRUE;
            
            END IF;
        END IF;
        --check if the professional has access to the EHR manager
        g_error := 'Professional category not parameterized in ehr_access_category';
        SELECT flg_has_ehr_access
          INTO l_has_ehr_manager_access
          FROM (SELECT eay.flg_has_ehr_access
                  FROM ehr_access_category eay
                 WHERE eay.id_category = (SELECT pc.id_category
                                            FROM prof_cat pc
                                           WHERE pc.id_professional = i_prof.id
                                             AND pc.id_institution = i_prof.institution)
                   AND eay.id_institution IN (0, i_prof.institution)
                   AND eay.id_software IN (0, i_prof.software)
                 ORDER BY eay.id_software DESC, eay.id_institution DESC)
         WHERE rownum = 1;
    
        -- if the professional doesnt have permission to view the ehr access manager we stop here
        g_error := 'Checking access justify';
        IF l_has_ehr_manager_access = g_no
        THEN
            o_log_need := 'N';
            o_area     := NULL;
            RETURN TRUE;
        END IF;
    
        g_error := 'CHECK EHR ACCESS';
        IF NOT check_ehr_access(i_lang, i_prof, i_id_patient, 'N', i_id_episode, l_access_type, o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        --get the ehr episode state
        BEGIN
            SELECT e.flg_ehr
              INTO l_epis_ehr_state
              FROM episode e
             WHERE e.id_episode = i_id_episode;
        EXCEPTION
            WHEN no_data_found THEN
                l_epis_ehr_state := NULL;
        END;
    
        IF i_id_episode IS NOT NULL -- Run the following code only if in the context of an episode
        THEN
            g_error := 'OPEN c_epis';
            OPEN c_epis;
            FETCH c_epis
                INTO l_log_need_epis;
            CLOSE c_epis;
        
            g_error := 'OPEN c_sch';
            OPEN c_sch;
            FETCH c_sch
                INTO l_log_need_sch;
            CLOSE c_sch;
        
            IF l_log_need_epis = g_yes
               OR l_log_need_sch = g_yes
            THEN
                o_log_need := g_yes;
            ELSE
                o_log_need := g_no;
            END IF;
        
            --    Access area check   --
        
            g_error := 'OPEN c_previous_check';
            OPEN c_previous_check;
            FETCH c_previous_check
                INTO l_area;
            CLOSE c_previous_check;
        
            g_error := 'OPEN c_previous_check_at';
            OPEN c_previous_check_at;
            FETCH c_previous_check_at
                INTO l_area;
            CLOSE c_previous_check_at;
        
            g_error := 'OPEN c_ongoing_check';
            OPEN c_ongoing_check;
            FETCH c_ongoing_check
                INTO l_area;
            CLOSE c_ongoing_check;
        
            g_error := 'OPEN c_scheduled_check';
            OPEN c_scheduled_check;
            FETCH c_scheduled_check
                INTO l_area;
            CLOSE c_scheduled_check;
        
            g_error := 'OPEN c_ehr_check';
            OPEN c_ehr_check;
            FETCH c_ehr_check
                INTO l_area;
            CLOSE c_ehr_check;
        
            g_error := 'OPEN c_cancelled_episode';
            OPEN c_canceled_episode;
            FETCH c_canceled_episode
                INTO l_area;
            CLOSE c_canceled_episode;
        
            -- SIGN OFF SPECIAL CASE
            g_error := 'PK_SIGN_OFF.GET_EPIS_SIGN_OFF_STATE';
            IF NOT pk_sign_off.get_epis_sign_off_state(i_lang     => i_lang,
                                                       i_prof     => i_prof,
                                                       i_episode  => i_id_episode,
                                                       o_sign_off => l_epis_signed_off,
                                                       o_error    => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            IF l_epis_signed_off = pk_alert_constant.g_yes
            THEN
                l_area := g_access_sign_off;
            END IF;
        
        ELSE
            -- If it doesn't have an episode, it's a scheduled episode for sure.
            o_log_need := g_yes;
            l_area     := g_access_scheduled;
        END IF;
    
        IF l_area IS NOT NULL
        THEN
            BEGIN
                SELECT eac.id_ehr_access_context
                  INTO o_area
                  FROM ehr_access_context eac
                 WHERE eac.flg_type = l_area
                   AND (eac.flg_context = g_flg_context_access OR eac.flg_type = pk_ehr_access.g_access_sign_off)
                   AND eac.flg_available = g_yes
                   AND eac.id_ehr_access_context =
                       (SELECT MAX(e2.id_ehr_access_context)
                          FROM ehr_access_context_soft e2
                          JOIN ehr_access_context e1
                            ON (e1.id_ehr_access_context = e2.id_ehr_access_context)
                         WHERE e2.id_software IN (0, i_prof.software)
                           AND e1.flg_type = eac.flg_type
                           AND (e1.flg_context = g_flg_context_access OR e1.flg_type = pk_ehr_access.g_access_sign_off)
                           AND e1.flg_available = g_yes
                         GROUP BY e1.flg_type);
            EXCEPTION
                WHEN no_data_found THEN
                    o_area := NULL;
            END;
        END IF;
    
        IF (l_justify = pk_alert_constant.g_no OR l_justify IS NULL)
           AND (i_id_episode IS NOT NULL AND l_epis_ehr_state <> pk_ehr_access.g_access_scheduled)
        THEN
            o_log_need := 'N';
            RETURN TRUE;
        END IF;
    
        IF l_access_type = g_rule_break_the_glass_access
        THEN
            o_log_need := g_yes;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_EHR_ACCESS', 'CHECK_LOG_NEED');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- undo changes
                pk_utils.undo_changes;
                -- return failure   
                RETURN FALSE;
            END;
    END check_log_need;

    /**
    * Gets access reasons for a professional
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_id_access_area      area context for the reasons
    * @param i_id_episode          episode identifier
    * @param i_id_schedule         schedule identifier
    * @param i_id_dep_clin_serv    dep_clin_serv identifier
    *
    * @param o_access_reasons      cursor containing access reasons for this professional
    * @param o_access_context      cursor containing the labels in order to give a context to the access reasons screen
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2008-05-21
    * @version v2.4.3
    * @author Sérgio Santos
    */
    FUNCTION get_access_reasons
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_access_area   IN ehr_access_reason.id_ehr_access_context%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_access_reasons   OUT pk_types.cursor_type,
        o_access_context   OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_type           ehr_access_context.flg_type%TYPE;
        l_access_type        sys_message.desc_message%TYPE;
        l_id_epis_type       epis_type.id_epis_type%TYPE;
        l_prof_profile_templ profile_template.id_profile_template%TYPE;
        l_flg_event          VARCHAR2(1) := 'N';
        l_visit_name         VARCHAR2(4000);
        l_flg_sign_off       VARCHAR(1);
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        l_prof_profile_templ := pk_tools.get_prof_profile_template(i_prof);
    
        IF NOT pk_sign_off.get_epis_sign_off_state(i_lang     => i_lang,
                                                   i_prof     => i_prof,
                                                   i_episode  => i_id_episode,
                                                   o_sign_off => l_flg_sign_off,
                                                   o_error    => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        BEGIN
            OPEN o_access_reasons FOR
                SELECT ear.id_ehr_access_reason id_reason,
                       pk_translation.get_translation(i_lang, ear.code_ehr_access_reason) reason_desc,
                       ear.flg_default flg_default,
                       ear.flg_notes_mandatory notes_mandatory
                  FROM ehr_access_reason ear
                  JOIN ehr_access_context eac
                    ON ear.id_ehr_access_context = eac.id_ehr_access_context
                 WHERE ear.id_ehr_access_context = i_id_access_area
                   AND (eac.flg_context = g_flg_context_access OR eac.flg_type = pk_ehr_access.g_access_sign_off)
                   AND eac.flg_available = g_yes
                   AND ear.flg_available = g_yes
                   AND ear.flg_visible = g_yes
                   AND ear.id_institution IN (i_prof.institution, 0)
                   AND ear.id_software IN (i_prof.software, 0)
                   AND ear.id_profile_template IN (l_prof_profile_templ, 0)
                 ORDER BY ear.rank, reason_desc;
        
            SELECT eac.flg_type
              INTO l_flg_type
              FROM ehr_access_context eac
             WHERE eac.id_ehr_access_context = i_id_access_area
               AND (eac.flg_context = g_flg_context_access OR eac.flg_type = pk_ehr_access.g_access_sign_off)
               AND eac.flg_available = g_yes;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        -- Resolve access type
        IF l_flg_type = g_access_ongoing
        THEN
            l_access_type := pk_message.get_message(i_lang, i_prof, 'EHR_ACCESS_T035');
        ELSIF l_flg_type IN (g_access_previous, g_access_previous_at)
        THEN
            l_access_type := pk_message.get_message(i_lang, i_prof, 'EHR_ACCESS_T032');
        ELSIF l_flg_type = g_access_ehr
        THEN
            IF i_id_dep_clin_serv IS NULL
            THEN
                l_access_type := pk_message.get_message(i_lang, i_prof, 'EHR_ACCESS_T041');
            ELSE
                l_access_type := pk_message.get_message(i_lang, i_prof, 'EHR_ACCESS_T038');
            END IF;
        ELSIF l_flg_type = g_access_scheduled
        THEN
            l_access_type := pk_message.get_message(i_lang, i_prof, 'EHR_ACCESS_T036');
        ELSIF l_flg_type = g_access_cancelled
        THEN
            l_access_type := pk_message.get_message(i_lang, i_prof, 'EHR_ACCESS_T042');
        ELSIF l_flg_type = g_access_sign_off
        THEN
            l_access_type := pk_message.get_message(i_lang, i_prof, 'EHR_ACCESS_T051');
        END IF;
    
        -- Resolve visit / event type
        IF i_id_episode IS NOT NULL
        THEN
            SELECT e.id_epis_type
              INTO l_id_epis_type
              FROM episode e
             WHERE e.id_episode = i_id_episode;
        ELSIF i_id_schedule IS NOT NULL
        THEN
            SELECT so.id_epis_type
              INTO l_id_epis_type
              FROM schedule_outp so
             WHERE so.id_schedule = i_id_schedule;
        ELSE
            l_id_epis_type := pk_sysconfig.get_config('EPIS_TYPE', i_prof);
            l_flg_event    := 'Y';
        END IF;
    
        l_visit_name := pk_ehr_common.get_visit_name_by_epis(i_lang, i_prof, l_id_epis_type, l_flg_event);
    
        g_error := 'OPEN O_ACCESS_CONTEXT';
        OPEN o_access_context FOR
            SELECT l_access_type AS access_type,
                   pk_string_utils.concat_if_exists(l_visit_name,
                                                    pk_ehr_common.get_visit_type_by_epis(i_lang,
                                                                                         i_prof,
                                                                                         e.id_episode,
                                                                                         l_id_epis_type,
                                                                                         ', '),
                                                    ' - ') AS visit_type,
                   pk_string_utils.concat_if_exists(pk_date_utils.date_char_tsz(i_lang,
                                                                                e.dt_begin_tstz,
                                                                                i_prof.institution,
                                                                                i_prof.software),
                                                    pk_prof_utils.get_name_signature(i_lang, i_prof, ei.id_professional),
                                                    ' / ') AS visit_by
              FROM episode e, epis_info ei
             WHERE i_id_episode IS NOT NULL
               AND e.id_episode = i_id_episode
               AND ei.id_episode = e.id_episode
               AND l_flg_sign_off = pk_alert_constant.g_no
            UNION ALL -- Sign off
            SELECT l_access_type AS access_type,
                   pk_string_utils.concat_if_exists(l_visit_name,
                                                    pk_ehr_common.get_visit_type_by_epis(i_lang,
                                                                                         i_prof,
                                                                                         eso.id_episode,
                                                                                         l_id_epis_type,
                                                                                         ', '),
                                                    ' - ') AS visit_type,
                   pk_message.get_message(i_lang, i_prof, 'EHR_ACCESS_T050') || ': ' ||
                   pk_string_utils.concat_if_exists(pk_date_utils.date_char_tsz(i_lang,
                                                                                eso.dt_event,
                                                                                i_prof.institution,
                                                                                i_prof.software),
                                                    pk_prof_utils.get_name_signature(i_lang,
                                                                                     i_prof,
                                                                                     eso.id_professional_event),
                                                    ' / ') AS visit_by
              FROM (SELECT eso.id_episode,
                           eso.dt_event,
                           eso.id_professional_event,
                           row_number() over(PARTITION BY eso.id_episode ORDER BY eso.dt_event DESC) rn
                      FROM epis_sign_off eso
                     WHERE i_id_episode IS NOT NULL
                       AND eso.id_episode = i_id_episode
                       AND l_flg_sign_off = pk_alert_constant.g_yes) eso
             WHERE rn = 1
            UNION ALL
            SELECT l_access_type AS access_type,
                   pk_string_utils.concat_if_exists(l_visit_name,
                                                    pk_string_utils.concat_if_exists(pk_translation.get_translation(i_lang,
                                                                                                                    'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                                                                                    dcs.id_clinical_service),
                                                                                     pk_sysdomain.get_domain('SCHEDULE_OUTP.FLG_TYPE',
                                                                                                             so.flg_type,
                                                                                                             i_lang),
                                                                                     ', '),
                                                    ' - ') AS visit_type,
                   pk_string_utils.concat_if_exists(pk_date_utils.date_char_tsz(i_lang,
                                                                                s.dt_begin_tstz,
                                                                                i_prof.institution,
                                                                                i_prof.software),
                                                    pk_prof_utils.get_name_signature(i_lang, i_prof, spo.id_professional),
                                                    ' / ') AS visit_by
              FROM schedule s, schedule_outp so, sch_prof_outp spo, dep_clin_serv dcs
             WHERE i_id_episode IS NULL
               AND i_id_schedule IS NOT NULL
               AND so.id_schedule = i_id_schedule
               AND so.id_schedule_outp = spo.id_schedule_outp(+)
               AND so.id_schedule = s.id_schedule
               AND s.id_dcs_requested = dcs.id_dep_clin_serv
               AND s.flg_status != pk_schedule.g_sched_status_cache -- agendamentos temporários (SCH 3.0)
            UNION ALL
            SELECT l_access_type AS access_type,
                   pk_string_utils.concat_if_exists(l_visit_name,
                                                    pk_translation.get_translation(i_lang,
                                                                                   'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                                                   dcs.id_clinical_service),
                                                    ' - ') AS visit_type,
                   pk_string_utils.concat_if_exists(pk_date_utils.date_char_tsz(i_lang,
                                                                                g_sysdate_tstz,
                                                                                i_prof.institution,
                                                                                i_prof.software),
                                                    pk_prof_utils.get_name_signature(i_lang, i_prof, i_prof.id),
                                                    ' / ') AS visit_by
              FROM dep_clin_serv dcs
             WHERE i_id_dep_clin_serv IS NOT NULL
               AND dcs.id_dep_clin_serv = i_id_dep_clin_serv;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EHR_ACCESS',
                                              'GET_ACCESS_REASONS',
                                              o_error);
            pk_types.open_my_cursor(o_access_reasons);
            pk_types.open_my_cursor(o_access_context);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_access_reasons;

    /**
    * Gets clinical services for a professional
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    *
    * @param o_clin_services       cursor containing clinical services for this professional
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2008-05-13
    * @version v2.4.3
    * @author rui.baeta
    */
    FUNCTION get_clinical_services
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_flg_context   IN ehr_access_context.flg_context%TYPE,
        o_clin_services OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_sch_event sch_event.id_sch_event%TYPE;
    
    BEGIN
        l_id_sch_event := get_sched_event(i_lang, i_prof, i_flg_context);
    
        g_error := 'o_clin_services';
        OPEN o_clin_services FOR
            SELECT *
              FROM (SELECT DISTINCT t1.id_clinical_service,
                                    t1.id_department,
                                    t1.id_dep_clin_serv,
                                    pk_translation.get_translation(i_lang, t1.code_clinical_service) ||
                                    decode(t2.counter,
                                           1,
                                           '',
                                           ' (' || pk_translation.get_translation(i_lang, t1.code_department) || ')') desc_clinical_service,
                                    pk_alert_constant.g_yes has_permission
                      FROM (SELECT cs.id_clinical_service,
                                   dcs.id_department,
                                   dcs.id_dep_clin_serv,
                                   cs.code_clinical_service,
                                   d.code_department
                              FROM clinical_service cs
                             INNER JOIN dep_clin_serv dcs
                                ON cs.id_clinical_service = dcs.id_clinical_service
                             INNER JOIN department d
                                ON dcs.id_department = d.id_department
                              LEFT JOIN prof_dep_clin_serv pdcs
                                ON dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
                             INNER JOIN software_dept sd
                                ON sd.id_dept = d.id_dept
                             WHERE pdcs.id_professional = i_prof.id
                               AND d.id_institution = i_prof.institution
                               AND sd.id_software = i_prof.software
                               AND cs.flg_available = pk_alert_constant.g_yes
                               AND dcs.flg_available = pk_alert_constant.g_yes) t1,
                           (SELECT COUNT(1) counter, cs.id_clinical_service
                              FROM clinical_service cs
                             INNER JOIN dep_clin_serv dcs
                                ON cs.id_clinical_service = dcs.id_clinical_service
                             INNER JOIN department d
                                ON dcs.id_department = d.id_department
                              LEFT JOIN prof_dep_clin_serv pdcs
                                ON dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
                             INNER JOIN software_dept sd
                                ON sd.id_dept = d.id_dept
                             WHERE pdcs.id_professional = i_prof.id
                               AND d.id_institution = i_prof.institution
                               AND sd.id_software = i_prof.software
                               AND cs.flg_available = pk_alert_constant.g_yes
                               AND dcs.flg_available = pk_alert_constant.g_yes
                             GROUP BY cs.id_clinical_service) t2
                     WHERE t1.id_clinical_service = t2.id_clinical_service)
             ORDER BY desc_clinical_service;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_EHR_ACCESS',
                                   'GET_CLINICAL_SERVICES');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                --open cursor
                pk_types.open_my_cursor(o_clin_services);
                -- return failure   
                RETURN FALSE;
            END;
    END get_clinical_services;

    /**
    * Gets the id professional to show in the Professional field
    *
    * @param id_schedule_outp        
    * @param i_episode            
    *
    * @return             id_professional
    *
    * @since 2010-FEB-10
    * @version v2.5
    * @author Sérgio Santos
    */
    FUNCTION get_epis_sch_prof
    (
        i_id_schedule_outp IN schedule_outp.id_schedule_outp%TYPE,
        i_id_episode       IN episode.id_episode%TYPE
    ) RETURN professional.id_professional%TYPE IS
        l_id_professional professional.id_professional%TYPE;
    BEGIN
        BEGIN
            SELECT t.id_professional
              INTO l_id_professional
              FROM (SELECT decode(e.id_epis_type,
                                  pk_visit.g_epis_type_nurse,
                                  ei.id_first_nurse_resp,
                                  pk_visit.g_epis_type_nurse_pp,
                                  ei.id_first_nurse_resp,
                                  pk_visit.g_epis_type_nurse_outp,
                                  ei.id_first_nurse_resp,
                                  ei.id_professional) id_professional,
                           10 rank
                      FROM episode e
                      JOIN epis_info ei
                        ON ei.id_episode = e.id_episode
                     WHERE ei.id_episode = i_id_episode
                    UNION
                    SELECT spo.id_professional, 20 rank
                      FROM sch_prof_outp spo
                     WHERE spo.id_schedule_outp = i_id_schedule_outp
                     ORDER BY rank) t
             WHERE t.id_professional IS NOT NULL
               AND rownum <= 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_professional := NULL;
        END;
    
        RETURN l_id_professional;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_epis_sch_prof;

    /**
    * Gets current episodes for a patient
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    *
    * @param o_current_with_me     cursor containing current episodes for this patient with the professional
    * @param o_current_all         cursor containing all the current episodes for this patient
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2008-05-19
    * @version v2.4.3
    * @author Sérgio Santos
    */
    FUNCTION get_current_episodes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        o_current_with_me OUT pk_types.cursor_type,
        o_current_all     OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_epis_type_acc   table_number;
        l_epis_type_count NUMBER;
        l_grp_insts       table_number;
    
        l_prof_inst_in_group VARCHAR2(1);
    
        l_handoff_type sys_config.value%TYPE;
    BEGIN
        g_error := 'GET HANDOFF TYPE';
        alertlog.pk_alertlog.log_info(text => g_error);
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
    
        g_error := 'GET INSTITUTIONS GROUP';
        SELECT column_value
          BULK COLLECT
          INTO l_grp_insts
          FROM TABLE(pk_list.tf_get_all_inst_group(i_prof.institution, g_inst_grp_flg_rel_adt));
    
        BEGIN
            SELECT DISTINCT pk_alert_constant.g_yes
              INTO l_prof_inst_in_group
              FROM dual
             WHERE i_prof.institution IN (SELECT column_value
                                            FROM TABLE(l_grp_insts));
        
        EXCEPTION
            WHEN no_data_found THEN
                l_prof_inst_in_group := pk_alert_constant.g_no;
        END;
    
        g_error := 'GET EPIS_TYPE';
        /*        SELECT eta.id_epis_type
         BULK COLLECT
         INTO l_epis_type_acc
         FROM epis_type_access eta, prof_profile_template ppt
        WHERE eta.id_institution = decode((SELECT eta.id_epis_type
                                            FROM epis_type_access eta, prof_profile_template ppt
                                           WHERE eta.id_institution = i_prof.institution
                                             AND ppt.id_profile_template = eta.id_profile_template
                                             AND ppt.id_professional = i_prof.id
                                             AND ppt.id_institution = eta.id_institution
                                             AND ppt.id_software = i_prof.software
                                             AND rownum <= 1),
                                          NULL,
                                          0,
                                          i_prof.institution)
          AND ppt.id_profile_template = eta.id_profile_template
          AND ppt.id_professional = i_prof.id
          AND ppt.id_institution = i_prof.institution
          AND ppt.id_software = i_prof.software
          AND eta.id_epis_type != 0;*/
        l_epis_type_acc   := pk_episode.get_epis_type_access(i_prof, pk_alert_constant.g_no);
        l_epis_type_count := l_epis_type_acc.count;
    
        g_error := 'OPEN O_CURRENT_WITH_ME';
        OPEN o_current_with_me FOR
            SELECT e.id_episode,
                   pk_ehr_common.get_visit_name_by_epis(i_lang, i_prof, e.id_epis_type) visit_name,
                   pk_ehr_common.get_visit_type_by_epis(i_lang, i_prof, e.id_episode, e.id_epis_type, ', ') visit_type,
                   pk_prof_utils.get_name_signature(i_lang,
                                                    i_prof,
                                                    get_epis_sch_prof(ei.id_schedule_outp, e.id_episode)) prof_nickname,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, e.dt_begin_tstz, i_prof) epis_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software) epis_hour,
                   pk_ehr_access.get_access_reason_desc(i_lang, i_id_patient, e.id_episode, g_sep_reason) last_access_reason,
                   decode(e.id_institution, i_prof.institution, g_no, g_yes) show_report,
                   to_char(e.dt_begin_tstz, pk_alert_constant.g_dt_yyyymmddhh24miss) order_date
              FROM episode e, epis_info ei
             WHERE ei.id_episode = e.id_episode
               AND (e.id_epis_type IN (SELECT column_value
                                         FROM TABLE(l_epis_type_acc)) OR
                   (l_epis_type_count = 0 AND ei.id_software IN (0, i_prof.software)))
               AND e.id_patient = i_id_patient
               AND (e.id_institution IN (SELECT column_value
                                           FROM TABLE(l_grp_insts)) OR
                   pk_transfer_institution.check_transfer_access(e.id_episode, i_prof) = g_yes)
               AND pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                    i_prof,
                                                                                    ei.id_episode,
                                                                                    pk_alert_constant.g_cat_type_doc,
                                                                                    l_handoff_type),
                                                i_prof.id) != -1
               AND e.flg_status IN (g_epis_active)
               AND e.flg_ehr = g_flg_ehr_normal
             ORDER BY order_date DESC;
    
        g_error := 'OPEN O_CURRENT_ALL';
        OPEN o_current_all FOR
            SELECT e.id_episode,
                   pk_ehr_common.get_visit_name_by_epis(i_lang, i_prof, e.id_epis_type) visit_name,
                   pk_ehr_common.get_visit_type_by_epis(i_lang, i_prof, e.id_episode, e.id_epis_type, ', ') visit_type,
                   pk_prof_utils.get_name_signature(i_lang,
                                                    i_prof,
                                                    get_epis_sch_prof(ei.id_schedule_outp, e.id_episode)) prof_nickname,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, e.dt_begin_tstz, i_prof) epis_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software) epis_hour,
                   pk_ehr_access.get_access_reason_desc(i_lang, i_id_patient, e.id_episode, g_sep_reason) last_access_reason,
                   decode(e.id_institution, i_prof.institution, g_no, g_yes) show_report,
                   to_char(e.dt_begin_tstz, pk_alert_constant.g_dt_yyyymmddhh24miss) order_date
              FROM episode e, epis_info ei
             WHERE ei.id_episode = e.id_episode
               AND (e.id_epis_type IN (SELECT column_value
                                         FROM TABLE(l_epis_type_acc)) OR
                   (l_epis_type_count = 0 AND ei.id_software IN (0, i_prof.software)))
               AND e.id_patient = i_id_patient
               AND (e.id_institution IN (SELECT column_value
                                           FROM TABLE(l_grp_insts)) OR
                   pk_transfer_institution.check_transfer_access(e.id_episode, i_prof) = g_yes)
               AND e.flg_status IN (g_epis_active)
               AND e.flg_ehr = g_flg_ehr_normal
             ORDER BY order_date DESC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_EHR_ACCESS', 'GET_CURRENT_EPISODES');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- fechar os cursores
                pk_types.open_my_cursor(o_current_with_me);
                pk_types.open_my_cursor(o_current_all);
                -- return failure 
                RETURN FALSE;
            END;
    END get_current_episodes;

    /**
    * Gets previous episodes for a patient
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    *
    * @param o_prev_with_me        cursor containing previous episodes for this patient with the professional
    * @param o_prev_last10         cursor containing the last 10 previous episodes for this patient
    * @param o_prev_all            cursor containing previous episodes for this patient
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2008-05-19
    * @version v2.4.3
    * @author Sérgio Santos
    */
    FUNCTION get_previous_episodes
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE,
        o_prev_with_me OUT pk_types.cursor_type,
        o_prev_last10  OUT pk_types.cursor_type,
        o_prev_all     OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_epis_type_acc   table_number;
        l_epis_type_count NUMBER;
        l_grp_insts       table_number;
    
        l_prof_inst_in_group VARCHAR2(1);
        l_handoff_type       sys_config.value%TYPE;
    BEGIN
        g_error := 'GET HANDOFF TYPE';
        alertlog.pk_alertlog.log_info(text => g_error);
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
    
        g_error := 'GET INSTITUTIONS GROUP';
        SELECT column_value
          BULK COLLECT
          INTO l_grp_insts
          FROM TABLE(pk_list.tf_get_all_inst_group(i_prof.institution, g_inst_grp_flg_rel_adt));
    
        BEGIN
            SELECT DISTINCT pk_alert_constant.g_yes
              INTO l_prof_inst_in_group
              FROM dual
             WHERE i_prof.institution IN (SELECT column_value
                                            FROM TABLE(l_grp_insts));
        
        EXCEPTION
            WHEN no_data_found THEN
                l_prof_inst_in_group := pk_alert_constant.g_no;
        END;
    
        /*        SELECT eta.id_epis_type
         BULK COLLECT
         INTO l_epis_type_acc
         FROM epis_type_access eta, prof_profile_template ppt
        WHERE eta.id_institution = decode((SELECT eta.id_epis_type
                                            FROM epis_type_access eta, prof_profile_template ppt
                                           WHERE eta.id_institution = i_prof.institution
                                             AND ppt.id_profile_template = eta.id_profile_template
                                             AND ppt.id_professional = i_prof.id
                                             AND ppt.id_institution = eta.id_institution
                                             AND ppt.id_software = i_prof.software
                                             AND rownum <= 1),
                                          NULL,
                                          0,
                                          i_prof.institution)
          AND ppt.id_profile_template = eta.id_profile_template
          AND ppt.id_professional = i_prof.id
          AND ppt.id_institution = i_prof.institution
          AND ppt.id_software = i_prof.software
          AND eta.id_epis_type != 0;*/
        l_epis_type_acc   := pk_episode.get_epis_type_access(i_prof, pk_alert_constant.g_no);
        l_epis_type_count := l_epis_type_acc.count;
    
        g_error := 'OPEN O_PREV_WITH_ME';
        OPEN o_prev_with_me FOR
            SELECT e.id_episode,
                   pk_ehr_common.get_visit_name_by_epis(i_lang, i_prof, e.id_epis_type) visit_name,
                   pk_ehr_common.get_visit_type_by_epis(i_lang, i_prof, e.id_episode, e.id_epis_type, ', ') visit_type,
                   pk_prof_utils.get_name_signature(i_lang,
                                                    i_prof,
                                                    get_epis_sch_prof(ei.id_schedule_outp, e.id_episode)) prof_nickname,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, e.dt_begin_tstz, i_prof) epis_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software) epis_hour,
                   pk_ehr_access.get_access_reason_desc(i_lang, i_id_patient, e.id_episode, g_sep_reason) last_access_reason,
                   decode(e.id_institution, i_prof.institution, g_no, g_yes) show_report,
                   to_char(e.dt_begin_tstz, pk_alert_constant.g_dt_yyyymmddhh24miss) order_date
              FROM episode e, epis_info ei
             WHERE ei.id_episode = e.id_episode
               AND (e.id_epis_type IN (SELECT column_value
                                         FROM TABLE(l_epis_type_acc)) OR
                   (l_epis_type_count = 0 AND ei.id_software IN (0, i_prof.software)))
               AND e.id_patient = i_id_patient
               AND (e.id_institution IN (SELECT column_value
                                           FROM TABLE(l_grp_insts)) OR
                   pk_transfer_institution.check_transfer_access(e.id_episode, i_prof) = g_yes)
               AND pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                    i_prof,
                                                                                    ei.id_episode,
                                                                                    pk_alert_constant.g_cat_type_doc,
                                                                                    l_handoff_type),
                                                i_prof.id) != -1
               AND e.flg_status IN (g_epis_inactive, g_epis_pending)
               AND e.flg_ehr = g_flg_ehr_normal
             ORDER BY order_date DESC;
    
        g_error := 'OPEN O_PREV_LAST10';
        OPEN o_prev_last10 FOR
            SELECT tbl.id_episode,
                   pk_ehr_common.get_visit_name_by_epis(i_lang, i_prof, tbl.id_epis_type) visit_name,
                   pk_ehr_common.get_visit_type_by_epis(i_lang, i_prof, tbl.id_episode, tbl.id_epis_type, ', ') visit_type,
                   tbl.prof_nickname,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, tbl.dt_begin_tstz, i_prof) epis_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, tbl.dt_begin_tstz, i_prof.institution, i_prof.software) epis_hour,
                   pk_ehr_access.get_access_reason_desc(i_lang, i_id_patient, tbl.id_episode, g_sep_reason) last_access_reason,
                   decode(tbl.id_institution, i_prof.institution, g_no, g_yes) show_report,
                   to_char(tbl.dt_begin_tstz, pk_alert_constant.g_dt_yyyymmddhh24miss) order_date
              FROM (SELECT e.id_episode,
                           e.id_epis_type,
                           e.dt_begin_tstz,
                           e.dt_end_tstz,
                           e.id_institution,
                           pk_prof_utils.get_name_signature(i_lang,
                                                            i_prof,
                                                            get_epis_sch_prof(ei.id_schedule_outp, e.id_episode)) prof_nickname
                      FROM episode e, epis_info ei
                     WHERE ei.id_episode = e.id_episode
                       AND (e.id_epis_type IN (SELECT column_value
                                                 FROM TABLE(l_epis_type_acc)) OR
                           (l_epis_type_count = 0 AND ei.id_software IN (0, i_prof.software)))
                       AND e.id_patient = i_id_patient
                       AND (e.id_institution IN (SELECT column_value
                                                   FROM TABLE(l_grp_insts)) OR
                           pk_transfer_institution.check_transfer_access(e.id_episode, i_prof) = g_yes)
                       AND e.flg_status IN (g_epis_inactive, g_epis_pending)
                       AND e.flg_ehr = g_flg_ehr_normal
                     ORDER BY e.dt_end_tstz DESC) tbl
             WHERE rownum <= 10
             ORDER BY order_date DESC;
    
        g_error := 'OPEN O_PREV_ALL';
        OPEN o_prev_all FOR
            SELECT e.id_episode,
                   pk_ehr_common.get_visit_name_by_epis(i_lang, i_prof, e.id_epis_type) visit_name,
                   pk_ehr_common.get_visit_type_by_epis(i_lang, i_prof, e.id_episode, e.id_epis_type, ', ') visit_type,
                   pk_prof_utils.get_name_signature(i_lang,
                                                    i_prof,
                                                    get_epis_sch_prof(ei.id_schedule_outp, e.id_episode)) prof_nickname,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, e.dt_begin_tstz, i_prof) epis_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software) epis_hour,
                   pk_ehr_access.get_access_reason_desc(i_lang, i_id_patient, e.id_episode, g_sep_reason) last_access_reason,
                   decode(e.id_institution, i_prof.institution, g_no, g_yes) show_report,
                   to_char(e.dt_begin_tstz, pk_alert_constant.g_dt_yyyymmddhh24miss) order_date
              FROM episode e, epis_info ei
             WHERE ei.id_episode = e.id_episode
               AND (e.id_epis_type IN (SELECT column_value
                                         FROM TABLE(l_epis_type_acc)) OR
                   (l_epis_type_count = 0 AND ei.id_software IN (0, i_prof.software)))
               AND e.id_patient = i_id_patient
               AND (e.id_institution IN (SELECT column_value
                                           FROM TABLE(l_grp_insts)) OR
                   pk_transfer_institution.check_transfer_access(e.id_episode, i_prof) = g_yes)
               AND e.flg_status IN (g_epis_inactive, g_epis_pending)
               AND e.flg_ehr = g_flg_ehr_normal
             ORDER BY order_date DESC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_EHR_ACCESS',
                                   'GET_PREVIOUS_EPISODES');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- fechar os cursores
                pk_types.open_my_cursor(o_prev_with_me);
                pk_types.open_my_cursor(o_prev_last10);
                pk_types.open_my_cursor(o_prev_all);
                -- return failure
                RETURN FALSE;
            END;
    END get_previous_episodes;

    /**
    * Gets scheduled episodes for a professional
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    *
    * @param o_sched_with_me      cursor containing scheduled episodes for this professional
    * @param o_sched_all          cursor containing scheduled episodes for this patient
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2008-05-19
    * @version v2.4.3
    * @author Sérgio Santos
    */
    FUNCTION get_scheduled_episodes
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN patient.id_patient%TYPE,
        o_sched_with_me OUT pk_types.cursor_type,
        o_sched_all     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_epis_type_acc   table_number;
        l_epis_type_count NUMBER;
    
        --variavel que indica de nos devemos deslocar para a area antiga quando estamos em episódios não efectivados
        l_to_old_area VARCHAR2(1);
    BEGIN
        /*        SELECT eta.id_epis_type
         BULK COLLECT
         INTO l_epis_type_acc
         FROM epis_type_access eta, prof_profile_template ppt
        WHERE eta.id_institution = decode((SELECT eta.id_epis_type
                                            FROM epis_type_access eta, prof_profile_template ppt
                                           WHERE eta.id_institution = i_prof.institution
                                             AND ppt.id_profile_template = eta.id_profile_template
                                             AND ppt.id_professional = i_prof.id
                                             AND ppt.id_institution = eta.id_institution
                                             AND ppt.id_software = i_prof.software
                                             AND rownum <= 1),
                                          NULL,
                                          0,
                                          i_prof.institution)
          AND ppt.id_profile_template = eta.id_profile_template
          AND ppt.id_professional = i_prof.id
          AND ppt.id_institution = i_prof.institution
          AND ppt.id_software = i_prof.software
          AND eta.id_epis_type != 0;*/
        l_epis_type_acc   := pk_episode.get_epis_type_access(i_prof, pk_alert_constant.g_no);
        l_epis_type_count := l_epis_type_acc.count;
    
        l_to_old_area := pk_sysconfig.get_config('EHR_ACCESS_SC_OLD_AREA', i_prof);
    
        g_error := 'OPEN o_sched_with_me';
        OPEN o_sched_with_me FOR
            SELECT s.id_schedule,
                   NULL id_episode,
                   (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                      FROM clinical_service cs
                     WHERE cs.id_clinical_service =
                           (SELECT dcs.id_clinical_service
                              FROM dep_clin_serv dcs
                             WHERE dcs.id_dep_clin_serv = s.id_dcs_requested)) visit_type,
                   pk_ehr_common.get_visit_name_by_epis(i_lang, i_prof, so.id_epis_type) visit_name,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, spo.id_professional) prof_nickname,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, s.dt_begin_tstz, i_prof) epis_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, s.dt_begin_tstz, i_prof.institution, i_prof.software) epis_hour,
                   NULL last_access_reason,
                   to_char(s.dt_begin_tstz, pk_alert_constant.g_dt_yyyymmddhh24miss) order_date
              FROM schedule s
              JOIN sch_group sg
                ON (s.id_schedule = sg.id_schedule)
              JOIN schedule_outp so
                ON (s.id_schedule = so.id_schedule)
              JOIN sch_prof_outp spo
                ON (spo.id_schedule_outp = so.id_schedule_outp)
             WHERE sg.id_patient = i_id_patient
               AND spo.id_professional = i_prof.id
               AND s.flg_status != pk_schedule.g_sched_status_cancelled
               AND s.flg_status != pk_schedule.g_sched_status_cache -- agendamentos temporários (SCH 3.0)
               AND so.id_epis_type IN (SELECT etsi.id_epis_type
                                         FROM epis_type_soft_inst etsi
                                        WHERE etsi.id_software = i_prof.software
                                          AND etsi.id_institution IN (i_prof.institution, 0))
               AND s.id_schedule NOT IN (SELECT ei.id_schedule
                                           FROM epis_info ei
                                           JOIN episode e
                                             ON (ei.id_episode = e.id_episode)
                                          WHERE e.id_patient = i_id_patient
                                               --AND e.flg_ehr IN (g_flg_ehr_scheduled)
                                            AND ei.id_schedule IS NOT NULL)
            UNION ALL
            SELECT s.id_schedule,
                   decode(l_to_old_area,
                          g_yes,
                          decode(s.id_schedule, NULL, e.id_episode, -1, e.id_episode, NULL),
                          e.id_episode) id_episode,
                   pk_ehr_common.get_visit_name_by_epis(i_lang, i_prof, e.id_epis_type) visit_name,
                   pk_ehr_common.get_visit_type_by_epis(i_lang, i_prof, e.id_episode, e.id_epis_type, ', ') visit_type,
                   pk_prof_utils.get_name_signature(i_lang,
                                                    i_prof,
                                                    (SELECT ei.id_professional
                                                       FROM epis_info ei
                                                      WHERE ei.id_episode = e.id_episode)) prof_nickname,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, s.dt_begin_tstz, i_prof) epis_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, s.dt_begin_tstz, i_prof.institution, i_prof.software) epis_hour,
                   pk_ehr_access.get_access_reason_desc(i_lang, i_id_patient, e.id_episode, g_sep_reason) last_access_reason,
                   to_char(s.dt_begin_tstz, pk_alert_constant.g_dt_yyyymmddhh24miss) order_date
              FROM episode e, epis_info ei, schedule s
             WHERE ei.id_episode = e.id_episode
               AND ei.id_schedule = s.id_schedule
               AND (s.flg_status NOT IN (pk_schedule.g_sched_status_cancelled, pk_schedule.g_sched_status_cache) OR
                   s.flg_status IS NULL)
               AND e.id_patient = i_id_patient
               AND e.id_institution IN
                   (SELECT column_value
                      FROM TABLE(pk_list.tf_get_all_inst_group(i_prof.institution, g_inst_grp_flg_rel_adt)))
               AND (e.id_epis_type IN (SELECT column_value
                                         FROM TABLE(l_epis_type_acc)) OR
                   (l_epis_type_count = 0 AND ei.id_software IN (0, i_prof.software)))
               AND ei.id_professional = i_prof.id
               AND e.flg_status IN (g_epis_active)
               AND e.flg_ehr = g_flg_ehr_scheduled
            UNION ALL -- episodios tipo 'S' sem linha na schedule
            SELECT NULL,
                   e.id_episode,
                   pk_ehr_common.get_visit_name_by_epis(i_lang, i_prof, e.id_epis_type) visit_name,
                   pk_ehr_common.get_visit_type_by_epis(i_lang, i_prof, e.id_episode, e.id_epis_type, ', ') visit_type,
                   pk_prof_utils.get_name_signature(i_lang,
                                                    i_prof,
                                                    (SELECT ei.id_professional
                                                       FROM epis_info ei
                                                      WHERE ei.id_episode = e.id_episode)) prof_nickname,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, e.dt_begin_tstz, i_prof) epis_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software) epis_hour,
                   pk_ehr_access.get_access_reason_desc(i_lang, i_id_patient, e.id_episode, g_sep_reason) last_access_reason,
                   to_char(e.dt_begin_tstz, pk_alert_constant.g_dt_yyyymmddhh24miss) order_date
              FROM episode e, epis_info ei
             WHERE ei.id_episode = e.id_episode
               AND NOT EXISTS (SELECT 'X'
                      FROM schedule s
                     WHERE s.id_schedule = decode(ei.id_schedule, -1, NULL, ei.id_schedule))
               AND e.id_patient = i_id_patient
               AND e.id_institution = i_prof.institution
               AND (e.id_epis_type IN (SELECT column_value
                                         FROM TABLE(l_epis_type_acc)) OR
                   (l_epis_type_count = 0 AND ei.id_software IN (0, i_prof.software)))
               AND ei.id_professional = i_prof.id
               AND e.flg_status IN (g_epis_active)
               AND e.flg_ehr = g_flg_ehr_scheduled
             ORDER BY order_date ASC;
    
        g_error := 'OPEN o_sched_all';
        OPEN o_sched_all FOR
            SELECT s.id_schedule,
                   NULL id_episode,
                   (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                      FROM clinical_service cs
                     WHERE cs.id_clinical_service =
                           (SELECT dcs.id_clinical_service
                              FROM dep_clin_serv dcs
                             WHERE dcs.id_dep_clin_serv = s.id_dcs_requested)) visit_type,
                   pk_ehr_common.get_visit_name_by_epis(i_lang, i_prof, so.id_epis_type) visit_name,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, spo.id_professional) prof_nickname,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, s.dt_begin_tstz, i_prof) epis_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, s.dt_begin_tstz, i_prof.institution, i_prof.software) epis_hour,
                   NULL last_access_reason,
                   to_char(s.dt_begin_tstz, pk_alert_constant.g_dt_yyyymmddhh24miss) order_date
              FROM schedule s
              JOIN sch_group sg
                ON (s.id_schedule = sg.id_schedule)
              JOIN schedule_outp so
                ON (s.id_schedule = so.id_schedule)
              JOIN sch_prof_outp spo
                ON (spo.id_schedule_outp = so.id_schedule_outp)
             WHERE sg.id_patient = i_id_patient
               AND s.flg_status != pk_schedule.g_sched_status_cancelled
               AND s.flg_status != pk_schedule.g_sched_status_cache -- agendamentos temporários (SCH 3.0)
               AND so.id_epis_type IN (SELECT etsi.id_epis_type
                                         FROM epis_type_soft_inst etsi
                                        WHERE etsi.id_software = i_prof.software
                                          AND etsi.id_institution IN (i_prof.institution, 0))
               AND s.id_schedule NOT IN (SELECT ei.id_schedule
                                           FROM epis_info ei
                                           JOIN episode e
                                             ON (ei.id_episode = e.id_episode)
                                          WHERE e.id_patient = i_id_patient
                                               --AND e.flg_ehr IN (g_flg_ehr_scheduled)
                                            AND ei.id_schedule IS NOT NULL)
            UNION ALL
            SELECT s.id_schedule,
                   decode(l_to_old_area,
                          g_yes,
                          decode(s.id_schedule, NULL, e.id_episode, -1, e.id_episode, NULL),
                          e.id_episode) id_episode,
                   pk_ehr_common.get_visit_name_by_epis(i_lang, i_prof, e.id_epis_type) visit_name,
                   pk_ehr_common.get_visit_type_by_epis(i_lang, i_prof, e.id_episode, e.id_epis_type, ', ') visit_type,
                   pk_prof_utils.get_name_signature(i_lang,
                                                    i_prof,
                                                    (SELECT ei.id_professional
                                                       FROM epis_info ei
                                                      WHERE ei.id_episode = e.id_episode)) prof_nickname,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, s.dt_begin_tstz, i_prof) epis_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, s.dt_begin_tstz, i_prof.institution, i_prof.software) epis_hour,
                   pk_ehr_access.get_access_reason_desc(i_lang, i_id_patient, e.id_episode, g_sep_reason) last_access_reason,
                   to_char(s.dt_begin_tstz, pk_alert_constant.g_dt_yyyymmddhh24miss) order_date
              FROM episode e, epis_info ei, schedule s
             WHERE ei.id_episode = e.id_episode
               AND ei.id_schedule = s.id_schedule
               AND ei.id_schedule <> -1
               AND (s.flg_status NOT IN (pk_schedule.g_sched_status_cancelled, pk_schedule.g_sched_status_cache) OR
                   s.flg_status IS NULL)
               AND e.id_institution IN
                   (SELECT column_value
                      FROM TABLE(pk_list.tf_get_all_inst_group(i_prof.institution, g_inst_grp_flg_rel_adt)))
               AND (e.id_epis_type IN (SELECT column_value
                                         FROM TABLE(l_epis_type_acc)) OR
                   (l_epis_type_count = 0 AND ei.id_software IN (0, i_prof.software)))
               AND e.id_patient = i_id_patient
               AND e.flg_status IN (g_epis_active)
               AND e.flg_ehr = g_flg_ehr_scheduled
            UNION ALL -- episodios tipo 'S' sem linha na schedule
            SELECT NULL,
                   e.id_episode,
                   pk_ehr_common.get_visit_name_by_epis(i_lang, i_prof, e.id_epis_type) visit_name,
                   pk_ehr_common.get_visit_type_by_epis(i_lang, i_prof, e.id_episode, e.id_epis_type, ', ') visit_type,
                   pk_prof_utils.get_name_signature(i_lang,
                                                    i_prof,
                                                    (SELECT ei.id_professional
                                                       FROM epis_info ei
                                                      WHERE ei.id_episode = e.id_episode)) prof_nickname,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, e.dt_begin_tstz, i_prof) epis_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software) epis_hour,
                   pk_ehr_access.get_access_reason_desc(i_lang, i_id_patient, e.id_episode, g_sep_reason) last_access_reason,
                   to_char(e.dt_begin_tstz, pk_alert_constant.g_dt_yyyymmddhh24miss) order_date
              FROM episode e, epis_info ei
             WHERE ei.id_episode = e.id_episode
               AND NOT EXISTS (SELECT 'X'
                      FROM schedule s
                     WHERE s.id_schedule = decode(ei.id_schedule, -1, NULL, ei.id_schedule))
               AND e.id_patient = i_id_patient
               AND e.id_institution = i_prof.institution
               AND (e.id_epis_type IN (SELECT column_value
                                         FROM TABLE(l_epis_type_acc)) OR
                   (l_epis_type_count = 0 AND ei.id_software IN (0, i_prof.software)))
               AND e.flg_status IN (g_epis_active)
               AND e.flg_ehr = g_flg_ehr_scheduled
             ORDER BY order_date ASC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_EHR_ACCESS',
                                   'GET_SCHEDULED_EPISODES');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- fechar os cursores
                pk_types.open_my_cursor(o_sched_with_me);
                pk_types.open_my_cursor(o_sched_all);
                -- return failure
                RETURN FALSE;
            END;
    END get_scheduled_episodes;

    /**
    * Gets EHR events for a professional
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    *
    * @param o_ehr_with_me         cursor containing EHR events for this professional
    * @param o_ehr_all             cursor containing EHR events for this patient
    * @param o_ehr_new             cursor indicating if we can create ehr events
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2008-05-19
    * @version v2.4.3
    * @author Sérgio Santos
    */
    FUNCTION get_ehr_events
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        o_ehr_with_me OUT pk_types.cursor_type,
        o_ehr_all     OUT pk_types.cursor_type,
        o_ehr_new     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_epis_type NUMBER;
    
    BEGIN
        g_error     := 'get prof epis_type';
        l_epis_type := pk_sysconfig.get_config('EPIS_TYPE', i_prof);
    
        g_error := 'OPEN o_ehr_with_me';
        OPEN o_ehr_with_me FOR
            SELECT e.id_episode,
                   e.id_epis_type,
                   pk_ehr_common.get_visit_name_by_epis(i_lang, i_prof, e.id_epis_type) visit_name,
                   pk_ehr_common.get_visit_type_by_epis(i_lang, i_prof, e.id_episode, e.id_epis_type, ', ') visit_type,
                   pk_prof_utils.get_name_signature(i_lang,
                                                    i_prof,
                                                    (SELECT nvl(ei.id_professional, ei.id_first_nurse_resp)
                                                       FROM epis_info ei
                                                      WHERE ei.id_episode = e.id_episode)) prof_nickname,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, e.dt_begin_tstz, i_prof) epis_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software) epis_hour,
                   pk_ehr_access.get_access_reason_desc(i_lang, i_id_patient, e.id_episode, g_sep_reason) last_access_reason,
                   to_char(e.dt_begin_tstz, pk_alert_constant.g_dt_yyyymmddhh24miss) order_date
              FROM episode e, epis_info ei
             WHERE ei.id_episode = e.id_episode
               AND e.id_patient = i_id_patient
               AND (i_prof.software, e.id_epis_type) IN
                   (SELECT etsi.id_software, etsi.id_epis_type
                      FROM epis_type_soft_inst etsi
                     WHERE etsi.id_institution IN (0, i_prof.institution))
               AND (ei.id_professional = i_prof.id OR ei.id_first_nurse_resp = i_prof.id)
               AND e.flg_ehr = g_flg_ehr_ehr
             ORDER BY order_date DESC;
    
        g_error := 'OPEN o_ehr_all';
        OPEN o_ehr_all FOR
            SELECT e.id_episode,
                   pk_ehr_common.get_visit_name_by_epis(i_lang, i_prof, e.id_epis_type) visit_name,
                   pk_ehr_common.get_visit_type_by_epis(i_lang, i_prof, e.id_episode, e.id_epis_type, ', ') visit_type,
                   pk_prof_utils.get_name_signature(i_lang,
                                                    i_prof,
                                                    (SELECT nvl(ei.id_professional, ei.id_first_nurse_resp)
                                                       FROM epis_info ei
                                                      WHERE ei.id_episode = e.id_episode)) prof_nickname,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, e.dt_begin_tstz, i_prof) epis_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software) epis_hour,
                   pk_ehr_access.get_access_reason_desc(i_lang, i_id_patient, e.id_episode, g_sep_reason) last_access_reason,
                   to_char(e.dt_begin_tstz, pk_alert_constant.g_dt_yyyymmddhh24miss) order_date
              FROM episode e
             WHERE e.id_patient = i_id_patient
               AND (i_prof.software, e.id_epis_type) IN
                   (SELECT etsi.id_software, etsi.id_epis_type
                      FROM epis_type_soft_inst etsi
                     WHERE etsi.id_institution IN (0, i_prof.institution))
               AND e.flg_ehr = g_flg_ehr_ehr
             ORDER BY order_date DESC;
    
        g_error := 'OPEN o_ehr_new';
        OPEN o_ehr_new FOR
            SELECT pk_message.get_message(i_lang, 'EHR_ACCESS_T029') new_ehr_desc,
                   pk_ehr_common.get_visit_name_by_epis(i_lang, i_prof, l_epis_type) visit_name,
                   pk_sysconfig.get_config('EHR_EVENT_CREATE', i_prof.institution, i_prof.software) new_ehr_create
              FROM dual;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_EHR_ACCESS', 'GET_CURRENT_EPISODES');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- fechar os cursores
                pk_types.open_my_cursor(o_ehr_with_me);
                pk_types.open_my_cursor(o_ehr_all);
                -- return failure
                RETURN FALSE;
            END;
    END get_ehr_events;

    /**
    * Prepares and creates the EHR access for a scheduled espisode.
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_id_episode          episode id
    * @param i_id_scheduled        scheduled id
    *
    * @param o_error               error message
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2008-05-21
    * @version v2.4.3
    * @author Eduardo Lourenço
    */
    FUNCTION create_ehr_access_schedule
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_schedule    IN schedule.id_schedule%TYPE,
        i_transaction_id IN VARCHAR2,
        o_episode        OUT episode.id_episode%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_epis_type epis_type.id_epis_type%TYPE;
        l_id_episode   episode.id_episode%TYPE;
    
        l_episode_assoc episode.id_episode%TYPE;
    
        -- SCH 3.0 variable
        l_transaction_id VARCHAR2(4000);
    
    BEGIN
    
        --Check if there is some episode relataded to the schedule
        BEGIN
            SELECT ei.id_episode
              INTO l_episode_assoc
              FROM epis_info ei
             WHERE ei.id_schedule = i_id_schedule
               AND nvl(ei.id_schedule, -1) <> -1;
        EXCEPTION
            WHEN no_data_found THEN
                l_episode_assoc := i_id_episode;
        END;
    
        -- TODO If there is no episode associated with the schedule, creates it.
        IF i_id_episode IS NULL
           AND l_episode_assoc IS NULL
        THEN
            g_error := 'create_ehr_access_schedule';
            BEGIN
                SELECT so.id_epis_type
                  INTO l_id_epis_type
                  FROM schedule s
                  JOIN schedule_outp so
                    ON s.id_schedule = so.id_schedule
                 WHERE s.id_schedule = i_id_schedule
                   AND i_id_schedule IS NOT NULL;
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_epis_type := to_number(pk_sysconfig.get_config('EPIS_TYPE', i_prof));
            END;
        
            -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
            g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
            l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
        
            IF NOT pk_visit.create_visit(i_lang            => i_lang,
                                         i_id_pat          => i_id_patient,
                                         i_id_institution  => i_prof.institution,
                                         i_id_sched        => i_id_schedule,
                                         i_id_professional => i_prof,
                                         i_id_episode      => i_id_episode,
                                         i_external_cause  => NULL,
                                         i_health_plan     => NULL,
                                         i_epis_type       => l_id_epis_type,
                                         i_dep_clin_serv   => NULL, -- The dep_clin_serv is assigned to the schedule
                                         i_origin          => NULL,
                                         i_flg_ehr         => g_flg_ehr_scheduled,
                                         i_transaction_id  => l_transaction_id,
                                         o_episode         => l_id_episode,
                                         o_error           => o_error)
            
            THEN
                o_episode := l_id_episode;
                RAISE g_exception;
            END IF;
            o_episode := l_id_episode;
        
            -- remote commit
            IF i_transaction_id IS NULL
               AND l_transaction_id IS NOT NULL
            THEN
                pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
            END IF;
        
        ELSE
            o_episode := l_episode_assoc;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            ROLLBACK;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_EHR_ACCESS',
                                   'CREATE_EHR_ACCESS_SCHEDULE');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- undo changes
                pk_utils.undo_changes;
                pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
                -- return failure
                RETURN FALSE;
            END;
        
    END create_ehr_access_schedule;

    /**
    * Prepares and creates the EHR access for a scheduled espisode.
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_id_episode          episode id
    * @param i_id_scheduled        scheduled id
    *
    * @param o_error               error message
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2008-05-21
    * @version v2.4.3
    * @author Eduardo Lourenço
    */
    FUNCTION create_ehr_access_schedul_no_c
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_schedule    IN schedule.id_schedule%TYPE,
        i_transaction_id IN VARCHAR2,
        o_episode        OUT episode.id_episode%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_epis_type  epis_type.id_epis_type%TYPE;
        l_id_episode    episode.id_episode%TYPE;
        l_episode_assoc episode.id_episode%TYPE;
        -- SCH 3.0 variable
        l_transaction_id VARCHAR2(4000);
        l_health_plan    health_plan.id_health_plan%TYPE;
        l_num            NUMBER;
    BEGIN
    
        --Check if there is some episode relataded to the schedule
        BEGIN
            SELECT ei.id_episode
              INTO l_episode_assoc
              FROM epis_info ei
             WHERE ei.id_schedule = i_id_schedule
               AND nvl(ei.id_schedule, -1) <> -1;
        EXCEPTION
            WHEN no_data_found THEN
                l_episode_assoc := i_id_episode;
        END;
    
        -- TODO If there is no episode associated with the schedule, creates it.
        IF i_id_episode IS NULL
           AND l_episode_assoc IS NULL
        THEN
            g_error := 'create_ehr_access_schedule_no_c';
            BEGIN
                SELECT so.id_epis_type
                  INTO l_id_epis_type
                  FROM schedule s
                  JOIN schedule_outp so
                    ON s.id_schedule = so.id_schedule
                 WHERE s.id_schedule = i_id_schedule
                   AND i_id_schedule IS NOT NULL;
            EXCEPTION
                WHEN no_data_found THEN
                    IF i_prof.software = pk_alert_constant.g_soft_rehab
                    THEN
                        SELECT COUNT(1)
                          INTO l_num
                          FROM rehab_schedule rs
                         WHERE rs.id_schedule = i_id_schedule;
                        IF l_num > 0
                        THEN
                            l_id_epis_type := pk_alert_constant.g_epis_type_rehab_session;
                        ELSE
                            l_id_epis_type := to_number(pk_sysconfig.get_config('EPIS_TYPE', i_prof));
                        END IF;
                    ELSE
                        l_id_epis_type := to_number(pk_sysconfig.get_config('EPIS_TYPE', i_prof));
                    END IF;
                
            END;
            BEGIN
                SELECT sg.id_health_plan
                  INTO l_health_plan
                  FROM sch_group sg
                 WHERE sg.id_schedule = i_id_schedule
                   AND id_patient = i_id_patient;
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;
            -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
            g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
            l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
        
            IF NOT pk_visit.create_visit_no_commit(i_lang                 => i_lang,
                                                   i_id_pat               => i_id_patient,
                                                   i_id_institution       => i_prof.institution,
                                                   i_id_sched             => i_id_schedule,
                                                   i_id_professional      => i_prof,
                                                   i_id_episode           => i_id_episode,
                                                   i_external_cause       => NULL,
                                                   i_health_plan          => l_health_plan,
                                                   i_epis_type            => l_id_epis_type,
                                                   i_dep_clin_serv        => NULL, -- The dep_clin_serv is assigned to the schedule
                                                   i_origin               => NULL,
                                                   i_flg_ehr              => g_flg_ehr_scheduled,
                                                   i_dt_begin             => current_timestamp,
                                                   i_flg_appointment_type => NULL,
                                                   i_transaction_id       => l_transaction_id,
                                                   o_episode              => l_id_episode,
                                                   o_error                => o_error)
            
            THEN
                o_episode := l_id_episode;
                RAISE g_exception;
            END IF;
        
            o_episode := l_id_episode;
        
            -- remote commit
            IF i_transaction_id IS NULL
               AND l_transaction_id IS NOT NULL
            THEN
                pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
            END IF;
        
        ELSE
            o_episode := l_episode_assoc;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            ROLLBACK;
            pk_schedule_api_upstream.do_rollback(i_prof);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_EHR_ACCESS',
                                   'CREATE_EHR_ACCESS_SCHEDULE_NO_C');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- undo changes
                pk_utils.undo_changes;
                pk_schedule_api_upstream.do_rollback(i_prof);
                -- return failure
                RETURN FALSE;
            END;
        
    END create_ehr_access_schedul_no_c;

    /**
    * Creates an episode to be used in special contexts (EHR, SCHEDULE, ORDER SETS)
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_id_episode          episode id
    * @param i_id_scheduled        scheduled id
    * @param i_id_dep_clin_serv    dep_clin_serv id
    * @param i_epis_type           epis_type id
    *
    * @param o_error               error message
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2010-05-26
    * @version v2.6.0.3
    * @author Sérgio Santos
    */
    FUNCTION create_special_episode
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_epis_type     IN epis_type.id_epis_type%TYPE,
        i_flg_ehr          IN episode.flg_ehr%TYPE,
        i_transaction_id   IN VARCHAR2,
        o_episode          OUT episode.id_episode%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'CREATE_SPECIAL_EPISODE';
    
        -- SCH 3.0 variable
        l_transaction_id VARCHAR2(4000);
    
    BEGIN
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        -- TODO If there is no episode associated with the EHR event, creates it.
        IF i_id_episode IS NULL
        THEN
            g_error := 'create_ehr_access_ehr';
            IF NOT pk_visit.create_visit_no_commit(i_lang                 => i_lang,
                                                   i_id_pat               => i_id_patient,
                                                   i_id_institution       => i_prof.institution,
                                                   i_id_sched             => i_id_schedule,
                                                   i_id_professional      => i_prof,
                                                   i_id_episode           => i_id_episode,
                                                   i_external_cause       => NULL,
                                                   i_health_plan          => NULL,
                                                   i_epis_type            => i_id_epis_type,
                                                   i_dep_clin_serv        => i_id_dep_clin_serv,
                                                   i_origin               => NULL,
                                                   i_flg_ehr              => i_flg_ehr,
                                                   i_transaction_id       => l_transaction_id,
                                                   i_dt_begin             => NULL,
                                                   i_flg_appointment_type => NULL,
                                                   o_episode              => o_episode,
                                                   o_error                => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        -- remote commit
        IF i_transaction_id IS NULL
           AND l_transaction_id IS NOT NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            --remote scheduler rollback. Doesn't affect PFH.
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
    END create_special_episode;

    /**
    * Prepares and creates the EHR access for a scheduled espisode.
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_id_episode          episode id
    * @param i_id_scheduled        scheduled id
    *
    * @param o_error               error message
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2008-05-21
    * @version v2.4.3
    * @author Eduardo Lourenço
    */
    FUNCTION create_ehr_access_ehr
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_transaction_id   IN VARCHAR2,
        o_episode          OUT episode.id_episode%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_epis_type epis_type.id_epis_type%TYPE;
    
        -- SCH 3.0 variable
        l_transaction_id VARCHAR2(4000);
    
    BEGIN
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        l_id_epis_type := to_number(pk_sysconfig.get_config('EPIS_TYPE', i_prof));
    
        -- TODO If there is no episode associated with the EHR event, creates it.
        IF i_id_episode IS NULL
        THEN
            g_error := 'create_ehr_access_ehr';
            IF NOT create_special_episode(i_lang             => i_lang,
                                          i_prof             => i_prof,
                                          i_id_patient       => i_id_patient,
                                          i_id_episode       => i_id_episode,
                                          i_id_schedule      => i_id_schedule,
                                          i_id_dep_clin_serv => i_id_dep_clin_serv,
                                          i_id_epis_type     => l_id_epis_type,
                                          i_transaction_id   => l_transaction_id,
                                          i_flg_ehr          => pk_ehr_access.g_flg_ehr_ehr,
                                          o_episode          => o_episode,
                                          o_error            => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
        END IF;
    
        -- remote commit
        IF i_transaction_id IS NULL
           AND l_transaction_id IS NOT NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            -- undo changes
            pk_utils.undo_changes;
            --remote scheduler rollback. Doesn't affect PFH.
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_EHR_ACCESS',
                                   'CREATE_EHR_ACCESS_EHR');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- undo changes
                pk_utils.undo_changes;
                -- return failure
                --remote scheduler rollback. Doesn't affect PFH.
                pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
                RETURN FALSE;
            END;
    END create_ehr_access_ehr;

    /**
    * Prepares and creates the EHR access for a scheduled espisode.
    * It's an adaptation of create_ehr_access_ehr, to be used inside create_ehr_access_no_commit.
    * Goal is have a stack tree of function calls clean of commit instructions.
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_id_episode          episode id
    * @param i_id_scheduled        scheduled id
    *
    * @param o_error               error message
    *
    * @return              true if sucess, false otherwise
    *
    * @date    27-05-2011
    * @version 2.6.1.1
    * @author Telmo
    */
    FUNCTION create_ehr_access_ehr_no_c
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_transaction_id   IN VARCHAR2,
        o_episode          OUT episode.id_episode%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_epis_type epis_type.id_epis_type%TYPE;
        -- SCH 3.0 variable
        l_transaction_id VARCHAR2(4000);
    BEGIN
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        g_error        := 'GET SYS_CONFIG VALUE FOR CODE ''EPIS_TYPE''';
        l_id_epis_type := to_number(pk_sysconfig.get_config('EPIS_TYPE', i_prof));
    
        -- TODO If there is no episode associated with the EHR event, creates it.
        IF i_id_episode IS NULL
        THEN
            g_error := 'CALL PK_VISIT.CREATE_VISIT_NO_COMMIT';
            IF NOT pk_visit.create_visit_no_commit(i_lang                 => i_lang,
                                                   i_id_pat               => i_id_patient,
                                                   i_id_institution       => i_prof.institution,
                                                   i_id_sched             => i_id_schedule,
                                                   i_id_professional      => i_prof,
                                                   i_id_episode           => i_id_episode,
                                                   i_external_cause       => NULL,
                                                   i_health_plan          => NULL,
                                                   i_epis_type            => l_id_epis_type,
                                                   i_dep_clin_serv        => i_id_dep_clin_serv,
                                                   i_origin               => NULL,
                                                   i_flg_ehr              => pk_ehr_access.g_flg_ehr_ehr,
                                                   i_dt_begin             => current_timestamp,
                                                   i_flg_appointment_type => NULL,
                                                   i_transaction_id       => l_transaction_id,
                                                   o_episode              => o_episode,
                                                   o_error                => o_error)
            THEN
                RAISE g_exception;
            END IF;
            /*
                        g_error := 'create_ehr_access_ehr';
                        IF NOT create_special_episode(i_lang             => i_lang,
                                                      i_prof             => i_prof,
                                                      i_id_patient       => i_id_patient,
                                                      i_id_episode       => i_id_episode,
                                                      i_id_schedule      => i_id_schedule,
                                                      i_id_dep_clin_serv => i_id_dep_clin_serv,
                                                      i_id_epis_type     => l_id_epis_type,
                                                      i_transaction_id   => l_transaction_id,
                                                      i_flg_ehr          => pk_ehr_access.g_flg_ehr_ehr,
                                                      o_episode          => o_episode,
                                                      o_error            => o_error)
                        THEN
                            RAISE g_exception;
                        END IF;
            
                        IF NOT pk_visit.create_visit(i_lang            => i_lang,
                                                     i_id_pat          => i_id_patient,
                                                     i_id_institution  => i_prof.institution,
                                                     i_id_sched        => i_id_schedule,
                                                     i_id_professional => i_prof,
                                                     i_id_episode      => i_id_episode,
                                                     i_external_cause  => NULL,
                                                     i_health_plan     => NULL,
                                                     i_epis_type       => i_id_epis_type,
                                                     i_dep_clin_serv   => i_id_dep_clin_serv,
                                                     i_origin          => NULL,
                                                     i_flg_ehr         => i_flg_ehr,
                                                     i_transaction_id  => l_transaction_id,
                                         o_episode         => o_episode,
                                         o_error           => o_error)
            THEN
                RAISE g_exception;
            END IF;
            */
        END IF;
    
        -- remote commit
        IF i_transaction_id IS NULL
           AND l_transaction_id IS NOT NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            -- undo changes
            pk_utils.undo_changes;
            --remote scheduler rollback. Doesn't affect PFH.
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_EHR_ACCESS',
                                   'CREATE_EHR_ACCESS_EHR_NO_C');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- undo changes
                pk_utils.undo_changes;
                -- return failure
                --remote scheduler rollback. Doesn't affect PFH.
                pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
                RETURN FALSE;
            END;
    END create_ehr_access_ehr_no_c;

    /**
    * Creates an order set type episode
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_id_episode          episode id
    * @param i_id_scheduled        scheduled id
    *
    * @param o_error               error message
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2010-05-27
    * @version v2.6.0.3
    * @author Sérgio Santos
    */
    FUNCTION create_order_set_episode
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_epis_type     IN epis_type.id_epis_type%TYPE,
        i_transaction_id   IN VARCHAR2,
        o_episode          OUT episode.id_episode%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'CREATE_ORDER_SET_EPISODE';
    
        -- SCH 3.0 variable
        l_transaction_id VARCHAR2(4000);
    
        l_rowids table_varchar;
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        -- TODO If there is no episode associated with the EHR event, creates it.
        IF i_id_episode IS NULL
        THEN
            g_error := 'create_ehr_access_ehr';
            IF NOT create_special_episode(i_lang             => i_lang,
                                          i_prof             => i_prof,
                                          i_id_patient       => i_id_patient,
                                          i_id_episode       => i_id_episode,
                                          i_id_schedule      => i_id_schedule,
                                          i_id_dep_clin_serv => i_id_dep_clin_serv,
                                          i_id_epis_type     => i_id_epis_type,
                                          i_flg_ehr          => pk_ehr_access.g_flg_ehr_scheduled,
                                          i_transaction_id   => l_transaction_id,
                                          o_episode          => o_episode,
                                          o_error            => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
        END IF;
    
        --We will put the episode cancelled because it can't be presented on the grids.
        g_error := 'INSERT INTO EPISODE';
        ts_episode.upd(id_episode_in => o_episode, flg_status_in => pk_visit.g_epis_cancel, rows_out => l_rowids);
    
        g_error := 'PROCESS INSERT';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPISODE',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        -- remote commit
        IF i_transaction_id IS NULL
           AND l_transaction_id IS NOT NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            --remote scheduler rollback. Doesn't affect PFH.
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
    END create_order_set_episode;

    /********************************************************************************************
    * Prepares and creates the EHR access
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_id_episode          episode id
    * @param i_id_scheduled        scheduled id
    * @param i_transaction_id     Scheduler 3.0 transaction ID
    *
    * @param o_error               error message
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2009-05-28
    * @author Pedro Teixeira
    ********************************************************************************************/
    FUNCTION create_ehr_access_new_contact
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_access_flg_type  IN ehr_access_context.flg_type%TYPE,
        i_flg_context      IN ehr_access_context.flg_context%TYPE,
        i_transaction_id   IN VARCHAR2,
        i_id_sch_event     IN sch_event.id_sch_event%TYPE,
        o_episode          OUT episode.id_episode%TYPE,
        o_flg_show         OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT create_ehr_access_new_contact(i_lang             => i_lang,
                                             i_prof             => i_prof,
                                             i_id_patient       => i_id_patient,
                                             i_id_episode       => i_id_episode,
                                             i_id_schedule      => i_id_schedule,
                                             i_id_dep_clin_serv => i_id_dep_clin_serv,
                                             i_access_flg_type  => i_access_flg_type,
                                             i_flg_context      => i_flg_context,
                                             i_transaction_id   => i_transaction_id,
                                             i_id_sch_event     => i_id_sch_event,
                                             i_id_prof          => i_prof.id,
                                             o_episode          => o_episode,
                                             o_flg_show         => o_flg_show,
                                             o_msg_title        => o_msg_title,
                                             o_msg              => o_msg,
                                             o_button           => o_button,
                                             o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    END create_ehr_access_new_contact;

    FUNCTION create_ehr_access_new_contact
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_access_flg_type  IN ehr_access_context.flg_type%TYPE,
        i_flg_context      IN ehr_access_context.flg_context%TYPE,
        i_transaction_id   IN VARCHAR2,
        i_id_sch_event     IN sch_event.id_sch_event%TYPE,
        i_id_prof          IN professional.id_professional%TYPE,
        o_episode          OUT episode.id_episode%TYPE,
        o_flg_show         OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_epis_type         epis_type.id_epis_type%TYPE;
        l_id_dep_clin_serv     dep_clin_serv.id_dep_clin_serv%TYPE;
        l_id_clinical_service  clinical_service.id_clinical_service%TYPE;
        l_rowids_e             table_varchar;
        l_id_schedule          schedule.id_schedule%TYPE;
        l_prof_cat             category.flg_type%TYPE;
        l_flg_appointment_type episode.flg_appointment_type%TYPE;
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
        l_func_exception EXCEPTION;
        l_dep_type          sch_event.dep_type%TYPE;
        l_id_episode_origin epis_info.id_episode%TYPE;
    
        CURSOR c_sched_epis_type IS
            SELECT id_epis_type
              FROM (SELECT ses.id_epis_type, row_number() over(ORDER BY ses.id_software DESC) line_number
                      FROM schedule s, sch_event_soft ses
                     WHERE s.id_schedule = l_id_schedule
                       AND s.id_sch_event = ses.id_sch_event
                       AND ses.id_software IN (pk_alert_constant.g_soft_all, i_prof.software))
             WHERE line_number = 1;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
        l_prof_cat     := pk_tools.get_prof_cat(profissional(i_id_prof, i_prof.institution, i_prof.software));
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        IF i_id_dep_clin_serv IS NULL
        THEN
            l_id_dep_clin_serv := -1;
        ELSE
            l_id_dep_clin_serv := i_id_dep_clin_serv;
        END IF;
    
        ------------------------------------
        -- if it's a nurse, then it's necessary to create the schedule
        -- if the acess context is search screen and the option iss "Criar contacto agora" 
        -- if the acess context is create contact in ADT
        g_error := 'CALL PK_TOOLS.GET_PROF_CAT';
        IF (l_prof_cat = g_nurse_category)
           OR (i_access_flg_type = g_access_create_contact AND i_flg_context = g_flg_context_access)
           OR (i_flg_context = g_flg_context_new_patient)
        THEN
            g_error := 'CALL CREATE_EHR_ACCESS_NEW_SCHEDULE';
            IF NOT create_ehr_access_new_schedule(i_lang             => i_lang,
                                                  i_prof             => i_prof,
                                                  i_id_patient       => i_id_patient,
                                                  i_id_episode       => NULL,
                                                  i_id_dep_clin_serv => l_id_dep_clin_serv,
                                                  i_dt_begin         => g_sysdate_tstz,
                                                  i_prof_category    => l_prof_cat,
                                                  i_flg_context      => i_flg_context,
                                                  i_transaction_id   => l_transaction_id,
                                                  i_id_sch_event     => i_id_sch_event,
                                                  i_id_prof          => i_id_prof,
                                                  o_id_schedule      => l_id_schedule,
                                                  o_flg_show         => o_flg_show,
                                                  o_msg_title        => o_msg_title,
                                                  o_msg              => o_msg,
                                                  o_button           => o_button,
                                                  o_error            => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        -- if not scheduled created then use the one passed into the function
        IF l_id_schedule IS NULL
        THEN
            l_id_schedule := i_id_schedule;
        END IF;
    
        ------------------------------------
        -- epis_type processing
        IF l_id_schedule IS NOT NULL
        THEN
            g_error := 'OPEN C_SCHED_EPIS_TYPE';
            OPEN c_sched_epis_type;
            FETCH c_sched_epis_type
                INTO l_id_epis_type;
            g_found := c_sched_epis_type%FOUND;
            CLOSE c_sched_epis_type;
        END IF;
    
        IF l_id_epis_type IS NULL
        THEN
            l_id_epis_type := to_number(pk_sysconfig.get_config('EPIS_TYPE', i_prof));
        END IF;
    
        ------------------------------------
        -- no episode defined: necessary to create one
        IF i_id_episode IS NULL
        THEN
            l_flg_appointment_type := pk_sysconfig.get_config(g_sc_flg_appointment_type, i_prof);
            IF (l_flg_appointment_type IS NULL)
               OR (i_access_flg_type = g_access_new_indirect_contact AND i_flg_context = g_flg_context_access)
            THEN
                l_flg_appointment_type := g_appointment_type_indirect;
            END IF;
        
            SELECT dep_type
              INTO l_dep_type
              FROM sch_event
             WHERE id_sch_event = i_id_sch_event;
            IF l_dep_type <> 'CR'
            THEN
            
                g_error := 'CALL PK_VISIT.CREATE_VISIT';
                IF NOT pk_visit.create_visit(i_lang                 => i_lang,
                                             i_id_pat               => i_id_patient,
                                             i_id_institution       => i_prof.institution,
                                             i_id_sched             => l_id_schedule,
                                             i_id_professional      => profissional(i_id_prof,
                                                                                    i_prof.institution,
                                                                                    i_prof.software),
                                             i_id_episode           => i_id_episode,
                                             i_external_cause       => NULL,
                                             i_health_plan          => NULL,
                                             i_epis_type            => l_id_epis_type,
                                             i_dep_clin_serv        => l_id_dep_clin_serv,
                                             i_origin               => NULL,
                                             i_flg_ehr              => g_flg_ehr_normal,
                                             i_dt_begin             => g_sysdate_tstz,
                                             i_flg_appointment_type => l_flg_appointment_type,
                                             i_transaction_id       => l_transaction_id,
                                             o_episode              => o_episode,
                                             o_error                => o_error)
                THEN
                    RAISE g_exception;
                END IF;
                ------------------------------------
                -- update schedule with id_episode, since pk_visit.create_visit only updates epis_info with id_schedule
                IF o_episode IS NOT NULL
                   AND l_id_schedule IS NOT NULL
                THEN
                    ------------------------------------
                    -- schedule does not have denormalized package (ts_schedule)
                    UPDATE schedule s
                       SET s.id_episode = o_episode
                     WHERE s.id_schedule = l_id_schedule;
                
                END IF;
                ------------------------------------
                -- start the visit
                IF (i_flg_context = g_flg_context_access AND i_access_flg_type = g_access_create_contact)
                   OR
                   (i_flg_context = g_flg_context_new_patient AND i_access_flg_type != g_access_new_indirect_contact)
                THEN
                    g_error := 'PK_VISIT.SET_VISIT_INIT';
                
                    IF NOT pk_visit.set_visit_init(i_lang       => i_lang,
                                                   i_id_episode => o_episode,
                                                   i_prof       => i_prof,
                                                   o_error      => o_error)
                    
                    THEN
                        RAISE g_exception;
                    ELSE
                        ------------------------------------
                        -- update episode
                        g_error := 'TS_EPISODE.UPD';
                        ts_episode.upd(id_episode_in    => o_episode,
                                       dt_begin_tstz_in => g_sysdate_tstz,
                                       rows_out         => l_rowids_e);
                    
                        g_error := 'T_DATA_GOV_MNT.PROCESS_UPDATE EPISODE';
                        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'EPISODE',
                                                      i_rowids     => l_rowids_e,
                                                      o_error      => o_error);
                    END IF;
                
                    -- ALERT-258957 - Mário Mineiro - Now this code happens when efectivate the pacient in: PK_VISIT.CREATE_VISIT        
                    -- Getting the clin service
                    g_error := 'GET DEPARTMENT ID';
                    IF l_id_dep_clin_serv IS NOT NULL
                    THEN
                        SELECT dcs.id_clinical_service
                          INTO l_id_clinical_service
                          FROM dep_clin_serv dcs
                         WHERE dcs.id_dep_clin_serv = l_id_dep_clin_serv;
                    END IF;
                    -- Nao deve correr este codigo se for um episodio do tipo de tratamento
                    IF l_id_epis_type != pk_visit.g_epis_type_session
                    THEN
                        --Verificar se existem requisies e prescries de exames, etc no episdio anterior para este episdio.
                        IF NOT pk_visit.create_exam_req_presc(i_lang            => i_lang,
                                                              i_id_episode      => o_episode,
                                                              i_id_patient      => i_id_patient,
                                                              i_id_clin_service => l_id_clinical_service,
                                                              i_prof            => i_prof,
                                                              o_error           => o_error)
                        
                        THEN
                            -- o_error := l_error;
                            pk_utils.undo_changes;
                            RETURN FALSE;
                        END IF;
                    END IF;
                
                END IF;
            ELSE
                SELECT id_episode
                  INTO l_id_episode_origin
                  FROM epis_info e
                 WHERE e.id_schedule = l_id_schedule;
                IF NOT pk_rehab.set_rehab_workflow_change(i_lang              => i_lang,
                                                          i_prof              => i_prof,
                                                          i_id_patient        => i_id_patient,
                                                          i_workflow_type     => 'A',
                                                          i_from_state        => 'A',
                                                          i_to_state          => 'B',
                                                          i_id_rehab_grid     => NULL,
                                                          i_id_rehab_presc    => NULL,
                                                          i_id_epis_origin    => l_id_episode_origin,
                                                          i_id_rehab_schedule => NULL,
                                                          i_id_schedule       => l_id_schedule,
                                                          i_id_cancel_reason  => NULL,
                                                          i_cancel_notes      => NULL,
                                                          i_transaction_id    => l_transaction_id,
                                                          o_id_episode        => o_episode,
                                                          o_error             => o_error)
                THEN
                    RETURN FALSE;
                END IF;
                IF o_episode IS NULL
                THEN
                    o_episode := l_id_episode_origin;
                END IF;
            END IF;
        
        END IF;
    
        --remote scheduler commit. Doesn't affect PFH.
        IF i_transaction_id IS NULL
           AND l_transaction_id IS NOT NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            -- undo changes
            pk_utils.undo_changes;
            --remote scheduler rollback. Doesn't affect PFH.
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_EHR_ACCESS',
                                   'CREATE_EHR_ACCESS_NEW_CONTACT');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- undo changes
                pk_utils.undo_changes;
                -- return failure
            
                --remote scheduler rollback. Doesn't affect PFH.
                pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
                RETURN FALSE;
            END;
    END create_ehr_access_new_contact;

    /********************************************************************************************
    * Prepares and creates the EHR access.
    * It's an adaptation of create_ehr_access_new_contact, to be used inside create_ehr_access_no_commit.
    * Goal is have a stack tree of function calls clean of commit instructions.
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_id_episode          episode id
    * @param i_id_scheduled        scheduled id
    * @param i_transaction_id     Scheduler 3.0 transaction ID
    *
    * @param o_error               error message
    *
    * @return              true if sucess, false otherwise
    *
    * @date    27-05-2011
    * @author  Telmo
    * @version 2.6.1.1
    ********************************************************************************************/
    FUNCTION create_ehr_access_new_con_no_c
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_access_flg_type  IN ehr_access_context.flg_type%TYPE,
        i_flg_context      IN ehr_access_context.flg_context%TYPE,
        i_transaction_id   IN VARCHAR2,
        o_episode          OUT episode.id_episode%TYPE,
        o_flg_show         OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_epis_type         epis_type.id_epis_type%TYPE;
        l_id_dep_clin_serv     dep_clin_serv.id_dep_clin_serv%TYPE;
        l_id_clinical_service  clinical_service.id_clinical_service%TYPE;
        l_rowids_e             table_varchar;
        l_prof_cat             category.flg_type%TYPE;
        l_flg_appointment_type episode.flg_appointment_type%TYPE;
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
        l_func_exception EXCEPTION;
    
        CURSOR c_dep_clin_serv IS
            SELECT dcs.id_dep_clin_serv
              FROM dep_clin_serv dcs, department d
             WHERE dcs.id_clinical_service = l_id_clinical_service
               AND dcs.id_department = d.id_department
               AND d.id_institution = i_prof.institution;
    
        CURSOR c_sched_epis_type IS
            SELECT ses.id_epis_type
              FROM schedule s, sch_event_soft ses
             WHERE s.id_schedule = i_id_schedule
               AND s.id_sch_event = ses.id_sch_event
               AND ses.id_software = i_prof.software;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
        l_prof_cat     := pk_tools.get_prof_cat(i_prof);
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        IF i_id_dep_clin_serv IS NULL
        THEN
            ------------------------------------
            --  get clinical service
            IF l_prof_cat = g_doctor_category
            THEN
                l_id_clinical_service := to_number(pk_sysconfig.get_config('NEW_CONTACT_CLINICAL_SERVICE', i_prof));
            ELSIF l_prof_cat = g_nurse_category
            THEN
                l_id_clinical_service := to_number(pk_sysconfig.get_config('NEW_NURSING_CONTACT_CLINICAL_SERVICE',
                                                                           i_prof));
            END IF;
        
            IF l_id_clinical_service IS NULL
            THEN
                l_id_clinical_service := 40; -- saúde adultos
            END IF;
        
            ------------------------------------
            -- clin_serv processing
            g_error := 'OPEN C_DEP_CLIN_SERV';
            OPEN c_dep_clin_serv;
            FETCH c_dep_clin_serv
                INTO l_id_dep_clin_serv;
            g_found := c_dep_clin_serv%FOUND;
            CLOSE c_dep_clin_serv;
        
            IF NOT g_found
            THEN
                l_id_dep_clin_serv := -1;
            END IF;
        ELSE
            l_id_dep_clin_serv := i_id_dep_clin_serv;
        END IF;
    
        ------------------------------------
        /*
                -- this block cannot exist here because the call stack top function is pk_schedule_api_downstream.create_schedule.
                -- It means that we are already in the middle of a schedule creation started by the scheduler itself.
                -- Telmo 27-05-2011
        
                -- if it's a nurse, then it's necessary to create the schedule
                -- if the acess context is search screen and the option iss "Criar contacto agora" 
                -- if the acess context is create contact in ADT
                g_error := 'CALL PK_TOOLS.GET_PROF_CAT';
                IF (l_prof_cat = g_nurse_category)
                   OR (i_access_flg_type = g_access_create_contact AND i_flg_context = g_flg_context_access)
                   OR (i_flg_context = g_flg_context_new_patient)
                THEN
                    g_error := 'CALL CREATE_EHR_ACCESS_NEW_SCHEDULE';
                    IF NOT create_ehr_access_new_schedule(i_lang             => i_lang,
                                                          i_prof             => i_prof,
                                                          i_id_patient       => i_id_patient,
                                                          i_id_episode       => NULL,
                                                          i_id_dep_clin_serv => l_id_dep_clin_serv,
                                                          i_dt_begin         => g_sysdate_tstz,
                                                          i_prof_category    => l_prof_cat,
                                                          i_flg_context      => i_flg_context,
                                                          i_transaction_id   => l_transaction_id,
                                                          o_id_schedule      => l_id_schedule,
                                                          o_flg_show         => o_flg_show,
                                                          o_msg_title        => o_msg_title,
                                                          o_msg              => o_msg,
                                                          o_button           => o_button,
                                                          o_error            => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                END IF;
            
                -- if not scheduled created then use the one passed into the function
                IF l_id_schedule IS NULL
                THEN
                    l_id_schedule := i_id_schedule;
                END IF;
        */
        ------------------------------------
        -- epis_type processing
        IF i_id_schedule IS NOT NULL
        THEN
            g_error := 'OPEN C_SCHED_EPIS_TYPE';
            OPEN c_sched_epis_type;
            FETCH c_sched_epis_type
                INTO l_id_epis_type;
            g_found := c_sched_epis_type%FOUND;
            CLOSE c_sched_epis_type;
        END IF;
    
        IF l_id_epis_type IS NULL
        THEN
            l_id_epis_type := to_number(pk_sysconfig.get_config('EPIS_TYPE', i_prof));
        END IF;
    
        ------------------------------------
        -- no episode defined: necessary to create one
        IF i_id_episode IS NULL
        THEN
            l_flg_appointment_type := pk_sysconfig.get_config(g_sc_flg_appointment_type, i_prof);
            IF (l_flg_appointment_type IS NULL)
               OR (i_access_flg_type = g_access_new_indirect_contact AND i_flg_context = g_flg_context_access)
            THEN
                l_flg_appointment_type := g_appointment_type_indirect;
            END IF;
        
            g_error := 'CALL PK_VISIT.CREATE_VISIT_NO_COMMIT';
            IF NOT pk_visit.create_visit_no_commit(i_lang                 => i_lang,
                                                   i_id_pat               => i_id_patient,
                                                   i_id_institution       => i_prof.institution,
                                                   i_id_sched             => i_id_schedule,
                                                   i_id_professional      => i_prof,
                                                   i_id_episode           => i_id_episode,
                                                   i_external_cause       => NULL,
                                                   i_health_plan          => NULL,
                                                   i_epis_type            => l_id_epis_type,
                                                   i_dep_clin_serv        => l_id_dep_clin_serv,
                                                   i_origin               => NULL,
                                                   i_flg_ehr              => g_flg_ehr_normal,
                                                   i_dt_begin             => g_sysdate_tstz,
                                                   i_flg_appointment_type => l_flg_appointment_type,
                                                   i_transaction_id       => l_transaction_id,
                                                   o_episode              => o_episode,
                                                   o_error                => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        ------------------------------------
        -- update schedule with id_episode, since pk_visit.create_visit only updates epis_info with id_schedule
        IF o_episode IS NOT NULL
           AND i_id_schedule IS NOT NULL
        THEN
            ------------------------------------
            -- schedule does not have denormalized package (ts_schedule)
            UPDATE schedule s
               SET s.id_episode = o_episode
             WHERE s.id_schedule = i_id_schedule;
        
            ------------------------------------
            -- start the visit
            IF (i_flg_context = g_flg_context_access AND i_access_flg_type = g_access_create_contact)
               OR (i_flg_context = g_flg_context_new_patient AND i_access_flg_type != g_access_new_indirect_contact)
            THEN
                g_error := 'PK_VISIT.SET_VISIT_INIT';
                IF NOT pk_visit.set_visit_init(i_lang       => i_lang,
                                               i_id_episode => o_episode,
                                               i_prof       => i_prof,
                                               o_error      => o_error)
                THEN
                    RAISE g_exception;
                ELSE
                    ------------------------------------
                    -- update episode
                    g_error := 'TS_EPISODE.UPD';
                    ts_episode.upd(id_episode_in    => o_episode,
                                   dt_begin_tstz_in => g_sysdate_tstz,
                                   rows_out         => l_rowids_e);
                
                    g_error := 'T_DATA_GOV_MNT.PROCESS_UPDATE EPISODE';
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'EPISODE',
                                                  i_rowids     => l_rowids_e,
                                                  o_error      => o_error);
                END IF;
            END IF;
        END IF;
    
        --remote scheduler commit. Doesn't affect PFH.
        IF i_transaction_id IS NULL
           AND l_transaction_id IS NOT NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            -- undo changes
            pk_utils.undo_changes;
            --remote scheduler rollback. Doesn't affect PFH.
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_EHR_ACCESS',
                                   'CREATE_EHR_ACCESS_NEW_CON_NO_C');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- undo changes
                pk_utils.undo_changes;
                -- return failure
            
                --remote scheduler rollback. Doesn't affect PFH.
                pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
                RETURN FALSE;
            END;
    END create_ehr_access_new_con_no_c;

    /********************************************************************************************
    * Prepares and creates the EHR access for a scheduled espisode.
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_id_episode          episode id
    * @param i_id_dep_clin_serv    department clinical service id
    * @param i_dt_begin            begin date
    * @param i_transaction_id      Scheduler 3.0 transaction ID
    *
    * @param o_id_scheduled        scheduled id - output value
    * @param o_error               error message
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2009-11-10
    * @author Pedro Teixeira
    ********************************************************************************************/
    FUNCTION create_ehr_access_new_schedule
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_dt_begin         IN episode.dt_begin_tstz%TYPE,
        i_prof_category    IN category.flg_type%TYPE,
        i_flg_context      IN ehr_access_context.flg_context%TYPE,
        i_transaction_id   IN VARCHAR2,
        i_id_sch_event     IN sch_event.id_sch_event%TYPE,
        o_id_schedule      OUT schedule.id_schedule%TYPE,
        o_flg_show         OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT create_ehr_access_new_schedule(i_lang             => i_lang,
                                              i_prof             => i_prof,
                                              i_id_patient       => i_id_patient,
                                              i_id_episode       => i_id_episode,
                                              i_id_dep_clin_serv => i_id_dep_clin_serv,
                                              i_dt_begin         => i_dt_begin,
                                              i_prof_category    => i_prof_category,
                                              i_flg_context      => i_flg_context,
                                              i_transaction_id   => i_transaction_id,
                                              i_id_sch_event     => i_id_sch_event,
                                              i_id_prof          => i_prof.id,
                                              o_id_schedule      => o_id_schedule,
                                              o_flg_show         => o_flg_show,
                                              o_msg_title        => o_msg_title,
                                              o_msg              => o_msg,
                                              o_button           => o_button,
                                              o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    END create_ehr_access_new_schedule;

    FUNCTION create_ehr_access_new_schedule
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_dt_begin         IN episode.dt_begin_tstz%TYPE,
        i_prof_category    IN category.flg_type%TYPE,
        i_flg_context      IN ehr_access_context.flg_context%TYPE,
        i_transaction_id   IN VARCHAR2,
        i_id_sch_event     IN sch_event.id_sch_event%TYPE,
        i_id_prof          IN professional.id_professional%TYPE,
        o_id_schedule      OUT schedule.id_schedule%TYPE,
        o_flg_show         OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_proceed  VARCHAR2(200);
        l_id_sch_event sch_event.id_sch_event%TYPE;
    
        l_nursing_sched_minutes NUMBER;
        --Scheduler 3.0 variables
        l_transaction_id  VARCHAR2(4000);
        l_ids_schedule    table_number;
        l_id_schedule_ext sch_api_map_ids.id_schedule_ext%TYPE;
    BEGIN
    
        -- get g_sc_nursing_sched_minutes
        l_nursing_sched_minutes := CAST(pk_sysconfig.get_config(g_sc_nursing_sched_minutes, i_prof) AS NUMBER);
        IF l_nursing_sched_minutes IS NULL
        THEN
            l_nursing_sched_minutes := 15;
        END IF;
    
        -- get sch_event for the schedule creation
        g_error := 'GET_SCHED_EVENT';
        IF i_id_sch_event IS NULL
        THEN
            l_id_sch_event := get_sched_event(i_lang, i_prof, i_flg_context);
        ELSE
            l_id_sch_event := i_id_sch_event;
        END IF;
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        -- create the schedule 
        g_error := 'UPDATE SCHEDULE_OUTP';
        IF NOT pk_schedule_api_upstream.create_schedule(i_lang             => i_lang,
                                                        i_prof             => i_prof,
                                                        i_event_id         => l_id_sch_event,
                                                        i_professional_id  => i_id_prof,
                                                        i_id_patient       => i_id_patient,
                                                        i_id_dep_clin_serv => i_id_dep_clin_serv,
                                                        i_dt_begin_tstz    => i_dt_begin,
                                                        i_dt_end_tstz      => i_dt_begin +
                                                                              numtodsinterval(l_nursing_sched_minutes,
                                                                                              'MINUTE'),
                                                        i_flg_vacancy      => pk_schedule_common.g_sched_vacancy_routine,
                                                        i_id_episode       => i_id_episode,
                                                        i_flg_rqst_type    => pk_schedule.g_def_sched_flg_req_type_nurse,
                                                        i_flg_sch_via      => pk_schedule.g_default_flg_sch_via,
                                                        i_sch_notes        => NULL,
                                                        i_transaction_id   => l_transaction_id,
                                                        o_ids_schedule     => l_ids_schedule,
                                                        o_id_schedule_ext  => l_id_schedule_ext,
                                                        o_flg_proceed      => l_flg_proceed,
                                                        o_flg_show         => o_flg_show,
                                                        o_msg_title        => o_msg_title,
                                                        o_msg              => o_msg,
                                                        o_button           => o_button,
                                                        o_error            => o_error)
        
        THEN
            RETURN FALSE;
        END IF;
    
        IF o_flg_show = g_yes
        THEN
            o_error := t_error_out(SQLCODE, o_msg, NULL, o_msg_title, NULL, NULL, o_msg_title, NULL);
            RETURN FALSE;
        END IF;
    
        --atribui o schedule na lista ao schedule de saida
        o_id_schedule := l_ids_schedule(l_ids_schedule.count);
    
        IF i_transaction_id IS NULL
           AND l_transaction_id IS NOT NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EHR_ACCESS',
                                              'CREATE_EHR_ACCESS_NEW_SCHEDULE',
                                              o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
        
    END create_ehr_access_new_schedule;

    /**
    * Records the access to a patient EHR, by a professional.
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_id_episode          episode id
    * @param i_id_schedule         scheduled id
    * @param i_access_type         granted access type (B - Break the Glass
    *                                                   F - Free Access
    *                                                   N - Not allowed)
    * @param i_id_access_reason    list of access reasons used by this professional.
    * @param i_id_dep_clin_serv    selected dep_clin_serv
    * @param i_access_text         access reason free text
    * @param i_transaction_id     Scheduler 3.0 transaction ID
    *
    * @param o_error               error message
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2008-05-21
    * @version v2.4.3
    * @author Sérgio Santos
    */
    FUNCTION create_ehr_access
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_access_area      IN ehr_access_context.id_ehr_access_context%TYPE,
        i_access_type      IN VARCHAR2,
        i_id_access_reason IN table_number,
        i_access_text      IN VARCHAR2,
        i_new_ehr_event    IN VARCHAR2,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_episode          OUT episode.id_episode%TYPE,
        o_flg_show         OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET ACCESS AREA FLAG';
        IF NOT create_ehr_access(i_lang             => i_lang,
                                 i_prof             => i_prof,
                                 i_id_patient       => i_id_patient,
                                 i_id_episode       => i_id_episode,
                                 i_id_schedule      => i_id_schedule,
                                 i_access_area      => i_access_area,
                                 i_access_type      => i_access_type,
                                 i_id_access_reason => i_id_access_reason,
                                 i_access_text      => i_access_text,
                                 i_new_ehr_event    => i_new_ehr_event,
                                 i_id_dep_clin_serv => i_id_dep_clin_serv,
                                 i_id_sch_event     => NULL,
                                 o_episode          => o_episode,
                                 o_flg_show         => o_flg_show,
                                 o_msg_title        => o_msg_title,
                                 o_msg              => o_msg,
                                 o_button           => o_button,
                                 o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN g_exception THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_EHR_ACCESS', 'CREATE_EHR_ACCESS');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- undo changes
                pk_utils.undo_changes;
                -- return failure
                --remote scheduler rollback. Doesn't affect PFH.                
                RETURN FALSE;
            END;
    END create_ehr_access;
    FUNCTION create_ehr_access
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_access_area      IN ehr_access_context.id_ehr_access_context%TYPE,
        i_access_type      IN VARCHAR2,
        i_id_access_reason IN table_number,
        i_access_text      IN VARCHAR2,
        i_new_ehr_event    IN VARCHAR2,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_sch_event     IN sch_event.id_sch_event%TYPE,
        o_episode          OUT episode.id_episode%TYPE,
        o_flg_show         OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_access_flg_type    ehr_access_context.flg_type%TYPE;
        l_access_flg_context ehr_access_context.flg_context%TYPE;
        l_episode            episode.id_episode%TYPE;
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
    BEGIN
        IF NOT create_ehr_access(i_lang             => i_lang,
                                 i_prof             => i_prof,
                                 i_id_patient       => i_id_patient,
                                 i_id_episode       => i_id_episode,
                                 i_id_schedule      => i_id_schedule,
                                 i_access_area      => i_access_area,
                                 i_access_type      => i_access_type,
                                 i_id_access_reason => i_id_access_reason,
                                 i_access_text      => i_access_text,
                                 i_new_ehr_event    => i_new_ehr_event,
                                 i_id_dep_clin_serv => i_id_dep_clin_serv,
                                 i_id_sch_event     => NULL,
                                 i_id_prof          => i_prof.id,
                                 o_episode          => o_episode,
                                 o_flg_show         => o_flg_show,
                                 o_msg_title        => o_msg_title,
                                 o_msg              => o_msg,
                                 o_button           => o_button,
                                 o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN g_exception THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_EHR_ACCESS', 'CREATE_EHR_ACCESS');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- undo changes
                pk_utils.undo_changes;
                -- return failure
                --remote scheduler rollback. Doesn't affect PFH.                
                RETURN FALSE;
            END;
    END create_ehr_access;

    FUNCTION create_ehr_access
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_access_area      IN ehr_access_context.id_ehr_access_context%TYPE,
        i_access_type      IN VARCHAR2,
        i_id_access_reason IN table_number,
        i_access_text      IN VARCHAR2,
        i_new_ehr_event    IN VARCHAR2,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_sch_event     IN sch_event.id_sch_event%TYPE,
        i_id_prof          IN professional.id_professional%TYPE,
        o_episode          OUT episode.id_episode%TYPE,
        o_flg_show         OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_access_flg_type    ehr_access_context.flg_type%TYPE;
        l_access_flg_context ehr_access_context.flg_context%TYPE;
        l_episode            episode.id_episode%TYPE;
    
        l_status episode.flg_status%TYPE;
    
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, i_prof);
    
        g_error := 'GET ACCESS AREA FLAG';
        SELECT eac.flg_type, eac.flg_context
          INTO l_access_flg_type, l_access_flg_context
          FROM ehr_access_context eac
         WHERE eac.id_ehr_access_context = i_access_area
           AND eac.flg_context IN (g_flg_context_access, g_flg_context_new_patient)
           AND eac.flg_available = g_yes;
    
        IF l_access_flg_type = g_access_ehr
           AND l_access_flg_context = g_flg_context_access
        THEN
            IF NOT create_ehr_access_ehr(i_lang             => i_lang,
                                         i_prof             => i_prof,
                                         i_id_patient       => i_id_patient,
                                         i_id_episode       => i_id_episode,
                                         i_id_schedule      => i_id_schedule,
                                         i_id_dep_clin_serv => i_id_dep_clin_serv,
                                         i_transaction_id   => l_transaction_id,
                                         o_episode          => l_episode,
                                         o_error            => o_error)
            THEN
                RAISE g_exception;
            ELSE
                o_episode := l_episode;
            END IF;
        ELSIF l_access_flg_type = g_access_scheduled
              AND l_access_flg_context = g_flg_context_access
        THEN
            IF NOT create_ehr_access_schedule(i_lang           => i_lang,
                                              i_prof           => i_prof,
                                              i_id_patient     => i_id_patient,
                                              i_id_episode     => i_id_episode,
                                              i_id_schedule    => i_id_schedule,
                                              i_transaction_id => l_transaction_id,
                                              o_episode        => l_episode,
                                              o_error          => o_error)
            THEN
                RAISE g_exception;
            ELSE
                o_episode := l_episode;
            END IF;
        ELSIF (l_access_flg_type = g_access_create_contact AND l_access_flg_context = g_flg_context_access)
        THEN
            IF NOT create_ehr_access_new_contact(i_lang             => i_lang,
                                                 i_prof             => i_prof,
                                                 i_id_patient       => i_id_patient,
                                                 i_id_episode       => i_id_episode,
                                                 i_id_schedule      => i_id_schedule,
                                                 i_id_dep_clin_serv => i_id_dep_clin_serv,
                                                 i_access_flg_type  => l_access_flg_type,
                                                 i_flg_context      => l_access_flg_context,
                                                 i_transaction_id   => l_transaction_id,
                                                 i_id_sch_event     => i_id_sch_event,
                                                 i_id_prof          => i_id_prof,
                                                 o_episode          => l_episode,
                                                 o_flg_show         => o_flg_show,
                                                 o_msg_title        => o_msg_title,
                                                 o_msg              => o_msg,
                                                 o_button           => o_button,
                                                 o_error            => o_error)
            THEN
                RAISE g_exception;
            ELSE
                o_episode := l_episode;
            END IF;
        ELSIF (l_access_flg_type = g_access_new_indirect_contact AND l_access_flg_context = g_flg_context_access)
              OR (l_access_flg_context = g_flg_context_new_patient)
        THEN
            IF NOT create_ehr_access_new_contact(i_lang             => i_lang,
                                                 i_prof             => i_prof,
                                                 i_id_patient       => i_id_patient,
                                                 i_id_episode       => i_id_episode,
                                                 i_id_schedule      => i_id_schedule,
                                                 i_id_dep_clin_serv => i_id_dep_clin_serv,
                                                 i_access_flg_type  => l_access_flg_type,
                                                 i_flg_context      => l_access_flg_context,
                                                 i_transaction_id   => l_transaction_id,
                                                 i_id_sch_event     => i_id_sch_event,
                                                 o_episode          => l_episode,
                                                 o_flg_show         => o_flg_show,
                                                 o_msg_title        => o_msg_title,
                                                 o_msg              => o_msg,
                                                 o_button           => o_button,
                                                 o_error            => o_error)
            THEN
                RAISE g_exception;
            ELSE
                o_episode := l_episode;
            END IF;
        END IF;
    
        IF i_id_access_reason IS NOT NULL
           AND i_id_access_reason.count > 0
        THEN
        
            IF l_episode IS NULL
            THEN
                l_episode := i_id_episode;
            END IF;
        
            IF NOT log_access(i_lang             => i_lang,
                              i_prof             => i_prof,
                              i_id_patient       => i_id_patient,
                              i_id_episode       => l_episode,
                              i_access_type      => i_access_type,
                              i_id_access_reason => i_id_access_reason,
                              i_access_text      => i_access_text,
                              o_error            => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        IF o_episode IS NULL
           AND i_id_episode IS NOT NULL
        THEN
            o_episode := i_id_episode;
        END IF;
    
        BEGIN
            SELECT e.flg_status
              INTO l_status
              FROM episode e
             WHERE e.id_episode = i_id_episode
               AND e.flg_status = pk_alert_constant.g_inactive;
        
            g_error := 'CALL TO PK_IA_EVENT_COMMON.INACTIVE_EPISODE_EHR_ACCESS';
            pk_ia_event_common.inactive_episode_ehr_access(i_id_institution => i_prof.institution,
                                                           i_id_episode     => i_id_episode);
        
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        -- remote commit    
        pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            -- undo changes
            pk_utils.undo_changes;
            --remote scheduler rollback. Doesn't affect PFH.
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_EHR_ACCESS', 'CREATE_EHR_ACCESS');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- undo changes
                pk_utils.undo_changes;
                -- return failure
                --remote scheduler rollback. Doesn't affect PFH.
                pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
                RETURN FALSE;
            END;
    END create_ehr_access;

    /**
    * Records the access to a patient EHR, by a professional. Used inside pk_schedule_api_downstream.create_schedule
    * or any other function that needs to call create_ehr_access. 
    * The original create_ehr_access is invoked by the flash code
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_id_episode          episode id
    * @param i_id_schedule         scheduled id
    * @param i_access_type         granted access type (B - Break the Glass
    *                                                   F - Free Access
    *                                                   N - Not allowed)
    * @param i_id_access_reason    list of access reasons used by this professional.
    * @param i_id_dep_clin_serv    selected dep_clin_serv
    * @param i_access_text         access reason free text
    *
    * @param o_error               error message
    *
    * @return              true if sucess, false otherwise
    *
    * @date     24-05-2011
    * @version  2.6.1.1
    * @author  Telmo 
    */
    FUNCTION create_ehr_access_no_commit
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_access_area      IN ehr_access_context.id_ehr_access_context%TYPE,
        i_access_type      IN VARCHAR2,
        i_id_access_reason IN table_number,
        i_access_text      IN VARCHAR2,
        i_new_ehr_event    IN VARCHAR2,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_transaction_id   IN VARCHAR2,
        o_episode          OUT episode.id_episode%TYPE,
        o_flg_show         OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_access_flg_type    ehr_access_context.flg_type%TYPE;
        l_access_flg_context ehr_access_context.flg_context%TYPE;
        l_episode            episode.id_episode%TYPE;
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        g_error := 'GET ACCESS AREA FLAG';
        SELECT eac.flg_type, eac.flg_context
          INTO l_access_flg_type, l_access_flg_context
          FROM ehr_access_context eac
         WHERE eac.id_ehr_access_context = i_access_area
           AND eac.flg_context IN (g_flg_context_access, g_flg_context_new_patient)
           AND eac.flg_available = g_yes;
    
        IF l_access_flg_type = g_access_ehr
           AND l_access_flg_context = g_flg_context_access
        THEN
            IF NOT create_ehr_access_ehr_no_c(i_lang             => i_lang,
                                              i_prof             => i_prof,
                                              i_id_patient       => i_id_patient,
                                              i_id_episode       => i_id_episode,
                                              i_id_schedule      => i_id_schedule,
                                              i_id_dep_clin_serv => i_id_dep_clin_serv,
                                              i_transaction_id   => l_transaction_id,
                                              o_episode          => l_episode,
                                              o_error            => o_error)
            THEN
                RAISE g_exception;
            ELSE
                o_episode := l_episode;
            END IF;
        ELSIF l_access_flg_type = g_access_scheduled
              AND l_access_flg_context = g_flg_context_access
        THEN
            IF NOT create_ehr_access_schedul_no_c(i_lang           => i_lang,
                                                  i_prof           => i_prof,
                                                  i_id_patient     => i_id_patient,
                                                  i_id_episode     => i_id_episode,
                                                  i_id_schedule    => i_id_schedule,
                                                  i_transaction_id => l_transaction_id,
                                                  o_episode        => l_episode,
                                                  o_error          => o_error)
            THEN
                RAISE g_exception;
            ELSE
                o_episode := l_episode;
            END IF;
        ELSIF (l_access_flg_type = g_access_new_indirect_contact AND l_access_flg_context = g_flg_context_access)
              OR (l_access_flg_type = g_access_create_contact AND l_access_flg_context = g_flg_context_access)
              OR (l_access_flg_context = g_flg_context_new_patient)
        THEN
            IF NOT create_ehr_access_new_con_no_c(i_lang             => i_lang,
                                                  i_prof             => i_prof,
                                                  i_id_patient       => i_id_patient,
                                                  i_id_episode       => i_id_episode,
                                                  i_id_schedule      => i_id_schedule,
                                                  i_id_dep_clin_serv => i_id_dep_clin_serv,
                                                  i_access_flg_type  => l_access_flg_type,
                                                  i_flg_context      => l_access_flg_context,
                                                  i_transaction_id   => l_transaction_id,
                                                  o_episode          => l_episode,
                                                  o_flg_show         => o_flg_show,
                                                  o_msg_title        => o_msg_title,
                                                  o_msg              => o_msg,
                                                  o_button           => o_button,
                                                  o_error            => o_error)
            THEN
                RAISE g_exception;
            ELSE
                o_episode := l_episode;
            END IF;
        END IF;
    
        IF i_id_access_reason IS NOT NULL
           AND i_id_access_reason.count > 0
        THEN
        
            IF l_episode IS NULL
            THEN
                l_episode := i_id_episode;
            END IF;
        
            IF NOT log_access(i_lang             => i_lang,
                              i_prof             => i_prof,
                              i_id_patient       => i_id_patient,
                              i_id_episode       => l_episode,
                              i_access_type      => i_access_type,
                              i_id_access_reason => i_id_access_reason,
                              i_access_text      => i_access_text,
                              o_error            => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        IF o_episode IS NULL
           AND i_id_episode IS NOT NULL
        THEN
            o_episode := i_id_episode;
        END IF;
    
        -- remote commit    
        IF i_transaction_id IS NULL
           AND l_transaction_id IS NOT NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            -- undo changes
            pk_utils.undo_changes;
            --remote scheduler rollback. Doesn't affect PFH.
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_EHR_ACCESS', 'CREATE_EHR_ACCESS');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- undo changes
                pk_utils.undo_changes;
                -- return failure
                --remote scheduler rollback. Doesn't affect PFH.
                pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
                RETURN FALSE;
            END;
    END create_ehr_access_no_commit;

    /**
    * Gets access areas for a professional
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    *
    * @param o_areas               cursor containing EHR events for this professional
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2008-05-16
    * @version v2.4.3
    * @author sergio.santos
    */
    FUNCTION get_access_areas
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_flg_show   OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_button     OUT VARCHAR2,
        o_areas      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_epis_type_acc   table_number;
        l_grp_insts       table_number;
        l_epis_type_count NUMBER;
    
        l_has_previous VARCHAR2(1 CHAR) := g_no;
        l_has_ongoing  VARCHAR2(1 CHAR) := g_no;
    
        l_has_scheduled            VARCHAR2(1 CHAR) := g_no;
        l_has_new_contact          VARCHAR2(1 CHAR) := g_no;
        l_can_create_sched_contact VARCHAR2(1 CHAR) := g_no;
        l_has_option_do_nothing    VARCHAR2(1 CHAR) := g_no;
        l_allow_sched_without_vac  sch_vacancy_usage.flg_sched_without_vac%TYPE;
    
        l_show_ehr_event VARCHAR2(1 CHAR) := g_no;
    
        -- check if there are previous episodes
        CURSOR c_previous
        (
            l_eta       table_number,
            l_eta_count NUMBER,
            l_insts     table_number
        ) IS
            SELECT DISTINCT g_yes
              FROM episode e, epis_info ei
             WHERE ei.id_episode = e.id_episode
               AND (e.id_epis_type IN (SELECT column_value
                                         FROM TABLE(l_eta)) OR
                   (l_eta_count = 0 AND ei.id_software IN (0, i_prof.software)))
               AND e.id_patient = i_id_patient
               AND (e.id_institution IN (SELECT *
                                           FROM TABLE(l_insts)) OR
                   pk_transfer_institution.check_transfer_access(e.id_episode, i_prof) = g_yes)
               AND e.flg_status IN (g_epis_inactive, g_epis_pending)
               AND e.flg_ehr = g_flg_ehr_normal
               AND rownum <= 1;
    
        -- check if there are ongoing episodes
        CURSOR c_ongoing
        (
            l_eta       table_number,
            l_eta_count NUMBER,
            l_insts     table_number
        ) IS
            SELECT DISTINCT g_yes
              FROM episode e, epis_info ei
             WHERE ei.id_episode = e.id_episode
               AND e.id_patient = i_id_patient
               AND (e.id_epis_type IN (SELECT column_value
                                         FROM TABLE(l_eta)) OR
                   (l_eta_count = 0 AND ei.id_software IN (0, i_prof.software)))
               AND (e.id_institution IN (SELECT *
                                           FROM TABLE(l_insts)) OR
                   pk_transfer_institution.check_transfer_access(e.id_episode, i_prof) = g_yes)
               AND e.flg_status IN (g_epis_active)
               AND e.flg_ehr = g_flg_ehr_normal
               AND rownum <= 1;
    
        --check if there are scheduled episodes
        CURSOR c_scheduled
        (
            l_eta       table_number,
            l_eta_count NUMBER
        ) IS
            SELECT g_yes
              FROM schedule s
              JOIN sch_group sg
                ON (s.id_schedule = sg.id_schedule)
              JOIN schedule_outp so
                ON (s.id_schedule = so.id_schedule)
              JOIN sch_prof_outp spo
                ON (spo.id_schedule_outp = so.id_schedule_outp)
             WHERE sg.id_patient = i_id_patient
               AND s.flg_status != pk_schedule.g_sched_status_cancelled
               AND so.id_epis_type IN (SELECT etsi.id_epis_type
                                         FROM epis_type_soft_inst etsi
                                        WHERE etsi.id_software = i_prof.software
                                          AND etsi.id_institution IN (i_prof.institution, 0))
               AND s.id_schedule NOT IN (SELECT ei.id_schedule
                                           FROM epis_info ei
                                           JOIN episode e
                                             ON (ei.id_episode = e.id_episode)
                                          WHERE ei.id_patient = i_id_patient
                                               --  AND e.flg_ehr IN (g_flg_ehr_scheduled)
                                            AND ei.id_schedule IS NOT NULL)
               AND rownum <= 1
            UNION ALL
            SELECT g_yes
              FROM episode e, epis_info ei
             WHERE ei.id_episode = e.id_episode
               AND (e.id_epis_type IN (SELECT column_value
                                         FROM TABLE(l_eta)) OR
                   (l_eta_count = 0 AND ei.id_software IN (0, i_prof.software)))
               AND nvl(ei.flg_sch_status, 'A') != pk_schedule.g_sched_status_cancelled
               AND e.id_patient = i_id_patient
               AND e.id_institution = i_prof.institution
               AND pk_episode.get_soft_by_epis_type(e.id_epis_type, e.id_institution) = i_prof.software
               AND e.flg_status IN (g_epis_active)
               AND e.flg_ehr = g_flg_ehr_scheduled
               AND rownum <= 1;
    
        CURSOR c_new_contact IS
            SELECT DISTINCT g_yes
              FROM prof_cat pc, category c
             WHERE pc.id_category = c.id_category
               AND pc.id_professional = i_prof.id
               AND pc.id_institution = i_prof.institution
               AND i_prof.software = g_software_care
               AND c.flg_type IN (g_doctor_category, g_nurse_category);
    
        CURSOR c_create_sched_contact IS
            SELECT DISTINCT g_yes
              FROM prof_cat pc, category c
             WHERE pc.id_category = c.id_category
               AND pc.id_professional = i_prof.id
               AND pc.id_institution = i_prof.institution
               AND i_prof.software IN (g_software_care, g_software_outpatient, g_software_pp)
               AND c.flg_type IN (g_doctor_category, g_nurse_category);
    
    BEGIN
        SELECT column_value
          BULK COLLECT
          INTO l_grp_insts
          FROM TABLE(pk_list.tf_get_all_inst_group(i_prof.institution, g_inst_grp_flg_rel_adt));
        /*    
        SELECT eta.id_epis_type
          BULK COLLECT
          INTO l_epis_type_acc
          FROM epis_type_access eta, prof_profile_template ppt
         WHERE eta.id_institution = decode((SELECT eta.id_epis_type
                                             FROM epis_type_access eta, prof_profile_template ppt
                                            WHERE eta.id_institution = i_prof.institution
                                              AND ppt.id_profile_template = eta.id_profile_template
                                              AND ppt.id_professional = i_prof.id
                                              AND ppt.id_institution = eta.id_institution
                                              AND ppt.id_software = i_prof.software
                                              AND rownum <= 1),
                                           NULL,
                                           0,
                                           i_prof.institution)
           AND ppt.id_profile_template = eta.id_profile_template
           AND ppt.id_professional = i_prof.id
           AND ppt.id_institution = i_prof.institution
           AND ppt.id_software = i_prof.software
           AND eta.id_epis_type != 0;*/
        l_epis_type_acc   := pk_episode.get_epis_type_access(i_prof, pk_alert_constant.g_no);
        l_epis_type_count := l_epis_type_acc.count;
    
        g_error := 'OPEN c_previous';
        OPEN c_previous(l_epis_type_acc, l_epis_type_count, l_grp_insts);
        FETCH c_previous
            INTO l_has_previous;
        CLOSE c_previous;
    
        g_error := 'OPEN c_ongoing';
        OPEN c_ongoing(l_epis_type_acc, l_epis_type_count, l_grp_insts);
        FETCH c_ongoing
            INTO l_has_ongoing;
        CLOSE c_ongoing;
    
        g_error := 'OPEN c_scheduled';
        OPEN c_scheduled(l_epis_type_acc, l_epis_type_count);
        FETCH c_scheduled
            INTO l_has_scheduled;
        CLOSE c_scheduled;
    
        g_error := 'OPEN c_new_contact';
        OPEN c_new_contact;
        FETCH c_new_contact
            INTO l_has_new_contact;
        CLOSE c_new_contact;
    
        IF has_ehr_permission(i_lang, i_prof, i_id_patient)
        THEN
            l_show_ehr_event := g_yes;
        ELSE
            l_show_ehr_event := g_no;
        END IF;
    
        ---------------------------------------------------
        g_error := 'OPEN c_create_sched_contact';
        OPEN c_create_sched_contact;
        FETCH c_create_sched_contact
            INTO l_can_create_sched_contact;
        CLOSE c_create_sched_contact;
    
        ---------------------------------------------------
        IF l_can_create_sched_contact = g_yes
        THEN
            IF has_sched_permission(i_lang, i_prof, g_flg_context_access)
            THEN
                l_allow_sched_without_vac := g_yes;
            ELSE
                l_allow_sched_without_vac := g_no;
            END IF;
        ELSE
            l_allow_sched_without_vac := g_no;
        END IF;
    
        ---------------------------------------------------
        -- option "Não fazer mais nada" vai estar sempre activa em todos os perfis
        l_has_option_do_nothing := g_yes;
    
        ---------------------------------------------------
        g_error := 'OPEN o_areas';
        OPEN o_areas FOR
            SELECT eac.id_ehr_access_context access_id,
                   pk_translation.get_translation(i_lang, eac.code_ehr_access_context) access_desc,
                   eac.flg_type access_type,
                   decode(eac.flg_type,
                          g_access_previous,
                          l_has_previous,
                          g_access_ongoing,
                          l_has_ongoing,
                          g_access_scheduled,
                          l_has_scheduled,
                          g_access_ehr,
                          l_show_ehr_event,
                          g_access_new_indirect_contact,
                          l_has_new_contact,
                          g_access_create_contact,
                          l_allow_sched_without_vac,
                          g_access_create_schedule,
                          l_can_create_sched_contact,
                          g_access_goto_patient_area,
                          g_yes,
                          g_access_do_nothing,
                          l_has_option_do_nothing) flg_active,
                   rank
              FROM ehr_access_context eac
             WHERE eac.id_ehr_access_context IN (SELECT MAX(e2.id_ehr_access_context)
                                                   FROM ehr_access_context_soft e2
                                                   JOIN ehr_access_context e1
                                                     ON (e1.id_ehr_access_context = e2.id_ehr_access_context)
                                                  WHERE e2.id_software IN (0, i_prof.software)
                                                    AND e1.flg_context = g_flg_context_access
                                                    AND e1.flg_available = g_yes
                                                  GROUP BY e1.flg_type)
               AND (eac.flg_type <> g_access_ehr OR l_show_ehr_event = g_yes)
               AND eac.flg_context = g_flg_context_access
               AND eac.flg_available = g_yes
             ORDER BY rank;
    
        IF l_has_previous = g_no
           AND l_has_ongoing = g_no
           AND l_has_scheduled = g_no
           AND l_show_ehr_event = g_no
           AND l_has_new_contact = g_no
           AND l_allow_sched_without_vac = g_no
           AND l_can_create_sched_contact = g_no
        THEN
            o_flg_show  := 'Y';
            o_msg       := pk_message.get_message(i_lang, 'EHR_ACCESS_T043');
            o_msg_title := pk_message.get_message(i_lang, 'EHR_ACCESS_T044');
            o_button    := 'R';
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_EHR_ACCESS', 'GET_ACCESS_AREAS');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- fechar os cursores
                pk_types.open_my_cursor(o_areas);
                -- return failure
                RETURN FALSE;
            END;
    END get_access_areas;

    /**
    * Returns a String with all the access reasons for an ehr access
    *
    * @param i_lang         Language identifier.
    * @param i_patient      Patient id
    * @param i_episode      The title of the visit type.
    * @param i_sep          String separator
    *
    * @return  the string containing all the access reasons
    *
    * @author   Sérgio Santos
    * @version  2.4.3
    * @since    2008/05/20
    */
    FUNCTION get_access_reason_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_sep     IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_id_ehr_access_log    ehr_access_log.id_ehr_access_log%TYPE;
        l_ehr_access_free_text ehr_access_log.access_reason_text%TYPE;
        l_access_array         table_varchar;
        l_return_str           VARCHAR2(4000) := NULL;
    BEGIN
        SELECT tbl.id_ehr_access_log, tbl.access_reason_text
          INTO l_id_ehr_access_log, l_ehr_access_free_text
          FROM (SELECT eal.id_ehr_access_log, eal.access_reason_text, eal.dt_log
                  FROM ehr_access_log eal
                 WHERE eal.id_patient = i_patient
                   AND eal.id_episode = i_episode
                 ORDER BY eal.dt_log DESC) tbl
         WHERE rownum <= 1;
    
        SELECT pk_translation.get_translation(i_lang, ear.code_ehr_access_reason)
          BULK COLLECT
          INTO l_access_array
          FROM ehr_access_log_reason ealr
          JOIN ehr_access_reason ear
            ON (ealr.id_ehr_access_reason = ear.id_ehr_access_reason)
         WHERE ealr.id_ehr_access_log = l_id_ehr_access_log;
    
        l_return_str := '';
    
        FOR i IN 1 .. l_access_array.count
        LOOP
            l_return_str := l_return_str || l_access_array(i);
            IF i <> l_access_array.count
            THEN
                l_return_str := l_return_str || i_sep;
            END IF;
        END LOOP;
    
        IF l_ehr_access_free_text IS NOT NULL
        THEN
            l_return_str := l_return_str || i_sep || l_ehr_access_free_text;
        END IF;
    
        RETURN l_return_str;
    END get_access_reason_desc;

    /**
    * Logs an ehr access to a previous episode
    *
    * @param i_lang         Language identifier.
    * @param i_prof         Professional identification
    * @param i_patient      Patient id
    * @param i_episode      The title of the visit type.
    * @param i_sep          String separator
    *
    * @return   true if sucess, false otherwise
    *
    * @author   Sérgio Santos
    * @version  2.4.3
    * @since    2008/05/21
    */
    FUNCTION log_access
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_access_type      IN VARCHAR2,
        i_id_access_reason IN table_number,
        i_access_text      IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ehr_access_log_nextval NUMBER;
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'seq_ehr_access_log.NEXTVAL';
        SELECT seq_ehr_access_log.nextval
          INTO l_ehr_access_log_nextval
          FROM dual;
    
        g_error := 'INSERT INTO ehr_access_log';
        INSERT INTO ehr_access_log
            (id_ehr_access_log,
             id_professional,
             id_institution,
             id_software,
             id_patient,
             id_episode,
             flg_type,
             id_dep_clin_serv,
             access_reason_text,
             dt_log)
        VALUES
            (l_ehr_access_log_nextval,
             i_prof.id,
             i_prof.institution,
             i_prof.software,
             i_id_patient,
             i_id_episode,
             i_access_type,
             NULL,
             i_access_text,
             g_sysdate_tstz);
    
        g_error := 'INSERT INTO ehr_access_log_reason';
        FOR i IN 1 .. i_id_access_reason.count
        LOOP
            INSERT INTO ehr_access_log_reason
                (id_ehr_access_log, id_ehr_access_reason)
            VALUES
                (l_ehr_access_log_nextval, i_id_access_reason(i));
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_EHR_ACCESS', 'LOG_ACCESS');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- undo changes
                pk_utils.undo_changes;
                -- return failure
                RETURN FALSE;
            END;
    END log_access;

    /**
    * Checks if a professional has access to the EHR ACCESS MANAGER
    *
    * @param i_lang         Language identifier.
    * @param i_prof         Professional identification
    * @param o_val          return 'Y' if the professional has access to the EHR ACCESS MANAGER, 'N' otherwise
    
    * @return   true if sucess, false otherwise
    *
    * @author   Sérgio Santos
    * @version  2.4.3
    * @since    2008/08/04
    */
    FUNCTION has_ehr_manager
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_val   OUT VARCHAR2,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        --check if the professional has access to the EHR manager
        g_error := 'Professional category not parameterized in ehr_access_category';
        SELECT flg_has_ehr_access
          INTO o_val
          FROM (SELECT eay.flg_has_ehr_access
                  FROM ehr_access_category eay
                 WHERE eay.id_category = (SELECT pc.id_category
                                            FROM prof_cat pc
                                           WHERE pc.id_professional = i_prof.id
                                             AND pc.id_institution = i_prof.institution)
                   AND eay.id_institution IN (0, i_prof.institution)
                   AND eay.id_software IN (0, i_prof.software)
                 ORDER BY eay.id_software DESC, eay.id_institution DESC)
         WHERE rownum = 1;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_EHR_ACCESS', 'HAS_EHR_MANAGER');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- return failure
                RETURN FALSE;
            END;
    END has_ehr_manager;

    /**
    * Checks if must show other popups (Visit init, patient responsability)
    *
    * @param i_lang         Language identifier.
    * @param i_prof         Professional identification
    * @param i_schedule     Schedule id (if available)
    * @param i_episode      Episode id (if available)
    * @param o_val          return 'Y' case must show other popups, 'N' otherwise
    * @param o_error        Error message
    *
    * @return   true if sucess, false otherwise
    *
    * @author   Sérgio Santos
    * @version  2.4.3
    * @since    2008/08/04
    */
    FUNCTION show_other_popups
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_schedule IN schedule.id_schedule%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        o_val      OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        o_val := g_no;
    
        IF i_episode IS NULL
           AND i_schedule IS NULL
        THEN
            o_val := g_no;
            RETURN TRUE;
        END IF;
    
        IF i_episode IS NULL
        THEN
            o_val := g_no;
            RETURN TRUE;
        ELSE
            g_error := 'SEL FROM EPIS';
            SELECT decode(e.flg_ehr,
                          g_flg_ehr_scheduled,
                          decode(e.id_epis_type, pk_alert_constant.g_epis_type_home_health_care, g_yes, g_no),
                          g_yes)
              INTO o_val
              FROM episode e
             WHERE e.id_episode = i_episode;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_EHR_ACCESS', 'SHOW_OTHER_POPUPS');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- return failure
                RETURN FALSE;
            END;
    END show_other_popups;

    FUNCTION check_area_create_permission
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_area    IN VARCHAR2,
        o_val     OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_val VARCHAR2(1000 CHAR);
    
    BEGIN
    
        l_val := pk_ehr_access.check_area_create_permission(i_lang         => i_lang,
                                                            i_professional => i_prof.id,
                                                            i_institution  => i_prof.institution,
                                                            i_software     => i_prof.software,
                                                            i_episode      => i_episode,
                                                            i_area         => i_area);
    
        o_val := l_val;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              'CHECK_AREA_CREATE_PERMISSION',
                                              o_error);
            RETURN FALSE;
    END check_area_create_permission;

    FUNCTION check_area_create_permission
    (
        i_lang         IN language.id_language%TYPE,
        i_professional IN professional.id_professional%TYPE,
        i_institution  IN institution.id_institution%TYPE,
        i_software     IN software.id_software%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_area         IN VARCHAR2
    ) RETURN VARCHAR2 result_cache IS
    
        l_prof_cs_valid NUMBER := 0;
        --episode info variables
        l_epis_flg_ehr    episode.flg_ehr%TYPE;
        l_epis_flg_status episode.flg_status%TYPE;
        l_epis_cs         episode.id_clinical_service%TYPE;
        l_id_pat          patient.id_patient%TYPE;
    
        --area info variables
        l_sched_create_perm_sc    ehr_access_area_def.sched_create_perm_sc%TYPE;
        l_ehr_create_perm_sc      ehr_access_area_def.ehr_create_perm_sc%TYPE;
        l_inactive_create_perm_sc ehr_access_area_def.inactive_create_perm_sc%TYPE;
        l_cons_create_perm_sc     ehr_access_area_def.cons_create_perm_sc%TYPE;
    
        --access permitions variables
        l_sched_create_perm    sys_config.value%TYPE;
        l_ehr_create_perm      sys_config.value%TYPE;
        l_inactive_create_perm sys_config.value%TYPE;
        l_consult_create_perm  sys_config.value%TYPE;
    
        l_inactive_pat VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_prof         profissional := profissional(i_professional, i_institution, i_software);
        o_val          VARCHAR2(1000 CHAR);
    BEGIN
    
        --if we dont have an episode, we will not allow new records
        IF i_episode IS NULL
        THEN
            o_val := g_no;
            RETURN o_val;
        END IF;
    
        --get information about the episode
        g_error := 'GET EPISODE INFORMATION';
        SELECT e.flg_status, e.flg_ehr, e.id_clinical_service, e.id_patient
          INTO l_epis_flg_status, l_epis_flg_ehr, l_epis_cs, l_id_pat
          FROM episode e
         WHERE e.id_episode = i_episode;
    
        ---inactive patient (don´t create a inp episode or oris episode)
    
        IF (i_area IN (g_area_oris_episode, g_area_inp_episode))
        THEN
            l_inactive_pat := pk_patient.get_pat_has_inactive(i_lang, l_prof, l_id_pat);
        END IF;
    
        IF (l_inactive_pat = pk_alert_constant.g_no)
        THEN
            --get area information
            g_error := 'GET AREA INFORMATION';
            SELECT e.sched_create_perm_sc, e.ehr_create_perm_sc, e.inactive_create_perm_sc, e.cons_create_perm_sc
              INTO l_sched_create_perm_sc, l_ehr_create_perm_sc, l_inactive_create_perm_sc, l_cons_create_perm_sc
              FROM ehr_access_area_def e
             WHERE e.area = i_area;
        ELSE
            l_sched_create_perm_sc    := pk_alert_constant.g_no;
            l_ehr_create_perm_sc      := pk_alert_constant.g_no;
            l_inactive_create_perm_sc := pk_alert_constant.g_no;
            l_cons_create_perm_sc     := pk_alert_constant.g_no;
        END IF;
    
        -- 2011/06/06 RMGM: if is a valid episode
        IF l_epis_cs IS NOT NULL
        THEN
            -- 2011/06/06 RMGM: check if is a speciality physician or a consultant physician
            SELECT nvl(COUNT(*), 0)
              INTO l_prof_cs_valid
              FROM prof_dep_clin_serv pdcs
             INNER JOIN dep_clin_serv dcs
                ON (dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv AND dcs.flg_available = 'Y')
             INNER JOIN department s
                ON (s.id_department = dcs.id_department AND s.id_institution = pdcs.id_institution AND
                   s.flg_available = g_yes)
             INNER JOIN clinical_service cs
                ON (cs.id_clinical_service = dcs.id_clinical_service AND cs.flg_available = g_yes)
             INNER JOIN dept d
                ON (d.id_dept = s.id_dept AND d.id_institution = s.id_institution AND d.flg_available = g_yes)
             INNER JOIN software_dept sd
                ON (sd.id_dept = d.id_dept AND sd.id_software = l_prof.software)
             WHERE pdcs.id_professional = l_prof.id
               AND pdcs.id_institution = l_prof.institution
               AND dcs.id_clinical_service = l_epis_cs
               AND pdcs.flg_status = 'S';
        
        END IF;
    
        --get permissions from sys_config
        g_error                := 'GET PERMISSIONS FROM SYS_CONFIG';
        l_sched_create_perm    := pk_sysconfig.get_config(l_sched_create_perm_sc, l_prof);
        l_ehr_create_perm      := pk_sysconfig.get_config(l_ehr_create_perm_sc, l_prof);
        l_inactive_create_perm := pk_sysconfig.get_config(l_inactive_create_perm_sc, l_prof);
        l_consult_create_perm  := pk_sysconfig.get_config(l_cons_create_perm_sc, l_prof);
    
        --if is an schedule, ehr or inactive episode, we check the permission to create records
        -- 2011/06/08 RMGM: add validation sequence to consultant
    
        IF l_prof_cs_valid = 0
           AND l_consult_create_perm != g_yes
        THEN
            o_val := l_consult_create_perm;
        ELSIF l_epis_flg_ehr = g_flg_ehr_ehr
        THEN
            o_val := l_ehr_create_perm;
        ELSIF l_epis_flg_ehr = g_flg_ehr_normal
              AND l_epis_flg_status = g_epis_inactive
        THEN
            o_val := l_inactive_create_perm;
        
        ELSIF l_epis_flg_ehr = g_flg_ehr_scheduled
        THEN
            o_val := l_sched_create_perm;
        ELSE
            --otherwise we can create
            o_val := g_yes;
        END IF;
    
        RETURN o_val;
    
    END check_area_create_permission;

    /**
    * Checks if a certain Alert functionality (area) can create records in schedule, EHR or inactive episodes.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         Professional identification
    * @param i_episode      Episode id
    * @param o_val          return 'Y' has permission to create records, 'N' otherwise
    * @param o_error        Error object
    *
    * @return   true if sucess, false otherwise
    *
    * @author   Sérgio Santos
    * @version  2.6.1.1
    * @since    2011/06/05
    */
    FUNCTION check_area_create_perm_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_area    IN table_varchar,
        o_area    OUT table_varchar,
        o_val     OUT table_varchar,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_temp_val_list table_varchar := table_varchar();
        l_temp_val      VARCHAR2(1 CHAR);
    
    BEGIN
        --check parameters
        IF i_area IS NULL
           OR i_prof IS NULL
        THEN
            o_area := NULL;
            o_val  := NULL;
        
            g_error := 'CHECK INPUT PARAMETERS';
            RAISE g_exception;
        END IF;
    
        --copy input areas for the output
        o_area := i_area;
    
        --check the access permission for each area
        FOR i IN 1 .. i_area.count
        LOOP
            IF NOT pk_ehr_access.check_area_create_permission(i_lang    => i_lang,
                                                              i_prof    => i_prof,
                                                              i_episode => i_episode,
                                                              i_area    => i_area(i),
                                                              o_val     => l_temp_val,
                                                              o_error   => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            l_temp_val_list.extend(1);
            l_temp_val_list(l_temp_val_list.count) := l_temp_val;
        
        END LOOP;
    
        --copy permissions to the output
        o_val := l_temp_val_list;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_EHR_ACCESS',
                                   'CHECK_AREA_CREATE_PERMISSION');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- return failure
                RETURN FALSE;
            END;
    END check_area_create_perm_list;

    /**
    * Get episode encounters.
    *
    * @param i_lang                language identifier
    * @param i_prof                logged professional structure
    * @param i_id_episode          episode identifier
    * @param i_id_patient          patient identifier
    * @param o_past_enc            past encounters
    * @param o_cur_enc             ongoing encounters
    * @param o_new_enc             new encounter
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2009/10/23
    * @version 2.5.0.7
    * @author Pedro Carneiro
    */
    FUNCTION get_encounters
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        o_past_enc   OUT pk_types.cursor_type,
        o_cur_enc    OUT pk_types.cursor_type,
        o_new_enc    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_epis_type episode.id_epis_type%TYPE;
    BEGIN
        g_error     := 'get prof epis_type';
        l_epis_type := pk_sysconfig.get_config('EPIS_TYPE', i_prof);
    
        g_error := 'OPEN o_past_enc';
        OPEN o_past_enc FOR
            SELECT er.id_epis_encounter,
                   er.id_episode,
                   pk_ehr_common.get_visit_name_by_epis(i_lang, i_prof, e.id_epis_type) visit_name,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, er.id_professional) prof_nickname,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, er.dt_epis_encounter, i_prof) epis_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, er.dt_epis_encounter, i_prof.institution, i_prof.software) epis_hour,
                   pk_case_management.get_encounter_reas(i_lang, i_prof, er.id_epis_encounter) encounter_reason,
                   pk_sysdomain.get_domain(pk_case_management.g_domain_enc_flg_type, er.flg_type, i_lang) encounter_type,
                   to_char(er.dt_epis_encounter, pk_alert_constant.g_dt_yyyymmddhh24miss) order_date
              FROM epis_encounter er
              JOIN episode e
                ON e.id_episode = er.id_episode
             WHERE er.id_episode = i_id_episode
               AND er.flg_status = pk_case_management.g_enc_flg_status_i
             ORDER BY order_date DESC;
    
        g_error := 'OPEN o_cur_enc';
        OPEN o_cur_enc FOR
            SELECT er.id_epis_encounter,
                   er.id_episode,
                   pk_ehr_common.get_visit_name_by_epis(i_lang, i_prof, e.id_epis_type) visit_name,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, er.id_professional) prof_nickname,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, er.dt_epis_encounter, i_prof) epis_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, er.dt_epis_encounter, i_prof.institution, i_prof.software) epis_hour,
                   pk_case_management.get_encounter_reas(i_lang, i_prof, er.id_epis_encounter) encounter_reason,
                   pk_sysdomain.get_domain(pk_case_management.g_domain_enc_flg_type, er.flg_type, i_lang) encounter_type,
                   to_char(er.dt_epis_encounter, pk_alert_constant.g_dt_yyyymmddhh24miss) order_date
              FROM epis_encounter er
              JOIN episode e
                ON e.id_episode = er.id_episode
             WHERE er.id_episode = i_id_episode
               AND er.flg_status IN (pk_case_management.g_enc_flg_status_a, pk_case_management.g_enc_flg_status_r)
             ORDER BY order_date DESC;
    
        g_error := 'OPEN o_new_enc';
        OPEN o_new_enc FOR
            SELECT pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T101') new_enc_desc,
                   pk_ehr_common.get_visit_name_by_epis(i_lang, i_prof, l_epis_type) visit_name,
                   g_yes new_enc_create,
                   decode((SELECT COUNT(1)
                            FROM epis_encounter er
                           WHERE er.id_episode = i_id_episode
                             AND er.flg_status IN (pk_case_management.g_enc_flg_status_a,
                                                   pk_case_management.g_enc_flg_status_i,
                                                   pk_case_management.g_enc_flg_status_r)),
                          0,
                          pk_case_management.g_enc_first,
                          pk_case_management.g_enc_followup) flg_type
              FROM dual;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_EHR_ACCESS',
                                              i_function => 'GET_ENCOUNTERS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_past_enc);
            pk_types.open_my_cursor(o_cur_enc);
            pk_types.open_my_cursor(o_new_enc);
            RETURN FALSE;
    END get_encounters;

    /**
    * Gets new contact options
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    *
    * @param o_options             cursor containing available options when a contact is created
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2008-05-16
    * @version v2.5.0.7.5
    * @author Pedro Teixeira
    */
    FUNCTION get_new_contact_options
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_options    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_allow_sched_without_vac sch_vacancy_usage.flg_sched_without_vac%TYPE;
        l_show_ehr_event          VARCHAR2(1 CHAR) := g_no;
    
    BEGIN
        ------------------------------------------------------------
        IF has_sched_permission(i_lang, i_prof, g_flg_context_new_patient)
        THEN
            l_allow_sched_without_vac := g_yes;
        ELSE
            l_allow_sched_without_vac := g_no;
        END IF;
    
        ------------------------------------------------------------
        IF has_ehr_permission(i_lang, i_prof, i_id_patient)
        THEN
            l_show_ehr_event := g_yes;
        ELSE
            l_show_ehr_event := g_no;
        END IF;
    
        ------------------------------------------------------------
        g_error := 'OPEN o_options';
        OPEN o_options FOR
            SELECT eac.id_ehr_access_context options_id,
                   pk_translation.get_translation(i_lang, eac.code_ehr_access_context) options_desc,
                   eac.flg_type options_type,
                   decode(eac.flg_type,
                          g_flg_access_new_contact,
                          l_allow_sched_without_vac,
                          g_access_ehr,
                          l_show_ehr_event,
                          g_yes) flg_active,
                   rank
              FROM ehr_access_context eac
             WHERE eac.id_ehr_access_context IN (SELECT MAX(e2.id_ehr_access_context)
                                                   FROM ehr_access_context_soft e2
                                                   JOIN ehr_access_context e1
                                                     ON (e1.id_ehr_access_context = e2.id_ehr_access_context)
                                                  WHERE e2.id_software IN (0, i_prof.software)
                                                    AND e1.flg_context = g_flg_context_new_patient
                                                    AND e1.flg_available = g_yes
                                                  GROUP BY e1.flg_type)
               AND eac.flg_context = g_flg_context_new_patient
               AND eac.flg_available = g_yes
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_EHR_ACCESS',
                                              i_function => 'GET_NEW_CONTACT_OPTIONS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_options);
            RETURN FALSE;
    END get_new_contact_options;

    /**
    * Gets administrator new contact options
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    *
    * @param o_options             cursor containing available options when a contact is created
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2009-01-14
    * @version v2.5.0.7.6
    * @author Pedro Teixeira
    */
    FUNCTION get_adm_contact_options
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_options    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN o_options';
        OPEN o_options FOR
            SELECT eac.id_ehr_access_context options_id,
                   pk_translation.get_translation(i_lang, eac.code_ehr_access_context) options_desc,
                   eac.flg_type options_type,
                   g_yes flg_active,
                   rank
              FROM ehr_access_context eac
             WHERE eac.id_ehr_access_context IN (SELECT MAX(e2.id_ehr_access_context)
                                                   FROM ehr_access_context_soft e2
                                                   JOIN ehr_access_context e1
                                                     ON (e1.id_ehr_access_context = e2.id_ehr_access_context)
                                                  WHERE e2.id_software IN (0, i_prof.software)
                                                    AND e1.flg_context = g_flg_context_new_patient
                                                    AND e1.flg_available = g_yes
                                                  GROUP BY e1.flg_type)
               AND eac.flg_context = g_flg_context_new_patient
               AND eac.flg_available = g_yes
               AND eac.flg_type != g_access_new_indirect_contact -- administrator cannot create indirect contact
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_EHR_ACCESS',
                                              i_function => 'GET_ADM_CONTACT_OPTIONS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_options);
            RETURN FALSE;
    END get_adm_contact_options;

    /**
    * Checks if professional has permission to create scheduled contacts
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_flg_context         context
    *
    * @return              true if has permission, false otherwise
    *
    * @since 2010-01-12
    * @version v2.5.0.7.6
    * @author Pedro Teixeira
    */
    FUNCTION has_sched_permission
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_context IN ehr_access_context.flg_context%TYPE
    ) RETURN BOOLEAN IS
    
        l_id_sch_event   sch_event.id_sch_event%TYPE;
        l_dcs_count      INTEGER := 0;
        l_has_permission BOOLEAN := FALSE;
        l_error          t_error_out;
    
        CURSOR c_sch_permission IS
            SELECT COUNT(1)
              FROM sch_permission sp, dep_clin_serv dcs
             WHERE sp.id_professional = i_prof.id
               AND sp.id_sch_event = l_id_sch_event
               AND sp.id_institution = i_prof.institution
               AND sp.flg_permission = pk_schedule.g_permission_schedule
               AND sp.id_dep_clin_serv = dcs.id_dep_clin_serv
               AND pk_schedule_api_downstream.get_appointment_exists(i_lang,
                                                                     i_prof,
                                                                     l_id_sch_event,
                                                                     dcs.id_clinical_service) = g_yes
               AND pk_schedule_common.get_sch_event_avail(l_id_sch_event, i_prof.institution, i_prof.software) =
                   pk_alert_constant.g_yes;
    
    BEGIN
    
        l_has_permission := TRUE;
        ---------------------------------------------
        l_id_sch_event := get_sched_event(i_lang, i_prof, i_flg_context);
    
        g_error := 'OPEN c_sch_permission';
        OPEN c_sch_permission;
        FETCH c_sch_permission
            INTO l_dcs_count;
        g_found := c_sch_permission%FOUND;
        CLOSE c_sch_permission;
    
        -- if no dep_clin_service available to this professional then it has no permission to create schedules
        IF l_dcs_count = 0
        THEN
            l_has_permission := FALSE;
        ELSE
            l_has_permission := TRUE;
        END IF;
    
        RETURN l_has_permission;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_EHR_ACCESS',
                                              i_function => 'HAS_SCHED_PERMISSION',
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END has_sched_permission;

    /**
    * Checks if professional has permission to create EHR event
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    *
    * @return              true if has permission, false otherwise
    *
    * @since 09-01-2010
    * @version V2.6.0.1
    * @author Pedro Teixeira
    */
    FUNCTION has_ehr_permission
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN BOOLEAN IS
    
        l_error t_error_out;
    
        l_has_permission BOOLEAN := FALSE;
        l_grp_insts      table_number;
    
        l_has_ehr        VARCHAR2(1 CHAR) := g_no;
        l_can_create_ehr sys_config.value%TYPE := pk_sysconfig.get_config('EHR_EVENT_CREATE',
                                                                          i_prof.institution,
                                                                          i_prof.software);
    
        --check if there are ehr events
        CURSOR c_ehr(l_insts table_number) IS
            SELECT DISTINCT g_yes
              FROM episode e, epis_info ei
             WHERE ei.id_episode = e.id_episode
               AND e.id_patient = i_id_patient
               AND ei.id_software = i_prof.software
               AND e.id_institution IN (SELECT *
                                          FROM TABLE(l_insts))
               AND e.flg_ehr = g_flg_ehr_ehr
               AND rownum <= 1;
    
    BEGIN
        SELECT column_value
          BULK COLLECT
          INTO l_grp_insts
          FROM TABLE(pk_list.tf_get_all_inst_group(i_prof.institution, g_inst_grp_flg_rel_adt));
    
        g_error := 'OPEN c_ehr';
        OPEN c_ehr(l_grp_insts);
        FETCH c_ehr
            INTO l_has_ehr;
        CLOSE c_ehr;
    
        IF (l_can_create_ehr = g_yes OR l_has_ehr = g_yes)
        THEN
            l_has_permission := TRUE;
        ELSE
            l_has_permission := FALSE;
        END IF;
    
        RETURN l_has_permission;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_EHR_ACCESS',
                                              i_function => 'HAS_EHR_PERMISSION',
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END has_ehr_permission;

    /**
    * Get the sch_event associated with the professional a context
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_flg_context         context
    *
    * @return              true if has permission, false otherwise
    *
    * @since 2010-01-12
    * @version v2.5.0.7.6
    * @author Pedro Teixeira
    */
    FUNCTION get_sched_event
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_context IN ehr_access_context.flg_context%TYPE
    ) RETURN VARCHAR2 IS
    
        l_id_sch_event sch_event.id_sch_event%TYPE;
        l_prof_cat     category.flg_type%TYPE := pk_tools.get_prof_cat(i_prof);
    
        l_error t_error_out;
    BEGIN
    
        IF l_prof_cat = g_doctor_category
        THEN
            IF i_flg_context = g_flg_context_access
            THEN
                l_id_sch_event := pk_schedule.g_event_subs_med;
            ELSIF i_flg_context = g_flg_context_new_patient
            THEN
                l_id_sch_event := pk_schedule.g_event_first_med;
            ELSE
                l_id_sch_event := pk_schedule.g_event_first_med;
            END IF;
        ELSIF l_prof_cat = g_nurse_category
        THEN
            l_id_sch_event := g_sch_care_event_nursing;
        ELSIF l_prof_cat = pk_alert_constant.g_cat_type_nutritionist
        THEN
            l_id_sch_event := pk_schedule.g_event_first_nutri;
        ELSIF l_prof_cat = pk_alert_constant.g_cat_type_social
        THEN
            l_id_sch_event := pk_schedule.g_event_first_social;
        ELSE
            l_id_sch_event := pk_schedule.g_event_first_med;
        END IF;
    
        RETURN l_id_sch_event;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_EHR_ACCESS',
                                              i_function => 'GET_SCHED_EVENT',
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END get_sched_event;

    /**
    * Get the sch_event associated with the professional a context
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_flg_context         context
    *
    * @return              true if has permission, false otherwise
    *
    * @since 2010-01-12
    * @version v2.5.0.7.6
    * @author Pedro Teixeira
    */
    FUNCTION get_sched_without_vac
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN BOOLEAN IS
    
        l_allow_sched_without_vac sch_vacancy_usage.flg_sched_without_vac%TYPE;
        l_error                   t_error_out;
    
        CURSOR c_allow_sched_without_vac IS
            SELECT svu.flg_sched_without_vac
              FROM sch_vacancy_usage svu
             WHERE svu.id_software = i_prof.software
               AND svu.id_institution IN (0, i_prof.institution)
               AND svu.flg_sch_type = g_flg_consult_sch_type
               AND rownum = 1
               AND svu.id_institution = (SELECT MAX(id_institution)
                                           FROM sch_vacancy_usage s
                                          WHERE s.id_software = svu.id_software
                                            AND s.flg_sch_type = g_flg_consult_sch_type
                                            AND s.id_institution IN (0, i_prof.institution));
    BEGIN
    
        ---------------------------------------------------
        g_error := 'OPEN c_allow_sched_without_vac';
        OPEN c_allow_sched_without_vac;
        FETCH c_allow_sched_without_vac
            INTO l_allow_sched_without_vac;
        g_found := c_allow_sched_without_vac%FOUND;
        CLOSE c_allow_sched_without_vac;
    
        IF g_found
           AND l_allow_sched_without_vac = g_yes
        THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_EHR_ACCESS',
                                              i_function => 'GET_SCHED_WITHOUT_VAC',
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_sched_without_vac;

    /**
    * Gets access areas for a professional
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * 
    * @param  o_flg_show           flag show / not show
    * @param o_precaution_list     string containing patient problems precautions
    * @param o_precaution_number     number patient problems precautions
    * @param o_problem_list        string containing patient problems with precautios
    * @param o_problem_number        number patient problems with precautios
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2010-02-25
    * @version v2.6.0
    * @author Paulo Teixeira
    */
    FUNCTION get_precaution_warning
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN patient.id_patient%TYPE,
        o_flg_show          OUT VARCHAR2,
        o_precaution_list   OUT VARCHAR2,
        o_precaution_number OUT NUMBER,
        o_problem_list      OUT VARCHAR2,
        o_problem_number    OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        o_flg_show := pk_problems.check_pat_precaution(i_lang => i_lang, i_pat => i_id_patient, i_prof => i_prof);
        IF NOT pk_problems.get_pat_precaution(i_lang              => i_lang,
                                              i_pat               => i_id_patient,
                                              i_prof              => i_prof,
                                              o_precaution_list   => o_precaution_list,
                                              o_precaution_number => o_precaution_number,
                                              o_error             => o_error)
        THEN
            RAISE g_exception;
        END IF;
        IF NOT pk_problems.get_pat_precaution_problem(i_lang           => i_lang,
                                                      i_pat            => i_id_patient,
                                                      i_prof           => i_prof,
                                                      o_problem_list   => o_problem_list,
                                                      o_problem_number => o_problem_number,
                                                      o_error          => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_EHR_ACCESS',
                                              i_function => 'get_precaution_warning',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    /**********************************************************************************************
    * Check if a patient is on trial
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_patient   PATIENT ID
    * @param o_flg_show     Y - if on trial N - Not on trial
    * @param o_trial        trial cursor
    * @param o_responsible  cursor with responsibles
    * @param o_shortcut     id shortcut to trials
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/17
    **********************************************************************************************/
    FUNCTION get_trials_warning
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        o_flg_show    OUT VARCHAR2,
        o_trial       OUT pk_types.cursor_type,
        o_responsible OUT pk_types.cursor_type,
        o_shortcut    OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_profile profile_template.id_profile_template%TYPE;
        l_num     NUMBER;
    BEGIN
        alertlog.pk_alertlog.log_debug('PARAMS[ i_id_patient: ' || i_id_patient, g_package_name, 'GET_TRIALS_WARNING');
    
        g_error := 'CALL pk_trials.check_patient_trial_ehr';
    
        o_flg_show := pk_trials.check_patient_trial_ehr(i_lang       => i_lang,
                                                        i_prof       => i_prof,
                                                        i_id_patient => i_id_patient);
        IF o_flg_show = pk_alert_constant.g_yes
        THEN
            g_error := 'CALL pk_trials.get_pat_trials_details';
            IF NOT pk_trials.get_pat_trials_details(i_lang        => i_lang,
                                                    i_prof        => i_prof,
                                                    i_id_patient  => i_id_patient,
                                                    i_type        => 'E',
                                                    o_trial       => o_trial,
                                                    o_responsible => o_responsible,
                                                    o_error       => o_error)
            THEN
                RAISE g_exception;
            END IF;
            g_error   := 'CALL pk_prof_utils.get_prof_profile_template';
            l_profile := pk_prof_utils.get_prof_profile_template(i_prof => i_prof);
        
            SELECT COUNT(1)
              INTO l_num
              FROM profile_templ_access pta
             WHERE pta.id_software = i_prof.software
               AND pta.id_profile_template IN (SELECT id_parent
                                                 FROM profile_template pt
                                                WHERE pt.id_profile_template = l_profile
                                                  AND id_parent IS NOT NULL
                                               UNION
                                               SELECT l_profile
                                                 FROM dual)
               AND id_sys_shortcut = pk_trials.g_trial_shortcut;
            IF l_num > 0
            THEN
                o_shortcut := pk_trials.g_trial_shortcut;
            END IF;
        ELSE
            pk_types.open_my_cursor(o_trial);
            pk_types.open_my_cursor(o_responsible);
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => g_package_name,
                                              i_function => 'GET_TRIALS_WARNING',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_trial);
            pk_types.open_my_cursor(o_responsible);
        
            RETURN FALSE;
        
    END get_trials_warning;
    /**
    * check if a exception shortcut for patient area is parameterized
    *
    * @param i_lang              language preference
    * @param i_prof              professional identification
    * @param i_shortcut          default shortcut
    * @param o_shortcut_return   shortcut 
    * @param o_error             error message
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2011-08-23
    * @version v2.5
    * @author rita lopes
    */
    FUNCTION check_shortcut_exception
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_shortcut        IN sys_shortcut.id_sys_shortcut%TYPE,
        o_shortcut_return OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_shortcut
        (
            v_profile_template profile_template.id_profile_template%TYPE,
            v_id_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE
        ) IS
            SELECT see.id_shortcut
              FROM shortcut_ehr_exception see
             WHERE see.id_institution = i_prof.institution
               AND see.id_profile_template = v_profile_template
               AND see.id_dep_clin_serv IN (0, v_id_dep_clin_serv)
             ORDER BY see.id_dep_clin_serv DESC;
        r_shortcut c_shortcut%ROWTYPE;
    
        l_func_name        VARCHAR2(60 CHAR) := 'CHECK_SHORTCUT_EXCEPTION';
        l_profile_template profile_template.id_profile_template%TYPE;
    
        l_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE;
    BEGIN
    
        l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof);
        BEGIN
            SELECT nvl(ei.id_dep_clin_serv, 0)
              INTO l_dep_clin_serv
              FROM epis_info ei
             WHERE ei.id_episode = i_episode;
        EXCEPTION
            WHEN no_data_found THEN
                l_dep_clin_serv := 0;
        END;
    
        OPEN c_shortcut(l_profile_template, l_dep_clin_serv);
        FETCH c_shortcut
            INTO r_shortcut;
        IF c_shortcut%FOUND
        THEN
            o_shortcut_return := r_shortcut.id_shortcut;
        ELSE
            o_shortcut_return := i_shortcut;
        END IF;
        CLOSE c_shortcut;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            o_shortcut_return := NULL;
            RETURN FALSE;
    END check_shortcut_exception;

    /******************************************************************************************** 
    * Check if a patient is on patient Alerts 
    * 
    * @param i_lang         language identifier 
    * @param i_prof         logged professional structure 
    * @param i_id_patient   PATIENT ID 
    * @param o_flg_show     Y - if on patient alerts N - Not on  patient alerts 
    * @param o_title        modalWindows title 
    * @param o_warning      alerts cursor 
    * @param o_shortcut     id shortcut to  patient alerts 
    * @param o_error        error 
    * 
    * @return               false if errors occur, true otherwise 
    * 
    * @author              Jorge Silva 
    * @version              2.6.2
    * @since                2012/11/23 
    **********************************************************************************************/
    FUNCTION get_active_patient_alerts
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_flg_show   OUT VARCHAR2,
        o_warning    OUT VARCHAR2,
        o_title      OUT VARCHAR2,
        o_shortcut   OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        episdoc_num NUMBER;
        cout_num    NUMBER;
        -- 
        l_exception EXCEPTION;
    BEGIN
        IF NOT pk_advanced_directives.get_active_patient_alerts(i_lang       => i_lang,
                                                                i_prof       => i_prof,
                                                                i_id_patient => i_id_patient,
                                                                o_flg_show   => o_flg_show,
                                                                o_warning    => o_warning,
                                                                o_title      => o_title,
                                                                o_shortcut   => o_shortcut,
                                                                o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              'get_active_patient_alerts',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END get_active_patient_alerts;

    /*
    * Gets the list of clinical services from a department, for a given event, professional or episode.
    * @param i_lang             Language identifier.
    * @param i_prof             Professional who is calling this function.
    * @param i_id_dep           Department identifier.
    * @param i_id_event         Event identifier.
    * @param i_id_episode       Episode identifier.
    * @param i_flg_search       Whether or not should the 'All' option be included
    * @param i_flg_schedule        Whether or not should the events be filtered considering the professional's permission to schedule
    * @param o_dep_clin_servs   List of clinical services.
    * @param o_error            Error message (if an error occurred).
    * 
    * @author              Jorge Silva 
    * @version              2.6.3.9
    * @since                2012/12/04 
    */
    FUNCTION get_department_by_schedule(i_id_schedule schedule.id_schedule%TYPE) RETURN department.id_department%TYPE IS
    
        l_id_department department.id_department%TYPE;
    
    BEGIN
    
        SELECT dcs.id_department
          INTO l_id_department
          FROM epis_info ei
          JOIN dep_clin_serv dcs
            ON dcs.id_dep_clin_serv = ei.id_dep_clin_serv
         WHERE ei.id_schedule = i_id_schedule;
    
        RETURN l_id_department;
    
    END get_department_by_schedule;
    FUNCTION get_dep_clin_servs_schedule
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_event       IN VARCHAR2,
        i_id_episode     IN episode.id_episode%TYPE DEFAULT NULL,
        i_id_schedule    IN schedule.id_schedule%TYPE,
        o_dep_clin_servs OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_DEP_CLIN_SERVS';
    
        l_dep_clin_servs_cursor pk_schedule.c_dep_clin_servs;
        l_dep_clin_servs        pk_schedule.t_coll_dep_clin_servs;
        l_dep_clin_servs_value  t_coll_dep_clin_serv_info := t_coll_dep_clin_serv_info();
    
        l_data                pk_types.cursor_type;
        l_id_clinical_service table_varchar;
        l_id_dep_clin_serv    table_varchar;
        l_has_child           table_varchar;
        l_label               table_varchar;
        l_flg_select          table_varchar;
    BEGIN
    
        g_error := 'CALL pk_progress_notes.get_appointment_types';
        IF NOT pk_progress_notes.get_appointment_types(i_lang    => i_lang,
                                                       i_prof    => i_prof,
                                                       i_episode => i_id_episode,
                                                       i_parent  => NULL,
                                                       o_data    => l_data,
                                                       o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        FETCH l_data BULK COLLECT
            INTO l_id_clinical_service, l_id_dep_clin_serv, l_label, l_has_child, l_flg_select;
        CLOSE l_data;
    
        FOR i IN l_id_dep_clin_serv.first .. l_id_dep_clin_serv.last
        LOOP
            l_dep_clin_servs_value.extend();
            l_dep_clin_servs_value(i) := t_rec_dep_clin_serv_info(data        => l_id_dep_clin_serv(i),
                                                                  label       => l_label(i),
                                                                  flg_select  => l_flg_select(i),
                                                                  order_field => i);
        END LOOP;
    
        OPEN o_dep_clin_servs FOR
            SELECT d.data, d.label label, d.flg_select flg_default
              FROM TABLE(l_dep_clin_servs_value) d
             ORDER BY d.order_field;
    
        /*OLD  IF NOT pk_ehr_access.get_dep_clin_servs(i_lang           => i_lang,
                                                i_prof           => i_prof,
                                                i_id_dep         => get_department_by_schedule(i_id_schedule),
                                                i_id_event       => i_id_event,
                                                i_id_episode     => i_id_episode,
                                                i_flg_search     => 'Y',
                                                i_flg_schedule   => 'Y',
                                                o_dep_clin_servs => o_dep_clin_servs,
                                                o_error          => o_error)
        
        THEN
            RAISE g_exception;
            RETURN FALSE;
        END IF;*/
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_dep_clin_servs);
            RETURN FALSE;
    END;

    FUNCTION get_dep_clin_servs
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_dep         IN VARCHAR2,
        i_id_event       IN VARCHAR2,
        i_id_episode     IN episode.id_episode%TYPE DEFAULT NULL,
        i_flg_search     IN VARCHAR2,
        i_flg_schedule   IN VARCHAR2,
        o_dep_clin_servs OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name             VARCHAR2(32) := 'GET_DEP_CLIN_SERVS';
        l_dep_clin_servs        pk_schedule.t_coll_dep_clin_servs;
        l_dep_clin_servs_value  t_coll_dep_clin_serv_info := t_coll_dep_clin_serv_info();
        l_dep_clin_servs_cursor pk_schedule.c_dep_clin_servs;
        l_id_dep_clin_servs     ehr_access_contact_config.id_dep_clin_serv%TYPE;
        l_profile               profile_template.id_profile_template%TYPE;
    
    BEGIN
    
        IF NOT pk_schedule.get_dep_clin_servs(i_lang           => i_lang,
                                              i_prof           => i_prof,
                                              i_id_dep         => i_id_dep,
                                              i_id_event       => i_id_event,
                                              i_id_episode     => i_id_episode,
                                              i_flg_search     => i_flg_search,
                                              i_flg_schedule   => i_flg_schedule,
                                              o_dep_clin_servs => l_dep_clin_servs_cursor,
                                              o_error          => o_error)
        THEN
            RAISE g_exception;
            RETURN FALSE;
        END IF;
    
        FETCH l_dep_clin_servs_cursor BULK COLLECT
            INTO l_dep_clin_servs;
        CLOSE l_dep_clin_servs_cursor;
    
        IF (l_dep_clin_servs.count > 0)
        THEN
            FOR i IN l_dep_clin_servs.first .. l_dep_clin_servs.last
            LOOP
                l_dep_clin_servs_value.extend();
                l_dep_clin_servs_value(i) := t_rec_dep_clin_serv_info(data        => l_dep_clin_servs(i).data,
                                                                      label       => l_dep_clin_servs(i).label,
                                                                      flg_select  => l_dep_clin_servs(i).flg_select,
                                                                      order_field => l_dep_clin_servs(i).order_field);
            END LOOP;
        END IF;
    
        l_profile := pk_tools.get_prof_profile_template(i_prof);
    
        BEGIN
        
            SELECT d.id_dep_clin_serv
              INTO l_id_dep_clin_servs
              FROM (SELECT eacc.id_dep_clin_serv,
                           row_number() over(ORDER BY decode(eacc.id_profile_template, l_profile, 1, 2), --
                           decode(eacc.id_professional, i_prof.id, 1, 2), --
                           decode(eacc.id_institution, i_prof.institution, 1, 2), --
                           decode(eacc.id_software, i_prof.software, 1, 2)) line_number
                      FROM ehr_access_contact_config eacc
                     WHERE eacc.id_professional IN (0, i_prof.id)
                       AND eacc.id_software IN (pk_alert_constant.g_soft_all, i_prof.software)
                       AND eacc.id_institution IN (pk_alert_constant.g_inst_all, i_prof.institution)
                       AND eacc.id_profile_template IN (pk_alert_constant.g_profile_template_all, l_profile)) d
             WHERE d.line_number = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_dep_clin_servs := -1;
        END;
    
        OPEN o_dep_clin_servs FOR
            SELECT d.data,
                   d.label label,
                   decode(d.data, l_id_dep_clin_servs, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_default
              FROM TABLE(l_dep_clin_servs_value) d
             WHERE d.data != pk_schedule.g_all;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_dep_clin_servs);
            RETURN FALSE;
    END get_dep_clin_servs;

    /*
    * Gets the list of professionals on whose schedules the logged professional
    * has permission to read or schedule.
    *
    * @param i_lang             Language identifier.
    * @param i_prof             Professional identifier.
    * @param i_id_dep           Department identifier.
    * @param i_id_clin_serv     Department-Clinical service identifier.
    * @param i_id_event         Event identifier.
    * @param i_flg_schedule     Whether or not should the events be filtered considering the professional's permission to schedule
    * @param o_professionals    List of processionals.
    * @param o_error            Error message (if an error occurred).
    * 
    * @author              Jorge Silva 
    * @version              2.6.3.9
    * @since                2012/12/04 
    */
    FUNCTION get_professionals
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_dep        IN VARCHAR2,
        i_id_clin_serv  IN VARCHAR2,
        i_id_event      IN VARCHAR2,
        i_flg_schedule  IN VARCHAR2,
        o_professionals OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name       VARCHAR2(32) := 'GET_PROFESSIONALS';
        l_sch_prof        pk_schedule.t_coll_sch_prof;
        l_sch_prof_value  t_coll_sch_prof_info := t_coll_sch_prof_info();
        l_sch_prof_cursor pk_schedule.c_sch_prof;
    BEGIN
    
        IF NOT pk_schedule.get_professionals(i_lang          => i_lang,
                                             i_prof          => i_prof,
                                             i_id_dep        => i_id_dep,
                                             i_id_clin_serv  => i_id_clin_serv,
                                             i_id_event      => i_id_event,
                                             i_flg_schedule  => i_flg_schedule,
                                             o_professionals => l_sch_prof_cursor,
                                             o_error         => o_error)
        THEN
            RAISE g_exception;
            RETURN FALSE;
        END IF;
    
        FETCH l_sch_prof_cursor BULK COLLECT
            INTO l_sch_prof;
        CLOSE l_sch_prof_cursor;
    
        IF (l_sch_prof.count > 0)
        THEN
            FOR i IN l_sch_prof.first .. l_sch_prof.last
            LOOP
                l_sch_prof_value.extend();
                l_sch_prof_value(i) := t_rec_sch_prof_info(data        => l_sch_prof(i).data,
                                                           label       => l_sch_prof(i).label,
                                                           flg_select  => l_sch_prof(i).flg_select,
                                                           order_field => l_sch_prof(i).order_field);
            END LOOP;
        END IF;
    
        OPEN o_professionals FOR
            SELECT d.data, d.label label
              FROM TABLE(l_sch_prof_value) d
             WHERE d.data != pk_schedule.g_all;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_professionals);
            RETURN FALSE;
    END get_professionals;

    /*
    * Gets the list of departments that a professional has access to.
    *
    * @param i_lang                Language identifier.
    * @param i_prof                Professional.
    * @param i_flg_search          Whether or not should the 'All' option appear on the list.
    * @param i_flg_schedule        Whether or not should the departments be filtered considering the professional's permission to schedule
    * @param i_id_institution      Institution ID
    * @param o_departments         List of departments
    * @param o_perm_msg            Error message to be shown if the professional has no permissions
    * @param o_error               Error message (if an error occurred).
    * 
    * @author              Jorge Silva 
    * @version              2.6.3.9
    * @since                2012/12/04 
    */
    FUNCTION get_departments
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_flg_search     IN VARCHAR2,
        i_flg_schedule   IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        o_departments    OUT pk_types.cursor_type,
        o_perm_msg       OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name         VARCHAR2(32) := 'GET_DEPARTMENTS';
        l_departments       pk_schedule.t_coll_departments;
        l_departments_value t_coll_departments_info := t_coll_departments_info();
        l_dep_cursor        pk_schedule.c_dep;
        l_id_department     ehr_access_contact_config.id_department%TYPE;
        l_flg_department    ehr_access_contact_config.flg_department%TYPE;
        l_profile           profile_template.id_profile_template%TYPE;
    
    BEGIN
        IF NOT pk_schedule.get_departments(i_lang           => i_lang,
                                           i_prof           => i_prof,
                                           i_flg_search     => i_flg_search,
                                           i_flg_schedule   => i_flg_schedule,
                                           i_id_institution => i_id_institution,
                                           o_departments    => l_dep_cursor,
                                           o_perm_msg       => o_perm_msg,
                                           o_error          => o_error)
        THEN
            RAISE g_exception;
            RETURN FALSE;
        END IF;
    
        FETCH l_dep_cursor BULK COLLECT
            INTO l_departments;
        CLOSE l_dep_cursor;
    
        FOR i IN l_departments.first .. l_departments.last
        LOOP
            l_departments_value.extend();
            l_departments_value(i) := t_rec_departments_info(data        => l_departments(i).data,
                                                             label       => l_departments(i).label,
                                                             flg_type    => l_departments(i).flg_type,
                                                             flg_select  => l_departments(i).flg_select,
                                                             data_flag   => l_departments(i).data_flag,
                                                             order_field => l_departments(i).order_field,
                                                             dep_type    => l_departments(i).dep_type);
        END LOOP;
    
        l_profile := pk_tools.get_prof_profile_template(i_prof);
    
        BEGIN
            SELECT d.id_department, d.flg_department
              INTO l_id_department, l_flg_department
              FROM (SELECT eacc.id_department,
                           eacc.flg_department,
                           row_number() over(ORDER BY decode(eacc.id_profile_template, l_profile, 1, 2), --
                           decode(eacc.id_professional, i_prof.id, 1, 2), --
                           decode(eacc.id_institution, i_prof.institution, 1, 2), --
                           decode(eacc.id_software, i_prof.software, 1, 2)) line_number
                      FROM ehr_access_contact_config eacc
                     WHERE eacc.id_professional IN (0, i_prof.id)
                       AND eacc.id_software IN (pk_alert_constant.g_soft_all, i_prof.software)
                       AND eacc.id_institution IN (pk_alert_constant.g_inst_all, i_prof.institution)
                       AND eacc.id_profile_template IN (pk_alert_constant.g_profile_template_all, l_profile)) d
             WHERE d.line_number = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_department  := -1;
                l_flg_department := NULL;
        END;
    
        OPEN o_departments FOR
            SELECT d.data id,
                   d.label label,
                   d.flg_type data,
                   decode(d.data,
                          l_id_department,
                          decode(d.flg_type, l_flg_department, pk_alert_constant.g_yes, pk_alert_constant.g_no),
                          pk_alert_constant.g_no) flg_default
              FROM TABLE(l_departments_value) d
             WHERE d.data != pk_schedule.g_all;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_departments);
        
            RETURN FALSE;
    END get_departments;

    /*
    * Gets the list of events.
    * @param i_lang               Language.
    * @param i_prof               Professional
    * @param i_id_dep             Department.
    * @param i_flg_search         Whether or not should the events be selected based on its type. (in 'N' cases, the first event is the only one selected).
    * @param i_flg_schedule       Whether or not should the events be filtered considering the professional's permission to schedule
    * @param i_flg_dep_type       Events should be filtered by sch_dep_type because the same department may have events with several sch_dep_type(s)
    * @param o_events             List of events.
    * @param o_error              Error message (if an error occurred).
    * 
    * @author              Jorge Silva 
    * @version              2.6.3.9
    * @since                2012/12/04 
    */
    FUNCTION get_events_schedule
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_events      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name     VARCHAR2(32) := 'GET_EVENTS';
        l_id_department department.id_department%TYPE;
        l_flg_type      department.flg_type%TYPE;
    BEGIN
    
        SELECT dcs.id_department, d.flg_type
          INTO l_id_department, l_flg_type
          FROM epis_info ei
          JOIN dep_clin_serv dcs
            ON dcs.id_dep_clin_serv = ei.id_dep_clin_serv
          JOIN department d
            ON d.id_department = dcs.id_department
         WHERE ei.id_schedule = i_id_schedule;
    
        IF NOT pk_ehr_access.get_events(i_lang         => i_lang,
                                        i_prof         => i_prof,
                                        i_id_dep       => l_id_department,
                                        i_flg_search   => 'Y',
                                        i_flg_schedule => 'N',
                                        i_flg_dep_type => l_flg_type,
                                        o_events       => o_events,
                                        o_error        => o_error)
        THEN
            RAISE g_exception;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_events);
        
            RETURN FALSE;
    END;
    FUNCTION get_events
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_dep       IN VARCHAR2,
        i_flg_search   IN VARCHAR2,
        i_flg_schedule IN VARCHAR2,
        i_flg_dep_type IN VARCHAR2,
        o_events       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name     VARCHAR2(32) := 'GET_EVENTS';
        l_events        pk_schedule.t_coll_events;
        l_events_value  t_coll_events_info := t_coll_events_info();
        l_events_cursor pk_schedule.c_events;
        l_id_events     ehr_access_contact_config.id_event%TYPE;
        l_profile       profile_template.id_profile_template%TYPE;
    
    BEGIN
        IF NOT pk_schedule.get_events(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_id_dep       => i_id_dep,
                                      i_flg_search   => i_flg_search,
                                      i_flg_schedule => i_flg_schedule,
                                      i_flg_dep_type => i_flg_dep_type,
                                      o_events       => l_events_cursor,
                                      o_error        => o_error)
        THEN
            RAISE g_exception;
            RETURN FALSE;
        END IF;
    
        FETCH l_events_cursor BULK COLLECT
            INTO l_events;
        CLOSE l_events_cursor;
    
        IF (l_events.count > 0)
        THEN
            FOR i IN l_events.first .. l_events.last
            LOOP
                l_events_value.extend();
                pk_alertlog.log_debug(text            => 'entrei aqui',
                                      object_name     => 'pk_ehr_access',
                                      sub_object_name => l_func_name);
            
                l_events_value(i) := t_rec_events_info(data         => l_events(i).data,
                                                       id_sch_event => l_events(i).id_sch_event,
                                                       label_full   => l_events(i).label_full,
                                                       label        => l_events(i).label,
                                                       flg_select   => l_events(i).flg_select,
                                                       order_field  => l_events(i).order_field,
                                                       order_field2 => l_events(i).order_field2,
                                                       no_prof      => l_events(i).no_prof);
            END LOOP;
        END IF;
    
        l_profile := pk_tools.get_prof_profile_template(i_prof);
    
        BEGIN
            SELECT d.id_event
              INTO l_id_events
              FROM (SELECT eacc.id_event,
                           row_number() over(ORDER BY decode(eacc.id_profile_template, l_profile, 1, 2), --
                           decode(eacc.id_professional, i_prof.id, 1, 2), --
                           decode(eacc.id_institution, i_prof.institution, 1, 2), --
                           decode(eacc.id_software, i_prof.software, 1, 2)) line_number
                      FROM ehr_access_contact_config eacc
                     WHERE eacc.id_professional IN (0, i_prof.id)
                       AND eacc.id_software IN (pk_alert_constant.g_soft_all, i_prof.software)
                       AND eacc.id_institution IN (pk_alert_constant.g_inst_all, i_prof.institution)
                       AND eacc.id_profile_template IN (pk_alert_constant.g_profile_template_all, l_profile)) d
             WHERE d.line_number = 1;
        
        EXCEPTION
            WHEN no_data_found THEN
                l_id_events := -1;
        END;
    
        OPEN o_events FOR
        
            SELECT d.id_sch_event data,
                   d.label_full label,
                   decode(d.id_sch_event, l_id_events, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_default
              FROM TABLE(l_events_value) d
             WHERE d.no_prof = pk_alert_constant.g_no;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_events);
        
            RETURN FALSE;
    END get_events;

    FUNCTION has_patient_access
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        o_access     OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        o_access := pk_alert_constant.g_no;
        IF i_episode IS NULL
           AND i_id_patient IS NULL
        THEN
            o_access := pk_alert_constant.g_yes;
        ELSE
            IF NOT pk_ehr_access_rules.ckeck_active_episode_with_me(i_lang               => i_lang,
                                                                    i_prof               => i_prof,
                                                                    i_id_patient         => i_id_patient,
                                                                    i_flg_episode_reopen => NULL,
                                                                    i_id_episode         => i_episode)
            THEN
                o_access := pk_alert_constant.g_yes;
            END IF;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_EHR_ACCESS',
                                              i_function => 'HAS_PATIENT_ACCESS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END has_patient_access;

    FUNCTION check_episode_out_on_pass
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_flg_show   OUT VARCHAR2,
        o_warning    OUT VARCHAR2,
        o_title      OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name           VARCHAR2(60 CHAR) := 'check_episode_out_on_pass';
        l_dt_in               epis_out_on_pass.dt_in%TYPE;
        l_dt_out              epis_out_on_pass.dt_out%TYPE;
        l_total_allowed_hours epis_out_on_pass.total_allowed_hours%TYPE;
    BEGIN
    
        g_error    := 'CALL pk_epis_out_on_pass.check_epis_out_on_pass_active: id_episode = ' || i_id_episode;
        o_flg_show := pk_epis_out_on_pass.check_epis_out_on_pass_active(i_lang       => i_lang,
                                                                        i_prof       => i_prof,
                                                                        i_id_episode => i_id_episode);
        IF o_flg_show = pk_alert_constant.g_yes
        THEN
            g_error := 'CALL pk_epis_out_on_pass.get_epis_out_on_pass_info';
            IF NOT pk_epis_out_on_pass.get_epis_out_on_pass_info(i_lang                => i_lang,
                                                                 i_prof                => i_prof,
                                                                 i_id_episode          => i_id_episode,
                                                                 o_dt_in               => l_dt_in,
                                                                 o_dt_out              => l_dt_out,
                                                                 o_total_allowed_hours => l_total_allowed_hours,
                                                                 o_error               => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            o_title   := pk_message.get_message(i_lang, i_prof, 'EHR_ACCESS_T044');
            o_warning := pk_message.get_message(i_lang, i_prof, 'EHR_ACCESS_T059') || '<br><br>' ||
                         pk_date_utils.dt_chr_date_hour_tsz(i_lang, l_dt_out, i_prof.institution, i_prof.software) ||
                         pk_message.get_message(i_lang, i_prof, 'EHR_ACCESS_T060') ||
                         pk_date_utils.dt_chr_date_hour_tsz(i_lang, l_dt_in, i_prof.institution, i_prof.software) || '.';
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END check_episode_out_on_pass;

    /********************************************************************************************
    * checks if the ok button [to access the patient ehr] is active when searching by cancelled episodes
    *
    * @param  I_LANG                       IN        NUMBER
    * @param  I_PROF                       IN        PROFISSIONAL
    * @param  o_ok_active                  OUT       Y-the ok button should be active. N-otherwise           
    *
    * @return  Boolean
    *
    * @author      Sofia Mendes
    * @version     2.8.0.1
    * @since       06/12/2019
    ********************************************************************************************/
    FUNCTION check_cancel_search_ok_active
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_ok_active OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(60 CHAR) := 'CHECK_CANCELLED_SEARCH_OK_ACTIVE';
        t_flg_permission table_varchar := table_varchar();
    
        l_mkt              market.id_market%TYPE;
        l_profile_template profile_template.id_profile_template%TYPE;
        l_cat              category.id_category%TYPE;
        l_config           alert_core_tech.t_config;
        k_cfg_ok_active CONSTANT VARCHAR2(30 CHAR) := 'CANCELLED_SEARCH_OK_ACTIVE';
    
    BEGIN
    
        o_ok_active := pk_alert_constant.g_no;
    
        g_error := 'Call pk_utils.get_institution_market / I_ID_INSTITUTION=' || i_prof.institution;
        l_mkt   := pk_utils.get_institution_market(i_lang => i_lang, i_id_institution => i_prof.institution);
    
        l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof => i_prof);
    
        l_cat := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
    
        g_error  := 'Database query to get configs...';
        l_config := pk_core_config.get_config(i_area             => k_cfg_ok_active,
                                              i_prof             => i_prof,
                                              i_market           => l_mkt,
                                              i_category         => l_cat,
                                              i_profile_template => l_profile_template,
                                              i_prof_dcs         => NULL,
                                              i_episode_dcs      => NULL);
    
        -- field01 : flag to control if the ok button [to access the patient ehr] is active when searching by cancelled episodes
        SELECT field_01
          BULK COLLECT
          INTO t_flg_permission
          FROM (SELECT row_number() over(PARTITION BY config_table ORDER BY id_dep_clin_serv DESC, id_institution DESC, id_software DESC, id_market DESC) rn,
                       id_record,
                       field_01,
                       id_config,
                       id_market,
                       id_institution,
                       id_software,
                       id_dep_clin_serv
                  FROM (SELECT cfg.id_record,
                               cfg.field_01,
                               c.id_config,
                               c.id_market,
                               c.id_institution,
                               c.id_software,
                               c.id_dep_clin_serv,
                               cfg.config_table
                          FROM v_config_table cfg
                          JOIN v_config c
                            ON cfg.id_config = c.id_config
                         WHERE cfg.config_table = k_cfg_ok_active
                           AND cfg.id_config = l_config.id_config) c) t
         WHERE t.rn = 1;
    
        IF t_flg_permission.count > 0
        THEN
            o_ok_active := t_flg_permission(1);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            o_ok_active := pk_alert_constant.g_no;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
        
    END check_cancel_search_ok_active;
BEGIN
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);
END pk_ehr_access;
/
