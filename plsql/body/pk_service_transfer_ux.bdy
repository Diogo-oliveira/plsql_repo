/*-- Last Change Revision: $Rev: 2027711 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:04 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_service_transfer_ux IS

    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    /********************************************************************************************
    * RETURNS A LIST OF TRANSFERS FOR the current DESTINATION SERVICE and 
    * RETURNS A LIST OF TRANSFERS FOR other DESTINATION SERVICEs.
    *
    * @param   I_LANG       language associated to the professional executing the request
    * @param   I_PROF       professional, institution and software ids
    * @param   o_out_list   A LIST OF TRANSFERS FOR other DESTINATION SERVICE
    * @param   o_in_list    A LIST OF TRANSFERS FOR the current DESTINATION SERVICE    
    * @param   o_error      Error message
    *                        
    * @return  true or false on success or error
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.0.4
    * @since                          21-Oct-2010    
    **********************************************************************************************/
    FUNCTION get_dept_transfer_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_out_list OUT pk_types.cursor_type,
        o_in_list  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
    BEGIN
        g_error := 'CALL PK_SERVICE_TRANSFER.GET_DEPT_TRANSFER_LIST';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_service_transfer.get_dept_transfer_list(i_lang     => i_lang,
                                                          i_prof     => i_prof,
                                                          o_out_list => o_out_list,
                                                          o_in_list  => o_in_list,
                                                          o_error    => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_out_list);
            pk_types.open_my_cursor(o_in_list);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_DEPT_TRANSFER_LIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_out_list);
            pk_types.open_my_cursor(o_in_list);
            RETURN FALSE;
        
    END get_dept_transfer_list;

    /********************************************************************************************
    * CHECK_ACTIVE_TRANSFER            Check if there is any transfer active (service or inter-hospital transfer)
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_prof                    professional, software and institution ids
    * @param i_flg_context             Flag that define what are we checking (Service Transfer 'S' or Inter-Hospital Transfer 'H')
    * @param i_id_episode              Episode ID to check transfers
    * @param o_flg_transfer            Flag that informs that there is any active service or inter-hospital transfer (Y/N)
    * @param o_msg_transfer            Message that informs that there is any active service or inter-hospital transfer
    * @param o_title_transfer          Title that informs that check if there is any active service or inter-hospital transfer
    * @param o_id_sys_shortcut         ID shortcut if there is any active service or inter-hospital transfer
    * @param o_flg_info_type           Flag that informs that there is any active service or inter-hospital transfer (I) Or there is more than one episode active in the same visit (E)
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          António Neto
    * @version                         2.5.1.4
    * @since                           22-Mar-2011
    *
    **********************************************************************************************/
    FUNCTION check_active_transfer
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_context     IN VARCHAR2 DEFAULT pk_service_transfer.g_transfer_flg_hospital_h,
        i_id_episode      IN episode.id_episode%TYPE,
        o_flg_transfer    OUT VARCHAR2,
        o_msg_transfer    OUT VARCHAR2,
        o_title_transfer  OUT VARCHAR2,
        o_id_sys_shortcut OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_flg_info_type   OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
    BEGIN
        g_error := 'CALL PK_SERVICE_TRANSFER.CHECK_ACTIVE_TRANSFER';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_service_transfer.check_active_transfer(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_flg_context     => i_flg_context,
                                                         i_id_episode      => i_id_episode,
                                                         o_flg_transfer    => o_flg_transfer,
                                                         o_msg_transfer    => o_msg_transfer,
                                                         o_title_transfer  => o_title_transfer,
                                                         o_id_sys_shortcut => o_id_sys_shortcut,
                                                         o_flg_info_type   => o_flg_info_type,
                                                         o_error           => o_error)
        THEN
            RAISE l_internal_error;
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
                                              'CHECK_ACTIVE_TRANSFER',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END check_active_transfer;

    /********************************************************************************************
    * GET ALL TRANSFER FROM GIVEN INSTITUTION AND PATIENT.
    *
    * @param   I_LANG             language associated to the professional executing the request
    * @param   i_id_episode       episode id
    * @param   i_id_patient       patient id
    * @param   i_prof             professional
    * @param   o_flag_my_service  Y-my service; N-not my service
    * @param   o_list             A LIST OF TRANSFERS    
    * @param   o_error            Error message
    *                        
    * @return  true or false on success or error
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.0.4
    * @since                          23-Mar-2011
    **********************************************************************************************/
    FUNCTION get_pat_transfer_list
    (
        i_lang            IN NUMBER,
        i_id_episode      IN NUMBER,
        i_id_patient      IN NUMBER,
        i_prof            IN profissional,
        o_flag_my_service OUT NUMBER,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
    BEGIN
        g_error := 'CALL PK_SERVICE_TRANSFER.GET_PAT_TRANSFER_LIST. i_id_episode: ' || i_id_episode ||
                   ' i_id_patient: ' || i_id_patient;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_service_transfer.get_pat_transfer_list(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_id_episode      => i_id_episode,
                                                         i_id_patient      => i_id_patient,
                                                         o_flag_my_service => o_flag_my_service,
                                                         o_list            => o_list,
                                                         o_error           => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_PAT_TRANSFER_LIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_pat_transfer_list;

    /********************************************************************************************
    * Get the transfer service detail and history data.
    *
    * @param   I_LANG                      language associated to the professional executing the request
    * @param   i_prof                      professional
    * @param   i_id_epis_prof_resp         service transfer identifier
    * @param   i_flg_screen                D-detail; H-history    
    * @param   o_data                      Output data    
    * @param   o_error                     Error message
    *                        
    * @return  true or false on success or error
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.0.4
    * @since                          28-Mar-2011
    **********************************************************************************************/
    FUNCTION get_serv_trans_det_hist
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_prof_resp IN table_number,
        i_flg_screen        IN VARCHAR2,
        o_data              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
    BEGIN
        g_error := 'CALL PK_SERVICE_TRANSFER.get_serv_trans_det_hist. i_flg_screen: ' || i_flg_screen;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_service_transfer.get_serv_trans_det_hist(i_lang              => i_lang,
                                                           i_prof              => i_prof,
                                                           i_id_epis_prof_resp => i_id_epis_prof_resp,
                                                           i_flg_screen        => i_flg_screen,
                                                           o_data              => o_data,
                                                           o_error             => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_data);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_SERV_TRANS_DET_HIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_data);
            RETURN FALSE;
    END get_serv_trans_det_hist;

BEGIN
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_service_transfer_ux;
/
