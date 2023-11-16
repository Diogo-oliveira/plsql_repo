/*-- Last Change Revision: $Rev: 2028704 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:26 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_grid AS

    FUNCTION get_pre_nurse_appointment
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_flg_ehr          IN episode.flg_ehr%TYPE,
        i_flg_status       IN schedule_outp.flg_state%TYPE,
        i_epis_type        IN epis_type.id_epis_type%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    FUNCTION get_daily_schedule
    (
        i_lang      IN language.id_language%TYPE,
        i_dt        IN VARCHAR2,
        i_instit    IN schedule.id_instit_requested%TYPE,
        i_epis_type IN schedule_outp.id_epis_type%TYPE,
        i_prof      IN profissional,
        o_sched     OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_admin_schedule
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_dt    IN VARCHAR2,
        o_sched OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION admin_exam_req
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE get_scheduled_tests_parameters
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    PROCEDURE get_tests_list_parameters
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

    FUNCTION get_scheduled_tests_dates
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Lab tests and exams requested but not scheduled for a given patient
    *
    * @param      i_lang      Language id
    * @param      i_prof      Professional
    * @param      i_patient   Patient id
    * @param      o_grid      Cursor
    * @param      o_error     Error message
    *
    * @return     boolean
    * @author     Luís Gaspar
    * @version    0.1
    * @since      2007/03/26
    * @notes      Based on technician_req function
    */

    FUNCTION get_scheduled_tests
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_grid    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_tests_to_schedule
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_req      IN NUMBER,
        i_flg_type IN VARCHAR2,
        o_exam     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Public Function.
    * Patient exams and a analysis to be executed on day I_DT.
    *
    *
    * @param      I_LANG              língua registada como preferência do profissional.
    * @param      I_PROF              object (ID do profissional, ID da instituição, ID do software).
    * @param      I_DT                data das requisições
    * @param      I_ID_PATIENT        Id do paciente
    * @param      o_grid              requisições
    * @param      O_ERROR             erro
    *
    * @return     boolean
    * @author     Luís Gaspar
    * @version    0.1
    * @since      2007/03/26
    * @notes      Similiar to the technician function
    */

    FUNCTION technician_by_patient
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_dt         IN VARCHAR2,
        i_id_patient IN patient.id_patient%TYPE,
        o_grid       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_admin_discharge
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_dt    IN VARCHAR2,
        o_sched OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_aux_schedule
    (
        i_lang      IN language.id_language%TYPE,
        i_dt        IN VARCHAR2,
        i_instit    IN schedule.id_instit_requested%TYPE,
        i_epis_type IN schedule_outp.id_epis_type%TYPE,
        i_prof      IN profissional,
        o_sched     OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION information_active
    (
        i_lang      IN language.id_language%TYPE,
        i_instit    IN schedule.id_instit_requested%TYPE,
        i_epis_type IN schedule_outp.id_epis_type%TYPE,
        i_prof      IN profissional,
        o_active    OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION information_active_det
    (
        i_lang   IN language.id_language%TYPE,
        i_epis   IN episode.id_episode%TYPE,
        i_pat    IN patient.id_patient%TYPE,
        i_prof   IN profissional,
        o_active OUT pk_types.cursor_type,
        o_titles OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION information_inactive
    (
        i_lang      IN language.id_language%TYPE,
        i_dt        IN VARCHAR2,
        i_instit    IN schedule.id_instit_requested%TYPE,
        i_epis_type IN schedule_outp.id_epis_type%TYPE,
        i_prof      IN profissional,
        o_inactive  OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION information_inactive_det
    (
        i_lang     IN language.id_language%TYPE,
        i_pat      IN patient.id_patient%TYPE,
        i_prof     IN profissional,
        o_inactive OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_status_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_status  IN VARCHAR2,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_id_patient  IN patient.id_patient%TYPE,
        o_status      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get data for multichoice on patient grids.
    * No option is selectable.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_schedule  schedule identifier
    * @param o_status       cursor 
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.0.7.8
    * @since                2010/04/19
    */
    FUNCTION get_pat_status_list_na
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_id_patient  IN patient.id_patient%TYPE,
        o_status      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION nurse_efectiv
    (
        i_lang          IN language.id_language%TYPE,
        i_epis_type     IN schedule_outp.id_epis_type%TYPE,
        i_prof          IN profissional,
        i_dt            IN VARCHAR2,
        i_type          IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_doc           OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION nurse_efectiv_my_rooms
    (
        i_lang          IN language.id_language%TYPE,
        i_epis_type     IN schedule_outp.id_epis_type%TYPE,
        i_prof          IN profissional,
        i_dt            IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_doc           OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION exist_prescription
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_flg     IN VARCHAR2
    ) RETURN NUMBER;

    FUNCTION exist_prescription
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_flg     IN VARCHAR2,
        i_dt      IN VARCHAR2
    ) RETURN NUMBER;

    FUNCTION min_dt_treatment
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN TIMESTAMP;

    FUNCTION technician_req
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION coord_efectiv
    (
        i_lang          IN language.id_language%TYPE,
        i_epis_type     IN schedule_outp.id_epis_type%TYPE,
        i_prof          IN profissional,
        i_dt            IN VARCHAR2,
        i_type          IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_doc           OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION coord_efectiv_location
    (
        i_lang      IN language.id_language%TYPE,
        i_epis_type IN schedule_outp.id_epis_type%TYPE,
        i_prof      IN profissional,
        i_dt        IN VARCHAR2,
        i_type      IN VARCHAR2,
        o_doc       OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_sched_time
    (
        i_lang     IN language.id_language%TYPE,
        i_schedule IN schedule.id_schedule%TYPE,
        i_state    IN schedule_outp.flg_state%TYPE
    ) RETURN VARCHAR2;

    FUNCTION set_doc_call
    (
        i_lang          IN language.id_language%TYPE,
        i_epis          IN episode.id_episode%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_last_vaccine_presc
    (
        i_lang    IN language.id_language%TYPE,
        i_id_pat  IN patient.id_patient%TYPE,
        i_id_epis IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_last_monitorization
    (
        i_lang    IN language.id_language%TYPE,
        i_id_pat  IN patient.id_patient%TYPE,
        i_id_epis IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_mov_desc
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_epis IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_cli_rec_total
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_epis IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_cli_rec_trans
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_epis IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_first_prec_icon
    (
        i_mess1    IN VARCHAR2,
        i_mess2    IN VARCHAR2,
        i_domain   IN VARCHAR2,
        i_cat_type IN category.flg_type%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_presc_req_icon_time
    (
        i_lang        IN language.id_language%TYPE,
        i_id_pat      IN patient.id_patient%TYPE,
        i_epis_status IN episode.flg_status%TYPE,
        i_flg_time    IN VARCHAR2,
        i_flg_status  IN VARCHAR2,
        i_dt_begin    IN TIMESTAMP,
        i_dt_req      IN TIMESTAMP,
        i_icon_name   IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN VARCHAR2;

    FUNCTION get_aux
    (
        i_lang        IN language.id_language%TYPE,
        i_id_pat      IN patient.id_patient%TYPE,
        i_epis_status IN episode.flg_status%TYPE,
        i_flg_time    IN VARCHAR2,
        i_flg_status  IN VARCHAR2,
        i_dt_begin    IN TIMESTAMP,
        i_dt_req      IN TIMESTAMP,
        i_icon_name   IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_nurse_teach
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_epis IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_string_task
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE DEFAULT NULL,
        i_epis_status IN episode.flg_status%TYPE,
        i_flg_time    IN VARCHAR2,
        i_flg_status  IN VARCHAR2,
        i_dt_begin    IN TIMESTAMP,
        i_dt_req      IN TIMESTAMP,
        i_icon_name   IN VARCHAR2,
        i_rank        IN sys_domain.rank%TYPE,
        o_error       OUT t_error_out
    ) RETURN VARCHAR2;

    /*
    *********************************************************************************************
      * Compares timestamps embedded in messages i_mess1 and i_mess2 and returns the message with 
      * the most oldest timestamp.
      *
      * This is a simpler version of get_prioritary_task(i_lang, i_mess1, i_mess2, i_domain, i_cat_type).
      *
      * @param i_lang                   the id language
      * @param i_mess1                  message 1
      * @param i_mess1                  message 2       
      *
      * @return                         the message with the most oldest timestamp
      *                        
      * @author                         Rui Baeta
      * @version                        1.0 
      * @since                          2008/01/08
      *
      * @author                         José Silva
      * @version                        2.0 
      * @since                          2008/03/26    
      **********************************************************************************************/
    FUNCTION get_prioritary_task
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_mess1    IN VARCHAR2,
        i_mess2    IN VARCHAR2,
        i_domain   IN VARCHAR2,
        i_prof_cat IN category.flg_type%TYPE,
        i_test     IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2;

    FUNCTION get_prioritary_task
    (
        i_lang     IN language.id_language%TYPE,
        i_mess1    IN VARCHAR2,
        i_mess2    IN VARCHAR2,
        i_domain   IN VARCHAR2,
        i_cat_type IN category.flg_type%TYPE
    ) RETURN VARCHAR2;

    FUNCTION delete_epis_grid_task
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_grid_task
    (
        i_lang      IN language.id_language%TYPE,
        i_grid_task IN grid_task%ROWTYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_grid_task
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        analysis_d_in         IN grid_task.analysis_d%TYPE DEFAULT NULL,
        analysis_d_nin        IN BOOLEAN := TRUE,
        analysis_n_in         IN grid_task.analysis_n%TYPE DEFAULT NULL,
        analysis_n_nin        IN BOOLEAN := TRUE,
        harvest_in            IN grid_task.harvest%TYPE DEFAULT NULL,
        harvest_nin           IN BOOLEAN := TRUE,
        exam_d_in             IN grid_task.exam_d%TYPE DEFAULT NULL,
        exam_d_nin            IN BOOLEAN := TRUE,
        exam_n_in             IN grid_task.exam_n%TYPE DEFAULT NULL,
        exam_n_nin            IN BOOLEAN := TRUE,
        drug_presc_in         IN grid_task.drug_presc%TYPE DEFAULT NULL,
        drug_presc_nin        IN BOOLEAN := TRUE,
        drug_req_in           IN grid_task.drug_req%TYPE DEFAULT NULL,
        drug_req_nin          IN BOOLEAN := TRUE,
        drug_transp_in        IN grid_task.drug_transp%TYPE DEFAULT NULL,
        drug_transp_nin       IN BOOLEAN := TRUE,
        intervention_in       IN grid_task.intervention%TYPE DEFAULT NULL,
        intervention_nin      IN BOOLEAN := TRUE,
        monitorization_in     IN grid_task.monitorization%TYPE DEFAULT NULL,
        monitorization_nin    IN BOOLEAN := TRUE,
        nurse_activity_in     IN grid_task.nurse_activity%TYPE DEFAULT NULL,
        nurse_activity_nin    IN BOOLEAN := TRUE,
        teach_req_in          IN grid_task.teach_req%TYPE DEFAULT NULL,
        teach_req_nin         IN BOOLEAN := TRUE,
        movement_in           IN grid_task.movement%TYPE DEFAULT NULL,
        movement_nin          IN BOOLEAN := TRUE,
        clin_rec_req_in       IN grid_task.clin_rec_req%TYPE DEFAULT NULL,
        clin_rec_req_nin      IN BOOLEAN := TRUE,
        clin_rec_transp_in    IN grid_task.clin_rec_transp%TYPE DEFAULT NULL,
        clin_rec_transp_nin   IN BOOLEAN := TRUE,
        vaccine_in            IN grid_task.vaccine%TYPE DEFAULT NULL,
        vaccine_nin           IN BOOLEAN := TRUE,
        hemo_req_in           IN grid_task.hemo_req%TYPE DEFAULT NULL,
        hemo_req_nin          IN BOOLEAN := TRUE,
        material_req_in       IN grid_task.material_req%TYPE DEFAULT NULL,
        material_req_nin      IN BOOLEAN := TRUE,
        icnp_intervention_in  IN grid_task.icnp_intervention%TYPE DEFAULT NULL,
        icnp_intervention_nin IN BOOLEAN := TRUE,
        positioning_in        IN grid_task.positioning%TYPE DEFAULT NULL,
        positioning_nin       IN BOOLEAN := TRUE,
        hidrics_reg_in        IN grid_task.hidrics_reg%TYPE DEFAULT NULL,
        hidrics_reg_nin       IN BOOLEAN := TRUE,
        scale_value_in        IN grid_task.scale_value%TYPE DEFAULT NULL,
        scale_value_nin       IN BOOLEAN := TRUE,
        prescription_n_in     IN grid_task.prescription_n%TYPE DEFAULT NULL,
        prescription_n_nin    IN BOOLEAN := TRUE,
        prescription_p_in     IN grid_task.prescription_p%TYPE DEFAULT NULL,
        prescription_p_nin    IN BOOLEAN := TRUE,
        discharge_pend_in     IN grid_task.discharge_pend%TYPE DEFAULT NULL,
        discharge_pend_nin    IN BOOLEAN := TRUE,
        supplies_in           IN grid_task.supplies%TYPE DEFAULT NULL,
        supplies_nin          IN BOOLEAN := TRUE,
        noc_outcome_in        IN grid_task.noc_outcome%TYPE DEFAULT NULL,
        noc_outcome_nin       IN BOOLEAN := TRUE,
        noc_indicator_in      IN grid_task.noc_indicator%TYPE DEFAULT NULL,
        noc_indicator_nin     IN BOOLEAN := TRUE,
        nic_activity_in       IN grid_task.nic_activity%TYPE DEFAULT NULL,
        nic_activity_nin      IN BOOLEAN := TRUE,
        opinion_state_in      IN grid_task.opinion_state%TYPE DEFAULT NULL,
        opinion_state_nin     IN BOOLEAN := TRUE,
        oth_exam_d_in         IN grid_task.oth_exam_d%TYPE DEFAULT NULL,
        oth_exam_d_nin        IN BOOLEAN := TRUE,
        oth_exam_n_in         IN grid_task.oth_exam_n%TYPE DEFAULT NULL,
        oth_exam_n_nin        IN BOOLEAN := TRUE,
        img_exam_d_in         IN grid_task.img_exam_d%TYPE DEFAULT NULL,
        img_exam_d_nin        IN BOOLEAN := TRUE,
        img_exam_n_in         IN grid_task.img_exam_n%TYPE DEFAULT NULL,
        img_exam_n_nin        IN BOOLEAN := TRUE,
        disp_task_in          IN grid_task.disp_task%TYPE DEFAULT NULL,
        disp_task_nin         IN BOOLEAN := TRUE,
        disp_ivroom_in        IN grid_task.disp_ivroom%TYPE DEFAULT NULL,
        disp_ivroom_nin       IN BOOLEAN := TRUE,
        common_order_in       IN grid_task.common_order%TYPE DEFAULT NULL,
        common_order_nin      IN BOOLEAN := TRUE,
        medical_order_in      IN grid_task.medical_order%TYPE DEFAULT NULL,
        medical_order_nin     IN BOOLEAN := TRUE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_nurse_task
    (
        i_lang      IN language.id_language%TYPE,
        i_grid_task IN grid_task_between%ROWTYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION delete_nurse_task
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    -- LG 2007-JAN-29
    FUNCTION get_daily_active_unpayed
    (
        i_lang  IN language.id_language%TYPE,
        i_dt    IN VARCHAR2,
        i_prof  IN profissional,
        o_epis  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Return grid_task fields to professional timezone.
    *
    * @param      I_LANG              língua registada como preferência do profissional.
    * @param      I_PROF              object (ID do profissional, ID da instituição, ID do software).
    * @param      I_STR               Texto de GRID_TASK
    * @param      I_POSITION          Position of the date field
    * @param      O_ERROR             erro
    *
    * @return     varchar2
    * @author     Rui Spratley/João Sá
    * @version    0.1
    * @since      2007/09/10
    * @notes
    */
    FUNCTION convert_grid_task_str
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_str      IN VARCHAR2,
        i_position IN NUMBER DEFAULT 2
    ) RETURN VARCHAR2;

    /*
    * Returns grid_task analysis or exam fields for a given visit.
    *
    * @param      I_LANG              language ID
    * @param      I_PROF              object (professional ID, institution ID, software ID).
    * @param      I_VISIT             visit ID
    * @param      I_TYPE              field type: A - analysis; E - exam; H - harvest
    * @param      O_ERROR             error message
    *
    * @return     varchar2
    * @author     José Silva
    * @version    1.0
    * @since      2008/01/16
    */
    FUNCTION visit_grid_task_str
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_visit    IN visit.id_visit%TYPE,
        i_type     IN VARCHAR2,
        i_prof_cat IN category.flg_type%TYPE
    ) RETURN VARCHAR2;

    /*
    *********************************************************************************************
      * VISIT_GRID_TASK_STR No Convert. Similar to VISIT_GRID_TASK_STR, yet no call to CONVERT_GRID_TASK_STR
      * is made in the end. Check NURSE_EFECTIV_CARE for usage example.
      *
      * @param i_lang                   language identifier
      * @param i_prof                   logged professional structure
      * @param i_visit                  visit identifier
      * @param i_type                   field type
      * @param i_prof_cat               professional category type
      *
      * @value i_type                   {*} 'A' Analysis {*} 'E' Exams {*} 'H' Harvests {*} 'M' Monitorizations {*} 'I' Intervention prescriptions
      *
      * @return                         varchar
      *
      * @raises
      *
      * @author                         Pedro Carneiro
      * @version                         1.0
      * @since                          2009/04/07
      **********************************************************************************************/
    FUNCTION visit_grid_task_str_nc
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_visit    IN visit.id_visit%TYPE,
        i_type     IN VARCHAR2,
        i_prof_cat IN category.flg_type%TYPE
    ) RETURN VARCHAR2;

    /*
    * Return a list of actions of the principal grid - MFR - terapeuta
    *
    * @param      I_LANG              língua registada como preferência do profissional.
    * @param      I_PROF              object (ID do profissional, ID da instituição, ID do software).
    * @param      I_ID_SCHEDULE       ID SCHEDULE   
    * @param      o_status            estados possiveis
    * @param      O_ERROR             erro
    *
    * @return     BOOLEAN
    * @author     Rita Lopes
    * @version    0.1
    * @since      2008/04/28
    * @notes
    */
    FUNCTION get_pat_status_list_session
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_status  IN VARCHAR2,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_status      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_schedule_real_state
    (
        flg_state IN schedule_outp.flg_state%TYPE,
        flg_ehr   IN episode.flg_ehr%TYPE
    ) RETURN VARCHAR2;

    /*
    *********************************************************************************************************** 
      *  Obtem a lista de estados possíveis de um paciente nas consultas de enfermagem    
      *
      * @param      i_lang           language
      * @param      i_prof           professional
      * @param      i_flg_status     Estado actual do paciente
      * @param      i_id_schedule    Id do agendamento
      *    
      * @author     Teresa Coutinho
      * @version    0.1
      * @since      2008/05/26
      ***********************************************************************************************************/

    FUNCTION get_pat_nurse_status_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_status  IN VARCHAR2,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_status      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get data for multichoice on patient grids.
    * No option is selectable.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_schedule  schedule identifier
    * @param o_status       cursor 
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.0.7.8
    * @since                2010/04/19
    */
    FUNCTION get_pat_nurse_status_list_na
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_status      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_notification_mfr_detail
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_dt               IN VARCHAR2,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        --i_id_rep_mfr_notification IN rep_mfr_notification.id_rep_mfr_notification%TYPE,
        i_flg_type             IN VARCHAR2,
        o_visit_name           OUT VARCHAR2,
        o_date_target          OUT VARCHAR2,
        o_hour_target          OUT VARCHAR2,
        o_nick_name            OUT professional.nick_name%TYPE,
        o_screen_title         OUT pk_translation.t_desc_translation,
        o_notification         OUT pk_types.cursor_type,
        o_notification_labels  OUT pk_types.cursor_type,
        o_notification_session OUT pk_types.cursor_type,
        o_not_session_labels   OUT pk_types.cursor_type
    ) RETURN BOOLEAN;

    /*
    *********************************************************************************************************** 
      * Grelha do enfermeiro detalhe dos cancelamentos das consultas de enfermagem    
      *
      * @param      i_lang           language
      * @param      i_prof           professional
      * @param      i_schedule       id do agendamento
      *    
      * @author     Teresa Coutinho
      * @version    0.1
      * @since      2008/12/21
      ***********************************************************************************************************/

    FUNCTION nurse_appointment_det
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_schedule      IN schedule.id_schedule%TYPE,
        o_cancel        OUT pk_types.cursor_type,
        o_cancel_detail OUT pk_types.cursor_type,
        o_det_title     OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_state_change
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_epis        IN episode.id_episode%TYPE,
        i_pat         IN patient.id_patient%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_from_state  IN schedule_outp.flg_state%TYPE,
        i_to_state    IN schedule_outp.flg_state%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION set_state_change_nc
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_epis        IN episode.id_episode%TYPE,
        i_pat         IN patient.id_patient%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_from_state  IN schedule_outp.flg_state%TYPE,
        i_to_state    IN schedule_outp.flg_state%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets outpatient schedule flg_state info.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_FLG_STATUS  schedule status
    * @param   I_ID_SCHEDULE id schedule
    * @param   O_STATUS the cursur with the domains info
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Rita Lopes
    * @version 1.0
    * @since   16-12-2009
    */
    FUNCTION get_reg_sched_state_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_status  IN VARCHAR2,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_status      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    *********************************************************************************************
      * GET_GRID_PAT_CONFIRM            Returns the patients grid for a given date [and professional, according to flg_prof]
      *
      * @param i_lang                   Language ID
      * @param i_prof                   Professional details
      * @param i_id_episode             table_number of Episode identifier
      * @param o_grid                   Grid information for confirmation screen
      * @param o_error                  Error message
      *
      * @return                         True on success, false otherwise
      *                        
      * @author                         Luís Maia
      * @version                        2.6.0.3
      * @since                          2010/06/04
      * @alteration                     
      **********************************************************************************************/
    FUNCTION get_grid_pat_confirm
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN table_number,
        o_grid       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /*
    ********************************************************************************************* 
      * Returns a list of days with appointments
      *
      * @param i_lang                   language identifier
      * @param i_prof                   logged professional structure
      * @param o_date                   days list
      * @param o_error                  error
      *
      * @return                         false if errors occur, true otherwise
      *
      * @raises
      *
      * @author                         Paulo Teixeira
      * @since                          2011/10/12
      **********************************************************************************************/
    FUNCTION nurse_appointment_dates
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_date  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    *********************************************************************************************
      * DELETE_DRUG_PRESC_FIELD         Forces the deletion of DRUG_PRESC field from GRID_TASK
      *
      * @param i_lang                   Language ID
      * @param i_prof                   Professional details
      * @param i_id_episode             table_number of Episode identifier
      * @param o_error                  Error message
      *
      * @return                         True on success, false otherwise
      *                        
      * @author                         Pedro Teixeira
      * @version                        2.6.2
      * @since                          15/02/2012
      * @alteration                     
      **********************************************************************************************/
    FUNCTION delete_drug_presc_field
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    *******************************************************************************************
      * Converts the status string dates timezone
      *
      * @param  I_LANG                                  IN        NUMBER(22,6)
      * @param  I_PROF                                  IN        PROFISSIONAL
      * @param  I_STR                                   IN        VARCHAR2
      *
      * @return  VARCHAR2
      *
      * @author      Alexis Nascimento
      * @version     v2.6.4.2.2
      * @since       05/11/2014
      *
      ********************************************************************************************/

    FUNCTION convert_grid_task_dates_to_str
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_str  IN VARCHAR2
    ) RETURN VARCHAR2;

    /*
    *********************************************************************************************
      * DELETE_DRUG_REQ_FIELD         Forces the deletion of DRUG_REQ field from GRID_TASK
      *
      * @param i_lang                   Language ID
      * @param i_prof                   Professional details
      * @param i_id_episode             table_number of Episode identifier
      * @param o_error                  Error message
      *
      * @return                         True on success, false otherwise
      *                        
      * @author          Pedro Teixeira
      * @since           05/01/2018
      **********************************************************************************************/
    FUNCTION delete_drug_req_field
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    *********************************************************************************************
      * UPDATE_DRUG_REQ_FIELD
      *
      * @param i_lang                   Language ID
      * @param i_prof                   Professional details
      * @param i_id_episode             table_number of Episode identifier
      * @param o_error                  Error message
      *
      * @return                         True on success, false otherwise
      *                        
      * @author          Pedro Teixeira
      * @since           05/01/2018
      **********************************************************************************************/
    FUNCTION update_drug_req_field
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_drug_req   IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_has_nurse_vs_status
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2;

    /*
    *********************************************************************************************
      * Update field disp_ivroom of grid_task for a given episode 
      *
      * @param i_lang                   Language ID
      * @param i_prof                   Professional details
      * @param i_id_episode             Episode identifier
      * @param i_disp_ivroom           field disp_ivroom of grid_task
      * @param o_error                  Error message
      *
      * @return                         True on success, false otherwise
      *                        
      * @author                         CRISTINA.OLIVEIRA
      * @since                          18/01/2019
      **********************************************************************************************/
    FUNCTION update_disp_ivroom_field
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_disp_ivroom IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    *********************************************************************************************
      * Update field i_disp_task of grid_task for a given episode 
      *
      * @param i_lang                   Language ID
      * @param i_prof                   Professional details
      * @param i_id_episode             Episode identifier
      * @param i_disp_task              field i_disp_task of grid_task
      * @param o_error                  Error message
      *
      * @return                         True on success, false otherwise
      *                        
      * @author                         CRISTINA.OLIVEIRA
      * @since                          18/01/2019
      **********************************************************************************************/
    FUNCTION update_disp_task_field
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_disp_task  IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    *********************************************************************************************
      *Forces the deletion of DISP_IVROOM field from GRID_TASK
      *
      * @param i_lang                   Language ID
      * @param i_prof                   Professional details
      * @param i_id_episode             Episode identifier
      * @param o_error                  Error message
      *
      * @return                         True on success, false otherwise
      *                        
      * @author                         CRISTINA.OLIVEIRA     
      * @since                          18/01/2019
      **********************************************************************************************/
    FUNCTION delete_disp_ivroom_field
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    *********************************************************************************************
      *Forces the deletion of DISP_TASK field from GRID_TASK
      *
      * @param i_lang                   Language ID
      * @param i_prof                   Professional details
      * @param i_id_episode             Episode identifier
      * @param o_error                  Error message
      *
      * @return                         True on success, false otherwise
      *                        
      * @author                         CRISTINA.OLIVEIRA     
      * @since                          18/01/2019
      **********************************************************************************************/
    FUNCTION delete_disp_task_field
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_dates_admin_grid
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_date  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_flg_status   IN VARCHAR2,
        i_id_schedule  IN schedule.id_schedule%TYPE,
        i_id_patient   IN patient.id_patient%TYPE,
        i_id_epis_type IN epis_type.id_epis_type%TYPE,
        i_flg_group    IN VARCHAR2 DEFAULT 'N',
        i_id_group     IN schedule.id_group%TYPE,
        i_context      IN VARCHAR2,
        o_status       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    ------------------------------------------------------------------------
    g_flg_patient_status_active   VARCHAR2(1);
    g_flg_visit_status_active     VARCHAR2(1);
    g_flg_episode_status_active   VARCHAR2(1);
    g_flg_episode_type_outpatient VARCHAR2(1);
    g_month_sign                  VARCHAR2(1);
    g_day_sign                    VARCHAR2(1);
    g_flg_doctor                  category.flg_type%TYPE;
    g_flg_nurse                   category.flg_type%TYPE;
    g_flg_pharmacist              category.flg_type%TYPE;
    g_flg_aux                     category.flg_type%TYPE;
    g_flg_admin                   category.flg_type%TYPE;
    g_flg_tech                    category.flg_type%TYPE;
    g_error                       VARCHAR2(4000);
    g_found                       BOOLEAN;

    g_epis_active   episode.flg_status%TYPE;
    g_epis_inactive episode.flg_status%TYPE;
    g_epis_temp     episode.flg_status%TYPE;
    g_epis_canc     episode.flg_status%TYPE;

    g_analy_req_pend analysis_req.flg_status%TYPE;
    g_analy_req_req  analysis_req.flg_status%TYPE;
    g_analy_req_exec analysis_req.flg_status%TYPE;
    g_analy_req_res  analysis_req.flg_status%TYPE;
    g_analy_req_canc analysis_req.flg_status%TYPE;
    g_analy_req_part analysis_req.flg_status%TYPE;
    g_analy_req_tran analysis_req.flg_status%TYPE;
    g_analy_req_harv analysis_req.flg_status%TYPE;
    g_analy_req_ext  analysis_req.flg_status%TYPE;

    g_exam_req_tosched exam_req.flg_status%TYPE;
    g_exam_req_sched   exam_req.flg_status%TYPE;
    g_exam_req_efectiv exam_req.flg_status%TYPE;
    g_exam_req_pend    exam_req.flg_status%TYPE;
    g_exam_req_req     exam_req.flg_status%TYPE;
    g_exam_req_exec    exam_req.flg_status%TYPE;
    g_exam_req_part    exam_req.flg_status%TYPE;
    g_exam_req_resu    exam_req.flg_status%TYPE;
    g_exam_req_canc    exam_req.flg_status%TYPE;
    g_exam_req_nr      exam_req.flg_status%TYPE;
    g_exam_req_read    exam_req.flg_status%TYPE;

    g_icon_tosched_admin CONSTANT VARCHAR2(20) := 'ScheduledNewIcon';

    g_interv_pend interv_prescription.flg_status%TYPE;
    g_interv_req  interv_prescription.flg_status%TYPE;
    g_interv_fin  interv_prescription.flg_status%TYPE;
    g_interv_canc interv_prescription.flg_status%TYPE;
    g_interv_part interv_prescription.flg_status%TYPE;
    g_interv_exe  interv_prescription.flg_status%TYPE;
    g_interv_intr interv_prescription.flg_status%TYPE;

    g_interv_plan_admin interv_presc_plan.flg_status%TYPE;
    g_interv_plan_req   interv_presc_plan.flg_status%TYPE;
    g_interv_plan_pend  interv_presc_plan.flg_status%TYPE;
    g_interv_plan_canc  interv_presc_plan.flg_status%TYPE;

    g_flg_time_e analysis_req.flg_time%TYPE;
    g_flg_time_n analysis_req.flg_time%TYPE;
    g_flg_time_b analysis_req.flg_time%TYPE;
    g_flg_time_d analysis_req.flg_time%TYPE;

    g_flg_status_f  VARCHAR2(2);
    g_flg_status_p  VARCHAR2(2);
    g_flg_status_r  VARCHAR2(2);
    g_flg_status_a  VARCHAR2(2);
    g_flg_status_c  VARCHAR2(2);
    g_flg_status_e  VARCHAR2(2);
    g_flg_status_d  VARCHAR2(2);
    g_flg_status_i  VARCHAR2(2);
    g_flg_status_x  VARCHAR2(2);
    g_flg_status_g  VARCHAR2(2) := 'A';
    g_flg_status_pa VARCHAR2(2) := 'PA';
    g_flg_status_cc VARCHAR2(2) := 'CC';
    g_flg_status_o  VARCHAR2(2) := 'O';

    g_vaccine_pend vaccine_prescription.flg_status%TYPE;
    g_vaccine_req  vaccine_prescription.flg_status%TYPE;
    g_vaccine_res  vaccine_prescription.flg_status%TYPE;
    g_vaccine_canc vaccine_prescription.flg_status%TYPE;
    g_vaccine_part vaccine_prescription.flg_status%TYPE;
    g_vaccine_exe  vaccine_prescription.flg_status%TYPE;

    g_sched_scheduled    schedule_outp.flg_state%TYPE;
    g_sched_efectiv      schedule_outp.flg_state%TYPE;
    g_sched_med_disch    schedule_outp.flg_state%TYPE;
    g_sched_adm_disch    schedule_outp.flg_state%TYPE;
    g_sched_nurse_disch  schedule_outp.flg_state%TYPE;
    g_sched_wait         schedule_outp.flg_state%TYPE;
    g_sched_nurse_prev   schedule_outp.flg_state%TYPE;
    g_sched_nurse        schedule_outp.flg_state%TYPE;
    g_sched_nurse_end    schedule_outp.flg_state%TYPE;
    g_sched_cons         schedule_outp.flg_state%TYPE;
    g_sched_wait_1nurse  schedule_outp.flg_state%TYPE;
    g_sched_in_1nurse    schedule_outp.flg_state%TYPE;
    g_sched_nutri_disch  schedule_outp.flg_state%TYPE := 'U';
    g_sched_ortopt       schedule_outp.flg_state%TYPE := 'G';
    g_sched_canc         schedule.flg_status%TYPE;
    g_sched_temp         schedule.flg_status%TYPE;
    g_flg_state_p        schedule_outp.flg_state%TYPE;
    g_flg_no_show        schedule_outp.flg_state%TYPE := 'B';
    g_sched_psycho_disch schedule_outp.flg_state%TYPE;
    g_sched_rt_disch     schedule_outp.flg_state%TYPE;
    g_sched_cdc_disch    schedule_outp.flg_state%TYPE;

    -- SCHEDULE_OUTP.FLG_NURSE_ACTION
    g_nurse_scheduled CONSTANT VARCHAR2(1) := 'A';

    g_icon        VARCHAR2(1);
    g_message     VARCHAR2(1);
    g_color_red   VARCHAR2(1);
    g_color_green VARCHAR2(1);
    g_no_color    VARCHAR2(1);

    g_text         VARCHAR2(1);
    g_date         VARCHAR2(1);
    g_dateicon     VARCHAR2(2);
    g_sysdate      DATE;
    g_sysdate_char VARCHAR2(50);

    g_mov_status_transp movement.flg_status%TYPE;
    g_mov_status_finish movement.flg_status%TYPE;
    g_mov_status_pend   movement.flg_status%TYPE;
    g_mov_status_req    movement.flg_status%TYPE;
    g_mov_status_interr movement.flg_status%TYPE;
    g_mov_status_cancel movement.flg_status%TYPE;

    g_cli_rec_pend    cli_rec_req.flg_status%TYPE;
    g_cli_rec_exec    cli_rec_req.flg_status%TYPE;
    g_cli_rec_cancel  cli_rec_req.flg_status%TYPE;
    g_cli_rec_req     cli_rec_req.flg_status%TYPE;
    g_cli_rec_partial cli_rec_req.flg_status%TYPE;
    g_cli_rec_finish  cli_rec_req.flg_status%TYPE;

    g_cli_rec_mov_o cli_rec_req_mov.flg_status%TYPE;
    g_cli_rec_mov_t cli_rec_req_mov.flg_status%TYPE;

    g_harvest_cancel harvest.flg_status%TYPE;
    g_harvest_finish harvest.flg_status%TYPE;
    g_harvest_trans  harvest.flg_status%TYPE;
    g_harvest_harv   harvest.flg_status%TYPE;

    g_monit_pend monitorization.flg_status%TYPE;
    g_monit_exe  monitorization.flg_status%TYPE;
    g_monit_fin  monitorization.flg_status%TYPE;
    g_monit_canc monitorization.flg_status%TYPE;

    g_exam_image exam.flg_type%TYPE;
    g_exam_func  exam.flg_type%TYPE;
    g_exam_audio exam.flg_type%TYPE;
    g_exam_gastr exam.flg_type%TYPE;
    g_exam_ortho exam.flg_type%TYPE;

    g_nurse_tea_pend nurse_tea_req.flg_status%TYPE;
    g_nurse_tea_act  nurse_tea_req.flg_status%TYPE;
    g_nurse_tea_fin  nurse_tea_req.flg_status%TYPE;
    g_nurse_tea_can  nurse_tea_req.flg_status%TYPE;

    g_read VARCHAR2(1);
    g_yes  VARCHAR2(1);
    g_no   VARCHAR2(1);

    g_flg_area_e interv_physiatry_area.flg_type%TYPE;
    g_flg_area_t interv_physiatry_area.flg_type%TYPE;
    g_flg_area_c interv_physiatry_area.flg_type%TYPE;
    g_flg_area_h interv_physiatry_area.flg_type%TYPE;
    g_flg_area_o interv_physiatry_area.flg_type%TYPE;
    g_flg_area_f interv_physiatry_area.flg_type%TYPE;

    g_flg_grid   VARCHAR2(1);
    g_flg_search VARCHAR2(1);

    g_flg_sos interv_presc_det.flg_interv_type%TYPE;

    g_monit_plan_pend monitorization_vs_plan.flg_status%TYPE;
    g_monit_plan_inco monitorization_vs_plan.flg_status%TYPE;

    g_nactv_det_pend nurse_actv_req_det.flg_status%TYPE;
    g_nactv_det_req  nurse_actv_req_det.flg_status%TYPE;
    g_nactv_det_exec nurse_actv_req_det.flg_status%TYPE;

    g_schdl_outp_state_domain     sys_domain.code_domain%TYPE;
    g_schdl_outp_state_act_domain sys_domain.code_domain%TYPE;
    g_schdl_nurse_state_domain    sys_domain.code_domain%TYPE;
    -- RL 2008/05/16    
    g_schdl_interv_state_domain sys_domain.code_domain%TYPE;

    g_sch_subs schedule_outp.flg_type%TYPE;
    g_instit_h institution.flg_type%TYPE;
    g_instit_c institution.flg_type%TYPE;

    g_wr_available_y VARCHAR2(1);
    g_sys_config_wr  VARCHAR2(50);

    g_selected VARCHAR2(1);
    g_isencao  VARCHAR2(1);

    g_currency_unit_format_db sys_config.id_sys_config%TYPE;
    g_exam_can_req            exam_dep_clin_serv.flg_type%TYPE;

    -- JS, 2007-09-11 - Timezone
    g_sysdate_tstz TIMESTAMP WITH TIME ZONE;

    g_edis_software   VARCHAR2(1);
    g_nutri_software  software.id_software%TYPE;
    g_psycho_software software.id_software%TYPE;
    g_rehab_software  software.id_software%TYPE;

    g_task_analysis CONSTANT VARCHAR2(1) := 'A';
    g_task_exam     CONSTANT VARCHAR2(1) := 'E';
    g_task_harvest  CONSTANT VARCHAR2(1) := 'H';

    g_flg_notification_c schedule.flg_notification%TYPE := 'C';
    g_flg_notification_p schedule.flg_notification%TYPE := 'P';
    g_flg_notification_n schedule.flg_notification%TYPE := 'N';
    g_flg_interv_d       interv_presc_det.flg_status%TYPE := 'D';
    g_flg_interv_p       interv_presc_det.flg_status%TYPE := 'P';
    g_flg_interv_v       interv_presc_det.flg_status%TYPE := 'V';
    g_flg_freq           sys_domain.code_domain%TYPE := 'INTERV_PRESC_DET.FLG_FREQ';
    g_priority_domain    sys_domain.code_domain%TYPE := 'INTERV_PRESC_DET.FLG_PRTY';

    g_flg_interv_a interv_presc_det.flg_status%TYPE := 'A';
    g_flg_interv_e interv_presc_det.flg_status%TYPE := 'E';
    g_flg_interv_c interv_presc_det.flg_status%TYPE := 'C';
    g_flg_interv_f interv_presc_det.flg_status%TYPE := 'F';
    g_flg_interv_s interv_presc_det.flg_status%TYPE := 'S';
    g_flg_interv_i interv_presc_det.flg_status%TYPE := 'I';
    g_flg_interv_g interv_presc_det.flg_status%TYPE := 'G';

    g_sched_interv_scheduled schedule_intervention.flg_state%TYPE := 'A';
    g_sched_interv_cancelled schedule_intervention.flg_state%TYPE := 'C';
    g_sched_interv_missed    schedule_intervention.flg_state%TYPE := 'F';

    g_cat_type_f category.flg_type%TYPE;
    g_cat_type_a category.flg_type%TYPE;
    g_cat_type_c category.flg_type%TYPE;

    g_flg_ehr_normal CONSTANT VARCHAR2(1) := 'N';

    g_flg_ehr CONSTANT VARCHAR2(1) := 'E';

    g_flg_epis_type_nurse_care VARCHAR2(2);
    g_flg_epis_type_nurse_outp VARCHAR2(2);
    g_flg_epis_type_nurse_pp   VARCHAR2(2);
    g_epis_type_nurse          epis_type.id_epis_type%TYPE;
    g_epis_type_rehab          epis_type.id_epis_type%TYPE;

    g_flg_available VARCHAR2(1) := 'Y';

    g_flg_status              sys_domain.code_domain%TYPE;
    g_flg_status_change       sys_domain.code_domain%TYPE;
    g_flg_status_schedulepend sys_domain.code_domain%TYPE;

    g_alloc_y VARCHAR2(1);
    g_alloc_n VARCHAR2(1);

    g_flg_referral_reserved  CONSTANT interv_presc_det.flg_referral%TYPE := 'R';
    g_flg_referral_sent      CONSTANT interv_presc_det.flg_referral%TYPE := 'S';
    g_flg_referral_available CONSTANT interv_presc_det.flg_referral%TYPE := 'A';

    g_flg_available_y CONSTANT VARCHAR2(1) := 'Y';
    g_flg_available_n CONSTANT VARCHAR2(1) := 'N';

    g_icon_ft          CONSTANT VARCHAR2(1) := 'F';
    g_icon_ft_transfer CONSTANT VARCHAR2(1) := 'T';
    g_ft_color         CONSTANT VARCHAR2(200) := '0xFFFFFF';
    g_ft_triage_white  CONSTANT VARCHAR2(200) := '0x787864';
    g_ft_status        CONSTANT VARCHAR2(1) := 'A';
    g_desc_grid        CONSTANT VARCHAR2(1) := 'G';

    g_flg_notes_n CONSTANT procedures_ea.flg_notes%TYPE := 'N';

    g_interv_p CONSTANT VARCHAR2(1) := 'P';

    g_flg_nurse_pre_y CONSTANT VARCHAR2(1) := 'Y';

    g_discharge_active   CONSTANT discharge.flg_status%TYPE := 'A';
    g_shed_discharge_med CONSTANT schedule_outp.flg_state%TYPE := 'D';

    g_flg_y CONSTANT VARCHAR2(1) := 'Y';

    g_exception EXCEPTION;

    g_sch_event_therap_decision sch_event.id_sch_event%TYPE := 20;

    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Date positions of grid task status string
    g_gt_date_pos CONSTANT table_number := table_number(3, 10);

    FUNCTION set_up_img
    (
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_flg_state         IN VARCHAR2,
        i_flg_status_adm    IN VARCHAR2,
        i_dt_begin_tstz     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_first_obs_tstz IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_med_tstz       IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_admin_tstz     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_sd2_img_name      IN VARCHAR2
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Saber se o episódio tem (Y) ou não (N) prescrições "até à próxima consulta" para hoje.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional details
    * @param i_id_episode             table_number of Episode identifier
    * @param o_error                  Error message
    *
    * @return                         Y/N
    *                        
    * @author          Elisabete Bugalho
    * @since           14/02/2022
    **********************************************************************************************/
    FUNCTION exist_prescription_between
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;
END pk_grid;
/
