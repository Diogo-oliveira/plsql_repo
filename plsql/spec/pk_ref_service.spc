/*-- Last Change Revision: $Rev: 2028914 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:43 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ref_service AS

    /**
    * Service to create or update a referral
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof                 Professional, institution and software ids
    * @param   i_ext_req              Referral identifier
    * @param   i_dt_modified          Date of last change, as returned in pk_ref_service.get_referral
    * @param   i_id_patient           Patient identifier
    * @param   i_speciality           Referral speciality identifier (P1_SPECIALITY)
    * @param   i_id_dep_clin_serv     Department/clinical_service identifier
    * @param   i_req_type             M)anual; Using clinical (P)rotocol
    * @param   i_flg_type             Referral type
    * @param   i_flg_priority urgent/not urgent
    * @param   i_flg_home home consultation?
    * @param   i_inst_orig            Origin institution identifier (can be different from i_prof.institution in case of 'at hospital entrance' referrals)
    * @param   i_inst_dest            Destination institution identifier
    * @param   i_problems             Problems identifier to be addressed
    * @param   i_problems_desc        Problems descriptions to be addressed
    * @param   i_dt_problem_begin     Problem onset
    * @param   i_detail               Referral detail info. For each detail: [id_detail|flg_type|text|flg|id_group]
    * @param   i_diagnosis            Referral Diagnosis
    * @param   i_completed            Referral data is completeded?
    * @param   i_id_tasks           Referral tasks needed for (S)cheduling. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done
    * @param   i_id_info            Referral tasks needed for (C)onsultation. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done    
    * @param   i_epis                 Episode identifier    
    * @param   i_workflow             Referral workflow identifier    
    * @param   i_num_order            Num order of the professional that requested the referral (at hospital entrance workflow)
    * @param   i_prof_name            Name of the professional that requested the referral (at hospital entrance workflow)
    * @param   i_prof_id              Identifier of the professional that requested the referral, if registered in db (at hospital entrance workflow)
    * @param   i_institution_name     Institution name where the referral was requested (at hospital entrance workflow)
    * @param   i_external_sys external system identifier that is creating the referral    
    * @param   i_comments             Referral comments   
    * @param   o_id_external_request  Referral identifier
    * @param   o_flg_show show message (Y/N)
    * @param   o_msg message text
    * @param   o_msg_title message title
    * @param   o_button type of button to show with message
    * @param   O_ERROR an error message, set when return=false
    *
    * @value   i_req_type             {*} M-Manual {*} P-Using clinical Protocol
    * @value   i_flg_type             {*} C-Appointments {*} A-Lab tests {*} I-Imaging exams {*} E-Other exams
    *                                 {*} P-Procedures {*} R-Rehabilitation  
    * @value   i_completed            {*} Y- yes {*} N- no
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.1
    * @since   18-04-2007
    */
    FUNCTION insert_referral
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_ext_req          IN p1_external_request.id_external_request%TYPE,
        i_dt_modified      IN VARCHAR2,
        i_id_patient       IN patient.id_patient%TYPE,
        i_speciality       IN p1_speciality.id_speciality%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_req_type         IN p1_external_request.req_type%TYPE,
        i_flg_type         IN p1_external_request.flg_type%TYPE,
        i_flg_priority     IN p1_external_request.flg_priority%TYPE,
        i_flg_home         IN p1_external_request.flg_home%TYPE,
        i_inst_orig        IN p1_external_request.id_inst_orig%TYPE,
        i_inst_dest        IN institution.id_institution%TYPE,
        i_problems         IN CLOB,
        i_dt_problem_begin IN VARCHAR2,
        i_detail           IN table_table_varchar,
        i_diagnosis        IN CLOB,
        i_completed        IN VARCHAR2,
        i_id_tasks         IN table_table_number,
        i_id_info          IN table_table_number,
        i_epis             IN episode.id_episode%TYPE,
        i_workflow         IN wf_workflow.id_workflow%TYPE,
        i_num_order        IN professional.num_order%TYPE DEFAULT NULL,
        i_prof_name        IN professional.name%TYPE DEFAULT NULL,
        i_prof_id          IN ref_orig_data.id_professional%TYPE DEFAULT NULL,
        i_institution_name IN ref_orig_data.institution_name%TYPE DEFAULT NULL,
        i_external_sys     IN external_sys.id_external_sys%TYPE,
        i_comments         IN table_table_clob,
        i_prof_cert        IN VARCHAR2,
        i_prof_first_name  IN VARCHAR2,
        i_prof_surname     IN VARCHAR2,
        i_prof_phone       IN VARCHAR2,
        i_id_fam_rel       IN family_relationship.id_family_relationship%TYPE,
        i_fam_rel_spec     IN VARCHAR2,
        i_name_first_rel   IN VARCHAR2,
        i_name_middle_rel  IN VARCHAR2,
        i_name_last_rel    IN VARCHAR2,
        --Health insurance
        i_health_plan         IN health_plan.id_health_plan%TYPE DEFAULT NULL,
        i_exemption           IN NUMBER DEFAULT NULL,
        o_id_external_request OUT p1_external_request.id_external_request%TYPE,
        o_flg_show            OUT VARCHAR2,
        o_msg                 OUT VARCHAR2,
        o_msg_title           OUT VARCHAR2,
        o_button              OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Insert mdct external request
    *
    * @param   i_lang                     Language associated to the professional executing the request
    * @param   i_prof                     Professional, institution and software ids
    * @param   i_ext_req                  Referral identifier
    * @param   i_workflow                 Referral workflow identifier
    * @param   i_flg_priority_home        Array of priority and home flags home for each mcdt
    * @param   i_mcdt                     Array of selected mcdt, requisitions and institutions
    * @param   i_id_patient               Patient identifier
    * @param   i_req_type                 
    * @param   i_flg_type                 Type of referral
    * @param   i_problems                 Problems identifier to be addressed
    * @param   i_problems_desc            Problems descriptions to be addressed
    * @param   i_dt_problem_begin         Problem onset
    * @param   i_detail                   Array of referral detail info. For each detail: [id_detail|flg_type|text|flg|id_group]
    * @param   i_diagnosis                Array of referral diagnosis
    * @param   i_completed                Flag indicating if the referral is completed
    * @param   i_id_tasks                 Referral tasks needed for (S)cheduling. [ID_TASK|ID_GROUP]
    * @param   i_id_info                  Referral tasks needed for (C)onsultation. [ID_TASK|ID_GROUP]
    * @param   i_epis                     Episode identifier
    * @param   i_date                     Operation date
    * @param   i_codification             Codification identifier of all MCDT being created
    * @param   i_flg_laterality           Array of laterality values for each MCDT
    * @param   i_dt_modified              Date of last change, as returned in pk_ref_service.get_referral
    * @param   o_flg_show                 Show message (Y/N)
    * @param   o_msg                      Message text
    * @param   o_msg_title                Message title
    * @param   o_button                   Type of button to show with message
    * @param   o_ext_req                  Array of referral identifiers being created/updated
    * @param   o_error                    An error message, set when return=false
    *
    * @value   i_flg_type {*} 'A' analysis {*} 'I' Image {*} 'E' Other Exams {*} 'P' Intervention/Procedures {*} 'F' MFR
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Ana Monteiro
    * @version 1.0
    * @since   16-01-2014
    */
    FUNCTION insert_mcdt_referral
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_ext_req                   IN p1_external_request.id_external_request%TYPE,
        i_workflow                  IN wf_workflow.id_workflow%TYPE,
        i_flg_priority_home         IN table_table_varchar,
        i_mcdt                      IN table_table_number,
        i_id_patient                IN patient.id_patient%TYPE,
        i_req_type                  IN p1_external_request.req_type%TYPE,
        i_flg_type                  IN p1_external_request.flg_type%TYPE,
        i_problems                  IN CLOB,
        i_dt_problem_begin          IN VARCHAR2,
        i_detail                    IN table_table_varchar,
        i_diagnosis                 IN CLOB,
        i_completed                 IN VARCHAR2,
        i_id_tasks                  IN table_table_number,
        i_id_info                   IN table_table_number,
        i_epis                      IN episode.id_episode%TYPE,
        i_date                      IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        i_codification              IN codification.id_codification%TYPE,
        i_flg_laterality            IN table_varchar DEFAULT NULL,
        i_dt_modified               IN VARCHAR2,
        i_consent                   IN VARCHAR2,
        i_health_plan               IN table_number DEFAULT NULL,
        i_exemption                 IN table_number DEFAULT NULL,
        i_reason                    IN table_varchar,
        i_complementary_information IN table_varchar,
        i_id_fam_rel                IN family_relationship.id_family_relationship%TYPE DEFAULT NULL,
        i_fam_rel_spec              IN VARCHAR2 DEFAULT NULL,
        i_name_first_rel            IN VARCHAR2 DEFAULT NULL,
        i_name_middle_rel           IN VARCHAR2 DEFAULT NULL,
        i_name_last_rel             IN VARCHAR2 DEFAULT NULL,
        o_flg_show                  OUT VARCHAR2,
        o_msg                       OUT VARCHAR2,
        o_msg_title                 OUT VARCHAR2,
        o_button                    OUT VARCHAR2,
        o_ext_req                   OUT table_number,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancel referral
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Id professional, institution and software    
    * @param   i_workflow       Workflow identifier
    * @param   i_ext_req        Referral id    
    * @param   i_id_patient     Patient id
    * @param   i_id_episode     Episode id        
    * @param   i_notes          Cancelation notes episode id    
    * @param   i_reason         Cancelation reason code    
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Ss
    * @version 1.0
    * @since   17-10-2007
    */
    FUNCTION cancel_referral
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_workflow   IN p1_external_request.id_workflow%TYPE,
        i_ext_req    IN p1_external_request.id_external_request%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_notes      IN VARCHAR2,
        i_reason     IN p1_reason_code.id_reason_code%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns message if there are active (emited and not closed) requests for the
    * patient/speciality provided in the last 30 days.  
    *
    * @param   i_lang language
    * @param   i_prof profissional, institution, software
    * @param   i_id_patient patient id
    * @param   i_spec speciality id
    * @param   i_type if null returns all request, otherwise return for the selected type
    *          ((C)onsulation, (A)nalysis, (E)xam, (I)ntervention)
    * @param   o_flg_show flag que indica se am mensagem o_msg deve ser mostrada
    * @param   o_msg mensagem a mostrar quando a pesquisa devolve mais que o no. max. de pedidos ou quando nao ha resultados
    * @param   o_msg_title titulo a mostrar junto de o_msg
    * @param   o_button tipo de botao disponivel no ecra que mostra a menasagem o_msg
    * @param   o_error an error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 1.0
    * @since   07-12-2007
    */
    FUNCTION get_pat_spec_active_count
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_spec       IN p1_speciality.id_speciality%TYPE,
        i_type       IN p1_external_request.flg_type%TYPE,
        o_flg_show   OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_button     OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns message if there are active (emited and not closed) requests for the
    * patient/i_mcdt provided in the last 30 days.  
    *
    * @param   i_lang language
    * @param   i_prof profissional, institution, software
    * @param   i_id_patient patient id
    * @param   i_mcdt  id_analysis, id_exam, Intervention
    * @param   i_type if null returns all request, otherwise return for the selected type
    *          ((C)onsulation, (A)nalysis, (E)xam, (I)ntervention)
    * @param   o_flg_show flag que indica se am mensagem o_msg deve ser mostrada
    * @param   o_msg mensagem a mostrar quando a pesquisa devolve mais que o no. max. de pedidos ou quando nao ha resultados
    * @param   o_msg_title titulo a mostrar junto de o_msg
    * @param   o_button tipo de botao disponivel no ecra que mostra a menasagem o_msg
    * @param   o_error an error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   19-08-2011
    */
    FUNCTION get_pat_mcdt_active_count
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_mcdt       IN table_number,
        i_type       IN p1_external_request.flg_type%TYPE,
        o_flg_show   OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_button     OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get help data for this speciality (p1_speciality)/institution
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_P1_SPEC request speciality id
    * @param      O_HELP canceling reason id
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  JoÆo S
    * @version 2.0
    * @since   28-11-2006
    */
    FUNCTION get_spec_help
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_p1_spec IN p1_speciality.id_speciality%TYPE,
        i_inst    IN institution.id_institution%TYPE,
        o_help    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get available specialities for requests
    *
    * @param   I_LANG            language associated to the professional executing the request
    * @param   I_PROF            professional, institution and software ids
    * @param   I_PATIENT         patient id, to filter by sex and age   
    * @param   i_flg_availability Referring type: {*} 'I' internal {*} 'E' external   
    * @param   i_external_sys    External system identifier
    * @param   O_SQL             specialities INFO
    * @param   O_ERROR           An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   02-07-2009
    */

    FUNCTION get_clinical_service
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_flg_availability IN VARCHAR2,
        i_external_sys     IN external_sys.id_external_sys%TYPE,
        o_sql              OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get institutions for the selected request speciality
    *
    * @param   I_LANG      Language associated to the professional executing the request
    * @param   I_PROF      Professional, institution and software ids
    * @param   i_flg_availability       Referring type
    * @param   i_external_sys           External system that created the referral   
    * @param   i_id_speciality          Referral speciality identifier
    * @param   i_flg_ref_line           Referral line 1,2,3
    * @param   i_flg_type_ins           Referral network to which it belongs
    * @param   i_flg_inside_ref_area    Flag indicating if is inside referral area or not
    * @param   i_flg_type               Referral type
    * @param   o_sql           Clinical institutions data
    * @param   O_ERROR     An error message, set when return=false
    *
    * @value   i_flg_availability       {*} 'I' internal {*} 'E' external
    * @value   i_flg_inside_ref_area    {*} 'Y' - inside ref area {*} 'N' - otherwise   
    * @value   i_flg_type               {*} 'C' - Appointments {*} 'A' - Lab tests {*} 'I' - Imaging exams 
    *                                   {*} 'E' - Other exams {*} 'P' - Procedures 
    *                                   {*} 'F' - Physical Medicine and Rehabilitation    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 2.0
    * @since   28-11-2006
    */
    FUNCTION get_clinical_institution
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_flg_availability    IN VARCHAR2,
        i_external_sys        IN external_sys.id_external_sys%TYPE,
        i_id_speciality       IN p1_speciality.id_speciality%TYPE,
        i_flg_ref_line        IN ref_dest_institution_spec.flg_ref_line%TYPE DEFAULT NULL,
        i_flg_type_ins        IN p1_dest_institution.flg_type_ins%TYPE DEFAULT NULL,
        i_flg_inside_ref_area IN ref_dest_institution_spec.flg_inside_ref_area%TYPE DEFAULT NULL,
        i_flg_type            IN p1_dest_institution.flg_type%TYPE,
        o_sql                 OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Validates if the professional can add tasks to be executed by the registrar of the origin institution    
    *
    * @param   i_lang         Language identififer
    * @param   i_prof         Professional identififer
    * @param   i_ref          Referral identifier
    * @param   i_inst_orig    Referral orig institution identifier
    * @param   o_can_add      Flag indicating if the professional can add tasks to be executed by the registrar  
    * @param   o_error        An error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise    
    * @author  Ana Monteiro
    * @version 1.0
    * @since   2010-03-25
    */
    FUNCTION can_add_tasks
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_ref       IN p1_external_request.id_external_request%TYPE,
        i_inst_orig IN p1_external_request.id_inst_orig%TYPE,
        o_can_add   OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get referral types: appointment, analysis, exam or intervention
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   O_TYPE avaible request types on REFERAL
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Joana Barroso
    * @version 2.4.3
    * @since   2008/02/11
    */
    FUNCTION get_referral_type
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_type  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get country attributes
    * Used by QueryFlashService.java
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional, institution and software ids
    * @param   i_country country id
    * @param   o_country cursor
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   12-02-2008
    */
    FUNCTION get_country_data
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_country IN country.id_country%TYPE,
        o_country OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get Referral list
    *
    * @param   I_LANG          Language associated to the professional executing the request
    * @param   I_PROF          Professional id, institution and software
    * @param   i_patient       Patient id. Null for all patients
    * @param   i_filter        Filter to apply. Depends on button selected.     
    * @param   i_type          Referral type: {*} (C)onsultation {*} (A)nalysis {*} (I)mage {*} (E)xam {*} (P)rocedure {*} (M)fr {*} Null for all types
    * @param   o_ref_list      Referral data    
    * @param   o_error         An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-07-2009
    */
    FUNCTION get_referral_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_filter   IN VARCHAR2,
        i_type     IN p1_external_request.flg_type%TYPE,
        o_ref_list OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets referral detail
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Professional, institution and software ids
    * @param   i_id_ext_req        Referral identifier
    * @param   i_status_detail     Detail status returned    
    * @param   o_patient           Patient data
    * @param   o_detail            Referral general data
    * @param   o_text              Referral information detail
    * @param   o_problem           Patient problems
    * @param   o_diagnosis         Patient diagnosis
    * @param   o_mcdt              MCDTs information
    * @param   o_needs             Additional needs for scheduling
    * @param   o_info              Additional needs for the appointment
    * @param   o_notes_status      Referral historical data
    * @param   o_notes_status_det  Referral historical data detail
    * @param   o_answer            Referral answer information
    * @param   o_title_status      Deprecated   
    * @param   o_can_cancel        'Y' if the request can be canceled, 'N' otherwise
    * @param   o_ref_orig_data     Referral orig data   
    * @param   o_fields_rank       Cursor with field names and ranks
    * @param   o_error             An error message, set when return=false
    *
    * @value   i_status_detail     {*} 'A' Active {*} 'C' Canceled {*} 'O' Outdated {*} null all details
    * @value   o_can_cancel        {*} 'Y' if the request can be canceled {*} 'N' otherwise
    *   
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.1
    * @since   03-11-2006
    */
    FUNCTION get_referral
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_ext_req       IN p1_external_request.id_external_request%TYPE,
        i_status_detail    IN p1_detail.flg_status%TYPE,
        o_patient          OUT pk_types.cursor_type,
        o_detail           OUT pk_types.cursor_type,
        o_text             OUT pk_types.cursor_type,
        o_problem          OUT pk_types.cursor_type,
        o_diagnosis        OUT pk_types.cursor_type,
        o_mcdt             OUT pk_types.cursor_type,
        o_needs            OUT pk_types.cursor_type,
        o_info             OUT pk_types.cursor_type,
        o_notes_status     OUT pk_types.cursor_type,
        o_notes_status_det OUT pk_types.cursor_type,
        o_answer           OUT pk_types.cursor_type,
        o_title_status     OUT VARCHAR2,
        o_can_cancel       OUT VARCHAR2,
        o_ref_orig_data    OUT pk_types.cursor_type,
        o_ref_comments     OUT pk_types.cursor_type,
        o_fields_rank      OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets referral detail
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   i_id_ext_req        Referral identifier
    * @param   i_status_detail     Detail status returned    
    * @param   o_patient           Patient general data
    * @param   O_DETAIL         Referral general data
    * @param   o_text              Referral information detail
    * @param   o_problem           Patient problems
    * @param   o_diagnosis         Patient diagnosis
    * @param   o_mcdt              MCDTs information
    * @param   o_needs             Additional needs for scheduling
    * @param   o_info              Additional needs for the appointment
    * @param   o_notes_status      Referral historical data
    * @param   o_notes_status_det  Referral historical data detail
    * @param   o_answer            Referral answer information
    * @param   o_title_status      Deprecated   
    * @param   O_CAN_CANCEL 'Y' if the request can be canceled, 'N' otherwise
    * @param   o_ref_orig_data     Referral orig data   
    * @param   o_fields_rank       Cursor with field names and ranks
    * @param   o_error             An error message, set when return=false
    *
    * @value   i_status_detail     {*} 'A' Active {*} 'C' Canceled {*} 'O' Outdated {*} null all details
    * @value   o_can_cancel        {*} 'Y' if the request can be canceled {*} 'N' otherwise
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.1
    * @since   03-11-2006
    */
    FUNCTION get_referral_rep
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_ext_req       IN p1_external_request.id_external_request%TYPE,
        i_status_detail    IN p1_detail.flg_status%TYPE,
        o_patient          OUT pk_types.cursor_type,
        o_detail           OUT pk_types.cursor_type,
        o_text             OUT pk_types.cursor_type,
        o_problem          OUT pk_types.cursor_type,
        o_diagnosis        OUT pk_types.cursor_type,
        o_mcdt             OUT pk_types.cursor_type,
        o_needs            OUT pk_types.cursor_type,
        o_info             OUT pk_types.cursor_type,
        o_notes_status     OUT pk_types.cursor_type,
        o_notes_status_det OUT pk_types.cursor_type,
        o_answer           OUT pk_types.cursor_type,
        o_title_status     OUT VARCHAR2,
        o_can_cancel       OUT VARCHAR2,
        o_ref_orig_data    OUT pk_types.cursor_type,
        o_fields_rank      OUT pk_types.cursor_type,
        o_med_dest_data    OUT pk_types.cursor_type,
        --o_ref_comments     OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets referral cancellation request data to be shown in the brief screen
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional id, institution and software
    * @param   I_ID_REF         Referral identifier
    * @param   I_ID_ACTION      Action identifier. This Parameter will be used to return o_c_req_answ
    * @param   O_REF_DATA       Referral data nedded for the cancellation request brief screen
    * @param   O_C_REQ_DATA     Cancellation request data
    * @param   O_C_REQ_ANSW     Cancellation request answer
    * @param   O_ERROR          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   17-09-2010
    */
    FUNCTION get_referral_req_cancel
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_ref     IN p1_external_request.id_external_request%TYPE,
        i_id_action  IN wf_action.id_action%TYPE,
        o_ref_data   OUT pk_types.cursor_type,
        o_c_req_data OUT pk_types.cursor_type,
        o_c_req_answ OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_doctor_test
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_doc   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_sched_test
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        i_doc     IN professional.id_professional%TYPE,
        i_date    IN VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_efectiv_test
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get patient social attributes
    * Used by QueryFlashService.
    * @param   i_lang language associated to the professional executing the request
    * @param   i_id_pat Patient id
    * @param   i_prof professional, institution and software ids
    * @param   o_pat patient attributes
    * @param   o_sns "Sistema Nacional de Saude" data
    * @param   o_seq_num external system id for this patient (available if has match)    
    * @param   o_photo url for patient photo    
    * @param   o_id patient id document data (number, expiration date, etc)  
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   19-10-2006
    */
    FUNCTION get_pat_soc_att
    (
        i_lang    IN language.id_language%TYPE,
        i_id_pat  IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        o_pat     OUT pk_types.cursor_type,
        o_sns     OUT pk_types.cursor_type,
        o_seq_num OUT p1_match.sequential_number%TYPE,
        o_photo   OUT VARCHAR2,
        o_id      OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Return available tasks
    *
    * @param   i_lang language
    * @param   i_type task type. For (S)cheduling or (C)onsultation
    * @param   o_tasks returned tasks for type S
    * @param   o_info returned tasks for type C
    * @param   o_error error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  JoÆo S 
    * @version 1.0
    * @since
    */
    FUNCTION get_tasks
    (
        i_lang  IN language.id_language%TYPE,
        i_type  IN VARCHAR2,
        o_tasks OUT pk_types.cursor_type,
        o_info  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Pesquisar por pedidos
    *
    * @param I_LANG Lingua registada como preferencia do profissional
    * @param I_ID_SYS_BTN_CRIT Lista de ID'S de crit¨rios de pesquisa.
    * @param I_CRIT_VAL lista de valores dos crit¨rios de pesquisa
    * @param I_PROF profissional q regista
    * @param I_PROF_CAT_TYPE Tipo de categoria do profissional, tal como e retornada em PK_LOGIN.GET_PROF_PREF
    * @param o_flg_show flag que indica se am mensagem o_msg deve ser mostrada
    * @param o_msg mensagem a mostrar quando a pesquisa devolve mais que o no. max. de pedidos ou quando nao ha resultados
    * @param o_msg_title titulo a mostrar junto de o_msg
    * @param o_button tipo de botao disponivel no ecra que mostra a menasagem o_msg
    * @param O_PAT - resultados
    * @param O_ERROR - erro
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 2.0
    * @since   27-05-2008
    * @modify Joana Barroso 2008-05-06 movo perfil director de CS
    */
    FUNCTION get_search_ref
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Pesquisar pelos meus pedidos
    *
    * @param I_LANG Lingua registada como preferencia do profissional
    * @param I_ID_SYS_BTN_CRIT Lista de ID'S de crit¨rios de pesquisa.
    * @param I_CRIT_VAL lista de valores dos crit¨rios de pesquisa
    * @param I_PROF profissional q regista
    * @param I_PROF_CAT_TYPE Tipo de categoria do profissional, tal como e retornada em PK_LOGIN.GET_PROF_PREF
    * @param o_flg_show flag que indica se am mensagem o_msg deve ser mostrada
    * @param o_msg mensagem a mostrar quando a pesquisa devolve mais que o no. max. de pedidos ou quando nao ha resultados
    * @param o_msg_title titulo a mostrar junto de o_msg
    * @param o_button tipo de botao disponivel no ecra que mostra a menasagem o_msg
    * @param O_PAT - resultados
    * @param O_ERROR - erro
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   19-11-2006
    */
    FUNCTION get_search_my_ref
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Pesquisar por pacientes
    *
    * @param I_LANG Lingua registada como preferencia do profissional
    * @param I_ID_SYS_BTN_CRIT Lista de ID'S de crit¨rios de pesquisa.
    * @param I_CRIT_VAL lista de valores dos crit¨rios de pesquisa
    * @param I_PROF profissional q regista
    * @param I_PROF_CAT_TYPE Tipo de categoria do profissional, tal como e retornada em PK_LOGIN.GET_PROF_PREF
    * @param o_flg_show flag que indica se am mensagem o_msg deve ser mostrada
    * @param o_msg mensagem a mostrar quando a pesquisa devolve mais que o no. max. de pedidos ou quando nao ha resultados
    * @param o_msg_title titulo a mostrar junto de o_msg
    * @param o_button tipo de botao disponivel no ecra que mostra a menasagem o_msg
    * @param O_PAT - resultados
    * @param O_ERROR - erro
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   19-11-2006
    */
    FUNCTION get_search_pat
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the options for the professional.
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   i_workflow       Workflow identifier
    * @param   i_id_ext_req     Referral id
    * @param   I_DT_MODIFIED    Last modified date as provided by get_referral
    * @param   i_workflow       Workflow identifier   
    * @param   O_STATUS         Options list
    * @param   O_FLG_SHOW       {*} 'Y' referral has been changed {*} 'N' otherwise
    * @param   O_MSG_TITLE      Message title
    * @param   O_MSG            Message text
    * @param   o_button         Type of button to show with message
    * @param   O_ERROR          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Lu¡s Gaspar
    * @version 1.0
    * @since   25-10-2006
    * @modify  Ana Monteiro 2009-01-19 ALERT-13289
    */
    FUNCTION get_status_options
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_workflow    IN p1_external_request.id_workflow%TYPE,
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
    * Since version 1.1 (12-04-2007) checks for changes using dt_last_interaction
    *
    * @param   I_LANG                Language associated to the professional executing the request
    * @param   I_PROF                Professional, institution and software ids
    * @param   i_workflow            Workflow identifier    
    * @param   i_ext_req             Referral identifier
    * @param   i_status_begin        Begin Transition status
    * @param   i_status_end          End Transition status
    * @param   i_level               Referral decision urgency level    
    * @param   i_prof_dest           Dest professional id (when forwarding or scheduling the request)   
    * @param   i_dcs                 Service id, used when changing clinical service
    * @param   i_notes               Notes related to transition
    * @param   i_dt_modified         Last modified date as provided by get_referral
    * @param   i_mode                (V)alidate date modified or do(N)t
    * @param   i_reason_code         Decline or refuse reason code 
    * @param   i_subtype             Flag used to mark refusals made by the interface
    * @param   i_inst_dest           Id of new institution, used when changing institution    
    * @param   i_action              To be removed when usgin workflow framework for all workflows
    * @param   o_flg_show            Flag indicating if o_msg is shown
    * @param   o_msg                 Message indicating that referral has been changed
    * @param   o_msg_title           Message title
    * @param   o_button              Button type    
    * @param   o_error               An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.1
    * @since   23-06-2009
    */
    FUNCTION set_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_workflow     IN p1_external_request.id_workflow%TYPE,
        i_ext_req      IN p1_external_request.id_external_request%TYPE,
        i_status_begin IN p1_external_request.flg_status%TYPE,
        i_status_end   IN p1_external_request.flg_status%TYPE,
        i_level        IN p1_external_request.decision_urg_level%TYPE,
        i_prof_dest    IN professional.id_professional%TYPE,
        i_dcs          IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_notes        IN p1_detail.text%TYPE,
        i_dt_modified  IN VARCHAR2,
        i_mode         IN VARCHAR2,
        i_reason_code  IN p1_reason_code.id_reason_code%TYPE,
        i_subtype      IN p1_tracking.flg_subtype%TYPE,
        i_inst_dest    IN institution.id_institution%TYPE,
        i_action       IN VARCHAR2, -- to be removed when usgin workflow framework for all workflows
        o_flg_show     OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_msg          OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get Decline, Refusal ou Canceling reason codes list
    *
    * @param   I_LANG language          Associated to the professional executing the request
    * @param   I_PROF                   Professional, institution and software ids    
    * @param   i_workflow               Workflow identifier   
    * @param   i_type                   Reason codes type: {*} 'C' cancelation {*} 'D' decline {*} 'R' refusal
    * @param   o_reasons                Return data
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Ss
    * @version 1.0
    * @since   17-10-2007
    */
    FUNCTION get_reason_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_type    IN p1_reason_code.flg_type%TYPE,
        o_reasons OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get Decline, Refusal ou Canceling reason codes list
    *
    * @param   I_LANG language          Associated to the professional executing the request
    * @param   I_PROF                   Professional, institution and software ids    
    * @param   i_workflow               Workflow identification   
    * @param   i_type                   Reason codes type: {*} 'C' cancelation {*} 'D' decline {*} 'R' refusal
    * @param   o_reasons                Return data
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   17-10-2007
    */
    FUNCTION get_mcdt_reason_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_type    IN p1_reason_code.flg_type%TYPE,
        o_reasons OUT pk_types.cursor_type,
        o_error   OUT t_error_out
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
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        o_count   OUT NUMBER,
        o_id      OUT dep_clin_serv.id_dep_clin_serv%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Lists all tasks related to p1 by doctor
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_workflow       Referral workflow identifier
    * @param   i_ext_req        Referral identifier
    * @param   o_tasks          Array of tasks for schedule
    * @param   o_info           Array of tasks for appointment
    * @param   o_notes          Notes related to each task
    * @param   o_editable       Check if referral is editable
    * @param   o_error          An error message, set when return=false
    *
    * @value   o_editable       {*} 'Y' - referral is editable {*} 'N' - otherwise
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 1.1
    * @since   29-03-2007
    */
    FUNCTION get_tasks_done
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_workflow IN p1_external_request.id_workflow%TYPE,
        i_ext_req  IN p1_external_request.id_external_request%TYPE,
        o_tasks    OUT pk_types.cursor_type,
        o_info     OUT pk_types.cursor_type,
        o_notes    OUT pk_types.cursor_type,
        o_editable OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Update status of tasks for the request (replaces UPD_TASKS_DONE)
    *
    * @param   I_LANG            Language
    * @param   I_PROF            Profissional, institution, software
    * @param   i_workflow        Workflow identifier    
    * @param   i_ext_req         Request id
    * @param   I_ID_TASKS        Array of tasks ids
    * @param   I_FLG_STATUS_INI  Array tasks initial status
    * @param   I_FLG_STATUS_FIN  Array tasks final status
    * @param   i_notes           Notes     
    * @param   O_ERROR           An error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 1.1
    * @since   29-03-2007
    */
    FUNCTION update_tasks_done
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_workflow       IN p1_external_request.id_workflow%TYPE,
        i_ext_req        IN p1_external_request.id_external_request%TYPE,
        i_id_tasks       IN table_number,
        i_flg_status_ini IN table_varchar,
        i_flg_status_fin IN table_varchar,
        i_notes          IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Sets the connection between the patient id and the hospital process
    * Calls set_match internal and commits.
    *
    * @param   I_LANG          Language associated to the professional executing the request
    * @param   I_PROF          Professional id, institution and software
    * @param   I_PAT           Patient identifier
    * @param   I_SEQ_NUM       External system id
    * @param   I_CLIN_REC      Patient process number on the institution, if available.
    * @param   O_ERROR         An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  JoÆo S
    * @version 2.0
    * @since   28-11-2006
    */
    FUNCTION set_match
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_pat      IN patient.id_patient%TYPE,
        i_seq_num  IN p1_match.sequential_number%TYPE,
        i_clin_rec IN clin_record.num_clin_record%TYPE,
        i_epis     IN episode.id_episode%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets clinical_services (the ids are dep_clin_serv) available for forwarding the request. 
    *
    * @param   I_LANG          Language associated to the professional executing the request
    * @param   I_PROF          Professional id, institution and software
    * @param   i_ext_req       Referral id
    * @param   i_dep           Department id    
    * @param   o_clin_serv     Dep_clin_serv ids and clinical services description    
    * @param   O_ERROR         An error message, set when return=false    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   29-04-2008
    */
    FUNCTION get_clin_serv_fwd_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_ext_req   IN p1_external_request.id_external_request%TYPE,
        i_dep       IN department.id_department%TYPE,
        o_clin_serv OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets departments available for forwarding the request. 
    *
    * @param   I_LANG          Language associated to the professional executing the request
    * @param   I_PROF          Professional id, institution and software
    * @param   i_ext_req       Referral id
    * @param   o_dep           Department ids and description    
    * @param   O_ERROR         An error message, set when return=false    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   29-04-2008
    */
    FUNCTION get_dep_fwd_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        o_dep     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

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
        i_dcs_except   IN p1_external_request.id_dep_clin_serv%TYPE,
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
        i_dcs_except   IN p1_external_request.id_dep_clin_serv%TYPE,
        o_cs           OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the list of professionals available for scheduling.
    *
    * @param   i_lang             Language id
    * @param   i_prof             Professional, institution, software
    * @param   i_dep_clin_serv dep_clin_serv id for the scheduling beeing requested
    * @param   i_external_sys     External system identifier
    * @param   i_dep service id (DEPARTMENT)
    * @param   O_CS specialities list (CLINICAL_SERVICES)
    * @param   O_ERROR an error message, set when return=false
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
    * Returns the list of available institutions to forward the referral.
    * The institutions must belong to the same hospital centre.
    * Notice that if the parameter INST_FORWARD_TYPE is (I)nstitution then the destination institution
    * must accept requests for the referral speciality.
    * If that parameter is (C)linical service then all institutions from the hospital centre that accept
    * any kind of referrals (all configured in p1_spec_dep_clin_serv) are listed 
    *
    * @param   i_lang language
    * @param   i_prof profissional, institution, software
    * @param   i_ext_req request id
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
    * Insert consultation doctor 
    *
    * @param   I_LANG             Language associated to the professional executing the request
    * @param   I_PROF             Professional, institution and software ids
    * @param   i_workflow         Workflow identifier   
    * @param   i_exr              External request id
    * @param   i_diagnosis        Selected diagnosis
    * @param   i_diag_desc        Diagnosis description, when entered in text mode
    * @param   i_answer           Observation, Therapy, Exam and Conclusion
    * @param   i_health_prob      Select Health Problem 
    * @param   i_health_prob_desc Health Problem description, when entered in text mode        
    * @param   o_error            An error message, set when return=false
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
        i_workflow         IN p1_external_request.id_workflow%TYPE,
        i_exr              IN p1_external_request.id_external_request%TYPE,
        i_diagnosis        IN table_number,
        i_diag_desc        IN table_varchar,
        i_answer           IN table_table_varchar,
        i_health_prob      IN table_number DEFAULT NULL,
        i_health_prob_desc IN table_varchar DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Return referral clinical services (just for internal referrals)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids 
    * @param   i_pat            Patient id, to filter by sex and age
    * @param   i_external_sys   External system identifier
    * @param   o_cs             Clinical Service info    
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   01-07-2009 
    */
    FUNCTION get_internal_spec
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_pat   IN patient.id_patient%TYPE,
        i_dep   IN department.id_department%TYPE,
        o_cs    OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get referal types: Internal or external
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   O_TYPE_ext avaible external REFERAL
    * @param   O_TYPE_int avaible REFERAL
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Joana Barroso
    * @version 2.5.0.6
    * @since   2009/08/17
    */
    FUNCTION get_referral_ie
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_type_ext OUT pk_types.cursor_type,
        o_type_int OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets referral completion options.
    * This function is used when creating one or multiple requests.
    *
    * @param   i_lang          Language associated to the professional executing the request
    * @param   i_prof          Id professional, institution and software    
    * @param   i_patient       Patient identifier   
    * @param   i_epis          Episode identifier
    * @param   i_codification  Codification identifiers   
    * @param   i_inst_dest     Referrals destination institutions
    * @param   i_flg_type      Referral type: {*} 'C' Consultation {*} 'A' Analysis {*} 'I' Image {*} 'E' Exam {*} 'P' Procedure {*} 'F' MFR    
    * @param   o_options       Referrals completion options
    * @param   O_ERROR         An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   27-08-2009
    *
    * @changed by: Ricardo Patrocínio
    * @changed in: 2009-11-06
    * @change reason: [ALERT-54754]
    */
    /*
    FUNCTION get_completion_options
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_epis         IN episode.id_episode%TYPE,
        i_codification IN table_number,
        i_inst_dest    IN table_number,
        i_flg_type     IN p1_external_request.flg_type%TYPE,
        i_spec         IN p1_speciality.id_speciality%TYPE,
        o_options      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    */

    /**
    * Gets referral completion options.
    * This function is used when creating one or multiple requests.
    *
    * @param   i_lang          Language associated to the professional executing the request
    * @param   i_prof          Id professional, institution and software    
    * @param   i_patient       Patient identifier   
    * @param   i_codification  Codification identifiers   
    * @param   i_inst_dest     Referrals destination institutions
    * @param   i_flg_type      Referral type: {*} 'C' Consultation {*} 'A' Analysis {*} 'I' Image {*} 'E' Exam {*} 'P' Procedure {*} 'F' MFR    
    * @param   o_options       Referrals completion options
    * @param   O_ERROR         An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   27-08-2009
    *
    * @changed by: Ricardo Patrocínio
    * @changed in: 2009-11-06
    * @change reason: [ALERT-54754]
    */
    /*
    FUNCTION get_completion_options
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_codification IN table_number,
        i_inst_dest    IN table_number,
        i_flg_type     IN p1_external_request.flg_type%TYPE,
        i_spec         IN p1_speciality.id_speciality%TYPE,
        o_options      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    */

    /**
    * Gets referral completion options.
    * Pop-up reformulation after development print list functionality
    *
    * @param   i_lang               preferred language id for this professional
    * @param   i_prof               professional id structure
    * @param   i_patient            Patient identifier
    * @param   i_epis               Episode identifier
    * @param   i_codification       Codification identifiers   
    * @param   i_inst_dest          Referrals destination institutions
    * @param   i_flg_type           Referral type    
    * @param   i_spec               Referral speciality (in case of consultation referral type) or id_mcdt (in case of mcdt referral type: Id_Analysis, Exam.id_exam or Intervention.id_intervention)
    * @param   o_options            Referrals completion options
    * @param   o_print_options      Reports available to print the referral
    * @param   o_flg_show_popup     Flag that indicates if the pop-up is shown or not. If not, default option is assumed
    * @param   o_error              An error message, set when return=false
    *
    * @value   i_flg_type           {*} 'C' Consultation 
    *                               {*} 'A' Lab tests 
    *                               {*} 'I' Imaging exams
    *                               {*} 'E' Other exams
    *                               {*} 'P' Procedure
    *                               {*} 'F' Rehab
    *
    * @value   o_flg_show_popup     {*} 'Y' the pop-up is shown 
    *                               {*} 'N' otherwise
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   06-10-2014
    */
    FUNCTION get_completion_options
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_epis           IN episode.id_episode%TYPE,
        i_codification   IN table_number,
        i_inst_dest      IN table_number,
        i_flg_type       IN p1_external_request.flg_type%TYPE,
        i_spec           IN ref_completion_cfg.id_mcdt%TYPE,
        o_options        OUT pk_types.cursor_type,
        o_print_options  OUT pk_types.cursor_type,
        o_flg_show_popup OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if the given option is available for concluding the request.
    *
    * @param   i_lang          Language associated to the professional executing the request
    * @param   i_prof          Id professional, institution and software    
    * @param   i_patient       Patient identifier   
    * @param   i_epis          Episode identifier
    * @param   i_codification  Codification identifiers   
    * @param   i_inst_dest     Referrals destination institutions
    * @param   i_flg_type      Referral type: {*} 'C' Consultation {*} 'A' Analysis {*} 'I' Image {*} 'E' Exam {*} 'P' Procedure {*} 'F' MFR    
    * @param   i_option        Completion option identifier to be validated
    * @param   o_flg_available Option availability {*} 'Y' - available  {*} 'N' - otherwise
    * @param   O_ERROR         An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   25-09-2009
    *
    * @changed by: Ricardo Patrocínio
    * @changed in: 2009-11-06
    * @change reason: [ALERT-54754]
    */
    /* FUNCTION check_completion_option
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_epis          IN episode.id_episode%TYPE,
        i_codification  IN table_number,
        i_inst_dest     IN table_number,
        i_flg_type      IN p1_external_request.flg_type%TYPE,
        i_option        IN ref_completion.id_ref_completion%TYPE,
        i_spec          IN p1_speciality.id_speciality%TYPE,
        o_flg_available OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;*/

    /**
    * Checks if the given option is available for concluding the request.
    *
    * @param   i_lang          Language associated to the professional executing the request
    * @param   i_prof          Id professional, institution and software    
    * @param   i_patient       Patient identifier   
    * @param   i_codification  Codification identifiers   
    * @param   i_inst_dest     Referrals destination institutions
    * @param   i_flg_type      Referral type: {*} 'C' Consultation {*} 'A' Analysis {*} 'I' Image {*} 'E' Exam {*} 'P' Procedure {*} 'F' MFR    
    * @param   i_option        Completion option identifier to be validated
    * @param   o_flg_available Option availability {*} 'Y' - available  {*} 'N' - otherwise
    * @param   O_ERROR         An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   25-09-2009
    *
    * @changed by: Ricardo Patrocínio
    * @changed in: 2009-11-06
    * @change reason: [ALERT-54754]
    */
    FUNCTION check_completion_option
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_codification  IN table_number,
        i_inst_dest     IN table_number,
        i_flg_type      IN p1_external_request.flg_type%TYPE,
        i_option        IN ref_completion.id_ref_completion%TYPE,
        i_spec          IN p1_speciality.id_speciality%TYPE,
        o_flg_available OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if referral can be sent to dest institution: all analysis req are ready to be sent
    *
    * @param   i_lang                Language associated to the professional executing the request
    * @param   i_prof                Id professional, institution and software    
    * @param   i_analysis_req_det    Analysis req detail identifier    
    * @param   o_flg_completed       Flag indicating if all analysis workflow are completed in professionl institution
    * @param   O_ERROR               An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   31-08-2009
    */
    FUNCTION check_ref_completed
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN table_number,
        o_flg_completed    OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get Id_external_request nad Checks if referral can be sent to dest institution: all analysis req are ready to be sent
    *
    * @param   i_lang                Language associated to the professional executing the request
    * @param   i_prof                Id professional, institution and software    
    * @param   i_analysis_req_det    Analysis req detail identifier    
    * @param   o_sql                 Id_external_request and flg_completed
    * @param   O_ERROR               An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   09-09-2009
    */
    FUNCTION get_ref_analysis_req_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN table_number,
        o_sql              OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets codification list: identifier and description
    *
    * @param   i_lang                Language associated to the professional executing the request
    * @param   i_prof                Id professional, institution and software        
    * @param   i_type                MCDT type: {*} (A)nalysis {*} (I)mage {*} (E)xam {*} (P)rocedure {*} (M)fr
    * @param   o_list                Codification list: identifier and desccription
    * @param   O_ERROR               An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   01-09-2009
    */
    FUNCTION get_codification_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_type  IN p1_external_request.flg_type%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get id_codification
    *
    * @param i_lang                       professional language
    * @param i_prof                       professional id, institution and software
    * @param i_ref_type                   referral type
    * @param i_mcdt_codification          id from the mcdt codifications
    * @param o_codification               id codifications
    * @param o_error         
    * 
    * @value i_ref_type {*}'A' Analyis {*}'E' Exams {*}'I' Image {*}'P' Interventions {*}'F' fisiatrics
    * @return                             TRUE if sucess, FALSE otherwise
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   03-09-2009
    */

    FUNCTION srv_get_codification
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_ref_type          IN p1_external_request.flg_type%TYPE,
        i_mcdt_codification IN analysis_codification.id_analysis_codification%TYPE,
        o_codification      OUT codification.id_codification%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets list of patient referrals available for scheduling
    * Used by scheduler.
    *
    * @param   i_lang  language
    * @param   i_prof  profissional, institution, software
    * @param   i_id_patient patient id
    * @param   i_type if null returns all request, otherwise return for the selected type
    *          ((C)onsulation, (A)nalysis, (E)xam, (I)ntervention)
    * @param   i_schedule      Schedule identifier
    * @param   o_p1 returned referral list
    * @param   o_message message to return
    * @param   o_title  message type
    * @param   o_button button message
    * @param   o_error an error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   23-10-2009
    */
    FUNCTION get_pat_ref_to_schedule
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_type       IN table_varchar,
        i_schedule   IN schedule.id_schedule%TYPE,
        o_p1         OUT pk_types.cursor_type,
        o_message    OUT VARCHAR2,
        o_title      OUT VARCHAR2,
        o_buttons    OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets Linked episodes
    *
    * @param   i_lang  language
    * @param   i_prof  profissional, institution, software
    * @param   i_ref   id referral
    * @param   o_liked_epis  linked episodes
    * @param   o_error an error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   30-10-2009
    */
    FUNCTION get_linked_episodes
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_ref        IN p1_external_request.id_external_request%TYPE,
        o_liked_epis OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Updates referral status
    *
    * @param   i_lang         Language associated to the professional executing the request
    * @param   i_prof         Id professional, institution and software    
    * @param   i_ext_req      Referral id              
    * @param   i_schedule     Schedule identifier
    * @param   i_status       (S)chedule, (E)fectivation, (M)ailed, appointment (C)anceled  and (F)ailed appointment  
    * @param   i_notes        Notes       
    * @param   i_reschedule   Indicates if referral was scheduled
    * @param   i_episode      Episode identifier (used by scheduler when scheduling ORIS/INP referral)
    * @param   o_error        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   04-11-2009
    */
    FUNCTION update_referral_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ext_req        IN p1_external_request.id_external_request%TYPE,
        i_schedule       IN schedule.id_schedule%TYPE,
        i_status         IN p1_external_request.flg_status%TYPE,
        i_notes          IN p1_detail.text%TYPE,
        i_reschedule     IN VARCHAR2,
        i_episode        IN episode.id_episode%TYPE,
        i_id_reason_code IN p1_reason_code.id_reason_code%TYPE DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Validates if the professional can create referrals and returns labels showing the type of referrals that can be created
    *
    * @param   i_lang         Language identififer
    * @param   i_prof         Professional identififer
    * @param   i_id_patient   Patient identififer
    * @param   i_external_sys External system identifier
    * @param   o_cursor       Labels showing the type of referrals that can be created  
    * @param   o_error        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   03-10-2012
    */
    FUNCTION check_ref_creation
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE,
        i_external_sys IN external_sys.id_external_sys%TYPE,
        o_cursor       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Check if a professional can create referrals 
    *
    * @param   i_lang          Language associated to the professional executing the request
    * @param   i_prof          Professional id, institution and software
    * @param   o_valid         {*}Y if can create referral  {*} N if can't create referral  
    * @param   o_error         Error message, set when return=false
    * 
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   14-12-2009
    */
    FUNCTION get_instit_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_inst  OUT pk_types.cursor_type,
        o_other OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get professional data
    *
    * @param   i_lang          Language associated to the professional executing the request
    * @param   i_prof          Professional id, institution and software
    * @param   i_num_order     Professional NUM ORDER 
    * @param   o_prof         pProfessional data  
    * @param   o_error         Error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   15-12-2009
    */
    FUNCTION get_prof_data
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_num_order IN professional.num_order%TYPE,
        o_prof      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Associates a referral to a schedule. Changes referral status accordingly.
    *
    * @param   i_lang     Language identifier
    * @param   i_prof     Professional identifier, institution and software    
    * @param   i_id_ref   Referral identifier               
    * @param   i_schedule Schedule identifier
    * @param   i_notes    Notes       
    * @param   i_episode  Episode identifier (used by scheduler when scheduling ORIS/INP referral)
    * @param   o_error    An error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   22-12-2009
    */
    FUNCTION set_ref_schedule
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_ref   IN p1_external_request.id_external_request%TYPE,
        i_schedule IN schedule.id_schedule%TYPE,
        i_notes    IN p1_detail.text%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels association between referral and schedule. Changes referral status accordingly.
    *
    * @param   i_lang     Language identifier
    * @param   i_prof     Professional identifier, institution and software    
    * @param   i_id_ref   Referral identifier               
    * @param   i_schedule Schedule identifier
    * @param   i_notes    Notes       
    * @param   i_date     Operation date
    * @param   o_error    An error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   22-12-2009
    */
    FUNCTION cancel_ref_schedule
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_ref   IN p1_external_request.id_external_request%TYPE,
        i_schedule IN schedule.id_schedule%TYPE,
        i_notes    IN p1_detail.text%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the sys_config option that determines if the destination column is to be shown or not
    *
    * @param   i_lang     Language identifier
    * @param   i_prof     Professional identifier, institution and software  
    * @param   o_show_opt 'Y' or 'N' depending if the destination column is to be shown or not. 
    * @param   o_error    An error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  João Almeida 
    * @version 1.0
    * @since   22-02-2010
    */
    FUNCTION get_screen_dest_option
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_show_opt OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the professional name that is responsible for the referral 
    * Used by reports
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    * @param   i_id_ref        Referral identifier
    * @param   o_prof_data     Professional data that is responsible for the referral
    * @param   o_error         An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   16-04-2010   
    */
    FUNCTION get_prof_resp
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_ref    IN p1_external_request.id_external_request%TYPE,
        o_prof_data OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if referral original institution is private or not
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    * @param   i_id_session    Session identifier that is related to referral temporary data    
    * @param   o_flg_result    Flag indicating if this institution is private or not
    * @param   o_error         An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   30-04-2010
    */
    FUNCTION check_priv_orig_inst
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_session IN ref_ext_session.id_session%TYPE,
        o_flg_result OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if referral is being updated, or not
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    * @param   i_id_session    Session identifier that is related to referral temporary data    
    * @param   o_flg_result    {*} Y - referral is being updated {*} N - referral is being created
    * @param   o_error         An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   19-07-2010
    */
    FUNCTION check_ref_update
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_session IN ref_ext_session.id_session%TYPE,
        o_flg_result OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns patient data from temporary table REF_EXT_XML_DATA.
    * This data is stored on XML format. 
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_id_session     Session identifier
    * @param   i_provider       Provider identifier. {*} REFERRAL {*} P1
    * @param   o_data           Patient data
    * @param   o_health_plan    Patient health plans
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   14-04-2010
    */
    FUNCTION get_patient_data
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_session  IN ref_ext_session.id_session%TYPE,
        i_provider    IN VARCHAR2,
        o_data        OUT pk_types.cursor_type,
        o_health_plan OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns referral data (must be synchronized with function PK_REF_CORE.get_referral) 
    *
    * @param   i_lang                         Language associated to the professional executing the request
    * @param   i_prof                         Professional, institution and software ids
    * @param   i_id_session                   Session identifier
    * @param   i_provider                     Provider identifier. {*} REFERRAL {*} P1
    * @param   o_detail                       Referral general data
    * @param   o_text                         Referral detail data
    * @param   o_problem                      Patient problems to be addressed
    * @param   o_diagnosis                    Referral diagnosis
    * @param   o_mcdt                         Referral MCDT details
    * @param   o_needs                        Referral additional needs: Sent to registrar
    * @param   o_info                         Referral additional needs: Additional information    
    * @param   o_notes_status                 Referral tracking status    
    * @param   o_notes_status_det             Referral tracking status details
    * @param   o_answer                       Referral answer   
    * @param   o_can_cancel                   Flag indicating if referral can be canceled by the professional
    * @param   o_error                        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   20-04-2010
    */
    FUNCTION get_referral_data
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_session       IN ref_ext_session.id_session%TYPE,
        i_provider         IN VARCHAR2,
        o_detail           OUT pk_types.cursor_type,
        o_text             OUT pk_types.cursor_type,
        o_problem          OUT pk_types.cursor_type,
        o_diagnosis        OUT pk_types.cursor_type,
        o_mcdt             OUT pk_types.cursor_type,
        o_needs            OUT pk_types.cursor_type,
        o_info             OUT pk_types.cursor_type,
        o_notes_status     OUT pk_types.cursor_type,
        o_notes_status_det OUT pk_types.cursor_type,
        o_answer           OUT pk_types.cursor_type,
        o_can_cancel       OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Matchs Alert patient with external system patient id
    *
    * @param   i_lang            Professional language identifier
    * @param   i_prof           Professional id, institution and software
    * @param   i_patient         Patient identifier
    * @param   i_id_session     Session identifier 
    * @param   i_provider        Provider identifier. {*} REFERRAL {*} P1
    * @param   i_flg_upd_data    {*} 'Y' to update patient data {*} 'N' otherwise    
    * @param   o_error           Error message    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   14-07-2010
    */
    FUNCTION set_match_session
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_id_session   IN VARCHAR2,
        i_flg_upd_data IN VARCHAR2,
        i_provider     IN VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * This functions updates session table after the referral has been created
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional id, institution and software
    * @param   i_id_session     Session identifier 
    * @param   i_id_ref         Referral identifier that has been created
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if its a valid user, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   18-05-2010
    */
    FUNCTION set_ref_created
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_session IN ref_ext_xml_data.id_session%TYPE,
        i_id_ref     IN p1_external_request.id_external_request%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * This functions notifies INTER-ALERT that the referral was updated
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional id, institution and software
    * @param   i_id_session     Session identifier 
    * @param   i_id_ref         Referral identifier that has been updated
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if its a valid user, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   15-07-2010
    */
    FUNCTION set_ref_updated
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_session IN ref_ext_xml_data.id_session%TYPE,
        i_id_ref     IN p1_external_request.id_external_request%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Actualizar estado dos pedidos apos actualização dos dados de identificação.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_ID_PATIENT Patient id
    * @param   I_PROF professional, institution and software ids
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   21-06-2010
    */
    FUNCTION update_pat_ref
    (
        i_lang       IN language.id_language%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_prof       IN profissional,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * This is called by flash, to ping session identifier
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional id, institution and software
    * @param   i_id_session     Session identifier 
    * @param   i_id_ref         Referral identifier that has been updated
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if its a valid user, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   23-11-2010
    */
    FUNCTION session_ping
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_session IN ref_ext_xml_data.id_session%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get Referral short detail 
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF professional, institution and software ids
    * @param   i_id_external_request 
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   29-06-2010 
    */
    FUNCTION get_ref_detail
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_external_request IN table_number,
        o_detail              OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Is the referral already answered?
    *
    * @param   I_LANG              Language associated to the professional executing the request
    * @param   I_PROF              Professional, institution and software ids
    * @param   I_EPISODE           Id episode 
    * @param   O_ID_EXT_REQ        External Request Identifier 
    * @param   O_WORKFLOW          workflow of the external request
    * @param   O_STATUS_DETAIL     status_detail , null by default
    * @param   O_NEEDS_ANSWER      Does the referral need answer?
    * @param   O_ERROR
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Almeida
    * @version 1.0
    * @since   22-07-2010
    */

    FUNCTION check_ref_answered
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN p1_external_request.id_episode%TYPE,
        o_id_ext_req    OUT p1_external_request.id_external_request%TYPE,
        o_workflow      OUT p1_external_request.id_workflow%TYPE,
        o_status_detail OUT p1_detail.flg_status%TYPE,
        o_needs_answer  OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Changes hand off status
    *
    * @param   I_LANG              Language associated to the professional executing the request
    * @param   I_PROF              Professional, institution and software ids
    * @param   i_referrals           Array of arrays. Each position: --1-id_ref 2-id_prof_transf_owner 3-tr_id_inst_dest 4-id_trans_resp  5-tr_id_workflow 6-tr_id_satus 7-tr_id_prof_dest 8-tr_id_inst_orig 
    * @param   i_id_reason_code      Reason code identifier
    * @param   i_reason_code_text    Reason code text
    * @param   i_notes               Notes
    * @param   i_params              Professional answer
    * @param   o_error               Error information
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Filipe Sousa
    * @version 1.0
    * @since   08-09-2010
    */
    FUNCTION tr_change_to_next_status
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_referrals        IN table_table_varchar,
        i_id_reason_code   IN p1_reason_code.id_reason_code%TYPE,
        i_reason_code_text IN ref_trans_responsibility.reason_code_text%TYPE,
        i_notes            IN ref_trans_responsibility.notes%TYPE,
        i_params           IN table_varchar,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Create referral hand off
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_referrals          Array of referral data, --1- id_external_request 2-id_prof_requested 
    * @param   i_id_reason_code     Reason code identifier
    * @param   i_reason_code_text   Reason code text
    * @param   i_notes              Notes
    * @param   i_prof_dest          Dest professional (in case of WF=10)
    * @param   i_id_inst_dest_tr    Hand off dest institution (in case of WF=11)
    * @param   i_notes              Notes
    * @param   i_id_workflow        Hand off workflow identifier
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Filipe Sousa
    * @version 1.0
    * @since   08-09-2010
    */
    FUNCTION tr_req_new_responsability
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_referrals        IN table_table_varchar,
        i_id_reason_code   IN p1_reason_code.id_reason_code%TYPE,
        i_reason_code_text IN ref_trans_responsibility.reason_code_text%TYPE,
        i_notes            IN ref_trans_responsibility.notes%TYPE,
        i_prof_dest        IN ref_trans_responsibility.id_prof_dest%TYPE,
        i_id_inst_dest_tr  IN ref_trans_responsibility.id_inst_dest_tr%TYPE,
        i_id_workflow      IN ref_trans_responsibility.id_workflow%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets hand off detail and history
    *
    * @param   i_lang          Professional preferred language
    * @param   i_prof          Professional identification and its context (institution and software)
    * @param   i_id_ref        Referral identifier
    * @param   o_ref_det       Referral detail
    * @param   o_tr_orig_det   Hand off active detail (orig institution)
    * @param   o_tr_dest_det   Hand off active detail (dest institution)
    * @param   o_error         Error information
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   29-05-2013
    */
    FUNCTION get_tr_detail
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN ref_trans_responsibility.id_external_request%TYPE,
        o_ref_det     OUT pk_types.cursor_type,
        o_tr_orig_det OUT pk_types.cursor_type,
        o_tr_dest_det OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets hand off detail
    *
    * @param   i_lang          Professional preferred language
    * @param   i_prof          Professional identification and its context (institution and software)
    * @param   i_id_tr_tab     Array of hand off identifiers
    * @param   o_tr_orig_det   Hand off active detail (orig institution)
    * @param   o_tr_dest_det   Hand off active detail (dest institution)
    * @param   o_error         Error information
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   20-08-2013
    */
    FUNCTION get_tr_short_detail
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_tr_tab   IN table_number,
        o_tr_orig_det OUT pk_types.cursor_type,
        o_tr_dest_det OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the list of transitions available from the action previously selected
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Professional, institution and software ids
    * @param   i_id_workflow           Workflow identifier
    * @param   i_id_status             Actual status identifier
    * @param   o_options               Options available
    * @param   o_error                 An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   20-08-2013
    */
    FUNCTION get_tr_options
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_workflow IN ref_trans_responsibility.id_workflow%TYPE,
        i_id_status   IN ref_trans_responsibility.id_status%TYPE,
        o_options     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the priority referral list
    *
    * @param   i_lang      Language associated to the professional executing the request
    * @param   i_prof      Professional, institution and software ids
    * @param   o_list      Priority list   
    * @param   o_error     An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   22-10-2012
    */
    FUNCTION get_priority_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get the speciality
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF professional, institution and software ids
    * @param   i_id_professional 
    * @param   i_id_institution 
    * @param   i_id_software 
    * @param   o_clin_serv
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Filipe Sousa
    * @version 1.0
    * @since   09-09-2010 
    */
    FUNCTION get_clin_serv
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional IN prof_dep_clin_serv.id_professional%TYPE DEFAULT NULL,
        i_id_institution  IN department.id_institution%TYPE DEFAULT NULL,
        i_id_software     IN department.id_software%TYPE DEFAULT NULL,
        o_clin_serv       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get the prof for clin serv 
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF professional, institution and software ids
    * @param   i_id_clinical_service   Clinical service identifier
    * @param   i_id_prof_except_tab    Array of professional identifiers that must not be returned (exceptions)
    * @param   o_prof                  Professionals related to this clinical service
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Filipe Sousa
    * @version 1.0
    * @since   09-09-2010 
    */
    FUNCTION get_prof_for_clin_serv
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_prof_except_tab  IN table_number,
        o_prof                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get if is multi choise
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF professional, institution and software ids
    * @param   i_id_clinical_service 
    * @param   i_id_institution 
    * @param   i_id_software 
    * @param   o_prof
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Filipe Sousa
    * @version 1.0
    * @since   09-09-2010 
    */
    FUNCTION tr_is_multi_prof
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_multi OUT VARCHAR2,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get the Ref type for prof
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF professional, institution and software ids
    * @param   i_id_clinical_service 
    * @param   i_id_institution 
    * @param   i_id_software 
    * @param   o_prof
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Filipe Sousa
    * @version 1.0
    * @since   09-09-2010 
    */
    FUNCTION get_prof_ref_flg_type
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_prof_requested IN table_varchar,
        o_flg_type          OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get the description of hand off workflow status
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF professional, institution and software ids
    * @param   o_status_desc    Workflow status description
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   25-09-2013
    */
    FUNCTION get_handoff_status_desc
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_status_desc OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * GET prof_name
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF professional, institution and software ids
    * @param   o_prof_name               OUT pk_types.cursor_type
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Filipe Sousa
    * @version 1.0
    * @since   09-09-2010 
    */
    FUNCTION get_prof_name
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_prof_id   IN professional.id_professional%TYPE,
        o_prof_name OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * <Function description>
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @param   o_error        Error information
    *
    * @return  <Return value usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   22-09-2010
    */
    FUNCTION dyn_sel
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        tab_name   IN VARCHAR2,
        i_column   IN VARCHAR2,
        field_name IN VARCHAR2,
        val        IN VARCHAR2,
        crs        OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * Gets referral actions available for a subject
    *
    * @param   I_LANG         Language associated to the professional executing the request
    * @param   I_PROF         Professional, institution and software ids
    * @param   I_ID_REF       Referral identifier
    * @param   I_SUBJECT      Subject for grouping of actions   
    * @param   I_FROM_STATE   Begin action state     
    * @param   O_ACTIONS      Referral actions
    * @param   O_ERROR        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   23-09-2010
    */
    FUNCTION get_ref_actions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_ref     IN p1_external_request.id_external_request%TYPE,
        i_subject    IN action.subject%TYPE,
        i_from_state IN action.from_state%TYPE,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets Referral Status F description
    *
    * @param   I_LANG         Language associated to the professional executing the request
    * @param   I_PROF         Professional, institution and software ids
    * @param   I_ID_REF       Referral identifier
    * @param   I_SUBJECT      Subject for grouping of actions   
    * @param   I_FROM_STATE   Begin action state     
    * @param   O_ACTIONS      Referral actions
    * @param   O_ERROR        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Filipe Sousa
    * @version 2.6
    * @since   27-09-2010
    */
    FUNCTION get_ref_f_information
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_professional     IN professional.id_professional%TYPE DEFAULT NULL,
        i_id_external_request IN p1_external_request.id_external_request%TYPE DEFAULT NULL,
        i_id_patient          IN patient.id_patient%TYPE DEFAULT NULL,
        o_cursor              OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets domains for waiting line
    *
    * @param   I_LANG         Language associated to the professional executing the request
    * @param   I_PROF         Professional, institution and software ids
    * @param   i_code_domain              Code domain to get values    
    * @param   i_id_inst_orig             Referral origin institution
    * @param   i_id_inst_dest             Referral dest institution    
    * @param   i_flg_default              Indicates if institution is default or not
    * @param   i_flg_type                 Referral type     
    * @param   i_flg_inside_ref_area      Flag indicating if is inside referral area or not
    * @param   i_flg_ref_line             Referral line 1,2,3
    * @param   i_flg_type_ins             Referral network to which it belongs
    * @param   i_id_speciality            Referral speciality
    * @param   i_external_sys             External system that created referral
    * @param   i_flg_availability       Referring type                     
    * @param   o_data                     Domains information
    * @param   O_ERROR        An error message, set when return=false
    *
    * @value   i_flg_default              {*} 'Y' - Default institution {*} 'N' - otherwise
    * @value   i_flg_type                 {*} 'C'- Consultation {*} 'A'- Analysis {*} 'I'- Image {*} 'E'- Exam
    *                                     {*} 'P'- Procedure {*} 'F'- Physiatrics
    * @value   i_flg_inside_ref_area      {*} 'Y' - inside ref area {*} 'N' - otherwise
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Filipe Sousa
    * @version 2.6
    * @since   07-10-2010
    */
    FUNCTION prwl_get_domains
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_code_domain         IN sys_domain.code_domain%TYPE,
        i_id_inst_orig        IN p1_dest_institution.id_inst_orig%TYPE DEFAULT NULL,
        i_id_inst_dest        IN p1_dest_institution.id_inst_dest%TYPE DEFAULT NULL,
        i_flg_default         IN p1_dest_institution.flg_default%TYPE DEFAULT NULL,
        i_flg_type            IN p1_dest_institution.flg_type%TYPE DEFAULT NULL,
        i_flg_inside_ref_area IN ref_dest_institution_spec.flg_inside_ref_area%TYPE DEFAULT NULL,
        i_flg_ref_line        IN ref_dest_institution_spec.flg_ref_line%TYPE DEFAULT NULL,
        i_flg_type_ins        IN p1_dest_institution.flg_type_ins%TYPE DEFAULT NULL,
        i_id_speciality       IN p1_speciality.id_speciality%TYPE DEFAULT NULL,
        i_external_sys        IN external_sys.id_external_sys%TYPE,
        i_flg_availability    IN VARCHAR2,
        o_data                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get professionals available for schedule
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Professional, institution and software ids
    * @param   i_spec              P1_SPECIALITY Id
    * @param   i_inst_dest         Institution Id
    * @param   o_sql               List of professionals 
    * @param   o_error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   11-10-2010
    */
    FUNCTION get_prof_to_schedule
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_spec      IN p1_speciality.id_speciality%TYPE,
        i_inst_dest IN institution.id_institution%TYPE,
        o_sql       OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Check if prof is a GP physican
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Professional, institution and software ids
    * @param   o_error
    *
    * @RETURN  VARCHAR2
    * @author  Joana Barroso
    * @version 1.0
    * @since   11-10-2010
    */
    FUNCTION check_prof_phy
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN VARCHAR2;

    /**
    * Gets field 'Cobertura' 
    * This function will be rebuild or removed in the future.
    *
    * @param   i_lang     Language identifier
    * @param   i_prof     Professional, institution and software ids     
    * @param   o_value    Values to populate multichoice
    * @param   o_error    An error message, set when return=false 
    *    
    * @RETURN  Referral schedule identifier associated
    * @author  Ana Monteiro
    * @version 1.0
    * @since   28-10-2010
    */
    FUNCTION get_cover
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_value OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /* 
    * Check if Referral Home is active
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF professional, institution and software ids
    * @param   I_TYPE  Referral type 
    * @param   o_home_active  
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   17-10-2011 
    */
    FUNCTION check_referral_home
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_type        IN p1_external_request.flg_type%TYPE,
        o_home_active OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Check if Referral reason is mandatory
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF professional, institution and software ids
    * @param   I_TYPE  Referral type 
    * @param   I_HOME Referral Home
    * @param   o_reason_mandatory 
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   17-10-2011 
    */
    FUNCTION check_referral_reason
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_type             IN p1_external_request.flg_type%TYPE,
        i_home             IN table_varchar,
        i_priority         IN table_varchar,
        o_reason_mandatory OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Check if Referral diagnosis is mandatory
    *
    * @param   I_LANG             language associated to the professional executing the request
    * @param   I_PROF             professional, institution and software ids
    * @param   o_diag_mandatory   Referral Diagnosis: {*} 'Y' Mandatory {*} 'N' Not mandatory    
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   01-08-2013 
    */
    FUNCTION check_referral_diagnosis
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_diag_mandatory OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * Gets available clinical services for referring in dest institution
    * Available only for external and at hospital entrance workflows
    *
    * @param   i_lang             language associated to the professional executing the request
    * @param   i_prof             professional, institution and software ids
    * @param   i_flg_availability Referring type
    * @param   i_p1_spec          Referral speciality identifier
    * @param   i_id_inst_dest     DEst institution identifier   
    * @param   i_external_sys     External system identifier
    * @param   o_sql              Dest clinical services exposed to the origin institution
    * @param   o_error            An error message, set when return=false
    *
    * @value   i_flg_availability {*} 'E' external {*} 'P' at hospital entrance
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   21-09-2012
    */
    FUNCTION get_ref_clin_serv
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_flg_availability IN VARCHAR2,
        i_p1_spec          IN p1_speciality.id_speciality%TYPE,
        i_id_inst_dest     IN p1_dest_institution.id_inst_dest%TYPE,
        i_external_sys     IN external_sys.id_external_sys%TYPE,
        o_sql              OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get last referral active detail for a given type
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional id, institution and software
    * @param   I_PAT            Patient identifier
    * @param   I_FLG_TYPE       Detail type
    * @param   O_DETAIL_TEXT    Detail description 
    * @param   O_ERROR          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   13-02-2013
    */
    FUNCTION get_ref_last_detail
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_pat         IN patient.id_patient%TYPE,
        i_flg_type    IN table_varchar,
        o_detail_text OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the list of types of referral handoff
    *
    * @param   i_lang      Language associated to the professional executing the request
    * @param   i_prof      Professional, institution and software ids
    * @param   i_id_ref_tab     Array of referral identifiers
    * @param   o_list      Types of referral handoff   
    * @param   o_error     An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-03-2013
    */
    FUNCTION get_handoff_type
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_ref_tab IN table_number,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the list of institutions to transfer the referral
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Professional, institution and software ids
    * @param   i_id_inst_parent        Institution parent identifier
    * @param   i_id_ref_tab            Array of referrals being hand off
    * @param   o_list                  Priority list   
    * @param   o_error                 An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-03-2013
    */
    FUNCTION get_handoff_inst
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_inst_parent IN institution.id_institution%TYPE,
        i_id_ref_tab     IN table_number,
        o_list_inst      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets hand off historic data
    *
    * @param   i_lang          Professional preferred language
    * @param   i_prof          Professional identification and its context (institution and software)
    * @param   i_id_ref        Referral identifier
    * @param   o_hist_data     Hand off historic data
    * @param   o_hist_data     Hand off historic detail data
    * @param   o_error         Error information
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   05-06-2013
    */
    FUNCTION get_tr_detail_hist
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_ref        IN ref_trans_responsibility.id_external_request%TYPE,
        o_hist_data     OUT pk_types.cursor_type,
        o_hist_data_det OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get the diagnosis cause (ALERT-261232)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_diagnosis              diagnosis id
    *
    * @return                         VARCHAR2 diagnosis description
    *                        
    * @author                         Joana Barroso
    * @version                        2.6.3.8.2
    * @since                          09-10-2013
    **********************************************************************************************/

    FUNCTION std_diag_desc_array
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_diagnosis        IN table_number,
        i_id_alert_diagnosis  IN table_number,
        i_code_diagnosis      IN table_varchar,
        i_desc_epis_diagnosis IN table_varchar,
        i_code                IN table_varchar,
        i_flg_other           IN table_varchar,
        o_diag_desc_array     OUT table_varchar
    ) RETURN BOOLEAN;

    /**
    * Gets field 'Come Back' 
    *
    * @param   i_lang     Language identifier
    * @param   i_prof     Professional, institution and software ids     
    * @param   o_value    Values to populate multichoice
    * @param   o_error    An error message, set when return=false 
    *    
    * @RETURN  Referral schedule identifier associated
    * @author  Joana Barroso
    * @version 1.0
    * @since   10-10-2010
    */
    FUNCTION get_come_back_vals
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_value OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cerate new Referral comment
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
    * @since   05-07-2013
    **/

    FUNCTION create_ref_comment
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_text           IN CLOB,
        i_dt_comment     IN VARCHAR2,
        o_id_ref_comment OUT ref_comments.id_ref_comment%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Set Referral comments
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
        i_dt_cancel      IN VARCHAR2,
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
    
    * @param   o_id_ref_comment Referral comment ids
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
        i_dt_edit        IN VARCHAR2,
        o_id_ref_comment OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets referral field ranks (to order in flash and reports)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   o_fields_rank    Cursor with field names and ranks
    * @param   o_error          An error message, set when return=false
    *
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   27-06-2014
    */
    FUNCTION get_fields_rank
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_fields_rank OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Adds the referral to the print list
    *
    * @param   i_lang               preferred language id for this professional
    * @param   i_prof               professional id structure
    * @param   i_patient            Patient identifier
    * @param   i_episode            Episode identifier
    * @param   i_id_refs             List of referral identifiers to  be added to the print list
    * @param   i_print_arguments    List of print arguments necessary to print the jobs
    * @param   o_print_list_jobs    List of print list job identifiers
    * @param   o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   07-10-2014
    */
    FUNCTION add_print_list_jobs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_id_refs         IN table_number,
        i_print_arguments IN table_varchar,
        o_print_list_job  OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns reports information available for the referral area
    * Used in print button by flash, in order to distinguish reports of referral area and general reports
    *
    * @param   i_lang               preferred language id for this professional
    * @param   i_prof               professional id structure
    * @param   o_cur_reports        Cursor with referral reports information:     
    *                               - id_reports: referral report identifiers
    *                               - column_name: column name from cursor PK_P1_EXT_SYS.get_pat_p1.o_detail, that has the value that flash must read, in order to enable/disable option in report button
    * @param   o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  ana.monteiro
    * @since   16-10-2014
    */
    FUNCTION get_available_reports
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_cur_reports OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_family_relationships
    
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        o_family_relat OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_patient_rules
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN alert.profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_type           IN p1_external_request.flg_type%TYPE,
        i_codification   IN codification.id_codification%TYPE,
        o_flg_show       OUT VARCHAR2,
        o_message_title  OUT VARCHAR2,
        o_message_text   OUT VARCHAR2,
        o_forward_button OUT VARCHAR2,
        o_back_button    OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION insert_external_request_mcdt
    (
        i_lang              IN language.id_language%TYPE,
        i_ext_req           IN p1_external_request.id_external_request%TYPE,
        i_dt_modified       IN VARCHAR2,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_episode        IN episode.id_episode%TYPE,
        i_req_type          IN p1_external_request.req_type%TYPE,
        i_flg_type          IN p1_external_request.flg_type%TYPE,
        i_flg_priority_home IN table_table_varchar,
        i_mcdt              IN table_table_number,
        i_prof              IN profissional,
        --i_id_sched            IN schedule.id_schedule%TYPE, --- Not used
        i_problems            IN CLOB,
        i_dt_problem_begin    IN VARCHAR2,
        i_detail              IN table_table_varchar,
        i_diagnosis           IN CLOB,
        i_completed           IN VARCHAR2,
        i_id_tasks            IN table_table_number,
        i_id_info             IN table_table_number,
        i_codification        IN codification.id_codification%TYPE,
        i_flg_laterality      IN table_varchar DEFAULT NULL,
        i_ref_completion      IN ref_completion.id_ref_completion%TYPE,
        i_consent             IN VARCHAR2,
        o_id_external_request OUT table_number,
        o_flg_show            OUT VARCHAR2,
        o_msg                 OUT VARCHAR2,
        o_msg_title           OUT VARCHAR2,
        o_button              OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION chk_ext_req_light_license
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        o_flg_show              OUT VARCHAR2,
        o_message_text          OUT VARCHAR2,
        o_info_buttons          OUT pk_types.cursor_type,
        o_flg_show_almost_empty OUT VARCHAR2,
        o_shortcut              OUT NUMBER,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_light_license_credits
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN NUMBER;

END pk_ref_service;
/
