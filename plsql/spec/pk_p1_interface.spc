/*-- Last Change Revision: $Rev: 2028837 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:14 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_p1_interface AS
    /****************************************************************************************
    PROJECT         : ALERT-P1
    PROJECT TEAM    : JOAO SA ( TEAM LEADER, PROJECT ANALYSIS, JAVA MAN ),
                      CARLOS FERREIRA ( PROJECT ANALYSIS, DB MAN ),
                      RUI DIAS ( PROJECT ANALYSIS, FLASH MAN ).
    
    PK CREATED BY   : JOAO SA
    PK DATE CREATION: 11-2006
    PK GOAL         : THIS PACKAGE HAS THE INTERFACE RELATED FUNCTIONS
    
    NOTES/ OBS      : ---
    ******************************************************************************************/

    TYPE p1_request_struct IS RECORD(
        id_patient          patient.id_patient%TYPE,
        id_external_request p1_external_request.id_external_request%TYPE,
        seq_num             p1_match.sequential_number%TYPE,
        --dt_creation         DATE,
        dt_creation_tstz VARCHAR2(14),
        flg_status       p1_external_request.flg_status%TYPE,
        --dt_status           p1_external_request.dt_status%TYPE, -- ex status e dta_recusa
        dt_status_tstz     p1_external_request.dt_status_tstz%TYPE, -- VARCHAR2(14),
        cod_unidade_saude  institution.ext_code%TYPE, -- origem (para implementacoes nao Alert)
        id_inst_orig       institution.id_institution%TYPE, -- novo (para implementacoes Alert)        
        id_inst_dest       institution.id_institution%TYPE, -- destino
        flg_type           p1_external_request.flg_type%TYPE, -- novo
        prof_requested     professional.nick_name%TYPE,
        prof_triage        professional.nick_name%TYPE,
        decision_urg_level p1_external_request.decision_urg_level%TYPE, -- ex urgent
        id_dep_clin_serv   dep_clin_serv.id_dep_clin_serv%TYPE, -- ex id_clinical_service
        summary            VARCHAR2(4000), -- novo
        operation          VARCHAR2(1),
        cod_mot_recusa     VARCHAR2(200));

    TYPE p1_update_struct IS RECORD(
        id_external_request p1_external_request.id_external_request%TYPE,
        id_inst_dest        institution.id_institution%TYPE,
        cod_especialidade   p1_speciality.id_speciality%TYPE,
        cod_service         dep_clin_serv.id_dep_clin_serv%TYPE);

    /**
    * Sets professional interface
    *
    * @param   I_PROF         Professional institution and software
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   17-06-2009
    */
    FUNCTION set_prof_interface(i_prof IN profissional) RETURN profissional;

    /**
    * Sets scheduling Gets request data. Used by the interface that registers the request in the hospital system
    * Notes: DT_SCHEDULE_TSTZ is the schedule creation date (before had the value 00:00:00), DT_BEGIN_TSTZ xx:yy:zz
    *
    * @param   I_LANG              Language identifier
    * @param   I_PROF              Professional id, institution and software for the professional that schedules
    * @param   I_EXT_REQ           Referral identifier
    * @param   I_PROF_SCHED        Professessional id for the appointment physician
    * @param   I_DCS               Appoitment's clinical service
    * @param   I_DATE_TSTZ         Appoitment's date/hour
    * @param   I_OP_DATE_TSTZ      Date of status change   
    * @param   I_TRANSACTION_ID    Remote scheduler transaction id. Can be null . 
    * @param   O_ERROR             an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   19-10-2006
    */
    FUNCTION setscheduling
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ext_req        IN p1_external_request.id_external_request%TYPE,
        i_num_order      IN professional.num_order%TYPE,
        i_prof_name      IN professional.name%TYPE,
        i_dcs            IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_date_tstz      IN VARCHAR2,
        i_op_date_tstz   IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        i_transaction_id IN VARCHAR2 DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Updates scheduling after efectivation
    *
    * @param   I_LANG idioma
    * @param   I_PROF professional id, institution and software for the professional that schedules
    * @param   I_EXT_REQ external request id
    * @param   i_op_date_tstz Date of status change   
    * @param   i_transaction_id SCH 3.0 TRansaction ID . Can be null
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Jo∆o S
    * @version 1.0
    * @since   19-10-2006
    */
    FUNCTION setefectivation
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ext_req        IN p1_external_request.id_external_request%TYPE,
        i_op_date_tstz   IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        i_transaction_id IN VARCHAR2 DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Updates scheduling after efectivation
    * If there is no scheduling, creates it and then does the efectivation
    *
    * @param   I_LANG            Language identifier
    * @param   I_PROF            Professional id, institution and software for the professional that schedules
    * @param   I_EXT_REQ         Referral identifier
    * @param   I_PROF_SCHED      Professessional id for the appointment physician
    * @param   I_DCS             Appoitment's department clinical service
    * @param   I_DATE_TSTZ       Appoitment's date/hour
    * @param   I_OP_DATE_TSTZ    Date of status change
    * @param   i_transaction_id  SCH 3.0 transaction ID. Can be null.
    * @param   O_ERROR           An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Jo∆o S
    * @version 1.0
    * @since   18-05-2007
    */
    FUNCTION setefectivation
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ext_req        IN p1_external_request.id_external_request%TYPE,
        i_num_order      IN professional.num_order%TYPE,
        i_prof_name      IN professional.name%TYPE,
        i_dcs            IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_date_tstz      IN VARCHAR2,
        i_op_date_tstz   IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        i_transaction_id IN VARCHAR2 DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Import Requests registed in SONHO
    *
    * @param   I_LANG                 Language associated to the professional executing the request
    * @param   I_PROF                 Professional id, institution and software    
    * @param   I_INST_ORIG            Origin Ext Code institution    
    * @param   I_ID_DEP_CLIN_SERV     Id department/clinical_service
    * @param   I_FLG_TYPE             Referral type: {*} (C)onsultation {*} (A)nalisys {*} (I)mage {*} (E)xam {*} (P) Intervention {*} (M)fr
    * @param   I_FLG_PRIORITY         Referral priority flag: {*} Y - urgent {*} N - otherwise
    * @param   I_FLG_HOME             Referral home flag: {*} Y - home {*} N - otherwise
    * @param   I_FLG_STATUS           Referral status: {*} (I)ssued {*} (T)riage {*} (A)ccepted {*} (S)cheduled
    * @param   I_DATE                 Appoitment's date/hour (if flg_status = 'S')
    * @param   I_NUM_ORDER_SCH        Scheduled consultation professional num order   
    * @param   I_PROF_NAME_SCH        Scheduled consultation professional name
    * @param   I_EXT_REFERENCE        External reference    
    * @param   I_JUSTIFICATION        Referral justification
    * @param   I_DT_ISSUED            Referral issued date
    * @param   i_dt_triage            Referral triaged date
    * @param   i_dt_accepted          Referral accepted date    
    * @param   i_dt_scheduled         Referral scheduled date
    * @param   I_SEQ_NUM              Match sequential number
    * @param   I_CLIN_REC             Clinical record number
    * @param   I_SNS                  Patient health plan number (SNS)
    * @param   I_NAME                 Patient name
    * @param   I_GENDER               Patient gender
    * @param   I_DT_BIRTH             Patient birth date
    * @param   I_ADDRESS              Patient address
    * @param   I_LOCATION             Patient location
    * @param   I_ZIP_CODE             Patient zip code
    * @param   I_ID_COUNTRY_ADDRESS   Patient country address
    * @param   I_FATHER_NAME          Patient father name
    * @param   I_MOTHER_NAME          Patient mother name   
    * @param   I_NUM_MAIN_CONTACT     Patient main contact number
    * @param   I_MARITAL_STATUS       Patient marital status
    * @param   I_INST_NAME            Origin institution name   
    * @param   I_PROF_NAME            Origin professional name
    * @param   I_TRANSACTION_ID       SCH 3.0 trnsaction id. Can be null.
    *
    * @param   O_ID_EXTERNAL_REQUEST  Referral id
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   06-05-2009
    *
    FUNCTION import_referral
    (
        i_lang IN LANGUAGE.id_language%TYPE,
        i_prof IN profissional,
        -- p1 info         
        i_inst_orig        IN institution.ext_code%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE, -- not null
        i_flg_type         IN p1_external_request.flg_type%TYPE,
        i_flg_priority     IN p1_external_request.flg_priority%TYPE,
        i_flg_home         IN p1_external_request.flg_home%TYPE,
        i_flg_status       IN p1_external_request.flg_status%TYPE, -- not null
        i_date             IN VARCHAR2,
        i_num_order_sch    IN professional.num_order%TYPE,
        i_prof_name_sch    IN professional.name%TYPE,
        i_ext_reference    IN p1_external_request.ext_reference%TYPE,
        i_justification    IN table_varchar,
        i_dt_issued        IN VARCHAR2,
        i_dt_triage        IN VARCHAR2,
        i_dt_accepted      IN VARCHAR2,
        i_dt_scheduled     IN VARCHAR2,
        -- patient info
        i_seq_num             IN p1_match.sequential_number%TYPE,
        i_clin_rec            IN clin_record.num_clin_record%TYPE,
        i_sns                 IN pat_health_plan.num_health_plan%TYPE,
        i_name                IN patient.name%TYPE,
        i_gender              IN patient.gender%TYPE,
        i_dt_birth            IN patient.dt_birth%TYPE,
        i_address             IN pat_soc_attributes.address%TYPE,
        i_location            IN pat_soc_attributes.location%TYPE,
        i_zip_code            IN pat_soc_attributes.zip_code%TYPE,
        i_id_country_address  IN pat_soc_attributes.id_country_address%TYPE,
        i_father_name         IN pat_soc_attributes.father_name%TYPE,
        i_mother_name         IN pat_soc_attributes.mother_name%TYPE,
        i_num_main_contact    IN pat_soc_attributes.num_main_contact%TYPE,
        i_marital_status      IN pat_soc_attributes.marital_status%TYPE,
        i_inst_name           IN pk_translation.t_desc_translation,
        i_prof_name           IN professional.name%TYPE,
        i_transaction_id      IN VARCHAR2 DEFAULT NULL,
        o_id_external_request OUT p1_external_request.id_external_request%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    */

    /**
    * Cancels a request
    *
    * @param   I_LANG idioma
    * @param   I_PROF professional id, institution and software for the professional that schedules
    * @param   I_EXT_REQ external request id
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   19-10-2006
    */
    FUNCTION cancelrequest
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ext_req        IN p1_external_request.id_external_request%TYPE,
        i_notes          IN VARCHAR2,
        i_reason         IN p1_reason_code.id_reason_code%TYPE,
        i_transaction_id IN VARCHAR2 DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Requests that are refused in SONHO
    *
    * @param   i_lang idioma
    * @param   i_prof professional id, institution and software for the professional that schedules
    * @param   i_ext_req external request id
    * @param   i_notes refusal notes
    * @param   i_reason resason code    
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   18-05-2007
    */
    FUNCTION refuserequest
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        i_notes   IN p1_detail.text%TYPE,
        i_reason  IN p1_reason_code.id_reason_code%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels a previous appointment
    *
    * @param   i_lang              Language identifier
    * @param   i_prof              Professional id, institution and software for the professional that schedules
    * @param   i_ext_req           Referral identifier
    * @param   i_date_tstz         Referral appointment date. Is used to check if corresponds to a active appointment (ther's no other way)
    * @param   i_notes             Appointement cancelation notes
    * @param   i_op_date_tstz      Date of status change   
    * @param   i_transaction_id    SCH 3.0 transaction id . Can be null.
    * @param   i_reason_code    Referral reason code        
    * @param   o_error             An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Jo∆o S
    * @version 1.0
    * @since   19-07-2007
    */
    FUNCTION cancelschedule
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ext_req        IN p1_external_request.id_external_request%TYPE,
        i_date_tstz      IN VARCHAR2,
        i_notes          IN VARCHAR2,
        i_op_date_tstz   IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        i_transaction_id IN VARCHAR2 DEFAULT NULL,
        i_reason_code    IN p1_reason_code.id_reason_code%TYPE DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets request data. Used by the interface that registers the request in the hospital system
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   i_ext_req external system id
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ricardo Patrocinio
    * @version 1.0
    * @since   05-02-2009
    * 
    */
    FUNCTION get_request_data
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        o_data    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets request specialty related data. Used by the interface that registers the request in the hospital system
    * Returned data: Request id, Destination Intitution id, Specialty id and Despination Department id
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   i_ext_req external system id
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   19-10-2006
    */
    FUNCTION get_esp_update_data
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        o_data    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets request data when a re-match takes place. Used by the interface that registers the request in the hospital system
    * Returned data: Request Id, Destination Institution Id and Sequencial Number
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   i_id_match external system id
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ricardo Patrocinio
    * @version 1.0
    * @since   05-02-2009
    */
    FUNCTION get_request_data_rematch
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_match IN p1_match.id_match%TYPE,
        o_data     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    --pk_p1_interface.
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
    * @author  Joao S
    * @version 1.0
    * @since   22-02-2008
    */
    FUNCTION set_match
    (
        i_lang     IN language.id_language%TYPE,
        i_pat      IN patient.id_patient%TYPE,
        i_prof     IN profissional,
        i_seq_num  IN p1_match.sequential_number%TYPE,
        i_clin_rec IN clin_record.num_clin_record%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets data from an P1 event generated by set_match
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PAT patient
    * @param   I_PROF professional id, institution and software
    * @param   I_SEQ_NUM external system id
    * @param   I_CLIN_REC patient process number on the institution, if available.
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ricardo Patrocinio
    * @version 1.0
    * @since   03-04-2009
    */
    FUNCTION get_p1_data
    (
        i_lang      IN language.id_language%TYPE,
        i_pat       IN p1_external_request.id_patient%TYPE,
        i_inst_dest IN p1_external_request.id_inst_dest%TYPE,
        o_data      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    TYPE scheduled_requests_rec IS RECORD(
        id_external_request p1_external_request.id_external_request%TYPE,
        dt_schedule         schedule.dt_begin_tstz%TYPE);

    TYPE scheduled_requests_table IS TABLE OF scheduled_requests_rec;

    /**
    * Gets the scheduled requests without triage
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_ext_req external system id
    * @param   O_DATA Cursor with the result of the query, set when return=true
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ricardo Patrocinio
    * @version 1.0
    * @since   03-04-2009
    */
    FUNCTION get_sch_without_triage
    (
        i_lang    IN language.id_language%TYPE,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        o_data    OUT NUMBER,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the scheduled requests in the interval between id_dt_begin and id_dt_end
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   id_dt_begin interval begin
    * @param   id_dt_begin interval end
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   24-04-2008
    */
    FUNCTION get_scheduled_requests
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        id_dt_begin IN VARCHAR2,
        id_dt_end   IN VARCHAR2
    ) RETURN scheduled_requests_table
        PIPELINED;

    /**
    * Get descriptions for provided tables and ids.
    * Used by the interface to get Alert description of mapped ids.
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   i_key  table names and ids, third field used only for sys_domain. (TABLE_NAME, ID[VAL], [CODE_DOMAIN])
    * @param   o_id   result id  description. (ID[VAL])
    * @param   o_desc result description. (Description)    
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   28-10-2008
    */
    FUNCTION get_description
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_key   IN table_table_varchar,
        o_id    OUT table_varchar,
        o_desc  OUT table_varchar,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *
    * Sets the request status to "T": hospital registrar has to send the request to triage.
    *
    * @param   I_LANG         Language associated to the professional executing the request
    * @param   I_PROF         Professional id, institution and software
    * @param   I_ID_EXT_REQ   External request id
    * @param   I_DATE         Date of status change
    * @param   O_ERROR        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   26-06-2009
    */
    FUNCTION set_to_triage
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_ext_req IN p1_external_request.id_external_request%TYPE,
        i_date       IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Triage the request
    * Sets the request status to "A": hospital physician has triaged the request.
    *
    * @param   I_LANG         Language associated to the professional executing the request
    * @param   I_PROF         Professional id, institution and software
    * @param   I_ID_EXT_REQ   External request id
    * @param   I_INST         Institution id    
    * @param   I_DCS          Destination department/clinical_service
    * @param   I_NUM_ORDER    Professional num order for the appointment physician
    * @param   I_PROF_NAME    Professional name for the appointment physician
    * @param   I_LEVEL        Decision urgency level
    * @param   I_DATE         Triage Date   
    * @param   O_ERROR        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   17-06-2009
    */
    FUNCTION triage_request
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_ext_req IN p1_external_request.id_external_request%TYPE,
        i_inst       IN institution.id_institution%TYPE,
        i_dcs        IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_num_order  IN professional.num_order%TYPE,
        i_prof_name  IN professional.name%TYPE,
        i_level      IN p1_external_request.decision_urg_level%TYPE,
        i_date       IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Function to get information for field Reason
    *
    * @param   I_LANG    Language associated to the professional executing the request
    * @param   I_PROF    Professional id, institution and software    
    * @param   i_ext_req       Referral identifier
    *
    * @RETURN  Referral reason 
    * @author  Ana Monteiro
    * @version 1.0
    * @since   21-08-2009
    */
    FUNCTION get_justification
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_req IN p1_external_request.id_external_request%TYPE
    ) RETURN VARCHAR2;

    /**
    * Gets the previous referral dest institution (when there was a change of institution)
    *
    * @param   i_lang            Language identifier
    * @param   i_prof            Professional id, institution and software
    * @param   i_id_ref          Referral identifier
    * @param   o_id_inst         Institution identifier
    * @param   o_error           An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   2010-03-02
    */
    FUNCTION get_prev_dest_inst
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_ref  IN p1_external_request.id_external_request%TYPE,
        o_id_inst OUT p1_external_request.id_inst_dest%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

END pk_p1_interface;
/
