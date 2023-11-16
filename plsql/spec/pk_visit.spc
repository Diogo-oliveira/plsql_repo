/*-- Last Change Revision: $Rev: 2029040 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:27 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_visit IS

    FUNCTION interf_info
    (
        i_id_institution     IN institution.id_institution%TYPE,
        i_id_instit_requests IN institution.id_institution%TYPE,
        i_clin_serv          IN clinical_service.id_clinical_service%TYPE,
        i_id_prof            IN sch_resource.id_professional%TYPE,
        i_id_prof_schedules  IN sch_resource.id_professional%TYPE,
        i_epis_type          IN episode.id_epis_type%TYPE,
        i_id_pat             IN patient.id_patient%TYPE,
        i_dt_schedule_begin  IN schedule.dt_begin_tstz%TYPE,
        i_dt_mcdt_begin      IN analysis_req.dt_begin_tstz%TYPE,
        i_id_analysis        IN analysis.id_analysis%TYPE DEFAULT NULL,
        i_id_exam            IN exam.id_exam%TYPE DEFAULT NULL,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    FUNCTION create_visit
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_pat               IN patient.id_patient%TYPE,
        i_id_institution       IN institution.id_institution%TYPE,
        i_id_sched             IN epis_info.id_schedule%TYPE,
        i_id_professional      IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_external_cause       IN visit.id_external_cause%TYPE,
        i_health_plan          IN health_plan.id_health_plan%TYPE,
        i_epis_type            IN episode.id_epis_type%TYPE,
        i_dep_clin_serv        IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_origin               IN visit.id_origin%TYPE,
        i_flg_ehr              IN episode.flg_ehr%TYPE DEFAULT 'N',
        i_dt_begin             IN episode.dt_begin_tstz%TYPE,
        i_flg_appointment_type IN episode.flg_appointment_type%TYPE,
        i_transaction_id       IN VARCHAR2,
        o_episode              OUT episode.id_episode%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /* copia do create_visit #1 mas sem o commit no fim*/
    FUNCTION create_visit_no_commit
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_pat               IN patient.id_patient%TYPE,
        i_id_institution       IN institution.id_institution%TYPE,
        i_id_sched             IN epis_info.id_schedule%TYPE,
        i_id_professional      IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_external_cause       IN visit.id_external_cause%TYPE,
        i_health_plan          IN health_plan.id_health_plan%TYPE,
        i_epis_type            IN episode.id_epis_type%TYPE,
        i_dep_clin_serv        IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_origin               IN visit.id_origin%TYPE,
        i_flg_ehr              IN episode.flg_ehr%TYPE DEFAULT 'N',
        i_dt_begin             IN episode.dt_begin_tstz%TYPE,
        i_flg_appointment_type IN episode.flg_appointment_type%TYPE,
        i_transaction_id       IN VARCHAR2,
        o_episode              OUT episode.id_episode%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Flash wrapper do not use otherwise 
    */
    FUNCTION create_visit
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_pat               IN patient.id_patient%TYPE,
        i_id_institution       IN institution.id_institution%TYPE,
        i_id_sched             IN epis_info.id_schedule%TYPE,
        i_id_professional      IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_external_cause       IN visit.id_external_cause%TYPE,
        i_health_plan          IN health_plan.id_health_plan%TYPE,
        i_epis_type            IN episode.id_epis_type%TYPE,
        i_dep_clin_serv        IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_origin               IN visit.id_origin%TYPE,
        i_flg_ehr              IN episode.flg_ehr%TYPE DEFAULT 'N',
        i_dt_begin             IN episode.dt_begin_tstz%TYPE,
        i_flg_appointment_type IN episode.flg_appointment_type%TYPE,
        o_episode              OUT episode.id_episode%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------

    FUNCTION create_visit
    (
        i_lang            IN language.id_language%TYPE,
        i_id_pat          IN patient.id_patient%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        i_id_sched        IN epis_info.id_schedule%TYPE,
        i_id_professional IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_external_cause  IN visit.id_external_cause%TYPE,
        i_health_plan     IN health_plan.id_health_plan%TYPE,
        i_epis_type       IN episode.id_epis_type%TYPE,
        i_dep_clin_serv   IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_origin          IN visit.id_origin%TYPE,
        i_flg_ehr         IN episode.flg_ehr%TYPE DEFAULT 'N',
        i_dt_begin        IN episode.dt_begin_tstz%TYPE,
        i_transaction_id  IN VARCHAR2,
        o_episode         OUT episode.id_episode%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /** Flash wrapper do not use otherwise */
    FUNCTION create_visit
    (
        i_lang            IN language.id_language%TYPE,
        i_id_pat          IN patient.id_patient%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        i_id_sched        IN epis_info.id_schedule%TYPE,
        i_id_professional IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_external_cause  IN visit.id_external_cause%TYPE,
        i_health_plan     IN health_plan.id_health_plan%TYPE,
        i_epis_type       IN episode.id_epis_type%TYPE,
        i_dep_clin_serv   IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_origin          IN visit.id_origin%TYPE,
        i_flg_ehr         IN episode.flg_ehr%TYPE DEFAULT 'N',
        i_dt_begin        IN episode.dt_begin_tstz%TYPE,
        o_episode         OUT episode.id_episode%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------

    FUNCTION create_visit
    (
        i_lang            IN language.id_language%TYPE,
        i_id_pat          IN patient.id_patient%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        i_id_sched        IN epis_info.id_schedule%TYPE,
        i_id_professional IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_external_cause  IN visit.id_external_cause%TYPE,
        i_health_plan     IN health_plan.id_health_plan%TYPE,
        i_epis_type       IN episode.id_epis_type%TYPE,
        i_dep_clin_serv   IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_origin          IN visit.id_origin%TYPE,
        i_flg_ehr         IN episode.flg_ehr%TYPE DEFAULT 'N',
        i_transaction_id  IN VARCHAR2,
        o_episode         OUT episode.id_episode%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /** Flash wrapper do not use otherwise */
    FUNCTION create_visit
    (
        i_lang            IN language.id_language%TYPE,
        i_id_pat          IN patient.id_patient%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        i_id_sched        IN epis_info.id_schedule%TYPE,
        i_id_professional IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_external_cause  IN visit.id_external_cause%TYPE,
        i_health_plan     IN health_plan.id_health_plan%TYPE,
        i_epis_type       IN episode.id_epis_type%TYPE,
        i_dep_clin_serv   IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_origin          IN visit.id_origin%TYPE,
        i_flg_ehr         IN episode.flg_ehr%TYPE DEFAULT 'N',
        o_episode         OUT episode.id_episode%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------

    FUNCTION create_episode
    (
        i_lang            IN language.id_language%TYPE,
        i_id_visit        IN visit.id_visit%TYPE,
        i_id_professional IN profissional,
        i_id_sched        IN epis_info.id_schedule%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_health_plan     IN health_plan.id_health_plan%TYPE,
        i_epis_type       IN episode.id_epis_type%TYPE,
        i_dep_clin_serv   IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_transaction_id  IN VARCHAR2,
        o_episode         OUT episode.id_episode%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /** Flash wrapper do not use otherwise*/
    FUNCTION create_episode
    (
        i_lang            IN language.id_language%TYPE,
        i_id_visit        IN visit.id_visit%TYPE,
        i_id_professional IN profissional,
        i_id_sched        IN epis_info.id_schedule%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_health_plan     IN health_plan.id_health_plan%TYPE,
        i_epis_type       IN episode.id_epis_type%TYPE,
        i_dep_clin_serv   IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_episode         OUT episode.id_episode%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------

    FUNCTION create_episode
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_visit             IN visit.id_visit%TYPE,
        i_id_professional      IN profissional,
        i_id_sched             IN epis_info.id_schedule%TYPE,
        i_id_episode           IN episode.id_episode%TYPE,
        i_health_plan          IN health_plan.id_health_plan%TYPE,
        i_epis_type            IN episode.id_epis_type%TYPE,
        i_dep_clin_serv        IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_sysdate              IN DATE,
        i_sysdate_tstz         IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_ehr              IN episode.flg_ehr%TYPE DEFAULT 'N',
        i_flg_appointment_type IN episode.flg_appointment_type%TYPE,
        i_flg_unknown          IN epis_info.flg_unknown%TYPE DEFAULT pk_alert_constant.g_no,
        i_transaction_id       IN VARCHAR2,
        o_episode              OUT episode.id_episode%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /** Flash wrapper do not use otherwise */
    FUNCTION create_episode
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_visit             IN visit.id_visit%TYPE,
        i_id_professional      IN profissional,
        i_id_sched             IN epis_info.id_schedule%TYPE,
        i_id_episode           IN episode.id_episode%TYPE,
        i_health_plan          IN health_plan.id_health_plan%TYPE,
        i_epis_type            IN episode.id_epis_type%TYPE,
        i_dep_clin_serv        IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_sysdate              IN DATE,
        i_sysdate_tstz         IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_ehr              IN episode.flg_ehr%TYPE DEFAULT 'N',
        i_flg_appointment_type IN episode.flg_appointment_type%TYPE,
        o_episode              OUT episode.id_episode%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------

    FUNCTION set_episode_end
    (
        i_lang       IN language.id_language%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_prof       IN profissional,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_info
    (
        i_lang                IN language.id_language%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_prof                IN profissional,
        o_flg_type            OUT episode.id_epis_type%TYPE,
        o_flg_status          OUT episode.flg_status%TYPE,
        o_id_room             OUT epis_info.id_room%TYPE,
        o_desc_room           OUT VARCHAR2,
        o_dt_entrance_room    OUT VARCHAR2,
        o_dt_last_interaction OUT VARCHAR2,
        o_dt_movement         OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_epis_info
    (
        i_lang         IN language.id_language%TYPE,
        i_id_episode   IN epis_info.id_episode%TYPE,
        i_id_room      IN epis_info.id_room%TYPE,
        i_bed          IN epis_info.id_bed%TYPE,
        i_norton       IN epis_info.norton%TYPE,
        i_professional IN epis_info.id_professional%TYPE,
        i_flg_hydric   IN epis_info.flg_hydric%TYPE,
        i_flg_wound    IN epis_info.flg_wound%TYPE,
        i_companion    IN epis_info.companion%TYPE,
        i_flg_unknown  IN epis_info.flg_unknown%TYPE,
        i_desc_info    IN epis_info.desc_info%TYPE,
        i_prof         IN profissional,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_epis_info
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_episode           IN epis_info.id_episode%TYPE,
        i_id_prof              IN profissional,
        i_dt_entrance_room     IN VARCHAR2,
        i_dt_last_interaction  IN VARCHAR2,
        i_dt_movement          IN VARCHAR2,
        i_dt_harvest           IN VARCHAR2,
        i_dt_next_drug         IN VARCHAR2,
        i_dt_first_obs         IN VARCHAR2,
        i_dt_next_intervention IN VARCHAR2,
        i_dt_next_vital_sign   IN VARCHAR2,
        i_dt_next_position     IN VARCHAR2,
        i_dt_harvest_mov       IN VARCHAR2,
        i_dt_first_nurse_obs   IN VARCHAR2,
        i_prof_cat_type        IN category.flg_type%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_epis_info_no_obs
    (
        i_lang         IN language.id_language%TYPE,
        i_id_episode   IN epis_info.id_episode%TYPE,
        i_id_room      IN epis_info.id_room%TYPE,
        i_bed          IN epis_info.id_bed%TYPE,
        i_norton       IN epis_info.norton%TYPE,
        i_professional IN epis_info.id_professional%TYPE,
        i_flg_hydric   IN epis_info.flg_hydric%TYPE,
        i_flg_wound    IN epis_info.flg_wound%TYPE,
        i_companion    IN epis_info.companion%TYPE,
        i_flg_unknown  IN epis_info.flg_unknown%TYPE,
        i_desc_info    IN epis_info.desc_info%TYPE,
        i_prof         IN profissional,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_epis_info_no_obs
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_episode           IN epis_info.id_episode%TYPE,
        i_id_prof              IN profissional,
        i_dt_entrance_room     IN VARCHAR2,
        i_dt_last_interaction  IN VARCHAR2,
        i_dt_movement          IN VARCHAR2,
        i_dt_harvest           IN VARCHAR2,
        i_dt_next_drug         IN VARCHAR2,
        i_dt_first_obs         IN VARCHAR2,
        i_dt_next_intervention IN VARCHAR2,
        i_dt_next_vital_sign   IN VARCHAR2,
        i_dt_next_position     IN VARCHAR2,
        i_dt_harvest_mov       IN VARCHAR2,
        i_dt_first_nurse_obs   IN VARCHAR2,
        i_prof_cat_type        IN category.flg_type%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION upd_epis_info_analysis
    (
        i_lang                   IN language.id_language%TYPE,
        i_id_episode             IN epis_info.id_episode%TYPE,
        i_id_prof                IN profissional,
        i_dt_first_analysis_exec IN VARCHAR2,
        i_dt_first_analysis_req  IN VARCHAR2,
        i_prof_cat_type          IN category.flg_type%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION upd_epis_info_exam
    (
        i_lang                IN language.id_language%TYPE,
        i_id_episode          IN epis_info.id_episode%TYPE,
        i_id_prof             IN profissional,
        i_dt_first_image_exec IN VARCHAR2,
        i_dt_first_image_req  IN VARCHAR2,
        i_prof_cat_type       IN category.flg_type%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION upd_epis_info_drug
    (
        i_lang               IN language.id_language%TYPE,
        i_id_episode         IN epis_info.id_episode%TYPE,
        i_id_prof            IN profissional,
        i_dt_first_drug_prsc IN VARCHAR2,
        i_dt_first_drug_take IN VARCHAR2,
        i_prof_cat_type      IN category.flg_type%TYPE,
        i_commit             IN VARCHAR2 DEFAULT 'N',
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION upd_epis_info_interv
    (
        i_lang                       IN language.id_language%TYPE,
        i_id_episode                 IN epis_info.id_episode%TYPE,
        i_id_prof                    IN profissional,
        i_dt_first_intervention_prsc IN VARCHAR2,
        i_dt_first_intervention_take IN VARCHAR2,
        i_prof_cat_type              IN category.flg_type%TYPE,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_first_obs
    (
        i_lang                IN language.id_language%TYPE,
        i_id_episode          IN epis_info.id_episode%TYPE,
        i_pat                 IN patient.id_patient%TYPE,
        i_prof                IN profissional,
        i_prof_cat_type       IN category.flg_type%TYPE,
        i_dt_last_interaction IN epis_info.dt_last_interaction_tstz%TYPE,
        i_dt_first_obs        IN epis_info.dt_first_obs_tstz%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_first_obs
    (
        i_lang                IN language.id_language%TYPE,
        i_id_episode          IN epis_info.id_episode%TYPE,
        i_pat                 IN patient.id_patient%TYPE,
        i_prof                IN profissional,
        i_prof_cat_type       IN category.flg_type%TYPE,
        i_dt_last_interaction IN epis_info.dt_last_interaction_tstz%TYPE,
        i_dt_first_obs        IN epis_info.dt_first_obs_tstz%TYPE,
        i_flg_triage_call     IN VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_active_vis_epis
    (
        i_lang           IN language.id_language%TYPE,
        i_id_pat         IN patient.id_patient%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_prof           IN profissional,
        o_id_visit       OUT visit.id_visit%TYPE,
        o_id_episode     OUT episode.id_episode%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns visit from episode
    *
    * @param   i_episode          episode
    * @param   o_error            error message
    *
    * @author  Rui Spratley
    * @version 1.0
    * @since   2007/10/29
    */

    FUNCTION get_visit
    (
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN visit.id_visit%TYPE;

    FUNCTION set_prof_resp
    (
        i_lang       IN language.id_language%TYPE,
        i_id_episode IN epis_info.id_episode%TYPE,
        i_prof       IN profissional,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_exam_req_presc
    (
        i_lang            IN language.id_language%TYPE,
        i_id_episode      IN epis_info.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_clin_service IN episode.id_clinical_service%TYPE,
        i_prof            IN profissional,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * CREATE_PRESC
    *
    * @param i_lang                language id
    * @param i_prof                professional id (INTERFACE PROFESSIOAL USED FOR MIGRATION)
    * @param i_id_episode          episode identifier
    * @param i_id_patient          patient identifier
    * @param i_id_clin_service     dep_clin_serv identifier
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      Luís Maia
    * @version                     2.6.1.1
    * @since                       2011/04/20
    * @dependents                  PK_VISIT.CREATE_EXAM_REQ_PRESC
    **********************************************************************************************/
    FUNCTION create_presc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN epis_info.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_clin_service IN episode.id_clinical_service%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    --
    /**********************************************************************************************
    * Criar um episdio temporrio.
       necessrio criar uma nova visita pois no se sabe qual  o paciente. 
    *
    * @param i_lang                   the id language
    * @param i_id_professional        professional, software and institution ids
    * @param o_episode                episode temporary id
    * @param o_patient                ID do paciente temporrio
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Silvia Freitas
    * @version                        1.0 
    * @since                          2006/07/25 
    **********************************************************************************************/
    FUNCTION create_episode_temp
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN profissional,
        o_episode         OUT NUMBER,
        o_patient         OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Creates temporary patients, according to the new logic requested by the ADT/Coding team.
    *
    * @param i_lang                   Language
    * @param i_id_prof                Professional ID
    * @param i_id_institution         Institution ID
    * @param i_id_software            Software ID
    * @param i_id_patient             New patient ID
    * @param o_ora_sqlcode            Error code
    * @param o_ora_sqlerrm            Error message
    * @param o_err_desc               Error description
    * @param o_err_action             Error action (when applicable)
    *
    * @return                         New episode ID if sucessful, -1 otherwise
    *                                 (The new logic doesn't allow returning boolean values)
    *                        
    * @author                         José Brito (Based on CREATE_EPISODE_TEMP by Sílvia Freitas)
    * @version                        1.0 
    * @since                          2009/03/23 
    **********************************************************************************************/
    FUNCTION create_episode_temp
    (
        i_lang           IN language.id_language%TYPE,
        i_id_prof        IN professional.id_professional%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_ext_sys     IN external_sys.id_external_sys%TYPE DEFAULT NULL,
        i_value          IN epis_ext_sys.value%TYPE DEFAULT NULL,
        o_ora_sqlcode    OUT VARCHAR2,
        o_ora_sqlerrm    OUT VARCHAR2,
        o_err_desc       OUT VARCHAR2,
        o_err_action     OUT VARCHAR2
    ) RETURN NUMBER;

    FUNCTION delete_episode
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sched        IN schedule.id_schedule%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_professional IN profissional,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION call_delete_episode
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sched        IN schedule.id_schedule%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_professional IN profissional,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------

    FUNCTION call_create_visit
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_pat               IN patient.id_patient%TYPE,
        i_id_institution       IN institution.id_institution%TYPE,
        i_id_sched             IN epis_info.id_schedule%TYPE,
        i_id_professional      IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_external_cause       IN visit.id_external_cause%TYPE,
        i_health_plan          IN health_plan.id_health_plan%TYPE,
        i_epis_type            IN episode.id_epis_type%TYPE,
        i_dep_clin_serv        IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_origin               IN visit.id_origin%TYPE,
        i_flg_ehr              IN episode.flg_ehr%TYPE DEFAULT 'N',
        i_dt_begin             IN episode.dt_begin_tstz%TYPE DEFAULT current_timestamp,
        i_flg_appointment_type IN episode.flg_appointment_type%TYPE,
        i_transaction_id       IN VARCHAR2,
        i_ext_value            IN epis_ext_sys.value%TYPE DEFAULT NULL,
        i_flg_unknown          IN epis_info.flg_unknown%TYPE DEFAULT pk_alert_constant.g_no,
        o_episode              OUT episode.id_episode%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION call_create_visit
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_pat               IN patient.id_patient%TYPE,
        i_id_institution       IN institution.id_institution%TYPE,
        i_id_sched             IN epis_info.id_schedule%TYPE,
        i_id_professional      IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_external_cause       IN visit.id_external_cause%TYPE,
        i_health_plan          IN health_plan.id_health_plan%TYPE,
        i_epis_type            IN episode.id_epis_type%TYPE,
        i_dep_clin_serv        IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_origin               IN visit.id_origin%TYPE,
        i_flg_ehr              IN episode.flg_ehr%TYPE DEFAULT 'N',
        i_dt_begin             IN episode.dt_begin_tstz%TYPE DEFAULT current_timestamp,
        i_flg_appointment_type IN episode.flg_appointment_type%TYPE,
        i_transaction_id       IN VARCHAR2,
        i_ext_value            IN epis_ext_sys.value%TYPE DEFAULT NULL,
        i_id_prof_in_charge    IN professional.id_professional%TYPE,
        i_flg_unknown          IN epis_info.flg_unknown%TYPE DEFAULT pk_alert_constant.g_no,
        o_episode              OUT episode.id_episode%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /** Flash wrapper do not use otherwise */
    FUNCTION call_create_visit
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_pat               IN patient.id_patient%TYPE,
        i_id_institution       IN institution.id_institution%TYPE,
        i_id_sched             IN epis_info.id_schedule%TYPE,
        i_id_professional      IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_external_cause       IN visit.id_external_cause%TYPE,
        i_health_plan          IN health_plan.id_health_plan%TYPE,
        i_epis_type            IN episode.id_epis_type%TYPE,
        i_dep_clin_serv        IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_origin               IN visit.id_origin%TYPE,
        i_flg_ehr              IN episode.flg_ehr%TYPE DEFAULT 'N',
        i_dt_begin             IN episode.dt_begin_tstz%TYPE DEFAULT current_timestamp,
        i_flg_appointment_type IN episode.flg_appointment_type%TYPE,
        o_episode              OUT episode.id_episode%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------

    FUNCTION delete_episode_info
    (
        i_lang            IN language.id_language%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_sched        IN schedule.id_schedule%TYPE,
        i_id_professional IN profissional,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
    * The main purposes of this function are:
    * - to allow ALERT from getting through third-party administrative systems the cancellation of an episode;
    * - to allow cancellation of episodes through ALERT ADT;
    * - to allow cancellation of temporary episodes within ALERT EDIS, ORIS and Inpatient.
    *
    * This function is used for cancelling episodes in ALERT EDIS, ORIS, Inpatient,
    * Outpatient and Private Practice. For the last two, this function calls
    * the other instance of PK_VISIT.CANCEL_EPISODE.
    * For ALERT EDIS, ORIS and Inpatient, this function checks if it's allowed to cancel
    * episodes with registered clinical information.
    * 
    * @param i_lang            Professional preferred language
    * @param i_id_episode      Episode ID
    * @param i_prof            Professional executing the action
    * @param i_cancel_reason   Reason for cancelling this episode
    * @param i_cancel_type     'E' Cancel a registration; 'S' Cancel a scheduled episode; 
    *                          'A' Cancelled in ALERT® (ADT included); 'I' Cancelled through INTER-ALERT®;
    *                          'D' Cancelled through medical discharge cancellation.
    * @param i_dt_cancel       Cancel date
    * @param i_transaction_id  scheduler 3 transaction id needed for calls to pk_schedule_api_upstream
    * @param i_goto_sch        true = allows scheduler 3 calls; false = refuses scheduler 3 calls
    * @param o_error           Error message
    * 
    * @return                  TRUE if succeeded, FALSE otherwise
    *
    * @author                  Jos Brito
    * @version                 0.1
    * @since                   2008-Apr-14
    *
    ******************************************************************************/
    FUNCTION call_cancel_episode
    (
        i_lang           IN language.id_language%TYPE,
        i_id_episode     IN episode.id_episode%TYPE,
        i_prof           IN profissional,
        i_cancel_reason  IN episode.desc_cancel_reason%TYPE,
        i_cancel_type    IN VARCHAR2 DEFAULT 'E',
        i_dt_cancel      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        i_transaction_id IN VARCHAR2,
        i_goto_sch       IN BOOLEAN DEFAULT TRUE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /** Flash wrapper do not use otherwise */
    FUNCTION call_cancel_episode
    (
        i_lang          IN language.id_language%TYPE,
        i_id_episode    IN episode.id_episode%TYPE,
        i_prof          IN profissional,
        i_cancel_reason IN episode.desc_cancel_reason%TYPE,
        i_cancel_type   IN VARCHAR2 DEFAULT 'E',
        i_dt_cancel     IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------

    /******************************************************************************
    * For use by the Flash application layer.
    * 
    * @param i_lang            Professional preferred language
    * @param i_id_episode      Episode ID
    * @param i_prof            Professional executing the action
    * @param i_cancel_reason   Reason for cancelling this episode
    * @param o_error           Error message
    * 
    * @return                  TRUE if succeeded, FALSE otherwise
    *
    * @author                  Jos Brito
    * @version                 0.1
    * @since                   2008-Jun-03
    *
    ******************************************************************************/
    FUNCTION cancel_episode
    (
        i_lang           IN language.id_language%TYPE,
        i_id_episode     IN episode.id_episode%TYPE,
        i_prof           IN profissional,
        i_cancel_reason  IN episode.desc_cancel_reason%TYPE,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /** Flash wrapper. Do not use otherwise */
    FUNCTION cancel_episode
    (
        i_lang          IN language.id_language%TYPE,
        i_id_episode    IN episode.id_episode%TYPE,
        i_prof          IN profissional,
        i_cancel_reason IN episode.desc_cancel_reason%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------

    /******************************************************************************
    * Used by Private Practice and Outpatient.
    *
    ******************************************************************************/
    FUNCTION cancel_episode
    (
        i_lang       IN language.id_language%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_prof       IN profissional,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Cancels an ambulatory episode (OUTP, PP, CARE, NUTRI).
    *
    * @param i_lang            language identifier
    * @param i_id_episode      episode identifier
    * @param i_prof            professional identification
    * @param i_cancel_type     pk_visit.g_cancel_efectiv    - cancel patient registration (FLG_EHR = 'S')
    *                          pk_visit.g_cancel_sched_epis - cancel episode (FLG_STATUS = 'C')
    * @param i_transaction_id  scheduler 3 transaction id needed for calls to pk_schedule_api_upstream
    * @param i_goto_sch        true = allows scheduler 3 calls; false = refuses scheduler 3 calls    
    * @param o_error           error message
    *
    * @return                  false, if errors occur, or true, otherwise
    *
    * @author                  LG
    * @version                  ??
    * @since                   2006/11/09
    */
    FUNCTION cancel_outp_pp_episode
    (
        i_lang           IN language.id_language%TYPE,
        i_id_episode     IN episode.id_episode%TYPE,
        i_prof           IN profissional,
        i_cancel_reason  IN episode.desc_cancel_reason%TYPE DEFAULT NULL,
        i_cancel_type    IN VARCHAR2 DEFAULT 'E',
        i_transaction_id IN VARCHAR2,
        i_goto_sch       IN BOOLEAN DEFAULT TRUE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /** Flash wrapper do not use otherwise */
    FUNCTION cancel_outp_pp_episode
    (
        i_lang        IN language.id_language%TYPE,
        i_id_episode  IN episode.id_episode%TYPE,
        i_prof        IN profissional,
        i_cancel_type IN VARCHAR2 DEFAULT 'E',
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------

    /**********************************************************************************************
    * Registar fim de visita
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_cat_type          professional category
    * @param i_id_visit               Visit  
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         CRS
    * @version                        2.4.2
    * @since                          2008/01/25 
    * @changes                        RS -- Add prof and prof_cat
    **********************************************************************************************/

    FUNCTION set_visit_end
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_id_visit      IN visit.id_visit%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Registar fim de visita
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_cat_type          professional category
    * @param i_id_visit               Visit
    * @param i_sysdate                sysdate
    * @param i_sysdate_tstz           sysdate_tstz
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         CRS
    * @version                        2.4.2
    * @since                          2008/01/25 
    * @changes                        RS -- Add prof and prof_cat
    **********************************************************************************************/
    FUNCTION set_visit_end
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_id_visit      IN visit.id_visit%TYPE,
        i_sysdate       IN DATE,
        i_sysdate_tstz  IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Reabrir um episdio de Urgncia ou de Internamento 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_epis                episode id
    * @param i_flg_reopen             'Y' - Prentende reabrir, mas ainda no foi confirmado
                                      'N' - Confirma a reabertura do episdio 
    * @param o_flg_show               Flag: Y - existe msg para mostrar; N -  existe  
    * @param o_msg                    Mensagem a mostrar
    * @param o_msg_title              Ttulo da mensagem
    * @param o_button                 Botes a mostrar: N - no, R - lido, C - confirmado  
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2007/01/20 
    **********************************************************************************************/
    FUNCTION set_reopen_epis
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_epis    IN episode.id_episode%TYPE,
        i_flg_reopen IN VARCHAR2,
        o_flg_show   OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_button     OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_reactivate_epis
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_epis        IN episode.id_episode%TYPE,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    --
    FUNCTION set_epis_prof_rec
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_patient  IN patient.id_patient%TYPE,
        i_flg_type IN epis_prof_rec.flg_type%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    --
    -- Jos Brito 29/08/2008 Criada para evitar ROLLBACK/COMMIT na interaco com a funo de cancelamento de episdios
    FUNCTION call_set_epis_prof_rec
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_patient  IN patient.id_patient%TYPE,
        i_flg_type IN epis_prof_rec.flg_type%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Sets the professional dep_clin_serv associated with a given episode.
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_episode                    episode ID
    * @param o_error                      Error message
    *                    
    * @return                             true or false on success or error
    *
    * @author                             Jos Silva
    * @version                            1.0   
    * @since                              05-06-2008
    **********************************************************************************************/
    FUNCTION set_epis_prof_dcs
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:  Insere actualiza a data do ltimo registo que o profissional efectuou
                      no episdio
       PARAMETROS:  Entrada: I_LANG - Lngua registada como preferncia do profissional
                             I_PROF - ID do profissional, instituio e software
            I_EPISODE - Id do episdio 
         I_PATIENT - ID do paciente 
                             I_FLG_TYPE - Tipo de registo. Valores possveis: R- Registo          
           Saida: O_ERROR - Erro 
     
      CRIAO: RB 2007/02/01 
      NOTAS:  
    *********************************************************************************/
    --  
    /******************************************************************************
    * This function is for exclusive internal use by the database. It checks
    * if an episode can be cancelled:
    * 1) Registrars can cancel all types of episode within ALERT ADT.
    * 2) Physician's and nurses can only cancel TEMPORARY EPISODES of their responsability.
    * 
    * @param i_lang            Professional prefered language
    * @param i_prof            Professional information
    * @param i_episode         Episode ID
    * 
    * @return                  Y if episode can be cancelled, N otherwise
    *
    * @author                  Jos Brito
    * @version                 0.1
    * @since                   2008-04-15
    *
    ******************************************************************************/
    FUNCTION check_flg_cancel
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /*********************************************************************************************************** 
    *  Esta funo verifica se o episodio ja tem data de inicio
    *
    * @param      i_lang               Lngua registada como preferncia do profissional
    * @param      i_episode            ID do episodio
    * @param      i_prof               ID do profissional    
    * @param      i_pat                ID do paciente
    * @param      o_msg_title - Ttulo da msg a mostrar ao utilizador, caso 
    * @param      o_flg_show = Y 
    * @param      o_msg - Texto da msg a mostrar ao utilizador, caso O_FLG_SHOW = Y 
    * @param      o_button - Botes a mostrar: N - no, R - lido, C - confirmado. Tb pode mostrar combinaes destes, qd  p/ mostrar + do q 1 boto    
    * @param      o_error              mensagem de erro
    *
    * @return     se a funo termina com sucesso e FALSE caso contrrio
    * @author     Teresa Coutinho
    * @version    2.4.3.
    * @since      
    ***********************************************************************************************************/

    FUNCTION check_visit_init
    (
        i_lang       IN language.id_language%TYPE,
        i_id_episode IN epis_info.id_episode%TYPE,
        i_prof       IN profissional,
        i_pat        IN patient.id_patient%TYPE,
        o_flg_show   OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_msg_text   OUT VARCHAR2,
        o_button     OUT VARCHAR2,
        o_dt_begin   OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /*********************************************************************************************************** 
    *  Esta funo permite registar a data de inicio da consulta.
    *
    * @param      i_lang               Lngua registada como preferncia do profissional
    * @param      i_episode            ID do episodio
    * @param      i_prof               ID do profissional    
    * @param      o_error              mensagem de erro
    *
    * @return     se a funo termina com sucesso e FALSE caso contrrio
    * @author     Teresa Coutinho
    * @version    2.4.3.
    * @since      
    ***********************************************************************************************************/

    FUNCTION set_visit_init
    (
        i_lang       IN language.id_language%TYPE,
        i_id_episode IN epis_info.id_episode%TYPE,
        i_prof       IN profissional,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*********************************************************************************************************** 
    *  Esta funo retorna a data de inicio da consulta.
    *
    * @param      i_lang               Lngua registada como preferncia do profissional
    * @param      i_id_episode        ID do episodio
    * @param      i_prof               ID do profissional    
    
    * @param      o_dt_init           Data de incio
    * @param      o_exist_dt_init     Se tem preenchida a data de inicio (Y/N)
    * @param      o_error              mensagem de erro
    *
    * @return     se a funo termina com sucesso e FALSE caso contrrio
    * @author     Teresa Coutinho
    * @version    2.4.3.
    * @since      
    ***********************************************************************************************************/

    FUNCTION get_visit_init
    (
        i_lang             IN language.id_language%TYPE,
        i_id_episode       IN epis_info.id_episode%TYPE,
        i_prof             IN profissional,
        o_dt_init          OUT VARCHAR2,
        o_exist_dt_init    OUT VARCHAR2,
        o_dt_begin         OUT VARCHAR2,
        o_dt_first_obs     OUT epis_info.dt_first_obs_tstz%TYPE,
        o_dt_first_nur_obs OUT epis_info.dt_first_nurse_obs_tstz%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * This functiom creates an definitive episode+visit for the specified patient.
    * If the patient is omitted a new patient is created.
    * If the patient already has active episodes the user will receive a warning/error
    *
    * @param i_lang            ui language
    * @param i_prof            user object
    * @param i_patient         patient id. If null, a new patient
    * @param i_test            test only if episode can be created, don't commit data
    * @oaran i_num_health_plan public health plan number
    * @param o_flg_show        tell wether the error message must be shown or not
    * @param o_button          buttons to show
    * @param o_msg_title       message title
    * @param o_msg             message
    * @param o_new_episode     new episode id
    * @param o_new_patient     new patient id
    * @param o_error           error message
    *
    * @return                  TRUE if sucessfull, FALSE otherwise
    *                        
    * @author                  Joo Eiras
    * @version                 1.0 
    * @since                   2008/04/30
    **********************************************************************************************/
    FUNCTION create_quick_episode
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_test    IN VARCHAR2,
        
        i_keys           IN table_varchar,
        i_values         IN table_varchar,
        i_transaction_id IN VARCHAR2,
        
        o_flg_show   OUT VARCHAR2,
        o_button     OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_can_create OUT VARCHAR2,
        
        o_new_episode OUT episode.id_episode%TYPE,
        o_new_patient OUT patient.id_patient%TYPE,
        
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /** Flash wrapper do not use otherwise */
    FUNCTION create_quick_episode
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_test    IN VARCHAR2,
        
        i_keys   IN table_varchar,
        i_values IN table_varchar,
        
        o_flg_show   OUT VARCHAR2,
        o_button     OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_can_create OUT VARCHAR2,
        
        o_new_episode OUT episode.id_episode%TYPE,
        o_new_patient OUT patient.id_patient%TYPE,
        
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------

    /*********************************************************************************************************** 
    *  Esta funo retorna a USF e a equipa do profissional
    *
    * @param      i_lang               Lngua registada como preferncia do profissional
    * @param      i_prof               ID do profissional    
    
    * @param      o_usf           id usf
    * @param      o_prof_team     id da equipa
    * @param      o_error              mensagem de erro
    *
    * @return     se a funo termina com sucesso e FALSE caso contrrio
    * @author     Teresa Coutinho
    * @version    2.4.3.
    * @since      
    ***********************************************************************************************************/

    FUNCTION get_usf_prof_team
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_usf       OUT VARCHAR2,
        o_prof_team OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_contact_reg_data
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        o_contact_data  OUT pk_types.cursor_type,
        o_clin_services OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_contact_reg_data
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN patient.id_patient%TYPE,
        i_episode             IN episode.id_episode%TYPE,
        i_dt_begin            IN VARCHAR2,
        i_flg_enc_type        IN sch_group.flg_contact_type%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_flg_request_type    IN schedule.flg_request_type%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_contact_permission_data
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        o_permission OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Checks if an episode type is of Ambulatory products
    * (OUTP, PP, CARE, NUTRI, SOCIAL).
    *
    * @param i_epis_type       episode type identifier
    *
    * @return                  true, if the episode type is of Ambulatory products,
    *                          or false, otherwise.
    *
    * @author                  Pedro Carneiro
    * @version                  2.5.0.7.6.1
    * @since                   2010/02/12
    */
    FUNCTION check_epis_type_amb(i_epis_type IN episode.id_epis_type%TYPE) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * INS_VISIT                       Create an visit for an patient with send parameters and returns id_visit created
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_ID_PATIENT             PATIENT identifier that should be associated with new visit
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EXTERNAL_CAUSE         EXTERNAL_CAUSE identifier that should be associated with new visit
    * @param I_DT_BEGIN               Date begin for current visit
    * @param I_DT_CREATION            Date creation of current visit
    * @param I_ID_ORIGIN              Origin identifier
    * @param I_FLG_MIGRATION          Shows type of visit ('A' for ALERT visits, 'M' for migrated records, 'T' for test records)
    * @param O_ID_VISIT               VISIT identifier corresponding to created visit
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    *
    * @return                         Returns TRUE if success, otherwise returns FALSE
    *
    * @value  I_FLG_MIGRATION         {*} 'A'- ALERT visits {*} 'M'- Migrated records {*} 'T'- Test records 
    *
    * @raises                         PL/SQL generic erro "OTHERS"
    *
    * @author                         Luís Maia
    * @version                        2.6.0.3
    * @since                          2010/May/25
    *
    *******************************************************************************************************************************************/
    FUNCTION ins_visit
    (
        i_lang           IN language.id_language%TYPE,
        i_id_patient     IN patient.id_patient%TYPE,
        i_prof           IN profissional,
        i_external_cause IN visit.id_external_cause%TYPE,
        i_dt_begin       IN visit.dt_begin_tstz%TYPE,
        i_dt_creation    IN visit.dt_begin_tstz%TYPE,
        i_id_origin      IN visit.id_origin%TYPE,
        i_flg_migration  IN visit.flg_migration%TYPE,
        i_inst_dest      IN institution.id_institution%TYPE DEFAULT NULL,
        i_order_set      IN VARCHAR2 DEFAULT 'N',
        o_id_visit       OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Check if professional category can update EPIS_INFO.DT_FIRST_OBS_TSTZ value.
    *
    * @param i_lang                 Language ID
    * @param i_prof_cat             Professional category
    *
    * @return                         YES/NO
    *
    * @author                         José Brito
    * @version                        2.5.1
    * @since                          2011/05/16
    **********************************************************************************************/
    FUNCTION check_first_obs_category
    (
        i_lang     IN language.id_language%TYPE,
        i_prof_cat IN category.flg_type%TYPE
    ) RETURN VARCHAR2;

    FUNCTION check_first_obs_category
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_prof_cat IN category.flg_type%TYPE
    ) RETURN VARCHAR2;

    /*
    * Get episode type by schedule.
    *
    * @param i_schedule     schedule identifier
    *
    * @return               episode type identifier
    *
    * @author               Pedro Carneiro
    * @version               2.5.1.7
    * @since                2010/09/09
    */
    FUNCTION get_epis_type(i_schedule IN schedule.id_schedule%TYPE) RETURN epis_type.id_epis_type%TYPE;
    --
    --
    FUNCTION check_first_obs
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN epis_info.id_episode%TYPE,
        i_id_schedule IN epis_info.id_schedule%TYPE
    ) RETURN VARCHAR2;

    FUNCTION check_first_obs_group
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_group IN schedule.id_group%TYPE
    ) RETURN VARCHAR2;

    FUNCTION set_dt_last_interaction
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_visit_init
    (
        i_lang       IN language.id_language%TYPE,
        i_id_episode IN epis_info.id_episode%TYPE,
        i_prof       IN profissional,
        i_dt_init    IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
	
    /**######################################################
      GLOBAIS
    ######################################################**/
    g_package_owner VARCHAR2(0050);
    g_package_name  VARCHAR2(0050);

    g_active CONSTANT VARCHAR2(1) := 'A';
    g_visit_active   visit.flg_status%TYPE;
    g_epis_active    episode.flg_status%TYPE;
    g_visit_inactive visit.flg_status%TYPE;
    g_epis_inactive  episode.flg_status%TYPE;
    g_epis_pend      episode.flg_status%TYPE;
    g_epis_cancel    episode.flg_status%TYPE;
    g_error          VARCHAR2(4000); -- Localizao do erro 
    g_sysdate_tstz   TIMESTAMP WITH LOCAL TIME ZONE;

    g_epis_info_efectiv     epis_info.flg_status%TYPE;
    g_epis_info_wait        epis_info.flg_status%TYPE;
    g_epis_info_first_nurse epis_info.flg_status%TYPE;
    g_epis_info_doctor      epis_info.flg_status%TYPE;
    g_epis_info_last_nurse  epis_info.flg_status%TYPE;
    g_epis_info_clin_disch  epis_info.flg_status%TYPE;
    g_epis_info_adm_disch   epis_info.flg_status%TYPE;

    g_sched_first_nurse schedule_outp.flg_state%TYPE;
    g_sched_doctor      schedule_outp.flg_state%TYPE;
    g_sched_efectiv     schedule_outp.flg_state%TYPE;
    g_sched_scheduled   schedule_outp.flg_state%TYPE;
    g_sched_nurse_prev  schedule_outp.flg_state%TYPE;
    g_sched_nurse       schedule_outp.flg_state%TYPE;
    g_sched_nurse_end   schedule_outp.flg_state%TYPE;
    g_sched_doctor_disch CONSTANT schedule_outp.flg_state%TYPE := 'D';
    g_sched_nutri_disch  CONSTANT schedule_outp.flg_state%TYPE := 'U';

    g_sched_cancel schedule.flg_status%TYPE;

    g_sched_sess schedule_intervention.flg_state%TYPE;

    g_cat_type_doc    category.flg_type%TYPE;
    g_cat_type_nurse  category.flg_type%TYPE;
    g_cat_type_reg    category.flg_type%TYPE;
    g_cat_type_fisio  category.flg_type%TYPE;
    g_cat_type_triage category.flg_type%TYPE;
    g_cat_type_nutri  category.flg_type%TYPE;

    g_flg_status_a VARCHAR2(1);
    g_flg_status_c VARCHAR2(1);
    g_flg_status_f VARCHAR2(1);
    g_flg_status_x VARCHAR2(1);
    g_flg_status_d VARCHAR2(1);
    g_flg_status_r VARCHAR2(1);
    g_flg_status_i VARCHAR2(1);

    g_found BOOLEAN;

    g_software_consh  NUMBER;
    g_software_conscs NUMBER;
    g_room_pref       prof_room.flg_pref%TYPE;

    g_flg_sos  VARCHAR2(1);
    g_flg_cont VARCHAR2(1);

    g_unknown        VARCHAR2(1);
    g_definitive     VARCHAR2(1);
    g_patient_active VARCHAR2(1);
    g_category_avail category.flg_available%TYPE;
    g_cat_prof       category.flg_prof%TYPE;
    g_flg_type_d     category.flg_type%TYPE;
    g_flg_type_n     category.flg_type%TYPE;

    g_domain_epis_info_flg_status VARCHAR2(25);
    g_domain_episode_flg_status   VARCHAR2(25);

    g_selected  VARCHAR2(1);
    g_epis_type episode.id_epis_type%TYPE;

    --
    g_func_reopen          sys_config.value%TYPE;
    g_epis_type_edis       epis_type.id_epis_type%TYPE;
    g_epis_type_inp        epis_type.id_epis_type%TYPE;
    g_epis_type_ubu        epis_type.id_epis_type%TYPE;
    g_epis_type_outp       epis_type.id_epis_type%TYPE;
    g_epis_type_pp         epis_type.id_epis_type%TYPE;
    g_epis_type_oris       epis_type.id_epis_type%TYPE;
    g_epis_type_nurse      epis_type.id_epis_type%TYPE;
    g_epis_type_nurse_outp epis_type.id_epis_type%TYPE;
    g_epis_type_nurse_pp   epis_type.id_epis_type%TYPE;
    g_epis_type_nutri      epis_type.id_epis_type%TYPE := 18;
    g_epis_type_care CONSTANT epis_type.id_epis_type%TYPE := pk_alert_constant.g_epis_type_primary_care;

    g_disch_reopen discharge.flg_status%TYPE;
    --lg 2007-03-02
    g_disch_active discharge.flg_status%TYPE;
    g_reopen       VARCHAR2(1);

    g_flg_type_rec epis_prof_rec.flg_type%TYPE := 'R';
    g_flg_default  dep_clin_serv.flg_default%TYPE;
    g_yes          VARCHAR2(1);
    g_no           VARCHAR2(1);

    g_between     exam_req.flg_time%TYPE;
    l_co_sign     co_sign_obj := co_sign_obj(NULL, NULL, NULL, NULL, NULL, NULL, NULL);
    g_flg_co_sign VARCHAR2(1);

    g_flg_type_s    schedule_outp.flg_type%TYPE;
    g_flg_type_p    schedule_outp.flg_type%TYPE;
    g_consultsubs_y schedule_outp.flg_sched%TYPE;
    g_consultsubs_n schedule_outp.flg_sched%TYPE;

    g_complaint epis_anamnesis.flg_type%TYPE;
    g_activo    epis_anamnesis.flg_status%TYPE;

    g_exam_type_req         ti_log.flg_type%TYPE;
    g_exam_type_det         ti_log.flg_type%TYPE;
    g_analysis_type_req     ti_log.flg_type%TYPE;
    g_analysis_type_req_det ti_log.flg_type%TYPE;
    g_analysis_type_harv    ti_log.flg_type%TYPE;

    g_flg_time_e interv_prescription.flg_time%TYPE;
    g_flg_time_n interv_prescription.flg_time%TYPE;
    g_flg_time_b interv_prescription.flg_time%TYPE;

    g_flg_time_betw    interv_prescription.flg_time%TYPE;
    g_flg_time_epis    interv_prescription.flg_time%TYPE;
    g_interv_det_req   interv_presc_det.flg_status%TYPE;
    g_interv_det_exec  interv_presc_det.flg_status%TYPE;
    g_interv_det_pend  interv_presc_det.flg_status%TYPE;
    g_interv_plan_req  interv_presc_plan.flg_status%TYPE;
    g_interv_plan_pend interv_presc_plan.flg_status%TYPE;

    g_flg_type_appointment_type CONSTANT doc_area_inst_soft.flg_type%TYPE := 'A';
    g_flg_template_type         CONSTANT doc_template_context.flg_type%TYPE := 'S';

    g_epis_type_session epis_type.id_epis_type%TYPE;

    g_flg_ehr_n CONSTANT episode.flg_ehr%TYPE := 'N';
    g_flg_ehr_s CONSTANT episode.flg_ehr%TYPE := 'S';
    g_flg_ehr_e CONSTANT episode.flg_ehr%TYPE := 'E';

    g_inp_definitive VARCHAR2(1);
    g_inp_temporary  VARCHAR2(1);

    g_profile_type_intern VARCHAR2(1);

    g_soft_triage CONSTANT software.id_software%TYPE := 35;
    g_soft_edis   CONSTANT software.id_software%TYPE := 8;

    g_referral_status_scheduled CONSTANT p1_external_request.flg_type%TYPE := 'S';
    g_referral_status_mailed    CONSTANT p1_external_request.flg_type%TYPE := 'M';
    g_referral_status_executed  CONSTANT p1_external_request.flg_type%TYPE := 'E';

    g_software_outp CONSTANT software.id_software%TYPE := 1;
    g_software_care CONSTANT software.id_software%TYPE := 3;
    -- Jos Brito 29/08/2008 Corrigido o valor da varivel global do Private Practice
    g_software_pp CONSTANT software.id_software%TYPE := 12;

    g_cancel_efectiv    CONSTANT VARCHAR2(1) := 'E';
    g_cancel_sched_epis CONSTANT VARCHAR2(1) := 'S';

    g_epis_flg_type_d CONSTANT VARCHAR2(1) := 'D';
    g_epis_flg_type_t CONSTANT VARCHAR2(1) := 'T';

    g_wr_available sys_config.id_sys_config%TYPE;

    g_flg_available VARCHAR2(1) := 'Y';
    g_flg_nurse_pre_y CONSTANT VARCHAR2(1) := 'Y';

    g_epis_flg_appointment_type CONSTANT sys_domain.code_domain%TYPE := 'EPISODE.FLG_APPOINTMENT_TYPE';
    g_sched_flg_req_type        CONSTANT sys_domain.code_domain%TYPE := 'SCHEDULE.FLG_REQUEST_TYPE';
    g_flg_request_type_patient  CONSTANT schedule.flg_request_type%TYPE := 'U';
    g_null_appointment_type     CONSTANT episode.flg_appointment_type%TYPE := 'N';

    g_ret BOOLEAN;

END;
/
