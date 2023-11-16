/*-- Last Change Revision: $Rev: 2006802 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2022-01-26 15:39:05 +0000 (qua, 26 jan 2022) $*/

CREATE OR REPLACE PACKAGE pk_past_history IS

    /****************************************************************************************************************************************************************************************
    * GLOBAL VARS USED IN PK
    *****************************************************************************************************************************************************************************************/
    g_exception EXCEPTION;
    g_error         VARCHAR2(4000);
    g_package_name  VARCHAR2(32);
    g_package_owner VARCHAR2(32);
    g_sysdate_tstz  TIMESTAMP WITH LOCAL TIME ZONE;
    g_found         BOOLEAN;
    g_has_error     BOOLEAN;

    /********************************************************************************************
    * Status of free text values (A - active, C - canceled...etc)
    **********************************************************************************************/
    g_flg_status_active_free_text CONSTANT VARCHAR(1 CHAR) := 'A'; --Active
    g_flg_status_outdtd_free_text CONSTANT VARCHAR(1 CHAR) := 'O'; --Outdated
    g_flg_status_cancel_free_text CONSTANT VARCHAR(1 CHAR) := 'C'; --Canceled
    g_flg_status_edited_free_text CONSTANT VARCHAR(1 CHAR) := 'E'; --Edited

    /********************************************************************************************
    * Doc areas of the past history values
    **********************************************************************************************/
    g_doc_area_past_med    CONSTANT doc_area.id_doc_area%TYPE := 45; -- Past medical
    g_doc_area_past_surg   CONSTANT doc_area.id_doc_area%TYPE := 46; -- Past surgical
    g_doc_area_past_fam    CONSTANT doc_area.id_doc_area%TYPE := 47; -- Past family
    g_doc_area_past_soc    CONSTANT doc_area.id_doc_area%TYPE := 48; -- Past social
    g_doc_area_relev_notes CONSTANT doc_area.id_doc_area%TYPE := 49; -- Relevant notes
    g_doc_area_cong_anom   CONSTANT doc_area.id_doc_area%TYPE := 52; -- Congenital anomalies
    g_doc_area_treatments  CONSTANT doc_area.id_doc_area%TYPE := 6753; -- Treatments
    g_doc_area_obs_hist    CONSTANT doc_area.id_doc_area%TYPE := 1049; -- Obstetric History
    g_doc_area_food_hist   CONSTANT doc_area.id_doc_area%TYPE := 1050; -- Food History
    g_doc_area_natal_hist  CONSTANT doc_area.id_doc_area%TYPE := 1051; -- Peri-natal and natal History
    g_doc_area_gyn_hist    CONSTANT doc_area.id_doc_area%TYPE := 1052; -- Gynecology History
    g_doc_area_perm_incap  CONSTANT doc_area.id_doc_area%TYPE := 1054; -- Permanent incapacities
    g_doc_area_occup_hist  CONSTANT doc_area.id_doc_area%TYPE := 36054; -- Occupational History
    g_doc_area_abuse_hist  CONSTANT doc_area.id_doc_area%TYPE := 36140; -- Occupational History
    /********************************************************************************************
    * Past history type - mapping of values in doc areas
    **********************************************************************************************/
    g_alert_diag_type_med       CONSTANT alert_diagnosis.flg_type%TYPE := 'M'; -- medical
    g_alert_diag_type_surg      CONSTANT alert_diagnosis.flg_type%TYPE := 'S'; -- surgical
    g_alert_diag_type_cong_anom CONSTANT alert_diagnosis.flg_type%TYPE := 'A'; -- congenital anomaly      
    g_alert_type_treatments     CONSTANT alert_diagnosis.flg_type%TYPE := 'T'; -- Treatments  
    g_alert_diag_type_family    CONSTANT alert_diagnosis.flg_type%TYPE := 'F'; -- Family
    g_alert_diag_type_gyneco    CONSTANT alert_diagnosis.flg_type%TYPE := 'G'; -- Gynecology
    g_alert_diag_type_others    CONSTANT alert_diagnosis.flg_type%TYPE := 'O'; -- Other areas

    /********************************************************************************************
    * FILTER types for treatments
    **********************************************************************************************/
    g_flg_treatments_freq   CONSTANT VARCHAR(1 CHAR) := 'A'; --Frequente
    g_flg_treatments_search CONSTANT VARCHAR(1 CHAR) := 'B'; --Search

    /********************************************************************************************
    * Search types for treatments
    **********************************************************************************************/
    g_flg_treatments_proc_search CONSTANT VARCHAR(1 CHAR) := 'P'; --Procedures
    g_flg_treatments_img_search  CONSTANT VARCHAR(1 CHAR) := 'I'; --Image
    g_flg_treatments_exam_search CONSTANT VARCHAR(1 CHAR) := 'O'; --Exams

    /********************************************************************************************
    * Diagnoses type 
    **********************************************************************************************/
    g_flg_past_hist_diags CONSTANT VARCHAR2(1 CHAR) := 'H'; --Past history diagnoses

    /********************************************************************************************
    * VARS Migrated from pk_summary_page
    **********************************************************************************************/
    g_year_unknown CONSTANT VARCHAR2(2 CHAR) := '-1';
    --
    g_pat_hist_diag_unknown    CONSTANT pat_history_diagnosis.flg_status%TYPE := 'U';
    g_pat_hist_diag_none       CONSTANT pat_history_diagnosis.flg_status%TYPE := 'N';
    g_pat_hist_diag_non_remark CONSTANT pat_history_diagnosis.flg_status%TYPE := 'NR';
    g_pat_hist_diag_canceled   CONSTANT pat_history_diagnosis.flg_status%TYPE := 'C';
    g_pat_notes_canceled       CONSTANT VARCHAR(1) := pk_alert_constant.g_cancelled;
    --
    g_diag_unknown    CONSTANT pat_history_diagnosis.id_diagnosis%TYPE := 0;
    g_diag_none       CONSTANT pat_history_diagnosis.id_diagnosis%TYPE := -1;
    g_diag_non_remark CONSTANT pat_history_diagnosis.id_diagnosis%TYPE := -2;
    --
    g_interv_type CONSTANT VARCHAR2(1 CHAR) := 'P';
    --
    g_active   CONSTANT VARCHAR2(1) := 'A';
    g_inactive CONSTANT VARCHAR2(1) := 'I';
    g_outdated CONSTANT VARCHAR2(1) := 'O';
    --
    g_past_hist_review_area review_detail.flg_context%TYPE := '';
    --
    g_epis_complaint_active CONSTANT epis_complaint.flg_status%TYPE := 'A';
    --
    g_pbm_session CONSTANT notes_config.notes_code%TYPE := 'PBM';
    g_rds_session CONSTANT notes_config.notes_code%TYPE := 'RDS';
    --    
    g_past_hist_treat_type_config  CONSTANT sys_config.desc_sys_config%TYPE := 'PAST_HISTORY_TREATMENT_TYPE';
    g_birth_hist_validation_config CONSTANT sys_config.desc_sys_config%TYPE := 'BIRTH_HISTORY_VALIDATIONS';
    --

    g_past_hist_date_precision_day CONSTANT pat_history_diagnosis.dt_diagnosed_precision%TYPE := 'D';

    /********************************************************************************************
    * VARS Migrated from pk_hea_prv_aux
    **********************************************************************************************/
    g_past_history_flg_resolved CONSTANT pat_allergy.flg_status%TYPE := 'R';
    --

    --API for CDA
    g_flg_type_context_pat_p     CONSTANT VARCHAR2(1 CHAR) := 'P';
    g_flg_type_context_epis_e    CONSTANT VARCHAR2(1 CHAR) := 'E';
    g_flg_type_context_epis_v    CONSTANT VARCHAR2(1 CHAR) := 'V';
    g_flg_status_epis_inactive_i CONSTANT VARCHAR2(1 CHAR) := 'I';
    g_flg_status_epis_active_a   CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_phd_flg_status             CONSTANT sys_domain.code_domain%TYPE := 'PAT_HISTORY_DIAGNOSIS.FLG_STATUS';
    g_phd_flg_death_cause        CONSTANT sys_domain.code_domain%TYPE := 'PAT_HISTORY_DIAGNOSIS.FLG_DEATH_CAUSE';
    --

    g_past_history_not_reviewed CONSTANT VARCHAR2(1 CHAR) := 'T';

    g_detail_type_create    CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_detail_type_review    CONSTANT VARCHAR2(1 CHAR) := 'R';
    g_detail_type_edit      CONSTANT VARCHAR2(1 CHAR) := 'E';
    g_detail_type_cancelled CONSTANT VARCHAR2(1 CHAR) := 'X';
    --
    g_context_flg_type_compl       CONSTANT doc_area_inst_soft.flg_type%TYPE := 'C';
    g_context_flg_type_app         CONSTANT doc_area_inst_soft.flg_type%TYPE := 'A';
    g_context_flg_type_srv         CONSTANT doc_area_inst_soft.flg_type%TYPE := 'S';
    g_context_flg_type_doc         CONSTANT doc_area_inst_soft.flg_type%TYPE := 'D';
    g_context_flg_type_sch_cln_srv CONSTANT doc_area_inst_soft.flg_type%TYPE := 'SC';

    g_int_name_cong_anom1 CONSTANT doc_element.internal_name%TYPE := 'ANOM_CONG1';
    g_int_name_cong_anom2 CONSTANT doc_element.internal_name%TYPE := 'ANOM_CONG2';
    --
    g_dummy_status VARCHAR2(1) := 'X';
    --
    g_past_hist_diag_type_treat CONSTANT sys_config.desc_sys_config%TYPE := 'PAST_HISTORY_TREATMENT_TYPE';
    --
    --  group for family history relationship
    g_family_hist_relationship CONSTANT relationship_type.id_relationship_type%TYPE := 2;

    TYPE t_rec_past_history_cda IS RECORD(
        id_epis_documentation_det   epis_documentation_det.id_epis_documentation_det%TYPE,
        flg_status                  epis_documentation.flg_status%TYPE,
        desc_status                 VARCHAR2(1000 CHAR),
        id_content_doc_component    doc_component.id_content%TYPE,
        id_doc_component            doc_component.id_doc_component%TYPE,
        desc_doc_component          pk_translation.t_desc_translation,
        id_content_doc_element_crit doc_element_crit.id_content%TYPE,
        desc_doc_element            pk_translation.t_desc_translation,
        element_domain_value        epis_documentation_det.value%TYPE,
        dt_reg_str                  VARCHAR2(14 CHAR),
        dt_reg_tstz                 epis_documentation.dt_creation_tstz%TYPE,
        dt_reg_formatted            VARCHAR2(1000 CHAR),
        internal_name               doc_element.internal_name%TYPE,
        id_epis_documentation       epis_documentation.id_epis_documentation%TYPE,
        reg_date                    VARCHAR2(32767),
        reg_date_str                VARCHAR2(14 CHAR));

    TYPE t_coll_past_history_cda IS TABLE OF t_rec_past_history_cda;

    TYPE t_rec_past_illness_cda IS RECORD(
        code_icd               diagnosis.code_icd%TYPE,
        desc_illness           pk_translation.t_desc_translation,
        id_content             diagnosis.id_content%TYPE,
        flg_status             pat_history_diagnosis.flg_status%TYPE,
        desc_status            VARCHAR2(1000 CHAR),
        flg_area               pat_history_diagnosis.flg_area%TYPE,
        dt_illness_to_print    VARCHAR2(1000 CHAR),
        dt_illness             pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        dt_illness_serial      VARCHAR2(14 CHAR),
        resolution_date_str    VARCHAR2(14 CHAR),
        resolution_date        pat_history_diagnosis.dt_resolved%TYPE,
        dt_diagnosed           VARCHAR2(100 CHAR),
        dt_diagnosed_serial    VARCHAR2(14 CHAR),
        id_terminology_version diagnosis.id_terminology_version%TYPE,
        notes                  pat_history_diagnosis.notes%TYPE);

    TYPE t_coll_past_illness_cda IS TABLE OF t_rec_past_illness_cda;

    TYPE t_rec_past_family_cda IS RECORD(
        code_icd                    diagnosis.code_icd%TYPE,
        desc_illness                pk_translation.t_desc_translation,
        id_content                  diagnosis.id_content%TYPE,
        flg_status                  pat_history_diagnosis.flg_status%TYPE,
        desc_status                 VARCHAR2(1000 CHAR),
        dt_illness_to_print         VARCHAR2(1000 CHAR),
        dt_illness                  pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        dt_illness_serial           VARCHAR2(14 CHAR),
        id_terminology_version      diagnosis.id_terminology_version%TYPE,
        notes                       pat_history_diagnosis.notes%TYPE,
        id_family_relationship      pat_history_diagnosis.id_family_relationship%TYPE,
        desc_family_relationship    VARCHAR2(1000 CHAR),
        family_relationship_content VARCHAR2(200 CHAR),
        flg_death_cause             pat_history_diagnosis.flg_death_cause%TYPE,
        desc_death_cause            VARCHAR2(200 CHAR),
        familiar_age                pat_history_diagnosis.familiar_age%TYPE);

    TYPE t_coll_past_family_cda IS TABLE OF t_rec_past_family_cda;

    g_date_precision_day   CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_date_precision_month CONSTANT VARCHAR2(1 CHAR) := 'M';
    g_date_precision_year  CONSTANT VARCHAR2(1 CHAR) := 'Y';
    g_date_precision_hour  CONSTANT VARCHAR2(1 CHAR) := 'H';
    g_date_unknown         CONSTANT VARCHAR2(1 CHAR) := 'U';

    /**
    * Converts flg_type to doc_area_id in past history types
    *
    * @param   i_flg_type               Type of past history area
    *
    * @return  VARCHAR2                 returns associated doc area id
    *
    * @author  José Silva
    * @version 2.6.2
    * @since   06-Oct-2011
    */
    FUNCTION prv_conv_flg_type_to_doc_area(i_flg_type IN pat_history_diagnosis.flg_type%TYPE)
        RETURN doc_area.id_doc_area%TYPE;

    /****************************************************************************************************************************************************************************************
    * PUBLIC FUNCTIONS
    **********************************************************************************************gg_outdated_outdated*******************************************************************************************/

    /********************************************************************************************
    * Returns the query for the past history grid
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             Current episode ID
    * @param i_id_patient             Patient ID
    * @param i_doc_area               Doc Area ID
    * @param i_past_hist_id           Past History Diagnosis/Past History free text
    * @param i_past_hist_ft           If past history ID was in free text or diagnosis
    * @param o_doc_area_val           Documentation data for the patient's episodes   
    * @param o_ph_ft                  Patient past history free text                                      
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui Duarte
    * @version                        1.0   
    * @since                          2010-Dec-09
    **********************************************************************************************/
    FUNCTION get_past_hist_all_grid
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_patient   IN patient.id_patient%TYPE,
        i_doc_area     IN doc_area.id_doc_area%TYPE,
        i_past_hist_id IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE,
        i_past_hist_ft IN VARCHAR2 DEFAULT pk_alert_constant.get_no,
        o_doc_area_val OUT pk_types.cursor_type,
        o_ph_ft_text   OUT pat_past_hist_free_text.text%TYPE,
        o_ph_ft_id     OUT pat_past_hist_free_text.id_pat_ph_ft%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Returns most recent ID for that alert_diagnosis / desc_pat_history_diagnosis
    * Similar to PK_PROBLEMS.get_pat_hist_diag_recent but for cong. anom. and surg hx
    *
    * @param i_lang                   Language ID
    * @param i_alert_diag             Alert Diagnosis ID
    * @param i_desc_phd               Description for the PHD
    * @param i_pat                    Patient ID
    *
    * @return                         PHD ID wanted
    *
    * @author                         Rui de Sousa Neves
    * @version                        1.0
    * @since                          2007/10/18
    **********************************************************************************************/

    FUNCTION prv_get_ph_diag_recent_all
    (
        i_lang       IN language.id_language%TYPE,
        i_alert_diag IN pat_history_diagnosis.id_alert_diagnosis%TYPE,
        i_desc_phd   IN pat_history_diagnosis.desc_pat_history_diagnosis%TYPE,
        i_flg_type   IN pat_history_diagnosis.flg_type%TYPE,
        i_pat        IN patient.id_patient%TYPE
    ) RETURN pat_history_diagnosis.id_pat_history_diagnosis%TYPE;
    --

    /**
    * Returns the number of previous medications.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_patient           Patient Id
    *
    * @return                       The number of previous medications
    *
    * @author   Rui Duarte
    * @version  2.6.0.5
    * @since    2011-Jan-06
    */
    FUNCTION get_past_hist_header_count
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN NUMBER;
    --

    /********************************************************************************************
    * Returns Relevant Notes
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Current profissional
    * @param i_pat_note                  Patient note ID
    * @param o_error                     Error message
    *                        
    * @return                            True or False on success or error
    *
    * @author  Filipe Machado
    * @version v2.6.0.1
    * @since   06-May-2010
    * @reason  ALERT-95625
    **********************************************************************************************/

    FUNCTION get_relevant_note
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_dt_note IN VARCHAR2,
        o_note    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Set past history in free text values
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode ID
    * @param i_pat                    Patient ID
    * @param i_doc_area               Doc Area ID
    * @param i_id_cancel_reason       Cancel Reason ID
    * @param i_cancel_notes           Cancelation notes   
    * @param o_ph_ft_id               pat_past_hist_free_text id
    * @param o_pat_ph_ft_hist         pat_past_hist_ft_hist id
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui Duarte
    * @version                        1.0
    * @since                          2010-Dec-14
    **********************************************************************************************/
    FUNCTION set_past_hist_free_text
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_pat              IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_doc_area         IN doc_area.id_doc_area%TYPE,
        i_ph_ft_id         IN pat_past_hist_free_text.id_pat_ph_ft%TYPE,
        i_ph_ft_text       IN pat_past_hist_free_text.text%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes     IN pat_problem_hist.cancel_notes%TYPE,
        i_dt_register      IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        i_dt_review        IN review_detail.dt_review%TYPE,
        o_ph_ft_id         OUT pat_past_hist_ft_hist.id_pat_ph_ft%TYPE,
        o_pat_ph_ft_hist   OUT pat_past_hist_ft_hist.id_pat_ph_ft_hist%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Records new diagnosis on the past medical and surgical history for this episode
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode when this/these problems were registered    
    * @param i_pat                    Patient ID 
    * @param i_doc_area               Doc Area ID
    * @param i_flg_status             Array of problem status
    * @param i_flg_nature             Array of problem nature
    * @param i_diagnosis              Array of relevant diseases' ID (in case of a past medical history record)
    * @param i_phd_outdated           Pat History Diagnosis/Pat notes ID fot the edited record (outdated)
    * @param i_desc_pat_history_diagnosis  Descriptions (when it's not based on an alert_diagnosis)
    * @param i_notes                  Notes if it was created through the problem screen  
    * @param i_id_cancel_reason       Cancelation reason ID
    * @param i_cancel_notes           Cancelation notes  
    * @param i_precaution_measure     list of arrays with precuation measures   
    * @param i_flg_warning            list of flag warning,
    * @param i_cdr_event              clinical decision rule corresponding id
    * @param i_flg_complications      Complications info for recording
    * @param i_flg_screen             Indicates from where the function was called. H - Past history screen (default), P - Problems screen
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui de Sousa Neves
    * @version                        1.0
    * @since                          2007/06/01
    **********************************************************************************************/

    FUNCTION set_past_hist_diagnosis
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_episode                    IN episode.id_episode%TYPE,
        i_pat                        IN patient.id_patient%TYPE,
        i_doc_area                   IN doc_area.id_doc_area%TYPE,
        i_flg_status                 IN table_varchar,
        i_flg_nature                 IN table_varchar,
        i_diagnosis                  IN table_number,
        i_phd_outdated               IN NUMBER,
        i_desc_pat_history_diagnosis IN table_varchar,
        i_notes                      IN table_varchar,
        i_id_cancel_reason           IN table_number,
        i_cancel_notes               IN table_varchar,
        i_precaution_measure         IN table_table_number,
        i_flg_warning                IN table_varchar,
        i_dt_register                IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        i_exam                       IN table_number,
        i_intervention               IN table_number,
        dt_execution                 IN table_varchar,
        i_dt_execution_precision     IN table_varchar,
        i_cdr_call                   IN cdr_call.id_cdr_call%TYPE,
        i_dt_review                  IN review_detail.dt_review%TYPE,
        i_flg_area                   IN table_varchar,
        i_flg_complications          IN table_varchar,
        i_flg_screen                 IN VARCHAR2 DEFAULT pk_alert_constant.g_diag_area_past_history,
        i_flg_cda_reconciliation     IN pat_history_diagnosis.flg_cda_reconciliation%TYPE DEFAULT pk_alert_constant.g_no,
        i_dt_diagnosed               IN table_varchar,
        i_dt_diagnosed_precision     IN table_varchar,
        i_dt_resolved                IN table_varchar,
        i_dt_resolved_precision      IN table_varchar,
        i_location                   IN table_number,
        i_id_family_relationship     IN table_number,
        i_flg_death_cause            IN table_varchar,
        i_familiar_age               IN table_number,
        i_phd_diagnosis              IN table_number,
        o_seq_phd                    OUT table_number,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Records new diagnosis on the past medical and surgical history for this episode
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode when this/these problems were registered    
    * @param i_pat                    Patient ID 
    * @param i_doc_area               Doc Area ID
    * @param i_flg_status             Array of problem status
    * @param i_flg_nature             Array of problem nature
    * @param i_diagnosis              Array of relevant diseases' ID (in case of a past medical history record)
    * @param i_phd_outdated           Pat History Diagnosis/Pat notes ID fot the edited record (outdated)
    * @param i_desc_pat_history_diagnosis  Descriptions (when it's not based on an alert_diagnosis)
    * @param i_notes                  Notes if it was created through the problem screen  
    * @param i_id_cancel_reason       Cancelation reason ID
    * @param i_cancel_notes           Cancelation notes  
    * @param o_msg                    Message to show
    * @param o_msg_title              Message title to show
    * @param o_flg_show               If it should show message or not
    * @param o_button                 Button type
    * @param i_precaution_measure     list of arrays with precuation measures   
    * @param i_flg_warning            list of flag warning,
    * @param i_ph_ft_id               Patient past history free text ID
    * @param i_ph_ft_text             Patient past history free text    
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui Duarte
    * @version                        1.0   
    * @since                          2010-Dec-09
    **********************************************************************************************/
    FUNCTION set_past_hist_all
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_episode                    IN episode.id_episode%TYPE,
        i_pat                        IN patient.id_patient%TYPE,
        i_doc_area                   IN doc_area.id_doc_area%TYPE,
        i_dt_diagnosed               IN table_varchar,
        i_dt_diagnosed_precision     IN table_varchar,
        i_flg_status                 IN table_varchar,
        i_flg_nature                 IN table_varchar,
        i_diagnosis                  IN table_number,
        i_phd_outdated               IN NUMBER,
        i_desc_pat_history_diagnosis IN table_varchar,
        i_notes                      IN table_varchar,
        i_id_cancel_reason           IN table_number,
        i_cancel_notes               IN table_varchar,
        i_precaution_measure         IN table_table_number,
        i_flg_warning                IN table_varchar,
        i_ph_ft_id                   IN pat_past_hist_free_text.id_pat_ph_ft%TYPE,
        i_ph_ft_text                 IN pat_past_hist_free_text.text%TYPE,
        i_exam                       IN table_number,
        i_intervention               IN table_number,
        dt_execution                 IN table_varchar,
        i_dt_execution_precision     IN table_varchar,
        i_cdr_call                   IN cdr_call.id_cdr_call%TYPE,
        i_dt_register                IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        i_dt_review                  IN review_detail.dt_review%TYPE,
        i_id_family_relationship     IN table_number,
        i_flg_death_cause            IN table_varchar,
        i_familiar_age               IN table_number,
        i_phd_diagnosis              IN table_number,
        o_seq_phd                    OUT table_number,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /**
     * This functions sets a past history as "review"
     *
     * @param IN   i_lang              Language ID
     * @param IN   i_prof              Professional Type
     * @param IN   i_id_blood_type     Blood Type ID
     * @param IN   i_review_notes      Notes
     * @param OUT  o_error             Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.5.0.7
     * @since    2009-Oct-23
     * @author   Thiago Brito
     * @reason   ALERT-52344
    */
    FUNCTION set_past_history_review
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_id_past_history       IN table_number,
        i_review_notes          IN review_detail.review_notes%TYPE,
        i_ft_flg                IN table_varchar,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /**
     * This functions used in patient match functionality
     *
    * @param i_lang language id
    * @param i_prof user's object
    * @param i_patient new patient id
    * @param i_patient_temp temporary patient which data will be merged out, and then deleted
    * @param o_error error message, if error occurs
     *
     * @return BOOLEAN
     *
     * @version  2.6.0.5
     * @since    2011-JAN-26
     * @author   Rui Duarte
     * @reason   ALERT-28215
    */
    FUNCTION set_match_patient
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_patient_temp IN patient.id_patient%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /**
     * This functions used in episode match functionality
     *
     * @param i_lang                          Language ID
     * @param i_prof                          Profissional array
     * @param i_episode                       Episode identifier
     * @param i_episode_temp                  Temporary episode 
     * @param o_error error message, if error occurs
     *
     * @return BOOLEAN
     *
     * @version  2.6.0.5
     * @since    2011-JAN-26
     * @author   Rui Duarte
     * @reason   ALERT-28215
    */
    FUNCTION set_match_episode
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_episode_temp IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Get Past History Surgical procedures
    *
    * @param i_lang              Id language
    * @param i_prof              Professional, software and institution ids
    * @param i_id_context        Identifier of the Episode/Patient/Visit based on the i_flg_type_context
    * @param i_flg_type_context  Flag to filter by Episode (E), by Visit (V) or by Patient (P)
    * @param o_doc_area          Data cursor
    * @param o_error             Error Message
    *
    * @return                    TRUE/FALSE
    *     
    * @author                    António Neto
    * @version                   2.6.1
    * @since                     2011-05-04
    *
    *********************************************************************************************/
    FUNCTION get_past_hist_surgical_api
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_context       IN NUMBER,
        i_flg_type_context IN VARCHAR2,
        o_doc_area         OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * @author  Sergio Dias
    * @version 2.6.1.1
    * @since   May-30-2011
    */
    FUNCTION set_past_hist_all
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_episode                    IN episode.id_episode%TYPE,
        i_pat                        IN patient.id_patient%TYPE,
        i_doc_area                   IN doc_area.id_doc_area%TYPE,
        i_dt_diagnosed               IN table_varchar,
        i_dt_diagnosed_precision     IN table_varchar,
        i_flg_status                 IN table_varchar,
        i_flg_nature                 IN table_varchar,
        i_diagnosis                  IN table_number,
        i_phd_outdated               IN NUMBER,
        i_desc_pat_history_diagnosis IN table_varchar,
        i_notes                      IN table_varchar, --13
        i_id_cancel_reason           IN table_number,
        i_cancel_notes               IN table_varchar,
        i_precaution_measure         IN table_table_number,
        i_flg_warning                IN table_varchar,
        i_ph_ft_id                   IN pat_past_hist_free_text.id_pat_ph_ft%TYPE, --18
        i_ph_ft_text                 IN pat_past_hist_free_text.text%TYPE,
        i_exam                       IN table_number,
        i_intervention               IN table_number,
        dt_execution                 IN table_varchar,
        i_dt_execution_precision     IN table_varchar,
        i_cdr_call                   IN cdr_call.id_cdr_call%TYPE,
        i_id_family_relationship     IN table_number,
        i_flg_death_cause            IN table_varchar,
        i_familiar_age               IN table_number,
        i_phd_diagnosis              IN table_number,
        --
        i_prof_cat_type         IN category.flg_type%TYPE, --25
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_epis_documentation    IN epis_documentation.id_epis_documentation%TYPE,
        i_flg_type              IN VARCHAR2,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number, --31
        i_value                 IN table_varchar,
        i_notes_template        IN epis_documentation.notes%TYPE,
        i_id_doc_element_qualif IN table_table_number,
        i_epis_context          IN epis_documentation.id_epis_context%TYPE,
        i_summary_and_notes     IN epis_documentation.notes%TYPE,
        i_episode_context       IN epis_documentation.id_episode_context%TYPE DEFAULT NULL, --37
        i_flg_table_origin      IN VARCHAR2 DEFAULT 'D',
        i_vs_element_list       IN table_number,
        i_vs_save_mode_list     IN table_varchar,
        i_vs_list               IN table_number,
        i_vs_value_list         IN table_number,
        i_vs_uom_list           IN table_number, --43
        i_vs_scales_list        IN table_number,
        i_vs_date_list          IN table_varchar,
        i_vs_read_list          IN table_number, --46
        o_seq_phd               OUT table_number,
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    --    
    /********************************************************************************************
    * Creates a review for a template record
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Object (professional ID, institution ID, software ID)
    * @param i_episode                   Episode ID
    * @param i_id_epis_documentation     Episode documentation ID
    * @param i_review_notes              Review notes
    * @param i_dt_review                 Review Date
    * @param o_error                     Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sergio Dias
    * @version                        2.6.1.1
    * @since                          Jun-01-2011
    **********************************************************************************************/
    FUNCTION set_template_review
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_review_notes          IN review_detail.review_notes%TYPE,
        i_dt_review             IN review_detail.dt_review%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Gets free text record for a specific documentation area
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Object (professional ID, institution ID, software ID)
    * @param i_current_episode           Episode ID
    * @param i_scope                     Scope ID
    * @param i_scope_type                Scope type
    * @param i_doc_area                  Doc_Area ID
    * @param o_doc_area_register         Register Cursor (left side on screen)
    * @param o_doc_area_val              Values Cursor (right side on screen)
    * @param o_error                     Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sergio Dias
    * @version                        2.6.1.1
    * @since                          Jun-01-2011
    **********************************************************************************************/
    FUNCTION get_past_hist_free_text
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_current_episode   IN episode.id_episode%TYPE,
        i_scope             IN NUMBER,
        i_scope_type        IN VARCHAR2,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        o_doc_area_register OUT NOCOPY pk_summary_page.doc_area_register_cur,
        o_doc_area_val      OUT NOCOPY pk_summary_page.doc_area_val_past_surg_cur,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Gets the last review made in an episode
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Object (professional ID, institution ID, software ID)
    * @param i_id_episode                Episode ID
    * @param o_last_review               Last review result
    * @param o_error                     Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sergio Dias
    * @version                        2.6.1.1
    * @since                          Jun-01-2011
    **********************************************************************************************/
    FUNCTION get_past_hist_review
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN NUMBER,
        o_last_review   OUT VARCHAR2,
        o_review_status OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Returns all diagnosis (Both standards diagnosis - like ICD9 - and ALERT diagnosis)
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_doc_area               Doc area ID
    * @param i_search                 String to search
    * @param i_pat                    Patient ID
    * @param i_flg_type               Protocol to be used (ICPC2, ICD9, ...), if it exists
    * @param i_format_text            Formats the output occurrences
    * @param o_diagnosis              Cursor containing the diagnosis info
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Ariel Machado (code-refactoring)
    * @version                        2.6.0.x       
    * @since                          2010/05/11
    **********************************************************************************************/
    FUNCTION get_search_treatments
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_search    IN VARCHAR2,
        i_pat       IN patient.id_patient%TYPE,
        i_flg_type  IN table_varchar,
        o_diagnosis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_review_info
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_id_record_area IN review_detail.id_record_area%TYPE,
        i_flg_context    IN review_detail.flg_context%TYPE,
        i_id_institution IN institution.id_institution%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    FUNCTION get_partial_date_format
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_date      IN pat_history_diagnosis.dt_execution%TYPE,
        i_precision IN pat_history_diagnosis.dt_execution_precision%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_partial_date_format_serial
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_date      IN pat_history_diagnosis.dt_execution%TYPE,
        i_precision IN pat_history_diagnosis.dt_execution_precision%TYPE
    ) RETURN VARCHAR2;

    /**************************************************************************
    * return list of documentation for the patient for a specific doc_area    *
    *                                                                         *
    * @param i_lang                   The language ID                         *
    * @param i_prof                   Object (professional ID, institution ID,*
    *                                 software ID)                            *
    * @param i_episode                the episode id                          *
    * @param i_doc_area               the doc_area id                         *
    *                                                                         *
    * @return                         return list of documentation for the    *
    *                                 patient for a specific doc_area         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2010/02/24                              *
    **************************************************************************/
    FUNCTION tf_doc_area_register
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_doc_area IN doc_area.id_doc_area%TYPE
    ) RETURN pk_touch_option.t_coll_doc_area_register
        PIPELINED;

    /**************************************************************************
    * return list of documentation values for the patient for a specific      *
    * doc_area.                                                               *
    *                                                                         *
    * @param i_lang                   The language ID                         *
    * @param i_prof                   Object (professional ID, institution ID,*
    *                                 software ID)                            *
    * @param i_episode                the episode id                          *
    * @param i_doc_area               the doc_area id                         *
    *                                                                         *
    * @return                         return list of documentation for the    *
    *                                 patient for a specific doc_area         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2010/02/24                              *
    **************************************************************************/
    FUNCTION tf_doc_area_val_documentation
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_doc_area IN doc_area.id_doc_area%TYPE
    ) RETURN pk_touch_option.t_coll_doc_area_val
        PIPELINED;

    /**
    * prv_get_review_notel_label returns notes label considering value and config
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_notes                  Notes
    *
    * @return  VARCHAR2                returns converted flag
    *
    * @author  rui.duarte
    * @version 2.6.1.3
    * @since   2011-SET-29
    */
    FUNCTION prv_get_review_note_label
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_notes IN VARCHAR2
    ) RETURN sys_message.desc_message%TYPE;

    /********************************************************************************************
    * Returns the diagnoses for the current complaint/type of appointment (Both standards diagnoses - like ICD9 - and ALERT diagnoses)
    
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode ID
    * @param i_pat                    Patient ID
    * @param i_doc_area               Doc area ID
    * @param o_diagnosis              Cursor containing the diagnoses info
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Ariel Machado 
    * @version                        v2.5.0.7       
    * @since                          2009/10/21 (code-refactoring)
    *
    **********************************************************************************************/
    FUNCTION get_context_alert_diagnosis
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_pat            IN patient.id_patient%TYPE,
        i_doc_area       IN doc_area.id_doc_area%TYPE,
        o_diagnosis      OUT pk_types.cursor_type,
        o_diag_not_class OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the procedures and exams (Treatments)
    *
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode ID
    * @param i_pat                    Patient ID
    * @param o_treatments             Cursor containing the treatments info
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Filipe Machado 
    * @version                        v2.6.1       
    * @since                          16-Apr-2011
    *
    **********************************************************************************************/
    FUNCTION get_context_treatments
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_pat             IN patient.id_patient%TYPE,
        o_treatments      OUT pk_types.cursor_type,
        o_treat_not_class OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Gets the past history record description
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    *                        
    * @return                         Past history description
    * 
    * @author                         José Silva
    * @version                        2.6.2
    * @since                          2011/10/06
    **********************************************************************************************/
    FUNCTION get_desc_past_hist_all
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_alert_diagnosis        IN pat_history_diagnosis.id_alert_diagnosis%TYPE,
        i_desc_pat_hist_diag     IN pat_history_diagnosis.desc_pat_history_diagnosis%TYPE,
        i_code_icd               IN diagnosis.code_icd%TYPE,
        i_flg_other              IN diagnosis.flg_other%TYPE,
        i_flg_icd9               IN alert_diagnosis_type.flg_icd9%TYPE,
        i_flg_status             IN pat_history_diagnosis.flg_status%TYPE,
        i_flg_compl              IN pat_history_diagnosis.flg_compl%TYPE,
        i_flg_nature             IN pat_history_diagnosis.flg_nature%TYPE,
        i_dt_diagnosed           IN pat_history_diagnosis.dt_diagnosed%TYPE,
        i_dt_diagnosed_precision IN pat_history_diagnosis.dt_diagnosed_precision%TYPE,
        i_doc_area               IN doc_area.id_doc_area%TYPE,
        i_family_relationship    IN pat_history_diagnosis.id_family_relationship%TYPE,
        i_flg_description        IN pn_dblock_ttp_mkt.flg_description%TYPE DEFAULT NULL,
        i_description_condition  IN pn_dblock_ttp_mkt.description_condition%TYPE DEFAULT NULL
    ) RETURN pk_translation.t_desc_translation;
    --
    /********************************************************************************************
    * Gets the past history section title associated with a patient record (H and P API)
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_pat_hist_diag          Past history diagnosis ID
    * @param i_pat_ph_ft              Past history ID of a free text record
    *                        
    * @return                         Section title
    * 
    * @author                         José Silva
    * @version                        2.6.2
    * @since                          2011/10/04
    **********************************************************************************************/
    FUNCTION get_past_hist_section_desc
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_hist_diag IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE,
        i_pat_ph_ft     IN pat_past_hist_ft_hist.id_pat_ph_ft%TYPE
    ) RETURN pk_translation.t_desc_translation;
    --
    /********************************************************************************************
    * Gets the past history record description (H&P API)
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_pat_hist_diag          Past history diagnosis ID
    * @param i_pat_ph_ft_hist         Past history ID of a free text record
    *                        
    * @return                         Section title
    * 
    * @author                         José Silva
    * @version                        2.6.2
    * @since                          2011/10/07
    **********************************************************************************************/
    FUNCTION get_past_hist_rec_desc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_pat_hist_diag  IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE,
        i_pat_ph_ft_hist        IN pat_past_hist_ft_hist.id_pat_ph_ft_hist%TYPE,
        i_flg_description       IN pn_dblock_ttp_mkt.flg_description%TYPE,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE
    ) RETURN pk_translation.t_desc_translation;
    --
    /********************************************************************************************
    * Returns the information from past medical that was imported from external areas (H and P API)
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Current profissional
    * @param i_episode                   Current episode ID
    * @param i_patient                   Patient ID
    * @param i_start_date                Start date 
    * @param i_end_date                  End date    
    * @param o_past_med                  External past medical history
    * @param o_error                     Error message
    *                        
    * @return                            True or False on success or error
    *
    * @author  José Silva
    * @version 2.6.2
    * @since   10-10-2011
    **********************************************************************************************/
    FUNCTION get_past_med_others
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE,
        i_start_date IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_past_med   OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Return past histtory formated desc for detail
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_doc_area               Doc Area ID
    * @param i_flg_ft                 Free text flag
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui Duarte
    * @version                        1.0
    * @since                          2011/10/18
    **********************************************************************************************/
    FUNCTION prv_get_past_hist_det_desc
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_doc_area IN doc_area.id_doc_area%TYPE,
        i_flg_ft   IN VARCHAR2 DEFAULT pk_alert_constant.get_no
    ) RETURN VARCHAR2;
    --
    /********************************************************************************************
    * Returns the unclassified diagnosis translation(ex: 'None' and 'Unknown')
    *
    * @param i_lang                   Language ID
    * @param i_id_diagnosis           Input diagnosis
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui Duarte
    * @version                        1.0   
    * @since                          2011/10/24
    **********************************************************************************************/
    FUNCTION prv_ph_diag_not_class_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_id_diagnosis IN pat_history_diagnosis.id_alert_diagnosis%TYPE
    ) RETURN VARCHAR2;
    --

    /**
     * get the past history mode(s) of documenting data
     *
     * @param i_lang                          Language ID
     * @param i_prof                          Profissional array
     * @param i_doc_area                      ID doc area   
     * @param o_modes                         Cursor with the values of the flags
     * @param o_error                         error message, if error occurs
     *
     * @return BOOLEAN
     *
     * @version  2.6.1
     * @since    12-Apr-2011
     * @author   Filipe Machado
     * @reason   ALERT-65577
    */
    FUNCTION get_ph_mode
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_doc_area IN episode.id_episode%TYPE,
        o_modes    OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Returns configured standards(ICD9,ICPC,etc.) that can be used in Past-History diagnoses(advanced search)
    * or treatment types (Image Exams, Other Exams, Procedures...etc)
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Current profissional
    * @param o_domains                   Available past history diagnoses to search
    * @param o_error                     Error message
    *                        
    * @return                            True or False on success or error
    *
    * @author  Rui Duarte
    * @version 
    * @since   10-Nov-09
    **********************************************************************************************/
    FUNCTION get_past_hist_search_types
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_doc_area IN doc_area.id_doc_area%TYPE,
        o_domains  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Returns all diagnosis and treatments
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_doc_area               Doc area ID
    * @param i_search                 String to search
    * @param i_pat                    Patient ID
    * @param i_flg_type               Protocol to be used (ICPC2, ICD9, ...), if it exists
    * @param o_diagnosis              Cursor containing the diagnosis info
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui Duarte
    * @version                        2.6.1    
    * @since                          2010/06/13
    **********************************************************************************************/
    FUNCTION get_search_past_hist
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_doc_area  IN doc_area.id_doc_area%TYPE,
        i_search    IN VARCHAR2,
        i_pat       IN patient.id_patient%TYPE,
        i_flg_type  IN table_varchar,
        o_diagnosis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Cancels records for past history
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_doc_area               Doc Area ID
    * @param i_id_episode             Episode ID
    * @param i_id_patient             Patient ID
    * @param i_record_id              Pat History Diagnosis ID or Free Text ID
    * @param i_ph_free_text           Value that indicates if "i_record_id" is a past_history_diagnosis_id or a free_text_id
    * @param i_id_cancel_reason       Cancel Reason ID
    * @param i_cancel_notes           Cancelation notes   
    * @param i_id_epis_documentation  Template info ID
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui de Sousa Neves
    * @version                        1.0   
    * @since                          2007/06/05
    *
    * @reviewed                       Sergio Dias
    * @version                        2.6.1.2
    * @since                          Jun-30-2011
    **********************************************************************************************/
    FUNCTION cancel_past_history
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_patient            IN patient.id_patient%TYPE,
        i_record_id             IN NUMBER,
        i_ph_free_text          IN VARCHAR2 DEFAULT pk_alert_constant.get_no,
        i_id_cancel_reason      IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes          IN pat_problem_hist.cancel_notes%TYPE,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_screen                IN VARCHAR2 DEFAULT pk_alert_constant.g_diag_area_past_history,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /**
    * Returns the lastest update information for the past history summary page
    *
    * @param i_lang        Language ID
    * @param i_prof        Current professional
    * @param i_pat         Patient ID
    * @param i_episode     Episode ID
    * @param o_sections    Cursor containing the sections info
    *
    * @param o_error        Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.1
    * @since   07-Apr-10 (code-refactoring)
    */
    FUNCTION get_past_hist_last_update
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_pat         IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_last_update OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Returns the possible values for complications for a past surgical history.
    *
    * @param i_lang              language id
    * @param i_prof              professional type
    * @param o_problem_compl     Cursor with possible options for the complications
    * @param o_error             Error message
    *
    * @return                    true (sucess), false (error)
    *
    * @author                    Rui de Sousa Neves
    * @version                   1.0
    * @since                     30-09-2007
    **********************************************************************************************/

    FUNCTION get_complications
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_problem_compl OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Returns the details for the past history summary page (medical and surgical history)
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             Current episode ID
    * @param i_id_patient             Patient ID
    * @param i_doc_area               Doc area ID   
    * @param i_pat_hist_diag          Past History Diagnosis ID   
    * @param o_doc_area_register      Doc area data
    * @param o_doc_area_val           Documentation data for the patient's episodes                                          
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui de Sousa Neves
    * @version                        1.0   
    * @since                          2007/09/13
    **********************************************************************************************/
    FUNCTION get_past_hist_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_id_patient        IN patient.id_patient%TYPE,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        i_pat_hist_diag     IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE,
        i_all               IN BOOLEAN DEFAULT FALSE,
        i_flg_ft            IN VARCHAR2 DEFAULT pk_alert_constant.get_no,
        i_epis_document     IN epis_documentation.id_epis_documentation%TYPE DEFAULT NULL,
        o_doc_area_register OUT pk_types.cursor_type,
        o_doc_area_val      OUT pk_types.cursor_type,
        o_epis_doc_register OUT pk_types.cursor_type,
        o_epis_document_val OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Returns info for past history areas based on a scope orientation (Patient,Episode, Visit)
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_current_episode    Current episode ID
    * @param   i_scope              Scope ID (Episode ID; Visit ID; Patient ID)
    * @param   i_scope_type         Scope type (by episode; by visit; by patient)
    * @param   i_doc_area           Documentation area ID
    * @param   o_doc_area_register  Cursor with the doc area info register
    * @param   o_doc_area_val       Cursor containing the completed info
    * @param   o_doc_area           Doc area ID                                     
    * @param   o_template_layouts   Cursor containing the layout for each template used
    * @param   o_doc_area_component Cursor containing the components for each template used 
    * @param   o_error              Error message
    * 
    * @author  ARIEL.MACHADO
    * @version 2.5.1.2
    * @since   11/04/2010
    **********************************************************************************************/
    FUNCTION get_past_hist_all
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_current_episode        IN episode.id_episode%TYPE,
        i_scope                  IN NUMBER,
        i_scope_type             IN VARCHAR2,
        i_doc_area               IN doc_area.id_doc_area%TYPE,
        o_doc_area_register      OUT pk_types.cursor_type,
        o_doc_area_val           OUT pk_types.cursor_type,
        o_doc_area_register_tmpl OUT pk_types.cursor_type,
        o_doc_area_val_tmpl      OUT pk_types.cursor_type,
        o_doc_area               OUT doc_area.id_doc_area%TYPE,
        o_template_layouts       OUT pk_types.cursor_type,
        o_doc_area_component     OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Returns the query for the past medical history summary page
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             Current episode ID
    * @param i_id_patient             Patient ID
    * @param i_flg_diag_call          Function is called by diagnosis deepnaves. Y - Yes; N - Otherwise
    * @param o_doc_area_register      Doc area data
    * @param o_doc_area_val           Documentation data for the patient's episodes                                          
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui de Sousa Neves
    * @version                        1.0
    * @since                          2007/05/30
    **********************************************************************************************/
    FUNCTION get_past_hist_medical
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_current_episode   IN episode.id_episode%TYPE,
        i_scope             IN NUMBER,
        i_scope_type        IN VARCHAR2,
        i_flg_diag_call     IN VARCHAR2 DEFAULT pk_alert_constant.get_no,
        o_doc_area_register OUT NOCOPY pk_summary_page.doc_area_register_cur,
        o_doc_area_val      OUT NOCOPY pk_summary_page.doc_area_val_past_med_cur,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Returns the query for the past surgical history summary page
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             Current episode ID
    * @param i_id_patient             Patient ID
    * @param o_doc_area_register      Doc area data
    * @param o_doc_area_val           Documentation data for the patient's episodes   
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui de Sousa Neves
    * @version                        1.0   
    * @since                          2007/05/30
    **********************************************************************************************/
    FUNCTION get_past_hist_surgical
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_current_episode   IN episode.id_episode%TYPE,
        i_scope             IN NUMBER,
        i_scope_type        IN VARCHAR2,
        o_doc_area_register OUT NOCOPY pk_summary_page.s_doc_area_register_cur,
        o_doc_area_val      OUT NOCOPY pk_summary_page.doc_area_val_past_surg_cur,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Returns the query for the congenital anomalies past history summary page
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             Current episode ID
    * @param i_id_patient             Patient ID
    * @param o_doc_area_register      Doc area data
    * @param o_doc_area_val           Documentation data for the patient's episodes                                          
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui de Sousa Neves
    * @version                        1.0   
    * @since                          2007/08/08
    **********************************************************************************************/
    FUNCTION get_past_hist_cong_anom
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_current_episode   IN episode.id_episode%TYPE,
        i_scope             IN NUMBER,
        i_scope_type        IN VARCHAR2,
        o_doc_area_register OUT NOCOPY pk_summary_page.s_doc_area_register_cur,
        o_doc_area_val      OUT NOCOPY pk_summary_page.doc_area_val_past_surg_cur,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    --  
    /********************************************************************************************
    * Returns the relevant notes info
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional object (professional ID, institution ID, software ID)
    * @param i_current_episode        Current episode ID
    * @param i_scope                  Scope
    * @param i_scope_type             Scope type
    * @param i_doc_area               Documentation area
    * @param o_doc_area_register      Documentation register cursor
    * @param o_doc_area_val           Documentation values cursor
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sergio Dias
    * @version                        2.6.1.2
    * @since                          30-08-2011
    **********************************************************************************************/
    FUNCTION get_past_hist_relev_notes
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_current_episode   IN episode.id_episode%TYPE,
        i_scope             IN NUMBER,
        i_scope_type        IN VARCHAR2,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        o_doc_area_register OUT pk_summary_page.doc_area_register_cur,
        o_doc_area_val      OUT pk_summary_page.doc_area_val_past_surg_cur,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Returns last activa past history records for dashboards
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_episode            Episode ID
    * @param   i_patient            Patient ID
    * @param   o_past_med_hist      Cursor containing active past history records
    * @param   o_error              Error message
    * 
    * @author  Rui Duarte
    * @version 2.6.1.5
    * @since   11/11/2011
    **********************************************************************************************/
    FUNCTION get_ph_summary_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_doc_area     IN doc_area.id_doc_area%TYPE,
        o_past_history OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION tf_past_history_cda
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_scope            IN NUMBER,
        i_scope_type       IN VARCHAR2,
        i_id_doc_area      IN NUMBER,
        i_id_doc_component IN table_varchar
    ) RETURN t_coll_past_history_cda
        PIPELINED;
    /**********************************************************************************************
    * List of social history for CDA section: Social history
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional ID
    * @param i_scope                 ID for scope type
    * @param i_scope_type            Scope type (E)pisode/(V)isit/(P)atient
    *
    * @return                        Table with social history records
    *                        
    * @author                        Vanessa Barsottelli
    * @version                       2.6.3
    * @since                         2014/01/02 
    * @Updated By                    Gisela Couto - 2014/05/05
    ***********************************************************************************************/
    FUNCTION tf_social_history_cda
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_scope            IN NUMBER,
        i_scope_type       IN VARCHAR2,
        i_id_doc_component IN table_varchar
    ) RETURN t_coll_past_history_cda
        PIPELINED;

    FUNCTION tf_family_history_cda
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_scope            IN NUMBER,
        i_scope_type       IN VARCHAR2,
        i_id_doc_component IN table_varchar
    ) RETURN t_coll_past_history_cda
        PIPELINED;

    FUNCTION tf_past_illness_cda
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN NUMBER,
        i_scope_type IN VARCHAR2,
        i_code_icd   IN table_varchar
    ) RETURN t_coll_past_illness_cda
        PIPELINED;

    /**********************************************************************************************
    * Internal function to retrieve most frequent diagnoses for past history screens
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional ID
    * @param i_episode               Episode ID
    * @param i_patient               Patient ID
    * @param i_doc_area              Doc Area ID
    * @param i_text_search           Text input to use as filter
    * @param i_flg_screen            Indicates from where the function was called. H - Past history screen (default), P - Problems screen
    *
    * @param o_diagnosis             Diagnoses information
    * @param o_error                 Error information
    *
    * @return                        TTrue/False
    *                        
    * @author                        Sergio Dias
    * @version                       2.6.3.14
    * @since                         25-03-2014
    ***********************************************************************************************/
    FUNCTION get_past_hist_diagnoses
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_patient           IN patient.id_patient%TYPE,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        i_text_search       IN VARCHAR2 DEFAULT NULL,
        i_flg_screen        IN VARCHAR2 DEFAULT pk_alert_constant.g_diag_area_past_history,
        i_tbl_terminologies IN table_varchar DEFAULT NULL,
        o_diagnosis         OUT t_coll_diagnosis_config,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION get_past_hist_ids_review
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN table_number,
        i_flg_context IN review_detail.flg_context%TYPE,
        i_flg_area    IN table_varchar,
        i_doc_area    IN doc_area.id_doc_area%TYPE
    ) RETURN table_number;
    FUNCTION get_last_past_hist
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_doc_area     IN doc_area.id_doc_area%TYPE,
        o_past_history OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION get_past_history_info
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis         IN table_number,
        i_pat          IN patient.id_patient%TYPE,
        i_flg_type     IN VARCHAR2,
        i_doc_area     IN doc_area.id_doc_area%TYPE,
        i_flg_ft       IN VARCHAR2 DEFAULT NULL,
        o_past_history OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION get_episode_reviewed
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE
    ) RETURN VARCHAR2;

    /* *******************************************************************************************
    *  Get current state of Past Medical history for viewer checklist 
    *             
    * @param    i_lang          Language ID
    * @param    i_prof          Logged professional structure
    * @param    i_scope_type    Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode    Episode ID
    * @param    i_id_patient    Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_vwr_med_past_hist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_family_relationships
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_relationship OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_death_cause
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_domains OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION tf_past_family_cda
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN NUMBER,
        i_scope_type IN VARCHAR2
    ) RETURN t_coll_past_family_cda
        PIPELINED;

    FUNCTION get_desc_past_hist
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_alert_diagnosis    IN pat_history_diagnosis.id_alert_diagnosis%TYPE,
        i_desc_pat_hist_diag IN pat_history_diagnosis.desc_pat_history_diagnosis%TYPE,
        i_code_icd           IN diagnosis.code_icd%TYPE,
        i_flg_other          IN diagnosis.flg_other%TYPE,
        i_flg_icd9           IN alert_diagnosis_type.flg_icd9%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_past_history_desc
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_hist_diag IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE,
        o_description   OUT VARCHAR2,
        o_status        OUT VARCHAR2,
        o_complications OUT VARCHAR2,
        o_nature        OUT VARCHAR2,
        o_dt_diagnosis  OUT VARCHAR2
    ) RETURN BOOLEAN;

    FUNCTION isphd_outbycancel
    (
        i_lang               IN language.id_language%TYPE,
        i_enter_mode         IN VARCHAR2,
        i_pat_hist_diagnosis IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE
    ) RETURN NUMBER;

    FUNCTION check_dup_icd_ph
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_id_diagnosis_list  IN table_number,
        i_id_alert_diag_list IN table_number DEFAULT NULL,
        o_flg_show           OUT VARCHAR2,
        o_msg                OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION convert_to_tstz
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_type  VARCHAR2,
        i_value VARCHAR2
    ) RETURN VARCHAR2;

    /* *******************************************************************************************
    *  Get current state of Past Surgical history for viewer checklist 
    *             
    * @param    i_lang          Language ID
    * @param    i_prof          Logged professional structure
    * @param    i_scope_type    Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode    Episode ID
    * @param    i_id_patient    Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author      Elisabete Bugalho               
    * @version       2.8.4.0             
    * @since        20/01/2022                      
    **********************************************************************************************/
    FUNCTION get_vwr_sug_past_hist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    FUNCTION tf_epis_diagnosis
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       profissional,
        i_id_patient episode.id_patient%TYPE,
        i_id_episode episode.id_episode%TYPE DEFAULT NULL,
        i_start_date episode.dt_begin_tstz%TYPE DEFAULT NULL,
        i_end_date   episode.dt_end_tstz%TYPE DEFAULT NULL
    ) RETURN t_tbl_epis_diagnosis;

    FUNCTION tf_pat_episode
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       profissional,
        i_id_patient episode.id_patient%TYPE,
        i_start_date episode.dt_begin_tstz%TYPE DEFAULT NULL,
        i_end_date   episode.dt_end_tstz%TYPE DEFAULT NULL
    ) RETURN t_tbl_pat_episode;

--
END pk_past_history;
/
