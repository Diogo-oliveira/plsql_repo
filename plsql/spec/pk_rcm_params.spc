/*-- Last Change Revision: $Rev: 1319805 $*/
/*-- Last Change by: $Author: ana.monteiro $*/
/*-- Date of last change: $Date: 2012-06-06 09:25:43 +0100 (qua, 06 jun 2012) $*/

CREATE OR REPLACE PACKAGE pk_rcm_params IS

    /**
    * Adds interval to the timestamp
    *
    * @param   i_timestamp    Timestamp
    * @param   i_amount       Number of units to add
    * @param   i_unit_measure Unit measure identifier
    * @param   o_error        Error information       
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   11-04-2012
    */
    FUNCTION add_interval
    (
        i_timestamp    IN TIMESTAMP WITH TIME ZONE,
        i_amount       IN NUMBER,
        i_unit_measure IN unit_measure.id_unit_measure%TYPE
    ) RETURN TIMESTAMP
        WITH TIME ZONE;

    /**
    * Gets the parameter value defined for this institution 
    *
    * @param   i_id_rcm_rule     Rule identifier    
    * @param   i_id_rule_inst    Rule instance identifier
    * @param   i_parameter_name  Parameter name. If not defined, returns all parameters.
    * @param   i_id_institution  Institution identifier
    *
    * @return  Parameters values
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   10-04-2012
    */
    FUNCTION get_rule_params_val
    (
        i_id_rcm_rule    IN rcm_inst_param_val.id_rcm_rule%TYPE,
        i_id_rule_inst   IN rcm_inst_param_val.id_rule_inst%TYPE,
        i_parameter_name IN rcm_inst_param_val.parameter_name%TYPE DEFAULT NULL,
        i_id_institution IN rcm_inst_param_val_inst.id_institution%TYPE
    ) RETURN t_coll_rule_param_val
        PIPELINED;

    /**
    * Initializes context parameters
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identifier and its context (institution and software)
    * @param   i_context_keys Context keys 
    * @param   i_context_vals Context values
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   18-04-2012
    */
    PROCEDURE init_params
    (
        i_lang         language.id_language%TYPE,
        i_prof         profissional,
        i_context_keys IN table_varchar,
        i_context_vals IN table_varchar
    );

    /**
    * Loads instance rules configuration into temporary table
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identifier and its context (institution and software)
    * @param   i_id_rcm_rule  Rule identifier. If Null, loads all rules
    * @param   o_error        Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   11-04-2012
    */
    FUNCTION load_instance_data
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_rcm_rule  IN rcm_rule_inst.id_rcm_rule%TYPE,
        i_id_rule_inst IN rcm_rule_inst.id_rule_inst%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets rules and instances info
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identifier and its context (institution and software)
    * @param   o_rcm_rules    Rules info
    * @param   o_error        Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   11-04-2012
    */
    FUNCTION get_rcm_rules
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_rcm_rules OUT pk_rcm_constant.t_cur_rcm_rule,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets text of the rule. Gets patient values from tbl_temp.
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identifier and its context (institution and software)
    * @param   i_id_rcm_rule  Rule identifier
    * @param   i_id_rule_inst Rule instance identifier
    * @param   i_id_patient   Patient identifier
    *
    * @return  Rule text
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   17-04-2012
    */
    FUNCTION get_rule_text
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_rcm_rule  IN rcm_rule_inst_rcm.id_rcm_rule%TYPE,
        i_id_rule_inst IN rcm_rule_inst_rcm.id_rule_inst%TYPE,
        i_id_patient   IN pat_rcm_det.id_patient%TYPE
    ) RETURN pat_rcm_det.rcm_text%TYPE;

    /**
    * Gets the parameter description 
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identifier and its context (institution and software)
    * @param   i_parameter_name      Parameter name
    * @param   i_parameter_value     Parameter value
    * @param   i_id_patient          Patient identifier
    * @param   o_error               Error information
    *
    * @return  Parameter description
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   04-04-2012
    */
    FUNCTION get_parameter_value_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_parameter_name  IN rcm_parameter.parameter_name%TYPE,
        i_parameter_value IN VARCHAR2,
        i_id_patient      IN patient.id_patient%TYPE
    ) RETURN CLOB;

END pk_rcm_params;
/
