/*-- Last Change Revision: $Rev: 1989382 $*/
/*-- Last Change by: $Author: humberto.cardoso $*/
/*-- Date of last change: $Date: 2021-05-18 09:34:24 +0100 (ter, 18 mai 2021) $*/
CREATE OR REPLACE PACKAGE pk_cnt_cdr IS

    -- Author  : HUMBERTO.CARDOSO
    -- Created : 24/01/2017 15:04:52
    -- Purpose : Content manipulation for CDR content

    --=============================================================================================
    --Public rule definition functions --
    --=============================================================================================

    FUNCTION get_rule_cc_name
    (
        i_id_cdr_definition IN NUMBER,
        i_position          IN NUMBER
    ) RETURN VARCHAR2;

    --OK
    /**
    * Gets the concatenation of the CDR_CONDITION INTERNAL_NAME with CDR_CONCEPT_INTERNAL_NAME for this ID_CDR_PARAMETER
    *
    *@i_id_cdr_parameter     The ID_CDR_PARAMETER
    *
    * @return                If rule invalid, returns #ERROR:%
    *
    * @author                Humberto Cardoso
    * @version               --
    * @since                 2017/01/24
    */
    FUNCTION get_parameter_cc_name(i_id_cdr_parameter IN NUMBER) RETURN VARCHAR2;

    --OK
    /**
    * Gets the relative position of the ID_CDR_PARAMETER inside the rule.
    * 
    *@i_id_cdr_parameter     The ID_CDR_PARAMETER 
    *
    * @return                If rule invalid, returns -1
    *
    * @author                Humberto Cardoso
    * @version               v2.7.0
    * @since                 2017/01/24
    */
    FUNCTION get_parameter_position(i_id_cdr_parameter IN NUMBER) RETURN NUMBER;

    --=============================================================================================
    --Public get content  functions --
    --=============================================================================================

    --OK
    /**
    * Returns a concatenation with | of all values in table cdr_inst_par_val for the current id_cdr_inst_param.
    *
    * @param i_id_cdr_inst_param   The ID CDR_INST_PARAM
    *
    * @return                      A concatenation with | of all values for the current id_cdr_inst_param.
    *
    * @author                      Humberto Cardoso
    * @version                     v2.7.0 
    * @since                       2017/01/24
    */
    FUNCTION get_inst_par_values(i_id_cdr_inst_param IN NUMBER) RETURN VARCHAR2;

    --OK
    /**
    * Returns a concatenation with | of all values in table cdr_inst_par_act_val for the current id_cdr_inst_par_action.
    *
    * @param i_id_cdr_inst_param   The ID INSTANCE_PARAMETER_ACTION
    *
    * @return                      A concatenation with | of all values for the current id_cdr_inst_par_action.
    * 
    * @author                      Humberto Cardoso
    * @version                     v2.7.0 
    * @since                       2017/01/24
    */
    FUNCTION get_inst_par_action_values(i_id_cdr_inst_par_action IN NUMBER) RETURN VARCHAR2;

    --=============================================================================================
    --Public content data manipulation--
    --=============================================================================================

    --OK
    /**
    * Inserts the record(s) into :
    * CDR_INSTANCE, CDR_INST_PARAM, CDR_INST_PAR_VAL, CDR_INST_PAR_ACTION, CDR_INST_PAR_VAL.
    * Uses the same value arguments as columns in view V_CNT_CDR_INSTANCE to produce the same results.
    * Needs documentation improvements
    *
    * @param i_test_param1   Test parameter 1 comment
    * @param i_test_param2   Test parameter 2 comment
    * @param i_test_param3   Test parameter 3 comment
    * @param o_test_param4   Test parameter 4 comment
    *
    * @raises                Error if null values
    * @raises                Error if the rule is not valid
    * @raises                Error if position/cc_name are not valid
    *
    * @author                Humberto Cardoso
    * @version               v2.7.0 
    * @since                 2017/01/24
    */
    PROCEDURE set_instance
    (
        i_action                     IN VARCHAR2,
        i_id_cdr_definition          IN NUMBER,
        i_id_language                IN NUMBER DEFAULT NULL,
        i_description_instance       IN VARCHAR2 DEFAULT NULL,
        i_severity                   IN VARCHAR2 DEFAULT NULL,
        i_id_content                 IN VARCHAR2 DEFAULT NULL,
        i_cc_name_1                  IN VARCHAR2 DEFAULT NULL,
        i_id_element_1               IN VARCHAR2 DEFAULT NULL,
        i_validity_1                 IN NUMBER DEFAULT NULL,
        i_id_validity_umea_1         IN NUMBER DEFAULT NULL,
        i_val_min_1                  IN NUMBER DEFAULT NULL,
        i_val_max_1                  IN NUMBER DEFAULT NULL,
        i_id_domain_umea_1           IN NUMBER DEFAULT NULL,
        i_cdr_action_1               IN VARCHAR2 DEFAULT NULL,
        i_inst_param_values_1        IN VARCHAR2 DEFAULT NULL,
        i_flg_first_time_1           IN VARCHAR2 DEFAULT NULL,
        i_id_cdr_message_1           IN NUMBER DEFAULT NULL,
        i_inst_param_action_values_1 IN VARCHAR2 DEFAULT NULL,
        i_cc_name_2                  IN VARCHAR2 DEFAULT NULL,
        i_id_element_2               IN VARCHAR2 DEFAULT NULL,
        i_validity_2                 IN NUMBER DEFAULT NULL,
        i_id_validity_umea_2         IN NUMBER DEFAULT NULL,
        i_val_min_2                  IN NUMBER DEFAULT NULL,
        i_val_max_2                  IN NUMBER DEFAULT NULL,
        i_id_domain_umea_2           IN NUMBER DEFAULT NULL,
        i_cdr_action_2               IN VARCHAR2 DEFAULT NULL,
        i_inst_param_values_2        IN VARCHAR2 DEFAULT NULL,
        i_flg_first_time_2           IN VARCHAR2 DEFAULT NULL,
        i_id_cdr_message_2           IN NUMBER DEFAULT NULL,
        i_inst_param_action_values_2 IN VARCHAR2 DEFAULT NULL,
        i_cc_name_3                  IN VARCHAR2 DEFAULT NULL,
        i_id_element_3               IN VARCHAR2 DEFAULT NULL,
        i_validity_3                 IN NUMBER DEFAULT NULL,
        i_id_validity_umea_3         IN NUMBER DEFAULT NULL,
        i_val_min_3                  IN NUMBER DEFAULT NULL,
        i_val_max_3                  IN NUMBER DEFAULT NULL,
        i_id_domain_umea_3           IN NUMBER DEFAULT NULL,
        i_cdr_action_3               IN VARCHAR2 DEFAULT NULL,
        i_inst_param_values_3        IN VARCHAR2 DEFAULT NULL,
        i_flg_first_time_3           IN VARCHAR2 DEFAULT NULL,
        i_id_cdr_message_3           IN NUMBER DEFAULT NULL,
        i_inst_param_action_values_3 IN VARCHAR2 DEFAULT NULL,
        i_cc_name_4                  IN VARCHAR2 DEFAULT NULL,
        i_id_element_4               IN VARCHAR2 DEFAULT NULL,
        i_validity_4                 IN NUMBER DEFAULT NULL,
        i_id_validity_umea_4         IN NUMBER DEFAULT NULL,
        i_val_min_4                  IN NUMBER DEFAULT NULL,
        i_val_max_4                  IN NUMBER DEFAULT NULL,
        i_id_domain_umea_4           IN NUMBER DEFAULT NULL,
        i_cdr_action_4               IN VARCHAR2 DEFAULT NULL,
        i_inst_param_values_4        IN VARCHAR2 DEFAULT NULL,
        i_flg_first_time_4           IN VARCHAR2 DEFAULT NULL,
        i_id_cdr_message_4           IN NUMBER DEFAULT NULL,
        i_inst_param_action_values_4 IN VARCHAR2 DEFAULT NULL,
        i_id_cdr_instance            IN NUMBER,
        i_id_cdr_inst_param_1        IN NUMBER DEFAULT NULL,
        i_id_cdr_inst_par_action_1   IN NUMBER DEFAULT NULL,
        i_id_cdr_inst_param_2        IN NUMBER DEFAULT NULL,
        i_id_cdr_inst_par_action_2   IN NUMBER DEFAULT NULL,
        i_id_cdr_inst_param_3        IN NUMBER DEFAULT NULL,
        i_id_cdr_inst_par_action_3   IN NUMBER DEFAULT NULL,
        i_id_cdr_inst_param_4        IN NUMBER DEFAULT NULL,
        i_id_cdr_inst_par_action_4   IN NUMBER DEFAULT NULL
    );

END pk_cnt_cdr;
/
