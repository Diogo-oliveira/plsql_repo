/*-- Last Change Revision: $Rev: 2028860 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:23 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE pk_periodic_observation_ux IS

    -- Periodic observation upper layer services

    /**********************************************************************************************
    * Retornar os tipos de parametros disponíveis para as observações periódicas
    *
    * @param i_lang                   the id language
    * @param i_prof                   Profissional que requisita
    
    * @param o_param                  cursor
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Teresa Coutinho
    * @version                        1.0
    * @since                          2007/08/23
    **********************************************************************************************/

    FUNCTION get_periodic_param_type
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_param OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION get_periodic_param_type
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_owner         IN VARCHAR2,
        o_param         OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_other_periodic_param
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_flg_periodic_param_type IN periodic_param_type.flg_periodic_param_type%TYPE,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN episode.id_episode%TYPE,
        o_param                   OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION get_other_periodic_param
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_flg_periodic_param_type IN periodic_param_type.flg_periodic_param_type%TYPE,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN episode.id_episode%TYPE,
        i_pat_pregnancy           IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_owner                   IN VARCHAR2,
        
        o_param OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_periodic_observation_an
    (
        i_lang          IN language.id_language%TYPE,
        i_room          IN room.id_room%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_analysis      OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION get_periodic_observation_an
    (
        i_lang          IN language.id_language%TYPE,
        i_room          IN room.id_room%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_owner         IN VARCHAR2,
        o_analysis      OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancel parameter for patient.
    *
    * @param i_lang         language identifier
    * @param i_patient      patient identifier
    * @param i_params       parameter identifiers
    * @param i_owners       owner identifiers
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/22
    */
    FUNCTION cancel_parameter
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_params  IN table_number,
        i_owners  IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION cancel_parameter
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_params        IN table_number,
        i_owners        IN table_number,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_owner         IN VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels registered values for parameters.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_prof_cat     logged professional category
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param i_values       value identifiers
    * @param i_types        parameter types
    * @param i_canc_reason  cancellation reason identifier
    * @param i_canc_notes   cancellation notes
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.5
    * @since                2010/12/23
    */
    FUNCTION cancel_value
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_cat    IN category.flg_type%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_patient     IN patient.id_patient%TYPE,
        i_values      IN table_number,
        i_types       IN table_varchar,
        i_canc_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_canc_notes  IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION cancel_value_ref
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_cat    IN category.flg_type%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_patient     IN patient.id_patient%TYPE,
        i_values      IN table_number,
        i_types       IN table_varchar,
        i_canc_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_canc_notes  IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Create periodic observation column.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_dt           column date
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/14
    */
    FUNCTION create_column
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_dt      IN VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_column_comm_order
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_dt              IN VARCHAR2,
        o_id_po_param_reg OUT po_param_reg.id_po_param_reg%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * Create periodic observation column.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_dt           column date
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/14
    */
    FUNCTION create_column
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_dt              IN VARCHAR2,
        i_pat_pregnancy   IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_show_warning    OUT VARCHAR2,
        o_title_warning   OUT VARCHAR2,
        o_message_warning OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get actions.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param o_actions      actions
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/12/13
    */
    FUNCTION get_actions
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_actions OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get "create" button options.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param o_create       create options
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/13
    */
    FUNCTION get_create
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_create OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION get_create
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_create        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get detail.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_date         date to get results from
    * @param o_detail       detail
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/28
    */
    FUNCTION get_detail
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_date      IN VARCHAR2,
        i_task_type IN VARCHAR2,
        o_detail    OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;
    -----------------------------------------------
    FUNCTION get_detail_by_wh
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_date          IN VARCHAR2,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_detail        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get parameters grid.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param o_param        parameters
    * @param o_time         times
    * @param o_value        values
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/09
    */
    FUNCTION get_grid_param
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_num_reg IN NUMBER DEFAULT NULL,
        o_param   OUT pk_types.cursor_type,
        o_time    OUT pk_types.cursor_type,
        o_value   OUT pk_types.cursor_type,
        o_ref     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    --

    FUNCTION get_grid_param
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_dt_begin IN VARCHAR2,
        i_dt_end   IN VARCHAR2,
        i_num_reg  IN NUMBER DEFAULT NULL,
        o_param    OUT pk_types.cursor_type,
        o_time     OUT pk_types.cursor_type,
        o_value    OUT pk_types.cursor_type,
        o_ref      OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get keypad.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_param        parameter identifier
    * @param i_owner        owner identifier
    * @param o_keypad       keypad
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/20
    */
    FUNCTION get_keypad
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_param  IN po_param.id_po_param%TYPE,
        i_owner  IN po_param.id_inst_owner%TYPE,
        o_keypad OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get multichoice.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_param        parameter identifier
    * @param i_owner        owner identifier
    * @param o_mc           multichoice
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/19
    */
    FUNCTION get_multichoice
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_param   IN po_param.id_po_param%TYPE,
        i_owner   IN po_param.id_inst_owner%TYPE,
        o_mc      OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get multichoice of values to cancel.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_param        parameter identifier
    * @param i_owner        owner identifier
    * @param i_dt           parameter observation date
    * @param o_values       values to cancel
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/26
    */
    FUNCTION get_values_cancel
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_param   IN po_param.id_po_param%TYPE,
        i_owner   IN po_param.id_inst_owner%TYPE,
        i_dt      IN VARCHAR2,
        o_values  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    ------------------------------------
    FUNCTION get_values_cancel
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_param           IN po_param.id_po_param%TYPE,
        i_owner           IN po_param.id_inst_owner%TYPE,
        i_dt              IN VARCHAR2,
        i_woman_health_id IN VARCHAR2,
        o_values          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * Get views.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_loader       the current loader (per obs, pregnant)
    * @param o_views        views
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/05
    */
    FUNCTION get_views
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_loader  IN application_file.file_name%TYPE,
        o_views   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_pat_periodic_obs
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_por   IN periodic_observation_reg.id_periodic_observation_reg%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*  
    * Create periodic observation column by mcdt.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_flg_type_param      parameter flg type
    * @param i_patient             patient identifier
    * @param i_episode      episode identifier
    * @param i_dt_begin_str           column date
    * @param i_prof_req               prof request
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Jorge Silva
    * @version               2.6
    * @since                2013/07/18
    */
    FUNCTION create_column_by_mcdt
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_flg_type_param IN periodic_observation_reg.flg_type_param%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_dt_begin_str   IN VARCHAR2,
        i_prof_req       IN periodic_observation_reg.id_prof_writes%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*  
    * delete periodic observation column by mcdt.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_por          reg of periodic observation
    * @param i_episode      episode identifier
    * @param i_dt           column date
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author              Jorge Silva
    * @version               2.6
    * @since                2013/07/18
    */
    FUNCTION delete_column_by_mcdt
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_por   IN periodic_observation_reg.id_periodic_observation_reg%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Set parameter for patient.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_parameters   local parameter identifiers
    * @param i_types        parameter type flags
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/22
    */
    FUNCTION set_parameter
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_parameters  IN table_number,
        i_types       IN table_varchar,
        i_sample_type IN table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_parameter
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_parameters    IN table_number,
        i_types         IN table_varchar,
        i_sample_type   IN table_number,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_owner         IN VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Set values with keypad.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_prof_cat     logged professional category
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_params       parameter identifiers
    * @param i_owners       owner identifiers
    * @param i_results      result descriptions list
    * @param i_unit_mea     measurement units list
    * @param i_date         observation date
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/26
    */
    FUNCTION set_value_k
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_prof_cat IN category.flg_type%TYPE,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_params   IN table_number,
        i_owners   IN table_number,
        i_results  IN table_varchar,
        i_unit_mea IN table_number,
        i_date     IN VARCHAR2,
        o_value    OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION set_value_k
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_prof_cat        IN category.flg_type%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_params          IN table_number,
        i_owners          IN table_number,
        i_results         IN table_varchar,
        i_unit_mea        IN table_number,
        i_date            IN VARCHAR2,
        i_woman_health_id IN VARCHAR2,
        o_value           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Set values with multichoice.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_prof_cat     logged professional category
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_params       parameter identifiers
    * @param i_owners       owner identifiers
    * @param i_options      multichoice options list
    * @param i_a_req_dets   lab test request details
    * @param i_date         observation date
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/27
    */
    FUNCTION set_value_m
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_prof_cat IN category.flg_type%TYPE,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_params   IN table_number,
        i_owners   IN table_number,
        i_options  IN table_table_number,
        i_date     IN VARCHAR2,
        o_value    OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    -------------------------------------
    FUNCTION set_value_m
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_prof_cat        IN category.flg_type%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_params          IN table_number,
        i_owners          IN table_number,
        i_options         IN table_table_number,
        i_date            IN VARCHAR2,
        i_woman_health_id IN VARCHAR2,
        o_value           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    -----------------------------------------------
    FUNCTION set_value_t
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_prof_cat IN category.flg_type%TYPE,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_params   IN table_number,
        i_owners   IN table_number,
        i_results  IN table_clob,
        i_date     IN VARCHAR2,
        o_value    OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    -----------------------------------------------
    FUNCTION set_value_t
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_prof_cat        IN category.flg_type%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_params          IN table_number,
        i_owners          IN table_number,
        i_results         IN table_clob,
        i_date            IN VARCHAR2,
        i_woman_health_id IN VARCHAR2,
        o_value           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    -----------------------------------------------
    FUNCTION set_value_d
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_cat   IN category.flg_type%TYPE,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_params     IN table_number,
        i_owners     IN table_number,
        i_dates      IN table_varchar,
        i_dates_mask IN table_varchar,
        i_date       IN VARCHAR2,
        o_value      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    -----------------------------------------------
    FUNCTION set_value_d
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_prof_cat        IN category.flg_type%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_params          IN table_number,
        i_owners          IN table_number,
        i_dates           IN table_varchar,
        i_dates_mask      IN table_varchar,
        i_date            IN VARCHAR2,
        i_woman_health_id IN VARCHAR2,
        o_value           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    -----------------------------------------------
    /*
    * Creates an order with a result for a given exam
    *
    * @param     i_lang                Language id
    * @param     i_prof                Professional
    * @param     i_patient             Patient id
    * @param     i_episode             Episode id
    * @param     i_exam_req_det        Exam detail order id
    * @param     i_reg                 Periodic observation id
    * @param     i_exam                Exams' id
    * @param     i_test                Flag that indicates if the exam is really to be ordered
    * @param     i_prof_performed      Professional perform id
    * @param     i_start_time          Exams' start time
    * @param     i_end_time            Exams' end time
    * @param     i_flg_result_origin   Flag that indicates what is the result's origin
    * @param     i_notes               Result notes
    * @param     i_flg_import          Flag that indicates if there is a document to import
    * @param     i_id_doc              Closing document id
    * @param     i_doc_type            Document type id
    * @param     i_desc_doc_type       Document type description
    * @param     i_dt_doc              Original document date
    * @param     i_dest                Destination id
    * @param     i_desc_dest           Destination description
    * @param     i_ori_type            Document type id
    * @param     i_desc_ori_doc_type   Document type description
    * @param     i_original            Original document id
    * @param     i_desc_original       Original document description
    * @param     i_btn                 Context
    * @param     i_title               Document description
    * @param     i_desc_perf_by        Performed by description
    * @param     i_woman_health_id     Pregnancy ID
    * @param     o_flg_show            Flag that indicates if there is a message to be shown
    * @param     o_msg_title           Message title
    * @param     o_msg_req             Message to be shown
    * @param     o_button              Buttons to show
    * @param     o_exam_req            Exams' order id
    * @param     o_exam_req_det        Exams' order details id 
    * @param     o_value               Value object,
    * @param     o_error               Error message
    *
    * @author               Jorge Silva
    * @version               2.5
    * @since                2013/04/09
    */
    FUNCTION set_value_exams
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN patient.id_patient%TYPE,
        i_episode             IN exam_req.id_episode%TYPE,
        i_exam_req_det        IN exam_req_det.id_exam_req_det%TYPE,
        i_reg                 IN periodic_observation_reg.id_periodic_observation_reg%TYPE,
        i_exam                IN exam.id_exam%TYPE,
        i_prof_performed      IN exam_req_det.id_prof_performed%TYPE,
        i_start_time          IN VARCHAR2,
        i_end_time            IN VARCHAR2,
        i_result_status       IN result_status.id_result_status%TYPE,
        i_abnormality         IN exam_result.id_abnormality%TYPE,
        i_flg_result_origin   IN exam_result.flg_result_origin%TYPE,
        i_result_origin_notes IN exam_result.result_origin_notes%TYPE,
        i_notes               IN exam_result.notes%TYPE,
        i_flg_import          IN table_varchar,
        i_id_doc              IN table_number,
        i_doc_type            IN table_number,
        i_desc_doc_type       IN table_varchar,
        i_dt_doc              IN table_varchar,
        i_dest                IN table_number,
        i_desc_dest           IN table_varchar,
        i_ori_doc_type        IN table_number,
        i_desc_ori_doc_type   IN table_varchar,
        i_original            IN table_number,
        i_desc_original       IN table_varchar,
        i_title               IN table_varchar,
        i_desc_perf_by        IN table_varchar,
        i_po_param            IN table_number,
        i_woman_health_id     IN VARCHAR2,
        o_exam_req            OUT exam_req.id_exam_req%TYPE,
        o_exam_req_det        OUT exam_req_det.id_exam_req_det%TYPE,
        o_value               OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Creates an order with a result for a given exam
    *
    * @param     i_lang                Language id
    * @param     i_prof                Professional
    * @param     i_patient             Patient id
    * @param     i_episode             Episode id
    * @param     i_exam_req_det        Exam detail order id
    * @param     i_reg                 Periodic observation id
    * @param     i_exam                Exams' id
    * @param     i_test                Flag that indicates if the exam is really to be ordered
    * @param     i_prof_performed      Professional perform id
    * @param     i_start_time          Exams' start time
    * @param     i_end_time            Exams' end time
    * @param     i_flg_result_origin   Flag that indicates what is the result's origin
    * @param     i_notes               Result notes
    * @param     i_flg_import          Flag that indicates if there is a document to import
    * @param     i_id_doc              Closing document id
    * @param     i_doc_type            Document type id
    * @param     i_desc_doc_type       Document type description
    * @param     i_dt_doc              Original document date
    * @param     i_dest                Destination id
    * @param     i_desc_dest           Destination description
    * @param     i_ori_type            Document type id
    * @param     i_desc_ori_doc_type   Document type description
    * @param     i_original            Original document id
    * @param     i_desc_original       Original document description
    * @param     i_btn                 Context
    * @param     i_title               Document description
    * @param     i_desc_perf_by        Performed by description
    * @param     o_flg_show            Flag that indicates if there is a message to be shown
    * @param     o_msg_title           Message title
    * @param     o_msg_req             Message to be shown
    * @param     o_button              Buttons to show
    * @param     o_exam_req            Exams' order id
    * @param     o_exam_req_det        Exams' order details id 
    * @param     o_value               Value object,
    * @param     o_error               Error message
    *
    * @author               Jorge Silva
    * @version               2.5
    * @since                2013/04/09
    */
    FUNCTION set_value_exams
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN patient.id_patient%TYPE,
        i_episode             IN exam_req.id_episode%TYPE,
        i_exam_req_det        IN exam_req_det.id_exam_req_det%TYPE,
        i_reg                 IN periodic_observation_reg.id_periodic_observation_reg%TYPE,
        i_exam                IN exam.id_exam%TYPE,
        i_prof_performed      IN exam_req_det.id_prof_performed%TYPE,
        i_start_time          IN VARCHAR2,
        i_end_time            IN VARCHAR2,
        i_result_status       IN result_status.id_result_status%TYPE,
        i_abnormality         IN exam_result.id_abnormality%TYPE,
        i_flg_result_origin   IN exam_result.flg_result_origin%TYPE,
        i_result_origin_notes IN exam_result.result_origin_notes%TYPE,
        i_notes               IN exam_result.notes%TYPE,
        i_flg_import          IN table_varchar,
        i_id_doc              IN table_number,
        i_doc_type            IN table_number,
        i_desc_doc_type       IN table_varchar,
        i_dt_doc              IN table_varchar,
        i_dest                IN table_number,
        i_desc_dest           IN table_varchar,
        i_ori_doc_type        IN table_number,
        i_desc_ori_doc_type   IN table_varchar,
        i_original            IN table_number,
        i_desc_original       IN table_varchar,
        i_title               IN table_varchar,
        i_desc_perf_by        IN table_varchar,
        i_po_param            IN table_number,
        o_exam_req            OUT exam_req.id_exam_req%TYPE,
        o_exam_req_det        OUT exam_req_det.id_exam_req_det%TYPE,
        o_value               OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
    *
    * Create analysis results with/without analysis req also updates de results values 
    * This development is for the complex analysis, inserting the results values partially
    *
    * @return true/false
    *
    * @AUTHOR Jorge Silva
    * @VERSION 2.5.2
    * @SINCE 22/4/2013
    *
    *******************************************************************************/
    FUNCTION set_value_analysis
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_patient                IN analysis_result.id_patient%TYPE,
        i_episode                IN analysis_result.id_episode%TYPE,
        i_analysis               IN analysis.id_analysis%TYPE,
        i_sample_type            IN sample_type.id_sample_type%TYPE,
        i_analysis_parameter     IN table_number,
        i_analysis_param         IN table_number,
        i_analysis_req_det       IN analysis_req_det.id_analysis_req_det%TYPE,
        i_analysis_req_par       IN table_number,
        i_analysis_result_par    IN table_number,
        i_flg_type               IN table_varchar,
        i_harvest                IN harvest.id_harvest%TYPE,
        i_dt_sample              IN VARCHAR2,
        i_prof_req               IN analysis_result.id_prof_req%TYPE,
        i_dt_analysis_result     IN VARCHAR2,
        i_flg_result_origin      IN analysis_result.flg_result_origin%TYPE,
        i_result_origin_notes    IN analysis_result.result_origin_notes%TYPE,
        i_result_notes           IN analysis_result.notes%TYPE,
        i_result                 IN table_varchar,
        i_analysis_desc          IN table_number,
        i_doc_external           IN table_table_number DEFAULT NULL,
        i_doc_type               IN table_table_number DEFAULT NULL,
        i_doc_ori_type           IN table_table_number DEFAULT NULL,
        i_title                  IN table_table_varchar DEFAULT NULL, --30
        i_unit_measure           IN table_number,
        i_result_status          IN table_number,
        i_ref_val_min            IN table_varchar,
        i_ref_val_max            IN table_varchar,
        i_parameter_notes        IN table_varchar,
        i_flg_orig_analysis      IN VARCHAR2,
        i_clinical_decision_rule IN NUMBER,
        i_po_param               IN table_number,
        i_woman_health_id        IN VARCHAR2,
        o_value                  OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
    *
    * Create analysis results with/without analysis req also updates de results values 
    * This development is for the complex analysis, inserting the results values partially
    * @return true/false
    *
    * @AUTHOR Jorge Silva
    * @VERSION 2.5.2
    * @SINCE 22/4/2013
    *
    *******************************************************************************/
    FUNCTION set_value_analysis
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_patient                IN analysis_result.id_patient%TYPE,
        i_episode                IN analysis_result.id_episode%TYPE,
        i_analysis               IN analysis.id_analysis%TYPE,
        i_sample_type            IN sample_type.id_sample_type%TYPE,
        i_analysis_parameter     IN table_number,
        i_analysis_param         IN table_number,
        i_analysis_req_det       IN analysis_req_det.id_analysis_req_det%TYPE,
        i_analysis_req_par       IN table_number,
        i_analysis_result_par    IN table_number,
        i_flg_type               IN table_varchar,
        i_harvest                IN harvest.id_harvest%TYPE,
        i_dt_sample              IN VARCHAR2,
        i_prof_req               IN analysis_result.id_prof_req%TYPE,
        i_dt_analysis_result     IN VARCHAR2,
        i_flg_result_origin      IN analysis_result.flg_result_origin%TYPE,
        i_result_origin_notes    IN analysis_result.result_origin_notes%TYPE,
        i_result_notes           IN analysis_result.notes%TYPE,
        i_result                 IN table_varchar,
        i_analysis_desc          IN table_number,
        i_doc_external           IN table_table_number DEFAULT NULL,
        i_doc_type               IN table_table_number DEFAULT NULL,
        i_doc_ori_type           IN table_table_number DEFAULT NULL,
        i_title                  IN table_table_varchar DEFAULT NULL, --30
        i_unit_measure           IN table_number,
        i_result_status          IN table_number,
        i_ref_val_min            IN table_varchar,
        i_ref_val_max            IN table_varchar,
        i_parameter_notes        IN table_varchar,
        i_flg_orig_analysis      IN VARCHAR2,
        i_clinical_decision_rule IN NUMBER,
        i_po_param               IN table_number,
        o_value                  OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get woman health grid.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param o_wh           woman health 
    * @param o_param        parameters
    * @param o_wh_param     woman health parameters
    * @param o_time         times
    * @param o_value        values
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Paulo Teixeira
    * @version               2.5
    * @since                2013/02/18
    */
    FUNCTION get_grid_wh
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_wh            OUT pk_types.cursor_type,
        o_param         OUT pk_types.cursor_type,
        o_wh_param      OUT pk_types.cursor_type,
        o_time          OUT pk_types.cursor_type,
        o_value         OUT pk_types.cursor_type,
        o_ref           OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_grid_comm_order
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_id_comm_order_plan IN comm_order_plan.id_comm_order_plan%TYPE,
        i_id_po_param_reg    IN po_param_reg.id_po_param_reg%TYPE,
        i_id_comm_order_req  IN comm_order_req.id_comm_order_req%TYPE,
        o_title              OUT VARCHAR2,
        o_sets               OUT pk_types.cursor_type,
        o_param              OUT pk_types.cursor_type,
        o_sets_param         OUT pk_types.cursor_type,
        o_time               OUT pk_types.cursor_type,
        o_value              OUT pk_types.cursor_type,
        o_ref                OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * get_permissions
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_pat_pregnancy        pat_pregnancy identifier
    * @param o_read_only        read_only Y/N
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Paulo Teixeira
    * @version               2.5
    * @since                2013/02/18
    */
    FUNCTION get_permissions
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_read_only     OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    -----------------------------------------------
    FUNCTION set_vital_sign
    (
        i_lang               IN language.id_language%TYPE,
        i_episode            IN vital_sign_read.id_episode%TYPE,
        i_prof               IN profissional,
        i_pat                IN vital_sign_read.id_patient%TYPE,
        i_vs_id              IN table_number,
        i_vs_val             IN table_number,
        i_id_monit           IN monitorization_vs_plan.id_monitorization_vs_plan%TYPE,
        i_unit_meas          IN table_number,
        i_vs_scales_elements IN table_number,
        i_notes              IN vital_sign_notes.notes%TYPE,
        i_prof_cat_type      IN category.flg_type%TYPE,
        i_dt_vs_read         IN VARCHAR2,
        i_params             IN table_number,
        i_woman_health_id    IN VARCHAR2,
        o_vital_sign_read    OUT table_number,
        o_value              OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    -----------------------------------------------
    FUNCTION set_vital_sign
    (
        i_lang               IN language.id_language%TYPE,
        i_episode            IN vital_sign_read.id_episode%TYPE,
        i_prof               IN profissional,
        i_pat                IN vital_sign_read.id_patient%TYPE,
        i_vs_id              IN table_number,
        i_vs_val             IN table_number,
        i_id_monit           IN monitorization_vs_plan.id_monitorization_vs_plan%TYPE,
        i_unit_meas          IN table_number,
        i_vs_scales_elements IN table_number,
        i_notes              IN vital_sign_notes.notes%TYPE,
        i_prof_cat_type      IN category.flg_type%TYPE,
        i_dt_vs_read         IN VARCHAR2,
        i_params             IN table_number,
        o_vital_sign_read    OUT table_number,
        o_value              OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_grid_sets
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_task_type  IN VARCHAR2,
        o_title      OUT VARCHAR2,
        o_sets       OUT pk_types.cursor_type,
        o_param      OUT pk_types.cursor_type,
        o_sets_param OUT pk_types.cursor_type,
        o_time       OUT pk_types.cursor_type,
        o_value      OUT pk_types.cursor_type,
        o_ref        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_column_comm_order
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_dt              IN VARCHAR2,
        i_task_type       IN task_type.id_task_type%TYPE,
        i_id_concept      IN comm_order_ea.id_concept%TYPE,
        o_show_warning    OUT VARCHAR2,
        o_title_warning   OUT VARCHAR2,
        o_message_warning OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

END pk_periodic_observation_ux;
/
