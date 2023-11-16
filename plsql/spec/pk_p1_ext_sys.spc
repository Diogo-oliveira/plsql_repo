/*-- Last Change Revision: $Rev: 2028836 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:14 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_p1_ext_sys AS

    g_p1_request_from_orders_area CONSTANT PLS_INTEGER := 999999;
    g_p1_orders_origin            CONSTANT VARCHAR2(1) := 'O';
    g_p1_referrals_origin         CONSTANT VARCHAR2(1) := 'R';
    g_p1_edit_action              CONSTANT NUMBER(24) := 2340164;

    TYPE mcdt_type IS RECORD(
        p1_id                        NUMBER(24),
        p1_id_parent                 NUMBER(24),
        p1_id_req                    NUMBER(24),
        p1_id_analysis_req           NUMBER(24),
        p1_id_exam_req               NUMBER(24),
        p1_title                     VARCHAR2(1000),
        p1_text                      VARCHAR2(4000),
        p1_dt_insert                 VARCHAR2(1000),
        p1_prof_name                 VARCHAR2(1000),
        p1_flg_type                  VARCHAR2(2),
        p1_flg_status                VARCHAR2(10),
        p1_id_institution            NUMBER(24),
        p1_abbreviation              VARCHAR2(1000),
        p1_desc_institution          VARCHAR2(1000),
        p1_flg_priority              VARCHAR2(2),
        p1_flg_home                  VARCHAR2(2),
        p1_priority_desc             VARCHAR2(1000),
        p1_desc_home                 VARCHAR2(1000),
        p1_label_priority            VARCHAR2(1000),
        p1_priority_icon             sys_domain.img_name%TYPE,
        p1_label_home                VARCHAR2(1000),
        p1_id_codification           interv_codification.id_codification%TYPE,
        p1_desc_codification         VARCHAR2(1000),
        p1_id_mcdt_codification      NUMBER(24),
        p1_product_desc              VARCHAR2(1000),
        p1_id_sample_type            analysis_sample_type.id_sample_type%TYPE,
        p1_id_rehab_area_interv      rehab_area_interv.id_rehab_area_interv%TYPE,
        p1_desc_rehab_area           VARCHAR2(1000),
        p1_flg_laterality            VARCHAR2(2),
        p1_desc_laterality           VARCHAR2(1000),
        p1_flg_laterality_mcdt       VARCHAR2(2),
        p1_label_laterality          VARCHAR2(1000),
        p1_label_amount              VARCHAR2(1000),
        p1_mcdt_amount               NUMBER(24),
        p1_id_rehab_session_type     rehab_session_type.id_rehab_session_type%TYPE,
        p1_reason                    VARCHAR2(1000 CHAR),
        p1_complementary_information VARCHAR2(1000 CHAR),
        standard_code                VARCHAR2(30 CHAR));

    TYPE tbl_mcdt_type IS TABLE OF mcdt_type;

    TYPE detail_type IS RECORD(
        id_external_request       p1_external_request.id_external_request%TYPE,
        id_p1                     p1_external_request.num_req%TYPE,
        flg_type                  p1_external_request.flg_type%TYPE,
        num_req                   p1_external_request.num_req%TYPE,
        id_workflow               p1_external_request.id_workflow%TYPE,
        id_episode                p1_external_request.id_episode%TYPE,
        dt_p1                     VARCHAR2(200 CHAR),
        status_icon               VARCHAR2(200 CHAR),
        flg_status                p1_external_request.flg_status%TYPE,
        status_colors             VARCHAR2(200 CHAR), --10
        desc_status               VARCHAR2(4000),
        priority_info             VARCHAR2(200 CHAR),
        priority_icon             VARCHAR2(200 CHAR),
        priority_desc             VARCHAR2(1000 CHAR),
        dt_elapsed                VARCHAR2(200 CHAR),
        id_prof_requested         NUMBER(24),
        prof_name_request         VARCHAR2(200 CHAR),
        prof_spec_request         VARCHAR2(200 CHAR),
        id_dep_clin_serv          p1_external_request.id_dep_clin_serv%TYPE,
        desc_clinical_service     VARCHAR2(200 CHAR), --20
        id_department             department.id_department%TYPE,
        desc_department           VARCHAR2(200 CHAR),
        id_speciality             p1_external_request.id_speciality%TYPE,
        id_inst_orig              p1_external_request.id_inst_orig%TYPE,
        inst_orig_clues           VARCHAR2(200 CHAR),
        inst_orig_abbrev          VARCHAR2(200 CHAR),
        inst_orig_name            VARCHAR2(200 CHAR),
        id_inst_dest              p1_external_request.id_inst_dest%TYPE,
        inst_abbrev               VARCHAR2(200 CHAR),
        inst_name                 VARCHAR2(200 CHAR), --30
        dep_name                  VARCHAR2(200 CHAR),
        spec_name                 VARCHAR2(200 CHAR),
        dt_schedule               VARCHAR2(200 CHAR),
        dt_probl_begin            VARCHAR2(200 CHAR),
        dt_probl_begin_ts         VARCHAR2(200 CHAR),
        field_name                VARCHAR2(200 CHAR),
        flg_priority              p1_external_request.flg_priority%TYPE,
        flg_home                  p1_external_request.flg_home%TYPE,
        prof_redirected           VARCHAR2(200 CHAR),
        dt_last_interaction       VARCHAR2(200 CHAR), --40
        label_institution         sys_message.desc_message%TYPE,
        label_clinical_service    sys_message.desc_message%TYPE,
        label_department          sys_message.desc_message%TYPE,
        label_priority            sys_message.desc_message%TYPE,
        label_home                sys_message.desc_message%TYPE,
        desc_home                 VARCHAR2(200 CHAR),
        label_status              sys_message.desc_message%TYPE,
        label_dt_probl_begin      sys_message.desc_message%TYPE,
        decision_urg_level        p1_external_request.decision_urg_level%TYPE,
        desc_decision_urg_level   VARCHAR2(200 CHAR), --50
        id_external_sys           p1_external_request.id_external_sys%TYPE,
        id_schedule_ext           p1_external_request.id_schedule%TYPE,
        id_prof_schedule          professional.id_professional%TYPE,
        reason_desc               VARCHAR2(200 CHAR),
        reason_text               VARCHAR2(200 CHAR),
        title_notes               VARCHAR2(200 CHAR),
        title_text                VARCHAR2(200 CHAR),
        sub_spec_name             VARCHAR2(200 CHAR),
        label_sub_spec            sys_message.desc_message%TYPE,
        label_spec                sys_message.desc_message%TYPE, --60
        wait_days                 VARCHAR2(200 CHAR),
        ref_line                  VARCHAR2(200 CHAR),
        type_ins                  VARCHAR2(200 CHAR),
        inside_ref_area           VARCHAR2(200 CHAR),
        inst_type_label           VARCHAR2(200 CHAR),
        ref_line_label            VARCHAR2(200 CHAR),
        wait_days_label           VARCHAR2(200 CHAR),
        id_sub_speciality         p1_external_request.id_dep_clin_serv%TYPE,
        id_content                VARCHAR2(200 CHAR),
        flg_type_desc             VARCHAR2(200 CHAR), --70
        location_dest             VARCHAR2(200 CHAR),
        dt_issued                 VARCHAR2(200 CHAR),
        label_referral_number     VARCHAR2(1000),
        flg_create_comment        VARCHAR2(1),
        prof_certificate          VARCHAR2(30 CHAR),
        prof_name                 VARCHAR2(200 CHAR),
        prof_surname              VARCHAR2(200 CHAR),
        prof_phone                VARCHAR2(30 CHAR),
        id_fam_rel                family_relationship.id_family_relationship%TYPE,
        desc_fr                   VARCHAR(100 CHAR),
        name_first_rel            VARCHAR2(100 CHAR),
        name_middle_rel           VARCHAR2(300 CHAR), --80
        name_last_rel             VARCHAR2(100 CHAR),
        consent                   VARCHAR2(2 CHAR),
        desc_consent              VARCHAR2(4000 CHAR),
        family_relationship_notes VARCHAR2(1000 CHAR));

    TYPE tbl_p1_detail_type IS TABLE OF detail_type;

    TYPE p1_text_type IS RECORD(
        label_group        VARCHAR2(100),
        label              VARCHAR2(200),
        id                 NUMBER(24),
        id_parent          NUMBER(24),
        id_req             NUMBER(24),
        title              VARCHAR2(4000),
        text               VARCHAR2(4000),
        dt_insert          VARCHAR2(100),
        prof_name          VARCHAR2(200),
        prof_spec          VARCHAR2(200),
        flg_type           NUMBER(12),
        flg_status         VARCHAR2(10),
        id_institution     NUMBER(24),
        flg_priority       VARCHAR2(1),
        flg_home           VARCHAR2(1),
        id_group           NUMBER(12),
        rank_group_reports NUMBER(12),
        field_name         VARCHAR2(100));

    TYPE tbl_p1_text IS TABLE OF p1_text_type;

    TYPE p1_diagnosis_type IS RECORD(
        label_group        VARCHAR2(1000 CHAR),
        label              VARCHAR2(1000 CHAR),
        id                 NUMBER(24),
        id_parent          NUMBER(24),
        id_alert_diagnosis NUMBER(24),
        code_icd           VARCHAR2(50),
        flg_other          VARCHAR2(10),
        id_req             NUMBER(24),
        title              VARCHAR2(1000 CHAR),
        text               VARCHAR2(1000 CHAR),
        dt_insert          VARCHAR2(200),
        prof_name          VARCHAR2(1000 CHAR),
        prof_spec          VARCHAR2(1000 CHAR),
        flg_type           VARCHAR2(10),
        flg_status         VARCHAR2(10),
        id_institution     NUMBER(24),
        flg_priority       VARCHAR2(10),
        flg_home           VARCHAR2(10),
        causes_code        VARCHAR2(1000 CHAR),
        rank_group_reports NUMBER(12),
        field_name         VARCHAR2(20),
        sub_rank           NUMBER(12));

    TYPE tbl_p1_diagnosis IS TABLE OF p1_diagnosis_type;

    /**
    * Gets list of patient referrals
    *
    * @param   i_lang  language
    * @param   i_prof  profissional, institution, software
    * @param   i_id_patient patient id
    * @param   i_type if null returns all request, otherwise return for the selected type
    *          ((C)onsulation, (A)nalysis, (E)xam, (I)ntervention)
    * @param   o_p1 returned referral list
    * @param   O_ERROR an error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 1.0
    * @since   29-08-2007
    */

    FUNCTION get_pat_p1_to_edit
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_p1_external_request IN p1_external_request.id_external_request%TYPE,
        o_p1                     OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_p1
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_type       IN p1_external_request.flg_type%TYPE,
        o_p1         OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_p1
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_type       IN p1_external_request.flg_type%TYPE
    ) RETURN t_tbl_p1_grid;

    /**
    * Gets list of patient referrals available for scheduling
    *
    * @param   i_lang  language
    * @param   i_prof  profissional, institution, software
    * @param   i_id_patient patient id
    * @param   i_type if null returns all request, otherwise return for the selected type
    *          ((C)onsulation, (A)nalysis, (E)xam, (I)ntervention)
    * @param   o_p1 returned referral list
    * @param   i_schedule current schedule id
    * @param   o_message message to return
    * @param   o_title  message type
    * @param   o_button button message
    * @param   o_error an error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 1.0
    * @since   29-08-2007
    */
    FUNCTION get_pat_p1_to_schedule
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_type       IN table_varchar, --p1_external_request.flg_type%TYPE,
        i_schedule   IN schedule.id_schedule%TYPE,
        o_p1         OUT pk_types.cursor_type,
        o_message    OUT VARCHAR2,
        o_title      OUT VARCHAR2,
        o_buttons    OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the list of referral MCDTs grouped as required the specified report
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   id_prof             Professional identifier
    * @param   id_inst             Professional institution identifier
    * @param   id_soft             Professional software identifier   
    * @param   i_exr               Referral identifier
    * @param   i_type              Splitting type: {*} 'PV' print preview (do not generate codes)
    *                                              {*} 'PF' print final(generate codes)
    *                                              {*} 'A' application  
    * @param   i_id_report         Report identifier. Needed to get the maximum number of MCDTs in each referral report
    * @param   i_id_ref_completion Referral completion option id. Needed to get the maximum number of MCDTs in each referral report   
    * @param   o_ref               MCDTs list
    * @param   O_ERROR             An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   02-06-2008
    * @modify  Ana Monteiro, 2009-10-23: ALERT-48308 - added parameters i_id_report and i_id_ref_completion   
    */
    FUNCTION get_exr_group
    (
        i_lang              IN language.id_language%TYPE,
        id_prof             IN professional.id_professional%TYPE,
        id_inst             IN institution.id_institution%TYPE,
        id_soft             IN software.id_software%TYPE,
        i_exr               IN p1_external_request.id_external_request%TYPE,
        i_type              IN VARCHAR2,
        i_id_report         IN reports.id_reports%TYPE,
        i_id_ref_completion IN ref_completion.id_ref_completion%TYPE,
        i_flg_isencao       IN VARCHAR2,
        o_ref               OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_exr_group
    (
        i_lang              IN language.id_language%TYPE,
        id_prof             IN professional.id_professional%TYPE,
        id_inst             IN institution.id_institution%TYPE,
        id_soft             IN software.id_software%TYPE,
        i_exr               IN p1_external_request.id_external_request%TYPE,
        i_type              IN VARCHAR2,
        i_id_report         IN reports.id_reports%TYPE,
        i_id_ref_completion IN ref_completion.id_ref_completion%TYPE,
        i_flg_isencao       IN VARCHAR2,
        o_ref               OUT pk_types.cursor_type,
        o_institution       OUT pk_types.cursor_type,
        o_patient           OUT pk_types.cursor_type,
        o_ref_health_plan   OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Splits referral MCDTs into groups, as required the specified report
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   id_prof                Professional identifier
    * @param   id_inst                Professional institution identifier
    * @param   id_soft                Professional software identifier   
    * @param   i_exr                  Referral identifier
    * @param   i_id_patient           Patient identifier
    * @param   i_id_episode           Episode identifier    
    * @param   i_type                 Splitting type: {*} 'PV' print preview (do not generate codes)
    *                                              {*} 'PF' print final(generate codes)
    *                                              {*} 'A' application  
    * @param   i_num_req              Referrals number    
    * @param   i_id_report            Report identifier. Needed to get the maximum number of MCDTs in each referral report
    * @param   i_id_ref_completion    Referral completion option id. Needed to get the maximum number of MCDTs in each referral report   
    * @param   o_id_external_request  Created referral ids
    * @param   O_ERROR                An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   02-06-2008
    * @modify  Ana Monteiro, 2009-10-23: ALERT-48308 - added parameters i_id_report and i_id_ref_completion
    */
    FUNCTION split_mcdt_request_by_group
    (
        i_lang                IN language.id_language%TYPE,
        id_prof               IN professional.id_professional%TYPE,
        id_inst               IN institution.id_institution%TYPE,
        id_soft               IN software.id_software%TYPE,
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
    * Service to create or update a request
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_ext_req request id
    * @param   i_dt_modified data da última alteração tal como devolvida por pk_p1_core.get_p1_detail
    * @param   i_id_patient patient id
    * @param   i_speciality request speciality (P1_SPECIALITY)
    * @param   i_id_dep_clin_serv id department/clinical_service (can be null)
    * @param   i_req_type (M)anual; Using clinical (P)rotocol
    * @param   i_flg_type (A)nalisys; (C)onsultation (E)xam, (I)ntervention,
    * @param   i_flg_priority urgent/not urgent
    * @param   i_flg_home home consultation?
    * @param   i_inst_dest destination institution
    * @param   i_prof  professional, institution and software ids
    * @param   i_id_sched   @deprecated
    * @param   i_problems request data - problem identifiers to solve
    * @param   i_problems request data - problem descriptions to solve
    * @param   i_dt_problem_begin request data - date of problem begining
    * @param   i_detail P1 detail info. For each detail: [id_detail|flg_type|text|flg|id_group]
    * @param   i_diagnosis request data - diagnosis
    * @param   i_completed request completeded (Y/N)
    * @param   i_id_tasks           Referral tasks needed for (S)cheduling. [ID_TASK|ID_GROUP]
    * @param   i_id_info            Referral tasks needed for (C)onsultation. [ID_TASK|ID_GROUP]
    * @param   o_id_external_request request id
    * @param   o_flg_show show message (Y/N)
    * @param   o_msg message text
    * @param   o_msg_title message title
    * @param   o_button type of button to show with message
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.1
    * @since   18-04-2007
    * @modify  Ana Monteiro 2009/01/08 ALERT-11632
    */
    FUNCTION insert_external_request_new
    (
        i_lang             IN language.id_language%TYPE,
        i_ext_req          IN p1_external_request.id_external_request%TYPE,
        i_dt_modified      IN VARCHAR2, -- JS: 2007-04-18, Validar se pedido é modificado enquanto é editado pelo médico do CS
        i_id_patient       IN patient.id_patient%TYPE,
        i_speciality       IN p1_speciality.id_speciality%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_req_type         IN p1_external_request.req_type%TYPE,
        i_flg_type         IN p1_external_request.flg_type%TYPE,
        i_flg_priority     IN p1_external_request.flg_priority%TYPE, -- I_ID_INST_ORIG IN PROFISSIONAL,
        i_flg_home         IN p1_external_request.flg_home%TYPE,
        i_inst_dest        IN institution.id_institution%TYPE,
        i_prof             IN profissional,
        --i_id_sched            IN schedule.id_schedule%TYPE, --- Não usado
        i_problems            IN CLOB,
        i_dt_problem_begin    IN VARCHAR2,
        i_detail              IN table_table_varchar,
        i_diagnosis           IN CLOB,
        i_completed           IN VARCHAR2,
        i_id_tasks            IN table_table_number,
        i_id_info             IN table_table_number,
        i_epis                IN episode.id_episode%TYPE,
        i_ref_completion      IN ref_completion.id_ref_completion%TYPE,
        i_prof_cert           IN VARCHAR2,
        i_prof_first_name     IN VARCHAR2,
        i_prof_surname        IN VARCHAR2,
        i_prof_phone          IN VARCHAR2,
        i_id_fam_rel          IN family_relationship.id_family_relationship%TYPE,
        i_name_first_rel      IN VARCHAR2,
        i_name_middle_rel     IN VARCHAR2,
        i_name_last_rel       IN VARCHAR2,
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
    * @param i_lang language associated to the professional executing the request
    * @param i_ext_req external request id
    * @param i_dt_modified
    * @param i_id_patient patient id
    * @param i_id_episode episode id
    * @param i_req_type
    * @param i_flg_type {*} 'A' analysis {*} 'I' Image {*} 'E' Other Exams {*} 'P' Intervention/Procedures {*} 'F' MFR
    * @param i_flg_priority_home priority and home flags home for each mcdt
    * @param i_mcdt selected mcdt, requisitions and institutions
    * @param i_prof  professional, institution and software ids
    * @param i_id_sched
    * @param i_problems Referral problems identifiers
    * @param i_problems_desc Referral problems descriptions
    * @param i_dt_problem_begin P1 detail
    * @param i_detail P1 detail info. For each detail: [id_detail|flg_type|text|flg|id_group]
    * @param i_diagnosis P1 diagnosis
    * @param i_completed
    * @param   i_id_tasks           Referral tasks needed for (S)cheduling. [ID_TASK|ID_GROUP]
    * @param   i_id_info            Referral tasks needed for (C)onsultation. [ID_TASK|ID_GROUP]
    * @param o_id_external_request
    * @param o_flg_show
    * @param o_msg
    * @param o_msg_title
    * @param o_button
    * @param o_error an error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Joana Barroso
    * @version 2.4.3
    * @since   17-04-2008
    */
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

    /**
    * Gets request detail
    *
    * @param   I_LANG             Language associated to the professional executing the request
    * @param   I_PROF             Professional, institution and software ids
    * @param   i_id_ext_req       External request id
    * @param   i_status_detail    Detail status returned: {*} 'A' Active {*} 'C' Canceled {*} 'O' Outdated {*} null all details
    * @param   i_flg_labels       Indicates if labels are returned: {*} 'Y' Returns lables {*} 'N' otherwise
    * @param   o_patient          Referral patient general data
    * @param   O_DETAIL           Request general data
    * @param   O_TEXT             P1 information detail: Reason, Symptomology, Progress, History, Family history, Objective exam
    *                                  Diagnostic exams and Notes (mcdts)
    * @param   O_PROBLEM
    * @param   O_DIAGNOSIS
    * @param   O_MCDT
    * @param   O_NEEDS
    * @param   O_INFO
    * @param   O_NOTES_STATUS
    * @param   O_NOTES_STATUS_DET
    * @param   o_answer
    * @param   O_TITLE_STATUS
    * @param   O_EDITABLE
    * @param   O_CAN_CANCEL 'Y' if the request can be canceled, 'N' otherwise
    * @param   o_fields_rank       Cursor with field names and ranks
    *
    * @param   O_ERROR
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.1
    * @since   03-11-2006
    */
    FUNCTION get_p1_detail_new
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          profissional,
        i_id_ext_req    IN p1_external_request.id_external_request%TYPE,
        i_status_detail IN p1_detail.flg_status%TYPE,
        i_flg_labels    IN VARCHAR2 DEFAULT pk_ref_constant.g_no,
        --o_patient          OUT pk_types.cursor_type,
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
        o_editable         OUT VARCHAR2,
        o_can_cancel       OUT VARCHAR2,
        o_ref_comments     OUT pk_types.cursor_type,
        o_fields_rank      OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_p1_healthcare_insurance
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_ext_req            IN p1_external_request.id_external_request%TYPE,
        i_root_name             IN VARCHAR2,
        i_req_det               IN exam_req_det.id_exam_req_det%TYPE DEFAULT NULL,
        o_id_pat_health_plan    OUT exam_req_det.id_pat_health_plan%TYPE,
        o_id_pat_exemption      OUT exam_req_det.id_pat_exemption%TYPE,
        o_id_health_plan_entity OUT health_plan_entity.id_health_plan_entity%TYPE,
        o_num_health_plan       OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_p1_detail_html
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_ext_req    IN p1_external_request.id_external_request%TYPE,
        i_status_detail IN p1_detail.flg_status%TYPE,
        o_detail        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_p1_mcdts
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_ext_req IN p1_external_request.id_external_request%TYPE,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_p1_order_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER, -- edit, new, submit
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_idx            IN NUMBER DEFAULT 1,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_value          IN table_table_varchar,
        i_value_desc     IN table_table_varchar,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value;

    /**
    * Get cancel reason codes list
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF id professional, institution and software    
    * @param   o_data return data
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Ss
    * @version 1.0
    * @since   17-10-2007
    */
    FUNCTION get_cancel_reasons
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_reasons OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_cancel_reasons
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_p1_flg_type VARCHAR,
        o_reasons     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancel referral
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof id professional, institution and software    
    * @param   i_ext_req referral id    
    * @param   i_id_patient patient id
    * @param   i_id_episode episode id        
    * @param   i_notes cancelation notes episode id    
    * @param   i_reason cancelation reason code    
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Ss
    * @version 1.0
    * @since   17-10-2007
    */
    FUNCTION cancel_external_request
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_ext_req    IN p1_external_request.id_external_request%TYPE,
        i_mcdts      IN table_number,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_notes      IN VARCHAR2,
        i_reason     IN p1_reason_code.id_reason_code%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Changes request status after scheduling
    *
    * @param   i_lang idioma
    * @param   i_prof professional id, institution and software for the professional that schedules
    * @param   i_ext_req external request id
    * @param   i_schedule schedule id
    * @param   i_reschedule Y - it is a reschedule, N - Otherwise
    * @param   i_date         Date of status change
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   31-07-2008
    */
    FUNCTION set_status_scheduled
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_ext_req    IN p1_external_request.id_external_request%TYPE,
        i_schedule   IN schedule.id_schedule%TYPE,
        i_reschedule IN VARCHAR,
        i_date       IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Changes request status after schedule cancelation
    *
    * @param   i_lang              Idioma
    * @param   i_prof              Professional id, institution and software for the professional that schedules
    * @param   i_ext_req           External request id
    * @param   i_notes             Cancelation notes
    * @param   i_date              Date of status change
    * @param   i_reason_code       Referral reason code            
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   31-08-2007
    */
    FUNCTION cancel_schedule
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_ext_req     IN p1_external_request.id_external_request%TYPE,
        i_notes       IN VARCHAR2,
        i_date        IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        i_reason_code IN p1_reason_code.id_reason_code%TYPE DEFAULT NULL,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Updates referral status
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof id professional, institution and software
    * @param   i_ext_req referral id
    * @param   i_id_sch episode id
    * @param   i_status (S)chedule, (E)fectivation, (M)ailed, appointment (C)anceled  and (F)ailed appointment
    * @param   i_notes notes
    * @param   i_reschedule Y if reschedule, N Otherwise
    * @param   i_id_reason_code  
    * @param   i_date         Date of status change
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   31-07-2008
    */
    FUNCTION update_referral_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ext_req        IN NUMBER,
        i_id_sch         IN schedule.id_schedule%TYPE,
        i_status         IN VARCHAR2,
        i_notes          IN VARCHAR2,
        i_reschedule     IN VARCHAR2,
        i_id_reason_code IN p1_reason_code.id_reason_code%TYPE DEFAULT NULL,
        i_date           IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates lab tests order and creates/updates a referral request
    *
    * @param i_lang                   Language associated to the professional executing the request
    * @param i_prof                   Professional, institution and software ids
    * @param i_patient                Patient identifier
    * @param i_episode                Episode identifier
    * @param i_analysis_req           Array of lab test order identifiers
    * @param i_analysis_req_det       Array of lab test order detail identifiers
    * @param i_dt_begin               Array of dates for the lab test to be performed
    * @param i_analysis               Array of lab test identifiers
    * @param i_analysis_group         Array of lab test identifiers in a panel (always empty array)
    * @param i_flg_type               Array of types of the lab test: A - Lab test; G - group of lab tests
    * @param i_prof_order             Array of professionals that ordered the lab test (co-sign)
    * @param i_codification           Array of lab test codification identifiers
    * @param i_clinical_decision_rule Array of lab test clinical decision rule id    
    * @param i_ext_req                Referral identifier
    * @param i_dt_modified            Last modification date
    * @param i_req_type               Referral type
    * @param i_req_flg_type           Referral flag type
    * @param i_flg_priority_home      Referral flags: priority and home for each MCDT prescription
    * @param i_mcdt                   MCDT prescription info. For each MCDT: [id_mcdt|id_req_det|id_institution_dest|amount|id_sample_type]
    * @param i_problems               Referral problems identifiers info
    * @param i_problems_desc          Referral problems descriptions info
    * @param i_dt_problem_begin       Problem begin date
    * @param i_detail                 Referral detail info. For each detail: [id_detail|flg_type|text|flg|id_group]
    * @param i_req_diagnosis          Referral diagnosis info
    * @param i_completed              Flag indicating if referral is completed or not.
    * @param i_id_task                Referral tasks needed for (S)cheduling. [ID_TASK|ID_GROUP|ID_OP], ID_OP: 0- delete, 1- insert
    * @param i_id_info                Referral tasks needed for (C)onsultation. [ID_TASK|ID_GROUP|ID_OP], ID_OP: 0- delete, 1- insert
    * @param i_ref_completion         Referral completion option identifier
    * @param o_flg_show               Indicates if there is information to be shown
    * @param o_msg_req                Message to be shown
    * @param o_msg                    Message indicating same procedures were recently prescribed
    * @param o_msg_title              Message title
    * @param o_button                 Available buttons code (No, Read, Confirm, combinations)    
    * @param o_id_external_request    Array of referral identifiers created
    * @param o_error                  Error message
    *
    * @value i_flg_type               {*} 'A' - Lab test {*} 'G' - group of lab tests
    * @value i_req_type               {*} 'M' Manual {*} 'P' Using clinical protocol    
    * @value i_req_flg_type           {*} 'A' Lab test
    * @value i_completed              {*} 'Y' is completed {*} 'N' otherwise
    *
    * @return                         TRUE if sucess, FALSE otherwise
    * @author                         Joana Barroso
    * @version                        0.1
    * @since                          2011/04/20
    */
    FUNCTION create_lab_test_order
    (
        i_lang                   IN language.id_language%TYPE, --1
        i_prof                   IN profissional,
        i_patient                IN patient.id_patient%TYPE,
        i_episode                IN episode.id_episode%TYPE,
        i_analysis_req           IN table_number, -- 5
        i_analysis_req_det       IN table_number,
        i_dt_begin               IN table_varchar,
        i_analysis               IN table_number,
        i_analysis_group         IN table_table_varchar,
        i_flg_type               IN table_varchar, --10
        i_prof_order             IN table_number,
        i_codification           IN table_number,
        i_clinical_decision_rule IN table_number,
        -- Referral parameters
        i_ext_req           IN p1_external_request.id_external_request%TYPE,
        i_dt_modified       IN VARCHAR2, --15
        i_req_type          IN p1_external_request.req_type%TYPE,
        i_req_flg_type      IN p1_external_request.flg_type%TYPE, -- tipo 'A'
        i_flg_priority_home IN table_table_varchar,
        i_mcdt              IN table_table_number,
        i_problems          IN CLOB, --20
        i_dt_problem_begin  IN VARCHAR2,
        i_detail            IN table_table_varchar,
        i_req_diagnosis     IN CLOB, -- 25
        i_completed         IN VARCHAR2,
        i_id_tasks          IN table_table_number,
        i_id_info           IN table_table_number,
        i_ref_completion    IN ref_completion.id_ref_completion%TYPE,
        i_consent           IN VARCHAR2, --30
        -- End of referral parameters
        o_flg_show  OUT VARCHAR2,
        o_msg_req   OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        -- referral requests created
        o_id_external_request OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_lab_test_order_internal
    (
        i_lang                      IN language.id_language%TYPE, --1
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_episode                   IN episode.id_episode%TYPE,
        i_analysis_req              IN table_number, -- 5
        i_analysis_req_det          IN table_number,
        i_dt_begin                  IN table_varchar,
        i_analysis                  IN table_number,
        i_analysis_group            IN table_table_varchar,
        i_flg_type                  IN table_varchar, --10
        i_prof_order                IN table_number,
        i_codification              IN table_number,
        i_clinical_decision_rule    IN table_number,
        i_reason                    IN table_varchar,
        i_complementary_information IN table_varchar,
        -- Referral parameters
        i_ext_req           IN p1_external_request.id_external_request%TYPE,
        i_dt_modified       IN VARCHAR2, --15
        i_req_type          IN p1_external_request.req_type%TYPE,
        i_req_flg_type      IN p1_external_request.flg_type%TYPE, -- tipo 'A'
        i_flg_priority_home IN table_table_varchar,
        i_mcdt              IN table_table_number,
        i_problems          IN CLOB, --20
        i_dt_problem_begin  IN VARCHAR2,
        i_detail            IN table_table_varchar,
        i_req_diagnosis     IN CLOB, -- 25
        i_completed         IN VARCHAR2,
        i_id_tasks          IN table_table_number,
        i_id_info           IN table_table_number,
        i_ref_completion    IN ref_completion.id_ref_completion%TYPE,
        i_consent           IN VARCHAR2, --30
        --Health insurance
        i_health_plan     IN table_number DEFAULT NULL,
        i_exemption       IN table_number DEFAULT NULL,
        i_id_fam_rel      IN family_relationship.id_family_relationship%TYPE DEFAULT NULL,
        i_fam_rel_spec    IN VARCHAR2 DEFAULT NULL,
        i_name_first_rel  IN VARCHAR2 DEFAULT NULL,
        i_name_middle_rel IN VARCHAR2 DEFAULT NULL,
        i_name_last_rel   IN VARCHAR2 DEFAULT NULL,
        -- End of referral parameters
        o_flg_show  OUT VARCHAR2,
        o_msg_req   OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        -- referral requests created
        o_id_external_request OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates exams order and creates/updates referral request
    *
    * @param i_lang                   Language associated to the professional executing the request
    * @param i_prof                   Professional, institution and software ids
    * @param i_patient                Patient identifier
    * @param i_episode                Episode identifier
    * @param i_dt_begin               Array of dates of the exam to be performed
    * @param i_exam                   Array of exam identifiers
    * @param i_exam_req               Array of exam order identifiers
    * @param i_exam_req_det           Array of exam order details identifiers
    * @param i_flg_type               Array of types of the exam
    * @param i_dt_order               Array of dates of the exam order (co-sign)
    * @param i_codification           Array of exam codification identifiers
    * @param i_clinical_decision_rule Array of exam clinical decision rule id    
    * @param i_flg_laterality         Array of exam lateralities
    * @param i_ext_req                Referral identifier
    * @param i_dt_modified            Last modification date
    * @param i_req_type               Referral type
    * @param i_req_flg_type           Referral flag type
    * @param i_flg_priority_home      Referral flags: priority and home for each MCDT prescription
    * @param i_mcdt                   MCDT prescription info. For each MCDT: [id_mcdt|id_req_det|id_institution_dest|amount]
    * @param i_problems               Referral problems identifier info
    * @param i_problems_desc          Referral problems descriptions info
    * @param i_dt_problem_begin       Problem begin date
    * @param i_detail                 Referral detail info. For each detail: [id_detail|flg_type|text|flg|id_group]
    * @param i_req_diagnosis          Referral diagnosis info
    * @param i_completed              Flag indicating if referral is completed or not
    * @param i_id_task                Referral tasks needed for (S)cheduling. [ID_TASK|ID_GROUP|ID_OP], ID_OP: 0- delete, 1- insert
    * @param i_id_info                Referral tasks needed for (C)onsultation. [ID_TASK|ID_GROUP|ID_OP], ID_OP: 0- delete, 1- insert
    * @param i_ref_completion         Referral completion option identifier
    * @param o_flg_show               Indicates if there is information to be shown
    * @param o_msg_req                Message to be shown
    * @param o_msg                    Message indicating same procedures were recently prescribed
    * @param o_msg_title              Message title    
    * @param o_exam_req_array         Array of exam orders identifiers related to the referral
    * @param o_button                 Available buttons code (No, Read, Confirm, combinations)    
    * @param o_id_external_request    Array of referral identifiers created/updated
    * @param o_error                  Error message
    *
    * @value i_flg_type               {*} 'E' - exam {*} 'G' - group of exams
    * @value i_req_type               {*} 'M' Manual {*} 'P' Using clinical protocol    
    * @value i_req_flg_type           {*} 'I' Image {*} 'E' Exam
    * @value i_completed              {*} 'Y' is completed {*} 'N' otherwise
    *    
    * @return                         TRUE if sucess, FALSE otherwise
    * @author                         Joana Barroso
    * @version                        0.1
    * @since                          2011/04/20
    */
    FUNCTION create_exam_order
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_patient                IN patient.id_patient%TYPE,
        i_episode                IN exam_req.id_episode%TYPE,
        i_dt_begin               IN table_varchar, --5
        i_exam                   IN table_number,
        i_exam_req               IN table_number, --exam_req.id_exam_req%TYPE,
        i_exam_req_det           IN table_number,
        i_flg_type               IN table_varchar,
        i_dt_order               IN table_varchar, --10
        i_codification           IN table_number,
        i_clinical_decision_rule IN table_number,
        i_flg_laterality         IN table_varchar DEFAULT NULL,
        -- Referral parameters
        i_ext_req           IN p1_external_request.id_external_request%TYPE,
        i_dt_modified       IN VARCHAR2, --15
        i_req_type          IN p1_external_request.req_type%TYPE,
        i_req_flg_type      IN p1_external_request.flg_type%TYPE,
        i_flg_priority_home IN table_table_varchar,
        i_mcdt              IN table_table_number,
        i_problems          IN CLOB, --20
        i_dt_problem_begin  IN VARCHAR2,
        i_detail            IN table_table_varchar,
        i_req_diagnosis     IN CLOB,
        i_completed         IN VARCHAR2,
        i_id_tasks          IN table_table_number, --25
        i_id_info           IN table_table_number,
        i_ref_completion    IN ref_completion.id_ref_completion%TYPE,
        i_consent           IN VARCHAR2,
        -- End of referral parameters
        o_flg_show       OUT VARCHAR2,
        o_msg_req        OUT VARCHAR2,
        o_msg            OUT VARCHAR2, --30
        o_msg_title      OUT VARCHAR2,
        o_exam_req_array OUT table_number,
        o_button         OUT VARCHAR2,
        -- referral requests created
        o_id_external_request OUT table_number,
        o_error               OUT t_error_out --35
    ) RETURN BOOLEAN;

    FUNCTION create_exam_order_internal
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_episode                   IN exam_req.id_episode%TYPE,
        i_dt_begin                  IN table_varchar, --5
        i_exam                      IN table_number,
        i_exam_req                  IN table_number, --exam_req.id_exam_req%TYPE,
        i_exam_req_det              IN table_number,
        i_flg_type                  IN table_varchar,
        i_dt_order                  IN table_varchar, --10
        i_codification              IN table_number,
        i_clinical_decision_rule    IN table_number,
        i_flg_laterality            IN table_varchar DEFAULT NULL,
        i_reason                    IN table_varchar,
        i_complementary_information IN table_varchar,
        -- Referral parameters
        i_ext_req           IN p1_external_request.id_external_request%TYPE,
        i_dt_modified       IN VARCHAR2, --15
        i_req_type          IN p1_external_request.req_type%TYPE,
        i_req_flg_type      IN p1_external_request.flg_type%TYPE,
        i_flg_priority_home IN table_table_varchar,
        i_mcdt              IN table_table_number,
        i_problems          IN CLOB, --20
        i_dt_problem_begin  IN VARCHAR2,
        i_detail            IN table_table_varchar,
        i_req_diagnosis     IN CLOB,
        i_completed         IN VARCHAR2,
        i_id_tasks          IN table_table_number, --25
        i_id_info           IN table_table_number,
        i_ref_completion    IN ref_completion.id_ref_completion%TYPE,
        i_consent           IN VARCHAR2,
        --Health insurance
        i_health_plan     IN table_number DEFAULT NULL,
        i_exemption       IN table_number DEFAULT NULL, --30   
        i_id_fam_rel      IN family_relationship.id_family_relationship%TYPE DEFAULT NULL,
        i_fam_rel_spec    IN VARCHAR2 DEFAULT NULL,
        i_name_first_rel  IN VARCHAR2 DEFAULT NULL,
        i_name_middle_rel IN VARCHAR2 DEFAULT NULL,
        i_name_last_rel   IN VARCHAR2 DEFAULT NULL,
        -- End of referral parameters
        o_flg_show       OUT VARCHAR2,
        o_msg_req        OUT VARCHAR2,
        o_msg            OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_exam_req_array OUT table_number,
        o_button         OUT VARCHAR2,
        -- referral requests created
        o_id_external_request OUT table_number,
        o_error               OUT t_error_out --35
    ) RETURN BOOLEAN;

    /**
    * Creates a new prescription for one or more procedures and creates/updates the referral request
    *    
    * @param i_lang                   Language associated to the professional executing the request
    * @param i_prof                   Professional, institution and software ids
    * @param i_episode                Episode identifier
    * @param i_patient                Patient identifier    
    * @param i_intervention           Array of procedures identifiers (ID_INTERVENTION)
    * @param i_interv_type            Array of procedure type    
    * @param i_interval               Array of interval between executions
    * @param i_num_take               Array of number of executions
    * @param i_dt_begin               Array of start dates
    * @param i_dt_end                 Array of end dates
    * @param i_notes                  Array of prescription notes
    * @param i_diagnosis              Array of array of diagnoses
    * @param i_prof_order             Array of professionals who ordered the procedures
    * @param i_dt_order               Array of order dates
    * @param i_test                   Test for recent prescriptions of the same procedure(s)
    * @param i_codification           Array of prescription codification identifiers
    * @param i_flg_laterality         Array of prescription lateralities
    * @param i_id_cdr_call            Rule event identifier
    * @param i_ext_req                Referral identifier
    * @param i_dt_modified            Last modification date
    * @param i_req_type               Referral type
    * @param i_req_flg_type           Referral flag type
    * @param i_flg_priority_home      Referral flags: priority and home for each MCDT prescription
    * @param i_mcdt                   MCDT prescription info. For each MCDT: [id_mcdt|id_req_det|id_institution_dest|amount]
    * @param i_problems               Referral problems identifier info
    * @param i_problems_desc          Referral problems descriptions info
    * @param i_dt_problem_begin       Problem begin date
    * @param i_detail                 Referral detail info. For each detail: [id_detail|flg_type|text|flg|id_group]
    * @param i_req_diagnosis          Referral diagnosis info
    * @param i_completed              Flag indicating if referral is completed or not
    * @param i_id_task                Referral tasks needed for (S)cheduling. [ID_TASK|ID_GROUP|ID_OP], ID_OP: 0- delete, 1- insert
    * @param i_id_info                Referral tasks needed for (C)onsultation. [ID_TASK|ID_GROUP|ID_OP], ID_OP: 0- delete, 1- insert
    * @param i_ref_completion         Referral completion option identifier
    * @param o_flg_show               Indicates if there is information to be shown
    * @param o_msg                    Message indicating same procedures were recently prescribed
    * @param o_msg_title              Message title
    * @param o_button                 Available buttons code (No, Read, Confirm, combinations)    
    * @param o_id_interv_presc_det    Array of prescription identifiers
    * @param o_id_external_request    Array of referral identifiers created/updated
    * @param o_error                  Error message
    *
    * @value i_req_type               {*} 'M' Manual {*} 'P' Using clinical protocol    
    * @value i_req_flg_type           {*} 'P' Procedure
    * @value i_completed              {*} 'Y' is completed {*} 'N' otherwise
    *    
    * @return                         TRUE if sucess, FALSE otherwise
    * @author                         Tércio Soares - JTS
    * @version                        0.1
    * @since                          2008/08/20
    */
    FUNCTION create_interv_presc
    (
        i_lang                   IN language.id_language%TYPE, --1 
        i_prof                   IN profissional,
        i_id_episode             IN episode.id_episode%TYPE,
        i_id_patient             IN patient.id_patient%TYPE,
        i_intervention           IN table_number, --5
        i_dt_begin               IN table_varchar,
        i_dt_order               IN table_varchar,
        i_codification           IN table_number,
        i_flg_laterality         IN table_varchar DEFAULT NULL,
        i_clinical_decision_rule IN table_number, --10
        -- Referral parameters    
        i_ext_req           IN p1_external_request.id_external_request%TYPE,
        i_dt_modified       IN VARCHAR2,
        i_req_type          IN p1_external_request.req_type%TYPE,
        i_req_flg_type      IN p1_external_request.flg_type%TYPE, -- tipo 'P'
        i_flg_priority_home IN table_table_varchar, --15
        i_mcdt              IN table_table_number,
        i_problems          IN CLOB,
        i_dt_problem_begin  IN VARCHAR2,
        i_detail            IN table_table_varchar, --20
        i_req_diagnosis     IN CLOB,
        i_completed         IN VARCHAR2,
        i_id_tasks          IN table_table_number,
        i_id_info           IN table_table_number, --25
        i_ref_completion    IN ref_completion.id_ref_completion%TYPE,
        i_consent           IN VARCHAR2,
        -- End of referral parameters
        o_flg_show            OUT VARCHAR2,
        o_msg_req             OUT VARCHAR2,
        o_msg_title           OUT VARCHAR2,
        o_id_interv_presc_det OUT table_number, --30
        -- referral requests created
        o_id_external_request OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_interv_presc_internal
    (
        i_lang                      IN language.id_language%TYPE, --1 
        i_prof                      IN profissional,
        i_id_episode                IN episode.id_episode%TYPE,
        i_id_patient                IN patient.id_patient%TYPE,
        i_intervention              IN table_number, --5
        i_dt_begin                  IN table_varchar,
        i_dt_order                  IN table_varchar,
        i_codification              IN table_number,
        i_flg_laterality            IN table_varchar DEFAULT NULL,
        i_clinical_decision_rule    IN table_number, --10
        i_reason                    IN table_varchar,
        i_complementary_information IN table_varchar,
        -- Referral parameters    
        i_ext_req           IN p1_external_request.id_external_request%TYPE,
        i_dt_modified       IN VARCHAR2,
        i_req_type          IN p1_external_request.req_type%TYPE,
        i_req_flg_type      IN p1_external_request.flg_type%TYPE, -- tipo 'P'
        i_flg_priority_home IN table_table_varchar, --15
        i_mcdt              IN table_table_number,
        i_problems          IN CLOB,
        i_dt_problem_begin  IN VARCHAR2,
        i_detail            IN table_table_varchar, --20
        i_req_diagnosis     IN CLOB,
        i_completed         IN VARCHAR2,
        i_id_tasks          IN table_table_number,
        i_id_info           IN table_table_number, --25
        i_ref_completion    IN ref_completion.id_ref_completion%TYPE,
        i_consent           IN VARCHAR2,
        --Health insurance
        i_health_plan     IN table_number DEFAULT NULL,
        i_exemption       IN table_number DEFAULT NULL,
        i_id_fam_rel      IN family_relationship.id_family_relationship%TYPE DEFAULT NULL,
        i_fam_rel_spec    IN VARCHAR2 DEFAULT NULL,
        i_name_first_rel  IN VARCHAR2 DEFAULT NULL,
        i_name_middle_rel IN VARCHAR2 DEFAULT NULL,
        i_name_last_rel   IN VARCHAR2 DEFAULT NULL,
        -- End of referral parameters
        o_flg_show            OUT VARCHAR2,
        o_msg_req             OUT VARCHAR2,
        o_msg_title           OUT VARCHAR2,
        o_id_interv_presc_det OUT table_number, --30
        -- referral requests created
        o_id_external_request OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates a new prescription for one or more procedures and creates/updates tge referral request
    *    
    * @param i_lang                   Language associated to the professional executing the request
    * @param i_prof                   Professional, institution and software ids
    * @param i_id_patient             Patient identifier
    * @param i_id_episode             Episode identifier
    * @param i_id_rehab_area_interv   Array of intervention identifiers
    * @param i_id_rehab_sch_need      Array of intervention schedule needs
    * @param i_exec_per_session       Array of number of executions per treeatment
    * @param i_presc_notes            Array of treatment notes
    * @param i_sessions               Array of sessions
    * @param i_frequency              Array of frequencies
    * @param i_flg_frequency          Array of frequency units
    * @param i_flg_priority           Array of priorities
    * @param i_date_begin             Array of begin date
    * @param i_session_notes          Array of session notes
    * @param i_session_type           Array of session types
    * @param i_codification           Array of intervention codification identifiers
    * @param i_flg_laterality         Array of intervention lateralities        
    * @param i_ext_req                Referral identifier
    * @param i_dt_modified            Last modification date
    * @param i_req_type               Referral type
    * @param i_req_flg_type           Referral flag type
    * @param i_flg_priority_home      Referral flags: priority and home for each MCDT prescription
    * @param i_mcdt                   MCDT prescription info. For each MCDT: [id_mcdt|id_req_det|id_institution_dest|amount]
    * @param i_problems               Referral problems identifier info
    * @param i_problems_desc          Referral problems descriptions info
    * @param i_dt_problem_begin       Problem begin date
    * @param i_detail                 Referral detail info. For each detail: [id_detail|flg_type|text|flg|id_group]
    * @param i_req_diagnosis          Referral diagnosis info
    * @param i_completed              Flag indicating if referral is completed or not
    * @param i_id_tasks               Referral tasks needed for (S)cheduling. [ID_TASK|ID_GROUP|ID_OP], ID_OP: 0- delete, 1- insert
    * @param i_id_info                Referral tasks needed for (C)onsultation. [ID_TASK|ID_GROUP|ID_OP], ID_OP: 0- delete, 1- insert
    * @param i_ref_completion         Referral completion option identifier
    * @param o_flg_show               Indicates if there is information to be shown
    * @param o_msg                    Message indicating same procedures were recently prescribed
    * @param o_msg_title              Message title
    * @param o_button                 Available buttons code (No, Read, Confirm, combinations)    
    * @param o_id_rehab_presc         Array of rehab orders identifiers related to the referral
    * @param o_id_external_request    Array of referral identifiers created/updated
    * @param o_error                  Error message
    *
    * @value i_req_type               {*} 'M' Manual {*} 'P' Using clinical protocol    
    * @value i_req_flg_type           {*} 'F' MFR
    * @param i_completed              {*} 'Y' is completed {*} 'N' otherwise
    *
    * @return                         TRUE if sucess, FALSE otherwise
    * @author                         Joana Barroso
    * @version                        0.1
    * @since                          2008/10/08
    */
    FUNCTION create_rehab_presc
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_patient           IN patient.id_patient%TYPE,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_rehab_area_interv IN table_number, -- 5
        i_id_rehab_sch_need    IN table_number,
        i_exec_per_session     IN table_number,
        i_presc_notes          IN table_varchar,
        i_sessions             IN table_number,
        i_frequency            IN table_number, -- 10
        i_flg_frequency        IN table_varchar,
        i_flg_priority         IN table_varchar,
        i_date_begin           IN table_varchar,
        i_session_notes        IN table_varchar,
        i_session_type         IN table_varchar, -- 15
        i_codification         IN table_number,
        i_flg_laterality       IN table_varchar DEFAULT NULL,
        -- Referral parameters
        i_ext_req           IN p1_external_request.id_external_request%TYPE,
        i_dt_modified       IN VARCHAR2,
        i_req_type          IN p1_external_request.req_type%TYPE, -- 20
        i_req_flg_type      IN p1_external_request.flg_type%TYPE,
        i_flg_priority_home IN table_table_varchar,
        i_mcdt              IN table_table_number,
        i_problems          IN CLOB, -- 25
        i_dt_problem_begin  IN VARCHAR2,
        i_detail            IN table_table_varchar,
        i_req_diagnosis     IN CLOB,
        i_completed         IN VARCHAR2, -- 30
        i_id_tasks          IN table_table_number,
        i_id_info           IN table_table_number,
        i_ref_completion    IN ref_completion.id_ref_completion%TYPE,
        i_consent           IN VARCHAR2,
        -- End of referral parameters
        o_flg_show       OUT VARCHAR2,
        o_msg            OUT VARCHAR2, --35
        o_msg_title      OUT VARCHAR2,
        o_button         OUT VARCHAR2,
        o_id_rehab_presc OUT table_number,
        -- referral requests created
        o_id_external_request OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_rehab_presc_internal
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_patient                IN patient.id_patient%TYPE,
        i_id_episode                IN episode.id_episode%TYPE,
        i_id_rehab_area_interv      IN table_number, -- 5
        i_id_rehab_sch_need         IN table_number,
        i_exec_per_session          IN table_number,
        i_presc_notes               IN table_varchar,
        i_sessions                  IN table_number,
        i_frequency                 IN table_number, -- 10
        i_flg_frequency             IN table_varchar,
        i_flg_priority              IN table_varchar,
        i_date_begin                IN table_varchar,
        i_session_notes             IN table_varchar,
        i_session_type              IN table_varchar, -- 15
        i_codification              IN table_number,
        i_flg_laterality            IN table_varchar DEFAULT NULL,
        i_reason                    IN table_varchar,
        i_complementary_information IN table_varchar,
        -- Referral parameters
        i_ext_req           IN p1_external_request.id_external_request%TYPE,
        i_dt_modified       IN VARCHAR2,
        i_req_type          IN p1_external_request.req_type%TYPE, -- 20
        i_req_flg_type      IN p1_external_request.flg_type%TYPE,
        i_flg_priority_home IN table_table_varchar,
        i_mcdt              IN table_table_number,
        i_problems          IN CLOB, -- 25
        i_dt_problem_begin  IN VARCHAR2,
        i_detail            IN table_table_varchar,
        i_req_diagnosis     IN CLOB,
        i_completed         IN VARCHAR2, -- 30
        i_id_tasks          IN table_table_number,
        i_id_info           IN table_table_number,
        i_ref_completion    IN ref_completion.id_ref_completion%TYPE,
        i_consent           IN VARCHAR2,
        --Health insurance
        i_health_plan     IN table_number DEFAULT NULL, --35
        i_exemption       IN table_number DEFAULT NULL,
        i_id_fam_rel      IN family_relationship.id_family_relationship%TYPE DEFAULT NULL,
        i_fam_rel_spec    IN VARCHAR2 DEFAULT NULL,
        i_name_first_rel  IN VARCHAR2 DEFAULT NULL,
        i_name_middle_rel IN VARCHAR2 DEFAULT NULL,
        i_name_last_rel   IN VARCHAR2 DEFAULT NULL,
        -- End of referral parameters
        o_flg_show       OUT VARCHAR2,
        o_msg            OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2, --40
        o_button         OUT VARCHAR2,
        o_id_rehab_presc OUT table_number,
        -- referral requests created
        o_id_external_request OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Returns type of form to be used for printing the referral.   
    * If the health plan in use is "SNS" then return the SYS_CONFIG value for id REFERRAL_FULL_FORM.
    * Otherwise returns (B)lank form.
    *
    * @param      i_lang         professional language
    * @param      i_prof         professional id, institution and software
    * @param      i_pat          patient id
    * @param      o_format       B - "Blank page"; Y - Generate complete referral form; N - Print on top of referral form
    * @param      o_error        error message
    *
    * @return     boolean
    * @author     Joao Sa
    * @version    1.0
    * @since      2008/09/17
    * @modified    
    */
    FUNCTION get_referral_form_format
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_pat    IN patient.id_patient%TYPE,
        i_epis   IN episode.id_episode%TYPE,
        o_format OUT VARCHAR2,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    * Private Function. Check if is a validid codification
    *
    * @param i_lang          professional language
    * @param i_prof          professional id, institution and software
    * @param i_mcdt          analisis, exams ou intervention (id, id_institution, id_req
    * @param i_codification  mdct's codifications
    * @param o_error         
    * 
    * @return                TRUE if sucess, FALSE otherwise
    * @author                Joana Barroso
    * @version               1.0
    * @since                 2009/09/03    
    */

    FUNCTION check_codification_count
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_mcdt         IN table_number,
        i_codification IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_mcdts_description
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_ext_req   IN p1_external_request.id_external_request%TYPE,
        i_desc_type IN VARCHAR2
    ) RETURN CLOB;

    FUNCTION get_sp_description
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_ext_req   IN p1_external_request.id_external_request%TYPE,
        i_desc_type IN VARCHAR2
    ) RETURN CLOB;

    FUNCTION get_p1_cross_actions
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_subject             IN action.subject%TYPE,
        i_p1_external_request IN p1_external_request.id_external_request%TYPE,
        i_p1_exr_temp         IN table_number,
        i_from_state          IN table_varchar,
        o_actions             OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_p1_request
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN nurse_tea_req.id_episode%TYPE,
        i_id_patient           IN patient.id_patient%TYPE,
        i_root_name            IN VARCHAR2,
        i_tbl_records          IN table_number,
        i_tbl_ds_internal_name IN table_varchar DEFAULT NULL,
        i_tbl_real_val         IN table_table_varchar DEFAULT NULL,
        i_tbl_val_clob         IN table_table_clob DEFAULT NULL,
        i_ref_completion       IN ref_completion.id_ref_completion%TYPE,
        i_codification         IN codification.id_codification%TYPE,
        o_id_external_request  OUT table_number,
        o_id_requisition       OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_p1_order_for_edition
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER, -- edit, new, submit
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_idx            IN NUMBER DEFAULT 1,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_value          IN table_table_varchar,
        i_value_desc     IN table_table_varchar,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value;

    PROCEDURE init_params_list
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

END pk_p1_ext_sys;
/
