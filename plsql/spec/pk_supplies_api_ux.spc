/*-- Last Change Revision: $Rev: 2045844 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2022-09-22 10:25:09 +0100 (qui, 22 set 2022) $*/
CREATE OR REPLACE PACKAGE pk_supplies_api_ux IS

    /*
    * Creates a supply order
    * 
    * @param     i_lang                Language id
    * @param     i_prof                Professional
    * @param     i_id_episode          Episode id
    * @param     i_supply              Supply id
    * @param     i_supply_set          Parent supply set (if applicable)
    * @param     i_supply_qty          Supply quantity
    * @param     i_supply_loc          Supply location
    * @param     i_dt_request          Date of request
    * @param     i_dt_return           Estimated date of of return
    * @param     i_id_req_reason       Reasons for each supply
    * @param     i_flg_reason_req      Reason for request
    * @param     i_id_context          Context id
    * @param     i_flg_context         Flag that indicates the supply context
    * @param     i_notes               Request notes
    * @param     i_supply_soft_inst    List
    * @param     o_id_supply_request   Supply request id
    * @param     o_error               Error message
    
    * @return    true or false on success or error
    * 
    * @author    Jorge Canossa
    * @version   2.5
    * @since     2010/10/13
    */

    FUNCTION create_supply_order
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_supply            IN table_number,
        i_supply_set        IN table_number,
        i_supply_qty        IN table_number,
        i_supply_loc        IN table_number,
        i_dt_request        IN table_varchar,
        i_dt_return         IN table_varchar,
        i_id_req_reason     IN table_number,
        i_flg_reason_req    IN supply_request.flg_reason%TYPE DEFAULT 'O',
        i_id_context        IN table_number,
        i_flg_context       IN table_varchar,
        i_notes             IN table_varchar,
        o_id_supply_request OUT supply_request.id_supply_request%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Registers the consumption of supplies
    * 
    * @param     i_lang                 Language id
    * @param     i_prof                 Professional
    * @param     i_id_episode           Episode id
    * @param     i_id_context           Context id
    * @param     i_flg_context          Flag that indicates the supply context
    * @param     i_id_supply_workflow   Supply workflow id
    * @param     i_supply               Supplies' id
    * @param     i_supply_set           Parent supply set (if applicable)
    * @param     i_supply_qty           Supply quantities
    * @param     i_flg_supply_type      Supply or supply Kit
    * @param     i_barcode_scanned      Barcode scanned
    * @param     i_deliver_needed       Deliver needed
    * @param     i_flg_cons_type        Consumption type
    * @param     i_dt_expected_date     Expected return date
    * @param     o_error                Error message
    
    * @return    true or false on success or error
    * 
    * @author    Joao Martins
    * @version   2.5.0.7
    * @since     2009/10/25
    */

    FUNCTION create_supply_with_consumption
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_context         IN supply_workflow.id_context%TYPE,
        i_flg_context        IN supply_workflow.flg_context%TYPE,
        i_id_supply_workflow IN table_number,
        i_supply             IN table_number,
        i_supply_set         IN table_number,
        i_supply_qty         IN table_number,
        i_flg_supply_type    IN table_varchar,
        i_barcode_scanned    IN table_varchar,
        i_fixed_asset_number IN table_varchar,
        i_deliver_needed     IN table_varchar,
        i_flg_cons_type      IN table_varchar,
        i_notes              IN table_varchar,
        i_dt_expected_date   IN table_varchar,
        i_check_quantities   IN VARCHAR2,
        i_dt_expiration      IN table_varchar,
        i_flg_validation     IN table_varchar,
        i_lot                IN table_varchar,
        i_test               IN VARCHAR2,
        o_flg_show           OUT VARCHAR2,
        o_msg_title          OUT VARCHAR2,
        o_msg                OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Set a supply to a prepared status
    * 
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_supplies           Supplies
    * @param     i_unic_id            Unic identifier of the supply 
    * @param     i_prepared_by        Profissional who prepared the supply
    * @param     i_prep_notes         Peparation notes
    * @param     i_new_supplies       New supplies to replace existing ones
    * @param     i_qty_dispensed      Quantity dispensed
    * @param     o_error              Error message
    
    * @return    true or false on success or error
    * 
    * @author    Jo�o Almeida
    * @version   2.5.0.7
    * @since     2009/11/16
    */

    FUNCTION set_supply_preparation
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_supplies      IN table_number,
        i_id_patient    IN patient.id_patient%TYPE,
        i_unic_id       IN table_number,
        i_prepared_by   IN table_varchar,
        i_prep_notes    IN table_varchar,
        i_new_supplies  IN table_number,
        i_qty_dispensed IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Edit a supply - it is possible to update the quantity and/or the return date
    * 
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_id_episode         Episode id
    * @param     i_supply_workflow    Supply_workflow id,    
    * @param     i_dt_return          Estimated date of return
    * @param     i_barcode_scanned    Barcode scanned
    * @param     i_asset_nr_scanned   Fixed asset number scanned
    * @param     i_flg_test           Flag that indicates if the episode needs to be reopened
    * @param     o_flg_show           Flag that indicates if there is a message to be shown
    * @param     o_msg                Message to be shown
    * @param     o_msg_title          Message title  
    * @param     o_error              Error message
    
    * @return    true or false on success or error
    * 
    * @author    Sofia Mendes
    * @version   2.6.0.3
    * @since     2010/05/31
    */

    FUNCTION set_supply_order
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_flg_test         IN VARCHAR2,
        i_supply_workflow  IN table_number,
        i_supply_qty       IN table_number,
        i_dt_return        IN table_varchar,
        i_barcode_scanned  IN table_varchar,
        i_asset_nr_scanned IN table_varchar,
        o_flg_show         OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Set supply consumption
    * 
    * @param     i_lang                 Language id
    * @param     i_prof                 Professional
    * @param     i_id_supply_workflow   Supply workflow id
    * @param     o_error                Error message
    
    * @return    true or false on success or error
    *
    * @author    Filipe Silva
    * @version   2.6.0.4
    * @since     2010/12/16
    */

    FUNCTION set_supplies_consume --set_supply_consumption
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Sets a supply request's status 
    * 
    * @param     i_lang       Language id
    * @param     i_prof       Professional
    * @param     i_supplies   List of supplies
    * @param     o_error      Error message
    
    * @return    true or false on success or error
    * 
    * @author    Pedro Henriques
    * @version   2.7.3.0
    * @since     2018/03/19
    */

    FUNCTION set_supply_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_supplies   IN table_number,
        i_flg_status IN supply_workflow.flg_status%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Function to deliver supplies
    * 
    * @param     i_lang              Language id
    * @param     i_prof              Professional
    * @param     i_supply_workflow   Supply workflow id list
    * @param     i_supply_qty        Units that are being delivered for each loan
    * @param     i_id_episode        Episode id    
    * @param     o_flg_show          Flag that indicates if there is a message to be shown
    * @param     o_msg               Message to be shown
    * @param     o_msg_title         Message title
    * @param     o_error             Error message
    
    * @return    true or false on success or error
    * 
    * @author    Sofia Mendes
    * @version   2.6.0.3
    * @since     2010/05/21
    */

    FUNCTION set_supply_delivery
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_supply_workflow IN table_number,
        i_supply_qty      IN table_number,
        i_id_episode      IN supply_workflow.id_episode%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_supply_delivery_confirmation
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_supply_workflow IN table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Set a supply to a conclude devolution status
    * 
    * @param     i_lang       Language id
    * @param     i_prof       Professional
    * @param     i_supplies   List of supplies
    * @param     i_barcode    Barcode
    * @param     o_error      Error message
    
    * @return    true or false on success or error
    * 
    * @author    Jo�o Almeida
    * @version   2.5.0.7
    * @since     2009/11/16
    */

    FUNCTION set_supply_devolution
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_supplies IN table_number,
        i_barcode  IN table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Rejects a supply, indicating the rejection reason
    * 
    * @param     i_lang                 Language id
    * @param     i_prof                 Professional
    * @param     i_id_supply_workflow   Supply workflow id
    * @param     i_rejection_notes      Rejection notes
    * @param     o_error                Error message
    
    * @return    true or false on success or error
    * 
    * @author    Jo�o Almeida
    * @version   2.5.0.7
    * @since     2009/10/28
    */

    FUNCTION set_supply_reject
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN supply_workflow.id_episode%TYPE,
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE,
        i_rejection_notes    IN supply_workflow.notes_reject%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * The user may skip the workflow "Ordered to Central Stock" directly to "Ready for preparation" status
    * by choosing  the "Ready for preparation" action in the action button.
    * 
    * @param    i_lang                 Language id
    * @param    i_prof                 Professional
    * @param    i_id_supply_workflow   Table number with supply workflow ID
    * @param    o_id_supply_workflow   Table number with supply workflow ID
    * @param    o_error                Error message
    
    * @return    true or false on success or error
    *
    * @author    Filipe Silva
    * @version   2.6.0.4
    * @since     2010/10/19
    */

    FUNCTION set_ready_for_preparation
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN table_number,
        o_id_supply_workflow OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Sets the need for deliver in a given supply request
    * 
    * @param     i_lang              Language id
    * @param     i_prof              Professional
    * @param     i_supply_workflow   Supply workflow id
    * @param     o_error             Error message
    
    * @return    true or false on success or error
    * 
    * @author    Joao Martins
    * @version   2.5.0.7
    * @since     2009/10/26
    */

    FUNCTION set_supply_for_delivery
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_supplies   IN table_number,
        i_reason     IN table_number,
        i_notes      IN table_varchar,
        i_id_episode IN supply_workflow.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Edit a supply
    * 
    * @param     i_lang                Language id
    * @param     i_prof                Professional
    * @param     i_id_episode          Episode id
    * @param     i_supply_workflow     Supply_workflow id,
    * @param     i_flg_status          Status,
    * @param     i_supply              Supply id
    * @param     i_supply_set          Parent supply set (if applicable)
    * @param     i_supply_qty          Supply quantity
    * @param     i_supply_loc          Supply location
    * @param     i_dt_request          Date of request
    * @param     i_dt_return           Estimated date of of return
    * @param     i_id_req_reason       Reasons for each supply
    * @param     i_flg_reason_req      Reason for request
    * @param     i_id_context          Request's context id
    * @param     i_flg_context         Flag that indicates the supply context
    * @param     i_notes               Request notes
    * @param     o_id_supply_request   Created request id
    * @param     o_error               Error message
    
    * @return    true or false on success or error
    * 
    * @author    Jo�o Almeida
    * @version   2.5.0.7
    * @since     2009/12/10
    */

    FUNCTION update_supply_order
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_supply_workflow IN table_number,
        i_supply          IN table_number,
        i_supply_set      IN table_number,
        i_supply_qty      IN table_number,
        i_supply_loc      IN table_number,
        i_dt_request      IN table_varchar,
        i_dt_return       IN table_varchar,
        i_id_req_reason   IN table_number,
        i_flg_reason_req  IN supply_request.flg_reason%TYPE DEFAULT 'O',
        i_id_context      IN supply_request.id_context%TYPE,
        i_flg_context     IN supply_request.flg_context%TYPE,
        i_notes           IN table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /*
    * Update supply workflow
    * 
    * @param     i_lang                Language id
    * @param     i_prof                Professional
    * @param     i_id_episode           ID episode
    * @param     i_id_supply_workflow   ID supply workflow
    * @param     i_flg_status           Flag status  
    * @param     i_supply               ID supply
    * @param     i_supply_set           Parent supply set (if applicable)
    * @param     i_supply_qty           Supply quantity
    * @param     i_supply_loc           Supply location
    * @param     i_dt_request           Date of request
    * @param     i_id_req_reason        Reasons for each supply
    * @param     i_id_context           Request's context ID
    * @param     i_flg_context          Request's context
    * @param     i_notes                Request notes
    * @param     i_flg_cons_type        Flag of consumption type
    * @param     i_cod_table            Code table
    * @param     o_id_supply_request    Created Request ID
    * @param     o_error                Error message
    
    * @return    true or false on success or error
    *
    * @author    Filipe Silva
    * @version   2.6.0.4
    * @since     2010/11/23
    */

    FUNCTION update_supply_workflow
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_supply_workflow IN table_number,
        i_supply          IN table_number,
        i_supply_set      IN table_number,
        i_supply_qty      IN table_number,
        i_supply_loc      IN table_number,
        i_dt_request      IN table_varchar,
        i_dt_return       IN table_varchar,
        i_id_req_reason   IN table_number,
        i_id_context      IN table_number,
        i_flg_context     IN table_varchar,
        i_notes           IN table_varchar,
        i_flg_cons_type   IN table_varchar,
        i_cod_table       IN table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Cancels a supply, indicating the cancelation reason
    * 
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_supplies           Supplies id
    * @param     i_id_episode         Episode id
    * @param     i_cancel_notes       Cancellation notes
    * @param     i_id_cancel_reason   Cancel reason id
    * @param     o_error              Error message
    
    * @return    true or false on success or error
    * 
    * @author    Jo�o Almeida
    * @version   2.5.0.7
    * @since     2009/10/28
    */

    FUNCTION cancel_supply_order
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_supplies         IN table_number,
        i_cancel_notes     IN supply_workflow.notes_cancel%TYPE,
        i_id_cancel_reason IN supply_workflow.id_cancel_reason%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Cancels a supply devolution
    * 
    * @param     i_lang                Language id
    * @param     i_prof                Professional
    * @param     i_id_episode          Episode id
    * @param     i_flg_test            Flag that indicates if the episode is to be reopened
    * @param     i_supplies_workflow   Supplies to be cancelled    
    * @param     i_cancel_notes        Cancel notes
    * @param     i_id_cancel_reason    Cancel reason
    * @param     o_flg_show            Flag that indicates if there is a message to be shown
    * @param     o_msg                 Message to tbe shown
    * @param     o_msg_title           Message title
    * @param     o_error               Error message
    
    * @return    true or false on success or error
    * 
    * @author    Sofia Mendes
    * @version   2.6.0.3
    * @since     2010/05/31
    */

    FUNCTION cancel_supply_deliver
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_flg_test          IN VARCHAR2,
        i_supplies_workflow IN table_number,
        i_cancel_notes      IN supply_workflow.notes_cancel%TYPE,
        i_id_cancel_reason  IN supply_workflow.id_cancel_reason%TYPE,
        o_flg_show          OUT VARCHAR2,
        o_msg               OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Cancels a loaned supply
    * 
    * @param     i_lang                Language id
    * @param     i_prof                Professional
    * @param     i_supplies_workflow   Supplies to be cancelled    
    * @param     i_id_episode          Episode id
    * @param     i_cancel_notes        Cancel notes
    * @param     i_id_cancel_reason    Cancel reason
    * @param     o_flg_show            Flag that indicates if there is a message to be shown
    * @param     o_msg                 Message to tbe shown
    * @param     o_msg_title           Message title
    * @param     o_error               Error message
    
    * @return    true or false on success or error
    * 
    * @author    Sofia Mendes
    * @version   2.6.0.3
    * @since     2010/06/02
    */

    FUNCTION cancel_supply_loan
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_supplies_workflow IN table_number,
        i_id_episode        IN supply_workflow.id_episode%TYPE,
        i_cancel_notes      IN supply_workflow.notes_cancel%TYPE,
        i_id_cancel_reason  IN supply_workflow.id_cancel_reason%TYPE,
        o_flg_show          OUT VARCHAR2,
        o_msg               OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list with the selectable types (e.g. supplies, kits or sets)
    * 
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_id_supply_area     Supply area id
    * @param     i_episode            Episode id
    * @param     i_consumption_type   Consumption type
    * @param     o_selection_list     Cursor
    * @param     o_error              Error message
    
    * @return    true or false on success or error
    * 
    * @author    Susana Silva
    * @version   2.5.0.7
    * @since     2009/11/03
    */

    FUNCTION get_supply_selection_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_supply_area   IN supply_area.id_supply_area%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_consumption_type IN supply_soft_inst.flg_cons_type%TYPE,
        i_id_inst_dest     IN institution.id_institution%TYPE,
        o_selection_list   OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the items configurated
    * 
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_episode            Episode id
    * @param     i_consumption_type   Consumption type
    * @param     i_flg_type           Flag type
    * @param     i_id_supply          Supply identification
    * @param     i_id_supply_type     Supply Type identification    
    * @param     o_supply_inf         Cursor
    * @param     o_supply_type        Cursor
    * @param     o_supply_items       Cursor
    * @param     o_flg_selected       Flag indicates when the supplies must be selected
    * @param     o_error              Error message
    
    * @return    true or false on success or error
    * 
    * @author    Jorge Canossa
    * @version   2.5
    * @since     2010/11/07
    */

    FUNCTION get_supply_for_selection
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_supply_area   IN supply_area.id_supply_area%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_consumption_type IN supply_soft_inst.flg_cons_type%TYPE,
        i_flg_type         IN supply.flg_type%TYPE,
        i_id_supply        IN supply.id_supply%TYPE,
        i_id_supply_type   IN supply.id_supply_type%TYPE,
        i_id_inst_dest     IN institution.id_institution%TYPE,
        o_supply_inf       OUT pk_types.cursor_type,
        o_supply_type      OUT pk_types.cursor_type,
        o_supply_items     OUT pk_types.cursor_type,
        o_flg_selected     OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of supplies that match a given criteria
    * 
    * @param     i_lang             Language id
    * @param     i_prof             Professional
    * @param     i_value            Search criteria
    * @param     i_id_supply_area   Supply area id
    * @param     i_episode          Episode id
    * @param     o_flg_show         Flag that indicates if there is a message to be shown
    * @param     o_msg              Message to be shown
    * @param     o_msg_title        Message title
    * @param     o_button           Buttons' labels
    * @param     o_supply           Cursor
    * @param     o_error            Error message
    
    * @return    true or false on success or error
    * 
    * @author    Nuno Neves
    * @version   2.6.2
    * @since     2012/10/17
    */

    FUNCTION get_supply_search
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_value           IN VARCHAR2,
        i_id_supply_area  IN supply_area.id_supply_area%TYPE,
        i_flg_consumption IN VARCHAR2, --Y/N
        i_id_inst_dest    IN institution.id_institution%TYPE DEFAULT NULL,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of all the supply requests and consumptions, grouped by status
    * 
    * @param     i_lang      Language id
    * @param     i_prof      Professional
    * @param     i_patient   Patient id
    * @param     i_episode   Episode id
    * @param     o_list      Cursor
    * @param     o_error     Error message
    
    * @return    true or false on success or error
    *
    * @author    Jorge Canossa
    * @version   2.5
    * @since     2010/10/08
    */
    FUNCTION get_supply_listview
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_supply_area IN supply_area.id_supply_area%TYPE,
        i_patient        IN episode.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_type       IN table_varchar,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_supply_listview
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_supply_area IN supply_area.id_supply_area%TYPE,
        i_patient        IN episode.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_type       IN table_varchar,
        i_id_hhc_req     IN epis_hhc_req.id_epis_hhc_req%TYPE DEFAULT NULL,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /* 
    * Supply detail 
    *
    * @param     i_lang        Language id
    * @param     i_prof        Professional
    * @param     i_id_sup_wf   Supply id
    * @param     o_register    Cursor
    * @param     o_req         Cursor
    * @param     o_canc        Cursor
    * @param     o_error       Error message
    
    * @return    true or false on success or error
    * 
    * @author    Telmo Castro
    * @version   2.5.0.7
    * @since     2009/11/04
    */

    FUNCTION get_supply_detail
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_sup_wf IN supply_workflow.id_supply_workflow%TYPE,
        o_register  OUT pk_types.cursor_type,
        o_req       OUT pk_types.cursor_type,
        o_canceled  OUT pk_types.cursor_type,
        o_rejected  OUT pk_types.cursor_type,
        o_consumed  OUT pk_types.cursor_type,
        o_others    OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the supply item information
    * 
    * @param     i_lang      Language id
    * @param     i_prof      Professional
    * @param     i_episode   Episode id
    * @param     i_supply    Supply id
    * @param     o_supply    Cursor
    * @param     o_error     Error message
    
    * @return    true or false on success or error
    * 
    * @author    Susana Silva
    * @version   2.5.0.7
    * @since     2009/11/09
    */

    FUNCTION get_supply_to_edit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_supply     IN table_number,
        o_supply     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list with the consumption types
    * 
    * @param     i_lang             Language id
    * @param     i_prof             Professional
    * @param     i_id_supply_area   Supply area id
    * @param     i_episode          Episode id
    * @param     o_types            Cursor
    * @param     o_error            Error message
    
    * @return    true or false on success or error
    * 
    * @author    Susana Silva
    * @version   2.5.0.7
    * @since     2009/10/28
    */

    FUNCTION get_supply_filter_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_supply_area  IN supply_area.id_supply_area%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_flg_consumption IN VARCHAR2, --Y/N
        i_id_inst_dest    IN institution.id_institution%TYPE DEFAULT NULL,
        o_types           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of locations where this supply exists
    * 
    * @param     i_lang     Language id
    * @param     i_prof     Professional
    * @param     i_id_sup   Supply id
    * @param     o_list     Cursor
    * @param     o_error    Error message
    
    * @return    true or false on success or error
    * 
    * @author    Jorge Canossa
    * @version   2.5
    * @since     2010/11/16
    */

    FUNCTION get_supply_location_list
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_sup IN supply.id_supply%TYPE,
        o_list   OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /* 
    * List of all possible values for the reason:* field when requesting material
    *
    * @param     i_lang    Language id
    * @param     i_prof    Professional
    * @param     o_list    Cursor
    * @param     o_error   Error message
    
    * @return    true or false on success or error
    * 
    * @author    Telmo Castro
    * @version   2.5.0.7
    * @since     2009/11/03
    */

    FUNCTION get_supply_reason_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_type IN supply_reason.flg_type%TYPE,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE l_______________;

    /*
    * Compares the scanned barcode with the one scanned when the request was prepared
    * 
    * @param     i_lang                 Language id
    * @param     i_prof                 Professional
    * @param     i_id_supply_area       Supply area id
    * @param     i_id_supply_workflow   Supply workflow id
    * @param     i_barcode              Supply barcode to check
    * @param     i_lot                  Supply lot to check
    * @param     o_check                Flag that indicates if the barcode matches
    * @param     o_c_supply             Cursor
    * @param     o_c_kit_set            Cursor
    * @param     o_error                Error message
    
    * @return    true or false on success or error
    * 
    * @author    Jorge Canossa
    * @version   2.5
    * @since     2010/11/02
    */

    FUNCTION check_barcode_scanned
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_supply_area IN supply_area.id_supply_area%TYPE,
        i_barcode        IN supply_barcode.barcode%TYPE,
        i_lot            IN supply_barcode.lot%TYPE,
        o_check          OUT VARCHAR2,
        o_c_supply       OUT pk_types.cursor_type,
        o_c_kit_set      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets a supply using its barcode or lot
    * 
    * @param     i_lang             Language id
    * @param     i_prof             Professional
    * @param     i_id_supply_area   Supply area id
    * @param     i_barcode          Supply barcode
    * @param     i_lot              Supply lot
    * @param     o_c_supply         Cursor
    * @param     o_c_kit_set        Cursor
    * @param     o_error            Error message
    
    * @return    true or false on success or error
    * 
    * @author    Jo�o Almeida
    * @version   2.5.0.7
    * @since     2009/10/28
    */

    FUNCTION get_sup_by_barcode
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_supply_area IN supply_area.id_supply_area%TYPE,
        i_barcode        IN supply_barcode.barcode%TYPE,
        i_lot            IN supply_barcode.lot%TYPE,
        i_asset_nr       IN supply_fixed_asset_nr.fixed_asset_nr%TYPE DEFAULT NULL,
        o_c_supply       OUT pk_types.cursor_type,
        o_c_kit_set      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of supplies not ready for consumption
    * 
    * @param     i_lang          Language id
    * @param     i_prof          Professional
    * @param     i_episode       Episode id
    * @param     i_id_context    ID of the context the supply was request on
    * @param     i_flg_context   Flag that indicates the supply context
    * @param     o_list          Cursor
    * @param     o_error         Error message
    
    * @return    true or false on success or error
    * 
    * @author    Jo�o Almeida
    * @version   2.5.0.7
    * @since     2009/11/24
    */

    FUNCTION get_sup_not_ready
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_id_context  IN supply_request.id_context%TYPE,
        i_flg_context IN supply_request.flg_context%TYPE,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of supplies associated by default (configured by institution or professional)
    * to a specific context
    * 
    * @param     i_lang          Language id
    * @param     i_prof          Professional
    * @param     i_id_context    Context id
    * @param     i_flg_context   Flag that indicates the supply context
    * @param     o_supplies      Cursor
    * @param     o_error         Error message
    
    * @return    true or false on success or error
    * 
    * @author    Joao Martins
    * @version   2.5.0.7
    * @since     2009/10/23
    */

    FUNCTION get_supplies_by_context
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_context  IN table_varchar,
        i_flg_context IN supply_context.flg_context%TYPE,
        o_supplies    OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the list of supplies requested within a given context
    * 
    * @param     i_lang          Language id
    * @param     i_prof          Professional
    * @param     i_id_context    Context id
    * @param     i_flg_context   Flag that indicates the supply context
    * @param     i_ready         Ready for consumption
    * @param     i_supply_area   Supply area id
    * @param     o_supplies      Cursor
    * @param     o_error         Error message
    
    * @return    true or false on success or error
    * 
    * @author    Joao Martins
    * @version   2.5.0.7
    * @since     2009/10/25
    */

    FUNCTION get_request_by_context
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_context  IN supply_request.id_context%TYPE,
        i_flg_context IN supply_request.flg_context%TYPE,
        i_ready       IN VARCHAR2,
        i_supply_area IN supply_sup_area.id_supply_area%TYPE,
        o_supplies    OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of profiles able to prepare a supply request to be transported
    
    * 
    * @param     i_lang          Language id
    * @param     i_prof          Professional
    * @param     o_prepared_by   Prepared by 
    * @param     o_error         Error message
    
    * @return    true or false on success or error
    * 
    * @author    Susana Silva
    * @version   2.5.0.7
    * @since     2009/11/10
    */

    FUNCTION get_prepared_by
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_prepared_by OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns detailed information to edit one or more supply requests
    * 
    * @param     i_lang              Language id
    * @param     i_prof              Professional
    * @param     i_supply_workflow   Supply workflow id
    * @param     o_supply_workflow   Cursor
    * @param     o_error             Error message
    
    * @return    true or false on success or error
    * 
    * @author    Joao Martins
    * @version   2.5.0.7
    * @since     2009/11/11
    */

    FUNCTION get_supply_request_edit
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_supply_workflow IN table_number,
        o_supply_workflow OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of supplies of the same type as the one indicated
    * 
    * @param     i_lang             Language id
    * @param     i_prof             Professional
    * @param     i_id_supply_area   Supply area Id
    * @param     i_episode          Episode id
    * @param     i_id_supply        Supply id
    * @param     o_supplies         Cursor
    * @param     o_error            Error message
    
    * @return    true or false on success or error
    * 
    * @author    Joao Martins
    * @version   2.5.0.7
    * @since     2009/11/20
    */

    FUNCTION get_same_type_supplies
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_supply_area IN supply_area.id_supply_area%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_id_supply      IN supply.id_supply%TYPE,
        o_supplies       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns deliver options (yes or no)
    * 
    * @param     i_lang      Language id
    * @param     i_prof      Professional
    * @param     o_options   Cursor
    * @param     o_error     Error message
    
    * @return    true or false on success or error
    * 
    * @author    Joao Martins
    * @version   2.5.0.7
    * @since     2009/11/21
    */

    FUNCTION get_deliver_options
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_options OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get the patients that has loaned supplies of a given supply
    *
    * @param     i_lang   Language id
    * @param     i_prof   Professional
    * @param     o_grid   Cursor    
    * @param     o_error  Error message
    
    * @return    true or false on success or error
    *
    * @author    Sofia Mendes
    * @version   2.6.0.3
    * @since     2010/05/21
    */

    FUNCTION get_supply_patients
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_supply IN supply.id_supply%TYPE,
        o_grid      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get the supply information for viewer
    *
    * @param     i_lang   Language id
    * @param     i_prof   Professional
    * @param     o_grid   Cursor    
    * @param     o_error  Error message
    
    * @return    true or false on success or error
    *
    * @author    Pedro Henriques
    * @version   2.7.4.3
    * @since     2018/05/10
    */

    FUNCTION get_supply_info_viewer
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE,
        i_flg_consumption    IN VARCHAR2,
        o_supply_info        OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Compares the scanned asset number with the one scanned when the request was prepared
    * 
    * @param     i_lang                 Language id
    * @param     i_prof                 Professional
    * @param     i_id_supply_workflow   Supply workflow id
    * @param     i_asset_nr             Supply asset nr
    * @param     i_lot                  Supply lot to check
    * @param     o_check                Flag that indicates if matches
    * @param     o_c_supply             Cursor
    * @param     o_c_kit_set            Cursor
    * @param     o_error                Error message
    
    * @return    true or false on success or error
    * 
    * @author    Sofia Mendes
    * @version   2.6.0.3
    * @since     2010/06/08
    */

    FUNCTION check_asset_nr_scanned
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_asset_nr  IN supply_fixed_asset_nr.fixed_asset_nr%TYPE,
        o_check     OUT VARCHAR2,
        o_c_supply  OUT pk_types.cursor_type,
        o_c_kit_set OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns a list with the consumption types.
    * 
    * @i_lang                 Language ID
    * @i_prof                 Professional's info
    * @i_id_supply_area       ID supply area
    * @i_episode              episode info
    * @o_types                List of types
    * @o_error                Error info
    * 
    * @return  True on success, false on error
    * 
    * @author  Susana Silva
    * @version 2.5.0.7
    * @since   2009/10/28
    **********************************************************************************************/
    FUNCTION get_type_consumption
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_supply_area  IN supply_area.id_supply_area%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_flg_consumption IN VARCHAR2, --Y/N
        i_id_inst_dest    IN institution.id_institution%TYPE DEFAULT NULL,
        o_types           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns possible consumption types 
    * 
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_flg_context        Flag that indicates the supply context
    * @param     i_id_supply          Supply id
    * @param     o_type_consumption   Cursor
    * @param     o_error              Error message
    
    * @return    true or false on success or error
    * 
    * @author    Jorge Canossa
    * @version   2.6.0.4
    * @since     2010/10/01
    */

    FUNCTION get_type_consumption_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_supply_area   IN supply_area.id_supply_area%TYPE,
        i_id_supply        IN supply.id_supply%TYPE,
        o_type_consumption OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of supplies that match a given id supply set
    * 
    * @param     i_lang             Language id
    * @param     i_prof             Professional
    * @param     i_id_supply_set    Set id
    * @param     i_id_supply_area   Supply area id
    * @param     i_episode          Episode id
    * @param     o_supply           Cursor
    * @param     o_error            Error message
    
    * @return    true or false on success or error
    * 
    * @author    Nuno Neves
    * @version   2.6.2
    * @since     2012/10/17
    */

    FUNCTION get_set_composition
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_supply_set  IN supply.id_supply%TYPE,
        i_id_supply_area IN supply_area.id_supply_area%TYPE,
        o_supply_info    OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the list of supplies connsumed within a given context
    * 
    * @param     i_lang          Language id
    * @param     i_prof          Professional
    * @param     i_id_context    Context ID
    * @param     i_flg_context   Flag that indicates the supply context
    * @param     i_supply_area   Supply area id
    * @param     o_supplies      Cursor
    * @param     o_error         Error message
    
    * @return    true or false on success or error
    * 
    * @author    Cristina Oliveira
    * @version   2.6.3.9.1
    * @since     2013/01/06
    */

    FUNCTION get_workflow_by_context
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_context  IN supply_request.id_context%TYPE,
        i_flg_context IN supply_request.flg_context%TYPE,
        o_supplies    OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets supply workflow details to populate order set grid, when editing this task type
    *
    * @param     i_lang              Language id
    * @param     i_prof              Professional
    * @param     i_supply_workflow   Supply workflow id
    * @param     o_supply_wf_data    Cursor
    * @param     o_error             Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Monteiro
    * @version   2.6.4.1
    * @since     2014/07/10
    */

    FUNCTION get_supply_wf_grid_detail
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_supply_workflow IN table_number,
        o_supply_wf_data  OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_cross_actions_permissions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN table_varchar,
        i_task_type  IN task_type.id_task_type%TYPE,
        i_flg_set    IN VARCHAR2,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_actions_permissions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN action.from_state%TYPE,
        i_flg_set    IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_id_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_actions_permissions
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_subject     IN action.subject%TYPE,
        i_from_state  IN action.from_state%TYPE,
        i_flg_set     IN VARCHAR2,
        i_episode     IN episode.id_episode%TYPE,
        i_id_hhc_req  IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_flg_context IN VARCHAR2 DEFAULT NULL,
        o_actions     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_actions_with_exceptions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN action.from_state%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_id_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list with the consumption types for supplies and surgical supplies
    * 
    * @param     i_lang      Language id
    * @param     i_prof      Professional
    * @param     i_episode   Episode id
    * @param     o_types     Cursor
    * @param     o_error     Error message
    
    * @return    true or false on success or error
    *
    * @author    Daniel Ferreira
    * @version   2.6.4.2.4
    * @since     2014/11/03
    */

    FUNCTION get_coding_supply_type_cons
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_flg_consumption IN VARCHAR2,
        o_types           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Consume and count surgical supplies
    * 
    * @param     i_lang                  Language id
    * @param     i_prof                  Professional
    * @param     i_id_supply_request     Supply_request ID
    * @param     i_id_supply             Supply ID
    * @param     i_qty_added             Quantity added 
    * @param     i_qty_final_count       Quantity final count
    * @param     i_id_recouncile_count   Recouncile count ID
    * @param     i_notes                 Notes
    * @param     i_cod_table             Code 
    * @param     o_error                 Error message
    
    * @return    true or false on success or error
    *
    * @author    Filipe Silva
    * @version   2.6.0.4
    * @since     2010/10/18
    */

    FUNCTION set_sup_cons_count
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_supply_workflow  IN table_table_number,
        i_id_supply           IN table_number,
        i_qty_added           IN table_number,
        i_qty_final_count     IN table_number,
        i_id_recouncile_count IN table_number,
        i_notes               IN table_varchar,
        i_cod_table           IN table_varchar,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get repeated supplies between surgical procedures 
    * 
    * @param     i_lang                 Language id
    * @param     i_prof                 Professional
    * @param     i_id_episode           Episode id
    * @param     i_id_supply_no_saved   Supply no commited
    * @param     i_id_supply_checked    Supply checked (the user want to request these supplies even though repeated)
    * @param     o_show_message         Show message (Y) or not (N) with a list of repeated supplies
    * @param     o_repeated_supplies    Cursor
    * @param     o_labels               Cursor
    * @param     o_error                Error message
    
    * @return    true or false on success or error
    *
    * @author    Filipe Silva
    * @version   2.6.0.4
    * @since     2010/10/11
    */

    FUNCTION get_repeated_supplies
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_supply_no_saved IN table_number,
        i_id_supply_checked  IN table_number,
        o_show_message       OUT VARCHAR2,
        o_repeated_supplies  OUT pk_types.cursor_type,
        o_labels             OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Supplies consumption and count grid 
    * 
    * @param     i_lang                 Language id
    * @param     i_prof                 Professional
    * @param     i_id_supply_workflow   Supply_workflow id
    * @param     o_sup_cons_count       Cursor
    * @param     o_error                rror message
    
    * @return    true or false on success or error
    *
    * @author    Filipe Silva
    * @version   2.6.0.4
    * @since     2010/10/18
    */

    FUNCTION get_sup_cons_count
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        o_sup_cons_count OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get consumption and count supplies
    * 
    * @param     i_lang                Language id
    * @param     i_prof                Professional
    * @param     i_id_episode          Episode ID
    * @param     o_sup_cons_count_v2   Cursor
    * @param     o_error               Error message
    
    * @return    true or false on success or error
    *
    * @author    Filipe Silva
    * @version   2.6.0.4
    * @since     2010/11/29
    */

    FUNCTION get_supplies_consumed_counted
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        o_sup_cons_count OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Detail of supply count
    * 
    * @param     i_lang                 Language id
    * @param     i_prof                 Professional
    * @param     i_id_sr_supply_count   Sr_supply_count id
    * @param     o_error                Error message
    
    * @return    true or false on success or error
    *
    * @author    Filipe Silva
    * @version   2.6.0.4
    * @since     2010/12/06
    */

    FUNCTION get_supply_count_detail
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_sr_supply_count  IN sr_supply_count.id_sr_supply_count%TYPE,
        o_supply_count_detail OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets the supply information to be presented on the supplies grid from the Procedures form request
    * in a structered way.
    * The input paramenter is a piped string
    *
    * @param     i_lang                Language id
    * @param     i_prof                Professional
    * @param     i_supplies            String with supply information
    * @param     o_supplies            Cursor with supply informationi
    * @param     o_error               Error message
    
    * @return    true or false on success or error
    * 
    * @author    Diogo Oliveira
    * @version   2.8.4.0
    * @since     2022/09/16
    */

    FUNCTION get_supplies_procedure_grid
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_supplies      IN VARCHAR2,
        o_supplies_info OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Prepare supplies for surgery.
    * 
    * @param     i_lang                 Language id
    * @param     i_prof                 Professional
    * @param     i_id_supply_workflow   Supply workflow ID
    * @param     i_barcode_scanned      Barcode scanned
    * @param     i_cod_table            Code table where the supplies is prepared
    * @param     i_id_episode           Episode ID
    * @param     o_error                Error message
    
    * @return    true or false on success or error
    *
    * @author    Filipe Silva
    * @version   2.6.0.4
    * @since     2010/10/14
    */

    FUNCTION set_prepare_supplies_for_surg
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN table_number,
        i_barcode_scanned    IN table_varchar,
        i_cod_table          IN table_varchar,
        i_id_episode         IN episode.id_episode%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_user_exception  EXCEPTION;
    g_other_exception EXCEPTION;
    g_error VARCHAR2(4000);

END pk_supplies_api_ux;
/
