/*-- Last Change Revision: $Rev: 2028918 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:44 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ref_utils AS

    /**
    * Returns the external request's workflow.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Professional Id
    * @param i_id_ext_sys           Patients Id
    * @param i_id_inst_orig         Institution where the referral was created
    * @param i_id_inst_dest         Destination Institution of the referral  
    * @param i_detail               detail of the referral, used to differentiate 2 circle WF 
    *
    * @return                       id_workflow
    *
    * @author   João Almeida
    * @version  2.6.03
    * @since    2010/07/26
    */
    FUNCTION get_workflow
    (
        i_prof         IN profissional,
        i_lang         IN language.id_language%TYPE,
        i_id_ext_sys   IN p1_external_request.id_external_sys%TYPE,
        i_id_inst_orig IN p1_external_request.id_inst_orig%TYPE,
        i_id_inst_dest IN p1_external_request.id_inst_dest%TYPE,
        i_detail       IN table_table_varchar
    ) RETURN NUMBER;

    /**
    * Returns the patient photo or silhuette.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Professional Id
    * @param i_id_patient           Patients Id
    * @param   i_id_ext_req id_external_request
    *
    * @return                       The patient s photo
    *
    * @author   João Almeida
    * @version  2.6
    * @since    2010/03/15
    */
    FUNCTION get_pat_photo
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_ext_req IN p1_external_request.id_external_request%TYPE
    ) RETURN VARCHAR2;

    /**
    * Return institution flag type
    *
    * @param   i_lang application language
    * @param   i_prof professional using the application
    * @param   i_id_inst       institution identifier
    * @param   o_inst_type institution type
    * @param   o_error         An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Almeida
    * @version 1.0
    * @since   01-03-2010   
    */
    FUNCTION get_inst_type
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_inst   IN institution.id_institution%TYPE,
        o_inst_type OUT institution.flg_type%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Return last status change data for the request and
    *
    * @param   i_id_ext_req external request id
    * @param   i_flg_status status
    * @param   o_data last record data
    * @param   o_error error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 1.0
    * @since   15-05-2007   
    */
    FUNCTION get_status_data
    (
        i_lang       IN language.id_language%TYPE,
        i_id_ext_req IN p1_external_request.id_external_request%TYPE,
        i_flg_status IN p1_external_request.flg_status%TYPE,
        o_data       OUT p1_tracking%ROWTYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the previous status change data for the referral
    *
    * @param   i_lang      Language identifier
    * @param   i_prof      Professional id, institution and software    
    * @param   i_id_ref    Referral identifier
    * @param   o_data      Last record data
    * @param   o_error     Error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   16-09-2010   
    */
    FUNCTION get_prev_status_data
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE,
        o_data   OUT p1_tracking%ROWTYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the current status change data for the referral
    *
    * @param   i_lang      Language identifier
    * @param   i_prof      Professional id, institution and software    
    * @param   i_id_ref    Referral identifier
    * @param   o_data      Last record data
    * @param   o_error     Error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   28-09-2010   
    */
    FUNCTION get_cur_status_data
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE,
        o_data   OUT p1_tracking%ROWTYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the current action identifier (related to the current status change)
    *
    * @param   i_lang      Language identifier
    * @param   i_prof      Professional id, institution and software    
    * @param   i_id_ref    Referral identifier
    *
    * @RETURN  action identifier
    * @author  Ana Monteiro
    * @version 1.0
    * @since   28-09-2010   
    */
    FUNCTION get_cur_action
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE
    ) RETURN p1_tracking.id_workflow_action%TYPE;

    /**
    * Return last status date for the request
    *
    * @param   i_id_ext_req external request id
    * @param   i_flg_status status
    * @param   o_error error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 1.0
    * @since   15-05-2007
    */
    FUNCTION get_status_date
    (
        i_lang       IN language.id_language%TYPE,
        i_id_ext_req IN p1_external_request.id_external_request%TYPE,
        i_flg_status IN p1_external_request.flg_status%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    /**
    * Returns referral active appointment date
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_id_ref         Referral identifier
    * @param   o_dt_schedule    Referral active appointment date 
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   19-11-2009
    */
    FUNCTION get_ref_schedule_date
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN p1_external_request.id_external_request%TYPE,
        o_dt_schedule OUT schedule.dt_begin_tstz%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns referral data in a string
    *
    * @param   i_lang           Language identifier
    * @param   i_prof           Professional identifier, institution and software    
    * @param   i_ref_row        Referral row
    *
    * @RETURN  Referral data string 
    * @author  Ana Monteiro
    * @version 1.0
    * @since   19-02-2010
    */
    FUNCTION to_string
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_ref_row IN p1_external_request%ROWTYPE
    ) RETURN VARCHAR2;

    /**
    * Returns referral detail data in a string
    *
    * @param   i_lang           Language identifier
    * @param   i_prof           Professional identifier, institution and software    
    * @param   i_detail_row     Referral detail row
    *
    * @RETURN  Referral data string 
    * @author  Ana Monteiro
    * @version 1.0
    * @since   19-02-2010
    */
    FUNCTION to_string
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_detail_row IN p1_detail%ROWTYPE
    ) RETURN VARCHAR2;

    /**
    * Returns referral tracking data in a string
    *
    * @param   i_lang           Language identifier
    * @param   i_prof           Professional identifier, institution and software    
    * @param   i_tracking_row   Referral tracking row
    *
    * @RETURN  Referral data string 
    * @author  Ana Monteiro
    * @version 1.0
    * @since   03-03-2010
    */
    FUNCTION to_string
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_tracking_row IN p1_tracking%ROWTYPE
    ) RETURN VARCHAR2;

    /**
    * Returns referral detail date
    *
    * @param  i_lang          Language
    * @param   i_id_ref         Referral identifier
    * @param   i_flg_status     Referral status
    * @param   i_id_workflow    Referral's Workflow
    *
    * @RETURN  
    * @author  João Almeida
    * @version 1.0
    * @since   25-02-2010
    */
    FUNCTION get_ref_detail_date
    (
        i_lang        IN language.id_language%TYPE,
        i_id_ext_req  IN p1_tracking.id_external_request%TYPE,
        i_flg_status  IN p1_tracking.ext_req_status%TYPE,
        i_id_workflow IN p1_external_request.id_workflow%TYPE
        
    ) RETURN TIMESTAMP
        WITH TIME ZONE;

    /**
    * Returns referral detail date
    *
    * @param   i_lang          Language
    * @param   i_id_ref         Referral identifier
    *
    * @RETURN  
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-11-2010
    */
    FUNCTION get_ref_detail_date
    (
        i_lang       IN language.id_language%TYPE,
        i_id_ext_req IN p1_tracking.id_external_request%TYPE
    ) RETURN TIMESTAMP
        WITH TIME ZONE;

    FUNCTION get_prof_spec_signature
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_professional  IN professional.id_professional%TYPE,
        i_id_instititution IN institution.id_institution%TYPE
    ) RETURN VARCHAR2;

    /**
    * Gets the last referral tracking row related to triaging referral or canceling referral schedule
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_id_ref         Referral identifier
    * @param   i_action         Action pretended: {*} 'A1' Triaging referral
                                                  {*} 'A2' Canceling referral schedule
    * @param   o_track_row      Tracking row
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   2010-04-26
    */
    FUNCTION get_last_track_row
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_ref    IN p1_external_request.id_external_request%TYPE,
        i_action    IN VARCHAR2,
        o_track_row OUT p1_tracking%ROWTYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Converts operation date DATE format into TIMESTAMP WITH LOCAL TIME ZONE format
    *
    * @param   i_lang     Language associated to the professional executing the request
    * @param   i_prof     Id professional, institution and software
    * @param   i_dt_d     Operation date (DATE format)
    * @param   o_dt_tstz  Operation date (TIMESTAMP WITH LOCAL TIME ZONE format)
    * @param   o_error    An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   26-10-2009
    */
    FUNCTION get_operation_date
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_dt_d    IN DATE,
        o_dt_tstz OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns professional data in a string
    *
    * @param   i_prof_data   Professional data
    *
    * @RETURN  Professional data string 
    * @author  Ana Monteiro
    * @version 1.0
    * @since   24-09-2010
    */
    FUNCTION to_string(i_prof_data IN t_rec_prof_data) RETURN VARCHAR2;

    /**
    * Gets the last referral tracking row related to triaging referral or canceling referral schedule
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_code_msg_arr   Code message array
    * @param   o_desc_msg_ibt   Description message
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   30-11-2010
    */
    FUNCTION get_message_ibt
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_code_msg_arr  IN table_varchar,
        io_desc_msg_ibt IN OUT NOCOPY pk_ref_constant.ibt_varchar_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Check if the professional can view the referral clinical data
    *
    * @param   i_lang               Language associated to the professional executing the request
    * @param   i_prof               Professional, institution and software ids
    * @param   i_cat                Professional category type
    * @param   i_prof_profile       Professional profile template
    * @param   i_id_prof_requested  Professional identifier that requested the referral
    * @param   i_id_workflow        Workflow ID
    *
    * @RETURN  {*} Y - can view clinical data; {*} N - otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   30-11-2010
    */
    FUNCTION can_view_clinical_data
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_cat               IN category.flg_type%TYPE,
        i_prof_profile      IN profile_template.id_profile_template%TYPE,
        i_id_prof_requested IN p1_external_request.id_prof_requested%TYPE,
        i_id_workflow       IN wf_workflow.id_workflow%TYPE
    ) RETURN VARCHAR2;

    /**
    * This procedure logs a CLOB to alert log tables
    *
    * @param   i_clob            CLOB to print
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   10-05-2010
    */
    PROCEDURE log_clob(i_clob IN CLOB);

    /**
    * Gets institution of the dep_clin_serv
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software
    * @param   i_dcs            Department and clinical service
    * @param   o_id_institution Institution identifier
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   07-12-2011
    */
    FUNCTION get_institution
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_dcs            IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_id_institution OUT institution.id_institution%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Check if referral needs to by aprroved By Clinical Director
    * WF = 28 CARE BR
    *
    * @param   i_prof           Id professional, institution and software    
    * @param   i_ref           Referral Id
    * @param   i_flg_type      Referral type {*} 'C' Visit, 
                                             {*} 'A' Analysis 
                                             {*} 'E' Other Exams
                                             {*} 'I' Image
                                             {*} 'P' Procedures                                            
                                             {*} 'F' MFR                                          
    *
    * @RETURN  VARCHAR 
    * @author  Joana Barroso
    * @version 1.0
    * @since   24-12-2012
    */
    FUNCTION check_ref_mcdt_to_aprove
    (
        i_prof     IN profissional,
        i_ref      IN p1_external_request.id_external_request%TYPE,
        i_flg_type IN p1_external_request.flg_type%TYPE
        
    ) RETURN VARCHAR;

    FUNCTION get_all_domains_cached
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_code_dom_arr IN table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_domain_cached_img_name
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_code_domain IN sys_domain.code_domain%TYPE,
        i_val         IN sys_domain.val%TYPE
    ) RETURN sys_domain.img_name%TYPE;

    FUNCTION get_domain_cached_rank
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_code_domain IN sys_domain.code_domain%TYPE,
        i_val         IN sys_domain.val%TYPE
    ) RETURN sys_domain.rank%TYPE;

    FUNCTION get_domain_cached_desc
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_code_domain IN sys_domain.code_domain%TYPE,
        i_val         IN sys_domain.val%TYPE
    ) RETURN sys_domain.desc_val%TYPE;

    /**
    * Returns a sys_config value
    *
    * @param   i_prof               Professional, institution and software ids
    * @param   i_id_sys_config      Sys config identifier
    *
    * @author  Ana Monteiro
    * @version 1.0
    * @since   03-08-2012
    */
    FUNCTION get_sys_config
    (
        i_prof          IN profissional,
        i_id_sys_config IN sys_config.id_sys_config%TYPE
    ) RETURN sys_config.value%TYPE;

    /*
    * Compares two timestamps at the minute level only 
    *
    * @param i_timestamp1         Timestamp
    * @param i_timestamp2         Timestamp
    *
    * @return 'G' if i_timestamp1 is more recent than i_timestamp2, 'E' if they are equal, 'L' otherwise
    *
    * @author Ana Monteiro
    * @version 1.0
    * @since 17-10-2012
    */
    FUNCTION compare_tsz_min
    (
        i_date1 IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_date2 IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2;

    /**
    * Parses date string into year, month and day separately
    *
    * @param   i_lang         Language associated to the professional executing the request
    * @param   i_prof         Professional, institution and software ids
    * @param   i_dt_str_flash Date in string format YYYY[MM[DD]] (flash interpretation)
    * @param   o_year         Year date
    * @param   o_month        Month date
    * @param   o_day          Day date
    * @param   o_error        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   04-01-2013
    */
    FUNCTION parse_dt_str
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_dt_str_flash IN VARCHAR,
        o_year         OUT NUMBER,
        o_month        OUT NUMBER,
        o_day          OUT NUMBER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Parses date year, month and day into string (for flash interpretation)
    *
    * @param   i_lang            Language associated to the professional executing the request
    * @param   i_prof            Professional, institution and software ids        
    * @param   i_year            Year date
    * @param   i_month           Month date
    * @param   i_day             Day date
    *
    * @RETURN  Problem begin date (string format for flash interpretation)
    * @author  Ana Monteiro
    * @version 1.0
    * @since   04-01-2013
    */
    FUNCTION parse_dt_str_flash
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_year  IN NUMBER,
        i_month IN NUMBER,
        i_day   IN NUMBER
    ) RETURN VARCHAR2;

    /**
    * Parses date year, month and day into string (to be shown in flash and reports)
    *
    * @param   i_lang            Language associated to the professional executing the request
    * @param   i_prof            Professional, institution and software ids        
    * @param   i_year            Year date
    * @param   i_month           Month date
    * @param   i_day             Day date
    *
    * @RETURN  Problem begin date (string))
    * @author  Ana Monteiro
    * @version 1.0
    * @since   04-01-2013
    */
    FUNCTION parse_dt_str_app
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_year  IN NUMBER,
        i_month IN NUMBER,
        i_day   IN NUMBER
    ) RETURN VARCHAR2;

    /**
    * Parses date string into year, month and day separately
    *
    * @param   i_lang         Language associated to the professional executing the request
    * @param   i_prof         Professional, institution and software ids
    * @param   i_dt_str_flash Date in string format YYYY[MM[DD]] (flash interpretation)
    * @param   i_year_1       Year date
    * @param   i_month_1      Month date
    * @param   i_day_1        Day date
    * @param   i_year_2       Year date
    * @param   i_month_2      Month date
    * @param   i_day_2        Day date    
    *
    * @return 'G' if i_date_1 is more recent than i_date_2, 'E' if they are equal, 'L' otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   04-01-2013
    */
    FUNCTION compare_dt
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_year_1  IN NUMBER,
        i_month_1 IN NUMBER,
        i_day_1   IN NUMBER,
        i_year_2  IN NUMBER,
        i_month_2 IN NUMBER,
        i_day_2   IN NUMBER
    ) RETURN VARCHAR2;

    /**
    * Gets the referral system date (time when the operation was executed in the system)
    *
    * @author  Ana Monteiro
    * @version 1.0
    * @since   10-01-2013
    */
    FUNCTION get_sysdate RETURN p1_tracking.dt_create%TYPE;

    /**
    * Gets the referral context variable
    *
    * @author  Ana Monteiro
    * @version 1.0
    * @since   10-01-2013
    */
    FUNCTION get_ref_context RETURN t_rec_ref_context;

    /**
    * Sets the referral context variable
    *
    * @author  Ana Monteiro
    * @version 1.0
    * @since   10-01-2013
    */
    PROCEDURE set_ref_context
    (
        i_id_external_request IN p1_external_request.id_external_request%TYPE DEFAULT NULL,
        i_dt_system_date      IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL
    );

    /**
    * Resets the referral context
    *
    * @author  Ana Monteiro
    * @version 1.0
    * @since   10-01-2013
    */
    PROCEDURE reset_ref_context;

    /**
    * Initializes the referral context
    *
    * @author  Ana Monteiro
    * @version 1.0
    * @since   10-01-2013
    */
    PROCEDURE init_ref_context;

    /**
    * Fucntion to evaluate an expression
    *
    * @author  Ana Monteiro
    * @version 1.0
    * @since   19-06-2013
    */
    FUNCTION eval(i_expr IN VARCHAR2) RETURN VARCHAR2;

    /**
    * Get defualt health plan id (SNS)
    * 
    * @author  Anna Kurowska
    * @version 1.0
    * @since   18-12-2020
    **/
    FUNCTION get_default_health_plan(i_prof IN profissional) RETURN health_plan.id_health_plan%TYPE;
    /**
    * Get other health plan id (SNS)
    * 
    * @author  Anna Kurowska
    * @version 1.0
    * @since   18-12-2020
    **/
    FUNCTION get_health_plan_other(i_prof IN profissional) RETURN health_plan.id_health_plan%TYPE;

    FUNCTION get_icon_request_type(i_id_p1_external_request p1_external_request.id_external_request%TYPE) RETURN VARCHAR2;

    FUNCTION get_id_report(i_id_p1_external_request p1_external_request.id_external_request%TYPE) RETURN NUMBER;

    FUNCTION get_id_completion(i_id_p1_external_request p1_external_request.id_external_request%TYPE) RETURN NUMBER;

END pk_ref_utils;
/
