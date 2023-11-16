/*-- Last Change Revision: $Rev: 2028839 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:15 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_p1_med_cs AS

    /****************************************************************************************
    PROJECT         : ALERT-P1
    PROJECT TEAM    : JOAO SA ( TEAM LEADER, PROJECT ANALYSIS, JAVA MAN ),
                      CARLOS FERREIRA ( PROJECT ANALYSIS, DB MAN ),
                      RUI DIAS ( PROJECT ANALYSIS, FLASH MAN ).
    
    PK CREATED BY   : CARLOS FERREIRA
    PK DATE CREATION: 07-2005
    PK GOAL         : THIS PACKAGE TAKES CARE OF ALL FUNCTIONS REGARDING THE DOCTOR ( MEDICO )
                      LOCATED AT THE HEALTHCARE CENTER ( CENTRO DE SAUDE ).
    
    NOTES/ OBS      : ---
    ******************************************************************************************/

    /**
    * Service to create a referral request
    *
    * @param   i_lang                Language associated to the professional executing the request
    * @param   i_prof                Professional, institution and software ids
    * @param   i_id_patient          Patient identifier
    * @param   i_speciality          Request speciality (P1_SPECIALITY)
    * @param   i_id_dep_clin_serv    Department/clinical_service identifier (can be null)
    * @param   i_req_type            (M)anual; Using clinical (P)rotocol
    * @param   i_flg_type            (A)nalisys; (C)onsultation (E)xam, (I)ntervention,
    * @param   i_flg_priority        Referral priority flag
    * @param   i_flg_home            Referral home flag
    * @param   i_inst_dest           Destination institution
    * @param   i_problems            Problems identifier to be addressed
    * @param   i_problems_desc       Problems description to be addressed
    * @param   i_dt_problem_begin    Problem onset
    * @param   i_detail              Referral detail info. For each detail: [id_detail|flg_type|text|flg|id_group]
    * @param   i_diagnosis           Referral Diagnosis
    * @param   i_completed           Referral data is completed? (Y/N)
    * @param   i_id_task             Referral tasks needed for (S)cheduling. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done
    * @param   i_id_info             Referral tasks needed for (C)onsultation. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done       
    * @param   i_epis                Episode where the referral was created
    * @param   i_external_sys        External system identifier that is creating the referral           
    * @param   i_date                Operation date   
    * @param   i_comments            Referral comments [ID_ref_comment|Flg_Status|text]
    * @param   o_id_external_request Referral identifier
    * @param   o_flg_show            Show message (Y/N)
    * @param   o_msg                 Message text
    * @param   o_msg_title           Message title
    * @param   o_button              Type of button to show with message
    * @param   o_error               An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.1
    * @since   18-04-2007
    */
    FUNCTION create_external_request
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_speciality       IN p1_speciality.id_speciality%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_req_type         IN p1_external_request.req_type%TYPE,
        i_flg_type         IN p1_external_request.flg_type%TYPE,
        i_flg_priority     IN p1_external_request.flg_priority%TYPE,
        i_flg_home         IN p1_external_request.flg_home%TYPE,
        i_inst_dest        IN institution.id_institution%TYPE,
        --i_id_sched            IN schedule.id_schedule%TYPE, -- Not used
        i_problems         IN CLOB,
        i_dt_problem_begin IN VARCHAR2,
        i_detail           IN table_table_varchar,
        i_diagnosis        IN CLOB,
        i_completed        IN VARCHAR2,
        i_id_tasks         IN table_table_number,
        i_id_info          IN table_table_number,
        i_epis             IN episode.id_episode%TYPE,
        i_external_sys     IN p1_external_request.id_external_sys%TYPE DEFAULT NULL,
        i_date             IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        i_comments         IN table_table_clob, -- ID ref comment, Flg Status, texto 
        i_prof_cert        IN VARCHAR2,
        i_prof_first_name  IN VARCHAR2,
        i_prof_surname     IN VARCHAR2,
        i_prof_phone       IN VARCHAR2,
        i_id_fam_rel       IN family_relationship.id_family_relationship%TYPE,
        i_fam_rel_spec     IN VARCHAR2 DEFAULT NULL,
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
    * Updates referral info
    *
    * @param   i_lang                Language associated to the professional executing the request
    * @param   i_prof                Professional, institution and software ids
    * @param   i_ext_req             Referral identifier
    * @param   i_dt_modified         Date of last change, as returned in pk_ref_service.get_referral
    * @param   i_speciality          Referral speciality identifier (P1_SPECIALITY)    
    * @param   i_id_dep_clin_serv    Department/clinical_service identifier
    * @param   i_req_type            (M)anual; Using clinical (P)rotocol
    * @param   i_flg_type            Referral type
    * @param   i_flg_priority        Referral priority flag
    * @param   i_flg_home            Referral home flag
    * @param   i_inst_dest           Destination institution
    * @param   i_problems            Problems identifier to be addressed
    * @param   i_problems_desc       Problems description to be addressed
    * @param   i_dt_problem_begin    Problem onset
    * @param   i_detail              Referral detail info. For each detail: [id_detail|flg_type|text|flg|id_group]
    * @param   i_diagnosis           Referral Diagnosis
    * @param   i_completed           Referral data is completed? (Y/N)
    * @param   i_id_task             Referral tasks needed for (S)cheduling. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done
    * @param   i_id_info             Referral tasks needed for (C)onsultation. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done           
    * @param   i_date                Operation date
    * @param   i_comments            Referral comments [ID_ref_comment|Flg_Status|text]
    * @param   o_id_external_request Referral identifier
    * @param   o_flg_show            Show message (Y/N)
    * @param   o_msg                 Message text
    * @param   o_msg_title           Message title
    * @param   o_button              Type of button to show with message
    * @param   o_error               An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.1
    * @since   18-04-2007
    */
    FUNCTION update_external_request
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_ext_req          IN p1_external_request.id_external_request%TYPE,
        i_dt_modified      IN VARCHAR2,
        i_speciality       IN p1_speciality.id_speciality%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_req_type         IN p1_external_request.req_type%TYPE,
        i_flg_type         IN p1_external_request.flg_type%TYPE,
        i_flg_priority     IN p1_external_request.flg_priority%TYPE,
        i_flg_home         IN p1_external_request.flg_home%TYPE,
        i_inst_dest        IN institution.id_institution%TYPE,
        --i_id_sched            IN schedule.id_schedule%TYPE, -- Not used
        i_problems         IN CLOB,
        i_dt_problem_begin IN VARCHAR2,
        i_detail           IN table_table_varchar,
        i_diagnosis        IN CLOB,
        i_completed        IN VARCHAR2,
        i_id_tasks         IN table_table_number,
        i_id_info          IN table_table_number,
        i_date             IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        i_comments         IN table_table_clob, -- ID ref comment, Flg Status, texto 
        i_prof_cert        IN VARCHAR2,
        i_prof_first_name  IN VARCHAR2,
        i_prof_surname     IN VARCHAR2,
        i_prof_phone       IN VARCHAR2,
        i_id_fam_rel       IN family_relationship.id_family_relationship%TYPE,
        i_fam_rel_spec     IN VARCHAR2 DEFAULT NULL,
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
    * Returns the list of referral MCDTs grouped as required the specified report
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Professional, institution and software ids
    * @param   i_exr               Referral identifier
    * @param   i_type              Splitting type: {*} 'PV' print preview (do not generate codes)
    *                                              {*} 'PF' print final(generate codes)
    *                                              {*} 'A' application
    * @param   i_id_report         Report identifier. Needed to get the maximum number of MCDTs in each referral report
    * @param   i_id_ref_completion Referral completion option id. Needed to get the maximum number of MCDTs in each referral report
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 2.0
    * @since   02-06-2008
    */
    FUNCTION get_exr_group_internal
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_exr               IN p1_external_request.id_external_request%TYPE,
        i_type              IN VARCHAR2,
        i_id_report         IN reports.id_reports%TYPE,
        i_id_ref_completion IN ref_completion.id_ref_completion%TYPE,
        i_gen_ref           IN VARCHAR2 DEFAULT 'N',
        i_flg_isencao       IN VARCHAR2
    ) RETURN t_coll_ref_group
        PIPELINED;

    /**
    * Returns the list of referral MCDTs grouped as required the specified report
    * 
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Professional, institution and software ids
    * @param   i_exr               Referral identifier
    * @param   i_type              Splitting type: {*} 'PV' print preview (do not generate codes)
    *                                              {*} 'PF' print final(generate codes)
    *                                              {*} 'A' application
    * @param   i_id_report         Report identifier. Needed to get the maximum number of MCDTs in each referral report
    * @param   i_id_ref_completion Referral completion option id. Needed to get the maximum number of MCDTs in each referral report
    * @param   o_error             An error message, set when return=false
    *
    * @value   i_type              {*} 'PV' print preview (do not generate codes)
    *                              {*} 'PF' print final(generate codes)
    *                              {*} 'A' application    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   02-06-2008
    */
    FUNCTION get_exr_group
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_exr               IN p1_external_request.id_external_request%TYPE,
        i_type              IN VARCHAR2,
        i_id_report         IN reports.id_reports%TYPE,
        i_id_ref_completion IN ref_completion.id_ref_completion%TYPE,
        i_flg_isencao       IN VARCHAR2,
        o_ref               OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Splits referral MCDTs into groups, as required the specified report    
    *
    * @param   i_lang                    Language associated to the professional executing the request
    * @param   i_prof                    Professional, institution and software ids
    * @param   i_id_patient              Patient id    
    * @param   i_exr                     Referral identifier
    * @param   i_id_episode              Episode identifier
    * @param   i_type                    Splitting type: {*} 'PV' print preview (do not generate codes)
    *                                              {*} 'PF' print final(generate codes)
    *                                              {*} 'A' application
    * @param   i_num_req                 Num_req ids        
    * @param   i_id_report               Report identifier. Needed to get the maximum number of MCDTs in each referral report
    * @param   i_id_ref_completion       Referral completion option id. Needed to get the maximum number of MCDTs in each referral report
    * @param   o_id_external_request     Referral requests identifiers
    * @param   O_ERROR                   An error message, set when return=false
    *
    * @value   i_type                    {*} 'PV' print preview (do not generate codes)
    *                                    {*} 'PF' print final(generate codes)
    *                                    {*} 'A' application
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   02-06-2008
    */
    FUNCTION split_mcdt_request_by_group
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_exr                 IN p1_external_request.id_external_request%TYPE,
        i_id_patient          IN patient.id_patient%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_type                IN VARCHAR2,
        i_num_req             IN table_varchar,
        i_id_report           IN reports.id_reports%TYPE,
        i_id_ref_completion   IN ref_completion.id_ref_completion%TYPE,
        i_flg_isencao         IN VARCHAR2,
        o_id_external_request OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Insert mdct external request
    *
    * @param   i_lang                Language associated to the professional executing the request
    * @param   i_prof                Professional, institution and software ids
    * @param   i_ext_req             Referral identifier
    * @param   i_dt_modified         Date of last change, as returned in pk_ref_service.get_referral
    * @param   i_id_patient          Patient identifier
    * @param   i_id_episode          Episode identifier
    * @param   i_req_type            (M)anual; Using clinical (P)rotocol
    * @param   i_flg_type            Referral type
    * @param   i_flg_priority_home   Priority and home flags home for each mcdt
    * @param   i_mcdt                MCDT information to relate to this referral
    * @param   i_problems            Problems identifier to be addressed
    * @param   i_problems_desc       Problems description to be addressed
    * @param   i_dt_problem_begin    Problem onset
    * @param   i_detail              Referral detail info. For each detail: [id_detail|flg_type|text|flg|id_group]
    * @param   i_diagnosis           Referral Diagnosis
    * @param   i_completed           Referral data is completed? (Y/N)
    * @param   i_id_task             Referral tasks needed for (S)cheduling. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done
    * @param   i_id_info             Referral tasks needed for (C)onsultation. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done
    * @param   i_codification        MCDTs codification identifier
    * @param   i_flg_laterality      MCDT laterality information
    * @param   i_ref_completion      
    * @param   o_id_external_request Referral identifier
    * @param   o_flg_show            Show message (Y/N)
    * @param   o_msg                 Message text
    * @param   o_msg_title           Message title
    * @param   o_button              Type of button to show with message
    * @param   o_error               An error message, set when return=false
    *
    * @value   i_flg_type            {*}'A' analysis {*}'I' Image {*}'E' Other Exams {*}'P' Intervention/Procedures {*}'F' Rehab
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Joana Barroso
    * @version 2.4.3
    * @since   17-04-2008
    */
    FUNCTION insert_referral_mcdt_internal
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_ext_req           IN p1_external_request.id_external_request%TYPE,
        i_dt_modified       IN VARCHAR2,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_episode        IN episode.id_episode%TYPE,
        i_req_type          IN p1_external_request.req_type%TYPE,
        i_flg_type          IN p1_external_request.flg_type%TYPE,
        i_flg_priority_home IN table_table_varchar,
        i_mcdt              IN table_table_number,
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

    /**
    * Create new mdct external request
    *
    * @param   i_lang                Language associated to the professional executing the request
    * @param   i_prof                Professional, institution and software ids
    * @param   i_id_patient          Patient identifier
    * @param   i_id_episode          Episode identifier
    * @param   i_req_type            (M)anual; Using clinical (P)rotocol
    * @param   i_flg_type            Referral type
    * @param   i_flg_priority_home   Priority and home flags home for each mcdt
    * @param   i_mcdt                MCDT information to relate to this referral
    * @param   i_problems            Problems identifier to be addressed
    * @param   i_problems_desc       Problems description to be addressed
    * @param   i_dt_problem_begin    Problem onset
    * @param   i_detail              Referral detail info. For each detail: [id_detail|flg_type|text|flg|id_group]
    * @param   i_diagnosis           Referral Diagnosis
    * @param   i_completed           Referral data is completed? (Y/N)
    * @param   i_id_task             Referral tasks needed for (S)cheduling. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done
    * @param   i_id_info             Referral tasks needed for (C)onsultation. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done
    * @param   i_codification        MCDTs codification identifier
    * @param   i_flg_laterality      MCDT laterality information
    * @param   o_id_external_request Referral identifier
    * @param   o_flg_show            Show message (Y/N)
    * @param   o_msg                 Message text
    * @param   o_msg_title           Message title
    * @param   o_button              Type of button to show with message
    * @param   o_error               An error message, set when return=false
    *
    * @value   i_flg_type            {*}'A' analysis {*}'I' Image {*}'E' Other Exams {*}'P' Intervention/Procedures {*}'F' Rehab
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Joana Barroso
    * @version 2.4.3
    * @since   17-04-2008
    */
    FUNCTION create_external_request_mcdt
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_episode        IN episode.id_episode%TYPE,
        i_req_type          IN p1_external_request.req_type%TYPE,
        i_flg_type          IN p1_external_request.flg_type%TYPE,
        i_flg_priority_home IN table_table_varchar,
        i_mcdt              IN table_table_number,
        --i_id_sched            IN schedule.id_schedule%TYPE, -- Not used
        i_problems                  IN CLOB,
        i_dt_problem_begin          IN VARCHAR2,
        i_detail                    IN table_table_varchar,
        i_diagnosis                 IN CLOB,
        i_completed                 IN VARCHAR2,
        i_id_tasks                  IN table_table_number,
        i_id_info                   IN table_table_number,
        i_codification              IN codification.id_codification%TYPE,
        i_flg_laterality            IN table_varchar DEFAULT NULL,
        i_consent                   IN VARCHAR2,
        i_reason                    IN table_varchar DEFAULT NULL,
        i_complementary_information IN table_varchar DEFAULT NULL,
        i_health_plan               IN health_plan.id_health_plan%TYPE DEFAULT NULL,
        i_exemption                 IN pat_isencao.id_pat_isencao%TYPE DEFAULT NULL,
        i_id_fam_rel                IN family_relationship.id_family_relationship%TYPE DEFAULT NULL,
        i_fam_rel_spec              IN VARCHAR2 DEFAULT NULL,
        i_name_first_rel            IN VARCHAR2 DEFAULT NULL,
        i_name_middle_rel           IN VARCHAR2 DEFAULT NULL,
        i_name_last_rel             IN VARCHAR2 DEFAULT NULL,
        o_id_external_request       OUT table_number,
        o_flg_show                  OUT VARCHAR2,
        o_msg                       OUT VARCHAR2,
        o_msg_title                 OUT VARCHAR2,
        o_button                    OUT VARCHAR2,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Update mdct external request
    *
    * @param   i_lang                Language associated to the professional executing the request
    * @param   i_prof                Professional, institution and software ids
    * @param   i_ext_req             Referral identifier
    * @param   i_dt_modified         Date of last change, as returned in pk_ref_service.get_referral
    * @param   i_id_episode          Episode identifier
    * @param   i_req_type            (M)anual; Using clinical (P)rotocol
    * @param   i_flg_type            Referral type
    * @param   i_flg_priority_home   Priority and home flags home for each mcdt
    * @param   i_mcdt                MCDT information to relate to this referral
    * @param   i_problems            Problems identifier to be addressed
    * @param   i_problems_desc       Problems description to be addressed
    * @param   i_dt_problem_begin    Problem onset
    * @param   i_detail              Referral detail info. For each detail: [id_detail|flg_type|text|flg|id_group]* @param   i_diagnosis           Referral Diagnosis
    * @param   i_completed           Referral data is completed? (Y/N)
    * @param   i_id_task             Referral tasks needed for (S)cheduling. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done
    * @param   i_id_info             Referral tasks needed for (C)onsultation. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done
    * @param   i_codification        MCDTs codification identifier
    * @param   i_flg_laterality      MCDT laterality information
    * @param   o_id_external_request Referral identifier
    * @param   o_flg_show            Show message (Y/N)
    * @param   o_msg                 Message text
    * @param   o_msg_title           Message title
    * @param   o_button              Type of button to show with message
    * @param   o_error               An error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Joana Barroso
    * @version 2.4.3
    * @since   17-04-2008
    */
    FUNCTION update_external_request_mcdt
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_ext_req           IN p1_external_request.id_external_request%TYPE,
        i_dt_modified       IN VARCHAR2,
        i_id_episode        IN episode.id_episode%TYPE,
        i_req_type          IN p1_external_request.req_type%TYPE,
        i_flg_type          IN p1_external_request.flg_type%TYPE,
        i_flg_priority_home IN table_table_varchar,
        i_mcdt              IN table_table_number,
        --i_id_sched            IN schedule.id_schedule%TYPE, -- Not used
        i_problems                  IN CLOB,
        i_dt_problem_begin          IN VARCHAR2,
        i_detail                    IN table_table_varchar,
        i_diagnosis                 IN CLOB,
        i_completed                 IN VARCHAR2,
        i_id_tasks                  IN table_table_number,
        i_id_info                   IN table_table_number,
        i_codification              IN codification.id_codification%TYPE,
        i_flg_laterality            IN table_varchar DEFAULT NULL,
        i_consent                   IN VARCHAR2,
        i_health_plan               IN table_number DEFAULT NULL,
        i_exemption                 IN table_number DEFAULT NULL,
        i_reason                    IN table_varchar DEFAULT NULL,
        i_complementary_information IN table_varchar DEFAULT NULL,
        i_id_fam_rel                IN family_relationship.id_family_relationship%TYPE DEFAULT NULL,
        i_fam_rel_spec              IN VARCHAR2 DEFAULT NULL,
        i_name_first_rel            IN VARCHAR2 DEFAULT NULL,
        i_name_middle_rel           IN VARCHAR2 DEFAULT NULL,
        i_name_last_rel             IN VARCHAR2 DEFAULT NULL,
        o_id_external_request       OUT table_number,
        o_flg_show                  OUT VARCHAR2,
        o_msg                       OUT VARCHAR2,
        o_msg_title                 OUT VARCHAR2,
        o_button                    OUT VARCHAR2,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    -- RETURNS NEXT CODE NUMBER FOR P1_EXTERNAL_REQUEST
    FUNCTION get_p1_num_req(i_inst IN NUMBER) RETURN VARCHAR2;

    FUNCTION get_request_methods
    (
        i_lang    IN language.id_language%TYPE,
        o_methods OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancel referral
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional identifier, institution and software    
    * @param   i_ext_req        Referral id    
    * @param   i_id_patient     Patient id
    * @param   i_id_episode     Episode id        
    * @param   i_notes          Cancelation notes    
    * @param   i_reason         Cancelation reason code    
    * @param   i_transaction_id Scheduler 3.0 id
    * @param   o_track          Array of ID_TRACKING transitions
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   17-10-2007
    */
    FUNCTION cancel_external_request_int
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ext_req        IN p1_external_request.id_external_request%TYPE,
        i_mcdts          IN table_number,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_episode     IN episode.id_episode%TYPE,
        i_notes          IN p1_detail.text%TYPE,
        i_reason         IN p1_reason_code.id_reason_code%TYPE,
        i_transaction_id IN VARCHAR2,
        o_track          OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Only used to cancel referral or decline cancellation request from actions button
    *
    * @param   i_lang            Language associated to the professional executing the request
    * @param   i_prof            professional id, institution and software    
    * @param   i_id_ref          Referral identifier
    * @param   i_action          Action to be processed
    * @param   i_reason_code     Reason code for cancellation
    * @param   i_notes           Notes of answering referral cancellation request    
    * @param   i_op_date         Operation date   
    * @param   i_dt_modified     Last modified date as provided by get_referral
    * @param   i_mode            (V)alidate date modified or do(N)t
    * @param   o_flg_show        Flag indicating if o_msg is shown
    * @param   o_msg             Message indicating that referral has been changed
    * @param   o_msg_title       Message title
    * @param   o_error           An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   21-09-2010
    */
    FUNCTION set_status
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN p1_external_request.id_external_request%TYPE,
        i_action      IN VARCHAR2,
        i_reason_code IN p1_reason_code.id_reason_code%TYPE,
        i_notes       IN VARCHAR2,
        i_op_date     IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        i_dt_modified IN VARCHAR2,
        i_mode        IN VARCHAR2,
        o_flg_show    OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_msg         OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Declines a cancellation request
    *
    * @param   i_lang            Language associated to the professional executing the request
    * @param   i_prof            professional id, institution and software    
    * @param   i_id_ref          Referral identifier
    * @param   i_notes           Notes of answering referral cancellation request    
    * @param   i_op_date         Operation date   
    * @param   o_error           An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   28-09-2010
    */
    FUNCTION decline_req_cancellation
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_ref  IN p1_external_request.id_external_request%TYPE,
        i_notes   IN VARCHAR2,
        i_op_date IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * Gets next status of mcdt referral: (N)ew or (G) Harvest
    *
    * @param   i_lang                Language associated to the professional executing the request
    * @param   i_prof                Id professional, institution and software    
    * @param   i_flg_type            Referral type: {*} 'A' analysis {*} 'I' Image {*} 'E' Exam {*} 'P' Procedure {*} 'F' MFR   
    * @param   i_mcdt_req_det        MCDT req detail identification    
    * @param   o_flg_status          Referral flag status
    * @param   O_ERROR               An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   01-09-2009
    */
    FUNCTION get_status_mcdt
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_flg_type     IN p1_external_request.flg_type%TYPE,
        i_mcdt_req_det IN table_number,
        o_flg_status   OUT p1_external_request.flg_status%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Updates MCDT data
    * 
    * @param   i_lang            Language associated to the professional executing the request
    * @param   i_prof            Professional, institution and software ids
    * @param   i_exr             Referral identifier
    * @param   i_id_episode      Episode identifier
    * @param   i_req_det         MCDT detail identifier    
    * @param   i_type            Referral type
    * @param   i_status          Flag referral related to the MCDT
    * @param   i_inst_dest       MCDT dest institution identifier
    * @param   i_flg_laterality  Flag laterality related to the MCDT (analysis not included)
    * @param   o_error           An error message, set when return=false
    *
    * @value   i_type            {*} (A)nalysis {*} Other (E)xam {*} (I)mage {*} (P) Intervention {*} M(F)R
    * @value   i_status          {*} (R)eserved {*} (S)ent
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-06-2009
    */
    FUNCTION update_flg_referral
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_exr            IN p1_external_request.id_external_request%TYPE,
        i_id_episode     IN episode.id_episode%TYPE,
        i_req_det        IN NUMBER,
        i_type           IN VARCHAR2,
        i_status         IN VARCHAR2,
        i_inst_dest      IN institution.id_institution%TYPE,
        i_flg_laterality IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *
    * Get Interventions prescription notes 
    *
    * @param      i_lang                       Professional language
    * @param      i_prof                       Professional, institution and software ids
    * @param      i_id_interv_presc_det        Interv_presc_det id
    *
    * @return     VARCHAR
    * @author     Joana Barroso
    * @version    0.1
    * @since      2012/12
    * @modified    
    */

    FUNCTION get_interv_notes
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE
    ) RETURN VARCHAR;

    /** 
    *
    * Get Rehab prescription notes 
    *
    * @param      i_lang                  professional language
    * @param      i_id_rehab_presc        Rehab_presc Id
    *
    * @return     VARCHAR
    * @author     Joana Barroso
    * @version    0.1
    * @since      2012/12
    * @modified    
    */

    FUNCTION get_rehab_notes
    (
        i_lang           IN language.id_language%TYPE,
        i_id_rehab_presc IN rehab_presc.id_rehab_presc%TYPE
    ) RETURN VARCHAR;

    /** 
    *
    * Get exam prescription notes 
    *
    * @param      i_lang                  professional language
    * @param      id_exam_req_det         Exam_req_der Id
    
    *
    * @return     VARCHAR
    * @author     Joana Barroso
    * @version    0.1
    * @since      2012/12
    * @modified    
    */

    FUNCTION get_exam_notes
    (
        i_lang          IN language.id_language%TYPE,
        id_exam_req_det IN exam_req_det.id_exam_req_det%TYPE
    ) RETURN VARCHAR;

    /** 
    *
    * Get Analysis prescription notes 
    *
    * @param      i_lang                  professional language
    * @param      id_analysis_req_det     Analysis_REQ_DET Id
    *
    * @return     VARCHAR
    * @author     Joana Barroso
    * @version    0.1
    * @since      2012/12
    * @modified    
    */

    FUNCTION get_analysis_notes
    (
        i_lang              IN language.id_language%TYPE,
        id_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE
    ) RETURN VARCHAR;

    FUNCTION get_p1_notes
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        id_external_request IN p1_external_request.id_external_request%TYPE
    ) RETURN VARCHAR;

END pk_p1_med_cs;
/
