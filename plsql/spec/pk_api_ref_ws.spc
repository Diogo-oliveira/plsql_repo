/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/
CREATE OR REPLACE PACKAGE pk_api_ref_ws AS

    /**
    * Checks if it is a valid reason_code
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Id professional, institution and software    
    * @param   i_id_prof_templ         Profile template identifier of the professional
    * @param   i_reason_code           Referral reason code
    * @param   i_reason_type           Referral type of reason code    
    * @param   o_flg_available         if is a valid reason code    {*} 'Y' - valid reason code 
                                                                    {*} 'N' - otherwise 
    * @param   o_error                 An error message, set when return=false
    *
    * @value   i_reason_type           {*} 'C' - Cancellation {*} 'D' - Sent back by physician {*} 'R' - Refuse {*} 'B' - Sent back by registrar
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   01-10-2009
    */
    FUNCTION check_ref_reason_code
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_prof_templ IN profile_template.id_profile_template%TYPE DEFAULT NULL,
        i_reason_code   IN p1_reason_code.id_reason_code%TYPE,
        i_reason_type   IN p1_reason_code.flg_type%TYPE,
        o_flg_available OUT VARCHAR,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if it is a valid dep_clin_serv for the dest institution
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Id professional, institution and software    
    * @param   i_dcs                   Department + Service
    * @param   i_id_inst_dest          Institution dest identifier    
    * @param   o_flg_available         Flag indicating if i_dcs is a valid dep_clin_serv
    * @param   o_error                 An error message, set when return=false
    *
    * @value   o_flg_available         {*} 'Y' - yes {*} 'N' - no
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6.0.5
    * @since   17-02-2011
    */
    FUNCTION check_dep_clin_serv
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_inst_dest  IN institution.id_institution%TYPE,
        i_dcs           IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_flg_available OUT VARCHAR,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the professional to whom the referral is scheduled
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier
    * @param   o_id_prof        Scheduled professional identifier
    * @param   o_num_order      Scheduled professional num order
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-10-2009
    */
    FUNCTION get_ref_schedule_prof
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_ref    IN p1_external_request.id_external_request%TYPE,
        o_id_prof   OUT professional.id_professional%TYPE,
        o_num_order OUT professional.num_order%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the first id_doc_external of document id_doc_external (last id from table)
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Id professional, institution and software
    * @param   i_id_doc                Active document identifier
    *
    * @RETURN  first doc_external identifier
    * @author  Ana Monteiro
    * @version 1.0
    * @since   20-10-2009
    */
    FUNCTION get_first_doc_external
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_doc IN doc_external.id_doc_external%TYPE
    ) RETURN doc_external.id_doc_external%TYPE;

    /**
    * Returns the last id_doc_external of document id_doc_external (first id from table)
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Id professional, institution and software
    * @param   i_id_doc                First document identifier (outdated)
    *
    * @RETURN  last doc_external identifier
    * @author  Ana Monteiro
    * @version 1.0
    * @since   20-10-2009
    */
    FUNCTION get_last_doc_external
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_doc IN doc_external.id_doc_external%TYPE
    ) RETURN doc_external.id_doc_external%TYPE;

    /**
    * Set the referral status to 'T' (Waiting for triage)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier
    * @param   i_clin_rec       Patient process number on the institution, if available.    
    * @param   i_notes          Notes to the triage physician    
    * @param   i_date           Operation date
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   30-09-2009
    */
    FUNCTION set_ref_sent_triage
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_ref   IN p1_external_request.id_external_request%TYPE,
        i_clin_rec IN clin_record.num_clin_record%TYPE,
        i_notes    IN p1_detail.text%TYPE,
        i_date     IN DATE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Triages the referral request: set referral status to 'A' (Appointment to be scheduled)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier
    * @param   i_clin_rec       Patient process number on the institution, if available.
    * @param   i_num_order      Professional order number that is triaging the referral
    * @param   i_prof_name      Professional name that is triaging the referral   
    * @param   i_level          Triage urgency level        
    * @param   i_notes          Triage decision notes    
    * @param   i_dcs            Department + Service            
    * @param   i_date           Operation date
    * @param   o_track          Tracking identifiers created due to the status change
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   01-10-2009
    */
    FUNCTION set_ref_triaged
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_ref    IN p1_external_request.id_external_request%TYPE,
        i_clin_rec  IN clin_record.num_clin_record%TYPE,
        i_num_order IN professional.num_order%TYPE,
        i_prof_name IN professional.name%TYPE,
        i_level     IN p1_external_request.decision_urg_level%TYPE,
        i_notes     IN p1_detail.text%TYPE,
        i_dcs       IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_date      IN DATE,
        o_track     OUT table_number,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Schedules a referral appointment. Set the referral status to 'S' (Scheduled, Patient to be notified)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier
    * @param   i_num_order      Professional order number that is triaging the referral
    * @param   i_prof_name      Professional name that is triaging the referral   
    * @param   i_dt_appointment Appointment date    
    * @param   i_date           Operation date
    * @param   i_transaction_id SCH 3.0 Transaction id 
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-10-2009
    */
    FUNCTION set_ref_scheduled
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_num_order      IN professional.num_order%TYPE,
        i_prof_name      IN professional.name%TYPE,
        i_dt_appointment IN DATE,
        i_date           IN DATE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancel an appointment. Set the referral status to 'A' (Appointment to be scheduled)
    * 
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier    
    * @param   i_notes          Decision notes
    * @param   i_dt_appointment Active appointment date to be cancelled
    * @param   i_date           Operation date
    * @param   i_reason_code    Referral reason code    
    * @param   i_reason_desc    Decline reason description. Parameter ignored.              
    * @param   o_error          An error message, set when return=false
    * 
    * @RETURN TRUE IF sucess, FALSE otherwise 
    * @author ana monteiro 
    * @version 1.0
    * @since   02-10-2009
    */
    FUNCTION set_ref_cancel_sch
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_dt_appointment IN DATE,
        i_notes          IN p1_detail.text%TYPE,
        i_date           IN DATE,
        i_reason_code    IN p1_reason_code.id_reason_code%TYPE DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Refuses the referral, setting status to 'X' (REFUSE)
    *
    * @param   i_lang                Language associated to the professional executing the request
    * @param   i_prof                Id professional, institution and software    
    * @param   i_id_ref              Referral identifier
    * @param   i_num_order           Professional order number that is refusing the referral
    * @param   i_prof_name           Professional name that is refusing the referral           
    * @param   i_notes               Refusal notes                
    * @param   i_id_reason_code      Refusal reason code identifier
    * @param   i_desc_code_reason    Refusal reason code description. Parameter ignored.   
    * @param   i_date                Operation date
    * @param   o_track               Tracking identifiers created due to the status change
    * @param   o_error               An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   01-10-2009
    */
    FUNCTION set_ref_refused
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_ref           IN p1_external_request.id_external_request%TYPE,
        i_num_order        IN professional.num_order%TYPE,
        i_prof_name        IN professional.name%TYPE,
        i_notes            IN p1_detail.text%TYPE,
        i_id_reason_code   IN p1_reason_code.id_reason_code%TYPE,
        i_desc_code_reason IN p1_reason_code.code_reason%TYPE, -- ignored
        i_date             IN DATE,
        o_track            OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Change Referral dep_clin_serv 
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier
    * @param   i_num_order      Professional order number that changed clinical service
    * @param   i_prof_name      Professional name that changed clinical service
    * @param   i_dcs            Dep_clin_serv           
    * @param   i_notes          Refuse notes                
    * @param   i_date           Operation date
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   02-10-2009
    */
    FUNCTION set_ref_cs
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_ref    IN p1_external_request.id_external_request%TYPE,
        i_num_order IN professional.num_order%TYPE,
        i_prof_name IN professional.name%TYPE,
        i_dcs       IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_notes     IN p1_detail.text%TYPE,
        i_date      IN DATE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Changes referral dest institution
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier
    * @param   i_num_order      Professional order number that changed clinical service
    * @param   i_prof_name      Professional name that changed clinical service
    * @param   i_id_inst_dest   New dest institution
    * @param   i_dcs            New Dep_clin_serv belonging to the new dest institution
    * @param   i_date           Operation date
    * @param   o_track          Array of tracking identifiers created
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   11-07-2013
    */
    FUNCTION set_ref_change_inst
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_ref       IN p1_external_request.id_external_request%TYPE,
        i_num_order    IN professional.num_order%TYPE,
        i_prof_name    IN professional.name%TYPE,
        i_id_inst_dest IN p1_external_request.id_inst_dest%TYPE,
        i_dcs          IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_date         IN DATE,
        o_track        OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Change Referral dep_clin_serv 
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier           
    * @param   i_num_order      Professional order number that is triaging the referral
    * @param   i_prof_name      Professional name that is triaging the referral           
    * @param   i_date           Operation date
    * @param   i_transaction_id SCH 3.0 Ref ID 
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   02-10-2009
    */
    FUNCTION set_ref_efectiv
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_ref    IN p1_external_request.id_external_request%TYPE,
        i_num_order IN professional.num_order%TYPE,
        i_prof_name IN professional.name%TYPE,
        i_date      IN DATE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Consultation physician answers the referral request
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier           
    * @param   i_num_order      Professional order number that is triaging the referral
    * @param   i_prof_name      Professional name that is triaging the referral
    * @param   i_diag_array     [i_diag_flg_type|i_diag_code|i_diag_desc|i_diag_notes]
    * @param   i_answer_array                  
    * @param   i_date           Operation date
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   02-10-2009
    */
    FUNCTION set_ref_answer
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_ref       IN p1_external_request.id_external_request%TYPE,
        i_num_order    IN professional.num_order%TYPE,
        i_prof_name    IN professional.name%TYPE,
        i_diag_array   IN table_table_varchar,
        i_answer_array IN table_table_varchar,
        i_date         IN DATE,
        o_error        OUT t_error_out
        
    ) RETURN BOOLEAN;

    /**
    * Sents referral back by administrative clerk, setting the referral status to 'B'
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software from the Interface
    * @param   i_id_ref         Referral identifier
    * @param   i_reason_code    Decline reason code identifier    
    * @param   i_reason_desc    Decline reason description. Parameter ignored.  
    * @param   i_notes          Administrative refusal notes
    * @param   i_date           Operation date
    * @param   o_track          Array of tracking identifiers created
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Almeida
    * @version 1.0
    * @since   30-09-2009
    */
    FUNCTION set_ref_bur_declined
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN p1_external_request.id_external_request%TYPE,
        i_reason_code IN p1_reason_code.id_reason_code%TYPE,
        i_reason_desc IN translation.code_translation%TYPE,
        i_notes       IN p1_detail.text%TYPE,
        i_date        IN DATE,
        o_track       OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Patient missed the appointment, setting the referral status to 'F'
    *
    * @param   i_lang         Language identifier associated to the professional executing the request
    * @param   i_prof         Professional id, institution and software
    * @param   i_id_ref       Referral identifier
    * @param   i_notes        Notes related to the missed appointment
    * @param   i_date         Operation date    
    * @param   i_REASON_CODE     Reason code 
    * @param   i_reason type     Reason code 
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   13-05-2010
    */
    FUNCTION set_ref_failed
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_notes          IN p1_detail.text%TYPE,
        i_date           IN DATE,
        i_id_reason_code IN p1_reason_code.id_reason_code%TYPE DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels the referral
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier    
    * @param   i_num_order      Professional order number who is canceling the referral
    * @param   i_prof_name      Professional name who is canceling the referral
    * @param   i_reason_code    Cancel reason code identifier    
    * @param   i_reason_desc    Cancel reason description. Parameter ignored.   
    * @param   i_notes          Cancelation notes
    * @param   i_date           Operation date
    * @param   i_transaction_id SCH 3.0 Transaction id    
    * @param   o_track          Tracking identifiers created due to the status change
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   30-04-2010
    */
    FUNCTION set_ref_cancel
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_num_order      IN professional.num_order%TYPE,
        i_prof_name      IN professional.name%TYPE,
        i_reason_code    IN p1_reason_code.id_reason_code%TYPE,
        i_reason_desc    IN translation.code_translation%TYPE,
        i_notes          IN p1_detail.text%TYPE,
        i_date           IN DATE,
        i_transaction_id IN VARCHAR2,
        o_track          OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels the referral
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier    
    * @param   i_num_order      Professional order number who is canceling the referral
    * @param   i_prof_name      Professional name who is canceling the referral
    * @param   i_reason_code    Cancel reason code identifier    
    * @param   i_reason_desc    Cancel reason description. Parameter ignored.   
    * @param   i_notes          Cancelation notes
    * @param   i_date           Operation date
    * @param   o_track          Tracking identifiers created due to the status change
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   30-04-2010
    */
    FUNCTION set_ref_cancel
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN p1_external_request.id_external_request%TYPE,
        i_num_order   IN professional.num_order%TYPE,
        i_prof_name   IN professional.name%TYPE,
        i_reason_code IN p1_reason_code.id_reason_code%TYPE,
        i_reason_desc IN translation.code_translation%TYPE,
        i_notes       IN p1_detail.text%TYPE,
        i_date        IN DATE,
        o_track       OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Declines the referral setting status to 'D' (Sent back due to lack of data)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software from the Interface
    * @param   i_id_ref         Referral identifier
    * @param   i_num_order      unique number for the physician that is returning the referral
    * @param   i_prof_name      name of the physician that is returning the referral
    * @param   i_reason_code    Decline reason code identifier    
    * @param   i_reason_desc    Decline reason description. Parameter ignored.
    * @param   i_notes          Decision notes
    * @param   i_date           Operation date
    * @param   o_track          Tracking identifiers created due to the status change
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Almeida
    * @version 1.0
    * @since   30-09-2009
    */
    FUNCTION set_ref_declined
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN p1_external_request.id_external_request%TYPE,
        i_num_order   IN professional.num_order%TYPE,
        i_prof_name   IN professional.name%TYPE,
        i_reason_code IN p1_reason_code.id_reason_code%TYPE,
        i_reason_desc IN translation.code_translation%TYPE,
        i_notes       IN p1_detail.text%TYPE,
        i_date        IN DATE,
        o_track       OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Declines the referral setting status to 'Y' (Sent back  by clinical director due to lack of data)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software from the Interface
    * @param   i_id_ref         Referral identifier
    * @param   i_num_order      unique number for the physician that is returning the referral
    * @param   i_prof_name      name of the physician that is returning the referral
    * @param   i_reason_code    Decline reason code identifier    
    * @param   i_reason_desc    Decline reason description. Parameter ignored.
    * @param   i_notes          Decision notes
    * @param   i_date           Operation date
    * @param   o_track          Tracking identifiers created due to the status change
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   28-03-2011
    */
    FUNCTION set_ref_declined_cd
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN p1_external_request.id_external_request%TYPE,
        i_num_order   IN professional.num_order%TYPE,
        i_prof_name   IN professional.name%TYPE,
        i_reason_code IN p1_reason_code.id_reason_code%TYPE,
        i_reason_desc IN translation.code_translation%TYPE,
        i_notes       IN p1_detail.text%TYPE,
        i_date        IN DATE,
        o_track       OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Declines the referral to the registrar, setting status to 'I' (issued)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software from the Interface
    * @param   i_id_ref         Referral identifier
    * @param   i_num_order      unique number for the physician that is returning the referral
    * @param   i_prof_name      name of the physician that is returning the referral
    * @param   i_reason_code    Decline reason code identifier    
    * @param   i_reason_desc    Decline reason description. Parameter ignored.
    * @param   i_notes          Decision notes
    * @param   i_date           Operation date
    * @param   o_track          Tracking identifiers created due to the status change
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6.0.5
    * @since   18-03-2011
    */
    FUNCTION set_ref_declined_to_reg
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN p1_external_request.id_external_request%TYPE,
        i_num_order   IN professional.num_order%TYPE,
        i_prof_name   IN professional.name%TYPE,
        i_reason_code IN p1_reason_code.id_reason_code%TYPE,
        i_reason_desc IN translation.code_translation%TYPE,
        i_notes       IN p1_detail.text%TYPE,
        i_date        IN DATE,
        o_track       OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Editing a document to put it in a received state
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software from the Interface
    * @param   i_id_ref         Referral identifier
    * @param   i_id_doc         Document identifier (first id_doc_external)
    * @param   i_flg_received   the file was received or not: {*} Y - yes {*} N - no
    * @param   i_date           date of the operation
    * @param   o_error_code     Referral error code, set when return=false
    * @param   o_error_desc     Referral error description, set when return=false
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Almeida
    * @version 1.0
    * @since   06-10-2009
    */
    FUNCTION set_ref_doc_edit
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_ref       IN p1_external_request.id_external_request%TYPE,
        i_id_doc       IN doc_external.id_doc_external%TYPE,
        i_flg_received IN doc_external.flg_received%TYPE,
        i_date         IN DATE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the last referral notes related to the transition specified
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_id_ref         Referral identifier
    * @param   i_notes_type     Type of referral notes
    * @param   o_notes_text     Notes description
    * @param   o_error          An error message, set when return=false
    *
    * @value   i_notes_type     {*} 'C' Cancelation notes 
                                                         {*} 'B' Notes when sending back by administrative clerk 
                                                         {*} 'D' Notes when sending back by the hosp. physician
                                                         {*} 'X' Notes when refusing referral
                                                         {*} 'A1' Notes when triaging referral
                                                         {*} 'A2' Notes when canceling referral schedule                                                         
                                                         {*} 'F' Notes when patient missed the appointment 
                                {*} 'T' Notes when registrar sents the referral to triage
                                {*} 'I1' Notes when orig registrar issues the referral
                                {*} 'I2' Notes when dest triage physician declines the referral to the registrar
                                {*} 'L' Notes when the referral is locked
                                {*} 'Z' Notes when the registrar requests the referral cancellation
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   2010-04-15
    */
    FUNCTION get_last_notes
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_ref     IN p1_external_request.id_external_request%TYPE,
        i_notes_type IN VARCHAR2,
        o_notes_text OUT p1_detail.text%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    ----------------------------------------------------------------------
    -- Integration With OUTPATIENT
    ----------------------------------------------------------------------

    /**
    * Forwards the referral request to a triage physician: set referral status to 'R' (Re-sent)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier
    * @param   i_num_order      Professional order number that is forwarding the referral
    * @param   i_prof_name      Professional name that is forwarding the referral   
    * @param   i_dest_num_order Professional order number to whom the referral is being forwarded
    * @param   i_dest_prof_name Professional name to whom the referral is being forwarded        
    * @param   i_notes          Triage decision notes            
    * @param   i_date           Operation date
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   29-06-2010
    */
    FUNCTION set_ref_forward
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_num_order      IN professional.num_order%TYPE,
        i_prof_name      IN professional.name%TYPE,
        i_dest_num_order IN professional.num_order%TYPE,
        i_dest_prof_name IN professional.name%TYPE,
        i_notes          IN p1_detail.text%TYPE,
        i_date           IN DATE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Notifies the patient of the referral appointment. Set the referral status to 'M' (Patient notified)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier
    * @param   i_date           Operation date
    * @param   i_transaction_id SCH 3.0 Transaction id 
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   29-06-2010
    */
    FUNCTION set_ref_notified
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE,
        i_date   IN DATE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Sets referral status to 'K' (Reply read)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier    
    * @param   i_num_order      Professional order number who is canceling the referral
    * @param   i_prof_name      Professional name who is canceling the referral
    * @param   i_date           Operation date    
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   29-06-2010
    */
    FUNCTION set_ref_answer_read
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_ref    IN p1_external_request.id_external_request%TYPE,
        i_num_order IN professional.num_order%TYPE,
        i_prof_name IN professional.name%TYPE,
        i_date      IN DATE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Blocks the referral: set referral status to 'L' (bLocked)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier
    * @param   i_notes          Triage decision notes            
    * @param   i_date           Operation date
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   29-06-2010
    */
    FUNCTION set_ref_blocked
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE,
        i_notes  IN p1_detail.text%TYPE,
        i_date   IN DATE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Unblocks the referral: set referral status to the previous status before b(L)ocked
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier
    * @param   i_notes          Triage decision notes            
    * @param   i_date           Operation date
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   29-06-2010
    */
    FUNCTION set_ref_unblocked
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE,
        i_notes  IN p1_detail.text%TYPE,
        i_date   IN DATE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * This function requests a referral cancellation.
    * Changes referral status to 'Z'.
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier                      
    * @param   i_id_reason_code Reason code identifier
    * @param   i_notes          Notes of the cancellation request
    * @param   i_date           Operation date
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   17-09-2010
    */
    FUNCTION set_ref_req_cancel
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_id_reason_code IN p1_reason_code.id_reason_code%TYPE,
        i_notes          IN p1_detail.text%TYPE,
        i_date           IN DATE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * This function denies a referral request cancellation.
    * This action can be done by the physician (answering to a registrar request) or can be done by the registrar (cancelling
    * his own cancellation request)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier                      
    * @param   i_num_order      Professional order number who performing this action (in case of a physician)
    * @param   i_prof_name      Professional name who performing this action
    * @param   i_notes          Notes of the cancellation request
    * @param   i_date           Operation date
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   17-09-2010
    */
    FUNCTION set_ref_req_cancel_deny
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_ref    IN p1_external_request.id_external_request%TYPE,
        i_num_order IN professional.num_order%TYPE,
        i_prof_name IN professional.name%TYPE,
        i_notes     IN p1_detail.text%TYPE,
        i_date      IN DATE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * This function do Responsability Transf.
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier                      
    * @param   i_prof_req       Professional that is requesting referral transf resp
    * @param   i_id_prof_dest   Professional to which the referral was transferred to
    * @param   i_id_reason_code Reason code 
    * @param   i_notes          Notes
    * @param   i_date           Operation date
    * @param   o_track          Tracking identifiers created due to the status change
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Filipe Sousa
    * @version 2.6
    * @since   17-09-2010
    */
    FUNCTION transf_referral_responsability
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_prof_req       IN professional.num_order%TYPE,
        i_prof_dest      IN professional.num_order%TYPE,
        i_id_reason_code IN p1_reason_code.id_reason_code%TYPE,
        i_notes          IN p1_detail.text%TYPE,
        i_date           IN DATE,
        o_track          OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    ----------------------------------
    -- Functions to be performed at origin institution
    ----------------------------------

    /**
    * Called after updating patient data. This will trigger a status update of all referrals of this patient
    *
    * @param   i_lang       Language associated to the professional executing the request
    * @param   i_prof       Professional, institution and software ids
    * @param   i_id_patient Patient identifier
    * @param   i_date           Operation date
    * @param   o_error      An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6.0.5
    * @since   16-02-2011
    */
    FUNCTION update_pat_ref
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_date       IN DATE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if this referral is the correct referral to be updated 
    *
    * @param   i_lang            Language identifier
    * @param   i_prof            Professional, institution and software ids
    * @param   i_id_ref          Referral identifier
    * @param   i_old_flg_type    Referral old type
    * @param   i_old_id_workflow Referral old workflow identifier
    * @param   i_old_id_pat      Referral old patient identifier
    * @param   i_old_inst_dest   Referral old data dest institution
    * @param   i_old_id_spec     Referral old speciality
    * @param   i_old_id_dcs      Referral old dep_clin_serv
    * @param   i_old_id_ext_sys  Referral old external sys
    * @param   i_old_flg_status  Referral status    
    * @param   i_new_flg_type    Referral new type
    * @param   i_new_id_workflow Referral new workflow identifier
    * @param   i_new_id_pat      Referral new patient identifier
    * @param   i_new_inst_dest   Referral new data dest institution
    * @param   i_new_id_spec     Referral new speciality
    * @param   i_new_id_dcs      Referral new dep_clin_serv
    * @param   i_new_id_ext_sys  Referral new external sys    
    * @param   o_flg_valid       Flag indicating if this referral is the correct referral to be updated
    * @param   o_error           An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6.0.5
    * @since   18-02-2011
    */
    FUNCTION check_referral_update
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_ref          IN p1_external_request.id_external_request%TYPE,
        i_old_flg_type    IN p1_external_request.flg_type%TYPE,
        i_old_id_workflow IN p1_external_request.id_workflow%TYPE,
        i_old_id_pat      IN p1_external_request.id_patient%TYPE,
        i_old_inst_dest   IN p1_external_request.id_inst_dest%TYPE,
        i_old_id_spec     IN p1_external_request.id_speciality%TYPE,
        i_old_id_dcs      IN p1_external_request.id_dep_clin_serv%TYPE,
        i_old_id_ext_sys  IN p1_external_request.id_external_sys%TYPE,
        i_old_flg_status  IN p1_external_request.flg_status%TYPE,
        i_new_flg_type    IN p1_external_request.flg_type%TYPE,
        i_new_id_workflow IN p1_external_request.id_workflow%TYPE,
        i_new_id_pat      IN p1_external_request.id_patient%TYPE,
        i_new_inst_dest   IN p1_external_request.id_inst_dest%TYPE,
        i_new_id_spec     IN p1_external_request.id_speciality%TYPE,
        i_new_id_dcs      IN p1_external_request.id_dep_clin_serv%TYPE,
        i_new_id_ext_sys  IN p1_external_request.id_external_sys%TYPE,
        o_flg_valid       OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates the referral
    *
    * @param   i_lang               Language associated to the professional executing the request
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Workflow identifier
    * @param   i_num_order          Professional num order that is creating the referral
    * @param   i_prof_name          Professional name that is creating the referral. If referral is at Hospital Entrance, this is the name considered
    * @param   i_id_patient         Patient identifier
    * @param   i_speciality         Referral speciality (P1_SPECIALITY)
    * @param   i_dcs                Id department/clinical_service (can be null)
    * @param   i_flg_priority       Urgent/not urgent
    * @param   i_flg_home           Home consultation?
    * @param   i_id_inst_orig       Institution origin identifier
    * @param   i_inst_orig_name     Institution origin name. If referral is at Hospital Entrance, this is the name considered
    * @param   i_id_inst_dest       Destination institution identifier
    * @param   i_p_flg_type         Problem array codification type: ICD9, ICD10, ICPC2...
    * @param   i_p_code_icd         Problem array code (code_icd)
    * @param   i_p_desc_problem     Problem array name
    * @param   i_p_year_begin       Problem array begin year. Format YYYY   
    * @param   i_p_month_begin      Problem array begin month. Format MM
    * @param   i_p_day_begin        Problem array begin day. Format DD
    * @param   i_d_flg_type         Diagnosis array codification type: ICD9, ICD10, ICPC2...
    * @param   i_d_code_icd         Diagnosis array code (code_icd)
    * @param   i_d_desc_diagnosis   Diagnosis array name
    * @param   i_detail             Referral detail info. For each detail: [idx,[detail_type|text]]
    * @param   i_id_external_sys    External system identifier
    * @param   i_date               Operation date
    * @param   o_id_ref             Referral identifier
    * @param   o_error              An error message, set when return=false
    *
    * @value   i_flg_priority       {*} 'Y' - Urgent {*} 'N' - Not urgent
    * @value   i_flg_home           {*} 'Y' - Home consultation {*} 'N' - Hospital consultation
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6.0.5
    * @since   17-02-2011
    */
    FUNCTION create_referral
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_workflow       IN p1_external_request.id_workflow%TYPE,
        i_num_order      IN professional.num_order%TYPE,
        i_prof_name      IN professional.name%TYPE,
        i_id_patient     IN p1_external_request.id_patient%TYPE,
        i_speciality     IN p1_external_request.id_speciality%TYPE,
        i_dcs            IN p1_external_request.id_dep_clin_serv%TYPE,
        i_flg_priority   IN p1_external_request.flg_priority%TYPE,
        i_flg_home       IN p1_external_request.flg_home%TYPE,
        i_id_inst_orig   IN p1_external_request.id_inst_orig%TYPE,
        i_inst_orig_name IN VARCHAR2,
        i_id_inst_dest   IN institution.id_institution%TYPE,
        -- problems data
        i_p_flg_type     IN table_varchar, -- ICD9, ICPC2, ICD10...
        i_p_code_icd     IN table_varchar,
        i_p_desc_problem IN table_varchar,
        --i_p_dt_begin     IN table_varchar,
        i_p_year_begin  IN table_number, -- YYYY
        i_p_month_begin IN table_number, -- MM
        i_p_day_begin   IN table_number, -- DD
        -- diagnosis data
        i_d_flg_type       IN table_varchar, -- ICD9, ICPC2, ICD10...
        i_d_code_icd       IN table_varchar,
        i_d_desc_diagnosis IN table_varchar,
        -- clinical info
        i_detail          IN table_table_varchar,
        i_id_external_sys IN p1_external_request.id_external_sys%TYPE,
        i_date            IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_comments        IN table_table_clob, -- ID ref comment, Flg Status, texto        
        o_id_ref          OUT p1_external_request.id_external_request%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Updates the referral
    *
    * @param   i_lang               Language associated to the professional executing the request
    * @param   i_prof               Professional, institution and software ids
    * @param   i_id_ref             Referral identifier   
    * @param   i_workflow           Workflow identifier. Used to check if this is the correct referral to be updated.
    * @param   i_num_order          Professional num order that is updating the referral. Ignored when the referral is at Hospital Entrance.
    * @param   i_prof_name          Professional name that is updating the referral
    * @param   i_id_patient         Patient identifier. Used to check if this is the correct referral to be updated.
    * @param   i_speciality         Referral speciality (P1_SPECIALITY). Used to check if this is the correct referral to be updated.
    * @param   i_dcs                Id department/clinical_service. Defined when the referral is inside the Hospital. Used to check if this is the correct referral to be updated.
    * @param   i_flg_priority       Urgent/not urgent
    * @param   i_flg_home           Home consultation?
    * @param   i_id_inst_orig       Institution origin identifier. Used to check if this is the correct referral to be updated.
    * @param   i_inst_orig_name     Institution origin name. Used to check if this is the correct referral to be updated.
    * @param   i_id_inst_dest       Destination institution identifier. Used to check if this is the correct referral to be updated.
    * @param   i_p_flg_type         Problem array codification type: ICD9, ICD10, ICPC2...
    * @param   i_p_code_icd         Problem array code (code_icd)
    * @param   i_p_desc_problem     Problem array name
    * @param   i_p_year_begin       Problem array begin year. Format YYYY   
    * @param   i_p_month_begin      Problem array begin month. Format MM
    * @param   i_p_day_begin        Problem array begin day. Format DD
    * @param   i_d_flg_type         Diagnosis array codification type: ICD9, ICD10, ICPC2...
    * @param   i_d_code_icd         Diagnosis array code (code_icd)
    * @param   i_d_desc_diagnosis   Diagnosis array name
    * @param   i_detail             Referral detail info. For each detail: [idx,[detail_type|text]]
    * @param   i_id_external_sys    External system identifier. Used to check if this is the correct referral to be updated.
    * @param   i_date               Operation date
    * @param   o_id_ref             Referral identifier
    * @param   o_error              An error message, set when return=false
    *
    * @value   i_flg_priority       {*} 'Y' - Urgent {*} 'N' - Not urgent
    * @value   i_flg_home           {*} 'Y' - Home consultation {*} 'N' - Hospital consultation
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6.0.5
    * @since   18-02-2011
    */
    FUNCTION update_referral
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_workflow       IN p1_external_request.id_workflow%TYPE,
        i_num_order      IN professional.num_order%TYPE,
        i_prof_name      IN professional.name%TYPE,
        i_id_patient     IN p1_external_request.id_patient%TYPE,
        i_speciality     IN p1_external_request.id_speciality%TYPE,
        i_dcs            IN p1_external_request.id_dep_clin_serv%TYPE,
        i_flg_priority   IN p1_external_request.flg_priority%TYPE,
        i_flg_home       IN p1_external_request.flg_home%TYPE,
        i_id_inst_orig   IN p1_external_request.id_inst_orig%TYPE,
        i_inst_orig_name IN VARCHAR2,
        i_id_inst_dest   IN institution.id_institution%TYPE,
        -- problems data
        i_p_flg_type     IN table_varchar, -- ICD9, ICPC2, ICD10...
        i_p_code_icd     IN table_varchar,
        i_p_desc_problem IN table_varchar,
        --i_p_dt_begin     IN table_varchar,
        i_p_year_begin  IN table_number, -- YYYY
        i_p_month_begin IN table_number, -- MM
        i_p_day_begin   IN table_number, -- DD
        -- diagnosis data
        i_d_flg_type       IN table_varchar, -- ICD9, ICPC2, ICD10...
        i_d_code_icd       IN table_varchar,
        i_d_desc_diagnosis IN table_varchar,
        -- clinical info
        i_detail          IN table_table_varchar,
        i_id_external_sys IN p1_external_request.id_external_sys%TYPE,
        i_date            IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_comments        IN table_table_clob, -- ID ref comment, Flg Status, texto                
        o_id_ref          OUT p1_external_request.id_external_request%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Origin registrar resends referral, after it has been sent back to the origin institution 
    *
    * @param   i_lang               Language associated to the professional executing the request
    * @param   i_prof               Professional, institution and software ids
    * @param   i_id_ref             Referral identifier   
    * @param   i_date               Operation date
    * @param   o_track              Tracking identifiers created due to the status change
    * @param   o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6.0.5
    * @since   21-02-2011
    */
    FUNCTION resend_referral
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE,
        i_date   IN DATE,
        o_track  OUT table_number,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Clinical director approves the referral
    *
    * @param   i_lang               Language associated to the professional executing the request
    * @param   i_prof               Professional, institution and software ids
    * @param   i_id_ref             Referral identifier
    * @param   i_num_order          Professional num order that is approving the referral
    * @param   i_prof_name          Professional name that is approving the referral
    * @param   i_notes              Approval notes
    * @param   i_date               Operation date
    * @param   o_track              Tracking identifiers created due to the status change
    * @param   o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6.0.5
    * @since   22-02-2011
    */
    FUNCTION set_ref_approved
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_ref    IN p1_external_request.id_external_request%TYPE,
        i_num_order IN professional.num_order%TYPE,
        i_prof_name IN professional.name%TYPE,
        i_notes     IN p1_detail.text%TYPE,
        i_date      IN DATE,
        o_track     OUT table_number,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Clinical director does not approves the referral
    *
    * @param   i_lang               Language associated to the professional executing the request
    * @param   i_prof               Professional, institution and software ids
    * @param   i_id_ref             Referral identifier
    * @param   i_num_order          Professional num order that is performing this operation
    * @param   i_prof_name          Professional name that is performing this operation
    * @param   i_notes              Rejection notes
    * @param   i_date               Operation date
    * @param   o_track              Tracking identifiers created due to the status change
    * @param   o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6.0.5
    * @since   22-02-2011
    */
    FUNCTION set_ref_not_approved
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_ref    IN p1_external_request.id_external_request%TYPE,
        i_num_order IN professional.num_order%TYPE,
        i_prof_name IN professional.name%TYPE,
        i_notes     IN p1_detail.text%TYPE,
        i_date      IN DATE,
        o_track     OUT table_number,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    * @param   i_lang               Language associated to the professional executing the request
    * @param   i_prof               Professional, institution and software ids
    * @param   i_id_ref             Referral identifier
    * @param   i_num_order          Professional num order that is performing this operation
    * @param   i_prof_name          Professional name that is performing this operation
    * @param   i_date               Operation date
    * @param   o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 2.6.1.3
    * @since   28-Sep-2011
    */
    FUNCTION set_ref_cancel_noshow
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_ref    IN p1_external_request.id_external_request%TYPE,
        i_num_order IN professional.num_order%TYPE,
        i_prof_name IN professional.name%TYPE,
        i_date      IN DATE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Origin registrar attachs informed consent.    
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software from the Interface
    * @param   i_id_ref         Referral identifier  
    * @param   i_notes          Registrar notes
    * @param   i_date           Operation date
    * @param   o_track          Tracking identifiers created due to the status change
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
        o_track  OUT table_number,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets flag availability based on id_workflow, origin institution and dest institution (if available)
    *
    * @param   i_id_workflow    Referral workflow identifier
    * @param   i_id_inst_orig   Referral origin institution identifier
    * @param   i_id_inst_dest   Referral dest institution identifier
    *
    * @RETURN  Flag availability
    * @author  Ana Monteiro
    * @version 1.0
    * @since   17-11-2011
    */
    FUNCTION get_flg_availability
    (
        i_id_workflow  IN p1_external_request.id_workflow%TYPE,
        i_id_inst_orig p1_external_request.id_inst_orig%TYPE DEFAULT NULL,
        i_id_inst_dest p1_external_request.id_inst_dest%TYPE DEFAULT NULL
    ) RETURN p1_spec_dep_clin_serv.flg_availability%TYPE;

    /**
    * Returns referral specialities
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Id professional, institution and software from the Interface
    * @param   i_id_external_sys   External system identifier
    * @param   i_id_workflow       Referral workflow
    * @param   i_id_inst_orig      Origin institution identifier
    * @param   i_pat_gender        Patient gender
    * @param   i_pat_age           Patient age
    * @param   o_ref_data          Referral specialities or dep_clin_servs data (depends on id_workflow): ID + DESC
    * @param   o_error             An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-11-2011
    */
    FUNCTION get_referral_specialities
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_external_sys IN p1_external_request.id_external_sys%TYPE,
        i_id_workflow     IN p1_external_request.id_workflow%TYPE,
        i_id_inst_orig    IN p1_external_request.id_inst_orig%TYPE,
        i_pat_gender      IN patient.gender%TYPE,
        i_pat_age         IN patient.age%TYPE,
        o_ref_data        OUT NOCOPY t_coll_ref_speciality,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns referral institutions for the workflow and speciality defined
    * Note: not used for wf=g_wf_x_hosp (professional is already at dest institution)
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Id professional, institution and software from the Interface
    * @param   i_id_external_sys   External system identifier
    * @param   i_id_workflow       Referral workflow
    * @param   i_id_inst_orig      Origin institution identifier. When "At hospital entrance" workflow this parameter is ignored.
    * @param   i_id_speciality     Speciality identifier
    * @param   o_ref_data          Referral specialities or dep_clin_servs data (depends on id_workflow): ID + DESC
    * @param   o_error             An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-11-2011
    */
    FUNCTION get_referral_network
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_external_sys IN p1_external_request.id_external_sys%TYPE,
        i_id_workflow     IN p1_external_request.id_workflow%TYPE,
        i_id_inst_orig    IN p1_external_request.id_inst_orig%TYPE,
        i_id_speciality   IN p1_external_request.id_speciality%TYPE,
        o_ref_data        OUT NOCOPY t_coll_ref_network,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns referral institutions/specialities available for referring, of the Hospital complex from which i_id_inst_dest belongs
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Id professional, institution and software from the Interface
    * @param   i_id_external_sys   External system identifier
    * @param   i_id_workflow       Referral workflow
    * @param   i_id_inst_dest      Institution belonging to the Hospital Complex
    * @param   o_ref_data          Referral specialities or dep_clin_servs data (depends on id_workflow): ID + DESC
    * @param   o_error             An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-11-2011
    */
    FUNCTION get_all_referral_network
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_external_sys IN p1_external_request.id_external_sys%TYPE,
        i_id_workflow     IN p1_external_request.id_workflow%TYPE,
        i_id_inst_dest    IN p1_external_request.id_inst_dest%TYPE,
        o_ref_data        OUT NOCOPY t_coll_ref_all_network,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns referral dep_clin_servs (for internal workflows)
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Id professional, institution and software from the Interface
    * @param   i_id_external_sys   External system identifier
    * @param   i_id_inst_orig      Origin institution identifier
    * @param   i_num_order         Professional num order
    * @param   i_pat_gender        Patient gender
    * @param   i_pat_age           Patient age
    * @param   o_ref_data          Referral dep_clin_servs data : ID + DESC
    * @param   o_error             An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-11-2011
    */
    FUNCTION get_referral_int_dcs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_external_sys IN p1_external_request.id_external_sys%TYPE,
        i_id_inst_orig    IN p1_external_request.id_inst_orig%TYPE,
        i_num_order       IN professional.num_order%TYPE,
        i_pat_gender      IN patient.gender%TYPE,
        i_pat_age         IN patient.age%TYPE,
        o_ref_data        OUT NOCOPY t_coll_ref_dcs,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns referral department and clinical services available for referring, of the Hospital complex from which i_id_inst_dest belongs
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Id professional, institution and software from the Interface
    * @param   i_id_external_sys   External system identifier
    * @param   i_id_inst_dest      Institution belonging to the Hospital Complex
    * @param   o_ref_data          Referral departments and clinical services
    * @param   o_error             An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   23-05-2013
    */
    FUNCTION get_all_referral_int_dcs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_external_sys IN p1_external_request.id_external_sys%TYPE,
        i_id_inst_dest    IN p1_external_request.id_inst_dest%TYPE,
        o_ref_data        OUT NOCOPY t_coll_ref_all_dcs,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets available clinical services for referring in dest institution.
    * Available only for external and at hospital entrance workflows
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Id professional, institution and software from the Interface
    * @param   i_id_workflow       Referral workflow
    * @param   i_id_speciality     Speciality identifier
    * @param   i_id_inst_dest      Dest institution identifier    
    * @param   o_ref_data          Referral dep_clin_servs data: ID + DESC
    * @param   o_error             An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   24-09-2012
    */
    FUNCTION get_referral_clinserv
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_workflow     IN p1_external_request.id_workflow%TYPE,
        i_id_speciality   IN p1_external_request.id_speciality%TYPE,
        i_id_inst_dest    IN p1_external_request.id_inst_dest%TYPE,
        i_id_external_sys IN p1_external_request.id_external_sys%TYPE,
        o_ref_data        OUT NOCOPY t_coll_ref_dcs,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns origin institutions available to referring for the workflow 'At hospital entrance'
    * Note: only used for wf=4
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Id professional, institution and software from the Interface
    * @param   i_id_external_sys   External system identifier
    * @param   i_id_inst_dest      Dest institution identifier
    * @param   i_id_speciality     Speciality identifier
    * @param   i_id_dep_clin_serv  Department and service identifier
    * @param   o_ref_data          Referral origin institutions available to referring
    * @param   o_error             An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   11-03-2014
    */
    FUNCTION get_referral_inst_orig
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_external_sys  IN p1_external_request.id_external_sys%TYPE,
        i_id_inst_dest     IN p1_external_request.id_inst_dest%TYPE,
        i_id_speciality    IN p1_external_request.id_speciality%TYPE,
        i_id_dep_clin_serv IN p1_external_request.id_dep_clin_serv%TYPE,
        o_ref_data         OUT NOCOPY t_coll_ref_inst,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns institutions and clinical services to forward the referral
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Id professional, institution and software from the Interface
    * @param   i_id_ref            Referral identifier
    * @param   o_inst_data         Institutions and clinical services to forward the referral
    * @param   o_error             An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   15-07-2013
    */
    FUNCTION get_inst_to_forward_ref
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_ref    IN p1_external_request.id_external_request%TYPE,
        o_inst_data OUT t_coll_ref_all_dcs,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Migrate a referral to a different dest institution
    * This function has COMMITs/ROLLBACKs
    *
    * Fill in table REF_MIG_INST_DEST_DATA with data to be migrated
    *
    * @param   i_default_dcs       Indicates if dep_clin_serv is mapped or calculated by default
    * @param   i_notes             Notes associated to the migration
    * @param   o_error             An error message, set when return=false
    *
    * @value   i_default_dcs       {*} Y- calculated by default for the referral speciality {*} N- calculated from table MAP
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   14-06-2012
    */
    FUNCTION mig_ref_dest_institution
    (
        i_default_dcs IN VARCHAR2 DEFAULT pk_ref_constant.g_yes,
        i_notes       IN VARCHAR2 DEFAULT NULL,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Sets the connection between the patient id and the hospital process
    *
    * @param   i_lang          Language associated to the professional executing the request
    * @param   i_prof          Professional id, institution and software
    * @param   i_pat           Patient identifier
    * @param   i_seq_num       External system identifier
    * @param   i_clin_rec      Patient process number on the institution, if available.
    * @param   i_epis          Episode identifier
    * @param   o_id_match      Match identifier
    * @param   o_error         An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   14-11-2012
    */
    FUNCTION set_match
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_pat      IN patient.id_patient%TYPE,
        i_seq_num  IN p1_match.sequential_number%TYPE,
        i_clin_rec IN clin_record.num_clin_record%TYPE,
        i_epis     IN episode.id_episode%TYPE DEFAULT NULL,
        o_id_match OUT p1_match.id_match%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Search for referral identifiers according to the criteria specified
    * Used by inter-alert
    *
    * @param   i_lang          Language associated to the professional executing the request
    * @param   i_prof          Professional id, institution and software
    * @param   i_pat_name      Patient name
    * @param   i_pat_gender    Patient gender
    * @param   i_dt_birth      Patient date of birth
    * @param   i_sns           Patient national health plan (SNS)
    * @param   i_id_ref        Referral identifier
    * @param   i_id_inst       Referral institution (orig or dest)
    * @param   i_id_inst_orig         Referral orig institution identifier
    * @param   i_id_inst_dest         Referral dest institution identifier
    * @param   i_id_spec       Referral speciality
    * @param   i_dt_search_beg        Begin search timestamp
    * @param   i_dt_search_end        End search timestamp
    * @param   o_id_ref_tab    Array of referral identifiers
    * @param   o_error         An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   14-12-2012
    */
    FUNCTION get_search_referrals
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_name      IN patient.name%TYPE,
        i_pat_gender    IN patient.gender%TYPE,
        i_dt_birth      IN patient.dt_birth%TYPE,
        i_sns           IN pat_health_plan.num_health_plan%TYPE,
        i_id_ref        IN p1_external_request.id_external_request%TYPE,
        i_id_inst       IN institution.id_institution%TYPE,
        i_id_inst_orig  IN p1_external_request.id_inst_orig%TYPE,
        i_id_inst_dest  IN p1_external_request.id_inst_dest%TYPE,
        i_id_spec       IN p1_speciality.id_speciality%TYPE,
        i_dt_search_beg IN TIMESTAMP WITH TIME ZONE,
        i_dt_search_end IN TIMESTAMP WITH TIME ZONE,
        o_id_ref_tab    OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Generate events for each issued referral of this patient in this institution
    * Used by inter-alert
    *
    * @param   i_lang          Language associated to the professional executing the request
    * @param   i_prof          Professional id, institution and software
    * @param   i_id_patient    Patient identifier
    * @param   o_error         An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   01-03-2013
    */
    FUNCTION set_event_patient_match
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * Crate new Referral comment
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional id, institution and software
    * @param   i_id_ref         Referral identifier
    * @param   i_text           Text comment
    * @param   i_dt_comment     Comment date 
    
    * @param   o_id_ref_comment Referral comment ids
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   25-07-2013
    **/

    FUNCTION create_ref_comment
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_text           IN CLOB,
        i_dt_comment     IN ref_comments.dt_comment%TYPE,
        o_id_ref_comment OUT ref_comments.id_ref_comment%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancel Referral comments
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional id, institution and software
    * @param   i_id_ref         Referral identifier
    * @param   i_id_ref_comment Referral comment id
    * @param   i_dt_cancel      Cancel Comment date 
    
    * @param   o_id_ref_comment Referral comment ids
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   05-07-2013
    **/
    FUNCTION cancel_ref_comment
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_id_ref_comment IN ref_comments.id_ref_comment%TYPE,
        i_dt_cancel      IN ref_comments.dt_comment%TYPE,
        o_id_ref_comment OUT ref_comments.id_ref_comment%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Edit Referral comments
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional id, institution and software
    * @param   i_id_ref         Referral identifier
    * @param   i_text           Text comment
    * @param   i_id_ref_comment Referral comment id
    * @param   i_dt_edit        Edit comment date 
    
    * @param   o_id_ref_comment New Referral comment id
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   05-07-2013
    **/
    FUNCTION edit_ref_comment
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_text           IN CLOB,
        i_id_ref_comment IN ref_comments.id_ref_comment%TYPE,
        i_dt_edit        IN ref_comments.dt_comment%TYPE,
        o_id_ref_comment OUT ref_comments.id_ref_comment%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

END pk_api_ref_ws;
/
