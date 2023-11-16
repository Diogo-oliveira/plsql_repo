/*-- Last Change Revision: $Rev: 2045844 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2022-09-22 10:25:09 +0100 (qui, 22 set 2022) $*/

CREATE OR REPLACE PACKAGE pk_supplies_api_db IS

    TYPE supplies_type IS RECORD(
        id_supply            NUMBER(24),
        id_parent_supply     NUMBER(24),
        desc_supply          VARCHAR2(1000 CHAR),
        desc_supply_attrib   VARCHAR2(1000 CHAR),
        desc_cons_type       VARCHAR2(1000 CHAR),
        flg_cons_type        VARCHAR2(2),
        quantity             NUMBER(12),
        dt_return            VARCHAR2(50 CHAR),
        id_supply_location   NUMBER(24),
        desc_supply_location VARCHAR2(1000 CHAR),
        flg_type             VARCHAR2(2 CHAR),
        id_context           VARCHAR2(20 CHAR),
        rank                 NUMBER(12),
        id_supply_soft_inst  NUMBER(24));

    TYPE tbl_supplies_type IS TABLE OF supplies_type;

    /**********************************************************************************************
    * Creates a supply request.
    * 
    * @i_lang              Language ID
    * @i_prof              Professional's info
    * @i_id_supply_area    supply area ID
    * @i_id_episode        Episode ID
    * @i_supply            Supply ID
    * @i_supply_set        Parent supply set (if applicable)
    * @i_supply_qty        Supply quantity
    * @i_supply_loc        Supply location
    * @i_dt_request        Date of request
    * @i_dt_return         Estimated date of of return
    * @i_id_req_reason     Reasons for each supply
    * @i_flg_reason_req    Reason for request
    * @i_id_context        Request's context ID
    * @i_flg_context       Request's context
    * @i_notes             Request notes
    * @o_id_supply_request Created request ID
    * @i_flg_preparing     Flag for preparing surgical supplies: Y-Yes, N- No    
    * @i_flg_countable     Flag for count surgical supplies: Y-Yes, N- No    
    * @i_id_supply_area    Id supply area 
    * @i_flg_status        Flag_status 
    * @i_barcode_scanned   Barcode scanned
    * @i_cod_table         Table code for surgery supplies
    * @o_error             Error info
    * 
    * @return              True on success, false on error
    * 
    * @author              Joao Martins
    * @version             2.5.0.7
    * @since               2009/10/24
    **********************************************************************************************/
    FUNCTION create_request
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
        i_id_context        IN supply_request.id_context%TYPE,
        i_flg_context       IN supply_request.flg_context%TYPE,
        i_notes             IN table_varchar,
        i_flg_cons_type     IN table_varchar,
        i_flg_reusable      IN table_varchar,
        i_flg_editable      IN table_varchar,
        i_flg_preparing     IN table_varchar,
        i_flg_countable     IN table_varchar,
        i_supply_soft_inst  IN table_number,
        i_supply_flg_status IN supply_request.flg_status%TYPE,
        i_id_inst_dest      IN institution.id_institution%TYPE DEFAULT NULL,
        o_id_supply_request OUT supply_request.id_supply_request%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Registers the consumption of supplies.
    * 
    * @i_lang               Language ID
    * @i_prof               Professional's info
    * @i_id_episode         Episode ID
    * @i_id_context         Context ID
    * @i_flg_context        Flag for context
    * @i_id_supply_workflow Workflow IDs
    * @i_supply             Supplies' IDs
    * @i_supply_set         Parent supply set (if applicable)
    * @i_supply_qty         Supply quantities
    * @i_flg_supply_type    Supply or supply Kit
    * @i_barcode_scanned    Barcode scanned
    * @i_deliver_needed     Deliver needed
    * @i_flg_cons_type      Consumption type
    * i_dt_expected_date    Expected return date
    * @o_error              Error info
    * 
    * @return               True on success, false on error
    * 
    * @author               Joao Martins
    * @version              2.5.0.7
    * @since                2009/10/25
    * @updated              Sofia Mendes (07-Jun-2010)
    *                       Added the oportunity of checking if the nr of units being loaned is lower that the nr of
    *                       available units
    **********************************************************************************************/

    FUNCTION set_supply_consumption
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
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_supply_order
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_supply            IN table_number,
        i_supply_set        IN table_number,
        i_supply_qty        IN table_number,
        i_dt_request        IN table_varchar,
        i_dt_return         IN table_varchar,
        i_id_context        IN supply_request.id_context%TYPE,
        i_flg_context       IN supply_request.flg_context%TYPE,
        i_supply_flg_status IN supply_request.flg_status%TYPE,
        i_lot               IN table_varchar DEFAULT NULL,
        i_barcode_scanned   IN table_varchar DEFAULT NULL,
        i_dt_expiration     IN table_varchar DEFAULT NULL,
        i_flg_validation    IN table_varchar DEFAULT NULL,
        i_supply_loc        IN table_number DEFAULT NULL,
        o_supply_request    OUT supply_request.id_supply_request%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_supply_order
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_id_content_supply     IN table_varchar,
        i_id_content_supply_set IN table_varchar,
        i_supply_qty            IN table_number,
        i_dt_request            IN table_varchar,
        i_dt_return             IN table_varchar,
        i_id_context            IN supply_request.id_context%TYPE,
        i_flg_context           IN supply_request.flg_context%TYPE,
        i_notes                 IN table_varchar,
        i_type_request          IN VARCHAR2,
        o_supply_request        OUT supply_request.id_supply_request%TYPE,
        o_supply_workflow       OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Cancels a supply, indicating the cancelation reason.
    * 
    * @i_lang  Language ID
    * @i_prof  Professional's info
    * @i_supplies supplies to be rejected
    * @i_id_episode episode
    * @i_rejection_notes    rejection notes to log
    * @o_error Error info
    * 
    * @return  True on success, false on error
    * 
    * @author  João Almeida
    * @version 2.5.0.7
    * @since   28/10/09
    **********************************************************************************************/
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

    /**********************************************************************************************
    * Set a supply to a conclude devolution status
    * 
    * @i_lang  Language ID
    * @i_prof  Professional's info
    * @i_supplies supplies 
    * @i_barcode scanned barcode
    * @o_error Error info
    * 
    * @return  True on success, false on error
    * 
    * @author  João Almeida
    * @version 2.5.0.7
    * @since   16/11/09
    **********************************************************************************************/
    FUNCTION set_supply_devolution
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_supplies IN table_number,
        i_barcode  IN table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Set a supply to a prepared status
    * 
    * @i_lang  Language ID
    * @i_prof  Professional's info
    * @i_supplies supplies
    * @i_unic_id unic identifier of the supply 
    * @i_prepared_by profissional who prepared the supply
    * @i_prep_notes notes about supply preparation
    * @i_new_supplies new supplies to replace existing ones
    * @o_error Error info
    * 
    * @return  True on success, false on error
    * 
    * @author  João Almeida
    * @version 2.5.0.7
    * @since   16/11/09
    **********************************************************************************************/
    FUNCTION set_supply_preparation
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_supplies     IN table_number,
        i_id_patient   IN patient.id_patient%TYPE,
        i_unic_id      IN table_number,
        i_prepared_by  IN table_varchar,
        i_prep_notes   IN table_varchar,
        i_new_supplies IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pharmacy_delivery
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_pha_dispense IN table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Saves the current state of a supply_workflow record to the history table.
    * 
    * @i_id_supply_workflow Supply Workflow ID
    * 
    * @author  Joao Martins
    * @version 2.5.0.7
    * @since   2009/10/25
    **********************************************************************************************/
    PROCEDURE set_supply_workflow_hist
    (
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE,
        i_id_context         IN supply_workflow.id_context%TYPE,
        i_flg_context        IN supply_workflow.flg_context%TYPE
    );

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
    * @param    i_cod_table                Code table
    *
    * @param    o_id_supply_request         Created Request ID
    * @param    o_error                     Error message
    * 
    * @return   True on success , false on error
    * 
    * @author   Filipe Silva
    * @version  2.6.0.4
    * @since    2010/11/23
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
    * Updates a supply requests status 
    * 
    * @i_lang                   Language ID
    * @i_prof                   Professional's info    
    * @i_supplies               list of Supplies
    * @i_episode                Current Episode  
    * @i_cancel_notes           Cancelation Notes
    * @i_id_cancel_reason       Id Cancel Reason
    * @i_flg_status             list of Status
    * @i_notes                  Request notes
    * @o_error                  Error info
    * 
    * @return  True on success, false on error
    * 
    * @author  Teresa Coutinho
    * @version 2.6.2
    * @since   27/03/2012
    **********************************************************************************************/

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

    FUNCTION cancel_supply_order
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_supply_workflow  IN table_number,
        i_notes            IN table_clob,
        i_id_cancel_reason IN table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_supply_order
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_context    IN supply_context.id_context%TYPE,
        i_flg_context   IN supply_context.flg_context%TYPE,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes  IN supply_request.notes%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Cancels a supply request.
    * 
    * @i_lang           Language ID
    * @i_prof           Professional's info
    * @i_supply_request Supply request
    * @i_notes          Cancel notes
    * @o_error          Error info
    * 
    * @return           True on success, false on error
    * 
    * @author           Joao Martins
    * @version          2.5.0.7
    * @since            2009/10/26
    **********************************************************************************************/
    FUNCTION cancel_request
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_supply_request   IN supply_request.id_supply_request%TYPE,
        i_notes            IN supply_request.notes%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

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
    * Return id_supply_area 
    * 
    * This is a workaround to get the id supply area from supplies and activity therapist area´s
    * The id supply area from surgical supplies, is sent from pk_supplies_api_db functions 
    * 
    * @param    i_lang                      Language ID
    * @param    i_prof                      Professional's info
    * @param    i_id_supply                 ID supply
    * @param    i_flg_type                  Type of supply
    * @param    i_id_supply_workflow        Supply Workflow ID
    *
    * @param    o_id_supply_area            ID supply area
    * @param    o_error                     t_error_out
    * 
    * @return                               True on success, false on error
    * 
    * @author  Jorge Canossa
    * @version 2.6.0.4
    * @since   2010/10/11
    **********************************************************************************************/
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

    /**********************************************************************************************
    * Returns the items configurated
    * 
    * @i_lang  Language ID
    * @i_prof  Professional's info
    * @i_id_supply_area   supply area ID
    * @i_episode  episode info
    * @i_consumption_type  Consumption type
    * @i_flg_type  Flag type
    * @i_id_supply  Supply identification
    * @i_id_supply_type  Supply Type identification
    * @o_supply_inf  Supply information
    * @o_supply_type  Supply type information
    * @o_supply_items Supply items information
    * @o_flg_selected Flag indicates when the supplies must be selected
    * @o_error Error info 
    * 
    * @return  True on success, false on error
    * 
    * @author  Susana Silva
    * @version 2.5.0.7
    * @since   2009/11/09
    **********************************************************************************************/

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
    * @author  João Almeida
    * @version 2.5.0.7
    * @since   9/11/09
    **********************************************************************************************/

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
    * @author        Luís Maia
    * @version       2.6.0.3
    * @since         09/Jun/2010
    **********************************************************************************************/
    FUNCTION get_list_req_cons_report
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN episode.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_flg_type IN supply.flg_type%TYPE,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns a list with the selectable types (e.g. supplies, kits or sets)..
    * 
    * @i_lang  Language ID
    * @i_prof  Professional's info
    * @i_id_supply_area supply area ID
    * @i_episode  episode info
    * @i_consumption_type  Consumption type
    * @o_selection_list of types
    * @o_error Error info
    * 
    * @return  True on success, false on error
    * 
    * @author  Susana Silva
    * @version 2.5.0.7
    * @since   2009/11/03
    **********************************************************************************************/
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
    * @author  João Almeida
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
        i_dep_clin_serv IN interv_dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        o_supplies      OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns a list of supplies associated by default (configured by institution or professional)
    * to medication and procedures
    * 
    * @i_lang         Language ID
    * @i_prof         Professional's info
    * @i_id_context_m Medication ids
    * @i_id_context_p Procedures ids
    * @o_supplies     List of supplies
    * @o_error        Error info
    * 
    * @return        True on success, false on error
    **********************************************************************************************/
    FUNCTION get_supplies_by_context
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_context_m  IN table_varchar,
        i_id_context_p  IN table_varchar,
        i_dep_clin_serv IN interv_dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        o_supplies      OUT pk_types.cursor_type,
        o_error         OUT t_error_out
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

    /* supply workflow details for the details screen.
    * Some liberties taken because no design is available. 
    *
    * @i_lang                   Language ID
    * @i_prof                   Professional info
    * @i_id_sup_wf              supply id
    * @o_register               main cursor. holds all status transitions and their ids and dates
    * @o_req                    requisition status. holds initial status info. 1 row only
    * @o_canc                   cursor for all cancel status in the life of this req.
    * @o_error                  error info, if any
    * 
    * @return  True on success, false on error
    * 
    * @author  Telmo
    * @version 2.5.0.7
    * @since   04-11-2009
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
        i_id_episode         IN supply_workflow.id_episode%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Returns possible consumption types 
    * 
    * @param    i_lang                      Language ID
    * @param    i_prof                      Professional's info
    * @param    i_flg_context               Context  
    * @param    i_id_supply                 id_supply
    *
    * @param    o_type_consumption          cursor with consumption type list
    * @param    o_error                     t_error_out
    * 
    * @return                               True on success, false on error
    * 
    * @author  Jorge Canossa
    * @version 2.6.0.4
    * @since   2010/10/01
    **********************************************************************************************/

    FUNCTION get_type_consumption_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_supply_area   IN supply_area.id_supply_area%TYPE,
        i_id_supply        IN supply.id_supply%TYPE,
        o_type_consumption OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_max_supply_delay
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN patient.id_patient%TYPE,
        i_phar_main_grid IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2;

    FUNCTION get_supplies_for_modal_window
    (
        i_lang     IN NUMBER,
        i_prof     IN profissional,
        i_supplies IN pk_supplies_core.tbl_supplies_by_context
    ) RETURN VARCHAR2;

    FUNCTION get_supplies_procedure_grid
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_supplies      IN VARCHAR2,
        o_supplies_info OUT pk_types.cursor_type,
        o_error         OUT t_error_out
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

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_other_exception EXCEPTION;
    g_user_exception  EXCEPTION;
    g_error      VARCHAR2(4000);
    g_error_code VARCHAR2(100);

END pk_supplies_api_db;
/
