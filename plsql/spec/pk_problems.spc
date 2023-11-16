/*-- Last Change Revision: $Rev: 2028874 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:29 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_problems IS

    TYPE problem_dif IS RECORD(
        precaution_measures_b sys_message.desc_message%TYPE,
        precaution_measures_a sys_message.desc_message%TYPE,
        header_warning_b      sys_message.desc_message%TYPE,
        header_warning_a      sys_message.desc_message%TYPE,
        specialty_b           sys_message.desc_message%TYPE,
        specialty_a           sys_message.desc_message%TYPE,
        resolution_date_b     sys_message.desc_message%TYPE,
        resolution_date_a     sys_message.desc_message%TYPE,
        status_b              sys_message.desc_message%TYPE,
        status_a              sys_message.desc_message%TYPE,
        location_b            sys_message.desc_message%TYPE,
        location_a            sys_message.desc_message%TYPE,
        nature_b              sys_message.desc_message%TYPE,
        nature_a              sys_message.desc_message%TYPE,
        onset_b               sys_message.desc_message%TYPE,
        onset_a               sys_message.desc_message%TYPE,
        type_prob_b           sys_message.desc_message%TYPE,
        type_prob_a           sys_message.desc_message%TYPE,
        problem_b             sys_message.desc_message%TYPE,
        problem_a             sys_message.desc_message%TYPE,
        notes_b               sys_message.desc_message%TYPE,
        notes_a               sys_message.desc_message%TYPE,
        cancel_notes_b        sys_message.desc_message%TYPE,
        cancel_notes_a        sys_message.desc_message%TYPE,
        cancel_reason_b       sys_message.desc_message%TYPE,
        cancel_reason_a       sys_message.desc_message%TYPE,
        registered_b          sys_message.desc_message%TYPE,
        registered_a          sys_message.desc_message%TYPE,
        create_time           sys_message.desc_message%TYPE,
        cancel_prof_b         sys_message.desc_message%TYPE,
        cancel_prof_a         sys_message.desc_message%TYPE,
        cancel_date_b         sys_message.desc_message%TYPE,
        cancel_date_a         sys_message.desc_message%TYPE,
        record_origin_b       sys_message.desc_message%TYPE,
        record_origin_a       sys_message.desc_message%TYPE,
        complications_b       sys_message.desc_message%TYPE,
        complications_a       sys_message.desc_message%TYPE,
        id_group_b            sys_message.desc_message%TYPE,
        id_group_a            sys_message.desc_message%TYPE);

    TYPE problem_dif_table IS TABLE OF problem_dif INDEX BY BINARY_INTEGER;

    TYPE problem_type IS RECORD(
        problem             sys_message.desc_message%TYPE,
        precaution_measures sys_message.desc_message%TYPE,
        header_warning      sys_message.desc_message%TYPE,
        type_prob           sys_message.desc_message%TYPE,
        onset               sys_message.desc_message%TYPE,
        id_habit            sys_message.desc_message%TYPE,
        location            sys_message.desc_message%TYPE,
        nature              sys_message.desc_message%TYPE,
        specialty           sys_message.desc_message%TYPE,
        status              sys_message.desc_message%TYPE,
        resolution_date     sys_message.desc_message%TYPE,
        notes               sys_message.desc_message%TYPE,
        cancel_reason       sys_message.desc_message%TYPE,
        cancel_notes        sys_message.desc_message%TYPE,
        registered          sys_message.desc_message%TYPE,
        create_time         sys_message.desc_message%TYPE,
        cancel_prof         sys_message.desc_message%TYPE,
        cancel_date         sys_message.desc_message%TYPE,
        record_origin       sys_message.desc_message%TYPE,
        complications       sys_message.desc_message%TYPE,
        id_group            sys_message.desc_message%TYPE);

    -- Joana  Barroso: 2008/11/14 - TYPE utilizado para retornar informacao de get_pat_problem
    TYPE pat_problem_rec IS RECORD(
        id                      NUMBER(24),
        id_problem              NUMBER(24),
        TYPE                    VARCHAR2(2),
        dt_problem2             VARCHAR2(200),
        dt_problem              VARCHAR2(50),
        dt_problem_to_print     VARCHAR2(50),
        desc_probl              VARCHAR2(4000),
        title                   VARCHAR2(4000),
        flg_source              VARCHAR2(2),
        dt_order                VARCHAR2(14),
        flg_status              VARCHAR2(2),
        rank_type               NUMBER(6),
        rank_cancelled          NUMBER(1),
        rank_area               NUMBER(6),
        flg_cancel              VARCHAR2(2),
        desc_status             VARCHAR2(200),
        desc_nature             VARCHAR2(200),
        rank_status             NUMBER(6),
        rank_nature             NUMBER(6),
        flg_nature              VARCHAR2(2),
        title_notes             VARCHAR2(4000),
        prob_notes              VARCHAR2(4000),
        title_canceled          VARCHAR2(4000),
        id_prob                 NUMBER(24),
        viewer_category         VARCHAR2(4000),
        viewer_category_desc    VARCHAR2(4000),
        viewer_id_prof          NUMBER(24),
        viewer_id_epis          NUMBER(24),
        viewer_date             VARCHAR2(14),
        registered_by_me        VARCHAR2(1),
        origin_specialty        VARCHAR2(200),
        id_origin_specialty     NUMBER(24),
        precaution_measures_str table_varchar,
        id_precaution_measures  table_number,
        header_warning          VARCHAR2(1),
        header_warning_str      VARCHAR2(200),
        resolution_date_str     VARCHAR2(200),
        resolution_date         VARCHAR2(200),
        dt_resolved_precision   VARCHAR2(1),
        warning_icon            VARCHAR2(4000),
        review_info             table_varchar,
        id_pat_habit            NUMBER(24),
        flg_area                VARCHAR2(1),
        id_terminology_version  NUMBER(24),
        id_content              VARCHAR2(200 CHAR),
        code_icd                VARCHAR2(200 CHAR),
        term_international_code VARCHAR2(200 CHAR),
        flg_info_button         VARCHAR2(1 CHAR),
        update_time             TIMESTAMP(6) WITH LOCAL TIME ZONE,
        dt_problem_serial       VARCHAR2(50),
        id_professional         NUMBER(24),
        dt_updated              TIMESTAMP(6) WITH LOCAL TIME ZONE);

    TYPE pat_problem_cur IS REF CURSOR RETURN pat_problem_rec;
    TYPE pat_problem_table IS TABLE OF pat_problem_rec;
    -- Joana Barroso: 2008/11/14 - TYPE utilizado para retornar informaar em get_pat_problem_det
    TYPE problem_rec IS RECORD(
        nick_name           professional.nick_name%TYPE,
        dt_order            VARCHAR2(14),
        dt_order_tstz       TIMESTAMP(6) WITH LOCAL TIME ZONE,
        notes               VARCHAR2(4000),
        flg_status          VARCHAR2(2),
        dt_pat_problem      VARCHAR2(50),
        desc_status         VARCHAR2(200),
        desc_nature         VARCHAR2(200),
        desc_speciality     VARCHAR2(4000),
        label_onset         VARCHAR2(4000),
        label_status        VARCHAR2(4000),
        label_nature        VARCHAR2(4000),
        label_type          VARCHAR2(4000),
        label_notes         VARCHAR2(4000),
        desc_edit           VARCHAR2(4000),
        dt_problem          VARCHAR2(4000),
        dt_problem_to_print VARCHAR2(4000),
        label_prob_cancel   VARCHAR2(4000),
        label_cancel_reason VARCHAR2(4000),
        label_cancel_notes  VARCHAR2(4000),
        cancel_reason       VARCHAR2(4000),
        cancel_notes        VARCHAR2(4000),
        flg_hist            VARCHAR2(1),
        flg_review          VARCHAR2(1),
        desc_review         VARCHAR2(4000));

    TYPE problem_rec_state_list IS RECORD(
        nick_name           professional.nick_name%TYPE,
        dt_order            VARCHAR2(14),
        notes               VARCHAR2(4000),
        flg_status          VARCHAR2(2),
        dt_pat_problem      VARCHAR2(50),
        desc_status         VARCHAR2(200),
        desc_nature         VARCHAR2(200),
        desc_speciality     VARCHAR2(4000),
        label_onset         VARCHAR2(4000),
        label_status        VARCHAR2(4000),
        label_nature        VARCHAR2(4000),
        label_type          VARCHAR2(4000),
        label_notes         VARCHAR2(4000),
        desc_edit           VARCHAR2(4000),
        dt_problem          VARCHAR2(4000),
        dt_problem_to_print VARCHAR2(4000),
        label_prob_cancel   VARCHAR2(4000),
        label_cancel_reason VARCHAR2(4000),
        label_cancel_notes  VARCHAR2(4000),
        cancel_reason       VARCHAR2(4000),
        cancel_notes        VARCHAR2(4000));

    TYPE problem_cur IS REF CURSOR RETURN problem_rec;

    TYPE problem_rec_status_edition IS RECORD(
        problem_status_list t_coll_epis_problem_list,
        new_problem         VARCHAR(1),
        edit_problem        VARCHAR(1));

    g_problem_view_episode CONSTANT VARCHAR2(2) := 'EP';
    g_problem_view_patient CONSTANT VARCHAR2(2) := 'PP';

    FUNCTION get_pat_problem_tf
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_pat     IN pat_history_diagnosis.id_patient%TYPE,
        i_status  IN table_varchar,
        i_type    IN VARCHAR2,
        i_problem IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE DEFAULT NULL,
        i_episode IN pat_problem.id_episode%TYPE,
        i_report  IN VARCHAR2,
        i_dt_ini  IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        i_dt_end  IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE
    ) RETURN pat_problem_table
        PIPELINED;

    FUNCTION get_pat_problem_tf_cda
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_pat         IN pat_history_diagnosis.id_patient%TYPE,
        i_status      IN table_varchar,
        i_type        IN VARCHAR2,
        i_problem     IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE DEFAULT NULL,
        i_scopeid     IN pat_problem.id_episode%TYPE,
        i_flg_scope   IN VARCHAR2,
        i_dt_ini      IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        i_dt_end      IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        i_show_ph     IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_show_review IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN pat_problem_table
        PIPELINED;

    FUNCTION get_pat_problem_tf_dash
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN pat_history_diagnosis.id_patient%TYPE,
        i_id_episode        IN pat_problem.id_episode%TYPE,
        i_flg_visit_or_epis IN VARCHAR2,
        i_tv_flg_status     IN table_varchar,
        i_tv_flg_type       IN table_varchar,
        i_dt_ini            IN VARCHAR2,
        i_dt_end            IN VARCHAR2
    ) RETURN pat_problem_table
        PIPELINED;

    FUNCTION get_phd
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_pat         IN pat_history_diagnosis.id_patient%TYPE,
        i_status      IN table_varchar,
        i_problem     IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE DEFAULT NULL,
        i_id_scope    IN NUMBER,
        i_scope       IN VARCHAR2,
        i_dt_ini      IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        i_dt_end      IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        i_show_ph     IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_show_review IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN pat_problem_table
        PIPELINED;

    FUNCTION get_pp
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_pat     IN pat_history_diagnosis.id_patient%TYPE,
        i_status  IN table_varchar,
        i_type    IN VARCHAR2,
        i_problem IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE DEFAULT NULL,
        i_episode IN pat_problem.id_episode%TYPE,
        i_report  IN VARCHAR2,
        i_dt_ini  IN pat_problem.dt_pat_problem_tstz%TYPE,
        i_dt_end  IN pat_problem.dt_pat_problem_tstz%TYPE
    ) RETURN pat_problem_table
        PIPELINED;

    FUNCTION get_pa
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_pat     IN pat_history_diagnosis.id_patient%TYPE,
        i_status  IN table_varchar,
        i_problem IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE DEFAULT NULL,
        i_episode IN pat_problem.id_episode%TYPE,
        i_report  IN VARCHAR2,
        i_dt_ini  IN pat_allergy.dt_pat_allergy_tstz%TYPE,
        i_dt_end  IN pat_allergy.dt_pat_allergy_tstz%TYPE
    ) RETURN pat_problem_table
        PIPELINED;

    FUNCTION get_pat_problem_internal
    (
        i_lang                      IN language.id_language%TYPE,
        i_pat                       IN pat_problem.id_patient%TYPE,
        i_status                    IN pat_problem.flg_status%TYPE,
        i_type                      IN VARCHAR2,
        i_prof                      IN profissional,
        i_problem                   IN pat_problem.id_pat_problem%TYPE DEFAULT NULL,
        i_episode                   IN pat_problem.id_episode%TYPE,
        i_report                    IN VARCHAR2,
        o_pat_problem               OUT pk_types.cursor_type,
        o_pat_prob_unaware_active   OUT pk_types.cursor_type,
        o_pat_prob_unaware_outdated OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_problem
    (
        i_lang                      IN language.id_language%TYPE,
        i_pat                       IN pat_problem.id_patient%TYPE,
        i_status                    IN pat_problem.flg_status%TYPE,
        i_type                      IN VARCHAR2,
        i_prof                      IN profissional,
        i_problem                   IN pat_problem.id_pat_problem%TYPE,
        i_episode                   IN pat_problem.id_episode%TYPE,
        i_report                    IN VARCHAR2,
        o_pat_problem               OUT pk_types.cursor_type,
        o_pat_prob_unaware_active   OUT pk_types.cursor_type,
        o_pat_prob_unaware_outdated OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_problem
    (
        i_lang                      IN language.id_language%TYPE,
        i_pat                       IN pat_problem.id_patient%TYPE,
        i_status                    IN pat_problem.flg_status%TYPE,
        i_type                      IN VARCHAR2,
        i_prof                      IN profissional,
        o_pat_problem               OUT pk_types.cursor_type,
        o_pat_prob_unaware_active   OUT pk_types.cursor_type,
        o_pat_prob_unaware_outdated OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_problem
    (
        i_lang                      IN language.id_language%TYPE,
        i_pat                       IN pat_problem.id_patient%TYPE,
        i_status                    IN pat_problem.flg_status%TYPE,
        i_type                      IN VARCHAR2,
        i_prof                      IN profissional,
        i_problem                   IN pat_problem.id_pat_problem%TYPE,
        o_pat_problem               OUT pk_types.cursor_type,
        o_pat_prob_unaware_active   OUT pk_types.cursor_type,
        o_pat_prob_unaware_outdated OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get the active problems that were registed as diagnoses in previous episodes
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                Patient ID
    * @param i_episode                Episode ID
    * @param o_epis_diagnosis         List of episode diagnosis IDs
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         José Silva
    * @version                        2.6.2.1
    * @since                          2012/03/21
    **********************************************************************************************/
    FUNCTION get_pat_prob_active_diag
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        o_epis_diagnosis OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_problem_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_problem_status OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_problem_nature
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_problem_nature OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Search all diagnosis on the DIAGNOSIS table
    *
    * @param i_lang                   Language ID
    * @param i_episode                Episode ID
    * @param i_criteria               String to search
    * @param i_diag_parent            Diagnosis parent, if it exists
    * @param i_flg_type               Protocol to be used (ICPC2, ICD9, ...), if it exists
    * @param i_prof                   Professional object
    * @param o_diagnosis              Cursor containing the diagnosis info
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui de Sousa Neves
    * @version                        1.0       
    * @since                          2006/11/20
    * @alter                          RdSN/João Eiras 2008/02/20 Improved performance
    **********************************************************************************************/

    FUNCTION get_diagnosis
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_patient       IN patient.id_patient%TYPE DEFAULT NULL,
        i_criteria      IN VARCHAR2,
        i_diag_parent   IN diagnosis.id_diagnosis_parent%TYPE,
        i_flg_type      IN diagnosis.flg_type%TYPE,
        i_prof          IN profissional,
        i_flg_task_type IN VARCHAR2 DEFAULT pk_alert_constant.g_diag_area_problems,
        o_diagnosis     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Multitype diagnoses search. Based on GET_DIAGNOSIS.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_flg_type     diagnosis types flags
    * @param i_diag_parent  parent diagnosis identifier
    * @param i_criteria     user query
    * @param i_format_text  apply styles to diagnoses names? Y/N
    * @param o_diagnosis    diagnoses data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/11/23
    */
    FUNCTION get_diagnosis_mt
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_type    IN table_varchar,
        i_diag_parent IN diagnosis.id_diagnosis_parent%TYPE,
        i_criteria    IN VARCHAR2,
        i_format_text IN VARCHAR2,
        o_diagnosis   OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Multitype diagnoses search. Based on GET_DIAGNOSIS.
    *
    * @param i_lang         language identifier
    * @param i_episode      Episode ID
    * @param i_prof         logged professional structure
    * @param i_flg_type     diagnosis types flags
    * @param i_diag_parent  parent diagnosis identifier
    * @param i_criteria     user query
    * @param i_format_text  apply styles to diagnoses names? Y/N
    * @param i_auto_search  Auto Search (show the diagnosis diferencial and most frequent problem)
    * @param o_diagnosis    diagnoses data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/11/23
    */
    FUNCTION get_diagnosis_mt_new
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_patient       IN patient.id_patient%TYPE DEFAULT NULL,
        i_prof          IN profissional,
        i_flg_type      IN table_varchar,
        i_diag_parent   IN diagnosis.id_diagnosis_parent%TYPE,
        i_criteria      IN VARCHAR2,
        i_format_text   IN VARCHAR2,
        i_flg_task_type IN VARCHAR2 DEFAULT pk_alert_constant.g_diag_area_problems,
        o_diagnosis     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_pat_problem_array
    (
        i_lang                   IN language.id_language%TYPE,
        i_epis                   IN episode.id_episode%TYPE,
        i_pat                    IN pat_problem.id_patient%TYPE,
        i_prof                   IN profissional,
        i_prof_cat_type          IN category.flg_type%TYPE,
        i_flg_area               IN table_varchar DEFAULT NULL,
        i_diagnosis              IN table_number,
        i_alert_diag             IN table_number,
        i_desc_problem           IN table_varchar,
        i_flg_status             IN table_varchar,
        i_notes                  IN table_varchar,
        i_flg_nature             IN table_varchar,
        i_header_warning         IN table_varchar,
        i_flg_complications      IN table_varchar DEFAULT NULL,
        i_precaution_measure     IN table_table_number,
        i_cdr_call               IN cdr_event.id_cdr_call%TYPE,
        i_flg_cda_reconciliation IN pat_history_diagnosis.flg_cda_reconciliation%TYPE DEFAULT pk_alert_constant.g_no,
        i_dt_diagnosed           IN table_varchar,
        i_dt_diagnosed_precision IN table_varchar,
        i_dt_resolved            IN table_varchar,
        i_dt_resolved_precision  IN table_varchar,
        i_location               IN table_number DEFAULT NULL,
        i_flg_epis_prob          IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_prob_group             IN table_number DEFAULT NULL,
        o_msg                    OUT VARCHAR2,
        o_msg_title              OUT VARCHAR2,
        o_flg_show               OUT VARCHAR2,
        o_button                 OUT VARCHAR2,
        o_type                   OUT table_varchar,
        o_ids                    OUT table_number,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_pat_problem_array_nc
    (
        i_lang                   IN language.id_language%TYPE,
        i_epis                   IN episode.id_episode%TYPE,
        i_pat                    IN pat_problem.id_patient%TYPE,
        i_prof                   IN profissional,
        i_prof_cat_type          IN category.flg_type%TYPE,
        i_flg_area               IN table_varchar DEFAULT NULL,
        i_dt_register            IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        i_diagnosis              IN table_number,
        i_alert_diag             IN table_number,
        i_desc_problem           IN table_varchar,
        i_flg_status             IN table_varchar,
        i_notes                  IN table_varchar,
        i_flg_nature             IN table_varchar,
        i_header_warning         IN table_varchar,
        i_flg_complications      IN table_varchar DEFAULT NULL,
        i_precaution_measure     IN table_table_number,
        i_cdr_call               IN cdr_event.id_cdr_call%TYPE,
        i_flg_cda_reconciliation IN pat_history_diagnosis.flg_cda_reconciliation%TYPE DEFAULT pk_alert_constant.g_no,
        i_dt_diagnosed           IN table_varchar,
        i_dt_diagnosed_precision IN table_varchar,
        i_dt_resolved            IN table_varchar,
        i_dt_resolved_precision  IN table_varchar,
        i_location               IN table_number DEFAULT NULL,
        i_flg_epis_prob          IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_prob_group             IN table_number DEFAULT NULL,
        o_msg                    OUT VARCHAR2,
        o_msg_title              OUT VARCHAR2,
        o_flg_show               OUT VARCHAR2,
        o_button                 OUT VARCHAR2,
        o_type                   OUT table_varchar,
        o_ids                    OUT table_number,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_pat_problem_array
    (
        i_lang                   IN language.id_language%TYPE,
        i_epis                   IN episode.id_episode%TYPE,
        i_pat                    IN pat_problem.id_patient%TYPE,
        i_prof                   IN profissional,
        i_desc_problem           IN table_varchar,
        i_flg_status             IN table_varchar,
        i_notes                  IN table_varchar,
        i_prof_cat_type          IN category.flg_type%TYPE,
        i_diagnosis              IN table_number,
        i_flg_nature             IN table_varchar,
        i_precaution_measure     IN table_table_number,
        i_header_warning         IN table_varchar,
        i_dt_diagnosed           IN table_varchar,
        i_dt_diagnosed_precision IN table_varchar,
        i_dt_resolved            IN table_varchar,
        i_dt_resolved_precision  IN table_varchar,
        i_location               IN table_number,
        o_msg                    OUT VARCHAR2,
        o_msg_title              OUT VARCHAR2,
        o_flg_show               OUT VARCHAR2,
        o_button                 OUT VARCHAR2,
        o_type                   OUT table_varchar,
        o_ids                    OUT table_number,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_problem_det_internal
    (
        i_lang         IN language.id_language%TYPE,
        i_pat_prob     IN pat_problem.id_pat_problem%TYPE,
        i_type         IN VARCHAR2,
        i_prof         IN profissional,
        i_problem_view IN VARCHAR2,
        o_problem      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_problem_det
    (
        i_lang         IN language.id_language%TYPE,
        i_pat_prob     IN pat_problem.id_pat_problem%TYPE,
        i_type         IN VARCHAR2,
        i_prof         IN profissional,
        i_problem_view IN VARCHAR2 DEFAULT g_problem_view_patient,
        o_problem      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pat_problem_array
    (
        i_lang                  IN language.id_language%TYPE,
        i_epis                  IN episode.id_episode%TYPE,
        i_pat                   IN pat_problem.id_patient%TYPE,
        i_prof                  IN profissional,
        i_id_pat_problem        IN table_number,
        i_flg_status            IN table_varchar,
        i_notes                 IN table_varchar,
        i_type                  IN table_varchar,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_flg_nature            IN table_varchar,
        i_precaution_measure    IN table_table_number,
        i_header_warning        IN table_varchar,
        i_dt_resolved           IN table_varchar DEFAULT NULL,
        i_dt_resolved_precision IN table_varchar DEFAULT NULL,
        i_flg_epis_prob         IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_prob_group            IN table_number DEFAULT NULL,
        i_seq_num               IN table_number DEFAULT NULL,
        o_type                  OUT table_varchar,
        o_ids                   OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pat_problem_array_nc
    (
        i_lang                  IN language.id_language%TYPE,
        i_epis                  IN episode.id_episode%TYPE,
        i_pat                   IN pat_problem.id_patient%TYPE,
        i_prof                  IN profissional,
        i_id_pat_problem        IN table_number,
        i_flg_status            IN table_varchar,
        i_notes                 IN table_varchar,
        i_type                  IN table_varchar,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_flg_nature            IN table_varchar,
        i_precaution_measure    IN table_table_number,
        i_header_warning        IN table_varchar,
        i_dt_register           IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        i_dt_resolved           IN table_varchar,
        i_dt_resolved_precision IN table_varchar,
        i_flg_epis_prob         IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_prob_group            IN table_number,
        i_seq_num               IN table_number,
        o_type                  OUT table_varchar,
        o_ids                   OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pat_problem_array_dt_nc
    (
        i_lang                   IN language.id_language%TYPE,
        i_epis                   IN episode.id_episode%TYPE,
        i_pat                    IN pat_problem.id_patient%TYPE,
        i_prof                   IN profissional,
        i_id_pat_problem         IN table_number,
        i_flg_status             IN table_varchar,
        i_notes                  IN table_varchar,
        i_type                   IN table_varchar,
        i_prof_cat_type          IN category.flg_type%TYPE,
        i_flg_nature             IN table_varchar,
        i_precaution_measure     IN table_table_number,
        i_header_warning         IN table_varchar,
        i_dt_register            IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        i_flg_area               IN pat_history_diagnosis.flg_area%TYPE,
        i_flg_complications      IN table_varchar DEFAULT NULL,
        i_dt_diagnosed           IN table_varchar,
        i_dt_diagnosed_precision IN table_varchar,
        i_dt_resolved            IN table_varchar,
        i_dt_resolved_precision  IN table_varchar,
        i_location               IN table_number DEFAULT NULL,
        i_flg_epis_prob          IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_prob_group             IN table_number DEFAULT NULL,
        i_seq_num                IN table_number DEFAULT NULL,
        o_type                   OUT table_varchar,
        o_ids                    OUT table_number,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pat_problem_array_dt
    (
        i_lang                   IN language.id_language%TYPE,
        i_epis                   IN episode.id_episode%TYPE,
        i_pat                    IN pat_problem.id_patient%TYPE,
        i_prof                   IN profissional,
        i_id_pat_problem         IN table_number,
        i_flg_status             IN table_varchar,
        i_notes                  IN table_varchar,
        i_type                   IN table_varchar,
        i_prof_cat_type          IN category.flg_type%TYPE,
        i_flg_nature             IN table_varchar,
        i_precaution_measure     IN table_table_number,
        i_header_warning         IN table_varchar,
        i_flg_area               IN pat_history_diagnosis.flg_area%TYPE,
        i_flg_complications      IN table_varchar DEFAULT NULL,
        i_dt_diagnosed           IN table_varchar,
        i_dt_diagnosed_precision IN table_varchar,
        i_dt_resolved            IN table_varchar,
        i_dt_resolved_precision  IN table_varchar,
        i_location               IN table_number,
        i_flg_epis_prob          IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_prob_group             IN table_number DEFAULT NULL,
        i_seq_num                IN table_number DEFAULT NULL,
        o_type                   OUT table_varchar,
        o_ids                    OUT table_number,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_problem_protocol
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_type    IN pat_history_diagnosis.flg_area%TYPE,
        o_problem_prot OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pat_allergy
    (
        i_lang             IN language.id_language%TYPE,
        i_epis             IN episode.id_episode%TYPE,
        i_id_pat_allergy   IN pat_allergy.id_pat_allergy%TYPE,
        i_id_pat           IN pat_allergy.id_patient%TYPE,
        i_prof             IN profissional,
        i_allergy          IN pat_allergy.id_allergy%TYPE,
        i_drug_pharma      IN pat_allergy.id_drug_pharma%TYPE,
        i_notes            IN pat_allergy.notes%TYPE,
        i_dt_first_time    IN pat_allergy.dt_first_time_tstz%TYPE,
        i_flg_type         IN pat_allergy.flg_type%TYPE,
        i_flg_approved     IN pat_allergy.flg_aproved%TYPE,
        i_flg_status       IN pat_allergy.flg_status%TYPE,
        i_flg_nature       IN pat_allergy.flg_nature%TYPE,
        i_dt_symptoms      IN VARCHAR2,
        i_id_cancel_reason IN pat_allergy.id_cancel_reason%TYPE,
        i_cancel_notes     IN pat_allergy.cancel_notes%TYPE,
        i_prof_cat_type    IN category.flg_type%TYPE,
        i_dt_resolution    IN pat_allergy.dt_resolution%TYPE,
        o_flg_show         OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg_text         OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_problem_list
    (
        i_lang      IN language.id_language%TYPE,
        i_id_parent IN diagnosis.id_diagnosis_parent%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_flg_type  IN diagnosis.flg_type%TYPE,
        i_search    IN VARCHAR2,
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_problem_system
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_search      IN VARCHAR2,
        o_problem_sys OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_problem_organ
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_search      IN VARCHAR2,
        i_system_app  IN system_apparati.id_system_apparati%TYPE,
        o_problem_org OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************************
    * Alterar / cancelar problema do doente. 
    * Usada no ecrã de mudança de estado dos "Problemas" do doente, pq permite a mudança de estado de vários problemas em simultâneo.
    * It does not perform a commit. 
    * Should not be called from flash, it's for database internal use.
    * 
    * @param i_lang The language id
    * @param i_epis The episode id
    * @param i_pat The patient id
    * @param i_prof The professional, institution and software ids    
    * @param i_id_pat_problem An array with pat problem ids
    * @param i_flg_status An array the the flg status values
    * @param i_notes An array with notes
    * @param i_type An array with pat problem types
    * @param i_id_prof_cat_type the professional category type
    * @param i_flg_nature An array with patient problem natures
    * @param o_error An error message to explain what went wrong if the execution fails.
    *
    * @return True if succeded, false otherwise.
    *
    * @author Luís Gaspar, copied from set_pat_problem_array
    * @version 0.1
    * @since 2007/05/10
    */
    FUNCTION set_pat_problem_array_internal
    (
        i_lang           IN language.id_language%TYPE,
        i_epis           IN episode.id_episode%TYPE,
        i_pat            IN pat_problem.id_patient%TYPE,
        i_prof           IN profissional,
        i_id_pat_problem IN table_number,
        i_flg_status     IN table_varchar,
        i_notes          IN table_varchar,
        i_type           IN table_varchar,
        i_prof_cat_type  IN category.flg_type%TYPE,
        i_flg_nature     IN table_varchar,
        i_dt_resolution  IN table_varchar,
        i_dt_register    IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pat_problem_array_internal
    (
        i_lang           IN language.id_language%TYPE,
        i_epis           IN episode.id_episode%TYPE,
        i_pat            IN pat_problem.id_patient%TYPE,
        i_prof           IN profissional,
        i_id_pat_problem IN table_number,
        i_flg_status     IN table_varchar,
        i_dt_symptoms    IN table_varchar,
        i_notes          IN table_varchar,
        i_type           IN table_varchar,
        i_prof_cat_type  IN category.flg_type%TYPE,
        i_flg_nature     IN table_varchar,
        i_dt_resolution  IN table_varchar,
        i_dt_register    IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Updates/Cancels problems based on every diagnosis (Both standards diagnosis - like ICD9 - and ALERT diagnosis)
    * Similar to PK_PROBLEM.set_pat_problem_array but supporting ALERT diagnosis
    *
    * @param i_lang                   Language ID
    * @param i_epis                   Episode ID
    * @param i_pat                    Patient ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat_problem         Array of problem ID
    * @param i_flg_status             Array of problem status
    * @param i_notes                  Array of problem notes
    * @param i_type                   Array of problem types (P - Problems, A - Allergies, H - Habits)
    * @param i_prof_cat_type          Professional category
    * @param i_flg_nature             Array of problem nature
    
    * @param o_error                  Error message
                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui de Sousa Neves
    * @since                          2007/06/17
    **********************************************************************************************/
    FUNCTION set_pat_problem_array_new
    (
        i_lang           IN language.id_language%TYPE,
        i_epis           IN episode.id_episode%TYPE,
        i_pat            IN pat_problem.id_patient%TYPE,
        i_prof           IN profissional,
        i_id_pat_problem IN table_number,
        i_flg_status     IN table_varchar,
        i_notes          IN table_varchar,
        i_type           IN table_varchar,
        i_prof_cat_type  IN category.flg_type%TYPE,
        i_flg_nature     IN table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Created new problems based on epis_diagnosis
    *
    * @param i_lang                   Language ID
    * @param i_epis                   Episode ID
    * @param i_pat                    Patient ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_desc_problem           Array of problem descriptions
    * @param i_flg_status             Array of problem status
    * @param i_notes                  Array of problem notes
    * @param i_dt_symptoms            Array of problem onset (YYYY-MM-DD String)
    * @param i_diagnosis              List of diagnoses id's
    * @param i_alert_diagnosis        List of diagnoses syonyms id's
    * @param i_epis_anamnesis         Array of problem anamnesis (complaint/history)
    * @param i_prof_cat_type          Professional category
    * @param i_epis_diagnosis         Array of problem diagnosis
    * @param i_flg_nature             Array of problem nature
    
    * @param o_msg                    Message returned
    * @param o_msg_title              Message title returned
    * @param o_flg_show               Flag to determine if message is shown
    * @param o_button                 Button type to show on the dialog box
    * @param o_error                  Error message
                        
    * @return                         true or false on success or error
    * 
    * @author                         Sílvia Freitas
    * @since                          2007/07/06
    **********************************************************************************************/
    FUNCTION create_pat_problem_epis_diag
    (
        i_lang            IN language.id_language%TYPE,
        i_epis            IN episode.id_episode%TYPE,
        i_pat             IN pat_problem.id_patient%TYPE,
        i_prof            IN profissional,
        i_desc_problem    IN table_varchar,
        i_flg_status      IN table_varchar,
        i_notes           IN table_varchar,
        i_dt_symptoms     IN table_varchar,
        i_diagnosis       IN table_number,
        i_alert_diagnosis IN table_number,
        i_epis_anamnesis  IN table_number,
        i_prof_cat_type   IN category.flg_type%TYPE,
        i_epis_diagnosis  IN table_number,
        i_flg_nature      IN table_varchar,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_flg_show        OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    ---------------------------------------------------------------------
    ------------- New problem list functions ----------------------------
    ---------------------------------------------------------------------   

    /********************************************************************************************
    * Returns all the patient's problems, including problems, relevant diseases, diagnosis and alergies.
    * Based on the old PK_PROBLEMS.GET_PAT_PROBLEM function but refering to the pat_history_diagnosis table.
    *
    * @param i_lang                   Language ID
    * @param i_pat                    Patient ID
    * @param i_status                 Record status (active, passive, canceled...). 
    *                                 If it is null, returns all records
    * @param i_type                   Type of records wanted (P - problems, D - relevant diseases,
    *                                 E - diagnosis, A - alergies, H - habits)
    *                                 If it is null, returns all records
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_pat_problem            Cursor containing the problems
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                         Rui de Sousa Neves
    * @version                        1.0
    * @since                          2007/09/13
    **********************************************************************************************/

    FUNCTION get_pat_problem_new
    (
        i_lang                      IN language.id_language%TYPE,
        i_pat                       IN pat_problem.id_patient%TYPE,
        i_status                    IN pat_problem.flg_status%TYPE,
        i_type                      IN VARCHAR2,
        i_prof                      IN profissional,
        i_problem                   IN pat_problem.id_pat_problem%TYPE DEFAULT NULL,
        i_episode                   IN pat_problem.id_episode%TYPE,
        i_report                    IN VARCHAR2,
        o_pat_problem               OUT pat_problem_cur,
        o_pat_prob_unaware_active   OUT pk_types.cursor_type,
        o_pat_prob_unaware_outdated OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Returns history of status and nature changes on a problem
    * Based on the old PK_PROBLEMS.GET_PAT_PROBLEM_DET function but refering to the pat_history_diagnosis table.
    *
    * @param i_lang                   Language ID
    * @param i_pat_prob               Problem ID
    * @param i_type                   Type of records wanted (P - problems, A - alergies)
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_problem                Cursor containing the problem's changes
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                         Rui de Sousa Neves
    * @version                        1.0
    * @since                          2007/09/14
    **********************************************************************************************/

    FUNCTION get_pat_problem_det_new
    (
        i_lang     IN language.id_language%TYPE,
        i_pat_prob IN pat_problem.id_pat_problem%TYPE,
        i_type     IN VARCHAR2,
        i_prof     IN profissional,
        o_problem  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Returns history of status and nature changes on a problem
    * Based on the old PK_PROBLEMS.GET_PAT_PROBLEM_DET function but refering to the pat_history_diagnosis table.
    *
    * @param i_lang                   Language ID
    * @param i_pat_prob               Problem ID
    * @param i_type                   Type of records wanted (P - problems, A - alergies)
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_problem_view           Type of problem view (EP - episode problems, PP - patient problem)
    * @param o_problem                Cursor containing the problem's changes
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                         Paulo Teixeira
    * @version                        v2.6.0
    * @since                          2010/02/10
    **********************************************************************************************/

    FUNCTION get_pat_problem_det_new_aux
    (
        i_lang         IN language.id_language%TYPE,
        i_pat_prob     IN pat_problem.id_pat_problem%TYPE,
        i_type         IN VARCHAR2,
        i_prof         IN profissional,
        i_problem_view IN VARCHAR2,
        o_problem      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns history of status and nature changes on a problem
    * Based on the old PK_PROBLEMS.GET_PAT_PROBLEM_DET function but refering to the pat_history_diagnosis table.
    *
    * @param i_lang                   Language ID
    * @param i_pat_prob               Problem ID
    * @param i_type                   Type of records wanted (P - problems, A - alergies)
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_problem_view           Type of problem view (EP - episode problems, PP - patient problem)
    * @param o_problem                Cursor containing the original problem
    * @param o_problem_hist           table_table_varchar containing the problem's changes
    * @param o_review_hist            cursor containing review list
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                         Paulo Teixeira
    * @version                        v2.6.0
    * @since                          2010/02/10
    **********************************************************************************************/

    FUNCTION get_pat_problem_det_new_hist
    (
        i_lang         IN language.id_language%TYPE,
        i_pat_prob     IN pat_problem.id_pat_problem%TYPE,
        i_type         IN VARCHAR2,
        i_prof         IN profissional,
        i_problem_view IN VARCHAR2 DEFAULT g_problem_view_patient,
        o_problem      OUT pk_types.cursor_type,
        o_problem_hist OUT table_table_varchar,
        o_review_hist  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns history of status and nature changes on a problem
    * Based on the old PK_PROBLEMS.GET_PAT_PROBLEM_DET function but refering to the pat_history_diagnosis table.
    *
    * @param i_lang                   Language ID
    * @param i_pat_prob               Problem ID
    * @param i_type                   Type of records wanted (P - problems, A - alergies)
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_problem_view           Type of problem view (EP - episode problems, PP - patient problem)
    * @param o_problem                Cursor containing the original problem
    * @param o_problem_hist           table_table_varchar containing the problem's changes
    * @param o_review_hist            cursor containing review list
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                         Paulo Teixeira
    * @version                        v2.6.0
    * @since                          2010/02/10
    **********************************************************************************************/

    FUNCTION get_pat_problem_det_new_hist_d
    (
        i_lang         IN language.id_language%TYPE,
        i_pat_prob     IN pat_problem.id_pat_problem%TYPE,
        i_type         IN VARCHAR2,
        i_prof         IN profissional,
        i_problem_view IN VARCHAR2,
        o_problem      OUT pk_types.cursor_type,
        o_problem_hist OUT table_table_varchar,
        o_review_hist  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Returns history of status and nature changes on a problem
    * Based on the old PK_PROBLEMS.GET_PAT_PROBLEM_DET function but refering to the pat_history_diagnosis table.
    *
    * @param i_lang                   Language ID
    * @param i_pat_prob               Problem ID
    * @param i_type                   Type of records wanted (P - problems, A - alergies)
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_problem                Cursor containing the original problem
    * @param o_problem_hist           table_table_varchar containing the problem's changes
    * @param o_review_hist            cursor containing review list
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                         Paulo Teixeira
    * @version                        v2.6.0
    * @since                          2010/02/10
    **********************************************************************************************/

    FUNCTION get_pat_problem_det_new_hist_a
    (
        i_lang         IN language.id_language%TYPE,
        i_pat_prob     IN pat_problem.id_pat_problem%TYPE,
        i_type         IN VARCHAR2,
        i_prof         IN profissional,
        o_problem      OUT pk_types.cursor_type,
        o_problem_hist OUT table_table_varchar,
        o_review_hist  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns history of status and nature changes on a problem
    * Based on the old PK_PROBLEMS.GET_PAT_PROBLEM_DET function but refering to the pat_history_diagnosis table.
    *
    * @param i_lang                   Language ID
    * @param i_pat_prob               Problem ID
    * @param i_type                   Type of records wanted (P - problems, A - alergies)
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_problem                Cursor containing the original problem
    * @param o_problem_hist           table_table_varchar containing the problem's changes
    * @param o_review_hist            cursor containing review list
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                         Paulo Teixeira
    * @version                        v2.6.0
    * @since                          2010/02/10
    **********************************************************************************************/

    FUNCTION get_pat_problem_det_new_hist_p
    (
        i_lang         IN language.id_language%TYPE,
        i_pat_prob     IN pat_problem.id_pat_problem%TYPE,
        i_type         IN VARCHAR2,
        i_prof         IN profissional,
        o_problem      OUT pk_types.cursor_type,
        o_problem_hist OUT table_table_varchar,
        o_review_hist  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Returns most recent ID for that alert_diagnosis / desc_pat_history_diagnosis
    *
    * @param i_lang                   Language ID
    * @param i_alert_diag             Alert Diagnosis ID
    * @param i_desc_phd               Description for the PHD
    * @param i_pat                    Patient ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_flg_canceled           Flg cancel (if canceled are to be returned or not - Y/N)
    *
    * @return                         PHD ID wanted
    *
    * @author                         Rui de Sousa Neves
    * @version                        1.0
    * @since                          2007/09/21
    **********************************************************************************************/

    FUNCTION get_pat_hist_diag_recent
    (
        i_lang         IN language.id_language%TYPE,
        i_alert_diag   IN pat_history_diagnosis.id_alert_diagnosis%TYPE,
        i_desc_phd     IN pat_history_diagnosis.desc_pat_history_diagnosis%TYPE,
        i_pat          IN patient.id_patient%TYPE,
        i_prof         IN profissional,
        i_flg_canceled IN VARCHAR
    ) RETURN pat_history_diagnosis.id_pat_history_diagnosis%TYPE;

    FUNCTION get_pat_hist_diag_recent
    (
        i_lang         IN language.id_language%TYPE,
        i_alert_diag   IN pat_history_diagnosis.id_alert_diagnosis%TYPE,
        i_desc_phd     IN pat_history_diagnosis.desc_pat_history_diagnosis%TYPE,
        i_pat          IN patient.id_patient%TYPE,
        i_prof         IN profissional,
        i_flg_canceled IN VARCHAR,
        i_flg_type     IN pat_history_diagnosis.flg_type%TYPE
    ) RETURN pat_history_diagnosis.id_pat_history_diagnosis%TYPE;
    /**
     * This function returns the status message string for the problem.
     * This function cannot be used by outside this package. This function
     * was not developed to access data base data directly. This function 
     * only build the string according to the i_flg_status and i_desc_status
     * parameters.
     *
     * @param  IN i_type               Problem type (H | A | P)
     * @param  IN i_flg_status         Flag status
     * @param  IN i_desc_status        Status description (already translated)
     * @param  IN i_date_problem       Problem's date
     *
     * @return VARCHAR2
     *
     * @version   2.4.4
     * @since     2009-Mar-05
     * @author    Thiago Brito
    */
    FUNCTION get_status_string
    (
        i_flg_status  IN VARCHAR2,
        i_desc_status IN VARCHAR2
    ) RETURN VARCHAR2;

    /**
     * This is an auxiliar function used by the VIEWER in order to get
     * the number of registers inside a determined area as well as
     * to get the first register for that area.
     *
     * @param     i_lang         language id
     * @param     i_prof         professional
     * @param     i_patient      patient id
     * @param     o_count        total number of registers
     * @param     o_first        description of the first register
     * @param     o_code         message's code
     * @param     o_date         date of the first occurrence
     * @param     o_fmt          first register
     *
     * @return BOOLEAN
     *
     * @version   2.4.4
     * @since     2008-NOV-13
     * @author    Thiago Brito
    */
    FUNCTION get_count_and_first
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        o_count              OUT NUMBER,
        o_first              OUT VARCHAR2,
        o_code               OUT VARCHAR2,
        o_date               OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_fmt                OUT VARCHAR2,
        o_id_alert_diagnosis OUT NUMBER,
        o_id_task_type       OUT NUMBER
    ) RETURN BOOLEAN;

    /**
     * This is an auxiliar function used by the VIEWER in order to get
     * the ordered list of all problems.
     *
     * @param     i_lang                  language id
     * @param     i_prof                  professional
     * @param     i_patient               patient id
     * @param     o_ordered_list          ordered list of all problems
     *
     * @return BOOLEAN
     * 
     * @version   2.4.4
     * @since     2008-NOV-13
     * @author    Thiago Brito
    */
    FUNCTION get_ordered_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        o_ordered_list OUT pk_types.cursor_type
    ) RETURN BOOLEAN;

    FUNCTION get_software
    (
        i_epis    IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE
    ) RETURN software.id_software%TYPE;

    FUNCTION get_institution
    (
        i_epis    IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE
    ) RETURN institution.id_institution%TYPE;

    FUNCTION get_prob_group
    (
        i_episode         IN episode.id_episode%TYPE,
        i_epis_prob_group IN epis_prob_group.id_epis_prob_group%TYPE
    ) RETURN NUMBER;

    FUNCTION get_language
    (
        i_epis    IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE
    ) RETURN language.id_language%TYPE;

    PROCEDURE upd_viewer_ehr_ea;

    FUNCTION upd_viewer_ehr_ea_pat
    (
        i_lang              IN language.id_language%TYPE,
        i_table_id_patients IN table_number,        
        i_ignore_error      IN boolean default false,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get nature field options.
    *
    * @param i_prof         logged professional structure
    * @param o_nat          nature field options
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/07/04
    */
    PROCEDURE get_nature_options
    (
        i_prof IN profissional,
        o_nat  OUT pk_types.cursor_type
    );

    /********************************************************************************************
    * Returns the problems onset list
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_onset                  Onset list
    * @param o_error                  Error Message
    *
    * @return                         True if success, False in case of error
    *
    * @author                         Sérgio Santos
    * @version                        1.0
    * @since                          2009/02/26
    **********************************************************************************************/
    FUNCTION get_problems_onset_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_onset OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the information of a specific problem. The problem can be in problems, relevant diseases, diagnosis and alergies.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_pat                    Patient ID
    * @param i_id_problem             The problem ID 
    * @param i_type                   Type of records wanted (P - problems, D - relevant diseases,
    *                                 E - diagnosis, A - alergies, H - habits)
    * @param o_pat_problem            Cursor containing the problems
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                         Sérgio Santos
    * @version                        1.0
    * @since                          2009/02/27
    **********************************************************************************************/
    FUNCTION get_pat_problem_info
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_pat         IN pat_problem.id_patient%TYPE,
        i_id_problem  IN NUMBER,
        i_type        IN VARCHAR2,
        o_pat_problem OUT NOCOPY pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_pat_problem_nc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_pat              IN pat_problem.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_problem       IN NUMBER,
        i_type             IN VARCHAR2,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes     IN pat_problem_hist.cancel_notes%TYPE,
        i_prof_cat_type    IN category.flg_type%TYPE,
        i_dt_register      IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        o_type             OUT table_varchar,
        o_ids              OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_pat_problem
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_pat              IN pat_problem.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_problem       IN NUMBER,
        i_type             IN VARCHAR2,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes     IN pat_problem_hist.cancel_notes%TYPE,
        i_prof_cat_type    IN category.flg_type%TYPE,
        o_type             OUT table_varchar,
        o_ids              OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns all the patient's problems, including problems, relevant diseases, diagnosis and alergies for the current episode.
    * Show the transitions in the state of the problem in the current episode.
    * This function uses the function tf_pat_problem_epis_stat to verify the transitions between states ir order to contruct a
    * new array that will by returned.
    *
    * @param i_lang                   Language ID
    * @param i_pat                    Patient ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    *
    * @param o_problem_allergy        Cursor containing the allergy
    * @param o_problem_habit          Cursor containing the habits
    * @param o_problem_relev          Cursor containing the relevant deceases
    * @param o_problem_diag           Cursor containing the diagnosis
    * @param o_problem_problem        Cursor containing the problems
    *   
    * @param o_error                  Error Object
    *
    * @return                         true or false on success or error
    *
    * @author                         Sérgio Santos
    * @version                        1.0
    * @since                          2009/03/25
    **********************************************************************************************/
    FUNCTION get_pat_problem_epis_stat
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        o_problem_allergy OUT NOCOPY pk_types.cursor_type,
        o_problem_habit   OUT NOCOPY pk_types.cursor_type,
        o_problem_relev   OUT NOCOPY pk_types.cursor_type,
        o_problem_diag    OUT NOCOPY pk_types.cursor_type,
        o_problem_problem OUT NOCOPY pk_types.cursor_type,
        o_new_problem     OUT VARCHAR2,
        o_edited_problem  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION tf_pat_problem_epis_stat
    (
        i_lang              IN language.id_language%TYPE,
        i_id_episode        IN episode.id_episode%TYPE,
        i_problem_list      IN t_coll_epis_problem,
        i_problem_list_hist IN t_coll_epis_problem
    ) RETURN problem_rec_status_edition;

    /**
    * Registers a review for a problem.
    *
    * @param i_lang            language id
    * @param i_prof            professional who is inserting this review
    * @param i_id_pat_problem  problem id
    * @param i_review_notes    review notes (optional)
    * @param o_error           error message 
    *
    * @author                  rui.baeta
    * @since                   2009-10-23
    * @version                 v2.5.0.7
    */
    FUNCTION set_pat_problem_review
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_pat_problem IN pat_problem.id_pat_problem%TYPE,
        i_flg_source     IN VARCHAR2,
        i_review_notes   IN review_detail.review_notes%TYPE DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * Registers a review for a problem.
    *
    * @param i_lang            language id
    * @param i_prof            professional who is inserting this review
    * @param i_id_pat_problem  problem id
    * @param i_review_notes    review notes (optional)
    * @param o_error           error message 
    *
    * @author                  rui.baeta
    * @since                   2009-10-23
    * @version                 v2.5.0.7
    */
    FUNCTION set_pat_problem_review
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_pat_problem IN pat_problem.id_pat_problem%TYPE,
        i_flg_source     IN VARCHAR2,
        i_review_notes   IN review_detail.review_notes%TYPE DEFAULT NULL,
        i_episode        IN review_detail.id_episode%TYPE,
        i_flg_auto       IN review_detail.flg_auto%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * Registers a review for a problem.
    *
    * @param i_lang            language id
    * @param i_prof            professional who is inserting this review
    * @param i_id_pat_problem  problem id
    * @param i_review_notes    review notes (optional)
    * @param o_error           error message 
    *
    * @author                  rui.baeta
    * @since                   2009-10-23
    * @version                 v2.5.0.7
    */
    FUNCTION set_pat_problem_review
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_pat_problem IN table_number,
        i_flg_source     IN table_varchar,
        i_review_notes   IN review_detail.review_notes%TYPE DEFAULT NULL,
        i_episode        IN review_detail.id_episode%TYPE,
        i_flg_auto       IN review_detail.flg_auto%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * Returns the possible precautions available
    *
    * @param i_lang            language id
    * @param i_prof            professional who is inserting this review
    * @param o_problem_problem Cursor containing the problems
    * @param o_error           error message 
    *
    * @author                  
    * @since                   2010-01-05
    * @version                 v2.6.0
    */
    FUNCTION get_precaution_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_precautions OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the possible precautions available
    *
    * @param i_lang            language id
    * @param i_prof            professional who is inserting this review
    * @param i_pat_history_diagnosis Cursor containing the problems 
    *
    * @return                table_number with the precaution id 
    * @author                  Paulo Teixeira
    * @since                   2010-02-10
    * @version                 v2.6.0
    */
    FUNCTION get_pat_precaution_list_cod
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_pat_history_diagnosis IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE
    ) RETURN table_number;

    /**
    * Returns the possible precautions available
    *
    * @param i_lang            language id
    * @param i_prof            professional who is inserting this review
    * @param i_pat_history_diagnosis Cursor containing the problems
    *
    * @return                table_varchar with the precaution id 
    *
    * @author                  Paulo Teixeira
    * @since                   2010-02-10
    * @version                 v2.6.0
    */
    FUNCTION get_pat_precaution_list_desc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_pat_history_diagnosis IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE
    ) RETURN table_varchar;

    /**
    * Add a problem to the list of problems registered by the professional
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_id_episode         The episode id
    * @param i_pat                The patient id
    * @param i_id_problem         Problem id
    * @param i_flg_type           Type of problem
    *
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Paulo Teixeira
    * @version               2.6.0
    * @since                 2010/01/27
    */
    FUNCTION set_registered_by_me
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN epis_info.id_episode%TYPE,
        i_pat        IN patient.id_patient%TYPE,
        i_id_problem IN NUMBER,
        i_flg_type   IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Removes a problem from the list of problems registered by the professional
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_id_episode         The episode id
    * @param i_pat                The patient id
    * @param i_id_problem         Problem id
    * @param i_flg_type           Type of problem
    *
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Paulo Teixeira
    * @version               2.6.0
    * @since                 2010/01/27
    */
    FUNCTION set_unregistered_by_me
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN epis_info.id_episode%TYPE,
        i_pat        IN patient.id_patient%TYPE,
        i_id_problem IN NUMBER,
        i_flg_type   IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Add a problem to the list of problems registered by the professional
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_id_episode         The episode id
    * @param i_pat                The patient id
    * @param i_id_problem         Problem id
    * @param i_flg_type           Type of problem
    * @param i_flag_active        Active identifier
    *
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Paulo Teixeira
    * @version               2.6.0
    * @since                 2010/01/27
    */
    FUNCTION set_register_by_me_nc
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN epis_info.id_episode%TYPE,
        i_pat         IN patient.id_patient%TYPE,
        i_id_problem  IN NUMBER,
        i_flg_type    IN VARCHAR2,
        i_flag_active IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns flg_active field of PROFESSIONAL_RECORD
    *
    * @param i_prof               Professional identifier
    * @param i_id_problem         Problem id
    * @param i_flg_type           Type of problem
    *
    * @return                flg_active field of PROFESSIONAL_RECORD
    *
    * @author                Paulo Teixeira
    * @version               2.6.0
    * @since                 2010/01/29
    */
    FUNCTION get_registered_by_me
    (
        i_prof       IN profissional,
        i_id_problem IN professional_record.id_record%TYPE,
        i_flg_type   IN professional_record.flg_type%TYPE
    ) RETURN VARCHAR2;

    /**
    * Add a precaution to the history of precautions registered by the professional
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_id_episode         The episode id
    * @param i_pat                The patient id
    * @param I_PAT_HISTORY_DIAGNOSIS    pat_hist_diag_precaution identifier
    * @param I_PRECAUTION               precaution identifier
    *
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Paulo Teixeira
    * @version               2.6.0
    * @since                 2010/02/05
    */
    FUNCTION set_pat_hist_diag_precau_nc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN epis_info.id_episode%TYPE,
        i_pat                   IN patient.id_patient%TYPE,
        i_pat_history_diagnosis IN pat_hist_diag_precaution.id_pat_history_diagnosis%TYPE,
        i_precaution            IN table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns id_precaution field of PAT_HIST_DIAG_PRECAUTION table
    *
    * @param i_pat_history_diagnosis         pat_hist_diag_precaution identifier
    *
    * @return                table_number of id_precaution field of PAT_HIST_DIAG_PRECAUTION
    *
    * @author                Paulo Teixeira
    * @version               2.6.0
    * @since                 2010/02/05
    */
    FUNCTION get_pat_hist_diag_precaution(i_pat_history_diagnosis IN pat_hist_diag_precaution.id_pat_history_diagnosis%TYPE)
        RETURN table_number;

    /**
    * Returns patient flag warning Y or N 
    *
    * @param i_lang               Language identifier
    * @param i_pat                The patient id
    * @param i_prof               Professional identifier
    *
    * @return                Y or N
    *
    * @author                Paulo Teixeira
    * @version               2.6.0
    * @since                 2010/02/22
    */
    FUNCTION get_pat_flg_warning
    (
        i_lang IN language.id_language%TYPE,
        i_pat  IN pat_problem.id_patient%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2;

    /**
    * Returns patient diag_condition Y or N 
    *
    * @param i_lang               Language identifier
    * @param i_pat                The patient id
    * @param i_prof               Professional identifier
    *
    * @return                Y or N
    *
    * @author                Paulo Teixeira
    * @version               2.6.0
    * @since                 2010/02/22
    */
    FUNCTION check_pat_diag_condition
    (
        i_lang IN language.id_language%TYPE,
        i_pat  IN pat_problem.id_patient%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2;

    /**
    * Returns patient precaution Y or N 
    *
    * @param i_lang               Language identifier
    * @param i_pat                The patient id
    * @param i_prof               Professional identifier
    *
    * @return                Y or N
    *
    * @author                Paulo Teixeira
    * @version               2.6.0
    * @since                 2010/02/22
    */
    FUNCTION check_pat_precaution
    (
        i_lang IN language.id_language%TYPE,
        i_pat  IN pat_problem.id_patient%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2;

    /**
    * Returns patient precaution list 
    *
    * @param i_lang               Language identifier
    * @param i_pat                The patient id
    * @param i_prof               Professional identifier
    * @param o_precaution_list         string containing the history data
    * @param o_precaution_number         number of elements of the history data
    * @param o_error           error message 
    * @return                boolean
    *
    * @author                Paulo Teixeira
    * @version               2.6.0
    * @since                 2010/02/22
    */
    FUNCTION get_pat_precaution
    (
        i_lang              IN language.id_language%TYPE,
        i_pat               IN pat_problem.id_patient%TYPE,
        i_prof              IN profissional,
        o_precaution_list   OUT VARCHAR2,
        o_precaution_number OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * Returns patient problem with precautions 
    *
    * @param i_lang               Language identifier
    * @param i_pat                The patient id
    * @param i_prof               Professional identifier
    * @param o_precaution_list         string containing list of problems
    * @param o_precaution_number         number of problems
    * @param o_error           error message 
    * @return                boolean
    *
    * @author                Paulo Teixeira
    * @version               2.6.0
    * @since                 2010/02/22
    */
    FUNCTION get_pat_precaution_problem
    (
        i_lang           IN language.id_language%TYPE,
        i_pat            IN pat_problem.id_patient%TYPE,
        i_prof           IN profissional,
        o_problem_list   OUT VARCHAR2,
        o_problem_number OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * this function fixes the pat_history_diagnosis ID_PAT_HISTORY_DIAGNOSIS and ID_PAT_HISTORY_DIAGNOSIS_new relations
    *
    * @param i_lang            language id
    * @param i_prof            professional who is inserting this review
    * @param i_pat             PATIENT_id
    * @param i_id_pat_problem  problem id    
    * @param o_error           error message 
    *
    * @author                  Paulo teixeira
    * @since                   2010-03-01
    * @version                 v 2.5.0.7.6.1 
    */
    FUNCTION set_problem_history
    (
        i_lang           IN language.id_language%TYPE,
        i_pat            IN patient.id_patient%TYPE,
        i_prof           IN profissional,
        i_id_pat_problem IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * GET review status
    *
    * @param i_lang            language id
    * @param i_prof            professional who is inserting this review    
    * @param i_id_pat_problem  ID PROBLEM
    * @param i_flg_source      SOURCE PROBLEM FLAG
    * @param i_episode         EPISODE IDENTIFIER
    * @param i_STATUS         STATUS FLAG
    *
    * @author                  Paulo teixeira
    * @since                   2010-10-26
    * @version                 v 2.5.1.2
    */
    FUNCTION get_review
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_pat_problem IN review_detail.id_record_area%TYPE,
        i_flg_source     IN VARCHAR2,
        i_episode        IN review_detail.id_episode%TYPE,
        i_status         IN VARCHAR2
    ) RETURN table_varchar;

    /********************************************************************************************
    * get_pat_problem_report
    *
    * @param i_lang                   Language ID
    * @param i_pat                    Patient ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode 
    * @param i_report
    * @param o_pat_problem            Cursor containing the problems
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                         Rui de Sousa Neves
    * @version                        1.0
    * @since                          2007/09/13
    **********************************************************************************************/
    FUNCTION get_pat_problem_report
    (
        i_lang                 IN language.id_language%TYPE,
        i_pat                  IN pat_problem.id_patient%TYPE,
        i_prof                 IN profissional,
        i_episode              IN pat_problem.id_episode%TYPE,
        i_report               IN VARCHAR2,
        i_dt_ini               IN VARCHAR2,
        i_dt_end               IN VARCHAR2,
        i_show_hist            IN VARCHAR2,
        o_pat_problem          OUT pk_types.cursor_type,
        o_unawareness_active   OUT pk_types.cursor_type,
        o_unawareness_outdated OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * get_unique_problem_id returns unique id given an original problem id
    *
    * @param i_pat      in      patient id
    * @param i_list     in      table_table_number with original id and unique id for one problem          
    *
    * @return                         number
    *
    * @author                  Paulo teixeira
    * @since                   2010-11-26
    * @version                 v 2.5.1.2
    */
    FUNCTION get_unique_problem_id
    (
        i_id_problem IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE,
        i_list       IN table_table_number
    ) RETURN NUMBER;

    /**
    * build_unique_problem_id
    *
    * @param i_pat        in     patient id
    * @param i_list       out    table_table_number with original id and unique id for one problem          
    *
    * @return                         true or false on success or error
    *
    * @author                  Paulo teixeira
    * @since                   2010-11-26
    * @version                 v 2.5.1.2
    */
    FUNCTION build_unique_problem_id
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_pat      IN pat_problem.id_patient%TYPE,
        i_list     OUT table_table_number,
        i_phd_list OUT table_number
    ) RETURN BOOLEAN;
    /**
    * get date string
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional object
    * @param i_dt                     date
    *
    * @return                         varchar2
    *
    * @author                  Paulo teixeira
    * @since                   2011-01-24
    * @version                 v 2.6.1
    */
    FUNCTION get_dt_str
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_dt   IN VARCHAR2
    ) RETURN VARCHAR2;

    /**
    * get date  string
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional object
    * @param i_year_begin             year
    * @param i_month_begin            month
    * @param i_day_begin              day
    *
    * @return                         varchar2
    *
    * @author                  Paulo teixeira
    * @since                   2011-01-24
    * @version                 v 2.6.1
    */
    FUNCTION get_dt_str
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_year_begin  IN NUMBER,
        i_month_begin IN NUMBER,
        i_day_begin   IN NUMBER
    ) RETURN VARCHAR2;
    /********************************************************************************************
    * Returns add button options
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                patient_id
    * @param o_list                  add list
    * @param o_error                  Error Message
    *
    * @return                         True if success, False in case of error
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/31
    **********************************************************************************************/
    FUNCTION get_add_problems
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * insert patient problem unawareness
    *
    * @param      i_lang               Language id
    * @param      i_prof               profissional identifier
    * @param      i_id_prob_unaware    problem unawareness identifier
    * @param      i_id_patient         patient identifier
    * @param      i_id_episode         episode identifier
    * @param      i_notes              notes
    * @param      i_flg_status         flag status
    * @param      i_id_cancel_reason   cancel reason identifier
    * @param      i_cancel_notes       cancel notes
    *
    * @param      o_id_combination_spec  combination specification identifier  
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/06/21
    **********************************************************************************************/
    FUNCTION ins_pat_prob_unaware
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_prob_unaware     IN pat_prob_unaware.id_prob_unaware%TYPE,
        i_id_patient          IN pat_prob_unaware.id_patient%TYPE,
        i_id_episode          IN pat_prob_unaware.id_episode%TYPE,
        i_notes               IN pat_prob_unaware.notes%TYPE,
        i_flg_status          IN pat_prob_unaware.flg_status%TYPE,
        i_id_cancel_reason    IN pat_prob_unaware.id_cancel_reason%TYPE,
        i_cancel_notes        IN pat_prob_unaware.cancel_notes%TYPE,
        o_id_pat_prob_unaware OUT pat_prob_unaware.id_pat_prob_unaware%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * get patient problem unawareness choices
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                patient_id
    * @param o_choices                choices list
    * @param o_error                  Error Message
    *
    * @return                         True if success, False in case of error
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/02/01
    **********************************************************************************************/
    FUNCTION get_pat_prob_unaware_choices
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_flg_type IN VARCHAR2,
        o_choices  OUT pk_types.cursor_type,
        o_notes    OUT pat_prob_unaware.notes%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * insert patient problem unawareness no commit
    *
    * @param      i_lang               Language id
    * @param      i_prof               profissional identifier
    * @param      i_id_prob_unaware    problem unawareness identifier
    * @param      i_id_patient         patient identifier
    * @param      i_id_episode         episode identifier
    * @param      i_notes              notes
    * @param      i_flg_status         flag status
    * @param      i_id_cancel_reason   cancel reason identifier
    * @param      i_cancel_notes       cancel notes
    *
    * @param      o_id_combination_spec  combination specification identifier  
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/06/21
    **********************************************************************************************/
    FUNCTION ins_pat_prob_unaware_nc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_prob_unaware     IN pat_prob_unaware.id_prob_unaware%TYPE,
        i_id_patient          IN pat_prob_unaware.id_patient%TYPE,
        i_id_episode          IN pat_prob_unaware.id_episode%TYPE,
        i_notes               IN pat_prob_unaware.notes%TYPE,
        i_flg_status          IN pat_prob_unaware.flg_status%TYPE,
        i_id_cancel_reason    IN pat_prob_unaware.id_cancel_reason%TYPE,
        i_cancel_notes        IN pat_prob_unaware.cancel_notes%TYPE,
        o_id_pat_prob_unaware OUT pat_prob_unaware.id_pat_prob_unaware%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * insert patient problem unawareness
    *
    * @param      i_lang               Language id
    * @param      i_prof               profissional identifier
    * @param      i_id_patient         patient identifier
    * @param      i_id_episode         episode identifier
    * @param      i_notes              notes
    * @param      i_id_cancel_reason   cancel reason identifier
    * @param      i_cancel_notes       cancel notes
    * @param      i_flg_status         flag status TO VALIDATE IF IT'S ACTIVE
    *
    * @param      o_id_combination_spec  combination specification identifier  
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/06/21
    **********************************************************************************************/
    FUNCTION cancel_pat_prob_unaware_nc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN pat_prob_unaware.id_patient%TYPE,
        i_id_episode          IN pat_prob_unaware.id_episode%TYPE,
        i_notes               IN pat_prob_unaware.notes%TYPE,
        i_id_cancel_reason    IN pat_prob_unaware.id_cancel_reason%TYPE,
        i_cancel_notes        IN pat_prob_unaware.cancel_notes%TYPE,
        i_flg_status          IN table_varchar,
        o_id_pat_prob_unaware OUT pat_prob_unaware.id_pat_prob_unaware%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * get patient problem unawareness choices
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                patient_id
    * @param i_episode                episode id
    * @param o_title                  title
    * @param o_msg                    message
    * @param o_show                   show popup Y or N
    * @param o_error                  Error Message
    *
    * @return                         True if success, False in case of error
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/02/01
    **********************************************************************************************/
    FUNCTION validate_unawareness
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_id_prob_unaware IN pat_prob_unaware.id_prob_unaware%TYPE,
        o_title           OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_show            OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Validate if problem is a trial
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_diagnosis              diagnosis
    * @param o_title                  title
    * @param o_msg                    message
    * @param o_flg_show               show popup Y or N
    * @param o_shortcut               id shortcut to be used
    * @param o_error                  Error Message
    *
    * @return                         True if success, False in case of error
    *
    * @author                Elisabete Bugalho
    * @version               2.6.1
    * @since                 2011/02/22
    **********************************************************************************************/
    FUNCTION validate_trials
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_diagnosis IN table_number,
        o_msg       OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_shortcut  OUT NUMBER,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the phd ids for the same problem
    *
    * @param i_pat_history_diagnosis pat_history_diagnosis ID
    *
    * @return                table_number with the problem id 's
    *
    * @author                  Paulo Teixeira
    * @since                   2011-03-25
    * @version                 v2.6.1
    */
    FUNCTION get_phd_ids
    (
        i_pat_history_diagnosis IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE,
        i_flg_area              VARCHAR2 DEFAULT pk_alert_constant.g_diag_area_problems
    ) RETURN table_number;
    /**
    * Returns the most recent phd id for the same problem
    *
    * @param i_pat_history_diagnosis pat_history_diagnosis ID
    *
    * @return                number with the problem id 
    *
    * @author                  Paulo Teixeira
    * @since                   2011-03-25
    * @version                 v2.6.1
    */
    FUNCTION get_most_recent_phd_id
    (
        i_pat_history_diagnosis IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE,
        i_flg_area              VARCHAR2 DEFAULT pk_alert_constant.g_diag_area_problems
    ) RETURN NUMBER;

    /********************************************************************************************
    * Checks the presence of a given diagnosis in the patient EHR
    *
    * @param i_lang                  Id language
    * @param i_prof                  Professional, software and institution ids
    * @param i_id_patient            Patient Id
    *
    * @return                   collection
    *     
    * @author                   Sérgio Santos
    * @version                  2.6.1
    * @since                    02-May-2011
    *
    *********************************************************************************************/
    FUNCTION check_diagnosis_in_ehr
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN t_coll_cdr_api_out;

    /********************************************************************************************
    * Checks the presence of a given alert diagnosis in the patient EHR
    *
    * @param i_lang                  Id language
    * @param i_prof                  Professional, software and institution ids
    * @param i_id_patient            Patient Id
    * @param i_diagnosis             Diagnosis Id
    * @param i_start_date            Lower date to be considered
    * @param o_is_present            Y- diagnosis is in patient EHR. N-otherwise
    * @param o_diag_list             List of diagnosis
    * @param o_diag_type             Diagnosis record area
    * @param o_error                 Error Menssage
    *
    * @return                   TRUE/FALSE
    *     
    * @author                   Sérgio Santos
    * @version                  2.6.1
    * @since                    02-May-2011
    *
    *********************************************************************************************/
    FUNCTION check_synonym_diag_in_ehr
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_alert_diag IN alert_diagnosis.id_alert_diagnosis%TYPE,
        i_start_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_is_present OUT VARCHAR2,
        o_diag_list  OUT table_number,
        o_diag_type  OUT table_varchar,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_dup_icd_problem
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_flg_type           IN epis_diagnosis.flg_type%TYPE,
        i_id_diagnosis_list  IN table_number,
        i_id_alert_diag_list IN table_number DEFAULT NULL,
        o_flg_show           OUT VARCHAR2,
        o_msg                OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * get_desc_probl
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional object
    * @param i_id                     problem id
    * @param i_type                   type of problem
    *
    * @return                         varchar2
    *
    * @author                  Paulo teixeira
    * @since                   2011-01-24
    * @version                 v 2.6.1
    */
    FUNCTION get_desc_probl
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_id   IN NUMBER,
        i_type IN VARCHAR2
    ) RETURN VARCHAR2;
    /********************************************************************************************
    * get_problem_types
    *
    * @param      i_lang               Language id
    * @param      i_prof               profissional identifier    
    * @param      o_list              cursor out
    *
    * @param      o_error              mensagem de erro
    *
    * @author  Paulo Teixeira
    * @version 2.6.1.6
    * @since   2011/12/16
    **********************************************************************************************/
    FUNCTION get_problem_types
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_flg_area
    (
        i_flg_area pat_history_diagnosis.flg_area%TYPE,
        i_flg_type pat_history_diagnosis.flg_type%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get the area option that will appear in the problems edition screen that allow to switch the
    * area of the record (Problems, PAst medical history)
    *
    * @param      i_lang               Language id
    * @param      i_prof               profissional identifier
    * @param      i_id_record          Record identifier, if not null, this means the function was called during an edit action
    * @param      o_list               List with the available area
    *
    * @param      o_error              mensagem de erro
    *
    * @author  Sofia Mendes
    * @version 2.6.3.2.1
    * @since   13-Feb-2013
    **********************************************************************************************/
    FUNCTION get_areas_domain
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_record         IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE,
        id_tl_task_timeline IN tl_task.id_tl_task%TYPE DEFAULT NULL,
        o_list              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the description of the area assigned to the record (P-problems; H-Past medical history).
    *
    * @param      i_lang               Language id
    * @param      i_prof               profissional identifier    
    * @param      i_flg_area           Area identification: P-problems; H-Past medical history; N-Not available
    * @param      i_id_alert_diagnosis Alert diagnosis ID
    *
    * @param      o_error              mensagem de erro
    *
    * @author  Sofia Mendes
    * @version 2.6.3.2.1
    * @since   13-Feb-2013
    **********************************************************************************************/
    FUNCTION get_problem_type_desc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_flg_area           IN pat_history_diagnosis.flg_area%TYPE,
        i_id_alert_diagnosis IN pat_history_diagnosis.id_alert_diagnosis%TYPE,
        i_flg_type           IN pat_history_diagnosis.flg_type%TYPE
    ) RETURN pk_translation.t_desc_translation;

    /**
    * Get task description.
    * Used for the task timeline easy access (HandP import mechanism).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_phd       identifier
    * @param i_desc_type    de4sc_type S-short/L-long
    *
    * @return               diet task description
    *
    * @author                         Paulo Teixeira
    * @version                        2.6.1.2
    * @since                          19/07/2012
    */
    FUNCTION get_description_phd
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_phd    IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE,
        i_desc_type IN VARCHAR2 DEFAULT NULL
    ) RETURN CLOB;

    /**
    * Get task description.
    * Used for the task timeline easy access (HandP import mechanism).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_pp        identifier
    * @param i_desc_type    de4sc_type S-short/L-long
    *
    * @return               diet task description
    *
    * @author                         Paulo Teixeira
    * @version                        2.6.1.2
    * @since                          19/07/2012
    */
    FUNCTION get_description_pp
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_pp     IN pat_problem.id_pat_problem%TYPE,
        i_desc_type IN VARCHAR2
    ) RETURN CLOB;

    /**
    * Get task description.
    * Used for the task timeline easy access (HandP import mechanism).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_pat_prob_unaware       identifier
    * @param i_desc_type    de4sc_type S-short/L-long
    *
    * @return               diet task description
    *
    * @author                         Paulo Teixeira
    * @version                        2.6.1.2
    * @since                          2012/09/05 
    */
    FUNCTION get_desc_prob_unaware
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_pat_prob_unaware IN pat_prob_unaware.id_pat_prob_unaware%TYPE,
        i_desc_type           IN VARCHAR2
    ) RETURN CLOB;
    /**
    * Returns task type for a past_history_diagnosis flg_area
    * Used in diagnosis descriptions
    *
    * @param i_flg_area     past_history_diagnosis.flg_area
    *
    * @return               Task Type ID
    *
    * @author                         Sergio Dias
    * @version                        2.6.3.11
    * @since                          25/02/2014
    */
    FUNCTION get_flg_area_task_type
    (
        i_flg_area pat_history_diagnosis.flg_area%TYPE,
        i_flg_type pat_history_diagnosis.flg_type%TYPE DEFAULT NULL
    ) RETURN task_type.id_task_type%TYPE;
    ---

    /**
    * Returns flg of info_button is acive or not
    *
    * @param i_diag              diagnosis Id
    *
    * @return                    Flag Y(active) or N (inactive)
    *
    * @author                    Jorge Silva
    * @version                   2.6.3.11
    * @since                     26/02/2014
    */
    FUNCTION get_flg_info_button
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_diag diagnosis.id_diagnosis%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************************************
    * During a problem creation, validates if the selected diagnoses can remain selected when changing to a different type
    *
    * @param      i_lang                Language id
    * @param      i_prof                profissional identifier
    * @param      i_id_patient          Patient ID
    * @param      i_flg_area            Indicates the type of problem to which the user just changed (past_history_diagnosis.flg_area)
    * @param      i_id_diagnosis        Selected diagnoses id list
    * @param      i_id_alert_diagnosis  Selected alert_diagnoses id list
    * @param      o_id_diagnosis        Diagnoses id list that can remain selected
    * @param      o_id_alert_diagnosis  Alert_diagnoses id list that can remain selected
    *
    * @param      o_error              error message
    *
    * @author     Sergio Dias
    * @version    2.6.3.12
    * @since      10-Mar-2013
    ************************************************************************************************************************/
    FUNCTION validate_diagnosis_selection
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_area           IN pat_history_diagnosis.flg_area%TYPE,
        i_id_diagnosis       IN table_number,
        i_id_alert_diagnosis IN table_number,
        o_id_diagnosis       OUT table_number,
        o_id_alert_diagnosis OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the area option that will appear in the problems edition screen that allow to switch the
    * area of the record (Problems, PAst medical history)
    *
    * @param      i_prof                 profissional identifier
    * @param      i_prog_notes_constant  If the value is in(pk_prog_notes_constants.g_task_ph_medical_hist, pk_prog_notes_constants.g_task_ph_surgical_hist, pk_prog_notes_constants.g_task_problems), then return 'Y' else return 'N'
    *
    * @author  Joel Lopes
    * @version 2.6.3.15
    * @since   08-Apr-2014
    **********************************************************************************************/
    FUNCTION get_validate_button_areas
    (
        i_prof       IN profissional,
        i_id_tl_task IN tl_task.id_tl_task%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Return if the add button is active or inactive
    *
    * @param      i_lang                Language id
    * @param      i_prof                profissional identifier
    * @param      i_patient             Patient ID
    * @param      i_episode             Episode ID
    *
    * @author  Joel Lopes
    * @version 2.6.3.15
    * @since   09-Apr-2014
    **********************************************************************************************/
    FUNCTION get_validate_add_button
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_pat_problem_detail
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN pat_history_diagnosis.id_patient%TYPE,
        i_type        IN VARCHAR2,
        i_id          IN NUMBER,
        i_id_episode  IN pat_problem.id_episode%TYPE,
        o_pat_problem OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns diagnosis has flag warning or not
    *
    * @param i_lang               Language identifier
    * @param i_diag               The Diagnosis id
    * @param i_prof               Professional identifier
    *
    *
    * @author                Jorge Silva
    * @version               2.6.4.1.1
    * @since                 2014/08/12
    */
    FUNCTION get_diag_flg_warning_value
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_diag IN diagnosis.id_diagnosis%TYPE
    ) RETURN VARCHAR2;
    /**
    * Returns diagnosis has flag warning or not
    *
    * @param i_lang               Language identifier
    * @param i_diag               The Diagnosis id array
    * @param i_prof               Professional identifier
    *
    * @param o_diag_warning       Warning value
    *
    * @author                Jorge Silva
    * @version               2.6.4.1.1
    * @since                 2014/08/12
    */
    FUNCTION get_diag_flg_warning
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_diag         IN table_number,
        o_diag_warning OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function that returns the the place of occurence of the diagnosis
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_diagnosis              Diagnosis ID
    * @param i_id_location            Place of occurence ID already registered 
     *
    * @return                         Place of occurence
    *
    *
    * @author                         Elisabete Bugalho
    * @version                        2.7.0
    * @since                          17/11/2016
    **********************************************************************************************/
    FUNCTION get_place_of_occurence
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_diagnosis   IN diagnosis.id_diagnosis%TYPE,
        i_id_location IN diagnosis_ea.id_concept_term%TYPE DEFAULT NULL,
        o_location    OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

	/********************************************************************************************
    * Function that returns the the places of occurence of the diagnoses
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_diagnosis              Collection of diagnoses IDs
    * @param i_id_location            Collection of places of occurence (IDs already registered)
    *
    * @return                         Places of occurence
    *
    * Note: This function will return the locations that are common to all the input diagnoses.
    **********************************************************************************************/
    FUNCTION get_place_of_occurence
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_diagnosis   IN table_number,
        i_id_location IN table_number DEFAULT NULL,
        o_location    OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /* *******************************************************************************************
    *  Get current state of past history problems for viewer checklist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_vwr_past_history_ph
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Function that returns the the patient active problems and the associated precautions
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_patient                Patient ID
     *
    * @return                         List of active problems
    *
    *
    * @author                         Elisabete Bugalho
    * @version                        2.7.1
    * @since                          30/3/2017
    **********************************************************************************************/

    FUNCTION get_problems_precautions
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        o_precautions OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************************
    * set_epis_problem_group_array
    *
    * @param i_lang The language id
    * @param i_episode The episode id
    * @param i_prof The professional, institution and software ids
    * @param i_id_pat_problem An array with pat problem ids
    * @param i_prob_group  An array with group ids
    * @param i_seq_num An array with rank ids
    * @param o_error An error message to explain what went wrong if the execution fails.
    *
    * @return True if succeded, false otherwise.
    *
    * @author : Lillian Lu
     * @since 2017/11/8
    **********************************************************************************************/
    FUNCTION set_epis_problem_group_array
    (
        i_lang            IN language.id_language%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_prof            IN profissional,
        i_id_problem      IN table_number,
        i_prev_id_problem IN table_number,
        i_flg_status      IN table_varchar,
        i_prob_group      IN table_number,
        i_seq_num         IN table_number,
        i_flg_type        IN table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************************
    * set_epis_prob_group_note
    *
    * @param i_lang The language id
    * @param i_prof The professional, institution and software ids
    * @param i_episode The episode id
    * @param i_id_epis_prob_group episode group id
    * @param i_assessment_note assessment note
    * @param i_plan_note plan note
    
    * @param o_error An error message to explain what went wrong if the execution fails.
    *
    * @return True if succeded, false otherwise.
    *
    * @author : Lillian Lu
     * @since 2017/11/10
    **********************************************************************************************/
    FUNCTION set_epis_prob_group_note
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_id_epis_prob_grp_ass IN epis_prob_group_assess.id_epis_prob_group_ass%TYPE,
        i_id_epis_prob_group   IN epis_prob_group.id_epis_prob_group%TYPE,
        i_assessment_note      IN CLOB,
        i_plan_note            IN CLOB,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************************
    * get_max_problem_group
    *
    * @param i_lang The language id
     * @param i_prof The professional, institution and software ids
    * @param i_epis The episode id
    * @param o_error An error message to explain what went wrong if the execution fails.
    *
    * @return True if succeded, false otherwise.
    *
    * @author : Lillian Lu
     * @since 2017/11/10
    **********************************************************************************************/
    FUNCTION get_max_problem_group
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_epis  IN episode.id_episode%TYPE,
        o_group OUT NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_max_prob_group_internal
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_epis IN episode.id_episode%TYPE
    ) RETURN NUMBER;

    /************************************************************************************************************************
    * get_epis_problem
    *
    * @param i_lang The language id
    * @param i_prof The professional, institution and software ids
    * @param i_episode The episode id
    * @param i_pat patient id
    * @param i_status
    * @param i_type
    * @param i_problem
    * @param o_error An error message to explain what went wrong if the execution fails.
    *
    * @return True if succeded, false otherwise.
    *
    * @author : Lillian Lu
     * @since 2017/11/23
    **********************************************************************************************/
    FUNCTION get_epis_problem
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_pat        IN pat_history_diagnosis.id_patient%TYPE,
        i_status     IN table_varchar,
        i_type       IN VARCHAR2,
        i_id_problem IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE DEFAULT NULL,
        o_problem    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************************
    * validate_epis_prob_group ( check if no any problem in the specific group)
    *
    * @param i_lang The language id
    * @param i_prof The professional, institution and software ids
    * @param i_episode The episode id
    * @param i_prob_group  group id
    * @param i_problem
    * @param o_error An error message to explain what went wrong if the execution fails.
    *
    * @return True if has problems in the group, false otherwise.
    *
    * @author : Lillian Lu
     * @since 2017/11/24
    **********************************************************************************************/
    FUNCTION validate_epis_prob_group
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_id_problem        IN epis_prob.id_problem%TYPE,
        i_prob_group        IN epis_prob_group.prob_group%TYPE,
        o_prob_in_epis_prob OUT VARCHAR2,
        o_prob_in_gorup     OUT VARCHAR2,
        o_prob_in_prev_epis OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************************
    * cancel_epis_problem
    *
    * @param i_lang The language id
    * @param i_prof The professional, institution and software ids
    * @param i_pat  patient id
    * @param i_id_episode The episode id
    * @param i_id_problem problem id
    * @param i_type                   Type of problem
    * @param i_id_cancel_reason       Cancel Reason ID
    * @param i_cancel_notes           Cancelation notes
    * @param i_prof_cat_type          Professional category flag
    * @param i_flg_cancel_pat_prob    cancel patient problem flah:
    *                                                'Y' if need to cancel patient problem
    * @param o_error                  Error message
    *
    * @return True if has problems in the group, false otherwise.
    *
    * @author : Lillian Lu
     * @since 2017/11/27
    **********************************************************************************************/
    FUNCTION cancel_epis_problem
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_pat                 IN pat_problem.id_patient%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_problem          IN NUMBER,
        i_type                IN VARCHAR2,
        i_id_cancel_reason    IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes        IN epis_prob.cancel_notes%TYPE,
        i_prof_cat_type       IN category.flg_type%TYPE,
        i_flg_cancel_pat_prob IN VARCHAR2 DEFAULT pk_alert_constant.get_no,
        o_type                OUT table_varchar,
        o_ids                 OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets actions available for Problem List View
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   o_list                       List of actions available
    * @param   o_error                    Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  Lillian Lu
    * @since   14-12-2017
    */
    FUNCTION get_actions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_from_state IN action.from_state%TYPE,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************************************
    * Gets the description of the group and assessment for Single Page
    *
    * @param      i_lang                    Language ID
    * @param      i_prof                    profissional identifier
    * @param      i_id_group_ass            Assessmente and Plan ID
    * @param      i_flg_desc_for_dblock     Description destination
    * @param      i_flg_description         Type od description
    * @param      i_description_condition   Fields to show in description
    *
    * return      Group and assessment description
    *
    * @author     Elisabete Bugalho
    * @version    2.7.2.2
    * @since      12/2017
    ************************************************************************************************************************/
    FUNCTION get_prob_group_description
    
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_group_ass          IN epis_prob_group_assess.id_epis_prob_group_ass%TYPE,
        i_flg_desc_for_dblock   IN VARCHAR2,
        i_flg_description       IN VARCHAR2,
        i_description_condition IN VARCHAR2
    ) RETURN CLOB;

    /**********************************************************************************************************************
    * Gets the description of episode problem for Single Page
    *
    * @param      i_lang                    Language ID
    * @param      i_prof                    profissional identifier
    * @param      i_id_problems             Episode Problem ID
    * @param      i_flg_desc_for_dblock     Description destination
    * @param      i_flg_description         Type od description
    * @param      i_description_condition   Fields to show in description
    *
    * return      Group and assessment description
    *
    * @author     Elisabete Bugalho
    * @version    2.7.2.2
    * @since      12/2017
    ************************************************************************************************************************/
    FUNCTION get_epis_prob_description
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_problems           IN epis_prob.id_epis_problem%TYPE,
        i_flg_desc_for_dblock   IN VARCHAR2,
        i_flg_description       IN VARCHAR2,
        i_description_condition IN VARCHAR2
    ) RETURN CLOB;

    /**********************************************************************************************************************
    * Gets the description of episode problem group ( with the list of problems)
    *
    * @param      i_lang                    Language ID
    * @param      i_prof                    profissional identifier
    * @param      i_id_epis_prob_group      Episode Problem Group ID
    * @param      i_id_epis_prob_group_ass  Assessment Plan ID 
    *
    * return      Group Problem description with lista of problems
    *
    * @author     Elisabete Bugalho
    * @version    2.7.2.2
    * @since      12/2017
    ************************************************************************************************************************/
    FUNCTION get_epis_group_problem
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_epis_prob_group     IN epis_prob_group.id_epis_prob_group%TYPE,
        i_id_epis_prob_group_ass IN epis_prob_group_assess.id_epis_prob_group_ass%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_epis_prob_group
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE,
        i_flg_status IN VARCHAR2,
        o_prob_group OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prob_group_assessment
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_id_epis_prob_group     IN epis_prob_group.id_epis_prob_group%TYPE,
        i_id_epis_prob_group_ass IN epis_prob_group_assess.id_epis_prob_group_ass%TYPE,
        o_assessement            OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_prob_group_assessment
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_id_epis_prob_group_ass IN epis_prob_group_assess.id_epis_prob_group_ass%TYPE,
        i_id_cancel_reason       IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel           IN CLOB,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prev_group_assessment
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_id_epis_prob_group IN epis_prob_group.id_epis_prob_group%TYPE
    ) RETURN CLOB;

    FUNCTION get_prev_group_plan
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_id_epis_prob_group IN epis_prob_group.id_epis_prob_group%TYPE
    ) RETURN CLOB;

    g_pk_owner CONSTANT VARCHAR2(6) := 'ALERT';
    g_package_name VARCHAR2(32);

    g_diag_select diagnosis.flg_select%TYPE;

    g_available VARCHAR2(1);
    g_selected  VARCHAR2(1);
    g_cancelled CONSTANT VARCHAR2(1) := 'C';

    g_exception EXCEPTION;

    g_error        VARCHAR2(4000); -- eRROR
    g_sysdate_tstz TIMESTAMP WITH TIME ZONE;
    g_found        BOOLEAN;
    g_sysdate_char VARCHAR2(50);

    g_patient_active           patient.flg_status%TYPE;
    g_pat_hplan_active         pat_health_plan.flg_status%TYPE;
    g_pat_hplan_flg_default_no pat_health_plan.flg_default%TYPE;
    g_pat_job_active           pat_job.flg_status%TYPE;
    g_pat_doc_active           pat_doc.flg_status%TYPE;
    g_clin_rec_active          clin_record.flg_status%TYPE;

    g_epis_diag_passive epis_diagnosis.flg_type%TYPE;

    g_pat_allergy_active   pat_allergy.flg_status%TYPE;
    g_pat_allergy_passive  pat_allergy.flg_status%TYPE;
    g_pat_allergy_cancel   pat_allergy.flg_status%TYPE;
    g_pat_allergy_resolved pat_allergy.flg_status%TYPE;

    g_pat_allergy_all  pat_allergy.flg_type%TYPE;
    g_pat_allergy_reac pat_allergy.flg_type%TYPE;

    g_pat_allergy_doc pat_allergy.flg_aproved%TYPE;
    g_pat_allergy_pat pat_allergy.flg_aproved%TYPE;

    g_pat_probl_active   pat_problem.flg_status%TYPE;
    g_pat_probl_passive  pat_problem.flg_status%TYPE;
    g_pat_probl_cancel   pat_problem.flg_status%TYPE;
    g_pat_probl_resolved pat_problem.flg_status%TYPE;
    g_pat_probl_invest   pat_problem.flg_status%TYPE;

    g_pat_note_flg_active pat_notes.flg_status%TYPE;
    g_pat_note_flg_cancel pat_notes.flg_status%TYPE;

    g_pat_hplan_default pat_health_plan.flg_default%TYPE;
    g_doc_avail         doc_type.flg_available%TYPE;
    g_hplan_avail       health_plan.flg_available%TYPE;

    g_pat_habit_canc        pat_habit.flg_status%TYPE;
    g_pat_habit_active      pat_habit.flg_status%TYPE;
    g_pat_fam_soc_hist_canc pat_fam_soc_hist.flg_status%TYPE;
    g_pat_fam_soc_hist_act  pat_fam_soc_hist.flg_status%TYPE;

    g_pat_medicat_active pat_medication.flg_status%TYPE;

    g_pat_blood_active pat_blood_group.flg_status%TYPE;
    g_pat_blood_cancel pat_blood_group.flg_status%TYPE;

    g_pat_prob_allrg VARCHAR2(1);
    g_pat_prob_prob  VARCHAR2(1);

    g_error_msg_code VARCHAR2(200);
    -- to execute dynamic pl/sql blocks with table metadata. Used to 
    g_patient_row            patient%ROWTYPE;
    g_pat_soc_attributes_row pat_soc_attributes%ROWTYPE;
    g_pat_job_row            pat_job%ROWTYPE;
    g_pat_cli_attributes_row pat_cli_attributes%ROWTYPE;
    g_clin_record_row        clin_record%ROWTYPE;
    g_pat_health_plan_row    pat_health_plan%ROWTYPE;
    g_keys                   table_varchar;
    g_values                 table_varchar;
    g_date_convert_pattern   VARCHAR2(50);

    g_flg_hist_n CONSTANT VARCHAR2(1) := 'N';
    g_flg_hist_y CONSTANT VARCHAR2(1) := 'Y';

    g_flg_type_med    CONSTANT pat_history_diagnosis.flg_type%TYPE := 'M';
    g_flg_status_none CONSTANT pat_history_diagnosis.flg_status%TYPE := 'N';
    g_flg_status_unk  CONSTANT pat_history_diagnosis.flg_status%TYPE := 'U';
    g_flg_cancel      CONSTANT VARCHAR2(2) := 'C';

    g_pbm_session CONSTANT notes_config.notes_code%TYPE := 'PBM';

    g_medical_diagnosis_type alert_diagnosis.flg_type%TYPE;

    -- viewer funcions' constants
    g_code_domain          CONSTANT VARCHAR2(200) := 'PATIENT_PROBLEM.FLG_SOURCE';
    g_problem_type_allergy CONSTANT VARCHAR2(2) := 'A';
    g_problem_type_diag    CONSTANT VARCHAR2(2) := 'D';
    g_problem_type_habit   CONSTANT VARCHAR2(2) := 'H';
    g_problem_type_problem CONSTANT VARCHAR2(2) := 'PP';
    g_problem_type_pmh     CONSTANT VARCHAR2(2) := 'PH';
    g_color_red            CONSTANT VARCHAR2(8) := '0xC86464'; -- VERMELHO
    g_color_orange         CONSTANT VARCHAR2(8) := '0xD2A05A'; -- LARANJA
    g_color_beige          CONSTANT VARCHAR2(8) := '0xC6C9B3'; -- BEGE
    g_font_p               CONSTANT VARCHAR2(50) := 'ViewerState'; -- PASSIVO
    g_font_o               CONSTANT VARCHAR2(50) := 'Vig_flg_type_medewerCancelState'; -- OUTROS
    --

    g_med_assoc CONSTANT VARCHAR2(2) := 'A';

    g_dot CONSTANT VARCHAR2(1) := '.';

    g_interv_pat_prob_inactive CONSTANT VARCHAR2(1) := 'C';

    g_no           CONSTANT VARCHAR2(1) := 'N';
    g_yes          CONSTANT VARCHAR2(1) := 'Y';
    g_semicolon    CONSTANT VARCHAR2(2 CHAR) := '; ';
    g_type_p       CONSTANT VARCHAR2(1 CHAR) := 'P';
    g_type_a       CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_type_d       CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_unknown      CONSTANT VARCHAR2(1 CHAR) := 'U';
    g_year_unknown CONSTANT VARCHAR2(2 CHAR) := '-1';

    g_report_p CONSTANT VARCHAR2(1) := 'P';
    g_report_v CONSTANT VARCHAR2(1) := 'V';
    g_report_e CONSTANT VARCHAR2(1) := 'E';

    g_passive                 CONSTANT VARCHAR2(1 CHAR) := 'P';
    g_active                  CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_inactive                CONSTANT VARCHAR2(1 CHAR) := 'I';
    g_bar                     CONSTANT VARCHAR2(3 CHAR) := ' / ';
    g_bar2                    CONSTANT VARCHAR2(1 CHAR) := '/';
    g_doctor                  CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_resolved                CONSTANT VARCHAR2(1 CHAR) := 'R';
    g_pat_probl_self_limiting CONSTANT VARCHAR2(1 CHAR) := 'I';
    g_status_ppu_active   pat_prob_unaware.flg_status%TYPE := 'A';
    g_status_ppu_cancel   pat_prob_unaware.flg_status%TYPE := 'C';
    g_status_ppu_outdated pat_prob_unaware.flg_status%TYPE := 'O';
    g_open_parentheses  CONSTANT VARCHAR2(1 CHAR) := '(';
    g_close_parentheses CONSTANT VARCHAR2(1 CHAR) := ')';
    g_no_known_prob         prob_unaware.id_prob_unaware%TYPE := 1;
    g_unable_to_access_prob prob_unaware.id_prob_unaware%TYPE := 2;
    g_search_number_char CONSTANT INTEGER(1) := 3;

    g_diag_unknown CONSTANT INTEGER(1) := -1;
    g_diag_none    CONSTANT INTEGER(1) := 0;

    g_area_sys_domain CONSTANT VARCHAR2(30 CHAR) := 'PAT_HISTORY_DIAGNOSIS.FLG_AREA';

    g_scope_patient CONSTANT VARCHAR2(1) := 'P';
    g_scope_visit   CONSTANT VARCHAR2(1) := 'V';
    g_scope_episode CONSTANT VARCHAR2(1) := 'E';

    g_ph_medical_hist  CONSTANT VARCHAR2(1) := 'H';
    g_ph_surgical_hist CONSTANT VARCHAR2(1) := 'S';
    g_prob             CONSTANT VARCHAR2(1) := 'P';
    g_pat_problem      CONSTANT VARCHAR2(2) := 'PP';

    g_status_prog_group_ass_a CONSTANT epis_prob_group_assess.flg_status%TYPE := 'A';
    g_status_prog_group_ass_c CONSTANT epis_prob_group_assess.flg_status%TYPE := 'C';
    g_error_group_code        CONSTANT VARCHAR2(30 CHAR) := 'PROB-0001';
END;
/
