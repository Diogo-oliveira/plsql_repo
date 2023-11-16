/*-- Last Change Revision: $Rev: 2028924 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:46 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE pk_rehab_ux IS

    FUNCTION get_rehab_interv_all
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_rehab_area          IN rehab_area.id_rehab_area%TYPE,
        i_intervention_parent IN intervention.id_intervention_parent%TYPE,
        i_id_codification     IN interv_codification.id_codification%TYPE,
        o_areas               OUT pk_types.cursor_type,
        o_list                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_rehab_interv_list
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_rehab_area          IN rehab_area.id_rehab_area%TYPE,
        i_intervention_parent IN intervention.id_intervention_parent%TYPE,
        i_id_codification     IN interv_codification.id_codification%TYPE,
        o_areas               OUT pk_types.cursor_type,
        o_list                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_rehab_interv_search
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_keyword         IN VARCHAR2,
        i_id_codification IN interv_codification.id_codification%TYPE DEFAULT NULL,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_rehab_area_prof
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        o_areas          OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_rehab_area_prof
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_institution IN table_number,
        i_rehab_area  IN table_table_number,
        i_test        IN VARCHAR2,
        o_flg_show    OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_msg_result  OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_rehab_group
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_short_name     IN VARCHAR2,
        i_description    IN VARCHAR2,
        i_flg_status     IN VARCHAR2,
        i_id_rehab_area  IN NUMBER,
        o_id_rehab_group OUT rehab_group.id_rehab_group%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_rehab_groups
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_groups OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_rehab_group
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_rehab_group IN rehab_group.id_rehab_group%TYPE,
        i_short_name     IN VARCHAR2,
        i_description    IN VARCHAR2,
        i_flg_status     IN VARCHAR2,
        i_id_rehab_area  IN NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_rehab_groups_prof
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_groups OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_rehab_groups_prof
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_groups IN table_number,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /*
        FUNCTION get_rehab_sch_existing
        (
            i_lang       IN language.id_language%TYPE,
            i_prof       IN profissional,
            i_id_episode IN episode.id_episode%TYPE,
            o_sch_needs  OUT pk_types.cursor_type,
            o_error      OUT t_error_out
        ) RETURN BOOLEAN;
    */

    FUNCTION get_rehab_treatment_plan
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN rehab_plan.id_patient%TYPE,
        i_id_episode        IN rehab_plan.id_episode_origin%TYPE,
        o_id_episode_origin OUT rehab_plan.id_episode_origin%TYPE,
        o_sch_need          OUT pk_types.cursor_type,
        o_treat             OUT pk_types.cursor_type,
        o_notes             OUT pk_types.cursor_type,
        o_labels            OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_rehab_instructions_cfg
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_label     OUT pk_types.cursor_type,
        o_frequency OUT pk_types.cursor_type,
        o_priority  OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pending_sch_needs
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode_origin  IN rehab_sch_need.id_episode_origin%TYPE,
        o_needs_instructions OUT VARCHAR2,
        o_list               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pending_sch_needs_grid
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_rehab_presc
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_patient           IN rehab_plan.id_patient%TYPE,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_rehab_area_interv IN table_number,
        i_id_rehab_sch_need    IN table_number,
        i_id_exec_institution  IN table_number,
        i_exec_per_session     IN table_number,
        i_presc_notes          IN table_varchar,
        i_sessions             IN table_number,
        i_frequency            IN table_number,
        i_flg_frequency        IN table_varchar,
        i_flg_priority         IN table_varchar,
        i_date_begin           IN table_varchar,
        i_session_notes        IN table_varchar,
        i_session_type         IN table_varchar,
        i_id_codification      IN table_number,
        i_flg_laterality       IN table_varchar,
        i_id_not_order_reason  IN table_number,
        o_id_rehab_presc       OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_rehab_presc
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN nurse_tea_req.id_episode%TYPE,
        i_id_patient           IN patient.id_patient%TYPE,
        i_root_name            IN VARCHAR2,
        i_tbl_records          IN table_number,
        i_tbl_ds_internal_name IN table_varchar,
        i_tbl_real_val         IN table_table_varchar,        
        i_tbl_val_mea          IN table_table_varchar,
        i_tbl_val_clob         IN table_table_clob DEFAULT NULL,
        i_tbl_val_array        IN tt_table_varchar DEFAULT NULL,
        i_tbl_val_array_desc   IN tt_table_varchar DEFAULT NULL,
        i_codification         IN rehab_presc.id_codification%TYPE,
        i_flg_action           IN VARCHAR2,
        i_clinical_question_pk IN table_number,
        i_clinical_question    IN table_varchar,
        i_response             IN table_table_varchar,
        o_id_rehab_presc       OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_rehab_schedule
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_rehab_schedule IN rehab_schedule.id_rehab_schedule%TYPE,
        i_id_cancel_reason  IN rehab_schedule.id_cancel_reason%TYPE,
        i_notes             IN rehab_schedule.notes%TYPE DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION missed_rehab_schedule
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_rehab_schedule IN rehab_schedule.id_rehab_schedule%TYPE,
        i_id_missed_reason  IN rehab_schedule.flg_status%TYPE,
        i_notes             IN rehab_schedule.notes%TYPE DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_treatment_plan_notes
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN rehab_notes.id_episode%TYPE,
        i_id_patient IN rehab_plan.id_patient%TYPE,
        i_notes      IN rehab_notes.notes%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_rehab_session
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_patient            IN rehab_plan.id_patient%TYPE,
        i_id_rehab_presc        IN table_number,
        i_id_episode            IN rehab_session.id_episode%TYPE,
        i_id_rehab_area_interv  IN table_number,
        i_id_rehab_session_type IN table_varchar,
        i_id_exec_prof          IN rehab_session.id_professional%TYPE,
        i_dt_begin              IN VARCHAR2,
        i_dt_end                IN VARCHAR2,
        i_duration              IN NUMBER,
        i_notes                 IN VARCHAR2,
        o_id_rehab_session      OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Edits the execution data of treatment sessions
    *
    * @param   i_lang              Professional preferred language
    * @param   i_prof              Professional identification and its context (institution and software)
    * @param   i_id_rehab_session  List of executions to edit        
    * @param   i_id_episode        Episode ID
    * @param   i_id_exec_prof      Profissional ID who execute the session
    * @param   i_dt_begin          Begin date
    * @param   i_dt_end            End dete
    * @param   i_duration          Elapsed time
    * @param   i_notes             Notes
    *
    * @param   o_error             Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   26-Jul-10
    */
    FUNCTION set_rehab_session
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_rehab_session IN table_number,
        i_id_episode       IN rehab_session.id_episode%TYPE,
        i_id_exec_prof     IN rehab_session.id_professional%TYPE,
        i_dt_begin         IN VARCHAR2,
        i_dt_end           IN VARCHAR2,
        i_duration         IN NUMBER,
        i_notes            IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the detail of executions in a treatment session
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_id_rehab_presc     Prescribed treatment ID
    * @param   o_rehab_session_rec  Cursor with record info
    * @param   o_rehab_session_val  Cursor with session's executions info
    *
    * @param   o_error              Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   27-Jul-10
    */
    FUNCTION get_rehab_session_detail
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_rehab_presc       IN rehab_session.id_rehab_presc%TYPE,
        o_rehab_session_detail OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_rehab_session
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_rehab_session IN table_number,
        i_id_cancel_reason IN rehab_session.id_cancel_reason%TYPE,
        i_notes            IN rehab_session.notes_cancel%TYPE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_rehab_presc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_rehab_presc   IN table_number,
        i_id_cancel_reason IN rehab_presc.id_cancel_reason%TYPE,
        i_notes            IN rehab_presc.notes_cancel%TYPE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_rehab_sch_need
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_rehab_sch_need IN rehab_sch_need.id_rehab_sch_need%TYPE,
        i_id_cancel_reason  IN rehab_sch_need.id_cancel_reason%TYPE,
        i_notes             IN rehab_sch_need.notes_cancel%TYPE DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    -- retorna todos os tratamentos de uma necessidade de agendamento
    FUNCTION get_rehab_sch_need_treats
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN rehab_sch_need.id_episode_origin%TYPE,
        i_id_schedule IN rehab_schedule.id_schedule %TYPE,
        o_session     OUT pk_types.cursor_type,
        o_treats      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_dt_init
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_dt_init OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    -- retorna todas as execuções de uma necessidade de agendamento
    FUNCTION get_rehab_sch_need_exec
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_rehab_sch_need IN rehab_sch_need.id_rehab_sch_need%TYPE,
        o_executions        OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    -- retorna todas as execuções de uma lista de requisições
    FUNCTION get_rehab_presc_exec
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_rehab_presc IN table_number,
        o_executions     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    --
    FUNCTION update_rehab_presc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_rehab_presc      IN rehab_presc.id_rehab_presc%TYPE,
        i_id_rehab_sch_need   IN rehab_presc.id_rehab_sch_need%TYPE,
        i_id_exec_institution IN rehab_presc.id_exec_institution%TYPE,
        i_exec_per_session    IN rehab_presc.exec_per_session%TYPE,
        i_notes               IN rehab_presc.notes%TYPE,
        i_flg_laterality      IN rehab_presc.flg_laterality%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    -- get list of professionals and groups allocated to the areas
    FUNCTION get_prof_group_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_rehab_area IN table_number,
        o_prof_list     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    -- get list of professionals allocated to the areas
    FUNCTION get_prof_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_rehab_area IN table_number,
        o_prof_list     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    -- get list of time units hora(s), minuto(s)
    FUNCTION get_time_units
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_units OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_patients_grid
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_all_patients IN VARCHAR2,
        o_flg_show     OUT VARCHAR2,
        o_msg          OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_button       OUT VARCHAR2,
        o_patients     OUT pk_types.cursor_type,
        o_error        OUT t_error_out
        
    ) RETURN BOOLEAN;

    -- aloca um profissional ou um grupo a uma necessidade de agendamento
    FUNCTION set_alloc_prof_sch_need
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_rehab_sch_need IN rehab_sch_need.id_rehab_sch_need%TYPE,
        i_id_resp           IN NUMBER,
        i_type              IN VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_origin_episode
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_id_schedule       IN epis_info.id_schedule%TYPE,
        o_id_episode_origin OUT rehab_plan.id_episode_origin%TYPE,
        o_id_schedule       OUT rehab_schedule.id_schedule%TYPE,
        o_id_epis_type      OUT episode.id_epis_type%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the detail for the Rehabilitation treatments
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_rehab_presc         Rehabilitaion prescription ID
    * @param o_rehab_treatment        Treatments details
    * @param o_rehab_treatment_prof   Professional details
    * @param o_rehab_session_detail
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/07/
    **********************************************************************************************/
    FUNCTION get_rehab_treatment_detail
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_rehab_presc       IN rehab_presc.id_rehab_presc%TYPE,
        o_rehab_treatment      OUT pk_types.cursor_type,
        o_rehab_treatment_prof OUT pk_types.cursor_type,
        o_rehab_session_detail OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the detail for the Rehabilitation sessions
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_rehab_sch_need      Rehabilitaion session ID
    * @param o_rehab_treatment        Treatments details
    * @param o_rehab_treatment_prof   Professional details
    
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/07/
    **********************************************************************************************/
    FUNCTION get_rehab_sch_need_detail
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_sch_need  IN rehab_sch_need.id_rehab_sch_need%TYPE,
        o_rehab_session      OUT pk_types.cursor_type,
        o_rehab_session_prof OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_treatments_edit
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_rehab_presc  IN rehab_presc.id_rehab_presc%TYPE,
        o_rehab_treatment OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_rehab_presc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN rehab_plan.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        --
        i_id_rehab_presc       IN rehab_presc.id_rehab_presc%TYPE,
        i_id_rehab_area_interv IN rehab_presc.id_rehab_area_interv%TYPE,
        i_id_rehab_sch_need    IN rehab_sch_need.id_rehab_sch_need%TYPE,
        i_id_exec_institution  IN rehab_presc.id_exec_institution%TYPE,
        i_exec_per_session     IN rehab_presc.exec_per_session%TYPE,
        i_presc_notes          IN rehab_presc.notes%TYPE,
        i_sessions             IN rehab_sch_need.sessions%TYPE,
        i_frequency            IN rehab_sch_need.frequency%TYPE,
        i_flg_frequency        IN rehab_sch_need.flg_frequency%TYPE,
        i_flg_priority         IN rehab_sch_need.flg_priority%TYPE,
        i_date_begin           IN VARCHAR2,
        i_session_notes        IN rehab_sch_need.notes%TYPE,
        i_session_type         IN rehab_sch_need.id_rehab_session_type%TYPE,
        i_flg_laterality       IN rehab_presc.flg_laterality%TYPE,
        i_id_not_order_reason  IN rehab_presc.id_not_order_reason%TYPE,
        --
        o_id_rehab_presc OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Creates rehabilitation diagnosis associated to the patient episode      *
    *                                                                         *
    * @param i_lang                   language id                             *
    * @param i_prof                   professional, software and              *
    *                                 institution ids                         *
    * @param i_episode                Episode id                              *
    * @param i_patient                Patient id                              *
    * @param i_icf                    List of ID of ICF component             *
    * @param i_iq_initial_incapacity  List of ID of the qualifier for initial *
    *                                 incapacity                              *
    * @param i_iqs_initial_incapacity List of ID of qualification scale for   *
    *                                 initial incapacity                      *
    * @param i_iq_expected_result     List of ID of the qualifier for expected*
    *                                 result                                  *
    * @param i_iqs_expected_result    List of ID of qualification scale for   *
    *                                 expected result                         *
    * @param i_iq_active_incapacity   List of ID of the qualifier for active  *
    *                                 incapacity                              *
    * @param i_iqs_active_incapacity  List of ID of qualification scale for   *
    *                                 active incapacity                       *       
    *                                                                         *
    * @param o_error                  Error message                           *
    * @param o_id_rehab_diagnosis     List of generated rehab diagnosis       *
    *                                 requests                                *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2010/07/16                              *
    **************************************************************************/
    FUNCTION create_rehab_diag
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_patient                IN patient.id_patient%TYPE,
        i_icf                    IN table_number,
        i_iq_initial_incapacity  IN table_number,
        i_iqs_initial_incapacity IN table_number,
        i_iq_expected_result     IN table_number,
        i_iqs_expected_result    IN table_number,
        i_iq_active_incapacity   IN table_number,
        i_iqs_active_incapacity  IN table_number,
        i_notes                  IN table_varchar,
        o_id_rehab_diagnosis     OUT table_number,
        o_flg_show               OUT VARCHAR2,
        o_msg                    OUT VARCHAR2,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Edits rehabilitation diagnosis data associated to the patient episode   *
    *                                                                         *
    * @param i_lang                   language id                             *
    * @param i_prof                   professional, software and              *
    *                                 institution ids                         *
    * @param i_id_rehab_diagnosis     list of rehab dianossis identifiers to  *
    *                                 cancel                                  *
    * @param i_episode                Episode id                              *
    * @param i_icf                    List of ID of ICF component             *
    * @param i_iq_initial_incapacity  List of ID of the qualifier for initial *
    *                                 incapacity                              *
    * @param i_iqs_initial_incapacity List of ID of qualification scale for   *
    *                                 initial incapacity                      *
    * @param i_iq_expected_result     List of ID of the qualifier for expected*
    *                                 result                                  *
    * @param i_iqs_expected_result    List of ID of qualification scale for   *
    *                                 expected result                         *
    * @param i_iq_active_incapacity   List of ID of the qualifier for active  *
    *                                 incapacity                              *
    * @param i_iqs_active_incapacity  List of ID of qualification scale for   *
    *                                 active incapacity                       *       
    *                                                                         *
    * @param o_error                  Error message                           *
    * @param o_id_rehab_diagnosis     List of generated rehab diagnosis       *
    *                                 requests                                *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2010/07/16                              *
    **************************************************************************/
    FUNCTION set_rehab_diag
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_rehab_diagnosis     IN table_number,
        i_episode                IN episode.id_episode%TYPE,
        i_icf                    IN table_number,
        i_iq_initial_incapacity  IN table_number,
        i_iqs_initial_incapacity IN table_number,
        i_iq_expected_result     IN table_number,
        i_iqs_expected_result    IN table_number,
        i_iq_active_incapacity   IN table_number,
        i_iqs_active_incapacity  IN table_number,
        i_status                 IN table_varchar,
        i_notes                  IN table_varchar,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Cancels rehabilitation diagnosis data associated to the patient episode *
    *                                                                         *
    * @param i_lang                   language id                             *
    * @param i_prof                   professional, software and              *
    *                                 institution ids                         *
    * @param i_id_rehab_diagnosis     list of rehab dianossis identifiers to  *
    *                                 cancel                                  *
    * @param i_episode                Episode id                              *
    * @param i_id_cancel_reason       Cancel reason id                        *
    * @param i_cancel_notes           Cancel notes                            *
    *                                                                         *
    * @param o_error                  Error message                           *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2010/07/21                              *
    **************************************************************************/
    FUNCTION cancel_rehab_diag
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_diagnosis IN table_number,
        i_episode            IN episode.id_episode%TYPE,
        i_id_cancel_reason   IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes       IN rehab_diagnosis.notes_cancel%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Cancels rehabilitation diagnosis data associated to the patient episode *
    *                                                                         *
    * @param i_lang                   language id                             *
    * @param i_prof                   professional, software and              *
    *                                 institution ids                         *
    * @param i_id_rehab_diagnosis     list of rehab diagnosis identifiers to  *
    *                                 cancel                                  *
    * @param i_episode                Episode id                              *
    *                                                                         *
    * @param o_error                  Error message                           *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2010/07/21                              *
    **************************************************************************/
    FUNCTION get_rehab_diag_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        o_rehab_diag OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Returns information to put in the Rehab Diagnosis Detail screen         *
    *                                                                         *
    * @param i_lang                   language id                             *
    * @param i_prof                   professional, software and              *
    *                                 institution ids                         *
    * @param i_rehab_diagnosis        Rehab diagnosis Id                      *
    *                                                                         *
    * @param o_error                  Error message                           *
    * @param o_rehab_diag_detail      Cursor with rehab diagnosis detail info *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2010/07/22                              *
    **************************************************************************/
    FUNCTION get_rehab_diag_detail
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_rehab_diagnosis   IN rehab_diagnosis.id_rehab_diagnosis%TYPE,
        o_rehab_diag_detail OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Returns Rehab Diagnosis actions list                                    *
    *                                                                         *
    * @param i_lang                   language id                             *
    * @param i_prof                   professional, software and              *
    *                                 institution ids                         *
    *                                                                         *
    * @param o_error                  Error message                           *
    * @param o_rehab_diag_actions     Cursor with rehab diagnosis actions     *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2010/07/26                              *
    **************************************************************************/
    FUNCTION get_rehab_diag_actions
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        o_rehab_diag_actions OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * retorna os pacientes com tratamentos para hoje
    *
    * %param i_lang                   id_language
    * %param i_prof                   id_professional
    * %param i_type                   A-appointments S-Scheduled else NonScheduled
    * %param i_status                 from state
    * %param o_status                 List of to states
    * %param o_error                  error message
    *
    * @return                         TRUE on success, FALSE otherwise
    *
    * @author                         Eduardo Reis
    * @version                        1.0
    * @since                          2010-08-21
    **********************************************************************************************/
    FUNCTION get_grid_workflow_status
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_type   IN VARCHAR2,
        i_status IN VARCHAR2,
        o_status OUT pk_types.cursor_type,
        o_error  OUT t_error_out
        
    ) RETURN BOOLEAN;

    -- This function can be used to edit a given treatment
    FUNCTION set_rehab_workflow_change
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN rehab_plan.id_patient%TYPE,
        --
        i_workflow_type  IN VARCHAR2,
        i_from_state     IN VARCHAR2,
        i_to_state       IN VARCHAR2,
        i_id_rehab_grid  IN NUMBER,
        i_id_rehab_presc IN rehab_sch_need.id_rehab_sch_need%TYPE,
        --create_visit
        i_id_epis_origin    IN episode.id_episode%TYPE,
        i_id_rehab_schedule IN rehab_schedule.id_rehab_schedule%TYPE,
        i_id_schedule       IN schedule.id_schedule%TYPE,
        --
        i_id_cancel_reason IN rehab_schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN rehab_schedule.notes%TYPE DEFAULT NULL,
        i_lock_uq_value    IN NUMBER,
        i_lock_func        IN VARCHAR2,
        i_id_lock          IN NUMBER,
        --
        o_id_episode OUT episode.id_episode%TYPE,
        o_lock       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_rehab_icf_list
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_id_icf                     IN icf_qualification_rel.id_icf%TYPE,
        i_id_icf_qualification_scale IN icf_qualification_rel.id_icf_qualification_scale%TYPE,
        i_flg_level                  IN icf_qualification_rel.flg_level%TYPE,
        o_qualif                     OUT pk_types.cursor_type,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_rsn_flg_status
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_rehab_schedule_need IN rehab_sch_need.id_rehab_sch_need%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_rehab_presc_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_rehab_presc IN table_number, --ARRAY
        i_to_state       IN action.to_state%TYPE,
        i_notes          IN rehab_presc.notes%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    -- pesquisa de pacientes
    FUNCTION get_patients_mfr
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_crit   IN table_number,
        i_crit_cond IN table_varchar,
        i_flg_state IN VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_pat       OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Accepts a rehab_presc proposal of suspension, discontinuation or edition
    *
    * %param i_lang                   id_language
    * %param i_prof                   id_professional
    * %param i_id_rehab_presc         treatment prescription
    * %param i_notes                  notes about status change
    * %param o_error                  error message
    *
    * @return                         TRUE on success, FALSE otherwise
    *
    * @author                         Eduardo Reis
    * @version                        1.0
    * @since                          2010-08-21
    **********************************************************************************************/
    FUNCTION accept_rehab_presc_proposal
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_rehab_presc IN rehab_presc.id_rehab_presc%TYPE,
        i_notes          IN rehab_presc.notes_change%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Rejects a rehab_presc proposal of suspension, discontinuation or edition
    *
    * %param i_lang                   id_language
    * %param i_prof                   id_professional
    * %param i_id_rehab_presc         treatment prescription
    * %param i_notes                  notes about status change
    * %param o_error                  error message
    *
    * @return                         TRUE on success, FALSE otherwise
    *
    * @author                         Eduardo Reis
    * @version                        1.0
    * @since                          2010-08-21
    **********************************************************************************************/
    FUNCTION reject_rehab_presc_proposal
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_rehab_presc IN rehab_presc.id_rehab_presc%TYPE,
        i_notes          IN rehab_presc.notes_change%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Cancels a rehab_presc proposal of suspension, discontinuation or edition
    *
    * %param i_lang                   id_language
    * %param i_prof                   id_professional
    * %param i_id_rehab_presc         treatment prescription
    * %param o_error                  error message
    *
    * @return                         TRUE on success, FALSE otherwise
    *
    * @author                         Joao Martins
    * @version                        v2.6.0.5.1.5
    * @since                          2011-02-10
    **********************************************************************************************/
    FUNCTION cancel_rehab_presc_proposal
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_rehab_presc IN rehab_presc.id_rehab_presc%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * get_rehab_menu_plans
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
    * @since   06-12-2010 19:14:35
    */
    FUNCTION get_rehab_menu_plans
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN action.from_state%TYPE,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * get_prof_by_cat
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
    * @since   06-12-2010 19:18:44
    */
    FUNCTION get_prof_by_cat
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_category IN category.id_category%TYPE DEFAULT NULL,
        o_curs        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * get_team
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
    * @since   06-12-2010 19:22:18
    */
    FUNCTION get_team
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan_team.id_rehab_epis_plan%TYPE,
        o_team               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * get_general_info
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
    * @since   06-12-2010 19:39:19
    */
    FUNCTION get_general_info
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN rehab_epis_plan.id_episode%TYPE,
        o_info       OUT pk_types.cursor_type,
        o_team       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * insert_plan_areas
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
    * @since   07-12-2010 11:18:28
    */
    FUNCTION set_plan_areas
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_rehab_epis_plan       IN rehab_epis_plan_area.id_rehab_epis_plan%TYPE,
        i_id_rehab_plan_area       IN table_number,
        i_id_rehab_epis_plan_area  IN table_number,
        i_current_situation        IN table_varchar,
        i_goals                    IN table_varchar,
        i_methodology              IN table_varchar,
        i_time                     IN table_number,
        i_flg_time_unit            IN table_varchar,
        i_id_prof_cat              IN table_table_number,
        i_id_rehab_epis_plan_sug   IN table_number,
        i_suggestions              IN table_varchar,
        i_id_rehab_epis_plan_notes IN table_number,
        i_notes                    IN table_varchar,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * INSERT_GENERAL_INFO
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
    * @since   07-12-2010 15:06:12
    */
    FUNCTION set_general_info
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan.id_rehab_epis_plan%TYPE,
        i_id_episode         IN rehab_epis_plan.id_episode%TYPE,
        i_id_prof_cat        IN table_number,
        i_creat_date         IN VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * get_all_plan
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
    * @since   07-12-2010 09:11:57
    */
    FUNCTION get_all_plan
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan_area.id_rehab_epis_plan%TYPE,
        o_info               OUT pk_types.cursor_type,
        o_notes              OUT pk_types.cursor_type,
        o_suggest            OUT pk_types.cursor_type,
        o_obj_profs          OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * get_gen_prof_info
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
    * @since   06-12-2010 19:39:19
    */
    FUNCTION get_gen_prof_info
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan_team.id_rehab_epis_plan%TYPE,
        i_id_episode         IN rehab_epis_plan.id_episode%TYPE,
        i_id_patient         IN episode.id_patient%TYPE,
        o_info               OUT pk_types.cursor_type,
        o_team               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * get_domains
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
    * @since   14-12-2010 12:12:32
    */
    FUNCTION get_domains
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_code_domain IN sys_domain.code_domain%TYPE,
        o_domain      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * cancel_plan
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
    * @since   15-12-2010 09:41:49
    */
    FUNCTION cancel_plan
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan_team.id_rehab_epis_plan%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * cancel_area
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
    * @since   15-12-2010 09:41:49
    */
    FUNCTION cancel_area
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan_area.id_rehab_epis_plan%TYPE,
        i_id_rehab_plan_area IN rehab_epis_plan_area.id_rehab_plan_area%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * cancel_objective
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
    * @since   15-12-2010 09:41:49
    */
    FUNCTION cancel_objective
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_rehab_epis_plan_area IN rehab_epis_plan_area.id_rehab_epis_plan_area%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * cancel_notes
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
    * @since   15-12-2010 09:41:49
    */
    FUNCTION cancel_notes
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_rehab_epis_plan_notes IN rehab_epis_plan_notes.id_rehab_epis_plan_notes%TYPE,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * get_all_plan
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
    * @since   07-12-2010 09:11:57
    */
    FUNCTION get_all_hist_plan
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_epis_plan IN rehab_epis_plan_area.id_rehab_epis_plan%TYPE,
        o_gen_info           OUT pk_types.cursor_type,
        o_info               OUT pk_types.cursor_type,
        o_notes              OUT pk_types.cursor_type,
        o_suggest            OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * set_plan_info
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
    * @since   07-12-2010 09:11:57
    */
    FUNCTION set_plan_info
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_rehab_epis_plan       IN rehab_epis_plan.id_rehab_epis_plan%TYPE,
        i_id_prof_cat_pl           IN table_number,
        i_id_episode               IN rehab_epis_plan.id_episode%TYPE,
        i_creat_date               IN VARCHAR2,
        i_id_rehab_plan_area       IN table_number,
        i_id_rehab_epis_plan_area  IN table_number,
        i_current_situation        IN table_varchar,
        i_goals                    IN table_varchar,
        i_methodology              IN table_varchar,
        i_time                     IN table_number,
        i_flg_time_unit            IN table_varchar,
        i_id_prof_cat              IN table_table_number,
        i_id_rehab_epis_plan_sug   IN table_number,
        i_suggestions              IN table_varchar,
        i_id_rehab_epis_plan_notes IN table_number,
        i_notes                    IN table_varchar,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns a list of rehab environmentsthat the professional is or can be allocated to in a given institution
    *
    * %param i_lang                   id_language
    * %param i_prof                   id_professional
    * %param i_id_institution         institution
    * %param o_environment            list of rehab environments
    * %param o_error                  error message
    *
    * @return                         TRUE on success, FALSE otherwise
    *
    * @author                         Nuno Neves
    * @version                        2.6.1
    * @since                          2011-03-02
    **********************************************************************************************/
    FUNCTION get_rehab_environment_prof
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        o_environment    OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Sets the list of rehab environment that the professional is allocated to, in one or more institutions
    *
    * %param i_lang                   id_language
    * %param i_prof                   id_professional
    * %param i_institution            list of institutions to alloc the professional
    * %param i_rehab_area             for each institution a list of rehab environment to alloc the professional
    * %param o_error                  error message
    *
    * @return                         TRUE on success, FALSE otherwise
    *
    * @author                         Nuno Neves
    * @version                        2.6.1
    * @since                          2011-03-02
    **********************************************************************************************/
    FUNCTION set_rehab_environment_prof
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_institution       IN table_number,
        i_rehab_environment IN table_table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the information about all rehab treats
    *
    * %param i_lang                   id_language
    * %param i_prof                   id_professional
    * %param i_id_patient             patient id
    * %param o_treat                  list of treatments
    * %param o_error                  error message
    *
    * @return                         TRUE on success, FALSE otherwise
    *
    * @author                         Nuno Neves
    * @version                        2.6.1.1
    * @since                          2012-02-10
    **********************************************************************************************/
    FUNCTION get_rehab_all_treat
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN rehab_plan.id_patient%TYPE,
        o_treat      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the information for the external prescriptions popup (if more than one for the same 
    * kind of codification).
    *
    * @param i_lang                ID language
    * @param i_prof                Professional
    * @param i_episode             Episode ID
    * @param i_id_rehab_presc      Prescription ID
    * @param o_show                Show popup?
    * @param o_messages            Titles and messages
    * @param o_interv              Cursor with the procedures
    * @param o_error               Error
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Joana Barroso
    * @version                     2.6.1.10
    * @since                       2012/08/16
    **********************************************************************************************/

    FUNCTION get_external_req
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_id_rehab_presc IN rehab_presc.id_rehab_presc%TYPE,
        o_show           OUT VARCHAR2,
        o_messages       OUT pk_types.cursor_type,
        o_rehab          OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns Institutions for rehab prescriptions  
    *
    * @param i_lang                ID language
    * @param i_prof                Professional
    * @param i_intervs             Array of requested Interventions
    * @param o_inst                Cursor with institutions
    * @param o_error               Error
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Joana Barroso
    * @version                     2.6.3.5
    * @since                       2013/05/18
    **********************************************************************************************/

    FUNCTION get_rehab_inst
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_intervs IN table_number,
        o_inst    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_rehab_presc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN rehab_plan.id_patient%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_rehab_presc      IN rehab_presc.id_rehab_presc%TYPE,
        i_id_rehab_sch_need   IN rehab_presc.id_rehab_sch_need%TYPE,
        i_id_exec_institution IN rehab_presc.id_exec_institution%TYPE,
        i_exec_per_session    IN rehab_presc.exec_per_session%TYPE,
        i_presc_notes         IN rehab_presc.notes%TYPE,
        i_sessions            IN rehab_sch_need.sessions%TYPE,
        i_frequency           IN rehab_sch_need.frequency%TYPE,
        i_flg_frequency       IN rehab_sch_need.flg_frequency%TYPE,
        i_flg_priority        IN rehab_sch_need.flg_priority%TYPE,
        i_date_begin          IN VARCHAR2,
        i_session_notes       IN rehab_sch_need.notes%TYPE,
        i_session_type        IN rehab_sch_need.id_rehab_session_type%TYPE,
        i_flg_laterality      IN rehab_presc.flg_laterality%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_cross_actions_permissions
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_subject     IN action.subject%TYPE,
        i_from_state  IN table_varchar,
        i_task_type   IN task_type.id_task_type%TYPE,
        i_rehab_presc IN table_number,
        o_actions     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_rehab_summary
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_pat  IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        --request
        o_rehab_request      OUT pk_types.cursor_type,
        o_rehab_request_prof OUT pk_types.cursor_type,
        --
        o_request_origin OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_grid_dates
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_all_patients     IN VARCHAR2,
        i_flg_type_profile IN VARCHAR2 DEFAULT NULL,
        o_date             OUT pk_types.cursor_type,
        o_error            OUT t_error_out
        
    ) RETURN BOOLEAN;

    FUNCTION set_rehab_resp
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_id_episode  IN NUMBER,
        i_id_schedule IN NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_rehab_favorite
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_rehab_area_interv IN rehab_area_interv.id_rehab_area_interv%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_actions
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_subject        IN action.subject%TYPE,
        i_from_state     IN action.from_state%TYPE,
        i_episode_origin IN episode.id_episode%TYPE,
        o_actions        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    --Globals
    g_error         VARCHAR2(4000);
    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

END pk_rehab_ux;
/
