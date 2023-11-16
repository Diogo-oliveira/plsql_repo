/*-- Last Change Revision: $Rev: 2027594 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:44 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ref_service AS

    g_error         VARCHAR2(1000 CHAR);
    g_package_name  VARCHAR2(50 CHAR);
    g_package_owner VARCHAR2(50 CHAR);
    g_exception    EXCEPTION;
    g_exception_np EXCEPTION;
    g_retval BOOLEAN;

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
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
    BEGIN
    
        l_params := 'ID_REF=' || i_ext_req || ' PAT=' || i_id_patient || ' SPEC=' || i_speciality || ' DCS=' ||
                    i_id_dep_clin_serv || ' REQ_TYP=' || i_req_type || ' FLG_TYP=' || i_flg_type || ' PRI=' ||
                    i_flg_priority || ' HOME=' || i_flg_home || ' I_ORIG=' || i_inst_orig || ' I_DEST=' || i_inst_dest ||
                    ' EPIS=' || i_epis || ' i_dt_problem_begin=' || i_dt_problem_begin || ' i_completed=' ||
                    i_completed || ' i_workflow=' || i_workflow || ' i_num_order=' || i_num_order || ' i_prof_id=' ||
                    i_prof_id || ' i_external_sys=' || i_external_sys;
        g_error  := 'Init insert_referral / ' || l_params;
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_ext_req, i_dt_system_date => current_timestamp);
    
        IF i_ext_req IS NULL
        THEN
            IF i_workflow IS NULL
            THEN
                IF i_speciality IS NULL
                THEN
                    g_error := 'Speciality cannot be null';
                    RAISE g_exception;
                END IF;
            
                -- old workflow
                g_error  := 'CALL pk_p1_med_cs.create_external_request / ' || l_params;
                g_retval := pk_p1_med_cs.create_external_request(i_lang             => i_lang,
                                                                 i_prof             => i_prof,
                                                                 i_id_patient       => i_id_patient,
                                                                 i_speciality       => i_speciality,
                                                                 i_id_dep_clin_serv => i_id_dep_clin_serv,
                                                                 i_req_type         => i_req_type,
                                                                 i_flg_type         => i_flg_type,
                                                                 i_flg_priority     => i_flg_priority,
                                                                 i_flg_home         => i_flg_home,
                                                                 i_inst_dest        => i_inst_dest,
                                                                 --i_id_sched            => NULL,
                                                                 i_problems            => i_problems,
                                                                 i_dt_problem_begin    => i_dt_problem_begin,
                                                                 i_detail              => i_detail,
                                                                 i_diagnosis           => i_diagnosis,
                                                                 i_completed           => i_completed,
                                                                 i_id_tasks            => i_id_tasks,
                                                                 i_id_info             => i_id_info,
                                                                 i_epis                => i_epis,
                                                                 i_comments            => i_comments,
                                                                 i_prof_cert           => i_prof_cert,
                                                                 i_prof_first_name     => i_prof_first_name,
                                                                 i_prof_surname        => i_prof_surname,
                                                                 i_prof_phone          => i_prof_phone,
                                                                 i_id_fam_rel          => i_id_fam_rel,
                                                                 i_fam_rel_spec        => i_fam_rel_spec,
                                                                 i_name_first_rel      => i_name_first_rel,
                                                                 i_name_middle_rel     => i_name_middle_rel,
                                                                 i_name_last_rel       => i_name_last_rel,
                                                                 i_health_plan         => i_health_plan,
                                                                 i_exemption           => i_exemption,
                                                                 o_id_external_request => o_id_external_request,
                                                                 o_flg_show            => o_flg_show,
                                                                 o_msg                 => o_msg,
                                                                 o_msg_title           => o_msg_title,
                                                                 o_button              => o_button,
                                                                 o_error               => o_error);
            
            ELSE
            
                g_error  := 'CALL pk_ref_orig_phy.create_referral / ' || l_params;
                g_retval := pk_ref_orig_phy.create_referral(i_lang             => i_lang,
                                                            i_prof             => i_prof,
                                                            i_workflow         => i_workflow,
                                                            i_id_patient       => i_id_patient,
                                                            i_speciality       => i_speciality,
                                                            i_dcs              => i_id_dep_clin_serv,
                                                            i_req_type         => i_req_type,
                                                            i_flg_type         => i_flg_type,
                                                            i_flg_priority     => i_flg_priority,
                                                            i_flg_home         => i_flg_home,
                                                            i_id_inst_orig     => i_inst_orig,
                                                            i_inst_dest        => i_inst_dest,
                                                            i_problems         => i_problems,
                                                            i_dt_problem_begin => i_dt_problem_begin,
                                                            i_detail           => i_detail,
                                                            i_diagnosis        => i_diagnosis,
                                                            i_completed        => i_completed,
                                                            i_id_tasks         => i_id_tasks,
                                                            i_id_info          => i_id_info,
                                                            i_epis             => i_epis,
                                                            i_num_order        => i_num_order,
                                                            i_prof_name        => i_prof_name,
                                                            i_prof_id          => i_prof_id,
                                                            i_institution_name => i_institution_name,
                                                            i_external_sys     => i_external_sys,
                                                            i_comments         => i_comments,
                                                            i_prof_cert        => i_prof_cert,
                                                            i_prof_first_name  => i_prof_first_name,
                                                            i_prof_surname     => i_prof_surname,
                                                            i_prof_phone       => i_prof_phone,
                                                            i_id_fam_rel       => i_id_fam_rel,
                                                            i_name_first_rel   => i_name_first_rel,
                                                            i_name_middle_rel  => i_name_middle_rel,
                                                            i_name_last_rel    => i_name_last_rel,
                                                            i_health_plan      => i_health_plan,
                                                            i_exemption        => i_exemption,
                                                            o_flg_show         => o_flg_show,
                                                            o_msg              => o_msg,
                                                            o_msg_title        => o_msg_title,
                                                            o_button           => o_button,
                                                            o_ext_req          => o_id_external_request,
                                                            o_error            => o_error);
            END IF;
        
        ELSE
        
            IF i_workflow IS NULL
            THEN
                -- old workflow
                g_error  := 'CALL pk_p1_med_cs.update_external_request / ' || l_params;
                g_retval := pk_p1_med_cs.update_external_request(i_lang             => i_lang,
                                                                 i_ext_req          => i_ext_req,
                                                                 i_dt_modified      => i_dt_modified,
                                                                 i_speciality       => i_speciality,
                                                                 i_id_dep_clin_serv => i_id_dep_clin_serv,
                                                                 i_req_type         => i_req_type,
                                                                 i_flg_type         => i_flg_type,
                                                                 i_flg_priority     => i_flg_priority,
                                                                 i_flg_home         => i_flg_home,
                                                                 i_inst_dest        => i_inst_dest,
                                                                 i_prof             => i_prof,
                                                                 --i_id_sched            => NULL,
                                                                 i_problems            => i_problems,
                                                                 i_dt_problem_begin    => i_dt_problem_begin,
                                                                 i_detail              => i_detail,
                                                                 i_diagnosis           => i_diagnosis,
                                                                 i_completed           => i_completed,
                                                                 i_id_tasks            => i_id_tasks,
                                                                 i_id_info             => i_id_info,
                                                                 i_comments            => i_comments,
                                                                 i_prof_cert           => i_prof_cert,
                                                                 i_prof_first_name     => i_prof_first_name,
                                                                 i_prof_surname        => i_prof_surname,
                                                                 i_prof_phone          => i_prof_phone,
                                                                 i_id_fam_rel          => i_id_fam_rel,
                                                                 i_fam_rel_spec        => i_fam_rel_spec,
                                                                 i_name_first_rel      => i_name_first_rel,
                                                                 i_name_middle_rel     => i_name_middle_rel,
                                                                 i_name_last_rel       => i_name_last_rel,
                                                                 i_health_plan         => i_health_plan,
                                                                 i_exemption           => i_exemption,
                                                                 o_id_external_request => o_id_external_request,
                                                                 o_flg_show            => o_flg_show,
                                                                 o_msg                 => o_msg,
                                                                 o_msg_title           => o_msg_title,
                                                                 o_button              => o_button,
                                                                 o_error               => o_error);
            
            ELSE
                g_error  := 'CALL pk_ref_orig_phy.update_referral / ' || l_params;
                g_retval := pk_ref_orig_phy.update_referral(i_lang             => i_lang,
                                                            i_prof             => i_prof,
                                                            i_ext_req          => i_ext_req,
                                                            i_dt_modified      => i_dt_modified,
                                                            i_speciality       => i_speciality,
                                                            i_dcs              => i_id_dep_clin_serv,
                                                            i_req_type         => i_req_type,
                                                            i_flg_type         => i_flg_type,
                                                            i_flg_priority     => i_flg_priority,
                                                            i_flg_home         => i_flg_home,
                                                            i_id_inst_orig     => i_inst_orig,
                                                            i_inst_dest        => i_inst_dest,
                                                            i_problems         => i_problems,
                                                            i_dt_problem_begin => i_dt_problem_begin,
                                                            i_detail           => i_detail,
                                                            i_diagnosis        => i_diagnosis,
                                                            i_completed        => i_completed,
                                                            i_id_tasks         => i_id_tasks,
                                                            i_id_info          => i_id_info,
                                                            i_num_order        => i_num_order,
                                                            i_prof_name        => i_prof_name,
                                                            i_prof_id          => i_prof_id,
                                                            i_institution_name => i_institution_name,
                                                            i_comments         => i_comments,
                                                            i_prof_cert        => i_prof_cert,
                                                            i_prof_first_name  => i_prof_first_name,
                                                            i_prof_surname     => i_prof_surname,
                                                            i_prof_phone       => i_prof_phone,
                                                            i_id_fam_rel       => i_id_fam_rel,
                                                            i_name_first_rel   => i_name_first_rel,
                                                            i_name_middle_rel  => i_name_middle_rel,
                                                            i_name_last_rel    => i_name_last_rel,
                                                            i_health_plan      => i_health_plan,
                                                            i_exemption        => i_exemption,
                                                            o_ext_req          => o_id_external_request,
                                                            o_flg_show         => o_flg_show,
                                                            o_msg              => o_msg,
                                                            o_msg_title        => o_msg_title,
                                                            o_button           => o_button,
                                                            o_error            => o_error);
            
            END IF;
        
        END IF;
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'INSERT_REFERRAL',
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END insert_referral;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'Init insert_mcdt_referral / i_ext_req=' || i_ext_req || ' i_id_patient=' || i_id_patient ||
                   ' i_req_type=' || i_req_type || ' i_flg_type=' || i_flg_type || ' i_dt_problem_begin=' ||
                   i_dt_problem_begin || ' i_completed=' || i_completed || ' i_epis=' || i_epis || ' i_workflow=' ||
                   i_workflow;
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_ext_req, i_dt_system_date => current_timestamp);
    
        IF i_ext_req IS NULL
        THEN
            IF i_workflow IS NULL
            THEN
                -- old workflow
                g_error  := g_error || ' / Call pk_p1_med_cs.create_external_request';
                g_retval := pk_p1_med_cs.create_external_request_mcdt(i_lang              => i_lang,
                                                                      i_id_patient        => i_id_patient,
                                                                      i_id_episode        => i_epis,
                                                                      i_req_type          => i_req_type,
                                                                      i_flg_type          => i_flg_type,
                                                                      i_flg_priority_home => i_flg_priority_home,
                                                                      i_mcdt              => i_mcdt,
                                                                      i_prof              => i_prof,
                                                                      --i_id_sched            => NULL,
                                                                      i_problems                  => i_problems,
                                                                      i_dt_problem_begin          => i_dt_problem_begin,
                                                                      i_detail                    => i_detail,
                                                                      i_diagnosis                 => i_diagnosis,
                                                                      i_completed                 => i_completed,
                                                                      i_id_tasks                  => i_id_tasks,
                                                                      i_id_info                   => i_id_info,
                                                                      i_codification              => i_codification,
                                                                      i_flg_laterality            => i_flg_laterality,
                                                                      i_consent                   => i_consent,
                                                                      i_reason                    => i_reason,
                                                                      i_complementary_information => i_complementary_information,
                                                                      i_health_plan               => CASE
                                                                                                         WHEN i_health_plan IS NULL THEN
                                                                                                          NULL
                                                                                                         ELSE
                                                                                                          i_health_plan(1)
                                                                                                     END,
                                                                      i_exemption                 => CASE
                                                                                                         WHEN i_health_plan IS NULL THEN
                                                                                                          NULL
                                                                                                         ELSE
                                                                                                          i_exemption(1)
                                                                                                     END,
                                                                      i_id_fam_rel                => i_id_fam_rel,
                                                                      i_fam_rel_spec              => i_fam_rel_spec,
                                                                      i_name_first_rel            => i_name_first_rel,
                                                                      i_name_middle_rel           => i_name_middle_rel,
                                                                      i_name_last_rel             => i_name_last_rel,
                                                                      o_id_external_request       => o_ext_req,
                                                                      o_flg_show                  => o_flg_show,
                                                                      o_msg                       => o_msg,
                                                                      o_msg_title                 => o_msg_title,
                                                                      o_button                    => o_button,
                                                                      o_error                     => o_error);
            ELSE
                -- new workflow
                g_error  := g_error || ' / Call pk_p1_med_cs.create_external_request';
                g_retval := pk_ref_orig_phy.create_mcdt_referral(i_lang              => i_lang,
                                                                 i_prof              => i_prof,
                                                                 i_workflow          => i_workflow,
                                                                 i_flg_priority_home => i_flg_priority_home,
                                                                 i_mcdt              => i_mcdt,
                                                                 i_id_patient        => i_id_patient,
                                                                 i_req_type          => i_req_type,
                                                                 i_flg_type          => i_flg_type,
                                                                 i_problems          => i_problems,
                                                                 i_dt_problem_begin  => i_dt_problem_begin,
                                                                 i_detail            => i_detail,
                                                                 i_diagnosis         => i_diagnosis,
                                                                 i_completed         => i_completed,
                                                                 i_id_tasks          => i_id_tasks,
                                                                 i_id_info           => i_id_info,
                                                                 i_epis              => i_epis,
                                                                 i_date              => i_date,
                                                                 i_codification      => i_codification,
                                                                 i_flg_laterality    => i_flg_laterality,
                                                                 i_consent           => i_consent,
                                                                 o_flg_show          => o_flg_show,
                                                                 o_msg               => o_msg,
                                                                 o_msg_title         => o_msg_title,
                                                                 o_button            => o_button,
                                                                 o_ext_req           => o_ext_req,
                                                                 o_error             => o_error);
            END IF;
        ELSE
            IF i_workflow IS NULL
            THEN
                -- old workflow
                g_error  := g_error || ' / Call pk_p1_med_cs.update_external_request_mcdt';
                g_retval := pk_p1_med_cs.update_external_request_mcdt(i_lang              => i_lang,
                                                                      i_ext_req           => i_ext_req,
                                                                      i_dt_modified       => i_dt_modified,
                                                                      i_id_episode        => i_epis,
                                                                      i_req_type          => i_req_type,
                                                                      i_flg_type          => i_flg_type,
                                                                      i_flg_priority_home => i_flg_priority_home,
                                                                      i_mcdt              => i_mcdt,
                                                                      i_prof              => i_prof,
                                                                      --i_id_sched            => NULL,
                                                                      i_problems                  => i_problems,
                                                                      i_dt_problem_begin          => i_dt_problem_begin,
                                                                      i_detail                    => i_detail,
                                                                      i_diagnosis                 => i_diagnosis,
                                                                      i_completed                 => i_completed,
                                                                      i_id_tasks                  => i_id_tasks,
                                                                      i_id_info                   => i_id_info,
                                                                      i_codification              => i_codification,
                                                                      i_flg_laterality            => i_flg_laterality,
                                                                      i_consent                   => i_consent,
                                                                      i_health_plan               => i_health_plan,
                                                                      i_exemption                 => i_exemption,
                                                                      i_reason                    => i_reason,
                                                                      i_complementary_information => i_complementary_information,
                                                                      i_id_fam_rel                => i_id_fam_rel,
                                                                      i_fam_rel_spec              => i_fam_rel_spec,
                                                                      i_name_first_rel            => i_name_first_rel,
                                                                      i_name_middle_rel           => i_name_middle_rel,
                                                                      i_name_last_rel             => i_name_last_rel,
                                                                      o_id_external_request       => o_ext_req,
                                                                      o_flg_show                  => o_flg_show,
                                                                      o_msg                       => o_msg,
                                                                      o_msg_title                 => o_msg_title,
                                                                      o_button                    => o_button,
                                                                      o_error                     => o_error);
            
            ELSE
                g_error  := g_error || ' / Call pk_ref_orig_phy.update_mcdt_referral';
                g_retval := pk_ref_orig_phy.update_mcdt_referral(i_lang              => i_lang,
                                                                 i_prof              => i_prof,
                                                                 i_workflow          => i_workflow,
                                                                 i_ext_req           => i_ext_req,
                                                                 i_dt_modified       => i_dt_modified,
                                                                 i_req_type          => i_req_type,
                                                                 i_flg_type          => i_flg_type,
                                                                 i_id_episode        => i_epis,
                                                                 i_flg_priority_home => i_flg_priority_home,
                                                                 i_mcdt              => i_mcdt,
                                                                 i_problems          => i_problems,
                                                                 i_dt_problem_begin  => i_dt_problem_begin,
                                                                 i_detail            => i_detail,
                                                                 i_diagnosis         => i_diagnosis,
                                                                 i_completed         => i_completed,
                                                                 i_id_tasks          => i_id_tasks,
                                                                 i_id_info           => i_id_info,
                                                                 i_date              => i_date,
                                                                 i_codification      => i_codification,
                                                                 i_flg_laterality    => i_flg_laterality,
                                                                 i_consent           => i_consent,
                                                                 i_health_plan       => i_health_plan,
                                                                 i_exemption         => i_exemption,
                                                                 o_ext_req           => o_ext_req,
                                                                 o_flg_show          => o_flg_show,
                                                                 o_msg               => o_msg,
                                                                 o_msg_title         => o_msg_title,
                                                                 o_button            => o_button,
                                                                 o_error             => o_error);
            END IF;
        END IF;
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'INSERT_MCDT_REFERRAL',
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END insert_mcdt_referral;

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
    ) RETURN BOOLEAN IS
        l_transaction_id VARCHAR2(4000);
        l_track_tab      table_number;
    BEGIN
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_ext_req, i_dt_system_date => current_timestamp);
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(l_transaction_id, i_prof);
    
        IF i_workflow IS NULL
        THEN
        
            g_error  := 'Call pk_p1_med_cs.cancel_external_request_int |WF=' || i_workflow || '|REF=' || i_ext_req;
            g_retval := pk_p1_med_cs.cancel_external_request_int(i_lang           => i_lang,
                                                                 i_prof           => i_prof,
                                                                 i_ext_req        => i_ext_req,
                                                                 i_mcdts          => NULL,
                                                                 i_id_patient     => NULL,
                                                                 i_id_episode     => NULL,
                                                                 i_notes          => i_notes,
                                                                 i_reason         => i_reason,
                                                                 i_transaction_id => l_transaction_id,
                                                                 o_track          => l_track_tab,
                                                                 o_error          => o_error);
        
        ELSE
            g_error  := 'Call pk_ref_orig_phy.cancel_referral |WF=' || i_workflow || '|REF=' || i_ext_req;
            g_retval := pk_ref_orig_phy.cancel_referral(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_ext_req        => i_ext_req,
                                                        i_id_patient     => NULL,
                                                        i_id_episode     => NULL,
                                                        i_notes          => i_notes,
                                                        i_reason         => i_reason,
                                                        i_transaction_id => l_transaction_id,
                                                        o_track          => l_track_tab,
                                                        o_error          => o_error);
        END IF;
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        COMMIT;
        -- warns the new scheduler that it should commit the transaction        
        pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            pk_schedule_api_upstream.do_rollback(i_id_transaction => l_transaction_id, i_prof => i_prof);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CANCEL_REFERRAL',
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            --warns the new scheduler that it should rollback the transaction
            pk_schedule_api_upstream.do_rollback(i_id_transaction => l_transaction_id, i_prof => i_prof);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END cancel_referral;

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
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'Init get_pat_spec_active_count / i_id_patient=' || i_id_patient || ' i_spec=' || i_spec ||
                   ' i_type=' || i_type;
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Call pk_ref_orig_phy.get_pat_spec_active_count |PAT=' || i_id_patient || '|SPEC=' || i_spec ||
                    '|TYPE=' || i_type;
        g_retval := pk_ref_orig_phy.get_pat_spec_active_count(i_lang       => i_lang,
                                                              i_prof       => i_prof,
                                                              i_id_patient => i_id_patient,
                                                              i_spec       => i_spec,
                                                              i_type       => i_type,
                                                              o_flg_show   => o_flg_show,
                                                              o_msg        => o_msg,
                                                              o_msg_title  => o_msg_title,
                                                              o_button     => o_button,
                                                              o_error      => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SPEC_ACTIVE_COUNT',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_pat_spec_active_count;

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
    ) RETURN BOOLEAN IS
    BEGIN
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Call pk_ref_orig_phy.get_pat_spec_active_count |PAT=' || i_id_patient || '|TYPE=' || i_type;
        g_retval := pk_ref_orig_phy.get_pat_mcdt_active_count(i_lang       => i_lang,
                                                              i_prof       => i_prof,
                                                              i_id_patient => i_id_patient,
                                                              i_mcdt       => i_mcdt,
                                                              i_type       => i_type,
                                                              o_flg_show   => o_flg_show,
                                                              o_msg        => o_msg,
                                                              o_msg_title  => o_msg_title,
                                                              o_button     => o_button,
                                                              o_error      => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PAT_MCDT_ACTIVE_COUNT',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_pat_mcdt_active_count;
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
    ) RETURN BOOLEAN IS
    BEGIN
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Call pk_ref_orig_phy.get_spec_help / REF=' || i_p1_spec || ' INST=' || i_inst;
        g_retval := pk_ref_orig_phy.get_spec_help(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_p1_spec => i_p1_spec,
                                                  i_inst    => i_inst,
                                                  o_help    => o_help,
                                                  o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alertlog.log_warn(g_error);
            pk_types.open_cursor_if_closed(o_help);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SPEC_HELP',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_cursor_if_closed(o_help);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_spec_help;

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
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'Init get_clinical_service / ID_PATIENT=' || i_patient || ' i_flg_availability=' ||
                   i_flg_availability || ' ID_EXTERNAL_SYS=' || i_external_sys;
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        IF i_flg_availability IN (pk_ref_constant.g_flg_availability_e, pk_ref_constant.g_flg_availability_p)
        THEN
            g_error  := 'Call pk_ref_list.get_net_spec / ID_PATIENT=' || i_patient || ' REF_TYPE=' ||
                        i_flg_availability || ' ID_EXTERNAL_SYS=' || i_external_sys;
            g_retval := pk_ref_list.get_net_spec(i_lang         => i_lang,
                                                 i_prof         => i_prof,
                                                 i_pat          => i_patient,
                                                 i_ref_type     => i_flg_availability,
                                                 i_external_sys => i_external_sys,
                                                 o_sql          => o_sql,
                                                 o_error        => o_error);
        
        ELSIF i_flg_availability = pk_ref_constant.g_flg_availability_i
        THEN
            g_error  := 'Call pk_ref_list.get_internal_dep / ID_PATIENT=' || i_patient || ' i_flg_availability=' ||
                        i_flg_availability || ' ID_EXTERNAL_SYS=' || i_external_sys;
            g_retval := pk_ref_list.get_internal_dep(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_pat          => i_patient,
                                                     i_external_sys => i_external_sys,
                                                     o_dep          => o_sql,
                                                     o_error        => o_error);
        
        END IF;
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_types.open_cursor_if_closed(o_sql);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_CLINICAL_SERVICE',
                                              o_error    => o_error);
            pk_types.open_cursor_if_closed(o_sql);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_clinical_service;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        IF i_dep IS NULL
        THEN
            -- this value must be defined under this circumstances
            g_error := 'Department identifier must be defined';
            RAISE g_exception;
        END IF;
    
        g_error  := 'Call pk_ref_list.get_internal_spec / ID_PATIENT=' || i_pat || ' ID_DEPARTMENT=' || i_dep;
        g_retval := pk_ref_list.get_internal_spec(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_pat          => i_pat,
                                                  i_dep          => i_dep,
                                                  i_external_sys => NULL, -- todo: incluir no flash este parametro
                                                  o_cs           => o_cs,
                                                  o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_types.open_cursor_if_closed(o_cs);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_INTERNAL_SPEC',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_cursor_if_closed(o_cs);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_internal_spec;

    /**
    * Get institutions for the selected request speciality
    *
    * @param   i_lang                   Language associated to the professional executing the request
    * @param   i_prof                   Professional, institution and software ids
    * @param   i_flg_availability       Referring type
    * @param   i_external_sys           External system that created the referral   
    * @param   i_id_speciality          Referral speciality identifier
    * @param   i_flg_ref_line           Referral line 1,2,3
    * @param   i_flg_type_ins           Referral network to which it belongs
    * @param   i_flg_inside_ref_area    Flag indicating if is inside referral area or not
    * @param   i_flg_type               Referral type
    * @param   o_sql                    Clinical institutions data
    * @param   o_error                  An error message, set when return=false
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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Call pk_ref_list.get_net_inst / i_flg_availability=' || i_flg_availability || ' ID_EXTERNAL_SYS=' ||
                    i_external_sys || ' ID_SPECIALITY=' || i_id_speciality || ' FLG_REF_LINE=' || i_flg_ref_line ||
                    ' FLG_TYPE_INS=' || i_flg_type_ins || ' FLG_INSIDE_REF_AREA=' || i_flg_inside_ref_area ||
                    ' FLG_TYPE=' || i_flg_type;
        g_retval := pk_ref_list.get_net_inst(i_lang                => i_lang,
                                             i_prof                => i_prof,
                                             i_ref_type            => i_flg_availability,
                                             i_external_sys        => i_external_sys,
                                             i_id_speciality       => i_id_speciality,
                                             i_flg_ref_line        => i_flg_ref_line,
                                             i_flg_type_ins        => i_flg_type_ins,
                                             i_flg_inside_ref_area => i_flg_inside_ref_area,
                                             i_flg_type            => i_flg_type,
                                             o_sql                 => o_sql,
                                             o_error               => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_types.open_cursor_if_closed(o_sql);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_CLINICAL_INSTITUTION',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_cursor_if_closed(o_sql);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_clinical_institution;

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
    ) RETURN BOOLEAN IS
    BEGIN
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_ref, i_dt_system_date => current_timestamp);
    
        g_error  := 'Call pk_ref_orig_phy.can_add_tasks / ID_REF=' || i_ref || ' ID_INST_ORIG=' || i_inst_orig;
        g_retval := pk_ref_orig_phy.can_add_tasks(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_ref       => i_ref,
                                                  i_inst_orig => i_inst_orig,
                                                  o_can_add   => o_can_add,
                                                  o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CAN_ADD_TASKS',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END can_add_tasks;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error := 'CAll pk_ref_list.get_referral_type';
        IF NOT pk_ref_list.get_referral_type(i_lang => i_lang, i_prof => i_prof, o_type => o_type, o_error => o_error)
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_types.open_cursor_if_closed(o_type);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REFERRAL_TYPE',
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_referral_type;

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
    ) RETURN BOOLEAN IS
    BEGIN
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'CAll pk_ref_list.get_country_data / i_country=' || i_country;
        g_retval := pk_ref_list.get_country_data(i_lang    => i_lang,
                                                 i_prof    => i_prof,
                                                 i_country => i_country,
                                                 o_country => o_country,
                                                 o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_types.open_cursor_if_closed(o_country);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_COUNTRY_DATA',
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            pk_types.open_cursor_if_closed(o_country);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
    END get_country_data;

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
    ) RETURN BOOLEAN IS
    BEGIN
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Call pk_ref_list.get_referral_list / i_patient=' || i_patient || ' i_filter=' || i_filter ||
                    ' i_type=' || i_type;
        g_retval := pk_ref_list.get_referral_list(i_lang     => i_lang,
                                                  i_prof     => i_prof,
                                                  i_patient  => i_patient,
                                                  i_filter   => i_filter,
                                                  i_type     => i_type,
                                                  o_ref_list => o_ref_list,
                                                  o_error    => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_types.open_cursor_if_closed(o_ref_list);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REFERRAL_LIST',
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            pk_types.open_cursor_if_closed(o_ref_list);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_referral_list;

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
    ) RETURN BOOLEAN IS
        o_med_dest_data pk_types.cursor_type;
    BEGIN
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ext_req, i_dt_system_date => current_timestamp);
    
        g_error  := 'Call pk_ref_core.get_referral / ID_REF=' || i_id_ext_req;
        g_retval := pk_ref_core.get_referral(i_lang          => i_lang,
                                             i_prof          => i_prof,
                                             i_id_ext_req    => i_id_ext_req,
                                             i_status_detail => i_status_detail,
                                             --i_flg_labels       => pk_ref_constant.g_no,
                                             o_patient          => o_patient,
                                             o_detail           => o_detail,
                                             o_text             => o_text,
                                             o_problem          => o_problem,
                                             o_diagnosis        => o_diagnosis,
                                             o_mcdt             => o_mcdt,
                                             o_needs            => o_needs,
                                             o_info             => o_info,
                                             o_notes_status     => o_notes_status,
                                             o_notes_status_det => o_notes_status_det,
                                             o_answer           => o_answer,
                                             o_title_status     => o_title_status,
                                             o_can_cancel       => o_can_cancel,
                                             o_ref_orig_data    => o_ref_orig_data,
                                             o_ref_comments     => o_ref_comments,
                                             o_fields_rank      => o_fields_rank,
                                             o_med_dest_data    => o_med_dest_data,
                                             o_error            => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        COMMIT; -- this commit needs to be here, there may be a status change in this function
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_types.open_cursor_if_closed(o_patient);
            pk_types.open_cursor_if_closed(o_detail);
            pk_types.open_cursor_if_closed(o_text);
            pk_types.open_cursor_if_closed(o_problem);
            pk_types.open_cursor_if_closed(o_diagnosis);
            pk_types.open_cursor_if_closed(o_mcdt);
            pk_types.open_cursor_if_closed(o_needs);
            pk_types.open_cursor_if_closed(o_info);
            pk_types.open_cursor_if_closed(o_notes_status);
            pk_types.open_cursor_if_closed(o_notes_status_det);
            pk_types.open_cursor_if_closed(o_answer);
            pk_types.open_cursor_if_closed(o_ref_orig_data);
            pk_types.open_cursor_if_closed(o_ref_comments);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REFERRAL',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_cursor_if_closed(o_patient);
            pk_types.open_cursor_if_closed(o_detail);
            pk_types.open_cursor_if_closed(o_text);
            pk_types.open_cursor_if_closed(o_problem);
            pk_types.open_cursor_if_closed(o_diagnosis);
            pk_types.open_cursor_if_closed(o_mcdt);
            pk_types.open_cursor_if_closed(o_needs);
            pk_types.open_cursor_if_closed(o_info);
            pk_types.open_cursor_if_closed(o_notes_status);
            pk_types.open_cursor_if_closed(o_notes_status_det);
            pk_types.open_cursor_if_closed(o_answer);
            pk_types.open_cursor_if_closed(o_ref_orig_data);
            pk_types.open_cursor_if_closed(o_ref_comments);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_referral;

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
    ) RETURN BOOLEAN IS
        l_ref_comments pk_types.cursor_type;
    BEGIN
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ext_req, i_dt_system_date => current_timestamp);
    
        g_error  := 'Call pk_ref_core.get_referral';
        g_retval := pk_ref_core.get_referral(i_lang          => i_lang,
                                             i_prof          => i_prof,
                                             i_id_ext_req    => i_id_ext_req,
                                             i_status_detail => i_status_detail,
                                             --i_flg_labels       => pk_ref_constant.g_yes,
                                             o_patient          => o_patient,
                                             o_detail           => o_detail,
                                             o_text             => o_text,
                                             o_problem          => o_problem,
                                             o_diagnosis        => o_diagnosis,
                                             o_mcdt             => o_mcdt,
                                             o_needs            => o_needs,
                                             o_info             => o_info,
                                             o_notes_status     => o_notes_status,
                                             o_notes_status_det => o_notes_status_det,
                                             o_answer           => o_answer,
                                             o_title_status     => o_title_status,
                                             o_can_cancel       => o_can_cancel,
                                             o_ref_orig_data    => o_ref_orig_data,
                                             o_ref_comments     => l_ref_comments,
                                             o_fields_rank      => o_fields_rank,
                                             o_med_dest_data    => o_med_dest_data,
                                             o_error            => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        COMMIT; -- this commit needs to be here, there may be a status change in this function
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_types.open_cursor_if_closed(o_patient);
            pk_types.open_cursor_if_closed(o_detail);
            pk_types.open_cursor_if_closed(o_text);
            pk_types.open_cursor_if_closed(o_problem);
            pk_types.open_cursor_if_closed(o_diagnosis);
            pk_types.open_cursor_if_closed(o_mcdt);
            pk_types.open_cursor_if_closed(o_needs);
            pk_types.open_cursor_if_closed(o_info);
            pk_types.open_cursor_if_closed(o_notes_status);
            pk_types.open_cursor_if_closed(o_notes_status_det);
            pk_types.open_cursor_if_closed(o_answer);
            pk_types.open_cursor_if_closed(o_ref_orig_data);
            pk_types.open_cursor_if_closed(l_ref_comments);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REFERRAL_REP',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_cursor_if_closed(o_patient);
            pk_types.open_cursor_if_closed(o_detail);
            pk_types.open_cursor_if_closed(o_text);
            pk_types.open_cursor_if_closed(o_problem);
            pk_types.open_cursor_if_closed(o_diagnosis);
            pk_types.open_cursor_if_closed(o_mcdt);
            pk_types.open_cursor_if_closed(o_needs);
            pk_types.open_cursor_if_closed(o_info);
            pk_types.open_cursor_if_closed(o_notes_status);
            pk_types.open_cursor_if_closed(o_notes_status_det);
            pk_types.open_cursor_if_closed(o_answer);
            pk_types.open_cursor_if_closed(o_ref_orig_data);
            pk_types.open_cursor_if_closed(l_ref_comments);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_referral_rep;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ref, i_dt_system_date => current_timestamp);
    
        g_error  := 'Call pk_ref_core.get_referral / ID_REF=' || i_id_ref || ' ID_ACTION=' || i_id_action;
        g_retval := pk_ref_core.get_referral_req_cancel(i_lang       => i_lang,
                                                        i_prof       => i_prof,
                                                        i_id_ref     => i_id_ref,
                                                        i_id_action  => i_id_action,
                                                        o_ref_data   => o_ref_data,
                                                        o_c_req_data => o_c_req_data,
                                                        o_c_req_answ => o_c_req_answ,
                                                        o_error      => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_types.open_cursor_if_closed(o_ref_data);
            pk_types.open_cursor_if_closed(o_c_req_data);
            pk_types.open_cursor_if_closed(o_c_req_answ);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REFERRAL_REQ_CANCEL',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_cursor_if_closed(o_ref_data);
            pk_types.open_cursor_if_closed(o_c_req_data);
            pk_types.open_cursor_if_closed(o_c_req_answ);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
    END get_referral_req_cancel;

    FUNCTION get_doctor_test
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_doc   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Call pk_ref_core.get_doctor_test';
        g_retval := pk_ref_core.get_doctor_test(i_lang => i_lang, i_prof => i_prof, o_doc => o_doc, o_error => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_types.open_cursor_if_closed(o_doc);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_DOCTOR_TEST',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_doc);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_doctor_test;

    FUNCTION set_sched_test
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        i_doc     IN professional.id_professional%TYPE,
        i_date    IN VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_ext_req, i_dt_system_date => current_timestamp);
    
        g_error  := 'Call pk_ref_core.set_sched_test';
        g_retval := pk_ref_core.set_sched_test(i_lang    => i_lang,
                                               i_prof    => i_prof,
                                               i_ext_req => i_ext_req,
                                               i_doc     => i_doc,
                                               i_date    => i_date,
                                               o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SCHED_TEST',
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_sched_test;

    FUNCTION set_efectiv_test
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_transaction_id VARCHAR2(4000);
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_ext_req, i_dt_system_date => current_timestamp);
    
        g_error          := 'START REMOTE TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(l_transaction_id, i_prof);
    
        g_error  := 'Call pk_ref_core.set_efectiv_test';
        g_retval := pk_ref_core.set_efectiv_test(i_lang           => i_lang,
                                                 i_prof           => i_prof,
                                                 i_ext_req        => i_ext_req,
                                                 i_transaction_id => l_transaction_id,
                                                 o_error          => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_EFFECTIV_TEST',
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_efectiv_test;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Call pk_ref_list.get_pat_soc_att / i_id_pat=' || i_id_pat;
        g_retval := pk_ref_list.get_pat_soc_att(i_lang    => i_lang,
                                                i_id_pat  => i_id_pat,
                                                i_prof    => i_prof,
                                                o_pat     => o_pat,
                                                o_sns     => o_sns,
                                                o_seq_num => o_seq_num,
                                                o_photo   => o_photo,
                                                o_id      => o_id,
                                                o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_types.open_cursor_if_closed(o_id);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PAT_SOC_ATT',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_id);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_pat_soc_att;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Call pk_ref_list.get_tasks';
        g_retval := pk_ref_list.get_tasks(i_lang  => i_lang,
                                          i_type  => i_type,
                                          o_tasks => o_tasks,
                                          o_info  => o_info,
                                          o_error => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_tasks);
            pk_types.open_my_cursor(o_info);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_TASKS',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_tasks);
            pk_types.open_my_cursor(o_info);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_tasks;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Call pk_ref_list.get_search_ref';
        g_retval := pk_ref_list.get_search_ref(i_lang          => i_lang,
                                               i_prof          => i_prof,
                                               i_crit_id_tab   => i_id_sys_btn_crit,
                                               i_crit_val_tab  => i_crit_val,
                                               i_prof_cat_type => i_prof_cat_type,
                                               o_flg_show      => o_flg_show,
                                               o_msg           => o_msg,
                                               o_msg_title     => o_msg_title,
                                               o_button        => o_button,
                                               o_pat           => o_pat,
                                               o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    EXCEPTION
    
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_pat);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SEARCH_REF',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_pat);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_search_ref;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Call pk_ref_list.get_search_my_ref';
        g_retval := pk_ref_list.get_search_my_ref(i_lang          => i_lang,
                                                  i_prof          => i_prof,
                                                  i_crit_id_tab   => i_id_sys_btn_crit,
                                                  i_crit_val_tab  => i_crit_val,
                                                  i_prof_cat_type => i_prof_cat_type,
                                                  o_flg_show      => o_flg_show,
                                                  o_msg           => o_msg,
                                                  o_msg_title     => o_msg_title,
                                                  o_button        => o_button,
                                                  o_pat           => o_pat,
                                                  o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_pat);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SEARCH_MY_REF',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_pat);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_search_my_ref;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Call pk_ref_list.get_search_pat';
        g_retval := pk_ref_list.get_search_pat(i_lang          => i_lang,
                                               i_prof          => i_prof,
                                               i_crit_id_tab   => i_id_sys_btn_crit,
                                               i_crit_val_tab  => i_crit_val,
                                               i_prof_cat_type => i_prof_cat_type,
                                               o_flg_show      => o_flg_show,
                                               o_msg           => o_msg,
                                               o_msg_title     => o_msg_title,
                                               o_button        => o_button,
                                               o_pat           => o_pat,
                                               o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_pat);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SEARCH_PAT',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_pat);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_search_pat;

    /**
    * Returns the options for the professional.
    *
    * @param   I_LANG           Language associated to the professional executing the request
    * @param   I_PROF           Professional, institution and software ids
    * @param   i_workflow       Workflow identifier
    * @param   i_id_ext_req     Referral id
    * @param   I_DT_MODIFIED    Last modified date as provided by get_referral    
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
    ) RETURN BOOLEAN IS
        l_profile           profile_template.id_profile_template%TYPE;
        l_profile_adm_cs    profile_template.id_profile_template%TYPE;
        l_profile_adm_cs_vo profile_template.id_profile_template%TYPE;
        l_profile_adm_hs    profile_template.id_profile_template%TYPE;
        l_profile_adm_hs_vo profile_template.id_profile_template%TYPE;
        l_profile_med_hs    profile_template.id_profile_template%TYPE;
        l_profile_adm_cs_cl profile_template.id_profile_template%TYPE;
        l_profile_adm_hs_cl profile_template.id_profile_template%TYPE;
        l_profile_med_hs_cl profile_template.id_profile_template%TYPE;
        l_profile_aux       profile_template.id_profile_template%TYPE;
        l_cat_med           category.flg_type%TYPE := NULL;
    
        l_wf_ref_med sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'REFERRAL_WF_MED', i_prof => i_prof);
    
        l_flg_status p1_external_request.flg_status%TYPE;
    
    BEGIN
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ext_req, i_dt_system_date => current_timestamp);
    
        BEGIN
            SELECT flg_status
              INTO l_flg_status
              FROM p1_external_request a
             WHERE a.id_external_request = i_id_ext_req;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
    
        IF i_workflow IS NULL
        THEN
        
            ----------------------
            -- CONFIG
            ----------------------        
            g_error          := 'Profiles / ID_WF=' || i_workflow || ' ID_REF=' || i_id_ext_req;
            l_profile_adm_cs := pk_ref_constant.g_profile_adm_cs;
            l_profile_adm_hs := pk_ref_constant.g_profile_adm_hs;
            l_profile_med_hs := pk_ref_constant.g_profile_med_hs;
        
            l_profile_adm_cs_cl := pk_ref_constant.g_profile_adm_cs_cl;
            l_profile_adm_hs_cl := pk_ref_constant.g_profile_adm_hs_cl;
            l_profile_med_hs_cl := pk_ref_constant.g_profile_med_hs_cl;
        
            -- view only
            l_profile_adm_hs_vo := pk_ref_constant.g_profile_adm_hs_vo;
            l_profile_adm_cs_vo := pk_ref_constant.g_profile_adm_cs_vo;
            ----------------------
            -- FUNC
            ----------------------
        
            g_error   := 'Calling pk_tools.get_prof_profile_template / ID_WF=' || i_workflow || ' ID_REF=' ||
                         i_id_ext_req;
            l_profile := pk_tools.get_prof_profile_template(i_prof);
        
            -- Para o comportamento no Chile ser igual ao Pt
            IF l_profile = l_profile_adm_cs
               OR l_profile = l_profile_adm_cs_cl
            THEN
                l_profile_aux := l_profile_adm_cs;
            
            ELSIF l_profile = l_profile_adm_hs
                  OR l_profile = l_profile_adm_hs_cl
            THEN
                l_profile_aux := l_profile_adm_hs;
            ELSIF l_profile = l_profile_med_hs
                  OR l_profile = l_profile_med_hs_cl
            THEN
                l_profile_aux := l_profile_med_hs;
            ELSE
                l_profile_aux := l_profile;
                l_cat_med     := pk_tools.get_prof_cat(i_prof => i_prof);
            END IF;
        
            g_error := 'CASE ' || l_profile || ' / ID_WF=' || i_workflow || ' ID_REF=' || i_id_ext_req;
            CASE
                WHEN l_profile_aux = l_profile_adm_cs THEN
                
                    g_error  := 'Calling pk_p1_adm_cs.get_status_options / ID_WF=' || i_workflow || ' ID_REF=' ||
                                i_id_ext_req;
                    g_retval := pk_p1_adm_cs.get_status_options(i_lang        => i_lang,
                                                                i_prof        => i_prof,
                                                                i_id_ext_req  => i_id_ext_req,
                                                                i_dt_modified => i_dt_modified,
                                                                o_status      => o_status,
                                                                o_flg_show    => o_flg_show,
                                                                o_msg_title   => o_msg_title,
                                                                o_msg         => o_msg,
                                                                o_button      => o_button,
                                                                o_error       => o_error);
                
                WHEN l_profile_aux = l_profile_adm_hs
                     OR (l_profile_aux = l_profile_med_hs AND l_wf_ref_med = pk_alert_constant.g_yes AND
                     l_flg_status = 'A') THEN
                
                    g_error  := 'Calling pk_p1_adm_hs.get_status_options / ID_WF=' || i_workflow || ' ID_REF=' ||
                                i_id_ext_req;
                    g_retval := pk_p1_adm_hs.get_status_options(i_lang        => i_lang,
                                                                i_prof        => i_prof,
                                                                i_id_ext_req  => i_id_ext_req,
                                                                i_dt_modified => i_dt_modified,
                                                                o_status      => o_status,
                                                                o_flg_show    => o_flg_show,
                                                                o_msg_title   => o_msg_title,
                                                                o_msg         => o_msg,
                                                                o_button      => o_button,
                                                                o_error       => o_error);
                WHEN l_profile_aux = l_profile_med_hs
                     OR l_cat_med = pk_ref_constant.g_doctor THEN
                
                    g_error  := 'Calling pk_p1_med_hs.get_status_options / ID_WF=' || i_workflow || ' ID_REF=' ||
                                i_id_ext_req;
                    g_retval := pk_p1_med_hs.get_status_options(i_lang        => i_lang,
                                                                i_prof        => i_prof,
                                                                i_ext_req     => i_id_ext_req,
                                                                i_dt_modified => i_dt_modified,
                                                                o_status      => o_status,
                                                                o_flg_show    => o_flg_show,
                                                                o_msg_title   => o_msg_title,
                                                                o_msg         => o_msg,
                                                                o_button      => o_button,
                                                                o_error       => o_error);
                
                WHEN l_profile_aux IN (l_profile_adm_hs_vo, l_profile_adm_cs_vo) THEN
                    pk_types.open_my_cursor(o_status);
                ELSE
                    g_error := 'CASE NOT FOUND ' || l_profile_aux || ' / ID_WF=' || i_workflow || ' ID_REF=' ||
                               i_id_ext_req;
                    RAISE g_exception_np;
            END CASE;
        
        ELSE
        
            g_error  := 'Call pk_ref_list.get_status_options / ID_WF=' || i_workflow || ' ID_REF=' || i_id_ext_req;
            g_retval := pk_ref_list.get_status_options(i_lang        => i_lang,
                                                       i_prof        => i_prof,
                                                       i_id_ext_req  => i_id_ext_req,
                                                       i_dt_modified => i_dt_modified,
                                                       o_status      => o_status,
                                                       o_flg_show    => o_flg_show,
                                                       o_msg_title   => o_msg_title,
                                                       o_msg         => o_msg,
                                                       o_button      => o_button,
                                                       o_error       => o_error);
        
        END IF;
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_status);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_STATUS_OPTIONS',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_status);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_status_options;

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
        i_action       IN VARCHAR2, -- to be removed when using workflow framework for all workflows
        o_flg_show     OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_msg          OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_profile        profile_template.id_profile_template%TYPE;
        l_profile_med_cs profile_template.id_profile_template%TYPE;
        l_profile_adm_cs profile_template.id_profile_template%TYPE;
        l_profile_adm_hs profile_template.id_profile_template%TYPE;
        l_profile_med_hs profile_template.id_profile_template%TYPE;
    
        l_profile_med_cs_cl profile_template.id_profile_template%TYPE;
        l_profile_adm_cs_cl profile_template.id_profile_template%TYPE;
        l_profile_adm_hs_cl profile_template.id_profile_template%TYPE;
        l_profile_med_hs_cl profile_template.id_profile_template%TYPE;
        l_profile_aux       profile_template.id_profile_template%TYPE;
    
        l_transaction_id VARCHAR2(4000);
        l_track_tab      table_number;
    BEGIN
        g_error := 'Init set_status / ID_REF=' || i_ext_req || ' i_status_begin=' || i_status_begin || ' i_status_end=' ||
                   i_status_end || ' i_level=' || i_level || ' i_prof_dest=' || i_prof_dest || ' i_dcs=' || i_dcs ||
                   ' i_dt_modified=' || i_dt_modified || ' i_mode=' || i_mode || ' i_reason_code=' || i_reason_code ||
                   ' i_subtype=' || i_subtype || ' i_inst_dest=' || i_inst_dest || ' i_action=' || i_action;
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_ext_req, i_dt_system_date => current_timestamp);
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_ext_req, i_dt_system_date => current_timestamp);
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(l_transaction_id, i_prof);
    
        IF i_workflow IS NULL
        THEN
        
            ----------------------
            -- CONFIG
            ----------------------        
            g_error          := 'pk_sysconfig.get_config / ID_REF=' || i_ext_req || ' i_status_begin=' ||
                                i_status_begin || ' i_status_end=' || i_status_end || ' i_level=' || i_level ||
                                ' i_prof_dest=' || i_prof_dest || ' i_dcs=' || i_dcs || ' i_dt_modified=' ||
                                i_dt_modified || ' i_mode=' || i_mode || ' i_reason_code=' || i_reason_code ||
                                ' i_subtype=' || i_subtype || ' i_inst_dest=' || i_inst_dest || ' i_action=' ||
                                i_action;
            l_profile_med_cs := pk_ref_constant.g_profile_med_cs; --to_number(pk_sysconfig.get_config(pk_ref_constant.g_sc_profile_med_cs, i_prof));
            l_profile_adm_cs := pk_ref_constant.g_profile_adm_cs; --to_number(pk_sysconfig.get_config(pk_ref_constant.g_sc_profile_adm_cs, i_prof));
            l_profile_adm_hs := pk_ref_constant.g_profile_adm_hs; --to_number(pk_sysconfig.get_config(pk_ref_constant.g_sc_profile_adm_hs, i_prof));
            l_profile_med_hs := pk_ref_constant.g_profile_med_hs; --to_number(pk_sysconfig.get_config(pk_ref_constant.g_sc_profile_med_hs, i_prof));
        
            l_profile_med_cs_cl := pk_ref_constant.g_profile_med_cs_cl; --to_number(pk_sysconfig.get_config(pk_ref_constant.g_sc_profile_med_cs_cl, i_prof));
            l_profile_adm_cs_cl := pk_ref_constant.g_profile_adm_cs_cl; --to_number(pk_sysconfig.get_config(pk_ref_constant.g_sc_profile_adm_cs_cl, i_prof));
            l_profile_adm_hs_cl := pk_ref_constant.g_profile_adm_hs_cl; --to_number(pk_sysconfig.get_config(pk_ref_constant.g_sc_profile_adm_hs_cl, i_prof));
            l_profile_med_hs_cl := pk_ref_constant.g_profile_med_hs_cl; --to_number(pk_sysconfig.get_config(pk_ref_constant.g_sc_profile_med_hs_cl, i_prof));
        
            ----------------------
            -- FUNC
            ---------------------- 
        
            g_error   := 'Calling pk_tools.get_prof_profile_template / ID_REF=' || i_ext_req || ' i_status_begin=' ||
                         i_status_begin || ' i_status_end=' || i_status_end || ' i_level=' || i_level ||
                         ' i_prof_dest=' || i_prof_dest || ' i_dcs=' || i_dcs || ' i_dt_modified=' || i_dt_modified ||
                         ' i_mode=' || i_mode || ' i_reason_code=' || i_reason_code || ' i_subtype=' || i_subtype ||
                         ' i_inst_dest=' || i_inst_dest || ' i_action=' || i_action;
            l_profile := pk_tools.get_prof_profile_template(i_prof);
        
            IF l_profile = l_profile_adm_cs
               OR l_profile = l_profile_adm_cs_cl
            THEN
                l_profile_aux := l_profile_adm_cs;
            
            ELSIF l_profile = l_profile_adm_hs
                  OR l_profile = l_profile_adm_hs_cl
            THEN
                l_profile_aux := l_profile_adm_hs;
            ELSIF l_profile = l_profile_med_hs
                  OR l_profile = l_profile_med_hs_cl
            THEN
                l_profile_aux := l_profile_med_hs;
            ELSIF l_profile = l_profile_med_cs
                  OR l_profile = l_profile_med_cs_cl
            THEN
                l_profile_aux := l_profile_med_cs;
            ELSE
                l_profile_aux := l_profile;
            END IF;
        
            g_error := 'CASE ' || l_profile || ' / ID_REF=' || i_ext_req || ' i_status_begin=' || i_status_begin ||
                       ' i_status_end=' || i_status_end || ' i_level=' || i_level || ' i_prof_dest=' || i_prof_dest ||
                       ' i_dcs=' || i_dcs || ' i_dt_modified=' || i_dt_modified || ' i_mode=' || i_mode ||
                       ' i_reason_code=' || i_reason_code || ' i_subtype=' || i_subtype || ' i_inst_dest=' ||
                       i_inst_dest || ' i_action=' || i_action;
            CASE l_profile_aux
                WHEN l_profile_adm_cs THEN
                
                    g_error  := 'Calling pk_p1_adm_cs.set_status_internal / ID_REF=' || i_ext_req || ' i_status=' ||
                                i_action;
                    g_retval := pk_p1_adm_cs.set_status_internal(i_lang        => i_lang,
                                                                 i_prof        => i_prof,
                                                                 i_id_p1       => i_ext_req,
                                                                 i_status      => i_action,
                                                                 i_reason_code => i_reason_code,
                                                                 i_notes       => i_notes,
                                                                 o_track       => l_track_tab,
                                                                 o_error       => o_error);
                
                WHEN l_profile_adm_hs THEN
                
                    g_error  := 'Calling pk_p1_adm_hs.set_status_internal / ID_REF=' || i_ext_req || ' i_status=' ||
                                i_action || ' i_reason_code=' || i_reason_code || ' i_dcs=' || i_dcs;
                    g_retval := pk_p1_adm_hs.set_status_internal(i_lang           => i_lang,
                                                                 i_prof           => i_prof,
                                                                 i_ext_req        => i_ext_req,
                                                                 i_status         => i_action,
                                                                 i_notes          => i_notes,
                                                                 i_reason_code    => i_reason_code,
                                                                 i_dcs            => i_dcs,
                                                                 i_date           => NULL,
                                                                 i_transaction_id => l_transaction_id,
                                                                 o_track          => l_track_tab,
                                                                 o_error          => o_error);
                WHEN l_profile_med_hs THEN
                
                    g_error  := 'Calling pk_p1_med_hs.set_status_internal / ID_REF=' || i_ext_req || ' i_status=' ||
                                i_action || ' i_reason_code=' || i_reason_code || ' i_dcs=' || i_dcs || ' i_level=' ||
                                i_level || ' i_prof_dest=' || i_prof_dest || ' i_mode=' || i_mode || ' i_subtype=' ||
                                i_subtype || ' i_inst_dest=' || i_inst_dest;
                    g_retval := pk_p1_med_hs.set_status_internal(i_lang          => i_lang,
                                                                 i_prof          => i_prof,
                                                                 i_id_p1         => i_ext_req,
                                                                 i_action        => i_action,
                                                                 i_level         => i_level,
                                                                 i_prof_dest     => i_prof_dest,
                                                                 i_dep_clin_serv => i_dcs,
                                                                 i_notes         => i_notes,
                                                                 i_dt_modified   => i_dt_modified,
                                                                 i_mode          => i_mode,
                                                                 i_reason_code   => i_reason_code,
                                                                 i_subtype       => i_subtype,
                                                                 i_inst_dest     => i_inst_dest,
                                                                 i_date          => NULL,
                                                                 o_track         => l_track_tab,
                                                                 o_flg_show      => o_flg_show,
                                                                 o_msg_title     => o_msg_title,
                                                                 o_msg           => o_msg,
                                                                 o_error         => o_error);
                
                WHEN l_profile_med_cs THEN
                    -- only used to cancel referral, accept/decline cancellation request from actions button
                    g_error  := 'Call pk_p1_med_cs.set_status / ID_REF=' || i_ext_req || ' i_dt_modified=' ||
                                i_dt_modified || ' i_mode=' || i_mode || ' i_reason_code=' || i_reason_code ||
                                ' i_action=' || i_action;
                    g_retval := pk_p1_med_cs.set_status(i_lang        => i_lang,
                                                        i_prof        => i_prof,
                                                        i_id_ref      => i_ext_req,
                                                        i_action      => i_action,
                                                        i_reason_code => i_reason_code,
                                                        i_notes       => i_notes,
                                                        i_op_date     => NULL,
                                                        i_dt_modified => i_dt_modified,
                                                        i_mode        => i_mode,
                                                        o_flg_show    => o_flg_show,
                                                        o_msg_title   => o_msg_title,
                                                        o_msg         => o_msg,
                                                        o_error       => o_error);
                
                ELSE
                    g_error := 'CASE NOT FOUND ' || l_profile_aux || ' / ID_REF=' || i_ext_req || ' i_status_begin=' ||
                               i_status_begin || ' i_status_end=' || i_status_end || ' i_level=' || i_level ||
                               ' i_prof_dest=' || i_prof_dest || ' i_dcs=' || i_dcs || ' i_dt_modified=' ||
                               i_dt_modified || ' i_mode=' || i_mode || ' i_reason_code=' || i_reason_code ||
                               ' i_subtype=' || i_subtype || ' i_inst_dest=' || i_inst_dest || ' i_action=' || i_action;
                    RAISE g_exception;
            END CASE;
        
        ELSE
        
            g_error  := 'Calling pk_ref_core.set_status2 / ID_REF=' || i_ext_req || ' i_status_begin=' ||
                        i_status_begin || ' i_status_end=' || i_status_end || ' i_level=' || i_level || ' i_prof_dest=' ||
                        i_prof_dest || ' i_dcs=' || i_dcs || ' i_dt_modified=' || i_dt_modified || ' i_mode=' || i_mode ||
                        ' i_reason_code=' || i_reason_code || ' i_subtype=' || i_subtype || ' i_inst_dest=' ||
                        i_inst_dest;
            g_retval := pk_ref_core.set_status2(i_lang           => i_lang,
                                                i_prof           => i_prof,
                                                i_ext_req        => i_ext_req,
                                                i_status_begin   => i_status_begin,
                                                i_status_end     => i_status_end,
                                                i_action         => i_action,
                                                i_level          => i_level,
                                                i_prof_dest      => i_prof_dest,
                                                i_dcs            => i_dcs,
                                                i_notes          => i_notes,
                                                i_dt_modified    => i_dt_modified,
                                                i_mode           => i_mode,
                                                i_reason_code    => i_reason_code,
                                                i_subtype        => i_subtype,
                                                i_inst_dest      => i_inst_dest,
                                                i_transaction_id => l_transaction_id,
                                                o_track          => l_track_tab,
                                                o_flg_show       => o_flg_show,
                                                o_msg_title      => o_msg_title,
                                                o_msg            => o_msg,
                                                o_error          => o_error);
        END IF;
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        COMMIT;
        -- warns the new scheduler that it should commit the transaction        
        pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_STATUS',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_status;

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
    * @author  Joao Sa
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
    ) RETURN BOOLEAN IS
        l_type p1_reason_code.flg_type%TYPE;
    BEGIN
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error := 'i_type=' || i_type;
        CASE i_type
            WHEN pk_ref_constant.g_ref_action_d THEN
                l_type := pk_ref_constant.g_reason_code_d;
            WHEN pk_ref_constant.g_ref_action_x THEN
                l_type := pk_ref_constant.g_reason_code_x;
            WHEN pk_ref_constant.g_ref_action_dcl_r THEN
                l_type := pk_ref_constant.g_reason_code_i;
            WHEN pk_ref_constant.g_ref_action_y THEN
                l_type := pk_ref_constant.g_reason_code_y;
            ELSE
                l_type := i_type;
        END CASE;
    
        g_error  := 'Calling pk_ref_list.get_reason_list / TYPE=' || i_type;
        g_retval := pk_ref_list.get_reason_list(i_lang    => i_lang,
                                                i_prof    => i_prof,
                                                i_type    => l_type,
                                                i_mcdt    => pk_ref_constant.g_no,
                                                o_reasons => o_reasons,
                                                o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_reasons);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REASON_LIST',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_reasons);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_reason_list;

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
    ) RETURN BOOLEAN IS
        l_type p1_reason_code.flg_type%TYPE;
    BEGIN
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error := 'i_type=' || i_type;
        CASE i_type
            WHEN 'DECLINE' THEN
                l_type := pk_ref_constant.g_p1_status_d;
            WHEN 'REFUSE' THEN
                l_type := 'X';
            ELSE
                l_type := i_type;
        END CASE;
    
        g_error  := 'Calling pk_ref_list.get_reason_list / i_type=' || i_type;
        g_retval := pk_ref_list.get_reason_list(i_lang    => i_lang,
                                                i_prof    => i_prof,
                                                i_type    => l_type,
                                                i_mcdt    => pk_ref_constant.g_yes,
                                                o_reasons => o_reasons,
                                                o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_reasons);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REASON_LIST',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_reasons);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_mcdt_reason_list;

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
    ) RETURN BOOLEAN IS
    BEGIN
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_ext_req, i_dt_system_date => current_timestamp);
    
        g_error  := 'Calling pk_ref_core.get_clin_serv_forward_count / ID_REF=' || i_ext_req;
        g_retval := pk_ref_core.get_clin_serv_forward_count(i_lang    => i_lang,
                                                            i_prof    => i_prof,
                                                            i_ext_req => i_ext_req,
                                                            o_count   => o_count,
                                                            o_id      => o_id,
                                                            o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_CLIN_SERV_FORWARD_COUNT',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_clin_serv_forward_count;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_ext_req, i_dt_system_date => current_timestamp);
    
        IF i_workflow IS NULL
        THEN
        
            g_error  := 'Calling pk_p1_adm_cs.get_tasks_done / REF=' || i_ext_req;
            g_retval := pk_p1_adm_cs.get_tasks_done(i_lang     => i_lang,
                                                    i_prof     => i_prof,
                                                    i_ext_req  => i_ext_req,
                                                    o_tasks    => o_tasks,
                                                    o_info     => o_info,
                                                    o_notes    => o_notes,
                                                    o_editable => o_editable,
                                                    o_error    => o_error);
        
        ELSE
        
            g_error  := 'Calling pk_ref_orig_reg.get_tasks_done / REF=' || i_ext_req;
            g_retval := pk_ref_orig_reg.get_tasks_done(i_lang     => i_lang,
                                                       i_prof     => i_prof,
                                                       i_ext_req  => i_ext_req,
                                                       o_tasks    => o_tasks,
                                                       o_info     => o_info,
                                                       o_notes    => o_notes,
                                                       o_editable => o_editable,
                                                       o_error    => o_error);
        END IF;
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_notes);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_TASKS_DONE',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_notes);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_tasks_done;

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
    ) RETURN BOOLEAN IS
        l_track_tab table_number;
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_ext_req, i_dt_system_date => current_timestamp);
    
        IF i_workflow IS NULL
        THEN
        
            g_error  := 'Calling pk_p1_adm_cs.update_tasks_done / ID_WF=' || i_workflow || ' ID_REF=' || i_ext_req;
            g_retval := pk_p1_adm_cs.update_tasks_done_internal(i_lang                => i_lang,
                                                                i_prof                => i_prof,
                                                                i_id_external_request => i_ext_req,
                                                                i_id_tasks            => i_id_tasks,
                                                                i_flg_status_ini      => i_flg_status_ini,
                                                                i_flg_status_fin      => i_flg_status_fin,
                                                                i_notes               => i_notes,
                                                                o_error               => o_error);
        
        ELSE
        
            g_error  := 'Calling pk_ref_orig_reg.update_tasks_done / ID_WF=' || i_workflow || ' ID_REF=' || i_ext_req;
            g_retval := pk_ref_orig_reg.update_tasks_done(i_lang           => i_lang,
                                                          i_prof           => i_prof,
                                                          i_ext_req        => i_ext_req,
                                                          i_id_tasks       => i_id_tasks,
                                                          i_flg_status_ini => i_flg_status_ini,
                                                          i_flg_status_fin => i_flg_status_fin,
                                                          i_notes          => i_notes,
                                                          o_track          => l_track_tab,
                                                          o_error          => o_error);
        END IF;
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'UPDATE_TASKS_DONE',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END update_tasks_done;

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
    ) RETURN BOOLEAN IS
        l_id_match p1_match.id_match%TYPE;
    BEGIN
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Calling pk_ref_dest_reg.set_match / ID_PATIENT=' || i_pat || ' SEQ_NUMBER=' || i_seq_num ||
                    ' CLIN_RECORD=' || i_clin_rec || ' ID_EPISODE=' || i_epis;
        g_retval := pk_ref_dest_reg.set_match(i_lang     => i_lang,
                                              i_prof     => i_prof,
                                              i_pat      => i_pat,
                                              i_seq_num  => i_seq_num,
                                              i_clin_rec => i_clin_rec,
                                              i_epis     => i_epis,
                                              o_id_match => l_id_match,
                                              o_error    => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_MATCH',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_match;

    /**
    * Gets clinical_services (the ids are dep_clin_serv) available for forwarding the request by the registrar 
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
    ) RETURN BOOLEAN IS
    BEGIN
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_ext_req, i_dt_system_date => current_timestamp);
    
        g_error  := 'Calling pk_ref_dest_reg.get_clin_serv_forward_list / ID_REF=' || i_ext_req || ' i_dep=' || i_dep;
        g_retval := pk_ref_dest_reg.get_clin_serv_forward_list(i_lang      => i_lang,
                                                               i_prof      => i_prof,
                                                               i_ext_req   => i_ext_req,
                                                               i_dep       => i_dep,
                                                               o_clin_serv => o_clin_serv,
                                                               o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_clin_serv);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_CLIN_SERV_FWD_LIST',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_clin_serv);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_clin_serv_fwd_list;

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
    ) RETURN BOOLEAN IS
    BEGIN
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_ext_req, i_dt_system_date => current_timestamp);
    
        g_error  := 'Calling pk_ref_dest_reg.get_dep_forward_list / ID_REF=' || i_ext_req;
        g_retval := pk_ref_dest_reg.get_dep_forward_list(i_lang    => i_lang,
                                                         i_prof    => i_prof,
                                                         i_ext_req => i_ext_req,
                                                         o_dep     => o_dep,
                                                         o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_dep);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_DEP_FWD_LIST',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_dep);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_dep_fwd_list;

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
    ) RETURN BOOLEAN IS
    BEGIN
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_ext_req, i_dt_system_date => current_timestamp);
    
        g_error  := 'Calling pk_ref_dest_phy.get_prof_triage_list / ID_REF=' || i_ext_req;
        g_retval := pk_ref_dest_phy.get_prof_triage_list(i_lang    => i_lang,
                                                         i_prof    => i_prof,
                                                         i_ext_req => i_ext_req,
                                                         o_prof    => o_prof,
                                                         o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_prof);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PROF_TRIAGE_LIST',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_prof);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_prof_triage_list;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Calling pk_ref_dest_phy.get_triage_level_list / ID_DEP_CLIN_SERV=' || i_dep_clin_serv ||
                    ' ID_EXTERNAL_SYS=' || i_external_sys;
        g_retval := pk_ref_dest_phy.get_triage_level_list(i_lang          => i_lang,
                                                          i_prof          => i_prof,
                                                          i_dep_clin_serv => i_dep_clin_serv,
                                                          i_external_sys  => i_external_sys,
                                                          o_levels        => o_levels,
                                                          o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_levels);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_TRIAGE_LEVEL_LIST',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_levels);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_triage_level_list;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Calling pk_ref_dest_phy.get_dep_forward_list / i_external_sys=' || i_external_sys ||
                    ' i_pat_gender=' || i_pat_gender || ' i_pat_age=' || i_pat_age || ' i_id_inst=' || i_id_inst ||
                    ' i_dcs_except=' || i_dcs_except;
        g_retval := pk_ref_dest_phy.get_dep_forward_list(i_lang         => i_lang,
                                                         i_prof         => i_prof,
                                                         i_external_sys => i_external_sys,
                                                         i_pat_gender   => i_pat_gender,
                                                         i_pat_age      => i_pat_age,
                                                         i_id_inst      => i_id_inst,
                                                         i_dcs_except   => i_dcs_except,
                                                         o_dep          => o_dep,
                                                         o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_dep);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_DEP_FORWARD_LIST',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_dep);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_dep_forward_list;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Calling pk_ref_dest_phy.get_dep_schedule_list / i_external_sys=' || i_external_sys ||
                    ' i_pat_gender=' || i_pat_gender || ' i_pat_age=' || i_pat_age;
        g_retval := pk_ref_dest_phy.get_dep_schedule_list(i_lang         => i_lang,
                                                          i_prof         => i_prof,
                                                          i_external_sys => i_external_sys,
                                                          i_pat_gender   => i_pat_gender,
                                                          i_pat_age      => i_pat_age,
                                                          o_dep          => o_dep,
                                                          o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_dep);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_DEP_SCHEDULE_LIST',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_dep);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_dep_schedule_list;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Calling pk_ref_dest_phy.get_clin_serv_forward_list / i_id_inst=' || i_id_inst || ' i_dep=' ||
                    i_dep || ' i_external_sys=' || i_external_sys || ' i_pat_gender=' || i_pat_gender || ' i_pat_age=' ||
                    i_pat_age || ' i_dcs_except=' || i_dcs_except;
        g_retval := pk_ref_dest_phy.get_clin_serv_forward_list(i_lang         => i_lang,
                                                               i_prof         => i_prof,
                                                               i_dep          => i_dep,
                                                               i_external_sys => i_external_sys,
                                                               i_pat_gender   => i_pat_gender,
                                                               i_pat_age      => i_pat_age,
                                                               i_id_inst      => i_id_inst,
                                                               i_dcs_except   => i_dcs_except,
                                                               o_cs           => o_cs,
                                                               o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_cs);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_CLIN_SERV_FORWARD_LIST',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_cs);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_clin_serv_forward_list;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Calling pk_ref_dest_phy.get_prof_schedule_list / ID_DEP_CLIN_SERV=' || i_dep_clin_serv ||
                    ' ID_EXTERNAL_SYS=' || i_external_sys;
        g_retval := pk_ref_dest_phy.get_prof_schedule_list(i_lang          => i_lang,
                                                           i_prof          => i_prof,
                                                           i_dep_clin_serv => i_dep_clin_serv,
                                                           i_external_sys  => i_external_sys,
                                                           o_prof          => o_prof,
                                                           o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_prof);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PROF_SCHEDULE_LIST',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_prof);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_prof_schedule_list;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_ext_req, i_dt_system_date => current_timestamp);
    
        g_error  := 'Calling pk_ref_dest_phy.get_inst_forward_list / ID_REF=' || i_ext_req;
        g_retval := pk_ref_dest_phy.get_inst_forward_list(i_lang    => i_lang,
                                                          i_prof    => i_prof,
                                                          i_ext_req => i_ext_req,
                                                          o_inst    => o_inst,
                                                          o_error   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_inst);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_INST_FORWARD_LIST',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_inst);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_inst_forward_list;

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
    ) RETURN BOOLEAN IS
        l_track_tab table_number;
    BEGIN
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_exr, i_dt_system_date => current_timestamp);
    
        IF i_workflow IS NULL
        THEN
            g_error  := 'Calling pk_p1_med_hs.set_request_answer_int / ID_WF=' || i_workflow || ' ID_REF=' || i_exr;
            g_retval := pk_p1_med_hs.set_request_answer_int(i_lang             => i_lang,
                                                            i_prof             => i_prof,
                                                            i_exr              => i_exr,
                                                            i_diagnosis        => i_diagnosis,
                                                            i_diag_desc        => i_diag_desc,
                                                            i_answer           => i_answer,
                                                            i_health_prob      => i_health_prob,
                                                            i_health_prob_desc => i_health_prob_desc,
                                                            o_error            => o_error);
        
        ELSE
        
            g_error  := 'Calling pk_ref_dest_phy.set_ref_answer / ID_WF=' || i_workflow || ' ID_REF=' || i_exr;
            g_retval := pk_ref_dest_phy.set_ref_answer(i_lang             => i_lang,
                                                       i_prof             => i_prof,
                                                       i_exr              => i_exr,
                                                       i_diagnosis        => i_diagnosis,
                                                       i_diag_desc        => i_diag_desc,
                                                       i_answer           => i_answer,
                                                       i_health_prob      => i_health_prob,
                                                       i_health_prob_desc => i_health_prob_desc,
                                                       o_track            => l_track_tab,
                                                       o_error            => o_error);
        
        END IF;
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_REF_ANSWER',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_ref_answer;

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
    ) RETURN BOOLEAN IS
    BEGIN
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Calling pk_ref_list.get_referral_type';
        g_retval := pk_ref_list.get_referral_type(i_lang     => i_lang,
                                                  i_prof     => i_prof,
                                                  o_type_ext => o_type_ext,
                                                  o_type_int => o_type_int,
                                                  o_error    => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_type_ext);
            pk_types.open_my_cursor(o_type_int);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REFERRAL_TYPE',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_type_ext);
            pk_types.open_my_cursor(o_type_int);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_referral_ie;

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
    ) RETURN BOOLEAN IS
    
        l_codification table_number := table_number();
    
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        IF i_codification.count() > 0
        THEN
            FOR i IN i_codification.first .. i_codification.last
            LOOP
                l_codification.extend();
                l_codification(l_codification.count) := CASE i_codification(i)
                                                            WHEN -1 THEN
                                                             NULL
                                                            ELSE
                                                             i_codification(i)
                                                        END;
            END LOOP;
        END IF;
    
        g_error  := 'Calling pk_ref_ext_sys.get_completion_options / ID_PAT=' || i_patient || '|FLG_TYPE=' ||
                    i_flg_type;
        g_retval := pk_ref_ext_sys.get_completion_options(i_lang           => i_lang,
                                                          i_prof           => i_prof,
                                                          i_patient        => i_patient,
                                                          i_epis           => i_epis,
                                                          i_codification   => l_codification,
                                                          i_inst_dest      => i_inst_dest,
                                                          i_flg_type       => i_flg_type,
                                                          i_spec           => i_spec,
                                                          o_options        => o_options,
                                                          o_print_options  => o_print_options,
                                                          o_flg_show_popup => o_flg_show_popup,
                                                          o_error          => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_options);
            pk_types.open_my_cursor(o_print_options);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_COMPLETION_OPTIONS',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_options);
            pk_types.open_my_cursor(o_print_options);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_completion_options;

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
    /*FUNCTION check_completion_option
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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Calling pk_ref_ext_sys.check_completion_option / ID_PAT=' || i_patient || '|FLG_TYPE=' ||
                    i_flg_type;
        g_retval := pk_ref_ext_sys.check_completion_option(i_lang          => i_lang,
                                                           i_prof          => i_prof,
                                                           i_patient       => i_patient,
                                                           i_epis          => i_epis,
                                                           i_codification  => i_codification,
                                                           i_inst_dest     => i_inst_dest,
                                                           i_flg_type      => i_flg_type,
                                                           i_option        => i_option,
                                                           i_spec          => i_spec,
                                                           o_flg_available => o_flg_available,
                                                           o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_COMPLETION_OPTION',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END check_completion_option;*/

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Calling pk_ref_ext_sys.check_completion_option / ID_PAT=' || i_patient || '|FLG_TYPE=' ||
                    i_flg_type;
        g_retval := pk_ref_ext_sys.check_completion_option(i_lang          => i_lang,
                                                           i_prof          => i_prof,
                                                           i_patient       => i_patient,
                                                           i_epis          => NULL,
                                                           i_codification  => i_codification,
                                                           i_inst_dest     => i_inst_dest,
                                                           i_flg_type      => i_flg_type,
                                                           i_option        => i_option,
                                                           i_spec          => i_spec,
                                                           o_flg_available => o_flg_available,
                                                           o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_COMPLETION_OPTION',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END check_completion_option;
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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Calling pk_p1_analysis.check_ref_completed / i_analysis_req_det.COUNT=' ||
                    i_analysis_req_det.count;
        g_retval := pk_p1_analysis.check_ref_completed(i_lang             => i_lang,
                                                       i_prof             => i_prof,
                                                       i_analysis_req_det => i_analysis_req_det,
                                                       o_flg_completed    => o_flg_completed,
                                                       o_error            => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_REF_COMPLETED',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END check_ref_completed;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Calling pk_p1_analysis.get_ref_analysis_req_det / i_analysis_req_det.COUNT=' ||
                    i_analysis_req_det.count;
        g_retval := pk_p1_analysis.get_ref_analysis_req_det(i_lang             => i_lang,
                                                            i_prof             => i_prof,
                                                            i_analysis_req_det => i_analysis_req_det,
                                                            o_sql              => o_sql,
                                                            o_error            => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_types.open_my_cursor(o_sql);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REF_ANALYSIS_REQ_DET',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_sql);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_ref_analysis_req_det;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Calling pk_mcdt.get_codification_list / i_type=' || i_type;
        g_retval := pk_mcdt.get_codification_list(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_mcdt_type => i_type,
                                                  i_flg_type  => NULL,
                                                  i_flg_p1    => pk_alert_constant.g_yes,
                                                  o_list      => o_list,
                                                  o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_CODIFICATION_LIST',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_codification_list;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'pk_p1_utils.get_codification / i_ref_type=' || i_ref_type;
        g_retval := pk_p1_utils.get_codification(i_lang              => i_lang,
                                                 i_prof              => i_prof,
                                                 i_ref_type          => i_ref_type,
                                                 i_mcdt_codification => i_mcdt_codification,
                                                 o_codification      => o_codification,
                                                 o_error             => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SRV_GET_CODIFICATION',
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
    END srv_get_codification;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Calling PK_REF_EXT_SYS.GET_PAT_REF_TO_SCHEDULE / ID_PAT=' || i_id_patient || ' ID_SCHEDULE=' ||
                    i_schedule;
        g_retval := pk_ref_ext_sys.get_pat_ref_to_schedule(i_lang     => i_lang,
                                                           i_prof     => i_prof,
                                                           i_patient  => i_id_patient,
                                                           i_type     => i_type,
                                                           i_schedule => i_schedule,
                                                           o_p1       => o_p1,
                                                           o_message  => o_message,
                                                           o_title    => o_title,
                                                           o_buttons  => o_buttons,
                                                           o_error    => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_p1);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PAT_REF_TO_SCHEDULE',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_p1);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_pat_ref_to_schedule;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_ref, i_dt_system_date => current_timestamp);
    
        g_error  := 'Calling PK_API_REF_CIRCLE.get_linked_episodes / ID_REF=' || i_ref;
        g_retval := pk_api_ref_circle.get_linked_episodes(i_lang        => i_lang,
                                                          i_prof        => i_prof,
                                                          i_id_ref      => i_ref,
                                                          o_linked_epis => o_liked_epis,
                                                          o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_liked_epis);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_LINKED_EPISODES',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_liked_epis);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_linked_episodes;

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
    ) RETURN BOOLEAN IS
        l_workflow wf_workflow.id_workflow%TYPE;
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_ext_req, i_dt_system_date => current_timestamp);
    
        g_error  := 'Call pk_p1_external_request.get_id_workflow / ID_REF=' || i_ext_req;
        g_retval := pk_p1_external_request.get_id_workflow(i_lang        => i_lang,
                                                           i_prof        => i_prof,
                                                           i_id_ref      => i_ext_req,
                                                           o_id_workflow => l_workflow,
                                                           o_error       => o_error);
    
        IF l_workflow IS NULL
        THEN
            g_error  := 'Call pk_p1_ext_sys.update_referral_status / ID_REF=' || i_ext_req || ' ID_WF=' || l_workflow ||
                        ' ID_SCHEDULE=' || i_schedule || ' STATUS=' || i_status || ' ID_EPISODE=' || i_episode ||
                        ' FLG_RESCHEDULE=' || i_reschedule;
            g_retval := pk_p1_ext_sys.update_referral_status(i_lang           => i_lang,
                                                             i_prof           => i_prof,
                                                             i_ext_req        => i_ext_req,
                                                             i_id_sch         => i_schedule,
                                                             i_status         => i_status,
                                                             i_notes          => i_notes,
                                                             i_reschedule     => i_reschedule,
                                                             i_id_reason_code => i_id_reason_code,
                                                             o_error          => o_error);
        
        ELSE
            g_error  := 'Call pk_ref_ext_sys.update_referral_status / ID_REF=' || i_ext_req || ' ID_WF=' || l_workflow ||
                        ' ID_SCHEDULE=' || i_schedule || ' STATUS=' || i_status || ' ID_EPISODE=' || i_episode ||
                        ' FLG_RESCHEDULE=' || i_reschedule;
            g_retval := pk_ref_ext_sys.update_referral_status(i_lang           => i_lang,
                                                              i_prof           => i_prof,
                                                              i_ext_req        => i_ext_req,
                                                              i_status         => i_status,
                                                              i_notes          => i_notes,
                                                              i_schedule       => i_schedule,
                                                              i_episode        => i_episode,
                                                              i_id_reason_code => i_id_reason_code,
                                                              o_error          => o_error);
        END IF;
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'UPDATE_REFERRAL_STATUS',
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END update_referral_status;

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
    ) RETURN BOOLEAN IS
    BEGIN
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Call pk_ref_dest_reg.check_ref_creation / i_id_patient=' || i_id_patient || ' i_external_sys=' ||
                    i_external_sys;
        g_retval := pk_ref_core.check_ref_creation(i_lang         => i_lang,
                                                   i_prof         => i_prof,
                                                   i_id_patient   => i_id_patient,
                                                   i_external_sys => i_external_sys,
                                                   o_cursor       => o_cursor,
                                                   o_error        => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_cursor);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_REF_CREATION',
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_cursor);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END check_ref_creation;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Call pk_ref_dest_reg.get_instit_list';
        g_retval := pk_ref_dest_reg.get_instit_list(i_lang  => i_lang,
                                                    i_prof  => i_prof,
                                                    o_inst  => o_inst,
                                                    o_other => o_other,
                                                    
                                                    o_error => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_inst);
            pk_types.open_my_cursor(o_other);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_INSTIT_LIST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_inst);
            pk_types.open_my_cursor(o_other);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_instit_list;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Call pk_ref_dest_reg.get_prof_data / i_num_order=' || i_num_order;
        g_retval := pk_ref_dest_reg.get_prof_data(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_num_order => i_num_order,
                                                  o_prof      => o_prof,
                                                  o_error     => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_prof);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PROF_DATA',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_prof);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_prof_data;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ref, i_dt_system_date => current_timestamp);
    
        g_error  := 'Calling pk_ref_ext_sys.set_ref_schedule / ID_REF=' || i_id_ref || ' ID_SCHEDULE=' || i_schedule ||
                    ' ID_EPISODE=' || i_episode;
        g_retval := pk_ref_ext_sys.set_ref_schedule(i_lang     => i_lang,
                                                    i_prof     => i_prof,
                                                    i_id_ref   => i_id_ref,
                                                    i_schedule => i_schedule,
                                                    i_notes    => i_notes,
                                                    i_episode  => i_episode,
                                                    --i_date     => NULL,
                                                    o_error => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_REF_SCHEDULE',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_ref_schedule;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ref, i_dt_system_date => current_timestamp);
    
        g_error  := 'Calling pk_ref_ext_sys.cancel_ref_schedule / ID_REF=' || i_id_ref || ' ID_SCHEDULE=' || i_schedule;
        g_retval := pk_ref_ext_sys.cancel_ref_schedule(i_lang     => i_lang,
                                                       i_prof     => i_prof,
                                                       i_id_ref   => i_id_ref,
                                                       i_schedule => i_schedule,
                                                       i_notes    => i_notes,
                                                       --i_date     => NULL,
                                                       o_error => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CANCEL_REF_SCHEDULE',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END cancel_ref_schedule;

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
    ) RETURN BOOLEAN IS
    BEGIN
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Call pk_ref_ext_sys.get_screen_dest_option / ID_INST = ' || i_prof.institution;
        g_retval := pk_ref_ext_sys.get_screen_dest_option(i_lang     => i_lang,
                                                          i_prof     => i_prof,
                                                          o_show_opt => o_show_opt,
                                                          o_error    => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SCREEN_DEST_OPTION',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_screen_dest_option;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ref, i_dt_system_date => current_timestamp);
    
        g_error  := 'CALL pk_ref_list.get_prof_resp / ID_REF = ' || i_id_ref;
        g_retval := pk_ref_list.get_prof_resp(i_lang      => i_lang,
                                              i_prof      => i_prof,
                                              i_id_ref    => i_id_ref,
                                              o_prof_data => o_prof_data,
                                              o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_prof_data);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PROF_RESP',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_prof_data);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_prof_resp;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'CALL pk_api_ref_ext.check_priv_orig_inst / i_id_session= ' || i_id_session;
        g_retval := pk_api_ref_ext.check_priv_orig_inst(i_lang       => i_lang,
                                                        i_prof       => i_prof,
                                                        i_id_session => i_id_session,
                                                        o_flg_result => o_flg_result,
                                                        o_error      => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_PRIV_ORIG_INST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END check_priv_orig_inst;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'CALL pk_api_ref_ext.check_ref_update / i_id_session= ' || i_id_session;
        g_retval := pk_api_ref_ext.check_ref_update(i_lang       => i_lang,
                                                    i_prof       => i_prof,
                                                    i_id_session => i_id_session,
                                                    o_flg_result => o_flg_result,
                                                    o_error      => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_REF_UPDATE',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END check_ref_update;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error := 'Init get_patient_data / ID_SESSION= ' || i_id_session || ' PROVIDER=' || i_provider;
        IF i_provider = pk_ref_constant.g_provider_p1
        THEN
            -- remove this provider after migrating all external systems to the new data model
            g_error  := 'CALL pk_p1_auto_complete.get_patient_data / ID_SESSION= ' || i_id_session;
            g_retval := pk_p1_auto_complete.get_patient_data(i_lang        => i_lang,
                                                             i_prof        => i_prof,
                                                             i_id_session  => i_id_session,
                                                             o_data        => o_data,
                                                             o_health_plan => o_health_plan,
                                                             o_error       => o_error);
        
        ELSIF i_provider = pk_ref_constant.g_provider_referral
        THEN
        
            g_error  := 'CALL pk_api_ref_ext.get_patient_data / ID_SESSION= ' || i_id_session;
            g_retval := pk_api_ref_ext.get_patient_data(i_lang        => i_lang,
                                                        i_prof        => i_prof,
                                                        i_id_session  => i_id_session,
                                                        o_data        => o_data,
                                                        o_health_plan => o_health_plan,
                                                        o_error       => o_error);
        END IF;
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_data);
            pk_types.open_my_cursor(o_health_plan);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PATIENT_DATA',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_data);
            pk_types.open_my_cursor(o_health_plan);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_patient_data;

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
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'Init get_referral_data / ID_SESSION= ' || i_id_session || ' PROVIDER=' || i_provider;
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        IF i_provider = pk_ref_constant.g_provider_p1
        THEN
            -- remove this provider after migrating all external systems to the new data model
            g_error  := 'CALL pk_p1_auto_complete.get_clinical_data_new / ID_SESSION= ' || i_id_session;
            g_retval := pk_p1_auto_complete.get_clinical_data_new(i_lang             => i_lang,
                                                                  i_prof             => i_prof,
                                                                  i_id_session       => i_id_session,
                                                                  o_detail           => o_detail,
                                                                  o_text             => o_text,
                                                                  o_problem          => o_problem,
                                                                  o_diagnosis        => o_diagnosis,
                                                                  o_mcdt             => o_mcdt,
                                                                  o_needs            => o_needs,
                                                                  o_info             => o_info,
                                                                  o_notes_status     => o_notes_status,
                                                                  o_notes_status_det => o_notes_status_det,
                                                                  o_answer           => o_answer,
                                                                  o_can_cancel       => o_can_cancel,
                                                                  o_error            => o_error);
        
        ELSIF i_provider = pk_ref_constant.g_provider_referral
        THEN
            g_error  := 'CALL pk_api_ref_ext.get_referral_data / ID_SESSION= ' || i_id_session;
            g_retval := pk_api_ref_ext.get_referral_data(i_lang             => i_lang,
                                                         i_prof             => i_prof,
                                                         i_id_session       => i_id_session,
                                                         o_detail           => o_detail,
                                                         o_text             => o_text,
                                                         o_problem          => o_problem,
                                                         o_diagnosis        => o_diagnosis,
                                                         o_mcdt             => o_mcdt,
                                                         o_needs            => o_needs,
                                                         o_info             => o_info,
                                                         o_notes_status     => o_notes_status,
                                                         o_notes_status_det => o_notes_status_det,
                                                         o_answer           => o_answer,
                                                         o_can_cancel       => o_can_cancel,
                                                         o_error            => o_error);
        
        END IF;
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_detail);
            pk_types.open_my_cursor(o_text);
            pk_types.open_my_cursor(o_problem);
            pk_types.open_my_cursor(o_diagnosis);
            pk_types.open_my_cursor(o_mcdt);
            pk_types.open_my_cursor(o_needs);
            pk_types.open_my_cursor(o_info);
            pk_types.open_my_cursor(o_notes_status);
            pk_types.open_my_cursor(o_notes_status_det);
            pk_types.open_my_cursor(o_answer);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REFERRAL_DATA',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_detail);
            pk_types.open_my_cursor(o_text);
            pk_types.open_my_cursor(o_problem);
            pk_types.open_my_cursor(o_diagnosis);
            pk_types.open_my_cursor(o_mcdt);
            pk_types.open_my_cursor(o_needs);
            pk_types.open_my_cursor(o_info);
            pk_types.open_my_cursor(o_notes_status);
            pk_types.open_my_cursor(o_notes_status_det);
            pk_types.open_my_cursor(o_answer);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_referral_data;

    /**
    * Matchs Alert patient with external system patient id
    *
    * @param   i_lang            Professional language identifier
    * @param   i_prof            Professional id, institution and software
    * @param   i_patient         Patient identifier
    * @param   i_id_session      Session identifier
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
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'Init set_match_session / ID_PATIENT= ' || i_patient || ' SEESION_ID=' || i_id_session ||
                   ' FLG_UPD_DATA=' || i_flg_upd_data || ' PROVIDER=' || i_provider;
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        IF i_provider = pk_ref_constant.g_provider_p1
        THEN
        
            g_error  := 'Call pk_p1_auto_complete.set_match / ID_PATIENT= ' || i_patient || ' SEESION_ID=' ||
                        i_id_session || ' FLG_UPD_DATA=' || i_flg_upd_data;
            g_retval := pk_p1_auto_complete.set_match(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_patient    => i_patient,
                                                      i_id_session => i_id_session,
                                                      o_error      => o_error);
        
            -- i_provider=REFERRAL does not need to match patient (searches patient by SNS)
            --ELSIF i_provider = pk_ref_constant.g_provider_referral THEN
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_MATCH_SESSION',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_match_session;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ref, i_dt_system_date => current_timestamp);
    
        g_error  := 'CALL pk_api_ref_ext.set_ref_created / ID_SESSION= ' || i_id_session || ' ID_REF=' || i_id_ref;
        g_retval := pk_api_ref_ext.set_ref_created(i_lang       => i_lang,
                                                   i_prof       => i_prof,
                                                   i_id_session => i_id_session,
                                                   i_id_ref     => i_id_ref,
                                                   o_error      => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_REF_CREATED',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_ref_created;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ref, i_dt_system_date => current_timestamp);
    
        g_error  := 'CALL pk_api_ref_ext.set_ref_updated / ID_SESSION= ' || i_id_session || ' ID_REF=' || i_id_ref;
        g_retval := pk_api_ref_ext.set_ref_updated(i_lang       => i_lang,
                                                   i_prof       => i_prof,
                                                   i_id_session => i_id_session,
                                                   i_id_ref     => i_id_ref,
                                                   o_error      => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_REF_UPDATED',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_ref_updated;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        -- has to be this function because the patient could have referrals having the old workflow, and referrals with the new workflow        
        g_error  := 'Call pk_p1_core.update_patient_requests / id_patient = ' || i_id_patient;
        g_retval := pk_p1_core.update_patient_requests(i_lang       => i_lang,
                                                       i_id_patient => i_id_patient,
                                                       i_prof       => i_prof,
                                                       --i_date       IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
                                                       o_error => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'UPDATE_PAT_REF',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END update_pat_ref;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Call pk_ref_list.get_ref_detail';
        g_retval := pk_ref_list.get_ref_detail(i_lang                => i_lang,
                                               i_prof                => i_prof,
                                               i_id_external_request => i_id_external_request,
                                               o_detail              => o_detail,
                                               o_error               => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REF_DETAIL',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_ref_detail;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'CALL pk_ref_status.check_ref_answered';
        g_retval := pk_ref_status.check_ref_answered(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_episode       => i_episode,
                                                     o_id_ext_req    => o_id_ext_req,
                                                     o_workflow      => o_workflow,
                                                     o_status_detail => o_status_detail,
                                                     o_needs_answer  => o_needs_answer,
                                                     o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_REF_ANSWERED',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
    END check_ref_answered;

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
    ) RETURN BOOLEAN IS
        l_transf_resp ref_trans_responsibility%ROWTYPE;
        l_params      table_varchar;
    BEGIN
        g_error  := 'Init tr_change_to_next_status / i_id_reason_code=' || i_id_reason_code || ' i_params=' ||
                    pk_utils.to_string(i_params);
        l_params := table_varchar();
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        FOR i IN 1 .. i_referrals.count
        LOOP
            --l_params := table_varchar(i_params(1), i_referrals(i) (3));
        
            l_transf_resp.id_external_request := to_number(i_referrals(i) (1));
            --l_transf_resp.id_prof_ref_owner   := i_referrals(i) (2);
            l_transf_resp.id_prof_transf_owner := to_number(i_referrals(i) (2));
            l_transf_resp.id_inst_dest_tr      := to_number(i_referrals(i) (3));
            l_transf_resp.id_trans_resp        := to_number(i_referrals(i) (4));
            l_transf_resp.id_workflow          := to_number(i_referrals(i) (5));
            l_transf_resp.id_status            := to_number(i_referrals(i) (6));
            l_transf_resp.id_prof_dest         := to_number(i_referrals(i) (7));
            l_transf_resp.id_inst_orig_tr      := to_number(i_referrals(i) (8));
            l_transf_resp.id_reason_code       := to_number(i_id_reason_code);
            l_transf_resp.reason_code_text     := i_reason_code_text;
            l_transf_resp.notes                := i_notes;
        
            g_error  := 'Call pk_ref_tr_status.init_tr_param_tab / ID_REF=' || l_transf_resp.id_external_request ||
                        ' id_trans_resp=' || l_transf_resp.id_trans_resp || ' ID_WF=' || l_transf_resp.id_workflow ||
                        ' ID_STATUS=' || l_transf_resp.id_status;
            l_params := pk_ref_tr_status.init_tr_param_tab(i_lang                 => i_lang,
                                                           i_prof                 => i_prof,
                                                           i_id_trans_resp        => l_transf_resp.id_trans_resp,
                                                           i_id_ref               => l_transf_resp.id_external_request,
                                                           i_id_prof_transf_owner => l_transf_resp.id_prof_transf_owner,
                                                           i_id_tr_prof_dest      => l_transf_resp.id_prof_dest,
                                                           i_id_tr_inst_orig      => l_transf_resp.id_inst_orig_tr,
                                                           i_id_tr_inst_dest      => l_transf_resp.id_inst_dest_tr,
                                                           i_user_answer          => i_params(1));
        
            g_error  := 'Call pk_ref_change_resp.change_to_next_status / ID_REF=' || l_transf_resp.id_external_request ||
                        ' id_trans_resp=' || l_transf_resp.id_trans_resp || ' ID_WF=' || l_transf_resp.id_workflow ||
                        ' ID_STATUS=' || l_transf_resp.id_status;
            g_retval := pk_ref_change_resp.change_to_next_status(i_lang        => i_lang,
                                                                 i_prof        => i_prof,
                                                                 i_transf_resp => l_transf_resp,
                                                                 i_params      => l_params,
                                                                 o_error       => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
        END LOOP;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'TR_CHANGE_TO_NEXT_STATUS',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END tr_change_to_next_status;

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
    ) RETURN BOOLEAN IS
        l_transf_resp ref_trans_responsibility%ROWTYPE;
    BEGIN
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        FOR i IN 1 .. i_referrals.count
        LOOP
        
            g_error  := 'Init tr_req_new_responsability / i_id_reason_code=' || i_id_reason_code || ' i_prof_dest=' ||
                        i_prof_dest;
            g_retval := pk_workflow.get_status_begin(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_id_workflow  => i_id_workflow,
                                                     o_status_begin => l_transf_resp.id_status,
                                                     o_error        => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            l_transf_resp.id_external_request  := i_referrals(i) (1);
            l_transf_resp.id_prof_ref_owner    := i_referrals(i) (2);
            l_transf_resp.id_trans_resp        := NULL;
            l_transf_resp.id_workflow          := i_id_workflow;
            l_transf_resp.id_prof_dest         := i_prof_dest;
            l_transf_resp.id_prof_transf_owner := i_prof.id;
            l_transf_resp.id_reason_code       := i_id_reason_code;
            l_transf_resp.reason_code_text     := i_reason_code_text;
            l_transf_resp.notes                := i_notes;
            l_transf_resp.id_inst_orig_tr      := i_prof.institution;
            l_transf_resp.id_inst_dest_tr      := i_id_inst_dest_tr;
        
            g_error  := 'Call PK_REF_CHANGE_RESP.req_new_responsibility / ID_REF=' || l_transf_resp.id_external_request;
            g_retval := pk_ref_change_resp.req_new_responsibility(i_lang        => i_lang,
                                                                  i_prof        => i_prof,
                                                                  i_transf_resp => l_transf_resp,
                                                                  o_error       => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        END LOOP;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'TR_REQ_NEW_RESPONSABILITY',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END tr_req_new_responsability;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Init get_tr_detail / ID_REF=' || i_id_ref;
        g_retval := pk_ref_change_resp.get_detail(i_lang        => i_lang,
                                                  i_prof        => i_prof,
                                                  i_id_ref      => i_id_ref,
                                                  o_ref_det     => o_ref_det,
                                                  o_tr_orig_det => o_tr_orig_det,
                                                  o_tr_dest_det => o_tr_dest_det,
                                                  o_error       => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_cursor_if_closed(o_ref_det);
            pk_types.open_cursor_if_closed(o_tr_orig_det);
            pk_types.open_cursor_if_closed(o_tr_dest_det);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_TR_DETAIL',
                                              o_error    => o_error);
            pk_types.open_cursor_if_closed(o_ref_det);
            pk_types.open_cursor_if_closed(o_tr_orig_det);
            pk_types.open_cursor_if_closed(o_tr_dest_det);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_tr_detail;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Init get_tr_short_detail / i_id_tr_tab.count=' || i_id_tr_tab.count;
        g_retval := pk_ref_change_resp.get_short_detail(i_lang        => i_lang,
                                                        i_prof        => i_prof,
                                                        i_id_tr_tab   => i_id_tr_tab,
                                                        o_tr_orig_det => o_tr_orig_det,
                                                        o_tr_dest_det => o_tr_dest_det,
                                                        o_error       => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_cursor_if_closed(o_tr_orig_det);
            pk_types.open_cursor_if_closed(o_tr_dest_det);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_TR_SHORT_DETAIL',
                                              o_error    => o_error);
            pk_types.open_cursor_if_closed(o_tr_orig_det);
            pk_types.open_cursor_if_closed(o_tr_dest_det);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_tr_short_detail;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Init get_tr_options';
        g_retval := pk_ref_change_resp.get_tr_options(i_lang        => i_lang,
                                                      i_prof        => i_prof,
                                                      i_id_workflow => i_id_workflow,
                                                      i_id_status   => i_id_status,
                                                      o_options     => o_options,
                                                      o_error       => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_cursor_if_closed(o_options);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_TR_OPTIONS',
                                              o_error    => o_error);
            pk_types.open_cursor_if_closed(o_options);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_tr_options;

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
    ) RETURN BOOLEAN IS
    BEGIN
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Init get_clin_serv / i_id_professional=' || i_id_professional || ' i_id_institution=' ||
                    i_id_institution || ' i_id_software=' || i_id_software;
        g_retval := pk_ref_list.get_clin_serv(i_lang      => i_lang,
                                              i_prof      => i_prof,
                                              o_clin_serv => o_clin_serv,
                                              o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_CLIN_SERV',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_clin_serv;

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
    ) RETURN BOOLEAN IS
    BEGIN
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Init pk_ref_list.get_prof_for_clin_serv / i_id_clinical_service=' || i_id_clinical_service;
        g_retval := pk_ref_list.get_prof_for_clin_serv(i_lang                => i_lang,
                                                       i_prof                => i_prof,
                                                       i_id_clinical_service => i_id_clinical_service,
                                                       i_id_prof_except_tab  => i_id_prof_except_tab,
                                                       o_prof                => o_prof,
                                                       o_error               => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PROF_FOR_CLIN_SERV',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_prof_for_clin_serv;

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
    ) RETURN BOOLEAN IS
    BEGIN
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Init tr_is_multi_prof';
        g_retval := pk_ref_change_resp.tr_is_multi_prof(i_lang  => i_lang,
                                                        i_prof  => i_prof,
                                                        o_multi => o_multi,
                                                        o_error => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'TR_IS_MULTI_PROF',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END tr_is_multi_prof;

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
    ) RETURN BOOLEAN IS
    BEGIN
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Init get_prof_ref_flg_type / i_id_prof_requested=' || pk_utils.to_string(i_id_prof_requested);
        g_retval := pk_ref_core.get_prof_ref_flg_type(i_lang              => i_lang,
                                                      i_prof              => i_prof,
                                                      i_id_prof_requested => i_id_prof_requested,
                                                      o_flg_type          => o_flg_type,
                                                      o_error             => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PROF_REF_FLG_TYPE',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_prof_ref_flg_type;

    /**
    * Get the description of hand off workflow status
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   o_status_desc    Workflow status description
    * @param   o_error          An error message, set when return=false
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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Call pk_ref_change_resp.get_handoff_status_desc';
        g_retval := pk_ref_change_resp.get_handoff_status_desc(i_lang        => i_lang,
                                                               i_prof        => i_prof,
                                                               o_status_desc => o_status_desc,
                                                               o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_status_desc);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_HANDOFF_STATUS_DESC',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_status_desc);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_handoff_status_desc;

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
    ) RETURN BOOLEAN IS
    BEGIN
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error     := ' CALL pk_prof_utils.get_name_signature i_prof_id=' || i_prof_id;
        o_prof_name := pk_prof_utils.get_name_signature(i_lang => i_lang, i_prof => i_prof, i_prof_id => i_prof.id);
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PROF_NAME',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_prof_name;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error := 'Init dyn_sel / tab_name=' || tab_name || ' i_column=' || i_column || ' field_name=' || field_name ||
                   ' val=' || val;
        pk_ref_change_resp.dyn_sel(i_lang       => i_lang,
                                   i_prof       => i_prof,
                                   i_tab_name   => tab_name,
                                   i_column     => i_column,
                                   i_field_name => field_name,
                                   i_val        => val,
                                   o_crs        => crs,
                                   o_error      => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'DYN_SEL',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
    END dyn_sel;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_ref, i_dt_system_date => current_timestamp);
    
        g_error  := 'Call pk_ref_core_internal.get_ref_actions / ID_REF=' || i_id_ref || ' SUBJECT=' || i_subject ||
                    ' FROM_STATE=' || i_from_state;
        g_retval := pk_ref_core_internal.get_ref_actions(i_lang       => i_lang,
                                                         i_prof       => i_prof,
                                                         i_id_ref     => i_id_ref,
                                                         i_subject    => i_subject,
                                                         i_from_state => i_from_state,
                                                         o_actions    => o_actions,
                                                         o_error      => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_actions);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REF_ACTIONS',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_actions);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_ref_actions;

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
    ) RETURN BOOLEAN IS
    BEGIN
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_id_external_request => i_id_external_request,
                                     i_dt_system_date      => current_timestamp);
    
        g_error  := 'Call pk_ref_core_internal.get_ref_actions / i_id_professional=' || i_id_professional ||
                    ' i_id_external_request=' || i_id_external_request || ' i_id_patient=' || i_id_patient;
        g_retval := pk_ref_core.get_ref_f_information(i_lang                => i_lang,
                                                      i_prof                => i_prof,
                                                      i_id_professional     => i_id_professional,
                                                      i_id_external_request => i_id_external_request,
                                                      i_id_patient          => i_id_patient,
                                                      o_cursor              => o_cursor,
                                                      o_error               => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_cursor);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REF_F_INFORMATION',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_cursor);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
    END get_ref_f_information;

    /**
    * Gets domains for waiting line
    *
    * @param   i_lang                     Language associated to the professional executing the request
    * @param   i_prof                     Professional, institution and software ids
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
    * @param   o_error                    An error message, set when return=false
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
    ) RETURN BOOLEAN IS
    BEGIN
    
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Call pk_ref_waiting_line.get_domains / i_code_domain=' || i_code_domain || ' i_id_inst_orig=' ||
                    i_id_inst_orig || ' i_id_inst_dest=' || i_id_inst_dest || ' i_flg_default=' || i_flg_default ||
                    ' i_flg_type=' || i_flg_type || ' i_flg_inside_ref_area=' || i_flg_inside_ref_area ||
                    ' i_flg_ref_line=' || i_flg_ref_line || ' i_flg_type_ins=' || i_flg_type_ins || ' i_id_speciality=' ||
                    i_id_speciality || ' i_flg_availability=' || i_flg_availability;
        g_retval := pk_ref_waiting_time.get_domains(i_lang                => i_lang,
                                                    i_prof                => i_prof,
                                                    i_code_domain         => i_code_domain,
                                                    i_id_inst_orig        => i_id_inst_orig,
                                                    i_id_inst_dest        => i_id_inst_dest,
                                                    i_flg_default         => i_flg_default,
                                                    i_flg_type            => i_flg_type,
                                                    i_flg_inside_ref_area => i_flg_inside_ref_area,
                                                    i_flg_ref_line        => i_flg_ref_line,
                                                    i_flg_type_ins        => i_flg_type_ins,
                                                    i_id_speciality       => i_id_speciality,
                                                    i_external_sys        => i_external_sys,
                                                    i_ref_type            => i_flg_availability,
                                                    o_data                => o_data,
                                                    o_error               => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'PRWL_GET_DOMAINS',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END prwl_get_domains;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'CALL pk_ref_core.get_prof_to_schedule / i_spec=' || i_spec || ' i_inst_dest=' || i_inst_dest;
        g_retval := pk_ref_core.get_prof_to_schedule(i_lang      => i_lang,
                                                     i_prof      => i_prof,
                                                     i_spec      => i_spec,
                                                     i_inst_dest => i_inst_dest,
                                                     o_sql       => o_sql,
                                                     o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_sql);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PROF_TO_SCHEDULE',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_sql);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_prof_to_schedule;

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
    ) RETURN VARCHAR2 IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        RETURN pk_ref_core.check_prof_phy(i_lang => i_lang, i_prof => i_prof, o_error => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_PROF_PHY',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
    END check_prof_phy;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Call pk_ref_list.get_cover';
        g_retval := pk_ref_list.get_cover(i_lang => i_lang, i_prof => i_prof, o_value => o_value, o_error => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_COVER',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_value);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_cover;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'CALL pk_api_ref_ext.session_ping / ID_SESSION= ' || i_id_session;
        g_retval := pk_api_ref_ext.session_ping(i_lang       => i_lang,
                                                i_prof       => i_prof,
                                                i_id_session => i_id_session,
                                                o_error      => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SESSION_PING',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END session_ping;

    /** Check if Referral Home is active
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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'CALL pk_ref_core.check_referral_home';
        g_retval := pk_ref_core.check_referral_home(i_lang        => i_lang,
                                                    i_prof        => i_prof,
                                                    i_type        => i_type,
                                                    o_home_active => o_home_active,
                                                    o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_REFERRAL_HOME',
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END check_referral_home;

    /**
    * Check if Referral reason is mandatory
    *
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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'CALL pk_ref_core.check_referral_reason / i_type=' || i_type;
        g_retval := pk_ref_core.check_referral_reason(i_lang             => i_lang,
                                                      i_prof             => i_prof,
                                                      i_type             => i_type,
                                                      i_home             => i_home,
                                                      i_priority         => i_priority,
                                                      o_reason_mandatory => o_reason_mandatory,
                                                      o_error            => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_REFERRAL_REASON',
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END check_referral_reason;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Call pk_ref_core.check_referral_diagnosis';
        g_retval := pk_ref_core.check_referral_diagnosis(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         o_diag_mandatory => o_diag_mandatory,
                                                         o_error          => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_PATIENT_RULES',
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END check_referral_diagnosis;

    /**
    * Gets available clinical services for referring in dest institution
    * Available only for external and at hospital entrance workflows
    *
    * @param   i_lang             language associated to the professional executing the request
    * @param   i_prof             professional, institution and software ids
    * @param   i_flg_availability Referring type
    * @param   i_p1_spec          Referral speciality identifier
    * @param   i_id_inst_dest     DEst institution identifier   
    * @param   i_external_sys External system identifier
    * @param   o_sql              Dest clinical services exposed to the origin institution
    * @param   o_error        An error message, set when return=false
    *
    * @value   i_flg_availability {*} 'E' external {*} 'P' at hospital entrance
    *
    * @return  TRUE if sucess, FALSE otherwise    
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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Init pk_ref_list.get_net_clin_serv / i_flg_availability=' || i_flg_availability || ' i_p1_spec=' ||
                    i_p1_spec || ' i_id_inst_dest=' || i_id_inst_dest || ' i_external_sys=' || i_external_sys;
        g_retval := pk_ref_list.get_net_clin_serv(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_ref_type     => i_flg_availability,
                                                  i_p1_spec      => i_p1_spec,
                                                  i_id_inst_dest => i_id_inst_dest,
                                                  i_external_sys => i_external_sys,
                                                  o_sql          => o_sql,
                                                  o_error        => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_sql);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REF_CLIN_SERV',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_sql);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_ref_clin_serv;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'CALL pk_ref_list.get_priority_list';
        g_retval := pk_ref_list.get_priority_list(i_lang  => i_lang,
                                                  i_prof  => i_prof,
                                                  o_list  => o_list,
                                                  o_error => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_types.open_my_cursor(o_list);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PRIORITY_LIST',
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_priority_list;

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
    **/

    FUNCTION get_ref_last_detail
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_pat         IN patient.id_patient%TYPE,
        i_flg_type    IN table_varchar,
        o_detail_text OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'CALL pk_ref_core.get_ref_last_detail';
        g_retval := pk_ref_core.get_ref_last_detail(i_lang        => i_lang,
                                                    i_prof        => i_prof,
                                                    i_pat         => i_pat,
                                                    i_flg_type    => i_flg_type,
                                                    o_detail_text => o_detail_text,
                                                    o_error       => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    END get_ref_last_detail;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_retval := pk_ref_list.get_handoff_type(i_lang       => i_lang,
                                                 i_prof       => i_prof,
                                                 i_id_ref_tab => i_id_ref_tab,
                                                 o_list       => o_list,
                                                 o_error      => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_HANDOFF_TYPE',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_handoff_type;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_retval := pk_ref_list.get_handoff_inst(i_lang           => i_lang,
                                                 i_prof           => i_prof,
                                                 i_id_inst_parent => i_id_inst_parent,
                                                 i_id_ref_tab     => i_id_ref_tab,
                                                 o_list_inst      => o_list_inst,
                                                 o_error          => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_types.open_my_cursor(o_list_inst);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_list_inst);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_HANDOFF_INST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_handoff_inst;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_retval := pk_ref_change_resp.get_detail_hist(i_lang          => i_lang,
                                                       i_prof          => i_prof,
                                                       i_id_ref        => i_id_ref,
                                                       o_hist_data     => o_hist_data,
                                                       o_hist_data_det => o_hist_data_det,
                                                       o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_types.open_my_cursor(o_hist_data);
            pk_types.open_my_cursor(o_hist_data_det);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_hist_data);
            pk_types.open_my_cursor(o_hist_data_det);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_TR_DETAIL_HIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_tr_detail_hist;

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
    ) RETURN BOOLEAN IS
    
        l_cause_enable sys_config.id_sys_config%TYPE;
        l_error        t_error_out;
        l_ret          table_varchar;
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
        l_cause_enable := nvl(pk_ref_utils.get_sys_config(i_prof          => i_prof,
                                                          i_id_sys_config => pk_ref_constant.g_ref_clave_cause_enabled),
                              pk_ref_constant.g_no);
    
        IF i_code_diagnosis.count = i_code_diagnosis.count
           AND i_code_diagnosis.count = i_code.count
        THEN
            l_ret := table_varchar();
            l_ret.extend(i_code_diagnosis.count);
        
            FOR i IN 1 .. i_code_diagnosis.count
            LOOP
                g_error := 'CALL  pk_diagnosis.STD_DIAG_DESC / I_DIAGNOSIS(' || i || ')=' || i_id_diagnosis(i) ||
                           ', I_CODE_DIAGNOSIS(' || i || ')=' || i_code_diagnosis(i) || ', I_CODE(' || i || ')=' ||
                           i_code(i) || ', I_FLG_OTHER(' || i || ')=' || i_flg_other(i);
            
                IF i_desc_epis_diagnosis(i) LIKE '%' || i_code(i) || '%'
                THEN
                    l_ret(i) := i_desc_epis_diagnosis(i);
                ELSE
                    l_ret(i) := pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                           i_prof                => i_prof,
                                                           i_id_alert_diagnosis  => i_id_alert_diagnosis(i),
                                                           i_id_diagnosis        => i_id_diagnosis(i),
                                                           i_code_diagnosis      => i_code_diagnosis(i),
                                                           i_desc_epis_diagnosis => i_desc_epis_diagnosis(i),
                                                           i_code                => i_code(i),
                                                           i_flg_other           => i_flg_other(i),
                                                           i_flg_show_term_code  => pk_alert_constant.g_yes,
                                                           i_flg_std_diag        => pk_alert_constant.g_yes,
                                                           i_flg_add_cause       => l_cause_enable);
                END IF;
            END LOOP;
        
        ELSE
            RAISE g_exception_np;
        END IF;
    
        o_diag_desc_array := l_ret;
        RETURN TRUE;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'STD_DIAG_DESC',
                                              o_error    => l_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END std_diag_desc_array;

    /**
    * Gets field 'Come Back' 
    * 
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
    ) RETURN BOOLEAN
    
     IS
    BEGIN
        g_error  := 'Call pk_ref_list.get_come_back_vals';
        g_retval := pk_ref_list.get_come_back_vals(i_lang  => i_lang,
                                                   i_prof  => i_prof,
                                                   o_value => o_value,
                                                   o_error => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_COME_BACK_VALS',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_value);
            RETURN FALSE;
    END get_come_back_vals;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Call pk_ref_core.create_ref_comment';
        g_retval := pk_ref_core.create_ref_comment(i_lang           => i_lang,
                                                   i_prof           => i_prof,
                                                   i_id_ref         => i_id_ref,
                                                   i_text           => i_text,
                                                   i_dt_comment     => pk_date_utils.get_string_tstz(i_lang,
                                                                                                     i_prof,
                                                                                                     i_dt_comment,
                                                                                                     NULL),
                                                   o_id_ref_comment => o_id_ref_comment,
                                                   o_error          => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CREATE_REF_COMMENT',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END create_ref_comment;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Call pk_ref_core.cancel_ref_comment / I_ID_REF=' || i_id_ref;
        g_retval := pk_ref_core.cancel_ref_comment(i_lang           => i_lang,
                                                   i_prof           => i_prof,
                                                   i_id_ref         => i_id_ref,
                                                   i_id_ref_comment => i_id_ref_comment,
                                                   i_dt_cancel      => pk_date_utils.get_string_tstz(i_lang,
                                                                                                     i_prof,
                                                                                                     i_dt_cancel,
                                                                                                     NULL),
                                                   o_id_ref_comment => o_id_ref_comment,
                                                   o_error          => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CANCEL_REF_COMMENT',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END cancel_ref_comment;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Call pk_ref_core.edit_ref_comment / I_ID_REF=' || i_id_ref;
        g_retval := pk_ref_core.edit_ref_comment(i_lang           => i_lang,
                                                 i_prof           => i_prof,
                                                 i_id_ref         => i_id_ref,
                                                 i_text           => i_text,
                                                 i_id_ref_comment => i_id_ref_comment,
                                                 i_dt_edit        => pk_date_utils.get_string_tstz(i_lang,
                                                                                                   i_prof,
                                                                                                   i_dt_edit,
                                                                                                   NULL),
                                                 o_id_ref_comment => o_id_ref_comment,
                                                 o_error          => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'EDIT_REF_COMMENT',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END edit_ref_comment;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Call pk_ref_list.get_fields_rank';
        g_retval := pk_ref_list.get_fields_rank(i_lang        => i_lang,
                                                i_prof        => i_prof,
                                                o_fields_rank => o_fields_rank,
                                                o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_FIELDS_RANK',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_fields_rank;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Call pk_ref_ext_sys.add_print_list_jobs / i_id_refs=' || pk_utils.to_string(i_id_refs);
        g_retval := pk_ref_ext_sys.add_print_list_jobs(i_lang            => i_lang,
                                                       i_prof            => i_prof,
                                                       i_patient         => i_patient,
                                                       i_episode         => i_episode,
                                                       i_id_refs         => i_id_refs,
                                                       i_print_arguments => i_print_arguments,
                                                       o_print_list_job  => o_print_list_job,
                                                       o_error           => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'ADD_PRINT_LIST_JOBS',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END add_print_list_jobs;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- sets the referral context
        pk_ref_utils.init_ref_context;
        pk_ref_utils.set_ref_context(i_dt_system_date => current_timestamp);
    
        g_error  := 'Call pk_ref_ext_sys.get_available_reports';
        g_retval := pk_ref_ext_sys.get_available_reports(i_lang        => i_lang,
                                                         i_prof        => i_prof,
                                                         o_cur_reports => o_cur_reports,
                                                         o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
        -- resets the referral context
        pk_ref_utils.reset_ref_context;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_AVAILABLE_REPORTS',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_available_reports;

    FUNCTION get_family_relationships
    
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        o_family_relat OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_ref_core.get_family_relationships(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_patient      => i_patient,
                                                    o_family_relat => o_family_relat,
                                                    o_error        => o_error)
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_AVAILABLE_REPORTS',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_family_relationships;

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
    ) RETURN BOOLEAN IS
        l_bdnp_available sys_config.value%TYPE;
    
        CURSOR c_cur_cod(x_cod codification.id_codification%TYPE) IS
            SELECT id_content
              FROM codification
             WHERE id_codification = x_cod;
        l_content codification.id_content%TYPE;
    
    BEGIN
    
        RETURN TRUE;
        OPEN c_cur_cod(i_codification);
        FETCH c_cur_cod
            INTO l_content;
        CLOSE c_cur_cod;
    
        -- convencionados e consultas
        IF l_content = pk_ref_constant.g_conv_codification
           OR i_type = pk_ref_constant.g_p1_type_c
        THEN
            g_error          := 'Call pk_sysconfig.get_config ' || pk_ref_constant.g_ref_mcdt_bdnp;
            l_bdnp_available := nvl(pk_sysconfig.get_config(pk_ref_constant.g_ref_mcdt_bdnp, i_prof),
                                    pk_ref_constant.g_no);
        
            IF l_bdnp_available = pk_ref_constant.g_yes
            THEN
                g_error := 'CALL pk_bdnp.check_patient_rules / I_PATIENT=' || i_patient || ' I_EPISODE=' || i_episode ||
                           ' i_type=' || i_type;
                pk_alertlog.log_debug(g_error);
            
                g_retval := pk_bdnp.check_patient_rules(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_patient        => i_patient,
                                                        i_episode        => i_episode,
                                                        i_type           => 'R',
                                                        o_flg_show       => o_flg_show,
                                                        o_message_title  => o_message_title,
                                                        o_message_text   => o_message_text,
                                                        o_forward_button => o_forward_button,
                                                        o_back_button    => o_back_button,
                                                        o_error          => o_error);
                IF NOT g_retval
                THEN
                    g_error := 'Error: ' || g_error;
                    RAISE g_exception;
                END IF;
            ELSE
                o_flg_show := pk_ref_constant.g_no;
            END IF;
        ELSE
            o_flg_show := pk_ref_constant.g_no;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_PATIENT_RULES',
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END check_patient_rules;

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
    ) RETURN BOOLEAN IS
        l_id_wf PLS_INTEGER;
    BEGIN
    
        g_error := 'Call pk_p1_med_cs.insert_referral_mcdt_internal';
        IF i_ref_completion != pk_ref_constant.g_ref_compl_ge
        THEN
            l_id_wf := NULL;
        ELSE
            l_id_wf := to_number(nvl(pk_sysconfig.get_config(pk_ref_constant.g_referral_button_wf, i_prof), 0));
            IF l_id_wf = 0
            THEN
                l_id_wf := NULL;
            END IF;
        END IF;
    
        g_error  := 'Call pk_ref_service.insert_mcdt_referral';
        g_retval := pk_ref_service.insert_mcdt_referral(i_lang                      => i_lang,
                                                        i_prof                      => i_prof,
                                                        i_ext_req                   => i_ext_req,
                                                        i_workflow                  => l_id_wf,
                                                        i_flg_priority_home         => i_flg_priority_home,
                                                        i_mcdt                      => i_mcdt,
                                                        i_id_patient                => i_id_patient,
                                                        i_req_type                  => i_req_type,
                                                        i_flg_type                  => i_flg_type,
                                                        i_problems                  => i_problems,
                                                        i_dt_problem_begin          => i_dt_problem_begin,
                                                        i_detail                    => i_detail,
                                                        i_diagnosis                 => i_diagnosis,
                                                        i_completed                 => i_completed,
                                                        i_id_tasks                  => i_id_tasks,
                                                        i_id_info                   => i_id_info,
                                                        i_epis                      => i_id_episode,
                                                        i_date                      => NULL,
                                                        i_codification              => i_codification,
                                                        i_flg_laterality            => i_flg_laterality,
                                                        i_dt_modified               => i_dt_modified,
                                                        i_consent                   => i_consent,
                                                        i_reason                    => NULL,
                                                        i_complementary_information => NULL,
                                                        o_flg_show                  => o_flg_show,
                                                        o_msg                       => o_msg,
                                                        o_msg_title                 => o_msg_title,
                                                        o_button                    => o_button,
                                                        o_ext_req                   => o_id_external_request,
                                                        o_error                     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- O COMMIT é feito no pk_ref_service
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'INSERT_EXTERNAL_REQUEST_MCDT_N',
                                              o_error    => o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END insert_external_request_mcdt;

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
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT VARCHAR2(30) := 'CHK_EXT_REQ_LIGHT_LICENSE';
        l_presc_light_value_syscfg sys_config.value%TYPE;
        l_balance                  NUMBER(24);
    BEGIN
        g_error := 'INIT CHK_EXT_REQ_LIGHT_LICENSE';
    
        l_presc_light_value_syscfg := pk_sysconfig.get_config(i_code_cf => 'PRESC_LIGHT_ALMOST_EMPTY', i_prof => i_prof);
        o_flg_show                 := pk_alert_constant.g_no;
        o_shortcut                 := 700182; -- Shortcut (portal de compras);
        o_flg_show_almost_empty    := pk_alert_constant.g_no;
    
        g_error   := 'CALL pk_api_med_out.get_light_license_credits';
        l_balance := get_light_license_credits(i_lang => i_lang, i_prof => i_prof);
    
        IF l_balance IS NOT NULL
        THEN
            o_flg_show := pk_alert_constant.g_yes;
            IF l_balance <= 0
            THEN
                o_flg_show_almost_empty := pk_alert_constant.g_no;
                o_message_text          := pk_message.get_message(i_lang      => i_lang,
                                                                  i_code_mess => 'PRESC_LIGHT_EMPTY_MSG');
            ELSIF l_balance <= l_presc_light_value_syscfg
            THEN
                o_flg_show_almost_empty := pk_alert_constant.g_yes;
                o_message_text          := REPLACE(pk_message.get_message(i_lang      => i_lang,
                                                                          i_prof      => i_prof,
                                                                          i_code_mess => 'PRESC_LIGHT_ALMOST_EMPTY_MSG'),
                                                   '@1',
                                                   l_presc_light_value_syscfg);
            ELSE
                o_flg_show_almost_empty := pk_alert_constant.g_no;
                o_flg_show              := pk_alert_constant.g_no;
            END IF;
        
            OPEN o_info_buttons FOR
                SELECT pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'ID_WARNING_TITLE') btnwarning,
                       pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'COMMON_M070') btnproceed,
                       pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'PRESC_LIGHT_BT_GOTO') btngoportal,
                       pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'COMMON_M103') btnclose
                  FROM dual;
        ELSE
            o_flg_show := pk_alert_constant.g_no;
            pk_types.open_my_cursor(o_info_buttons);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            o_flg_show := pk_alert_constant.g_no;
            pk_types.open_my_cursor(o_info_buttons);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_info_buttons);
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => l_db_object_name,
                                                     o_error    => o_error);
    END chk_ext_req_light_license;

    FUNCTION get_light_license_credits
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN NUMBER IS
        l_db_object_name CONSTANT VARCHAR2(30) := 'GET_LIGHT_LICENSE_CREDITS';
        l_flg_payment_pla presc_light_license.flg_payment_plan%TYPE;
        l_prof_assoc      presc_light_license.id_professional%TYPE;
        l_balance         NUMBER(24) := 0;
        -- 
        l_curid  INTEGER;
        l_sql    CLOB;
        l_ret    INTEGER;
        l_cursor pk_types.cursor_type;
        l_error  t_error_out;
    BEGIN
        g_error := 'INIT GET_LIGHT_LICENSE_CREDITS';
    
        IF pk_tools.get_prof_profile_template(i_prof) = 136 /*PP Light profile template*/
        THEN
        
            g_error := 'GET info';
            BEGIN
                SELECT t.flg_payment_plan, t.id_professional
                  INTO l_flg_payment_pla, l_prof_assoc
                  FROM (SELECT pll.flg_payment_plan,
                               pll.id_professional,
                               row_number() over(ORDER BY pll.id_professional) line_number
                          FROM presc_light_license pll
                         WHERE pll.id_professional IN (0, i_prof.id)
                           AND pll.id_institution = i_prof.institution) t
                 WHERE t.line_number = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    --Theres no license
                    RETURN NULL;
            END;
        
            g_error := 'GET l_balance - l_flg_payment_pla: ' || l_flg_payment_pla || '|l_prof_assoc: ' || l_prof_assoc;
            IF l_flg_payment_pla = 'PRE'
            THEN
                --PRE
                l_curid := dbms_sql.open_cursor;
            
                --get the remaining licenses from AWD
                IF l_prof_assoc = 0
                THEN
                    --institution shared licenses
                    BEGIN
                        l_sql := 'SELECT vplb.balance FROM v_prescription_light_balance vplb WHERE vplb.id_professional = 0 ' ||
                                 ' AND vplb.id_institution = :i_institution ';
                    
                        dbms_sql.parse(l_curid, l_sql, dbms_sql.native);
                        dbms_sql.bind_variable(l_curid, 'i_institution', i_prof.institution);
                        l_ret    := dbms_sql.execute(l_curid);
                        l_cursor := dbms_sql.to_refcursor(l_curid);
                    
                        FETCH l_cursor
                            INTO l_balance;
                    EXCEPTION
                        WHEN OTHERS THEN
                            g_error := g_error || ' - sql: ' || dbms_lob.substr(l_sql, 4000, 1);
                            pk_alertlog.log_debug(object_name     => g_package_name,
                                                  sub_object_name => l_db_object_name,
                                                  text            => g_error);
                            l_balance := 0;
                    END;
                ELSE
                    --professional licenses
                    BEGIN
                        l_sql := 'SELECT vplb.balance FROM v_prescription_light_balance vplb WHERE vplb.id_professional = :i_prof_id ' ||
                                 ' AND vplb.id_institution = :i_institution ';
                    
                        dbms_sql.parse(l_curid, l_sql, dbms_sql.native);
                        dbms_sql.bind_variable(l_curid, 'i_prof_id', i_prof.id);
                        dbms_sql.bind_variable(l_curid, 'i_institution', i_prof.institution);
                        l_ret    := dbms_sql.execute(l_curid);
                        l_cursor := dbms_sql.to_refcursor(l_curid);
                    
                        FETCH l_cursor
                            INTO l_balance;
                    EXCEPTION
                        WHEN OTHERS THEN
                            g_error := g_error || ' - sql: ' || dbms_lob.substr(l_sql, 4000, 1);
                            pk_alertlog.log_debug(object_name     => g_package_name,
                                                  sub_object_name => l_db_object_name,
                                                  text            => g_error);
                            l_balance := 0;
                    END;
                END IF;
            ELSE
                -- POS
                RETURN NULL;
            END IF;
        
        ELSE
            RETURN NULL;
        END IF;
    
        RETURN l_balance;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => l_error);
            RETURN NULL;
        
    END get_light_license_credits;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_ref_service;
/
