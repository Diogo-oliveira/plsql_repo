/*-- Last Change Revision: $Rev: 2028911 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:42 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ref_orig_phy AS

    /*
    * Get a default priority or home  to referral mcdt request
    *
    * @param  i_arr_priority_home array with priority_home information
    *
    * @RETURN  VARCHAR2 if sucess, NULL otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   10-12-2012
    */
    FUNCTION get_priority_home
    (
        i_lang              IN language.id_language%TYPE,
        i_arr_priority_home IN table_table_varchar,
        i_val               IN NUMBER -- 1 priority, 2 home
    ) RETURN VARCHAR2;

    /**
    * Outdates details related to flg_home and flg_priority and adds new records with the new values (only if they are different)
    * Used by database functions only.
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids    
    * @param   i_id_ref         Referral identifier    
    * @param   i_flg_priority   New value of flg_priority
    * @param   i_flg_home       New value of flg_home
    * @param   io_detail_tab    Detail structure
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6.1
    * @since   01-04-2011
    */
    FUNCTION add_flgs_to_detail
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_ref       IN p1_external_request.id_external_request%TYPE,
        i_flg_priority IN p1_external_request.flg_priority%TYPE,
        i_flg_home     IN p1_external_request.flg_home%TYPE,
        io_detail_tab  IN OUT NOCOPY table_table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Create the referral
    *
    * @param   i_lang               Language associated to the professional executing the request
    * @param   i_prof               Professional, institution and software ids
    * @param   i_workflow           Referral workflow identification    
    * @param   i_id_patient         Patient id
    * @param   i_speciality         Referral speciality (P1_SPECIALITY)
    * @param   i_dcs                Id department/clinical_service (can be null)
    * @param   i_req_type           (M)anual; Using clinical (P)rotocol
    * @param   i_flg_type           (A)nalisys; (C)onsultation (E)xam, (I)ntervention,
    * @param   i_flg_priority       Urgent/not urgent
    * @param   i_flg_home           Home consultation?
    * @param   i_id_inst_orig       Origin institution identifier (may be different from i_prof.institution in case of "at hospital entrance" workflow)
    * @param   i_inst_dest          Destination institution   
    * @param   i_problems           Referral data - problem identifier to solve
    * @param   i_problems_desc      Referral data - problem description to solve
    * @param   i_dt_problem_begin   Referral data - date of problem begining
    * @param   i_detail             P1 detail info. For each detail: [id_detail|flg_type|text|flg|id_group]
    * @param   i_diagnosis          Referral data - diagnosis
    * @param   i_completed          Referral completed (Y/N)
    * @param   i_id_task            Referral tasks needed for (S)cheduling. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done
    * @param   i_id_info            Referral tasks needed for (C)onsultation. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done    
    * @param   i_epis               Episode Id
    * @param   i_num_order          Professional num_order
    * @param   i_prof_name          Professional name
    * @param   i_prof_id            Professional Id
    * @param   i_institution_name   Origin institution name
    * @param   i_external_sys       External system identifier    
    * @param   i_date               Operation date
    * @param   o_ext_req            Referral id
    * @param   o_flg_show           Show message (Y/N)
    * @param   o_msg                Message text
    * @param   o_msg_title          Message title
    * @param   o_button             Type of button to show with message
    * @param   O_ERROR              an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   23-06-2009 
    */
    FUNCTION create_referral
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_workflow         IN wf_workflow.id_workflow%TYPE,
        i_id_patient       IN patient.id_patient%TYPE,
        i_speciality       IN p1_speciality.id_speciality%TYPE,
        i_dcs              IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_req_type         IN p1_external_request.req_type%TYPE,
        i_flg_type         IN p1_external_request.flg_type%TYPE,
        i_flg_priority     IN p1_external_request.flg_priority%TYPE,
        i_flg_home         IN p1_external_request.flg_home%TYPE,
        i_id_inst_orig     IN p1_external_request.id_inst_orig%TYPE,
        i_inst_dest        IN institution.id_institution%TYPE,
        i_problems         IN CLOB,
        i_dt_problem_begin IN VARCHAR2,
        i_detail           IN table_table_varchar,
        i_diagnosis        IN CLOB,
        i_completed        IN VARCHAR2,
        i_id_tasks         IN table_table_number,
        i_id_info          IN table_table_number,
        i_epis             IN episode.id_episode%TYPE,
        i_num_order        IN professional.num_order%TYPE DEFAULT NULL,
        i_prof_name        IN professional.name%TYPE DEFAULT NULL,
        i_prof_id          IN ref_orig_data.id_professional%TYPE DEFAULT NULL,
        i_institution_name IN ref_orig_data.institution_name%TYPE DEFAULT NULL,
        i_external_sys     IN p1_external_request.id_external_sys%TYPE,
        i_date             IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        i_comments         IN table_table_clob, -- ID ref comment, Flg Status, texto
        i_prof_cert        IN VARCHAR2,
        i_prof_first_name  IN VARCHAR2,
        i_prof_surname     IN VARCHAR2,
        i_prof_phone       IN VARCHAR2,
        i_id_fam_rel       IN family_relationship.id_family_relationship%TYPE,
        i_name_first_rel   IN VARCHAR2,
        i_name_middle_rel  IN VARCHAR2,
        i_name_last_rel    IN VARCHAR2,
        --Health insurance
        i_health_plan IN health_plan.id_health_plan%TYPE DEFAULT NULL,
        i_exemption   IN NUMBER DEFAULT NULL,
        o_flg_show    OUT VARCHAR2,
        o_msg         OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_ext_req     OUT p1_external_request.id_external_request%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Create new mdct external request
    *
    * @param   i_lang                Language associated to the professional executing the request
    * @param   i_prof                Professional, institution and software ids
    * @param   i_workflow            Referral workflow identifier
    * @param   i_mcdt                MCDT information to relate to this referral
    * @param   i_id_patient          Patient identifier   
    * @param   i_req_type            (M)anual; Using clinical (P)rotocol
    * @param   i_flg_type            Referral type    
    * @param   i_problems            Problems identifier to be addressed
    * @param   i_problems_desc       Problems description to be addressed
    * @param   i_dt_problem_begin    Problem onset
    * @param   i_detail              Referral detail info. For each detail: [id_detail|flg_type|text|flg|id_group]
    * @param   i_diagnosis           Referral Diagnosis
    * @param   i_completed           Referral data is completed? (Y/N)
    * @param   i_id_task             Referral tasks needed for (S)cheduling. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done
    * @param   i_id_info             Referral tasks needed for (C)onsultation. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done
    * @param   i_epis                Episode identifier
    * @param   i_codification        MCDTs codification identifier
    * @param   i_flg_laterality      MCDT laterality information    
    * @param   o_flg_show            Show message (Y/N)
    * @param   o_msg                 Message text
    * @param   o_msg_title           Message title
    * @param   o_button              Type of button to show with message
    * @param   o_ext_req             Referral identifier
    * @param   o_error               An error message, set when return=false
    *
    * @value   i_flg_type            {*}'A' analysis {*}'I' Image {*}'E' Other Exams {*}'P' Intervention/Procedures {*}'F' Rehab
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Joana Barroso
    * @version 1.0
    * @since   02-01-2013
    */
    FUNCTION create_mcdt_referral
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_workflow          IN wf_workflow.id_workflow%TYPE,
        i_flg_priority_home IN table_table_varchar,
        i_mcdt              IN table_table_number,
        i_id_patient        IN patient.id_patient%TYPE,
        i_req_type          IN p1_external_request.req_type%TYPE,
        i_flg_type          IN p1_external_request.flg_type%TYPE,
        i_problems          IN CLOB,
        i_dt_problem_begin  IN VARCHAR2,
        i_detail            IN table_table_varchar,
        i_diagnosis         IN CLOB,
        i_completed         IN VARCHAR2,
        i_id_tasks          IN table_table_number,
        i_id_info           IN table_table_number,
        i_epis              IN episode.id_episode%TYPE,
        i_date              IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        i_codification      IN codification.id_codification%TYPE,
        i_flg_laterality    IN table_varchar DEFAULT NULL,
        i_consent           IN VARCHAR2,
        o_flg_show          OUT VARCHAR2,
        o_msg               OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_button            OUT VARCHAR2,
        o_ext_req           OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Updates referral info
    *
    * @param   i_lang               Language associated to the professional executing the request
    * @param   i_prof               Professional, institution and software ids
    * @param   i_ext_req            Referral identifier
    * @param   i_dt_modified        Referral last interaction (dt_last_interaction)
    * @param   i_speciality         Referral speciality (P1_SPECIALITY)
    * @param   i_dcs                Id department/clinical_service 
    * @param   i_req_type           Referral req type (M)anual; Using clinical (P)rotocol
    * @param   i_flg_type           Referral type
    * @param   i_flg_priority       Urgent/not urgent
    * @param   i_flg_home           Home consultation?    
    * @param   i_id_inst_orig       Origin institution identifier (may be different from i_prof.institution in case of "at hospital entrance" workflow)
    * @param   i_inst_dest          Destination institution    
    * @param   i_problems           Referral data - problem identifier to solve
    * @param   i_problems_desc      Referral data - problem description to solve
    * @param   i_dt_problem_begin   Referral data - date of problem begining
    * @param   i_detail             P1 detail info. For each detail: [id_detail|flg_type|text|flg|id_group]
    * @param   i_diagnosis          Referral data - diagnosis
    * @param   i_completed          Referral completed (Y/N)
    * @param   i_id_task            Referral tasks needed for (S)cheduling. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done
    * @param   i_id_info            Referral tasks needed for (C)onsultation. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done        
    * @param   i_num_order          Professional num_order
    * @param   i_prof_name          Professional name
    * @param   i_prof_id            Professional ID
    * @param   i_institution_name   Origin institution name
    * @param   i_date               Operation date
    * @param   o_ext_req            Referral identification
    * @param   o_flg_show           Show message
    * @param   o_msg                Message text
    * @param   o_msg_title          Message title
    * @param   o_button             Type of button to show with message
    * @param   o_error              An error message, set when return=false
    *
    * @value   i_req_type           {*} 'M' - manual  {*} 'P' - Using clinical protocol
    * @value   i_flg_type           {*} 'C' - Appointments {*} 'A'  - Lab tests {*} 'I' - Imaging exams {*} 'E' - Other exams
    *                               {*} 'P' - Procedures {*} 'F' -  Rehabilitation {*} 'S'  - Surgery requests
    *                               {*} 'N' - Admission requests
    * @value   i_flg_priority       {*} 'Y' - Urgent {*} 'N' - not urgent
    * @value   i_flg_home           {*} 'Y' - Home consultation {*} 'N' - otherwise
    * @value   i_completed          {*} 'Y' - Referral completed {*} 'N' - otherwise  
    * @value   i_p_flg_type         {*} 'P' - problem {*} 'A' - allergie {*} 'H' - habit {*} 'D' - Relevant diseases {*} 'E'
    * @param   o_flg_show           {*} 'Y' - Show message {*} 'N' - otherwise
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   25-06-2009
    */
    FUNCTION update_referral
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_ext_req          IN p1_external_request.id_external_request%TYPE,
        i_dt_modified      IN VARCHAR2,
        i_speciality       IN p1_speciality.id_speciality%TYPE,
        i_dcs              IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_req_type         IN p1_external_request.req_type%TYPE,
        i_flg_type         IN p1_external_request.flg_type%TYPE,
        i_flg_priority     IN p1_external_request.flg_priority%TYPE,
        i_flg_home         IN p1_external_request.flg_home%TYPE,
        i_id_inst_orig     IN p1_external_request.id_inst_orig%TYPE,
        i_inst_dest        IN institution.id_institution%TYPE,
        i_problems         IN CLOB,
        i_dt_problem_begin IN VARCHAR2,
        i_detail           IN table_table_varchar,
        i_diagnosis        IN CLOB,
        i_completed        IN VARCHAR2,
        i_id_tasks         IN table_table_number,
        i_id_info          IN table_table_number,
        i_num_order        IN professional.num_order%TYPE DEFAULT NULL,
        i_prof_name        IN professional.name%TYPE DEFAULT NULL,
        i_prof_id          IN ref_orig_data.id_professional%TYPE DEFAULT NULL,
        --i_id_institution   IN ref_orig_data.id_institution%TYPE DEFAULT NULL,
        i_institution_name IN ref_orig_data.institution_name%TYPE DEFAULT NULL,
        i_date             IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        i_comments         IN table_table_clob, -- ID ref comment, Flg Status, texto     
        i_prof_cert        IN VARCHAR2,
        i_prof_first_name  IN VARCHAR2,
        i_prof_surname     IN VARCHAR2,
        i_prof_phone       IN VARCHAR2,
        i_id_fam_rel       IN family_relationship.id_family_relationship%TYPE,
        i_name_first_rel   IN VARCHAR2,
        i_name_middle_rel  IN VARCHAR2,
        i_name_last_rel    IN VARCHAR2,
        --Health insurance
        i_health_plan IN health_plan.id_health_plan%TYPE DEFAULT NULL,
        i_exemption   IN NUMBER DEFAULT NULL,
        o_ext_req     OUT p1_external_request.id_external_request%TYPE,
        o_flg_show    OUT VARCHAR2,
        o_msg         OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Update mdct external request
    *
    * @param   i_lang                Language associated to the professional executing the request
    * @param   i_prof                Professional, institution and software ids
    * @param   i_workflow            Referral workflow identifier
    * @param   i_ext_req             Referral identifier
    * @param   i_dt_modified         Date of last change, as returned in pk_ref_service.get_referral    
    * @param   i_req_type            (M)anual; Using clinical (P)rotocol
    * @param   i_flg_type            Referral type
    * @param   i_id_episode          Episode identifier
    * @param   i_flg_priority_home   Priority and home flags home for each mcdt
    * @param   i_mcdt                MCDT information to relate to this referral
    * @param   i_problems            Problems identifier to be addressed
    * @param   i_problems_desc       Problems description to be addressed
    * @param   i_dt_problem_begin    Problem onset
    * @param   i_detail              Referral detail info. For each detail: [id_detail|flg_type|text|flg|id_group]* @param   i_diagnosis           Referral Diagnosis
    * @param   i_diagnosis           Referral Diagnosis
    * @param   i_completed           Referral data is completed? (Y/N)
    * @param   i_id_task             Referral tasks needed for (S)cheduling. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done
    * @param   i_id_info             Referral tasks needed for (C)onsultation. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done
    * @param   i_date                Operation date
    * @param   i_codification        MCDTs codification identifier
    * @param   i_flg_laterality      MCDT laterality information    
    * @param   o_ext_req             Referral identifier
    * @param   o_flg_show            Show message (Y/N)
    * @param   o_msg                 Message text
    * @param   o_msg_title           Message title
    * @param   o_button              Type of button to show with message
    * @param   o_error               An error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Joana Barroso
    * @version 1.0
    * @since   02-01-2013
    */
    FUNCTION update_mcdt_referral
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_workflow          IN wf_workflow.id_workflow%TYPE,
        i_ext_req           IN p1_external_request.id_external_request%TYPE,
        i_dt_modified       IN VARCHAR2,
        i_req_type          IN p1_external_request.req_type%TYPE,
        i_flg_type          IN p1_external_request.flg_type%TYPE,
        i_id_episode        IN episode.id_episode%TYPE,
        i_flg_priority_home IN table_table_varchar,
        i_mcdt              IN table_table_number,
        i_problems          IN CLOB,
        i_dt_problem_begin  IN VARCHAR2,
        i_detail            IN table_table_varchar,
        i_diagnosis         IN CLOB,
        i_completed         IN VARCHAR2,
        i_id_tasks          IN table_table_number,
        i_id_info           IN table_table_number,
        i_date              IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        i_codification      IN codification.id_codification%TYPE,
        i_flg_laterality    IN table_varchar DEFAULT NULL,
        i_consent           IN VARCHAR2,
        i_health_plan       IN table_number DEFAULT NULL,
        i_exemption         IN table_number DEFAULT NULL,
        o_ext_req           OUT table_number,
        o_flg_show          OUT VARCHAR2,
        o_msg               OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_button            OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Return number to be used in printed referrals.   
    *
    * @param      i_lang         professional language
    * @param      i_prof         professional, institution and software ids
    * @param      i_ext_req      referral id
    * @param      o_number       referral number
    * @param      O_ERROR        erro
    *
    * @return     boolean
    * @author     Joao Sa
    * @version    0.1
    * @since      2008/07/17
    * @modified    
    */
    FUNCTION get_referral_number
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_ext_req           IN p1_external_request.id_external_request%TYPE,
        i_id_ref_completion IN ref_completion.id_ref_completion%TYPE,
        o_number            OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Return number to be used in printed referrals.   
    *
    * @param      i_lang         professional language
    * @param      i_prof         professional, institution and software ids
    * @param      i_ext_req      referral id
    * @param      o_number       referral number
    * @param      O_ERROR        erro
    *
    * @return     boolean
    * @author     Joao Sa
    * @version    0.1
    * @since      2008/07/17
    * @modified    
    */
    FUNCTION get_referral_number
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_dt_req            IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_ref_completion IN ref_completion.id_ref_completion%TYPE,
        o_number            OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns message if there are active (emited and not closed) requests for the
    * patient/speciality provided in the last 30 days.  
    *
    * @param   i_lang               Language associated to the professional executing the request
    * @param   i_prof               Professional, institution and software ids
    * @param   i_id_patient         Patient identifier
    * @param   i_spec               Referral speciality identifier
    * @param   i_type               Referral type. If null returns all referrals, otherwise returns the referrals selected type
    * @param   o_flg_show           Show message (Y/N)
    * @param   o_msg                Message text
    * @param   o_msg_title          Message title
    * @param   o_button             Type of button to show with message
    * @param   o_error              An error message, set when return=false
    *
    * @value   i_type               {*} 'C' - consulation {*} 'A' - lab tests {*} 'I' - imaging exams {*} 'E' - other exams
    *                               {*} 'P' - procedures {*} 'F' - MFR
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
    * Returns number of days to active requests for the i_mcdt
    *
    * @param   i_lang language
    * @param   i_prof profissional, institution, software
    * @param   i_mcdt  id_analysis, id_exam, Intervention
    * @param   i_type if null returns all request, otherwise return for the selected type
    *          ((C)onsulation, (A)nalysis, (E)xam, (I)ntervention)
    *
    * @return  Number of days
    * @author  Joana Barroso
    * @version 1.0
    * @since   25-08-2011
    */

    FUNCTION get_mcdt_active_count
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_mcdt IN ref_mcdt_active_count.id_mcdt%TYPE,
        i_type IN ref_mcdt_active_count.flg_mcdt%TYPE
    ) RETURN NUMBER;

    /**
    * Returns message if there are active (emited and not closed) requests for the
    * patient/i_mcdt provided in the last 30 days.  
    *
    * @param   i_lang            Language associated to the professional executing the request
    * @param   i_prof            Professional, institution and software ids
    * @param   i_id_patient      Patient identifier
    * @param   i_mcdt            id_analysis, id_exam, Intervention
    * @param   i_type            Referral type. If null returns all request, otherwise return for the selected type
    * @param   o_flg_show        Show message (Y/N)
    * @param   o_msg             Message text
    * @param   o_msg_title       Message title
    * @param   o_button          Type of button to show with message
    * @param   o_error           An error message, set when return=false
    *
    * @value   i_type            {*} NULL- all referral types {*} C-Consulation {*} A-Lab tests {*} E-Exam {*} I-Intervention {*} F-Rehab
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
    * Insert tasks
    *
    * @param   I_LANG     Language associated to the professional executing the request
    * @param   I_PROF     Professional, institution and software ids
    * @param   i_ext_req  Referral id
    * @param   i_id_task  Referral tasks needed for (S)cheduling. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done
    * @param   i_id_info  Referral tasks needed for (C)onsultation. [ID_TASK|ID_GROUP|ID_OP,ID_TASK_DONE], ID_OP: 0- delete, 1- insert, 2-cancel task_done    
    * @param   i_date     Operation date
    * @param   O_ERROR    An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   09-10-2007
    */
    FUNCTION create_tasks_done
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_ext_req  IN p1_external_request.id_external_request%TYPE,
        i_id_tasks IN table_table_number,
        i_id_info  IN table_table_number,
        i_date     IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    -- RETURNS NEXT CODE NUMBER FOR P1_EXTERNAL_REQUEST
    FUNCTION get_ref_num_req(i_inst IN NUMBER) RETURN VARCHAR2;

    /**
    * Cancel referral
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof id professional, institution and software    
    * @param   i_ext_req        Referral identifier    
    * @param   i_id_patient     Patient identifier
    * @param   i_id_episode     Episode identifier        
    * @param   i_notes          Cancelation notes 
    * @param   i_reason         Cancelation reason 
    * @param   i_transaction_id Scheduler 3.0 identifier
    * @param   o_track          Array of ID_TRACKING transitions
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   17-10-2007
    */
    FUNCTION cancel_referral
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ext_req        IN p1_external_request.id_external_request%TYPE,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_episode     IN episode.id_episode%TYPE,
        i_notes          IN p1_detail.text%TYPE,
        i_reason         IN p1_reason_code.id_reason_code%TYPE,
        i_transaction_id IN VARCHAR2,
        o_track          OUT table_number,
        o_error          OUT t_error_out
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
    * @author  Joao S
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
    * Creates an EHR episode (to be used in referral)    
    *
    * @param   i_lang               Language identififer
    * @param   i_prof               Professional identififer
    * @param   i_id_patient         Patient identifier
    * @param   i_id_dep_clin_serv   Department and clinical service identifier
    * @param   o_id_episode         Episode identifier  
    * @param   o_error              An error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise    
    * @author  Ana Monteiro
    * @version 2.6.1
    * @since   14-07-2011
    */
    FUNCTION create_episode
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN p1_external_request.id_patient%TYPE,
        i_id_dep_clin_serv IN p1_external_request.id_dep_clin_serv%TYPE,
        o_id_episode       OUT p1_external_request.id_episode%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

END pk_ref_orig_phy;
/
