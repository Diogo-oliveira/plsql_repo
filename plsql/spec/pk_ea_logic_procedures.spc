/*-- Last Change Revision: $Rev: 2028647 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:06 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ea_logic_procedures IS

    -- Author  : RITA.LOPES
    -- Created : 26/09/2008 9:23:44 AM
    -- Purpose : Easy access for procedures

    -- Public type declarations
    TYPE t_coll_procedures_ea IS TABLE OF ts_procedures_ea.procedures_ea_tc;

    /**
    * Calculate the status of procedure
    *
    * @param    i_lang                     Language id
    * @param    i_prof                     Professional
    * @param    i_episode                  Episode id
    * @param    i_flg_time                 Execution time flag
    * @param    i_flg_status_det           Detail status flag
    * @param    i_flg_prn                  PRN flag
    * @param    i_flg_referral             Referral flag
    * @param    i_dt_interv_prescription   Procedure order date
    * @param    i_dt_begin_req             Begin date
    * @param    i_dt_plan                  Planned date
    * @param    o_status_str               Status string
    * @param    o_status_msg               Status message
    * @param    o_status_icon              Status icon
    * @param    o_status_flg               Status flag
    *
    * @author   Pedro Teixeira
    * @version  2.4.3-Denormalized
    * @since    2008/10/08
    */

    PROCEDURE get_procedure_status
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN procedures_ea.id_episode%TYPE,
        i_flg_time               IN procedures_ea.flg_time%TYPE,
        i_flg_status_det         IN procedures_ea.flg_status_det%TYPE,
        i_flg_prn                IN procedures_ea.flg_prn%TYPE,
        i_flg_referral           IN procedures_ea.flg_referral%TYPE,
        i_dt_interv_prescription IN procedures_ea.dt_interv_prescription%TYPE,
        i_dt_begin_req           IN procedures_ea.dt_begin_req%TYPE,
        i_dt_plan                IN procedures_ea.dt_plan%TYPE,
        i_order_recurr_option    IN order_recurr_option.id_order_recurr_option%TYPE,
        o_status_str             OUT procedures_ea.status_str%TYPE,
        o_status_msg             OUT procedures_ea.status_msg%TYPE,
        o_status_icon            OUT procedures_ea.status_icon%TYPE,
        o_status_flg             OUT procedures_ea.status_flg%TYPE
    );

    FUNCTION get_procedure_status_str
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN procedures_ea.id_episode%TYPE,
        i_flg_time               IN procedures_ea.flg_time%TYPE,
        i_flg_status_det         IN procedures_ea.flg_status_det%TYPE,
        i_flg_prn                IN procedures_ea.flg_prn%TYPE,
        i_flg_referral           IN procedures_ea.flg_referral%TYPE,
        i_dt_interv_prescription IN procedures_ea.dt_interv_prescription%TYPE,
        i_dt_begin_req           IN procedures_ea.dt_begin_req%TYPE,
        i_dt_plan                IN procedures_ea.dt_plan%TYPE,
        i_order_recurr_option    IN order_recurr_option.id_order_recurr_option%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_procedure_status_msg
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN procedures_ea.id_episode%TYPE,
        i_flg_time               IN procedures_ea.flg_time%TYPE,
        i_flg_status_det         IN procedures_ea.flg_status_det%TYPE,
        i_flg_prn                IN procedures_ea.flg_prn%TYPE,
        i_flg_referral           IN procedures_ea.flg_referral%TYPE,
        i_dt_interv_prescription IN procedures_ea.dt_interv_prescription%TYPE,
        i_dt_begin_req           IN procedures_ea.dt_begin_req%TYPE,
        i_dt_plan                IN procedures_ea.dt_plan%TYPE,
        i_order_recurr_option    IN order_recurr_option.id_order_recurr_option%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_procedure_status_icon
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN procedures_ea.id_episode%TYPE,
        i_flg_time               IN procedures_ea.flg_time%TYPE,
        i_flg_status_det         IN procedures_ea.flg_status_det%TYPE,
        i_flg_prn                IN procedures_ea.flg_prn%TYPE,
        i_flg_referral           IN procedures_ea.flg_referral%TYPE,
        i_dt_interv_prescription IN procedures_ea.dt_interv_prescription%TYPE,
        i_dt_begin_req           IN procedures_ea.dt_begin_req%TYPE,
        i_dt_plan                IN procedures_ea.dt_plan%TYPE,
        i_order_recurr_option    IN order_recurr_option.id_order_recurr_option%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_procedure_status_flg
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN procedures_ea.id_episode%TYPE,
        i_flg_time               IN procedures_ea.flg_time%TYPE,
        i_flg_status_det         IN procedures_ea.flg_status_det%TYPE,
        i_flg_prn                IN procedures_ea.flg_prn%TYPE,
        i_flg_referral           IN procedures_ea.flg_referral%TYPE,
        i_dt_interv_prescription IN procedures_ea.dt_interv_prescription%TYPE,
        i_dt_begin_req           IN procedures_ea.dt_begin_req%TYPE,
        i_dt_plan                IN procedures_ea.dt_plan%TYPE,
        i_order_recurr_option    IN order_recurr_option.id_order_recurr_option%TYPE
    ) RETURN VARCHAR2;

    /**
    * Calculate the status of procedure execution
    *
    * @param    i_lang          Language id
    * @param    i_prof          Professional
    * @param    i_flg_status    Execution status flag
    * @param    i_dt_plan       Planned date
    * @param    o_status_str    Status string
    * @param    o_status_msg    Status message
    * @param    o_status_icon   Status icon
    * @param    o_status_flg    Status flag
    *
    * @author   Ana Matos
    * @version  2.7.1.0
    * @since    2017/02/03
    */

    PROCEDURE get_procedure_plan_status
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_status  IN interv_presc_plan.flg_status%TYPE,
        i_dt_plan     IN interv_presc_plan.dt_plan_tstz%TYPE,
        o_status_str  OUT VARCHAR2,
        o_status_msg  OUT VARCHAR2,
        o_status_icon OUT VARCHAR2,
        o_status_flg  OUT VARCHAR2
    );

    FUNCTION get_procedure_plan_status_str
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_status IN interv_presc_plan.flg_status%TYPE,
        i_dt_plan    IN interv_presc_plan.dt_plan_tstz%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_procedure_plan_status_msg
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_status IN interv_presc_plan.flg_status%TYPE,
        i_dt_plan    IN interv_presc_plan.dt_plan_tstz%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_procedure_plan_status_icon
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_status IN interv_presc_plan.flg_status%TYPE,
        i_dt_plan    IN interv_presc_plan.dt_plan_tstz%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_procedure_plan_status_flg
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_status IN interv_presc_plan.flg_status%TYPE,
        i_dt_plan    IN interv_presc_plan.dt_plan_tstz%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_procedure_status_all
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN procedures_ea.id_episode%TYPE,
        i_flg_time               IN procedures_ea.flg_time%TYPE,
        i_flg_status_det         IN procedures_ea.flg_status_det%TYPE,
        i_flg_prn                IN procedures_ea.flg_prn%TYPE,
        i_flg_referral           IN procedures_ea.flg_referral%TYPE,
        i_dt_interv_prescription IN procedures_ea.dt_interv_prescription%TYPE,
        i_dt_begin_req           IN procedures_ea.dt_begin_req%TYPE,
        i_dt_plan                IN procedures_ea.dt_plan%TYPE,
        i_order_recurr_option    IN order_recurr_option.id_order_recurr_option%TYPE
    ) RETURN table_ea_struct;

    /*
    * Updates the easy access table for procedures (procedures_ea)
    *
    * @param     i_lang                Language id
    * @param     i_prof                Professional
    * @param     i_event_type          Event type
    * @param     i_rowids              Row ids
    * @param     i_source_table_name   Source table name
    * @param     i_list_columns        List of columns
    * @param     i_dg_table_name       Target table name
    
    *
    * @author    João Martins
    * @version   2.4.3-Denormalized
    * @since     2008/09/30
    */

    PROCEDURE set_procedures
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    FUNCTION set_grid_task_procedures_across
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Sets the grid task table
    *
    * @param     i_lang                Language id
    * @param     i_prof                Professional
    * @param     i_event_type          Event type
    * @param     i_rowids              Row ids
    * @param     i_source_table_name   Source table name
    * @param     i_list_columns        List of columns
    * @param     i_dg_table_name       Target table name
    
    *
    * @author    Ana Matos
    * @version   2.6.5.1
    * @since     2015/11/12
    */

    PROCEDURE set_grid_task_procedures
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /*
    * Updates procedures information in the Task timeline easy access table (task_timeline_ea)
    *
    * @param     i_lang                Language id
    * @param     i_prof                Professional
    * @param     i_event_type          Event type
    * @param     i_rowids              Row ids
    * @param     i_source_table_name   Source table name
    * @param     i_list_columns        List of columns
    * @param     i_dg_table_name       Target table name
    
    *
    * @author    Luís Maia
    * @version   2.6
    * @since     2009/04/21
    */

    PROCEDURE set_task_timeline_proced
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /*
    * Sets the timeline table
    *
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_event_type     Event type
    * @param     i_rowids         Row ids
    * @param     i_src_table      Source table name
    * @param     i_list_columns   List of columns
    * @param     i_dg_table       Target table name
    
    *
    * @author    Pedro Carneiro
    * @version   2.6.2
    * @since     2012/05/02
    */

    PROCEDURE set_task_timeline_proc_notes
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_event_type   IN VARCHAR2,
        i_rowids       IN table_varchar,
        i_src_table    IN VARCHAR2,
        i_list_columns IN table_varchar,
        i_dg_table     IN VARCHAR2
    );

    /*
    * Sets the timeline table
    *
    * @param     i_lang                Language id
    * @param     i_prof                Professional
    * @param     i_event_type          Event type
    * @param     i_rowids              Row ids
    * @param     i_source_table_name   Source table name
    * @param     i_list_columns        List of columns
    * @param     i_dg_table_name       Target table name
    
    *
    * @author    Nuno Neves
    * @version   2.6.2
    * @since     2012/11/16
    */

    PROCEDURE set_task_timeline
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    ---------------------------------------- GLOBAL VALUES ----------------------------------------------

    /* Package name */
    g_package_name  VARCHAR2(32);
    g_package_owner VARCHAR2(32);

    /* Error tracking */
    g_error VARCHAR2(4000);

    /* Invalid event type */
    g_excp_invalid_event_type EXCEPTION;

END pk_ea_logic_procedures;
/
