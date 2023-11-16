/*-- Last Change Revision: $Rev: 2027184 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:25 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_hand_off_api IS

    -- Private variable declarations
    g_one CONSTANT PLS_INTEGER := 1;

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    /**
    * Get responsability icons
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_episode      Episode id
    * @param   i_handoff_type Hand-off type
    *
    * @value   i_handoff_type {*} 'N' Normal
    *                         {*} 'M' Multiple
    *
    * @return                 Array with the responsability icons
    *
    * @raises                 g_resp_type_exception Error when getting responsability type for the episode/i_prof
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_resp_icons
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_handoff_type IN sys_config.value%TYPE
    ) RETURN table_varchar IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_RESP_ICONS';
    BEGIN
        g_error := 'CALL TO PK_HAND_OFF_CORE.GET_RESP_ICONS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        RETURN pk_hand_off_core.get_resp_icons(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_episode      => i_episode,
                                               i_handoff_type => i_handoff_type);
    END get_resp_icons;

    FUNCTION get_resp_icon
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_RESP_ICON';
        l_resp          table_varchar;
        l_hand_off_type VARCHAR2(2 CHAR);
    BEGIN
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
        g_error         := 'CALL TO PK_HAND_OFF_CORE.GET_RESP_ICONS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_resp := pk_hand_off_core.get_resp_icons(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_episode      => i_episode,
                                                  i_handoff_type => l_hand_off_type);
        IF l_resp.exists(1)
        THEN
            RETURN l_resp(1);
        ELSE
            RETURN NULL;
        END IF;
    END get_resp_icon;
    /**
    * Checks if current episode has and needs a overall responsible
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identification and its context (institution and software)
    * @param   i_episode         Episode id
    * @param   o_flg_show_error  Is or isn't to show error message
    * @param   o_error_title     Error title
    * @param   o_error_message   Error message
    * @param   o_error           Error information
    *
    * @value   o_flg_show_error  {*} 'Y' Yes
    *                            {*} 'N' No
    *
    * @return                 TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION check_overall_responsible
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        o_flg_show_error OUT VARCHAR2,
        o_error_title    OUT sys_message.desc_message%TYPE,
        o_error_message  OUT sys_message.desc_message%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'CHECK_OVERALL_RESPONSIBLE';
    BEGIN
        g_error := 'CALL TO PK_HAND_OFF_CORE.CHECK_OVERALL_RESPONSIBLE';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT pk_hand_off_core.check_overall_responsible(i_lang           => i_lang,
                                                          i_prof           => i_prof,
                                                          i_episode        => i_episode,
                                                          o_flg_show_error => o_flg_show_error,
                                                          o_error_title    => o_error_title,
                                                          o_error_message  => o_error_message,
                                                          o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    END check_overall_responsible;

    /********************************************************************************************
    * Returns an array with the responsible professionals for the episode, for a given category.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_prof_cat                 Professional category    
    * @param   i_hand_off_type            Type of hand-off (N) Normal (M) Multiple
    *                        
    * @return  Array with the responsible professionals ID
    * 
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2009
    **********************************************************************************************/
    FUNCTION get_responsibles_id
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_prof_cat      IN category.flg_type%TYPE,
        i_hand_off_type IN sys_config.value%TYPE,
        i_my_patients   IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN table_number IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_RESPONSIBLES_ID';
    BEGIN
        -- g_error := 'CALL TO PK_HAND_OFF_CORE.GET_RESPONSIBLES_ID';
        -- alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        RETURN pk_hand_off_core.get_responsibles_id(i_lang          => i_lang,
                                                    i_prof          => i_prof,
                                                    i_id_episode    => i_id_episode,
                                                    i_prof_cat      => i_prof_cat,
                                                    i_hand_off_type => i_hand_off_type,
                                                    i_my_patients   => i_my_patients);
    END get_responsibles_id;

    /**
    * Get all episodes where i_profs are responsible (Used on search criteria)
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identification and its context (institution and software)
    * @param   i_prof_cat        Professional category    
    * @param   i_hand_off_type   Type of hand-off (N) Normal (M) Multiple
    * @param   i_profs           Array with id_prof's
    *
    * @return                 Array with id_episode's
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_prof_episodes
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat      IN category.flg_type%TYPE,
        i_hand_off_type IN sys_config.value%TYPE,
        i_profs         IN table_number
    ) RETURN table_number IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_PROF_EPISODES';
    BEGIN
        g_error := 'CALL TO PK_HAND_OFF_CORE.GET_PROF_EPISODES';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        RETURN pk_hand_off_core.get_prof_episodes(i_lang          => i_lang,
                                                  i_prof          => i_prof,
                                                  i_prof_cat      => i_prof_cat,
                                                  i_hand_off_type => i_hand_off_type,
                                                  i_profs         => i_profs);
    END get_prof_episodes;

    /**********************************************************************************************
    * Creates a new request for EPISODE responsability (transfer responsability).
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Professional data
    * @param i_prof_to                Destination professional
    * @param i_episode                Episode ID
    * @param i_cs                     Destination clinical service
    * @param i_dept                   Destination department
    * @param i_notes                  Transfer notes
    * @param i_flg_type               Type of request: (D) Physician transfer (N) Nurse transfer
    * @param i_flg_profile            Type of profile (when applicable): (S)pecialist (R)esident (I)ntern (N)urse
    * @param i_id_speciality          Destination speciality ID (when applicable)
    * @param i_dt_reg                 Record date (current date if NULL)
    * @param o_epis_prof_resp         Created record ID
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Alexandre Santos
    * @version                        2.6.0.5
    * @since                          22-03-2011
    **********************************************************************************************/
    FUNCTION create_request_resp
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_prof_to        IN epis_prof_resp.id_prof_to%TYPE,
        i_episode        IN epis_prof_resp.id_episode%TYPE,
        i_cs             IN NUMBER,
        i_dept           IN NUMBER,
        i_notes          IN epis_prof_resp.notes_clob%TYPE,
        i_flg_type       IN epis_prof_resp.flg_type%TYPE,
        i_flg_profile    IN profile_template.flg_profile%TYPE,
        i_id_speciality  IN epis_multi_prof_resp.id_speciality%TYPE,
        i_dt_reg         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_epis_prof_resp OUT epis_prof_resp.id_epis_prof_resp%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'CREATE_REQUEST_RESP';
        --
        l_flg_resp_g CONSTANT VARCHAR2(1) := 'G'; -- Request responsability
        l_epis_prof_resp table_number;
        l_cs_dept        NUMBER(24);
        --
        l_handoff_type sys_config.value%TYPE;
        l_cfg_handoff_nurse CONSTANT sys_config.id_sys_config%TYPE := 'HANDOFF_NURSE';
        l_handoff_nurse sys_config.value%TYPE;
    BEGIN
        --TODO: l_cs_dept
    
        g_error := 'GET HAND OFF TYPE';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
    
        g_error := 'GET HAND OFF TYPE';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_handoff_nurse := pk_sysconfig.get_config(i_code_cf   => l_cfg_handoff_nurse,
                                                   i_prof_inst => i_prof.institution,
                                                   i_prof_soft => i_prof.software);
    
        g_error := 'SET L_CS_DEPT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF i_flg_type = pk_hand_off.g_flg_type_d
           AND l_handoff_type = pk_hand_off.g_handoff_normal
        THEN
            l_cs_dept := i_cs;
        ELSIF i_flg_type = pk_hand_off.g_flg_type_n
              AND l_handoff_nurse = pk_hand_off.g_handoff_nurse_clin_serv
        THEN
            l_cs_dept := i_cs;
        ELSIF i_flg_type = pk_hand_off.g_flg_type_n
              AND l_handoff_nurse = pk_hand_off.g_handoff_nurse_department
        THEN
            l_cs_dept := i_dept;
        ELSE
            l_cs_dept := NULL;
        END IF;
    
        g_error := 'CALL TO PK_HAND_OFF.CREATE_EPIS_PROF_RESP_API';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT pk_hand_off.create_epis_prof_resp_api(i_lang           => i_lang,
                                                     i_prof           => i_prof,
                                                     i_prof_to        => table_varchar(i_prof_to),
                                                     i_tot_epis       => table_number(g_one),
                                                     i_epis_pat       => table_number(i_episode),
                                                     i_cs_or_dept     => table_number(l_cs_dept),
                                                     i_notes          => table_varchar(i_notes),
                                                     i_flg_type       => i_flg_type,
                                                     i_flg_resp       => l_flg_resp_g,
                                                     i_flg_profile    => i_flg_profile,
                                                     i_sysdate        => i_dt_reg,
                                                     i_id_speciality  => i_id_speciality,
                                                     o_epis_prof_resp => l_epis_prof_resp,
                                                     o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF l_epis_prof_resp IS NOT NULL
           AND l_epis_prof_resp.count = g_one
        THEN
            o_epis_prof_resp := l_epis_prof_resp(g_one);
        END IF;
    
        RETURN TRUE;
    END create_request_resp;

    /********************************************************************************************
    * Cancel a SPECIALIST PHYSICIAN responsability record that is in "finalized" state.
    * Used by INTER-
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info
    * @param i_id_professional         Specialist physician ID
    * @param i_notes                   Cancellation notes
    * @param i_id_cancel_reason        Cancel reason ID
    * @param i_dt_cancel               Cancellation date
    * @param o_error                   Error message
    * 
    * @return                          TRUE if sucess, FALSE otherwise
    *
    * @author                          José Brito
    * @version                         2.6
    * @since                           13-Jul-2011
    *
    **********************************************************************************************/
    FUNCTION cancel_responsability_spec
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_professional  IN professional.id_professional%TYPE,
        i_notes            IN epis_prof_resp.notes_cancel%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_dt_cancel        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(200 CHAR) := 'CANCEL_RESPONSABILITY_SPEC';
        l_internal_error EXCEPTION;
    BEGIN
    
        IF NOT pk_hand_off_core.cancel_responsability_spec(i_lang             => i_lang,
                                                           i_prof             => i_prof,
                                                           i_id_episode       => i_id_episode,
                                                           i_id_professional  => i_id_professional,
                                                           i_notes            => i_notes,
                                                           i_id_cancel_reason => i_id_cancel_reason,
                                                           i_dt_cancel        => i_dt_cancel,
                                                           o_error            => o_error)
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
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END cancel_responsability_spec;

    /********************************************************************************************
    * Cancel a responsability request.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_epis_prof_resp           Record ID
    * @param   i_flg_type                 Type of transfer: (D) Physician (N) Nurse
    * @param   i_notes                    Cancellation notes
    * @param   i_id_cancel_reason         Cancel reason ID
    * @param   i_dt_reg                   Record date (current date if NULL)
    * @param   o_error                    Error message
    *                        
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Alexandre Santos
    * @version                        2.6.0.5
    * @since                          22-03-2011
    **********************************************************************************************/
    FUNCTION cancel_request_resp
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_prof_resp   IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_flg_type         IN epis_prof_resp.flg_type%TYPE,
        i_notes            IN epis_prof_resp.notes_cancel%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_dt_reg           IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'CANCEL_REQUEST_RESP';
    BEGIN
        g_error := 'CALL_CANCEL_REQUEST_RESP';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT pk_hand_off.call_cancel_request_resp(i_lang             => i_lang,
                                                    i_prof             => i_prof,
                                                    i_epis_prof_resp   => i_epis_prof_resp,
                                                    i_flg_type         => i_flg_type,
                                                    i_notes            => i_notes,
                                                    i_id_cancel_reason => i_id_cancel_reason,
                                                    i_sysdate          => i_dt_reg,
                                                    o_error            => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    END cancel_request_resp;

    /**********************************************************************************************
    * Change the status of the hand-off requests (CANCEL, ACCEPT or REJECT).
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_tot_epis               Total episodes to process
    * @param i_epis_prof_resp         Epis prof resp array id's
    * @param i_flg_status             Status
    * @param i_flg_type               Professional category
    * @param i_notes                  Notes
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        2.6.0.5
    * @since                          22-03-2011
    **********************************************************************************************/
    FUNCTION set_epr_no_commit
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
        l_func_name CONSTANT VARCHAR2(30) := 'SET_EPR_NO_COMMIT';
        --
        l_can_refresh_mview_str VARCHAR2(1) := 'N';
        l_internal_error EXCEPTION;
    BEGIN
        g_error := 'CALL TO PK_HAND_OFF.SET_EPIS_PROF_RESP';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT pk_hand_off.call_set_epis_prof_resp(i_lang             => i_lang,
                                                   i_prof             => i_prof,
                                                   i_tot_epis         => i_tot_epis,
                                                   i_epis_prof_resp   => i_epis_prof_resp,
                                                   i_flg_status       => i_flg_status,
                                                   i_flg_type         => i_flg_type,
                                                   i_notes            => i_notes,
                                                   i_sysdate          => NULL,
                                                   i_hand_off_type    => NULL,
                                                   i_one_step_process => pk_alert_constant.g_no,
                                                   i_id_cancel_reason => NULL,
                                                   o_refresh_mview    => l_can_refresh_mview_str,
                                                   o_error            => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'CALL TO PK_HAND_OFF.SET_PROF_RESPONSIBLE_ALERT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT pk_hand_off.set_prof_responsible_alert(i_lang     => i_lang,
                                                      i_prof     => i_prof,
                                                      i_tot_epis => i_tot_epis,
                                                      o_error    => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'UPDATE MVIEW';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF l_can_refresh_mview_str = 'Y'
        THEN
            pk_episode.update_mv_episodes();
        END IF;
    
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
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_epr_no_commit;

    /**********************************************************************************************
    * Accept request for episode responsability
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_epis_prof_resp         Record ID
    * @param i_flg_type               Type of request: (D) Physician transfer (N) Nurse transfer
    * @param i_notes                  Accpet notes
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Alexandre Santos
    * @version                        2.6.0.5
    * @since                          22-03-2011
    **********************************************************************************************/
    FUNCTION set_accept_request_resp
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_flg_type       IN epis_prof_resp.flg_type%TYPE,
        i_notes          IN epis_prof_resp.notes_clob%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'SET_ACCEPT_REQUEST_RESP';
    BEGIN
        g_error := 'CALL SET_EPR_NO_COMMIT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT set_epr_no_commit(i_lang           => i_lang,
                                 i_prof           => i_prof,
                                 i_tot_epis       => table_number(g_one),
                                 i_epis_prof_resp => table_varchar(i_epis_prof_resp),
                                 i_flg_status     => pk_hand_off.g_hand_off_f,
                                 i_flg_type       => i_flg_type,
                                 i_notes          => i_notes,
                                 o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    END set_accept_request_resp;

    /**********************************************************************************************
    * Reject request for episode responsability
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_epis_prof_resp         Record ID
    * @param i_flg_type               Type of request: (D) Physician transfer (N) Nurse transfer
    * @param i_notes                  Accpet notes
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Alexandre Santos
    * @version                        2.6.0.5
    * @since                          22-03-2011
    **********************************************************************************************/
    FUNCTION set_reject_request_resp
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_flg_type       IN epis_prof_resp.flg_type%TYPE,
        i_notes          IN epis_prof_resp.notes_cancel%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'SET_REJECT_REQUEST_RESP';
    BEGIN
        g_error := 'CALL SET_EPR_NO_COMMIT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT set_epr_no_commit(i_lang           => i_lang,
                                 i_prof           => i_prof,
                                 i_tot_epis       => table_number(g_one),
                                 i_epis_prof_resp => table_varchar(i_epis_prof_resp),
                                 i_flg_status     => pk_hand_off.g_hand_off_c,
                                 i_flg_type       => i_flg_type,
                                 i_notes          => i_notes,
                                 o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    END set_reject_request_resp;

    /*******************************************************************************************************************************************
    * Sets the overall responsability for the episode
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional that insert current record
    * @param I_ID_PROF_ADMITTING      New responsable professional of information
    * @param I_ID_DEP_CLIN_SERV       DEP_CLIN_SERV identifier that should be associated with the episode
    * @param I_ID_CLINICAL_SERVICE    CLINICAL_SERVICE identifier that should be associated with the episode
    * @param I_ID_EPISODE             EPISODE identifier that should be associated
    * @param I_DT_REG                 Record date (current date if NULL)
    * @param I_FLG_RESP_TYPE          Check if flag main overall responsability is to be set ((E - default) Episode (O) overall - patient responsability)
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    *
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @author                         António Neto
    * @version                        0.1
    * @since                          18-Jan-2011
    * @dependents                     PK_INP_EPISODE
    *******************************************************************************************************************************************/
    FUNCTION set_overall_responsability
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_prof_admitting   IN profissional,
        i_id_dep_clin_serv    IN epis_info.id_dep_clin_serv%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE DEFAULT NULL,
        i_id_episode          IN episode.id_episode%TYPE,
        i_dt_reg              IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_resp_type       IN epis_multi_prof_resp.flg_resp_type%TYPE DEFAULT NULL,
        i_sbar_note           IN CLOB DEFAULT NULL,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'SET_OVERALL_RESPONSABILITY';
    
        l_id_clinical_service dep_clin_serv.id_clinical_service%TYPE;
        l_speciality_id       speciality.id_speciality%TYPE;
    
        l_internal_error EXCEPTION;
    
        l_flg_type CONSTANT epis_prof_resp.flg_type%TYPE := 'D';
        l_flg_resp CONSTANT VARCHAR2(1 CHAR) := 'G';
        l_tot_epis CONSTANT PLS_INTEGER := 1;
    
        l_handoff_type sys_config.value%TYPE;
        l_flg_profile  profile_template.flg_profile%TYPE;
        l_prof_cat     category.flg_type%TYPE;
        --
        l_flg_show                VARCHAR2(1);
        l_msg_title               sys_message.desc_message%TYPE;
        l_msg_body                sys_message.desc_message%TYPE;
        l_id_epis_prof_resp       epis_prof_resp.id_epis_prof_resp%TYPE;
        l_id_epis_multi_prof_resp epis_multi_prof_resp.id_epis_multi_prof_resp%TYPE;
        l_id_cancel_reason        cancel_reason.id_cancel_reason%TYPE;
    
        l_prof profissional;
        l_bool boolean;
        err_custom exception;
    
        CURSOR c_epis_prof_resp IS
            SELECT empr.id_epis_prof_resp, empr.id_professional
              FROM epis_multi_prof_resp empr
             WHERE empr.id_episode = i_id_episode
               AND empr.flg_status = pk_hand_off_core.g_active
               AND empr.flg_resp_type = pk_hand_off_core.g_resp_overall;
    
    BEGIN
        g_error := 'GET ADMITTING PROFESSIONAL';
        
        SELECT profissional(i_id_prof_admitting.id, e.id_institution, ei.id_software)
          INTO l_prof
          FROM episode e
          JOIN epis_info ei
            ON ei.id_episode = e.id_episode
         WHERE e.id_episode = i_id_episode;
    
        pk_hand_off_core.get_hand_off_type(i_lang, l_prof, l_handoff_type); --Get the type of hand-off
        l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => l_prof);
    
        IF pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                            i_id_prof_admitting,
                                                                            i_id_episode,
                                                                            l_prof_cat,
                                                                            l_handoff_type,
                                                                            pk_alert_constant.g_yes),
                                        i_id_prof_admitting.id) = -1
        THEN
        
            IF i_id_dep_clin_serv IS NOT NULL
            THEN
                g_error := 'GET CLINICAL_SERVICE';
                pk_alertlog.log_debug(g_error);
                BEGIN
                    SELECT dcs.id_clinical_service
                      INTO l_id_clinical_service
                      FROM dep_clin_serv dcs
                     WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_id_clinical_service := NULL;
                END;
            
            ELSIF i_id_clinical_service IS NOT NULL
            THEN
                l_id_clinical_service := i_id_clinical_service;
            END IF;
        
       
            g_error := 'HANDOFF TYPE = ' || l_handoff_type;
            pk_alertlog.log_debug(g_error);
            IF l_handoff_type = pk_hand_off.g_handoff_multiple
            THEN
                g_error := 'CALL PK_HAND_OFF_CORE.GET_FLG_PROFILE';
                pk_alertlog.log_debug(g_error);
                IF NOT pk_hand_off_core.get_flg_profile(i_lang             => i_lang,
                                                        i_prof             => l_prof,
                                                        i_profile_template => NULL,
                                                        o_flg_profile      => l_flg_profile,
                                                        o_error            => o_error)
                THEN
                    RAISE l_internal_error;
                END IF;
            END IF;
        
        
            --this code is similar to the pk_discharge.set_inp_episode
            g_error := 'CALL GET_PROF_SPECIALITY_ID';
            pk_alertlog.log_debug(g_error);
            l_speciality_id := pk_prof_utils.get_prof_speciality_id(i_lang => i_lang, i_prof => i_id_prof_admitting);
        
            IF l_handoff_type = pk_hand_off.g_handoff_multiple
            THEN
            
           
                IF i_flg_resp_type = pk_hand_off_core.g_resp_overall
                THEN
                
                    SELECT cr.id_cancel_reason
                      INTO l_id_cancel_reason
                      FROM cancel_reason cr
                     WHERE cr.id_content = g_cr_id_content;
                
                    g_error := 'CHECK Main Responsible';
                    FOR r_epis_prof_resp IN c_epis_prof_resp
                    LOOP
                        IF r_epis_prof_resp.id_professional <> i_id_prof_admitting.id
                        THEN
                            IF NOT pk_hand_off_core.cancel_responsability_spec(i_lang             => i_lang,
                                                                               i_prof             => i_prof,
                                                                               i_id_episode       => i_id_episode,
                                                                               i_id_professional  => r_epis_prof_resp.id_professional,
                                                                               i_notes            => NULL,
                                                                               i_id_cancel_reason => 10500,
                                                                               i_dt_cancel        => i_dt_reg,
                                                                               o_error            => o_error)
                            THEN
                                RETURN FALSE;
                            END IF;
                        ELSE
                            l_id_epis_prof_resp := r_epis_prof_resp.id_professional;
                        END IF;
                    END LOOP;
                
                END IF;
            
            
                IF l_id_epis_prof_resp IS NULL
                THEN
                    g_error := 'CALL PK_HAND_OFF_CORE.CALL_SET_OVERALL_RESP';
                    pk_alertlog.log_debug(g_error);
                    IF NOT pk_hand_off_core.call_set_overall_resp(i_lang                    => i_lang,
                                                                  i_prof                    => i_prof,
                                                                  i_id_episode              => i_id_episode,
                                                                  i_id_prof_resp            => i_id_prof_admitting.id,
                                                                  i_id_speciality           => l_speciality_id,
                                                                  i_notes                   => NULL,
                                                                  i_dt_reg                  => i_dt_reg,
                                                                  o_flg_show                => l_flg_show,
                                                                  o_msg_title               => l_msg_title,
                                                                  o_msg_body                => l_msg_body,
                                                                  o_id_epis_prof_resp       => l_id_epis_prof_resp,
                                                                  o_id_epis_multi_prof_resp => l_id_epis_multi_prof_resp,
                                                                  o_error                   => o_error)
                    THEN
                        RETURN FALSE; -- direct return in order to keep possible user error messages
                    END IF;
                END IF;
            ELSE
              
                g_error := 'CALL PK_HAND_OFF.CREATE_EPIS_PROF_RESP';
                pk_alertlog.log_debug(g_error);
                l_bool := pk_hand_off.create_epis_prof_resp(i_lang          => i_lang,
                                                         i_prof          => i_prof,
                                                         i_prof_to       => table_varchar(to_char(i_id_prof_admitting.id)),
                                                         i_tot_epis      => table_number(l_tot_epis),
                                                         i_epis_pat      => table_number(i_id_episode),
                                                         i_cs_or_dept    => table_number(l_id_clinical_service),
                                                         i_notes         => table_varchar(NULL),
                                                         i_flg_type      => l_flg_type,
                                                         i_flg_resp      => l_flg_resp,
                                                         i_flg_profile   => l_flg_profile,
                                                         i_sysdate       => i_dt_reg,
                                                         i_id_speciality => l_speciality_id,
                                                         i_flg_assign_supervisor => 'Y',
                                                         i_sbar_note     => i_sbar_note,
                                                         o_flg_show      => l_flg_show,
                                                         o_msg_title     => l_msg_title,
                                                         o_msg_body      => l_msg_body,
                                                         o_error         => o_error);
                                                         
                l_bool := l_bool and ( coalesce(l_flg_show, 'N') != 'Y' );
                                                         
                if not l_bool
                THEN
                   raise err_custom;
                END IF;
                
            END IF;
        
        END IF;
    
   
        RETURN TRUE;
    
    EXCEPTION
        when err_custom then
			pk_alertlog.log_error(l_msg_body);
            pk_utils.undo_changes;
            RETURN FALSE;
          
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_overall_responsability;

    /**
    * Get the current ongoing responsibility transfer ID for a given episode
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identification and its context (institution and software)
    * @param   i_episode         Episode ID
    *
    * @return                 Episode responsibility ID
    *
    * @author  José Silva
    * @version v2.6.0.5
    * @since   07-09-2011
    */
    FUNCTION get_epis_prof_resp_id
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN epis_prof_resp.id_epis_prof_resp%TYPE IS
    
        l_ret epis_prof_resp.id_epis_prof_resp%TYPE;
    
    BEGIN
        SELECT id_epis_prof_resp
          INTO l_ret
          FROM epis_prof_resp ep
         WHERE id_episode = i_episode
           AND flg_status = pk_hand_off.g_hand_off_r;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_epis_prof_resp_id;

    /*******************************************************************************************************************************************
    * Sets the episode  responsability for the episode
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional that insert current record
    * @param I_ID_EPISODE             EPISODE identifier that should be associated
    * @param I_FLG_RESP_TYPE          Check if flag main overall responsability is to be set ((E - default) Episode (O) overall - patient responsability)
    * @param I_ID_PROF_ADMITTING      Array with list responsable professional
    * @param I_ID_DEP_CLIN_SERV       Array with DEP_CLIN_SERV identifier that should be associated with the episode
    * @param I_DT_REG                 Array with responsable record date (current date if NULL)
    * @param i_id_priority            Array with priority 
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    *
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          13-Nov-2017
    *******************************************************************************************************************************************/
    FUNCTION set_episode_responsability
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_flg_resp_type       IN epis_multi_prof_resp.flg_resp_type%TYPE DEFAULT NULL,
        i_id_prof_admitting   IN table_number,
        i_id_clinical_service IN table_number, --
        i_dt_reg              IN table_varchar, -- TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_priority         IN table_number,
        i_sbar_note           IN CLOB DEFAULT NULL,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'SET_OVERALL_RESPONSABILITY';
    
        l_id_clinical_service dep_clin_serv.id_clinical_service%TYPE;
        l_speciality_id       speciality.id_speciality%TYPE;
    
        l_internal_error EXCEPTION;
    
        l_flg_type CONSTANT epis_prof_resp.flg_type%TYPE := 'D';
        l_flg_resp CONSTANT VARCHAR2(1 CHAR) := 'G';
        l_tot_epis CONSTANT PLS_INTEGER := 1;
    
        l_handoff_type sys_config.value%TYPE;
        l_flg_profile  profile_template.flg_profile%TYPE;
        l_prof_cat     category.flg_type%TYPE;
        --
        l_flg_show                VARCHAR2(1);
        l_msg_title               sys_message.desc_message%TYPE;
        l_msg_body                sys_message.desc_message%TYPE;
        l_id_epis_prof_resp       epis_prof_resp.id_epis_prof_resp%TYPE;
        l_id_epis_multi_prof_resp epis_multi_prof_resp.id_epis_multi_prof_resp%TYPE;
        l_id_cancel_reason        cancel_reason.id_cancel_reason%TYPE;
        l_responsible_list        table_number;
        l_prof                    profissional;
        l_id_software             software.id_software%TYPE;
        l_id_institution          institution.id_institution%TYPE;
        l_is_responsible          VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_flg_main_responsible    VARCHAR2(1 CHAR);
    
        l_dt_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
        g_error := 'GET ADMITTING PROFESSIONAL';
        SELECT e.id_institution, ei.id_software
          INTO l_id_institution, l_id_software
          FROM episode e
          JOIN epis_info ei
            ON ei.id_episode = e.id_episode
         WHERE e.id_episode = i_id_episode;
    
        l_prof := profissional(NULL, l_id_institution, l_id_software);
    
        pk_hand_off_core.get_hand_off_type(i_lang, l_prof, l_handoff_type); --Get the type of hand-off
    
        FOR i IN i_id_prof_admitting.first .. i_id_prof_admitting.last
        LOOP
            dbms_output.put_line('i_id_prof_admitting(i):' || i_id_prof_admitting(i));
        
            l_prof    := profissional(i_id_prof_admitting(i), l_id_institution, l_id_software);
            l_dt_tstz := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_reg(i), NULL);
        
            g_error := 'HANDOFF TYPE = ' || l_handoff_type;
            IF l_handoff_type = pk_hand_off.g_handoff_multiple
            THEN
                g_error := 'CALL PK_HAND_OFF_CORE.GET_FLG_PROFILE';
                IF NOT pk_hand_off_core.get_flg_profile(i_lang             => i_lang,
                                                        i_prof             => l_prof,
                                                        i_profile_template => NULL,
                                                        o_flg_profile      => l_flg_profile,
                                                        o_error            => o_error)
                THEN
                    RAISE l_internal_error;
                END IF;
            END IF;
        
            --this code is similar to the pk_discharge.set_inp_episode
            g_error         := 'CALL GET_PROF_SPECIALITY_ID';
            l_speciality_id := pk_prof_utils.get_prof_speciality_id(i_lang => i_lang, i_prof => l_prof);
        
            IF l_handoff_type = pk_hand_off.g_handoff_multiple
               AND i_flg_resp_type = pk_hand_off_core.g_resp_overall
            THEN
                IF i_id_priority(i) = 1
                THEN
                    l_flg_main_responsible := pk_alert_constant.g_yes;
                ELSE
                    l_flg_main_responsible := pk_alert_constant.g_no;
                END IF;
            
                g_error := 'CALL PK_HAND_OFF_CORE.CALL_SET_OVERALL_RESP';
                IF NOT pk_hand_off_core.call_set_overall_resp(i_lang                    => i_lang,
                                                              i_prof                    => i_prof,
                                                              i_id_episode              => i_id_episode,
                                                              i_id_prof_resp            => i_id_prof_admitting(i),
                                                              i_id_speciality           => l_speciality_id,
                                                              i_notes                   => NULL,
                                                              i_dt_reg                  => l_dt_tstz,
                                                              i_flg_epis_respons        => pk_alert_constant.g_no,
                                                              i_flg_update_resp         => pk_alert_constant.g_yes,
                                                              i_flg_main_responsible    => l_flg_main_responsible,
                                                              i_priority                => i_id_priority(i),
                                                              o_flg_show                => l_flg_show,
                                                              o_msg_title               => l_msg_title,
                                                              o_msg_body                => l_msg_body,
                                                              o_id_epis_prof_resp       => l_id_epis_prof_resp,
                                                              o_id_epis_multi_prof_resp => l_id_epis_multi_prof_resp,
                                                              o_error                   => o_error)
                THEN
                    RETURN FALSE; -- direct return in order to keep possible user error messages
                END IF;
            
            ELSE
                g_error := 'CALL PK_HAND_OFF.CREATE_EPIS_PROF_RESP';
                IF NOT pk_hand_off.create_epis_prof_resp(i_lang                  => i_lang,
                                                         i_prof                  => i_prof,
                                                         i_prof_to               => table_varchar(to_char(i_id_prof_admitting(i))),
                                                         i_tot_epis              => table_number(l_tot_epis),
                                                         i_epis_pat              => table_number(i_id_episode),
                                                         i_cs_or_dept            => i_id_clinical_service,
                                                         i_notes                 => table_varchar(NULL),
                                                         i_flg_type              => l_flg_type,
                                                         i_flg_resp              => l_flg_resp,
                                                         i_flg_profile           => l_flg_profile,
                                                         i_sysdate               => l_dt_tstz,
                                                         i_id_speciality         => l_speciality_id,
                                                         i_flg_assign_supervisor => pk_alert_constant.g_yes,
                                                         i_priority              => i_id_priority(i),
                                                         i_sbar_note             => i_sbar_note,
                                                         o_flg_show              => l_flg_show,
                                                         o_msg_title             => l_msg_title,
                                                         o_msg_body              => l_msg_body,
                                                         o_error                 => o_error)
                THEN
                    RETURN FALSE; -- direct return in order to keep possible user error messages
                END IF;
            END IF;
        
        END LOOP;
    
        -- FINALIZAR RESPONSABILIDADES
        IF NOT pk_hand_off_core.set_prof_resp_outdated(i_lang          => i_lang,
                                                       i_prof          => i_prof,
                                                       i_episode       => i_id_episode,
                                                       i_flg_resp_type => i_flg_resp_type,
                                                       i_prof_list     => i_id_prof_admitting,
                                                       o_error         => o_error)
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
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_episode_responsability;

BEGIN
    /* CAN'T TOUCH THIS */
    /* Who am I */
    pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    pk_alertlog.log_init(object_name => g_package);
END pk_hand_off_api;
/
