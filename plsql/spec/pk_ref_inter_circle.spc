/*-- Last Change Revision: $Rev: 952740 $*/
/*-- Last Change by: $Author: ana.monteiro $*/
/*-- Date of last change: $Date: 2011-04-15 08:47:41 +0100 (sex, 15 abr 2011) $*/

CREATE OR REPLACE PACKAGE pk_ref_inter_circle IS

    -- Author  : JOANA.BARROSO
    -- Created : 20-10-2009 17:31:26
    -- Purpose : Circle UK Project

    -- Public variable declarations
    g_error         VARCHAR2(4000);
    g_sysdate       TIMESTAMP WITH TIME ZONE;
    g_package_name  VARCHAR2(50);
    g_package_owner VARCHAR2(50);
    g_exception EXCEPTION;
    g_exception_np EXCEPTION;
    g_retval BOOLEAN;
    g_found  BOOLEAN;

    g_null        CONSTANT VARCHAR2(1) := NULL;
    g_date_format CONSTANT VARCHAR2(50) := 'YYYYMMDDHH24MISS';

    -- Public function and procedure declarations
    /*
    * Create referral (and ProfessionaL if the gp_code is not in table professional )
    *
    * @param   i_lang                         Language 
    * @param   i_prof_gp_code                 External professional 
    * @param   i_prof_gender                  Professional gender
    * @param   i_prof_nick_name               Professional Nick Name  
    * @param   i_prof_first_name              Professional First Name
    * @param   i_prof_middle_name             Professional Middle             
    * @param   i_prof_last_name               Professional Last Name 
    * @param   i_title                        Professional Title                   
    * @param   i_patient                      Patient Id
    * @param   i_int_orig                     Referral origin institution
    * @param   i_int_dest                     Referral destiny institution
    * @param   i_id_ref                       Id Referral in the external system
    * @param   i_id_ext_sys                   Id Extenal system
    * @param   i_flg_status                   Referral status
    * @param   i_flg_type                     Referral Type
    * @param   i_decision_urg_level           Referral decision urg level
    * @param   i_dt_requested                 (RF1) Efective Date
    * @param   i_dt_ref_received              
    * @param   i_notes                        Referral Priority Description, Contract Type Description, Type Description
    * @param   i_req_item                     Requested items (Referral Disposition - Activity To schedule)
    * @param   i_reason                       Referral Reason
    * @param   i_ubrn                         External Referral Identifier
    * @param   o_ext_req                      Id_EXTERNAL_REQUEST
    * @param   o_error                        an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   21-10-2009
    */
    FUNCTION create_referral
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof_gp_code       IN professional.num_order%TYPE,
        i_prof_gender        IN professional.gender%TYPE DEFAULT 'I',
        i_prof_nick_name     IN professional.nick_name%TYPE,
        i_prof_first_name    IN professional.first_name%TYPE,
        i_prof_middle_name   IN professional.middle_name%TYPE,
        i_prof_last_name     IN professional.last_name%TYPE,
        i_prof_title         IN professional.title%TYPE DEFAULT NULL,
        i_patient            IN patient.id_patient%TYPE,
        i_int_orig           IN institution.id_institution%TYPE,
        i_int_dest           IN institution.id_institution%TYPE,
        i_id_ref             IN p1_external_request.ext_reference%TYPE,
        i_id_ext_sys         IN p1_external_request.id_external_sys%TYPE,
        i_flg_status         IN p1_external_request.flg_status%TYPE,
        i_flg_type           IN p1_external_request.flg_type%TYPE,
        i_decision_urg_level IN p1_external_request.decision_urg_level%TYPE,
        i_dt_requested       IN p1_external_request.dt_requested%TYPE,
        i_dt_ref_received    IN p1_external_request.dt_requested%TYPE,
        i_notes              IN p1_detail.text%TYPE, -- 17
        i_req_item           IN p1_detail.text%TYPE, -- 19
        i_reason             IN p1_detail.text%TYPE, -- 0
        i_ubrn               IN p1_detail.text%TYPE, -- 20
        o_ext_req            OUT p1_external_request.id_external_request%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Update referral status and details
    *
    * @param   i_lang                         Language 
    * @param   i_prof_gp_code                 External professional 
    * @param   i_int_orig                     Referral origin institution
    * @param   i_int_dest                     Referral destiny institution
    * @param   i_id_ref                       Id Referral in the external system
    * @param   i_id_ext_sys                   Id Extenal system
    * @param   i_flg_status                   Referral status
    * @param   i_decision_urg_level           Referral decision urg level
    * @param   i_notes                        Referral Priority Description, Contract Type Description, Type Description
    * @param   i_req_item                     Requested items (Referral Disposition - Activity To schedule)
    * @param   i_reason                       Referral Reason
    * @param   i_dt_ref_received
    * @param   o_ext_req                      Id_EXTERNAL_REQUEST
    * @param   o_error                        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   21-10-2009
    */
    FUNCTION update_referral
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof_gp_code       IN professional.num_order%TYPE,
        i_int_orig           IN institution.id_institution%TYPE,
        i_int_dest           IN institution.id_institution%TYPE,
        i_id_ref             IN p1_external_request.ext_reference%TYPE,
        i_id_ext_sys         IN p1_external_request.id_external_sys%TYPE,
        i_flg_status         IN p1_external_request.flg_status%TYPE,
        i_decision_urg_level IN p1_external_request.decision_urg_level%TYPE,
        i_notes              IN p1_detail.text%TYPE,
        i_req_item           IN p1_detail.text%TYPE,
        i_reason             IN p1_detail.text%TYPE,
        i_dt_ref_received    IN p1_tracking.dt_tracking_tstz%TYPE,
        o_ext_req            OUT p1_external_request.id_external_request%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Cancel referral 
    *
    * @param   i_lang           language associated to the professional executing the request
    * @param   i_prof_gp_code   Num order, 
    * @param   i_int_dest       Institution desteny
    * @param   i_id_ref         extenal system referral id   
    * @param   i_id_extenal_sys external system
    * @param   o_error          an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   21-10-2009
    */

    FUNCTION cancel_referral
    (
        i_lang            IN LANGUAGE.id_language%TYPE,
        i_prof_gp_code    IN professional.num_order%TYPE,
        i_int_dest        IN institution.id_institution%TYPE,
        i_id_ref          IN p1_external_request.ext_reference%TYPE,
        i_id_ext_sys      IN p1_external_request.id_external_sys%TYPE,
        i_dt_ref_received IN p1_tracking.dt_tracking_tstz%TYPE,
        o_ext_req         OUT p1_external_request.id_external_request%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Create schedule 
    *
    * @param   i_lang          Language 
    * @param   i_prof          (Professional, Institution, Software)
    * @param   i_sched_outp    Record containing data from an external system
    * @param   i_id_ext_ref    Referral id in the external system 
    * @param   i_id_ext_sys    External system
    * @param   o_new_id_sched  Schedule identifier on ALERT Scheduler
    * @param   o_warning       Warning message.
    * @param   o_error         An error message, set when return = false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   27-11-2009
    */

    FUNCTION create_ref_schedule
    (
        i_lang         IN LANGUAGE.id_language%TYPE,
        i_prof         IN profissional,
        i_sched_outp   IN pk_schedule_interface.schedule_outp_struct,
        i_id_ext_ref   IN p1_external_request.ext_reference%TYPE,
        i_id_ext_sys   IN p1_external_request.id_external_sys%TYPE,
        o_new_id_sched OUT schedule.id_schedule%TYPE,
        o_warning      OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Create schedule
    *
    * @param   i_lang          Language
    * @param   i_prof          (Professional, Institution, Software)
    * @param   i_sched_outp    Record containing data from an external system
    * @param   i_id_ext_ref    Referral id in the external system
    * @param   i_id_ext_sys    External system
    * @param   o_new_id_sched  Schedule identifier on ALERT Scheduler
    * @param   o_warning       Warning message.
    * @param   o_error         An error message, set when return = false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   27-11-2009
    */

    FUNCTION create_sch_with_ref_map
    (
        i_lang         IN LANGUAGE.id_language%TYPE,
        i_prof         IN profissional,
        i_sched_outp   IN pk_schedule_interface.schedule_outp_struct,
        i_id_ext_ref   IN p1_external_request.ext_reference%TYPE,
        i_id_ext_sys   IN p1_external_request.id_external_sys%TYPE,
        o_new_id_sched OUT schedule.id_schedule%TYPE,
        o_id_ref_map   OUT ref_map.id_ref_map%TYPE,
        o_warning      OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Cancel schedule
    *
    * @param   i_lang                  Language
    * @param   i_prof                  (Professional, Institution, Software)
    * @param   i_sched_outp_cancel     Cancellation data.    
    * @param   o_id_ref                Alert Referral ID
    * @param   o_warning               Warning message.
    * @param   o_error                 an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   27-11-2009
    */
    FUNCTION cancel_ref_schedule
    (
        i_lang              IN LANGUAGE.id_language%TYPE,
        i_prof              IN profissional,
        i_sched_outp_cancel IN pk_schedule_interface.schedule_outp_cancel_struct,
        i_id_ref            IN p1_external_request.id_external_request%TYPE,
        o_warning           OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get external system and external reference
    *
    * @param   i_lang         Language 
    * @param   i_prof        (Professional, Institution, Software)
    * @param   i_schedule     Id schedule
    * @param   o_id_ref       Referral id    
    * @param   o_error        an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   30-11-2009
    */
    FUNCTION get_ref_from_map
    (
        i_lang     IN LANGUAGE.id_language%TYPE,
        i_prof     IN profissional,
        i_schedule IN schedule.id_schedule%TYPE,
        o_id_ref   OUT p1_external_request.id_external_request%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Creates an active REF_MAP record
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional id, institution and software
    * @param   i_id_ref         Referral identifier
    * @param   i_id_schedule    Schedule identifier
    * @param   i_id_episode     Episode identifier
    * @param   o_id_ref_map     REF_MAP identifier
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   02-06-2010
    */
    FUNCTION create_ref_map
    (
        i_lang        IN LANGUAGE.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ext_ref  IN p1_external_request.ext_reference%TYPE,
        i_id_ext_sys  IN p1_external_request.id_external_sys%TYPE,
        i_id_schedule IN ref_map.id_schedule%TYPE DEFAULT NULL,
        i_id_episode  IN ref_map.id_episode%TYPE,
        o_id_ref_map  OUT ref_map.id_ref_map%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels REF_MAP record
    *
    * @param   i_lang       Language associated to the professional executing the request
    * @param   i_prof       Professional id, institution and software
    * @param   i_ref_map    Record data
    * @param   o_error      An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   02-06-2010
    */
    FUNCTION cancel_ref_map
    
    (
        i_lang             IN LANGUAGE.id_language%TYPE,
        i_prof             IN profissional,
        i_ref_map_schedule IN ref_map.id_schedule%TYPE,
        i_ref_map_episode  IN ref_map.id_episode%TYPE,
        i_id_ext_ref       IN p1_external_request.ext_reference%TYPE,
        i_id_ext_sys       IN p1_external_request.id_external_sys%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get referral id
    *
    * @param   i_lang              Language
    * @param   i_ref_ext_sys       Referral id in the external system
    * @param   i_id_extenal_sys    External system
    * @param   o_id_ref            Id external request
    * @param   o_id_pat            Id patient
    * @param   o_epis              Id episide
    * @param   o_error             An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   21-10-2009
    */

    FUNCTION get_referral_id
    (
        i_lang           IN LANGUAGE.id_language%TYPE,
        i_ref_ext_sys    IN p1_external_request.ext_reference%TYPE,
        i_id_extenal_sys IN external_sys.id_external_sys%TYPE,
        o_id_ref         OUT p1_external_request.id_external_request%TYPE,
        o_id_pat         OUT patient.id_patient%TYPE,
        o_epis           OUT episode.id_episode%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

END pk_ref_inter_circle;
/
