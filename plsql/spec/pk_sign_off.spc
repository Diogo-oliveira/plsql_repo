/*-- Last Change Revision: $Rev: 1947597 $*/
/*-- Last Change by: $Author: cristina.oliveira $*/
/*-- Date of last change: $Date: 2020-04-29 10:02:28 +0100 (qua, 29 abr 2020) $*/

CREATE OR REPLACE PACKAGE pk_sign_off IS

    FUNCTION get_sign_off
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_cur        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    g_error VARCHAR2(2000);

    FUNCTION get_sign_off_professionals
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_cur        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_sign_off_details
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_cur        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_report_details
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_cur        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_sign_off
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_prof_co_sign IN professional.id_professional%TYPE,
        i_flg_value       IN VARCHAR2,
        i_note            IN VARCHAR2,
        i_flg_conf        IN VARCHAR2,
        o_cur             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_submitted_for_co_sign
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_cur   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_waiting_for_co_sign
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_cur   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pending_tasks
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_cur   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pending_lab_tasks
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_cur        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pending_exam_tasks
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_cur        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get the state of the Episode in terms of Sign Off
    *
    * @param          i_lang              language id    
    * @param          i_prof              professional type
    * @param          i_episode           episode id
    * @param          o_sign_off          Sign Off state: 
    *                                     Y if the episode is already signed off and N otherwise
    * @param          o_error             error message
    *
    * @return         boolean             true on success, otherwise false
    *
    * @author                             Orlando Antunes
    * @version                            2.5.1.2
    * @since                              2010/10/20       
    ********************************************************************************************/
    FUNCTION get_epis_sign_off_state
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        o_sign_off OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get the state of the Episode in terms of Sign Off (to be used in SQL)
    *
    * @param          i_lang              language id    
    * @param          i_prof              professional type
    * @param          i_episode           episode id
    *
    * @param          epis_sign_off_state Sign Off state: 
    *                                     Y if the episode is already signed off and N otherwise
    *
    * @author                             Orlando Antunes
    * @version                            2.5.1.2
    * @since                              2010/10/2       
    ********************************************************************************************/
    FUNCTION get_epis_sign_off_state
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Get the Sign Off checklist information
    *
    * @param          i_lang              language id    
    * @param          i_prof              professional type
    * @param          i_episode           episode id
    * @param          o_sign_off          Sign off data
    * @param          o_addendums_list    Addendums list
    * @param          o_error             error message
    *
    * @return         boolean             true on success, otherwise false
    *
    * @author                             Orlando Antunes
    * @version                            2.5.1.2
    * @since                              2010/10/19       
    ********************************************************************************************/
    FUNCTION get_sign_off_checklist
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_checklist OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get the list of Addemdums for a given episode. This function includes also information
    * about the Sign off of the episode, and when exists, the Sign off for each addendums
    *
    * @param          i_lang              language id    
    * @param          i_prof              professional type
    * @param          i_episode           episode id
    * @param          o_sign_off          Sign off data
    * @param          o_addendums_list    Addendums list
    * @param          o_error             error message
    *
    * @return         boolean             true on success, otherwise false
    *
    * @author                             Orlando Antunes
    * @version                            2.5.1.2
    * @since                              2010/10/19       
    ********************************************************************************************/
    FUNCTION get_addendums_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        o_sign_off       OUT pk_types.cursor_type,
        o_addendums_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get the list of Addemdums for a given episode.
    *
    * @param          i_lang              language id    
    * @param          i_prof              professional type
    * @param          i_episode           episode id
    * @param          o_addendums_list    Addendums list
    * @param          o_error             error message
    *
    * @return         boolean             true on success, otherwise false
    *
    * @author                             Orlando Antunes
    * @version                            2.5.1.2
    * @since                              2010/10/28       
    ********************************************************************************************/
    FUNCTION get_epis_addendums
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_addendums OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get the Sign Off details for a given episode.
    *
    * @param          i_lang              language id    
    * @param          i_prof              professional type
    * @param          i_episode           episode id
    * @param          o_sign_off          Sign off data
    * @param          o_error             error message
    *
    * @return         boolean             true on success, otherwise false
    *
    * @author                             Orlando Antunes
    * @version                            2.5.1.2
    * @since                              2010/10/28       
    ********************************************************************************************/
    FUNCTION get_epis_sign_off
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        o_sign_off OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Set new Addendum or updade an existing Addendum to register the Sign Off
    *
    * @param          i_lang              language id    
    * @param          i_prof              professional type
    * @param          i_episode           episode id
    * @param          i_epis_addendum     Addendum ID (Null when creating a new Addendum)
    * @param          i_epis_sign_off     Sign Off ID
    * @param          i_prof_sign_off     Professional that registers the Addendum's Sign Off
    * @param          i_addendum          Addendum text
    * @param          o_epis_addendum     New addendum ID
    * @param          o_error             error message
    *
    * @return         boolean             true on success, otherwise false
    *
    * @author                             Orlando Antunes
    * @version                            2.5.1.2
    * @since                              2010/10/19       
    ********************************************************************************************/
    FUNCTION set_addendum
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_epis_addendum IN epis_addendum.id_epis_addendum%TYPE,
        i_epis_sign_off IN epis_sign_off.id_epis_sign_off%TYPE,
        i_prof_sign_off IN epis_addendum.id_professional_sign_off%TYPE,
        i_addendum      IN epis_addendum.notes%TYPE,
        o_epis_addendum OUT epis_addendum.id_epis_addendum%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get the ID of the Episode Sign Off (epis_sign_off)
    *
    * @param          i_lang              language id    
    * @param          i_prof              professional type
    * @param          i_episode           episode id
    * @param          o_id_epis_sign_off  ID Episode Sign Off state
    * @param          o_error             error message
    *
    * @return         boolean             true on success, otherwise false
    *
    * @author                             Orlando Antunes
    * @version                            2.5.1.2
    * @since                              2010/10/25       
    ********************************************************************************************/
    FUNCTION get_epis_sign_off_id
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        o_id_epis_sign_off OUT epis_sign_off.id_epis_sign_off%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancel Addendums.
    *
    * @ param i_lang                    Preferred language ID for this professional
    * @ param i_prof                    Object (professional ID, institution ID, software ID)
    * @ param i_episode                 episode id
    * @ param i_epis_addendum           Addendum ID (Null when creating a new Addendum)
    * @ param i_notes                   Cancel notes
    * @ param i_cancel_reason           Cancel reason
    *
    * @ param o_error                   Error message
    *
    * @return                          true or false on success or error
    *
    * @author                           Orlando Antunes
    * @version                          0.1
    * @since                            2010/02/26
    **********************************************************************************************/
    FUNCTION set_cancel_addendum
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_epis_addendum IN epis_addendum.id_epis_addendum%TYPE,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes         IN epis_addendum.notes_cancel%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /**********************************************************************************************
    * get_GLOBAL_SHORTCUT_FILTER
    *
    * @param          i_lang              language id    
    * @param          i_prof              professional type
    * @param          i_episode           episode id
    *
    * @author                             Paulo Teixeira
    * @version                            2.6.5
    * @since                              2015/07/1      
    ********************************************************************************************/
    FUNCTION get_global_shortcut_filter
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /* Stores the package name. */
    g_package_name VARCHAR2(32);
    g_yes          VARCHAR2(1);
    g_no           VARCHAR2(1);

    g_eso_flg_state_cancel     epis_sign_off.flg_state%TYPE;
    g_eso_flg_state_sub_cosign epis_sign_off.flg_state%TYPE;
    g_eso_flg_state_co_sign    epis_sign_off.flg_state%TYPE;
    g_eso_flg_state_sign_off   epis_sign_off.flg_state%TYPE;

    g_eso_flg_event_socs  epis_sign_off.flg_event_type%TYPE;
    g_eso_flg_event_sc    epis_sign_off.flg_event_type%TYPE;
    g_eso_flg_event_cs    epis_sign_off.flg_event_type%TYPE;
    g_eso_flg_event_so    epis_sign_off.flg_event_type%TYPE;
    g_eso_flg_event_csocs epis_sign_off.flg_event_type%TYPE;
    g_eso_flg_event_csc   epis_sign_off.flg_event_type%TYPE;
    g_eso_flg_event_ccs   epis_sign_off.flg_event_type%TYPE;
    g_eso_flg_event_cso   epis_sign_off.flg_event_type%TYPE;

    g_i_flg_status_unresolved issue.flg_status%TYPE;
    g_im_flg_status_active    issue_message.flg_status%TYPE;
    g_im_flg_status_cancel    issue_message.flg_status%TYPE;

    g_ard_flg_status_f analysis_req_det.flg_status%TYPE;
    g_ard_flg_status_c analysis_req_det.flg_status%TYPE;
    g_ard_flg_th_e     analysis_req_det.flg_time_harvest%TYPE;

    g_erd_flg_status_f exam_req_det.flg_status%TYPE;
    g_erd_flg_status_c exam_req_det.flg_status%TYPE;
    g_er_flg_time_e    exam_req.flg_time%TYPE;

    g_e_flg_status_a episode.flg_status%TYPE;
    g_e_flg_status_p episode.flg_status%TYPE;

    g_assign_flg_active issue_prof_assigned.flg_status%TYPE;

    g_pend_issue_open CONSTANT pending_issue.flg_status%TYPE := 'O';
    g_pend_issue_g    CONSTANT pending_issue.flg_status%TYPE := 'G';

    g_ea_flg_status_a CONSTANT epis_addendum.flg_status%TYPE := 'A';
    g_ea_flg_status_c CONSTANT epis_addendum.flg_status%TYPE := 'C';
    g_ea_flg_status_s CONSTANT epis_addendum.flg_status%TYPE := 'S';

    g_sched_signoff_s CONSTANT schedule_outp.flg_state%TYPE := 'S';

    --SIGN OFF AREA SHORTCUTS
    g_so_addendum       CONSTANT sys_shortcut.id_sys_shortcut%TYPE := 610021;
    g_so_ss_lab         CONSTANT sys_shortcut.id_sys_shortcut%TYPE := 619117;
    g_so_ss_imag        CONSTANT sys_shortcut.id_sys_shortcut%TYPE := 619118;
    g_so_ss_exam        CONSTANT sys_shortcut.id_sys_shortcut%TYPE := 619119;
    g_so_ss_pend_issues CONSTANT sys_shortcut.id_sys_shortcut%TYPE := 619120;

END pk_sign_off;
/
