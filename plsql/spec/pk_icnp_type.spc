/*-- Last Change Revision: $Rev: 2028735 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:37 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_icnp_type IS

    --------------------------------------------------------------------------------
    -- GENERIC PACKAGE TYPES
    --------------------------------------------------------------------------------

    -- Type for the text messages that briefly describes the current operation
    SUBTYPE t_current_operation IS VARCHAR2(1000 CHAR);
    -- Type used to identify the package owner
    SUBTYPE t_package_owner IS VARCHAR2(32 CHAR);
    -- Type used to identify the package name
    SUBTYPE t_package_name IS VARCHAR2(32 CHAR);
    -- Type used to identify the function name
    SUBTYPE t_function_name IS VARCHAR2(50 CHAR);
    -- Type used to identify the exception name when throwing exceptions
    SUBTYPE t_exception_name IS VARCHAR2(4000);

    --------------------------------------------------------------------------------
    -- DATE TYPES
    --------------------------------------------------------------------------------

    -- Serialized timestpamp used to communicate with the UX layer
    SUBTYPE t_serialized_timestamp IS VARCHAR2(14 CHAR);

    --------------------------------------------------------------------------------
    -- TYPES USED IN GET_INSTRUCTIONS
    --------------------------------------------------------------------------------

    -- Type used to specify the instruction mask of an icnp intervention; the mask is 
    -- used to define which information appear and in which order
    SUBTYPE t_instruction_mask IS VARCHAR2(3 CHAR);
    -- Type used to return the text with the instructions of a given icnp instruction
    SUBTYPE t_instruction_desc IS VARCHAR2(1000 CHAR);

    --------------------------------------------------------------------------------
    -- TYPES USED IN SUGGESTIONS
    --------------------------------------------------------------------------------

    -- Type used in pk_icnp_suggestion.set_suggs_status_accept to associate a 
    -- suggestion with an intervention
    TYPE t_interv_suggested_rec IS RECORD(
        id_icnp_epis_interv icnp_suggest_interv.id_icnp_epis_interv%TYPE,
        id_icnp_sug_interv  icnp_suggest_interv.id_icnp_sug_interv%TYPE);
    TYPE t_interv_suggested_coll IS TABLE OF t_interv_suggested_rec;

    --------------------------------------------------------------------------------
    -- TYPES USED IN EXECUTIONS
    --------------------------------------------------------------------------------

    -- Type used in pk_icnp_exec.set_execs_status_execute; it has all the data needed
    -- to correctly execute an intervention
    TYPE t_exec_interv_rec IS RECORD(
        id_icnp_interv_plan  icnp_interv_plan.id_icnp_interv_plan%TYPE,
        id_icnp_epis_interv  icnp_interv_plan.id_icnp_epis_interv%TYPE,
        id_order_recurr_plan icnp_epis_intervention.id_order_recurr_plan%TYPE,
        exec_number          icnp_interv_plan.exec_number%TYPE);
    TYPE t_exec_interv_coll IS TABLE OF t_exec_interv_rec;

END pk_icnp_type;
/
