/*-- Last Change Revision: $Rev: 1518489 $*/
/*-- Last Change by: $Author: joana.barroso $*/
/*-- Date of last change: $Date: 2013-10-28 12:19:51 +0000 (seg, 28 out 2013) $*/
CREATE OR REPLACE PACKAGE pk_api_ref_sync IS

    /**
    * Creates a referral request.
    *
    * @param   i_lang               Language associated to the professional executing the request
    * @param   i_prof               Professional performing this operation
    * @param   i_id_ref             Referral Identifier on the central system (PT- ACSS)
    * @param   i_id_patient         Patient Identifier
    * @param   i_speciality         Referral specialty
    * @param   i_inst_dest          Institution dest identifier
    * @param   i_flg_priority       Referral priority. {*} Y - Urgent {*} N - not urgent 
    * @param   i_flg_home           Home consultation? {*} Y - Home consultation {*} N - otherwise
    * @param   i_detail             P1 detail info. For each detail: [detail_type|description], where detail_type is
    *                                     0- Reason, 1- Signs and symptoms, 2- Progress, 3- History, 4- Family history,
    *                                     5- Objective exam, 6- Diagnostic tests, 50- Tasks for scheduling        
    * @param   i_problems           Referral problems to solve. For each problem: [id_diagnosis|desc_diagnosis|begin_date|end_date|notes],
    *                                     Note1: Begin_date and end_date must be in format YYYYMMDDHH24MISS
    *                                     Note2: End_date and notes are not used yet.
    * @param   i_diagnosis          Referral diagnosis. For each diagnosis: [id_diagnosis|desc_diagnosis|begin_date|end_date|notes]
    *                                     Note1: Begin_date and end_date must be in format YYYYMMDDHH24MISS
    *                                     Note2: Begin_date, end_date and notes are not used yet.
    * @param   i_external_sys       External system identifier
    * @param   i_date               Operation date
    * @param   o_id_ref             Referral local identifier
    * @param   o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   05-08-2010
    */
    FUNCTION create_referral_data
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_ref       IN p1_external_request.id_external_request%TYPE,
        i_id_patient   IN p1_external_request.id_patient%TYPE,
        i_speciality   IN p1_speciality.id_speciality%TYPE,
        i_inst_dest    IN institution.id_institution%TYPE,
        i_flg_priority IN p1_external_request.flg_priority%TYPE,
        i_flg_home     IN p1_external_request.flg_home%TYPE,
        i_detail       IN table_table_varchar,
        i_problems     IN table_table_varchar,
        i_diagnosis    IN table_table_varchar,
        i_external_sys IN p1_external_request.id_external_sys%TYPE,
        i_date         IN DATE,
        o_id_ref       OUT p1_external_request.id_external_request%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Updates clinical referral data, and may changes referral status
    *
    * @param   i_lang               Language associated to the professional executing the request
    * @param   i_prof               Professional performing this operation
    * @param   i_id_ref             Referral Identifier         
    * @param   i_flg_priority       Referral priority. {*} Y - Urgent {*} N - not urgent 
    * @param   i_flg_home           Home consultation? {*} Y - Home consultation {*} N - otherwise
    * @param   i_detail             P1 detail info. For each detail: [detail_type|description], where detail_type is
    *                                     0- Reason, 1- Signs and symptoms, 2- Progress, 3- History, 4- Family history,
    *                                     5- Objective exam, 6- Diagnostic tests, 50- Tasks for scheduling        
    * @param   i_problems           Referral problems to solve. For each problem: [id_diagnosis|desc_diagnosis|begin_date|end_date|notes],
    *                                     Note1: Begin_date and end_date must be in format YYYYMMDDHH24MISS
    *                                     Note2: End_date and notes are not used yet.
    * @param   i_diagnosis          Referral diagnosis. For each diagnosis: [id_diagnosis|desc_diagnosis|begin_date|end_date|notes]
    *                                     Note1: Begin_date and end_date must be in format YYYYMMDDHH24MISS
    *                                     Note2: Begin_date, end_date and notes are not used yet.
    * @param   i_date               Operation date
    * @param   o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   04-08-2010
    */
    FUNCTION update_referral_data
    (
        i_lang         IN LANGUAGE.id_language%TYPE,
        i_prof         IN profissional,
        i_id_ref       IN p1_external_request.id_external_request%TYPE,
        i_flg_priority IN p1_external_request.flg_priority%TYPE,
        i_flg_home     IN p1_external_request.flg_home%TYPE,
        i_detail       IN table_table_varchar,
        i_problems     IN table_table_varchar,
        i_diagnosis    IN table_table_varchar,
        i_date         IN DATE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Changes status referral to (T)riage.
    * Note 1: This function do not change referral status to fo(R)warded if it have already been in triage and was forwarded.
    * Note 2: Id_dep_clin_serv is not provided (we have to calculate it)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional performing this operation 
    * @param   i_id_ref         Referral Identifier 
    * @param   i_notes          Status change notes
    * @param   i_date           Status change date
    * @param   o_track          ID_TRACKING of first transition
    * @param   o_error          An error message, set when return=false   
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Almeida
    * @version 1.0
    * @since   27-07-2010
    */
    FUNCTION set_ref_sent_triage
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE,
        i_notes  IN VARCHAR2,
        i_date   IN DATE,
        o_track  OUT p1_tracking.id_tracking%TYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Changes status referral to (A)ccepted
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional performing this operation   
    * @param   i_id_ref         Referral identifier
    * @param   i_notes          Status change notes
    * @param   i_prof_dest      Professional consultation suggested
    * @param   i_dcs            Dep_clin_serv id
    * @param   i_level          Triage decision urgency level
    * @param   i_date           Status change date
    * @param   o_track          ID_TRACKING of first transition
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   02-08-2010
    */
    FUNCTION set_ref_triaged
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_ref    IN p1_external_request.id_external_request%TYPE,
        i_notes     IN p1_detail.text%TYPE,
        i_prof_dest IN professional.id_professional%TYPE,
        i_dcs       IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_level     IN p1_external_request.decision_urg_level%TYPE,
        i_date      IN DATE,
        o_track     OUT p1_tracking.id_tracking%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Changes referral status after scheduling
    * Do NOT update id_schedule (it was already updated by the OutP scheduling function, or is to be updated)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional performing this operation 
    * @param   i_id_ref         Referral Identifier
    * @param   i_dt_appointment Appointment date
    * @param   i_date           Status change date    
    * @param   o_track          ID_TRACKING of first transition
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   02-08-2010
    */
    FUNCTION set_ref_scheduled
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_dt_appointment IN DATE,
        i_date           IN DATE,
        o_track          OUT p1_tracking.id_tracking%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels a previous appointment (referral data only. Schedule is not cancelled in this function)
    * 
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional performing this operation 
    * @param   i_id_ref         Referral Identifier
    * @param   i_dt_appointment Appointment date. Parameter ignored...
    * @param   i_notes          Status change notes
    * @param   i_date           Status change date     
    * @param   i_reason_code    Referral reason code        
    * @param   o_track          ID_TRACKING of first transition
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   02-08-2010
    */
    FUNCTION set_ref_cancel_sch
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_dt_appointment IN DATE,
        i_notes          IN VARCHAR2,
        i_date           IN DATE,
        i_reason_code    IN p1_reason_code.id_reason_code%TYPE DEFAULT NULL,                
        o_track          OUT p1_tracking.id_tracking%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Medical refuse
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional performing this operation 
    * @param   i_id_ref         Referral Identifier 
    * @param   i_date           Status change date      
    * @param   i_notes          Status change notes
    * @param   i_reason_code    Refuse reason code            
    * @param   o_track          ID_TRACKING of first transition
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   02-08-2010
    */
    FUNCTION set_ref_refuse
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN p1_external_request.id_external_request%TYPE,
        i_notes       IN p1_detail.text%TYPE,
        i_reason_code IN p1_reason_code.id_reason_code%TYPE,
        i_date        IN DATE,
        o_track       OUT p1_tracking.id_tracking%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Changes referral clinical service
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional performing this operation 
    * @param   i_id_ref         Referral Identifier      
    * @param   i_dcs            New dep_clin_serv identifier
    * @param   i_notes          Status change notes        
    * @param   i_date           Status change date
    * @param   o_track          ID_TRACKING of first transition
    * @param   o_error          An error message, set when return=false    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   03-08-2010
    */
    FUNCTION set_ref_cs
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE,
        i_dcs    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_notes  IN p1_detail.text%TYPE,
        i_date   IN DATE,
        o_track  OUT p1_tracking.id_tracking%TYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Changes referral status to "E" (efectivation)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional performing this operation 
    * @param   i_id_ref         Referral Identifier
    * @param   i_date           Status change date
    * @param   o_track          ID_TRACKING of first transition
    * @param   o_error          An error message, set when return=false   
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   03-08-2010
    */
    FUNCTION set_ref_efectv
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE,
        i_date   IN DATE,
        o_track  OUT p1_tracking.id_tracking%TYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Insert referral's answer 
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional performing this operation
    * @param   i_id_ref         Referral Identifier           
    * @param   i_diagnosis      Selected diagnosis
    * @param   i_diag_desc      Diagnosis description, when entered in text mode
    * @param   i_answer         Observation, Therapy, Exam and Conclusion
    * @param   i_date           Status change date
    * @param   o_track          ID_TRACKING of first transition
    * @param   o_error          An error message, set when return=false   
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Almeida
    * @version 1.0
    * @since   27-07-2010
    */
    FUNCTION set_ref_answer
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_ref    IN p1_external_request.id_external_request%TYPE,
        i_diagnosis IN table_number,
        i_diag_desc IN table_varchar,
        i_answer    IN table_table_varchar,
        i_date      IN DATE,
        o_track     OUT p1_tracking.id_tracking%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Performs a bureaucratic decline
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional performing this operation
    * @param   i_id_ref         Referral Identifier       
    * @param   i_reason_code    Bureaucratic decline reason code    
    * @param   i_notes          Status change notes   
    * @param   i_date           Status change date    
    * @param   o_track          ID_TRACKING of first transition
    * @param   o_error          An error message, set when return=false         
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   03-08-2010
    */
    FUNCTION set_ref_bur_declined
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN p1_external_request.id_external_request%TYPE,
        i_reason_code IN p1_reason_code.id_reason_code%TYPE,
        i_notes       IN p1_detail.text%TYPE,
        i_date        IN DATE,
        o_track       OUT p1_tracking.id_tracking%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Changes referral status to "F". Means that the patient missed the appointment 
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional performing this operation
    * @param   i_id_ref         Referral Identifier        
    * @param   i_dt_appointment Appointment date. Parameter ignored
    * @param   i_notes          Notes related to the missed appointment   
    * @param   i_date           Status change date      
    * @param   o_track          ID_TRACKING of first transition
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   03-08-2010
    */
    FUNCTION set_ref_failed
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_dt_appointment IN DATE,
        i_notes          IN p1_detail.text%TYPE,
        i_date           IN DATE,
        i_id_reason_code IN p1_reason_code.id_reason_code%TYPE DEFAULT NULL,
        o_track          OUT p1_tracking.id_tracking%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancel referral
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional performing this operation
    * @param   i_id_ref         Referral Identifier
    * @param   i_reason_code    Cancelation reason code
    * @param   i_notes          Status change notes    
    * @param   i_date           Status change date    
    * @param   o_track          ID_TRACKING of first transition
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   03-08-2010
    */
    FUNCTION set_ref_cancel
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN p1_external_request.id_external_request%TYPE,
        i_reason_code IN p1_tracking.id_reason_code%TYPE,
        i_notes       IN p1_detail.text%TYPE,
        i_date        IN DATE,
        o_track       OUT p1_tracking.id_tracking%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Medical decline
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional performing this operation
    * @param   i_id_ref         Referral Identifier
    * @param   i_reason_code    Cancelation reason code
    * @param   i_notes          Status change notes    
    * @param   i_date           Status change date    
    * @param   o_track          ID_TRACKING of first transition
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   03-08-2010
    */
    FUNCTION set_ref_declined
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN p1_external_request.id_external_request%TYPE,
        i_reason_code IN p1_reason_code.id_reason_code%TYPE,
        i_notes       IN p1_detail.text%TYPE,
        i_date        IN DATE,
        o_track       OUT p1_tracking.id_tracking%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Medical decline (by Clinical director)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional performing this operation
    * @param   i_id_ref         Referral Identifier
    * @param   i_reason_code    Cancelation reason code
    * @param   i_notes          Status change notes    
    * @param   i_date           Status change date    
    * @param   o_track          ID_TRACKING of first transition
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 2.6
    * @since   25-03-2011
    */
    FUNCTION set_ref_declined_cd
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN p1_external_request.id_external_request%TYPE,
        i_reason_code IN p1_reason_code.id_reason_code%TYPE,
        i_notes       IN p1_detail.text%TYPE,
        i_date        IN DATE,
        o_track       OUT p1_tracking.id_tracking%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * This function requests a referral cancellation
    *    
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional performing this operation
    * @param   i_id_ref         Referral Identifier
    * @param   i_reason_code    Cancellation reason code
    * @param   i_notes          Status change notes    
    * @param   i_date           Status change date    
    * @param   o_track          ID_TRACKING of first transition
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   16-09-2010
    */
    FUNCTION set_ref_req_cancel
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN p1_external_request.id_external_request%TYPE,
        i_reason_code IN p1_tracking.id_reason_code%TYPE,
        i_notes       IN p1_detail.text%TYPE,
        i_date        IN DATE,
        o_track       OUT p1_tracking.id_tracking%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * This function denies a referral request cancellation.
    * This action can be done by the physician (answering to a registrar request) or can be done by the registrar (cancelling
    * his own cancellation request)
    *    
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional performing this operation
    * @param   i_id_ref         Referral Identifier
    * @param   i_notes          Status change notes    
    * @param   i_date           Status change date    
    * @param   o_track          ID_TRACKING of first transition
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   16-09-2010
    */
    FUNCTION set_ref_req_cancel_deny
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE,
        i_notes  IN p1_detail.text%TYPE,
        i_date   IN DATE,
        o_track  OUT p1_tracking.id_tracking%TYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * This function sends the referral to the dest registrar 
    *    
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional performing this operation
    * @param   i_id_ref         Referral Identifier
    * @param   i_reason_code    Reason code
    * @param   i_notes          Status change notes    
    * @param   i_date           Status change date    
    * @param   o_track          ID_TRACKING of first transition
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   27-10-2010
    */
    FUNCTION set_ref_decline_to_reg
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN p1_external_request.id_external_request%TYPE,
        i_reason_code IN p1_tracking.id_reason_code%TYPE,
        i_notes       IN p1_detail.text%TYPE,
        i_date        IN DATE,
        o_track       OUT p1_tracking.id_tracking%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    * Changes referral status to "V". Means that the referral was approved by clinical director and needs informed consent.
    *    
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional performing this operation
    * @param   i_id_ref         Referral Identifier
    * @param   i_notes          Status change notes    
    * @param   i_date           Status change date    
    * @param   o_track          ID_TRACKING of first transition
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6.0.5
    * @since   23-02-2011
    */
    FUNCTION set_ref_approved
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE,
        i_notes  IN p1_detail.text%TYPE,
        i_date   IN DATE,
        o_track  OUT p1_tracking.id_tracking%TYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

   /** 
    * Cancel a patient no show - undo to last flg_status
    *    
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional performing this operation
    * @param   i_id_ref         Referral Identifier    
    * @param   i_date           Status change date    
    * @param   o_track          ID_TRACKING of first transition
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 2.6.1.3
    * @since   27-Sep-2011
    */
    FUNCTION set_ref_cancel_noshow
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE,
        i_date   IN DATE,
        o_track  OUT p1_tracking.id_tracking%TYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    * Origin registrar attachs informed consent
    *    
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional performing this operation
    * @param   i_id_ref         Referral Identifier
    * @param   i_notes          Status change notes    
    * @param   i_date           Status change date    
    * @param   o_track          ID_TRACKING of first transition
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6.0.5
    * @since   23-02-2011
    */
    FUNCTION attach_informed_consent
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE,
        i_notes  IN p1_detail.text%TYPE,
        i_date   IN DATE,
        o_track  OUT p1_tracking.id_tracking%TYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * This function do Responsibility Transf.
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier                      
    * @param   i_id_prof_dest   Professional to which the referral was transferred to
    * @param   i_id_reason_code Reason code 
    * @param   i_notes          Notes
    * @param   i_date           Operation date
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6.0.5
    * @since   25-02-2011
    */

    FUNCTION transf_referral_responsibility
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_id_prof_dest   IN professional.id_professional%TYPE,
        i_id_reason_code IN p1_reason_code.id_reason_code%TYPE,
        i_notes          IN p1_detail.text%TYPE,
        i_date           IN DATE,
        o_track          OUT p1_tracking.id_tracking%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

END pk_api_ref_sync;
/
