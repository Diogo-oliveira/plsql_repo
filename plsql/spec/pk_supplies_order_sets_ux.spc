/*-- Last Change Revision: $Rev: 1877368 $*/
/*-- Last Change by: $Author: adriano.ferreira $*/
/*-- Date of last change: $Date: 2018-11-12 15:39:19 +0000 (seg, 12 nov 2018) $*/

CREATE OR REPLACE PACKAGE pk_supplies_order_sets_ux IS

    /**
    * Creates a predefined supply_workflow request
		* Used for supplies area (id_supply_area=1)
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_supply                     Array of supplies identifiers
    * @param   i_supply_set                 Array of parent supplies set (if applicable)
    * @param   i_supply_qty                 Array of supplies quantities
    * @param   i_supply_loc                 Array of supplies location
    * @param   i_id_req_reason              Array of reasons for each supply
    * @param   i_notes                      Array of request notes
    * @param   i_supply_soft_inst           Array of supplies configuration identifiers
    * @param   o_id_supply_workflow         Array of new supply_workflow identifiers
    * @param   o_error                      Error information       
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   18-06-2014
    */
    FUNCTION create_predefined_task
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_supply             IN table_number,
        i_supply_set         IN table_number,
        i_supply_qty         IN table_number,
        i_supply_loc         IN table_number,
        i_id_req_reason      IN table_number,
        i_notes              IN table_varchar,
        i_supply_soft_inst   IN table_number,
        o_id_supply_workflow OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;


    /**
    * Creates a predefined supply_workflow request
		* Used for surgical supplies area (id_supply_area=3)
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
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
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   18-06-2014
    */
    FUNCTION create_predefined_task_sr
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
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
    * Updates a task
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_supply_workflow            Array of supply_workflow identifiers
    * @param   i_supply                     Array of supply identifiers
    * @param   i_supply_set                 Array of parent supplies set (if applicable)
    * @param   i_supply_qty                 Array of supplies quantities
    * @param   i_supply_loc                 Array of supplies locations
    * @param   i_dt_request                 Array of dates of request
    * @param   i_dt_return                  Array of estimated dates of return
    * @param   i_id_req_reason              Array of reasons for each supply
		* @param   i_id_context                 Array of surgical procedures, in case of a surgical supply
		* @param   i_id_context                 Array of surgical procedures, in case of a surgical supply
		* @param   i_flg_cons_type              Array of flags indicating consumption type
    * @param   i_notes                      Request notes
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   18-06-2014
    */
    FUNCTION set_task_parameters
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
				i_supply_workflow IN table_number,
        i_supply          IN table_number,
        i_supply_set      IN table_number,
        i_supply_qty      IN table_number,
        i_supply_loc      IN table_number,
        i_dt_request      IN table_varchar,
        i_dt_return       IN table_varchar,
        i_id_req_reason   IN table_number,
        i_id_context      IN table_number,
				i_flg_cons_type   IN table_varchar,
        i_notes           IN table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

END pk_supplies_order_sets_ux;
/
