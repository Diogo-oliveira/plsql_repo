/*-- Last Change Revision: $Rev: 2028827 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:11 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_p1_adm_hs AS

    /****************************************************************************************
    PROJECT         : ALERT-P1
    PROJECT TEAM    : JOAO SA ( TEAM LEADER, PROJECT ANALYSIS, JAVA MAN ),
                      CARLOS FERREIRA ( PROJECT ANALYSIS, DB MAN ),
                      RUI DIAS ( PROJECT ANALYSIS, FLASH MAN ).
    
    PK CREATED BY   : CARLOS FERREIRA
    PK DATE CREATION: 07-2005
    PK GOAL         : THIS PACKAGE TAKES CARE OF ALL FUNCTIONS REGARDING THE CLERK ( ADMINISTRATIVE )
                      LOCATED AT THE HOSPITAL.
    
    NOTES/ OBS      : ---
    ******************************************************************************************/

    /**
    * Check if referral can change status to "No show"
    * 
    * @param   i_lang    Language associated to the professional executing the request
    * @param   i_prof    Professional, institution and software ids
    * @param   i_id_ref  Referral identifier    
    * @param   i_id_workflow              Workflow identifier
    * @param   i_flg_status               Referral status
    * @param   i_id_profile_template      Profile template identifier
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   14-05-2012 
    */
    FUNCTION check_no_show
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref              IN p1_external_request.id_external_request%TYPE,
        i_id_workflow         IN p1_external_request.id_workflow%TYPE,
        i_flg_status          IN p1_external_request.flg_status%TYPE,
        i_id_profile_template IN profile_template.id_profile_template%TYPE
    ) RETURN VARCHAR;

    /**
    * Gets status change options
    * 
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional, institution and software ids
    * @param   i_id_ext_req request id    
    * @param   I_DT_MODIFIED last modified date as provided by get_p1_detail
    * @param   o_status available options list
    * @param   O_FLG_SHOW {*} 'Y' referral has been changed {*} 'N' otherwise
    * @param   O_MSG_TITLE message title
    * @param   O_MSG message text
    * @param   o_button type of button to show with message
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 2.0
    * @since   06-12-2007
    * @modify  Ana Monteiro 2009-01-19 ALERT-13289
    * @modify  Ana Monteiro 2009-05-11 ALERT-27134: Pedidos importados nao podem ser devolvidos   
    */
    FUNCTION get_status_options
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ext_req  IN p1_external_request.id_external_request%TYPE,
        i_dt_modified IN VARCHAR2,
        o_status      OUT pk_types.cursor_type,
        o_flg_show    OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_msg         OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Change request status. 
    *
    * @param   i_lang            Language identifier
    * @param   i_prof            Professional, institution and software
    * @param   i_ext_req         Referral identifier
    * @param   i_status          Referral final flag status     
    * @param   i_notes           Notes of this transition
    * @param   i_reason_code     Decline reason identifier
    * @param   i_dcs destination department/clinical_service    
    * @param   i_date            Date of status change       
    * @param   o_track           Array of ID_TRACKING transitions
    * @param   o_error           An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   29-04-2008
    */
    FUNCTION set_status_internal
    (
        i_lang           IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_ext_req        IN p1_external_request.id_external_request%TYPE,
        i_status      IN VARCHAR2,
        i_notes       IN VARCHAR2,
        i_reason_code IN p1_reason_code.id_reason_code%TYPE,
        i_dcs         IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_date        IN p1_tracking.dt_tracking_tstz%TYPE,
        i_transaction_id IN VARCHAR2 DEFAULT NULL,
        o_track          OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if theres a process in the institution that matches the patient
    *
    * ATENTION: This function is used only for simulation purposes.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PAT patient id professional, institution and software ids
    * @param   I_PROF professional id, institution and software
    * @param   I_SEQ_NUM external system id
    * @param   I_SNS National Health System number
    * @param   I_NAME patient name
    * @param   I_GENDER patient gender (M, F or I)
    * @param   I_DT_BIRTH patient date of birth                
    * @param   O_DATA_OUT patient data to be returned    
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 3.0
    * @since   30-10-2007
    */
    FUNCTION get_match
    (
        i_lang     IN language.id_language%TYPE,
        i_pat      IN patient.id_patient%TYPE,
        i_prof     IN profissional,
        i_sns      IN VARCHAR2,
        i_name     IN VARCHAR2,
        i_gender   IN VARCHAR2,
        i_dt_birth IN VARCHAR2,
        o_data_out OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Sets the connection between the patient id and the hospital process
    * Calls set_match internal and commits.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PAT patient
    * @param   I_PROF professional id, institution and software
    * @param   I_SEQ_NUM external system id
    * @param   I_CLIN_REC patient process number on the institution, if available.
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Jo∆o S
    * @version 2.0
    * @since   28-11-2006
    */
    FUNCTION set_match
    (
        i_lang     IN language.id_language%TYPE,
        i_pat      IN patient.id_patient%TYPE,
        i_prof     IN profissional,
        i_seq_num  IN p1_match.sequential_number%TYPE,
        i_clin_rec IN clin_record.num_clin_record%TYPE,
        i_epis     IN episode.id_episode%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Sets the connection between the patient id and the hospital process
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PAT patient
    * @param   I_PROF professional id, institution and software
    * @param   I_SEQ_NUM external system id
    * @param   I_CLIN_REC patient process number on the institution, if available.
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Jo∆o S
    * @version 2.0
    * @since   28-11-2006
    */
    FUNCTION set_match_internal
    (
        i_lang     IN language.id_language%TYPE,
        i_pat      IN patient.id_patient%TYPE,
        i_prof     IN profissional,
        i_seq_num  IN p1_match.sequential_number%TYPE,
        i_clin_rec IN clin_record.num_clin_record%TYPE,
        i_epis     IN episode.id_episode%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels match
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_pat patient id 
    * @param   i_prof professional id, institution and software
    * @param   i_id not in use
    * @param   i_id_ext_sys not in use    
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Jo∆o S
    * @version 2.0
    * @since   28-11-2006
    */
    FUNCTION drop_match
    (
        i_lang       IN language.id_language%TYPE,
        i_pat        IN patient.id_patient%TYPE, --- PARA SIMULAR NA FORMACAO
        i_prof       IN profissional,
        i_id         IN patient.id_patient%TYPE,
        i_id_ext_sys IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get available genders list.
    * The difference from pk_list.get_gender_list is that it return the "Unknown" option which
    * is used by the match screen.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   o_data return data
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   31-10-2007
    */
    FUNCTION get_gender_list
    (
        i_lang   IN LANGUAGE.id_language%TYPE,
        o_gender OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets number of available dcs for the request. 
    *
    * @param   i_lang professional id
    * @param   i_prof dep_clin_serv id
    * @param   i_ext_req referral id
    * @param   o_count number of available dcs    
    * @param   o_id dcs id, when there's only one.    
    * @param   o_error error message    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   29-04-2008
    */
    FUNCTION get_clin_serv_forward_count
    (
        i_lang    IN LANGUAGE.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        o_count   OUT NUMBER,
        o_id      OUT dep_clin_serv.id_dep_clin_serv%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets departments available for forwarding the request. 
    *
    * @param   i_lang professional id
    * @param   i_prof dep_clin_serv id
    * @param   i_ext_req referral id
    * @param   o_dep department ids and description    
    * @param   o_error error message    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   29-04-2008
    */
    FUNCTION get_dep_forward_list
    (
        i_lang    IN LANGUAGE.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_rec IN p1_external_request.id_external_request%TYPE,
        o_dep     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets clinical_services (the ids are dep_clin_serv) available for forwarding the request. 
    *
    * @param   i_lang professional id
    * @param   i_prof dep_clin_serv id
    * @param   i_ext_req referral id
    * @param   i_dep department id    
    * @param   o_clin_serv dep_clin_serv ids and clinical services description    
    * @param   o_error error message    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   29-04-2008
    */
    FUNCTION get_clin_serv_forward_list
    (
        i_lang      IN LANGUAGE.id_language%TYPE,
        i_prof      IN profissional,
        i_ext_rec   IN p1_external_request.id_external_request%TYPE,
        i_dep       IN department.id_department%TYPE,
        o_clin_serv OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

END pk_p1_adm_hs;
/
