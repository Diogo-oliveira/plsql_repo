/*-- Last Change Revision: $Rev: 2051362 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2022-11-28 09:52:13 +0000 (seg, 28 nov 2022) $*/

CREATE OR REPLACE PACKAGE pk_supplies_external IS

    TYPE t_rec_priority_task IS RECORD(
        dt_supply_workflow supply_workflow.dt_supply_workflow%TYPE,
        flg_status         supply_workflow.flg_status%TYPE,
        id_status          supplies_wf_status.id_status%TYPE,
        flg_display_type   supplies_wf_status.flg_display_type%TYPE);

    TYPE t_supply_priority_task IS TABLE OF t_rec_priority_task;

    TYPE supplies_type_cfg IS RECORD(
        id_supply_soft_inst  NUMBER(24),
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
        flg_consumed         VARCHAR2(1 CHAR));

    TYPE tbl_supplies_type_cfg IS TABLE OF supplies_type_cfg;

    TYPE supplies_type_req IS RECORD(
        id_supply_workflow NUMBER(24),
        id_supply          NUMBER(24),
        flg_type           VARCHAR2(2 CHAR),
        desc_supply        VARCHAR2(1000 CHAR),
        quantity           NUMBER(12),
        flg_status         VARCHAR2(1 CHAR),
        barcode_req        VARCHAR2(200 CHAR),
        flg_reusable       VARCHAR2(1 CHAR),
        id_supply_set      NUMBER(24),
        set_description    VARCHAR2(1000 CHAR),
        flg_cons_type      VARCHAR2(1 CHAR),
        desc_supply_attrib VARCHAR2(1000 CHAR),
        id_parent_supply   NUMBER(24),
        flg_dispensed      VARCHAR2(1 CHAR),
        barcode_scanned    VARCHAR2(1000 CHAR),
        lot                VARCHAR2(1000 CHAR),
        dt_expiration      TIMESTAMP(6) WITH LOCAL TIME ZONE);

    TYPE tbl_supplies_type_req IS TABLE OF supplies_type_req;

    PROCEDURE exams_____________________;

    PROCEDURE procedures________________;

    PROCEDURE surgical_procedures_______;

    FUNCTION get_supply_priority_task
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN t_supply_priority_task
        PIPELINED;

    PROCEDURE order_sets________________;

    PROCEDURE activity_therapy__________;

    PROCEDURE nanda_nic_noc_____________;

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

    /********************************************************************************************
    *   Returns biggest delay among of surgical supplies 
    *
    * @param i_lang             Language ID
    * @param i_prof             Professional ID
    * @param i_id_episode       ORIS episode ID
    * @param i_material_req     Surgical supplies string grid task
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Filipe Silva
    * @since                    2010/10/22
    ********************************************************************************************/

    FUNCTION get_surg_supplies_reg
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_material_req IN grid_task.material_req%TYPE
    ) RETURN VARCHAR2;

    /**
    * Order predefined supply_workflow and links them into the same supply_request
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_supply_workflow         Supply_workflow identifier
    * @param   i_id_episode                 New episode identifier. If null, copy value from the original
    * @param   o_id_supply_request          New supply_request identifier created
    * @param   o_id_supply_workflow         Array of new supply_workflow identifiers updated/created
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   25-06-2014
    */
    FUNCTION set_supply_wf_order_predf
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_supply_workflow    IN table_number,
        i_id_episode         IN supply_workflow.id_episode%TYPE,
        o_id_supply_request  OUT table_number,
        o_id_supply_workflow OUT table_table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Update supply workflow
    * 
    * @param    i_lang                      Language ID
    * @param    i_prof                      Professional
    * @param    i_id_episode                ID episode
    * @param    i_id_supply_workflow        ID supply workflow
    * @param    i_flg_status                Flag status  
    * @param    i_supply                    ID supply
    * @param    i_supply_set                Parent supply set (if applicable)
    * @param    i_supply_qty                Supply quantity
    * @param    i_supply_loc                Supply location
    * @param    i_dt_return                 Return date
    * @param    i_id_req_reason             Reasons for each supply
    * @param    i_id_context                Request's context ID
    * @param    i_notes                     Request notes
    * @param    i_flg_cons_type             Flag of consumption type
    * @param    i_cod_table                 Code table
    *
    * @param    o_error                     Error message
    * 
    * @return   True on success , false on error
    * 
    * @author  Filipe Silva
    * @version 2.6.0.4
    * @since   2010/11/23
    **********************************************************************************************/
    FUNCTION set_edit_supply
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_supply_workflow IN table_number,
        i_supply          IN table_number,
        i_supply_qty      IN table_number,
        i_supply_loc      IN table_number,
        i_dt_return       IN table_varchar,
        i_id_req_reason   IN table_number,
        i_id_context      IN table_number,
        i_notes           IN table_varchar,
        i_flg_cons_type   IN table_varchar,
        i_cod_table       IN table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets supply_workflow instructions
    *
    * @param   i_lang                 Professional preferred language
    * @param   i_prof                 Professional identification and its context (institution and software)
    * @param   i_task_request         Supply_workflow request id
    * @param   o_task_instr           Task instructions
    * @param   o_error                error structure for exception handling
    *
    * @return  boolean                True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   22-07-2014
    */
    FUNCTION get_task_instructions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN supply_workflow.id_supply_workflow%TYPE,
        o_task_instr   OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Cancels a supply, indicating the cancelation reason.
    * 
    * @param i_lang                      Language ID
    * @param i_prof                      Professional's info
    * @param i_supplies                  supplies to be rejected
    * @param i_id_episode                episode
    * @param i_rejection_notes           rejection notes to log
    * @param o_error                     Error info
    * 
    * @return                      True on success, false on error
    * 
    * @author  Filipe Silva
    * @version 2.6.0.4
    * @since   2010/09/07
    **********************************************************************************************/
    FUNCTION cancel_supply
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_supplies         IN table_number,
        i_id_episode       IN supply_workflow.id_episode%TYPE,
        i_cancel_notes     IN supply_workflow.notes_cancel%TYPE,
        i_id_cancel_reason IN supply_workflow.id_cancel_reason%TYPE,
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

    /**********************************************************************************************
    * Calcule biggest delay among of surgical supplies for pharmacist profile
    * 
    * @param    i_lang                      Language ID
    * @param    i_prof                      Professional's info
    * @param    i_id_episode                Episode ID
    * @param    i_dt_supply_workflow        Supply's date
    * @param    i_phar_main_grid            (Y) calcule biggest delay for pharmacist' main grid, 
                                            (N) others pharmacist grids
    * 
    * @return                               Return string with the biggest delay supply task
    * 
    * @author  Filipe Silva
    * @version 2.6.0.4
    * @since   2010/11/19
    **********************************************************************************************/

    FUNCTION check_max_delay_sup_pharmacist
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_dt_supply_workflow IN supply_workflow.dt_supply_workflow%TYPE,
        i_phar_main_grid     IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN TIMESTAMP
        WITH TIME ZONE;

    /**********************************************************************************************
    * Associate surgical supplies to a surgical procedure
    * 
    * @param    i_lang                      Language ID
    * @param    i_prof                      Professional's info
    * @param    i_id_sr_epis_interv         Primary key of sr_epis_interv
    * @param    i_id_episode                Episode ID
    * @param    i_supply                    Supply ID,
    * @param    i_supply_set                Parent supply set (if applicable),
    * @param    i_supply_qty                Supply quantity,
    * @param    i_supply_loc                Supply location
    * @param    i_dt_return                 Estimated date of of return,
    * @param    i_supply_soft_inst          List,
    * @param    i_flg_cons_type             flag of consumption type
    * @param    i_id_req_reason             Reasons for each supply
    * @param    i_notes                     Request notes
    *
    * @param    o_error                     t_error_out
    * 
    * @return                               True on success, false on error
    * 
    * @author  Filipe Silva
    * @version 2.6.0.4
    * @since   2010/09/13
    **********************************************************************************************/
    FUNCTION set_supplies_surg_proc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_sr_epis_interv IN table_number,
        i_id_episode        IN episode.id_episode%TYPE,
        i_supply            IN table_table_number,
        i_supply_set        IN table_table_number,
        i_supply_qty        IN table_table_number,
        i_supply_loc        IN table_table_number,
        i_dt_return         IN table_table_varchar,
        i_supply_soft_inst  IN table_table_number,
        i_flg_cons_type     IN table_table_varchar,
        i_id_req_reason     IN table_table_number,
        i_notes             IN table_table_varchar,
        i_id_inst_dest      IN institution.id_institution%TYPE DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get status info for surgical supplies tasks
    *
    * @param i_lang             Language ID
    * @param i_prof             Professional ID
    * @param i_id_episode       ORIS episode ID
    * @param i_date             Request date
    * @param i_phar_main_grid   (Y) - function called by pharmacist main grids; (N) otherwise 
    * @param io_icon_info        WF_STATUS_CONFIG data
    * @param io_icon_type       Icon type
    *
    * @param o_status_info      WF_STATUS_CONFIG data
    * @param o_surgery_date     Surgery date
    * @param o_error            Error message
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Filipe Silva
    * @since                    2010/10/29
    ********************************************************************************************/

    FUNCTION get_sr_status_info
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_date           IN supply_workflow.dt_request%TYPE,
        i_phar_main_grid IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        io_icon_info     IN OUT t_rec_wf_status_info,
        io_icon_type     IN OUT supplies_wf_status.flg_display_type%TYPE,
        o_surgery_date   OUT schedule_sr.dt_target_tstz%TYPE,
        o_icon_color     OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Checks if there is loaned supplies associated to an episode.
    * 
    * @param i_lang     Language ID
    * @param i_episode  episode info
    * @param o_error    t_error_out
    * 
    * @return  success/fail
    * 
    * @author  Sofia Mendes
    * @version 2.6.0.3
    * @since   20-Mai-2010
    **********************************************************************************************/

    FUNCTION check_loaned_supplies
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns a description indicating if the episode has (or not) loaned supplies.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure     
    * @param i_id_episode     Episode identifier      
    *
    * @return                 Description indicating if the episode has (or not) loaned supplies
    *
    * @author                 Sofia Mendes
    * @version                2.6.0.3
    * @since                  15-Jun-2010
    */
    FUNCTION get_has_supplies_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN sys_domain.desc_val%TYPE;

    /**
    * Creates a new supply_workflow based on an existing one (copy)
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_supply_workflow         Supply_workflow identifier
    * @param   i_id_episode                 New episode identifier. If null, copy value from the original
    * @param   i_dt_request                 New date of request. If null, copy value from the original
    * @param   o_id_supply_workflow         New supply_workflow identifier created
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   25-06-2014
    */
    FUNCTION copy_supply_wf
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE,
        i_id_episode         IN supply_workflow.id_episode%TYPE DEFAULT NULL,
        i_dt_request         IN supply_workflow.dt_request%TYPE DEFAULT NULL,
        o_id_supply_workflow OUT supply_workflow.id_supply_workflow%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates a set of predefined supply_workflows (in order to be used in order sets)
    * 
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_supply_area             Supply area identifier
    * @param   i_supply                     Array of supplies identifiers
    * @param   i_supply_set                 Array of parent supplies set (if applicable)
    * @param   i_supply_qty                 Array of supplies quantities
    * @param   i_supply_loc                 Array of supplies location
    * @param   i_id_req_reason              Array of reasons for each supply
    * @param   i_notes                      Array of request notes
    * @param   i_supply_soft_inst           Array of supplies configuration identifiers
    * @param   i_flg_cons_type              Array of flag of consumption type
    * @param   o_id_supply_workflow         Array of new supply_workflow identifiers
    * @param   o_error                      Error information
    *
    * @return  True on success, false on error
    * 
    * @author  ana.monteiro
    * @version 1.0
    * @since   18-Jun-2014
    */
    FUNCTION create_supply_wf_predf
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_area     IN supply_area.id_supply_area%TYPE,
        i_supply             IN table_number,
        i_supply_set         IN table_number,
        i_supply_qty         IN table_number,
        i_supply_loc         IN table_number,
        i_id_req_reason      IN table_number,
        i_notes              IN table_varchar,
        i_supply_soft_inst   IN table_number,
        i_flg_cons_type      IN table_varchar,
        o_id_supply_workflow OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Deletes an existing predefined supply_workflow
    * 
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_supply_workflow            Array of suppply_workflow identifiers to be removed (must be in a predefined state)
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   19-06-2014
    */
    FUNCTION delete_supply_workflow
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_supply_workflow IN table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION delete_supplies_by_context
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_context  IN supply_request.id_context%TYPE,
        i_flg_context IN supply_request.flg_context%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns a string with the supplies associated to a specific context.
    * 
    * @i_lang        Language ID
    * @i_prof        Professional's info
    * @i_id_context  Context ID
    * @i_flg_context Flag for context
    * @i_flg_status  Requisition status
    * 
    * @return        True on success, false on error
    * 
    * @author        Joao Martins
    * @version       2.5.0.7
    * @since         2009/11/16
    **********************************************************************************************/
    FUNCTION get_context_supplies_str
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_context  IN supply_context.id_context%TYPE,
        i_flg_context IN supply_context.flg_context%TYPE,
        i_flg_status  IN table_varchar DEFAULT NULL
    ) RETURN VARCHAR2;

    /********************************************************************************************
     * Returns info about supplies without requests (Image and Other Exams)
     *
     * @param i_lang                 Language ID
     * @param i_prof                 Professional
     * @param i_id_context           Id Context
     * @param i_flg_context          Flg_context
     * @param i_flg_filter_type      C--only consumptions (do not have request), D-only dispenses (has request), A-all
    * @param i_flg_status            Default NULL - Supplies not cancelled or supplies in the past status
     * 
     * @return                 Cursor containing supply info
     * 
     * @author                Teresa Coutinho
     * @version               1.0
     * @since                 2012/01/19
     ********************************************************************************************/

    FUNCTION get_count_supplies_str_all
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_context               IN supply_context.id_context%TYPE,
        i_flg_context              IN supply_context.flg_context%TYPE,
        i_flg_filter_type          IN VARCHAR2 DEFAULT 'A', --C--only consumptions (do not have request), D-only dispenses (has request), A-all
        i_flg_status               IN VARCHAR2 DEFAULT NULL, -- NULL - all, NC - all except cancelled, or status specific
        i_flg_show_set_description IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) RETURN VARCHAR2;

    FUNCTION get_supplies_descr_by_id
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_supply_workflow IN table_varchar,
        i_flg_filter_type IN VARCHAR2 DEFAULT 'A' --C--only consumptions (do not have request), D-only dispenses (has request), A-all
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Check if there're supplies to be cancelled and get the id_supply and id_supply_workflows
    * 
    * @param    i_lang                      Language ID
    * @param    i_prof                      Professional's info
    * @param    i_id_context                Request's context ID
    * @param    i_flg_context               Request's context
    * @param    i_id_supply                 Table number with supplies id
    * @param    i_flg_status                Table varchar with flag status
    *
    * @param    o_has_supplies              Check if there're supplies to be cancelled
    * @param    o_id_supply_workflow        Table number with id_supply_workflows
    * @param    o_id_supply                 Table number with id_supply
    * @param    o_error                     t_error_out
    * 
    * @return                               True on success, false on error
    * 
    * @author  Filipe Silva
    * @version 2.6.0.4
    * @since   2010/10/07
    **********************************************************************************************/
    FUNCTION get_inf_supply_workflow
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_context         IN supply_workflow.id_context%TYPE,
        i_flg_context        IN supply_workflow.flg_context%TYPE,
        i_id_supply          IN table_number,
        i_flg_status         IN table_varchar,
        o_has_supplies       OUT VARCHAR2,
        o_id_supply_workflow OUT table_number,
        o_id_supply          OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_supplies_request
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_context  IN supply_context.id_context%TYPE,
        i_flg_context IN supply_context.flg_context%TYPE,
        o_supplies    OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_supplies_request
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_context  IN supply_context.id_context%TYPE,
        i_flg_context IN supply_context.flg_context%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_supplies_request_history
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_context  IN supply_context.id_context%TYPE,
        i_flg_context IN supply_context.flg_context%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get the supply description.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure       
    * @param i_id_supply              Supply identifier            
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                2.6.0.3
    * @since                  08-07-2010
    */
    FUNCTION get_supply_desc
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_supply IN supply.id_supply%TYPE
    ) RETURN pk_translation.t_desc_translation;

    FUNCTION get_supply_set_description
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_supply_workflow IN supply_workflow.id_supply_workflow%TYPE,
        i_id_supply       IN supply_workflow.id_supply%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_supply_description
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_supply_workflow IN table_varchar,
        i_flg_filter_type IN VARCHAR2 DEFAULT 'A' --C--only consumptions (do not have request), D-only dispenses (has request), A-all
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Returns the nr of units that exists of a given supply.
    * @param i_lang                   id language
    * @param i_prof                   professional, software and institution ids                                            
    * @param i_id_supply_area         Supply area Id
    *
    * @return                         Nr of units of the supply that exists
    *                        
    * @author                         Sofia Mendes
    * @version                        2.6.0.3
    * @since                          21-May-2010
    **********************************************************************************************/
    FUNCTION get_supply_quantity
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_supply_area IN supply_area.id_supply_area%TYPE,
        i_id_supply      IN supply.id_supply%TYPE
    ) RETURN supply_soft_inst.quantity%TYPE;

    /**********************************************************************************************************************
    * Gets the description of supply_workflow for Single Page
    *
    * @param      i_lang                    Language ID
    * @param      i_prof                    profissional identifier
    * @param      i_id_supply_workflow             Supply Workflow ID
    * @param      i_flg_description         Type od description
    * @param      i_description_condition   Fields to show in description
    *
    * return      supply workflow description
    *
    * @author     Lillian Lu
    * @version    2.7.2.3
    * @since      1/2018
    ************************************************************************************************************************/
    FUNCTION get_task_description
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_supply_workflow    IN supply_workflow.id_supply_workflow%TYPE,
        i_flg_description       IN pn_dblock_ttp_mkt.flg_description%TYPE,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE
    ) RETURN CLOB;

    /********************************************************************************************
    * Get history detail info of the loans and deliveries of supplies.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure    
    * @param i_id_supply_area        Supply area Id 
    * @param i_id_episode            Episode identifier  
    * @param i_id_supply_workflow    Supply workflow identifier
    * @param i_id_supply             Supply identifier    
    * @param o_sup_workflow_prof     Professional data
    * @param o_sup_workflow     Professional data
    * @param o_error                 error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                2.6.0.3
    * @since                  06-Mai-2010
    */
    FUNCTION get_workflow_history
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_area     IN supply_area.id_supply_area%TYPE,
        i_id_episode         IN table_number,
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE,
        i_id_supply          IN supply.id_supply%TYPE,
        i_start_date         IN supply_workflow.dt_supply_workflow%TYPE,
        i_end_date           IN supply_workflow.dt_supply_workflow%TYPE,
        i_flg_screen         IN VARCHAR2,
        i_supply_desc        IN VARCHAR2,
        o_sup_workflow_prof  OUT pk_types.cursor_type,
        o_sup_workflow       OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the id_supply_workflow_parent.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure       
    * @param i_id_supply_workflow     Supply workflow parent        
    * @param o_error                  error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                2.6.0.3
    * @since                  17-06-2010
    */
    FUNCTION get_workflow_parent
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE
    ) RETURN supply_workflow.id_supply_workflow%TYPE;

    /**********************************************************************************************
    * Return the id supply workflow 
    * 
    * @param    i_lang                      Language ID
    * @param    i_prof                      Professional's info
    * @param    i_id_supply_workflow        Table number with id_supply_workflows
    *
    * @param    o_error                     t_error_out
    * 
    * @return                               True on success, false on error
    * 
    * @author  Filipe Silva
    * @version 2.6.0.4
    * @since   2010/09/30
    **********************************************************************************************/

    FUNCTION set_independent_supply
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_supply_order
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_supply         IN table_number,
        i_supply_set     IN table_number,
        i_supply_qty     IN table_number,
        i_dt_request     IN table_varchar,
        i_dt_return      IN table_varchar,
        i_id_context     IN supply_request.id_context%TYPE,
        i_flg_context    IN supply_request.flg_context%TYPE,
        o_supply_request OUT supply_request.id_supply_request%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_requested_supplies_per_context
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_context     IN supply_request.flg_context%TYPE,
        i_id_context      IN supply_workflow.id_context%TYPE,
        i_flg_default_qty IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_id_context_m    IN table_varchar DEFAULT NULL,
        i_id_context_p    IN table_varchar DEFAULT NULL,
        o_supplies        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_default_supplies_req_cfg
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_context_d   IN supply_request.flg_context%TYPE,
        i_id_context_d    IN supply_workflow.id_context%TYPE,
        i_id_context_m    IN table_varchar,
        i_id_context_p    IN table_varchar,
        i_flg_default_qty IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_supplies        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_supply_workflow_lst
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_flg_context        IN supply_request.flg_context%TYPE,
        i_id_context         IN supply_workflow.id_context%TYPE,
        o_supply_wokflow_lst OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_supply_default_qty
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_supply     IN supply_workflow.id_supply%TYPE,
        i_id_supply_set IN supply_workflow.id_supply_set%TYPE,
        i_id_context_m  IN table_varchar DEFAULT NULL,
        i_id_context_p  IN table_varchar DEFAULT NULL
    ) RETURN supply_workflow.quantity%TYPE;

    FUNCTION update_supply_record
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_supply_workflow IN table_number,
        i_supply          IN table_number,
        i_supply_set      IN table_number,
        i_supply_qty      IN table_number,
        i_supply_lot      IN table_varchar,
        i_barcode_scanned IN table_varchar,
        i_dt_request      IN table_varchar,
        i_dt_expiration   IN table_varchar,
        i_flg_validation  IN table_varchar,
        i_flg_supply_type IN table_varchar,
        i_deliver_needed  IN table_varchar,
        i_flg_cons_type   IN table_varchar,
        i_flg_consumption IN table_varchar,
        i_id_context      IN supply_request.id_context%TYPE,
        i_flg_context     IN supply_request.flg_context%TYPE,
        o_supply_request  OUT supply_request.id_supply_request%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_supplies_not_in_inicial_status
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_flg_context      IN supply_request.flg_context%TYPE,
        i_id_context       IN supply_workflow.id_context%TYPE,
        i_id_cancel_reason IN supply_workflow.id_cancel_reason%TYPE
    ) RETURN VARCHAR2;

    FUNCTION inactivate_records_by_context
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_supply_workflow IN table_number,
        i_id_context      IN supply_request.id_context%TYPE,
        i_flg_context     IN supply_request.flg_context%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION inactivate_supplies_tasks
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_inst        IN institution.id_institution%TYPE,
        i_ids_exclude IN OUT table_number,
        o_has_error   OUT BOOLEAN,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_other_exception EXCEPTION;
    g_user_exception  EXCEPTION;
    g_error      VARCHAR2(4000);
    g_error_code VARCHAR2(100);

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

END pk_supplies_external;
/
