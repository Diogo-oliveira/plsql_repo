/*-- Last Change Revision: $Rev: 1944474 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2020-04-06 14:30:00 +0100 (seg, 06 abr 2020) $*/

CREATE OR REPLACE PACKAGE pk_dyn_form AS

    SUBTYPE t_low_char IS VARCHAR2(0100 CHAR);
    SUBTYPE t_big_char IS VARCHAR2(1000 CHAR);
    SUBTYPE t_big_byte IS VARCHAR2(4000 BYTE);

    SUBTYPE t_big_num IS NUMBER;
    SUBTYPE t_big_dec IS NUMBER(24, 6);
    SUBTYPE t_timestamp IS TIMESTAMP(6) WITH LOCAL TIME ZONE;

    k_multc_domain      CONSTANT t_low_char := 'DOM';
    k_multc_syslist     CONSTANT t_low_char := 'SLG';
    k_multc_multichoice CONSTANT t_low_char := 'MUL';

    FUNCTION get_default_action RETURN NUMBER;

    FUNCTION get_dyn_tree_mkt
    (
        i_component_name IN VARCHAR2,
        i_market         IN NUMBER,
        i_action         IN NUMBER
    ) RETURN t_dyn_tree_table;
    -- ***********************************

    /*
      * Get whole tree with default action, from local configuration given root component_name
      *
    * @return table function, returning rows of tree
      *
      * @author Carlos Ferreira
      * @version
      * @since 2019/04
      */
    FUNCTION get_dyn_cfg_inst
    (
        i_prof        IN profissional,
        i_profile     IN NUMBER,
        i_category    IN NUMBER,
        i_tbl_mkt_rel IN t_dyn_tree_table,
        i_action      IN NUMBER
    ) RETURN t_dyn_tree_table;

    -- ********************************
    FUNCTION get_dyn_items_comp_name
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_tbl_dyn_cfg IN t_dyn_tree_table,
        i_action      IN NUMBER,
        o_result      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    -- *******************************
    FUNCTION get_dyn_cfg
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_patient    IN NUMBER,
        i_id_mkt_rel IN NUMBER,
        i_action     IN NUMBER
    ) RETURN t_dyn_tree_table;

    FUNCTION get_dyn_cfg_mkt
    (
        i_prof           IN profissional,
        i_profile        IN NUMBER,
        i_category       IN NUMBER,
        i_market         IN NUMBER,
        i_component_name IN VARCHAR2,
        i_action         IN NUMBER
    ) RETURN t_dyn_tree_table;

    -- ****************************************
    FUNCTION get_dyn_cfg
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_patient        IN NUMBER,
        i_component_name IN VARCHAR2,
        i_action         IN NUMBER
    ) RETURN t_dyn_tree_table;

    -- *****************************************
    FUNCTION get_multichoice
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_flg_type      IN table_varchar,
        i_internal_name IN table_varchar
    ) RETURN t_tbl_core_domain;

    -- ***************************************************************
    FUNCTION get_ds_target
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_patient      IN NUMBER,
        i_episode      IN NUMBER,
                           i_tbl_cmp_orig IN table_number,
        i_action       IN NUMBER,
                           o_result       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    -- *****************************************
    FUNCTION get_multichoice
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_flg_type      IN table_varchar,
        i_internal_name IN table_varchar,
        o_result        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    -- new
    FUNCTION get_full_items_by_name
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_patient        IN NUMBER,
        i_episode        IN NUMBER,
        i_component_name IN VARCHAR2,
        i_action         IN NUMBER,
        o_components     OUT pk_types.cursor_type,
        o_ds_target      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    -- new
    FUNCTION get_full_items_by_screen
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_patient     IN NUMBER,
        i_episode     IN NUMBER,
        i_screen_name IN VARCHAR2,
        i_action      IN NUMBER,
        o_components  OUT pk_types.cursor_type,
        o_ds_target   OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    --****************************************************************
    FUNCTION check_age_limits_max
    (
        i_pat_age      IN NUMBER,
        i_age_limit    IN NUMBER,
        i_unit_measure IN NUMBER
    ) RETURN VARCHAR2;

    --****************************************************************
    FUNCTION check_age_limits_min
    (
        i_pat_age      IN NUMBER,
        i_age_limit    IN NUMBER,
        i_unit_measure IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_union_tree
    (
        i_id_root   IN NUMBER,
        i_tbl_union IN t_dyn_tree_table
    ) RETURN t_dyn_tree_table;

    FUNCTION get_union
    (
        i_tbl_mkt_rel  IN t_dyn_tree_table,
        i_tbl_inst_rel IN t_dyn_tree_table
    ) RETURN t_dyn_tree_table;

    FUNCTION get_multichoice
    (
        i_lang                 IN NUMBER,
        i_prof                 IN profissional,
        i_episode              IN NUMBER,
        i_patient              IN NUMBER,
        i_internal_name        IN VARCHAR2,
        i_internal_name_origin IN table_varchar,
        i_internal_name_values IN table_varchar,
        o_result               OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_dyn_desc
    (
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_action    IN NUMBER,
        i_node_type IN VARCHAR2,
        i_tbl_codes IN table_varchar
    ) RETURN VARCHAR2;

    FUNCTION get_id_mkt_rel_dest(i_id_mkt_orig IN table_number) RETURN table_number;

    FUNCTION get_id_mkt_rel_dest
    (
        i_lang        IN NUMBER,
        i_id_mkt_orig IN table_number,
        o_result      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

END pk_dyn_form;
/
