/*-- Last Change Revision: $Rev: 2026608 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:19 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_activity_therapist_ux IS

    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    /********************************************************************************************
    * Get data for the activity therapist 'my patients' grids.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure    
    * @param o_requests       requests cursor
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                2.6.0.3
    * @since                  06-05-2010
    */
    FUNCTION get_grid_my_patients
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_requests OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
    BEGIN
        g_error := 'CALL pk_paramedical_prof_core.get_paramedical_requests';
        IF NOT pk_activity_therapist.get_grid_patients(i_lang     => i_lang,
                                                       i_prof     => i_prof,
                                                       i_show_all => pk_alert_constant.g_no,
                                                       o_requests => o_requests,
                                                       o_error    => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_requests);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_GRID_MY_PATIENTS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_requests);
            RETURN FALSE;
        
    END get_grid_my_patients;

    /********************************************************************************************
    * Get data for the activity therapist 'my specialties' grids.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure    
    * @param o_requests       requests cursor
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                2.6.0.3
    * @since                  06-05-2010
    */
    FUNCTION get_grid_my_specialties
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_requests OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
    BEGIN
        g_error := 'CALL pk_paramedical_prof_core.get_paramedical_requests';
        IF NOT pk_activity_therapist.get_grid_patients(i_lang     => i_lang,
                                                       i_prof     => i_prof,
                                                       i_show_all => pk_alert_constant.g_yes,
                                                       o_requests => o_requests,
                                                       o_error    => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_requests);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_GRID_MY_SPECIALTIES',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_requests);
            RETURN FALSE;
        
    END get_grid_my_specialties;

    /*
    * Get an episode's follow up notes list.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        social episode identifier
    * @param i_mng_followup   follow up notes identifier
    * @param o_follow_up_prof follow up notes records info 
    * @param o_follow_up      follow up notes
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                 2.6.0.3
    * @since                  20-May-2010
    */
    FUNCTION get_followup_notes
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN management_follow_up.id_episode%TYPE,
        i_mng_followup   IN management_follow_up.id_management_follow_up%TYPE,
        o_follow_up_prof OUT pk_types.cursor_type,
        o_follow_up      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
    BEGIN
        g_error := 'CALL pk_paramedical_prof_core.get_followup_notes';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_paramedical_prof_core.get_followup_notes(i_lang           => i_lang,
                                                           i_prof           => i_prof,
                                                           i_episode        => i_episode,
                                                           i_mng_followup   => i_mng_followup,
                                                           i_show_cancelled => pk_alert_constant.g_yes,
                                                           o_follow_up_prof => o_follow_up_prof,
                                                           o_follow_up      => o_follow_up,
                                                           o_error          => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_follow_up_prof);
            pk_types.open_my_cursor(o_follow_up);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_FOLLOWUP_NOTES',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_follow_up_prof);
            pk_types.open_my_cursor(o_follow_up);
            RETURN FALSE;
    END get_followup_notes;

    /*
    * Set follow up notes.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_mng_followup   follow up notes identifier
    * @param i_episode        episode identifier
    * @param i_notes          follow up notes
    * @param i_start_dt       start date
    * @param i_time_spent     time spent
    * @param i_unit_time      time spent unit measure
    * @param i_next_dt        next date
    * @param o_mng_followup   created follow up notes identifier
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                 2.6.0.3
    * @since                  20-May-2010
    */
    FUNCTION set_followup_notes
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_mng_followup IN management_follow_up.id_management_follow_up%TYPE,
        i_episode      IN management_follow_up.id_episode%TYPE,
        i_notes        IN management_follow_up.notes%TYPE,
        i_start_dt     IN VARCHAR2,
        i_time_spent   IN management_follow_up.time_spent%TYPE,
        i_unit_time    IN management_follow_up.id_unit_time%TYPE,
        i_next_dt      IN VARCHAR2,
        o_mng_followup OUT management_follow_up.id_management_follow_up%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
    BEGIN
        g_error := 'CALL pk_paramedical_prof_core.set_followup_notes';
        IF NOT pk_paramedical_prof_core.set_followup_notes(i_lang         => i_lang,
                                                           i_prof         => i_prof,
                                                           i_mng_followup => i_mng_followup,
                                                           i_episode      => i_episode,
                                                           i_notes        => i_notes,
                                                           i_start_dt     => i_start_dt,
                                                           i_time_spent   => i_time_spent,
                                                           i_unit_time    => i_unit_time,
                                                           i_next_dt      => i_next_dt,
                                                           o_mng_followup => o_mng_followup,
                                                           o_error        => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_EDIT_FOLLOWUP_NOTES',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_followup_notes;

    /*
    * Cancel follow up notes.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_mng_followup   follow up notes identifier
    * @param i_episode        episode identifier
    * @param i_cancel_reason  cancellation reason
    * @param i_notes          cancellation notes
    * @param o_mng_followup   created follow up notes identifier
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                 2.6.0.3
    * @since                  20-May-2010
    */
    FUNCTION set_cancel_followup_notes
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_mng_followup  IN management_follow_up.id_management_follow_up%TYPE,
        i_episode       IN management_follow_up.id_episode%TYPE,
        i_cancel_reason IN management_follow_up.id_cancel_reason%TYPE,
        i_notes         IN management_follow_up.notes_cancel%TYPE,
        o_mng_followup  OUT management_follow_up.id_management_follow_up%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
    BEGIN
        g_error := 'CALL pk_case_management.cancel_mng_followup';
        IF NOT pk_case_management.cancel_mng_followup(i_lang              => i_lang,
                                                      i_prof              => i_prof,
                                                      i_mng_plan_followup => i_mng_followup,
                                                      i_episode           => i_episode,
                                                      i_epis_encounter    => NULL,
                                                      i_cancel_reason     => i_cancel_reason,
                                                      i_notes             => i_notes,
                                                      o_mng_plan_followup => o_mng_followup,
                                                      o_error             => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_CANCEL_FOLLOWUP_NOTES',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_cancel_followup_notes;

    /*
    * Get follow up notes data for the create/edit screen.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_mng_followup   follow up notes identifier
    * @param o_follow_up      follow up notes
    * @param o_time_units     time units
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                 2.6.0.3
    * @since                  21-May-2010
    */
    FUNCTION get_followup_notes_edit
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_mng_followup IN management_follow_up.id_management_follow_up%TYPE,
        o_follow_up    OUT pk_types.cursor_type,
        o_time_units   OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
        o_domain pk_types.cursor_type;
    BEGIN
        g_error := 'CALL pk_paramedical_prof_core.get_edit_followup_notes';
        IF NOT pk_paramedical_prof_core.get_followup_notes_edit(i_lang         => i_lang,
                                                                i_prof         => i_prof,
                                                                i_mng_followup => i_mng_followup,
                                                                o_follow_up    => o_follow_up,
                                                                o_time_units   => o_time_units,
                                                                o_domain       => o_domain,
                                                                o_error        => o_error)
        
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_follow_up);
            pk_types.open_my_cursor(o_time_units);
            pk_types.open_my_cursor(o_domain);
        
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_FOLLOWUP_NOTES_EDIT',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_follow_up);
            pk_types.open_my_cursor(o_time_units);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_followup_notes_edit;

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
        l_internal_error EXCEPTION;
    BEGIN
        g_error := 'CALL pk_activity_therapist.get_supplies_grid';
        IF NOT pk_activity_therapist.get_supplies_grid(i_lang  => i_lang,
                                                       i_prof  => i_prof,
                                                       o_grid  => o_grid,
                                                       o_error => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_grid);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_SUPPLIES_GRID',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_grid);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END get_supplies_grid;

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
    BEGIN
        g_error := 'CALL pk_activity_therapist.get_supply_patients for id_supply = ' || i_id_supply;
        IF NOT pk_activity_therapist.get_supply_patients(i_lang      => i_lang,
                                                         i_prof      => i_prof,
                                                         i_id_supply => i_id_supply,
                                                         o_grid      => o_grid,
                                                         o_header    => o_header,
                                                         o_error     => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.reset_error_state;
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
            pk_alert_exceptions.reset_error_state;
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
    BEGIN
        g_error := 'CALL pk_activity_therapist.get_workflow_detail for id_supply_workflow = ' || i_id_supply_workflow ||
                   ' and id_episode: ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_activity_therapist.get_workflow_history(i_lang               => i_lang,
                                                          i_prof               => i_prof,
                                                          i_id_episode         => i_id_episode,
                                                          i_id_supply_workflow => i_id_supply_workflow,
                                                          i_id_supply          => i_id_supply,
                                                          i_id_patient         => i_id_patient,
                                                          o_sup_workflow_prof  => o_sup_workflow_prof,
                                                          o_sup_workflow       => o_sup_workflow,
                                                          o_header             => o_header,
                                                          o_error              => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_sup_workflow_prof);
            pk_types.open_my_cursor(o_sup_workflow);
            pk_utils.undo_changes;
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
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_sup_workflow_prof);
            pk_types.open_my_cursor(o_sup_workflow);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END get_workflow_history;

    /********************************************************************************************
    * Get inactive activity therapist episodes info.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure     
    * @param i_id_patient     Patient identifier    
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
        l_internal_error EXCEPTION;
    BEGIN
        g_error := 'CALL pk_activity_therapist.get_epis_pat_inactive FOR id_patient = ' || i_id_patient;
        IF NOT pk_activity_therapist.get_epis_pat_inactive(i_lang       => i_lang,
                                                           i_prof       => i_prof,
                                                           i_id_patient => i_id_patient,
                                                           o_epis_inact => o_epis_inact,
                                                           o_error      => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_epis_inact);
            pk_utils.undo_changes;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_EPIS_PAT_INACTIVE',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_epis_inact);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END get_epis_pat_inactive;

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
        l_internal_error EXCEPTION;
    BEGIN
        g_error := 'CALL pk_activity_therapist.get_epis_inactive';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_activity_therapist.get_epis_inactive(i_lang            => i_lang,
                                                       i_prof            => i_prof,
                                                       i_id_sys_btn_crit => i_id_sys_btn_crit,
                                                       i_crit_val        => i_crit_val,
                                                       i_dt              => i_dt,
                                                       o_msg             => o_msg,
                                                       o_msg_title       => o_msg_title,
                                                       o_button          => o_button,
                                                       o_epis_inact      => o_epis_inact,
                                                       o_mess_no_result  => o_mess_no_result,
                                                       o_flg_show        => o_flg_show,
                                                       o_error           => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_epis_inact);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_EPIS_INACTIVE',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_epis_inact);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END get_epis_inactive;

    /********************************************************************************************
    * Creates the activity therapy request and the corresponding episode.
    * It is used in the patient search area.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure 
    * @param i_episode        Episode identifier of the parent episode
    * @param i_patient        Patient identifier
    * @param o_opinion        created opinion identifier
    * @param o_opinion_hist   created opinion history identifier    
    * @param o_opinion        opinion identifier
    * @param o_opinion_prof   opinion prof identifier
    * @param o_episode        episode identifier
    * @param o_epis_encounter episode encounter dentifier  
    * @param o_requests       requests cursor
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
        i_episode        IN episode.id_episode%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        o_opinion        OUT opinion.id_opinion%TYPE,
        o_opinion_hist   OUT opinion_hist.id_opinion_hist%TYPE,
        o_opinion_prof   OUT opinion_prof.id_opinion_prof%TYPE,
        o_episode        OUT episode.id_episode%TYPE,
        o_epis_encounter OUT epis_encounter.id_epis_encounter%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
    BEGIN
        g_error := 'CALL pk_activity_therapist.set_request_and_episode';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_activity_therapist.set_request_and_episode(i_lang           => i_lang,
                                                             i_prof           => i_prof,
                                                             i_episode_origin => i_episode,
                                                             i_patient        => i_patient,
                                                             o_opinion        => o_opinion,
                                                             o_opinion_hist   => o_opinion_hist,
                                                             o_opinion_prof   => o_opinion_prof,
                                                             o_episode        => o_episode,
                                                             o_epis_encounter => o_epis_encounter,
                                                             o_error          => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_REQUEST_AND_EPISODE',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_request_and_episode;

    /**********************************************************************************************
    * Check if it is necessary to reopen the episode when recording loaned supplies, that is, check
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
        l_internal_error EXCEPTION;
    BEGIN
        g_error := 'CALL pk_activity_therapist.set_request_and_episode';
        pk_alertlog.log_debug(g_error);
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
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
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
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END check_epis_to_reopen;

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
    BEGIN
        g_error := 'CALL pk_discharge_amb.get_discharge_create';
        IF NOT pk_activity_therapist.get_discharge_create(i_lang    => i_lang,
                                                          i_prof    => i_prof,
                                                          i_episode => i_episode,
                                                          o_create  => o_create,
                                                          o_error   => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.reset_error_state;
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
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_discharge_create;

    /*
    * Get an episode's discharges list. Specify the discharge
    * identifier to retrieve the history of its changes.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_discharge      discharge identifier
    * @param o_discharge      discharges
    * @param o_discharge_prof discharges records info
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                 2.6.0.3
    * @since                  01-Jun-2010
    */
    FUNCTION get_discharge
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_discharge      IN discharge.id_discharge%TYPE,
        o_discharge      OUT pk_types.cursor_type,
        o_discharge_prof OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
    BEGIN
        g_error := 'CALL pk_discharge_amb.get_discharge';
        IF NOT pk_discharge_amb.get_discharge(i_lang           => i_lang,
                                              i_prof           => i_prof,
                                              i_episode        => i_episode,
                                              i_discharge      => i_discharge,
                                              i_show_cancelled => pk_alert_constant.g_yes,
                                              i_show_destiny   => pk_alert_constant.g_no,
                                              o_discharge      => o_discharge,
                                              o_discharge_prof => o_discharge_prof,
                                              o_error          => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_discharge);
            pk_types.open_my_cursor(o_discharge_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_DISCHARGE',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_discharge);
            pk_types.open_my_cursor(o_discharge_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_discharge;

    /*
    * Get discharge data for the create/edit screen.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_discharge      discharge identifier
    * @param o_discharge      discharge
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                 2.6.0.3
    * @since                  01-Jun-2010
    */
    FUNCTION get_discharge_edit
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_discharge IN discharge.id_discharge%TYPE,
        o_discharge OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
    BEGIN
        g_error := 'CALL pk_discharge_amb.get_discharge_edit';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_discharge_amb.get_discharge_edit(i_lang      => i_lang,
                                                   i_prof      => i_prof,
                                                   i_episode   => i_episode,
                                                   i_discharge => i_discharge,
                                                   o_discharge => o_discharge,
                                                   o_error     => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_discharge);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_DISCHARGE_EDIT',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_discharge);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_discharge_edit;

    /*
    * Get time units domains for discharge registration.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure    
    * @param o_time_unit      time units
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                 2.6.0.3
    * @since                  23-Jun-2010
    */
    FUNCTION get_discharge_domains
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_time_unit OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_paramedical_prof_core.get_followup_time_units';
        pk_alertlog.log_debug(g_error);
        pk_paramedical_prof_core.get_followup_time_units(i_prof => i_prof, o_time_units => o_time_unit);
    
        RETURN TRUE;
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_DISCHARGE_DOMAINS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_time_unit);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_discharge_domains;

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
        l_internal_error EXCEPTION;
    BEGIN
        g_error := 'CALL pk_activity_therapist.set_discharge';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_activity_therapist.set_discharge(i_lang             => i_lang,
                                                   i_prof             => i_prof,
                                                   i_prof_cat         => i_prof_cat,
                                                   i_discharge        => i_discharge,
                                                   i_episode          => i_episode,
                                                   i_dt_end           => i_dt_end,
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
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_DISCHARGE',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_discharge;

    /*
    * Cancels a discharge.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_discharge      discharge identifier
    * @param i_episode        episode identifier
    * @param i_cancel_reason  cancel reason identifier
    * @param i_cancel_notes   cancel notes
    * @param o_disch_hist     created discharge_hist identifier
    * @param o_disch_det_hist created discharge_detail_hist identifier
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                 2.6.0.3
    * @since                  06/Jul/2010
    */
    FUNCTION set_discharge_cancel
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_discharge      IN discharge.id_discharge%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes   IN discharge.notes_cancel%TYPE,
        o_disch_hist     OUT discharge_hist.id_discharge_hist%TYPE,
        o_disch_det_hist OUT discharge_detail_hist.id_discharge_detail_hist%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
    BEGIN
        g_error := 'CALL pk_social.set_discharge_cancel';
        IF NOT pk_paramedical_prof_core.set_discharge_cancel(i_lang           => i_lang,
                                                             i_prof           => i_prof,
                                                             i_discharge      => i_discharge,
                                                             i_episode        => i_episode,
                                                             i_cancel_reason  => i_cancel_reason,
                                                             i_cancel_notes   => i_cancel_notes,
                                                             o_disch_hist     => o_disch_hist,
                                                             o_disch_det_hist => o_disch_det_hist,
                                                             o_error          => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_DISCHARGE_CANCEL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_discharge_cancel;

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
        l_internal_error EXCEPTION;
    BEGIN
        g_error := 'CALL pk_activity_therapist.get_start_ther_pop_msgs';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_activity_therapist.get_start_ther_pop_msgs(i_lang      => i_lang,
                                                             i_prof      => i_prof,
                                                             o_msg_title => o_msg_title,
                                                             o_msg       => o_msg,
                                                             o_error     => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_START_THER_POP_MSGS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_start_ther_pop_msgs;

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
    * @since                  18-Jun-2010
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
    BEGIN
        g_error := 'GET discharge date';
        pk_alertlog.log_debug(g_package || g_error);
        IF NOT pk_activity_therapist.get_discharge_date(i_lang                => i_lang,
                                                        i_prof                => i_prof,
                                                        i_id_episode          => i_id_episode,
                                                        o_discharge_date_desc => o_discharge_date_desc,
                                                        o_discharge_hour_desc => o_discharge_hour_desc,
                                                        o_discharge_date      => o_discharge_date,
                                                        o_error               => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_START_THER_POP_MSGS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_discharge_date;

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
    FUNCTION get_at_summary_ehr
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
    BEGIN
        g_error := 'GET_SOCIAL_SUMMARY_EHR';
        IF NOT pk_activity_therapist.get_summary_ehr(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_id_pat        => i_id_pat,
                                                     i_episode       => i_episode,
                                                     i_scale         => i_scale,
                                                     o_screen_labels => o_screen_labels,
                                                     o_episodes_det  => o_episodes_det,
                                                     o_at_request    => o_at_request,
                                                     o_follow_up     => o_follow_up,
                                                     o_supplies      => o_supplies,
                                                     o_discharge     => o_discharge,
                                                     o_error         => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
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
                                              i_function => 'GET_AT_SUMMARY_EHR',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_at_summary_ehr;

    /********************************************************************************************
    * Get episode start date.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure       
    * @param i_id_episode            Activity Therapy episode identifier
    * @param o_date                  Episode start date    
    * @param o_error                 error
    *
    * @return                        false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                2.6.0.3
    * @since                  12-Oct-2010
    */
    FUNCTION get_epis_dt_creation
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_date       OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
        l_dt_creation_str VARCHAR2(200);
        l_dt_creation     episode.dt_begin_tstz%TYPE;
    BEGIN
        g_error := 'CALL pk_episode.get_epis_dt_creation with id_episode: ' || i_id_episode;
        pk_alertlog.log_debug(g_package || g_error);
        IF NOT pk_episode.get_epis_dt_creation(i_lang        => i_lang,
                                               i_prof        => i_prof,
                                               i_id_episode  => i_id_episode,
                                               o_dt_creation => l_dt_creation_str,
                                               o_error       => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'Convert VARCHAR2 dt_creation_str to TIMESTAMP WITH LOCAL TIME ZONE l_dt_creation';
        pk_alertlog.log_debug(g_error);
        l_dt_creation := pk_date_utils.get_string_tstz(i_lang, i_prof, l_dt_creation_str, NULL);
    
        g_error := 'CALL  pk_date_utils.date_send_tsz';
        pk_alertlog.log_debug(g_package || g_error);
        o_date := pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => l_dt_creation, i_prof => i_prof);
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_EPIS_DT_CREATION',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_epis_dt_creation;

BEGIN
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_activity_therapist_ux;
/
