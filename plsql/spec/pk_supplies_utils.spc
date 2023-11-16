/*-- Last Change Revision: $Rev: 2045835 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2022-09-22 08:43:34 +0100 (qui, 22 set 2022) $*/

CREATE OR REPLACE PACKAGE pk_supplies_utils IS

    FUNCTION create_supply_workflow
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_area     IN supply_area.id_supply_area%TYPE,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_supply_request  IN supply_request.id_supply_request%TYPE,
        i_supply             IN table_number,
        i_supply_set         IN table_number,
        i_supply_qty         IN table_number,
        i_supply_loc         IN table_number,
        i_flg_status         IN table_varchar,
        i_dt_request         IN table_varchar,
        i_dt_return          IN table_varchar,
        i_id_req_reason      IN table_number,
        i_id_context         IN supply_request.id_context%TYPE,
        i_flg_context        IN supply_request.flg_context%TYPE,
        i_notes              IN table_varchar,
        i_id_inst_dest       IN institution.id_institution%TYPE DEFAULT NULL,
        i_sup_wkflow_parent  IN supply_workflow.id_sup_workflow_parent%TYPE DEFAULT NULL,
        i_lot                IN table_varchar DEFAULT NULL,
        i_barcode_scanned    IN table_varchar DEFAULT NULL,
        i_dt_expiration      IN table_varchar DEFAULT NULL,
        i_flg_validation     IN table_varchar DEFAULT NULL,
        o_id_supply_workflow OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_supply_rqt
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_supply_area    IN supply_area.id_supply_area%TYPE,
        i_id_episode        IN episode.id_episode%TYPE,
        i_flg_reason_req    IN supply_request.flg_reason%TYPE DEFAULT 'O',
        i_id_context        IN supply_request.id_context%TYPE,
        i_flg_context       IN supply_request.flg_context%TYPE,
        i_supply_flg_status IN supply_request.flg_status%TYPE,
        i_supply_dt_request IN supply_request.dt_request%TYPE,
        o_id_supply_request OUT supply_request.id_supply_request%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE set_supply_request_hist(i_id_supply_request IN supply_request.id_supply_request%TYPE);

    PROCEDURE set_supply_workflow_hist
    (
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE,
        i_id_context         IN supply_workflow.id_context%TYPE,
        i_flg_context        IN supply_workflow.flg_context%TYPE
    );

    PROCEDURE set_supply_wf_hist_quant
    (
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE,
        i_flg_status         IN supply_workflow.flg_status%TYPE DEFAULT NULL
    );

    PROCEDURE set_supply_wf_hist_outd
    (
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE,
        i_flg_status         IN supply_workflow.flg_status%TYPE DEFAULT NULL
    );

    FUNCTION set_history
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE,
        i_flg_edition        IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_outdate        IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_status         IN supply_workflow.flg_status%TYPE DEFAULT NULL,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_edit_loans
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_supply_workflow  IN table_number,
        i_supply_qty       IN table_number,
        i_dt_return        IN table_varchar,
        i_barcode_scanned  IN table_varchar,
        i_asset_nr_scanned IN table_varchar,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_active_wf_parent
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_supply_wf_parent IN supply_workflow.id_supply_workflow%TYPE,
        i_supply_workflow  IN supply_workflow.id_supply_workflow%TYPE,
        i_quantity_parent  IN supply_workflow.quantity%TYPE,
        i_quantity_child   IN supply_workflow.quantity%TYPE,
        i_cancel_notes     IN supply_workflow.notes_cancel%TYPE,
        i_id_cancel_reason IN supply_workflow.id_cancel_reason%TYPE,
        i_flg_edition      IN VARCHAR2,
        i_dt_return        IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_upd_and_insert
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN supply_workflow.id_episode%TYPE,
        i_supply_workflow_upd IN supply_workflow.id_supply_workflow%TYPE,
        i_quantity_upd        IN supply_workflow.quantity%TYPE,
        --info to be inserted        
        i_id_supply            IN supply_workflow.id_supply%TYPE,
        i_id_supply_set        IN supply_workflow.id_supply_set%TYPE,
        i_barcode_scanned      IN supply_workflow.barcode_scanned%TYPE,
        i_quantity             IN supply_workflow.quantity%TYPE,
        i_total_quantity       IN supply_workflow.total_quantity%TYPE,
        i_id_context           IN supply_workflow.id_context%TYPE,
        i_flg_context          IN supply_workflow.flg_context%TYPE,
        i_flg_status           IN supply_workflow.flg_status%TYPE,
        i_flg_edited           IN supply_workflow.flg_outdated%TYPE,
        i_dt_returned          IN supply_workflow.dt_returned%TYPE,
        i_notes                IN supply_workflow.notes%TYPE,
        i_notes_cancel         IN supply_workflow.notes_cancel%TYPE,
        i_id_cancel_reason     IN supply_workflow.id_cancel_reason%TYPE,
        i_dt_cancel            IN supply_workflow.dt_cancel%TYPE,
        i_total_avail_quantity IN supply_workflow.total_avail_quantity%TYPE,
        o_id_supply_workflow   OUT supply_workflow.id_supply_workflow%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_partial_deliver
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_supply_wf_parent IN supply_workflow.id_supply_workflow%TYPE,
        i_id_supply_workflow  IN supply_workflow.id_supply_workflow%TYPE,
        i_supply_qty          IN supply_workflow.quantity%TYPE,
        i_id_episode          IN supply_workflow.id_episode%TYPE,
        i_r_supply_workflow   IN supply_workflow%ROWTYPE,
        i_current_timestamp   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_edition         IN VARCHAR2,
        i_old_quantity        IN supply_workflow.quantity%TYPE,
        i_dt_return           IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_barcode_scanned     IN supply_workflow.barcode_scanned%TYPE,
        i_asset_nr_scanned    IN supply_workflow.asset_number%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_complete_deliver
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_supply_wf_parent IN supply_workflow.id_supply_workflow%TYPE,
        i_id_supply_workflow  IN supply_workflow.id_supply_workflow%TYPE,
        i_supply_qty          IN supply_workflow.quantity%TYPE,
        i_current_timestamp   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_edition         IN VARCHAR2,
        i_dt_return           IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_barcode_scanned     IN supply_workflow.barcode_scanned%TYPE,
        i_asset_nr_scanned    IN supply_workflow.asset_number%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_cancel_deliver
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_supplies_workflow IN table_number,
        i_cancel_notes      IN supply_workflow.notes_cancel%TYPE,
        i_id_cancel_reason  IN supply_workflow.id_cancel_reason%TYPE,
        i_flg_edition       IN VARCHAR2,
        i_quantities        IN table_number,
        i_dt_return         IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_flg_show          OUT VARCHAR2,
        o_msg               OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_delivery
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_supply_workflow  IN table_number,
        i_supply_qty       IN table_number,
        i_dt_return        IN table_varchar DEFAULT NULL,
        i_id_episode       IN supply_workflow.id_episode%TYPE,
        i_flg_edition      IN VARCHAR2,
        i_barcode_scanned  IN table_varchar,
        i_asset_nr_scanned IN table_varchar,
        o_flg_show         OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_status_req
    (
        i_prof               IN profissional,
        i_id_supply_location IN supply_location.id_supply_location%TYPE
    ) RETURN supply_workflow.flg_status%TYPE;

    FUNCTION get_ini_status_supply_wf
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_area     IN supply_area.id_supply_area%TYPE,
        i_id_supply_location IN supply_location.id_supply_location%TYPE,
        i_id_supply_set      IN supply_workflow.id_supply_set%TYPE,
        i_id_supply          IN supply_workflow.id_supply%TYPE,
        i_sup_interface      IN sys_config.value%TYPE,
        i_id_inst_dest       IN institution.id_institution%TYPE DEFAULT NULL
    ) RETURN supply_workflow.flg_status%TYPE;

    /*
    * Returns the supply_request associated to a procedure.
    * 
    * @i_lang  Language ID
    * @i_prof  Professional's info
    * @i_id_episode Episode
    * @i_id_context   Context id
    * @i_flg_context  Context flg
    * 
    * @return  supply request ID
    * 
    * @author  João Almeida
    * @version 2.5.0.7
    * @since   23/11/09
    */

    FUNCTION get_supply_by_context
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_context IN supply_request.id_context%TYPE,
        o_supply     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_total_avail_quantity
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_supply_area IN supply_area.id_supply_area%TYPE,
        i_id_supply      IN supply.id_supply%TYPE,
        i_flg_cons_type  IN supply_soft_inst.flg_cons_type%TYPE,
        i_id_episode     IN episode.id_episode%TYPE
    ) RETURN supply_soft_inst.total_avail_quantity%TYPE;

    FUNCTION get_count_hist
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE,
        o_count_hist         OUT PLS_INTEGER,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_nr_editable_units
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_supply_workflow_prt IN supply_workflow.id_supply_workflow%TYPE,
        i_id_supply_workflow  IN supply_workflow.id_supply_workflow%TYPE,
        i_supply_workflow     IN table_number,
        i_supply_qty          IN table_number,
        o_nr_units            OUT supply_workflow.quantity%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_desc_supplies
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_supplies   IN table_number,
        o_desc_supplies OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_canc_deliveries_msgs
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_supplies IN table_number,
        o_flg_show    OUT VARCHAR2,
        o_msg         OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_hist_return_date
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN supply_workflow_hist.id_supply_workflow%TYPE,
        o_return_date        OUT supply_workflow_hist.dt_returned%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_supply_soft_inst
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_supply_soft_inst IN table_number,
        o_flg_cons_type    OUT table_varchar,
        o_flg_reusable     OUT table_varchar,
        o_flg_editable     OUT table_varchar,
        o_flg_preparing    OUT table_varchar,
        o_flg_countable    OUT table_varchar,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_edit_reopen_epis
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_supply_workflow IN table_number,
        i_supply_qty      IN table_number,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_cancel_deliver
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_supply           IN supply.id_supply%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_supply_workflow     IN table_number,
        io_supplies_no_cancel /*NOCOPY*/ IN OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE get_supplies_init_parameters
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

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_user_exception  EXCEPTION;
    g_other_exception EXCEPTION;
    g_error VARCHAR2(4000);

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

END pk_supplies_utils;
/
