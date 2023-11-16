/*-- Last Change Revision: $Rev: 2028692 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:21 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_exam_external IS

    TYPE t_rec_exam_listview IS RECORD(
        id_exam_req         exam_req.id_exam_req%TYPE,
        id_exam_req_det     exam_req_det.id_exam_req_det%TYPE,
        id_exam             NUMBER(24),
        flg_status          VARCHAR2(3 CHAR),
        flg_time            VARCHAR2(2 CHAR),
        desc_exam           VARCHAR2(1000 CHAR),
        exam_cat            VARCHAR2(1000 CHAR),
        msg_notes           VARCHAR2(50 CHAR),
        notes               VARCHAR2(1000 CHAR),
        notes_patient       VARCHAR2(1000 CHAR),
        notes_technician    VARCHAR2(1000 CHAR),
        icon_name           VARCHAR2(200 CHAR),
        desc_diagnosis      VARCHAR2(1000 CHAR),
        priority            VARCHAR2(200 CHAR),
        hr_begin            VARCHAR2(200 CHAR),
        dt_begin            VARCHAR2(200 CHAR),
        to_be_perform       VARCHAR2(200 CHAR),
        desc_status         VARCHAR2(200 CHAR),
        status_string       VARCHAR2(200 CHAR),
        id_codification     NUMBER(24),
        id_task_dependency  NUMBER(24),
        flg_timeout         VARCHAR2(2 CHAR),
        avail_button_ok     VARCHAR2(2 CHAR),
        avail_button_cancel VARCHAR2(2 CHAR),
        avail_button_action VARCHAR2(2 CHAR),
        avail_button_read   VARCHAR2(2 CHAR),
        flg_current_episode VARCHAR2(2 CHAR),
        rank                NUMBER,
        dt_ord              VARCHAR2(50 CHAR),
        prof_order          VARCHAR2(200 CHAR),
        dt_order            VARCHAR2(200 CHAR),
        order_type          VARCHAR2(200 CHAR),
        co_sign_prof        VARCHAR2(200 CHAR),
        co_sign_date        VARCHAR2(50 CHAR),
        co_sign_notes       VARCHAR2(1000 CHAR));

    -- Ana Monteiro: 2008/11/14 - cursor utilizado para retornar informacao de exames
    TYPE t_cur_exam_listview IS REF CURSOR RETURN t_rec_exam_listview;

    TYPE t_exam_order IS RECORD(
        id_exam_req     NUMBER(24),
        id_exam_req_det NUMBER(24),
        flg_time        VARCHAR2(10),
        id_req_group    NUMBER(24));

    TYPE t_tbl_exam_order IS TABLE OF t_exam_order;

    /**
    * Types used in past history treatments most frequent
    */

    /*TYPE t_rec_exam_selection_list IS RECORD(
        id_exam               exam.id_exam%TYPE,
        desc_exam             pk_translation.t_desc_translation,
        desc_perform          sys_message.desc_message%TYPE,
        flg_clinical_question VARCHAR2(1 CHAR),
        flg_laterality_mcdt   VARCHAR2(1 CHAR),
        TYPE                  VARCHAR2(1 CHAR),
        rank                  exam.rank%TYPE);
    
    TYPE t_cur_exam_selection_list IS REF CURSOR RETURN t_rec_exam_selection_list;
    
    TYPE t_tbl_exam_selecion_list IS TABLE OF t_rec_exam_selection_list;*/

    /**
    * Types used in past history treatments search
    */

    /*TYPE t_rec_exam_search IS RECORD(
        id_exam                  exam.id_exam%TYPE,
        desc_exam                pk_translation.t_desc_translation,
        TYPE                     VARCHAR2(1 CHAR),
        desc_perform             sys_message.desc_message%TYPE,
        flg_clinical_question    VARCHAR2(1 CHAR),
        flg_laterality_mcdt      VARCHAR2(1 CHAR),
        doc_template_exam        doc_template.id_doc_template%TYPE,
        doc_template_exam_result doc_template.id_doc_template%TYPE);
    
    TYPE t_cur_exam_search IS REF CURSOR RETURN t_rec_exam_search;
    
    TYPE t_tbl_exam_search IS TABLE OF t_rec_exam_search;*/

    TYPE t_rec_exam_to_schedule IS RECORD(
        idpatient                NUMBER(24),
        iddepclinserv            NUMBER(24),
        idservice                NUMBER(24),
        idspeciality             NUMBER(24),
        idcontent                VARCHAR2(200 CHAR),
        flgtype                  VARCHAR2(4 CHAR),
        idrequisition            NUMBER(24),
        dtcreation               TIMESTAMP WITH LOCAL TIME ZONE,
        idusercreation           NUMBER(24),
        idinstitution            NUMBER(24),
        idresource               NUMBER(24),
        resourcetype             VARCHAR2(4 CHAR),
        dtsugested               TIMESTAMP WITH LOCAL TIME ZONE,
        dtbeginmin               TIMESTAMP WITH LOCAL TIME ZONE,
        dtbeginmax               TIMESTAMP WITH LOCAL TIME ZONE,
        flgcontacttype           VARCHAR2(4 CHAR),
        priority                 VARCHAR2(4 CHAR),
        idlanguage               NUMBER(24),
        idmotive                 NUMBER(24),
        motivetype               VARCHAR2(4000 CHAR),
        motivedescription        VARCHAR2(4000 CHAR),
        daylynumberdays          NUMBER(24),
        flgweeklyfriday          VARCHAR2(4 CHAR),
        flgweeklymonday          VARCHAR2(4 CHAR),
        flgweeklysaturday        VARCHAR2(4 CHAR),
        flgweeklysunday          VARCHAR2(4 CHAR),
        flgweeklythursday        VARCHAR2(4 CHAR),
        flgweeklytuesday         VARCHAR2(4 CHAR),
        flgweeklywednesday       VARCHAR2(4 CHAR),
        weeklynumberweeks        VARCHAR2(4 CHAR),
        monthlynumbermonths      NUMBER(24),
        monthlydaynumber         NUMBER(24),
        monthlyweekday           NUMBER(24),
        monthlyweeknumber        NUMBER(24),
        yearlyyearnumber         NUMBER(24),
        yearlymonthdaynumber     NUMBER(24),
        yearlymonthnumber        NUMBER(24),
        yearlyweekday            NUMBER(24),
        yearlyweeknumber         NUMBER(24),
        yearlyweekdaymonthnumber NUMBER(24),
        flgreccurencepattern     VARCHAR2(4 CHAR),
        recurrencebegindate      TIMESTAMP WITH LOCAL TIME ZONE,
        recurrenceenddate        TIMESTAMP WITH LOCAL TIME ZONE,
        recurrenceendnumber      NUMBER(24),
        sessionnumber            VARCHAR2(4 CHAR),
        frequencyunit            VARCHAR2(4 CHAR),
        frequency                VARCHAR2(4 CHAR),
        totalrecordnumber        NUMBER(24));

    TYPE t_cur_exam_to_schedule IS REF CURSOR RETURN t_rec_exam_to_schedule;

    TYPE t_rec_exam_result IS RECORD(
        id_exam_req_det exam_req_det.id_exam_req_det%TYPE,
        id_exam         exam.id_exam%TYPE,
        desc_exam       VARCHAR2(1000 CHAR),
        RESULT          CLOB,
        dt_req          VARCHAR2(200 CHAR));

    TYPE t_cur_exam_result IS REF CURSOR RETURN t_rec_exam_result;

    FUNCTION tf_exams_ea
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_visit      IN visit.id_visit%TYPE,
        i_cancelled  IN VARCHAR2,
        i_exam_type  IN exam.flg_type%TYPE,
        i_crit_type  IN VARCHAR2,
        i_start_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_status IN table_varchar DEFAULT NULL
    ) RETURN t_tbl_exams_ea;

    PROCEDURE episode___________________;

    FUNCTION get_exam_for_episode_timeline
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_type    IN VARCHAR2
    ) RETURN VARCHAR2;

    PROCEDURE reports___________________;

    FUNCTION get_exam_listview
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_exam_type    IN exam.flg_type%TYPE,
        i_flg_all_exam IN VARCHAR2 DEFAULT 'N',
        i_scope        IN NUMBER DEFAULT NULL,
        i_flg_scope    IN VARCHAR2 DEFAULT '',
        i_start_date   IN VARCHAR2 DEFAULT NULL,
        i_end_date     IN VARCHAR2 DEFAULT NULL,
        i_cancelled    IN VARCHAR2 DEFAULT NULL,
        i_crit_type    IN VARCHAR2 DEFAULT 'A',
        i_flg_status   IN table_varchar DEFAULT NULL,
        i_flg_rep      IN VARCHAR2 DEFAULT 'N',
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_exam_orders
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_exam_type               IN exam.flg_type%TYPE,
        i_flg_location            IN exam_req_det.flg_location%TYPE,
        i_flg_reports             IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_list                    OUT pk_types.cursor_type,
        o_exam_clinical_questions OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of exams with result for a patient within a visit
    *
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_patient        Patient id
    * @param     i_episode        Episode id
    * @param     o_list           Cursor
    * @param     o_error          Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/09/14
    */

    FUNCTION get_exam_result_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN exam_req.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns an exam detail
    *
    * @param     i_lang                      Language id
    * @param     i_prof                      Professional
    * @param     i_episode                   Episode id
    * @param     i_exam_req_det              Exam detail order id
    * @param     i_flg_report                Flag that indicates if the list is to be shown in the application or in a report
    * @param     o_exam_order                Cursor
    * @param     o_exam_co_sign              Cursor
    * @param     o_exam_clinical_questions   Cursor
    * @param     o_exam_perform              Cursor
    * @param     o_exam_result               Cursor
    * @param     o_exam_result_images        Cursor
    * @param     o_exam_doc                  Cursor
    * @param     o_exam_review               Cursor
    * @param     o_error                     Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/03/03
    */

    FUNCTION get_exam_detail
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_exam_req_det            IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_report              IN VARCHAR2 DEFAULT pk_exam_constant.g_no,
        o_exam_order              OUT pk_types.cursor_type,
        o_exam_co_sign            OUT pk_types.cursor_type,
        o_exam_clinical_questions OUT pk_types.cursor_type,
        o_exam_perform            OUT pk_types.cursor_type,
        o_exam_result             OUT pk_types.cursor_type,
        o_exam_result_images      OUT pk_types.cursor_type,
        o_exam_doc                OUT pk_types.cursor_type,
        o_exam_review             OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns an exam detail history
    *
    * @param     i_lang                      Language id
    * @param     i_prof                      Professional
    * @param     i_episode                   Episode id
    * @param     i_exam_req_det              Exam detail order id
    * @param     i_flg_report                Flag that indicates if the list is to be shown in the application or in a report
    * @param     o_exam_order                Cursor
    * @param     o_exam_co_sign              Cursor
    * @param     o_exam_clinical_questions   Cursor
    * @param     o_exam_perform              Cursor
    * @param     o_exam_result               Cursor
    * @param     o_exam_result_images        Cursor
    * @param     o_exam_doc                  Cursor
    * @param     o_exam_review               Cursor
    * @param     o_error                     Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.1
    * @since     2011/05/04
    */

    FUNCTION get_exam_detail_history
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_exam_req_det            IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_report              IN VARCHAR2 DEFAULT pk_exam_constant.g_no,
        o_exam_order              OUT pk_types.cursor_type,
        o_exam_co_sign            OUT pk_types.cursor_type,
        o_exam_clinical_questions OUT pk_types.cursor_type,
        o_exam_perform            OUT pk_types.cursor_type,
        o_exam_result             OUT pk_types.cursor_type,
        o_exam_result_images      OUT pk_types.cursor_type,
        o_exam_doc                OUT pk_types.cursor_type,
        o_exam_review             OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the print list job using print list job identifier 
    *
    * @param     i_lang                Language id
    * @param     i_prof                Professional
    * @param     i_id_print_list_job   Print list job identifier
    
    * @return    Print list job information
    *
    * @author    Ana Matos
    * @version   2.6.4.2.1
    * @since     2014/10/17
    */

    FUNCTION tf_get_print_job_info
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_print_list_job IN print_list_job.id_print_list_job%TYPE
    ) RETURN t_rec_print_list_job;

    /*
    * Returns the print list job using print list job identifier 
    *
    * @param     i_lang                     Language id
    * @param     i_prof                     Professional
    * @param     i_print_job_context_data   Print list job context
    * @param     i_tbl_print_list_jobs      Array of print list job identifiers
    
    * @return    Array of print list jobs that are similar
    *
    * @author    Ana Matos
    * @version   2.6.4.2.1
    * @since     2014/10/17
    */

    FUNCTION tf_compare_print_jobs
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_print_job_context_data IN print_list_job.context_data%TYPE,
        i_tbl_print_list_jobs    IN table_number
    ) RETURN table_number;

    FUNCTION get_exam_in_print_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_print_list_job IN print_list_job.id_print_list_job%TYPE
    ) RETURN print_list_job.context_data%TYPE;

    FUNCTION add_print_list_jobs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_exam_req_det    IN table_number,
        i_print_arguments IN table_varchar,
        o_print_list_job  OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_exam_print_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_type IN exam.flg_type%TYPE,
        o_options  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION tf_get_exam_to_print
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN table_varchar
    ) RETURN table_varchar;

    PROCEDURE co_sign___________________;

    /*
    * Returns the exam description
    *
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_exam_req_det   Exam order detail id
    * @param     i_co_sign_hist   Co sign id
    
    * @return    Clob
    *
    * @author    Cristina Oliveira
    * @version   2.6.5
    * @since     2015/01/09
    */

    FUNCTION get_exam_description
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        i_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN CLOB;

    /*
    * Returns the exam instructions
    *
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_exam_req_det   Exam order detail id
    * @param     i_co_sign_hist   Co sign id
    
    * @return    Clob
    *
    * @author    Cristina Oliveira
    * @version   2.6.5
    * @since     2015/01/09
    */

    FUNCTION get_exam_instructions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        i_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN CLOB;

    /*
    * Get the exam action description (Order; Cancelation)
    *
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_exam_req_det   Exam order detail id
    * @param     i_action         Type of action
    * @param     i_co_sign_hist   Co sign id
    
    * @return    String
    *
    * @author    Cristina Oliveira
    * @version   2.6.5
    * @since     2015/01/09
    */

    FUNCTION get_exam_action_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        i_action       IN co_sign.id_action%TYPE,
        i_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN VARCHAR2;

    /*
    * Get the exam's date to order
    *
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_exam_req_det   Exam order detail id
    * @param     i_co_sign_hist   Co sign id
    
    * @return    String
    *
    * @author    Ana Matos
    * @version   2.6.5
    * @since     2015/10/21
    */

    FUNCTION get_exam_date_to_order
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        i_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    PROCEDURE cdr_______________________;

    FUNCTION get_exam_id_content
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_exam IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_alias_translation
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_content       IN VARCHAR2,
        i_dep_clin_serv IN exam_alias.id_dep_clin_serv%TYPE
    ) RETURN VARCHAR2;

    FUNCTION check_exam_cdr
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_exam         IN VARCHAR2,
        i_date         IN exam_req.dt_begin_tstz%TYPE,
        o_exam_req_det OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE referral___________________;

    /*
    * Updates an exam laterality
    *
    * @param     i_lang             Language id
    * @param     i_prof             Professional
    * @param     i_exam_req_det     Exam order detail id
    * @param     i_flg_laterality   New flag laterality
    * @param     o_error            Error message
    
    * @return    string on success or error
    *
    * @author    Ana Matos
    * @version   2.6.1
    * @since     2012/09/04
    */

    FUNCTION update_exam_laterality
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_exam_req_det   IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_laterality IN exam_req_det.flg_laterality%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Updates an exam perform insitution
    *
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_exam_req_det       Exam order detail id
    * @param     i_exec_institution   New institution id
    * @param     o_error              Error message
    
    * @return    string on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/09/09
    */

    FUNCTION update_exam_institution
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_exam_req_det     IN exam_req_det.id_exam_req_det%TYPE,
        i_exec_institution IN exam_req_det.id_exec_institution%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Updates an exam referral status
    *
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_exam_req_det   Exam order detail id
    * @param     i_flg_referral   New flag referral
    * @param     o_error          Error message
    
    * @return    string on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/09/09
    */

    FUNCTION update_exam_referral
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_referral IN exam_req_det.flg_referral%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_exam_listview
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_exam_external.t_cur_exam_result,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE cpoe______________________;

    FUNCTION copy_exam_to_draft
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_task_request         IN cpoe_process_task.id_task_request%TYPE,
        i_task_start_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_task_end_timestamp   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_draft                OUT cpoe_process_task.id_task_request%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_exam_mandatory_field
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_id_exams_req_det IN exam_req_det.id_exam_req_det%TYPE
    ) RETURN VARCHAR2;

    FUNCTION check_exam_draft_conflict
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_draft        IN table_number,
        o_flg_conflict OUT table_varchar,
        o_msg_title    OUT table_varchar,
        o_msg_body     OUT table_varchar,
        o_msg_template OUT table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_exam_draft
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_has_draft OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_exam_draft_activation
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_draft         IN table_number,
        i_flg_commit    IN VARCHAR2,
        i_id_cdr_call   IN cdr_call.id_cdr_call%TYPE,
        o_created_tasks OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_exam_draft
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_draft   IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_exam_all_drafts
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_exam_task_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_task_request    IN table_number,
        i_filter_tstz     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_filter_status   IN table_varchar,
        i_flg_report      IN VARCHAR2 DEFAULT 'N',
        i_dt_begin        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_dt_end          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_flg_type        IN VARCHAR2,
        i_flg_out_of_cpoe IN VARCHAR2 DEFAULT 'N',
        i_flg_print_items IN VARCHAR2 DEFAULT 'N',
        i_cpoe_tab        IN VARCHAR2 DEFAULT 'A',
        o_task_list       OUT pk_types.cursor_type,
        o_plan_list       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_exam_actions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN cpoe_process_task.id_task_request%TYPE,
        o_action       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_order_plan_report
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_task_request  IN table_number,
        i_flg_type      IN VARCHAR2,
        i_cpoe_dt_begin IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_cpoe_dt_end   IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_plan_rep      OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE order_sets_________________;

    FUNCTION get_exam_req_det
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_exam_req_det OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_exam_task_title
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_request     IN exam_req.id_exam_req%TYPE,
        i_task_request_det IN exam_req_det.id_exam_req_det%TYPE,
        o_task_desc        OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_exam_task_instructions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_task_request      IN exam_req.id_exam_req%TYPE,
        i_task_request_det  IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_showdate      IN VARCHAR2 DEFAULT pk_exam_constant.g_yes,
        o_task_instructions OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets task description          
    *                                        
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_task_request   Request that identifies patient's task process 
    * @param     o_task_desc      Task description
    * @param     o_error          Error message
    
    * @return    true or false on success or error
    *                                                                            
    * @author    Filipe Silva                            
    * @version   v2.6.0.3                                   
    * @since     2010/05/13                                 
    */

    FUNCTION get_exam_task_description
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_exam_req_det  IN exam_req_det.id_exam_req_det%TYPE,
        o_exams_desc       OUT VARCHAR2,
        o_task_status_desc OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the status for a give exam order (ORDER TOOLS)
    *
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_exam_req       Exam  order id
    * @param     o_flg_status     Exam order status
    * @param     o_status_string  Exam order status string
    * @param     o_error          Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/09/09
    */

    FUNCTION get_exam_status
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_task_request  IN exam_req_det.id_exam_req_det%TYPE,
        o_flg_status    OUT VARCHAR2,
        o_status_string OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_exam_questionnaire
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN exam_req.id_exam_req%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_exam_date_limits
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_exam_task_id
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_request     IN exam_req.id_exam_req%TYPE,
        i_task_request_det IN exam_req_det.id_exam_req_det%TYPE,
        o_exam_id          OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_exam_request_task
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_task_request            IN table_number,
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar,
        i_order_type              IN table_number,
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        i_clinical_decision_rule  IN exam_req_det.id_cdr%TYPE,
        i_task_dependency         IN table_number,
        i_flg_task_dependency     IN table_varchar,
        o_exam_req                OUT table_number,
        o_exam_req_det            OUT table_table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_exam_copy_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN exam_req.id_exam_req%TYPE,
        o_exam_req     OUT exam_req.id_exam_req%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_exam_delete_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_exam_diagnosis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN table_number,
        i_diagnosis    IN pk_edis_types.rec_in_epis_diagnosis,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_exam_execute_time
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_exam_mandatory_field
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN exam_req.id_exam_req%TYPE,
        o_check        OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_exam_conflict
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_task_request IN exam_req.id_exam_req%TYPE,
        o_flg_conflict OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_exam_cancel
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN exam_req_det.id_exam_req_det%TYPE,
        o_flg_cancel   OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE tde_______________________;

    /*
    * Checks if the exam is still available to be ordered or not (ORDER TOOLS)
    *
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_patient        Patient id
    * @param     i_exam           Exams' id
    * @param     o_flg_conflict   Flag that indicates if there is a conflict or not
    * @param     o_error          Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/03/25
    */

    FUNCTION check_exam_conflict
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_exam         IN exam.id_exam%TYPE,
        o_flg_conflict OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Checks dependent task cancel permission (checks if i_prof can cancel     
    * this task)                                                              
    *                                                                         
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_task_request   Request that identifies patient's task 
    * @param     o_flg_cancel     Indicates if task can be canceled  
    * @value     o_flg_cancel     'Y' task can be canceled           
    * @param     o_error          Error message    
    
    * @return    true or false on success or error
    *                                                                           
    * @author    Filipe Silva                           
    * @version   v2.6.0.3                                  
    * @since     2010/05/26                                 
    */

    FUNCTION get_exam_cancel_permission
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        o_flg_cancel      OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Start dependent task (define start timestamp and put task in the beggining of workflow)            
    *                                        
    *@param  i_lang                    preferred language id   
    *@param  i_prof                    Professional struture
    *@param  i_task_request            Request that identifies patient's task process
    *@param  i_start_tstz              Interval for execution window 
    *
    *@param o_error                    error struture for exception handling
    *
    *@return boolean                   true on success, otherwise false
    *                                                                            
    * @author                          Filipe Silva                            
    * @version                         v2.6.0.3                                   
    * @since                           2010/05/13                                 
    */

    FUNCTION start_exam_task_req
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        i_start_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Cancels dependent task (task created by TDE order sets)
    *
    * @param     i_lang            Language id
    * @param     i_prof            Professional
    * @param     i_task_request    Exam detail order id
    * @param     i_reason          Cancel reason id
    * @param     i_reason_notes    Cancellation notes
    * @param     i_prof_order      Professional that ordered the exam cancelation (co-sign)
    * @param     i_dt_order        Date of the exam cancelation (co-sign)
    * @param     i_order_type      Type of cancelation (co-sign)
    * @param     i_transaction_id  Transaction id
    * @param     o_error           Error message
    
    * @return    true or false on success or error
    *
    * @author    Filipe Silva
    * @version   2.6.0.3
    * @since     2010/05/31
    */

    FUNCTION cancel_exam_task
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_request     IN tde_task_dependency.id_task_request%TYPE,
        i_reason           IN cancel_reason.id_cancel_reason%TYPE,
        i_reason_notes     IN VARCHAR2,
        i_prof_order       IN co_sign.id_prof_ordered_by%TYPE,
        i_dt_order         IN VARCHAR2,
        i_order_type       IN co_sign.id_order_type%TYPE,
        i_transaction_id   IN VARCHAR2,
        i_flg_cancel_event IN VARCHAR2 DEFAULT 'Y',
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets ongoing tasks (exams)
    *                                        
    * @param     i_lang          Language id
    * @param     i_prof          Professional
    * @param     i_patient       Patient id 
    
    * @return    tf_tasks_list   List of cancelable exams
    *                                                                            
    * @author    Carlos Nogueira                           
    * @version   v2.6.0.3                                   
    * @since     2010/05/28                                 
    */

    FUNCTION get_exam_ongoing_tasks
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN tf_tasks_list;

    /*
    * Suspends tasks (exams)
    *                                        
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     i_id_task      Exam requisition detail id
    * @param     i_flg_reason   Reason for the WF suspension: 'D' (Death)        
    * @param     o_msg_error    Error message to be shown in flash
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *                                                                            
    * @author    Carlos Nogueira                           
    * @version   v2.6.0.3                                   
    * @since     2010/05/28                                 
    */

    FUNCTION suspend_exam_task
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_task    IN NUMBER,
        i_flg_reason IN VARCHAR2,
        o_msg_error  OUT VARCHAR,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Reactivates tasks (exams)     
    *                                        
    * @param     i_lang        Language id
    * @param     i_prof        Professional
    * @param     i_id_task     Exam requisition detail id
    * @param     o_msg_error   Error message to be shown in flash
    * @param     o_error       Error message
    
    * @return    true or false on success or error
    *                                                                            
    * @author    Carlos Nogueira                           
    * @version   v2.6.0.3                                   
    * @since     2010/05/28                                 
    */

    FUNCTION reactivate_exam_task
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_task   IN NUMBER,
        o_msg_error OUT VARCHAR,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets task execution time          
    *                                        
    * @param     i_lang            Language id
    * @param     i_prof            Professional
    * @param     i_task_request    Request that identifies patient's task process 
    * @param     o_flg_time        Execution time
    * @param     o_flg_time_desc   Execution time description
    * @param     o_error           Error message
    
    * @return    true or false on success or error
    *                                                                            
    * @author    Filipe Silva                            
    * @version   v2.6.0.3                                   
    * @since     2010/06/22                                 
    */

    FUNCTION get_exam_task_execute_time
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_exam_req_det IN exam_req.id_exam_req%TYPE,
        o_flg_time        OUT VARCHAR2,
        o_flg_time_desc   OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * update task dependency engine state                                     
    *                                                                         
    * @param     i_lang              Language id
    * @param     i_prof              Professional
    * @param     i_exam_req          Request identifier                     
    * @param     i_flg_action        Update action (E - Execute, C - Cancel, F - Finish)                            
    * @param     i_task_dependency   task dependency identifier             
    * @param     i_reason            Cancel reason identifier               
    * @param     i_reason_notes      Cancel reason notes                    
    * @param     i_transaction_id    Transaction id                      
    * @param     o_error             Error message  
    
    * @return    true or false on success or error
    *                                                                            
    * @author    Gustavo Serrano                        
    * @version   v2.6.0.3                               
    * @since     2010/06/28                                
    */

    FUNCTION update_tde_task_state
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_exam_req_det    IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_action      IN VARCHAR2,
        i_task_dependency IN tde_task_dependency.id_task_dependency%TYPE DEFAULT NULL,
        i_reason          IN cancel_reason.id_cancel_reason%TYPE DEFAULT NULL,
        i_reason_notes    IN VARCHAR2 DEFAULT NULL,
        i_transaction_id  IN VARCHAR2 DEFAULT NULL,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE pregnancy_________________;

    FUNCTION tf_exam_pregnancy_info
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_exam_req_det    IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_last_result IN VARCHAR2 DEFAULT pk_exam_constant.g_no
    ) RETURN t_tbl_exams_pregnancy_result;

    FUNCTION tf_exam_pregnancy_info
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_exam_req_det    IN table_number,
        i_flg_last_result IN VARCHAR2 DEFAULT pk_exam_constant.g_no
    ) RETURN t_tbl_exams_pregnancy_result;

    FUNCTION tf_exam_pregnancy_result_info
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_exam_result IN exam_result.id_exam_result%TYPE
    ) RETURN t_tbl_exams_pregnancy_result;

    FUNCTION tf_exam_pregnancy_result_info
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_exam_result IN table_number
    ) RETURN t_tbl_exams_pregnancy_result;

    PROCEDURE single_page________________;

    /*
    * Get exams results description.
    *
    * @param     i_lang              Language id
    * @param     i_prof              Professional
    * @param     i_id_exam_result    Exam result ID
    * @param     o_description       Result description: exam name. (date ?DT_exam_results, result status), execution date and time     
    * @param     o_notes_result      Notes
    * @param     o_result_notes      Result notes
    * @param     o_interpretation    Interpretation
    * @param     o_error            Error message
    
    * @return    true or false on success or error
    *
    * @author    Sofia Mendes
    * @version   v2.6.2.0.7
    * @since     08/Feb/2012
    */

    FUNCTION get_exam_result_desc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_exam_result IN exam_result.id_exam_result%TYPE,
        i_flg_image_exam IN pk_types.t_flg_char,
        o_description    OUT CLOB,
        o_notes_result   OUT CLOB,
        o_result_notes   OUT CLOB,
        o_interpretation OUT CLOB,
        o_exec_date      OUT exam_req_det.start_time%TYPE,
        o_result         OUT pk_translation.t_desc_translation,
        o_report_date    OUT exam_req.dt_req_tstz%TYPE,
        o_inst_name      OUT CLOB,
        o_result_date    OUT exam_result.dt_exam_result_tstz%TYPE,
        o_exam_desc      OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns an exam order detail id for a given recurrende plan id
    *
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_order_recurrence   Exam order recurrence plan id
    * @param     o_exam_req_det       Exam order detail id
    * @param     o_error              Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   v2.6.5.0.3
    * @since     16/Jul/2015
    */

    FUNCTION get_exam_req_det_by_id_recurr
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_order_recurrence IN exam_req_det.id_order_recurrence%TYPE,
        o_exam_req_det     OUT exam_req_det.id_exam_req_det%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get exams order status.
    *
    * @param     i_lang              Language id
    * @param     i_prof              Professional
    * @param     i_id_exam_result    Exam request ID
    * @param     o_status            Status description     
    * @param     o_error            Error message
    
    * @return    true or false on success or error
    *
    * @author    Sofia Mendes
    * @version   v2.6.2.2
    * @since     28/Mar/2012
    */

    FUNCTION get_exam_status_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        o_status          OUT CLOB,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Verify if the exam for a given recurrence is finished 
    *
    * @param     i_lang                Language id
    * @param     i_prof                Professional
    * @param     i_order_recurrence    Exam order recurrence plan id
    
    * @return    Y or N
    *                                                                            
    * @author    Vanessa Barsottelli
    * @version   v2.6.2.0.6
    * @since     2012/03/15
    */

    FUNCTION is_exam_recurr_finished
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_order_recurrence IN exam_req_det.id_order_recurrence%TYPE
    ) RETURN VARCHAR2;

    PROCEDURE hand_off__________________;

    FUNCTION get_exam_by_status
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_flg_type IN exam.flg_type%TYPE,
        o_exam     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE discharge_summary____________;

    FUNCTION check_technical_exam
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_exam_exec_date
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE
    ) RETURN VARCHAR2;

    PROCEDURE flowsheets________________;

    /*
    * Gets Image and other exams for flow sheets that scheduled 
    *
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     i_scope        Scope type id
    * @param     i_scope_type   Scope type (E)pisode/(V)isit/(P)atient
    
    * @return    Type list
    *                        
    * @author    Cristina Oliveira
    * @version   2.6.4
    * @since     2014/12/23 
    */

    FUNCTION get_exam_flowsheets
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_type_scope IN VARCHAR2,
        i_id_scope   IN NUMBER
    ) RETURN t_coll_mcdt_flowsheets;

    PROCEDURE scheduler_________________;

    /*
    * Sets the status to a given exam
    *
    * @param     i_lang
    * @param     i_prof
    * @param     i_exam_req
    * @param     i_status
    * @param     o_error   Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.4.3
    * @since     2008/06/16
    */

    FUNCTION set_exam_status
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_exam_req      IN exam_req.id_exam_req%TYPE,
        i_status        IN exam_req.flg_status%TYPE,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE DEFAULT NULL,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list with the results of the user search (SCHEDULER)
    *
    * @param     i_lang                Language id
    * @param     i_prof                Professional
    * @param     i_id_market           Market id
    * @param     i_pat_search_values   Array with patient criteria and their values to search for
    * @param     i_ids_exam            Exams' id
    * @param     i_min_date            Suggested date (if exists) must be higher than i_min_date, if supplied
    * @param     i_min_date            Suggested date (if exists) must be lower than i_max_date, if supplied
    * @param     i_priorities          Priority of the exam order
    * @param     o_list                Cursor
    * @param     o_error               Error message
    
    * @return    true or false on success or error
    *
    * @author    Telmo Castro
    * @version   2.6
    * @since     2010/01/07
    */

    FUNCTION get_exam_search
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_market         IN market.id_market%TYPE,
        i_pat_search_values IN pk_utils.hashtable_pls_integer,
        i_ids_content       IN table_varchar,
        i_min_date          IN VARCHAR2,
        i_max_date          IN VARCHAR2,
        i_id_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE,
        i_ids_prof          IN table_number,
        i_ids_exam_cat      IN table_number,
        i_priorities        IN table_varchar,
        o_list              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get exam request to schedule
    * 
    * @param     i_lang             Language ID
    * @param     i_prof             Professional
    * @param     i_institution      Institution List
    * @param     i_patient          Patient ID
    * @param     i_flg_type         Exam Type (I)mage, (E)xams
    * @param     i_id_content       Exam Content ID
    * @param     i_id_department    Room Department ID
    * @param     i_pat_age_min      Patient age Min
    * @param     i_pat_age_max      Patient age Max
    * @param     i_pat_gender       Patient gender
    * @param     i_start            Start page
    * @param     i_offset           Number of records per page
    * @param     o_list             Cursor
    * @param     o_error            Error message 
    *
    * @return    true or false on success or error
    *                                                                            
    * @author    Vanessa Barsottelli
    * @version   v2.6.1
    * @since     2011/11/30
    */

    FUNCTION get_exam_request_to_schedule
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_institution   IN table_number,
        i_patient       IN patient.id_patient%TYPE DEFAULT NULL,
        i_flg_type      IN exam.flg_type%TYPE DEFAULT NULL,
        i_id_content    IN exam.id_content%TYPE DEFAULT NULL,
        i_id_department IN room.id_department%TYPE DEFAULT NULL,
        i_pat_age_min   IN patient.age%TYPE DEFAULT NULL,
        i_pat_age_max   IN patient.age%TYPE DEFAULT NULL,
        i_pat_gender    IN patient.gender%TYPE DEFAULT NULL,
        i_start         IN NUMBER DEFAULT NULL,
        i_offset        IN NUMBER DEFAULT NULL,
        o_list          OUT pk_exam_external.t_cur_exam_to_schedule,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE viewer___________________;

    /*
    * Returns an order rank used for sorting exams
    *
    * @param     i_flg_status          exam_req_det.flg_status of current exam
    * @param     i_flg_time            exam_req.flg_time of current exam
    * @param     i_dt_begin            exam_req.dt_begin_tstz of current exam
    * @param     i_id_episode_origin   exam_req.id_episode_origin of current exam
    *
    * @return    Number
    *
    * @author    Rui Baeta
    * @version   2.5
    * @since     2008/11/05
    */

    FUNCTION e_get_order_rank
    (
        i_flg_status        IN exam_req_det.flg_status%TYPE,
        i_flg_time          IN exam_req.flg_time%TYPE,
        i_dt_begin          IN exam_req.dt_begin_tstz%TYPE,
        i_id_episode_origin IN exam_req.id_episode_origin%TYPE
    ) RETURN NUMBER;

    /*
    * Returns exams ordered list for the viewer
    *
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_patient        Patient id
    * @param     i_translate      Translation code
    * @param     o_ordered_list   Cursor
    * @param     o_error          Error message
    
    * @return    true or false on success or error
    *
    * @author    Gustavo Serrano
    * @version   2.5
    * @since     2008/11/14
    */

    FUNCTION get_ordered_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_translate    IN VARCHAR2 DEFAULT NULL, --se ‘N?os código não serão traduzidos
        i_viewer_area  IN VARCHAR2,
        i_episode      IN episode.id_episode%TYPE,
        o_ordered_list OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns info about lab tests
    *
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_exam_req_det       Exams' order detail id
    * @param     o_ordered_list_det   Cursor
    * @param     o_error              Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.7.1
    * @since     2017/03/31
    */

    FUNCTION get_ordered_list_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_exam_req_det     IN exam_req_det.id_exam_req_det%TYPE,
        o_ordered_list_det OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns exams information for the viewer
    *
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     i_patient      Patient id
    * @param     o_num_occur    Number of lab tests for the given patient
    * @param     o_desc_first   First exams description
    * @param     o_dt_first     First exams order date
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *
    * @author    Gustavo Serrano
    * @version   2.5
    * @since     2008/11/14
    */

    FUNCTION get_count_and_first
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_viewer_area IN VARCHAR2,
        i_episode     IN episode.id_episode%TYPE,
        o_num_occur   OUT NUMBER,
        o_desc_first  OUT VARCHAR2,
        o_code_first  OUT VARCHAR2,
        o_dt_first    OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    *  Get current state of imaging exams for viewer checlist 
    *             
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     i_scope_type   Scope flag: 'P' - Patient; 'E' - Episode; 'V' - Visit
    * @param     i_episode      Episode id
    * @param     i_patient      Patient id
    *
    * @return    String
    * 
    * @author    Ana Matos
    * @version   2.7.0
    * @since     2016/10/27                         
    */

    FUNCTION get_imaging_viewer_checklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /*
    *  Get current state of other exams for viewer checlist 
    *             
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     i_scope_type   Scope flag: 'P' - Patient; 'E' - Episode; 'V' - Visit
    * @param     i_episode      Episode id
    * @param     i_patient      Patient id
    *
    * @return    String
    * 
    * @author    Ana Matos
    * @version   2.7.0
    * @since     2016/10/27                         
    */

    FUNCTION get_exams_viewer_checklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /*
    *  Get current state of exams for viewer checlist 
    *             
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     i_patient      Patient id
    * @param     i_episode      Episode id
    * @param     i_flg_type     Exam Type (I)mage, (E)xams
    * @param     i_scope_type   Scope flag: 'P' - Patient; 'E' - Episode; 'V' - Visit 
    *
    * @return    String
    * 
    * @author    Ana Matos
    * @version   2.7.0
    * @since     2016/10/27                         
    */

    FUNCTION get_exam_viewer_checklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_flg_type   IN exam.flg_type%TYPE,
        i_scope_type IN VARCHAR2
    ) RETURN VARCHAR2;

    PROCEDURE upd_viewer_ehr_ea
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    );

    /*
    * Updates the viewer_ehr_ea table for the given patients
    *
    * @param     i_lang                Language id
    * @param     i_prof                Professional
    * @param     i_table_id_patients   Patient id
    * @param     o_error               Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Coelho
    * @version   2.5
    * @since     2011/04/27
    */

    FUNCTION upd_viewer_ehr_ea_pat
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_table_id_patients IN table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE cda______________________;

    /*
    * Gets Image and other exams for CDA section that are pending and future scheduled 
    *
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     i_scope        Scope type id
    * @param     i_scope_type   Scope type (E)pisode/(V)isit/(P)atient
    * @param     o_exam_cda     Cursor with infomation about Image and other exams for the given scope
    * @param     o_error        Error message
    *
    * @return    true or false on success or error
    *                        
    * @author    Cristina Oliveira
    * @version   2.6.4
    * @since     2014/10/09 
    */

    FUNCTION get_exam_cda
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_type_scope IN VARCHAR2,
        i_id_scope   IN NUMBER,
        o_exam_cda   OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE crisis_machine_____________;

    FUNCTION tf_cm_imaging_episodes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_search_interval IN crisis_machine.interval_search%TYPE
    ) RETURN t_tbl_cm_episodes;

    FUNCTION tf_cm_imaging_episode_detail
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_schedule IN schedule.id_schedule%TYPE
    ) RETURN t_tbl_imaging_episodes;

    FUNCTION tf_cm_exams_episodes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_search_interval IN crisis_machine.interval_search%TYPE
    ) RETURN t_tbl_cm_episodes;

    FUNCTION tf_cm_exams_episode_detail
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_schedule IN schedule.id_schedule%TYPE
    ) RETURN t_tbl_other_exams_episodes;

    PROCEDURE match____________________;

    FUNCTION set_exam_match
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_episode_temp IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE reset_____________________;

    /*
    * Resets exams info by patient and /or episode
    *     
    * @param    i_lang      Language
    * @param    i_prof      Professional
    * @param    i_patient   Patient id
    * @param    i_episode   Episode id
    * @param    o_error     Error message
    
    * @return    true or false on success or error
    *
    * @author    Carlos Nogueira
    * @version   2.6.0.5
    * @since     2011/02/18
    */

    FUNCTION reset_exams
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN table_number,
        i_episode      IN table_number,
        io_transaction IN OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE system__________________;

    /*
    * Processes all pending orders changing the status from pending to requested
    * 
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/03/27
    */

    PROCEDURE process_exam_pending;

    FUNCTION inactivate_exams_tasks
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_inst        IN institution.id_institution%TYPE,
        i_flg_type    IN exam.flg_type%TYPE,
        i_ids_exclude IN OUT table_number,
        o_has_error   OUT BOOLEAN,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_user_exception  EXCEPTION;
    g_other_exception EXCEPTION;
    g_error      VARCHAR2(4000);
    g_error_code VARCHAR2(100);

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50);
    g_found        BOOLEAN;

END pk_exam_external;
/
