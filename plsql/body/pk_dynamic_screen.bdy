/*-- Last Change Revision: $Rev: 2027009 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:43 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_dynamic_screen AS

    --
    -- PRIVATE SUBTYPES
    -- 
    g_data_key NUMBER;

    SUBTYPE obj_name IS VARCHAR2(32 CHAR);
    SUBTYPE debug_msg IS VARCHAR2(200 CHAR);
    SUBTYPE value_str IS pk_translation.t_desc_translation;

    k_value0 CONSTANT VARCHAR2(0050 CHAR) := 'DSCP';
    k_value1 CONSTANT VARCHAR2(0050 CHAR) := 'DSCMP';

    TYPE rec_cfg_vars IS RECORD(
        id_market      market.id_market%TYPE,
        id_institution institution.id_institution%TYPE,
        id_software    software.id_software%TYPE);

    --
    -- PRIVATE CONSTANTS
    -- 

    -- Package info
    c_package_owner CONSTANT obj_name := 'ALERT';
    c_package_name  CONSTANT obj_name := pk_alertlog.who_am_i();

    -- Relationship type for valid relationships for authorizing organ donations
    c_rel_type_organ_donation CONSTANT relationship_type.id_relationship_type%TYPE := 3;

    -- PARTIAL DATE VALIDATION CONSTANTS
    k_pos_dd CONSTANT NUMBER := 7;
    k_pos_mm CONSTANT NUMBER := 5;
    --k_pos_yy CONSTANT NUMBER := 1;
    --k_pos_hr CONSTANT NUMBER := 9;
    k_len  CONSTANT NUMBER := 2;
    k_leny CONSTANT NUMBER := 4;

    k_pos_name     CONSTANT NUMBER := 1;
    k_pos_flg_type CONSTANT NUMBER := 2;

    k_yes CONSTANT VARCHAR2(0010 CHAR) := 'Y';
    k_no  CONSTANT VARCHAR2(0010 CHAR) := 'N';
    --
    -- PRIVATE FUNCTIONS
    -- 

    /**
    * Gets the configuration variables: institution and software
    *
    * @param   i_prof                   professional, software and institution ids             
    * @param   i_component_name            Component internal name
    * @param   i_component_type            Component type (defaults to node component type)
    *
    * @return  Record with id_market, id_institution and id_software
    *
    * @author  Alexandre Santos
    * @version v2.6.1
    * @since   04-01-2012
    */
    FUNCTION get_cfg_vars
    (
        i_prof           IN profissional,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_child%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_child%TYPE DEFAULT c_node_component
    ) RETURN rec_cfg_vars IS
        c_function_name VARCHAR2(30) := 'GET_CFG_VARS';
        --
        l_dbg_msg debug_msg;
        l_market  ds_cmpt_mkt_rel.id_market%TYPE;
        --
        l_ret rec_cfg_vars;
    BEGIN
        l_dbg_msg := 'CALL PK_CORE.GET_INST_MKT';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
    
        BEGIN
            l_dbg_msg := 'GET DIAGNOSIS CFG_VARS';
            pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);

        SELECT id_market, id_software
              INTO l_ret.id_market, l_ret.id_software
              FROM (SELECT dscm.id_market,
                           dscm.id_software,
                           row_number() over(ORDER BY decode(dscm.id_market, l_market, 1, 2), --
                           decode(dscm.id_software, i_prof.software, 1, 2)) line_number
                      FROM ds_cmpt_mkt_rel dscm
                     WHERE dscm.internal_name_parent = i_component_name
                       AND dscm.flg_component_type_parent = i_component_type
                       AND dscm.id_market IN (pk_alert_constant.g_id_market_all, l_market)
                       AND dscm.id_software IN (pk_alert_constant.g_soft_all, i_prof.software))
             WHERE line_number = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_ret.id_market      := pk_alert_constant.g_id_market_all;
                l_ret.id_institution := pk_alert_constant.g_inst_all;
                l_ret.id_software    := pk_alert_constant.g_soft_all;
        END;
    
        RETURN l_ret;
    END get_cfg_vars;

    PROCEDURE set_data_key(i_value_key IN NUMBER) IS
    BEGIN
        g_data_key := i_value_key;
    END set_data_key;

    FUNCTION get_data_key RETURN NUMBER IS
    BEGIN
        RETURN g_data_key;
    END get_data_key;

    /**********************************************************************************************
    * Get dynamic screen section events
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   professional, software and institution ids             
    * @param        i_component_name         Component internal name
    * @param        i_component_type         Component type (defaults to node component type)
    * @param        o_events                 Section events
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        07-Jun-2010
    **********************************************************************************************/
    FUNCTION get_ds_events
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT c_node_component,
        i_patient        IN NUMBER DEFAULT NULL,
        o_events         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_DS_EVENTS';
        l_dbg_msg debug_msg;
        tbl_event t_table_ds_events;
    BEGIN
    
        l_dbg_msg := 'get dynamic screen section events';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
    
        IF i_patient IS NULL
        THEN
            OPEN o_events FOR
                SELECT dsev.id_ds_event,
                       dsev.id_ds_cmpt_mkt_rel AS origin,
                       dsev.value,
                       dset.id_ds_cmpt_mkt_rel AS target,
                       dset.flg_event_type
                  FROM ds_event dsev
                 INNER JOIN ds_event_target dset
                    ON dsev.id_ds_event = dset.id_ds_event
                 INNER JOIN TABLE(get_cmp_rel(i_prof, i_component_name, i_component_type)) dscm
                    ON dsev.id_ds_cmpt_mkt_rel = dscm.id_ds_cmpt_mkt_rel;
        ELSE
        
            tbl_event := tf_ds_events(i_lang           => i_lang,
                                      i_prof           => i_prof,
                                      i_component_name => i_component_name,
                                      i_component_type => i_component_type,
                                      i_patient        => i_patient);
        
            OPEN o_events FOR
                SELECT id_ds_event, origin, VALUE, target, flg_event_type
                  FROM TABLE(tbl_event);
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(i_cursor => o_events);
            RETURN FALSE;
    END get_ds_events;

    /**********************************************************************************************
    * Get dynamic screen section default events
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   professional, software and institution ids             
    * @param        i_component_name         Component internal name
    * @param        i_component_type         Component type (defaults to node component type)
    * @param        i_component_list         (Y/N) If Y(es) it returns only the default events for
    *                                        the child components 
    *                                        and not for all componentsthe entire structure (defaults to N(o))
    * @param        o_def_events             Section default events
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        07-Jun-2010
    **********************************************************************************************/
    FUNCTION get_ds_def_events
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT c_node_component,
        i_component_list IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_def_events     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_DS_DEF_EVENTS';
        l_dbg_msg debug_msg;
    
    BEGIN
        l_dbg_msg := 'get dynamic screen section default events';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        OPEN o_def_events FOR
            SELECT dsde.id_ds_cmpt_mkt_rel, dsde.id_def_event, dsde.flg_event_type
              FROM ds_def_event dsde
             INNER JOIN TABLE(get_cmp_rel(i_prof, i_component_name, i_component_type, i_component_list)) dscm
                ON dsde.id_ds_cmpt_mkt_rel = dscm.id_ds_cmpt_mkt_rel;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(i_cursor => o_def_events);
            RETURN FALSE;
        
    END get_ds_def_events;

    --

    FUNCTION get_ds_items_values
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT c_node_component,
        o_items_values   OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_DS_ITEMS_VALUES';
        l_dbg_msg debug_msg;
    
    BEGIN
        l_dbg_msg := 'get dynamic screen item values for multichoices';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        OPEN o_items_values FOR
            SELECT a.id_ds_cmpt_mkt_rel,
                   a.id_ds_component,
                   a.internal_name,
                   a.flg_component_type,
                   a.item_desc,
                   a.item_value,
                   a.item_alt_value,
                   a.item_rank
              FROM TABLE(pk_dynamic_screen.tf_ds_items_values(i_lang           => i_lang,
                                                              i_prof           => i_prof,
                                                              i_component_name => i_component_name,
                                                              i_component_type => i_component_type)) a;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(i_cursor => o_items_values);
            RETURN FALSE;
        
    END get_ds_items_values;

    --

    FUNCTION get_sys_list_alt_value
    (
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT c_leaf_component,
        i_sys_list       IN sys_list_group_rel.id_sys_list%TYPE
    ) RETURN VARCHAR2 IS
        c_function_name CONSTANT obj_name := 'GET_SYS_LIST_CONTEXT';
        l_dbg_msg debug_msg;
    
        l_slg_internal_name ds_component.slg_internal_name%TYPE;
    
    BEGIN
        l_dbg_msg := 'get sys list group internal name';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        SELECT dscp.slg_internal_name
          INTO l_slg_internal_name
          FROM ds_component dscp
         WHERE dscp.internal_name = i_component_name
           AND dscp.flg_component_type = i_component_type;
    
        l_dbg_msg := 'get sys list alternate value';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        RETURN pk_sys_list.get_sys_list_context(i_internal_name => l_slg_internal_name, i_sys_list => i_sys_list);
    
    END get_sys_list_alt_value;

    --

    FUNCTION get_family_relationship_desc
    (
        i_lang                IN language.id_language%TYPE,
        i_family_relationship IN family_relationship.id_family_relationship%TYPE,
        i_available           IN family_relationship.flg_available%TYPE DEFAULT NULL
    ) RETURN pk_translation.t_desc_translation IS
        c_function_name CONSTANT obj_name := 'GET_FAMILY_RELATIONSHIP_DESC';
        l_dbg_msg debug_msg;
    
        l_desc pk_translation.t_desc_translation;
    
    BEGIN
        l_dbg_msg := 'get family relationship description';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        SELECT pk_translation.get_translation(i_lang, fr.code_family_relationship)
          INTO l_desc
          FROM family_relationship fr
         WHERE fr.id_family_relationship = i_family_relationship
           AND (i_available IS NULL OR fr.flg_available = i_available);
    
        RETURN l_desc;
    
    END get_family_relationship_desc;

    --

    FUNCTION add_values
    (
        i_data_val    IN table_table_varchar,
        i_name        IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_desc        IN value_str,
        i_value       IN value_str,
        i_alt_value   IN value_str DEFAULT NULL,
        i_hist        IN value_str DEFAULT NULL,
        i_extra_value IN value_str DEFAULT NULL
    ) RETURN table_table_varchar IS
        c_function_name CONSTANT obj_name := 'ADD_VALUES';
        l_dbg_msg debug_msg;
    
        l_data_val table_table_varchar := i_data_val;
        idx        PLS_INTEGER;
    
    BEGIN
        l_dbg_msg := 'add values to the structure';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
    
        IF i_data_val IS NULL
        THEN
            l_data_val := table_table_varchar();
        END IF;
    
        l_data_val.extend();
        idx := l_data_val.last();
    
        l_data_val(idx) := table_varchar();
        l_data_val(idx).extend(c_n_columns);
    
        l_data_val(idx)(c_name_idx) := i_name;
        l_data_val(idx)(c_desc_idx) := i_desc;
        l_data_val(idx)(c_val_idx) := i_value;
        l_data_val(idx)(c_alt_val_idx) := i_alt_value;
        l_data_val(idx)(c_hist_idx) := i_hist;
        --
        --        l_data_val(idx)(c_flg_other_idx) := null;
        --l_data_val(idx)(c_other_diag_desc_idx) := NULL;
        --
        l_data_val(idx)(c_key) := get_data_key();
        l_data_val(idx)(c_epis_diag_idx) := i_extra_value;
    
        RETURN l_data_val;
    
    END add_values;

    --
    -- PUBLIC FUNCTIONS
    -- 

    /**********************************************************************************************
    * Returns tree-like relations between components below a certain component
    *
    * @param        i_prof                   professional, software and institution ids             
    * @param        i_component_name         Component internal name
    * @param        i_component_type         Component type (defaults to node component type)
    * @param        i_component_list         (Y/N) If Y(es) it returns only a list of child components
    *                                        and not the entire structure (defaults to N)
    *
    * @return       Tree-like relations between components
    *                        
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        07-Jun-2010
    **********************************************************************************************/
    FUNCTION get_cmp_rel
    (
        i_prof           IN profissional,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_child%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_child%TYPE DEFAULT c_node_component,
        i_component_list IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_component_root IN ds_cmpt_mkt_rel.internal_name_parent%TYPE DEFAULT NULL
    ) RETURN tf_ds_section IS
        c_function_name CONSTANT obj_name := 'GET_CMP_REL';
        l_dbg_msg debug_msg;
    
        l_dss tf_ds_section;
    
        l_cfg_vars rec_cfg_vars;
    BEGIN
        l_dbg_msg := 'CALL GET_CFG_VARS';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_cfg_vars := get_cfg_vars(i_prof           => i_prof,
                                   i_component_name => i_component_name,
                                   i_component_type => i_component_type);
    
        l_dbg_msg := 'get dynamic screen structure';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        SELECT tr_ds_section(dscm.id_ds_cmpt_mkt_rel,
                             dscm.id_market,
                             decode(dscm.internal_name_child,
                                    i_component_name,
                                    to_number(NULL),
                                    dscm.id_ds_component_parent),
                             decode(dscm.internal_name_child, i_component_name, to_char(NULL), dscm.internal_name_parent),
                             decode(dscm.internal_name_child,
                                    i_component_name,
                                    to_char(NULL),
                                    dscm.flg_component_type_parent),
                             dscm.id_ds_component_child,
                             dscm.internal_name_child,
                             dscm.flg_component_type_child,
                             dscm.rank,
                             dscm.gender,
                             dscm.age_min_value,
                             dscm.age_min_unit_measure,
                             dscm.age_max_value,
                             dscm.age_max_unit_measure,
                             --- cmf
                             dscm.id_unit_measure,
                             dscm.id_unit_measure_subtype,
                             dscm.max_len,
                             dscm.min_value,
                             dscm.max_value,
                             -------
                             rownum)
          BULK COLLECT
          INTO l_dss
          FROM (SELECT d.id_ds_cmpt_mkt_rel,
                       d.id_market,
                       d.id_ds_component_parent,
                       d.internal_name_parent,
                       d.flg_component_type_parent,
                       d.id_ds_component_child,
                       d.internal_name_child,
                       d.flg_component_type_child,
                       d.rank,
                       d.gender,
                       d.age_min_value,
                       d.age_min_unit_measure,
                       d.age_max_value,
                       d.age_max_unit_measure
                       --- cmf
                      ,
                       d.id_unit_measure,
                       d.id_unit_measure_subtype,
                       d.max_len,
                       d.min_value,
                       d.max_value
                ------------
                  FROM ds_cmpt_mkt_rel d
                 WHERE d.id_market = l_cfg_vars.id_market
                   AND d.id_software = l_cfg_vars.id_software) dscm
         WHERE i_component_list = pk_alert_constant.g_no
            OR (dscm.internal_name_parent = i_component_name AND dscm.flg_component_type_parent = i_component_type)
        CONNECT BY PRIOR dscm.id_ds_component_child = dscm.id_ds_component_parent
         START WITH (dscm.internal_name_child = i_component_name OR i_component_name IS NULL)
                AND dscm.flg_component_type_child = i_component_type
                AND (dscm.internal_name_parent = i_component_root OR i_component_root IS NULL)
         ORDER SIBLINGS BY dscm.rank;
    
        RETURN l_dss;
    END get_cmp_rel;

    FUNCTION get_cmp_rel_child
    (
        i_prof           IN profissional,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_child%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_child%TYPE DEFAULT c_node_component,
        i_component_list IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_component_root IN ds_cmpt_mkt_rel.internal_name_parent%TYPE DEFAULT NULL
    ) RETURN tf_ds_section IS
        c_function_name CONSTANT obj_name := 'GET_CMP_REL';
        l_dbg_msg debug_msg;
    
        l_dss tf_ds_section;
    
        l_cfg_vars rec_cfg_vars;
    BEGIN
        l_dbg_msg := 'CALL GET_CFG_VARS';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_cfg_vars := get_cfg_vars(i_prof           => i_prof,
                                   i_component_name => i_component_name,
                                   i_component_type => i_component_type);
    
        l_dbg_msg := 'get dynamic screen structure';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        SELECT tr_ds_section(dscm.id_ds_cmpt_mkt_rel,
                             dscm.id_market,
                             decode(dscm.internal_name_child,
                                    i_component_name,
                                    to_number(NULL),
                                    dscm.id_ds_component_parent),
                             decode(dscm.internal_name_child, i_component_name, to_char(NULL), dscm.internal_name_parent),
                             decode(dscm.internal_name_child,
                                    i_component_name,
                                    to_char(NULL),
                                    dscm.flg_component_type_parent),
                             dscm.id_ds_component_child,
                             dscm.internal_name_child,
                             dscm.flg_component_type_child,
                             dscm.rank,
                             dscm.gender,
                             dscm.age_min_value,
                             dscm.age_min_unit_measure,
                             dscm.age_max_value,
                             dscm.age_max_unit_measure,
                             --- cmf
                             dscm.id_unit_measure,
                             dscm.id_unit_measure_subtype,
                             dscm.max_len,
                             dscm.min_value,
                             dscm.max_value,
                             -------
                             rownum)
          BULK COLLECT
          INTO l_dss
          FROM (SELECT d.id_ds_cmpt_mkt_rel,
                       d.id_market,
                       d.id_ds_component_parent,
                       d.internal_name_parent,
                       d.flg_component_type_parent,
                       d.id_ds_component_child,
                       d.internal_name_child,
                       d.flg_component_type_child,
                       d.rank,
                       d.gender,
                       d.age_min_value,
                       d.age_min_unit_measure,
                       d.age_max_value,
                       d.age_max_unit_measure
                       --- cmf
                      ,
                       d.id_unit_measure,
                       d.id_unit_measure_subtype,
                       d.max_len,
                       d.min_value,
                       d.max_value
                ------------
                  FROM ds_cmpt_mkt_rel d
                 WHERE d.id_market = l_cfg_vars.id_market
                   AND d.id_software = l_cfg_vars.id_software) dscm
         WHERE i_component_list = pk_alert_constant.g_no
            OR (dscm.internal_name_parent = i_component_name AND dscm.flg_component_type_parent = i_component_type)
        CONNECT BY PRIOR dscm.id_ds_component_child = dscm.id_ds_component_parent
         START WITH dscm.internal_name_parent = i_component_name
        --AND dscm.flg_component_type_child = i_component_type
        --AND (dscm.internal_name_parent = i_component_root OR i_component_root IS NULL)
         ORDER SIBLINGS BY dscm.rank;
    
        RETURN l_dss;
    END get_cmp_rel_child;

    /**********************************************************************************************
    * Get a dynamic screen section structure
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   professional, software and institution ids             
    * @param        i_component_name         Component internal name
    * @param        i_component_type         Component type (defaults to node component type)
    * @param        i_component_list         (Y/N) If Y(es) it returns only a list of child components
    *                                        and not the entire structure (defaults to N)
    * @param        o_section                Section components structure
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        07-Jun-2010
    **********************************************************************************************/
    FUNCTION get_ds_section
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT c_node_component,
        i_component_list IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_patient        IN patient.id_patient%TYPE DEFAULT NULL,
        i_filter         IN VARCHAR2 DEFAULT NULL,
        o_section        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_DS_SECTION';
        l_dbg_msg debug_msg;
    
    BEGIN
        l_dbg_msg := 'get dynamic screen section structure';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        OPEN o_section FOR
            SELECT a.id_ds_cmpt_mkt_rel,
                   a.id_ds_component_parent,
                   a.id_ds_component,
                   a.component_desc,
                   a.internal_name,
                   a.flg_component_type,
                   a.flg_data_type,
                   a.slg_internal_name,
                   a.addit_info_xml_value,
                   a.rank,
                   a.max_len,
                   a.min_value,
                   a.max_value
              FROM TABLE(pk_dynamic_screen.tf_ds_sections(i_lang           => i_lang,
                                                          i_prof           => i_prof,
                                                          i_component_name => i_component_name,
                                                          i_component_type => i_component_type,
                                                          i_component_list => i_component_list,
                                                          i_patient        => i_patient,
                                                          i_filter         => i_filter)) a;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(i_cursor => o_section);
            RETURN FALSE;
    END get_ds_section;

    --

    FUNCTION get_ds_section_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT c_node_component,
        i_patient        IN patient.id_patient%TYPE DEFAULT NULL,
        o_section        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_DS_SECTION_LIST';
        l_dbg_msg debug_msg;
    
        l_exception EXCEPTION;
    BEGIN
        l_dbg_msg := 'get dynamic screen section list';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF NOT get_ds_section(i_lang           => i_lang,
                              i_prof           => i_prof,
                              i_component_name => i_component_name,
                              i_component_type => i_component_type,
                              i_component_list => pk_alert_constant.g_yes,
                              i_patient        => i_patient,
                              o_section        => o_section,
                              o_error          => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_types.open_my_cursor(i_cursor => o_section);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(i_cursor => o_section);
            RETURN FALSE;
    END get_ds_section_list;

    --

    FUNCTION get_ds_section_events_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT c_node_component,
        i_patient        IN patient.id_patient%TYPE DEFAULT NULL,
        o_section        OUT pk_types.cursor_type,
        o_def_events     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_DS_SECTION_EVENTS_LIST';
        l_dbg_msg debug_msg;
    
        l_exception EXCEPTION;
    BEGIN
        l_dbg_msg := 'get dynamic screen section list';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF NOT get_ds_section(i_lang           => i_lang,
                              i_prof           => i_prof,
                              i_component_name => i_component_name,
                              i_component_type => i_component_type,
                              i_component_list => pk_alert_constant.g_yes,
                              o_section        => o_section,
                              o_error          => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        l_dbg_msg := 'get dynamic screen section list default events';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF NOT get_ds_def_events(i_lang           => i_lang,
                                 i_prof           => i_prof,
                                 i_component_name => i_component_name,
                                 i_component_type => i_component_type,
                                 i_component_list => pk_alert_constant.g_yes,
                                 o_def_events     => o_def_events,
                                 o_error          => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_def_events);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_def_events);
            RETURN FALSE;
    END get_ds_section_events_list;

    --

    FUNCTION get_ds_section_events_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT c_node_component,
        i_patient        IN patient.id_patient%TYPE DEFAULT NULL,
        o_section        OUT t_table_ds_sections,
        o_def_events     OUT t_table_ds_def_events,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_DS_SECTION_EVENTS_LIST';
        l_dbg_msg debug_msg;
    BEGIN
        l_dbg_msg := 'CALL PK_DYNAMIC_SCREEN.TF_DS_SECTIONS';
        pk_alertlog.log_debug(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        o_section := pk_dynamic_screen.tf_ds_sections(i_lang           => i_lang,
                                                      i_prof           => i_prof,
                                                      i_component_name => i_component_name,
                                                      i_component_type => i_component_type,
                                                      i_patient        => i_patient,
                                                      i_component_list => pk_alert_constant.g_yes);
    
        l_dbg_msg := 'CALL PK_DYNAMIC_SCREEN.TF_DS_DEF_EVENTS';
        pk_alertlog.log_debug(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        o_def_events := pk_dynamic_screen.tf_ds_def_events(i_lang           => i_lang,
                                                           i_prof           => i_prof,
                                                           i_component_name => i_component_name,
                                                           i_component_type => i_component_type,
                                                           i_component_list => pk_alert_constant.g_yes);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            o_section    := t_table_ds_sections();
            o_def_events := t_table_ds_def_events();
            RETURN FALSE;
    END get_ds_section_events_list;

    --

    FUNCTION get_ds_section_complete_struct
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT c_node_component,
        i_patient        IN patient.id_patient%TYPE DEFAULT NULL,
        i_component_root IN ds_cmpt_mkt_rel.internal_name_parent%TYPE DEFAULT NULL,
        i_filter         IN VARCHAR2 DEFAULT NULL,
        o_section        OUT t_table_ds_sections,
        o_def_events     OUT t_table_ds_def_events,
        o_events         OUT t_table_ds_events,
        o_items_values   OUT t_table_ds_items_values,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_DR_SECTION_COMPLETE_STRUCT';
        l_dbg_msg debug_msg;
    BEGIN
        l_dbg_msg := 'CALL PK_DYNAMIC_SCREEN.TF_DS_SECTIONS';
        pk_alertlog.log_debug(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        o_section := pk_dynamic_screen.tf_ds_sections(i_lang           => i_lang,
                                                      i_prof           => i_prof,
                                                      i_component_name => i_component_name,
                                                      i_component_type => i_component_type,
                                                      i_patient        => i_patient,
                                                      i_component_root => i_component_root,
                                                      i_filter         => i_filter);
    
        l_dbg_msg := 'CALL PK_DYNAMIC_SCREEN.TF_DS_DEF_EVENTS';
        pk_alertlog.log_debug(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        o_def_events := pk_dynamic_screen.tf_ds_def_events(i_lang           => i_lang,
                                                           i_prof           => i_prof,
                                                           i_component_name => i_component_name,
                                                           i_component_type => i_component_type,
                                                           i_component_root => i_component_root);
    
        l_dbg_msg := 'CALL PK_DYNAMIC_SCREEN.TF_DS_DEF_EVENTS';
        pk_alertlog.log_debug(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        o_events := pk_dynamic_screen.tf_ds_events(i_lang           => i_lang,
                                                   i_prof           => i_prof,
                                                   i_component_name => i_component_name,
                                                   i_component_type => i_component_type,
                                                   i_component_root => i_component_root);
    
        l_dbg_msg := 'get dynamic screen item values for multichoices of single choice';
        pk_alertlog.log_debug(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        o_items_values := pk_dynamic_screen.tf_ds_items_values(i_lang           => i_lang,
                                                               i_prof           => i_prof,
                                                               i_component_name => i_component_name,
                                                               i_component_type => i_component_type,
                                                               i_component_root => i_component_root);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            o_section      := t_table_ds_sections();
            o_def_events   := t_table_ds_def_events();
            o_events       := t_table_ds_events();
            o_items_values := t_table_ds_items_values();
            RETURN FALSE;
    END get_ds_section_complete_struct;

    FUNCTION get_ds_section_complete_struct
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT c_node_component,
        i_patient        IN patient.id_patient%TYPE DEFAULT NULL,
        o_section        OUT pk_types.cursor_type,
        o_def_events     OUT pk_types.cursor_type,
        o_events         OUT pk_types.cursor_type,
        o_items_values   OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_DR_SECTION_COMPLETE_STRUCT';
        l_dbg_msg debug_msg;
    
        l_exception EXCEPTION;
    BEGIN
        l_dbg_msg := 'get dynamic screen section structure';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF NOT get_ds_section(i_lang           => i_lang,
                              i_prof           => i_prof,
                              i_component_name => i_component_name,
                              i_component_type => i_component_type,
                              i_patient        => i_patient,
                              o_section        => o_section,
                              o_error          => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        l_dbg_msg := 'get dynamic screen section default events';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF NOT get_ds_def_events(i_lang           => i_lang,
                                 i_prof           => i_prof,
                                 i_component_name => i_component_name,
                                 i_component_type => i_component_type,
                                 o_def_events     => o_def_events,
                                 o_error          => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        l_dbg_msg := 'get dynamic screen section events';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF NOT get_ds_events(i_lang           => i_lang,
                             i_prof           => i_prof,
                             i_component_name => i_component_name,
                             i_component_type => i_component_type,
                             i_patient        => i_patient,
                             o_events         => o_events,
                             o_error          => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        l_dbg_msg := 'get dynamic screen item values for multichoices of single choice';
        pk_alertlog.log_debug(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF NOT get_ds_items_values(i_lang           => i_lang,
                                   i_prof           => i_prof,
                                   i_component_name => i_component_name,
                                   i_component_type => i_component_type,
                                   o_items_values   => o_items_values,
                                   o_error          => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_def_events);
            pk_types.open_my_cursor(i_cursor => o_events);
            pk_types.open_my_cursor(i_cursor => o_items_values);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_def_events);
            pk_types.open_my_cursor(i_cursor => o_events);
            pk_types.open_my_cursor(i_cursor => o_items_values);
            RETURN FALSE;
    END get_ds_section_complete_struct;

    FUNCTION get_diag_str
    (
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_data_val       IN table_table_varchar
    ) RETURN VARCHAR2 IS
    
        c_function_name CONSTANT obj_name := 'GET_DIAG_STR';
        l_dbg_msg debug_msg;
        l_result  VARCHAR2(1000 CHAR);
    BEGIN
        l_dbg_msg := 'search for component value';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        FOR idx IN i_data_val.first() .. i_data_val.last()
        LOOP
            IF i_component_name = i_data_val(idx) (c_name_idx)
            THEN
                l_result := i_data_val(idx) (c_diag_desc_idx);
            END IF;
        END LOOP;
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        RETURN l_result;
    
    END get_diag_str;

    --
    -- **********************************************************************
    FUNCTION get_dp_mode(i_date IN VARCHAR2) RETURN VARCHAR2 IS
    
        k_empty CONSTANT VARCHAR2(0010 CHAR) := '00';
    
        l_dd VARCHAR2(0020 CHAR);
        l_mm VARCHAR2(0020 CHAR);
        --l_yy     VARCHAR2(0020 CHAR);
        l_return VARCHAR2(0020 CHAR);
        --l_hr     VARCHAR2(0020 CHAR);
        --l_case VARCHAR2(0200 CHAR);
    
    BEGIN
    
        --l_yy := substr(i_date, k_pos_yy, k_leny);
        l_mm := substr(i_date, k_pos_mm, k_len);
        l_dd := substr(i_date, k_pos_dd, k_len);
    
        CASE
            WHEN l_mm = k_empty
                 AND l_dd = k_empty THEN
                l_return := k_dp_mode_yyyy;
            WHEN l_mm != k_empty
                 AND l_dd = k_empty THEN
                l_return := k_dp_mode_mmyyyy;
            ELSE
                l_return := k_dp_mode_full;
        END CASE;
    
        RETURN l_return;
    
    END get_dp_mode;

    -- **********************************************************************
    FUNCTION get_value_str
    (
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_data_val       IN table_table_varchar,
        i_orig_val       IN VARCHAR2 DEFAULT NULL,
        i_alt_val        IN BOOLEAN DEFAULT FALSE
    ) RETURN VARCHAR2 IS
        c_function_name CONSTANT obj_name := 'GET_VALUE_STR';
        l_dbg_msg debug_msg;
    
    BEGIN
        l_dbg_msg := 'search for component value';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        FOR idx IN i_data_val.first() .. i_data_val.last()
        LOOP
            IF i_component_name = i_data_val(idx) (c_name_idx)
            THEN
                IF NOT i_alt_val
                THEN
                    RETURN i_data_val(idx)(c_val_idx);
                ELSE
                    RETURN i_data_val(idx)(c_alt_val_idx);
                END IF;
            END IF;
        END LOOP;
    
        l_dbg_msg := 'didn''t find  the component in data structure, so it returns original value';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        RETURN i_orig_val;
    
    END get_value_str;

    --

    FUNCTION get_value_number
    (
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_data_val       IN table_table_varchar,
        i_orig_val       IN NUMBER DEFAULT NULL,
        i_alt_val        IN BOOLEAN DEFAULT FALSE
    ) RETURN NUMBER IS
        c_function_name CONSTANT obj_name := 'GET_VALUE_NUMBER';
        l_dbg_msg debug_msg;
    
    BEGIN
        l_dbg_msg := 'get component value as a number';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        RETURN get_value_str(i_component_name => i_component_name,
                             i_data_val       => i_data_val,
                             i_orig_val       => i_orig_val,
                             i_alt_val        => i_alt_val);
    
    END get_value_number;

    --
    -- *****************************************************************************
    FUNCTION get_dt_format
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_component_name IN VARCHAR2,
        i_data_val       IN table_table_varchar
    ) RETURN VARCHAR2 IS
        l_str VARCHAR2(0200 CHAR);
    BEGIN
    
        l_str := get_value_str(i_component_name => i_component_name,
                               i_data_val       => i_data_val,
                               i_orig_val       => NULL,
                               i_alt_val        => FALSE);
    
        l_str := get_dp_mode(l_str);
    
        RETURN l_str;
    
    END get_dt_format;

    -- *****************************************************************************
    FUNCTION get_value_tstz
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_data_val       IN table_table_varchar,
        i_orig_val       IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_alt_val        IN BOOLEAN DEFAULT FALSE,
        i_flg_partial_dt IN VARCHAR2 DEFAULT NULL
        
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
        c_function_name CONSTANT obj_name := 'GET_VALUE_TSTZ';
        l_dbg_msg debug_msg;
    
        c_dt_send_mask_cfg CONSTANT sys_config.id_sys_config%TYPE := 'DATE_HOUR_SEND_FORMAT';
    
        l_orig_dt_str value_str;
        l_dt_str      value_str;
        l_timezone    timezone_region.timezone_region%TYPE;
        l_mask        sys_config.value%TYPE;
    
        FUNCTION transform_date
        (
            i_dt        IN VARCHAR2,
            i_mask_type IN VARCHAR2
        ) RETURN VARCHAR2 IS
            l_return VARCHAR2(0200 CHAR);
            k_mm_0  CONSTANT VARCHAR2(0100 CHAR) := '01';
            k_dd_0  CONSTANT VARCHAR2(0100 CHAR) := '01';
            k_hmi_0 CONSTANT VARCHAR2(0100 CHAR) := '000000';
        BEGIN
        
            CASE i_mask_type
                WHEN k_dp_mode_yyyy THEN
                    l_return := substr(i_dt, 1, k_leny) || k_mm_0 || k_dd_0 || k_hmi_0;
                WHEN k_dp_mode_mmyyyy THEN
                    l_return := substr(i_dt, 1, k_leny) || substr(i_dt, k_pos_mm, k_len) || k_dd_0 || k_hmi_0;
                ELSE
                    -- k_dp_mode_full
                    l_return := i_dt;
            END CASE;
        
            RETURN l_return;
        
        END transform_date;
    
    BEGIN
        l_dbg_msg := 'transform original value as timestamp in a string';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_orig_dt_str := pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                     i_date => i_orig_val,
                                                     i_inst => i_prof.institution,
                                                     i_soft => i_prof.software);
    
        l_dbg_msg := 'get component value as a string';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_dt_str := get_value_str(i_component_name => i_component_name,
                                  i_data_val       => i_data_val,
                                  i_orig_val       => l_orig_dt_str,
                                  i_alt_val        => i_alt_val);
    
        l_dbg_msg := 'get profissional timezone';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_timezone := pk_date_utils.get_timezone(i_lang => i_lang, i_prof => i_prof);
    
        l_dbg_msg := 'get mask to use in string to timestamp conversion';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_mask := pk_sysconfig.get_config(c_dt_send_mask_cfg, i_prof.institution, i_prof.software);
    
        -- transform date according to i_flg_partial_dt
        l_dt_str := transform_date(i_dt => l_dt_str, i_mask_type => i_flg_partial_dt);
    
        l_dbg_msg := 'transform original value as string in a timestamp with local time zone';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        RETURN pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => l_dt_str,
                                             i_timezone  => l_timezone,
                                             i_mask      => l_mask);
    
    END get_value_tstz;

    --

    FUNCTION add_value_tstz
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_data_val  IN table_table_varchar,
        i_name      IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_value     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_desc_mode IN VARCHAR2 DEFAULT k_dt_output_01,
        i_hist      IN NUMBER DEFAULT NULL
    ) RETURN table_table_varchar IS
        c_function_name CONSTANT obj_name := 'ADD_VALUE_TSTZ';
        l_dbg_msg debug_msg;
    
        l_desc  value_str;
        l_value value_str;
    
    BEGIN
        IF i_value IS NULL
        THEN
            RETURN i_data_val;
        END IF;
    
        l_dbg_msg := 'get date formatted as a string to be shown';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
    
        l_value := pk_date_utils.date_send_tsz(i_lang => i_lang,
                                               i_date => i_value,
                                               i_inst => i_prof.institution,
                                               i_soft => i_prof.software);
    
        CASE i_desc_mode
            WHEN k_dt_output_02 THEN
                l_desc := pk_date_utils.date_chr_short_read_tsz(i_lang => i_lang, i_date => i_value, i_prof => i_prof);
            WHEN k_dp_mode_mmyyyy THEN
                l_desc  := pk_date_utils.to_char_insttimezone(i_lang      => i_lang,
                                                              i_prof      => i_prof,
                                                              i_timestamp => i_value,
                                                              i_mask      => 'Mon-YYYY');
                l_value := substr(l_value, 1, 6) || '00000000';
            WHEN k_dp_mode_yyyy THEN
                l_desc  := pk_date_utils.to_char_insttimezone(i_lang      => i_lang,
                                                              i_prof      => i_prof,
                                                              i_timestamp => i_value,
                                                              i_mask      => 'YYYY');
                l_value := substr(l_value, 1, 4) || '0000000000';
            ELSE
                l_desc := pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                      i_date => i_value,
                                                      i_inst => i_prof.institution,
                                                      i_soft => i_prof.software);
        END CASE;
    
        l_dbg_msg := 'get date in date send format';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
    
        l_dbg_msg := 'add date value to the data structure';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        RETURN add_values(i_data_val => i_data_val,
                          i_name     => i_name,
                          i_desc     => l_desc,
                          i_value    => l_value,
                          i_hist     => i_hist);
    
    END add_value_tstz;

    --

    FUNCTION add_value_prof
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_data_val IN table_table_varchar,
        i_name     IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_value    IN professional.id_professional%TYPE,
        i_hist     IN NUMBER DEFAULT NULL
    ) RETURN table_table_varchar IS
        c_function_name CONSTANT obj_name := 'ADD_VALUE_PROF';
        l_dbg_msg debug_msg;
    
        l_desc value_str;
    
    BEGIN
        IF i_value IS NULL
        THEN
            RETURN i_data_val;
        END IF;
    
        l_dbg_msg := 'get professional name';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_desc := pk_prof_utils.get_name_signature(i_lang => i_lang, i_prof => i_prof, i_prof_id => i_value);
    
        l_dbg_msg := 'add professional info to the data structure';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        RETURN add_values(i_data_val => i_data_val,
                          i_name     => i_name,
                          i_desc     => l_desc,
                          i_value    => i_value,
                          i_hist     => i_hist);
    
    END add_value_prof;

    --

    FUNCTION add_value_sl
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_data_val IN table_table_varchar,
        i_name     IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_value    IN sys_list.id_sys_list%TYPE,
        i_hist     IN NUMBER DEFAULT NULL
    ) RETURN table_table_varchar IS
        c_function_name CONSTANT obj_name := 'ADD_VALUE_SL';
        l_dbg_msg debug_msg;
    
        l_desc      value_str;
        l_alt_value value_str;
    
    BEGIN
        IF i_value IS NULL
        THEN
            RETURN i_data_val;
        END IF;
    
        l_dbg_msg := 'get sys list description';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_desc := pk_sys_list.get_sys_list_value_desc(i_lang => i_lang, i_prof => i_prof, i_id_sys_list => i_value);
    
        l_dbg_msg := 'get alternate value (sys list flag context)';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_alt_value := get_sys_list_alt_value(i_component_name => i_name, i_sys_list => i_value);
    
        l_dbg_msg := 'add sys list info to the data structure';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        RETURN add_values(i_data_val  => i_data_val,
                          i_name      => i_name,
                          i_desc      => l_desc,
                          i_value     => i_value,
                          i_alt_value => l_alt_value,
                          i_hist      => i_hist);
    
    END add_value_sl;

    FUNCTION add_value_slms
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_data_val IN table_table_varchar,
        i_name     IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_value    IN NUMBER,
        i_hist     IN NUMBER DEFAULT NULL
    ) RETURN table_table_varchar IS
        l_return table_table_varchar := table_table_varchar();
        l_desc   VARCHAR2(4000);
    BEGIN
    
        l_desc := pk_api_multichoice.get_multichoice_option_desc(i_lang      => i_lang,
                                                                 i_prof      => i_prof,
                                                                 i_id_option => i_value);
    
        IF l_desc IS NULL
        THEN
        
            l_return := pk_dynamic_screen.add_value_sl(i_lang     => i_lang,
                                                       i_prof     => i_prof,
                                                       i_data_val => i_data_val,
                                                       i_name     => i_name,
                                                       i_value    => i_value,
                                                       i_hist     => i_hist);
        ELSE
        
            l_return := add_values(i_data_val  => i_data_val,
                                   i_name      => i_name,
                                   i_desc      => l_desc,
                                   i_value     => i_value,
                                   i_alt_value => NULL,
                                   i_hist      => i_hist);
        
        END IF;
    
        RETURN l_return;
    
    END add_value_slms;

    FUNCTION add_value_k
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_data_val IN table_table_varchar,
        i_name     IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_value    IN NUMBER,
        i_um       IN NUMBER,
        i_hist     IN NUMBER DEFAULT NULL
    ) RETURN table_table_varchar IS
        c_function_name CONSTANT obj_name := 'ADD_VALUE_K';
        l_dbg_msg   debug_msg;
        l_desc      value_str;
        l_alt_value value_str;
        k_sp CONSTANT VARCHAR2(0010 CHAR) := chr(32);
    BEGIN
        IF i_value IS NULL
        THEN
            RETURN i_data_val;
        END IF;
    
        l_dbg_msg := 'get unit_measure description';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_desc := to_char(i_value) || k_sp ||
                  pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                               i_prof         => i_prof,
                                                               i_unit_measure => i_um);
    
        l_dbg_msg := 'get alternate value ';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_alt_value := i_um;
    
        l_dbg_msg := 'add unit_measure info to the data structure';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        RETURN add_values(i_data_val  => i_data_val,
                          i_name      => i_name,
                          i_desc      => l_desc,
                          i_value     => i_value,
                          i_alt_value => l_alt_value,
                          i_hist      => i_hist);
    
    END add_value_k;

    FUNCTION add_value_adt
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_data_val IN table_table_varchar,
        i_name     IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_value    IN NUMBER,
        i_type     IN VARCHAR2 DEFAULT NULL,
        i_hist     IN NUMBER DEFAULT NULL
    ) RETURN table_table_varchar IS
        c_function_name CONSTANT obj_name := 'ADD_VALUE_ADT';
        l_dbg_msg   debug_msg;
        l_desc      value_str;
        l_alt_value value_str;
        l_value     NUMBER;
    BEGIN
        IF i_value IS NULL
        THEN
            RETURN i_data_val;
        END IF;
        IF i_type IS NULL
        THEN
            l_value := i_value;
        ELSE
            -- jurisdiction
            l_value := pk_adt.get_jurisdiction_id(i_value);
        END IF;
    
        l_dbg_msg := 'get unit_measure description';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_desc := pk_adt.get_regional_classifier_desc(i_lang                      => i_lang,
                                                      i_prof                      => i_prof,
                                                      i_id_rb_regional_classifier => l_value);
    
        l_dbg_msg := 'get alternate value ';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_alt_value := l_value;
    
        l_dbg_msg := 'add unit_measure info to the data structure';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        RETURN add_values(i_data_val  => i_data_val,
                          i_name      => i_name,
                          i_desc      => l_desc,
                          i_value     => i_value,
                          i_alt_value => l_alt_value,
                          i_hist      => i_hist);
    
    END add_value_adt;

    FUNCTION add_value_fc
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_data_val IN table_table_varchar,
        i_name     IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_value    IN NUMBER,
        i_hist     IN NUMBER DEFAULT NULL
    ) RETURN table_table_varchar IS
        c_function_name CONSTANT obj_name := 'ADD_VALUE_FC';
        l_dbg_msg   debug_msg;
        l_desc      value_str;
        l_alt_value value_str;
    BEGIN
        IF i_value IS NULL
        THEN
            RETURN i_data_val;
        END IF;
    
        l_dbg_msg := 'get unit_measure description';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        --        l_desc := pk_utils.get_institution_name(i_lang => i_lang, i_id_institution => i_value);
        l_desc := pk_adt.get_clues_code(i_id_clues => NULL, i_id_institution => i_value);
    
        l_dbg_msg := 'get alternate value ';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_alt_value := i_value;
    
        l_dbg_msg := 'add unit_measure info to the data structure';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        RETURN add_values(i_data_val  => i_data_val,
                          i_name      => i_name,
                          i_desc      => l_desc,
                          i_value     => i_value,
                          i_alt_value => l_alt_value,
                          i_hist      => i_hist);
    
    END add_value_fc;

    FUNCTION add_value_text
    (
        i_data_val IN table_table_varchar,
        i_name     IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_value    IN VARCHAR2,
        i_hist     IN NUMBER DEFAULT NULL
    ) RETURN table_table_varchar IS
        c_function_name CONSTANT obj_name := 'ADD_VALUE_TEXT';
        l_dbg_msg debug_msg;
    
    BEGIN
        IF i_value IS NULL
        THEN
            RETURN i_data_val;
        END IF;
    
        l_dbg_msg := 'add free text to the data structure';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        RETURN add_values(i_data_val => i_data_val,
                          i_name     => i_name,
                          i_desc     => i_value,
                          i_value    => i_value,
                          i_hist     => i_hist);
    
    END add_value_text;

    --

    FUNCTION add_value_fr
    (
        i_lang     IN language.id_language%TYPE,
        i_data_val IN table_table_varchar,
        i_name     IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_value    IN family_relationship.id_family_relationship%TYPE,
        i_hist     IN NUMBER DEFAULT NULL
    ) RETURN table_table_varchar IS
        c_function_name CONSTANT obj_name := 'ADD_VALUE_FR';
        l_dbg_msg debug_msg;
    
        l_desc value_str;
    
    BEGIN
        IF i_value IS NULL
        THEN
            RETURN i_data_val;
        END IF;
    
        l_dbg_msg := 'get family relationship description';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_desc := get_family_relationship_desc(i_lang => i_lang, i_family_relationship => i_value);
    
        l_dbg_msg := 'add family relationship info to the data structure';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        RETURN add_values(i_data_val => i_data_val,
                          i_name     => i_name,
                          i_desc     => l_desc,
                          i_value    => i_value,
                          i_hist     => i_hist);
    
    END add_value_fr;

    --

    FUNCTION add_value_epis_diagn
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_data_val IN table_table_varchar,
        i_name     IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_value    IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_hist     IN NUMBER DEFAULT NULL
    ) RETURN table_table_varchar IS
        c_function_name CONSTANT obj_name := 'ADD_VALUE_EPIS_DIAGN';
        l_dbg_msg debug_msg;
    
        l_desc      value_str;
        l_value     value_str;
        l_alt_value value_str;
    
    BEGIN
        IF i_value IS NULL
        THEN
            RETURN i_data_val;
        END IF;
    
        l_dbg_msg := 'get diagnosis description and ids';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        SELECT pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                          i_prof                => i_prof,
                                          i_id_alert_diagnosis  => ed.id_alert_diagnosis,
                                          i_id_diagnosis        => d.id_diagnosis,
                                          i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                          i_code                => d.code_icd,
                                          i_flg_other           => d.flg_other,
                                          i_flg_std_diag        => ad.flg_icd9,
                                          i_epis_diag           => ed.id_epis_diagnosis,
                                          i_flg_search_mode     => pk_alert_constant.g_yes),
               ed.id_diagnosis,
               ed.id_alert_diagnosis
          INTO l_desc, l_value, l_alt_value
          FROM epis_diagnosis ed
         INNER JOIN diagnosis d
            ON ed.id_diagnosis = d.id_diagnosis
          LEFT OUTER JOIN alert_diagnosis ad
            ON ed.id_alert_diagnosis = ad.id_alert_diagnosis
         WHERE ed.id_epis_diagnosis = i_value;
    
        l_dbg_msg := 'add diagnosis to the data structure';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        RETURN add_values(i_data_val    => i_data_val,
                          i_name        => i_name,
                          i_desc        => l_desc,
                          i_value       => l_value,
                          i_alt_value   => l_alt_value,
                          i_hist        => i_hist,
                          i_extra_value => i_value);
    
    END add_value_epis_diagn;

    --
    FUNCTION add_value_diagn
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_data_val   IN table_table_varchar,
        i_name       IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_value      IN death_cause.id_death_cause%TYPE,
        i_value_hist IN death_cause_hist.id_death_cause_hist%TYPE,
        i_hist       IN NUMBER DEFAULT NULL
    ) RETURN table_table_varchar IS
        c_function_name CONSTANT obj_name := 'ADD_VALUE_EPIS_DIAGN';
        l_dbg_msg debug_msg;
    
        /*l_desc      value_str;
        l_value     value_str;
        l_alt_value value_str;
        */
    
        l_desc      VARCHAR2(4000);
        l_value     NUMBER;
        l_alt_value VARCHAR(4000);
    
    BEGIN
        IF i_value IS NOT NULL
           AND i_value_hist IS NULL
        THEN
            l_dbg_msg := 'get diagnosis description and ids';
            pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
            SELECT pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                              i_id_diagnosis        => d.id_diagnosis,
                                              i_desc_epis_diagnosis => NULL,
                                              i_code                => d.code_icd,
                                              i_flg_other           => d.flg_other,
                                              i_flg_std_diag        => ad.flg_icd9,
                                              i_epis_diag           => NULL,
                                              i_flg_search_mode     => pk_alert_constant.g_yes),
                   d.id_diagnosis,
                   ad.id_alert_diagnosis
              INTO l_desc, l_value, l_alt_value
              FROM death_cause dc
              LEFT JOIN diagnosis d
                ON dc.id_diagnosis = d.id_diagnosis
              LEFT JOIN alert_diagnosis ad
                ON dc.id_alert_diagnosis = ad.id_alert_diagnosis
             WHERE dc.id_death_cause = i_value;
        ELSIF i_value_hist IS NOT NULL
              AND i_value IS NULL
        THEN
        
            l_dbg_msg := 'get diagnosis description and ids hist';
            pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
            SELECT pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                              i_id_diagnosis        => d.id_diagnosis,
                                              i_desc_epis_diagnosis => NULL,
                                              i_code                => d.code_icd,
                                              i_flg_other           => d.flg_other,
                                              i_flg_std_diag        => ad.flg_icd9,
                                              i_epis_diag           => NULL,
                                              i_flg_search_mode     => pk_alert_constant.g_yes),
                   d.id_diagnosis,
                   ad.id_alert_diagnosis
              INTO l_desc, l_value, l_alt_value
              FROM death_cause_hist dc
              LEFT JOIN diagnosis d
                ON dc.id_diagnosis = d.id_diagnosis
              LEFT JOIN alert_diagnosis ad
                ON dc.id_alert_diagnosis = ad.id_alert_diagnosis
             WHERE dc.id_death_cause_hist = i_value_hist;
        
        ELSE
            RETURN i_data_val;
        END IF;
    
        l_dbg_msg := 'add diagnosis to the data structure';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        RETURN add_values(i_data_val  => i_data_val,
                          i_name      => i_name,
                          i_desc      => l_desc,
                          i_value     => l_value,
                          i_alt_value => l_alt_value,
                          i_hist      => i_hist);
    
    END add_value_diagn;

    FUNCTION add_value_pat_hist_diagn
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_data_val IN table_table_varchar,
        i_name     IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_value    IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE,
        i_hist     IN NUMBER DEFAULT NULL
    ) RETURN table_table_varchar IS
        c_function_name CONSTANT obj_name := 'ADD_VALUE_PAT_HIST_DIAGN';
        l_dbg_msg debug_msg;
    
        l_desc      value_str;
        l_value     value_str;
        l_alt_value value_str;
    
    BEGIN
        IF i_value IS NULL
        THEN
            RETURN i_data_val;
        END IF;
    
        l_dbg_msg := 'get diagnosis description and ids';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        SELECT decode(phd.id_alert_diagnosis,
                      NULL,
                      phd.desc_pat_history_diagnosis,
                      decode(phd.desc_pat_history_diagnosis, NULL, NULL, phd.desc_pat_history_diagnosis || ' - ') ||
                      pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                 i_prof               => i_prof,
                                                 i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                 i_code               => d.code_icd,
                                                 i_flg_other          => d.flg_other,
                                                 i_flg_std_diag       => ad.flg_icd9)),
               phd.id_diagnosis,
               phd.id_alert_diagnosis
          INTO l_desc, l_value, l_alt_value
          FROM pat_history_diagnosis phd
         INNER JOIN diagnosis d
            ON phd.id_diagnosis = d.id_diagnosis
          LEFT OUTER JOIN alert_diagnosis ad
            ON phd.id_alert_diagnosis = ad.id_alert_diagnosis
           AND ad.flg_type = pk_summary_page.g_alert_diag_type_med
         WHERE phd.id_pat_history_diagnosis = i_value;
    
        l_dbg_msg := 'add diagnosis to the data structure';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        RETURN add_values(i_data_val  => i_data_val,
                          i_name      => i_name,
                          i_desc      => l_desc,
                          i_value     => l_value,
                          i_alt_value => l_alt_value,
                          i_hist      => i_hist);
    
    END add_value_pat_hist_diagn;

    --

    FUNCTION add_value_org_tis
    (
        i_lang     IN language.id_language%TYPE,
        i_data_val IN table_table_varchar,
        i_name     IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_value    IN organ_tissue.id_organ_tissue%TYPE,
        i_hist     IN NUMBER DEFAULT NULL
    ) RETURN table_table_varchar IS
        c_function_name CONSTANT obj_name := 'ADD_VALUE_ORG_TIS';
        l_dbg_msg debug_msg;
    
        l_desc value_str;
    
    BEGIN
        IF i_value IS NULL
        THEN
            RETURN i_data_val;
        END IF;
    
        l_dbg_msg := 'get organ/tissue description';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        SELECT pk_translation.get_translation(i_lang, ot.code_organ_tissue)
          INTO l_desc
          FROM organ_tissue ot
         WHERE ot.id_organ_tissue = i_value;
    
        l_dbg_msg := 'add diagnosis to the data structure';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        RETURN add_values(i_data_val  => i_data_val,
                          i_name      => i_name,
                          i_desc      => l_desc,
                          i_value     => i_value,
                          i_alt_value => i_value,
                          i_hist      => i_hist);
    
    END add_value_org_tis;

    --

    FUNCTION get_registry_prof_data
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_registry_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_prof_registry IN professional.id_professional%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_flg_status    IN VARCHAR2,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel  IN CLOB,
        o_prof_data     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
        
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_REGISTRY_PROF_DATA';
        l_dbg_msg debug_msg;
    
        l_registry_date      value_str;
        l_prof_name          value_str;
        l_prof_speciality    value_str;
        l_cancel_reason_desc value_str;
    
    BEGIN
        l_dbg_msg := 'get registry date formatted as a string to be shown';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_registry_date := pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                       i_date => i_registry_date,
                                                       i_inst => i_prof.institution,
                                                       i_soft => i_prof.software);
    
        l_dbg_msg := 'get professional name';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_prof_name := pk_prof_utils.get_name_signature(i_lang    => i_lang,
                                                        i_prof    => i_prof,
                                                        i_prof_id => i_prof_registry);
    
        l_dbg_msg := 'get professional speciality';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_prof_speciality := pk_prof_utils.get_spec_signature(i_lang    => i_lang,
                                                              i_prof    => i_prof,
                                                              i_prof_id => i_prof_registry,
                                                              i_dt_reg  => i_registry_date,
                                                              i_episode => i_episode);
    
        l_dbg_msg := 'get cancel reason description';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_cancel_reason_desc := pk_cancel_reason.get_cancel_reason_desc(i_lang             => i_lang,
                                                                        i_prof             => i_prof,
                                                                        i_id_cancel_reason => i_cancel_reason);
    
        l_dbg_msg := 'return cursor with professional name, speciality and date of changes';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        OPEN o_prof_data FOR
            SELECT l_registry_date      AS registry_date,
                   l_prof_name          AS prof_name,
                   l_prof_speciality    AS prof_speciality,
                   i_flg_status         AS flg_status,
                   l_cancel_reason_desc AS cancel_reason_desc,
                   i_notes_cancel       AS notes_cancel
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(i_cursor => o_prof_data);
            RETURN FALSE;
        
    END get_registry_prof_data;

    FUNCTION get_death_registry_prof_data
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_tbl_id    IN table_number,
        o_prof_data OUT pk_types.cursor_type,
        o_error     OUT t_error_out
        
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_REGISTRY_PROF_DATA';
        l_dbg_msg debug_msg;
    BEGIN
    
        l_dbg_msg := 'return cursor with professional name, speciality and date of changes';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
    
        OPEN o_prof_data FOR
            SELECT dr.id_death_registry AS id_record,
                   pk_date_utils.date_char_tsz(i_lang => i_lang,
                                               i_date => dr.dt_death_registry,
                                               i_inst => i_prof.institution,
                                               i_soft => i_prof.software) AS registry_date,
                   pk_prof_utils.get_name_signature(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_prof_id => dr.id_prof_death_registry) AS prof_name,
                   pk_prof_utils.get_spec_signature(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_prof_id => dr.id_prof_death_registry,
                                                    i_dt_reg  => dr.dt_death_registry,
                                                    i_episode => dr.id_episode) AS prof_speciality,
                   dr.flg_status AS flg_status,
                   pk_cancel_reason.get_cancel_reason_desc(i_lang             => i_lang,
                                                           i_prof             => i_prof,
                                                           i_id_cancel_reason => dr.id_cancel_reason) AS cancel_reason_desc,
                   dr.notes_cancel AS notes_cancel
              FROM death_registry dr
             WHERE dr.id_death_registry IN (SELECT column_value
                                              FROM TABLE(i_tbl_id))
             ORDER BY dr.dt_death_registry DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(i_cursor => o_prof_data);
            RETURN FALSE;
        
    END get_death_registry_prof_data;

    FUNCTION get_organ_donor_prof_data
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_tbl_id    IN table_number,
        o_prof_data OUT pk_types.cursor_type,
        o_error     OUT t_error_out
        
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_ORGAN_DONOR_PROF_DATA';
        l_dbg_msg debug_msg;
    BEGIN
    
        l_dbg_msg := 'return cursor with professional name, speciality and date of changes';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
    
        OPEN o_prof_data FOR
            SELECT od.id_organ_donor AS id_record,
                   pk_date_utils.date_char_tsz(i_lang => i_lang,
                                               i_date => od.dt_organ_donor,
                                               i_inst => i_prof.institution,
                                               i_soft => i_prof.software) AS registry_date,
                   pk_prof_utils.get_name_signature(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_prof_id => od.id_prof_organ_donor) AS prof_name,
                   pk_prof_utils.get_spec_signature(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_prof_id => od.id_prof_organ_donor,
                                                    i_dt_reg  => od.dt_organ_donor,
                                                    i_episode => od.id_episode) AS prof_speciality,
                   od.flg_status AS flg_status,
                   pk_cancel_reason.get_cancel_reason_desc(i_lang             => i_lang,
                                                           i_prof             => i_prof,
                                                           i_id_cancel_reason => od.id_cancel_reason) AS cancel_reason_desc,
                   od.notes_cancel AS notes_cancel
              FROM organ_donor od
             WHERE od.id_organ_donor IN (SELECT column_value
                                           FROM TABLE(i_tbl_id))
             ORDER BY od.dt_organ_donor DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(i_cursor => o_prof_data);
            RETURN FALSE;
        
    END get_organ_donor_prof_data;

    FUNCTION tf_ds_items_values
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT c_node_component,
        i_component_root IN ds_cmpt_mkt_rel.internal_name_parent%TYPE DEFAULT NULL
    ) RETURN t_table_ds_items_values IS
        c_function_name CONSTANT obj_name := 'TF_DS_ITEMS_VALUES';
    
        l_dbg_msg debug_msg;
    
        c_ot_type_o CONSTANT organ_tissue.flg_type%TYPE := 'O';
        c_ot_type_t CONSTANT organ_tissue.flg_type%TYPE := 'T';
    
        l_inst_market organ_tissue_market.id_market%TYPE;
    
        l_ret_tbl t_table_ds_items_values;
    BEGIN
        l_dbg_msg := 'get the market id for the current institution';
        pk_alertlog.log_debug(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_inst_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
    
        SELECT t_rec_ds_items_values(id_ds_cmpt_mkt_rel => a.id_ds_cmpt_mkt_rel,
                                     id_ds_component    => a.id_ds_component,
                                     internal_name      => a.internal_name,
                                     flg_component_type => a.flg_component_type,
                                     item_desc          => a.item_desc,
                                     item_value         => a.item_value,
                                     item_alt_value     => a.item_alt_value,
                                     item_xml_value     => NULL,
                                     item_rank          => a.item_rank)
          BULK COLLECT
          INTO l_ret_tbl
          FROM (SELECT DISTINCT dscm.id_ds_cmpt_mkt_rel,
                                dscp.id_ds_component,
                                dscp.internal_name,
                                dscp.flg_component_type,
                                aux.desc_list           AS item_desc,
                                aux.id_sys_list         AS item_value,
                                aux.flg_context         AS item_alt_value,
                                aux.rank                AS item_rank
                  FROM ds_component dscp
                 INNER JOIN TABLE(pk_dynamic_screen.get_cmp_rel(i_prof, i_component_name, i_component_type, i_component_root)) dscm
                    ON dscp.id_ds_component = dscm.id_ds_component_child
                 INNER JOIN TABLE(pk_sys_list.tf_sys_list_values(i_lang, i_prof, dscp.slg_internal_name)) aux
                    ON dscp.slg_internal_name = aux.internal_name
                 WHERE dscp.flg_component_type = c_leaf_component
                   AND dscp.flg_data_type = c_ms_data_type
                   AND aux.desc_list IS NOT NULL
                
                UNION ALL
                
                SELECT dscm.id_ds_cmpt_mkt_rel,
                       dscp.id_ds_component,
                       dscp.internal_name,
                       dscp.flg_component_type,
                       aux.desc_list           AS item_desc,
                       aux.id_sys_list         AS item_value,
                       aux.flg_context         AS item_alt_value,
                       aux.rank                AS item_rank
                  FROM ds_component dscp
                 INNER JOIN TABLE(pk_dynamic_screen.get_cmp_rel_child(i_prof, i_component_name, i_component_type, pk_alert_constant.g_no, i_component_root)) dscm
                    ON dscp.id_ds_component = dscm.id_ds_component_child
                 INNER JOIN ds_cmpt_mkt_rel d
                    ON dscm.id_ds_component_parent = d.id_ds_component_child
                 INNER JOIN TABLE(pk_sys_list.tf_sys_list_values(i_lang, i_prof, dscp.slg_internal_name)) aux
                    ON dscp.slg_internal_name = aux.internal_name
                 WHERE dscp.flg_component_type = c_leaf_component
                   AND dscp.flg_data_type = c_ms_data_type
                   AND aux.desc_list IS NOT NULL
                   AND d.flg_component_type_parent = c_node_component
                   AND d.id_market IN (0, l_inst_market)
                
                UNION ALL
                
                SELECT dscm.id_ds_cmpt_mkt_rel,
                       dscp.id_ds_component,
                       dscp.internal_name,
                       dscp.flg_component_type,
                       aux.item_desc,
                       aux.item_value,
                       aux.item_alt_value,
                       aux.item_rank
                  FROM ds_component dscp
                 INNER JOIN TABLE(pk_dynamic_screen.get_cmp_rel(i_prof, i_component_name, i_component_type)) dscm
                    ON dscp.id_ds_component = dscm.id_ds_component_child
                 INNER JOIN (SELECT c_mo_data_type AS flg_data_type,
                                   pk_translation.get_translation(i_lang, ot.code_organ_tissue) AS item_desc,
                                   ot.id_organ_tissue AS item_value,
                                   to_char(ot.id_organ_tissue) AS item_alt_value,
                                   NULL AS item_rank
                              FROM organ_tissue ot
                             INNER JOIN organ_tissue_market otm
                                ON otm.id_organ_tissue = ot.id_organ_tissue
                             WHERE otm.id_market = l_inst_market
                               AND ot.flg_type = c_ot_type_o
                               AND ot.flg_available = pk_alert_constant.get_yes) aux
                    ON dscp.flg_data_type = aux.flg_data_type
                 WHERE dscp.flg_component_type = c_leaf_component
                   AND dscp.flg_data_type = c_mo_data_type
                   AND aux.item_desc IS NOT NULL
                UNION ALL
                -- cmf
                SELECT DISTINCT dscm.id_ds_cmpt_mkt_rel,
                                dscp.id_ds_component,
                                dscp.internal_name,
                                dscp.flg_component_type,
                                desc_option               item_desc,
                                aux.id_multichoice_option item_value,
                                NULL                      item_alt_value,
                                aux.rank                  item_rank
                  FROM ds_component dscp
                 INNER JOIN TABLE(pk_dynamic_screen.get_cmp_rel(i_prof, i_component_name, i_component_type)) dscm
                    ON dscp.id_ds_component = dscm.id_ds_component_child
                 INNER JOIN TABLE(pk_multichoice.tf_multichoice_options(i_lang, i_prof, dscp.multi_option_column)) aux
                    ON dscp.multi_option_column = aux.multi_option_column
                 WHERE dscp.flg_component_type = c_leaf_component
                   AND dscp.flg_data_type IN (c_ms_data_type, c_data_type_mf)
                   AND aux.desc_option IS NOT NULL
                -------------------------
                UNION ALL
                SELECT id_ds_cmpt_mkt_rel,
                       id_ds_component,
                       internal_name,
                       flg_component_type,
                       item_desc,
                       item_value,
                       NULL item_alt_value,
                       item_rank
                  FROM (SELECT dscm.id_ds_cmpt_mkt_rel,
                               dscp.id_ds_component,
                               dscp.internal_name,
                               dscp.flg_component_type,
                               CASE
                                    WHEN pk_dynamic_screen.check_unit_measure_fields(dscm.id_unit_measure,
                                                                                     dscm.id_unit_measure_subtype) =
                                         pk_alert_constant.g_yes THEN
                                     dscm.id_unit_measure
                                    ELSE
                                     dscp.id_unit_measure
                                END id_unit_measure,
                               CASE
                                    WHEN pk_dynamic_screen.check_unit_measure_fields(dscm.id_unit_measure,
                                                                                     dscm.id_unit_measure_subtype) =
                                         pk_alert_constant.g_yes THEN
                                     dscm.id_unit_measure_subtype
                                    ELSE
                                     dscp.id_unit_measure_subtype
                                END id_unit_measure_subtype,
                               aux.desc_unit_measure item_desc,
                               aux.id_unit_measure item_value,
                               aux.order_rank item_rank
                          FROM ds_component dscp
                          JOIN TABLE(pk_dynamic_screen.get_cmp_rel(i_prof, i_component_name, i_component_type)) dscm
                            ON dscp.id_ds_component = dscm.id_ds_component_child
                          JOIN TABLE(pk_dynamic_screen.get_dyn_umea(i_lang, i_prof, dscp.id_ds_component, dscm.id_unit_measure, dscm.id_unit_measure_subtype)) aux
                            ON aux.id_ds_component = dscp.id_ds_component
                         WHERE aux.desc_unit_measure IS NOT NULL
                           AND dscp.flg_component_type = c_leaf_component
                           AND dscp.flg_data_type = c_data_type_k)
                -------------------------------                   
                UNION ALL
                SELECT dscm.id_ds_cmpt_mkt_rel,
                       dscp.id_ds_component,
                       dscp.internal_name,
                       dscp.flg_component_type,
                       aux.item_desc,
                       aux.item_value,
                       aux.item_alt_value,
                       aux.item_rank
                  FROM ds_component dscp
                 INNER JOIN TABLE(pk_dynamic_screen.get_cmp_rel(i_prof, i_component_name, i_component_type)) dscm
                    ON dscp.id_ds_component = dscm.id_ds_component_child
                 INNER JOIN (SELECT c_mt_data_type AS flg_data_type,
                                   pk_translation.get_translation(i_lang, ot.code_organ_tissue) AS item_desc,
                                   ot.id_organ_tissue AS item_value,
                                   to_char(ot.id_organ_tissue) AS item_alt_value,
                                   NULL AS item_rank
                              FROM organ_tissue ot
                             INNER JOIN organ_tissue_market otm
                                ON ot.id_organ_tissue = otm.id_organ_tissue
                             WHERE otm.id_market = l_inst_market
                               AND ot.flg_type = c_ot_type_t
                               AND ot.flg_available = pk_alert_constant.get_yes) aux
                    ON dscp.flg_data_type = aux.flg_data_type
                 WHERE dscp.flg_component_type = c_leaf_component
                   AND dscp.flg_data_type = c_mt_data_type
                   AND aux.item_desc IS NOT NULL
                
                UNION ALL
                
                SELECT dscm.id_ds_cmpt_mkt_rel,
                       dscp.id_ds_component,
                       dscp.internal_name,
                       dscp.flg_component_type,
                       aux.item_desc,
                       aux.item_value,
                       aux.item_alt_value,
                       aux.item_rank
                  FROM ds_component dscp
                 INNER JOIN TABLE(pk_dynamic_screen.get_cmp_rel(i_prof, i_component_name, i_component_type)) dscm
                    ON dscp.id_ds_component = dscm.id_ds_component_child
                 INNER JOIN (SELECT c_mr_data_type AS flg_data_type,
                                   pk_translation.get_translation(i_lang, fr.code_family_relationship) AS item_desc,
                                   fr.id_family_relationship AS item_value,
                                   to_char(fr.id_family_relationship) AS item_alt_value,
                                   NULL AS item_rank
                              FROM family_relationship fr
                             INNER JOIN relationship_grp_market rgm
                                ON fr.id_family_relationship = rgm.id_family_relationship
                             WHERE fr.flg_available = pk_alert_constant.get_yes
                               AND rgm.id_market = l_inst_market
                               AND rgm.id_relationship_type = c_rel_type_organ_donation) aux
                    ON dscp.flg_data_type = aux.flg_data_type
                 WHERE dscp.flg_component_type = c_leaf_component
                   AND dscp.flg_data_type = c_mr_data_type
                   AND aux.item_desc IS NOT NULL
                
                 ORDER BY id_ds_component, item_rank, item_desc) a;
    
        RETURN l_ret_tbl;
    END tf_ds_items_values;

    /**********************************************************************************************
    * Determines if the patient age is within the limits defined to the ds_component or ds_cmp_mkt_rel
    *   
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_pat_age                Patient age
    * @param i_age_limit              Limit to check (minimum or maximum)
    * @param i_limit_type             (MIN) Check minimum; (MAX) Check maximum;
    *
    * @return                         Y - Value within the limits; N - Value not within the limits.
    *                        
    * @author                         Sergio Dias
    * @version                        2.6.3.8.5
    * @since                          Nov/26/2013 
    **********************************************************************************************/
    FUNCTION check_age_limits
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_pat_age    IN NUMBER,
        i_age_limit  IN NUMBER,
        i_limit_type IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_result VARCHAR2(1) := pk_alert_constant.g_no;
        --l_error  t_error_out;
        l_param_error EXCEPTION;
    BEGIN
    
        IF i_limit_type NOT IN (g_age_min, g_age_max)
           OR i_limit_type IS NULL
        THEN
            RAISE l_param_error;
        END IF;
    
        IF (i_pat_age >= i_age_limit AND i_limit_type = g_age_min OR
           i_pat_age <= i_age_limit AND i_limit_type = g_age_max)
           AND i_pat_age IS NOT NULL
           AND i_age_limit IS NOT NULL
        THEN
            l_result := pk_alert_constant.g_yes;
        
        ELSIF i_age_limit IS NULL
--              OR i_pat_age IS NULL
        THEN
            l_result := pk_alert_constant.g_yes;
        elsif i_pat_age IS NULL then
          l_result := pk_alert_constant.g_no;
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END check_age_limits;

    /**********************************************************************************************
    * Get a dynamic screen section structure
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   professional, software and institution ids             
    * @param        i_component_name         Component internal name
    * @param        i_component_type         Component type (defaults to node component type)
    * @param        i_component_list         (Y/N) If Y(es) it returns only a list of child components
    *                                        and not the entire structure (defaults to N)
    * @param        o_section                Section components structure
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        07-Jun-2010
    **********************************************************************************************/
    FUNCTION tf_ds_sections1
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT c_node_component,
        i_component_list IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_patient        IN patient.id_patient%TYPE
    ) RETURN t_table_ds_sections IS
        c_function_name CONSTANT obj_name := 'TF_DS_SECTIONS';
        --
        l_dbg_msg        debug_msg;
        l_ret_tbl        t_table_ds_sections;
        l_patient_age    patient.age%TYPE;
        l_patient_gender patient.gender%TYPE;
    BEGIN
    
        BEGIN
            IF i_patient IS NOT NULL
            THEN
                SELECT p.gender,
                       pk_patient.get_pat_age(i_lang     => i_lang,
                                              i_dt_birth => p.dt_birth,
                                              i_age      => p.age,
                                              i_patient  => i_patient)
                  INTO l_patient_gender, l_patient_age
                  FROM patient p
                 WHERE p.id_patient = i_patient;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                l_patient_gender := NULL;
                l_patient_age    := NULL;
        END;
    
        l_dbg_msg := 'get dynamic screen section structure';
        pk_alertlog.log_debug(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        SELECT t_rec_ds_sections(id_ds_cmpt_mkt_rel     => a.id_ds_cmpt_mkt_rel,
                                 id_ds_component_parent => a.id_ds_component_parent,
                                 id_ds_component        => a.id_ds_component,
                                 component_desc         => a.component_desc,
                                 internal_name          => a.internal_name,
                                 flg_component_type     => a.flg_component_type,
                                 flg_data_type          => a.flg_data_type,
                                 slg_internal_name      => a.slg_internal_name,
                                 addit_info_xml_value   => NULL,
                                 rank                   => a.rank,
                                 max_len                => a.max_len,
                                 min_value              => a.min_value,
                                 max_value              => a.max_value,
                                 gender                 => a.gender,
                                 age_min_value          => a.age_min_value,
                                 age_min_unit_measure   => a.age_min_unit_measure,
                                 age_max_value          => a.age_max_value,
                                 age_max_unit_measure   => a.age_max_unit_measure,
                                 component_values       => NULL)
          BULK COLLECT
          INTO l_ret_tbl
          FROM (SELECT dscm.id_ds_cmpt_mkt_rel,
                       dscm.id_ds_component_parent,
                       dscp.id_ds_component,
                       pk_translation.get_translation(i_lang, dscp.code_ds_component) AS component_desc,
                       dscp.internal_name,
                       dscp.flg_component_type,
                       dscp.flg_data_type,
                       dscp.slg_internal_name,
                       dscm.rank,
                       dscp.max_len,
                       dscp.min_value,
                       dscp.max_value,
                       dscp.gender,
                       dscp.age_min_value,
                       dscp.age_min_unit_measure,
                       dscp.age_max_value,
                       dscp.age_max_unit_measure,
                       dscm.rn
                  FROM ds_component dscp
                 INNER JOIN TABLE(pk_dynamic_screen.get_cmp_rel(i_prof, i_component_name, i_component_type, i_component_list)) dscm
                    ON dscp.id_ds_component = dscm.id_ds_component_child
                 WHERE (dscm.age_min_value IS NULL AND dscm.age_max_value IS NULL AND dscm.gender IS NULL AND
                       nvl(nvl(dscp.gender, l_patient_gender), 'UNKNOWN') = nvl(l_patient_gender, 'UNKNOWN') AND
                       check_age_limits(i_lang       => i_lang,
                                         i_prof       => i_prof,
                                         i_pat_age    => l_patient_age,
                                         i_age_limit  => decode(dscp.age_min_unit_measure,
                                                                g_id_unit_measure_year,
                                                                dscp.age_min_value,
                                                                pk_unit_measure.get_unit_mea_conversion(i_value         => dscp.age_min_value,
                                                                                                        i_unit_meas     => dscp.age_min_unit_measure,
                                                                                                        i_unit_meas_def => g_id_unit_measure_year)),
                                         i_limit_type => pk_edis_triage.g_age_min) = pk_alert_constant.g_yes AND
                       check_age_limits(i_lang       => i_lang,
                                         i_prof       => i_prof,
                                         i_pat_age    => l_patient_age,
                                         i_age_limit  => decode(dscp.age_max_unit_measure,
                                                                g_id_unit_measure_year,
                                                                dscp.age_max_value,
                                                                pk_unit_measure.get_unit_mea_conversion(i_value         => dscp.age_max_value,
                                                                                                        i_unit_meas     => dscp.age_max_unit_measure,
                                                                                                        i_unit_meas_def => g_id_unit_measure_year)),
                                         i_limit_type => pk_edis_triage.g_age_max) = pk_alert_constant.g_yes)
                    OR ((dscm.age_min_value IS NOT NULL OR dscm.age_max_value IS NOT NULL OR dscm.gender IS NOT NULL) AND
                       nvl(nvl(dscm.gender, l_patient_gender), 'UNKNOWN') = nvl(l_patient_gender, 'UNKNOWN') AND
                       check_age_limits(i_lang       => i_lang,
                                         i_prof       => i_prof,
                                         i_pat_age    => l_patient_age,
                                         i_age_limit  => decode(dscm.age_min_unit_measure,
                                                                g_id_unit_measure_year,
                                                                dscm.age_min_value,
                                                                pk_unit_measure.get_unit_mea_conversion(i_value         => dscm.age_min_value,
                                                                                                        i_unit_meas     => dscm.age_min_unit_measure,
                                                                                                        i_unit_meas_def => g_id_unit_measure_year)),
                                         i_limit_type => pk_edis_triage.g_age_min) = pk_alert_constant.g_yes AND
                       check_age_limits(i_lang       => i_lang,
                                         i_prof       => i_prof,
                                         i_pat_age    => l_patient_age,
                                         i_age_limit  => decode(dscm.age_max_unit_measure,
                                                                g_id_unit_measure_year,
                                                                dscm.age_max_value,
                                                                pk_unit_measure.get_unit_mea_conversion(i_value         => dscm.age_max_value,
                                                                                                        i_unit_meas     => dscm.age_max_unit_measure,
                                                                                                        i_unit_meas_def => g_id_unit_measure_year)),
                                         i_limit_type => pk_edis_triage.g_age_max) = pk_alert_constant.g_yes)) a
         ORDER BY rn, rank;
    
        RETURN l_ret_tbl;
    END tf_ds_sections1;
    --
    /**********************************************************************************************
    * Get a dynamic screen section structure
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   professional, software and institution ids             
    * @param        i_component_name         Component internal name
    * @param        i_component_type         Component type (defaults to node component type)
    *
    * @return       Component record
    *
    * @author       Alexandre Santos
    * @version      2.6.1
    * @since        26-12-2012
    **********************************************************************************************/
    FUNCTION get_ds_section_rec
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT c_node_component
    ) RETURN t_rec_ds_sections IS
        c_function_name CONSTANT obj_name := 'GET_DS_SECTION_REC';
        --
        l_dbg_msg debug_msg;
        l_ret_rec t_rec_ds_sections;
        --
        l_cfg_vars rec_cfg_vars;
    BEGIN
        l_dbg_msg := 'CALL GET_CFG_VARS';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_cfg_vars := get_cfg_vars(i_prof           => i_prof,
                                   i_component_name => i_component_name,
                                   i_component_type => i_component_type);
    
        l_dbg_msg := 'get dynamic screen section structure';
        pk_alertlog.log_debug(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        SELECT t_rec_ds_sections(id_ds_cmpt_mkt_rel     => a.id_ds_cmpt_mkt_rel,
                                 id_ds_component_parent => a.id_ds_component_parent,
                                 id_ds_component        => a.id_ds_component,
                                 component_desc         => a.component_desc,
                                 internal_name          => a.internal_name,
                                 flg_component_type     => a.flg_component_type,
                                 flg_data_type          => a.flg_data_type,
                                 slg_internal_name      => a.slg_internal_name,
                                 addit_info_xml_value   => NULL,
                                 rank                   => a.rank,
                                 max_len                => a.max_len,
                                 min_value              => a.min_value,
                                 max_value              => a.max_value,
                                 gender                 => a.gender,
                                 age_min_value          => a.age_min_value,
                                 age_min_unit_measure   => a.age_min_unit_measure,
                                 age_max_value          => a.age_max_value,
                                 age_max_unit_measure   => a.age_max_unit_measure,
                                 component_values       => NULL)
          INTO l_ret_rec
          FROM (SELECT dscm.id_ds_cmpt_mkt_rel,
                       dscm.id_ds_component_parent,
                       dscp.id_ds_component,
                       pk_translation.get_translation(i_lang, dscp.code_ds_component) AS component_desc,
                       dscp.internal_name,
                       dscp.flg_component_type,
                       dscp.flg_data_type,
                       dscp.slg_internal_name,
                       dscm.rank,
                       dscp.max_len,
                       dscp.min_value,
                       dscp.max_value,
                       dscp.gender,
                       dscp.age_min_value,
                       dscp.age_min_unit_measure,
                       dscp.age_max_value,
                       dscp.age_max_unit_measure
                  FROM ds_component dscp
                 INNER JOIN ds_cmpt_mkt_rel dscm
                    ON dscm.id_ds_component_child = dscp.id_ds_component
                 WHERE dscm.id_market = l_cfg_vars.id_market
                   AND dscm.id_software = l_cfg_vars.id_software
                   AND dscp.internal_name = i_component_name
                   AND dscp.flg_component_type = i_component_type) a;
    
        RETURN l_ret_rec;
    END get_ds_section_rec;

    --
    /**********************************************************************************************
    * Get dynamic screen section events
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   professional, software and institution ids             
    * @param        i_component_name         Component internal name
    * @param        i_component_type         Component type (defaults to node component type)
    * @param        o_events                 Section events
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        07-Jun-2010
    **********************************************************************************************/
    FUNCTION tf_ds_events_cmf
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT c_node_component
    ) RETURN t_table_ds_events IS
        c_function_name CONSTANT obj_name := 'TF_DS_EVENTS';
        --
        l_dbg_msg debug_msg;
        l_ret_tbl t_table_ds_events;
    BEGIN
        l_dbg_msg := 'get dynamic screen section events';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        SELECT t_rec_ds_events(id_ds_event    => dsev.id_ds_event,
                               origin         => dsev.id_ds_cmpt_mkt_rel,
                               VALUE          => dsev.value,
                               target         => dset.id_ds_cmpt_mkt_rel,
                               flg_event_type => dset.flg_event_type)
          BULK COLLECT
          INTO l_ret_tbl
          FROM ds_event dsev
         INNER JOIN ds_event_target dset
            ON dsev.id_ds_event = dset.id_ds_event
         INNER JOIN TABLE(get_cmp_rel(i_prof, i_component_name, i_component_type)) dscm
            ON dsev.id_ds_cmpt_mkt_rel = dscm.id_ds_cmpt_mkt_rel;
    
        RETURN l_ret_tbl;
    END tf_ds_events_cmf;

    FUNCTION tf_ds_events
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT c_node_component,
        i_patient        IN NUMBER DEFAULT NULL,
        i_component_root IN ds_cmpt_mkt_rel.internal_name_parent%TYPE DEFAULT NULL
    ) RETURN t_table_ds_events IS
        c_function_name CONSTANT obj_name := 'TF_DS_EVENTS';
        l_dbg_msg       debug_msg;
        l_ret_tbl       t_table_ds_events;
        tbl             table_varchar := table_varchar();
        tbl_sect_active t_table_ds_sections := t_table_ds_sections();
        tbl_sect_all    tf_ds_section := tf_ds_section();
        root_name       VARCHAR2(200 CHAR);
        root_type       VARCHAR2(200 CHAR);
    
        l_compulsory_reas_mandatory sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'COMPULSORY_REASON_MANDATORY',
                                                                                     i_prof    => i_prof);
    BEGIN
    
        IF i_patient IS NULL
        THEN
        
            l_dbg_msg := 'get dynamic screen section events';
            pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
            SELECT t_rec_ds_events(id_ds_event    => t.id_ds_event,
                                   origin         => t.id_ds_cmpt_mkt_rel,
                                   VALUE          => t.value,
                                   target         => t.id_ds_cmpt_mkt_rel1,
                                   flg_event_type => t.flg_event_type)
              BULK COLLECT
              INTO l_ret_tbl
              FROM (SELECT dsev.id_ds_event,
                           dsev.id_ds_cmpt_mkt_rel,
                           dsev.value,
                           dset.id_ds_cmpt_mkt_rel id_ds_cmpt_mkt_rel1,
                           dset.flg_event_type
                      FROM ds_event dsev
                     INNER JOIN ds_event_target dset
                        ON dsev.id_ds_event = dset.id_ds_event
                     INNER JOIN TABLE(get_cmp_rel(i_prof, i_component_name, i_component_type, i_component_root)) dscm
                        ON dsev.id_ds_cmpt_mkt_rel = dscm.id_ds_cmpt_mkt_rel
                    UNION ALL
                    SELECT dsev.id_ds_event,
                           dsev.id_ds_cmpt_mkt_rel,
                           dsev.value,
                           dset.id_ds_cmpt_mkt_rel id_ds_cmpt_mkt_rel1,
                           decode(dset.id_ds_event_target,
                                  pk_admission_request.g_reas_adm_event_target_active,
                                  decode(l_compulsory_reas_mandatory,
                                         pk_alert_constant.g_yes,
                                         dset.flg_event_type,
                                         pk_alert_constant.g_active),
                                  dset.flg_event_type) flg_event_type
                      FROM ds_event dsev
                     INNER JOIN ds_event_target dset
                        ON dsev.id_ds_event = dset.id_ds_event
                     INNER JOIN TABLE(get_cmp_rel_child(i_prof, i_component_name, i_component_type, pk_alert_constant.g_no, i_component_root)) dscm
                        ON dsev.id_ds_cmpt_mkt_rel = dscm.id_ds_cmpt_mkt_rel) t;
        
        ELSE
        
            tbl := get_ds_section_root(i_lang           => i_lang,
                                       i_prof           => i_prof,
                                       i_component_name => i_component_name,
                                       i_component_type => i_component_type);
        
            root_name := tbl(k_pos_name);
            root_type := tbl(k_pos_flg_type);
        
            tbl_sect_active := tf_ds_sections(i_lang           => i_lang,
                                              i_prof           => i_prof,
                                              i_component_name => root_name,
                                              i_component_type => root_type,
                                              i_patient        => i_patient);
        
            tbl_sect_all := get_cmp_rel(i_prof, i_component_name, i_component_type);
        
            l_dbg_msg := 'get dynamic screen section events';
            pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
            SELECT t_rec_ds_events(id_ds_event    => dsev.id_ds_event,
                                   origin         => dsev.id_ds_cmpt_mkt_rel,
                                   VALUE          => dsev.value,
                                   target         => dset.id_ds_cmpt_mkt_rel,
                                   flg_event_type => dset.flg_event_type)
              BULK COLLECT
              INTO l_ret_tbl
              FROM ds_event dsev
              JOIN ds_event_target dset
                ON dsev.id_ds_event = dset.id_ds_event
              JOIN TABLE(tbl_sect_all) dscm
                ON dsev.id_ds_cmpt_mkt_rel = dscm.id_ds_cmpt_mkt_rel
              JOIN TABLE(tbl_sect_active) dsec
                ON dsec.id_ds_cmpt_mkt_rel = dset.id_ds_cmpt_mkt_rel;
        
        END IF;
    
        RETURN l_ret_tbl;
    END tf_ds_events;

    /**********************************************************************************************
    * Get dynamic screen section default events
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   professional, software and institution ids             
    * @param        i_component_name         Component internal name
    * @param        i_component_type         Component type (defaults to node component type)
    * @param        i_component_list         (Y/N) If Y(es) it returns only the default events for
    *                                        the child components 
    *                                        and not for all componentsthe entire structure (defaults to N(o))
    * @param        o_def_events             Section default events
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        07-Jun-2010
    **********************************************************************************************/
    FUNCTION tf_ds_def_events
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT c_node_component,
        i_component_list IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_component_root IN ds_cmpt_mkt_rel.internal_name_parent%TYPE DEFAULT NULL
    ) RETURN t_table_ds_def_events IS
        c_function_name CONSTANT obj_name := 'TF_DS_DEF_EVENTS';
        --
        l_dbg_msg debug_msg;
        l_ret_tbl t_table_ds_def_events;
    
    BEGIN
        l_dbg_msg := 'get dynamic screen section default events';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        SELECT t_rec_ds_def_events(id_ds_cmpt_mkt_rel => dsde.id_ds_cmpt_mkt_rel,
                                   id_def_event       => dsde.id_def_event,
                                   flg_event_type     => dsde.flg_event_type)
          BULK COLLECT
          INTO l_ret_tbl
          FROM ds_def_event dsde
         INNER JOIN TABLE(get_cmp_rel(i_prof, i_component_name, i_component_type, i_component_list, i_component_root)) dscm
            ON dsde.id_ds_cmpt_mkt_rel = dscm.id_ds_cmpt_mkt_rel;
    
        RETURN l_ret_tbl;
    END tf_ds_def_events;

    /**********************************************************************************************
    * Get ds_event id. This function is used in triage to create dynamic events to vital signs fields
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   professional, software and institution ids             
    * @param        i_component_name         Component internal name
    * @param        i_value                  Event value
    *
    * @return       Event id
    *
    * @author       Alexandre Santos
    * @version      2.6.1
    * @since        31-01-2013
    **********************************************************************************************/
    FUNCTION get_ds_event_id
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_child%TYPE,
        i_value          IN ds_event.value%TYPE
    ) RETURN ds_event.id_ds_event%TYPE IS
        c_function_name CONSTANT obj_name := 'GET_DS_EVENT_ID';
        --
        l_dbg_msg debug_msg;
        --
        l_cfg_vars rec_cfg_vars;
        l_ret      ds_event.id_ds_event%TYPE;
    BEGIN
        l_dbg_msg := 'CALL GET_CFG_VARS';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_cfg_vars := get_cfg_vars(i_prof           => i_prof,
                                   i_component_name => i_component_name,
                                   i_component_type => pk_dynamic_screen.c_leaf_component);
    
        SELECT de.id_ds_event
          INTO l_ret
          FROM ds_cmpt_mkt_rel dcmr
          JOIN ds_event de
            ON de.id_ds_cmpt_mkt_rel = dcmr.id_ds_cmpt_mkt_rel
         WHERE dcmr.internal_name_child = i_component_name
           AND dcmr.id_market = l_cfg_vars.id_market
           AND dcmr.id_software = l_cfg_vars.id_software
           AND de.value = i_value;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_ds_event_id;
    --
    /**********************************************************************************************
    * Calculate the correct component rank
    *
    * @param        i_tbl_section         Section table
    * @param        i_ds_cmpt_mkt_rel     PK column
    *
    * @return       Rank of the request PK
    *
    * @author       Alexandre Santos
    * @version      2.6.3
    * @since        05-08-2013
    **********************************************************************************************/
    FUNCTION get_section_rank
    (
        i_tbl_section     IN t_table_ds_sections,
        i_ds_cmpt_mkt_rel IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE
    ) RETURN ds_cmpt_mkt_rel.rank%TYPE IS
        l_rank ds_cmpt_mkt_rel.rank%TYPE;
    BEGIN
        SELECT (CASE
                    WHEN chld.flg_component_type = pk_dynamic_screen.c_node_component
                         AND prt.flg_component_type IS NULL
                         AND grnd_prt.flg_component_type IS NULL THEN
                     chld.rank
                    WHEN chld.flg_component_type = pk_dynamic_screen.c_node_component
                         AND prt.flg_component_type = pk_dynamic_screen.c_node_component
                         AND grnd_prt.flg_component_type IS NULL THEN
                     chld.rank * 10
                    WHEN chld.flg_component_type = pk_dynamic_screen.c_leaf_component
                         AND prt.flg_component_type = pk_dynamic_screen.c_leaf_component
                         AND grnd_prt.flg_component_type = pk_dynamic_screen.c_node_component THEN
                     prt.rank * 10 + chld.rank
                    WHEN chld.flg_component_type = pk_dynamic_screen.c_leaf_component
                         AND prt.flg_component_type = pk_dynamic_screen.c_node_component
                         AND grnd_prt.flg_component_type IS NULL THEN
                     chld.rank * 10
                    WHEN chld.flg_component_type = pk_dynamic_screen.c_leaf_component
                         AND prt.flg_component_type = pk_dynamic_screen.c_node_component
                         AND grnd_prt.flg_component_type = pk_dynamic_screen.c_node_component THEN
                     prt.rank * 10 + chld.rank
                    WHEN chld.flg_component_type = pk_dynamic_screen.c_node_component
                         AND prt.flg_component_type = pk_dynamic_screen.c_leaf_component
                         AND grnd_prt.flg_component_type = pk_dynamic_screen.c_node_component THEN
                     prt.rank * 10 + chld.rank * 10
                    WHEN chld.flg_component_type = pk_dynamic_screen.c_leaf_component
                         AND prt.flg_component_type = pk_dynamic_screen.c_node_component
                         AND grnd_prt.flg_component_type = pk_dynamic_screen.c_leaf_component
                         AND grt_grnd_prt.flg_component_type = pk_dynamic_screen.c_node_component THEN
                     grnd_prt.rank * 10 + prt.rank * 10 + chld.rank
                    ELSE
                     1
                END) rank
          INTO l_rank
          FROM TABLE(i_tbl_section) chld
          LEFT JOIN TABLE(i_tbl_section) prt
            ON prt.id_ds_component = chld.id_ds_component_parent
          LEFT JOIN TABLE(i_tbl_section) grnd_prt
            ON grnd_prt.id_ds_component = prt.id_ds_component_parent
          LEFT JOIN TABLE(i_tbl_section) grt_grnd_prt
            ON grt_grnd_prt.id_ds_component = grnd_prt.id_ds_component_parent
         WHERE chld.id_ds_cmpt_mkt_rel = i_ds_cmpt_mkt_rel;
    
        RETURN l_rank;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_section_rank;

    FUNCTION check_unit_measure_fields
    (
        i_unit_measure         IN NUMBER,
        i_unit_measure_subtype IN NUMBER
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(0010 CHAR);
    
    BEGIN
    
        CASE
            WHEN i_unit_measure IS NULL
                 AND i_unit_measure_subtype IS NULL THEN
                l_return := pk_alert_constant.g_no;
            WHEN i_unit_measure IS NOT NULL THEN
                l_return := pk_alert_constant.g_yes;
            WHEN i_unit_measure_subtype IS NOT NULL THEN
                l_return := pk_alert_constant.g_yes;
            ELSE
                l_return := pk_alert_constant.g_no;
        END CASE;
    
        RETURN l_return;
    
    END check_unit_measure_fields;

    FUNCTION get_dyn_umea
    (
        i_lang                 IN NUMBER,
        i_prof                 IN profissional,
        i_ds_component         IN NUMBER,
        i_unit_measure         IN NUMBER,
        i_unit_measure_subtype IN NUMBER
    ) RETURN t_tbl_dyn_umea IS
        tbl_return             t_tbl_dyn_umea;
        l_unit_measure         NUMBER := i_unit_measure;
        l_unit_measure_subtype NUMBER := i_unit_measure_subtype;
    
    BEGIN
    
        IF l_unit_measure IS NULL
           AND l_unit_measure_subtype IS NULL
        THEN
        
            SELECT id_unit_measure, id_unit_measure_subtype
              INTO l_unit_measure, l_unit_measure_subtype
              FROM ds_component d
             WHERE d.id_ds_component = i_ds_component;
        
        END IF;
    
        IF l_unit_measure_subtype IS NOT NULL
        THEN
        
            tbl_return := pk_unit_measure.get_dyn_only_umea_type(i_lang                 => i_lang,
                                                                 i_prof                 => i_prof,
                                                                 i_ds_component         => i_ds_component,
                                                                 i_unit_measure_subtype => l_unit_measure_subtype);
        
        ELSE
        
            tbl_return := pk_unit_measure.get_dyn_only_umea(i_lang         => i_lang,
                                                            i_ds_component => i_ds_component,
                                                            i_unit_measure => l_unit_measure);
        
        END IF;
    
        RETURN tbl_return;
    
    END get_dyn_umea;

    /**********************************************************************************************
    * Get a dynamic root node from first section
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   professional, software and institution ids
    * @param        i_component_name         Component internal name
    * @param        i_component_type         Component type (defaults to node component type)
    *
    * @return       array : first pos is component name, second pos is flg_component_type
    *
    * @author       Carlos Ferreira
    * @version      2.7.1
    * @since        24-08-2017
    **********************************************************************************************/
    FUNCTION get_ds_section_root
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_component_name IN VARCHAR2,
        i_component_type IN VARCHAR2 DEFAULT c_node_component
    ) RETURN table_varchar IS
        l_cfg rec_cfg_vars;
        --k_pos_name     CONSTANT NUMBER := 1;
        --k_pos_flg_type CONSTANT NUMBER := 2;
        --k_first_row CONSTANT NUMBER := 1;
        tbl_name     table_varchar;
        tbl_flg_type table_varchar;
        tbl_return   table_varchar := table_varchar(i_component_name, i_component_type);
    BEGIN
    
        l_cfg := get_cfg_vars(i_prof           => i_prof,
                              i_component_name => i_component_name,
                              i_component_type => i_component_type);
    
        --***********************
        --***********************
        -- sql gets hierarchy until initial node ( root )
        SELECT internal_name_child, flg_component_type_child
          BULK COLLECT
          INTO tbl_name, tbl_flg_type
          FROM (SELECT xsql.*
                  FROM (SELECT LEVEL nivel, x.*
                          FROM (SELECT *
                                  FROM ds_cmpt_mkt_rel xx
                                 WHERE xx.id_market = l_cfg.id_market
                                   AND xx.id_software = l_cfg.id_software) x
                        CONNECT BY PRIOR x.id_ds_component_parent = x.id_ds_component_child
                         START WITH x.internal_name_child = i_component_name
                         ORDER SIBLINGS BY rank) xsql
                 ORDER BY nivel DESC) xfinal;
        -- ********************************
        IF tbl_name.count > 0
        THEN
            tbl_return(k_pos_name) := tbl_name(1);
            tbl_return(k_pos_flg_type) := tbl_flg_type(1);
        END IF;
    
        RETURN tbl_return;
    
    END get_ds_section_root;

    -- **********************************
    FUNCTION process_mx_partial_dt
    (
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_dt_exists IN VARCHAR2,
        i_value     IN death_registry.dt_death%TYPE,
        i_dt_format IN VARCHAR2,
        i_type      IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
        k_ignore  CONSTANT VARCHAR2(0200 CHAR) := '88/88/8888';
        k_partial CONSTANT VARCHAR2(0200 CHAR) := '99';
        l_return VARCHAR2(0200 CHAR);
        k_hour_ignore  CONSTANT VARCHAR2(0200 CHAR) := '88:88';
        k_hour_partial CONSTANT VARCHAR2(0200 CHAR) := '99:99';
    BEGIN
    
        IF i_dt_exists = 'Y'
        THEN
            IF i_type IS NULL
            THEN
                CASE i_dt_format
                    WHEN k_dt_output_02 THEN
                        /*
                                l_return := pk_date_utils.date_chr_short_read_tsz(i_lang => i_lang,
                                                                                  i_date => i_value,
                                                                                  i_prof => i_prof);
                        */
                        l_return := pk_date_utils.to_char_insttimezone(i_lang      => i_lang,
                                                                       i_prof      => i_prof,
                                                                       i_timestamp => i_value,
                                                                       i_mask      => 'DD/MM/YYYY');
                        -- END IF;
                
                    WHEN k_dp_mode_mmyyyy THEN
                        l_return := pk_date_utils.to_char_insttimezone(i_lang      => i_lang,
                                                                       i_prof      => i_prof,
                                                                       i_timestamp => i_value,
                                                                       i_mask      => 'MM/YYYY');
                        l_return := k_partial || '/' || l_return;
                    WHEN k_dp_mode_yyyy THEN
                        l_return := pk_date_utils.to_char_insttimezone(i_lang      => i_lang,
                                                                       i_prof      => i_prof,
                                                                       i_timestamp => i_value,
                                                                       i_mask      => 'YYYY');
                        l_return := k_partial || '/' || k_partial || '/' || l_return;
                    ELSE
                        --l_return := pk_date_utils.dt_chr_tsz(i_lang, i_value, i_prof.institution, i_prof.software);
                        l_return := pk_date_utils.to_char_insttimezone(i_lang      => i_lang,
                                                                       i_prof      => i_prof,
                                                                       i_timestamp => i_value,
                                                                       i_mask      => 'DD/MM/YYYY');
                END CASE;
            ELSE
                CASE i_dt_format
                    WHEN k_dp_mode_full THEN
                        l_return := pk_date_utils.dt_chr_hour_tsz(i_lang, i_value, i_prof.institution, 0);
                    ELSE
                        l_return := k_hour_partial;
                    
                END CASE;
            END IF;
        ELSE
            IF i_dt_exists IS NULL
            THEN
                IF i_type IS NULL
                THEN
                    --l_return := pk_date_utils.dt_chr_tsz(i_lang, i_value, i_prof.institution, i_prof.software);
                    l_return := pk_date_utils.to_char_insttimezone(i_lang      => i_lang,
                                                                   i_prof      => i_prof,
                                                                   i_timestamp => i_value,
                                                                   i_mask      => 'DD/MM/YYYY');
                ELSE
                    l_return := pk_date_utils.dt_chr_hour_tsz(i_lang, i_value, i_prof.institution, 0);
                END IF;
            ELSE
                IF i_type IS NULL
                THEN
                    l_return := k_ignore;
                ELSE
                    l_return := k_hour_ignore;
                END IF;
            END IF;
        END IF;
    
        RETURN l_return;
    
    END process_mx_partial_dt;

    -- ***************************************************************
    -- auxiliary function
    -- ***************************************************************
    FUNCTION chk_age_value_null
    (
        i_age_min_value IN NUMBER,
        i_age_max_value IN NUMBER,
        i_gender1       IN VARCHAR2,
        i_gender2       IN VARCHAR2,
        i_pat_gender    IN VARCHAR2
    ) RETURN BOOLEAN IS
        l_bool BOOLEAN := TRUE;
        k_unknown CONSTANT VARCHAR2(0050 CHAR) := 'UNKNOWN';
    BEGIN
    
        l_bool := l_bool AND i_age_min_value IS NULL;
        l_bool := l_bool AND i_age_max_value IS NULL;
        l_bool := l_bool AND i_gender1 IS NULL;
        l_bool := l_bool AND nvl(nvl(i_gender2, i_pat_gender), k_unknown) = nvl(i_pat_gender, k_unknown);
    
        RETURN l_bool;
    
    END chk_age_value_null;

    -- ***************************************************************
    FUNCTION chk_age_value_n_null
    (
        i_age_min_value IN NUMBER,
        i_age_max_value IN NUMBER,
        i_gender1       IN VARCHAR2,
        i_gender2       IN VARCHAR2,
        i_pat_gender    IN VARCHAR2
    ) RETURN BOOLEAN IS
        l_bool BOOLEAN := TRUE;
        k_unknown CONSTANT VARCHAR2(0050 CHAR) := 'UNKNOWN';
    BEGIN
    
        l_bool := l_bool AND (i_age_min_value IS NOT NULL);
        l_bool := l_bool OR (i_age_max_value IS NOT NULL);
        l_bool := l_bool OR (i_gender1 IS NOT NULL);
        l_bool := l_bool AND (nvl(nvl(i_gender2, i_pat_gender), k_unknown) = nvl(i_pat_gender, k_unknown));
    
        RETURN l_bool;
    
    END chk_age_value_n_null;

    -- **********************************************************************
    --check_age_value( i_age_min_value => , i_age_max_value => , i_gender1 => , i_gender2 => , i_pat_gender => )
    FUNCTION check_age_value
    (
        i_age_min_value IN NUMBER,
        i_age_max_value IN NUMBER,
        i_gender1       IN VARCHAR2,
        i_gender2       IN VARCHAR2,
        i_pat_gender    IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_bool   BOOLEAN;
        l_return VARCHAR2(0010 CHAR) := k_no;
    BEGIN
    
        l_bool := chk_age_value_null(i_age_min_value => i_age_min_value,
                                     i_age_max_value => i_age_max_value,
                                     i_gender1       => i_gender1,
                                     i_gender2       => i_gender2,
                                     i_pat_gender    => i_pat_gender);
    
        IF l_bool
        THEN
            l_return := 'DSCP';
        ELSE
        
            l_bool := chk_age_value_n_null(i_age_min_value => i_age_min_value,
                                           i_age_max_value => i_age_max_value,
                                           i_gender1       => i_gender1,
                                           i_gender2       => i_gender1,
                                           i_pat_gender    => i_pat_gender);
        
            IF l_bool
            THEN
                l_return := 'DSCMP';
            ELSE
                l_return := 'NONE';
            END IF;
        
        END IF;
    
        RETURN l_return;
    
    END check_age_value;

    FUNCTION tf_ds_sections
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT c_node_component,
        i_component_list IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_patient        IN patient.id_patient%TYPE,
        i_component_root IN ds_cmpt_mkt_rel.internal_name_parent%TYPE DEFAULT NULL,
        i_filter         IN VARCHAR2 DEFAULT NULL
    ) RETURN t_table_ds_sections IS
        c_function_name CONSTANT obj_name := 'TF_DS_SECTIONS';
        --
        l_dbg_msg        debug_msg;
        l_ret_tbl        t_table_ds_sections;
        l_patient_age    patient.age%TYPE;
        l_patient_gender patient.gender%TYPE;
        l_patient_age_days       NUMBER;
        l_patient_age_days_years NUMBER;
        k_decimals constant number := 6;
    BEGIN
    
        -- ***********
        BEGIN
            IF i_patient IS NOT NULL
            THEN
                SELECT p.gender,
                       pk_patient.get_pat_age(i_lang     => i_lang,
                                              i_dt_birth => p.dt_birth,
                                              i_age      => p.age,
                                              i_patient  => i_patient),
                       pk_patient.get_pat_age(i_lang       => i_lang,
                                              i_dt_birth   => p.dt_birth,
                                              i_age        => age,
                                              i_age_format => 'DAYS')
                  INTO l_patient_gender, l_patient_age, l_patient_age_days
                  FROM patient p
                 WHERE p.id_patient = i_patient;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                l_patient_gender := NULL;
                l_patient_age    := NULL;
        END;
        /*       l_patient_age_days       := pk_patient.get_pat_age_num(i_lang    => i_lang,
        i_prof    => i_prof,
        i_patient => i_patient,
        i_type    => 'D');*/
        l_patient_age_days_years := pk_unit_measure.get_unit_mea_conversion(i_value         => l_patient_age_days,
                                                                            i_unit_meas     => g_id_unit_measure_day,
                                                                            i_unit_meas_def => g_id_unit_measure_year,
                                                                            i_decimals => k_decimals);
        -- **********
        l_dbg_msg := 'get dynamic screen section structure';
        pk_alertlog.log_debug(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        SELECT t_rec_ds_sections(id_ds_cmpt_mkt_rel     => a.id_ds_cmpt_mkt_rel,
                                 id_ds_component_parent => a.id_ds_component_parent,
                                 id_ds_component        => a.id_ds_component,
                                 component_desc         => a.component_desc,
                                 internal_name          => a.internal_name,
                                 flg_component_type     => a.flg_component_type,
                                 flg_data_type          => a.flg_data_type,
                                 slg_internal_name      => a.slg_internal_name,
                                 addit_info_xml_value   => NULL,
                                 rank                   => a.rank,
                                 max_len                => a.max_len,
                                 min_value              => a.min_value,
                                 max_value              => a.max_value,
                                 gender                 => a.gender,
                                 age_min_value          => a.age_min_value,
                                 age_min_unit_measure   => a.age_min_unit_measure,
                                 age_max_value          => a.age_max_value,
                                 age_max_unit_measure   => a.age_max_unit_measure,
                                 component_values       => NULL)
          BULK COLLECT
          INTO l_ret_tbl
          FROM (SELECT xsql3.*, first_value(rn1) over(ORDER BY id_ds_component_parent NULLS FIRST) rns,
           decode(i_filter,pk_alert_constant.g_yes,decode(id_ds_component_parent, null, 0, rn), rn) rn_alt
                  FROM ((SELECT xsql2.*
                           FROM (SELECT row_number() over(PARTITION BY id_ds_component_parent, internal_name ORDER BY id_ds_component_parent NULLS FIRST, rn) rn1,
                                        xsql1.id_ds_cmpt_mkt_rel,
                               xsql1.id_ds_component_parent,
                               xsql1.id_ds_component,
                               xsql1.component_desc,
                               xsql1.internal_name,
                               xsql1.flg_component_type,
                               xsql1.flg_data_type,
                               xsql1.slg_internal_name,
                               xsql1.rank,
                               xsql1.max_len,
                               xsql1.min_value,
                               xsql1.max_value,
                               decode(xsql1.chk_value, k_value0, xsql1.gender0, k_value1, xsql1.gender1) gender,
                                        decode(xsql1.chk_value,
                                               k_value0,
                                               xsql1.age_min_value0,
                                               k_value1,
                                               xsql1.age_min_value1) age_min_value,
                               decode(xsql1.chk_value,
                                      k_value0,
                                      xsql1.age_min_unit_measure0,
                                      k_value1,
                                      xsql1.age_min_unit_measure1) age_min_unit_measure,
                                        decode(xsql1.chk_value,
                                               k_value0,
                                               xsql1.age_max_value0,
                                               k_value1,
                                               xsql1.age_max_value1) age_max_value,
                               decode(xsql1.chk_value,
                                      k_value0,
                                      xsql1.age_max_unit_measure0,
                                      k_value1,
                                      xsql1.age_max_unit_measure1) age_max_unit_measure,
                               xsql1.rn
                          FROM (SELECT dscm.id_ds_cmpt_mkt_rel,
                                       dscm.id_ds_component_parent,
                                       dscp.id_ds_component,
                                       pk_translation.get_translation(i_lang, dscp.code_ds_component) AS component_desc,
                                       dscp.internal_name,
                                       dscp.flg_component_type,
                                       dscp.flg_data_type,
                                       dscp.slg_internal_name,
                                       dscm.rank,
                                       nvl(dscm.max_len, dscp.max_len) max_len,
                                       nvl(dscm.min_value, dscp.min_value) min_value,
                                       nvl(dscm.max_value, dscp.max_value) max_value,
                                       dscm.gender gender1,
                                       dscp.gender gender0,
                                       dscm.age_min_value age_min_value1,
                                       dscm.age_min_unit_measure age_min_unit_measure1,
                                       dscm.age_max_value age_max_value1,
                                       dscm.age_max_unit_measure age_max_unit_measure1,
                                       dscp.age_min_value age_min_value0,
                                       dscp.age_min_unit_measure age_min_unit_measure0,
                                       dscp.age_max_value age_max_value0,
                                       dscp.age_max_unit_measure age_max_unit_measure0,
                                       pk_dynamic_screen.check_age_value(i_age_min_value => dscm.age_min_value,
                                                                         i_age_max_value => dscm.age_max_value,
                                                                         i_gender1       => dscm.gender,
                                                                         i_gender2       => dscp.gender,
                                                                         i_pat_gender    => l_patient_gender) chk_value,
                                       dscm.rn
                                         
                                  FROM ds_component dscp
                                  JOIN (SELECT /*+ OPT_ESTIMATE(TABLE cmp_rel ROWS=1) */
                                        cmp_rel.*
                                         FROM TABLE(pk_dynamic_screen.get_cmp_rel(i_prof,
                                                                                  i_component_name,
                                                                                  i_component_type,
                                                                                  i_component_list,
                                                                                  i_component_root)) cmp_rel) dscm
                                    ON dscp.id_ds_component = dscm.id_ds_component_child) xsql1
                         WHERE xsql1.chk_value != 'NONE') xsql2
                 WHERE pk_dynamic_screen.check_age_limits(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                                   i_pat_age    => decode(xsql2.age_min_unit_measure,
                                                                                          g_id_unit_measure_year,
                                                                                          l_patient_age,
                                                                                          l_patient_age_days_years),
                                                          i_age_limit  => decode(xsql2.age_min_unit_measure,
                                                                                 g_id_unit_measure_year,
                                                                                 xsql2.age_min_value,
                                                                                 pk_unit_measure.get_unit_mea_conversion(i_value         => xsql2.age_min_value,
                                                                                                                         i_unit_meas     => xsql2.age_min_unit_measure,
                                                                                                                         i_unit_meas_def => g_id_unit_measure_year,
                                                                                                                         i_decimals => k_decimals)),
                                                          i_limit_type => pk_edis_triage.g_age_min) = k_yes
                   AND pk_dynamic_screen.check_age_limits(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                                   i_pat_age    => decode(xsql2.age_max_unit_measure,
                                                                                          g_id_unit_measure_year,
                                                                                          l_patient_age,
                                                                                          l_patient_age_days_years),
                                                          i_age_limit  => decode(xsql2.age_max_unit_measure,
                                                                                 g_id_unit_measure_year,
                                                                                 xsql2.age_max_value,
                                                                                 pk_unit_measure.get_unit_mea_conversion(i_value         => xsql2.age_max_value,
                                                                                                                         i_unit_meas     => xsql2.age_max_unit_measure,
                                                                                                                         i_unit_meas_def => g_id_unit_measure_year,
                                                                                                                         i_decimals => k_decimals)),
                                                                   i_limit_type => pk_edis_triage.g_age_max) = k_yes
                         
                         ) xsql3)) a
         WHERE (rn1 = rns AND i_filter = pk_alert_constant.g_yes)
            OR i_filter IS NULL
         ORDER BY rn_alt, rank;
    
        RETURN l_ret_tbl;
    
    END tf_ds_sections;

    FUNCTION get_id_epis_diag
    (
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_data_val       IN table_table_varchar
    ) RETURN VARCHAR2 IS
    
        c_function_name CONSTANT obj_name := 'get_ID_EPIS_diag';
        l_dbg_msg debug_msg;
        l_result  VARCHAR2(1000 CHAR);
    BEGIN
        l_dbg_msg := 'search for component value';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        FOR idx IN i_data_val.first() .. i_data_val.last()
        LOOP
            IF i_component_name = i_data_val(idx) (c_name_idx)
            THEN
                l_result := i_data_val(idx) (c_desc_idx);
            END IF;
        END LOOP;
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        RETURN l_result;
    
    END get_id_epis_diag;

    FUNCTION add_values_all
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_data_val IN table_table_varchar,
        i_name     IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_value    IN NUMBER,
        i_text     IN VARCHAR2,
        i_hist     IN NUMBER DEFAULT NULL
    ) RETURN table_table_varchar IS
        l_return table_table_varchar := table_table_varchar();
        l_desc   VARCHAR2(4000);
    BEGIN
    
        IF i_text IS NOT NULL
        THEN
            l_return := add_values(i_data_val  => i_data_val,
                                   i_name      => i_name,
                                   i_desc      => i_text,
                                   i_value     => i_value,
                                   i_alt_value => NULL,
                                   i_hist      => i_hist);
        
        END IF;
    
        RETURN l_return;
    
    END add_values_all;

    --
    -- cmf
    FUNCTION get_ds_rep_section
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_section_name   IN VARCHAR2,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT c_node_component,
        i_component_list IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_patient        IN patient.id_patient%TYPE DEFAULT NULL,
        o_section        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_DS_SECTION';
        l_dbg_msg debug_msg;
        l_count   NUMBER;
    BEGIN
        l_dbg_msg := 'get dynamic screen section structure';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
    
        SELECT COUNT(*)
          INTO l_count
          FROM ds_rep_cmpt
         WHERE section_name = i_section_name;
    
        IF l_count = 0
        THEN
            OPEN o_section FOR
                SELECT a.id_ds_cmpt_mkt_rel,
                       a.id_ds_component_parent,
                       a.id_ds_component,
                       a.component_desc,
                       a.internal_name,
                       a.flg_component_type,
                       a.flg_data_type,
                       a.slg_internal_name,
                       a.addit_info_xml_value,
                       a.rank,
                       a.max_len,
                       a.min_value,
                       a.max_value
                  FROM TABLE(pk_dynamic_screen.tf_ds_sections(i_lang           => i_lang,
                                                              i_prof           => i_prof,
                                                              i_component_name => i_component_name,
                                                              i_component_type => i_component_type,
                                                              i_component_list => i_component_list,
                                                              i_patient        => i_patient)) a;
        ELSE
            OPEN o_section FOR
                SELECT a.id_ds_cmpt_mkt_rel,
                       a.id_ds_component_parent,
                       a.id_ds_component,
                       --coalesce(pk_translation.get_translation( i_lang, drc.code_ds_rep_cmpt), a.component_desc) component_desc,
                       pk_dynamic_screen.get_rep_component_desc(i_lang               => i_lang,
                                                                i_section_name       => i_section_name,
                                                                i_id_ds_cmpt_kmt_rel => a.id_ds_cmpt_mkt_rel) component_desc,
                       a.internal_name,
                       a.flg_component_type,
                       a.flg_data_type,
                       a.slg_internal_name,
                       a.addit_info_xml_value,
                       a.rank,
                       a.max_len,
                       a.min_value,
                       a.max_value
                  FROM TABLE(pk_dynamic_screen.tf_ds_sections(i_lang           => i_lang,
                                                              i_prof           => i_prof,
                                                              i_component_name => i_component_name,
                                                              i_component_type => i_component_type,
                                                              i_component_list => i_component_list,
                                                              i_patient        => i_patient)) a
                  JOIN ds_rep_cmpt drc
                    ON drc.id_ds_cmpt_mkt_rel = a.id_ds_cmpt_mkt_rel
                 WHERE drc.section_name = i_section_name
                 ORDER BY coalesce(drc.rank, 0), a.rank;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(i_cursor => o_section);
            RETURN FALSE;
    END get_ds_rep_section;

    ---***************
    FUNCTION get_ds_rep_cmpt_code
    (
        i_section_name       IN VARCHAR2,
        i_id_ds_cmpt_kmt_rel IN NUMBER
    ) RETURN VARCHAR2 IS
        l_bool   BOOLEAN;
        tbl_code table_varchar;
        l_return VARCHAR2(4000);
    BEGIN
    
        l_bool := i_id_ds_cmpt_kmt_rel IS NOT NULL AND i_section_name IS NOT NULL;
    
        IF l_bool
        THEN
        
            SELECT code_ds_rep_cmpt
              BULK COLLECT
              INTO tbl_code
              FROM ds_rep_cmpt d
             WHERE d.section_name = i_section_name
               AND d.id_ds_cmpt_mkt_rel = i_id_ds_cmpt_kmt_rel;
        
            IF tbl_code.count > 0
            THEN
                l_return := tbl_code(1);
            END IF;
        
        END IF;
    
        RETURN l_return;
    
    END get_ds_rep_cmpt_code;

    -- ****************************************************
    FUNCTION get_component_desc
    (
        i_lang         IN NUMBER,
        i_ds_component IN NUMBER
    ) RETURN VARCHAR2 IS
        l_text   VARCHAR2(4000);
        tbl_text table_varchar;
    BEGIN
    
        SELECT pk_translation.get_translation(i_lang, code_ds_component) xdesc
          BULK COLLECT
          INTO tbl_text
          FROM ds_component d
         WHERE d.id_ds_component = i_ds_component;
    
        IF tbl_text.count > 0
        THEN
            l_text := tbl_text(1);
        END IF;
    
        RETURN l_text;
    
    END get_component_desc;

    FUNCTION get_rep_component_desc
    (
        i_lang               IN NUMBER,
        i_section_name       IN VARCHAR2,
        i_id_ds_cmpt_kmt_rel IN NUMBER
    ) RETURN VARCHAR2 IS
        c_function_name CONSTANT obj_name := 'get_rep_component_desc';
        l_code VARCHAR2(0200 CHAR);
        l_desc VARCHAR2(4000);
        tbl_id table_number;
    BEGIN
    
        l_desc := NULL;
        l_code := get_ds_rep_cmpt_code(i_section_name, i_id_ds_cmpt_kmt_rel);
    
        IF l_code IS NOT NULL
        THEN
        
            l_desc := pk_translation.get_translation(i_lang, l_code);
        
            IF l_desc IS NULL
            THEN
            
                SELECT dc.id_ds_component_child
                  BULK COLLECT
                  INTO tbl_id
                  FROM ds_cmpt_mkt_rel dc
                 WHERE dc.id_ds_cmpt_mkt_rel = i_id_ds_cmpt_kmt_rel;
            
                IF tbl_id.count > 0
                THEN
                
                    l_desc := get_component_desc(i_lang => i_lang, i_ds_component => tbl_id(1));
                END IF;
            
            END IF;
        
        END IF;
    
        RETURN l_desc;
    
    END get_rep_component_desc;

--
-- INITIALIZATION SECTION
-- 
BEGIN
    -- Initializes log context
    pk_alertlog.log_init(object_name => c_package_name);
END pk_dynamic_screen;
/
