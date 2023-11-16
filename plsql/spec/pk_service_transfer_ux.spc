/*-- Last Change Revision: $Rev: 2028970 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:02 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_service_transfer_ux IS

    -- Author  : SOFIA.MENDES
    -- Created : 06-05-2010 14:02:07
    -- Purpose : Activity Therapist UX functions

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

END pk_service_transfer_ux;
/
