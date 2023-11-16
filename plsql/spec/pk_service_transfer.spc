/*-- Last Change Revision: $Rev: 2028968 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:01 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_service_transfer AS

    -- ################################################################################
    /******************************************************************************
    NAME: GET_IN_DEPT_TRANSFER_LIST
    CREATION INFO: CARLOS FERREIRA 2007/01/31
    GOAL: RETURNS A LIST OF TRANSFERS FOR DESTINATION SERVICE
    NOTAS:
    
    PARAMETERS:
    -------------------------------------------------------------------------------
    | PARAMETER NAME   |   DATATYPE             | I/O |      DESCRIPTION          |
    -------------------------------------------------------------------------------
    -------------------------------------------------------------------------------
    *********************************************************************************/
    FUNCTION get_in_dept_transfer_list
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    -- #################################################################################
    /******************************************************************************
    NAME: GET_IN_DEPT_TRANSFER_LIST
    CREATION INFO: CARLOS FERREIRA 2007/01/31
    GOAL: RETURNS A LIST OF TRANSFERS FOR DESTINATION SERVICE
    NOTAS:
    
    PARAMETERS:
    -------------------------------------------------------------------------------
    | PARAMETER NAME   |   DATATYPE             | I/O |      DESCRIPTION          |
    -------------------------------------------------------------------------------
    -------------------------------------------------------------------------------
    *********************************************************************************/
    FUNCTION get_out_dept_transfer_list
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

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
        i_lang     IN NUMBER,
        i_prof     IN profissional,
        o_out_list OUT pk_types.cursor_type,
        o_in_list  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

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

    /***************************************************************************
    * build string icon for service transfer state
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID  
    * @param i_id_epis_prof_resp      Primary key of epis_prof_resp table                 
    *
    * @return string icon   
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.5.1                                  
    * @since                          2011/03/24                               
    **************************************************************************/

    FUNCTION get_serv_transfer_icon_string
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE
    ) RETURN VARCHAR2;

    /***************************************************************************
    * Returns a list of service transfer in a string
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID  
    * @param i_patient                Patient identifier
    * @param i_episode                Episode identifier
    *
    * @return string with transfer service
    *                                                                         
    * @author                         Elisabete Bugalho                         
    * @version                        2.7.1.0                                 
    * @since                          2017/04/20                            
    **************************************************************************/
    FUNCTION get_pat_service_transfer
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    g_package_name VARCHAR2(32 CHAR);
    g_owner        VARCHAR2(30 CHAR);
    g_error        VARCHAR2(1000 CHAR);
    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50 CHAR);
    g_found        BOOLEAN;
    g_date_mask    VARCHAR2(16 CHAR) := 'YYYYMMDDHH24MISS';

    g_flg_transf_s     CONSTANT VARCHAR2(1 CHAR) := 'S';
    g_flg_ehr_normal   CONSTANT VARCHAR2(1 CHAR) := 'N';
    g_flg_ehr_schedule CONSTANT VARCHAR2(1 CHAR) := 'S';

    g_transfer_flg_service_s      CONSTANT VARCHAR2(30 CHAR) := 'S';
    g_transfer_flg_hospital_h     CONSTANT VARCHAR2(30 CHAR) := 'H';
    g_transfer_hospital_shortcut  CONSTANT PLS_INTEGER := 800003;
    g_transfer_service_shortcut   CONSTANT PLS_INTEGER := 623;
    g_subseq_episodes_shortcut    CONSTANT PLS_INTEGER := NULL;
    g_message_subseq_episodes_m   CONSTANT VARCHAR2(30 CHAR) := 'TRANSFER_INSTITUTION_M002';
    g_message_service_transfer_m  CONSTANT VARCHAR2(30 CHAR) := 'TRANSFER_INSTITUTION_M009';
    g_message_hospital_transfer_m CONSTANT VARCHAR2(30 CHAR) := 'TRANSFER_INSTITUTION_M008';
    g_message_service_transfer_t  CONSTANT VARCHAR2(30 CHAR) := 'TRANSFER_INSTITUTION_T027';
    g_message_hospital_transfer_t CONSTANT VARCHAR2(30 CHAR) := 'TRANSFER_INSTITUTION_T026';
    g_hour_format                 CONSTANT VARCHAR2(4 CHAR) := 'HOUR';
    g_hours_limit_to_show         CONSTANT VARCHAR2(21 CHAR) := 'TRANSF_INST_GRID_TIME';
    g_message_more_episodes_m     CONSTANT VARCHAR2(25 CHAR) := 'TRANSFER_INSTITUTION_M011';
    g_message_more_episodes_t     CONSTANT VARCHAR2(25 CHAR) := 'TRANSFER_INSTITUTION_T030';
    g_flg_info_type_tranfer_i     CONSTANT VARCHAR2(1 CHAR) := 'I';
    g_flg_info_type_episodes_e    CONSTANT VARCHAR2(1 CHAR) := 'E';

    g_detail_d  CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_history_h CONSTANT VARCHAR2(1 CHAR) := 'H';

    -- type of content to be returned in the detail/history screens
    g_title_t       CONSTANT VARCHAR2(1) := 'T';
    g_content_c     CONSTANT VARCHAR2(1) := 'C';
    g_signature_s   CONSTANT VARCHAR2(1) := 'S';
    g_new_content_n CONSTANT VARCHAR2(1) := 'N';
    g_line_l        CONSTANT VARCHAR2(1) := 'L';
    --a content under other content
    g_content_sc      CONSTANT VARCHAR2(2) := 'SC';
    g_new_content_nsc CONSTANT VARCHAR2(3) := 'NSC';

    g_sm_detail_empty CONSTANT sys_message.code_message%TYPE := 'COMMON_M106';
    g_sm_no_changes   CONSTANT sys_message.code_message%TYPE := 'HIDRICS_M072';

    g_sd_transfer_status          CONSTANT sys_domain.code_domain%TYPE := 'EPIS_PROF_RESP.TRANSFER_STATUS';
    g_sd_transfer_status_det_desc CONSTANT sys_domain.code_domain%TYPE := 'EPIS_PROF_RESP.FLG_STATUS_DET';
    g_sd_patient_consent          CONSTANT sys_domain.code_domain%TYPE := 'EPIS_PROF_RESP.FLG_PATIENT_CONSENT';

    g_open_parenthesis  CONSTANT VARCHAR2(2 CHAR) := ' (';
    g_close_parenthesis CONSTANT VARCHAR2(1 CHAR) := ')';

    g_hand_off_f CONSTANT epis_prof_resp.flg_status%TYPE := 'F'; -- Final
    g_hand_off_x CONSTANT epis_prof_resp.flg_status%TYPE := 'X'; -- Executada

    g_exception EXCEPTION;

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
    * GET_TRANSFER_SHORTCUT            Gets the transfer status string from an episode
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_prof                    professional, software and institution ids
    * @param i_flg_context             Flag that define what are we checking (Service Transfer 'S' or Inter-Hospital Transfer 'H')
    * 
    * @return                          Transfer status string with icon
    *
    * @author                          Sofia Mendes
    * @version                         2.5.1.4
    * @since                           24-Mar-2011
    *
    **********************************************************************************************/
    FUNCTION get_transfer_shortcut
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_context IN VARCHAR2
    ) RETURN sys_shortcut.id_sys_shortcut%TYPE;

    /********************************************************************************************
    * GET_TRANSFER_STATUS_ICON         Gets the transfer status string from an episode
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_prof                    professional, software and institution ids
    * @param i_id_episode              Episode ID to check transfers
    * @param i_flg_context             Flag that define what are we checking (Service Transfer 'S' or Inter-Hospital Transfer 'H')
    * 
    * @return                          Transfer status string with icon
    *
    * @author                          António Neto
    * @version                         2.5.1.4
    * @since                           24-Mar-2011
    *
    **********************************************************************************************/
    FUNCTION get_transfer_status_icon
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_flg_context IN VARCHAR2 DEFAULT pk_service_transfer.g_transfer_flg_hospital_h
        
    ) RETURN VARCHAR2;

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

    /**
    * Get detail/history signature line
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_id_episode                Episode id
    * @param   i_date                      Date of the insertion/last change
    * @param   i_id_prof_last_change       Professional id that performed the insertion/ last change
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Sofia Mendes
    * @version v2.6.0.5
    * @since   14-Jan-2011
    */
    FUNCTION get_signature
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_date                IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_last_change IN professional.id_professional%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_transfer_detail
    (
        i_lang              IN NUMBER,
        i_area              IN VARCHAR2, --- A, B,C
        i_prof              IN profissional,
        i_id_epis_prof_resp IN NUMBER,
        o_title             OUT pk_types.cursor_type,
        o_data              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

END pk_service_transfer;
/