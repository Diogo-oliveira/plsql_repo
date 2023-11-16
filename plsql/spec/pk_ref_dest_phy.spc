/*-- Last Change Revision: $Rev: 2028907 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:40 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ref_dest_phy AS

    /**
    * Gets list of available professionals for triage.
    * Returns all triage professionals that are connect to the request dep_clin_serv.
    * Excludes the professional calling the function.
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof  professional, institution and software ids
    * @param   i_ext_req request id.
    * @param   o_prof professionals list
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 2.0
    * @since   23-04-2008
    */
    FUNCTION get_prof_triage_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        o_prof    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets list of available clinical services
    *
    * @param   i_lang           Language
    * @param   i_prof           Professional, institution, software
    * @param   i_dep_clin_serv  Department and clinical service identifier
    * @param   i_external_sys   External system identifier    
    * @param   o_levels         Triage urgency levels
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   05-03-2010
    */
    FUNCTION get_triage_level_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_external_sys  IN external_sys.id_external_sys%TYPE,
        o_levels        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the list of professionals available for scheduling.
    *
    * @param   i_lang             Language id
    * @param   i_prof             Professional, institution, software
    * @param   i_dep_clin_serv    Dep_clin_serv id for the scheduling beeing requested
    * @param   i_external_sys     External system identifier
    * @param   i_dep              Service id (DEPARTMENT)
    * @param   o_cs               Specialities list (CLINICAL_SERVICES)
    * @param   o_error            An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   05-06-2007
    */
    FUNCTION get_prof_schedule_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_external_sys  IN external_sys.id_external_sys%TYPE,
        o_prof          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Validates if the professional has the functionality for the dcs provided 
    *
    * @param   i_prof professional id
    * @param   i_dcs dep_clin_serv id
    * @param   i_func functionality id (sys_functionality)
    *
    * @RETURN  Y if true, N otherwise
    * @author  Joao Sa
    * @version 4.0
    * @since   24-11-2007
    */
    FUNCTION validate_dcs_func
    (
        i_prof IN profissional,
        i_dcs  IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_func IN sys_functionality.id_functionality%TYPE
    ) RETURN VARCHAR2;

    /**
    * Validates if the professional has at least one of the functionalities for the dcs provided 
    * Used on grids
    *
    * @param   i_prof  Professional identifier
    * @param   i_dcs   Dep_clin_serv identifier
    * @param   i_func  Functionalities identifiers (sys_functionality)
    *
    * @RETURN  Y if true, N otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   08-09-2010
    */
    FUNCTION validate_dcs_func
    (
        i_prof IN profissional,
        i_dcs  IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_func IN table_number
    ) RETURN VARCHAR2;

    /**
    * Validates if the professional has the functionality "Triage" or "Speciality Triage" for the dcs provided 
    *
    * @param   i_prof professional id
    * @param   i_dcs dep_clin_serv id
    * @param   i_func functionality id (sys_functionality)
    *
    * @RETURN  Y if true, N otherwise
    * @author  Joao Sa
    * @version 4.0
    * @since   24-11-2007
    */
    FUNCTION validate_dcs_triage
    (
        i_prof IN profissional,
        i_dcs  IN dep_clin_serv.id_dep_clin_serv%TYPE
    ) RETURN VARCHAR2;

    /**
    * Returns the list of available institutions to forward the referral.
    * The institutions must belong to the same hospital centre.
    * Notice that if the parameter INST_FORWARD_TYPE is (I)nstitution then the destination institution
    * must accept requests for the referral speciality.
    * If that parameter is (C)linical service then all institutions from the hospital centre that accept
    * any kind of referrals (all configured in p1_spec_dep_clin_serv) are listed 
    *
    * @param   i_lang            Language associated to the professional executing the request
    * @param   i_prof            Professional, institution and software ids
    * @param   i_ext_req         Referral identifier
    * @param   o_inst available institutions
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   06-05-2008
    */
    FUNCTION get_inst_forward_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        o_inst    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Pipeline function that returns the list of available institutions and dep_clin_servs to forward the referral.
    * Notice that if the parameter INST_FORWARD_TYPE is (I)nstitution then the destination institution
    * must accept requests for the referral speciality.
    * If that parameter is (C)linical service then all institutions from the hospital centre that accept
    * any kind of referrals (all configured in p1_spec_dep_clin_serv) are listed 
    *
    * @param   i_lang            Language associated to the professional executing the request
    * @param   i_prof            Professional, institution and software ids
    * @param   i_id_spec         Referral speciality identifier
    * @param   i_id_workflow     Referral workflow identifier
    * @param   i_id_inst_orig    Referral origin institution
    * @param   i_id_inst_dest    Referral dest institution
    * @param   i_pat_gender      Patient gender
    * @param   i_pat_age         Patient age
    * @param   i_external_sys    External system identifier
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   16-07-2013
    */
    FUNCTION get_inst_dcs_forward_p
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_spec      IN p1_external_request.id_speciality%TYPE,
        i_id_workflow  IN p1_external_request.id_workflow%TYPE,
        i_id_inst_orig IN p1_external_request.id_inst_orig%TYPE,
        i_id_inst_dest IN p1_external_request.id_inst_dest%TYPE,
        i_pat_gender   IN patient.gender%TYPE,
        i_pat_age      IN patient.age%TYPE,
        i_external_sys IN external_sys.id_external_sys%TYPE
    ) RETURN t_coll_ref_inst_dcs_fwd
        PIPELINED;

    /**
    * Returns then department and services available to forward or schedule referrals
    *
    * @param   i_lang           Language
    * @param   i_prof           Professional, institution, software
    * @param   i_id_institution Departments returned from this institution
    * @param   i_id_market      Institution market related to i_id_institution    
    * @param   i_pat_gender     Patient gender
    * @param   i_pat_age        Patient age
    * @param   i_external_sys   External system identifier
    *
    * @RETURN  Return table (t_coll_ref_inst_dcs_fwd) pipelined
    *
    * @author  Ana Monteiro
    * @version 1.0
    * @since   07-06-2013
    */
    FUNCTION get_dcs_forward_list_p
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_market      IN market.id_market%TYPE DEFAULT NULL,
        i_pat_gender     IN patient.gender%TYPE,
        i_pat_age        IN patient.age%TYPE,
        i_external_sys   IN external_sys.id_external_sys%TYPE
    ) RETURN t_coll_ref_inst_dcs_fwd
        PIPELINED;

    /**
    * Insert consultation doctor 
    *
    * @param   i_lang            Language identifier
    * @param   i_prof            Professional, institution and software
    * @param   i_exr             Referral identifier
    * @param   i_diagnosis       Selected diagnosis
    * @param   i_diag_desc       Diagnosis description, when entered in text mode
    * @param   i_answer          Observation, Therapy, Exam and Conclusion
    * @param   i_date            Operation date
    * @param   o_track           Array of ID_TRACKING transitions
    * @param   o_error           An error message, set when return=false
    *
    * @RETURN  Y if true, N otherwise
    * @author  Joao Sa
    * @version 4.0
    * @since   24-11-2007
    */

    FUNCTION set_ref_answer
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
        o_track            OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the suggested physician who will provide consultation
    *
    * @param   i_lang           Language id
    * @param   i_prof           Professional, institution, software
    * @param   i_id_ref         Referral identifier
    *
    * @RETURN  Professional identifier
    * @author  Ana Monteiro
    * @version 2.6.1
    * @since   27-05-2011
    */
    FUNCTION get_suggested_physician
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE
    ) RETURN professional.id_professional%TYPE;

    /**
    * Returns the list of services (DEPARTMENT) available for forward the request (dest physician)
    *
    * @param   i_lang            Language associated to the professional executing the request
    * @param   i_prof            Professional, institution and software ids
    * @param   i_external_sys    External system identifier
    * @param   i_pat_gender      Patient gender
    * @param   i_pat_age         Patient age
    * @param   i_id_inst         Departments returned from this institution
    * @param   i_dcs_except      Dep_clin_Serv exception: not to be returned
    * @param   o_dep             Service identifier (DEPARTMENT)
    * @param   o_error           An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   25-10-2006
    */
    FUNCTION get_dep_forward_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_external_sys IN external_sys.id_external_sys%TYPE,
        i_pat_gender   IN patient.gender%TYPE,
        i_pat_age      IN patient.age%TYPE,
        i_id_inst      IN p1_external_request.id_inst_dest%TYPE,
        i_dcs_except   IN p1_external_request.id_dep_clin_serv%TYPE DEFAULT NULL,
        o_dep          OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the list of services (DEPARTMENT) available for schedule
    * Returns all departments in which the professional has at least one speciality (prof_dep_clin_serv).
    *
    * @param   i_lang            Language associated to the professional executing the request
    * @param   i_prof            Professional, institution and software ids
    * @param   i_external_sys    External system identifier
    * @param   i_pat_gender      Patient gender
    * @param   i_pat_age         Patient age
    * @param   o_dep             Service identifier (DEPARTMENT)
    * @param   o_error           An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 2.0
    * @since   23-04-2008
    */
    FUNCTION get_dep_schedule_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_external_sys IN external_sys.id_external_sys%TYPE,
        i_pat_gender   IN patient.gender%TYPE,
        i_pat_age      IN patient.age%TYPE,
        o_dep          OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the list of specialities available for forward/schedule the request (dest physician)
    * Retuns all specialities in the department that are configured in p1_spec_dep_clin_serv
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids    
    * @param   i_dep            Service identifier (DEPARTMENT)
    * @param   i_external_sys   External system identifier
    * @param   i_pat_gender     Patient gender
    * @param   i_pat_age        Patient age
    * @param   i_id_inst        Institution identifier (to return the list of specialities available)
    * @param   i_dcs_except     Dep_clin_Serv exception: not to be returned
    * @param   o_cs             Clinical services list (CLINICAL_SERVICES)
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   04-06-2007
    */
    FUNCTION get_clin_serv_forward_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_dep          IN department.id_department%TYPE,
        i_external_sys IN external_sys.id_external_sys%TYPE,
        i_pat_gender   IN patient.gender%TYPE,
        i_pat_age      IN patient.age%TYPE,
        i_id_inst      IN p1_external_request.id_inst_dest%TYPE,
        i_dcs_except   IN p1_external_request.id_dep_clin_serv%TYPE DEFAULT NULL,
        o_cs           OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

END pk_ref_dest_phy;
/
