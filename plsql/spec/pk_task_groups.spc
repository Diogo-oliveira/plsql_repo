/*-- Last Change Revision: $Rev: 2055401 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2023-02-22 09:43:55 +0000 (qua, 22 fev 2023) $*/

CREATE OR REPLACE PACKAGE pk_task_groups IS

    -- Purpose : Group categories database package

    /********************************************************************************************
    * initialize parameters for task groups list filter (auto-generated code)
    *
    * @author       Tiago Silva
    * @since        2013/05/20   
    ********************************************************************************************/
    PROCEDURE init_params_groups_list_filter
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

    /********************************************************************************************
    * create a new task group
    *
    * @param       i_lang                 preferred language id for this professional
    * @param       i_prof                 professional id structure
    * @param       i_name                 task group name
    * @param       i_author               task group author
    * @param       i_flg_status           task group status
    * @param       i_notes                task group notes
    * @param       o_new_group_task_id    created task group id
    * @param       o_error                error message    
    *
    * @return      boolean                true or false on success or error
    *
    * @value       i_flg_status           {*} 'A' active task group
    *                                     {*} 'I' inactive task group       
    *
    * @author                             Tiago Silva
    * @since                              2013/05/22
    ********************************************************************************************/
    FUNCTION create_task_group
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_name              IN VARCHAR2,
        i_author            IN VARCHAR2,
        i_flg_status        IN VARCHAR2,
        i_notes             IN VARCHAR2,
        o_new_group_task_id OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * update/edit a task group
    *
    * @param       i_lang                 preferred language id for this professional
    * @param       i_prof                 professional id structure
    * @param       i_task_group           id of the task group to edit
    * @param       i_name                 new task group name
    * @param       i_author               new task group author
    * @param       i_flg_status           new task group status
    * @param       i_notes                new task group notes
    * @param       o_error                error message    
    *
    * @return      boolean                true or false on success or error
    *
    * @value       i_flg_status           {*} 'A' active task group
    *                                     {*} 'I' inactive task group      
    *
    * @author                             Tiago Silva
    * @since                              2013/05/22
    ********************************************************************************************/
    FUNCTION update_task_group
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_task_group IN NUMBER,
        i_name          IN VARCHAR2,
        i_author        IN VARCHAR2,
        i_flg_status    IN VARCHAR2,
        i_notes         IN VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * cancel task group
    *
    * @param       i_lang                 preferred language id for this professional
    * @param       i_prof                 professional id structure
    * @param       i_task_group           task group to cancel
    * @param       i_id_cancel_reason     reason to cancel the task groups
    * @param       i_cancel_notes         cancel notes
    * @param       o_error                error message    
    *
    * @return      boolean                true or false on success or error
    *
    * @author                             Tiago Silva
    * @since                              2013/05/22
    ********************************************************************************************/
    FUNCTION cancel_task_group
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_group       IN task_group.id_task_group%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes     IN task_group.cancel_notes%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * set task groups status
    *
    * @param       i_lang                 preferred language id for this professional
    * @param       i_prof                 professional id structure
    * @param       i_task_groups          list of task groups to set status
    * @param       i_flg_status           new task group status
    * @param       o_error                error message    
    *
    * @return      boolean                true or false on success or error
    *
    * @value       i_flg_status           {*} 'A' active task group
    *                                     {*} 'I' inactive task group          
    *
    * @author                             Tiago Silva
    * @since                              2013/05/22
    ********************************************************************************************/
    FUNCTION set_task_groups_status
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_task_groups IN table_number,
        i_flg_status  IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get task group data
    *
    * @param       i_lang                 preferred language id for this professional
    * @param       i_prof                 professional id structure
    * @param       i_task_group           id of the task group
    * @param       o_task_group_data      cursor with all task group data
    * @param       o_error                error message    
    *
    * @return      boolean                true or false on success or error
    *
    * @author                             Tiago Silva
    * @since                              2013/05/22
    ********************************************************************************************/
    FUNCTION get_task_group_data
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_task_group   IN NUMBER,
        o_task_group_data OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * set task groups ranks
    *
    * @param       i_lang                 preferred language id for this professional
    * @param       i_prof                 professional id structure
    * @param       i_task_groups          list of task groups to set rank
    * @param       i_ranks                list of ranks   
    * @param       o_error                error message    
    *
    * @return      boolean                true or false on success or error
    *
    * @author                             Tiago Silva
    * @since                              2013/05/24
    ********************************************************************************************/
    FUNCTION set_task_groups_rank
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_task_groups IN table_number,
        i_ranks       IN table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get ranks list to assign to the task groups
    *
    * @param       i_lang            preferred language id for this professional
    * @param       i_prof            professional id structure
    * @param       o_ranks_list      cursor with the list of ranks
    * @param       o_error           error message    
    *
    * @return      boolean           true or false on success or error
    *
    * @author                        Tiago Silva
    * @since                         2013/05/24
    ********************************************************************************************/
    FUNCTION get_ranks_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_ranks_list OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_task_group
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_tbl_id_pk            IN table_number,
        i_tbl_ds_internal_name IN table_varchar,
        i_tbl_real_val         IN table_table_varchar,
        i_flg_update           IN VARCHAR2,
        o_group_task_id        OUT NUMBER,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_task_group_form_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER,
        i_root_name      IN VARCHAR2,
        i_curr_component IN NUMBER,
        i_idx            IN NUMBER DEFAULT 1,
        i_tbl_id_pk      IN table_number,
        i_tbl_mkt_rel    IN table_number,
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        i_value_mea      IN table_table_varchar,
        i_value_desc     IN table_table_varchar,
        i_tbl_data       IN table_table_varchar,
        i_value_clob     IN table_clob,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value;

    FUNCTION get_task_group_detail
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_task_group IN NUMBER,
        o_detail        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************/
    /********************************************************************************************/
    /********************************************************************************************/

    g_module CONSTANT VARCHAR2(30) := 'TASK_GROUPS';

    -- task group flag status
    g_flg_active   CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_flg_inactive CONSTANT VARCHAR2(1 CHAR) := 'I';
    g_flg_canceled CONSTANT VARCHAR2(1 CHAR) := 'C';

    g_task_group_edit CONSTANT NUMBER(24) := 215231;

END pk_task_groups;
/
