/*-- Last Change Revision: $Rev: 2045844 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2022-09-22 10:25:09 +0100 (qui, 22 set 2022) $*/

CREATE OR REPLACE PACKAGE pk_supplies_core IS

    TYPE t_rec_surg_supply_count IS RECORD(
        id_sr_supply_count    sr_supply_count.id_sr_supply_count%TYPE,
        id_supply             supply_workflow.id_supply%TYPE,
        desc_supply           pk_translation.t_desc_translation,
        desc_supply_attrib    VARCHAR2(4000),
        cod_table             supply_workflow.cod_table%TYPE,
        flg_type              supply.flg_type%TYPE,
        desc_supply_type      sys_domain.desc_val%TYPE,
        id_supply_type        NUMBER(24),
        desc_code_supply_type pk_translation.t_desc_translation,
        qty_before            supply_workflow.quantity%TYPE);

    TYPE t_surg_supply_count IS TABLE OF t_rec_surg_supply_count;

    TYPE t_hashmap IS TABLE OF NUMBER INDEX BY PLS_INTEGER;

    TYPE t_supplies_by_context IS RECORD(
        id_supply            NUMBER(24),
        id_parent_supply     NUMBER(24),
        desc_supply          VARCHAR2(1000 CHAR),
        desc_supply_attrib   VARCHAR2(1000 CHAR),
        desc_cons_type       VARCHAR2(1000 CHAR),
        flg_cons_type        VARCHAR2(10 CHAR),
        quantity             NUMBER(24),
        dt_return            VARCHAR2(1000 CHAR), -----              
        id_supply_location   NUMBER(24),
        desc_supply_location VARCHAR2(1000 CHAR),
        flg_type             VARCHAR2(10 CHAR),
        id_context           VARCHAR2(20 CHAR),
        rank                 NUMBER(24),
        id_supply_soft_inst  NUMBER(24));

    TYPE tbl_supplies_by_context IS TABLE OF t_supplies_by_context;

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
        i_id_supply_area    IN supply_area.id_supply_area%TYPE,
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
        i_supply_flg_status IN supply_request.flg_status%TYPE,
        i_id_inst_dest      IN institution.id_institution%TYPE DEFAULT NULL,
        i_lot               IN table_varchar DEFAULT NULL,
        i_barcode_scanned   IN table_varchar DEFAULT NULL,
        i_dt_expiration     IN table_varchar DEFAULT NULL,
        i_flg_validation    IN table_varchar DEFAULT NULL,
        o_id_supply_request OUT supply_request.id_supply_request%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Registers the consumption of supplies (if the episode is inactive reopens it)
    * 
    * @param     i_lang                 Language id
    * @param     i_prof                 Professional
    * @param     i_id_episode           Episode id
    * @param     i_id_context           Context id
    * @param     i_flg_context          Flag that indicates the supply context
    * @param     i_id_supply_workflow   Workflow IDs
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
        i_qty_dispensed IN table_number DEFAULT NULL,
        o_error         OUT t_error_out
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
        i_id_context      IN supply_request.id_context%TYPE,
        i_flg_context     IN supply_request.flg_context%TYPE,
        i_notes           IN table_varchar,
        o_error           OUT t_error_out
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

    FUNCTION set_supply_consumption
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
    * @param     i_id_supply_workflow   Supply id
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
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_supplies    IN table_number,
        i_reason      IN table_number,
        i_notes       IN table_varchar,
        i_id_episode  IN supply_workflow.id_episode%TYPE,
        i_flg_context IN supply_workflow.flg_context%TYPE DEFAULT NULL,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_supply_parent_status
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_parents_supplies IN table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pharmacy_delivery
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_pha_dispense IN table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Updates a supply requests status 
    * 
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_supplies           Supplies
    * @param     i_episode            Episode id
    * @param     i_cancel_notes       Cancellation notes
    * @param     i_id_cancel_reason   Cancel reason id
    * @param     i_flg_status         Status
    * @param     i_notes              Notes
    * @param     o_error              Error message
    
    * @return    true or false on success or error
    * 
    * @author    Teresa Coutinho
    * @version   2.6.2
    * @since     2012/03/27
    */

    FUNCTION update_supply_workflow_status
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_supplies         IN table_number,
        i_id_prof_cancel   IN professional.id_professional%TYPE,
        i_cancel_notes     IN supply_workflow.notes_cancel%TYPE,
        i_id_cancel_reason IN supply_workflow.id_cancel_reason%TYPE,
        i_dt_cancel        IN supply_workflow.dt_cancel%TYPE,
        i_flg_status       IN supply_workflow.flg_status%TYPE,
        i_notes            IN table_varchar,
        o_error            OUT t_error_out
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
        i_id_prof_cancel   IN professional.id_professional%TYPE,
        i_cancel_notes     IN supply_workflow.notes_cancel%TYPE,
        i_id_cancel_reason IN supply_workflow.id_cancel_reason%TYPE,
        i_dt_cancel        IN supply_workflow.dt_cancel%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_supply_request
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_supply_request   IN supply_request.id_supply_request%TYPE,
        i_notes            IN supply_request.notes%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
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
        i_flg_status     IN table_varchar DEFAULT NULL,
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
        i_id_inst_dest    IN institution.id_institution%TYPE DEFAULT NULL
    ) RETURN t_tbl_supply_type_consumption;

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
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_supply_area IN supply_area.id_supply_area%TYPE,
        i_id_sup         IN supply.id_supply%TYPE,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /* 
    * List of all possible values for the reason:* field when requesting material
    *
    * @param     i_lang       Language id
    * @param     i_prof       Professional
    * @param     i_flg_type   Reason type
    * @param     o_list       Cursor
    * @param     o_error      Error message
    
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

    PROCEDURE x_______________;

    /**********************************************************************************************
    * Compares the scanned barcode with the one scanned when the request was prepared.
    * 
    * @i_lang  Language ID
    * @i_prof  Professional's info
    * @i_id_supply_area ID supply area
    * @i_id_supply_workflow supply workflow identifier
    * @i_barcode   supply barcode to check
    * @i_lot                supply lot to check
    * @o_check              does it match? Yes or No
    * @o_c_supply           supply info
    * @o_c_kit_set          kit or set info
    * @o_error Error info
    * 
    * @return  True on success, false on error
    * 
    * @author  Jo�o Almeida
    * @version 2.5.0.7
    * @since   28/10/09
    **********************************************************************************************/
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

    FUNCTION check_supply_request_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_supply_request IN supply_request.id_supply_request%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Compares the scanned asset number with the one scanned when the request was prepared.
    * 
    * @i_lang               Language ID
    * @i_prof               Professional's info
    * @i_id_supply_workflow supply workflow identifier
    * @i_asset_nr           supply asset nr
    * @i_lot                supply lot to check
    * @o_check              does it match? Yes or No
    * @o_c_supply           supply info
    * @o_c_kit_set          kit or set info
    * @o_error Error info
    * 
    * @return  True on success, false on error
    * 
    * @author  Sofia Mendes
    * @version 2.6.0.3
    * @since   08-Jun-2010
    **********************************************************************************************/
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

    /**
    * Checks if a supply_workflow can be canceled or not
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_supply_area             Supply area identifier
    * @param   i_flg_status                 Flag indicating supply_workflow state
    * @param   i_quantity                   Supply_workflow quantity
    * @param   i_total_quantity             Supply_workflow total quantity
    *
    * @return  varchar2                     Y- supply_workflow can be cancelled, N- otherwise
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   02-07-2014
    */
    FUNCTION check_supply_wf_cancel
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_supply_area IN supply_workflow.id_supply_area%TYPE,
        i_flg_status     IN supply_workflow.flg_status%TYPE,
        i_quantity       IN supply_workflow.quantity%TYPE,
        i_total_quantity IN supply_workflow.total_quantity%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Gets a supply using its barcode or lot.
    * 
    * @i_lang  Language ID
    * @i_prof  Professional's info
    * @i_id_supply_area  Id supply area
    * @i_barcode barcode to check
    * @i_lot lot to check
    * @o_c_supply list of supplies
    * @o_c_kit_set list of kits or sets associated with that barcode
    * 
    * @return  True on success, false on error
    * 
    * @author  Jo�o Almeida
    * @version 2.5.0.7
    * @since   28/10/09
    **********************************************************************************************/

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

    /**********************************************************************************************
    * Returns a list of supplies associated by default (configured by institution or professional)
    * to a specific context.
    * 
    * @i_lang        Language ID
    * @i_prof        Professional's info
    * @i_id_context  Context ID
    * @i_flg_context Flag for context
    * @o_supplies    List of supplies
    * @o_error       Error info
    * 
    * @return        True on success, false on error
    * 
    * @author        Joao Martins
    * @version       2.5.0.7
    * @since         2009/10/23
    **********************************************************************************************/
    FUNCTION get_supplies_by_context
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_context    IN table_varchar,
        i_flg_context   IN supply_context.flg_context%TYPE,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_supplies      OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the list of supplies requested within a given context.
    * 
    * @i_lang        Language ID
    * @i_prof        Professional's info
    * @i_id_context  Context ID
    * @i_flg_context Flag for context
    * @i_ready       Ready for consumption
    * @i_SUPPLY_AREA id supply area
    * @o_supplies    List of requested supplies
    * @o_error       Error info
    * 
    * @return        True on success, false on error
    * 
    * @author        Joao Martins
    * @version       2.5.0.7
    * @since         2009/10/25
    **********************************************************************************************/
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

    /**********************************************************************************************
    * INLINE FUNCTION
    * returns biggest delay among all material (if any) workflows for a given episode. To be called 
    * in several grid functions. Supplies the value to new column 
    * 
    * @i_lang         Language ID
    * @i_prof         Professional's info
    * @i_id_episode  episode id
    * @i_back_color   color code to use in cell background
    * 
    * @return  string complying with Code Convention's document at point 5.13
    * 
    * @author  Telmo
    * @version 2.5.0.7
    * @since   28-10-2009
    **********************************************************************************************/
    FUNCTION get_epis_max_supply_delay
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN patient.id_patient%TYPE,
        i_phar_main_grid IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Returns a list with the consumption types for supplies and surgical supplies.
    * 
    * @i_lang  Language ID
    * @i_prof  Professional's info
    * @i_episode  episode info
    * @o_types List of types
    * @o_error Error info
    * 
    * @return  True on success, false on error
    * 
    * @author  Daniel Ferreira
    * @version 2.6.4.2.4
    * @since   2014/11/03
    **********************************************************************************************/
    FUNCTION get_coding_supply_type_cons
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_flg_consumption IN VARCHAR2, --Y/N
        o_types           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /* INLINE support function for get_supply_wf_det 
    *
    * @i_lang       Language ID
    * @i_prof       Professional's info
    * @i_id_sw      supply_workflow id
    * @i_code_msg   wanted value
    * @i_source     can be 'SUPPLY_WORKFLOW' or 'SUPPLY_WORKFLOW_HIST'. It's the table to get the value from
    *
    * @return  column value
    * 
    * @author  Telmo
    * @version 2.5.0.7
    * @since   03-11-2009
    */
    FUNCTION get_supply_workflow_col_value
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_sw    IN supply_workflow.id_supply_workflow%TYPE,
        i_code_msg IN sys_message.code_message%TYPE,
        i_source   IN VARCHAR2
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Returns the supply information
    * 
    * @i_lang  Language ID
    * @i_prof  Professional's info
    * @i_id_supply_area   supply area ID
    * @i_episode  episode info
    * @i_consumption_type  Consumption type
    * @i_flg_type  Flag type
    * @i_id_supply  Supply identification
    * @i_id_supply_type  Supply Type identification
    * @o_supply  Supply information
    * @o_error Error info 
    * 
    * @return  True on success, false on error
    * 
    * @author  Susana Silva
    * @version 2.5.0.7
    * @since   2009/11/09
    **********************************************************************************************/

    FUNCTION get_supply_info
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
        o_supply           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the supply type information
    * 
    * @i_lang  Language ID
    * @i_prof  Professional's info
    * @i_id_supply_area   supply area ID
    * @i_episode  episode info
    * @i_consumption_type  Consumption type
    * @i_flg_type  Flag type
    * @o_supply_type  Supply type information
    * @o_error Error info 
    * 
    * @return  True on success, false on error
    * 
    * @author  Susana Silva
    * @version 2.5.0.7
    * @since   2009/11/09
    **********************************************************************************************/

    FUNCTION get_supply_type
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_supply_area   IN supply_area.id_supply_area%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_consumption_type IN supply_soft_inst.flg_cons_type%TYPE,
        i_flg_type         IN supply.flg_type%TYPE,
        i_id_inst_dest     IN institution.id_institution%TYPE,
        o_supply_type      OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the supply type parent information
    * 
    * @i_lang  Language ID
    * @i_supply_type  supply type identification
    * 
    * @return  number
    * 
    * @author  Susana Silva
    * @version 2.5.0.7
    * @since   2009/11/09
    **********************************************************************************************/

    FUNCTION get_parent_supply_type
    (
        i_lang        IN language.id_language%TYPE,
        i_supply_type IN supply_type.id_supply_type%TYPE
    ) RETURN NUMBER;

    /**********************************************************************************************
    * Returns the supply item information
    * 
    * @i_lang             Language ID
    * @i_prof             Professional's info
    * @i_id_supply_area   supply area ID
    * @i_id_episode       episode ID
    * @i_consumption_type Consumption type
    * @i_supply           Supply information
    * @o_supply_items     Supply items information
    * @return  boolean
    * 
    * @author  Susana Silva
    * @version 2.5.0.7
    * @since   2009/11/09
    **********************************************************************************************/

    FUNCTION get_supply_item
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_supply_area   IN supply_area.id_supply_area%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_consumption_type IN supply_soft_inst.flg_cons_type%TYPE,
        i_supply           IN supply.id_supply%TYPE,
        i_id_inst_dest     IN institution.id_institution%TYPE DEFAULT NULL,
        o_supply_items     OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_item_count
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_supply_area   IN supply_area.id_supply_area%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_consumption_type IN supply_soft_inst.flg_cons_type%TYPE,
        i_flg_type         IN supply.flg_type%TYPE,
        i_id_supply        IN supply.id_supply%TYPE,
        i_id_supply_type   IN supply.id_supply_type%TYPE,
        i_id_inst_dest     IN institution.id_institution%TYPE DEFAULT NULL,
        o_supply_prof      OUT PLS_INTEGER,
        o_supply_dept      OUT PLS_INTEGER,
        o_dept             OUT NUMBER,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the supply type suns
    * 
    * @i_lang  Language ID
    * @i_prof  Professional's info
    * @i_id_supply_area   supply area ID
    * @i_episode  episode info
    * @i_consumption_type  Consumption type
    * @i_flg_type  Flag type
    * @i_id_supply_type  Supply Type identification
    * @o_count_sun  Number of suns
    * @o_supply_type  Supply type information
    * @o_error Error info 
    * 
    * @return  True on success, false on error
    * 
    * @author  Susana Silva
    * @version 2.5.0.7
    * @since   2009/11/09
    **********************************************************************************************/

    FUNCTION get_supply_child_type
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_supply_area   IN supply_area.id_supply_area%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_consumption_type IN supply_soft_inst.flg_cons_type%TYPE,
        i_flg_type         IN supply.flg_type%TYPE,
        i_supply_type      IN supply_type.id_supply_type%TYPE,
        i_id_inst_dest     IN institution.id_institution%TYPE,
        o_count_sun        OUT NUMBER,
        o_supply_type      OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns a list of profiles able to prepare a supply request to be transported.
    
    * 
    * @i_lang  Language ID
    * @i_prof  Professional's info
    * @o_prepared_by  Prepared by 
    * @o_error Error info 
    * 
    * @return  True on success, false on error
    * 
    * @author  Susana Silva
    * @version 2.5.0.7
    * @since   2009/11/10
    **********************************************************************************************/

    FUNCTION get_prepared_by
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_prepared_by OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns detailed information to edit a supply request.
    * 
    * @i_lang               Language ID
    * @i_prof               Professional
    * @i_supply_workflow    Array of supply workflow IDs
    * @o_supply_workflow    Supply request info
    * @o_error              Error object
    *
    * @return               True on success, false otherwise
    * 
    * @author               Joao Martins
    * @version              2.5.0.7
    * @since                2009/10/26
    **********************************************************************************************/
    FUNCTION get_supply_request_edit
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_supply_workflow IN table_number,
        o_supply_workflow OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the lower sun of supply type
    
    * 
    * @i_lang  Language ID
    * @i_supply_type  Professional's info
    * 
    * @return  NUMBER
    * 
    * @author  Susana Silva
    * @version 2.5.0.7
    * @since   2009/11/11
    **********************************************************************************************/

    FUNCTION get_sun_supply_type
    (
        i_lang        IN language.id_language%TYPE,
        i_supply_type IN supply_type.id_supply_type%TYPE
    ) RETURN NUMBER;

    /**********************************************************************************************
    * Returns the number of supply type suns
    * 
    * @i_lang  Language ID
    * @i_prof  Professional's info
    * @i_id_supply_area   supply area ID
    * @i_episode  episode info
    * @i_consumption_type  Consumption type
    * @i_flg_type  Flag type
    * @i_id_supply_type  Supply Type identification
    * 
    * @return  varchar
    * 
    * @author  Susana Silva
    * @version 2.5.0.7
    * @since   2009/11/12
    **********************************************************************************************/

    FUNCTION get_supply_child_type_count
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_supply_area   IN supply_area.id_supply_area%TYPE,
        i_consumption_type IN supply_soft_inst.flg_cons_type%TYPE,
        i_flg_type         IN supply.flg_type%TYPE,
        i_supply_type      IN supply_type.id_supply_type%TYPE,
        l_count_prof       IN PLS_INTEGER,
        l_count_dept       IN PLS_INTEGER,
        l_dept             IN NUMBER,
        i_id_inst_dest     IN institution.id_institution%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Returns the default location for a given supply.
    * 
    * @i_lang  Language ID
    * @i_prof  Professional's info
    * @i_id_supply  Supply ID
    * 
    * @return  Supply's default location ID
    * 
    * @author  Joao Martins
    * @version 2.5.0.7
    * @since   2009/11/12
    **********************************************************************************************/
    FUNCTION get_default_location
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_supply_area IN supply_area.id_supply_area%TYPE,
        i_id_supply      IN supply.id_supply%TYPE,
        i_id_inst_dest   IN institution.id_institution%TYPE DEFAULT NULL
    ) RETURN NUMBER;

    FUNCTION get_default_location_name
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_supply_area IN supply_area.id_supply_area%TYPE,
        i_id_supply      IN supply.id_supply%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Returns a list of supply requests by patient.
    * 
    * @i_lang  Language ID
    * @i_prof  Professional's info
    * @o_supply_request Flag indicates when the supplies must be selected
    * @o_error Error info 
    * 
    * @return  True on success, false on error
    * 
    * @author  Susana Silva
    * @version 2.5.0.7
    * @since   2009/11/09
    **********************************************************************************************/

    FUNCTION tf_get_supply_requests
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN t_tbl_supply_requests;

    /**********************************************************************************************
    * Returns the consumption type of a given supply.
    * 
    * @i_lang       Language ID
    * @i_prof       Professional's info
    * @i_id_supply_area       Supply area Id
    * @i_supply     Supply ID
    * 
    * @return       Flag for consumption type
    * 
    * @author       Joao Martins
    * @version      2.5.0.7
    * @since        2009/11/17
    **********************************************************************************************/
    FUNCTION get_consumption_type
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_supply_area IN supply_area.id_supply_area%TYPE,
        i_supply         IN supply.id_supply%TYPE,
        i_id_inst_dest   IN institution.id_institution%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Returns the attributes of a given supply.
    * 
    * @i_lang              Language ID
    * @i_prof              Professional's info
    * @i_id_supply_area    Supply area ID
    * @i_supply            Supply ID
    * @i_supply_location   Supply location ID (default)
    * 
    * @return              String with the attributes
    * 
    * @author              Joao Martins
    * @version             2.5.0.7
    * @since               2009/11/17
    **********************************************************************************************/
    FUNCTION get_attributes
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_area     IN supply_area.id_supply_area%TYPE,
        i_supply             IN supply.id_supply%TYPE,
        i_supply_location    IN supply_location.id_supply_location%TYPE DEFAULT NULL,
        i_id_inst_dest       IN institution.id_institution%TYPE DEFAULT NULL,
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Returns a list of supplies of the same type as the one indicated.
    * 
    * @i_lang           Language ID
    * @i_prof           Professional's info
    * @i_id_supply_area Supply area Id
    * @i_episode        Episode ID
    * @i_id_supply      Supply ID
    * @o_supplies       List of supplies    
    * @o_error          Error
    *
    * @return      True on success, false otherwise
    * 
    * @author      Joao Martins
    * @version     2.5.0.7
    * @since       2009/11/20
    **********************************************************************************************/
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

    /**********************************************************************************************
    * Returns deliver options (yes or no)
    * 
    * @i_lang    Language ID
    * @i_prof    Professional's info
    * @o_options List of options
    * @o_error   Error
    * 
    * @return    True on success, false otherwise
    * 
    * @author    Joao Martins
    * @version   2.5.0.7
    * @since     2009/11/21
    **********************************************************************************************/
    FUNCTION get_deliver_options
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_options OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns SUPPLY status string
    * 
    * @i_lang  Language ID
    * @i_prof  Professional's info
    * @i_id_episode  Episode's info
    * @i_flag  flag status
    * 
    * @return  varchar2
    * 
    * @author  Susana Silva
    * @version 2.5.0.7
    * @since   2009/11/24
    **********************************************************************************************/

    FUNCTION get_supply_delay_sr_day
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN supply_workflow.id_episode%TYPE,
        i_flag       IN supply_workflow.flg_status%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Returns a list of supplies not ready for consumption
    * 
    * @i_lang  Language ID
    * @i_prof  Professional's info
    * @i_episode Current Episode
    * @i_id_context ID of the context the supply was request on
    * @i_flg_context Flag indicating the type of context
    * @o_list  list of all the supply requests and consumptions
    * @o_error Error info
    * 
    * @return  True on success, false on error
    * 
    * @author  Jo�o Almeida
    * @version 2.5.0.7
    * @since   24/11/09
    **********************************************************************************************/

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

    /********************************************************************************************
    * Get the patients that has loaned supplies of a given supply.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure     
    * @param o_grid           output cursor    
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                2.6.0.3
    * @since                  21-Mai-2010
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
        i_id_supply_workflow IN table_varchar,
        i_id_supply_count    IN sr_supply_count.id_sr_supply_count%TYPE
    ) RETURN CLOB;

    FUNCTION get_supply_info_viewer
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE,
        i_flg_consumption    IN VARCHAR2,
        o_supply_info        OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Calculates the nr of loaned units of a given supply.
    * 
    * @param i_lang               Language ID
    * @param i_prof               Professional
    * @param i_id_supply_area     Supply area Id
    * @param i_id_supply          Supply identifier    
    * 
    * @return  nr of loaned units
    * 
    * @author  Sofia Mendes
    * @version 2.6.0.3
    * @since   28-Mai-2010
    **********************************************************************************************/

    FUNCTION get_nr_loaned_units
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_supply_area   IN supply_area.id_supply_area%TYPE,
        i_id_supply        IN supply.id_supply%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_consumption_type IN supply_soft_inst.flg_cons_type%TYPE,
        i_flg_type         IN supply.flg_type%TYPE,
        i_id_inst_dest     IN institution.id_institution%TYPE DEFAULT NULL
    ) RETURN supply_workflow.quantity%TYPE;

    /**********************************************************************************************
    * Calculates the nr of available units of a given supply.
    * 
    * @param i_lang               Language ID
    * @param i_prof               Professional
    * @param i_id_supply_area     Supply area Id
    * @param i_id_supply          Supply identifier    
    * 
    * @return  nr of loaned units
    * 
    * @author  Sofia Mendes
    * @version 2.6.0.3
    * @since   28-Mai-2010
    **********************************************************************************************/
    FUNCTION get_nr_avail_units
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_supply_area IN supply_area.id_supply_area%TYPE,
        i_id_supply      IN supply.id_supply%TYPE,
        i_id_episode     IN episode.id_episode%TYPE
    ) RETURN supply_soft_inst.quantity%TYPE;

    /**********************************************************************************************
    * Calculates the total nr of delivered units, related to a specfic loan.
    * 
    * @param i_lang               Language ID
    * @param i_prof               Professional
    * @param i_software_workflow  Supply workflow identifier    
    * @param i_software_wf_parent Parent supply workflow identifier
    * 
    * @return  nr of delivered units
    * 
    * @author  Sofia Mendes
    * @version 2.6.0.3
    * @since   28-Mai-2010
    **********************************************************************************************/
    FUNCTION get_delivered_units
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_software_workflow  IN supply.id_supply%TYPE,
        i_software_wf_parent IN supply.id_supply%TYPE
    ) RETURN supply_workflow.quantity%TYPE;

    /**********************************************************************************************
    * Returns a list of all the supply requests and consumptions, grouped by status to REPORTS team.
    * 
    * @i_lang        Language ID
    * @i_prof        Professional's info
    * @i_patient     Patient's id
    * @i_episode     Current Episode
    * @i_flg_type    Type of material ('M' - Activity terapist material; 'O' - Other material)
    * @o_list        list of all the supply requests and consumptions
    * @o_error       Error info
    * 
    * @return        True on success, false on error
    *
    * @Dependencies  REPORTS 
    *
    * @author        Lu�s Maia
    * @version       2.6.0.3
    * @since         09/Jun/2010
    **********************************************************************************************/
    FUNCTION get_list_req_cons_report
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN episode.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_flg_type   IN supply.flg_type%TYPE,
        i_flg_status IN table_varchar DEFAULT NULL,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    -- GS: 20100727 - Made this function only to correct a bug 
    -- review of functions get_supply_date, get_supply_hour, get_supply_requests are needed
    FUNCTION get_supply_date_tstz
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN supply_workflow.id_episode%TYPE,
        i_flag       IN supply_workflow.flg_status%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    /**********************************************************************************************
    * Return the id supply workflow 
    * 
    * @param    i_lang                      Language ID
    * @param    i_prof                      Professional's info
    * @param    i_id_supply                 Table number with supplies id
    * @param    i_id_context                Request's context ID
    * @param    i_flg_context               Request's context
    * @param    i_flg_status                Flag status
    *
    * @param    o_id_supply_workflow        Table number with id_supply_workflows
    * @param    o_error                     t_error_out
    * 
    * @return                               True on success, false on error
    * 
    * @author  Filipe Silva
    * @version 2.6.0.4
    * @since   2010/09/30
    **********************************************************************************************/
    FUNCTION get_supply_workflow
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_context         IN supply_workflow.id_context%TYPE,
        i_flg_context        IN supply_workflow.flg_context%TYPE,
        i_id_supply          IN table_number,
        i_flg_status         IN table_varchar,
        o_id_supply_workflow OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

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

    FUNCTION get_type_consumption_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_supply_area   IN supply_area.id_supply_area%TYPE,
        i_id_supply        IN supply.id_supply%TYPE,
        o_type_consumption OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Check if there are repeated supplies for an episode ID
    * 
    * @param    i_lang                      Language ID
    * @param    i_prof                      Professional's info
    * @param    i_id_episode                ORIS episode ID
    * @param    i_id_supply_area            ID supply area ( 3 - Surgical supplies) 
    * @param    i_flg_status                Table varchar with flg_status                                                   
    * @param    i_id_supply_no_saved        Table number with id supply no commited
    * @param    i_id_supply_checked         Table number with id_supply_checked (the user want to request these supplies
    *                                       even though repeated       
    *
    * @param    o_repeated_supplies         Table number with list of repeated supplies Id
    * @param    o_error                     t_error_out
    * 
    * @return                               True on success, false on error
    * 
    * @author  Filipe Silva
    * @version 2.6.0.4
    * @since   2010/10/11
    **********************************************************************************************/

    FUNCTION check_repeated_supplies
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_supply_area       IN supply_workflow.id_supply_area%TYPE,
        i_flg_status           IN table_varchar,
        i_id_supply_no_saved   IN table_number,
        i_id_supply_checked    IN table_number,
        o_id_repeated_supplies OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_id_supply_area
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply          IN supply.id_supply%TYPE,
        i_flg_type           IN supply.flg_type%TYPE,
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE DEFAULT NULL,
        o_id_supply_area     OUT supply_area.id_supply_area%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_id_supply_soft_inst
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_supply_area   IN supply_area.id_supply_area%TYPE,
        i_id_dept          IN episode.id_dept_requested%TYPE,
        i_consumption_type IN supply_soft_inst.flg_cons_type%TYPE,
        i_id_supply        IN supply.id_supply%TYPE,
        i_id_inst_dest     IN institution.id_institution%TYPE DEFAULT NULL
    ) RETURN supply_soft_inst.id_supply_soft_inst%TYPE;

    /**********************************************************************************************
    * Update the supply request status 
    * 
    * @param    i_lang                      Language ID
    * @param    i_prof                      Professional's info
    * @param    i_id_supply_workflow        Table number with Supply workflows ID
    *
    * @return                               True on success, false on error
    * 
    * @author  Filipe Silva
    * @version 2.6.0.4
    * @since   2010/11/16
    **********************************************************************************************/

    FUNCTION update_supply_request
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Update supply workflow
    * 
    * @param    i_lang                      Language ID
    * @param    i_id_episode                ID episode
    * @param    i_id_supply_workflow        ID supply workflow
    * @param    i_flg_status                Flag status  
    * @param    i_supply                    ID supply
    * @param    i_supply_set                Parent supply set (if applicable)
    * @param    i_supply_qty                Supply quantity
    * @param    i_supply_loc                Supply location
    * @param    i_dt_request                Date of request
    * @param    i_id_req_reason             Reasons for each supply
    * @param    i_id_context                Request's context ID
    * @param    i_flg_context               Request's context
    * @param    i_notes                     Request notes
    * @param    i_flg_cons_type             Flag of consumption type
    * @param    i_cod_table                 Code table
    *
    * @param    o_id_supply_request         Created Request ID
    * @param    o_error                     Error message
    * 
    * @return   True on success , false on error
    * 
    * @author  Filipe Silva
    * @version 2.6.0.4
    * @since   2010/11/23
    **********************************************************************************************/
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

    /**********************************************************************************************
    * Returns a list of all the supply requests and consumptions, grouped by status.
    * 
    * @i_lang  Language ID
    * @i_prof  Professional's info
    * @i_id_supply_area   supply area ID
    * @i_patient Patient's id
    * @i_episode Current Episode
    * @o_list  list of all the supply requests and consumptions
    * @o_error Error info
    * 
    * @return  True on success, false on error
    *
    * @author  Jo�o Almeida
    * @version 2.5.0.7
    * @since   9/11/09
    **********************************************************************************************/

    FUNCTION get_list_req_cons_no_cat
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_supply_area IN supply_area.id_supply_area%TYPE,
        i_patient        IN episode.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_type       IN table_varchar,
        i_flg_status     IN table_varchar DEFAULT NULL,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns a list of all the supply requests and consumptions, grouped by status to REPORTS team.
    * 
    * @i_lang        Language ID
    * @i_prof        Professional's info
    * @i_patient     Patient's id
    * @i_episode     Current Episode
    * @i_flg_type    Type of material ('M' - Activity terapist material; 'O' - Other material)
    * @o_list        list of all the supply requests and consumptions
    * @o_error       Error info
    * 
    * @return        True on success, false on error
    *
    * @Dependencies  REPORTS 
    *
    * @author        Lu�s Maia
    * @version       2.6.0.3
    * @since         09/Jun/2010
    **********************************************************************************************/
    FUNCTION get_list_req_cons_reprt_no_cat
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN episode.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_flg_type IN supply.flg_type%TYPE,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns a list of supplies that match a given id supply set.
    * 
    * @param i_lang      Language ID
    * @param i_prof           Professional's info
    * @param i_id_supply_set   id of SET
    * @param i_id_supply_area   supply area ID
    * @param i_episode  episode info
    * @param o_supply  Supply information
    * @param o_error Error info 
    * 
    * @return  True on success, false on error
    * 
    * @author  Nuno Neves
    * @version 2.6.2
    * @since   2012/10/17
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

    /**
    * Returns the list of supplies connsumed within a given context.
    * 
    * @i_lang        Language ID
    * @i_prof        Professional's info
    * @i_id_context  Context ID
    * @i_flg_context Flag for context
    * @i_supply_area id supply area
    * @o_supplies    List of requested supplies
    * @o_error       Error info
    * 
    * @return        True on success, false on error
    * 
    * @author        Cristina Oliveira
    * @version       2.6.3.9.1
    * @since         2013/01/06
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

    /**
    * Gets workflow identifier, based on supply area
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)    
    * @param   i_id_supply_area             Supply_workflow area identifier
    *
    * @return  workflow identifier
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   26-06-2014
    */
    FUNCTION get_id_workflow
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_supply_area IN supply_workflow.id_supply_area%TYPE
    ) RETURN wf_workflow.id_workflow%TYPE;

    /**
    * Gets supply_workflow status string
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)    
    * @param   i_flg_status                 Flag indicating the supply_workflow state
    * @param   i_id_sys_shortcut            Shortcut identifier to be used
    * @param   i_id_workflow                Workflow identifier (if null, will be used i_id_supply_area to calculate it)
    * @param   i_id_supply_area             Supply_workflow area identifier (only used if i_id_workflow is null)
    * @param   i_id_category                Professional category identifier
    * @param   i_dt_returned                Date of return (for loans)
    * @param   i_dt_request                 Date for request
    * @param   i_dt_supply_workflow         Workflow last action date 
    * @param   i_id_episode                 Episode identifier
    *
    * @return  supply_workflow status string
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   25-06-2014
    */
    FUNCTION get_supply_wf_status_string
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_flg_status         IN supply_workflow.flg_status%TYPE,
        i_id_sys_shortcut    IN sys_shortcut.id_sys_shortcut%TYPE,
        i_id_workflow        IN wf_workflow.id_workflow%TYPE,
        i_id_supply_area     IN supply_workflow.id_supply_area%TYPE,
        i_id_category        IN category.id_category%TYPE,
        i_dt_returned        IN supply_workflow.dt_returned%TYPE,
        i_dt_request         IN supply_workflow.dt_request%TYPE,
        i_dt_supply_workflow IN supply_workflow.dt_supply_workflow%TYPE,
        i_id_episode         IN supply_workflow.id_episode%TYPE,
        i_supply_workflow    IN supply_workflow.id_supply_workflow%TYPE DEFAULT NULL
    ) RETURN VARCHAR;

    /**
    * Gets supply workflow details to populate order set grid, when editing this task type
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and
    * @param   i_supply_workflow            Array of supply_workflow identifiers
    * @param   o_supply_wf_data             Cursor with supply_workflow data
    * @param   o_error                      Error information
    * 
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   10-07-2014
    */
    FUNCTION get_supply_wf_grid_detail
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_supply_workflow IN table_number,
        o_supply_wf_data  OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_supply_set_info
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_supply_workflow IN supply_workflow.id_supply_workflow%TYPE,
        i_supply_request  IN supply_workflow.id_supply_request%TYPE
    ) RETURN VARCHAR2;

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

    /**********************************************************************************************
    * Get repeated supplies between surgical procedures 
    * 
    * @param    i_lang                      Language ID
    * @param    i_prof                      Professional's info
    * @param    i_id_episode                ORIS episode ID
    * @param    i_id_supply_no_saved        Table number with id supply no commited
    * @param    i_id_supply_checked         Table number with id_supply_checked (the user want to request these supplies
    *                                       even though repeated       
    *
    * @param    o_show_message              Show message (Y) or not (N) with a list of repeated supplies
    * @param    o_repeated_supplies         Cursor with list of repeated supplies
    * @param    o_labels                    Cursor with labels
    * @param    o_error                     t_error_out
    * 
    * @return                               True on success, false on error
    * 
    * @author  Filipe Silva
    * @version 2.6.0.4
    * @since   2010/10/11
    **********************************************************************************************/

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

    /**********************************************************************************************
    * Supplies consumption and count grid 
    * 
    * @param    i_lang                      Language ID
    * @param    i_prof                      Professional's info
    * @param    i_id_supply_workflow        Table number with id_supply_workflow
    *
    * @param    o_sup_cons_count            Cursor with list of supplies consumption and count
    * @param    o_error                     t_error_out
    * 
    * @return                               True on success, false on error
    * 
    * @author  Filipe Silva
    * @version 2.6.0.4
    * @since   2010/10/18
    **********************************************************************************************/
    FUNCTION get_sup_cons_count
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        o_sup_cons_count OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get consumption and count supplies
    * 
    * @param    i_lang                      Language ID
    * @param    i_prof                      Professional's info
    * @param    i_id_episode                Episode ID
    *
    * @param    o_sup_cons_count_v2         Cursor with list of supplies consumption and count
    * @param    o_error                     t_error_out
    * 
    * @return                               True on success, false on error
    * 
    * @author  Filipe Silva
    * @version 2.6.0.4
    * @since   2010/11/29
    **********************************************************************************************/
    FUNCTION get_supplies_consumed_counted
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        o_sup_cons_count OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Table function: Return data record for surgical supplies count
    * 
    * @param    i_lang                      Language ID
    * @param    i_prof                      Professional's info
    * @param    i_id_episode                Episode ID
    * @param    i_id_sr_supply_count        ID sr_supply_count
    *
    * @param    o_error                     t_error_out
    * 
    * @author  Filipe Silva
    * @version 2.6.0.4
    * @since   2010/12/07
    **********************************************************************************************/
    FUNCTION tf_surg_supply_count
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_sr_supply_count IN sr_supply_count.id_sr_supply_count%TYPE
    ) RETURN t_surg_supply_count
        PIPELINED;

    /**********************************************************************************************
    * Prepare supplies for surgery.
    * 
    * @param    i_lang                      Language ID
    * @param    i_prof                      Professional's info
    * @param    i_id_supply_workflow        Supply workflow ID
    * @param    i_barcode_scanned           Barcode scanned
    * @param    i_cod_table                 Code table where the supplies is prepared
    * @param    i_id_episode                Episode ID
    
    * @param    o_error                     t_error_out
    * 
    * @return                      True on success, false on error
    * 
    * @author  Filipe Silva
    * @version 2.6.0.4
    * @since   2010/10/14
    **********************************************************************************************/

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

    /**********************************************************************************************
    * The user may skip the workflow "Ordered to Central Stock" directly to "Ready for preparation" status
    * by choosing  the "Ready for preparation" action in the action button.
    * 
    * @param    i_lang                      Language ID
    * @param    i_prof                      Professional's info
    * @param    i_id_supply_workflow        Table number with supply workflow ID
    *
    * @param    o_id_supply_workflow        Table number with supply workflow ID
    * @param    o_error                     t_error_out
    * 
    * @return                               True on success, false on error
    * 
    * @author  Filipe Silva
    * @version 2.6.0.4
    * @since   2010/10/19
    **********************************************************************************************/
    FUNCTION set_ready_for_preparation
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN table_number,
        o_id_supply_workflow OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get supply attributs ( reusable, editable, preparing and countable)
    * 
    * @param    i_lang                      Language ID
    * @param    i_prof                      Professional's info
    * @param    i_supply_soft_inst          Primary key supply_soft_inst table
    *
    * @param    o_flg_reusable              Table varchar with flag reusable
    * @param    o_flg_editable              Table varchar with flag editable
    * @param    o_flg_preparing             Table varchar with flag preparing
    * @param    o_flg_countable             Table varchar with flag countable
    * @param    o_error                     t_error_out
    * 
    * @return                      True on success, false on error
    * 
    * @author  Filipe Silva
    * @version 2.6.0.4
    * @since   2010/09/13
    **********************************************************************************************/

    FUNCTION get_supply_attributs
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_supply_soft_inst IN table_number,
        o_flg_reusable     OUT table_varchar,
        o_flg_editable     OUT table_varchar,
        o_flg_preparing    OUT table_varchar,
        o_flg_countable    OUT table_varchar,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Detail of supply count
    * 
    * @param    i_lang                      Language ID
    * @param    i_prof                      Professional's info
    * @param    i_id_sr_supply_count        ID sr_supply_count
    *
    * @param    o_error                     t_error_out
    * 
    * @return                               True on success, false on error
    * 
    * @author  Filipe Silva
    * @version 2.6.0.4
    * @since   2010/12/06
    **********************************************************************************************/
    FUNCTION get_supply_count_detail
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_sr_supply_count  IN sr_supply_count.id_sr_supply_count%TYPE,
        o_supply_count_detail OUT pk_types.cursor_type,
        o_error               OUT t_error_out
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
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_subject     IN action.subject%TYPE,
        i_from_state  IN action.from_state%TYPE,
        i_flg_set     IN VARCHAR2,
        i_episode     IN episode.id_episode%TYPE DEFAULT NULL,
        i_id_hhc_req  IN epis_hhc_req.id_epis_hhc_req%TYPE DEFAULT NULL,
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
        i_episode    IN episode.id_episode%TYPE DEFAULT NULL,
        i_id_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE DEFAULT NULL,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_supply_available_quantity
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE
    ) RETURN NUMBER;

    FUNCTION get_supply_kit_info
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_supply_area   IN supply_area.id_supply_area%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_consumption_type IN supply_soft_inst.flg_cons_type%TYPE,
        i_supply           IN supply.id_supply%TYPE,
        i_id_inst_dest     IN institution.id_institution%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    FUNCTION revert_supply_consumption
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE init_params
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
    g_error      VARCHAR2(4000);
    g_error_code VARCHAR2(100);

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50);
    g_found        BOOLEAN;

END pk_supplies_core;
/
