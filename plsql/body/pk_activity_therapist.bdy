/*-- Last Change Revision: $Rev: 2026606 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:19 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_activity_therapist IS

    -- Private type declarations

    -- Private constant declarations

    -- Private variable declarations

    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    /********************************************************************************************
    * Get data for the activity therapist 'my patients' grids.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure 
    * @param i_show_all       'Y' to show all requests,
    *                         'N' to show my requests.   
    * @param o_requests       requests cursor
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                2.6.0.3
    * @since                  06-05-2010
    */
    FUNCTION get_grid_patients
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_show_all IN VARCHAR2,
        o_requests OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
    BEGIN
        g_error := 'CALL pk_paramedical_prof_core.get_paramedical_requests';
        IF NOT pk_paramedical_prof_core.get_paramedical_requests(i_lang     => i_lang,
                                                                 i_prof     => i_prof,
                                                                 i_show_all => i_show_all,
                                                                 o_requests => o_requests,
                                                                 o_error    => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_types.open_my_cursor(o_requests);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_GRID_PATIENTS',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_requests);
            RETURN FALSE;
        
    END get_grid_patients;

    /********************************************************************************************
    * Get data for the activity therapist 'supplies' grids.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure     
    * @param o_grid           output cursor
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                2.6.0.3
    * @since                  06-05-2010
    */
    FUNCTION get_supplies_grid
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_loaned_msg pk_translation.t_desc_translation;
    BEGIN
        g_error := 'GET Message';
        pk_alertlog.log_debug(g_error);
        l_loaned_msg := pk_message.get_message(i_lang      => i_lang,
                                               i_code_mess => pk_act_therap_constant.g_msg_loaned_units);
    
        g_error := 'GET SUPLIES DATA';
        pk_alertlog.log_debug(g_error);
        OPEN o_grid FOR
            SELECT sp.id_supply,
                   pk_translation.get_translation(i_lang, sp.code_supply) desc_supply,
                   sp.code_supply,
                   pk_supplies_api_db.get_attributes(i_lang,
                                                     i_prof,
                                                     pk_supplies_constant.g_area_activity_therapy,
                                                     sp.id_supply) desc_supply_attrib,
                   st.id_supply_type,
                   pk_translation.get_translation(i_lang, st.code_supply_type) desc_supply_type,
                   st.code_supply_type,
                   t.nr_patients,
                   t.qt nr_loned,
                   REPLACE(REPLACE(l_loaned_msg, pk_act_therap_constant.g_1st_replace, t.qt),
                           pk_act_therap_constant.g_2nd_replace,
                           pk_supplies_external_api_db.get_supply_quantity(i_lang,
                                                                           i_prof,
                                                                           pk_supplies_constant.g_area_activity_therapy,
                                                                           sp.id_supply)) AS loaned_units
              FROM supply sp
              JOIN supply_type st
                ON st.id_supply_type = sp.id_supply_type
              JOIN (SELECT sw.id_supply,
                           SUM(nvl(sw.quantity, pk_act_therap_constant.g_supplies_default_qt)) qt,
                           COUNT(DISTINCT epi.id_patient) nr_patients
                      FROM supply_workflow sw
                      JOIN episode epi
                        ON epi.id_episode = sw.id_episode
                     WHERE sw.flg_status = pk_supplies_constant.g_sww_loaned
                       AND sw.id_professional = i_prof.id
                       AND sw.flg_outdated IN (pk_supplies_constant.g_sww_active, pk_supplies_constant.g_sww_edited)
                       AND sw.id_supply_area = pk_supplies_constant.g_area_activity_therapy
                     GROUP BY sw.id_supply) t
                ON t.id_supply = sp.id_supply;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_SUPPLIES_GRID',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_grid);
            RETURN FALSE;
    END get_supplies_grid;

    /********************************************************************************************
    * Get inactive activity therapist episodes info.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure     
    * @param i_id_patient        Patient identifier    
    * @param o_epis_inact     output cursor
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                2.6.0.3
    * @since                  24-Mai-2010
    */
    FUNCTION get_epis_pat_inactive
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_epis_inact OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN O_EPIS_INACT ';
        pk_alertlog.log_debug(g_error);
        OPEN o_epis_inact FOR
            SELECT t.*,
                   pk_date_utils.date_send_tsz(i_lang, t.dt_discharge, i_prof) dt_discharge,
                   pk_date_utils.date_chr_short_read_tsz(i_lang, t.dt_discharge, i_prof.institution, i_prof.software) date_discharge,
                   pk_date_utils.date_char_hour_tsz(i_lang, t.dt_discharge, i_prof.institution, i_prof.software) hour_discharge
              FROM (SELECT e.id_episode,
                           e.id_patient,
                           pk_date_utils.date_send_tsz(i_lang, e.dt_begin_tstz, i_prof) dt_start_epis_at,
                           pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                 e.dt_begin_tstz,
                                                                 i_prof.institution,
                                                                 i_prof.software) date_start_epis_at,
                           pk_date_utils.date_char_hour_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software) hour_start_epis_at,
                           
                           pk_date_utils.date_send_tsz(i_lang, ep.dt_begin_tstz, i_prof) dt_start_epis_inp,
                           pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                 ep.dt_begin_tstz,
                                                                 i_prof.institution,
                                                                 i_prof.software) date_start_epis_inp,
                           pk_date_utils.date_char_hour_tsz(i_lang,
                                                            ep.dt_begin_tstz,
                                                            i_prof.institution,
                                                            i_prof.software) hour_start_epis_inp,
                           pk_discharge.get_disch_phy_adm_date(i_lang, i_prof, e.id_prev_episode) dt_discharge,
                           pk_alert_constant.g_yes flg_reopen
                      FROM episode e
                      JOIN episode ep
                        ON ep.id_episode = e.id_prev_episode
                      JOIN epis_info ei
                        ON ep.id_episode = ei.id_episode
                     WHERE e.id_epis_type = pk_act_therap_constant.g_activ_therap_epis_type
                       AND e.flg_status IN
                           (pk_alert_constant.g_epis_status_inactive, pk_alert_constant.g_epis_status_pendent)
                       AND e.id_patient = i_id_patient) t;
    
        RETURN TRUE;
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_EPIS_PAT_INACTIVE',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_epis_inact);
            RETURN FALSE;
    END get_epis_pat_inactive;

    /********************************************************************************************
    * Get the patients that has loaned supplies of a given supply.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure     
    * @param o_grid           output cursor
    * @param o_header         Header text separated by '|'
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                2.6.0.3
    * @since                  21-Mai-2010
    */
    FUNCTION get_supply_patients
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_supply IN supply.id_supply%TYPE,
        o_grid      OUT pk_types.cursor_type,
        o_header    OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
        l_supply_desc   pk_translation.t_desc_translation;
        l_supply_attrib pk_translation.t_desc_translation;
        l_supply_type   pk_translation.t_desc_translation;
    BEGIN
        g_error := 'GET SUPLY DESCRIPTIONS FOR id_supply = ' || i_id_supply;
        pk_alertlog.log_debug(g_error);
        SELECT pk_translation.get_translation(i_lang, sp.code_supply) desc_supply,
               pk_supplies_api_db.get_attributes(i_lang,
                                                 i_prof,
                                                 pk_supplies_constant.g_area_activity_therapy,
                                                 sp.id_supply) desc_supply_attrib,
               pk_translation.get_translation(i_lang, st.code_supply_type) desc_supply_type
          INTO l_supply_desc, l_supply_attrib, l_supply_type
          FROM supply sp
          JOIN supply_type st
            ON st.id_supply_type = sp.id_supply_type
         WHERE sp.id_supply = i_id_supply;
    
        g_error := 'CALL pk_supplies_api_db.get_supply_patients';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_supplies_api_db.get_supply_patients(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_id_supply => i_id_supply,
                                                      o_grid      => o_grid,
                                                      o_error     => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'CALC HEADER';
        pk_alertlog.log_debug(g_error);
        o_header := REPLACE(REPLACE(REPLACE(pk_message.get_message(i_lang      => i_lang,
                                                                   i_code_mess => pk_act_therap_constant.g_msg_supplies_header),
                                            pk_act_therap_constant.g_1st_replace,
                                            l_supply_desc),
                                    pk_act_therap_constant.g_2nd_replace,
                                    l_supply_type),
                            pk_act_therap_constant.g_3rd_replace,
                            l_supply_attrib);
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_types.open_my_cursor(o_grid);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_SUPPLY_PATIENTS',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_grid);
            RETURN FALSE;
    END get_supply_patients;

    /********************************************************************************************
    * Get history detail info of the loans and deliveries of supplies.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure     
    * @param i_id_episode            Episode identifier  
    * @param i_id_supply_workflow    Supply workflow identifier
    * @param i_id_supply             Supply identifier    
    * @param o_sup_workflow_prof     Professional data
    * @param o_sup_workflow     Professional data
    * @param o_error                 error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                2.6.0.3
    * @since                  06-Mai-2010
    */
    FUNCTION get_workflow_history
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE,
        i_id_supply          IN supply.id_supply%TYPE,
        i_id_patient         IN patient.id_patient%TYPE,
        o_sup_workflow_prof  OUT pk_types.cursor_type,
        o_sup_workflow       OUT pk_types.cursor_type,
        o_header             OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
        l_id_supply_workflow supply_workflow.id_supply_workflow%TYPE;
        l_supply_desc        sys_message.desc_message%TYPE;
    BEGIN
        IF (i_id_supply_workflow IS NOT NULL)
        THEN
            -- get id_supply_workflow parent
            g_error := 'CALL pk_supplies_external_api_db.get_workflow_parent for id_supply_workflow: ' ||
                       i_id_supply_workflow;
            pk_alertlog.log_debug(g_error);
            l_id_supply_workflow := pk_supplies_external_api_db.get_workflow_parent(i_lang               => i_lang,
                                                                                    i_prof               => i_prof,
                                                                                    i_id_supply_workflow => i_id_supply_workflow);
        
            l_id_supply_workflow := nvl(l_id_supply_workflow, i_id_supply_workflow);
        END IF;
    
        g_error := 'CALL pk_supplies_external_api_db.get_supply_desc i_id_supply: ' || i_id_supply;
        pk_alertlog.log_debug(g_error);
        l_supply_desc := pk_supplies_external_api_db.get_supply_desc(i_lang      => i_lang,
                                                                     i_prof      => i_prof,
                                                                     i_id_supply => i_id_supply);
    
        --get patient desc    
        g_error := 'CALC HEADER';
        pk_alertlog.log_debug(g_error);
        o_header := REPLACE(REPLACE(pk_message.get_message(i_lang => i_lang, i_code_mess => 'AT_HIST_T004'),
                                    pk_act_therap_constant.g_1st_replace,
                                    pk_patient.get_pat_name(i_lang, i_prof, i_id_patient, i_id_episode)),
                            pk_act_therap_constant.g_2nd_replace,
                            l_supply_desc);
    
        g_error := 'CALL pk_supplies_external_api_db.get_workflow_history for episode: ' || i_id_episode ||
                   ' and id_supply_workflow: ' || l_id_supply_workflow;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_supplies_external_api_db.get_workflow_history(i_lang               => i_lang,
                                                                i_prof               => i_prof,
                                                                i_id_supply_area     => pk_supplies_constant.g_area_activity_therapy,
                                                                i_id_episode         => table_number(i_id_episode),
                                                                i_id_supply_workflow => l_id_supply_workflow,
                                                                i_id_supply          => i_id_supply,
                                                                i_start_date         => NULL,
                                                                i_end_date           => NULL,
                                                                i_flg_screen         => pk_act_therap_constant.g_screen_detail,
                                                                i_supply_desc        => l_supply_desc,
                                                                o_sup_workflow_prof  => o_sup_workflow_prof,
                                                                o_sup_workflow       => o_sup_workflow,
                                                                
                                                                o_error => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_types.open_my_cursor(o_sup_workflow_prof);
            pk_types.open_my_cursor(o_sup_workflow);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_WORKFLOW_HISTORY',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_sup_workflow_prof);
            pk_types.open_my_cursor(o_sup_workflow);
            RETURN FALSE;
    END get_workflow_history;

    /********************************************************************************************
    * Get the id_prev_episode of the activity therapy episode.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure       
    * @param i_id_episode     Activity Therapy episode identifier
    * @param o_id_episode     Inpatient episode identifier    
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                2.6.0.3
    * @since                  07-05-2010
    */
    FUNCTION get_epis_parent
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_id_episode OUT episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET THE ID_PREV_EPISODE FOR EPISODE: ' || i_id_episode;
        SELECT e.id_prev_episode
          INTO o_id_episode
          FROM episode e
          JOIN episode ie
            ON e.id_prev_episode = ie.id_episode
         WHERE e.id_episode = i_id_episode
           AND ie.id_epis_type = pk_act_therap_constant.g_inp_epis_type;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            o_id_episode := NULL;
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_EPIS_PARENT',
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_epis_parent;

    /********************************************************************************************
    * Get the id_prev_episode of the activity therapy episode.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure       
    * @param i_id_episode     Activity Therapy episode identifier
    
    *
    * @return                 episode identifier
    *
    * @author                 Sofia Mendes
    * @version                2.6.0.3
    * @since                  07-05-2010
    */
    FUNCTION get_epis_parent
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN episode.id_episode%TYPE IS
        l_id_episode episode.id_episode%TYPE;
        l_error      t_error_out;
    BEGIN
        g_error := 'GET THE ID_PREV_EPISODE FOR EPISODE: ' || i_id_episode;
        SELECT e.id_prev_episode
          INTO l_id_episode
          FROM episode e
          JOIN episode ie
            ON e.id_prev_episode = ie.id_episode
         WHERE e.id_episode = i_id_episode;
    
        RETURN l_id_episode;
    EXCEPTION
        WHEN no_data_found THEN
            l_id_episode := NULL;
            RETURN l_id_episode;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_EPIS_PARENT',
                                              o_error    => l_error);
            RETURN l_id_episode;
        
    END get_epis_parent;

    /********************************************************************************************
    * Get the id_prev_episode of the activity therapy episode.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure       
    * @param i_id_epis_parent Parent episode identifier
    * @param o_id_episode     Activity Therapy episode identifier    
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                2.6.0.3
    * @since                  07-05-2010
    */
    FUNCTION get_epis_child
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_epis_parent IN episode.id_episode%TYPE,
        o_id_episode     OUT episode.id_episode%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET THE ID_EPISODE WITH PREV_EPISODE: ' || i_id_epis_parent;
        SELECT e.id_episode
          INTO o_id_episode
          FROM episode e
         WHERE e.id_prev_episode = i_id_epis_parent
           AND e.flg_status = pk_alert_constant.g_active
           AND e.id_epis_type = pk_act_therap_constant.g_activ_therap_epis_type
           AND rownum = 1;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            o_id_episode := NULL;
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_EPIS_CHILD',
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_epis_child;

    /********************************************************************************************
    * Get the id_prev_episode of the activity therapy episode.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure       
    * @param i_id_epis_parent Parent episode identifier    
    *
    * @return                 Activity Therapy episode identifier 
    *
    * @author                 Sofia Mendes
    * @version                2.6.0.3
    * @since                  07-05-2010
    */
    FUNCTION get_epis_child
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_epis_parent IN episode.id_episode%TYPE
    ) RETURN episode.id_episode%TYPE IS
        l_internal_error EXCEPTION;
        l_id_episode episode.id_episode%TYPE;
        l_error      t_error_out;
    BEGIN
        IF NOT get_epis_child(i_lang           => i_lang,
                              i_prof           => i_prof,
                              i_id_epis_parent => i_id_epis_parent,
                              o_id_episode     => l_id_episode,
                              o_error          => l_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN l_id_episode;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN l_internal_error THEN
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_EPIS_CHILD',
                                              o_error    => l_error);
            RETURN NULL;
        
    END get_epis_child;

    /********************************************************************************************
    * Build status string for activity therapist requests. 
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_status         request status
    * @param i_dt_req         request date
    *
    * @return                 request status string
    *
    * @author                 Sofia Mendes
    * @version                2.6.0.3
    * @since                  2010/05/10
    */
    FUNCTION get_req_status_str
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_status IN opinion.flg_state%TYPE,
        i_dt_req IN opinion.dt_problem_tstz%TYPE
    ) RETURN VARCHAR2 IS
        l_retval       VARCHAR2(32767);
        l_display_type VARCHAR2(2 CHAR);
        l_value_icon   sys_domain.code_domain%TYPE;
        l_back_color   VARCHAR2(8 CHAR);
        l_icon_color   VARCHAR2(8 CHAR);
        l_error        t_error_out;
    BEGIN
        IF (i_status IS NULL)
        THEN
            l_display_type := pk_alert_constant.g_display_type_icon;
        
            l_value_icon := pk_act_therap_constant.g_at_search_icons;
            l_back_color := pk_alert_constant.g_color_null;
            l_icon_color := pk_alert_constant.g_color_icon_medium_grey;
        
            -- generate status string
            g_error := 'CALL PK_UTILS.GET_STATUS_STRING_IMMEDIATE';
            pk_alertlog.log_debug(g_error);
            l_retval := pk_utils.get_status_string_immediate(i_lang            => i_lang,
                                                             i_prof            => i_prof,
                                                             i_display_type    => l_display_type,
                                                             i_flg_state       => pk_act_therap_constant.g_flg_na,
                                                             i_value_text      => NULL,
                                                             i_value_date      => NULL,
                                                             i_value_icon      => l_value_icon,
                                                             i_shortcut        => NULL,
                                                             i_back_color      => l_back_color,
                                                             i_icon_color      => l_icon_color,
                                                             i_message_style   => NULL,
                                                             i_message_color   => NULL,
                                                             i_flg_text_domain => pk_alert_constant.g_no);
        ELSE
            g_error := 'CALL PK_PARAMEDICAL_PROF_CORE.GET_REQ_STATUS_STR';
            pk_alertlog.log_debug(g_error);
            l_retval := pk_paramedical_prof_core.get_req_status_str(i_lang   => i_lang,
                                                                    i_prof   => i_prof,
                                                                    i_status => i_status,
                                                                    i_dt_req => i_dt_req);
        END IF;
    
        RETURN l_retval;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_REQ_STATUS_STR',
                                              o_error    => l_error);
            RETURN NULL;
    END get_req_status_str;

    /********************************************************************************************
    * Updates the status of an episode to inactive. 
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        Episode identifier
    * @param o_error          Error info
    *
    * @return                 success/failure
    *
    * @author                 Sofia Mendes
    * @version                 2.6.0.3
    * @since                  10-Mai-2010
    */
    FUNCTION set_episode_inactive
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowids table_varchar;
    BEGIN
        g_error := 'CALL TS_EPISODE.UPD FOR EPISODE: ' || i_episode;
        pk_alertlog.log_debug(g_error);
        ts_episode.upd(id_episode_in   => i_episode,
                       flg_status_in   => pk_alert_constant.g_inactive,
                       flg_status_nin  => FALSE,
                       dt_end_tstz_in  => current_timestamp,
                       dt_end_tstz_nin => FALSE,
                       rows_out        => l_rowids);
    
        g_error := 'PROCESS UPDATE';
        pk_alertlog.log_debug(g_error);
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPISODE',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_STATUS', 'DT_END_TSTZ'));
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_EPISODE_INACTIVE',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_episode_inactive;

    /********************************************************************************************
    * Updates the status of the activity therapy episode to inactive, if it the parent episode 
    * is inactive.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        Episode identifier
    * @param o_inactivated    Y- The theray episode was inactivated.
    * @param o_error          Error info
    *
    * @return                 success/failure
    *
    * @author                 Sofia Mendes
    * @version                 2.6.0.3
    * @since                  02-Jun-2010
    */
    FUNCTION set_epis_inactive
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        o_inactivated OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_epis_parent episode.id_episode%TYPE;
        l_internal_error EXCEPTION;
        l_flg_status episode.flg_status%TYPE;
    BEGIN
        --check if the parent episode is inactive
        g_error := 'CALL pk_activity_therapist.get_epis_parent for id_episode: ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_activity_therapist.get_epis_parent(i_lang       => i_lang,
                                                     i_prof       => i_prof,
                                                     i_id_episode => i_id_episode,
                                                     o_id_episode => l_id_epis_parent,
                                                     o_error      => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'CALL pk_episode.get_flg_status for id_episode: ' || l_id_epis_parent;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_episode.get_flg_status(i_lang       => i_lang,
                                         i_prof       => i_prof,
                                         i_id_episode => l_id_epis_parent,
                                         o_flg_status => l_flg_status,
                                         o_error      => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        IF l_flg_status = pk_alert_constant.g_inactive
        THEN
            -- check if the AT episode is active
            g_error := 'CALL pk_episode.get_flg_status for id_episode: ' || l_id_epis_parent;
            pk_alertlog.log_debug(g_error);
            IF NOT pk_episode.get_flg_status(i_lang       => i_lang,
                                             i_prof       => i_prof,
                                             i_id_episode => i_id_episode,
                                             o_flg_status => l_flg_status,
                                             o_error      => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
            IF l_flg_status = pk_alert_constant.g_active
            THEN
                --inactivate the AT episode
                g_error := 'CALL set_episode_inactive for id_episode: ' || i_id_episode;
                pk_alertlog.log_debug(g_error);
                IF NOT set_episode_inactive(i_lang    => i_lang,
                                            i_prof    => i_prof,
                                            i_episode => i_id_episode,
                                            o_error   => o_error)
                THEN
                    RAISE l_internal_error;
                END IF;
                o_inactivated := pk_alert_constant.g_yes;
            END IF;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_EPIS_INACTIVE',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_epis_inactive;

    /********************************************************************************************
    * Updates the status of the activity therapy episode to inactive, if it the parent episode 
    * is inactive and the patient does not have loaned supplies.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        AT Episode identifier
    * @param o_flg_show       Flag: Y - exists message to be shown; N -  otherwise
    * @param o_msg            Message to be shown
    * @param o_msg_title      Message title  
    * @param o_error          Error info
    *
    * @return                 success/failure
    *
    * @author                 Sofia Mendes
    * @version                 2.6.0.3
    * @since                  11-Jun-2010
    */
    FUNCTION set_epis_inact_no_sup
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_flg_show   OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
        l_has_loaned_supplies  VARCHAR2(1);
        l_inactivated          VARCHAR2(1);
        l_epis_parent          episode.id_episode%TYPE;
        l_discharge_date       discharge.dt_med_tstz%TYPE;
        l_flg_discharge_status epis_info.flg_dsch_status%TYPE;
    BEGIN
        g_error := 'CALL check_loaned_supplies for episode: ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        l_has_loaned_supplies := pk_supplies_external_api_db.check_loaned_supplies(i_lang       => i_lang,
                                                                                   i_prof       => i_prof,
                                                                                   i_id_episode => i_id_episode);
    
        --if the patient has not more loaned supplies and the parent episode is inactive, the child episode
        -- should also stay inactive
        IF (l_has_loaned_supplies = pk_alert_constant.g_no)
        THEN
            g_error := 'CALL pk_activity_therapist.set_parent_epis_inact';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_activity_therapist.set_epis_inactive(i_lang        => i_lang,
                                                           i_prof        => i_prof,
                                                           i_id_episode  => i_id_episode,
                                                           o_inactivated => l_inactivated,
                                                           o_error       => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
            IF (l_inactivated = pk_alert_constant.g_yes)
            THEN
                -- the activity therapy request should be updated to the state: Concluded        
                g_error := 'CALL update_request_state for id_episode: ' || i_id_episode;
                pk_alertlog.log_debug(g_error);
                IF NOT update_request_state(i_lang          => i_lang,
                                            i_prof          => i_prof,
                                            i_id_episode_at => i_id_episode,
                                            i_from_states   => table_varchar(pk_opinion.g_opinion_accepted,
                                                                             pk_opinion.g_opinion_req),
                                            i_to_state      => pk_opinion.g_opinion_over,
                                            o_error         => o_error)
                THEN
                    RAISE l_internal_error;
                END IF;
            
                o_flg_show  := pk_alert_constant.g_yes;
                o_msg       := pk_message.get_message(i_lang      => i_lang,
                                                      i_code_mess => pk_act_therap_constant.g_msg_auto_close);
                o_msg_title := pk_message.get_message(i_lang      => i_lang,
                                                      i_code_mess => pk_act_therap_constant.g_msg_auto_close_title);
            
                g_error := 'CALL get_epis_parent for id_episode: ' || i_id_episode;
                pk_alertlog.log_debug(g_error);
                IF NOT get_epis_parent(i_lang       => i_lang,
                                       i_prof       => i_prof,
                                       i_id_episode => i_id_episode,
                                       o_id_episode => l_epis_parent,
                                       o_error      => o_error)
                THEN
                    RAISE l_internal_error;
                END IF;
                --the existing alerts associated to this patient indicating that he has loaned supplies
                --should be deleted                
                g_error := 'CALL pk_alerts.delete_sys_alert_event';
                pk_alertlog.log_debug(g_error);
                IF NOT pk_alerts.delete_sys_alert_event(i_lang         => i_lang,
                                                        i_prof         => i_prof,
                                                        i_id_sys_alert => pk_act_therap_constant.g_id_supplies_alert,
                                                        i_id_record    => l_epis_parent,
                                                        o_error        => o_error)
                THEN
                    RAISE l_internal_error;
                END IF;
            ELSE
                --if there is already a inp physician discharge
                --should be deleted the alert
                g_error := 'CALL get_epis_parent for id_episode: ' || i_id_episode;
                pk_alertlog.log_debug(g_error);
                IF NOT get_epis_parent(i_lang       => i_lang,
                                       i_prof       => i_prof,
                                       i_id_episode => i_id_episode,
                                       o_id_episode => l_epis_parent,
                                       o_error      => o_error)
                THEN
                    RAISE l_internal_error;
                END IF;
            
                g_error := 'CALL pk_discharge.get_discharge_date for id_episode: ' || l_epis_parent;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_discharge.get_discharge_date(i_lang                 => i_lang,
                                                       i_prof                 => i_prof,
                                                       i_id_episode           => l_epis_parent,
                                                       o_discharge_date       => l_discharge_date,
                                                       o_flg_discharge_status => l_flg_discharge_status,
                                                       o_error                => o_error)
                THEN
                    RAISE l_internal_error;
                END IF;
            
                IF (l_discharge_date IS NOT NULL)
                THEN
                    --the existing alerts associated to this patient indicating that he has loaned supplies
                    --should be deleted                
                    g_error := 'CALL pk_alerts.delete_sys_alert_event';
                    pk_alertlog.log_debug(g_error);
                    IF NOT pk_alerts.delete_sys_alert_event(i_lang         => i_lang,
                                                            i_prof         => i_prof,
                                                            i_id_sys_alert => pk_act_therap_constant.g_id_supplies_alert,
                                                            i_id_record    => l_epis_parent,
                                                            o_error        => o_error)
                    THEN
                        RAISE l_internal_error;
                    END IF;
                END IF;
            END IF;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_EPIS_INACT_NO_SUP',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_epis_inact_no_sup;

    /**********************************************************************************************
    * Table function to return the activity therapy inactive episodes
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_where                  Where clause             
    *
    * @return                         Structure with the inactive episodes info
    *                        
    * @author                         Sofia Mendes
    * @version                        2.6.0.3
    * @since                          26-Mai-2010
    **********************************************************************************************/
    FUNCTION tf_epis_inactive
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_where IN VARCHAR2
    ) RETURN t_coll_episinactive IS
        dataset pk_types.cursor_type;
        l_limit sys_config.desc_sys_config%TYPE;
        out_obj t_rec_episinactive := t_rec_episinactive(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
    
        CURSOR l_cur IS
            SELECT *
              FROM (SELECT counter,
                           t.dt_birth,
                           t.name_pat,
                           t.name_pat_to_sort,
                           t.pat_ndo,
                           t.pat_nd_icon,
                           t.id_patient id_patient,
                           (SELECT location
                              FROM pat_soc_attributes) location
                      FROM (SELECT *
                              FROM v_at_epis_inactive t) t);
    
        TYPE dataset_tt IS TABLE OF l_cur%ROWTYPE INDEX BY PLS_INTEGER;
        l_dataset dataset_tt;
        l_row     PLS_INTEGER := 1;
    
        RESULT t_coll_episinactive := t_coll_episinactive();
    
    BEGIN
        --
        g_error := 'GET LIMIT';
        l_limit := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
    
        pk_context_api.set_parameter('i_lang', i_lang);
    
        pk_context_api.set_parameter('i_prof_id', i_prof.id);
        pk_context_api.set_parameter('i_prof_software', i_prof.software);
        pk_context_api.set_parameter('i_prof_institution', i_prof.institution);
        pk_context_api.set_parameter('id_epis_type', pk_act_therap_constant.g_activ_therap_epis_type);
    
        pk_context_api.set_parameter('g_epis_inactive', pk_alert_constant.g_epis_status_inactive);
        pk_context_api.set_parameter('g_epis_pending', pk_alert_constant.g_epis_status_pendent);
    
        pk_context_api.set_parameter('i_inst_grp_flg_relation', pk_edis_proc.g_inst_grp_flg_rel_adt);
    
        pk_context_api.set_parameter('ID_EXTERNAL_SYS',
                                     pk_sysconfig.get_config('ID_EXTERNAL_SYS', i_prof.institution, i_prof.software));
    
        pk_context_api.set_parameter('EXTERNAL_SYSTEM_EXIST',
                                     pk_sysconfig.get_config('EXTERNAL_SYSTEM_EXIST',
                                                             i_prof.institution,
                                                             i_prof.software));
        --
    
        g_error := 'OPEN CURSOR';
        OPEN dataset FOR 'SELECT * ' || --
         '  FROM (SELECT counter, ' || --
         '               t.dt_birth, ' || --
         '               t.name_pat, ' || --
         '               t.name_pat_to_sort, ' || --
         '               t.pat_ndo, ' || --
         '               t.pat_nd_icon, ' || --
         '               t.id_patient id_patient, ' || --
         '               pk_patient.get_pat_location(:i_prof_institution, :g_inst_grp_flg_rel_adt, t.id_patient) location ' || --
         '          FROM (SELECT * ' || --
         '                  FROM v_at_epis_inactive t ' || --
         '                 WHERE 1 = 1 ' || --
        i_where || --
         '                         ) t ' || --
         '         GROUP BY counter, id_patient, name_pat, name_pat_to_sort, pat_ndo, pat_nd_icon, dt_birth ' || --
         '				 ORDER BY name_pat_to_sort) ' || --
         ' WHERE rownum <= :l_limit + 1 '
            USING --
        i_prof.institution, --
        pk_edis_proc.g_inst_grp_flg_rel_adt, --
        l_limit;
        --
        g_error := 'FETCH FROM RESULTS CURSOR';
        FETCH dataset BULK COLLECT
            INTO l_dataset;
        g_error := 'CLOSE RESULTS CURSOR';
        CLOSE dataset;
        --
    
        g_error := 'COUNT RESULTS';
        IF (l_dataset.count > l_limit)
        THEN
            g_overlimit := TRUE;
            RETURN RESULT;
        ELSE
            IF (l_dataset.count = 0)
            THEN
                g_no_results := TRUE;
            END IF;
        END IF;
    
        g_error := 'EXTEND RESULT ARRAY';
        IF (l_dataset.count < l_limit)
        THEN
            result.extend(l_dataset.count);
        ELSE
            result.extend(l_limit);
        END IF;
    
        --
        l_row   := l_dataset.first;
        g_error := 'GET DATA';
        WHILE (l_row <= result.count)
        LOOP
            out_obj.num_episode := l_dataset(l_row)
                                   .counter + pk_edis_proc.get_prev_episode(i_lang,
                                                                            l_dataset(l_row).id_patient,
                                                                            i_prof.institution,
                                                                            i_prof.software);
            IF (NOT l_dataset(l_row).dt_birth IS NULL)
            THEN
                out_obj.dt_birth_string := pk_date_utils.dt_chr(i_lang,
                                                                l_dataset(l_row).dt_birth,
                                                                i_prof.institution,
                                                                i_prof.software);
                out_obj.dt_birth        := pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                       i_date => l_dataset(l_row).dt_birth,
                                                                       i_prof => i_prof);
            ELSE
                out_obj.dt_birth_string := NULL;
                out_obj.dt_birth        := NULL;
            END IF;
            out_obj.name_pat      := l_dataset(l_row).name_pat;
            out_obj.name_pat_sort := l_dataset(l_row).name_pat_to_sort;
            out_obj.pat_ndo       := l_dataset(l_row).pat_ndo;
            out_obj.pat_nd_icon   := l_dataset(l_row).pat_nd_icon;
            out_obj.location      := l_dataset(l_row).location;
            out_obj.id_patient    := l_dataset(l_row).id_patient;
        
            RESULT(l_row) := out_obj;
            --
        
            l_row := l_row + 1;
        END LOOP;
        RETURN(RESULT);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            RETURN RESULT;
    END tf_epis_inactive;

    /**********************************************************************************************
    * List the inactive activity therapy episodes.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   professional, software and institution ids
    * @param i_id_sys_btn_crit        Search criteria identifiers.             
    * @param i_crit_val               Search criteria values
    * @param i_dt                     Date to search. If null is passed it is considered the system date
    * @param o_msg    
    * @param o_msg_title
    * @param o_button   
    * @param o_epis_inact             Inactive episodes list
    * @param o_mess_no_result         Message to be shown when the search does not produce results  
    * @param o_flg_show                
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Sofia Mendes
    * @version                        2.6.0.3
    * @since                          26-Mai-2010
    **********************************************************************************************/
    FUNCTION get_epis_inactive
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_dt              IN VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_epis_inact      OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_flg_show        OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_where VARCHAR2(32767);
    
    BEGIN
        --
        o_flg_show := 'N';
        --
        l_where := NULL;
        --
        IF (NOT pk_search.get_where(i_criteria => i_id_sys_btn_crit,
                                    i_crit_val => i_crit_val,
                                    i_lang     => i_lang,
                                    i_prof     => i_prof,
                                    o_where    => l_where))
        THEN
            l_where := NULL;
        END IF;
        --
        g_error      := 'OPEN CURSOR O_EPIS_INACT';
        g_no_results := FALSE;
        g_overlimit  := FALSE;
    
        --
        OPEN o_epis_inact FOR
            SELECT *
              FROM TABLE(tf_epis_inactive(i_lang, i_prof, l_where));
    
        IF (g_overlimit = TRUE)
        THEN
            RAISE pk_search.e_overlimit;
        ELSE
            IF (g_no_results = TRUE)
            THEN
                RAISE pk_search.e_noresults;
            
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_search.e_noresults THEN
            pk_types.open_my_cursor(o_epis_inact);
        
            RETURN pk_search.noresult_handler(i_lang, i_prof, g_package, 'GET_EPIS_INACTIVE', o_error);
        WHEN pk_search.e_overlimit THEN
            pk_types.open_my_cursor(o_epis_inact);
        
            RETURN pk_search.overlimit_handler(i_lang, i_prof, g_package, 'GET_EPIS_INACTIVE', o_error);
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_EPIS_INACTIVE',
                                              o_error);
        
            pk_types.open_my_cursor(o_epis_inact);
            RETURN FALSE;
    END get_epis_inactive;

    /********************************************************************************************
    * Creates the activity therapy request and the corresponding episode.
    * It is used in the patient search area.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure 
    * @param i_episode_origin Episode identifier of the parent episode
    * @param i_patient        Patient identifier
    * @param o_opinion        created opinion identifier
    * @param o_opinion_hist   created opinion history identifier    
    * @param o_opinion        opinion identifier
    * @param o_opinion_prof   opinion prof identifier
    * @param o_episode        episode identifier
    * @param o_epis_encounter episode encounter dentifier      
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                2.6.0.3
    * @since                  27-Mai-2010
    */
    FUNCTION set_request_and_episode
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode_origin IN episode.id_episode%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        o_opinion        OUT opinion.id_opinion%TYPE,
        o_opinion_hist   OUT opinion_hist.id_opinion_hist%TYPE,
        o_opinion_prof   OUT opinion_prof.id_opinion_prof%TYPE,
        o_episode        OUT episode.id_episode%TYPE,
        o_epis_encounter OUT epis_encounter.id_epis_encounter%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
        l_flg_approve opinion_type_prof.flg_approve%TYPE;
    BEGIN
        g_error := 'CALL PK_OPINION.SET_CONSULT_REQUEST';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_opinion.set_consult_request(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_episode      => i_episode_origin,
                                              i_patient      => i_patient,
                                              i_opinion      => NULL,
                                              i_opinion_type => pk_act_therap_constant.g_at_opinion_type,
                                              i_clin_serv    => NULL,
                                              i_reason_ft    => NULL,
                                              i_reason_mc    => NULL,
                                              i_prof_id      => i_prof.id,
                                              i_notes        => NULL,
                                              o_opinion      => o_opinion,
                                              o_opinion_hist => o_opinion_hist,
                                              o_error        => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'CALL pk_opinion.check_approval_need';
        pk_alertlog.log_debug(g_error);
        l_flg_approve := pk_opinion.check_approval_need(i_prof         => i_prof,
                                                        i_opinion_type => pk_act_therap_constant.g_at_opinion_type);
    
        IF (l_flg_approve = pk_alert_constant.g_no)
        THEN
            g_error := 'CALL PK_OPINION.SET_REQUEST_ANSWER';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_opinion.set_request_answer(i_lang             => i_lang,
                                                 i_prof             => i_prof,
                                                 i_opinion          => o_opinion,
                                                 i_patient          => i_patient,
                                                 i_flg_state        => pk_opinion.g_opinion_accepted,
                                                 i_management_level => NULL,
                                                 i_notes            => NULL,
                                                 i_cancel_reason    => NULL,
                                                 o_opinion_prof     => o_opinion_prof,
                                                 o_episode          => o_episode,
                                                 o_epis_encounter   => o_epis_encounter,
                                                 o_error            => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_REQUEST_AND_EPISODE',
                                              o_error    => o_error);
        
            RETURN FALSE;
        
    END set_request_and_episode;

    /********************************************************************************************
    * Creates the activity therapy request and the corresponding episode.
    * It is used in the patient search area.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure 
    * @param i_episode_origin   Episode identifier of the parent episode    
    * @param o_has_at_episode   Y-has an active activity therapy episode
    *                           N-does not have an active AT episode
    * @param o_error            error
    *
    * @return                   false, if errors occur, or true otherwise
    *
    * @author                   Sofia Mendes
    * @version                  2.6.0.3
    * @since                    27-Mai-2010
    */
    FUNCTION check_act_ther_episodes
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode_origin IN episode.id_episode%TYPE,
        o_has_at_episode OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_nr_at_episodes PLS_INTEGER;
    BEGIN
        g_error := 'SECLECT NR OF ACTIVITY THERAPY EPISODES FOR ID_EPISODE_ORIGIN: ' || i_episode_origin;
        pk_alertlog.log_debug(g_error);
        SELECT COUNT(1)
          INTO l_nr_at_episodes
          FROM episode e
         WHERE e.id_prev_episode = i_episode_origin
           AND e.flg_status = pk_alert_constant.g_active
           AND e.id_epis_type = pk_act_therap_constant.g_activ_therap_epis_type;
    
        IF (l_nr_at_episodes > 0)
        THEN
            o_has_at_episode := pk_alert_constant.get_yes;
        ELSE
            o_has_at_episode := pk_alert_constant.get_no;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CHECK_ACT_THER_EPISODES',
                                              o_error    => o_error);
        
            RETURN FALSE;
        
    END check_act_ther_episodes;

    /********************************************************************************************
    * Checks adicional criteria when reopening an inactive episode.
    * In order to be possible to reopen it:
    * there is no active activity therapy episode
    * there is no request on state requested or approved
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure 
    * @param i_episode        Episode identifier of the parent episode    
    * @param o_flg_reopen     Y-There is not active AT episode nor request; N-otherwise
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                2.6.0.3
    * @since                  27-Mai-2010
    */
    FUNCTION check_reopen_episode
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        o_flg_reopen OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
        l_has_at_episode    VARCHAR2(1);
        l_has_request       VARCHAR2(1);
        l_id_episode_origin episode.id_episode%TYPE;
    BEGIN
        g_error := 'CALL get_epis_parent for id_episode: ' || i_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT get_epis_parent(i_lang       => i_lang,
                               i_prof       => i_prof,
                               i_id_episode => i_episode,
                               o_id_episode => l_id_episode_origin,
                               o_error      => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        --check if there already exists an active activity therapy episode for this origin episode
        g_error := 'CALL CHECK_ACT_THER_EPISODES for episode: ' || l_id_episode_origin;
        pk_alertlog.log_debug(g_error);
        IF NOT check_act_ther_episodes(i_lang           => i_lang,
                                       i_prof           => i_prof,
                                       i_episode_origin => l_id_episode_origin,
                                       o_has_at_episode => l_has_at_episode,
                                       o_error          => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        IF (l_has_at_episode = pk_alert_constant.get_no)
        THEN
            -- check if there is some request for this origin episode in the state requested or approved
            g_error := 'CALL PK_OPINION.CHECK_OPINION_STATE';
            pk_alertlog.log_debug(g_error);
            l_has_request := pk_opinion.check_opinion_state(i_lang       => i_lang,
                                                            i_prof       => i_prof,
                                                            i_id_episode => l_id_episode_origin);
        
            IF (l_has_request = pk_alert_constant.g_yes)
            THEN
                o_flg_reopen := pk_alert_constant.g_no;
            ELSE
                o_flg_reopen := pk_alert_constant.g_yes;
            END IF;
        
        ELSE
            o_flg_reopen := pk_alert_constant.g_no;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CHECK_REOPEN_EPISODE',
                                              o_error    => o_error);
        
            RETURN FALSE;
        
    END check_reopen_episode;

    /********************************************************************************************
    * Get the discharge schedule date of the parent episode of the activity therapy episode.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure       
    * @param i_id_episode            Activity Therapy episode identifier
    * @param o_discharge_date        Discharge date (YYYYMMDDHH24MISS)
    * @param o_discharge_date_desc   Discharge date description
    * @param o_discharge_hour_desc   Discharge hour description
    * @param o_error                 error
    *
    * @return                        false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                2.6.0.3
    * @since                  28-Mai-2010
    */
    FUNCTION get_discharge_date
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        o_discharge_date_desc OUT VARCHAR2,
        o_discharge_hour_desc OUT VARCHAR2,
        o_discharge_date      OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
        l_id_episode_origin episode.id_episode%TYPE;
        l_discharge_date    discharge_schedule.dt_discharge_schedule%TYPE;
    BEGIN
        g_error := 'CALL get_epis_parent for id_episode: ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT get_epis_parent(i_lang       => i_lang,
                               i_prof       => i_prof,
                               i_id_episode => i_id_episode,
                               o_id_episode => l_id_episode_origin,
                               o_error      => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'CALL pk_discharge.get_discharge_date for id_episode: ' || l_id_episode_origin;
        pk_alertlog.log_debug(g_error);
        l_discharge_date := pk_discharge.get_discharge_date(i_lang       => i_lang,
                                                            i_prof       => i_prof,
                                                            i_id_episode => l_id_episode_origin);
    
        IF l_discharge_date IS NOT NULL
        THEN
            g_error := 'CALL pk_date_utils.date_send_tsz';
            pk_alertlog.log_debug(g_error);
            o_discharge_date_desc := pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                           l_discharge_date,
                                                                           i_prof.institution,
                                                                           i_prof.software);
            o_discharge_hour_desc := pk_date_utils.date_char_hour_tsz(i_lang,
                                                                      l_discharge_date,
                                                                      i_prof.institution,
                                                                      i_prof.software);
        
            o_discharge_date := pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                            i_date => l_discharge_date,
                                                            i_prof => i_prof);
        ELSE
            o_discharge_date_desc := NULL;
            o_discharge_hour_desc := NULL;
            o_discharge_date      := NULL;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            o_discharge_date := NULL;
            RETURN TRUE;
        WHEN l_internal_error THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_DISCHARGE_DATE',
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_discharge_date;

    /**********************************************************************************************
    * Get the message to be shown to the user when it is necessary to reopen the episode. 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids       
    * @param o_flg_show               Flag: Y - exists message to be shown; N -  otherwise
    * @param o_msg                    Message to be shown
    * @param o_msg_title              Message title      
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Sofia Mendes
    * @version                        2.6.0.3
    * @since                          31-Mai-2010 
    **********************************************************************************************/
    FUNCTION get_epis_reopen_msgs
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_flg_show   OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_reopen_at VARCHAR2(1 CHAR);
        l_internal_error EXCEPTION;
    BEGIN
    
        g_error := 'CALL pk_activity_therapist.check_reopen_episode for episode: ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_activity_therapist.check_reopen_episode(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_episode    => i_id_episode,
                                                          o_flg_reopen => l_flg_reopen_at,
                                                          o_error      => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        IF (l_flg_reopen_at = pk_alert_constant.g_yes)
        THEN
            o_flg_show  := pk_act_therap_constant.g_flg_show_q;
            o_msg       := pk_message.get_message(i_lang      => i_lang,
                                                  i_code_mess => pk_act_therap_constant.g_msg_epis_reopen_bd);
            o_msg_title := pk_message.get_message(i_lang      => i_lang,
                                                  i_code_mess => pk_act_therap_constant.g_msg_epis_reopen);
        ELSE
            o_flg_show  := pk_act_therap_constant.g_flg_show_r;
            o_msg       := pk_message.get_message(i_lang, 'AT_SUP_M024'); -- NaO PODE REABRIR   
            o_msg_title := pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMMON_T013');
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'get_epis_reopen_msgs',
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_epis_reopen_msgs;

    /**********************************************************************************************
    * Check if it is necessary to reopen the episode qhen recording loaned supplies, that is, check
    * if the episode is inactive. Is yes, returns a message to be displayed to the user. 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             episode id   
    * @param o_flg_show               Flag: Y - exists message to be shown; N -  otherwise
    * @param o_msg                    Message to be shown
    * @param o_msg_title              Message title      
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Sofia Mendes
    * @version                        2.6.0.3
    * @since                          31-Mai-2010 
    **********************************************************************************************/
    FUNCTION check_epis_to_reopen
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_flg_show   OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_status episode.flg_status%TYPE;
        l_internal_error EXCEPTION;
    BEGIN
        g_error := 'CALL pk_episode.get_flg_status for episode: ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_episode.get_flg_status(i_lang       => i_lang,
                                         i_prof       => i_prof,
                                         i_id_episode => i_id_episode,
                                         o_flg_status => l_flg_status,
                                         o_error      => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        IF (l_flg_status = pk_alert_constant.g_epis_status_inactive)
        THEN
            g_error := 'get_epis_reopen_msgs';
            pk_alertlog.log_debug(g_error);
            IF NOT get_epis_reopen_msgs(i_lang       => i_lang,
                                        i_prof       => i_prof,
                                        i_id_episode => i_id_episode,
                                        o_flg_show   => o_flg_show,
                                        o_msg        => o_msg,
                                        o_msg_title  => o_msg_title,
                                        o_error      => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        ELSE
            o_flg_show := pk_alert_constant.g_no;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CHECK_EPIS_TO_REOPEN',
                                              o_error    => o_error);
            RETURN FALSE;
        
    END check_epis_to_reopen;

    /**********************************************************************************************
    * Check if it is necessary to reopen the episode when i_flg_test is 'Y'. Otherwise checks if the 
    * episode is inactive, and if it is reopen it.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids    
    * @param i_id_episode             episode id   
    * @param i_flg_test               Y-it is to check if it is necessary to reopen the episode. N-otherwise
    * @param o_flg_show               Flag: Y - exists message to be shown; N -  otherwise
    * @param o_msg                    Message to be shown
    * @param o_msg_title              Message title      
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Sofia Mendes
    * @version                        2.6.0.3
    * @since                          11-Jun-2010 
    **********************************************************************************************/
    FUNCTION set_reopen_episode
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_flg_test   IN VARCHAR2,
        o_flg_show   OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_status episode.flg_status%TYPE;
        l_internal_error EXCEPTION;
        l_button        VARCHAR2(4000 CHAR);
        l_flg_reopen_at VARCHAR2(1 CHAR);
    BEGIN
    
        IF (i_flg_test = pk_alert_constant.g_yes)
        THEN
            /*g_error := 'CALL pk_activity_therapist.check_reopen_episode for episode: ' || i_id_episode;
            pk_alertlog.log_debug(g_error);
            IF NOT pk_activity_therapist.check_reopen_episode(i_lang       => i_lang,
                                                              i_prof       => i_prof,
                                                              i_episode    => i_id_episode,
                                                              o_flg_reopen => l_flg_reopen_at,
                                                              o_error      => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
            
            IF (l_flg_reopen_at = pk_alert_constant.g_yes)
            THEN*/
            IF NOT pk_activity_therapist.check_epis_to_reopen(i_lang       => i_lang,
                                                              i_prof       => i_prof,
                                                              i_id_episode => i_id_episode,
                                                              o_flg_show   => o_flg_show,
                                                              o_msg        => o_msg,
                                                              o_msg_title  => o_msg_title,
                                                              o_error      => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
            /*ELSE
                o_flg_show := pk_act_therap_constant.g_flg_show_l;
                o_msg      := pk_message.get_message(i_lang, 'VISIT_M008'); -- NaO PODE REABRIR                    
            END IF;*/
        ELSE
            g_error := 'CALL pk_episode.get_flg_status for episode: ' || i_id_episode;
            pk_alertlog.log_debug(g_error);
            IF NOT pk_episode.get_flg_status(i_lang       => i_lang,
                                             i_prof       => i_prof,
                                             i_id_episode => i_id_episode,
                                             o_flg_status => l_flg_status,
                                             o_error      => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
            IF (l_flg_status = pk_alert_constant.g_epis_status_inactive)
            THEN
            
                g_error := 'CALL pk_activity_therapist.check_reopen_episode for episode: ' || i_id_episode;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_activity_therapist.check_reopen_episode(i_lang       => i_lang,
                                                                  i_prof       => i_prof,
                                                                  i_episode    => i_id_episode,
                                                                  o_flg_reopen => l_flg_reopen_at,
                                                                  o_error      => o_error)
                THEN
                    RAISE l_internal_error;
                END IF;
            
                IF (l_flg_reopen_at = pk_alert_constant.g_yes)
                THEN
                    --reopen episode
                    g_error := 'CALL pk_visit.set_reopen_epis';
                    pk_alertlog.log_debug(g_error);
                    IF NOT pk_visit.set_reopen_epis(i_lang       => i_lang,
                                                    i_prof       => i_prof,
                                                    i_id_epis    => i_id_episode,
                                                    i_flg_reopen => pk_alert_constant.g_no,
                                                    o_flg_show   => o_flg_show,
                                                    o_msg        => o_msg,
                                                    o_msg_title  => o_msg_title,
                                                    o_button     => l_button,
                                                    o_error      => o_error)
                    THEN
                        RAISE l_internal_error;
                    END IF;
                    /*ELSE
                    o_flg_show := pk_alert_constant.g_yes;
                    o_msg      := pk_message.get_message(i_lang, 'VISIT_M008'); -- NaO PODE REABRIR    */
                END IF;
            
            ELSE
                o_flg_show := pk_alert_constant.g_no;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_REOPEN_EPISODE',
                                              o_error    => o_error);
            RETURN FALSE;
        
    END set_reopen_episode;

    /**********************************************************************************************
    * Gets the default discharge reason to the Activity Therapy discharge. 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids    
    * @param o_id_disch_reas_dest     Id of the disch_reas_dest      
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Sofia Mendes
    * @version                        2.6.0.3
    * @since                          02-Jun-2010 
    **********************************************************************************************/
    FUNCTION get_default_disch_reas
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        o_id_disch_reas_dest OUT disch_reas_dest.id_disch_reas_dest%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_disch_reason disch_reas_dest.id_discharge_reason%TYPE;
    BEGIN
        g_error := 'CALL pk_sysconfig.get_config';
        pk_alertlog.log_debug(g_error);
        l_disch_reason := pk_sysconfig.get_config(i_code_cf => pk_act_therap_constant.g_def_disch_reas_sc,
                                                  i_prof    => i_prof);
    
        g_error := 'GET o_id_disch_reas_dest';
        pk_alertlog.log_debug(g_error);
        SELECT drd.id_disch_reas_dest data
          INTO o_id_disch_reas_dest
          FROM disch_reas_dest drd
         WHERE drd.id_discharge_reason = l_disch_reason
           AND drd.id_instit_param IN (i_prof.institution, 0)
           AND drd.id_software_param = i_prof.software
           AND drd.flg_active = pk_alert_constant.g_active
           AND rownum = 1;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => pk_act_therap_constant.g_msg_disch_no_config,
                                              i_sqlerrm  => pk_message.get_message(i_lang      => i_lang,
                                                                                   i_code_mess => pk_act_therap_constant.g_msg_disch_no_config),
                                              i_message  => pk_message.get_message(i_lang      => i_lang,
                                                                                   i_code_mess => pk_act_therap_constant.g_msg_error),
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_DEFAULT_DISCH_REAS',
                                              o_error    => o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_DEFAULT_DISCH_REAS',
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_default_disch_reas;

    /*
    * Set discharge.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_prof_cat       logged professional category
    * @param i_discharge      discharge identifier
    * @param i_episode        episode identifier
    * @param i_dt_end         discharge date    
    * @param i_notes          discharge notes_med
    * @param i_print_report   print report?
    * @param o_reports_pat    report to print
    * @param o_flg_show       warm
    * @param o_msg_title      warn
    * @param o_msg_text       warn
    * @param o_button         warn
    * @param o_id_episode     created episode identifier
    * @param o_discharge      created discharge identifier
    * @param o_disch_detail   created discharge_detail identifier
    * @param o_disch_hist     created discharge_hist identifier
    * @param o_disch_det_hist created discharge_detail_hist identifier
    * @param o_error          error message
    *
    * @return                 false if errors occur, true otherwise
    *
    * @author                 Sofia Mendes
    * @version                 2.6.0.3
    * @since                  01-Jun-2010
    */
    FUNCTION set_discharge
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_prof_cat         IN category.flg_type%TYPE,
        i_discharge        IN discharge.id_discharge%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_dt_end           IN VARCHAR2,
        i_notes            IN discharge.notes_med%TYPE,
        i_time_spent       IN discharge_detail.total_time_spent%TYPE,
        i_unit_measure     IN discharge_detail.id_unit_measure%TYPE,
        i_print_report     IN discharge_detail.flg_print_report%TYPE,
        i_flg_type_closure IN discharge_detail.flg_type_closure%TYPE,
        o_reports_pat      OUT reports.id_reports%TYPE,
        o_flg_show         OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg_text         OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_id_episode       OUT episode.id_episode%TYPE,
        o_discharge        OUT discharge.id_discharge%TYPE,
        o_disch_detail     OUT discharge_detail.id_discharge_detail%TYPE,
        o_disch_hist       OUT discharge_hist.id_discharge_hist%TYPE,
        o_disch_det_hist   OUT discharge_detail_hist.id_discharge_detail_hist%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error  EXCEPTION;
        l_no_disch_reason EXCEPTION;
        l_id_disch_reas_dest disch_reas_dest.id_disch_reas_dest%TYPE;
        l_has_supplies       VARCHAR2(1);
        l_id_discharge       discharge.id_discharge%TYPE;
        l_rowids             table_varchar;
    BEGIN
        --get the default discharge reason (because the activity therapy discharge does not require an explicit discharge reason)
        g_error := 'CALL get_default_disch_reas';
        pk_alertlog.log_debug(g_error);
        IF NOT get_default_disch_reas(i_lang               => i_lang,
                                      i_prof               => i_prof,
                                      o_id_disch_reas_dest => l_id_disch_reas_dest,
                                      o_error              => o_error)
        THEN
            RAISE l_no_disch_reason;
        END IF;
    
        --check if there is loaned supplies in this episode
        g_error := 'CALL pk_supplies_external_api_db.check_loaned_supplies for episode: ' || i_episode;
        pk_alertlog.log_debug(g_error);
        l_has_supplies := pk_supplies_external_api_db.check_loaned_supplies(i_lang       => i_lang,
                                                                            i_prof       => i_prof,
                                                                            i_id_episode => i_episode);
    
        IF (l_has_supplies = pk_alert_constant.g_yes)
        THEN
            o_flg_show  := pk_alert_constant.g_yes;
            o_msg_title := pk_message.get_message(i_lang, i_prof, pk_act_therap_constant.g_msg_error);
            o_msg_text  := pk_message.get_message(i_lang, i_prof, pk_act_therap_constant.g_msg_disch_has_sup);
            o_button    := pk_act_therap_constant.g_button;
        ELSE
            --discharges
            g_error := 'CALL pk_paramedical_prof_core.set_discharge';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_paramedical_prof_core.set_discharge(i_lang             => i_lang,
                                                          i_prof             => i_prof,
                                                          i_prof_cat         => i_prof_cat,
                                                          i_discharge        => i_discharge,
                                                          i_episode          => i_episode,
                                                          i_dt_end           => i_dt_end,
                                                          i_disch_dest       => l_id_disch_reas_dest,
                                                          i_notes            => i_notes,
                                                          i_time_spent       => i_time_spent,
                                                          i_unit_measure     => i_unit_measure,
                                                          i_print_report     => i_print_report,
                                                          i_flg_type_closure => i_flg_type_closure,
                                                          o_reports_pat      => o_reports_pat,
                                                          o_flg_show         => o_flg_show,
                                                          o_msg_title        => o_msg_title,
                                                          o_msg_text         => o_msg_text,
                                                          o_button           => o_button,
                                                          o_id_episode       => o_id_episode,
                                                          o_discharge        => o_discharge,
                                                          o_disch_detail     => o_disch_detail,
                                                          o_disch_hist       => o_disch_hist,
                                                          o_disch_det_hist   => o_disch_det_hist,
                                                          o_error            => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
            g_error := 'Inactivate episode: ' || i_episode;
            pk_alertlog.log_debug(g_error);
            ts_episode.upd(id_episode_in   => i_episode,
                           flg_status_in   => pk_alert_constant.g_epis_status_inactive,
                           flg_status_nin  => FALSE,
                           dt_end_tstz_in  => current_timestamp,
                           dt_end_tstz_nin => FALSE,
                           rows_out        => l_rowids);
        
            g_error := 'CALL  t_data_gov_mnt.process_update';
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'EPISODE',
                                          i_rowids       => l_rowids,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_STATUS', 'DT_END_TSTZ'));
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_no_disch_reason THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN l_internal_error THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_DISCHARGE',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_discharge;

    /******************************************************************************
    *  Function that creates the sys_alert for the activity therapist profile,
    *  in case it is performed an inpatient discharge and the patient has loaned supplies.
    *
    *  @param  i_lang                     Language ID
    *  @param  i_prof                     Professional ID/Institution ID/Software ID
    *  @param  i_id_epis_parent           Episode identifier (parent episode)
    *  @param  o_error                    error info
    *
    *  @return                     boolean
    *
    *  @author                     Sofia Mendes
    *  @version                    2.6.0.3
    *  @since                      02-Jun-2010
    ******************************************************************************/
    FUNCTION set_supplies_alert
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_epis_parent IN episode.id_episode%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
        l_id_at_epis episode.id_episode%TYPE;
        l_id_patient patient.id_patient%TYPE;
        l_pat_name   patient.name%TYPE;
    BEGIN
        g_error := 'CALL get_epis_child for id_episode: ' || i_id_epis_parent;
        pk_alertlog.log_debug(g_error);
        IF NOT get_epis_child(i_lang           => i_lang,
                              i_prof           => i_prof,
                              i_id_epis_parent => i_id_epis_parent,
                              o_id_episode     => l_id_at_epis,
                              o_error          => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'CALL pk_episode.get_epis_patient for id_episode: ' || l_id_at_epis;
        pk_alertlog.log_debug(g_error);
        l_id_patient := pk_episode.get_epis_patient(i_lang => i_lang, i_prof => i_prof, i_episode => l_id_at_epis);
    
        g_error := 'CALL pk_patient.get_pat_name for id_patient: ' || l_id_patient;
        pk_alertlog.log_debug(g_error);
        l_pat_name := pk_patient.get_pat_name(i_lang, i_prof, l_id_patient, l_id_at_epis);
    
        g_error := 'CALL pk_alerts.insert_sys_alert_event';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_alerts.insert_sys_alert_event(i_lang                => i_lang,
                                                i_prof                => i_prof,
                                                i_sys_alert           => pk_act_therap_constant.g_id_supplies_alert,
                                                i_id_episode          => l_id_at_epis,
                                                i_id_record           => i_id_epis_parent,
                                                i_dt_record           => current_timestamp,
                                                i_id_professional     => NULL,
                                                i_id_room             => NULL,
                                                i_id_clinical_service => NULL,
                                                i_flg_type_dest       => NULL,
                                                i_replace1            => l_pat_name,
                                                i_replace2            => NULL,
                                                o_error               => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_SUPPLIES_ALERT',
                                              o_error);
            RETURN FALSE;
    END set_supplies_alert;

    /**********************************************************************************************
    * Checks if the episode has loaned supplies. If yes sends an alert to the Activity Therapist.   
    * To be used in the physician inpatient discharge.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             Parent episode id         
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Sofia Mendes
    * @version                        2.6.0.3
    * @since                          02-Jun-2010
    **********************************************************************************************/
    FUNCTION set_discharge_phy
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_internal_error EXCEPTION;
        l_epis_at      episode.id_episode%TYPE;
        l_has_supplies VARCHAR2(1);
    BEGIN
        -- get activity therapy episode
        g_error := 'CALL get_epis_child for episode: ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT get_epis_child(i_lang           => i_lang,
                              i_prof           => i_prof,
                              i_id_epis_parent => i_id_episode,
                              o_id_episode     => l_epis_at,
                              o_error          => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        IF (l_epis_at IS NOT NULL)
        THEN
            --check if there is loaned supplies in the Activity Therapy episode
            g_error := 'CALL pk_supplies_external_api_db.check_loaned_supplies for episode: ' || l_epis_at;
            pk_alertlog.log_debug(g_error);
            l_has_supplies := pk_supplies_external_api_db.check_loaned_supplies(i_lang       => i_lang,
                                                                                i_prof       => i_prof,
                                                                                i_id_episode => l_epis_at);
        
            IF (l_has_supplies = pk_alert_constant.g_yes)
            THEN
                -- send alert to the Activity Therapist
                g_error := 'CALL set_supplies_alert for episode: ' || i_id_episode;
                pk_alertlog.log_debug(g_error);
                IF NOT set_supplies_alert(i_lang           => i_lang,
                                          i_prof           => i_prof,
                                          i_id_epis_parent => i_id_episode,
                                          o_error          => o_error)
                THEN
                    RAISE l_internal_error;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_DISCHARGE_PHY',
                                              o_error    => o_error);
            RETURN FALSE;
        
    END set_discharge_phy;

    /**********************************************************************************************
    * Update the activity therapy request.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode_at          Activity Therapy episode id        
    * @param i_from_states            Request possible states
    * @param i_to_state               State to which the request will be updated to
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Sofia Mendes
    * @version                        2.6.0.3
    * @since                          14-Jun-2010
    **********************************************************************************************/
    FUNCTION update_request_state
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode_at IN episode.id_episode%TYPE,
        i_from_states   IN table_varchar,
        i_to_state      IN opinion.flg_state%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
        l_opinion      opinion.id_opinion%TYPE;
        l_opinion_hist opinion_hist.id_opinion_hist%TYPE;
    BEGIN
        --update state of the request undergoing activity therapist episodes            
        g_error := 'CALL pk_opinion.get_opinion_id_by_state (state: accepted) for episode: ' || i_id_episode_at;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_opinion.get_opinion_id_by_state(i_lang            => i_lang,
                                                  i_prof            => i_prof,
                                                  i_id_episode      => i_id_episode_at,
                                                  i_id_opinion_type => pk_act_therap_constant.g_at_opinion_type,
                                                  i_flg_states      => i_from_states,
                                                  o_id_opinion      => l_opinion,
                                                  o_error           => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        IF l_opinion IS NOT NULL
        THEN
            --set the request state as concluded
            g_error := 'CALL pk_opinion_pc.set_consult_request_state for id_opinion: ' || l_opinion;
            pk_alertlog.log_debug(g_error);
            IF NOT pk_opinion.set_consult_request_state(i_lang         => i_lang,
                                                        i_prof         => i_prof,
                                                        i_opinion      => l_opinion,
                                                        i_state        => i_to_state,
                                                        i_set_oprof    => pk_alert_constant.g_no,
                                                        o_opinion_hist => l_opinion_hist,
                                                        o_error        => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'UPDATE_REQUEST_STATE',
                                              o_error    => o_error);
            RETURN FALSE;
        
    END update_request_state;

    /**********************************************************************************************
    * Checks if the AT episode had already been discharged. If no, inactive the AT episode.
    * To be used in the registrar inpatient discharge.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             Parent episode id         
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Sofia Mendes
    * @version                        2.6.0.3
    * @since                          02-Jun-2010
    **********************************************************************************************/
    FUNCTION set_discharge_adm
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_internal_error EXCEPTION;
        l_epis_at      episode.id_episode%TYPE;
        l_has_supplies VARCHAR2(1);
        l_at_discharge VARCHAR2(1);
    
        l_opinion_data       pk_types.cursor_type;
        l_flg_state_temp     opinion.flg_state%TYPE;
        l_id_opinion_temp    opinion.id_opinion%TYPE;
        l_id_episode_at_temp opinion.id_episode_answer%TYPE;
        l_flg_show           VARCHAR2(4000);
        l_msg                VARCHAR2(4000);
        l_msg_title          VARCHAR2(4000);
    BEGIN
        -- get activity therapy episode
        g_error := 'CALL get_epis_child for episode: ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT get_epis_child(i_lang           => i_lang,
                              i_prof           => i_prof,
                              i_id_epis_parent => i_id_episode,
                              o_id_episode     => l_epis_at,
                              o_error          => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        --if there is an active AT episode
        IF (l_epis_at IS NOT NULL)
        THEN
            --raise l_internal_error;
            --if the patient has not more loaned supplies and the parent episode is inactive, the child episode
            -- should also stay inactive    
            g_error := 'CALL pk_activity_therapist.set_parent_epis_inact for episode: ' || l_epis_at;
            pk_alertlog.log_debug(g_error);
            IF NOT pk_activity_therapist.set_epis_inact_no_sup(i_lang       => i_lang,
                                                               i_prof       => i_prof,
                                                               i_id_episode => l_epis_at,
                                                               o_flg_show   => l_flg_show,
                                                               o_msg        => l_msg,
                                                               o_msg_title  => l_msg_title,
                                                               o_error      => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_DISCHARGE_ADM',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_DISCHARGE_ADM',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_discharge_adm;

    /*
    * Check if the CREATE button must be enabled
    * in the discharge screen.
    *
    * @param i_lang           language identifier
    * @param i_prof                   professional, software and institution ids
    * @param i_episode        episode identifier
    * @param o_create         'Y' to enable create, 'N' otherwise
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                 2.6.0.3
    * @since                  01-Jun-2010
    */
    FUNCTION get_discharge_create
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_create  OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
        l_flg_status episode.flg_status%TYPE;
    BEGIN
        g_error := 'CALL pk_episode.get_flg_status for episode: ' || i_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_episode.get_flg_status(i_lang       => i_lang,
                                         i_prof       => i_prof,
                                         i_id_episode => i_episode,
                                         o_flg_status => l_flg_status,
                                         o_error      => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        IF l_flg_status <> pk_alert_constant.g_epis_status_inactive
        THEN
            g_error := 'CALL pk_discharge_amb.get_discharge_create';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_discharge_amb.get_discharge_create(i_lang    => i_lang,
                                                         i_episode => i_episode,
                                                         o_create  => o_create,
                                                         o_error   => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        ELSE
            o_create := pk_alert_constant.g_no;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_DISCHARGE_CREATE',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_discharge_create;

    /**********************************************************************************************
    * Gets the message to he shown in the popup that appears when the Activity Therapist starts 
    * a new Activity Therapy episode (if he has permissions to create requests without approval)
    * or a request to be approved by other professional. 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids    
    * @param o_msg_title              Popup title      
    * @param o_msg                    Popup messsage
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Sofia Mendes
    * @version                        2.6.0.3
    * @since                          15-Jun-2010 
    **********************************************************************************************/
    FUNCTION get_start_ther_pop_msgs
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_approve opinion_type_prof.flg_approve%TYPE;
    BEGIN
        g_error := 'CALL check_approval_need';
        pk_alertlog.log_debug(g_error);
        l_flg_approve := pk_opinion.check_approval_need(i_prof         => i_prof,
                                                        i_opinion_type => pk_act_therap_constant.g_at_opinion_type);
    
        IF (l_flg_approve = pk_alert_constant.g_yes)
        THEN
            o_msg_title := pk_message.get_message(i_lang      => i_lang,
                                                  i_code_mess => pk_act_therap_constant.g_msg_create_req);
            o_msg       := pk_message.get_message(i_lang      => i_lang,
                                                  i_code_mess => pk_act_therap_constant.g_msg_create_req_cont);
        ELSE
            o_msg_title := pk_message.get_message(i_lang      => i_lang,
                                                  i_code_mess => pk_act_therap_constant.g_msg_start_therapy);
            o_msg       := pk_message.get_message(i_lang      => i_lang,
                                                  i_code_mess => pk_act_therap_constant.g_msg_start_cont);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_START_THER_POP_MSGS',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_start_ther_pop_msgs;

    /**********************************************************************************************
    * Get the start and end dates to be considered in the EHR detail, according to the time scale 
    * choosen by the use. 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids    
    * @param i_scale                  Time Scale: ALL, YEAR, MONTH, WEEK      
    * @param o_start_date             Time interval start date
    * @param o_end_date               Time interval end date
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Sofia Mendes
    * @version                        2.6.0.3
    * @since                          15-Jun-2010 
    **********************************************************************************************/
    FUNCTION get_scale_dates
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scale      IN VARCHAR2,
        o_start_date OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_end_date   OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL start and end dates';
        pk_alertlog.log_debug(g_error);
    
        IF (i_scale = pk_act_therap_constant.g_scale_all)
        THEN
            o_start_date := NULL;
            o_end_date   := NULL;
        
        ELSIF (i_scale = pk_act_therap_constant.g_scale_year)
        THEN
            o_start_date := pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                             i_timestamp => current_timestamp,
                                                             i_format    => pk_act_therap_constant.g_year_format);
            o_end_date   := pk_date_utils.add_to_ltstz(i_timestamp => o_start_date,
                                                       i_amount    => 1,
                                                       i_unit      => pk_act_therap_constant.g_scale_year);
        
        ELSIF (i_scale = pk_act_therap_constant.g_scale_month)
        THEN
            o_start_date := pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                             i_timestamp => current_timestamp,
                                                             i_format    => pk_act_therap_constant.g_month_format);
            o_end_date   := pk_date_utils.add_to_ltstz(i_timestamp => o_start_date,
                                                       i_amount    => 1,
                                                       i_unit      => pk_act_therap_constant.g_scale_month);
        
        ELSIF (i_scale = pk_act_therap_constant.g_scale_week)
        THEN
            o_start_date := pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                             i_timestamp => current_timestamp,
                                                             i_format    => pk_act_therap_constant.g_week_format);
            o_end_date   := pk_date_utils.add_days_to_tstz(o_start_date, 6);
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_SCALE_DATES',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_scale_dates;

    /**********************************************************************************************
    * Get the start and end dates to be considered in the EHR detail, according to the time scale 
    * choosen by the use. 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids    
    * @param i_scale                  Time Scale: ALL, YEAR, MONTH, WEEK   
    *
    * @return                         description
    *                        
    * @author                         Sofia Mendes
    * @version                        2.6.0.3
    * @since                          23-Jun-2010 
    **********************************************************************************************/
    FUNCTION get_ehr_main_header
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_scale IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_res   pk_translation.t_desc_translation;
        l_error t_error_out;
    BEGIN
        g_error := 'GET EHR MAIN HEADER';
        pk_alertlog.log_debug(g_error);
    
        SELECT pk_translation.get_translation(i_lang, v.code_view_option)
          INTO l_res
          FROM view_option v
         WHERE v.subject = pk_act_therap_constant.g_ehr_view_option_sub
              
           AND v.screen_identifier = i_scale;
    
        RETURN l_res;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_EHR_MAIN_HEADER',
                                              o_error    => l_error);
            RETURN NULL;
    END get_ehr_main_header;

    /********************************************************************************************
    * Get patient's list of episode of a given patient.
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_patient                 Patient ID   
    * @ param i_remove_status         Episode status to remove from the list
    * @ param o_episodes_ids          List of episode IDs
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Sofia Mendes
    * @version                         2.6.0.3
    * @since                           2010/03/15
    **********************************************************************************************/
    FUNCTION get_parent_epis_by_pat
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN patient.id_patient%TYPE,
        i_remove_status IN table_varchar DEFAULT table_varchar(pk_alert_constant.g_flg_status_c),
        --list of episodes
        o_episodes_ids OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET_EPIS_BY_TYPE_AND_PAT';
        pk_alertlog.log_debug(g_error);
    
        SELECT epi.id_episode id_episode
          BULK COLLECT
          INTO o_episodes_ids
          FROM episode epi
          JOIN opinion op
            ON op.id_episode = epi.id_episode
         WHERE epi.id_patient = i_id_patient
           AND epi.flg_status NOT IN (SELECT column_value
                                        FROM TABLE(i_remove_status))
           AND op.id_opinion_type = pk_act_therap_constant.g_at_opinion_type;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_PARENT_EPIS_BY_PAT',
                                              o_error    => o_error);
        
    END get_parent_epis_by_pat;

    /********************************************************************************************
    * Get the episodes detail information 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 Patient ID
    * @ param o_episodes_det          List of episodes detail
    * @ param o_error 
    
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Sofia Mendes
    * @version                         2.6.0.3
    * @since                           18-Jun-2010
    **********************************************************************************************/
    FUNCTION get_episodes_detail
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_pat      IN patient.id_patient%TYPE,
        i_id_episodes IN table_number,
        --list of episodes
        o_episodes_det OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_admission_label sys_message.desc_message%TYPE;
        l_discharge_label sys_message.desc_message%TYPE;
    BEGIN
    
        l_admission_label := pk_act_therap_constant.g_open_bold_html ||
                             pk_message.get_message(i_lang, i_prof, pk_act_therap_constant.g_msg_admission) ||
                             pk_act_therap_constant.g_close_bold_html;
    
        l_discharge_label := pk_act_therap_constant.g_open_bold_html ||
                             pk_message.get_message(i_lang, i_prof, pk_act_therap_constant.g_msg_discharge) ||
                             pk_act_therap_constant.g_close_bold_html;
    
        g_error := 'GET EPISODES DETAIL';
        pk_alertlog.log_debug(g_error);
    
        OPEN o_episodes_det FOR
            SELECT t.id_episode_origin,
                   t.dt,
                   t.dt_str,
                   t.prof_sign,
                   t.epis_det_desc,
                   t.admission_date_desc,
                   l_discharge_label || decode(t.dt_discharge,
                                               NULL,
                                               pk_act_therap_constant.g_dashes,
                                               pk_date_utils.dt_chr_tsz(i_lang, t.dt_discharge, i_prof) ||
                                               pk_act_therap_constant.g_open_parenthesis ||
                                               pk_inp_grid.get_discharge_msg(i_lang, i_prof, t.id_episode_origin, NULL) ||
                                               pk_act_therap_constant.g_close_parenthesis) discharge_date_desc
            
              FROM (SELECT epi.id_episode id_episode_origin,
                           pk_date_utils.dt_chr_tsz(i_lang, epi.dt_begin_tstz, i_prof) dt,
                           pk_date_utils.date_send_tsz(i_lang, epi.dt_begin_tstz, i_prof) dt_str,
                           pk_tools.get_prof_description(i_lang, i_prof, ei.id_professional, epi.dt_creation, NULL) prof_sign,
                           pk_message.get_message(i_lang, 'AT_HIST_T005') epis_det_desc,
                           l_admission_label || pk_date_utils.dt_chr_tsz(i_lang, epi.dt_begin_tstz, i_prof) admission_date_desc,
                           pk_discharge.get_discharge_date(i_lang, i_prof, epi.id_episode) dt_discharge
                      FROM episode epi
                      JOIN epis_info ei
                        ON epi.id_episode = ei.id_episode
                     WHERE epi.id_episode IN (SELECT column_value
                                                FROM TABLE(i_id_episodes))
                    
                     ORDER BY epi.dt_begin_tstz) t;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_episodes_det);
            --
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_EPISODES_DETAIL',
                                              o_error    => o_error);
        
            RETURN FALSE;
    END get_episodes_detail;

    /********************************************************************************************
    * Get the episodes detail information 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episodes               Episode IDs list
    * @param i_start_date             Time interval start date
    * @param i_end_date               Time interval end date
    * @ param o_episodes_det          List of episodes detail
    * @ param o_error 
    
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Sofia Mendes
    * @version                         2.6.0.3
    * @since                           23-Jun-2010
    **********************************************************************************************/
    FUNCTION get_discharge_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episodes   IN table_number,
        i_start_date IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_discharge  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_end_date_desc   sys_message.desc_message%TYPE;
        l_total_time_desc sys_message.desc_message%TYPE;
        l_prof_desc       sys_message.desc_message%TYPE;
        l_nr_enc_desc     sys_message.desc_message%TYPE;
        l_notes_desc      sys_message.desc_message%TYPE;
    BEGIN
        l_end_date_desc   := pk_paramedical_prof_core.format_str_header_w_colon(i_srt       => pk_message.get_message(i_lang,
                                                                                                                      i_prof,
                                                                                                                      'SOCIAL_T125'),
                                                                                i_is_report => pk_alert_constant.g_no);
        l_total_time_desc := pk_paramedical_prof_core.format_str_header_w_colon(i_srt       => pk_message.get_message(i_lang,
                                                                                                                      i_prof,
                                                                                                                      'SOCIAL_T138'),
                                                                                i_is_report => pk_alert_constant.g_no);
        l_nr_enc_desc     := pk_paramedical_prof_core.format_str_header_w_colon(i_srt       => pk_message.get_message(i_lang,
                                                                                                                      i_prof,
                                                                                                                      'SOCIAL_T139'),
                                                                                i_is_report => pk_alert_constant.g_no);
        l_notes_desc      := pk_paramedical_prof_core.format_str_header_w_colon(i_srt       => pk_message.get_message(i_lang,
                                                                                                                      i_prof,
                                                                                                                      'SOCIAL_T082'),
                                                                                i_is_report => pk_alert_constant.g_no);
    
        l_prof_desc := pk_paramedical_prof_core.format_str_header_w_colon(i_srt       => pk_message.get_message(i_lang,
                                                                                                                i_prof,
                                                                                                                'DIET_T126'),
                                                                          i_is_report => pk_alert_constant.g_no);
    
        g_error := 'Open o_discharge cursor';
        pk_alertlog.log_debug(g_error);
        OPEN o_discharge FOR
            SELECT dd.id_episode,
                   pk_activity_therapist.get_epis_parent(i_lang, i_prof, dd.id_episode) id_episode_origin,
                   l_prof_desc || pk_prof_utils.get_name_signature(i_lang, i_prof, dd.id_prof_med) desc_prof,
                   l_total_time_desc ||
                   pk_paramedical_prof_core.get_time_spent_desc(i_lang, dd.total_time_spent, dd.id_unit_measure) desc_total_time_spent,
                   l_nr_enc_desc || dd.followup_count desc_enc_count,
                   l_end_date_desc || pk_date_utils.dt_chr_date_hour_tsz(i_lang, dd.dt_med_tstz, i_prof) desc_date_discharge,
                   pk_paramedical_prof_core.get_ehr_last_update_info(i_lang,
                                                                     i_prof,
                                                                     dd.dt_disch_tstz,
                                                                     dd.id_prof_med,
                                                                     dd.dt_disch_tstz,
                                                                     dd.id_episode) last_update_info
              FROM (SELECT d.id_episode,
                           d.id_prof_med,
                           dt.total_time_spent,
                           dt.id_unit_measure,
                           dt.followup_count,
                           d.dt_med_tstz,
                           nvl((SELECT MAX(dh.dt_created_hist)
                                 FROM discharge_hist dh
                                WHERE dh.id_discharge = d.id_discharge),
                               d.dt_med_tstz) dt_disch_tstz
                      FROM discharge d
                      JOIN discharge_detail dt
                        ON d.id_discharge = dt.id_discharge
                     WHERE d.id_episode IN (SELECT column_value
                                              FROM TABLE(i_episodes))
                       AND (d.flg_status = pk_alert_constant.g_active)
                       AND (i_start_date IS NULL OR d.dt_med_tstz >= i_start_date)
                       AND (i_end_date IS NULL OR d.dt_med_tstz <= i_end_date)
                     ORDER BY d.dt_med_tstz DESC) dd;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_discharge);
        
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_DISCHARGE_LIST',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_discharge_list;

    /********************************************************************************************
    * Get patient's EHR Activity Therapy Summary. This includes information of:
    *    - Activity Therapy requests
    *    - Follow up notes
    *    - Supplies
    *    - Activity Therapy end   
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 Patient ID
    * @param i_episode                ID Episode
    * @param i_scale                  Info of the time interval to be considered: All, Year, Month, Week
    * 
    * @ param o_screen_labels         Labels
    * @ param o_episodes_det          List of patient's episodes
    * @ param o_at_request            Activity Therapy requests   
    * @ param o_follow_up             Follow up notes list
    * @ param o_supplies              Supplies info
    * @ param o_discharge             Activity Therapy dicharge info
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Sofia Mendes
    * @version                         2.6.0.3
    * @since                           19-Jun-2010
    **********************************************************************************************/
    FUNCTION get_summary_ehr
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_pat  IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_scale   IN VARCHAR2,
        --labels
        o_screen_labels OUT pk_types.cursor_type,
        --list of episodes
        o_episodes_det OUT pk_types.cursor_type,
        --request
        o_at_request OUT pk_types.cursor_type,
        --followup notes
        o_follow_up OUT pk_types.cursor_type,
        --diets
        o_supplies OUT pk_types.cursor_type,
        --discharge info
        o_discharge OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
        l_temp_cur        pk_types.cursor_type;
        l_parent_episodes table_number;
        l_episodes        table_number;
    
        t_table_message_array pk_paramedical_prof_core.table_message_array;
        l_start_date          TIMESTAMP WITH LOCAL TIME ZONE;
        l_end_date            TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        pk_alertlog.log_debug('GET SUMMARY EHR - get all labels for the EHR screen');
        IF NOT pk_paramedical_prof_core.get_message_array(i_lang         => i_lang,
                                                          i_code_msg_arr => table_varchar('AT_HIST_T008',
                                                                                          'AT_HIST_T006',
                                                                                          'AT_SUP_T012',
                                                                                          'AT_HIST_T007',
                                                                                          'AT_DISCH_T009'),
                                                          i_prof         => i_prof,
                                                          o_desc_msg_arr => t_table_message_array)
        THEN
            RAISE l_internal_error;
        END IF;
    
        OPEN o_screen_labels FOR
            SELECT REPLACE(t_table_message_array('AT_HIST_T008'),
                           pk_act_therap_constant.g_1st_replace,
                           get_ehr_main_header(i_lang, i_prof, i_scale)) ehr_summary_main_header,
                   t_table_message_array('AT_HIST_T006') followup_header,
                   t_table_message_array('AT_SUP_T012') supplies_header,
                   t_table_message_array('AT_HIST_T007') request_header,
                   t_table_message_array('AT_DISCH_T009') discharge_header
              FROM dual;
    
        g_error := 'CALL pk_social.get_epis_by_type_and_pat';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_social.get_epis_by_type_and_pat(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_id_pat       => i_id_pat,
                                                  i_id_epis_type => table_number(pk_act_therap_constant.g_activ_therap_epis_type),
                                                  o_episodes_ids => l_episodes,
                                                  o_error        => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'CALL get_parent_epis_by_pat';
        pk_alertlog.log_debug(g_error);
        IF NOT get_parent_epis_by_pat(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_id_patient => i_id_pat,
                                      --i_remove_status IN table_varchar DEFAULT table_varchar(pk_alert_constant.g_flg_status_c),
                                      --list of episodes
                                      o_episodes_ids => l_parent_episodes,
                                      o_error        => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'CALL get_scale_dates for scale: ' || i_scale;
        pk_alertlog.log_debug(g_error);
        IF NOT get_scale_dates(i_lang       => i_lang,
                               i_prof       => i_prof,
                               i_scale      => i_scale,
                               o_start_date => l_start_date,
                               o_end_date   => l_end_date,
                               o_error      => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'CALL pk_paramedical_prof_core.get_followup_notes';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_paramedical_prof_core.get_followup_notes(i_lang           => i_lang,
                                                           i_prof           => i_prof,
                                                           i_episode        => l_episodes,
                                                           i_show_cancelled => pk_alert_constant.g_no,
                                                           i_start_date     => l_start_date,
                                                           i_end_date       => l_end_date,
                                                           i_opinion_type   => pk_act_therap_constant.g_at_opinion_type,
                                                           o_follow_up_prof => l_temp_cur,
                                                           o_follow_up      => o_follow_up,
                                                           o_error          => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
        CLOSE l_temp_cur;
    
        --
        g_error := 'CALL get_episodes_detail';
        pk_alertlog.log_debug(g_error);
        IF NOT get_episodes_detail(i_lang         => i_lang,
                                   i_prof         => i_prof,
                                   i_id_pat       => i_id_pat,
                                   i_id_episodes  => l_parent_episodes,
                                   o_episodes_det => o_episodes_det,
                                   o_error        => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'CALL pk_opinion.get_request_summary';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_opinion.get_request_summary(i_lang            => i_lang,
                                              i_prof            => i_prof,
                                              i_id_episode      => l_parent_episodes,
                                              i_id_opinion_type => pk_act_therap_constant.g_at_opinion_type,
                                              i_start_date      => l_start_date,
                                              i_end_date        => l_end_date,
                                              o_requests        => o_at_request,
                                              o_error           => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'CALL pk_supplies_external_api_db.get_workflow_history';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_supplies_external_api_db.get_workflow_history(i_lang               => i_lang,
                                                                i_prof               => i_prof,
                                                                i_id_supply_area     => pk_supplies_constant.g_area_activity_therapy,
                                                                i_id_episode         => l_episodes,
                                                                i_id_supply_workflow => NULL,
                                                                i_id_supply          => NULL,
                                                                i_start_date         => l_start_date,
                                                                i_end_date           => l_end_date,
                                                                i_flg_screen         => pk_act_therap_constant.g_screen_ehr,
                                                                i_supply_desc        => NULL,
                                                                o_sup_workflow_prof  => l_temp_cur,
                                                                o_sup_workflow       => o_supplies,
                                                                o_error              => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
        CLOSE l_temp_cur;
    
        g_error := 'CALL get_discharge_list';
        pk_alertlog.log_debug(g_error);
        IF NOT get_discharge_list(i_lang       => i_lang,
                                  i_prof       => i_prof,
                                  i_episodes   => l_episodes,
                                  i_start_date => l_start_date,
                                  i_end_date   => l_end_date,
                                  o_discharge  => o_discharge,
                                  o_error      => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_types.open_my_cursor(o_screen_labels);
            pk_types.open_my_cursor(o_episodes_det);
            pk_types.open_my_cursor(o_at_request);
            pk_types.open_my_cursor(o_follow_up);
            pk_types.open_my_cursor(o_supplies);
            pk_types.open_my_cursor(o_discharge);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_screen_labels);
            pk_types.open_my_cursor(o_episodes_det);
            pk_types.open_my_cursor(o_at_request);
            pk_types.open_my_cursor(o_follow_up);
            pk_types.open_my_cursor(o_supplies);
            pk_types.open_my_cursor(o_discharge);
        
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_SUMMARY_EHR',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_summary_ehr;

    /**********************************************************************************************
    * Match function to be used when matching inp episodes. Checks if that episodes has activity therapy
    * requests or episodes and treat that requests or match the child episodes.
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_episode_temp                  Temporary episode
    * @param i_episode                       Episode identifier 
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.0.7
    * @since                                 2009/11/03
    **********************************************************************************************/
    FUNCTION set_match_act_therapy
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode_temp IN episode.id_episode%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
        l_opinion_data       pk_types.cursor_type;
        l_flg_state_temp     opinion.flg_state%TYPE;
        l_flg_state          opinion.flg_state%TYPE;
        l_id_opinion         opinion.id_opinion%TYPE;
        l_id_opinion_temp    opinion.id_opinion%TYPE;
        l_id_episode_at      opinion.id_episode_answer%TYPE;
        l_id_episode_at_temp opinion.id_episode_answer%TYPE;
        l_cancel_msg         sys_message.desc_message%TYPE;
    BEGIN
        l_cancel_msg := pk_message.get_message(i_lang      => i_lang,
                                               i_code_mess => pk_act_therap_constant.g_msg_cancel_notes_match);
    
        --check if the def episode has some activity therapy request
        g_error := 'CALL get_request_state of episode: ' || i_episode_temp;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_opinion.get_request_states(i_lang            => i_lang,
                                             i_prof            => i_prof,
                                             i_id_episode      => i_episode_temp,
                                             i_states          => table_varchar(pk_opinion.g_opinion_req,
                                                                                pk_opinion.g_opinion_approved,
                                                                                pk_opinion.g_opinion_accepted),
                                             i_id_opinion_type => pk_act_therap_constant.g_at_opinion_type,
                                             o_data            => l_opinion_data,
                                             o_error           => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        FETCH l_opinion_data
            INTO l_flg_state_temp, l_id_opinion_temp, l_id_episode_at_temp;
        CLOSE l_opinion_data;
    
        --if the request associated to the temporary episode is not yet undergoing
        IF (l_flg_state_temp IS NOT NULL) --IN (pk_opinion.g_opinion_req, pk_opinion.g_opinion_approved))
        THEN
            g_error := 'CALL get_request_state of episode: ' || i_episode;
            pk_alertlog.log_debug(g_error);
            IF NOT pk_opinion.get_request_states(i_lang            => i_lang,
                                                 i_prof            => i_prof,
                                                 i_id_episode      => i_episode,
                                                 i_states          => table_varchar(pk_opinion.g_opinion_req,
                                                                                    pk_opinion.g_opinion_approved,
                                                                                    pk_opinion.g_opinion_accepted),
                                                 i_id_opinion_type => pk_act_therap_constant.g_at_opinion_type,
                                                 o_data            => l_opinion_data,
                                                 o_error           => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
            FETCH l_opinion_data
                INTO l_flg_state, l_id_opinion, l_id_episode_at;
            CLOSE l_opinion_data;
        
            IF (l_flg_state IS NOT NULL)
            THEN
                --if both the definitive and temporary episodes has active therapy requests (not undergoing yet)
                -- the request associated to the temporary episode should be cancelled
                IF l_flg_state_temp IN (pk_opinion.g_opinion_req, pk_opinion.g_opinion_approved)
                THEN
                    g_error := 'CALL pk_opinion.set_opinion_canc_no_val with id_opinion: ' || l_id_opinion_temp;
                    pk_alertlog.log_debug(g_error);
                    IF NOT pk_opinion.set_opinion_canc_no_val(i_lang          => i_lang,
                                                              i_prof          => i_prof,
                                                              i_opinion       => l_id_opinion_temp,
                                                              i_opinion_type  => pk_act_therap_constant.g_at_opinion_type,
                                                              i_notes_cancel  => NULL,
                                                              i_cancel_reason => NULL,
                                                              o_error         => o_error)
                    THEN
                        RAISE l_internal_error;
                    END IF;
                
                ELSIF (l_flg_state_temp = pk_opinion.g_opinion_accepted)
                THEN
                    --the AT request of the temporary epis is undergoing and the AT request of the definitive
                    -- episode is requestes or accepetd (no epis created yet)                    
                    IF (l_flg_state IN (pk_opinion.g_opinion_req, pk_opinion.g_opinion_approved))
                    THEN
                        --cancel the request of the definitive episode
                        g_error := 'CALL pk_opinion.set_opinion_canc_no_val with id_opinion: ' || l_id_opinion_temp;
                        pk_alertlog.log_debug(g_error);
                        IF NOT pk_opinion.set_opinion_canc_no_val(i_lang          => i_lang,
                                                                  i_prof          => i_prof,
                                                                  i_opinion       => l_id_opinion,
                                                                  i_opinion_type  => pk_act_therap_constant.g_at_opinion_type,
                                                                  i_notes_cancel  => NULL,
                                                                  i_cancel_reason => NULL,
                                                                  o_error         => o_error)
                        THEN
                            RAISE l_internal_error;
                        END IF;
                    ELSE
                        --both episodes has undergoing request (active activity therapy episodes) :(
                        --transfer the followup notes and supplies from the AT epis of the temporary inp epis
                        --to the definitive one                        
                        g_error := 'CALL pk_match.set_match_episodes with i_episode_temp: ' || l_id_episode_at_temp ||
                                   ' and i_episode: ' || l_id_episode_at;
                        pk_alertlog.log_debug(g_error);
                        IF NOT pk_match.set_match_episodes(i_lang         => i_lang,
                                                           i_prof         => i_prof,
                                                           i_episode_temp => l_id_episode_at_temp,
                                                           i_episode      => l_id_episode_at,
                                                           o_error        => o_error)
                        THEN
                            RAISE l_internal_error;
                        END IF;
                    
                        --cancel the request associated to the temporary episode
                        g_error := 'CALL pk_opinion.set_opinion_canc_no_val with id_opinion: ' || l_id_opinion_temp;
                        pk_alertlog.log_debug(g_error);
                        IF NOT pk_opinion.set_opinion_canc_no_val(i_lang          => i_lang,
                                                                  i_prof          => i_prof,
                                                                  i_opinion       => l_id_opinion_temp,
                                                                  i_opinion_type  => pk_act_therap_constant.g_at_opinion_type,
                                                                  i_notes_cancel  => NULL,
                                                                  i_cancel_reason => NULL,
                                                                  o_error         => o_error)
                        THEN
                            RAISE l_internal_error;
                        END IF;
                    
                        g_error := 'CALL pk_alerts.delete_sys_alert_event_episode with id_opinion: ' ||
                                   l_id_opinion_temp;
                        pk_alertlog.log_debug(g_error);
                        IF NOT pk_alerts.delete_sys_alert_event_episode(i_lang    => i_lang,
                                                                        i_prof    => i_prof,
                                                                        i_episode => l_id_episode_at_temp,
                                                                        i_delete  => pk_alert_constant.g_yes,
                                                                        o_error   => o_error)
                        THEN
                            RAISE l_internal_error;
                        END IF;
                    
                    END IF;
                END IF;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_MATCH_ACT_THERAPY',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_match_act_therapy;
BEGIN
    -- Initialization

    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_activity_therapist;
/
