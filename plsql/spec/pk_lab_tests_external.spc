/*-- Last Change Revision: $Rev: 2028772 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:50 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_lab_tests_external IS

    TYPE t_rec_lab_test_result IS RECORD(
        flg_type            VARCHAR2(1 CHAR),
        id_analysis_req_det table_number,
        id_analysis         NUMBER(12),
        desc_analysis       VARCHAR2(1000 CHAR),
        desc_parameter      VARCHAR2(1000 CHAR),
        RESULT              CLOB,
        flg_result_type     VARCHAR2(2 CHAR),
        desc_unit_measure   VARCHAR2(200 CHAR),
        ref_val             VARCHAR2(200 CHAR),
        abnormality         VARCHAR2(200 CHAR),
        dt_req              VARCHAR2(200 CHAR));

    TYPE t_cur_lab_test_result IS REF CURSOR RETURN t_rec_lab_test_result;

    TYPE t_rec_lab_test_to_schedule IS RECORD(
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

    TYPE t_cur_lab_test_to_schedule IS REF CURSOR RETURN t_rec_lab_test_to_schedule;

    TYPE t_lab_test_order IS RECORD(
        id_analysis_req     NUMBER(24),
        id_analysis_req_det NUMBER(24),
        flg_time_harvest    VARCHAR2(10),
        id_req_group        NUMBER(24));

    TYPE t_tbl_lab_test_order IS TABLE OF t_lab_test_order;

    FUNCTION tf_lab_tests_ea
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_visit      IN visit.id_visit%TYPE,
        i_crit_type  IN VARCHAR2,
        i_start_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN t_tbl_lab_tests_ea;

    FUNCTION tf_analysis_result
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            profissional,
        i_id_patient      analysis_result.id_patient%TYPE DEFAULT NULL,
        i_id_episode_orig analysis_result.id_episode_orig%TYPE DEFAULT NULL,
        i_id_visit        analysis_result.id_visit%TYPE DEFAULT NULL
    ) RETURN t_tbl_analysis_result;

    PROCEDURE episode___________________;

    FUNCTION get_lab_test_for_episode_timeline
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_type    IN VARCHAR2
    ) RETURN VARCHAR2;

    PROCEDURE reports___________________;

    FUNCTION get_lab_tests_listview
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_scope      IN NUMBER,
        i_flg_scope  IN VARCHAR2,
        i_start_date IN VARCHAR2,
        i_end_date   IN VARCHAR2,
        i_cancelled  IN VARCHAR2,
        i_crit_type  IN VARCHAR2,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_resultsview
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_visit            IN visit.id_visit%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_analysis_req_det IN table_number,
        i_flg_type         IN VARCHAR2,
        i_dt_min           IN VARCHAR2,
        i_dt_max           IN VARCHAR2,
        i_flg_report       IN VARCHAR2,
        o_list             OUT pk_types.cursor_type,
        o_result_list      OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_reports_table1
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_column_number IN NUMBER DEFAULT 10000,
        i_episode       IN episode.id_episode%TYPE,
        i_visit         IN visit.id_visit%TYPE,
        i_crit_type     IN VARCHAR2 DEFAULT 'A',
        i_start_date    IN VARCHAR2,
        i_end_date      IN VARCHAR2,
        o_list_columns  OUT pk_types.cursor_type,
        o_list_rows     OUT pk_types.cursor_type,
        o_list_values   OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_reports_table2
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_visit              IN visit.id_visit%TYPE,
        i_crit_type          IN VARCHAR2 DEFAULT 'A',
        i_start_date         IN VARCHAR2,
        i_end_date           IN VARCHAR2,
        o_list_columns       OUT pk_types.cursor_type,
        o_list_rows          OUT pk_types.cursor_type,
        o_list_values        OUT pk_types.cursor_type,
        o_list_minmax_values OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_reports_counter
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_visit      IN visit.id_visit%TYPE,
        i_crit_type  IN VARCHAR2 DEFAULT 'A',
        i_start_date IN VARCHAR2,
        i_end_date   IN VARCHAR2,
        o_counter    OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_tests_orders
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_flg_location          IN VARCHAR2,
        i_flg_reports           IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_list                  OUT pk_types.cursor_type,
        o_lt_clinical_questions OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a lab test detail
    *
    * @param     i_lang                          Language id
    * @param     i_prof                          Professional
    * @param     i_episode                       Episode id
    * @param     i_analysis_req_det              Lab tests' order detail id
    * @param     i_flg_report                    Flag that indicates if the list is to be shown in the application or in a report
    * @param     o_lab_test_order                Cursor
    * @param     o_lab_test_co_sign              Cursor
    * @param     o_lab_test_clinical_questions   Cursor
    * @param     o_lab_test_harvest              Cursor
    * @param     o_lab_test_result               Cursor
    * @param     o_lab_test_doc                  Cursor
    * @param     o_lab_test_review               Cursor
    * @param     o_error                         Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.1
    * @since     2011/05/04
    */

    FUNCTION get_lab_test_detail
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_episode                     IN episode.id_episode%TYPE,
        i_analysis_req_det            IN analysis_req_det.id_analysis_req_det%TYPE,
        i_flg_report                  IN VARCHAR2 DEFAULT pk_lab_tests_constant.g_no,
        o_lab_test_order              OUT pk_types.cursor_type,
        o_lab_test_co_sign            OUT pk_types.cursor_type,
        o_lab_test_clinical_questions OUT pk_types.cursor_type,
        o_lab_test_harvest            OUT pk_types.cursor_type,
        o_lab_test_result             OUT pk_types.cursor_type,
        o_lab_test_doc                OUT pk_types.cursor_type,
        o_lab_test_review             OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_co_sign
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_flg_report       IN VARCHAR2 DEFAULT pk_lab_tests_constant.g_no,
        o_lab_test_co_sign OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a lab test detail history
    *
    * @param     i_lang                          Language id
    * @param     i_prof                          Professional
    * @param     i_episode                       Episode id
    * @param     i_analysis_req_det              Lab tests' order detail id
    * @param     i_flg_report                    Flag that indicates if the list is to be shown in the application or in a report
    * @param     o_lab_test_order                Cursor
    * @param     o_lab_test_co_sign              Cursor
    * @param     o_lab_test_clinical_questions   Cursor
    * @param     o_lab_test_harvest              Cursor
    * @param     o_lab_test_result               Cursor
    * @param     o_lab_test_doc                  Cursor
    * @param     o_lab_test_review               Cursor
    * @param     o_error                         Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.1
    * @since     2011/05/04
    */

    FUNCTION get_lab_test_detail_history
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_episode                     IN episode.id_episode%TYPE,
        i_analysis_req_det            IN analysis_req_det.id_analysis_req_det%TYPE,
        i_flg_report                  IN VARCHAR2 DEFAULT pk_lab_tests_constant.g_no,
        o_lab_test_order              OUT pk_types.cursor_type,
        o_lab_test_co_sign            OUT pk_types.cursor_type,
        o_lab_test_clinical_questions OUT pk_types.cursor_type,
        o_lab_test_harvest            OUT pk_types.cursor_type,
        o_lab_test_result             OUT pk_types.cursor_type,
        o_lab_test_doc                OUT pk_types.cursor_type,
        o_lab_test_review             OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the EPL code for a given harvest to be sent to the printer
    *
    * @param     i_lang      Language id
    * @param     i_prof      Professional
    * @param     i_harvest   Harvest id
    
    * @return    EPL code or null on success or error
    *
    * @author    Ana Matos
    * @version   2.6.3
    * @since     2013/07/24
    */

    FUNCTION get_harvest_barcode_for_print
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_harvest IN harvest.id_harvest%TYPE
    ) RETURN VARCHAR2;

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

    FUNCTION get_lab_test_in_print_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_print_list_job IN print_list_job.id_print_list_job%TYPE
    ) RETURN print_list_job.context_data%TYPE;

    FUNCTION add_print_list_jobs
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_analysis_req_det IN table_number,
        i_print_arguments  IN table_varchar,
        o_print_list_job   OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_print_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_options OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION tf_get_lab_test_to_print
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN table_varchar
    ) RETURN table_varchar;

    FUNCTION get_lab_tests_allowed
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_context IN CLOB
    ) RETURN NUMBER;

    FUNCTION get_lab_test_infect_pl
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_context IN CLOB
    ) RETURN VARCHAR2;

    PROCEDURE pdms_____________________;

    FUNCTION get_lab_test_pdmsview
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_visit            IN visit.id_visit%TYPE,
        i_analysis_req_det IN table_number,
        i_flg_type         IN VARCHAR2,
        i_dt_min           IN VARCHAR2,
        i_dt_max           IN VARCHAR2,
        o_result_gridview  OUT pk_types.cursor_type,
        o_result_graphview OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE co_sign___________________;

    /*
    * Get the lab test description
    *
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_analysis_req_det   Lab tests' order detail id
    * @param     i_co_sign_hist       Co sign id
    
    * @return    String
    *
    * @author    Cristina Oliveira
    * @version   2.6.5
    * @since     2015/01/09
    */

    FUNCTION get_lab_test_description
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_co_sign_hist     IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN CLOB;

    /*
    * Get the lab test instructions
    *
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_analysis_req_det   Lab tests' order detail id
    * @param     i_co_sign_hist       Co sign id
    
    * @return    Clob
    *
    * @author    Cristina Oliveira
    * @version   2.6.5
    * @since     2015/01/09
    */

    FUNCTION get_lab_test_instructions
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_co_sign_hist     IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN CLOB;

    /*
    * Get the lab test action description (Order; Cancelation)
    *
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_analysis_req_det   Lab tests' order detail id
    * @param     i_action             Type of action
    * @param     i_co_sign_hist       Co sign id
    
    * @return    String
    *
    * @author    Cristina Oliveira
    * @version   2.6.5
    * @since     2015/01/09
    */

    FUNCTION get_lab_test_action_desc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_action           IN co_sign.id_action%TYPE,
        i_co_sign_hist     IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN VARCHAR2;

    /*
    * Get the lab test's date to order
    *
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_analysis_req_det   Lab tests' order detail id
    * @param     i_action             Type of action
    * @param     i_co_sign_hist       Co sign id
    
    * @return    String
    *
    * @author    Ana Matos
    * @version   2.6.5
    * @since     2015/10/21
    */

    FUNCTION get_lab_test_date_to_order
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_co_sign_hist     IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    PROCEDURE cdr_______________________;

    FUNCTION get_lab_test_id_content
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_analysis IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_lab_test_param_id_content
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_analysis_parameter IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_alias_translation
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_flg_type      IN VARCHAR2 DEFAULT 'A',
        i_content       IN VARCHAR2,
        i_dep_clin_serv IN analysis_alias.id_dep_clin_serv%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_lab_test_parameter_for_cdr
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_analysis_param     IN table_number,
        o_analysis_parameter OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_cdr
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_analysis_parameter IN VARCHAR2,
        i_date               IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_list               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_lab_test_cdr
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_analysis         IN VARCHAR2,
        i_date             IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_analysis_req_det OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE referral___________________;

    /*
    * Updates a lab test perform institution
    *
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_analysis_req_det   Analysis order detail id
    * @param     i_exec_institution   New institution id
    * @param     o_error              Error message
    
    * @return    string on success or error
    *
    * @author    José Castro
    * @version   2.5
    * @since     2009/09/09
    */

    FUNCTION update_lab_test_institution
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_exec_institution IN analysis_req_det.id_exec_institution%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Updates an analysis request data after referral association
    *
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_analysis_req_det   Analysis order detail id
    * @param     i_flg_referral       New flag referral
    * @param     o_error              Error message
    
    * @return    string on success or error
    *
    * @author    José Castro
    * @version   2.5
    * @since     2009/09/09
    */

    FUNCTION update_lab_test_referral
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_flg_referral     IN analysis_req_det.flg_referral%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_resultsview
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_analysis_req_det IN table_number,
        o_list             OUT pk_lab_tests_external.t_cur_lab_test_result,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_lab_test_workflow_end
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN table_number,
        o_list             OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE cpoe______________________;

    FUNCTION copy_lab_test_to_draft
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

    FUNCTION check_lab_test_mandatory_field
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE
    ) RETURN VARCHAR2;

    FUNCTION check_lab_test_draft_conflict
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

    FUNCTION check_lab_test_draft
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_has_draft OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_lab_test_draft_activation
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

    FUNCTION cancel_lab_test_draft
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_draft   IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_lab_test_all_drafts
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_task_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_task_request    IN table_number,
        i_filter_tstz     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_filter_status   IN table_varchar,
        i_flg_out_of_cpoe IN VARCHAR2 DEFAULT 'N',
        i_flg_report      IN VARCHAR2 DEFAULT 'N',
        i_dt_begin        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_dt_end          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_flg_print_items IN VARCHAR2 DEFAULT 'N',
        i_cpoe_tab        IN VARCHAR2 DEFAULT 'A',
        o_task_list       OUT pk_types.cursor_type,
        o_plan_list       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_actions
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
        i_cpoe_dt_begin IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_cpoe_dt_end   IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_plan_rep      OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE order_sets_________________;

    FUNCTION get_lab_test_req_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_request     IN table_number,
        o_analysis_req_det OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_task_title
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_request     IN analysis_req.id_analysis_req%TYPE,
        i_task_request_det IN analysis_req_det.id_analysis_req_det%TYPE,
        o_task_desc        OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_task_instructions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_task_request      IN analysis_req.id_analysis_req%TYPE,
        i_task_request_det  IN analysis_req_det.id_analysis_req_det%TYPE,
        i_flg_showdate      IN VARCHAR2 DEFAULT 'Y',
        i_flg_group_type    IN VARCHAR2 DEFAULT NULL,
        o_task_instructions OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets task description                                                    
    *                                                                         
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_task_request       Request that identifies patient's task
    * @param     o_task_desc          Task description                       
    * @param     o_task_status_desc   Status' task description               
    * @param     o_error              Error message
    
    * @return    true or false on success or error
    *                                                                           
    * @author    Gustavo Serrano                        
    * @version   v2.6.0.3                               
    * @since     2010/05/13                                
    */

    FUNCTION get_lab_test_task_description
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        o_labtest_desc     OUT VARCHAR2,
        o_task_status_desc OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the status for a give lab test order (ORDER TOOLS)
    *
    * @param     i_lang              Language id
    * @param     i_prof              Professional
    * @param     i_analysis_req_det  Lab test detail order id
    * @param     o_flg_status        Lab test order status
    * @param     o_status_string     Lab test order status string
    * @param     o_flg_finished      Flag that indicates if the lab test is concluded
    * @param     o_flg_canceled      Flag that indicates if the lab test is cancelled
    * @param     o_error             Error message
    
    * @return    true or false on success or error
    *
    * @author    Gustavo Serrano
    * @version   2.5
    * @since     2008/05/23
    */

    FUNCTION get_lab_test_status
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_task_request  IN analysis_req_det.id_analysis_req_det%TYPE,
        o_flg_status    OUT VARCHAR2,
        o_status_string OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_questionnaire
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN analysis_req.id_analysis_req%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_date_limits
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_task_id
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_request     IN analysis_req.id_analysis_req%TYPE,
        i_task_request_det IN analysis_req_det.id_analysis_req_det%TYPE,
        o_lab_test_id      OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_lab_test_request_task
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
        i_clinical_decision_rule  IN analysis_req_det.id_cdr%TYPE,
        i_task_dependency         IN table_number,
        i_flg_task_dependency     IN table_varchar,
        o_analysis_req            OUT table_number,
        o_analysis_req_det        OUT table_table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_lab_test_copy_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN analysis_req.id_analysis_req%TYPE,
        o_analysis_req OUT analysis_req.id_analysis_req%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_lab_test_delete_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_lab_test_diagnosis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN table_number,
        i_diagnosis    IN pk_edis_types.rec_in_epis_diagnosis,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_lab_test_execute_time
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_lab_test_mandatory_field
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN analysis_req.id_analysis_req%TYPE,
        o_check        OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_lab_test_conflict
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_task_request IN analysis_req.id_analysis_req%TYPE,
        o_flg_conflict OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_lab_test_cancel
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN analysis_req_det.id_analysis_req_det%TYPE,
        o_flg_cancel   OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE medication_______________;

    FUNCTION get_lab_test_result_desc
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_analysis_result_par IN analysis_result_par.id_analysis_result_par%TYPE,
        i_dt_analysis_result_par IN analysis_result_par.dt_analysis_result_par_tstz%TYPE
    ) RETURN VARCHAR2;

    PROCEDURE tde_______________________;

    /*
    * Checks if the lab test is still available to be ordered or not (ORDER TOOLS)
    *
    * @param     i_lang             Language id
    * @param     i_prof             Professional
    * @param     i_patient          Patient id
    * @param     i_episode          Episode id
    * @param     i_analysis         Lab test id
    * @param     i_analysis_group   Lab test group id
    * @param     o_reason_msg       Reason message for non availability
    * @param     o_flg_conflict     Flag that indicates if there is a conflict or not
    * @param     o_error            Error message
    
    * @return    true or false on success or error
    *
    * @author    Gustavo Serrano
    * @version   2.4.3
    * @since     2008/05/23
    */

    FUNCTION check_lab_test_conflict
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_analysis       IN analysis.id_analysis%TYPE,
        i_analysis_group IN analysis_group.id_analysis_group%TYPE,
        o_flg_reason_msg OUT VARCHAR2,
        o_flg_conflict   OUT VARCHAR2,
        o_error          OUT t_error_out
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
    * @author    Gustavo Serrano
    * @version   v2.6.0.3
    * @since     2010/05/13
    */

    FUNCTION get_lab_test_cancel_permission
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        o_flg_cancel       OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Start dependent task (define start timestamp and put task in the beggining of workflow)            
    *                                        
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_task_request   Request that identifies patient's task process
    * @param     i_start_tstz     Interval for execution window 
    * @param     o_error          Error message
    
    * @return    true on success, otherwise false
    *                                                                            
    * @author    Gustavo Serrano                            
    * @version   v2.6.0.3                                   
    * @since     2010/05/13                                 
    */

    FUNCTION start_lab_test_task_req
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN tde_task_dependency.id_task_request%TYPE,
        i_start_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Cancels dependent task (task created by TDE order sets)     
    *
    * @param     i_lang            Language id
    * @param     i_prof            Professional
    * @param     i_task_request    Lab tests' order detail id 
    * @param     i_reason          Cancel reason id
    * @param     i_reason_notes    Cancellation notes
    * @param     i_prof_order      Professional that ordered the lab test cancelation (co-sign)
    * @param     i_dt_order        Date of the lab test cancelation (co-sign)
    * @param     i_order_type      Type of cancelation (co-sign)  
    * @param     o_error           Error message
    
    * @return    true or false on success or error
    *
    * @author    Gustavo Serrano
    * @version   2.6.0.3
    * @since     2010/05/13
    */

    FUNCTION cancel_lab_test_task
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_request     IN analysis_req_det.id_analysis_req_det%TYPE,
        i_reason           IN cancel_reason.id_cancel_reason%TYPE,
        i_reason_notes     IN VARCHAR2,
        i_prof_order       IN co_sign.id_prof_ordered_by%TYPE,
        i_dt_order         IN VARCHAR2,
        i_order_type       IN co_sign.id_order_type%TYPE,
        i_flg_cancel_event IN VARCHAR2 DEFAULT 'Y',
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets ongoing tasks (lab tests)
    *                                        
    * @param     i_lang          Language id
    * @param     i_prof          Professional
    * @param     i_patient       Patient id 
    
    * @return    tf_tasks_list   List of cancelable lab tests
    *                                                                            
    * @author    Carlos Nogueira                           
    * @version   v2.6.0.3                                   
    * @since     2010/05/28                                 
    */

    FUNCTION get_lab_test_ongoing_tasks
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN tf_tasks_list;

    /*
    * Suspends tasks (lab tests)
    *                                        
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     i_id_task      Lab test requisition detail id
    * @param     i_flg_reason   Reason for the WF suspension: 'D' (Death)        
    * @param     o_msg_error    Error message to be shown in flash
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *                                                                            
    * @author    Carlos Nogueira                           
    * @version   v2.6.0.3                                   
    * @since     2010/05/28                                 
    */

    FUNCTION suspend_lab_test_task
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_task    IN NUMBER,
        i_flg_reason IN VARCHAR2,
        o_msg_error  OUT VARCHAR,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Reactivates tasks (lab tests)     
    *                                        
    * @param     i_lang        Language id
    * @param     i_prof        Professional
    * @param     i_id_task     Lab test requisition detail id
    * @param     o_msg_error   Error message to be shown in flash
    * @param     o_error       Error message
    
    * @return    true on success, otherwise false
    *                                                                            
    * @author    Carlos Nogueira                           
    * @version   v2.6.0.3                                   
    * @since     2010/05/28                                 
    */

    FUNCTION reactivate_lab_test_task
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
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_analysis_req_det   Request that identifies patient's task process 
    * @param     o_flg_time           Execution time
    * @param     o_flg_time_desc      Execution time description
    * @param     o_error              Error message
    
    * @return    true on success, otherwise false
    *                                                                            
    * @author    Filipe Silva                            
    * @version   v2.6.0.3                                   
    * @since     2010/06/22                                 
    */

    FUNCTION get_lab_test_task_execute_time
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        o_flg_time         OUT VARCHAR2,
        o_flg_time_desc    OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Updates task dependency engine state                                     
    *                                                                         
    * @param     i_lang              Language id
    * @param     i_prof              Professional
    * @param     i_lab_test_req      Request identifier                     
    * @param     i_flg_action        Update action (E - Execute, C - Cancel, F - Finish)                            
    * @param     i_task_dependency   task dependency identifier             
    * @param     i_reason            Cancel reason identifier               
    * @param     i_reason_notes      Cancel reason notes                    
    * @param     i_transaction_id    Transaction id                      
    * @param     o_error             Error message  
    
    * @return    true on success, otherwise false
    *                                                                            
    * @author    Gustavo Serrano                        
    * @version   v2.6.0.3                               
    * @since     2010/06/28                                
    */

    FUNCTION update_tde_task_state
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_lab_test_req    IN analysis_req.id_analysis_req%TYPE,
        i_flg_action      IN VARCHAR2,
        i_task_dependency IN tde_task_dependency.id_task_dependency%TYPE DEFAULT NULL,
        i_reason          IN cancel_reason.id_cancel_reason%TYPE DEFAULT NULL,
        i_reason_notes    IN VARCHAR2 DEFAULT NULL,
        i_transaction_id  IN VARCHAR2 DEFAULT NULL,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE pregnancy_________________;

    /*
    * Count the number of results of a given analysis and patient, after a specific date
    * 
    * @param     i_lang                Language id
    * @param     i_prof                Professional
    * @param     i_patient             Patient id
    * @param     i_id_content          List of analysis content IDs
    * @param     i_dt_min_lab_result   Only consider results after this date
    
    * @return    true on success, otherwise false
    *                                                                            
    * @author    José Silva
    * @version   2.5.1.9
    * @since     2011/11/23
    */

    FUNCTION get_count_lab_test_results
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_patient           IN patient.id_patient%TYPE,
        i_id_content        IN table_varchar,
        i_dt_min_lab_result IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN NUMBER;

    PROCEDURE single_page________________;

    /*
    * Returns a lab test order detail id for a given recurrende plan id
    *
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_order_recurrence   Lab test order recurrence plan id
    * @param     o_analysis_req_det   Lab test order detail id
    * @param     o_error              Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   v2.6.5.0.3
    * @since     16/Jul/2015
    */

    FUNCTION get_lab_req_det_by_id_recurr
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_order_recurrence IN analysis_req_det.id_order_recurrence%TYPE,
        i_dt_req           IN analysis_req.dt_req_tstz%TYPE DEFAULT NULL,
        o_analysis_req_det OUT analysis_req_det.id_analysis_req_det%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of lab test results for a patient within a visit
    *
    * @param     i_lang      Language id
    * @param     i_prof      Professional
    * @param     i_episode   Episode id
    
    * @return    List of lab test results
    *
    * @author    Gustavo Serrano
    * @version   2.5
    * @since     2009/03/06
    */

    FUNCTION get_lab_test_result_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_varchar;

    /*
    * Get description of lab order result
    *
    * @param     i_lang                     Language id
    * @param     i_prof                     Professional
    * @param     i_id_analysis_result_par   Lab test result id
    * @param     i_description_condition    String that will dictate how the description should be built
    * @param     i_flg_desc_for_dblock      Is a datablock description?     
    * @param     o_description              Description
    * @param     o_error                    Error message
    
    * @return    true or false on success or error
    *
    * @author    António Neto
    * @version   2.6.2
    * @since     2012/01/31
    */

    FUNCTION get_lab_test_result_desc
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_analysis_result_par IN analysis_result_par.id_analysis_result_par%TYPE,
        i_description_condition  IN pn_dblock_ttp_mkt.description_condition%TYPE DEFAULT NULL,
        i_flg_desc_for_dblock    IN pk_types.t_flg_char DEFAULT NULL,
        o_description            OUT CLOB,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_order_cond_desc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_analysis_req_det   IN analysis_req_det.id_analysis_req_det%TYPE,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE DEFAULT NULL,
        i_flg_desc_for_dblock   IN pk_types.t_flg_char DEFAULT NULL,
        o_description           OUT CLOB,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get analysis order status.
    *
    * @param     i_lang                  Language id
    * @param     i_prof                  Professional
    * @param     i_id_analysis_req_det   Lab test request ID
    * @param     o_status                Status description     
    * @param     o_error                 Error message
    
    * @return    true on success, otherwise false
    *
    * @author    Sofia Mendes
    * @version   v2.6.2.2
    * @since     28/Mar/2012
    */

    FUNCTION get_analysis_status_desc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        o_status              OUT CLOB,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get the last lab test result parameter by date
    * 
    * @param     i_lang                Language id
    * @param     i_prof                Professional
    * @param     i_patient             Patiente id
    * @param     i_analysis_param      List of params
    * @param     i_dt_result           Search date
    * @param     o_list                Cursor
    * @param     o_error               Error message 
    
    * @return    true on success, otherwise false
    *                                                                            
    * @author    Vanessa Barsottelli
    * @version   v2.6.1.5.1
    * @since     2011/11/22
    */

    FUNCTION get_lab_test_result_param
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_analysis_param IN table_number,
        i_dt_result      IN VARCHAR2,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get lab test parameter identifiers list.
    *
    * @param     i_prof          Professional
    * @param     i_analysis      Lab tests' id
    * @param     i_sample_type   Sample type id
    *
    * @return    Lab test parameter identifiers list
    *
    * @author    Pedro Carneiro
    * @version   2.6.1.9
    * @since     2012/07/02
    */

    FUNCTION get_lab_test_parameters
    (
        i_prof        IN profissional,
        i_analysis    IN analysis.id_analysis%TYPE,
        i_sample_type IN sample_type.id_sample_type%TYPE
    ) RETURN table_number;

    /*
    * Get lab test parameter count.
    *
    * @param     i_prof          Professional
    * @param     i_analysis      Lab tests' id
    * @param     i_sample_type   Sample type id
    *
    * @return    Lab test parameter identifiers list
    *
    * @author    Pedro Carneiro
    * @version   2.6.1.9
    * @since     2012/07/02
    */

    FUNCTION get_lab_test_param_count
    (
        i_prof        IN profissional,
        i_analysis    IN analysis.id_analysis%TYPE,
        i_sample_type IN sample_type.id_sample_type%TYPE
    ) RETURN NUMBER;

    /*
    * Verify if the lab test for the given recurrence is finished 
    *
    * @param     i_lang                Language id
    * @param     i_prof                Professional
    * @param     i_order_recurrence    Analysis order recurrence plan id
    
    * @return    true on success, otherwise false
    *                                                                            
    * @author    Vanessa Barsottelli
    * @version   v2.6.2.0.6
    * @since     2012/03/15
    */

    FUNCTION is_lab_test_recurr_finished
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_order_recurrence IN analysis_req_det.id_order_recurrence%TYPE
    ) RETURN VARCHAR2;

    /*
    * Checks if the result of lab test is outside of the min and max parameters
    *
    * @param     i_lang                       Language id
    * @param     i_prof                       Professional object identifier
    * @param     i_flg_type_comparison        Type of comparison, compares with min or max value
    * @param     i_desc_analysis_result       Description for the Analysis Result
    * @param     i_analysis_result_value      Value for the Analysis Result
    * @param     i_ref_val                    Min/Max reference value to compare with the value
    *
    * @value     i_flg_type_comparison        {*} 'A'- Compares with max Value {*} 'I'- Compares with min Value
    
    * @return                                 'Y' - Yes outside interval, 'N' - otherwise No
    *
    * @author                                 António Neto
    * @version                                v2.6.2
    * @since                                  17-Apr-2012
    */

    FUNCTION is_lab_result_outside_params
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_flg_type_comparison   IN VARCHAR2,
        i_desc_analysis_result  IN analysis_result_par.desc_analysis_result%TYPE,
        i_analysis_result_value IN analysis_result_par.analysis_result_value_1%TYPE,
        i_ref_val               IN analysis_result_par.ref_val_min%TYPE
    ) RETURN VARCHAR2;

    /*
    * Description to present in the single page
    *                                                                         
    * @param     i_lang                     Language id
    * @param     i_prof                     Professional
    * @param     i_id_analysis_result_par   Lab test order id                     
    * @param     i_description_condition    Date to start                         
    * @param     i_flg_desc_for_dblock      Scheduling notes
    * @param     o_error                    Error message
    
    * @return    true or false on success or error
    *                                                                           
    * @author    Rui Mendonça
    * @version   2.7.1.5
    * @since     2017/10/12
    */

    FUNCTION get_lab_test_result_cond_desc
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_analysis_result_par IN analysis_result_par.id_analysis_result_par%TYPE,
        i_description_condition  IN pn_dblock_ttp_mkt.description_condition%TYPE,
        i_flg_desc_for_dblock    IN pk_types.t_flg_char,
        o_description            OUT CLOB,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE hand_off__________________;

    FUNCTION get_lab_tests_by_status
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        o_analysis OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE sev_score_________________;

    FUNCTION get_lab_test_result
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_analysis_parameter IN table_varchar,
        i_flg_parameter      IN VARCHAR2,
        i_dt_min             IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_max             IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_result_value       OUT NUMBER,
        o_result_um          OUT unit_measure.id_unit_measure%TYPE
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_result
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_id_mtos_param IN mtos_param.id_mtos_param%TYPE,
        i_flg_parameter IN VARCHAR2,
        i_dt_min        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_max        IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2;

    FUNCTION get_lab_test_result_um
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_id_mtos_param IN mtos_param.id_mtos_param%TYPE,
        i_flg_parameter IN VARCHAR2,
        i_dt_min        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_max        IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN NUMBER;

    FUNCTION get_results_count
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_analysis_parameter IN table_varchar,
        i_flg_parameter      IN VARCHAR2,
        i_dt_min             IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_max             IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN INTEGER;

    PROCEDURE viewer___________________;

    /*
    * Returns lab tests ordered list for the viewer
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
        i_translate    IN VARCHAR2 DEFAULT NULL, --se ‘N’ os código não serão traduzidos
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
    * @param     i_analysis_req_det   Lab tests' order detail id
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
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        o_ordered_list_det OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns lab tests information for the viewer
    *
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     i_patient      Patient id
    * @param     o_num_occur    Number of lab tests for the given patient
    * @param     o_desc_first   First lab tests description
    * @param     o_dt_first     First lab tests order date
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

    FUNCTION get_lab_test_viewer_checklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
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

    PROCEDURE crisis_machine_____________;

    FUNCTION tf_cm_lab_episodes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_search_interval IN crisis_machine.interval_search%TYPE
    ) RETURN t_tbl_cm_episodes;

    FUNCTION tf_cm_lab_episode_detail
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_schedule IN schedule.id_schedule%TYPE
    ) RETURN t_tbl_lab_episodes;

    PROCEDURE context_help__________________;

    FUNCTION get_lab_test_context_help
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_analysis            IN table_varchar,
        i_analysis_result_par IN table_number,
        o_content             OUT table_varchar,
        o_map_target_code     OUT table_varchar,
        o_id_map_set          OUT table_varchar,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE cda______________________;

    /*
    * Gets lab tests for CDA section that are pending and future scheduled 
    *
    * @param i_lang           Language ID
    * @param i_prof           Professional ID
    * @param i_scope          ID for scope type
    * @param i_scope_type     Scope type (E)pisode/(V)isit/(P)atient
    * @param o_lab_test_cda   Cursor with infomation about Lab Tests for the given scope
    * @param o_error          Error message
    *
    * @return                 True on success, false otherwise
    *                        
    * @author                 Cristina Oliveira
    * @version                2.6.4
    * @since                  2014/10/10 
    */

    FUNCTION get_lab_test_cda
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_type_scope   IN VARCHAR2,
        i_id_scope     IN NUMBER,
        o_lab_test_cda OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE scheduler__________________;

    /*
    * Get lab test request to schedule
    * 
    * @param     i_lang            Language ID
    * @param     i_prof            Professional
    * @param     i_institution     Institution ID
    * @param     i_patient         Patient ID
    * @param     i_id_content      Lab test content ID
    * @param     i_id_department   Department ID
    * @param     i_pat_age_min     Patient age Min
    * @param     i_pat_age_max     Patient age Max
    * @param     i_pat_gender      Patient gender
    * @param     i_start           Start page
    * @param     i_offset          Number of records per page
    * @param     o_list            Cursor
    * @param     o_error           Error message 
    *
    * @return    true or false on success or error
    *                                                                            
    * @author    Cristina Oliveira
    * @version   2.6.4
    * @since     2014/11/17
    */
    FUNCTION get_lab_test_req_to_schedule
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_institution   IN table_number,
        i_patient       IN patient.id_patient%TYPE DEFAULT NULL,
        i_id_department IN room.id_department%TYPE DEFAULT NULL,
        i_pat_age_min   IN patient.age%TYPE DEFAULT NULL,
        i_pat_age_max   IN patient.age%TYPE DEFAULT NULL,
        i_pat_gender    IN patient.gender%TYPE DEFAULT NULL,
        i_start         IN NUMBER DEFAULT NULL,
        i_offset        IN NUMBER DEFAULT NULL,
        o_list          OUT pk_lab_tests_external.t_cur_lab_test_to_schedule,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE match____________________;

    FUNCTION set_lab_test_match
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
    * Resets lab tests info by patient and /or episode
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

    FUNCTION reset_lab_tests
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN table_number,
        i_episode      IN table_number,
        io_transaction IN OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE system___________________;

    /*
    * Processes all pending orders changing the status from pending to requested
    * 
    * @author    Gustavo Serrano
    * @version   2.5
    * @since     2009/03/27
    */

    PROCEDURE process_lab_test_pending;

    FUNCTION inactivate_lab_tests_tasks
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_inst        IN institution.id_institution%TYPE,
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

END pk_lab_tests_external;
/
