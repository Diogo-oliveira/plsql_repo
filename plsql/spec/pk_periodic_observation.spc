/*-- Last Change Revision: $Rev: 2028859 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:23 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE pk_periodic_observation IS

    /**********************************************************************************************
    *   Retornar o id_clinical_service
    *
    * @param i_episode                ID DO EPISODIO
    
    *
    * @return                         id_clinical_setvice
    *
    * @author                         Teresa Coutinho
    * @version                        1.0
    * @since                          2007/08/17
    **********************************************************************************************/
    FUNCTION get_id_clinical_service(i_episode IN episode.id_episode%TYPE) RETURN NUMBER;

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
        o_param                   OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Adds a new column to the periodic observation grid.
    *
    * @param i_lang                    language identifier.
    * @param i_prof                    logged professional structure.
    * @param i_flg_type_param          type of parameters ('O'ther or 'P'arametrized).
    * @param i_patient                 patient identifier.
    * @param i_episode                 episode identifier.
    * @param i_dt_begin_str            new column date.
    * @param i_prof_req                requesting professional identifier.
    *
    * @author                         Teresa Coutinho
    * @version                        1.0
    * @since                          2007/08/30
    **********************************************************************************************/
    PROCEDURE set_pat_periodic_observation
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_flg_type_param IN periodic_observation_reg.flg_type_param%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_dt_begin_str   IN VARCHAR2,
        i_prof_req       IN periodic_observation_reg.id_prof_writes%TYPE
    );

    /*
    * Cancels a given id (column)
    *
    * @param     i_prof                       Professional
    * @param     i_periodic_observation_reg   Periodic observation id
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2010/03/18
    */
    PROCEDURE cancel_pat_periodic_obs
    (
        i_prof IN profissional,
        i_por  IN periodic_observation_reg.id_periodic_observation_reg%TYPE
    );

    /*
    * Deletes a given id (column)
    *
    * @param     i_periodic_observation_reg   Periodic observation id
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2010/06/14
    */
    PROCEDURE delete_pat_periodic_obs(i_por IN periodic_observation_reg.id_periodic_observation_reg%TYPE);

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
    * @param i_patient      patient identifier
    * @param i_params       parameter identifiers
    * @param i_owners       owner identifiers
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/22
    */
    PROCEDURE cancel_parameter
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_params        IN table_number,
        i_owners        IN table_number,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_owner         IN VARCHAR2
    );

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
        i_ref_value   IN VARCHAR2 DEFAULT 'N',
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
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/14
    */
    PROCEDURE create_column
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_dt      IN VARCHAR2,
        o_error   OUT t_error_out
    );

    PROCEDURE create_column_comm_order
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_dt              IN VARCHAR2,
        o_id_po_param_reg OUT po_param_reg.id_po_param_reg%TYPE,
        o_error           OUT t_error_out
    );
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

    FUNCTION cancel_column
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_po_param_reg IN po_param_reg.id_po_param_reg%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Create automatic periodic observation column (to use on episode creation only).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/13
    */
    PROCEDURE create_column_auto
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    );

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

    FUNCTION get_detail_comm_order
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_comm_order_req  IN comm_order_req.id_comm_order_req%TYPE,
        i_po_param_reg    IN po_param_reg.id_po_param_reg%TYPE,
        o_parameter_desc  OUT table_varchar,
        o_parameter_value OUT table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_count_comm_order
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        i_po_param_reg   IN po_param_reg.id_po_param_reg%TYPE,
        o_error          OUT t_error_out
    ) RETURN NUMBER;

    /**
    * Get the episode's periodic observations.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param o_per_obs      episode's periodic observations
    *
    * @author               Pedro Carneiro
    * @version               2.5.0.7
    * @since                2010/01/06
    */
    PROCEDURE get_epis_per_obs
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_per_obs OUT pk_types.cursor_type
    );

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
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_cursor_out IN VARCHAR2 DEFAULT 'A',
        i_dt_begin   IN VARCHAR2 DEFAULT NULL,
        i_dt_end     IN VARCHAR2 DEFAULT NULL,
        i_num_reg    IN NUMBER DEFAULT NULL,
        o_param      OUT pk_types.cursor_type,
        o_time       OUT pk_types.cursor_type,
        o_value      OUT pk_types.cursor_type,
        o_values_wh  OUT t_coll_wh_values,
        o_ref        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get keypad.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_param        parameter identifier
    * @param i_owner        owner identifier
    * @param o_keypad       keypad
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/20
    */
    PROCEDURE get_keypad
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_param  IN po_param.id_po_param%TYPE,
        i_owner  IN po_param.id_inst_owner%TYPE,
        o_keypad OUT pk_types.cursor_type
    );

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
    * Get full parameters list (as used in parameters grid).
    *
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    *
    * @return               parameters collection
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/27
    */
    FUNCTION get_param
    (
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN t_coll_po_param;

    /**
    * Get parameter alias translation.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_param        parameter identifier
    * @param i_owner        owner identifier
    * @param i_dcs          service/specialty identifier
    *
    * @return               parameter translation
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/12
    */
    FUNCTION get_param_alias
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_param IN po_param.id_po_param%TYPE,
        i_owner IN po_param.id_inst_owner%TYPE,
        i_dcs   IN po_param_alias.id_dep_clin_serv%TYPE := NULL
    ) RETURN pk_translation.t_desc_translation;

    /**
    * Get parameters value for create option.
    *
    * @param flg_type       Parameter Type ('A' - Analysis, 'E' -Exames...)
    * @param i_idParam      Parameter register id
    * @param i_id_parameter Parameter id 
    *
    * @author               Jorge Silva
    * @version               2.5
    * @since                2013/10/08
    */
    FUNCTION get_param_create
    (
        i_prof         IN profissional,
        i_flg_type     IN po_param.flg_type%TYPE,
        i_id_param     IN po_param.id_po_param%TYPE,
        i_id_parameter IN po_param.id_parameter%TYPE
    ) RETURN VARCHAR2;

    /**
    * Get parameter description.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_param        parameter identifier
    * @param i_owner        owner identifier
    * @param i_flg_type     parameter type flag
    * @param i_parameter    local parameter identifier
    * @param i_dcs          service/specialty identifier
    *
    * @return               parameter translation
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/12/11
    */
    FUNCTION get_param_desc
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_param     IN po_param.id_po_param%TYPE,
        i_owner     IN po_param.id_inst_owner%TYPE,
        i_flg_type  IN po_param.flg_type%TYPE,
        i_parameter IN po_param.id_parameter%TYPE,
        i_dcs       IN po_param_alias.id_dep_clin_serv%TYPE := NULL
    ) RETURN pk_translation.t_desc_translation;

    /**
    * Get parameter rank.
    *
    * @param i_prof         logged professional structure
    * @param i_param        parameter identifier
    * @param i_owner        owner identifier
    * @param i_rank         parameter self rank
    *
    * @return               parameter rank
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/28
    */
    FUNCTION get_param_rank
    (
        i_prof  IN profissional,
        i_param IN po_param.id_po_param%TYPE,
        i_owner IN po_param.id_inst_owner%TYPE,
        i_rank  IN po_param.rank%TYPE := NULL
    ) RETURN po_param_rank.rank%TYPE;

    /**
    * Get previous appointment date.
    *
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    *
    * @return               previous appointment date
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/30
    */
    FUNCTION get_prev_epis_date
    (
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN episode.dt_end_tstz%TYPE;

    /**
    * Get record multichoice option identifiers.
    *
    * @param i_popr         parameter record identifier
    *
    * @return               multichoice option identifiers
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/23
    */
    FUNCTION get_reg_opt_codes(i_popr IN po_param_reg.id_po_param_reg%TYPE) RETURN table_varchar;

    /**
    * Get record multichoice option icon.
    *
    * @param i_lang         language identifier
    * @param i_popr         parameter record identifier
    *
    * @return               multichoice first option icon
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/28
    */
    FUNCTION get_reg_opt_icon
    (
        i_lang IN language.id_language%TYPE,
        i_popr IN po_param_reg.id_po_param_reg%TYPE
    ) RETURN pk_translation.t_desc_translation;

    /**
    * Get record multichoice option value.
    *
    * @param i_lang         language identifier
    * @param i_codes        multichoice option codes
    *
    * @return               multichoice option value
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/28
    */
    FUNCTION get_reg_opt_value
    (
        i_lang  IN language.id_language%TYPE,
        i_codes IN table_varchar
    ) RETURN pk_translation.t_desc_translation;

    /**
    * Checks if a parameter is shown in the parameters grid.
    *
    * @param i_prof         logged professional structure
    * @param i_params       parameters collection
    * @param i_type         parameter type flag
    * @param i_parameter    local parameter identifier
    * @param i_sample_type  sample type Id
    *
    * @return               'true'/'false'
    *
    * @author               Teresa Coutinho
    * @version               2.4.3
    * @since                2008/01/23
    */
    FUNCTION get_selected
    (
        i_prof        IN profissional,
        i_params      IN t_coll_po_param,
        i_type        IN po_param.flg_type%TYPE,
        i_parameter   IN po_param.id_parameter%TYPE,
        i_sample_type IN po_param.id_sample_type%TYPE
    ) RETURN VARCHAR2;

    /**
    * Get record signature.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_prof_id      professional identifier
    * @param i_dt_reg       registry date
    * @param i_episode      episode identifier
    * @param i_inst         institution identifier
    *
    * @return               record signature
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/28
    */
    FUNCTION get_signature
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_id    IN professional.id_professional%TYPE,
        i_dt_reg     IN po_param_reg.dt_creation%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_inst       IN institution.id_institution%TYPE,
        i_flg_status IN VARCHAR2 DEFAULT 'A'
    ) RETURN pk_translation.t_desc_translation;

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

    /**
    * Set parameter for patient.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_parameters   local parameter identifiers
    * @param i_types        parameter type flags
    * @param i_sample_type  Analysis parameter
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
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_parameters    IN table_number,
        i_types         IN table_varchar,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_owner         IN VARCHAR2,
        i_sample_type   IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Set parameters for patient. Internal use only.
    *
    * @param i_patient      patient identifier
    * @param i_params       parameter identifiers
    * @param i_owners       owner identifiers
    * @param i_flg_visible  parameter visibility (Y/N)
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/22
    */
    PROCEDURE set_parameter_int
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_params        IN table_number,
        i_owners        IN table_number,
        i_flg_visible   IN pat_po_param.flg_visible%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_owner         IN VARCHAR2
    );

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
    * @param     i_woman_health_id     Woman health id
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
        i_cursor_out    IN VARCHAR2 DEFAULT 'A',
        o_wh            OUT pk_types.cursor_type,
        o_param         OUT pk_types.cursor_type,
        o_wh_param      OUT pk_types.cursor_type,
        o_time          OUT pk_types.cursor_type,
        o_value         OUT pk_types.cursor_type,
        o_values_wh     OUT t_coll_wh_values,
        o_ref           OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get full parameters list (as used in parameters grid).
    *
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    *
    * @return               parameters collection
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/27
    */
    FUNCTION get_param_wp
    (
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_owner         IN VARCHAR2
    ) RETURN t_coll_po_param;
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
    /********************************************************************************************
    * get_pregnancy_week
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_dt_ini       begin date
    * @param i_dt_fim       end date
    *
    * @return               pregnancy_week
    *
    * @author               Paulo Teixeira
    * @version               2.5
    * @since                2013/02/18
    *
    **********************************************************************************************/
    FUNCTION get_pregnancy_week
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_dt_ini IN pat_pregnancy.dt_init_pregnancy%TYPE,
        i_dt_fim IN pat_pregnancy.dt_intervention%TYPE
    ) RETURN VARCHAR2;
    /**
    * Get values collection.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_params       parameter identifiers
    *
    * @return               values collection
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/12
    */
    FUNCTION get_value_coll_wh
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_params        IN t_coll_po_param,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_dt_ini        IN pat_pregnancy.dt_init_pregnancy%TYPE,
        i_dt_fim        IN pat_pregnancy.dt_init_pregnancy%TYPE
    ) RETURN t_coll_po_value;

    FUNCTION get_value_coll_comm_order
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_params         IN t_coll_po_param,
        i_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        i_dt_ini         IN pat_pregnancy.dt_init_pregnancy%TYPE,
        i_dt_fim         IN pat_pregnancy.dt_init_pregnancy%TYPE,
        o_time           OUT pk_types.cursor_type
    ) RETURN t_coll_po_value;
    ------------------------------
    FUNCTION get_value_coll
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_params   IN t_coll_po_param,
        i_dt_begin IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_dt_end   IN TIMESTAMP WITH TIME ZONE DEFAULT NULL
    ) RETURN t_coll_po_value;
    -----------------------------
    FUNCTION get_value_cursor_wh
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_values  IN t_coll_po_value
    ) RETURN t_coll_wh_values;
    ------------------------------
    FUNCTION get_value_cursor
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_values IN t_coll_po_value
    ) RETURN t_coll_wh_values;
    ------------------------------------
    FUNCTION split_woman_health_id
    (
        i_woman_health_id    IN VARCHAR2,
        o_id_pat_pregnancy   OUT pat_pregnancy.id_pat_pregnancy%TYPE,
        o_id_pat_pregn_fetus OUT pat_pregn_fetus.id_pat_pregn_fetus%TYPE
    ) RETURN BOOLEAN;
    -----------------------------------------------
    FUNCTION get_pregn_interval_dates
    (
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_dt_ini        OUT pat_pregnancy.dt_init_pregnancy%TYPE,
        o_dt_fim        OUT pat_pregnancy.dt_init_pregnancy%TYPE
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
    -----------------------------------------------
    FUNCTION get_po_param_reg_date
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient patient.id_patient%TYPE,
        i_date       VARCHAR2
    ) RETURN VARCHAR2;

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
    FUNCTION get_dt_str
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_date      IN VARCHAR2,
        i_date_mask IN VARCHAR2
    ) RETURN VARCHAR2;
    -----------------------------------------------
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
    -------------------------------
    FUNCTION get_woman_health_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_woman_health_id IN VARCHAR2
    ) RETURN VARCHAR2;
    -------------------------------
    FUNCTION has_vital_sign_val_ref(i_id_vital_sign IN vital_sign.id_vital_sign%TYPE) RETURN VARCHAR2;
    -------------------------------
    FUNCTION set_preg_po_param
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    -------------------------------

    FUNCTION get_values_return
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_params          IN table_number,
        i_date            IN VARCHAR2,
        i_woman_health_id IN VARCHAR2,
        o_value           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /*****************************************************************************
    * Retrieve a collection with all mapped events, given the patient's current
    * health program inscriptions. Medication events are retrieved externally,
    * and therefore, separated.
    *
    * @param i_prof        logged professional structure
    * @param i_patient     patient identifier
    * @param o_hpg         table_info collection (other events
    * @param o_med         table_index_varchar collection (g_med_local and g_med_ext events)
    *
    * @author              Pedro Carneiro
    * @version              1.0
    * @since               2009/05/22
    *******************************************************************************/
    PROCEDURE get_health_programs_events
    (
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_hpg     OUT table_info,
        o_med     OUT table_index_varchar
    );

    /************************************************************************************************************
    * Réplica da função get_periodic_observation_all mas o cursor o_periodic_observation_val retorna os campos
    * separados em vez de unidos por pipes
    *
    * @param      i_lang                Língua registada como preferência do profissional
    * @param      i_patient             ID do paciente
    * @param      i_prof                ID do profissional
    * @param      i_episode             ID do episode
    *
    * @param      o_periodic_observation_time      Cursor com a informação dos tempos (colunas)
    * @param      o_periodic_observation_par       Cursor com a informação dos parâmetros (linhas)
    * @param      o_periodic_observation_val       Cursor com a informação dos valores
    * @param      o_error              Erro
    *
    * @return     true em caso de sucesso e false caso contrário
    * @author     Pedro Teixeira
    * @version    0.1
    * @since      2009/07/14
    ***********************************************************************************************************/
    FUNCTION get_periodic_observation_rep
    (
        i_lang                      IN language.id_language%TYPE,
        i_patient                   IN patient.id_patient%TYPE,
        i_prof                      IN profissional,
        i_episode                   IN episode.id_episode%TYPE,
        o_periodic_observation_time OUT pk_types.cursor_type,
        o_periodic_observation_par  OUT pk_types.cursor_type,
        o_periodic_observation_val  OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;
    /************************************************************************************************************
    * Get values collection.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    *
    * @return               values collection
    *
    * @author               Teresa Coutinho
    * @version              2.6.4.2
    * @since                2014/10/01
    ***********************************************************************************************************/

    FUNCTION get_value_coll_pl
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN t_coll_po_value_pl;

    /************************************************************************************************************
    * Get values collection for fetus vs.
    *
    * @param i_lang          language identifier
    * @param i_prof          logged professional structure
    * @param i_patient       patient identifier
    * @param i_pat_pregnancy pat_pregnancy identifier    
    * @param i_dt_ini        begin date
    * @param i_dt_fim        end date
    *
    * @return                values collection
    *
    * @author                Teresa Coutinho
    * @version               2.6.4.2
    * @since                 2014/10/02
    ***********************************************************************************************************/

    FUNCTION get_value_coll_fetus_pl
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_dt_ini        IN pat_pregnancy.dt_init_pregnancy%TYPE,
        i_dt_fim        IN pat_pregnancy.dt_init_pregnancy%TYPE
    ) RETURN t_coll_po_value_pl;

    /************************************************************************************************************
    * Inactivates empty time columns at flowsheets
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    *
    * @return               values collection
    *
    * @author               Teresa Coutinho
    * @version               2.6.4.2
    * @since                2014/10/01
    */
    FUNCTION set_po_param_reg_inactive
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get health programs grid.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_task_type    id task types
    * @param o_sets         Sets of indicators
    * @param o_param        parameters
    * @param o_sets_param   Sets of indicators parameters
    * @param o_time         times
    * @param o_value        values
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Teresa Coutinho
    * @version               2.6.4.3
    * @since                2014/12/15
    */
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
        o_values_wh  OUT t_coll_wh_values,
        o_ref        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_sets_coll
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_task_type IN table_varchar2,
        i_value     IN VARCHAR2 DEFAULT NULL
    ) RETURN t_coll_sets;

    FUNCTION get_param_sets
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_param     IN po_param.id_po_param%TYPE,
        i_owner     IN po_param.id_inst_owner%TYPE,
        i_sets      IN t_coll_sets,
        i_task_type IN table_varchar2
    ) RETURN pk_translation.t_desc_translation;

    FUNCTION get_grid_comm_order
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_id_comm_order_plan IN comm_order_plan.id_comm_order_plan%TYPE,
        i_id_po_param_reg    IN po_param_reg.id_po_param_reg%TYPE DEFAULT NULL,    
        i_id_comm_order_req  IN comm_order_req.id_comm_order_req%type,
        o_title              OUT VARCHAR2,
        o_sets               OUT pk_types.cursor_type,
        o_param              OUT pk_types.cursor_type,
        o_sets_param         OUT pk_types.cursor_type,
        o_time               OUT pk_types.cursor_type,
        o_value              OUT pk_types.cursor_type,
        o_values_wh          OUT t_coll_wh_values,
        o_ref                OUT pk_types.cursor_type,
        o_error              OUT t_error_out
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

    FUNCTION set_parameter_comm_order
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_id_comm_order_plan IN comm_order_plan.id_comm_order_plan%TYPE,
        i_id_po_param_reg    IN po_param_reg.id_po_param_reg%TYPE DEFAULT NULL,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_values_coll
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        i_po_param_reg   IN po_param_reg.id_po_param_reg%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    -- common use
    g_flg_yes CONSTANT VARCHAR2(1 CHAR) := pk_alert_constant.g_yes;
    g_flg_no  CONSTANT VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    g_yes     CONSTANT VARCHAR2(1 CHAR) := pk_alert_constant.g_yes;

    g_po_status_cancel CONSTANT periodic_observation_reg.flg_status%TYPE := 'C';
    g_po_status_active CONSTANT periodic_observation_reg.flg_status%TYPE := 'A';
    g_flg_type_reg     CONSTANT periodic_observation_reg.flg_type_reg%TYPE := 'O';
    g_flg_type_reg_s   CONSTANT periodic_observation_reg.flg_type_reg%TYPE := 'S';
    g_flg_mig_no       CONSTANT periodic_observation_reg.flg_mig%TYPE := 'N';

    -- parameter types
    g_habit      CONSTANT po_param.flg_type%TYPE := 'H';
    g_others     CONSTANT po_param.flg_type%TYPE := 'O';
    g_analysis   CONSTANT po_param.flg_type%TYPE := 'A';
    g_exam       CONSTANT po_param.flg_type%TYPE := 'E';
    g_vital_sign CONSTANT po_param.flg_type%TYPE := 'VS';
    g_biometric  CONSTANT event.flg_group%TYPE := 'PE';
    g_med_local  CONSTANT po_param.flg_type%TYPE := 'ML';
    g_med_ext    CONSTANT po_param.flg_type%TYPE := 'MX';

    -- parameter registration types
    g_ft_adv_input   CONSTANT po_param.flg_fill_type%TYPE := 'A'; -- used only for lab tests
    g_ft_keypad      CONSTANT po_param.flg_fill_type%TYPE := 'K'; -- works with "/"
    g_ft_multichoice CONSTANT po_param.flg_fill_type%TYPE := 'M'; -- single selection
    g_ft_multivalue  CONSTANT po_param.flg_fill_type%TYPE := 'V'; -- multiple selection
    g_ft_scale       CONSTANT po_param.flg_fill_type%TYPE := 'S'; -- pain scale
    g_free_text      CONSTANT po_param.flg_fill_type%TYPE := 'T'; -- pain scale
    g_free_date      CONSTANT po_param.flg_fill_type%TYPE := 'D'; -- pain scale

    -- Vital signs related variables
    g_vs_rel_conc CONSTANT vital_sign_relation.relation_domain%TYPE := pk_alert_constant.g_vs_rel_conc;
    g_vs_rel_sum  CONSTANT vital_sign_relation.relation_domain%TYPE := pk_alert_constant.g_vs_rel_sum;
    g_vs_bio      CONSTANT vital_sign.flg_vs%TYPE := 'V3';
    g_vs_vs       CONSTANT vital_sign.flg_vs%TYPE := 'V2';

    -- Analysis related variables
    g_ana_req_det_domain CONSTANT sys_domain.code_domain%TYPE := 'ANALYSIS_REQ_DET.FLG_STATUS';

    -- Exam related variables
    g_exam_req_status_domain CONSTANT sys_domain.code_domain%TYPE := 'EXAM_REQ_DET.FLG_STATUS';

    -- Medication related variables
    g_med_cell_text         CONSTANT VARCHAR2(1 CHAR) := 'T';
    g_med_cell_icon         CONSTANT VARCHAR2(1 CHAR) := 'I';
    g_per_obs_loader        CONSTANT application_file.file_name%TYPE := 'FlowSheetsLoaderViews';
    g_per_obs_preg_loader   CONSTANT application_file.file_name%TYPE := 'FlowSheetsLoaderViewsWomanHealth';
    g_per_obs_medical_order CONSTANT application_file.file_name%TYPE := 'CommunicationsFlowSheetsLoader';

    g_parameter_mother CONSTANT VARCHAR2(20 CHAR) := 'PARAMETER_MOTHER';
    g_parameter_fetus  CONSTANT VARCHAR2(20 CHAR) := 'PARAMETER_FETUS';
    g_flg_owner_m      preg_po_param.flg_owner%TYPE := 'M';
    g_flg_owner_f      preg_po_param.flg_owner%TYPE := 'F';
    g_flg_screen_po    po_param_reg.flg_screen%TYPE := 'PO';
    g_flg_screen_wh    po_param_reg.flg_screen%TYPE := 'WH';
    g_flg_domain_a     po_param.flg_domain%TYPE := 'A';
    g_flg_domain_f     po_param.flg_domain%TYPE := 'F';
    g_flg_domain_m     po_param.flg_domain%TYPE := 'M';
    g_flg_domain_o     po_param.flg_domain%TYPE := 'O'; --periodic observation normal grid
    g_ref_value        VARCHAR2(14 CHAR) := 'REF_VALUE';
    g_woman_health_det time_event_group.intern_name%TYPE := 'WOMAN_HEALTH_DET';

    -- Sets
    g_task_type_hpg           task_type.id_task_type%TYPE := 101;
    g_task_type_interv        task_type.id_task_type%TYPE := 10;
    g_task_type_exam          task_type.id_task_type%TYPE := 7;
    g_task_type_oth_exams     task_type.id_task_type%TYPE := 8;
    g_task_type_medical_order task_type.id_task_type%TYPE := 147;
    g_task_type_comm_order    task_type.id_task_type%TYPE := 83;
END pk_periodic_observation;
/
