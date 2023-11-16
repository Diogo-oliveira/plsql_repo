/*-- Last Change Revision: $Rev: 2028840 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:15 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_p1_med_hs AS

    /****************************************************************************************
    PROJECT         : ALERT-P1
    PROJECT TEAM    : JOAO SA ( TEAM LEADER, PROJECT ANALYSIS, JAVA MAN ),
                      CARLOS FERREIRA ( PROJECT ANALYSIS, DB MAN ),
                      RUI DIAS ( PROJECT ANALYSIS, FLASH MAN ).
    
    PK CREATED BY   : CARLOS FERREIRA
    PK DATE CREATION: 07-2005
    PK GOAL         : THIS PACKAGE TAKES CARE OF ALL FUNCTIONS REGARDING THE DOCTOR ( MEDICO )
                      LOCATED AT THE HOSPITAL.
    
    NOTES/ OBS      : ---
    ******************************************************************************************/

    /**
    * Get available options for triage
    * Since version 1.1 (10-04-2007) allows changing status for requests with status (A)ccepted
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_EXT_REQ request id. Only for updates.
    * @param   I_EXT_FLG_STATUS referral status
    * @param   I_DT_MODIFIED last modified date as provided by get_p1_detail
    * @param   O_STATUS available status (descriptions and values)
    *
    * @param   O_FLG_SHOW {*} 'Y' referral has been changed {*} 'N' otherwise
    * @param   O_MSG_TITLE message title
    * @param   O_MSG message text
    * @param   o_button type of button to show with message
    * @param   O_ERROR an error message, set when return=false    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Jo∆o S
    * @version 1.1
    * @since   19-09-2006
    * @modify  Ana Monteiro 2009-01-16 ALERT-13289
    * @modify  Ana Monteiro 2009-05-11 ALERT-27134: Pedidos importados nao podem ser devolvidos   
    */
    FUNCTION get_status_options
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_ext_req     IN p1_external_request.id_external_request%TYPE,
        i_dt_modified IN VARCHAR2,
        o_status      OUT pk_types.cursor_type,
        o_flg_show    OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_msg         OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Changes referral status
    * Checks for changes using dt_last_interaction
    *
    * @param   i_lang            Language identifier
    * @param   i_prof            Professional, institution and software
    * @param   i_id_p1           Referral identifier
    * @param   i_action          Triage decision: to schedule, Refuse, Decline, Forward, etc
    * @param   i_dep_clin_serv   Service id, used when changing clinical service
    * @param   i_notes           Decision notes
    * @param   i_dt_modified     Last modified date as provided by get_p1_detail
    * @param   i_mode            (V)alidate date modified or do(N)t
    * @param   i_reason_code     Refusing code (used by the interface)
    * @param   i_subtype         Flag used to mark refusals made by the interface
    * @param   i_inst_dest       New institution identifier, used when changing institution    
    * @param   i_date            Date of status change           
    * @param   o_track           Array of ID_TRACKING transitions
    * @param   o_error           An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.1
    * @since   19-09-2006
    */
    FUNCTION set_status_internal
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_p1         IN p1_external_request.id_external_request%TYPE,
        i_action        IN VARCHAR2,
        i_level         IN p1_external_request.decision_urg_level%TYPE,
        i_prof_dest     IN professional.id_professional%TYPE,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_notes         IN VARCHAR2,
        i_dt_modified   IN VARCHAR2,
        i_mode          IN VARCHAR2,
        i_reason_code   IN p1_reason_code.id_reason_code%TYPE,
        i_subtype       IN VARCHAR2,
        i_inst_dest     IN institution.id_institution%TYPE,
        i_date          IN p1_tracking.dt_tracking_tstz%TYPE,
        o_track         OUT table_number,
        o_flg_show      OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Insert consultation doctor (NO COMMIT)
    *
    * @param   i_lang            Language identifier
    * @param   i_prof            Professional, institution and software
    * @param   i_exr             Referral identifier
    * @param   i_diagnosis       Selected diagnosis
    * @param   i_diag_desc       Diagnosis description, when entered in text mode
    * @param   i_answer          Observation, Therapy, Exam and Conclusion
    * @param   i_date            Operation date
    * @param   i_health_prob      Select Health Problem 
    * @param   i_health_prob_desc Health Problem description, when entered in text mode    
    * @param   o_error           An error message, set when return=false
    *
    * @RETURN  Y if true, N otherwise
    * @author  Joao Sa
    * @version 4.0
    * @since   24-11-2007
    */
    FUNCTION set_request_answer_int
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_exr              IN p1_external_request.id_external_request%TYPE,
        i_diagnosis        IN table_number,
        i_diag_desc        IN table_varchar,
        i_answer           IN table_table_varchar,
        i_date             IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        i_health_prob      IN table_number DEFAULT NULL,
        i_health_prob_desc IN table_varchar DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

END pk_p1_med_hs;
/
