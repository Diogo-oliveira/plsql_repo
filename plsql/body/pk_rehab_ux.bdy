/*-- Last Change Revision: $Rev: 2027614 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:47 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_rehab_ux IS

    -- Returns the list of all the rehab areas and procedures parameterized for the current institution/software
    FUNCTION get_rehab_interv_all
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_rehab_area          IN rehab_area.id_rehab_area%TYPE,
        i_intervention_parent IN intervention.id_intervention_parent%TYPE,
        i_id_codification     IN interv_codification.id_codification%TYPE,
        o_areas               OUT pk_types.cursor_type,
        o_list                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_REHAB_INTERV_ALL';
    BEGIN
        g_error := 'before call';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        IF NOT pk_rehab.get_rehab_interv_all(i_lang                => i_lang,
                                             i_prof                => i_prof,
                                             i_rehab_area          => i_rehab_area,
                                             i_intervention_parent => i_intervention_parent,
                                             i_id_codification     => i_id_codification,
                                             o_areas               => o_areas,
                                             o_list                => o_list,
                                             o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error('get_rehab_interv_all Parameters: i_rehab_area=' || i_rehab_area ||
                                  ',i_intervention_parent=' || i_intervention_parent || ' @' || g_error,
                                  g_package_name,
                                  l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_REHAB_INTERV_ALL',
                                              o_error);
            RETURN FALSE;
    END get_rehab_interv_all;

    FUNCTION get_rehab_interv_list
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_rehab_area          IN rehab_area.id_rehab_area%TYPE,
        i_intervention_parent IN intervention.id_intervention_parent%TYPE,
        i_id_codification     IN interv_codification.id_codification%TYPE,
        o_areas               OUT pk_types.cursor_type,
        o_list                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_REHAB_INTERV_LIST';
    BEGIN
        g_error := 'before call';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        IF NOT pk_rehab.get_rehab_interv_list(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_rehab_area          => i_rehab_area,
                                              i_intervention_parent => i_intervention_parent,
                                              i_id_codification     => i_id_codification,
                                              o_areas               => o_areas,
                                              o_list                => o_list,
                                              o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error('get_rehab_interv_all Parameters: i_rehab_area=' || i_rehab_area ||
                                  ',i_intervention_parent=' || i_intervention_parent || ' @' || g_error,
                                  g_package_name,
                                  l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_REHAB_INTERV_LIST',
                                              o_error);
            RETURN FALSE;
    END get_rehab_interv_list;

    -- Returns the list of rehab procedures parameterized for the current institution/software that match the search expression
    FUNCTION get_rehab_interv_search
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_keyword         IN VARCHAR2,
        i_id_codification IN interv_codification.id_codification%TYPE DEFAULT NULL,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_REHAB_INTERV_SEARCH';
    BEGIN
        g_error := 'before call';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        IF NOT pk_rehab.get_rehab_interv_search(i_lang, i_prof, i_keyword, i_id_codification, o_list, o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error('get_rehab_interv_search Parameters: i_keyword=' || i_keyword || ' @' || g_error,
                                  g_package_name,
                                  l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_rehab_interv_search;

    -- Returns a list of rehab areas that the professional is or can be allocated to in a given institution
    FUNCTION get_rehab_area_prof
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        o_areas          OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_REHAB_AREA_PROF';
    BEGIN
        g_error := 'before call';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        IF NOT pk_rehab.get_rehab_area_prof(i_lang, i_prof, i_id_institution, o_areas, o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error('get_rehab_area_prof Parameters: i_id_institution=' || i_id_institution || ' @' ||
                                  g_error,
                                  g_package_name,
                                  l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_rehab_area_prof;

    -- Sets the list of rehab areas that the professional is allocated to, in one or more institutions
    FUNCTION set_rehab_area_prof
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_institution IN table_number,
        i_rehab_area  IN table_table_number,
        i_test        IN VARCHAR2,
        o_flg_show    OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_msg_result  OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'SET_REHAB_AREA_PROF';
    BEGIN
        g_error := 'before call';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        IF NOT pk_rehab.set_rehab_area_prof(i_lang        => i_lang,
                                            i_prof        => i_prof,
                                            i_institution => i_institution,
                                            i_rehab_area  => i_rehab_area,
                                            i_test        => i_test,
                                            o_flg_show    => o_flg_show,
                                            o_msg_title   => o_msg_title,
                                            o_msg_result  => o_msg_result,
                                            o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error('set_rehab_area_prof Parameters: i_institution=' ||
                                  pk_utils.concat_table(i_institution) || ' @' || g_error,
                                  g_package_name,
                                  l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END set_rehab_area_prof;

    -- Creates a new rehab group
    FUNCTION create_rehab_group
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_short_name     IN VARCHAR2,
        i_description    IN VARCHAR2,
        i_flg_status     IN VARCHAR2,
        i_id_rehab_area  IN NUMBER,
        o_id_rehab_group OUT rehab_group.id_rehab_group%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'CREATE_REHAB_GROUP';
    BEGIN
        g_error := 'before call';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        IF NOT pk_rehab.create_rehab_group(i_lang           => i_lang,
                                           i_prof           => i_prof,
                                           i_short_name     => i_short_name,
                                           i_description    => i_description,
                                           i_flg_status     => i_flg_status,
                                           i_id_rehab_area  => i_id_rehab_area,
                                           o_id_rehab_group => o_id_rehab_group,
                                           o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error('create_rehab_group Parameters: i_short_name=' || i_short_name || ', i_description=' ||
                                  i_description || ', i_flg_status=' || i_flg_status || ' @' || g_error,
                                  g_package_name,
                                  l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END create_rehab_group;

    -- Returns a list of rehab groups for the professional's institution
    FUNCTION get_rehab_groups
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_groups OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_REHAB_GROUPS';
    BEGIN
        g_error := 'before call';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        IF NOT pk_rehab.get_rehab_groups(i_lang, i_prof, o_groups, o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error('get_rehab_groups Parameters: i_short_name=' || ' @' || g_error,
                                  g_package_name,
                                  l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_rehab_groups;

    -- Updates a rehab group details
    FUNCTION update_rehab_group
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_rehab_group IN rehab_group.id_rehab_group%TYPE,
        i_short_name     IN VARCHAR2,
        i_description    IN VARCHAR2,
        i_flg_status     IN VARCHAR2,
        i_id_rehab_area  IN NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'UPDATE_REHAB_GROUP';
    BEGIN
        g_error := 'before call';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        IF NOT pk_rehab.update_rehab_group(i_lang           => i_lang,
                                           i_prof           => i_prof,
                                           i_id_rehab_group => i_id_rehab_group,
                                           i_short_name     => i_short_name,
                                           i_description    => i_description,
                                           i_flg_status     => i_flg_status,
                                           i_id_rehab_area  => i_id_rehab_area,
                                           o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error('update_rehab_group Parameters: i_id_rehab_group=' || i_id_rehab_group ||
                                  ', i_short_name=' || i_short_name || ', i_description=' || i_description ||
                                  ', i_flg_status=' || i_flg_status || ' @' || g_error,
                                  g_package_name,
                                  l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END update_rehab_group;

    -- Returns a list of rehab groups for the professional in the current institution
    FUNCTION get_rehab_groups_prof
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_groups OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_REHAB_GROUPS_PROF';
    BEGIN
        g_error := 'before call';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        IF NOT pk_rehab.get_rehab_groups_prof(i_lang, i_prof, o_groups, o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error('get_rehab_groups_prof Parameters: ' || ' @' || g_error, g_package_name, l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_rehab_groups_prof;

    -- Sets the list of rehab groups that the professional is allocated to
    FUNCTION set_rehab_groups_prof
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_groups IN table_number,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'SET_REHAB_GROUPS_PROF';
    BEGIN
        g_error := 'before call';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        IF NOT
            pk_rehab.set_rehab_groups_prof(i_lang => i_lang, i_prof => i_prof, i_groups => i_groups, o_error => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error('set_rehab_groups_prof Parameters: i_groups=' || pk_utils.concat_table(i_groups) || ' @' ||
                                  g_error,
                                  g_package_name,
                                  l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END set_rehab_groups_prof;

    -- Returns the information about schedule needs and requested/ongoing treatments
    FUNCTION get_rehab_treatment_plan
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN rehab_plan.id_patient%TYPE,
        i_id_episode        IN rehab_plan.id_episode_origin%TYPE,
        o_id_episode_origin OUT rehab_plan.id_episode_origin%TYPE,
        o_sch_need          OUT pk_types.cursor_type,
        o_treat             OUT pk_types.cursor_type,
        o_notes             OUT pk_types.cursor_type,
        o_labels            OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_REHAB_TREATMENT_PLAN';
    BEGIN
        g_error := 'before call';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        IF NOT pk_rehab.get_rehab_treatment_plan(i_lang              => i_lang,
                                                 i_prof              => i_prof,
                                                 i_id_patient        => i_id_patient,
                                                 i_id_episode        => i_id_episode,
                                                 o_id_episode_origin => o_id_episode_origin,
                                                 o_sch_need          => o_sch_need,
                                                 o_treat             => o_treat,
                                                 o_notes             => o_notes,
                                                 o_labels            => o_labels,
                                                 o_error             => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_sch_need);
            pk_types.open_my_cursor(o_treat);
            pk_types.open_my_cursor(o_notes);
            pk_types.open_my_cursor(o_labels);
            pk_alertlog.log_error('get_rehab_treatment_plan Parameters: i_id_patient=' || i_id_patient || ' @' ||
                                  g_error,
                                  g_package_name,
                                  l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_rehab_treatment_plan;

    -- Returns a list of labels used in scheduling instructions
    FUNCTION get_rehab_instructions_cfg
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_label     OUT pk_types.cursor_type,
        o_frequency OUT pk_types.cursor_type,
        o_priority  OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_REHAB_INSTRUCTIONS_CFG';
    BEGIN
        g_error := 'before call';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        IF NOT pk_rehab.get_rehab_instructions_cfg(i_lang, i_prof, o_label, o_frequency, o_priority, o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error('get_rehab_instructions_cfg Parameters: ' || ' @' || g_error,
                                  g_package_name,
                                  l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_rehab_instructions_cfg;

    -- returns a list of sheduling needs open
    FUNCTION get_pending_sch_needs
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode_origin  IN rehab_sch_need.id_episode_origin%TYPE,
        o_needs_instructions OUT VARCHAR2,
        o_list               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_PENDING_SCH_NEEDS';
    BEGIN
        g_error := 'before call';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        IF NOT pk_rehab.get_pending_sch_needs(i_lang               => i_lang,
                                              i_prof               => i_prof,
                                              i_id_episode_origin  => i_id_episode_origin,
                                              o_needs_instructions => o_needs_instructions,
                                              o_list               => o_list,
                                              o_error              => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_list);
            pk_alertlog.log_error('Parameters: ' || ' @' || g_error, g_package_name, l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_pending_sch_needs;

    --Returns a list of rehab needs open (waiting for scheduling) in this MFR plan
    --to be used in the grid pag.18
    FUNCTION get_pending_sch_needs_grid
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_PENDING_SCH_NEEDS_GRID';
    BEGIN
        g_error := 'before call';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        IF NOT
            pk_rehab.get_pending_sch_needs_grid(i_lang => i_lang, i_prof => i_prof, o_list => o_list, o_error => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error('Parameters: ' || ' @' || g_error, g_package_name, l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_pending_sch_needs_grid;

    -- Creates a new rehab treatments prescription
    FUNCTION create_rehab_presc
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_patient           IN rehab_plan.id_patient%TYPE,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_rehab_area_interv IN table_number,
        i_id_rehab_sch_need    IN table_number,
        i_id_exec_institution  IN table_number,
        i_exec_per_session     IN table_number,
        i_presc_notes          IN table_varchar,
        i_sessions             IN table_number,
        i_frequency            IN table_number,
        i_flg_frequency        IN table_varchar,
        i_flg_priority         IN table_varchar,
        i_date_begin           IN table_varchar,
        i_session_notes        IN table_varchar,
        i_session_type         IN table_varchar,
        i_id_codification      IN table_number,
        i_flg_laterality       IN table_varchar,
        i_id_not_order_reason  IN table_number,
        o_id_rehab_presc       OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'CREATE_REHAB_PRESC';
    BEGIN
        g_error := 'before call';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        IF NOT pk_rehab.create_rehab_presc(i_lang                 => i_lang,
                                           i_prof                 => i_prof,
                                           i_id_patient           => i_id_patient,
                                           i_id_episode           => i_id_episode,
                                           i_id_rehab_area_interv => i_id_rehab_area_interv,
                                           i_id_rehab_sch_need    => i_id_rehab_sch_need,
                                           i_id_exec_institution  => i_id_exec_institution,
                                           i_exec_per_session     => i_exec_per_session,
                                           i_presc_notes          => i_presc_notes,
                                           i_sessions             => i_sessions,
                                           i_frequency            => i_frequency,
                                           i_flg_frequency        => i_flg_frequency,
                                           i_flg_priority         => i_flg_priority,
                                           i_date_begin           => i_date_begin,
                                           i_session_notes        => i_session_notes,
                                           i_session_type         => i_session_type,
                                           i_id_codification      => i_id_codification,
                                           i_flg_laterality       => i_flg_laterality,
                                           i_id_not_order_reason  => i_id_not_order_reason,
                                           o_id_rehab_presc       => o_id_rehab_presc,
                                           o_error                => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error('Parameters: i_id_episode=' || i_id_episode || ' @' || g_error,
                                  g_package_name,
                                  l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END create_rehab_presc;

    FUNCTION create_rehab_presc
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN nurse_tea_req.id_episode%TYPE,
        i_id_patient           IN patient.id_patient%TYPE,
        i_root_name            IN VARCHAR2,
        i_tbl_records          IN table_number,
        i_tbl_ds_internal_name IN table_varchar,
        i_tbl_real_val         IN table_table_varchar,       
        i_tbl_val_mea          IN table_table_varchar,
        i_tbl_val_clob         IN table_table_clob DEFAULT NULL,
        i_tbl_val_array        IN tt_table_varchar DEFAULT NULL,
        i_tbl_val_array_desc   IN tt_table_varchar DEFAULT NULL,
        i_codification         IN rehab_presc.id_codification%TYPE,
        i_flg_action           IN VARCHAR2,
        i_clinical_question_pk IN table_number,
        i_clinical_question    IN table_varchar,
        i_response             IN table_table_varchar,
        o_id_rehab_presc       OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'CREATE_REHAB_PRESC';
    BEGIN
        g_error := 'before call';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        IF NOT pk_rehab.create_rehab_presc(i_lang                 => i_lang,
                                           i_prof                 => i_prof,
                                           i_id_episode           => i_id_episode,
                                           i_id_patient           => i_id_patient,
                                           i_root_name            => i_root_name,
                                           i_tbl_records          => i_tbl_records,
                                           i_tbl_ds_internal_name => i_tbl_ds_internal_name,
                                           i_tbl_real_val         => i_tbl_real_val,
                                           i_tbl_val_mea          => i_tbl_val_mea,
                                           i_tbl_val_clob         => i_tbl_val_clob,
                                           i_tbl_val_array        => i_tbl_val_array,
                                           i_tbl_val_array_desc   => i_tbl_val_array_desc,
                                           i_codification         => i_codification,
                                           i_flg_action           => i_flg_action,
                                           i_clinical_question_pk => i_clinical_question_pk,
                                           i_clinical_question    => i_clinical_question,
                                           i_response             => i_response,
                                           o_id_rehab_presc       => o_id_rehab_presc,
                                           o_error                => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error('Parameters: i_id_episode=' || i_id_episode || ' @' || g_error,
                                  g_package_name,
                                  l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END create_rehab_presc;

    FUNCTION get_reasons_miss_session
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_reasons OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_REASONS_MISS_SESSION';
    BEGIN
        g_error := 'before call';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        IF NOT pk_rehab.get_reasons_miss_session(i_lang, i_prof, o_reasons, o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error, g_package_name, l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_reasons_miss_session;

    FUNCTION get_reasons_cancel_treat
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_reasons OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_REASONS_CANCEL_TREAT';
    BEGIN
        g_error := 'before call';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        IF NOT pk_rehab.get_reasons_cancel_treat(i_lang, i_prof, o_reasons, o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error, g_package_name, l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_reasons_cancel_treat;

    FUNCTION cancel_rehab_schedule
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_rehab_schedule IN rehab_schedule.id_rehab_schedule%TYPE,
        i_id_cancel_reason  IN rehab_schedule.id_cancel_reason%TYPE,
        i_notes             IN rehab_schedule.notes%TYPE DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'CANCEL_REHAB_SCHEDULE';
    BEGIN
        g_error := 'before call';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        IF NOT pk_rehab.cancel_rehab_schedule(i_lang              => i_lang,
                                              i_prof              => i_prof,
                                              i_id_rehab_schedule => i_id_rehab_schedule,
                                              i_id_cancel_reason  => i_id_cancel_reason,
                                              i_notes             => i_notes,
                                              o_error             => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error, g_package_name, l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END cancel_rehab_schedule;

    FUNCTION missed_rehab_schedule
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_rehab_schedule IN rehab_schedule.id_rehab_schedule%TYPE,
        i_id_missed_reason  IN rehab_schedule.flg_status%TYPE,
        i_notes             IN rehab_schedule.notes%TYPE DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'MISSED_REHAB_SCHEDULE';
    BEGIN
        g_error := 'before call';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        IF NOT pk_rehab.missed_rehab_schedule(i_lang              => i_lang,
                                              i_prof              => i_prof,
                                              i_id_rehab_schedule => i_id_rehab_schedule,
                                              i_id_missed_reason  => i_id_missed_reason,
                                              i_notes             => i_notes,
                                              o_error             => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error, g_package_name, l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END missed_rehab_schedule;

    -- Adds notes to a treatment plan
    FUNCTION set_treatment_plan_notes
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN rehab_notes.id_episode%TYPE,
        i_id_patient IN rehab_plan.id_patient%TYPE,
        i_notes      IN rehab_notes.notes%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'SET_TREATMENT_PLAN_NOTES';
    BEGIN
        g_error := 'before call';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        IF NOT pk_rehab.set_treatment_plan_notes(i_lang       => i_lang,
                                                 i_prof       => i_prof,
                                                 i_id_episode => i_id_episode,
                                                 i_id_patient => i_id_patient,
                                                 i_notes      => i_notes,
                                                 o_error      => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error, g_package_name, l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END set_treatment_plan_notes;

    FUNCTION create_rehab_session
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_patient            IN rehab_plan.id_patient%TYPE,
        i_id_rehab_presc        IN table_number,
        i_id_episode            IN rehab_session.id_episode%TYPE,
        i_id_rehab_area_interv  IN table_number,
        i_id_rehab_session_type IN table_varchar,
        i_id_exec_prof          IN rehab_session.id_professional%TYPE,
        i_dt_begin              IN VARCHAR2,
        i_dt_end                IN VARCHAR2,
        i_duration              IN NUMBER,
        i_notes                 IN VARCHAR2,
        o_id_rehab_session      OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'CREATE_REHAB_SESSION';
        e_function_call_error EXCEPTION;
    BEGIN
        g_error := 'Call pk_rehab.create_rehab_session';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT pk_rehab.create_rehab_session(i_lang                  => i_lang,
                                             i_prof                  => i_prof,
                                             i_id_patient            => i_id_patient,
                                             i_id_rehab_presc        => i_id_rehab_presc,
                                             i_id_episode            => i_id_episode,
                                             i_id_rehab_area_interv  => i_id_rehab_area_interv,
                                             i_id_rehab_session_type => i_id_rehab_session_type,
                                             i_id_exec_prof          => i_id_exec_prof,
                                             i_dt_begin              => i_dt_begin,
                                             i_dt_end                => i_dt_end,
                                             i_duration              => i_duration,
                                             i_notes                 => i_notes,
                                             o_id_rehab_session      => o_id_rehab_session,
                                             o_error                 => o_error)
        THEN
            RAISE e_function_call_error;
        END IF;
    
        g_error := 'Commit after call pk_rehab.create_rehab_session';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_function_call_error THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => o_error.ora_sqlcode,
                                              i_sqlerrm  => o_error.ora_sqlerrm,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END create_rehab_session;

    /**
    * Edits the execution data of treatment session
    *
    * @param   i_lang              Professional preferred language
    * @param   i_prof              Professional identification and its context (institution and software)
    * @param   i_id_rehab_session  List of executions to edit        
    * @param   i_id_episode        Episode ID
    * @param   i_id_exec_prof      Profissional ID who execute the session
    * @param   i_dt_begin          Begin date
    * @param   i_dt_end            End dete
    * @param   i_duration          Elapsed time
    * @param   i_notes             Notes
    *
    * @param   o_error             Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   26-Jul-10
    */
    FUNCTION set_rehab_session
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_rehab_session IN table_number,
        i_id_episode       IN rehab_session.id_episode%TYPE,
        i_id_exec_prof     IN rehab_session.id_professional%TYPE,
        i_dt_begin         IN VARCHAR2,
        i_dt_end           IN VARCHAR2,
        i_duration         IN NUMBER,
        i_notes            IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'SET_REHAB_SESSION';
        e_function_call_error EXCEPTION;
    
    BEGIN
        g_error := 'Call pk_rehab.set_rehab_session';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        IF NOT pk_rehab.set_rehab_session(i_lang             => i_lang,
                                          i_prof             => i_prof,
                                          i_id_rehab_session => i_id_rehab_session,
                                          i_id_episode       => i_id_episode,
                                          i_id_exec_prof     => i_id_exec_prof,
                                          i_dt_begin         => i_dt_begin,
                                          i_dt_end           => i_dt_end,
                                          i_duration         => i_duration,
                                          i_notes            => i_notes,
                                          o_error            => o_error)
        THEN
            RAISE e_function_call_error;
        END IF;
    
        g_error := 'Commit after call pk_rehab.set_rehab_session';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_function_call_error THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => o_error.ora_sqlcode,
                                              i_sqlerrm  => o_error.ora_sqlerrm,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_rehab_session;

    /**
    * Returns the detail of executions in a treatment session
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_id_rehab_presc     Prescribed treatment ID
    * @param   o_rehab_session_rec  Cursor with record info
    * @param   o_rehab_session_val  Cursor with session's executions info
    *
    * @param   o_error              Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   27-Jul-10
    */
    FUNCTION get_rehab_session_detail
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_rehab_presc       IN rehab_session.id_rehab_presc%TYPE,
        o_rehab_session_detail OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_REHAB_SESSION_DETAIL';
        e_function_call_error EXCEPTION;
    BEGIN
        g_error := 'Call pk_rehab.get_rehab_session_detail';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT pk_rehab.get_rehab_session_detail(i_lang                 => i_lang,
                                                 i_prof                 => i_prof,
                                                 i_id_rehab_presc       => i_id_rehab_presc,
                                                 o_rehab_session_detail => o_rehab_session_detail,
                                                 o_error                => o_error)
        THEN
            RAISE e_function_call_error;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_function_call_error THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => o_error.ora_sqlcode,
                                              i_sqlerrm  => o_error.ora_sqlerrm,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_rehab_session_detail);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_rehab_session_detail);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_rehab_session_detail;

    FUNCTION cancel_rehab_session
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_rehab_session IN table_number,
        i_id_cancel_reason IN rehab_session.id_cancel_reason%TYPE,
        i_notes            IN rehab_session.notes_cancel%TYPE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'CANCEL_REHAB_SESSION';
    BEGIN
        g_error := 'before call';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        IF NOT pk_rehab.cancel_rehab_session(i_lang             => i_lang,
                                             i_prof             => i_prof,
                                             i_id_rehab_session => i_id_rehab_session,
                                             i_id_cancel_reason => i_id_cancel_reason,
                                             i_notes            => i_notes,
                                             o_error            => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error, g_package_name, l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END cancel_rehab_session;

    FUNCTION cancel_rehab_presc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_rehab_presc   IN table_number,
        i_id_cancel_reason IN rehab_presc.id_cancel_reason%TYPE,
        i_notes            IN rehab_presc.notes_cancel%TYPE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'CANCEL_REHAB_PRESC';
    BEGIN
        g_error := 'before call';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        IF NOT pk_rehab.cancel_rehab_presc(i_lang             => i_lang,
                                           i_prof             => i_prof,
                                           i_id_rehab_presc   => i_id_rehab_presc,
                                           i_id_cancel_reason => i_id_cancel_reason,
                                           i_notes            => i_notes,
                                           o_error            => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error, g_package_name, l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END cancel_rehab_presc;

    FUNCTION cancel_rehab_sch_need
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_rehab_sch_need IN rehab_sch_need.id_rehab_sch_need%TYPE,
        i_id_cancel_reason  IN rehab_sch_need.id_cancel_reason%TYPE,
        i_notes             IN rehab_sch_need.notes_cancel%TYPE DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'CANCEL_REHAB_SCH_NEED';
    BEGIN
        g_error := 'before call';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        IF NOT pk_rehab.cancel_rehab_sch_need(i_lang              => i_lang,
                                              i_prof              => i_prof,
                                              i_id_rehab_sch_need => i_id_rehab_sch_need,
                                              i_id_cancel_reason  => i_id_cancel_reason,
                                              i_notes             => i_notes,
                                              o_error             => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error, g_package_name, l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END cancel_rehab_sch_need;

    -- retorna todos os tratamentos de uma necessidade de agendamento
    FUNCTION get_rehab_sch_need_treats
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN rehab_sch_need.id_episode_origin%TYPE,
        i_id_schedule IN rehab_schedule.id_schedule %TYPE,
        o_session     OUT pk_types.cursor_type,
        o_treats      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_REHAB_SCH_NEED_TREATS';
    BEGIN
        g_error := 'before call';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        IF NOT pk_rehab.get_rehab_sch_need_treats(i_lang        => i_lang,
                                                  i_prof        => i_prof,
                                                  i_id_episode  => i_id_episode,
                                                  i_id_schedule => i_id_schedule,
                                                  o_session     => o_session,
                                                  o_treats      => o_treats,
                                                  o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error, g_package_name, l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_rehab_sch_need_treats;

    FUNCTION get_dt_init
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_dt_init OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_DT_INIT';
    BEGIN
        g_error := 'before call';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        IF NOT pk_rehab.get_dt_init(i_lang    => i_lang,
                                    i_prof    => i_prof,
                                    i_episode => i_episode,
                                    o_dt_init => o_dt_init,
                                    o_error   => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error, g_package_name, l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_dt_init;

    -- retorna todas as execuções de uma necessidade de agendamento
    FUNCTION get_rehab_sch_need_exec
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_rehab_sch_need IN rehab_sch_need.id_rehab_sch_need%TYPE,
        o_executions        OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_REHAB_SCH_NEED_EXEC';
    BEGIN
        g_error := 'before call';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        IF NOT pk_rehab.get_rehab_sch_need_exec(i_lang              => i_lang,
                                                i_prof              => i_prof,
                                                i_id_rehab_sch_need => i_id_rehab_sch_need,
                                                o_executions        => o_executions,
                                                o_error             => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error, g_package_name, l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_rehab_sch_need_exec;

    -- retorna todas as execuções de uma lista de requisições
    FUNCTION get_rehab_presc_exec
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_rehab_presc IN table_number,
        o_executions     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_REHAB_PRESC_EXEC';
    BEGIN
        g_error := 'before call';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
    
        IF NOT pk_rehab.get_rehab_presc_exec(i_lang           => i_lang,
                                             i_prof           => i_prof,
                                             i_id_rehab_presc => i_id_rehab_presc,
                                             o_executions     => o_executions,
                                             o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error, g_package_name, l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_rehab_presc_exec;

    --
    FUNCTION update_rehab_presc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_rehab_presc      IN rehab_presc.id_rehab_presc%TYPE,
        i_id_rehab_sch_need   IN rehab_presc.id_rehab_sch_need%TYPE,
        i_id_exec_institution IN rehab_presc.id_exec_institution%TYPE,
        i_exec_per_session    IN rehab_presc.exec_per_session%TYPE,
        i_notes               IN rehab_presc.notes%TYPE,
        i_flg_laterality      IN rehab_presc.flg_laterality%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_REHAB_SCH_NEED_EXEC';
    BEGIN
        g_error := 'before call';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        IF NOT pk_rehab.update_rehab_presc(i_lang                => i_lang,
                                           i_prof                => i_prof,
                                           i_id_rehab_presc      => i_id_rehab_presc,
                                           i_id_rehab_sch_need   => i_id_rehab_sch_need,
                                           i_id_exec_institution => i_id_exec_institution,
                                           i_exec_per_session    => i_exec_per_session,
                                           i_notes               => i_notes,
                                           i_flg_laterality      => i_flg_laterality,
                                           o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error, g_package_name, l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END update_rehab_presc;

    -- get list of professionals and groups allocated to the areas
    FUNCTION get_prof_group_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_rehab_area IN table_number,
        o_prof_list     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_PROF_GROUP_LIST';
    
    BEGIN
        g_error := 'before call';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        IF NOT pk_rehab.get_prof_group_list(i_lang          => i_lang,
                                            i_prof          => i_prof,
                                            i_id_rehab_area => i_id_rehab_area,
                                            o_prof_list     => o_prof_list,
                                            o_error         => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error, g_package_name, l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_prof_group_list;

    -- get list of professionals allocated to the areas
    FUNCTION get_prof_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_rehab_area IN table_number,
        o_prof_list     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_PROF_LIST';
    BEGIN
        g_error := 'before call';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        IF NOT pk_rehab.get_prof_list(i_lang          => i_lang,
                                      i_prof          => i_prof,
                                      i_id_rehab_area => i_id_rehab_area,
                                      o_prof_list     => o_prof_list,
                                      o_error         => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error, g_package_name, l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_prof_list;

    -- get list of time units hora(s), minuto(s)
    FUNCTION get_time_units
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_units OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_TIME_UNITS';
    BEGIN
        g_error := 'before call';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        IF NOT pk_rehab.get_time_units(i_lang => i_lang, i_prof => i_prof, o_units => o_units, o_error => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error, g_package_name, l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_time_units;

    FUNCTION get_patients_grid
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_all_patients IN VARCHAR2,
        o_flg_show     OUT VARCHAR2,
        o_msg          OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_button       OUT VARCHAR2,
        o_patients     OUT pk_types.cursor_type,
        o_error        OUT t_error_out
        
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_PATIENTS_GRID';
    BEGIN
        g_error := 'before call';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
    
        IF NOT pk_rehab.get_patients_grid(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_all_patients => i_all_patients,
                                          o_flg_show     => o_flg_show,
                                          o_msg          => o_msg,
                                          o_msg_title    => o_msg_title,
                                          o_button       => o_button,
                                          o_patients     => o_patients,
                                          o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error, g_package_name, l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_patients_grid;

    -- aloca um profissional ou um grupo a uma necessidade de agendamento
    FUNCTION set_alloc_prof_sch_need
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_rehab_sch_need IN rehab_sch_need.id_rehab_sch_need%TYPE,
        i_id_resp           IN NUMBER,
        i_type              IN VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'SET_ALLOC_PROF_SCH_NEED';
    BEGIN
        g_error := 'before call';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
    
        IF NOT pk_rehab.set_alloc_prof_sch_need(i_lang              => i_lang,
                                                i_prof              => i_prof,
                                                i_id_rehab_sch_need => i_id_rehab_sch_need,
                                                i_id_resp           => i_id_resp,
                                                i_type              => i_type,
                                                o_error             => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error, g_package_name, l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END set_alloc_prof_sch_need;

    FUNCTION get_origin_episode
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_id_schedule       IN epis_info.id_schedule%TYPE,
        o_id_episode_origin OUT rehab_plan.id_episode_origin%TYPE,
        o_id_schedule       OUT rehab_schedule.id_schedule%TYPE,
        o_id_epis_type      OUT episode.id_epis_type%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'SET_ALLOC_PROF_SCH_NEED';
    BEGIN
        g_error := 'before call';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
    
        IF NOT pk_rehab.get_origin_episode(i_lang              => i_lang,
                                           i_prof              => i_prof,
                                           i_id_episode        => i_id_episode,
                                           i_id_schedule       => i_id_schedule,
                                           o_id_episode_origin => o_id_episode_origin,
                                           o_id_schedule       => o_id_schedule,
                                           o_id_epis_type      => o_id_epis_type,
                                           o_error             => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error, g_package_name, l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_origin_episode;

    /********************************************************************************************
    * Get the detail for the Rehabilitation treatments
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_rehab_presc         Rehabilitaion prescription ID
    * @param o_rehab_treatment        Treatments details
    * @param o_rehab_treatment_prof   Professional details
    * @param o_rehab_session_detail
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/07/
    **********************************************************************************************/
    FUNCTION get_rehab_treatment_detail
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_rehab_presc       IN rehab_presc.id_rehab_presc%TYPE,
        o_rehab_treatment      OUT pk_types.cursor_type,
        o_rehab_treatment_prof OUT pk_types.cursor_type,
        o_rehab_session_detail OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_REHAB_TREATMENT_DETAIL';
    BEGIN
        --
        g_error := 'CALL GET_REHAB_TREATMENT_DETAIL: i_id_rehab_presc = ' || i_id_rehab_presc;
        pk_alertlog.log_debug(g_error);
    
        IF NOT pk_rehab.get_rehab_treatment_detail(i_lang                 => i_lang,
                                                   i_prof                 => i_prof,
                                                   i_id_rehab_presc       => i_id_rehab_presc,
                                                   o_rehab_treatment      => o_rehab_treatment,
                                                   o_rehab_treatment_prof => o_rehab_treatment_prof,
                                                   o_rehab_session_detail => o_rehab_session_detail,
                                                   o_error                => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_rehab_treatment);
            pk_types.open_my_cursor(o_rehab_treatment_prof);
            pk_types.open_my_cursor(o_rehab_session_detail);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
    END get_rehab_treatment_detail;
    --

    /********************************************************************************************
    * Get the detail for the Rehabilitation sessions
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_rehab_sch_need      Rehabilitaion session ID
    * @param o_rehab_treatment        Treatments details
    * @param o_rehab_treatment_prof   Professional details
    
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/07/
    **********************************************************************************************/
    FUNCTION get_rehab_sch_need_detail
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_sch_need  IN rehab_sch_need.id_rehab_sch_need%TYPE,
        o_rehab_session      OUT pk_types.cursor_type,
        o_rehab_session_prof OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_REHAB_SESSION_DETAIL';
    BEGIN
        --
        g_error := 'CALL GET_REHAB_SESSION_DETAIL: i_id_rehab_sch_need = ' || i_id_rehab_sch_need;
        pk_alertlog.log_debug(g_error);
    
        IF NOT pk_rehab.get_rehab_sch_need_detail(i_lang               => i_lang,
                                                  i_prof               => i_prof,
                                                  i_id_rehab_sch_need  => i_id_rehab_sch_need,
                                                  o_rehab_session      => o_rehab_session,
                                                  o_rehab_session_prof => o_rehab_session_prof,
                                                  o_error              => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_rehab_session);
            pk_types.open_my_cursor(o_rehab_session_prof);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
    END get_rehab_sch_need_detail;
    --

    /********************************************************************************************
    * Get the detail for the Rehabilitation sessions
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_rehab_sch_need      Rehabilitaion session ID
    * @param o_rehab_treatment        Treatments details
    * @param o_rehab_treatment_prof   Professional details
    
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/07/
    **********************************************************************************************/
    FUNCTION get_treatments_edit
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_rehab_presc  IN rehab_presc.id_rehab_presc%TYPE,
        o_rehab_treatment OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_TREATMENTS_EDIT';
    BEGIN
        --
        g_error := 'CALL GET_REHAB_SESSION_DETAIL: i_id_rehab_presc = ' || i_id_rehab_presc;
        pk_alertlog.log_debug(g_error);
    
        IF NOT pk_rehab.get_treatments_edit(i_lang            => i_lang,
                                            i_prof            => i_prof,
                                            i_id_rehab_presc  => i_id_rehab_presc,
                                            o_rehab_treatment => o_rehab_treatment,
                                            o_error           => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_rehab_treatment);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
    END get_treatments_edit;
    --

    FUNCTION set_rehab_presc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN rehab_plan.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        --
        i_id_rehab_presc       IN rehab_presc.id_rehab_presc%TYPE,
        i_id_rehab_area_interv IN rehab_presc.id_rehab_area_interv%TYPE,
        i_id_rehab_sch_need    IN rehab_sch_need.id_rehab_sch_need%TYPE,
        i_id_exec_institution  IN rehab_presc.id_exec_institution%TYPE,
        i_exec_per_session     IN rehab_presc.exec_per_session%TYPE,
        i_presc_notes          IN rehab_presc.notes%TYPE,
        i_sessions             IN rehab_sch_need.sessions%TYPE,
        i_frequency            IN rehab_sch_need.frequency%TYPE,
        i_flg_frequency        IN rehab_sch_need.flg_frequency%TYPE,
        i_flg_priority         IN rehab_sch_need.flg_priority%TYPE,
        i_date_begin           IN VARCHAR2,
        i_session_notes        IN rehab_sch_need.notes%TYPE,
        i_session_type         IN rehab_sch_need.id_rehab_session_type%TYPE,
        i_flg_laterality       IN rehab_presc.flg_laterality%TYPE,
        i_id_not_order_reason  IN rehab_presc.id_not_order_reason%TYPE,
        --
        o_id_rehab_presc OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(30) := 'SET_REHAB_PRESC';
    
    BEGIN
    
        --
        g_error := 'CALL SET_REHAB_PRESC: i_id_rehab_presc = ' || i_id_rehab_presc;
        pk_alertlog.log_debug(g_error);
    
        IF NOT pk_rehab.set_rehab_presc(i_lang                 => i_lang,
                                        i_prof                 => i_prof,
                                        i_id_patient           => i_id_patient,
                                        i_id_episode           => i_id_episode,
                                        i_id_rehab_presc       => i_id_rehab_presc,
                                        i_id_rehab_area_interv => i_id_rehab_area_interv,
                                        i_id_rehab_sch_need    => i_id_rehab_sch_need,
                                        i_id_exec_institution  => i_id_exec_institution,
                                        i_exec_per_session     => i_exec_per_session,
                                        i_presc_notes          => i_presc_notes,
                                        i_sessions             => i_sessions,
                                        i_frequency            => i_frequency,
                                        i_flg_frequency        => i_flg_frequency,
                                        i_flg_priority         => i_flg_priority,
                                        i_date_begin           => i_date_begin,
                                        i_session_notes        => i_session_notes,
                                        i_session_type         => i_session_type,
                                        i_flg_laterality       => i_flg_laterality,
                                        i_id_not_order_reason  => i_id_not_order_reason,
                                        o_id_rehab_presc       => o_id_rehab_presc,
                                        o_error                => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error('Parameters: i_id_patient=' || i_id_patient || ' @' || g_error,
                                  g_package_name,
                                  l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END set_rehab_presc;

    /**************************************************************************
    * Creates rehabilitation diagnosis associated to the patient episode      *
    *                                                                         *
    * @param i_lang                   language id                             *
    * @param i_prof                   professional, software and              *
    *                                 institution ids                         *
    * @param i_episode                Episode id                              *
    * @param i_patient                Patient id                              *
    * @param i_icf                    List of ID of ICF component             *
    * @param i_iq_initial_incapacity  List of ID of the qualifier for initial *
    *                                 incapacity                              *
    * @param i_iqs_initial_incapacity List of ID of qualification scale for   *
    *                                 initial incapacity                      *
    * @param i_iq_expected_result     List of ID of the qualifier for expected*
    *                                 result                                  *
    * @param i_iqs_expected_result    List of ID of qualification scale for   *
    *                                 expected result                         *
    * @param i_iq_active_incapacity   List of ID of the qualifier for active  *
    *                                 incapacity                              *
    * @param i_iqs_active_incapacity  List of ID of qualification scale for   *
    *                                 active incapacity                       *       
    *                                                                         *
    * @param o_error                  Error message                           *
    * @param o_id_rehab_diagnosis     List of generated rehab diagnosis       *
    *                                 requests                                *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2010/07/16                              *
    **************************************************************************/
    FUNCTION create_rehab_diag
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_patient                IN patient.id_patient%TYPE,
        i_icf                    IN table_number,
        i_iq_initial_incapacity  IN table_number,
        i_iqs_initial_incapacity IN table_number,
        i_iq_expected_result     IN table_number,
        i_iqs_expected_result    IN table_number,
        i_iq_active_incapacity   IN table_number,
        i_iqs_active_incapacity  IN table_number,
        i_notes                  IN table_varchar,
        o_id_rehab_diagnosis     OUT table_number,
        o_flg_show               OUT VARCHAR2,
        o_msg                    OUT VARCHAR2,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'CREATE_REHAB_DIAG';
    
        l_error t_error_out;
        l_exception EXCEPTION;
    BEGIN
        g_error := 'Call pk_rehab.create_rehab_diag';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        IF NOT pk_rehab.create_rehab_diag(i_lang                   => i_lang,
                                          i_prof                   => i_prof,
                                          i_episode                => i_episode,
                                          i_patient                => i_patient,
                                          i_icf                    => i_icf,
                                          i_iq_initial_incapacity  => i_iq_initial_incapacity,
                                          i_iqs_initial_incapacity => i_iqs_initial_incapacity,
                                          i_iq_expected_result     => i_iq_expected_result,
                                          i_iqs_expected_result    => i_iqs_expected_result,
                                          i_iq_active_incapacity   => i_iq_active_incapacity,
                                          i_iqs_active_incapacity  => i_iqs_active_incapacity,
                                          i_notes                  => i_notes,
                                          o_id_rehab_diagnosis     => o_id_rehab_diagnosis,
                                          o_flg_show               => o_flg_show,
                                          o_msg                    => o_msg,
                                          o_error                  => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF o_flg_show = pk_alert_constant.g_yes
        THEN
            pk_utils.undo_changes;
            RETURN TRUE;
        END IF;
    
        g_error := 'Commit';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_rehab_diag;

    /**************************************************************************
    * Edits rehabilitation diagnosis data associated to the patient episode   *
    *                                                                         *
    * @param i_lang                   language id                             *
    * @param i_prof                   professional, software and              *
    *                                 institution ids                         *
    * @param i_id_rehab_diagnosis     list of rehab dianossis identifiers to  *
    *                                 cancel                                  *
    * @param i_episode                Episode id                              *
    * @param i_icf                    List of ID of ICF component             *
    * @param i_iq_initial_incapacity  List of ID of the qualifier for initial *
    *                                 incapacity                              *
    * @param i_iqs_initial_incapacity List of ID of qualification scale for   *
    *                                 initial incapacity                      *
    * @param i_iq_expected_result     List of ID of the qualifier for expected*
    *                                 result                                  *
    * @param i_iqs_expected_result    List of ID of qualification scale for   *
    *                                 expected result                         *
    * @param i_iq_active_incapacity   List of ID of the qualifier for active  *
    *                                 incapacity                              *
    * @param i_iqs_active_incapacity  List of ID of qualification scale for   *
    *                                 active incapacity                       *       
    *                                                                         *
    * @param o_error                  Error message                           *
    * @param o_id_rehab_diagnosis     List of generated rehab diagnosis       *
    *                                 requests                                *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2010/07/16                              *
    **************************************************************************/
    FUNCTION set_rehab_diag
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_rehab_diagnosis     IN table_number,
        i_episode                IN episode.id_episode%TYPE,
        i_icf                    IN table_number,
        i_iq_initial_incapacity  IN table_number,
        i_iqs_initial_incapacity IN table_number,
        i_iq_expected_result     IN table_number,
        i_iqs_expected_result    IN table_number,
        i_iq_active_incapacity   IN table_number,
        i_iqs_active_incapacity  IN table_number,
        i_status                 IN table_varchar,
        i_notes                  IN table_varchar,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'SET_REHAB_DIAG';
    
        l_error t_error_out;
        l_exception EXCEPTION;
    BEGIN
        g_error := 'Call pk_rehab.create_rehab_diag';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        IF NOT pk_rehab.set_rehab_diag(i_lang                   => i_lang,
                                       i_prof                   => i_prof,
                                       i_id_rehab_diagnosis     => i_id_rehab_diagnosis,
                                       i_episode                => i_episode,
                                       i_icf                    => i_icf,
                                       i_iq_initial_incapacity  => i_iq_initial_incapacity,
                                       i_iqs_initial_incapacity => i_iqs_initial_incapacity,
                                       i_iq_expected_result     => i_iq_expected_result,
                                       i_iqs_expected_result    => i_iqs_expected_result,
                                       i_iq_active_incapacity   => i_iq_active_incapacity,
                                       i_iqs_active_incapacity  => i_iqs_active_incapacity,
                                       i_status                 => i_status,
                                       i_notes                  => i_notes,
                                       o_error                  => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'Commit';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_rehab_diag;

    /**************************************************************************
    * Cancels rehabilitation diagnosis data associated to the patient episode *
    *                                                                         *
    * @param i_lang                   language id                             *
    * @param i_prof                   professional, software and              *
    *                                 institution ids                         *
    * @param i_id_rehab_diagnosis     list of rehab dianossis identifiers to  *
    *                                 cancel                                  *
    * @param i_episode                Episode id                              *
    *                                                                         *
    * @param o_error                  Error message                           *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2010/07/21                              *
    **************************************************************************/
    FUNCTION cancel_rehab_diag
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_diagnosis IN table_number,
        i_episode            IN episode.id_episode%TYPE,
        i_id_cancel_reason   IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes       IN rehab_diagnosis.notes_cancel%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'CANCEL_REHAB_DIAG';
    
        l_error t_error_out;
        l_exception EXCEPTION;
    BEGIN
        g_error := 'Call pk_rehab.create_rehab_diag';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        IF NOT pk_rehab.cancel_rehab_diag(i_lang               => i_lang,
                                          i_prof               => i_prof,
                                          i_id_rehab_diagnosis => i_id_rehab_diagnosis,
                                          i_episode            => i_episode,
                                          i_id_cancel_reason   => i_id_cancel_reason,
                                          i_cancel_notes       => i_cancel_notes,
                                          o_error              => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'Commit';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_rehab_diag;

    /**************************************************************************
    * Cancels rehabilitation diagnosis data associated to the patient episode *
    *                                                                         *
    * @param i_lang                   language id                             *
    * @param i_prof                   professional, software and              *
    *                                 institution ids                         *
    * @param i_id_rehab_diagnosis     list of rehab diagnosis identifiers to  *
    *                                 cancel                                  *
    * @param i_episode                Episode id                              *
    *                                                                         *
    * @param o_error                  Error message                           *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2010/07/21                              *
    **************************************************************************/
    FUNCTION get_rehab_diag_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        o_rehab_diag OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_REHAB_DIAG_LIST';
    
        l_error t_error_out;
        l_exception EXCEPTION;
    BEGIN
        g_error := 'Call pk_rehab.create_rehab_diag';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        IF NOT pk_rehab.get_rehab_diag_list(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_episode    => i_episode,
                                            o_rehab_diag => o_rehab_diag,
                                            o_error      => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_rehab_diag_list;

    /**************************************************************************
    * Returns information to put in the Rehab Diagnosis Detail screen         *
    *                                                                         *
    * @param i_lang                   language id                             *
    * @param i_prof                   professional, software and              *
    *                                 institution ids                         *
    * @param i_rehab_diagnosis        Rehab diagnosis Id                      *
    *                                                                         *
    * @param o_error                  Error message                           *
    * @param o_rehab_diag_detail      Cursor with rehab diagnosis detail info *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2010/07/22                              *
    **************************************************************************/
    FUNCTION get_rehab_diag_detail
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_rehab_diagnosis   IN rehab_diagnosis.id_rehab_diagnosis%TYPE,
        o_rehab_diag_detail OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_REHAB_DIAG_DETAIL';
    
        l_error t_error_out;
        l_exception EXCEPTION;
    BEGIN
        g_error := 'Call pk_rehab.get_rehab_diag_detail';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        IF NOT pk_rehab.get_rehab_diag_detail(i_lang              => i_lang,
                                              i_prof              => i_prof,
                                              i_rehab_diagnosis   => i_rehab_diagnosis,
                                              o_rehab_diag_detail => o_rehab_diag_detail,
                                              o_error             => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_rehab_diag_detail;

    /**************************************************************************
    * Returns Rehab Diagnosis actions list                                    *
    *                                                                         *
    * @param i_lang                   language id                             *
    * @param i_prof                   professional, software and              *
    *                                 institution ids                         *
    *                                                                         *
    * @param o_error                  Error message                           *
    * @param o_rehab_diag_actions     Cursor with rehab diagnosis actions     *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2010/07/26                              *
    **************************************************************************/
    FUNCTION get_rehab_diag_actions
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        o_rehab_diag_actions OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_REHAB_DIAG_ACTIONS';
    
        l_error t_error_out;
        l_exception EXCEPTION;
    BEGIN
        g_error := 'Call pk_sysdomain.get_values_domain';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        IF NOT pk_sysdomain.get_values_domain(i_code_dom      => 'REHAB_DIAGNOSIS.FLG_STATUS',
                                              i_lang          => i_lang,
                                              o_data          => o_rehab_diag_actions,
                                              o_error         => l_error,
                                              i_vals_included => NULL,
                                              i_vals_excluded => table_varchar('C'))
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_rehab_diag_actions;

    /**********************************************************************************************
    * retorna os pacientes com tratamentos para hoje
    *
    * %param i_lang                   id_language
    * %param i_prof                   id_professional
    * %param i_type                   A-appointments S-Scheduled else NonScheduled
    * %param i_status                 from state
    * %param o_status                 List of to states
    * %param o_error                  error message
    *
    * @return                         TRUE on success, FALSE otherwise
    *
    * @author                         Eduardo Reis
    * @version                        1.0
    * @since                          2010-08-21
    **********************************************************************************************/
    FUNCTION get_grid_workflow_status
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_type   IN VARCHAR2,
        i_status IN VARCHAR2,
        o_status OUT pk_types.cursor_type,
        o_error  OUT t_error_out
        
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_GRID_WORKFLOW_STATUS';
    
    BEGIN
    
        g_error := 'Call pk_rehab.get_grid_workflow_status';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        IF NOT pk_rehab.get_grid_workflow_status(i_lang   => i_lang,
                                                 i_prof   => i_prof,
                                                 i_type   => i_type,
                                                 i_status => i_status,
                                                 o_status => o_status,
                                                 o_error  => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     l_func_name,
                                                     o_error);
        
    END get_grid_workflow_status;
    --

    -- This function can be used to edit a given treatment
    FUNCTION set_rehab_workflow_change
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN rehab_plan.id_patient%TYPE,
        --
        i_workflow_type  IN VARCHAR2,
        i_from_state     IN VARCHAR2,
        i_to_state       IN VARCHAR2,
        i_id_rehab_grid  IN NUMBER,
        i_id_rehab_presc IN rehab_sch_need.id_rehab_sch_need%TYPE,
        --create_visit
        i_id_epis_origin    IN episode.id_episode%TYPE,
        i_id_rehab_schedule IN rehab_schedule.id_rehab_schedule%TYPE,
        i_id_schedule       IN schedule.id_schedule%TYPE,
        --
        i_id_cancel_reason IN rehab_schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN rehab_schedule.notes%TYPE DEFAULT NULL,
        i_lock_uq_value    IN NUMBER,
        i_lock_func        IN VARCHAR2,
        i_id_lock          IN NUMBER,
        --
        o_id_episode OUT episode.id_episode%TYPE,
        o_lock       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
        
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'SET_REHAB_WORKFLOW_CHANGE';
        l_transaction_id VARCHAR2(4000);
        l_context        table_varchar := table_varchar(i_lock_func);
        l_lock_count     NUMBER := -1;
    
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, i_prof);
    
        g_error := 'SET_REHAB_WORKFLOW_CHANGE: i_id_patient = ' || i_id_patient;
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
    
        IF i_lock_func IS NOT NULL
        THEN
        
            IF NOT pk_lock.save_lock(i_lang       => i_lang,
                                     i_prof       => i_prof,
                                     i_lock_print => table_number(i_id_lock),
                                     i_tbl_func   => l_context,
                                     i_tbl_ids    => table_number(i_lock_uq_value),
                                     i_flg_save   => pk_alert_constant.g_yes,
                                     o_sql        => o_lock,
                                     o_lock_count => l_lock_count,
                                     o_error      => o_error)
            
            THEN
                RETURN FALSE;
            END IF;
        
        END IF;
    
        IF NOT (l_lock_count > 0)
           OR i_lock_func IS NULL
        THEN
            IF NOT pk_rehab.set_rehab_workflow_change(i_lang              => i_lang,
                                                      i_prof              => i_prof,
                                                      i_id_patient        => i_id_patient,
                                                      i_workflow_type     => i_workflow_type,
                                                      i_from_state        => i_from_state,
                                                      i_to_state          => i_to_state,
                                                      i_id_rehab_grid     => i_id_rehab_grid,
                                                      i_id_rehab_presc    => i_id_rehab_presc,
                                                      i_id_epis_origin    => i_id_epis_origin,
                                                      i_id_rehab_schedule => i_id_rehab_schedule,
                                                      i_id_schedule       => i_id_schedule,
                                                      i_id_cancel_reason  => i_id_cancel_reason,
                                                      i_cancel_notes      => i_cancel_notes,
                                                      i_transaction_id    => l_transaction_id,
                                                      o_id_episode        => o_id_episode,
                                                      o_error             => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        IF l_transaction_id IS NOT NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error('Parameters: i_id_patient=' || i_id_patient || ' @' || g_error,
                                  g_package_name,
                                  l_func_name);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END set_rehab_workflow_change;

    FUNCTION get_rehab_icf_list
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_id_icf                     IN icf_qualification_rel.id_icf%TYPE,
        i_id_icf_qualification_scale IN icf_qualification_rel.id_icf_qualification_scale%TYPE,
        i_flg_level                  IN icf_qualification_rel.flg_level%TYPE,
        o_qualif                     OUT pk_types.cursor_type,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_REHAB_ICF_LIST';
    
    BEGIN
        g_error := '';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
    
        IF NOT pk_rehab.get_rehab_icf_list(i_lang                       => i_lang,
                                           i_prof                       => i_prof,
                                           i_id_icf                     => i_id_icf,
                                           i_id_icf_qualification_scale => i_id_icf_qualification_scale,
                                           i_flg_level                  => i_flg_level,
                                           o_qualif                     => o_qualif,
                                           o_error                      => o_error)
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
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_rehab_icf_list;

    FUNCTION update_rsn_flg_status
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_rehab_schedule_need IN rehab_sch_need.id_rehab_sch_need%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'UPDATE_RSN_FLG_STATUS';
    
    BEGIN
        g_error := '';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
    
        IF NOT pk_rehab.update_rsn_flg_status(i_lang                   => i_lang,
                                              i_prof                   => i_prof,
                                              i_id_rehab_schedule_need => i_id_rehab_schedule_need,
                                              o_error                  => o_error)
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
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END update_rsn_flg_status;

    FUNCTION update_rehab_presc_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_rehab_presc IN table_number, --ARRAY
        i_to_state       IN action.to_state%TYPE,
        i_notes          IN rehab_presc.notes%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'UPDATE_REHAB_PRESC_STATUS';
    
    BEGIN
        g_error := '';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
    
        IF NOT pk_rehab.update_rehab_presc_status(i_lang           => i_lang,
                                                  i_prof           => i_prof,
                                                  i_id_rehab_presc => i_id_rehab_presc,
                                                  i_to_state       => i_to_state,
                                                  i_notes          => i_notes,
                                                  o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END update_rehab_presc_status;

    -- pesquisa de pacientes
    FUNCTION get_patients_mfr
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_crit   IN table_number,
        i_crit_cond IN table_varchar,
        i_flg_state IN VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_pat       OUT pk_types.cursor_type,
        o_error     OUT t_error_out
        
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_PATIENTS_MFR';
    
    BEGIN
        g_error := 'begin';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
    
        IF NOT pk_rehab.get_patients_mfr(i_lang      => i_lang,
                                         i_prof      => i_prof,
                                         i_id_crit   => i_id_crit,
                                         i_crit_cond => i_crit_cond,
                                         i_flg_state => i_flg_state,
                                         o_flg_show  => o_flg_show,
                                         o_msg       => o_msg,
                                         o_msg_title => o_msg_title,
                                         o_button    => o_button,
                                         o_pat       => o_pat,
                                         o_error     => o_error)
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
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_patients_mfr;

    /**********************************************************************************************
    * Accepts a rehab_presc proposal of suspension, discontinuation or edition
    *
    * %param i_lang                   id_language
    * %param i_prof                   id_professional
    * %param i_id_rehab_presc         treatment prescription
    * %param i_notes                  notes about status change
    * %param o_error                  error message
    *
    * @return                         TRUE on success, FALSE otherwise
    *
    * @author                         Eduardo Reis
    * @version                        1.0
    * @since                          2010-08-21
    **********************************************************************************************/
    FUNCTION accept_rehab_presc_proposal
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_rehab_presc IN rehab_presc.id_rehab_presc%TYPE,
        i_notes          IN rehab_presc.notes_change%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'ACCEPT_REHAB_PRESC_PROPOSAL';
    
    BEGIN
        g_error := 'begin';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
    
        IF NOT pk_rehab.accept_rehab_presc_proposal(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_id_rehab_presc => i_id_rehab_presc,
                                                    i_notes          => i_notes,
                                                    o_error          => o_error)
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
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END accept_rehab_presc_proposal;

    /**********************************************************************************************
    * Rejects a rehab_presc proposal of suspension, discontinuation or edition
    *
    * %param i_lang                   id_language
    * %param i_prof                   id_professional
    * %param i_id_rehab_presc         treatment prescription
    * %param i_notes                  notes about status change
    * %param o_error                  error message
    *
    * @return                         TRUE on success, FALSE otherwise
    *
    * @author                         Eduardo Reis
    * @version                        1.0
    * @since                          2010-08-21
    **********************************************************************************************/
    FUNCTION reject_rehab_presc_proposal
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_rehab_presc IN rehab_presc.id_rehab_presc%TYPE,
        i_notes          IN rehab_presc.notes_change%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'REJECT_REHAB_PRESC_PROPOSAL';
    
    BEGIN
        g_error := 'begin';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
    
        IF NOT pk_rehab.reject_rehab_presc_proposal(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_id_rehab_presc => i_id_rehab_presc,
                                                    i_notes          => i_notes,
                                                    o_error          => o_error)
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
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END reject_rehab_presc_proposal;

    /**********************************************************************************************
    * Cancels a rehab_presc proposal of suspension, discontinuation or edition
    *
    * %param i_lang                   id_language
    * %param i_prof                   id_professional
    * %param i_id_rehab_presc         treatment prescription
    * %param o_error                  error message
    *
    * @return                         TRUE on success, FALSE otherwise
    *
    * @author                         Joao Martins
    * @version                        v2.6.0.5.1.5
    * @since                          2011-02-10
    **********************************************************************************************/
    FUNCTION cancel_rehab_presc_proposal
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_rehab_presc IN rehab_presc.id_rehab_presc%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'CANCEL_REHAB_PRESC_PROPOSAL';
    
    BEGIN
        g_error := 'Call cancel_rehab_presc_proposal';
        RETURN pk_rehab.cancel_rehab_presc_proposal(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_id_rehab_presc => i_id_rehab_presc,
                                                    o_error          => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END cancel_rehab_presc_proposal;

    /**
    * get_rehab_menu_plans
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   06-12-2010 19:14:35
    */
    FUNCTION get_rehab_menu_plans
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN action.from_state%TYPE,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'get_rehab_menu_plans';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text            => g_error,
                                       object_name     => g_package_name,
                                       sub_object_name => l_sub_object_name);
    
        IF NOT pk_rehab_plan.get_rehab_menu_plans(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_subject    => i_subject,
                                                  i_from_state => i_from_state,
                                                  o_actions    => o_actions,
                                                  o_error      => o_error)
        THEN
            RAISE e_controlled_error;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
            l_action_message := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Action Message Code>');
            l_error_message  := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Error Message Code>');
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => SQLCODE,
                                              i_sqlerrm     => SQLERRM,
                                              i_message     => l_error_message,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => l_sub_object_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_sub_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_rehab_menu_plans;

    /**
    * get_prof_by_cat
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   06-12-2010 19:18:44
    */
    FUNCTION get_prof_by_cat
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_category IN category.id_category%TYPE DEFAULT NULL,
        o_curs        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'get_prof_by_cat';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text            => g_error,
                                       object_name     => g_package_name,
                                       sub_object_name => l_sub_object_name);
    
        IF NOT pk_rehab_plan.get_prof_by_cat(i_lang        => i_lang,
                                             i_prof        => i_prof,
                                             i_id_category => i_id_category,
                                             o_curs        => o_curs,
                                             o_error       => o_error)
        THEN
            RAISE e_controlled_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
            l_action_message := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Action Message Code>');
            l_error_message  := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Error Message Code>');
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => SQLCODE,
                                              i_sqlerrm     => SQLERRM,
                                              i_message     => l_error_message,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => l_sub_object_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_sub_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_prof_by_cat;

    /**
    * get_team
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   06-12-2010 19:22:18
    */
    FUNCTION get_team
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan_team.id_rehab_epis_plan%TYPE,
        o_team               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'get_team';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text            => g_error,
                                       object_name     => g_package_name,
                                       sub_object_name => l_sub_object_name);
    
        IF NOT pk_rehab_plan.get_team(i_lang               => i_lang,
                                      i_prof               => i_prof,
                                      i_id_rehab_epis_plan => i_id_rehab_epis_plan,
                                      o_team               => o_team,
                                      o_error              => o_error)
        THEN
            RAISE e_controlled_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
            l_action_message := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Action Message Code>');
            l_error_message  := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Error Message Code>');
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => SQLCODE,
                                              i_sqlerrm     => SQLERRM,
                                              i_message     => l_error_message,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => l_sub_object_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_sub_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_team;

    /**
    * get_general_info
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   06-12-2010 19:39:19
    */
    FUNCTION get_general_info
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN rehab_epis_plan.id_episode%TYPE,
        o_info       OUT pk_types.cursor_type,
        o_team       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'get_general_info';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text            => g_error,
                                       object_name     => g_package_name,
                                       sub_object_name => l_sub_object_name);
    
        IF NOT pk_rehab_plan.get_general_info(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_id_episode => i_id_episode,
                                              o_info       => o_info,
                                              o_team       => o_team,
                                              o_error      => o_error)
        THEN
            RAISE e_controlled_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
            l_action_message := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Action Message Code>');
            l_error_message  := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Error Message Code>');
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => SQLCODE,
                                              i_sqlerrm     => SQLERRM,
                                              i_message     => l_error_message,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => l_sub_object_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_sub_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_general_info;

    /**
    * insert_plan_areas
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   06-12-2010 19:39:19
    */
    FUNCTION set_plan_areas
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_rehab_epis_plan       IN rehab_epis_plan_area.id_rehab_epis_plan%TYPE,
        i_id_rehab_plan_area       IN table_number,
        i_id_rehab_epis_plan_area  IN table_number,
        i_current_situation        IN table_varchar,
        i_goals                    IN table_varchar,
        i_methodology              IN table_varchar,
        i_time                     IN table_number,
        i_flg_time_unit            IN table_varchar,
        i_id_prof_cat              IN table_table_number,
        i_id_rehab_epis_plan_sug   IN table_number,
        i_suggestions              IN table_varchar,
        i_id_rehab_epis_plan_notes IN table_number,
        i_notes                    IN table_varchar,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'set_plan_areas';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text            => g_error,
                                       object_name     => g_package_name,
                                       sub_object_name => l_sub_object_name);
    
        IF NOT pk_rehab_plan.set_plan_areas(i_lang                     => i_lang,
                                            i_prof                     => i_prof,
                                            i_id_rehab_epis_plan       => i_id_rehab_epis_plan,
                                            i_id_rehab_plan_area       => i_id_rehab_plan_area,
                                            i_id_rehab_epis_plan_area  => i_id_rehab_epis_plan_area,
                                            i_current_situation        => i_current_situation,
                                            i_goals                    => i_goals,
                                            i_methodology              => i_methodology,
                                            i_time                     => i_time,
                                            i_flg_time_unit            => i_flg_time_unit,
                                            i_id_prof_cat              => i_id_prof_cat,
                                            i_id_rehab_epis_plan_sug   => i_id_rehab_epis_plan_sug,
                                            i_suggestions              => i_suggestions,
                                            i_id_rehab_epis_plan_notes => i_id_rehab_epis_plan_notes,
                                            i_notes                    => i_notes,
                                            o_error                    => o_error)
        THEN
            RAISE e_controlled_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
            l_action_message := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Action Message Code>');
            l_error_message  := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Error Message Code>');
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => SQLCODE,
                                              i_sqlerrm     => SQLERRM,
                                              i_message     => l_error_message,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => l_sub_object_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_sub_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END set_plan_areas;

    /**
    * INSERT_GENERAL_INFO
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   07-12-2010 15:06:12
    */
    FUNCTION set_general_info
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan.id_rehab_epis_plan%TYPE,
        i_id_episode         IN rehab_epis_plan.id_episode%TYPE,
        i_id_prof_cat        IN table_number,
        i_creat_date         IN VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'set_general_info';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text            => g_error,
                                       object_name     => g_package_name,
                                       sub_object_name => l_sub_object_name);
    
        IF NOT pk_rehab_plan.set_general_info(i_lang               => i_lang,
                                              i_prof               => i_prof,
                                              i_id_rehab_epis_plan => i_id_rehab_epis_plan,
                                              i_id_episode         => i_id_episode,
                                              i_id_prof_cat        => i_id_prof_cat,
                                              i_creat_date         => i_creat_date,
                                              o_error              => o_error)
        THEN
            RAISE e_controlled_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
            l_action_message := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Action Message Code>');
            l_error_message  := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Error Message Code>');
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => SQLCODE,
                                              i_sqlerrm     => SQLERRM,
                                              i_message     => l_error_message,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => l_sub_object_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_sub_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END set_general_info;

    /**
    * get_all_plan
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   07-12-2010 15:06:12
    */
    FUNCTION get_all_plan
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan_area.id_rehab_epis_plan%TYPE,
        o_info               OUT pk_types.cursor_type,
        o_notes              OUT pk_types.cursor_type,
        o_suggest            OUT pk_types.cursor_type,
        o_obj_profs          OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'get_all_plan';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text            => g_error,
                                       object_name     => g_package_name,
                                       sub_object_name => l_sub_object_name);
    
        IF NOT pk_rehab_plan.get_all_plan(i_lang               => i_lang,
                                          i_prof               => i_prof,
                                          i_id_rehab_epis_plan => i_id_rehab_epis_plan,
                                          o_info               => o_info,
                                          o_notes              => o_notes,
                                          o_suggest            => o_suggest,
                                          o_obj_profs          => o_obj_profs,
                                          o_error              => o_error)
        THEN
            RAISE e_controlled_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
            l_action_message := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Action Message Code>');
            l_error_message  := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Error Message Code>');
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => SQLCODE,
                                              i_sqlerrm     => SQLERRM,
                                              i_message     => l_error_message,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => l_sub_object_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_sub_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_all_plan;

    /**
    * get_all_plan
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   07-12-2010 15:06:12
    */
    FUNCTION get_gen_prof_info
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan_team.id_rehab_epis_plan%TYPE,
        i_id_episode         IN rehab_epis_plan.id_episode%TYPE,
        i_id_patient         IN episode.id_patient%TYPE,
        o_info               OUT pk_types.cursor_type,
        o_team               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'get_gen_prof_info';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text            => g_error,
                                       object_name     => g_package_name,
                                       sub_object_name => l_sub_object_name);
    
        IF i_id_rehab_epis_plan IS NOT NULL
        THEN
            IF NOT pk_rehab_plan.get_gen_prof_info(i_lang               => i_lang,
                                                   i_prof               => i_prof,
                                                   i_id_rehab_epis_plan => i_id_rehab_epis_plan,
                                                   o_info               => o_info,
                                                   o_team               => o_team,
                                                   o_error              => o_error)
            THEN
                RAISE e_controlled_error;
            END IF;
        ELSE
            IF NOT pk_rehab_plan.get_list_by_pat_ep(i_lang       => i_lang,
                                                    i_prof       => i_prof,
                                                    i_id_episode => i_id_episode,
                                                    i_id_patient => i_id_patient,
                                                    o_info       => o_info,
                                                    o_teams      => o_team,
                                                    o_error      => o_error)
            THEN
                RAISE e_controlled_error;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
            l_action_message := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Action Message Code>');
            l_error_message  := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Error Message Code>');
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => SQLCODE,
                                              i_sqlerrm     => SQLERRM,
                                              i_message     => l_error_message,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => l_sub_object_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_sub_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_gen_prof_info;

    /**
    * get_domains
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   14-12-2010 12:12:32
    */
    FUNCTION get_domains
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_code_domain IN sys_domain.code_domain%TYPE,
        o_domain      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'get_domains';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text            => g_error,
                                       object_name     => g_package_name,
                                       sub_object_name => l_sub_object_name);
    
        IF NOT pk_rehab_plan.get_domains(i_lang        => i_lang,
                                         i_prof        => i_prof,
                                         i_code_domain => i_code_domain,
                                         o_domain      => o_domain,
                                         o_error       => o_error)
        THEN
            RAISE e_controlled_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
            l_action_message := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Action Message Code>');
            l_error_message  := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Error Message Code>');
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => SQLCODE,
                                              i_sqlerrm     => SQLERRM,
                                              i_message     => l_error_message,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => l_sub_object_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_sub_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_domains;

    /**
    * cancel_plan
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   15-12-2010 09:41:49
    */
    FUNCTION cancel_plan
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan_team.id_rehab_epis_plan%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'cancel_plan';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text            => g_error,
                                       object_name     => g_package_name,
                                       sub_object_name => l_sub_object_name);
    
        IF NOT pk_rehab_plan.cancel_plan(i_lang               => i_lang,
                                         i_prof               => i_prof,
                                         i_id_rehab_epis_plan => i_id_rehab_epis_plan,
                                         o_error              => o_error)
        THEN
            RAISE e_controlled_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
            l_action_message := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Action Message Code>');
            l_error_message  := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Error Message Code>');
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => SQLCODE,
                                              i_sqlerrm     => SQLERRM,
                                              i_message     => l_error_message,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => l_sub_object_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_sub_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END cancel_plan;

    /**
    * cancel_area
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   15-12-2010 09:41:49
    */
    FUNCTION cancel_area
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan_area.id_rehab_epis_plan%TYPE,
        i_id_rehab_plan_area IN rehab_epis_plan_area.id_rehab_plan_area%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'cancel_area';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text            => g_error,
                                       object_name     => g_package_name,
                                       sub_object_name => l_sub_object_name);
    
        IF NOT pk_rehab_plan.cancel_area(i_lang               => i_lang,
                                         i_prof               => i_prof,
                                         i_id_rehab_epis_plan => i_id_rehab_epis_plan,
                                         i_id_rehab_plan_area => i_id_rehab_plan_area,
                                         o_error              => o_error)
        THEN
            RAISE e_controlled_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
            l_action_message := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Action Message Code>');
            l_error_message  := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Error Message Code>');
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => SQLCODE,
                                              i_sqlerrm     => SQLERRM,
                                              i_message     => l_error_message,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => l_sub_object_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_sub_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END cancel_area;

    /**
    * cancel_objective
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   15-12-2010 09:41:49
    */
    FUNCTION cancel_objective
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_rehab_epis_plan_area IN rehab_epis_plan_area.id_rehab_epis_plan_area%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'cancel_objective';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text            => g_error,
                                       object_name     => g_package_name,
                                       sub_object_name => l_sub_object_name);
    
        IF NOT pk_rehab_plan.cancel_objective(i_lang                    => i_lang,
                                              i_prof                    => i_prof,
                                              i_id_rehab_epis_plan_area => i_id_rehab_epis_plan_area,
                                              o_error                   => o_error)
        THEN
            RAISE e_controlled_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
            l_action_message := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Action Message Code>');
            l_error_message  := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Error Message Code>');
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => SQLCODE,
                                              i_sqlerrm     => SQLERRM,
                                              i_message     => l_error_message,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => l_sub_object_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_sub_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END cancel_objective;

    /**
    * cancel_notes
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   15-12-2010 09:41:49
    */
    FUNCTION cancel_notes
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_rehab_epis_plan_notes IN rehab_epis_plan_notes.id_rehab_epis_plan_notes%TYPE,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'cancel_notes';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text            => g_error,
                                       object_name     => g_package_name,
                                       sub_object_name => l_sub_object_name);
    
        IF NOT pk_rehab_plan.cancel_notes(i_lang                     => i_lang,
                                          i_prof                     => i_prof,
                                          i_id_rehab_epis_plan_notes => i_id_rehab_epis_plan_notes,
                                          o_error                    => o_error)
        THEN
            RAISE e_controlled_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
            l_action_message := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Action Message Code>');
            l_error_message  := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Error Message Code>');
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => SQLCODE,
                                              i_sqlerrm     => SQLERRM,
                                              i_message     => l_error_message,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => l_sub_object_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_sub_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END cancel_notes;

    /**
    * get_all_hist_plan
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   07-12-2010 15:06:12
    */
    FUNCTION get_all_hist_plan
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan_area.id_rehab_epis_plan%TYPE,
        o_gen_info           OUT pk_types.cursor_type,
        o_info               OUT pk_types.cursor_type,
        o_notes              OUT pk_types.cursor_type,
        o_suggest            OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'get_all_hist_plan';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text            => g_error,
                                       object_name     => g_package_name,
                                       sub_object_name => l_sub_object_name);
    
        IF NOT pk_rehab_plan.get_all_hist_plan(i_lang               => i_lang,
                                               i_prof               => i_prof,
                                               i_id_rehab_epis_plan => i_id_rehab_epis_plan,
                                               o_gen_info           => o_gen_info,
                                               o_info               => o_info,
                                               o_notes              => o_notes,
                                               o_suggest            => o_suggest,
                                               o_error              => o_error)
        THEN
            RAISE e_controlled_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
            l_action_message := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Action Message Code>');
            l_error_message  := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Error Message Code>');
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => SQLCODE,
                                              i_sqlerrm     => SQLERRM,
                                              i_message     => l_error_message,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => l_sub_object_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_sub_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_all_hist_plan;

    /**
    * set_plan_info
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   06-12-2010 19:39:19
    */
    FUNCTION set_plan_info
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_rehab_epis_plan       IN rehab_epis_plan.id_rehab_epis_plan%TYPE,
        i_id_prof_cat_pl           IN table_number,
        i_id_episode               IN rehab_epis_plan.id_episode%TYPE,
        i_creat_date               IN VARCHAR2,
        i_id_rehab_plan_area       IN table_number,
        i_id_rehab_epis_plan_area  IN table_number,
        i_current_situation        IN table_varchar,
        i_goals                    IN table_varchar,
        i_methodology              IN table_varchar,
        i_time                     IN table_number,
        i_flg_time_unit            IN table_varchar,
        i_id_prof_cat              IN table_table_number,
        i_id_rehab_epis_plan_sug   IN table_number,
        i_suggestions              IN table_varchar,
        i_id_rehab_epis_plan_notes IN table_number,
        i_notes                    IN table_varchar,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sub_object_name VARCHAR2(20) := 'set_plan_info';
        e_controlled_error EXCEPTION;
        l_action_message sys_message.desc_message%TYPE;
        l_error_message  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'Init get_ref_status_info WF=';
        alertlog.pk_alertlog.log_debug(text            => g_error,
                                       object_name     => g_package_name,
                                       sub_object_name => l_sub_object_name);
    
        IF NOT pk_rehab_plan.set_plan_info(i_lang                     => i_lang,
                                           i_prof                     => i_prof,
                                           i_id_rehab_epis_plan       => i_id_rehab_epis_plan,
                                           i_id_prof_cat_pl           => i_id_prof_cat_pl,
                                           i_id_episode               => i_id_episode,
                                           i_creat_date               => i_creat_date,
                                           i_id_rehab_plan_area       => i_id_rehab_plan_area,
                                           i_id_rehab_epis_plan_area  => i_id_rehab_epis_plan_area,
                                           i_current_situation        => i_current_situation,
                                           i_goals                    => i_goals,
                                           i_methodology              => i_methodology,
                                           i_time                     => i_time,
                                           i_flg_time_unit            => i_flg_time_unit,
                                           i_id_prof_cat              => i_id_prof_cat,
                                           i_id_rehab_epis_plan_sug   => i_id_rehab_epis_plan_sug,
                                           i_suggestions              => i_suggestions,
                                           i_id_rehab_epis_plan_notes => i_id_rehab_epis_plan_notes,
                                           i_notes                    => i_notes,
                                           o_error                    => o_error)
        THEN
            RAISE e_controlled_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_controlled_error THEN
            l_action_message := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Action Message Code>');
            l_error_message  := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => '<Costumized Error Message Code>');
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => SQLCODE,
                                              i_sqlerrm     => SQLERRM,
                                              i_message     => l_error_message,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => l_sub_object_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_sub_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END set_plan_info;

    /**********************************************************************************************
    * Returns a list of rehab environmentsthat the professional is or can be allocated to in a given institution
    *
    * %param i_lang                   id_language
    * %param i_prof                   id_professional
    * %param i_id_institution         institution
    * %param o_environment            list of rehab environments
    * %param o_error                  error message
    *
    * @return                         TRUE on success, FALSE otherwise
    *
    * @author                         Nuno Neves
    * @version                        2.6.1
    * @since                          2011-03-02
    **********************************************************************************************/
    FUNCTION get_rehab_environment_prof
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        o_environment    OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_REHAB_ENVIRONMENT_PROF';
    BEGIN
        g_error := 'OPEN o_environment for id_professional=' || i_prof.id || ', id_institution=' || i_id_institution;
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
    
        IF NOT pk_rehab.get_rehab_environment_prof(i_lang, i_prof, i_id_institution, o_environment, o_error)
        
        THEN
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error('Parameters: i_id_institution=' || i_id_institution || ' @' || g_error,
                                  g_package_name,
                                  l_func_name);
            pk_types.open_my_cursor(o_environment);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_rehab_environment_prof;

    /**********************************************************************************************
    * Sets the list of rehab environment that the professional is allocated to, in one or more institutions
    *
    * %param i_lang                   id_language
    * %param i_prof                   id_professional
    * %param i_institution            list of institutions to alloc the professional
    * %param i_rehab_area             for each institution a list of rehab environment to alloc the professional
    * %param o_error                  error message
    *
    * @return                         TRUE on success, FALSE otherwise
    *
    * @author                         Nuno Neves
    * @version                        2.6.1
    * @since                          2011-03-02
    **********************************************************************************************/
    FUNCTION set_rehab_environment_prof
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_institution       IN table_number,
        i_rehab_environment IN table_table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(30) := 'SET_REHAB_ENVIRONMENT_PROF';
    
    BEGIN
    
        IF NOT pk_rehab.set_rehab_environment_prof(i_lang, i_prof, i_institution, i_rehab_environment, o_error)
        
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error, g_package_name, l_func_name);
            pk_utils.undo_changes;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END set_rehab_environment_prof;

    /**********************************************************************************************
    * Returns the information about all rehab treats
    *
    * %param i_lang                   id_language
    * %param i_prof                   id_professional
    * %param i_id_patient             patient id
    * %param o_treat                  list of treatments
    * %param o_error                  error message
    *
    * @return                         TRUE on success, FALSE otherwise
    *
    * @author                         Nuno Neves
    * @version                        2.6.1.1
    * @since                          2012-02-10
    **********************************************************************************************/
    FUNCTION get_rehab_all_treat
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN rehab_plan.id_patient%TYPE,
        o_treat      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_REHAB_ALL_TREAT';
    BEGIN
    
        IF NOT pk_rehab.get_rehab_all_treat(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_id_patient => i_id_patient,
                                            o_treat      => o_treat,
                                            o_error      => o_error)
        
        THEN
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_treat);
            pk_alertlog.log_error('get_rehab_treatment_plan Parameters: i_id_patient=' || i_id_patient || ' @' ||
                                  g_error,
                                  g_package_name,
                                  l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_rehab_all_treat;
    /**********************************************************************************************
    * Returns the information for the external prescriptions popup (if more than one for the same 
    * kind of codification).
    *
    * @param i_lang                ID language
    * @param i_prof                Professional
    * @param i_episode             Episode ID
    * @param i_id_rehab_presc      Prescription ID
    * @param o_show                Show popup?
    * @param o_messages            Titles and messages
    * @param o_interv              Cursor with the procedures
    * @param o_error               Error
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Joana Barroso
    * @version                     2.6.1.10
    * @since                       2012/08/16
    **********************************************************************************************/
    FUNCTION get_external_req
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_id_rehab_presc IN rehab_presc.id_rehab_presc%TYPE,
        o_show           OUT VARCHAR2,
        o_messages       OUT pk_types.cursor_type,
        o_rehab          OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN
    
     IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_EXTERNAL_REQ';
    BEGIN
        g_error := 'Call pk_rehab.get_external_req / I_EPISODE=' || i_episode || ' i_id_rehab_presc=' ||
                   i_id_rehab_presc;
        IF NOT pk_rehab.get_external_req(i_lang           => i_lang,
                                         i_prof           => i_prof,
                                         i_episode        => i_episode,
                                         i_id_rehab_presc => i_id_rehab_presc,
                                         o_show           => o_show,
                                         o_messages       => o_messages,
                                         o_rehab          => o_rehab,
                                         o_error          => o_error)
        
        THEN
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_rehab);
            pk_types.open_my_cursor(o_messages);
            pk_alertlog.log_error('pk_rehab.get_external_req / I_EPISODE=' || i_episode || ' i_id_rehab_presc=' ||
                                  i_id_rehab_presc || ' @' || g_error,
                                  g_package_name,
                                  l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_external_req;

    /**********************************************************************************************
    * Returns Institutions for rehab prescriptions  
    *
    * @param i_lang                ID language
    * @param i_prof                Professional
    * @param i_intervs             Array of requested Interventions
    * @param o_inst                Cursor with institutions
    * @param o_error               Error
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Joana Barroso
    * @version                     2.6.3.5
    * @since                       2013/05/18
    **********************************************************************************************/

    FUNCTION get_rehab_inst
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_intervs IN table_number,
        o_inst    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_REHAB_INST';
    BEGIN
    
        g_error := 'Call pk_rehab.get_rehab_inst / I_INTERVS=' || pk_utils.to_string(i_intervs);
        IF NOT pk_rehab.get_rehab_inst(i_lang    => i_lang,
                                       i_prof    => i_prof,
                                       i_intervs => i_intervs,
                                       o_inst    => o_inst,
                                       o_error   => o_error)
        
        THEN
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_inst);
            pk_alertlog.log_error('pk_rehab.get_rehab_inst / I_INTERVS=' || pk_utils.to_string(i_intervs) || ' @' ||
                                  g_error,
                                  g_package_name,
                                  l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_rehab_inst;

    FUNCTION update_rehab_presc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN rehab_plan.id_patient%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_rehab_presc      IN rehab_presc.id_rehab_presc%TYPE,
        i_id_rehab_sch_need   IN rehab_presc.id_rehab_sch_need%TYPE,
        i_id_exec_institution IN rehab_presc.id_exec_institution%TYPE,
        i_exec_per_session    IN rehab_presc.exec_per_session%TYPE,
        i_presc_notes         IN rehab_presc.notes%TYPE,
        i_sessions            IN rehab_sch_need.sessions%TYPE,
        i_frequency           IN rehab_sch_need.frequency%TYPE,
        i_flg_frequency       IN rehab_sch_need.flg_frequency%TYPE,
        i_flg_priority        IN rehab_sch_need.flg_priority%TYPE,
        i_date_begin          IN VARCHAR2,
        i_session_notes       IN rehab_sch_need.notes%TYPE,
        i_session_type        IN rehab_sch_need.id_rehab_session_type%TYPE,
        i_flg_laterality      IN rehab_presc.flg_laterality%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'update_rehab_presc';
    BEGIN
        g_error := 'before call';
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
        IF NOT pk_rehab.update_rehab_presc(i_lang                => i_lang,
                                           i_prof                => i_prof,
                                           i_id_patient          => i_id_patient,
                                           i_id_episode          => i_id_episode,
                                           i_id_rehab_presc      => i_id_rehab_presc,
                                           i_id_rehab_sch_need   => i_id_rehab_sch_need,
                                           i_id_exec_institution => i_id_exec_institution,
                                           i_exec_per_session    => i_exec_per_session,
                                           i_presc_notes         => i_presc_notes,
                                           i_sessions            => i_sessions,
                                           i_frequency           => i_frequency,
                                           i_flg_frequency       => i_flg_frequency,
                                           i_flg_priority        => i_flg_priority,
                                           i_date_begin          => i_date_begin,
                                           i_session_notes       => i_session_notes,
                                           i_session_type        => i_session_type,
                                           i_flg_laterality      => i_flg_laterality,
                                           o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error, g_package_name, l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END update_rehab_presc;

    FUNCTION get_cross_actions_permissions
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_subject     IN action.subject%TYPE,
        i_from_state  IN table_varchar,
        i_task_type   IN task_type.id_task_type%TYPE,
        i_rehab_presc IN table_number,
        o_actions     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_CROSS_ACTIONS_PERMISSIONS';
    BEGIN
    
        g_error := 'Call pk_rehab.get_cross_actions_permissions';
        IF NOT pk_rehab.get_cross_actions_permissions(i_lang        => i_lang,
                                                      i_prof        => i_prof,
                                                      i_subject     => i_subject,
                                                      i_from_state  => i_from_state,
                                                      i_task_type   => i_task_type,
                                                      i_rehab_presc => i_rehab_presc,
                                                      o_actions     => o_actions,
                                                      o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_actions);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_cross_actions_permissions;

    FUNCTION get_rehab_summary
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_pat  IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        --request
        o_rehab_request      OUT pk_types.cursor_type,
        o_rehab_request_prof OUT pk_types.cursor_type,
        --
        o_request_origin OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        --
        IF NOT pk_rehab.get_rehab_summary(i_lang               => i_lang,
                                          i_prof               => i_prof,
                                          i_id_pat             => i_id_pat,
                                          i_episode            => i_episode,
                                          o_rehab_request      => o_rehab_request,
                                          o_rehab_request_prof => o_rehab_request_prof,
                                          o_error              => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := ('GET_REHAB_EPISODE_ORIGIN_TYPE');
        IF pk_rehab.get_rehab_epis_origin_type(i_lang, i_prof, i_episode) = 'R'
           OR pk_rehab.get_rehab_epis_origin_type(i_lang, i_prof, i_episode) = 'C'
        THEN
            o_request_origin := pk_alert_constant.g_yes;
        ELSE
            o_request_origin := pk_alert_constant.g_no;
        END IF;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            --
            pk_types.open_my_cursor(o_rehab_request);
            pk_types.open_my_cursor(o_rehab_request_prof);
        
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     'ALERT',
                                                     'PK_REHAB_UX',
                                                     'GET_REHAB_SUMMARY',
                                                     o_error);
        
    END get_rehab_summary;

    FUNCTION get_grid_dates
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_all_patients     IN VARCHAR2,
        i_flg_type_profile IN VARCHAR2 DEFAULT NULL,
        o_date             OUT pk_types.cursor_type,
        o_error            OUT t_error_out
        
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        --
        IF NOT pk_rehab.get_grid_dates(i_lang             => i_lang,
                                       i_prof             => i_prof,
                                       i_all_patients     => i_all_patients,
                                       i_flg_type_profile => i_flg_type_profile,
                                       o_date             => o_date,
                                       o_error            => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            --
            pk_types.open_my_cursor(o_date);
        
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     o_error.ora_sqlcode,
                                                     o_error.ora_sqlerrm,
                                                     o_error.err_desc,
                                                     'ALERT',
                                                     'PK_REHAB_UX',
                                                     'GET_GRID_DATES',
                                                     o_error);
        
    END get_grid_dates;

    FUNCTION set_rehab_resp
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_id_episode  IN NUMBER,
        i_id_schedule IN NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_ret BOOLEAN;
    
    BEGIN
    
        l_ret := pk_rehab.set_rehab_resp(i_lang => i_lang,
                                         i_prof => i_prof,
                                         --i_id_view     => i_id_view,
                                         i_id_episode  => i_id_episode,
                                         i_id_schedule => i_id_schedule,
                                         o_error       => o_error);
    
        IF l_ret
        THEN
            COMMIT;
        ELSE
            pk_utils.undo_changes();
        END IF;
    
        RETURN l_ret;
    
    END set_rehab_resp;

    FUNCTION set_rehab_favorite
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_rehab_area_interv IN rehab_area_interv.id_rehab_area_interv%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN AS
        l_exception EXCEPTION;
    BEGIN
    
        IF NOT pk_rehab.set_rehab_favorite(i_lang                 => i_lang,
                                           i_prof                 => i_prof,
                                           i_id_rehab_area_interv => i_id_rehab_area_interv,
                                           o_error                => o_error)
        THEN
            RAISE l_exception;
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
                                              'SET_REHAB_FAVORITE',
                                              o_error);
            RETURN FALSE;
    END set_rehab_favorite;

    FUNCTION get_actions
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_subject        IN action.subject%TYPE,
        i_from_state     IN action.from_state%TYPE,
        i_episode_origin IN episode.id_episode%TYPE,
        o_actions        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_rehab.get_actions(i_lang           => i_lang,
                                    i_prof           => i_prof,
                                    i_subject        => i_subject,
                                    i_from_state     => i_from_state,
                                    i_episode_origin => i_episode_origin,
                                    o_actions        => o_actions,
                                    o_error          => o_error);
    
    END get_actions;

BEGIN
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_rehab_ux;
/
