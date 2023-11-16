/*-- Last Change Revision: $Rev: 2027190 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:26 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_hand_off_ux IS

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    /**********************************************************************************************
    * Listing of all transfers of responsibility made about the patient (episode)
    *
    * @param   i_lang                 Language id
    * @param   i_prof                 Professional, software and institution ids
    * @param   i_episode              Episode id
    * @param   i_flg_type             Professional Category
    * @param   i_flg_hist             Get history responsability?
    * @param   o_resp_grid            Responsability grid
    * @param   o_transf_grid          Transfer requests grid
    * @param   o_error                Error message
    *
    * @value   i_flg_hist     {*} 'Y' Returns history responsability grid
    *                         {*} 'N' Returns current responsability grid
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    **********************************************************************************************/
    FUNCTION get_epis_prof_resp_all
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_flg_type    IN category.flg_type%TYPE,
        i_flg_hist    IN VARCHAR2,
        o_resp_grid   OUT pk_types.cursor_type,
        o_transf_grid OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_EPIS_PROF_RESP_ALL';
    BEGIN
        g_error := 'CALL TO PK_HAND_OFF_CORE.GET_EPIS_PROF_RESP_ALL';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT pk_hand_off_core.get_epis_prof_resp_all(i_lang        => i_lang,
                                                       i_prof        => i_prof,
                                                       i_episode     => i_episode,
                                                       i_flg_type    => i_flg_type,
                                                       i_flg_hist    => i_flg_hist,
                                                       o_resp_grid   => o_resp_grid,
                                                       o_transf_grid => o_transf_grid,
                                                       o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    END get_epis_prof_resp_all;

    /**
    * Gets responsability history
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identification and its context (institution and software)
    * @param   i_epis_prof_resp  Epis prof resp id
    * @param   o_resp_hist       Responsability history grid
    * @param   o_error           Error information
    *
    * @return                 TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_epis_prof_resp_hist
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        o_resp_hist      OUT pk_types.cursor_type,
        o_sbar_note      OUT CLOB,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_EPIS_PROF_RESP_HIST';
    BEGIN
        g_error := 'CALL TO PK_HAND_OFF_CORE.GET_EPIS_PROF_RESP_HIST';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT pk_hand_off_core.get_epis_prof_resp_hist(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_epis_prof_resp => i_epis_prof_resp,
                                                        o_resp_hist      => o_resp_hist,
                                                        o_sbar_note      => o_sbar_note,
                                                        o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    END get_epis_prof_resp_hist;

    FUNCTION check_prof_resp
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN epis_info.id_episode%TYPE,
        o_show_msg_box         OUT VARCHAR2,
        o_flg_hand_off_type    OUT VARCHAR2,
        o_responsibles         OUT pk_types.cursor_type,
        o_overall_resp_box     OUT pk_types.cursor_type,
        o_episode_resp_options OUT pk_types.cursor_type,
        o_labels_grid          OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'CHECK_PROF_RESP';
    BEGIN
        g_error := 'CALL TO PK_HAND_OFF_CORE.CHECK_PROF_RESP';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT pk_hand_off_core.check_prof_resp(i_lang                 => i_lang,
                                                i_prof                 => i_prof,
                                                i_id_episode           => i_id_episode,
                                                o_show_msg_box         => o_show_msg_box,
                                                o_flg_hand_off_type    => o_flg_hand_off_type,
                                                o_responsibles         => o_responsibles,
                                                o_overall_resp_box     => o_overall_resp_box,
                                                o_episode_resp_options => o_episode_resp_options,
                                                o_labels_grid          => o_labels_grid,
                                                o_error                => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    END check_prof_resp;

    /**
    * Gets the available tabs when selecting the overall responsible
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identification and its context (institution and software)
    * @param   i_episode         Episode id
    * @param   i_patient         Patient id
    * @param   o_tabs            Available tabs
    * @param   o_error           Error information
    *
    * @return                 TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_overall_resp_tabs
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        o_tabs    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_OVERALL_RESP_TABS';
    BEGIN
        g_error := 'CALL TO PK_HAND_OFF_CORE.GET_OVERALL_RESP_TABS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT pk_hand_off_core.get_overall_resp_tabs(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_episode => i_episode,
                                                      i_patient => i_patient,
                                                      o_tabs    => o_tabs,
                                                      o_error   => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    END get_overall_resp_tabs;

    /********************************************************************************************
    * Checks if the professional has permission to request a physician hand off.
    * Only applies to the CREATE button. The permission for other buttons (Ok/Cancel)
    * is returned in GET_EPIS_PROF_RESP_ALL.
    *
    * @param   I_LANG               Language associated to the professional executing the request
    * @param   I_PROF               Professional, institution and software ids
    * @param   i_episode            Episode ID
    * @param   i_flg_type           Categoria do profissional: S - Assistente social; D - Médico; N - Enfermeiro
    * @param   o_flg_create         Request permission: Y - yes, N - No
    * @param   o_create_actions     Options to display in the CREATE button
    * @param   o_error              Error message
    *                        
    * @return  true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          18-08-2009
    *
    * @alter                          José Brito
    * @version                        2.5.0.7
    * @since                          23-10-2009
    **********************************************************************************************/
    FUNCTION get_hand_off_req_permission
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_type       IN category.flg_type%TYPE,
        o_flg_create     OUT VARCHAR2,
        o_create_actions OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_hand_off.get_hand_off_req_permission(i_lang           => i_lang,
                                                       i_prof           => i_prof,
                                                       i_episode        => i_episode,
                                                       i_flg_type       => i_flg_type,
                                                       o_flg_create     => o_flg_create,
                                                       o_create_actions => o_create_actions,
                                                       o_error          => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package,
                                              'GET_HAND_OFF_REQ_PERMISSION',
                                              o_error);
            pk_types.open_my_cursor(o_create_actions);
            RETURN FALSE;
        
    END get_hand_off_req_permission;

    /********************************************************************************************
    * Returns the options to display in the hand-off internal button, 
    * for the ACTIONS/VIEWS buttons.
    *
    * This method is not intended to set permissions for each option. Insted this will be managed
    * by Flash according to the values of flags embedded in the cursors returned by GET_EPIS_PROF_RESP_ALL.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_flg_type                 Context of hand-off: physician or nurse hand-off
    * @param   o_id_epis_multi_prof_resp  New multiple hand-off record
    * @param   o_error                    Error message
    *                        
    * @return  TRUE. FALSE on error.
    * 
    * @author                         José Brito
    * @version                        2.6.0.4
    * @since                          18-10-2010
    **********************************************************************************************/
    FUNCTION get_hand_off_options
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_type IN epis_prof_resp.flg_type%TYPE,
        o_actions  OUT pk_types.cursor_type,
        o_views    OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'GET_HAND_OFF_REQ_PERMISSION';
    BEGIN
    
        RETURN pk_hand_off_core.get_hand_off_options(i_lang     => i_lang,
                                                     i_prof     => i_prof,
                                                     i_flg_type => i_flg_type,
                                                     o_actions  => o_actions,
                                                     o_views    => o_views,
                                                     o_error    => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_actions);
            pk_types.open_my_cursor(o_views);
            RETURN FALSE;
    END get_hand_off_options;

    /**********************************************************************************************
    * Current professional is taking EPISODE responsability over the patient.
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Professional data
    * @param i_prof_to                Destination professional ID   
    * @param i_id_episode             Destination Episode ID
    * @param i_notes                  Hand-off notes
    * @param i_prof_cat               Professional category: S - Social assistant; D - Physician; N - Nurse
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         José Brito
    * @version                        2.6.0.4
    * @since                          2010/10/21
    **********************************************************************************************/
    FUNCTION set_my_epis_responsability
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_to    IN professional.id_professional%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_notes      IN epis_prof_resp.notes_clob%TYPE,
        i_prof_cat   IN epis_prof_resp.flg_type%TYPE,
        o_flg_show   OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_msg_body   OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(200 CHAR) := 'SET_MY_EPIS_RESPONSABILITY';
        l_internal_error EXCEPTION;
    BEGIN
    
        g_error := 'CALL TO PK_HAND_OFF.CREATE_EPIS_PROF_RESP';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_hand_off.create_epis_prof_resp(i_lang       => i_lang,
                                                 i_prof       => i_prof,
                                                 i_prof_to    => table_varchar(i_prof_to),
                                                 i_tot_epis   => table_number(1),
                                                 i_epis_pat   => table_number(i_id_episode),
                                                 i_cs_or_dept => table_number(NULL),
                                                 i_notes      => table_varchar(i_notes),
                                                 i_flg_type   => i_prof_cat,
                                                 -- Called in grids
                                                 i_flg_resp    => 'G',
                                                 i_flg_profile => NULL,
                                                 i_sysdate     => NULL,
                                                 -- Not needed, will calculate the speciality of the current professional.
                                                 i_id_speciality => NULL,
                                                 i_sbar_note     => NULL,
                                                 o_flg_show      => o_flg_show,
                                                 o_msg_title     => o_msg_title,
                                                 o_msg_body      => o_msg_body,
                                                 o_error         => o_error)
        
        THEN
            RAISE l_internal_error;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_my_epis_responsability;

    /**********************************************************************************************
    * Creates a new request for EPISODE responsability (transfer responsability).
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Professional data
    * @param i_prof_to                Array of destination professionals
    * @param i_tot_epis               Array with total number of transferred episodes
    * @param i_epis_pat               Array with episode ID's
    * @param i_cs_or_dept             Array with destination clinical services/departments
    * @param i_notes                  Array with transfer notes
    * @param i_flg_type               Type of request: (D) Physician transfer (N) Nurse transfer
    * @param i_flg_profile            Type of profile (when applicable): (S)pecialist (R)esident (I)ntern (N)urse
    * @param i_id_speciality          Destination speciality ID (when applicable(
    * @param i_flg_assign_supervisor  Flag that indicates if this is a supervisor assignment
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         José Brito
    * @version                        2.6.0.4
    * @since                          2010/10/21
    **********************************************************************************************/
    FUNCTION set_req_epis_responsability
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_prof_to               IN table_varchar,
        i_tot_epis              IN table_number,
        i_epis_pat              IN table_number,
        i_cs_or_dept            IN table_number,
        i_notes                 IN table_varchar,
        i_flg_type              IN epis_prof_resp.flg_type%TYPE,
        i_flg_profile           IN profile_template.flg_profile%TYPE,
        i_id_speciality         IN epis_multi_prof_resp.id_speciality%TYPE,
        i_flg_assign_supervisor IN VARCHAR2 DEFAULT 'N',
        i_sbar_note             IN CLOB DEFAULT NULL,
        i_id_epis_pn            IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(200 CHAR) := 'SET_REQ_EPIS_RESPONSABILITY';
        l_internal_error EXCEPTION;
        l_flg_show  VARCHAR2(4000);
        l_msg_title VARCHAR2(4000);
        l_msg_body  VARCHAR2(4000);
    BEGIN
    
        g_error := 'CALL TO PK_HAND_OFF.CREATE_EPIS_PROF_RESP';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_hand_off.create_epis_prof_resp(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_prof_to    => i_prof_to,
                                            i_tot_epis   => i_tot_epis,
                                            i_epis_pat   => i_epis_pat,
                                            i_cs_or_dept => i_cs_or_dept,
                                            i_notes      => i_notes,
                                            i_flg_type   => i_flg_type,
                                            -- Request responsability in hand-off
                                            i_flg_resp              => CASE
                                                                           WHEN i_flg_assign_supervisor = pk_alert_constant.g_yes THEN
                                                                            'G'
                                                                           ELSE
                                                                            'H'
                                                                       END,
                                            i_flg_profile           => i_flg_profile,
                                            i_sysdate               => NULL,
                                            i_id_speciality         => i_id_speciality,
                                            i_flg_assign_supervisor => i_flg_assign_supervisor,
                                            i_sbar_note             => i_sbar_note,
                                            i_id_epis_pn            => i_id_epis_pn,
                                            o_flg_show              => l_flg_show,
                                            o_msg_title             => l_msg_title,
                                            o_msg_body              => l_msg_body,
                                            o_error                 => o_error)
        
        THEN
            RAISE l_internal_error;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              'ALERT',
                                              g_package,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_req_epis_responsability;

    /**********************************************************************************************
    * List all the specialities with an assigned specialist physician.
    * 
    * NOTE: Used only for OVERALL responsability. 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_profs                  cursor with types departament or clinical service
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                          José Brito
    * @version                        2.6.0.4 
    * @since                          2010/10/19
    **********************************************************************************************/
    FUNCTION get_handoff_dest_overall
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_profs OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name     VARCHAR2(200) := 'GET_HANDOFF_DEST_OVERALL';
        l_dests_header  sys_message.desc_message%TYPE;
        l_profs_header  sys_message.desc_message%TYPE;
        l_handoff_type  sys_config.value%TYPE;
        l_handoff_nurse sys_config.value%TYPE;
    BEGIN
        RETURN pk_hand_off_core.get_handoff_dest(i_lang => i_lang,
                                                 i_prof => i_prof,
                                                 -- Only applicable to physicians
                                                 i_flg_type => pk_alert_constant.g_cat_type_doc,
                                                 -- OVERALL responsability
                                                 i_flg_resp_type => pk_hand_off_core.g_resp_overall,
                                                 o_dests_header  => l_dests_header,
                                                 o_profs_header  => l_profs_header,
                                                 o_dests         => o_profs,
                                                 o_handoff_type  => l_handoff_type,
                                                 o_handoff_nurse => l_handoff_nurse,
                                                 o_error         => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_profs);
            RETURN FALSE;
    END get_handoff_dest_overall;

    /**********************************************************************************************
    * Lista serviços clinicos, ou departamentos, para filtrar profissionais para os quais o profissional 
      actual pode transferir a responsabilidade de pacientes seus.
    * 
    * NOTE: Used only for EPISODE responsability. 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_flg_type               tipo de transferência: D - médico, N - enfermeiro
    * @param o_dests_header           cabeçalho da coluna dos destinos
    * @param o_profs_header           cabeçalho da coluna dos profissionais
    * @param o_dests                  cursor with types departament or clinical service
    * @param o_handoff_type           type of hand-off configured in the institution
    * @param o_handoff_nurse          configuration for nurse hand-off (clinical service or department)
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         João Eiras
    * @version                        1.0 
    * @since                          2007/06/05
    *
    * @alter                          José Brito
    * @version                        2.6.0.4 
    * @since                          2010/10/19
    **********************************************************************************************/
    FUNCTION get_handoff_dest
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_flg_type      IN category.flg_type%TYPE,
        o_dests_header  OUT VARCHAR2,
        o_profs_header  OUT VARCHAR2,
        o_dests         OUT pk_types.cursor_type,
        o_handoff_type  OUT sys_config.value%TYPE,
        o_handoff_nurse OUT sys_config.value%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(200) := 'GET_HANDOFF_DEST';
    BEGIN
    
        RETURN pk_hand_off_core.get_handoff_dest(i_lang     => i_lang,
                                                 i_prof     => i_prof,
                                                 i_flg_type => i_flg_type,
                                                 -- EPISODE responsability
                                                 i_flg_resp_type => pk_hand_off_core.g_resp_episode,
                                                 o_dests_header  => o_dests_header,
                                                 o_profs_header  => o_profs_header,
                                                 o_dests         => o_dests,
                                                 o_handoff_type  => o_handoff_type,
                                                 o_handoff_nurse => o_handoff_nurse,
                                                 o_error         => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_dests);
            RETURN FALSE;
    END get_handoff_dest;

    /**********************************************************************************************
    * Get the profile types (Specialist, Resident, Intern, Nurse, etc.)
    * to which the professional can make a hand-off request.
    *
    * NOTE: Used only for EPISODE responsability. 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             episode ID
    * @param i_flg_type               type of category (D) Physician (N) Nurse
    * @param o_profiles               list of profile types
    * @param o_error                  error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Brito
    * @version                        2.5.0.7
    * @since                          2009/10/07
    **********************************************************************************************/
    FUNCTION get_handoff_dest_profiles
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_flg_type   IN category.flg_type%TYPE,
        o_profiles   OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'GET_HANDOFF_DEST_PROFILES';
    BEGIN
    
        RETURN pk_hand_off_core.get_handoff_dest_profiles(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_id_episode => i_id_episode,
                                                          i_flg_type   => i_flg_type,
                                                          o_profiles   => o_profiles,
                                                          o_error      => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_profiles);
            RETURN FALSE;
    END get_handoff_dest_profiles;

    /**********************************************************************************************
    * Get the destination professionals for the current responsability transfer, filtered
    * according to the destination clinical service/department/speciality.
    *
    * Used for EPISODE responsability.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional, software and institution ids
    * @param i_dest                   ID of the destination clinical service/department/speciality
    * @param i_episode                Episode ID
    * @param i_flg_type               Type of category (D) Physician (N) Nurse
    * @param i_handoff_type           Type of hand-off: (N) Normal (M) Multiple
    * @param i_handoff_nurse          Configuration for nurse hand-off (clinical service or department)
    * @param i_flg_profile            Type of profile (specialist, resident, intern, nurse)
    * @param i_flg_assign_supervisor  Flag that indicates if this is a supervisor assignment
    * @param o_profs                  List of professionals
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Brito
    * @version                        2.5.0.7
    * @since                          2009/10/07
    *
    * @alter                          José Brito
    * @version                        2.6.0.4
    * @since                          2010/10/22
    **********************************************************************************************/
    FUNCTION get_handoff_dest_profs
    (
        i_lang                  IN NUMBER,
        i_prof                  IN profissional,
        i_dest                  IN dep_clin_serv.id_clinical_service%TYPE,
        i_episode               IN episode.id_episode%TYPE,
        i_flg_type              IN category.flg_type%TYPE,
        i_handoff_type          IN VARCHAR2,
        i_handoff_nurse         IN VARCHAR2,
        i_flg_profile           IN profile_template.flg_profile%TYPE,
        i_flg_assign_supervisor IN VARCHAR2 DEFAULT 'N',
        o_profs                 OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(200) := 'GET_HANDOFF_DEST_PROFS';
    BEGIN
    
        RETURN pk_hand_off_core.get_handoff_dest_profs(i_lang                  => i_lang,
                                                       i_prof                  => i_prof,
                                                       i_dest                  => i_dest,
                                                       i_episode               => i_episode,
                                                       i_flg_type              => i_flg_type,
                                                       i_handoff_type          => i_handoff_type,
                                                       i_handoff_nurse         => i_handoff_nurse,
                                                       i_flg_profile           => i_flg_profile,
                                                       i_flg_resp_type         => pk_hand_off_core.g_resp_episode,
                                                       i_flg_assign_supervisor => i_flg_assign_supervisor,
                                                       o_profs                 => o_profs,
                                                       o_error                 => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_profs);
            RETURN FALSE;
    END get_handoff_dest_profs;

    /**********************************************************************************************
    * Get the destination specialist physicians for the current responsability transfer.
    * Used for OVERALL responsability.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional, software and institution ids
    * @param i_dest                   ID of the destination clinical service/department/speciality
    * @param i_episode                Episode ID
    * @param o_profs                  List of professionals
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Brito
    * @version                        2.5.0.7
    * @since                          2009/10/07
    *
    * @alter                          José Brito
    * @version                        2.6.0.4
    * @since                          2010/10/22
    **********************************************************************************************/
    FUNCTION get_handoff_dest_ov_profs
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_dest    IN dep_clin_serv.id_clinical_service%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_profs   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(200) := 'GET_HANDOFF_DEST_OV_PROFS';
    BEGIN
    
        RETURN pk_hand_off_core.get_handoff_dest_profs(i_lang    => i_lang,
                                                       i_prof    => i_prof,
                                                       i_dest    => i_dest,
                                                       i_episode => i_episode,
                                                       -- Overall responsability is always destined to physicians
                                                       i_flg_type      => pk_alert_constant.g_cat_type_doc,
                                                       i_handoff_type  => NULL,
                                                       i_handoff_nurse => NULL,
                                                       i_flg_profile   => pk_hand_off_core.g_specialist,
                                                       i_flg_resp_type => pk_hand_off_core.g_resp_overall,
                                                       o_profs         => o_profs,
                                                       o_error         => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_profs);
            RETURN FALSE;
    END get_handoff_dest_ov_profs;

    /**********************************************************************************************
    * Returns all data relative to on-call physicians to display in the overall 
    * responsability transfer screen.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional, software and institution ids
    * @param i_id_episode             Episode ID
    * @param o_profs                  List of on-call physicians
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Brito
    * @version                        2.6.0.4
    * @since                          2010/10/22
    **********************************************************************************************/
    FUNCTION get_handoff_oncall_profs_data
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_profs      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'GET_HANDOFF_DBC_PROFS';
    BEGIN
        RETURN pk_hand_off_core.get_handoff_oncall_profs_data(i_lang       => i_lang,
                                                              i_prof       => i_prof,
                                                              i_id_episode => i_id_episode,
                                                              o_profs      => o_profs,
                                                              o_error      => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_profs);
            RETURN FALSE;
    END get_handoff_oncall_profs_data;

    /********************************************************************************************
    * Creates overall responsability over an episode.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_id_prof_resp             Responsible professional
    * @param   i_flg_profile              Responsible professional type of profile
    * @param   i_id_speciality            Responsible professional speciality ID
    * @param   i_notes                    Responsability record notes
    * @param   o_flg_show                 Show warning message (Y) Yes (N) No
    * @param   o_msg_title                Warning message title
    * @param   o_msg_body                 Warning message body
    * @param   o_id_epis_prof_resp        Responsability record ID
    * @param   o_id_epis_multi_prof_resp  Multiple responsability record ID
    * @param   o_error                    Error message
    *                        
    * @return  TRUE if successfull / FALSE otherwise
    * 
    * @author                         José Brito
    * @version                        2.6.0.4
    * @since                          07-10-2010
    **********************************************************************************************/
    FUNCTION set_overall_resp
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_episode              IN episode.id_episode%TYPE,
        i_id_prof_resp            IN epis_multi_prof_resp.id_professional%TYPE,
        i_id_speciality           IN epis_multi_prof_resp.id_speciality%TYPE,
        i_notes                   IN epis_prof_resp.notes_clob%TYPE,
        o_flg_show                OUT VARCHAR2,
        o_msg_title               OUT VARCHAR2,
        o_msg_body                OUT VARCHAR2,
        o_id_epis_prof_resp       OUT epis_prof_resp.id_epis_prof_resp%TYPE,
        o_id_epis_multi_prof_resp OUT epis_multi_prof_resp.id_epis_multi_prof_resp%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'SET_OVERALL_RESP';
        l_internal_error EXCEPTION;
    BEGIN
    
        g_error := 'CALL TO CALL_SET_OVERALL_RESP_1 ';
        IF NOT pk_hand_off_core.call_set_overall_resp(i_lang                    => i_lang,
                                                      i_prof                    => i_prof,
                                                      i_id_episode              => i_id_episode,
                                                      i_id_prof_resp            => i_id_prof_resp,
                                                      i_id_speciality           => i_id_speciality,
                                                      i_notes                   => i_notes,
                                                      i_flg_epis_respons        => pk_alert_constant.g_no,
                                                      o_flg_show                => o_flg_show,
                                                      o_msg_title               => o_msg_title,
                                                      o_msg_body                => o_msg_body,
                                                      o_id_epis_prof_resp       => o_id_epis_prof_resp,
                                                      o_id_epis_multi_prof_resp => o_id_epis_multi_prof_resp,
                                                      o_error                   => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              'ALERT',
                                              g_package,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_overall_resp;

    /********************************************************************************************
    * Terminate responsability over an episode.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_epis_prof_resp        Responsability transfer request ID
    * @param   i_flg_type                 Type of hand-off: Physician / Nurse
    * @param   o_flg_show                 Show warning message? Y/N
    * @param   o_msg_title                Warning message title
    * @param   o_msg_body                 Warning message text
    * @param   o_error                    Error message
    *                        
    * @return  TRUE/FALSE
    * 
    * @author                         José Brito
    * @version                        2.6.0.4
    * @since                          11-10-2010
    **********************************************************************************************/
    FUNCTION set_terminate_resp
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_flg_type          IN epis_prof_resp.flg_type%TYPE,
        o_flg_show          OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_msg_body          OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'SET_TERMINATE_RESP';
        l_internal_error EXCEPTION;
    BEGIN
    
        IF NOT pk_hand_off_core.call_set_terminate_resp(i_lang              => i_lang,
                                                        i_prof              => i_prof,
                                                        i_id_epis_prof_resp => i_id_epis_prof_resp,
                                                        i_flg_type          => i_flg_type,
                                                        o_flg_show          => o_flg_show,
                                                        o_msg_title         => o_msg_title,
                                                        o_msg_body          => o_msg_body,
                                                        o_error             => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              'ALERT',
                                              g_package,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_terminate_resp;

    /********************************************************************************************
    * Set main overall responsability for a patient.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_id_new_resp              New main overall responsible ID
    * @param   i_id_epis_prof_resp        Hand-off request ID
    * @param   o_flg_show                 Show warning message? Y/N
    * @param   o_msg_title                Warning message title
    * @param   o_msg_body                 Warning message text
    * @param   o_error                    Error message
    *                        
    * @return  TRUE/FALSE
    * 
    * @author                         José Brito
    * @version                        2.6.0.4
    * @since                          11-10-2010
    **********************************************************************************************/
    FUNCTION set_main_resp
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_id_new_resp       IN professional.id_professional%TYPE,
        i_id_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        o_flg_show          OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_msg_body          OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'SET_MAIN_RESP';
        l_internal_error EXCEPTION;
    BEGIN
    
        IF NOT pk_hand_off_core.call_set_main_resp(i_lang              => i_lang,
                                                   i_prof              => i_prof,
                                                   i_id_episode        => i_id_episode,
                                                   i_id_new_resp       => i_id_new_resp,
                                                   i_id_epis_prof_resp => i_id_epis_prof_resp,
                                                   o_flg_show          => o_flg_show,
                                                   o_msg_title         => o_msg_title,
                                                   o_msg_body          => o_msg_body,
                                                   o_error             => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              'ALERT',
                                              g_package,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_main_resp;

    /********************************************************************************************
    * Cancel a responsability request.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_epis_prof_resp           Record ID
    * @param   i_flg_type                 Type of transfer: (D) Physician (N) Nurse
    * @param   i_notes                    Cancellation notes
    * @param   i_id_cancel_reason         Cancel reason ID
    * @param   o_error                    Error message
    *                        
    * @return  TRUE/FALSE
    * 
    * @author                         José Brito
    * @version                        2.6.0.4
    * @since                          04-11-2010
    **********************************************************************************************/
    FUNCTION cancel_request_resp
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_prof_resp   IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_flg_type         IN epis_prof_resp.flg_type%TYPE,
        i_notes            IN epis_prof_resp.notes_cancel%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'CANCEL_REQUEST_RESP';
        l_internal_error EXCEPTION;
    BEGIN
    
        g_error := 'CALL_CANCEL_REQUEST_RESP';
        IF NOT pk_hand_off.call_cancel_request_resp(i_lang             => i_lang,
                                                    i_prof             => i_prof,
                                                    i_epis_prof_resp   => i_epis_prof_resp,
                                                    i_flg_type         => i_flg_type,
                                                    i_notes            => i_notes,
                                                    i_id_cancel_reason => i_id_cancel_reason,
                                                    o_error            => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              'ALERT',
                                              g_package,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_request_resp;

    /**********************************************************************************************
    * Change the status of the hand-off requests (CANCEL, ACCEPT or REJECT).
    * Function called by the Flash layer.
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_tot_epis               Array com o número total de episódios de transferência de responsabilidade,que o profissional vai aceitar, cancelar ou rejeitar
    * @param i_epis_prof_resp         Array com os IDs dos episódios de transferência de responsabilidade
    * @param i_flg_status             Status da Transferência de responsabilidade:  C - Cancelado;
                                                                                    F- Final;
                                                                                    D- Rejeitado        
    * @param i_flg_type               Categoria do profissional: S - Assistente social; D - Médico; N - Enfermeiro
    * @param i_notes                  Notes
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/08/11
    *
    * @alter                          José Brito
    * @version                        2.5.0.7 
    * @since                          2009/10/29
    **********************************************************************************************/
    FUNCTION set_epis_prof_resp
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_tot_epis       IN table_number,
        i_epis_prof_resp IN table_varchar,
        i_flg_status     IN epis_prof_resp.flg_status%TYPE,
        i_flg_type       IN epis_prof_resp.flg_type%TYPE,
        i_notes          IN epis_prof_resp.notes_cancel%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'SET_EPIS_PROF_RESP';
        l_internal_error EXCEPTION;
    BEGIN
        IF NOT pk_hand_off.set_epis_prof_resp(i_lang           => i_lang,
                                              i_prof           => i_prof,
                                              i_tot_epis       => i_tot_epis,
                                              i_epis_prof_resp => i_epis_prof_resp,
                                              i_flg_status     => i_flg_status,
                                              i_flg_type       => i_flg_type,
                                              i_notes          => i_notes,
                                              o_error          => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              'ALERT',
                                              g_package,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_epis_prof_resp;

    /**
    * Get patient previous responsibles
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional, software and institution ids
    * @param i_episode                Episode id
    * @param o_profs                  List of on-call physicians ID's
    * @param o_error                  Error message
    *
    * @return                 TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_previous_responsibles
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_profs   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_PREVIOUS_RESPONSIBLES';
    BEGIN
        g_error := 'CALL TO PK_HAND_OFF_CORE.GET_PREVIOUS_RESPONSIBLES';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT pk_hand_off_core.get_previous_responsibles(i_lang    => i_lang,
                                                          i_prof    => i_prof,
                                                          i_episode => i_episode,
                                                          o_profs   => o_profs,
                                                          o_error   => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    END get_previous_responsibles;

    /**
    * Get hand off configuration vars
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional, software and institution ids
    * @param i_flg_type               Transf. type
    * @param o_label                  Speciality or Clinical Service or Department
    * @param o_handoff_type           Hand off type
    * @param o_error                  Error message
    *
    * @value   i_flg_type     {*} 'D' Physician
    *                         {*} 'N' Nurse
    *
    * @value   o_handoff_type {*} 'N' Normal
    *                         {*} 'M' Multiple
    *
    * @return                 TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_hand_off_vars
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_flg_type     IN category.flg_type%TYPE,
        o_label        OUT sys_message.code_message%TYPE,
        o_handoff_type OUT sys_config.value%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_HAND_OFF_VARS';
    BEGIN
        g_error := 'CALL TO PK_HAND_OFF_CORE.GET_HAND_OFF_VARS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        RETURN pk_hand_off_core.get_hand_off_vars(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_flg_type     => i_flg_type,
                                                  o_label        => o_label,
                                                  o_handoff_type => o_handoff_type,
                                                  o_error        => o_error);
    END get_hand_off_vars;

    /**********************************************************************************************
    * Gets the information of the given episode
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    * @param i_flg_type               type of hand-off: (D) Physician (N) Nurse
    * @param o_patient                All patients list
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        2.6.0.3.4 
    * @since                          2010/11/26
    **********************************************************************************************/
    FUNCTION get_grid_hand_off_cab
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_flg_type IN VARCHAR2 DEFAULT NULL,
        o_patient  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_GRID_HAND_OFF_CAB';
    BEGIN
        g_error := 'CALL TO PK_HAND_OFF.GET_GRID_HAND_OFF_CAB';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        RETURN pk_hand_off.get_grid_hand_off_cab(i_lang     => i_lang,
                                                 i_prof     => i_prof,
                                                 i_episode  => i_episode,
                                                 i_flg_type => i_flg_type,
                                                 --This function is only called when a new request of responsability is made
                                                 i_flg_show_only_resp => pk_alert_constant.g_no,
                                                 o_patient            => o_patient,
                                                 o_error              => o_error);
    END get_grid_hand_off_cab;

    /********************************************************************************************
    * Cancel a responsability.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_epis_prof_resp           Record ID
    * @param   i_flg_type                 Type of transfer: (D) Physician (N) Nurse
    * @param   i_notes                    Cancellation notes
    * @param   i_id_cancel_reason         Cancel reason ID
    * @param   o_error                    Error message
    *                        
    * @return  TRUE/FALSE
    * 
    * @author                         Alexandre Santos
    * @version                        2.6.1
    * @since                          07-06-2011
    **********************************************************************************************/
    FUNCTION cancel_responsability
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_prof_resp   IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_flg_type         IN epis_prof_resp.flg_type%TYPE,
        i_notes            IN epis_prof_resp.notes_cancel%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'CANCEL_RESPONSABILITY';
    BEGIN
        g_error := 'CALL TO PK_HAND_OFF_CORE.CANCEL_RESPONSABILITY';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        RETURN pk_hand_off_core.cancel_responsability(i_lang             => i_lang,
                                                      i_prof             => i_prof,
                                                      i_epis_prof_resp   => i_epis_prof_resp,
                                                      i_flg_type         => i_flg_type,
                                                      i_notes            => i_notes,
                                                      i_id_cancel_reason => i_id_cancel_reason,
                                                      o_error            => o_error);
    END cancel_responsability;

    /********************************************************************************************
    * Creates overall responsability over an episode.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_id_prof_resp             Responsible professional
    * @param   i_id_speciality            Responsible professional speciality ID
    * @param   i_notes                    Responsability record notes
    * @param   i_flg_epis_respons         Flag that indicates if the professional also takes episode responsability 
    * @param   o_flg_show                 Show warning message (Y) Yes (N) No
    * @param   o_msg_title                Warning message title
    * @param   o_msg_body                 Warning message body
    * @param   o_id_epis_prof_resp        Responsability record ID
    * @param   o_id_epis_multi_prof_resp  Multiple responsability record ID
    * @param   o_error                    Error message
    *                        
    * @return  TRUE if successfull / FALSE otherwise
    * 
    * @author                         Sergio Dias
    * @version                        2.6.1.10.1
    * @since                          27-Set-2012
    **********************************************************************************************/
    FUNCTION set_overall_resp
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_episode              IN episode.id_episode%TYPE,
        i_id_prof_resp            IN epis_multi_prof_resp.id_professional%TYPE,
        i_id_speciality           IN epis_multi_prof_resp.id_speciality%TYPE,
        i_notes                   IN epis_prof_resp.notes_clob%TYPE,
        i_flg_epis_response        IN VARCHAR2,
        o_flg_show                OUT VARCHAR2,
        o_msg_title               OUT VARCHAR2,
        o_msg_body                OUT VARCHAR2,
        o_id_epis_prof_resp       OUT epis_prof_resp.id_epis_prof_resp%TYPE,
        o_id_epis_multi_prof_resp OUT epis_multi_prof_resp.id_epis_multi_prof_resp%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'SET_OVERALL_RESP';
        l_internal_error EXCEPTION;
    BEGIN
    
        g_error := 'CALL TO CALL_SET_OVERALL_RESP_2' ;
        IF NOT pk_hand_off_core.call_set_overall_resp(i_lang                    => i_lang,
                                                      i_prof                    => i_prof,
                                                      i_id_episode              => i_id_episode,
                                                      i_id_prof_resp            => i_id_prof_resp,
                                                      i_id_speciality           => i_id_speciality,
                                                      i_notes                   => i_notes,
                                                      i_flg_epis_respons        => i_flg_epis_response,
                                                      o_flg_show                => o_flg_show,
                                                      o_msg_title               => o_msg_title,
                                                      o_msg_body                => o_msg_body,
                                                      o_id_epis_prof_resp       => o_id_epis_prof_resp,
                                                      o_id_epis_multi_prof_resp => o_id_epis_multi_prof_resp,
                                                      o_error                   => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              'ALERT',
                                              g_package,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_overall_resp;

    /********************************************************************************************
    * THIS FUNCTION IS ONLY TO BE USED BY REPORTS TEAM
    * HAS THE SAME LOGIC OF HEADER FUNCTION PK_HEA_PRV_EPIS.GET_EPIS_RESPONSIBLES
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_id_patient               Patient ID
    * @param   o_resp_doctor              Episode responsible physician
    * @param   o_first_nurse_resp         Episode first nurse responsible
    *                        
    * @return  Array with the responsible professionals ID
    * 
    * @author                         Alexandre Santos
    * @version                        2.6
    * @since                          01-Fev-2013
    **********************************************************************************************/
    FUNCTION get_resp_doctor_nurse
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_patient       IN patient.id_patient%TYPE,
        o_resp_doctor      OUT professional.id_professional%TYPE,
        o_first_nurse_resp OUT professional.id_professional%TYPE
    ) RETURN BOOLEAN IS
        l_prof_cat category.flg_type%TYPE;
    BEGIN
        RETURN pk_hand_off_core.get_resp_doctor_nurse(i_lang             => i_lang,
                                                      i_prof             => i_prof,
                                                      i_id_episode       => i_id_episode,
                                                      i_id_patient       => i_id_patient,
                                                      o_resp_doctor      => o_resp_doctor,
                                                      o_first_nurse_resp => o_first_nurse_resp);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END get_resp_doctor_nurse;

    /********************************************************************************************
    * THIS FUNCTION IS ONLY TO BE USED BY REPORTS TEAM
    * HAS THE SAME LOGIC OF HEADER FUNCTION PK_HEA_PRV_EPIS.GET_EPIS_RESPONSIBLES
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_id_patient               Patient ID
    * @param   o_resp_doctor              Episode responsible physician
    * @param   o_resp_doctor_spec         Responsible physician speciality
    * @param   o_resp_nurse               Episode responsible nurse
    * @param   o_error                    Error message
    *                        
    * @return  Array with the responsible professionals ID
    * 
    * @author                         Alexandre Santos
    * @version                        2.6
    * @since                          01-Fev-2013
    **********************************************************************************************/
    FUNCTION get_epis_responsibles
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_patient       IN patient.id_patient%TYPE,
        o_resp_doctor      OUT VARCHAR,
        o_resp_doctor_spec OUT VARCHAR,
        o_resp_nurse       OUT VARCHAR,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_hand_off_core.get_epis_responsibles(i_lang             => i_lang,
                                                      i_prof             => i_prof,
                                                      i_id_episode       => i_id_episode,
                                                      i_id_patient       => i_id_patient,
                                                      o_resp_doctor      => o_resp_doctor,
                                                      o_resp_doctor_spec => o_resp_doctor_spec,
                                                      o_resp_nurse       => o_resp_nurse,
                                                      o_error            => o_error);
    END get_epis_responsibles;

    /**********************************************************************************************
    * THIS FUNCTION IS ONLY TO BE USED BY REPORTS TEAM
    * HAS THE SAME LOGIC OF FUNCTION GET_EPIS_PROF_RESP_ALL BUT ALSO CHECKS IN EPIS_INFO FOR OUTP
    * Listing of all transfers of responsibility made about the patient (episode)
    *
    * @param   i_lang                 Language id
    * @param   i_prof                 Professional, software and institution ids
    * @param   i_episode              Episode id
    * @param   i_flg_type             Professional Category
    * @param   i_flg_hist             Get history responsability?
    * @param   o_resp_grid            Responsability grid
    * @param   o_transf_grid          Transfer requests grid
    * @param   o_error                Error message
    *
    * @value   i_flg_hist     {*} 'Y' Returns history responsability grid
    *                         {*} 'N' Returns current responsability grid
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author  Sergio Dias
    * @version v2.6.3.8.3
    * @since   17-Oct-2013
    **********************************************************************************************/
    FUNCTION get_responsibles
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_flg_type    IN category.flg_type%TYPE,
        i_flg_hist    IN VARCHAR2,
        o_resp_grid   OUT pk_types.cursor_type,
        o_transf_grid OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_EPIS_RESPONSIBLES';
    BEGIN
        g_error := 'CALL TO PK_HAND_OFF_CORE.GET_RESPONSIBLES';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        RETURN pk_hand_off_core.get_responsibles(i_lang        => i_lang,
                                                 i_prof        => i_prof,
                                                 i_episode     => i_episode,
                                                 i_flg_type    => i_flg_type,
                                                 i_flg_hist    => i_flg_hist,
                                                 o_resp_grid   => o_resp_grid,
                                                 o_transf_grid => o_transf_grid,
                                                 o_error       => o_error);
    END get_responsibles;

    /********************************************************************************************
    * Gets the list of professional responsible for admission (doctors)
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional information data
    * @param   i_episode                  Episode identifier
    * @param   o_prof_resp                List od professional responsible for episode                   
    * @return  true/faslse
    * 
    * @author                         Elisabete Bugalho            
    * @version                        2.7.1.0
    * @since                          28/04/2017
    **********************************************************************************************/
    FUNCTION get_epis_prof_resp_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_prof_resp OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_EPIS_PROF_RESP_LIST';
    BEGIN
        g_error := 'CALL TO PK_HAND_OFF_CORE.GET_EPIS_PROF_RESP_LIST';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        RETURN pk_hand_off_core.get_epis_prof_resp_list(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_episode   => i_episode,
                                                        o_prof_resp => o_prof_resp,
                                                        o_error     => o_error);
    END get_epis_prof_resp_list;

BEGIN
    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_hand_off_ux;
/
