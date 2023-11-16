/*-- Last Change Revision: $Rev: 2055401 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2023-02-22 09:43:55 +0000 (qua, 22 fev 2023) $*/

CREATE OR REPLACE PACKAGE pk_patient_education_api_ux IS

    /**
    * Create Patient Education Request
    *
    * @param   i_lang                        Professional preferred language
    * @param   i_prof                        Professional identification and its context (institution and software)
    * @param   i_id_episode                  ID Episode
    * @param   i_topics                      Table Number topics Ids
    * @param   i_compositions                Table Table Number Compositions Ids
    * @param   i_diagnoses                   Table Clob Diagnoses
    * @param   i_to_be_performed             Table Varchar To Be Performed Date
    * @param   i_start_date                  Table Varchar Start Date
    * @param   i_notes                       Table Varchar Notes
    * @param   i_description                 Table Clob Description
    * @param   i_order_recurr                Table Number Order Recurrence Ids
    * @param   i_draft                       Varchar Draft (Y/N)
    * @param   i_id_nurse_tea_req_sugg       Table Number Nurse_Tea_Req_Sugg Ids
    * @param   i_desc_topic_aux              Table Varchar Desc Topic
    * @param   i_not_order_reason            Table Number Not Order Reason
    * @param   o_id_nurse_tea_req            Table Number Nurse_Tea_Req Ids
    * @param   o_id_nurse_tea_topic          Table Number Nurse_Tea_Topic Ids
    * @param   o_title_topic                 Table Varchar Title Topics
    * @param   o_desc_diagnosis              Table Varchar Diagnoses Description
    * @param   o_error                       Error information
    *
    * @return  True or False on success or error
    *
    * HTML
    */
    FUNCTION create_request
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN nurse_tea_req.id_episode%TYPE,
        i_draft                IN VARCHAR2 DEFAULT 'N',
        i_topics               IN table_number,
        i_tbl_ds_internal_name IN table_varchar DEFAULT NULL,
        i_tbl_real_val         IN table_table_varchar DEFAULT NULL,
        i_tbl_val_clob         IN table_table_clob DEFAULT NULL,
        i_tbl_val_array        IN tt_table_varchar DEFAULT NULL,
        i_flg_edition          IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_tbl_nurse_tea_req    IN table_number DEFAULT NULL,
        i_flg_origin_req       IN VARCHAR2,
        o_id_nurse_tea_req     OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Set Documentation Patient Education Execution
    *
    * @param   i_lang                        Professional preferred language
    * @param   i_prof                        Professional identification and its context (institution and software)
    * @param   i_id_nurse_tea_req            Nurse_Tea_Req Id
    * @param   i_subject                     Subject
    * @param   i_id_nurse_tea_opt            Nurse_Tea_Option Id
    * @param   i_free_text                   Free Text
    * @param   i_dt_start                    Start Date
    * @param   i_dt_end                      End Date
    * @param   i_duration                    Duration
    * @param   i_unit_meas_duration          Unit Measure
    * @param   i_description                 Description
    * @param   o_error                       Error information
    *
    * @return  True or False on success or error
    *
    * HTML
    */
    FUNCTION set_documentation_exec
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_nurse_tea_req     IN table_number,
        i_tbl_ds_internal_name IN table_varchar DEFAULT NULL,
        i_tbl_real_val         IN table_table_varchar DEFAULT NULL,
        i_tbl_val_clob         IN table_table_clob DEFAULT NULL,
        i_unit_meas_duration   IN table_number DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Set Ignore Suggestion
    *
    * @param   i_lang                        Professional preferred language
    * @param   i_prof                        Professional identification and its context (institution and software)
    * @param   i_id_nurse_tea_req            Nurse_Tea_Req Id
    * @param   o_error                       Error information
    *
    * @return  True or False on success or error
    *
    * HTML
    */
    FUNCTION set_ignore_suggestion
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Update Patient Education Request
    *
    * @param   i_lang                        Professional preferred language
    * @param   i_prof                        Professional identification and its context (institution and software)
    * @param   i_id_episode                  ID Episode
    * @param   i_topics                      Table Number topics Ids
    * @param   i_compositions                Table Table Number Compositions Ids
    * @param   i_diagnoses                   Table Clob Diagnoses
    * @param   i_to_be_performed             Table Varchar To Be Performed Date
    * @param   i_start_date                  Table Varchar Start Date
    * @param   i_notes                       Table Varchar Notes
    * @param   i_description                 Table Clob Description
    * @param   i_order_recurr                Table Number Order Recurrence Ids
    * @param   i_upd_flg_status              Update Flag Status (Y/N)
    * @param   i_not_order_reason            Table Number Not Order Reason
    * @param   o_error                       Error information
    *
    * @return  True or False on success or error
    *
    * HTML
    */
    FUNCTION update_request
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN nurse_tea_req.id_episode%TYPE,
        i_id_nurse_tea_req IN table_number,
        i_topics           IN table_number,
        i_compositions     IN table_table_number,
        i_diagnoses        IN table_clob,
        i_to_be_performed  IN table_varchar,
        i_start_date       IN table_varchar,
        i_notes            IN table_varchar,
        i_description      IN table_clob,
        i_order_recurr     IN table_number,
        i_upd_flg_status   IN VARCHAR2 DEFAULT 'Y',
        i_not_order_reason IN table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancel Patient Education Request
    *
    * @param   i_lang                        Professional preferred language
    * @param   i_prof                        Professional identification and its context (institution and software)
    * @param   i_id_nurse_tea_req            Table Number Nurse_Tea_Req Ids
    * @param   i_id_cancel_reason            Cancel Reason
    * @param   i_cancel_notes                Cancel Reason Notes
    * @param   o_error                       Error information
    *
    * @return  True or False on success or error
    *
    * HTML
    */
    FUNCTION cancel_patient_education
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN table_number,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes     IN nurse_tea_req.notes_close%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get Domain Flag TIme
    *
    * @param   i_lang                        Professional preferred language
    * @param   i_prof                        Professional identification and its context (institution and software)
    * @param   o_values                      Flag Time Values
    * @param   o_error                       Error information
    *
    * @return  True or False on success or error
    *
    * HTML
    */
    FUNCTION get_domain_flg_time
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_values OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get Patient Education Request Data To Update
    *
    * @param   i_lang                        Professional preferred language
    * @param   i_prof                        Professional identification and its context (institution and software)
    * @param   i_id_nurse_tea_req            Table Number Nurse_Tea_Req Ids
    * @param   o_detail                      Cursor with request details
    * @param   o_error                       Error information
    *
    * @return  True or False on success or error
    *
    * HTML
    */
    FUNCTION get_request_for_update
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN table_number,
        o_detail           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get Topic List
    *
    * @param   i_lang                        Professional preferred language
    * @param   i_prof                        Professional identification and its context (institution and software)
    * @param   i_flg_show_others             Flag show others
    * @param   o_topics                      Cursor with list of topics
    * @param   o_error                       Error information
    *
    * @return  True or False on success or error
    *
    * HTML
    */
    FUNCTION get_topic_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_show_others IN VARCHAR2 DEFAULT 'Y',
        o_topics          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get Subject Topic List
    *
    * @param   i_lang                        Professional preferred language
    * @param   i_prof                        Professional identification and its context (institution and software)
    * @param   i_id_subject                  Subject Id
    * @param   i_flg_show_others             Flag show others
    * @param   o_subjects                    Cursor with subjects
    * @param   o_topics                      Cursor with list of topics
    * @param   o_error                       Error information
    *
    * @return  True or False on success or error
    *
    * HTML
    */
    FUNCTION get_subject_topic_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_subject      IN nurse_tea_subject.id_nurse_tea_subject%TYPE,
        i_flg_show_others IN VARCHAR2 DEFAULT 'Y',
        o_subjects        OUT pk_types.cursor_type,
        o_topics          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get available actions according with patient education request's status
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param   i_nurse_tea_req  Patient education request IDs
    * @param   o_actions        Available actions
    * @param   o_error          Error information
    *
    * @return  True or False on success or error
    *
    * HTML
    */
    FUNCTION get_request_actions
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nurse_tea_req IN table_number,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_hhc_req    IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_actions       OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * SET Order for execution
    *
    * @return  True or False on success or error
    *
    * HTML
    */
    FUNCTION set_order_for_execution
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_id_nurse_tea_topic   IN table_number,
        i_tbl_ds_internal_name IN table_varchar DEFAULT NULL,
        i_tbl_real_val         IN table_table_varchar DEFAULT NULL,
        i_tbl_val_clob         IN table_table_clob DEFAULT NULL,
        i_unit_meas_duration   IN table_number DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    g_error VARCHAR2(100);
    g_exception EXCEPTION;
    g_package_owner CONSTANT VARCHAR2(5) := 'ALERT';
    g_package_name  CONSTANT VARCHAR2(20) := 'PK_PATIENT_EDUCATION';

END pk_patient_education_api_ux;
/
