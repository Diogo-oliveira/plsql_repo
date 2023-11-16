/*-- Last Change Revision: $Rev: 2026855 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:12 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_cdr_bo_core IS

    g_error        VARCHAR2(1000 CHAR);
    g_owner        VARCHAR2(30 CHAR);
    g_package      VARCHAR2(30 CHAR);
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    g_exception EXCEPTION;
    g_fault     EXCEPTION;

    --Types
    SUBTYPE varchar_1 IS VARCHAR2(1 CHAR);

    TYPE rec_cdr_condition IS RECORD(
        id_cdr_def_cond    cdr_def_cond.id_cdr_def_cond%TYPE,
        cdr_condition      VARCHAR2(200),
        cdr_condition_name VARCHAR2(4000),
        rank               cdr_def_cond.rank%TYPE);

    TYPE t_rec_cdr_condition IS TABLE OF rec_cdr_condition;

    TYPE rec_rule_parameter IS RECORD(
        id_cdr_parameter cdr_parameter.id_cdr_parameter%TYPE,
        id_cdr_condition cdr_condition.id_cdr_condition%TYPE,
        id_cdr_concept   cdr_concept.id_cdr_concept%TYPE,
        message          pk_translation.t_desc_translation,
        rank             cdr_parameter.rank%TYPE);

    TYPE t_rec_rule_parameter IS TABLE OF rec_rule_parameter;

    TYPE rec_cdr_ins_param IS RECORD(
        id_cdr_inst_param cdr_inst_param.id_cdr_inst_param%TYPE,
        id_cdr_concept    cdr_concept.id_cdr_concept%TYPE,
        id_element        cdr_inst_param.id_element%TYPE,
        flg_identifiable  cdr_concept.flg_identifiable%TYPE,
        flg_valuable      cdr_concept.flg_valuable%TYPE,
        val_min           cdr_inst_param.val_min%TYPE,
        val_max           cdr_inst_param.val_max%TYPE,
        id_unit_measure   cdr_inst_param.id_domain_umea%TYPE);

    TYPE t_rec_cdr_ins_param IS TABLE OF rec_cdr_ins_param;

    TYPE rec_cdr_ins_config IS RECORD(
        id_cdr_inst_par_action cdr_inst_config.id_cdr_inst_par_action%TYPE,
        id_software            cdr_inst_config.id_software%TYPE,
        id_profile_template    cdr_inst_config.id_profile_template%TYPE,
        id_dep_clin_serv       cdr_inst_config.id_dep_clin_serv%TYPE,
        id_professional        cdr_inst_config.id_professional%TYPE);

    TYPE t_rec_cdr_ins_config IS TABLE OF rec_cdr_ins_config;

    g_code_definition_name        cdr_definition.code_name%TYPE := 'CDR_DEFINITION.CODE_NAME.';
    g_code_definition_description cdr_definition.code_description%TYPE := 'CDR_DEFINITION.CODE_DESCRIPTION.';

    -- I
    g_idx_condition        CONSTANT PLS_INTEGER := 1;
    g_idx_flg_condition    CONSTANT PLS_INTEGER := 2;
    g_idx_flg_deny         CONSTANT PLS_INTEGER := 3;
    g_idx_condition_rank   CONSTANT PLS_INTEGER := 4;
    g_idx_concept          CONSTANT PLS_INTEGER := 5;
    g_idx_concept_rank     CONSTANT PLS_INTEGER := 6;
    g_idx_action           CONSTANT PLS_INTEGER := 7;
    g_idx_action_value     CONSTANT PLS_INTEGER := 8;
    g_idx_action_unit      CONSTANT PLS_INTEGER := 9;
    g_idx_action_flg_first CONSTANT PLS_INTEGER := 10;
    g_idx_action_message   CONSTANT PLS_INTEGER := 11;

    /********************************************************************************
    |                            Generic - Helper functions                         |
    ********************************************************************************/

    /**
    * Get a default valued table_number.
    * If the table_number has elements, it returns itself.
    * Otherwise, it creates a new table_number with the default value.
    *
    * @param i_tn           table_number
    * @param i_def          default value
    *
    * @return               default valued table_number
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2011/10/25
    */
    FUNCTION get_default_tn
    (
        i_tn  IN table_number,
        i_def IN NUMBER
    ) RETURN table_number IS
        l_ret table_number;
    BEGIN
        IF i_tn IS NULL
           OR i_tn.count < 1
        THEN
            l_ret := table_number(i_def);
        ELSE
            l_ret := i_tn;
        END IF;
    
        RETURN l_ret;
    END get_default_tn;

    /**
    * Get number of definitions of a given type.
    *
    * @param i_prof         logged professional structure
    * @param i_type         rule type identifier
    *
    * @return               number of definitions of the given type
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2011/10/27
    */
    FUNCTION get_def_count
    (
        i_prof IN profissional,
        i_type IN cdr_type.id_cdr_type%TYPE
    ) RETURN PLS_INTEGER IS
        l_ret PLS_INTEGER;
    BEGIN
        IF i_type IS NULL
        THEN
            l_ret := 0;
        ELSE
            SELECT COUNT(*)
              INTO l_ret
              FROM cdr_definition cdrd
             WHERE cdrd.id_institution IN (0, i_prof.institution)
               AND cdrd.flg_status IN (pk_alert_constant.g_active, pk_cdr_constant.g_edited)
               AND cdrd.flg_available = pk_alert_constant.g_yes
               AND cdrd.id_cdr_type = i_type;
        END IF;
    
        RETURN l_ret;
    END get_def_count;

    /**********************************************************************************************
    * Get list of rule types.
    *
    * @param i_lang                   the id language
    * @param i_prof                   logged professional structure
    * @param o_list                   list of rule types
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/03/07
    **********************************************************************************************/
    FUNCTION get_list_type
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_LIST_TYPE';
    BEGIN
    
        pk_alertlog.log_debug('', g_package, l_func_name);
        --
        g_error := 'OPEN o_list';
        OPEN o_list FOR
            SELECT cdrt.id_cdr_type type_id,
                   pk_translation.get_translation(i_lang, cdrt.code_cdr_type) type_name,
                   cdrt.icon type_icon,
                   CASE
                        WHEN get_def_count(i_prof, cdrt.id_cdr_type) > 0 THEN
                         pk_alert_constant.g_yes
                        ELSE
                         pk_alert_constant.g_no
                    END type_has_child
              FROM cdr_type cdrt
             WHERE cdrt.flg_available = pk_alert_constant.g_yes
             ORDER BY type_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => l_func_name,
                                                     o_error    => o_error);
    END get_list_type;
    --

    /**********************************************************************************************
    * Returns the list of severity types available
    *
    * @param i_lang                   the id language
    * @param o_severity_type_list     list of severity types
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/03/07
    **********************************************************************************************/
    FUNCTION get_severity_type_list
    (
        i_lang               IN language.id_language%TYPE,
        o_severity_type_list OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        pk_alertlog.log_debug('', g_package, 'GET_SEVERITY_TYPE_LIST');
        --
        g_error := 'OPEN CURSOR o_severity_type_list';
        OPEN o_severity_type_list FOR
            SELECT cdrs.id_cdr_severity,
                   pk_translation.get_translation(i_lang, cdrs.code_cdr_severity) desc_severity,
                   cdrs.color
              FROM cdr_severity cdrs
             WHERE cdrs.flg_available = pk_alert_constant.g_yes
             ORDER BY cdrs.rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_severity_type_list);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_SEVERITY_TYPE_LIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_severity_type_list;

    /**********************************************************************************************
    * Returns the list of action types available
    *
    * @param i_lang                   the id language
    * @param o_action_type_list       list of action types
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/04/15
    **********************************************************************************************/
    FUNCTION get_action_type_list
    (
        i_lang             IN language.id_language%TYPE,
        o_action_type_list OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        pk_alertlog.log_debug('', g_package, 'GET_ACTION_TYPE_LIST');
        --
        g_error := 'OPEN CURSOR o_action_type_list';
        OPEN o_action_type_list FOR
            SELECT ca.id_cdr_action,
                   pk_translation.get_translation(i_lang, ca.code_cdr_action) desc_action,
                   ca.internal_name
              FROM cdr_action ca
             WHERE ca.flg_available = pk_alert_constant.g_yes
             ORDER BY ca.rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_action_type_list);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_ACTION_TYPE_LIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_action_type_list;

    FUNCTION check_definition_has_instances(i_id_cdr_definition IN cdr_definition.id_cdr_definition%TYPE) RETURN VARCHAR2 IS
        CURSOR c_instances IS
            SELECT decode(COUNT(1), 0, pk_alert_constant.g_no, pk_alert_constant.g_yes)
              FROM cdr_instance ci
             WHERE ci.id_cdr_definition = i_id_cdr_definition
               AND ci.flg_status = pk_alert_constant.g_active;
    
        l_has_instances VARCHAR2(1 CHAR);
    BEGIN
        OPEN c_instances;
        FETCH c_instances
            INTO l_has_instances;
        CLOSE c_instances;
        RETURN l_has_instances;
    END;
    --

    /********************************************************************************
    |                            Rules Creation                                     |
    ********************************************************************************/

    /**********************************************************************************************
    * Creates a new Rule definition
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_cdr_definition      ID CDR for update
    * @param i_name                   definition name
    * @param i_description            definition description
    * @param i_id_cdr_type            type of definition
    * @param i_severity               array with the selected severity
    * @param i_severity_def           severity id that is the default 
    * @param i_definition_data        array with all information that defines the rule
    * @param o_id_cdr_definition      ID of the new rule definition
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/06/08
    **********************************************************************************************/
    FUNCTION set_cdr_definition
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_definition IN cdr_definition.id_cdr_definition%TYPE,
        i_name              IN VARCHAR2,
        i_description       IN VARCHAR2,
        i_id_cdr_type       IN cdr_definition.id_cdr_type%TYPE,
        i_severity          IN table_number,
        i_severity_def      IN cdr_def_severity.id_cdr_severity%TYPE,
        i_definition_data   IN table_table_varchar,
        o_id_cdr_definition OUT cdr_definition.id_cdr_definition%TYPE,
        o_flg_show          OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_msg               OUT VARCHAR2,
        o_buttons           OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_cdr_definition     cdr_definition.id_cdr_definition%TYPE;
        l_flg_origin            cdr_definition.flg_origin%TYPE;
        l_definition_data       table_varchar;
        l_id_cdr_condition      cdr_def_cond.id_cdr_condition%TYPE;
        l_id_cdr_def_cond       cdr_def_cond.id_cdr_def_cond%TYPE;
        l_id_cdr_parameter      cdr_parameter.id_cdr_parameter%TYPE;
        l_id_cdr_concept        cdr_parameter.id_cdr_concept%TYPE;
        l_id_cdr_param_action   cdr_param_action.id_cdr_param_action%TYPE;
        l_id_cdr_def_severity   cdr_def_severity.id_cdr_def_severity%TYPE;
        l_rows_out              table_varchar;
        l_rows_out_def_cond     table_varchar;
        l_rows_out_parameter    table_varchar;
        l_rows_out_param_action table_varchar;
    
        CURSOR c_definition(i_definition IN cdr_definition.id_cdr_definition%TYPE) IS
            SELECT cdrd.flg_origin
              FROM cdr_definition cdrd
             WHERE cdrd.id_cdr_definition = i_definition;
    BEGIN
    
        pk_alertlog.log_debug('PARAMS[ i_id_cdr_definition:' || i_id_cdr_definition || ' i_name:' || i_name ||
                              'i_description:' || i_description || ' i_id_cdr_type:' || i_id_cdr_type || ' ]',
                              g_package,
                              'CREATE_RULE_DEFINITION');
    
        IF i_id_cdr_definition IS NULL
        THEN
        
            l_id_cdr_definition := ts_cdr_definition.next_key;
        
            ts_cdr_definition.ins(id_cdr_definition_in => l_id_cdr_definition,
                                  id_cdr_type_in       => i_id_cdr_type,
                                  flg_status_in        => pk_alert_constant.g_active,
                                  flg_origin_in        => pk_cdr_constant.g_origin_local,
                                  id_institution_in    => i_prof.institution,
                                  id_prof_create_in    => i_prof.id,
                                  rows_out             => l_rows_out);
        
            g_error := 'INSERT TRANSLATION';
            pk_translation.insert_into_translation(i_lang       => i_lang,
                                                   i_code_trans => g_code_definition_name || l_id_cdr_definition,
                                                   i_desc_trans => i_name);
            pk_translation.insert_into_translation(i_lang       => i_lang,
                                                   i_code_trans => g_code_definition_description || l_id_cdr_definition,
                                                   i_desc_trans => i_description);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'CDR_DEFINITION',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            g_error := 'SEVERITY';
            FOR i IN i_severity.first .. i_severity.last
            LOOP
                SELECT seq_cdr_def_severity.nextval
                  INTO l_id_cdr_def_severity
                  FROM dual;
                ts_cdr_def_severity.ins(id_cdr_def_severity_in => l_id_cdr_def_severity,
                                        id_cdr_definition_in   => l_id_cdr_definition,
                                        id_cdr_severity_in     => i_severity(i),
                                        flg_default_in         => CASE
                                                                      WHEN i_severity_def = i_severity(i) THEN
                                                                       pk_alert_constant.g_yes
                                                                      ELSE
                                                                       pk_alert_constant.g_yes
                                                                  END,
                                        rows_out               => l_rows_out);
            
            END LOOP;
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'CDR_DEF_SEVERITY',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            -- gravar as condições
            l_id_cdr_condition := -1;
            l_id_cdr_concept   := -1;
            g_error            := 'CONDITION';
            FOR i IN i_definition_data.first .. i_definition_data.last -- CONDIÇÕES
            LOOP
                l_definition_data := i_definition_data(i);
                IF l_definition_data(g_idx_condition) <> l_id_cdr_condition
                THEN
                    l_id_cdr_condition := l_definition_data(g_idx_condition);
                    l_id_cdr_def_cond  := ts_cdr_def_cond.next_key;
                
                    ts_cdr_def_cond.ins(id_cdr_def_cond_in   => l_id_cdr_def_cond,
                                        id_cdr_definition_in => l_id_cdr_definition,
                                        id_cdr_condition_in  => l_id_cdr_condition,
                                        rank_in              => l_definition_data(g_idx_condition_rank),
                                        flg_condition_in     => l_definition_data(g_idx_flg_condition),
                                        flg_deny_in          => l_definition_data(g_idx_flg_deny),
                                        rows_out             => l_rows_out_def_cond);
                END IF;
                IF l_definition_data(g_idx_concept) <> l_id_cdr_concept
                THEN
                    -- cdr_paramenter (concepts)
                    g_error            := 'CONCEPT';
                    l_id_cdr_concept   := l_definition_data(g_idx_concept);
                    l_id_cdr_parameter := ts_cdr_parameter.next_key;
                    ts_cdr_parameter.ins(id_cdr_parameter_in => l_id_cdr_parameter,
                                         id_cdr_def_cond_in  => l_id_cdr_def_cond,
                                         id_cdr_concept_in   => l_id_cdr_concept,
                                         rank_in             => l_definition_data(g_idx_concept_rank),
                                         rows_out            => l_rows_out_parameter);
                
                END IF;
                -- CDR_PARAM_ACTION
                SELECT seq_cdr_param_action.nextval
                  INTO l_id_cdr_param_action
                  FROM dual;
                g_error := 'PARAM ACTION';
                ts_cdr_param_action.ins(id_cdr_param_action_in => l_id_cdr_param_action,
                                        id_cdr_parameter_in    => l_id_cdr_parameter,
                                        id_cdr_action_in       => l_definition_data(g_idx_action),
                                        event_span_in          => l_definition_data(g_idx_action_value),
                                        id_event_span_umea_in  => l_definition_data(g_idx_action_unit),
                                        message_in             => l_definition_data(g_idx_action_message),
                                        flg_first_time_in      => l_definition_data(g_idx_action_flg_first),
                                        rows_out               => l_rows_out_param_action);
            
            END LOOP;
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'CDR_DEF_COND',
                                          i_rowids     => l_rows_out_def_cond,
                                          o_error      => o_error);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'CDR_PARAMETER',
                                          i_rowids     => l_rows_out_parameter,
                                          o_error      => o_error);
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'CDR_PARAM_ACTION',
                                          i_rowids     => l_rows_out_param_action,
                                          o_error      => o_error);
        
        ELSE
            -- edit one definition
            OPEN c_definition(i_definition => i_id_cdr_definition);
            FETCH c_definition
                INTO l_flg_origin;
            CLOSE c_definition;
            IF l_flg_origin = pk_cdr_constant.g_origin_def
            THEN
                o_flg_show  := pk_alert_constant.g_yes;
                o_buttons   := 'NC';
                o_msg_title := pk_message.get_message(i_lang, i_prof, 'COMMON_T013');
                o_msg       := pk_message.get_message(i_lang, i_prof, 'CDR_T072') || ' <BR><BR>' ||
                               pk_message.get_message(i_lang, i_prof, 'CDR_T074');
            
                RETURN TRUE;
            
            END IF;
            IF check_definition_has_instances(i_id_cdr_definition => i_id_cdr_definition) = pk_alert_constant.g_yes
            THEN
                o_flg_show  := pk_alert_constant.g_yes;
                o_buttons   := 'NC';
                o_msg_title := pk_message.get_message(i_lang, i_prof, 'COMMON_T013');
                o_msg       := pk_message.get_message(i_lang, i_prof, 'CDR_T072') || ' <BR><BR>' ||
                               pk_message.get_message(i_lang, i_prof, 'CDR_T073');
            
                RETURN TRUE;
            END IF;
            ts_cdr_definition.upd(id_cdr_definition_in => i_id_cdr_definition,
                                  id_cdr_type_in       => i_id_cdr_type,
                                  rows_out             => l_rows_out);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'CDR_DEFINITION',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            g_error := 'INSERT TRANSLATION';
            pk_translation.insert_into_translation(i_lang       => i_lang,
                                                   i_code_trans => g_code_definition_name || l_id_cdr_definition,
                                                   i_desc_trans => i_name);
            pk_translation.insert_into_translation(i_lang       => i_lang,
                                                   i_code_trans => g_code_definition_description || l_id_cdr_definition,
                                                   i_desc_trans => i_description);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'CDR_DEFINITION',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'CDR_DEF_SEVERITY',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
        END IF;
        o_id_cdr_definition := l_id_cdr_definition;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_CDR_DEFINITION',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_cdr_definition;

    --

    /*###################################################################################################
                                            INSTANCES
    ###################################################################################################*/

    --

    /********************************************************************************
    |                              List Functions                                   |
    ********************************************************************************/

    /**********************************************************************************************
    * Returns the get name/description function for a given concept
    *
    * @param i_lang                   the id language
    * @param i_id_concept             Concept ID    
    *
    * @return                         String with function name for get the
    *                                 name/description of the concept
    *
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/03/17
    **********************************************************************************************/
    FUNCTION get_concept_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_id_concept IN cdr_concept.id_cdr_concept%TYPE
    ) RETURN pk_translation.t_desc_translation IS
    BEGIN
        RETURN pk_translation.get_translation(i_lang      => i_lang,
                                              i_code_mess => 'CDR_CONCEPT.CODE_CDR_CONCEPT.' || i_id_concept);
    END get_concept_desc;

    /**********************************************************************************************
    * Get list of definitions for the settings selection screen.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_rule_def_list          list of definitions for the selection screen
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/03/09
    **********************************************************************************************/
    FUNCTION get_setting_select_def
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_rule_def_list OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_SETTING_SELECT_DEF';
    BEGIN
    
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ']', g_package, l_func_name);
        --
        g_error := 'OPEN o_rule_def_list';
        OPEN o_rule_def_list FOR
            SELECT cr.id_cdr_definition definition_id,
                   pk_translation.get_translation(i_lang, cr.code_name) definition_name,
                   get_desc_conditions(i_lang, cr.id_cdr_definition) definition_conditions,
                   get_desc_tooltip_def(i_lang, i_prof, cr.id_cdr_definition) definition_tooltip
              FROM cdr_definition cr
             WHERE cr.id_institution IN (0, i_prof.institution)
               AND cr.flg_status IN (pk_alert_constant.g_active, pk_cdr_constant.g_edited)
               AND cr.flg_available = pk_alert_constant.g_yes
               AND NOT EXISTS (SELECT 1
                      FROM cdr_def_config cdc
                      JOIN cdr_param_action cpa
                        ON cdc.id_cdr_param_action = cpa.id_cdr_param_action
                      JOIN cdr_parameter cp
                        ON cpa.id_cdr_parameter = cp.id_cdr_parameter
                      JOIN cdr_def_cond cdc1
                        ON cp.id_cdr_def_cond = cdc1.id_cdr_def_cond
                     WHERE cdc1.id_cdr_definition = cr.id_cdr_definition
                       AND cdc.id_institution = i_prof.institution)
             ORDER BY definition_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_rule_def_list);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_setting_select_def;
    --

    /**********************************************************************************************
    * Returns the list all rule instances, or all rule instances for a given rule definition, when 
    * the parameter i_id_rule_definiton is either NULL or not.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_cdr_definition     ID rule definition
    * @param o_rule_inst_list         list of all rule instances
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/04/19
    **********************************************************************************************/
    FUNCTION get_rules_instances_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_definition IN cdr_definition.id_cdr_definition%TYPE,
        o_rule_inst_list    OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ']',
                              g_package,
                              'get_rules_instances_list');
        --
        g_error := 'OPEN CURSOR o_rule_inst_list';
        OPEN o_rule_inst_list FOR
            SELECT ci.id_cdr_instance,
                   ci.id_cdr_definition,
                   pk_translation.get_translation(i_lang, cd.code_name) instance_name,
                   pk_translation.get_translation(i_lang, ct.code_cdr_type) desc_cdr_type,
                   get_cdr_instances_desc(i_lang, i_prof, ci.id_cdr_instance) desc_instances,
                   ci.code_description instance_description,
                   ci.flg_status flg_status,
                   pk_sysdomain.get_domain(pk_cdr_constant.g_domain_status, ci.flg_status, i_lang) desc_status,
                   get_cdr_def_concepts_desc(i_lang, i_prof, cd.id_cdr_definition) desc_concepts,
                   pk_translation.get_translation(i_lang, cs.code_cdr_severity) desc_severity,
                   -- Button control
                   decode(ci.flg_origin,
                          pk_cdr_constant.g_origin_def,
                          pk_alert_constant.g_no,
                          pk_action.get_action_flg_status('CDR_RULE_INS_ACT_BUTT',
                                                          ci.flg_status,
                                                          pk_cdr_constant.g_action_cancel)) flg_can_cancel,
                   decode(ci.flg_origin,
                          pk_cdr_constant.g_origin_def,
                          pk_alert_constant.g_no,
                          pk_action.get_action_flg_status('CDR_RULE_INS_ACT_BUTT',
                                                          ci.flg_status,
                                                          pk_cdr_constant.g_action_edit)) flg_can_edit,
                   ct.rank
              FROM cdr_instance ci
              JOIN cdr_definition cd
                ON (ci.id_cdr_definition = cd.id_cdr_definition)
              JOIN cdr_type ct
                ON (cd.id_cdr_type = ct.id_cdr_type)
              JOIN cdr_severity cs
                ON ci.id_cdr_severity = cs.id_cdr_severity
             WHERE (i_id_cdr_definition IS NULL OR i_id_cdr_definition = cd.id_cdr_definition)
               AND nvl(ci.id_institution, 0) IN (0, i_prof.institution)
             ORDER BY rank, instance_name DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_rule_inst_list);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_RULES_INSTANCES_LIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_rules_instances_list;
    --

    /**********************************************************************************************
    * Set/change the rule definition state.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_CDR_DEFINITION     ID rule definition
    * @param i_rule_status            rule new status 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/03/09
    **********************************************************************************************/
    FUNCTION set_cdr_definition_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_definition IN cdr_definition.id_cdr_definition%TYPE,
        i_cdr_status        IN cdr_definition.flg_status%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows_out table_varchar := table_varchar();
    BEGIN
    
        pk_alertlog.log_debug('PARAMS[i_id_CDR_DEFINITION: ' || i_id_cdr_definition || 'i_cdr_status: ' ||
                              i_cdr_status || ']',
                              g_package,
                              'set_CDR_DEFINITION_status');
        --
        g_error := 'UPDATE CDR_DEFINITION status';
    
        --IF the status is set ot INACTIVE the Rule Instances don't change 'automatically'.
        --It only means that we cannot create new instances of that type.
        ts_cdr_definition.upd(id_cdr_definition_in => i_id_cdr_definition,
                              flg_status_in        => i_cdr_status,
                              rows_out             => l_rows_out);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'CDR_DEFINITION',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_CDR_DEFINITION_STATUS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_cdr_definition_status;
    --

    /**********************************************************************************************
    * Set/change the rule instance state.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_rule_instance       ID rule instance
    * @param i_rule_status            rule new status 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/03/09
    **********************************************************************************************/
    FUNCTION set_cdr_instance_status
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_cdr_instance IN cdr_instance.id_cdr_instance%TYPE,
        i_cdr_status      IN cdr_instance.flg_status%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows_out table_varchar := table_varchar();
    BEGIN
    
        pk_alertlog.log_debug('PARAMS[i_id_rule_instance: ' || i_id_cdr_instance || 'i_rule_status: ' || i_cdr_status || ']',
                              g_package,
                              'set_cdr_instance_status');
        --
        g_error := 'UPDATE rule_instance status';
    
        ts_cdr_instance.upd(id_cdr_instance_in => i_id_cdr_instance,
                            flg_status_in      => i_cdr_status,
                            rows_out           => l_rows_out);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'CDR_INSTANCE',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_CDR_INSTANCE_STATUS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_cdr_instance_status;
    --

    /**********************************************************************************************
    * Cancel Rule definition
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_id_CDR_DEFINITION     ID rule definition
    * @param i_notes                  Cancel notes
    * @param i_cancel_reason          ID Cancel reason    
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/03/14
    **********************************************************************************************/
    FUNCTION cancel_cdr_definition
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_definition IN cdr_definition.id_cdr_definition%TYPE,
        i_notes             IN cancel_info_det.notes_cancel_short%TYPE,
        i_cancel_reason     IN cancel_reason.id_cancel_reason%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        --Local Variables
        l_rows_out           table_varchar := table_varchar();
        l_cancel_info_det_id cancel_info_det.id_cancel_info_det%TYPE;
    
    BEGIN
    
        pk_alertlog.log_debug('PARAMS[:i_id_CDR_DEFINITION:' || i_id_cdr_definition || ' ]',
                              g_package,
                              'CANCEL_CDR_DEFINITION');
    
        --insert the cancel details:
        g_sysdate_tstz := current_timestamp;
        --
        pk_alertlog.log_debug('CANCEL_CDR_DEFINITION: i_cancel_reason =  ' || i_cancel_reason || ', ');
        ts_cancel_info_det.ins(id_prof_cancel_in      => i_prof.id,
                               id_cancel_reason_in    => i_cancel_reason,
                               dt_cancel_in           => g_sysdate_tstz,
                               notes_cancel_short_in  => i_notes,
                               id_cancel_info_det_out => l_cancel_info_det_id,
                               rows_out               => l_rows_out);
    
        g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON CANCEL_INFO_DET';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'CANCEL_INFO_DET',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        g_error := 'CALL TS_CDR_DEFINITION.UPD';
        ts_cdr_definition.upd(id_cdr_definition_in  => i_id_cdr_definition,
                              flg_status_in         => pk_alert_constant.g_cancelled,
                              id_cancel_info_det_in => l_cancel_info_det_id,
                              rows_out              => l_rows_out);
    
        pk_alertlog.log_debug('UPDATE_CDR_DEFINITION: i_id_CDR_DEFINITION:' || i_id_cdr_definition,
                              g_package,
                              'CANCEL_CDR_DEFINITION');
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'CDR_DEFINITION',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CANCEL_CDR_DEFINITION',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_cdr_definition;
    --

    /**********************************************************************************************
    * Cancel Rule instance
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_id_rule_instance       ID rule instance
    * @param i_notes                  Cancel notes
    * @param i_cancel_reason          ID Cancel reason    
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/03/14
    **********************************************************************************************/
    FUNCTION cancel_cdr_instance
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_cdr_instance IN cdr_instance.id_cdr_instance%TYPE,
        i_notes           IN cancel_info_det.notes_cancel_short%TYPE,
        i_cancel_reason   IN cancel_reason.id_cancel_reason%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        --Local Variables
        l_rows_out           table_varchar := table_varchar();
        l_cancel_info_det_id cancel_info_det.id_cancel_info_det%TYPE;
    
    BEGIN
    
        pk_alertlog.log_debug('PARAMS[:i_id_rule:' || i_id_cdr_instance || ' ]', g_package, 'CANCEL_RULE_INSTANCE');
    
        --insert the cancel details:
        g_sysdate_tstz := current_timestamp;
        --
        pk_alertlog.log_debug('CANCEL_RULE_INSTANCE: i_cancel_reason =  ' || i_cancel_reason || ', ');
        ts_cancel_info_det.ins(id_prof_cancel_in      => i_prof.id,
                               id_cancel_reason_in    => i_cancel_reason,
                               dt_cancel_in           => g_sysdate_tstz,
                               notes_cancel_short_in  => i_notes,
                               id_cancel_info_det_out => l_cancel_info_det_id,
                               rows_out               => l_rows_out);
    
        g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON CANCEL_INFO_DET';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'CANCEL_INFO_DET',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        g_error := 'CALL TS_RULE.UPD';
        ts_cdr_instance.upd(id_cdr_instance_in    => i_id_cdr_instance,
                            flg_status_in         => pk_alert_constant.g_cancelled,
                            id_cancel_info_det_in => l_cancel_info_det_id,
                            rows_out              => l_rows_out);
    
        pk_alertlog.log_debug('UPDATE_RULE:i_id_cdr_instance:' || i_id_cdr_instance, g_package, 'CANCEL_RULE_INSTANCE');
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'CDR_INSTANCE',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CANCEL_RULE_INSTANCE',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_cdr_instance;
    --

    /**********************************************************************************************
    * Get all information to the edit screen in order to edit a rule definition
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_rule_def_list          list of all rule definitions
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/03/09
    **********************************************************************************************/
    FUNCTION get_edit_cdr_definition
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_cdr_definition      IN cdr_definition.id_cdr_definition%TYPE,
        o_cdr_definition         OUT pk_types.cursor_type,
        o_cdr_def_condition      OUT pk_types.cursor_type,
        o_cdr_concepts           OUT pk_types.cursor_type,
        o_cdr_actions            OUT pk_types.cursor_type,
        o_cdr_severity           OUT pk_types.cursor_type,
        o_cdr_parameters         OUT pk_types.cursor_type,
        o_cdr_parameters_actions OUT pk_types.cursor_type,
        o_screen_labels          OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ']',
                              g_package,
                              'GET_EDIT_CDR_DEFINITION');
        --
        g_error := 'OPEN CURSOR o_cdr_definition';
        OPEN o_cdr_definition FOR
            SELECT cd.id_cdr_definition,
                   pk_translation.get_translation(i_lang, cd.code_name) instance_name,
                   pk_translation.get_translation(i_lang, cd.code_description) instance_description,
                   ct.id_cdr_type,
                   pk_translation.get_translation(i_lang, ct.code_cdr_type) desc_cdr_type,
                   ct.icon icon_name,
                   cd.flg_status flg_status
              FROM cdr_definition cd
              JOIN cdr_type ct
                ON (cd.id_cdr_type = ct.id_cdr_type)
             WHERE cd.id_cdr_definition = i_id_cdr_definition
             ORDER BY instance_name DESC;
    
        g_error := 'OPEN CURSOR o_cdr_severity';
        OPEN o_cdr_severity FOR
            SELECT cs.id_cdr_severity,
                   pk_translation.get_translation(i_lang, cs.code_cdr_severity) desc_severity,
                   cds.flg_default,
                   cs.color
              FROM cdr_def_severity cds
              JOIN cdr_severity cs
                ON cds.id_cdr_severity = cs.id_cdr_severity
             WHERE cds.id_cdr_definition = i_id_cdr_definition;
        ----
        g_error := 'OPEN CURSOR o_cdr_def_condition';
        OPEN o_cdr_def_condition FOR
            SELECT cd.id_cdr_definition id_cdr_definition,
                   cdc.id_cdr_condition id_rule_condition,
                   cdc.rank,
                   cdc.flg_condition    operation
              FROM cdr_definition cd
              JOIN cdr_def_cond cdc
                ON (cd.id_cdr_definition = cdc.id_cdr_definition)
             WHERE cd.id_cdr_definition = i_id_cdr_definition
             ORDER BY cdc.rank;
        ---
        OPEN o_cdr_parameters FOR
            SELECT cc.id_cdr_condition id_rule_condition,
                   cp.id_cdr_parameter id_parameter,
                   cp.rank             rank,
                   cp.id_cdr_concept   param_type,
                   cdc.flg_condition   operation
              FROM cdr_definition cd
              JOIN cdr_def_cond cdc
                ON (cd.id_cdr_definition = cdc.id_cdr_definition)
              JOIN cdr_condition cc
                ON cdc.id_cdr_condition = cc.id_cdr_condition
              JOIN cdr_parameter cp
                ON (cp.id_cdr_def_cond = cdc.id_cdr_def_cond)
             WHERE cd.id_cdr_definition = i_id_cdr_definition
             ORDER BY cdc.rank, cp.rank;
    
        OPEN o_screen_labels FOR
            SELECT decode(i_id_cdr_definition,
                          NULL,
                          pk_message.get_message(i_lang, 'CDR_T026'),
                          pk_message.get_message(i_lang, 'CDR_T027')) screen_header,
                   pk_message.get_message(i_lang, 'CDR_T028') tab_definition,
                   pk_message.get_message(i_lang, 'CDR_T029') name,
                   pk_message.get_message(i_lang, 'CDR_T016') type_of_rule,
                   pk_message.get_message(i_lang, 'CDR_T023') severity_level,
                   pk_message.get_message(i_lang, 'CDR_T030') description,
                   pk_message.get_message(i_lang, 'CDR_T045') action,
                   pk_message.get_message(i_lang, 'CDR_T032') preview,
                   pk_message.get_message(i_lang, 'CDR_T033') warning,
                   pk_message.get_message(i_lang, 'CDR_T034') action_general,
                   pk_message.get_message(i_lang, 'CDR_T035') action_specific_concept,
                   pk_message.get_message(i_lang, 'CDR_T044') rule_construction,
                   pk_message.get_message(i_lang, 'CDR_T036') cdr_rule,
                   pk_message.get_message(i_lang, 'CDR_T037') cdr_negative,
                   pk_message.get_message(i_lang, 'CDR_T038') cdr_condition,
                   pk_message.get_message(i_lang, 'CDR_T039') and_operation,
                   pk_message.get_message(i_lang, 'CDR_T040') or_operation,
                   pk_message.get_message(i_lang, 'CDR_T041') concept,
                   pk_message.get_message(i_lang, 'CDR_T042') action_specific,
                   pk_message.get_message(i_lang, 'CDR_T043') crd_not
              FROM dual;
        pk_types.open_my_cursor(o_cdr_concepts);
        pk_types.open_my_cursor(o_cdr_actions);
    
        pk_types.open_my_cursor(o_cdr_parameters_actions);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_cdr_definition);
            pk_types.open_my_cursor(o_cdr_def_condition);
            pk_types.open_my_cursor(o_cdr_concepts);
            pk_types.open_my_cursor(o_cdr_actions);
            pk_types.open_my_cursor(o_cdr_severity);
        
            pk_types.open_my_cursor(o_cdr_parameters);
            pk_types.open_my_cursor(o_cdr_parameters_actions);
            pk_types.open_my_cursor(o_screen_labels);
        
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_EDIT_CDR_DEFINITION',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_edit_cdr_definition;
    --

    /**********************************************************************************************
    * This function returns a the concepts of rule. This description 
    * is based on the several conditions/ concepts that are part of the rule.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_cdr_definition      ID rule definition    
    *
    * @return                         String with the rule description
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/04/18
    **********************************************************************************************/
    FUNCTION get_cdr_def_concepts_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_definition IN cdr_definition.id_cdr_definition%TYPE
    ) RETURN CLOB IS
    
        l_rule_concept_desc CLOB;
    
        l_t_rec_rule_parameter t_rec_rule_parameter;
        l_t_rec_cdr_condition  t_rec_cdr_condition;
        l_open_parentisis      varchar_1 := '(';
        l_close_parentisis     varchar_1 := ')';
    BEGIN
    
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ']',
                              g_package,
                              'GET_CDR_DEFINITION_CONCEPTS_DESC');
        --
        g_error := 'GET rule instance concepts detailed desc';
        --converts the rule concepts in text
    
        SELECT cdc.id_cdr_def_cond,
               pk_sysdomain.get_domain(pk_cdr_constant.g_domain_operator, cdc.flg_condition, i_lang) rule_condition,
               pk_translation.get_translation(i_lang, cc.code_cdr_condition),
               cdc.rank
          BULK COLLECT
          INTO l_t_rec_cdr_condition
          FROM cdr_definition cd
          JOIN cdr_def_cond cdc
            ON cdc.id_cdr_definition = cd.id_cdr_definition
          JOIN cdr_condition cc
            ON cdc.id_cdr_condition = cc.id_cdr_condition
         WHERE cd.id_cdr_definition = i_id_cdr_definition
         ORDER BY cdc.rank;
    
        FOR i IN 1 .. l_t_rec_cdr_condition.count
        LOOP
            l_rule_concept_desc := l_rule_concept_desc || l_t_rec_cdr_condition(i).cdr_condition_name ||
                                   l_open_parentisis;
        
            SELECT cp.id_cdr_parameter, cp.id_cdr_def_cond, cp.id_cdr_concept, NULL message, cp.rank rank
              BULK COLLECT
              INTO l_t_rec_rule_parameter
              FROM cdr_parameter cp
             WHERE cp.id_cdr_def_cond = l_t_rec_cdr_condition(i).id_cdr_def_cond
             ORDER BY cp.rank;
        
            FOR j IN 1 .. l_t_rec_rule_parameter.count
            LOOP
                l_rule_concept_desc := l_rule_concept_desc ||
                                       get_concept_desc(i_lang, l_t_rec_rule_parameter(j).id_cdr_concept);
                IF j < l_t_rec_rule_parameter.count
                THEN
                    l_rule_concept_desc := l_rule_concept_desc || ',';
                END IF;
            END LOOP;
        
            l_rule_concept_desc := l_rule_concept_desc || l_close_parentisis;
            --
            IF i < l_t_rec_cdr_condition.count
            THEN
                l_rule_concept_desc := l_rule_concept_desc || ' ' || l_t_rec_cdr_condition(i).cdr_condition || ' ';
            END IF;
        
        END LOOP;
        --
    
        RETURN l_rule_concept_desc;
    END get_cdr_def_concepts_desc;

    /**
    * Describe a rule definition in natural language,
    * using it's conditions and operators.
    *
    * @param i_lang         language identifier
    * @param i_definition   rule definition identifier
    *
    * @return               rule definition conditions description
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2011/10/13
    */
    FUNCTION get_desc_conditions
    (
        i_lang       IN language.id_language%TYPE,
        i_definition IN cdr_definition.id_cdr_definition%TYPE
    ) RETURN pk_translation.t_desc_translation IS
        l_no CONSTANT sys_domain.desc_val%TYPE := pk_sysdomain.get_domain(i_code_dom => 'YES_NO',
                                                                          i_val      => pk_alert_constant.g_no,
                                                                          i_lang     => i_lang);
        l_cond table_varchar;
        l_oper table_varchar;
        l_deny table_varchar;
        l_ret  pk_translation.t_desc_translation;
    
        CURSOR c_conditions IS
            SELECT pk_translation.get_translation(i_lang, cdrc.code_cdr_condition) desc_condition,
                   (SELECT pk_sysdomain.get_domain(pk_cdr_constant.g_domain_operator, cdrdc.flg_condition, i_lang)
                      FROM dual) desc_oper,
                   decode(cdrdc.flg_deny, pk_alert_constant.g_yes, l_no) desc_deny
              FROM cdr_def_cond cdrdc
              JOIN cdr_condition cdrc
                ON cdrdc.id_cdr_condition = cdrc.id_cdr_condition
             WHERE cdrdc.id_cdr_definition = i_definition
             ORDER BY cdrdc.rank;
    BEGIN
        OPEN c_conditions;
        FETCH c_conditions BULK COLLECT
            INTO l_cond, l_oper, l_deny;
        CLOSE c_conditions;
    
        IF l_cond IS NULL
           OR l_cond.count < 1
        THEN
            l_ret := NULL;
        ELSE
            FOR i IN l_cond.first .. l_cond.last
            LOOP
                l_ret := pk_string_utils.concat_if_exists(i_str1 => l_ret,
                                                          i_str2 => pk_string_utils.concat_if_exists(i_str1 => l_deny(i),
                                                                                                     i_str2 => l_cond(i),
                                                                                                     i_sep  => ' '),
                                                          i_sep  => ' ') || CASE
                             WHEN l_cond.exists(i + 1) THEN
                              ' ' || l_oper(i)
                         END;
            END LOOP;
        END IF;
    
        RETURN l_ret;
    END get_desc_conditions;

    /**
    * Describe a rule definition in natural language,
    * using all available information. To be shown on the screen tooltip.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_definition   rule definition identifier
    *
    * @return               rule definition full description
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2011/10/13
    */
    FUNCTION get_desc_tooltip_def
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_definition IN cdr_definition.id_cdr_definition%TYPE
    ) RETURN CLOB IS
        l_break  CONSTANT VARCHAR2(5 CHAR) := '<br/>';
        l_indent CONSTANT VARCHAR2(2 CHAR) := '  ';
        l_lbl_name  sys_message.desc_message%TYPE;
        l_lbl_type  sys_message.desc_message%TYPE;
        l_lbl_desc  sys_message.desc_message%TYPE;
        l_lbl_cdrc  sys_message.desc_message%TYPE;
        l_lbl_cdrcp sys_message.desc_message%TYPE;
        l_lbl_cdra  sys_message.desc_message%TYPE;
        l_lbl_deny  sys_message.desc_message%TYPE;
        l_ret       CLOB;
        l_buf       VARCHAR2(2000 CHAR);
        l_idx       PLS_INTEGER := 1; -- conditions collection index
        l_param_cnt PLS_INTEGER;
        l_actions   table_varchar;
    
        CURSOR c_attrib IS
            SELECT pk_translation.get_translation(i_lang, cdrd.code_name) rule_name,
                   pk_translation.get_translation(i_lang, cdrd.code_description) rule_desc,
                   pk_translation.get_translation(i_lang, cdrt.code_cdr_type) rule_type
              FROM cdr_definition cdrd
              JOIN cdr_type cdrt
                ON cdrd.id_cdr_type = cdrt.id_cdr_type
             WHERE cdrd.id_cdr_definition = i_definition;
    
        CURSOR c_cond IS
            SELECT cdrp.id_cdr_parameter,
                   COUNT(DISTINCT cdrp.id_cdr_parameter) over(PARTITION BY cdrdc.id_cdr_def_cond) param_count,
                   pk_translation.get_translation(i_lang, cdrc.code_cdr_condition) condition_desc,
                   pk_translation.get_translation(i_lang, cdrcp.code_cdr_concept) concept_desc,
                   (SELECT pk_sysdomain.get_domain(pk_cdr_constant.g_domain_operator, cdrdc.flg_condition, i_lang)
                      FROM dual) oper_desc,
                   cdrdc.flg_deny
              FROM cdr_def_cond cdrdc
              JOIN cdr_condition cdrc
                ON cdrdc.id_cdr_condition = cdrc.id_cdr_condition
              JOIN cdr_parameter cdrp
                ON cdrdc.id_cdr_def_cond = cdrp.id_cdr_def_cond
              JOIN cdr_concept cdrcp
                ON cdrp.id_cdr_concept = cdrcp.id_cdr_concept
             WHERE cdrdc.id_cdr_definition = i_definition
             ORDER BY cdrdc.rank;
    
        CURSOR c_action(i_param IN cdr_param_action.id_cdr_parameter%TYPE) IS
            SELECT pk_translation.get_translation(i_lang, cdra.code_cdr_action) action_desc
              FROM cdr_param_action cdrpa
              JOIN cdr_action cdra
                ON cdrpa.id_cdr_action = cdra.id_cdr_action
             WHERE cdrpa.id_cdr_parameter = i_param;
    
        r_attrib c_attrib%ROWTYPE;
        TYPE t_cond IS TABLE OF c_cond%ROWTYPE;
        l_cond t_cond;
    
        -- internal utility function to get indentations
        FUNCTION get_indent(i_n IN PLS_INTEGER) RETURN VARCHAR2 IS
        BEGIN
            RETURN rpad(l_indent, i_n * 2);
        END get_indent;
    BEGIN
        -- get labels
        l_lbl_name  := pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang      => i_lang,
                                                                                                 i_prof      => i_prof,
                                                                                                 i_code_mess => 'CDR_T077'));
        l_lbl_type  := pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang      => i_lang,
                                                                                                 i_prof      => i_prof,
                                                                                                 i_code_mess => 'CDR_T078'));
        l_lbl_desc  := pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang      => i_lang,
                                                                                                 i_prof      => i_prof,
                                                                                                 i_code_mess => 'CDR_T079'));
        l_lbl_cdrc  := pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang      => i_lang,
                                                                                                 i_prof      => i_prof,
                                                                                                 i_code_mess => 'CDR_T080'));
        l_lbl_cdrcp := pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang      => i_lang,
                                                                                                 i_prof      => i_prof,
                                                                                                 i_code_mess => 'CDR_T081'));
        l_lbl_cdra  := pk_paramedical_prof_core.format_str_header_w_colon(pk_message.get_message(i_lang      => i_lang,
                                                                                                 i_prof      => i_prof,
                                                                                                 i_code_mess => 'CDR_T082'));
        l_lbl_deny  := pk_utils.to_bold(i_text => pk_message.get_message(i_lang      => i_lang,
                                                                         i_prof      => i_prof,
                                                                         i_code_mess => 'CDR_T087'));
    
        -- get definition attributes
        OPEN c_attrib;
        FETCH c_attrib
            INTO r_attrib;
        CLOSE c_attrib;
    
        dbms_lob.createtemporary(l_ret, TRUE);
    
        -- add definition attributes
        l_buf := l_lbl_name || r_attrib.rule_name || l_break || l_break;
        l_buf := l_buf || l_lbl_type || r_attrib.rule_type || l_break;
        l_buf := l_buf || l_lbl_desc || r_attrib.rule_desc || l_break || l_break;
    
        dbms_lob.writeappend(l_ret, length(l_buf), l_buf);
    
        -- get rule definition structure
        OPEN c_cond;
        FETCH c_cond BULK COLLECT
            INTO l_cond;
        CLOSE c_cond;
    
        WHILE l_cond.count >= l_idx
        LOOP
            l_param_cnt := l_cond(l_idx).param_count;
        
            -- add expression label
            IF l_idx = l_cond.first
            THEN
                l_buf := l_lbl_cdrc || l_break;
                -- add deniability
                IF l_cond(l_idx).flg_deny = pk_alert_constant.g_yes
                THEN
                    l_buf := l_buf || l_lbl_deny || l_break;
                END IF;
            ELSE
                l_buf := NULL;
            END IF;
            -- add definition condition
            l_buf := l_buf || l_cond(l_idx).condition_desc || l_break;
            -- add concepts label
            l_buf := l_buf || get_indent(1) || l_lbl_cdrcp || l_break;
            FOR i IN 1 .. l_param_cnt
            LOOP
                -- add definition concepts
                l_buf := l_buf || get_indent(2) || l_cond(l_idx).concept_desc || l_break;
            
                -- get parameter actions
                OPEN c_action(i_param => l_cond(l_idx).id_cdr_parameter);
                FETCH c_action BULK COLLECT
                    INTO l_actions;
                CLOSE c_action;
            
                -- add action label
                IF l_actions IS NOT NULL
                   AND l_actions.count > 0
                THEN
                    l_buf := l_buf || get_indent(3) || l_lbl_cdra || l_break;
                END IF;
            
                -- add action descriptions
                FOR j IN 1 .. l_actions.count
                LOOP
                    l_buf := l_buf || get_indent(4) || l_actions(j) || l_break;
                END LOOP;
            
                l_idx := l_idx + 1;
            END LOOP;
        
            -- add operator
            IF l_idx < l_cond.count + 1
            THEN
                l_buf := l_buf || pk_utils.to_bold(i_text => upper(l_cond(l_idx - 1).oper_desc));
                -- add deniability
                IF l_cond(l_idx).flg_deny = pk_alert_constant.g_yes
                THEN
                    l_buf := l_buf || ' ' || l_lbl_deny;
                END IF;
                l_buf := l_buf || l_break;
            END IF;
        
            dbms_lob.writeappend(l_ret, length(l_buf), l_buf);
        END LOOP;
    
        RETURN l_ret;
    END get_desc_tooltip_def;

    FUNCTION get_element_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_inst_param IN cdr_inst_param.id_cdr_inst_param%TYPE,
        i_id_cdr_concept    IN cdr_concept.id_cdr_concept%TYPE,
        i_id_element        IN cdr_inst_param.id_element%TYPE,
        i_flg_identifiable  IN cdr_concept.flg_identifiable%TYPE,
        i_flg_valuable      IN cdr_concept.flg_valuable%TYPE,
        i_val_min           IN cdr_inst_param.val_min%TYPE,
        i_val_max           IN cdr_inst_param.val_max%TYPE,
        i_unit_measure      IN cdr_inst_param.id_domain_umea%TYPE
    ) RETURN pk_translation.t_desc_translation IS
    
        l_parameter_desc   pk_translation.t_desc_translation;
        l_open_parentisis  varchar_1 := '(';
        l_close_parentisis varchar_1 := ')';
        l_element_value    pk_translation.t_desc_translation;
    BEGIN
    
        IF i_flg_identifiable = pk_alert_constant.g_available -- concept is identifiable
        THEN
            l_parameter_desc := pk_cdr_fo_core.get_elem_translation(i_lang    => i_lang,
                                                                    i_prof    => i_prof,
                                                                    i_concept => i_id_cdr_concept,
                                                                    i_element => i_id_element);
        END IF;
    
        IF i_flg_valuable = pk_alert_constant.g_available -- concept is valuable
        THEN
            l_element_value := pk_cdr_fo_core.get_val_domain_desc(i_lang      => i_lang,
                                                                  i_prof      => i_prof,
                                                                  i_val_min   => i_val_min,
                                                                  i_val_max   => i_val_max,
                                                                  i_domain_um => i_unit_measure);
            IF l_element_value IS NOT NULL
            THEN
                IF i_flg_identifiable = pk_alert_constant.g_available
                THEN
                    l_parameter_desc := l_parameter_desc || l_open_parentisis || l_element_value || l_close_parentisis;
                ELSE
                    l_parameter_desc := l_element_value;
                END IF;
            ELSE
            
                l_parameter_desc := pk_utils.query_to_string(i_query     => 'SELECT VALUE FROM CDR_INST_PAR_VAL WHERE ID_CDR_INST_PARAM = ' ||
                                                                            i_id_cdr_inst_param,
                                                             i_separator => ',');
            END IF;
        END IF;
        RETURN l_parameter_desc;
    END;

    /**********************************************************************************************
    * This function returns a the concepts of rule instance. This description 
    * is based on the several conditions/ concepts that are part of the rule.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_cdr_definition      ID rule definition    
    *
    * @return                         String with the rule description
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/04/18
    **********************************************************************************************/
    FUNCTION get_cdr_instances_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_cdr_instance IN cdr_instance.id_cdr_instance%TYPE
    ) RETURN CLOB IS
        l_rule_instances_desc CLOB;
        l_parameter_desc      VARCHAR2(1000 CHAR);
        l_t_rec_cdr_ins_param t_rec_cdr_ins_param;
        l_t_rec_cdr_condition t_rec_cdr_condition;
        l_open_parentisis     varchar_1 := '(';
        l_close_parentisis    varchar_1 := ')';
    
    BEGIN
    
        g_error := 'GET NAME';
    
        SELECT cdc.id_cdr_def_cond,
               pk_sysdomain.get_domain(pk_cdr_constant.g_domain_operator, cdc.flg_condition, i_lang) rule_condition,
               pk_translation.get_translation(i_lang, cc.code_cdr_condition),
               cdc.rank
          BULK COLLECT
          INTO l_t_rec_cdr_condition
          FROM cdr_instance ci
          JOIN cdr_definition cd
            ON ci.id_cdr_definition = cd.id_cdr_definition
          JOIN cdr_def_cond cdc
            ON cd.id_cdr_definition = cdc.id_cdr_definition
          JOIN cdr_condition cc
            ON cdc.id_cdr_condition = cc.id_cdr_condition
         WHERE ci.id_cdr_instance = i_id_cdr_instance
         ORDER BY cdc.rank;
    
        FOR i IN 1 .. l_t_rec_cdr_condition.count
        LOOP
            l_rule_instances_desc := l_rule_instances_desc || l_t_rec_cdr_condition(i).cdr_condition_name ||
                                     l_open_parentisis;
        
            SELECT cip.id_cdr_inst_param,
                   cp.id_cdr_concept,
                   id_element,
                   cc.flg_identifiable,
                   cc.flg_valuable,
                   cip.val_min,
                   cip.val_max,
                   cip.id_domain_umea
              BULK COLLECT
              INTO l_t_rec_cdr_ins_param
              FROM cdr_parameter cp
              JOIN cdr_inst_param cip
                ON cp.id_cdr_parameter = cip.id_cdr_parameter
              JOIN cdr_concept cc
                ON cp.id_cdr_concept = cc.id_cdr_concept
             WHERE cp.id_cdr_def_cond = l_t_rec_cdr_condition(i).id_cdr_def_cond
               AND cip.id_cdr_instance = i_id_cdr_instance
             ORDER BY cp.rank;
        
            FOR j IN 1 .. l_t_rec_cdr_ins_param.count
            LOOP
                l_parameter_desc := get_element_desc(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_cdr_inst_param => l_t_rec_cdr_ins_param(j).id_cdr_inst_param,
                                                     i_id_cdr_concept    => l_t_rec_cdr_ins_param(j).id_cdr_concept,
                                                     i_id_element        => l_t_rec_cdr_ins_param(j).id_element,
                                                     i_flg_identifiable  => l_t_rec_cdr_ins_param(j).flg_identifiable,
                                                     i_flg_valuable      => l_t_rec_cdr_ins_param(j).flg_valuable,
                                                     i_val_min           => l_t_rec_cdr_ins_param(j).val_min,
                                                     i_val_max           => l_t_rec_cdr_ins_param(j).val_max,
                                                     i_unit_measure      => l_t_rec_cdr_ins_param(j).id_unit_measure);
            
                IF j < l_t_rec_cdr_ins_param.count
                THEN
                    l_parameter_desc := l_parameter_desc || ',';
                END IF;
                l_rule_instances_desc := l_rule_instances_desc || l_parameter_desc;
            END LOOP;
        
            l_rule_instances_desc := l_rule_instances_desc || l_close_parentisis;
            --
            IF i < l_t_rec_cdr_condition.count
            THEN
                l_rule_instances_desc := l_rule_instances_desc || ' ' || l_t_rec_cdr_condition(i).cdr_condition || ' ';
            END IF;
        
        END LOOP;
    
        RETURN l_rule_instances_desc;
    END get_cdr_instances_desc;

    /**********************************************************************************************
    * Get all information to the edit screen in order to edit a rule instance
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_rule_def_list          list of all rule definitions
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/03/09
    **********************************************************************************************/
    FUNCTION get_edit_cdr_instance
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_rule_instance     IN cdr_instance.id_cdr_instance%TYPE,
        o_rule_instance        OUT pk_types.cursor_type,
        o_rule_inst_condition  OUT pk_types.cursor_type,
        o_rule_cond_parameters OUT pk_types.cursor_type,
        o_screen_labels        OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ']', g_package, 'GET_EDIT_RULE_INSTANCE');
        --
        g_error := 'OPEN CURSOR get_edit_rule_instance';
    
        OPEN o_rule_instance FOR
            SELECT ci.id_cdr_instance id_rule,
                   cd.id_cdr_definition id_rule_def,
                   pk_translation.get_translation(i_lang, cd.code_name) rule_name,
                   ci.code_description desc_rule,
                   ct.id_cdr_type id_warning_type,
                   pk_translation.get_translation(i_lang, ct.code_cdr_type) warning_type,
                   --
                   cs.id_cdr_severity id_severity_type,
                   pk_translation.get_translation(i_lang, cs.code_cdr_severity) severity_type,
                   --
                   cd.flg_status flg_status
              FROM cdr_instance ci
              JOIN cdr_definition cd
                ON (ci.id_cdr_definition = cd.id_cdr_definition)
              JOIN cdr_type ct
                ON (cd.id_cdr_type = ct.id_cdr_type)
              JOIN cdr_severity cs
                ON (ci.id_cdr_severity = cs.id_cdr_severity)
             WHERE ci.id_cdr_instance = i_id_rule_instance
             ORDER BY rule_name DESC;
    
        OPEN o_screen_labels FOR
            SELECT pk_message.get_message(i_lang, 'CLINICAL_RULES_T024') screen_header,
                   pk_message.get_message(i_lang, 'CLINICAL_RULES_T007') tab_definition,
                   pk_message.get_message(i_lang, 'CLINICAL_RULES_T008') tab_instance,
                   pk_message.get_message(i_lang, 'CLINICAL_RULES_T003') name,
                   pk_message.get_message(i_lang, 'CLINICAL_RULES_T009') type_warnig,
                   pk_message.get_message(i_lang, 'CLINICAL_RULES_T010') severity_level,
                   pk_message.get_message(i_lang, 'CLINICAL_RULES_T011') description,
                   pk_message.get_message(i_lang, 'CLINICAL_RULES_T012') warning,
                   pk_message.get_message(i_lang, 'CLINICAL_RULES_T013') preview,
                   pk_message.get_message(i_lang, 'CLINICAL_RULES_T014') add_action,
                   pk_message.get_message(i_lang, 'CLINICAL_RULES_T015') to_be_applied,
                   pk_message.get_message(i_lang, 'CLINICAL_RULES_T016') rule_conditions,
                   pk_message.get_message(i_lang, 'CLINICAL_RULES_T017') type_of_rule,
                   pk_message.get_message(i_lang, 'CLINICAL_RULES_T018') and_operation,
                   pk_message.get_message(i_lang, 'CLINICAL_RULES_T019') or_operation,
                   pk_message.get_message(i_lang, 'CLINICAL_RULES_T020') condition_concept,
                   pk_message.get_message(i_lang, 'CLINICAL_RULES_T021') condition_instruction,
                   pk_message.get_message(i_lang, 'CLINICAL_RULES_T022') condition_mandatory,
                   pk_message.get_message(i_lang, 'CLINICAL_RULES_T023') condition_negative
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_rule_instance);
            pk_types.open_my_cursor(o_rule_inst_condition);
            pk_types.open_my_cursor(o_rule_cond_parameters);
            pk_types.open_my_cursor(o_screen_labels);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_EDIT_RULE_INSTANCE',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_edit_cdr_instance;
    --

    /*######################################################################################################
        SETTINGS
    #######################################################################################################/
    
    /**********************************************************************************************
    * Returns the list of professinal category 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_warning_type_list      list of action types
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/04/15
    **********************************************************************************************/
    FUNCTION get_prof_by_profile_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_category IN category.id_category%TYPE,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ' i_category:' || i_category || ']',
                              g_package,
                              'GET_PROF_BY_PROFILE_LIST');
    
        g_error := 'OPEN o_list';
        OPEN o_list FOR
            SELECT pc.id_professional,
                   pk_prof_utils.get_name_signature(i_lang,
                                                    profissional(pc.id_professional, NULL, NULL),
                                                    pc.id_professional) prof_name,
                   decode(i_prof.id, pc.id_professional, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_default,
                   c.id_category category
              FROM prof_cat pc
              JOIN category c
                ON c.id_category = pc.id_category
             INNER JOIN prof_institution pi
                ON pc.id_professional = pi.id_professional
             WHERE pc.id_institution = i_prof.institution
               AND c.id_category = i_category
               AND pi.flg_state = pk_alert_constant.g_active
               AND pi.id_institution = i_prof.institution
             ORDER BY prof_name DESC;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_PROF_BY_PROFILE_LIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_prof_by_profile_list;

    /**********************************************************************************************
    * Returns the list of all rules instance execptions
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_rule_inst_list         list of all rule instances exceptions
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/04/14
    **********************************************************************************************/
    FUNCTION get_rules_inst_settings
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_rule_inst_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ']',
                              g_package,
                              'GET_RULES_INST_SETTINGS');
    
        g_error := 'GET LABELS';
    
        g_error := 'OPEN o_rule_inst_list';
        OPEN o_rule_inst_list FOR
            SELECT ci.id_cdr_instance,
                   icon icon_name,
                   pk_translation.get_translation(i_lang, ct.code_cdr_type) desc_cdr_type,
                   pk_translation.get_translation(i_lang, cd.code_name) definition_name,
                   --                   get_cdr_def_concepts_desc(i_lang, i_prof, cd.id_cdr_definition) desc_concept,
                   get_cdr_instances_desc(i_lang, i_prof, ci.id_cdr_instance) desc_instances
              FROM cdr_instance ci
              JOIN cdr_definition cd
                ON ci.id_cdr_definition = cd.id_cdr_definition
              JOIN cdr_type ct
                ON cd.id_cdr_type = ct.id_cdr_type
             WHERE nvl(ci.id_institution, 0) IN (0, i_prof.institution)
               AND ci.flg_status = pk_alert_constant.g_active
               AND cd.flg_status = pk_alert_constant.g_active
               AND nvl(cd.id_institution, 0) IN (0, i_prof.institution)
               AND EXISTS (SELECT 1
                      FROM cdr_inst_param cip
                      JOIN cdr_inst_par_action cipa
                        ON cip.id_cdr_inst_param = cipa.id_cdr_inst_param
                      JOIN cdr_inst_config cic
                        ON cipa.id_cdr_inst_par_action = cic.id_cdr_inst_par_action
                     WHERE cip.id_cdr_instance = ci.id_cdr_instance)
             ORDER BY definition_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_rule_inst_list);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_RULES_INST_SETTINGS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_rules_inst_settings;

    /**********************************************************************************************
    * Get list of definitions for the settings grid screen.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_rule_list              list of definitions for the settings grid screen
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/04/18
    **********************************************************************************************/
    FUNCTION get_setting_grid_def
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_rule_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_SETTING_GRID_DEF';
    BEGIN
    
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ']', g_package, l_func_name);
    
        g_error := 'OPEN o_rule_list';
    
        OPEN o_rule_list FOR
            SELECT cd.id_cdr_definition definition_id,
                   pk_translation.get_translation(i_lang, cd.code_name) definition_name,
                   ct.id_cdr_type type_id,
                   pk_translation.get_translation(i_lang, ct.code_cdr_type) type_name,
                   ct.icon type_icon,
                   get_desc_conditions(i_lang, cd.id_cdr_definition) definition_conditions,
                   get_desc_tooltip_def(i_lang, i_prof, cd.id_cdr_definition) definition_tooltip
              FROM cdr_definition cd
              JOIN cdr_type ct
                ON cd.id_cdr_type = ct.id_cdr_type
             WHERE cd.id_institution IN (0, i_prof.institution)
               AND cd.flg_status IN (pk_alert_constant.g_active, pk_cdr_constant.g_edited)
               AND cd.flg_available = pk_alert_constant.g_yes
               AND EXISTS (SELECT 1
                      FROM cdr_def_config cdc
                      JOIN cdr_param_action cpa
                        ON cdc.id_cdr_param_action = cpa.id_cdr_param_action
                      JOIN cdr_parameter cp
                        ON cpa.id_cdr_parameter = cp.id_cdr_parameter
                      JOIN cdr_def_cond cdc1
                        ON cp.id_cdr_def_cond = cdc1.id_cdr_def_cond
                     WHERE cdc1.id_cdr_definition = cd.id_cdr_definition
                       AND cdc.id_institution = i_prof.institution)
             ORDER BY definition_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_rule_list);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_setting_grid_def;

    /**********************************************************************************************
    * Returns the list of conditions for the rule definition
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_condition_list         list of all rule definition
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/04/18
    **********************************************************************************************/
    FUNCTION get_cdr_conditions
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_condition_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ']', g_package, 'GET_CDR_CONDITIONS');
        g_error := 'OPEN o_condition_list';
        OPEN o_condition_list FOR
            SELECT cd.id_cdr_definition, pk_translation.get_translation(i_lang, cd.code_name) name
              FROM cdr_definition cd
             WHERE nvl(cd.id_institution, 0) IN (0, i_prof.institution)
               AND cd.flg_status = pk_alert_constant.g_active
             ORDER BY name;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_condition_list);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_CDR_CONDITIONS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_cdr_conditions;

    /**********************************************************************************************
    * Returns the list of conditions for the rule definition
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_condition_list         list of all rule definition
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/04/18
    **********************************************************************************************/
    FUNCTION get_cdr_definition_concepts
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_definition IN cdr_definition.id_cdr_definition%TYPE,
        o_concepts_list     OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ']',
                              g_package,
                              'GET_CDR_DEFINITION_CONCEPTS');
        g_error := 'OPEN o_condition_list';
        OPEN o_concepts_list FOR
            SELECT cp.id_cdr_parameter,
                   cc.id_cdr_concept,
                   cdc.id_cdr_condition,
                   pk_translation.get_translation(i_lang, cc.code_cdr_concept) desc_concept,
                   cp.rank,
                   NULL message
              FROM cdr_definition cd
              JOIN cdr_def_cond cdc
                ON cd.id_cdr_definition = cdc.id_cdr_definition
              JOIN cdr_parameter cp
                ON cdc.id_cdr_def_cond = cp.id_cdr_def_cond
              JOIN cdr_concept cc
                ON cp.id_cdr_concept = cc.id_cdr_concept
             WHERE cd.id_cdr_definition = i_id_cdr_definition
             ORDER BY cdc.rank;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_concepts_list);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_CDR_DEFINITION_CONCEPTS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_cdr_definition_concepts;

    /**********************************************************************************************
    * Returns the list all rule instances, or all rule instances for a given rule definition, when 
    * the parameter i_id_rule_definiton is NOT NULL.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_cdr_definition     ID rule definition
    * @param o_rule_inst_list         list of all rule instances
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/04/27
    **********************************************************************************************/
    FUNCTION get_cdr_instances
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_definition IN cdr_definition.id_cdr_definition%TYPE,
        o_cdr_inst          OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ']', g_package, 'GET_CDR_INSTANCES');
        --
        g_error := 'OPEN CURSOR o_rule_inst_list';
        OPEN o_cdr_inst FOR
            SELECT ci.id_cdr_instance,
                   ci.id_cdr_definition,
                   pk_translation.get_translation(i_lang, cd.code_name) instance_name,
                   get_cdr_instances_desc(i_lang, i_prof, ci.id_cdr_instance) desc_instances
              FROM cdr_instance ci
              JOIN cdr_definition cd
                ON (ci.id_cdr_definition = cd.id_cdr_definition)
              JOIN cdr_type ct
                ON (cd.id_cdr_type = ct.id_cdr_type)
             WHERE (i_id_cdr_definition IS NULL OR i_id_cdr_definition = cd.id_cdr_definition)
               AND nvl(ci.id_institution, 0) IN (0, i_prof.institution)
             ORDER BY instance_name DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_cdr_inst);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_CDR_INSTANCES',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_cdr_instances;

    /**********************************************************************************************
    * Returns the list of definition rules from a determine type
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_cdr_type            Id type of cdr
    * @param o_def_list               list of definitions
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/04/27
    **********************************************************************************************/
    FUNCTION get_setting_select_def_by_type
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_cdr_type IN cdr_type.id_cdr_type%TYPE,
        o_def_list    OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_SETTING_SELECT_DEF_BY_TYPE';
    BEGIN
    
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ' i_id_cdr_type:' || i_id_cdr_type || ']',
                              g_package,
                              l_func_name);
    
        --
        g_error := 'OPEN o_def_list';
        OPEN o_def_list FOR
            SELECT cr.id_cdr_definition definition_id,
                   pk_translation.get_translation(i_lang, cr.code_name) definition_name,
                   get_desc_conditions(i_lang, cr.id_cdr_definition) definition_conditions,
                   get_desc_tooltip_def(i_lang, i_prof, cr.id_cdr_definition) definition_tooltip
              FROM cdr_definition cr
             WHERE cr.id_institution IN (0, i_prof.institution)
               AND cr.flg_status IN (pk_alert_constant.g_active, pk_cdr_constant.g_edited)
               AND cr.flg_available = pk_alert_constant.g_yes
               AND cr.id_cdr_type = i_id_cdr_type
               AND NOT EXISTS (SELECT 1
                      FROM cdr_def_config cdc
                      JOIN cdr_param_action cpa
                        ON cdc.id_cdr_param_action = cpa.id_cdr_param_action
                      JOIN cdr_parameter cp
                        ON cpa.id_cdr_parameter = cp.id_cdr_parameter
                      JOIN cdr_def_cond cdc1
                        ON cp.id_cdr_def_cond = cdc1.id_cdr_def_cond
                     WHERE cdc1.id_cdr_definition = cr.id_cdr_definition
                       AND cdc.id_institution = i_prof.institution)
             ORDER BY definition_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => l_func_name,
                                                     o_error    => o_error);
    END get_setting_select_def_by_type;

    /**********************************************************************************************
    * Returns the list of dep_clin_serv by department and service.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_dept                   department identifier
    * @param i_department             service identifier
    * @param o_list                   list of dep_clin_serv available
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/05/05
    **********************************************************************************************/
    FUNCTION get_list_specialty
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_dept       IN dept.id_dept%TYPE,
        i_department IN department.id_department%TYPE,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_LIST_SPECIALTY';
    BEGIN
        g_error := 'i_prof.institution: ' || i_prof.institution;
        g_error := g_error || ', i_dept: ' || i_dept;
        g_error := g_error || ', i_department: ' || i_department;
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'OPEN o_list';
        OPEN o_list FOR
            SELECT s.specialty_id, s.specialty_name
              FROM (SELECT dcs.id_dep_clin_serv specialty_id,
                           pk_translation.get_translation(i_lang, cs.code_clinical_service) specialty_name
                      FROM dep_clin_serv dcs
                      JOIN clinical_service cs
                        ON dcs.id_clinical_service = cs.id_clinical_service
                      JOIN department d
                        ON d.id_department = dcs.id_department
                     WHERE cs.flg_available = pk_alert_constant.g_available
                       AND dcs.flg_available = pk_alert_constant.g_available
                       AND d.flg_available = pk_alert_constant.g_available
                       AND d.id_institution = i_prof.institution
                       AND d.id_department = i_department
                       AND d.id_dept = i_dept) s
             WHERE s.specialty_name IS NOT NULL
             ORDER BY s.specialty_name;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => l_func_name,
                                                     o_error    => o_error);
    END get_list_specialty;

    /**********************************************************************************************
    * Get list of profiles.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_software               table with software 
    * @param o_list                   list of profiles
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/04/29
    **********************************************************************************************/
    FUNCTION get_list_profile
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_software IN table_number,
        o_templ    OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_LIST_PROFILE';
        l_count    PLS_INTEGER;
        l_profiles PLS_INTEGER := 0;
        l_market   market.id_market%TYPE;
    BEGIN
    
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ' i_software:' ||
                              pk_utils.concat_table(i_tab => i_software) || ']',
                              g_package,
                              l_func_name);
    
        g_error := 'COUNT PROFILES ON INSTITUTION';
        SELECT COUNT(pti.id_profile_template)
          INTO l_profiles
          FROM profile_template_inst pti
         WHERE pti.id_institution = i_prof.institution;
    
        l_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
        l_count  := nvl(cardinality(i_software), 0);
    
        IF l_count > 1
        THEN
            -- if the user selected more than one software, return no profiles!
            -- there are no profiles that can be shared between softwares
            pk_types.open_my_cursor(i_cursor => o_templ);
        ELSE
            g_error := 'OPEN o_templ - l_profiles: ' || l_profiles;
            IF l_profiles = 0 -- NO PROFILES ON INSTITUTION
            THEN
                OPEN o_templ FOR
                    SELECT DISTINCT pt.id_profile_template profile_id,
                                    pk_string_utils.strip_html_tags(pk_translation.get_translation(i_lang,
                                                                                                   s.code_software)) ||
                                    ' - ' ||
                                    decode(ptm.id_market,
                                           0,
                                           pk_message.get_message(i_lang, pt.code_profile_template),
                                           pk_message.get_message(i_lang, pt.code_profile_template) || ' (' ||
                                           pk_utils.query_to_string('SELECT pk_translation.get_translation(' || i_lang ||
                                                                    ', m.code_market) 
                               FROM market m WHERE m.id_market =' ||
                                                                    ptm.id_market || '',
                                                                    ',') || ')') profile_name
                      FROM profile_template pt
                      JOIN profile_template_inst pti
                        ON pt.id_profile_template = pti.id_profile_template
                      JOIN profile_template_market ptm
                        ON pti.id_profile_template = ptm.id_profile_template
                      JOIN TABLE(i_software) tt
                        ON (tt.column_value = pt.id_software)
                      JOIN software s
                        ON pt.id_software = s.id_software
                      JOIN profile_template_category ptc
                        ON pt.id_profile_template = ptc.id_profile_template
                      JOIN category c
                        ON ptc.id_category = c.id_category
                     WHERE pt.flg_available = pk_alert_constant.g_available
                       AND pti.id_institution = 0
                       AND ptm.id_market IN (0, l_market)
                       AND c.flg_clinical = pk_alert_constant.g_yes
                    UNION ALL
                    SELECT DISTINCT pt.id_profile_template profile_id,
                                    pk_string_utils.strip_html_tags(pk_translation.get_translation(i_lang,
                                                                                                   s.code_software)) ||
                                    ' - ' ||
                                    decode(ptm.id_market,
                                           0,
                                           pk_message.get_message(i_lang, pt.code_profile_template),
                                           pk_message.get_message(i_lang, pt.code_profile_template) || ' (' ||
                                           pk_utils.query_to_string('SELECT pk_translation.get_translation(' || i_lang ||
                                                                    ', m.code_market) 
                               FROM market m WHERE m.id_market =' ||
                                                                    ptm.id_market || '',
                                                                    ',') || ')') profile_name
                      FROM profile_template pt
                      JOIN profile_template_inst pti
                        ON pt.id_profile_template = pti.id_profile_template
                      JOIN profile_template_market ptm
                        ON pti.id_profile_template = ptm.id_profile_template
                      JOIN software s
                        ON pt.id_software = s.id_software
                      JOIN profile_template_category ptc
                        ON pt.id_profile_template = ptc.id_profile_template
                      JOIN category c
                        ON ptc.id_category = c.id_category
                     WHERE pt.flg_available = pk_alert_constant.g_available
                       AND pti.id_institution = 0
                       AND ptm.id_market IN (0, l_market)
                       AND s.flg_viewer = pk_alert_constant.g_no
                       AND c.flg_clinical = pk_alert_constant.g_yes
                       AND l_count = 0
                     ORDER BY 2;
            ELSE
                OPEN o_templ FOR
                    SELECT DISTINCT pt.id_profile_template profile_id,
                                    decode(ptm.id_market,
                                           0,
                                           pk_message.get_message(i_lang, pt.code_profile_template),
                                           pk_message.get_message(i_lang, pt.code_profile_template) || ' (' ||
                                           pk_utils.query_to_string('SELECT pk_translation.get_translation(' || i_lang ||
                                                                    ', m.code_market) 
                               FROM market m WHERE m.id_market =' ||
                                                                    ptm.id_market || '',
                                                                    ',') || ')') profile_name
                      FROM profile_template pt
                      JOIN profile_template_inst pti
                        ON pt.id_profile_template = pti.id_profile_template
                      JOIN profile_template_market ptm
                        ON pti.id_profile_template = ptm.id_profile_template
                      JOIN TABLE(CAST(i_software AS table_number)) tt
                        ON (tt.column_value = pt.id_software)
                      JOIN profile_template_category ptc
                        ON pt.id_profile_template = ptc.id_profile_template
                      JOIN category c
                        ON ptc.id_category = c.id_category
                     WHERE pt.flg_available = pk_alert_constant.g_available
                       AND pti.id_institution = i_prof.institution
                       AND ptm.id_market IN (0, l_market)
                       AND c.flg_clinical = pk_alert_constant.g_yes
                    UNION ALL
                    SELECT DISTINCT pt.id_profile_template profile_id,
                                    decode(ptm.id_market,
                                           0,
                                           pk_message.get_message(i_lang, pt.code_profile_template),
                                           pk_message.get_message(i_lang, pt.code_profile_template) || ' (' ||
                                           pk_utils.query_to_string('SELECT pk_translation.get_translation(' || i_lang ||
                                                                    ', m.code_market) 
                               FROM market m WHERE m.id_market =' ||
                                                                    ptm.id_market || '',
                                                                    ',') || ')') profile_name
                      FROM profile_template pt
                      JOIN profile_template_inst pti
                        ON pt.id_profile_template = pti.id_profile_template
                      JOIN profile_template_market ptm
                        ON pti.id_profile_template = ptm.id_profile_template
                      JOIN software s
                        ON pt.id_software = s.id_software
                      JOIN profile_template_category ptc
                        ON pt.id_profile_template = ptc.id_profile_template
                      JOIN category c
                        ON ptc.id_category = c.id_category
                     WHERE pt.flg_available = pk_alert_constant.g_available
                       AND pti.id_institution = i_prof.institution
                       AND ptm.id_market IN (0, l_market)
                       AND s.flg_viewer = pk_alert_constant.g_no
                       AND c.flg_clinical = pk_alert_constant.g_yes
                       AND l_count = 0
                     ORDER BY 2;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_types.open_my_cursor(o_templ);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_list_profile;

    /**********************************************************************************************
    * Get list of professionals.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_software               table with software 
    * @param i_dep_clin_serv          table with dep_clin_serv 
    * @param i_profile_template       table with profile_template 
    * @param o_list                   list of professionals
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/04/29
    **********************************************************************************************/
    FUNCTION get_list_professional
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_software         IN table_number,
        i_dep_clin_serv    IN table_number,
        i_profile_template IN table_number,
        o_list             OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_LIST_PROFESSIONAL';
        l_soft_count PLS_INTEGER;
        l_dcs_count  PLS_INTEGER;
        l_pt_count   PLS_INTEGER;
    BEGIN
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ' i_software:' ||
                              pk_utils.concat_table(i_tab => i_software) || ' i_dep_clin_serv:' ||
                              pk_utils.concat_table(i_tab => i_dep_clin_serv) || ' i_profile_template:' ||
                              pk_utils.concat_table(i_tab => i_profile_template) || ']',
                              g_package,
                              l_func_name);
    
        l_soft_count := nvl(cardinality(i_software), 0);
        l_dcs_count  := nvl(cardinality(i_dep_clin_serv), 0);
        l_pt_count   := nvl(cardinality(i_profile_template), 0);
    
        g_error := 'OPEN o_list';
        OPEN o_list FOR
            SELECT p.id_professional professional_id,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) professional_name
              FROM (SELECT DISTINCT p.id_professional
                      FROM prof_institution pi
                      JOIN professional p
                        ON pi.id_professional = p.id_professional
                      JOIN prof_profile_template ppt
                        ON p.id_professional = ppt.id_professional
                      JOIN prof_dep_clin_serv pdcs
                        ON p.id_professional = pdcs.id_professional
                     WHERE pi.flg_state = pk_alert_constant.g_active
                       AND pi.id_institution = i_prof.institution
                       AND nvl(p.flg_prof_test, pk_alert_constant.g_no) = pk_alert_constant.g_no
                       AND ppt.id_institution = i_prof.institution
                       AND (ppt.id_profile_template IN (SELECT /*+dynamic_sampling(t 2)*/
                                                         t.column_value id_profile_template
                                                          FROM TABLE(i_profile_template) t) OR l_pt_count = 0)
                       AND (ppt.id_software IN (SELECT /*+dynamic_sampling(t 2)*/
                                                 t.column_value id_software
                                                  FROM TABLE(i_software) t) OR l_soft_count = 0)
                       AND (pdcs.id_dep_clin_serv IN (SELECT /*+dynamic_sampling(t 2)*/
                                                       t.column_value id_dep_clin_serv
                                                        FROM TABLE(i_dep_clin_serv) t) OR l_dcs_count = 0)) p
             ORDER BY professional_name;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_list_professional;

    /**********************************************************************************************
    * Returns the list of all cdr instance exceptions
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_cdr_instance        Id cdr instance
    * @param o_cdr_inst_exception     list of all rule instances exceptions
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/05/02
    **********************************************************************************************/
    FUNCTION get_cdr_inst_exception
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_cdr_instance    IN cdr_instance.id_cdr_instance%TYPE,
        o_cdr_inst_exception OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_none sys_message.desc_message%TYPE;
    
    BEGIN
    
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ' i_id_cdr_instance:' ||
                              i_id_cdr_instance || ']',
                              g_package,
                              'GET_CDR_INST_EXCEPTION');
    
        g_error := 'GET_MESSAGE';
        l_none  := pk_message.get_message(i_lang, 'CDR_T054');
    
        g_error := 'OPEN o_cdr_inst_exception';
        OPEN o_cdr_inst_exception FOR
            SELECT cic.id_cdr_inst_config,
                   decode(s.id_software,
                          pk_alert_constant.g_soft_all,
                          l_none,
                          pk_string_utils.strip_html_tags(pk_translation.get_translation(i_lang, s.code_software))) desc_software,
                   decode(cic.id_dep_clin_serv,
                          -1,
                          l_none,
                          pk_translation.get_translation(i_lang, cse.code_clinical_service)) desc_speciality,
                   decode(pt.id_profile_template, 0, l_none, pk_message.get_message(i_lang, pt.code_profile_template)) desc_profile,
                   decode(cic.id_professional,
                          -1,
                          l_none,
                          pk_prof_utils.get_name_signature(i_lang,
                                                           profissional(cic.id_professional, NULL, NULL),
                                                           cic.id_professional)) prof_name,
                   pk_translation.get_translation(i_lang, cs.code_cdr_severity) desc_severity,
                   pk_translation.get_translation(i_lang, ca.code_cdr_action) desc_action
              FROM cdr_inst_config cic
              JOIN software s
                ON cic.id_software = s.id_software
              JOIN profile_template pt
                ON cic.id_profile_template = pt.id_profile_template
              JOIN dep_clin_serv dcs
                ON cic.id_dep_clin_serv = dcs.id_dep_clin_serv
              JOIN clinical_service cse
                ON dcs.id_clinical_service = cse.id_clinical_service
              JOIN cdr_inst_par_action cipa
                ON cic.id_cdr_inst_par_action = cipa.id_cdr_inst_par_action
              JOIN cdr_inst_param cip
                ON cipa.id_cdr_inst_param = cip.id_cdr_inst_param
              JOIN cdr_instance ci
                ON cip.id_cdr_instance = ci.id_cdr_instance
              JOIN cdr_severity cs
                ON ci.id_cdr_severity = cs.id_cdr_severity
              JOIN cdr_action ca
                ON cipa.id_cdr_action = ca.id_cdr_action
             WHERE ci.id_cdr_instance = i_id_cdr_instance
               AND nvl(cic.id_institution, 0) IN (0, i_prof.institution);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_types.open_my_cursor(o_cdr_inst_exception);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_CDR_INST_EXCEPTION',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_cdr_inst_exception;

    /**********************************************************************************************
    * Get list of exceptions for the settings summary screen.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_definition             Id cdr definition
    * @param o_exception              list of all rule instances exceptions
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/05/02
    **********************************************************************************************/
    FUNCTION get_setting_summary_def
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_definition IN cdr_definition.id_cdr_definition%TYPE,
        o_exception  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_SETTING_SUMMARY_DEF';
        l_none sys_message.desc_message%TYPE;
    
    BEGIN
    
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ' i_definition:' || i_definition || ']',
                              g_package,
                              l_func_name);
    
        g_error := 'GET_MESSAGE';
        l_none  := pk_message.get_message(i_lang, i_prof, 'CDR_T054');
    
        g_error := 'OPEN o_exception';
    
        OPEN o_exception FOR
            SELECT e.id_software software_id,
                   decode(e.id_software,
                          pk_alert_constant.g_soft_all,
                          l_none,
                          pk_string_utils.strip_html_tags(pk_translation.get_translation(i_lang, e.code_software))) software_name,
                   e.id_dep_clin_serv specialty_id,
                   decode(e.id_dep_clin_serv,
                          -1,
                          l_none,
                          pk_translation.get_translation(i_lang, e.code_clinical_service)) specialty_name,
                   e.id_profile_template profile_id,
                   decode(e.id_profile_template, 0, l_none, pk_message.get_message(i_lang, e.code_profile_template)) profile_name,
                   e.id_professional professional_id,
                   decode(e.id_professional,
                          -1,
                          l_none,
                          pk_prof_utils.get_name_signature(i_lang, i_prof, e.id_professional)) professional_name,
                   e.id_cdr_def_severity severity_id,
                   decode(e.id_cdr_severity,
                          pk_cdr_constant.g_cdrs_not_applicable,
                          l_none,
                          pk_translation.get_translation(i_lang, e.code_cdr_severity)) severity_name,
                   e.id_cdr_action action_id,
                   pk_translation.get_translation(i_lang, e.code_cdr_action) action_name
              FROM (SELECT DISTINCT cdc.id_software,
                                    s.code_software,
                                    cdc.id_dep_clin_serv,
                                    cse.code_clinical_service,
                                    cdc.id_profile_template,
                                    pt.code_profile_template,
                                    cdc.id_professional,
                                    cds.id_cdr_def_severity,
                                    cds.id_cdr_severity,
                                    cs.code_cdr_severity,
                                    cpa.id_cdr_action,
                                    ca.code_cdr_action,
                                    cdc.update_time
                      FROM cdr_def_config cdc
                      JOIN cdr_param_action cpa
                        ON cdc.id_cdr_param_action = cpa.id_cdr_param_action
                      JOIN cdr_def_severity cds
                        ON cdc.id_cdr_def_severity = cds.id_cdr_def_severity
                      JOIN cdr_severity cs
                        ON cds.id_cdr_severity = cs.id_cdr_severity
                      JOIN cdr_action ca
                        ON cpa.id_cdr_action = ca.id_cdr_action
                      JOIN cdr_parameter cp
                        ON cpa.id_cdr_parameter = cp.id_cdr_parameter
                      JOIN cdr_def_cond cdcc
                        ON cp.id_cdr_def_cond = cdcc.id_cdr_def_cond
                      JOIN software s
                        ON cdc.id_software = s.id_software
                      JOIN profile_template pt
                        ON cdc.id_profile_template = pt.id_profile_template
                      JOIN dep_clin_serv dcs
                        ON cdc.id_dep_clin_serv = dcs.id_dep_clin_serv
                      JOIN clinical_service cse
                        ON dcs.id_clinical_service = cse.id_clinical_service
                     WHERE cdcc.id_cdr_definition = i_definition
                       AND cdc.id_institution = i_prof.institution) e
             ORDER BY e.update_time;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => l_func_name,
                                                     o_error    => o_error);
    END get_setting_summary_def;

    /**
    * Get list of exceptions for the settings summary screen,
    * through user setting defined lists.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_definition   rule definition identifier
    * @param i_software     software identifiers list
    * @param i_specialty    specialty identifiers list
    * @param i_profile      profile identifiers list
    * @param i_professional professional identifiers list
    * @param i_severity     severity identifiers list
    * @param i_action       action identifiers list
    * @param i_e_soft       exception software identifiers list
    * @param i_e_spec       exception specialty identifiers list
    * @param i_e_pt         exception profile identifiers list
    * @param i_e_prof       exception professional identifiers list
    * @param i_e_cdrs       exception severity identifiers list
    * @param i_e_cdra       exception action identifiers list
    * @param o_exception    cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2011/10/25
    */
    FUNCTION get_setting_summary_def_coll
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_definition   IN cdr_definition.id_cdr_definition%TYPE,
        i_software     IN table_number,
        i_specialty    IN table_number,
        i_profile      IN table_number,
        i_professional IN table_number,
        i_severity     IN table_number,
        i_action       IN table_number,
        i_e_soft       IN table_number,
        i_e_spec       IN table_number,
        i_e_pt         IN table_number,
        i_e_prof       IN table_number,
        i_e_cdrs       IN table_number,
        i_e_cdra       IN table_number,
        o_exception    OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_SETTING_SUMMARY_DEF_COLL';
        l_none         sys_message.desc_message%TYPE;
        l_software     table_number;
        l_specialty    table_number;
        l_profile      table_number;
        l_professional table_number;
        l_severity     table_number;
    BEGIN
        g_error := 'GET_MESSAGE';
        l_none  := pk_message.get_message(i_lang, i_prof, 'CDR_T054');
    
        -- set local settings collections
        l_software     := get_default_tn(i_tn => i_software, i_def => pk_alert_constant.g_soft_all);
        l_specialty    := get_default_tn(i_tn => i_specialty, i_def => -1);
        l_profile      := get_default_tn(i_tn => i_profile, i_def => 0);
        l_professional := get_default_tn(i_tn => i_professional, i_def => -1);
    
        -- get definition severity identifiers
        IF i_severity IS NULL
           OR i_severity.count < 1
        THEN
            g_error := 'SELECT l_severity (n/a)';
            SELECT cdrds.id_cdr_def_severity
              BULK COLLECT
              INTO l_severity
              FROM cdr_def_severity cdrds
             WHERE cdrds.id_cdr_definition = i_definition
               AND cdrds.id_cdr_severity = pk_cdr_constant.g_cdrs_not_applicable;
        ELSE
            l_severity := i_severity;
        END IF;
    
        g_error := 'OPEN o_exception';
        OPEN o_exception FOR
            SELECT s.id_software software_id,
                   decode(s.id_software,
                          pk_alert_constant.g_soft_all,
                          l_none,
                          pk_string_utils.strip_html_tags(pk_translation.get_translation(i_lang, s.code_software))) software_name,
                   dcs.id_dep_clin_serv specialty_id,
                   decode(dcs.id_dep_clin_serv,
                          -1,
                          l_none,
                          pk_translation.get_translation(i_lang, cs.code_clinical_service)) specialty_name,
                   pt.id_profile_template profile_id,
                   decode(pt.id_profile_template, 0, l_none, pk_message.get_message(i_lang, pt.code_profile_template)) profile_name,
                   dt.id_professional professional_id,
                   decode(dt.id_professional,
                          -1,
                          l_none,
                          pk_prof_utils.get_name_signature(i_lang, i_prof, dt.id_professional)) professional_name,
                   cdrds.id_cdr_def_severity severity_id,
                   decode(cdrs.id_cdr_severity,
                          pk_cdr_constant.g_cdrs_not_applicable,
                          l_none,
                          pk_translation.get_translation(i_lang, cdrs.code_cdr_severity)) severity_name,
                   cdra.id_cdr_action action_id,
                   pk_translation.get_translation(i_lang, cdra.code_cdr_action) action_name
              FROM ( -- exceptions from edit screen
                    SELECT s.id_software,
                            dcs.id_dep_clin_serv,
                            pt.id_profile_template,
                            p.id_professional,
                            cdrds.id_cdr_def_severity,
                            cdra.id_cdr_action
                      FROM (SELECT /*+dynamic_sampling(t 2)*/
                              t.column_value id_software
                               FROM TABLE(l_software) t) s,
                            (SELECT /*+dynamic_sampling(t 2)*/
                              t.column_value id_dep_clin_serv
                               FROM TABLE(l_specialty) t) dcs,
                            (SELECT /*+dynamic_sampling(t 2)*/
                              t.column_value id_profile_template
                               FROM TABLE(l_profile) t) pt,
                            (SELECT /*+dynamic_sampling(t 2)*/
                              t.column_value id_professional
                               FROM TABLE(l_professional) t) p,
                            (SELECT /*+dynamic_sampling(t 2)*/
                              t.column_value id_cdr_def_severity
                               FROM TABLE(l_severity) t) cdrds,
                            (SELECT /*+dynamic_sampling(t 2)*/
                              t.column_value id_cdr_action
                               FROM TABLE(i_action) t) cdra
                    UNION
                    -- exceptions that are already registered
                    SELECT soft.id_software,
                            dcs.id_dep_clin_serv,
                            pt.id_profile_template,
                            prof.id_professional,
                            s.id_cdr_def_severity,
                            ca.id_cdr_action
                      FROM (SELECT /*+dynamic_sampling(t 2)*/
                              t.column_value id_software, rownum rn
                               FROM TABLE(i_e_soft) t) soft
                      JOIN (SELECT /*+dynamic_sampling(t 2)*/
                             t.column_value id_profile_template, rownum rn
                              FROM TABLE(i_e_pt) t) pt
                        ON soft.rn = pt.rn
                      JOIN (SELECT /*+dynamic_sampling(t 2)*/
                             t.column_value id_dep_clin_serv, rownum rn
                              FROM TABLE(i_e_spec) t) dcs
                        ON soft.rn = dcs.rn
                      JOIN (SELECT /*+dynamic_sampling(t 2)*/
                             t.column_value id_professional, rownum rn
                              FROM TABLE(i_e_prof) t) prof
                        ON soft.rn = prof.rn
                      JOIN (SELECT /*+dynamic_sampling(t 2)*/
                             t.column_value id_cdr_action, rownum rn
                              FROM TABLE(i_e_cdra) t) ca
                        ON soft.rn = ca.rn
                      JOIN (SELECT /*+dynamic_sampling(t 2)*/
                             t.column_value id_cdr_def_severity, rownum rn
                              FROM TABLE(i_e_cdrs) t) s
                        ON soft.rn = s.rn) dt
              JOIN software s
                ON dt.id_software = s.id_software
              JOIN dep_clin_serv dcs
                ON dt.id_dep_clin_serv = dcs.id_dep_clin_serv
              JOIN clinical_service cs
                ON dcs.id_clinical_service = cs.id_clinical_service
              JOIN profile_template pt
                ON dt.id_profile_template = pt.id_profile_template
              JOIN cdr_def_severity cdrds
                ON dt.id_cdr_def_severity = cdrds.id_cdr_def_severity
              JOIN cdr_severity cdrs
                ON cdrds.id_cdr_severity = cdrs.id_cdr_severity
              JOIN cdr_action cdra
                ON dt.id_cdr_action = cdra.id_cdr_action;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => l_func_name,
                                                     o_error    => o_error);
    END get_setting_summary_def_coll;

    /**********************************************************************************************
    * Returns the expections defined for an instance
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_cdr_instance        Id cdr instance
    * @param o_cdr_labels             list of all labels used on screen
    * @param o_software               list of software exceptions
    * @param o_profile                list of profile templates exceptions
    * @param o_dep_clin_serv          list of dep_clin_serv exceptions
    * @param o_professional           list of professionals exceptions
    * @param o_action                 list os distinct action of instance                  
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/05/02
    **********************************************************************************************/

    FUNCTION get_edit_cdr_inst_exception
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_cdr_instance IN cdr_instance.id_cdr_instance%TYPE,
        o_cdr_labels      OUT pk_types.cursor_type,
        o_software        OUT pk_types.cursor_type,
        o_profile         OUT pk_types.cursor_type,
        o_dep_clin_serv   OUT pk_types.cursor_type,
        o_professional    OUT pk_types.cursor_type,
        o_action          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ' i_id_cdr_instance:' ||
                              i_id_cdr_instance || ']',
                              g_package,
                              'GET_CDR_DEF_EXCEPTION');
    
        g_error := 'OPEN o_cdr_labels';
        OPEN o_cdr_labels FOR
            SELECT pk_message.get_message(i_lang, i_prof, 'CDR_T058') screen_header,
                   pk_message.get_message(i_lang, i_prof, 'CDR_T056') screen_subtitle,
                   pk_message.get_message(i_lang, i_prof, 'CDR_T012') software,
                   pk_message.get_message(i_lang, i_prof, 'CDR_T013') speciality,
                   pk_message.get_message(i_lang, i_prof, 'CDR_T014') category,
                   pk_message.get_message(i_lang, i_prof, 'CDR_T015') professional,
                   pk_message.get_message(i_lang, i_prof, 'CDR_T049') severity,
                   pk_message.get_message(i_lang, i_prof, 'CDR_T045') action,
                   pk_message.get_message(i_lang, i_prof, 'CDR_T054') none
              FROM dual;
    
        g_error := 'OPEN o_software';
        OPEN o_software FOR
            SELECT s.id_software software_id,
                   pk_string_utils.strip_html_tags(pk_translation.get_translation(i_lang, s.code_software)) software_name
              FROM (SELECT DISTINCT s.id_software, s.code_software
                      FROM cdr_inst_config cic
                      JOIN cdr_inst_par_action cipa
                        ON cic.id_cdr_inst_par_action = cipa.id_cdr_inst_par_action
                      JOIN cdr_inst_param cip
                        ON cipa.id_cdr_inst_param = cip.id_cdr_inst_param
                      JOIN software s
                        ON cic.id_software = s.id_software
                     WHERE cip.id_cdr_instance = i_id_cdr_instance
                       AND cic.id_institution = i_prof.institution
                       AND cic.id_software > 0) s;
    
        g_error := 'OPEN o_profile';
        OPEN o_profile FOR
            SELECT pt.id_profile_template profile_id,
                   pk_message.get_message(i_lang, pt.code_profile_template) profile_name
              FROM (SELECT DISTINCT pt.id_profile_template, pt.code_profile_template
                      FROM cdr_inst_config cic
                      JOIN cdr_inst_par_action cipa
                        ON cic.id_cdr_inst_par_action = cipa.id_cdr_inst_par_action
                      JOIN cdr_inst_param cip
                        ON cipa.id_cdr_inst_param = cip.id_cdr_inst_param
                      JOIN profile_template pt
                        ON cic.id_profile_template = pt.id_profile_template
                     WHERE cip.id_cdr_instance = i_id_cdr_instance
                       AND cic.id_institution = i_prof.institution
                       AND cic.id_profile_template > 0) pt;
    
        g_error := 'OPEN o_dep_clin_serv';
        OPEN o_dep_clin_serv FOR
            SELECT DISTINCT cic.id_dep_clin_serv id_dep_clin_serv,
                            pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_speciality
              FROM cdr_inst_config cic
              JOIN cdr_inst_par_action cipa
                ON cic.id_cdr_inst_par_action = cipa.id_cdr_inst_par_action
              JOIN cdr_inst_param cip
                ON cipa.id_cdr_inst_param = cip.id_cdr_inst_param
              JOIN dep_clin_serv dcs
                ON cic.id_dep_clin_serv = dcs.id_dep_clin_serv
              JOIN clinical_service cs
                ON dcs.id_clinical_service = cs.id_clinical_service
             WHERE cip.id_cdr_instance = i_id_cdr_instance
               AND cic.id_institution = i_prof.institution
               AND cic.id_dep_clin_serv <> -1;
    
        g_error := 'OPEN o_professional';
        OPEN o_professional FOR
            SELECT p.id_professional professional_id,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) professional_name
              FROM (SELECT DISTINCT cic.id_professional
                      FROM cdr_inst_config cic
                      JOIN cdr_inst_par_action cipa
                        ON cic.id_cdr_inst_par_action = cipa.id_cdr_inst_par_action
                      JOIN cdr_inst_param cip
                        ON cipa.id_cdr_inst_param = cip.id_cdr_inst_param
                     WHERE cip.id_cdr_instance = i_id_cdr_instance
                       AND cic.id_institution = i_prof.institution
                       AND cic.id_professional > 0) p;
    
        g_error := 'OPEN o_action';
        OPEN o_action FOR
            SELECT a.id_cdr_action action_id, pk_translation.get_translation(i_lang, a.code_cdr_action) action_name
              FROM (SELECT DISTINCT ca.id_cdr_action, ca.code_cdr_action
                      FROM cdr_instance ci
                      JOIN cdr_inst_param cip
                        ON ci.id_cdr_instance = cip.id_cdr_instance
                      JOIN cdr_inst_par_action cipa
                        ON cip.id_cdr_inst_param = cipa.id_cdr_inst_param
                      JOIN cdr_action ca
                        ON cipa.id_cdr_action = ca.id_cdr_action
                      JOIN cdr_inst_config cic
                        ON cipa.id_cdr_inst_par_action = cic.id_cdr_inst_par_action
                     WHERE ci.id_cdr_instance = i_id_cdr_instance
                       AND cic.id_institution = i_prof.institution) a;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_types.open_my_cursor(o_cdr_labels);
            pk_types.open_my_cursor(o_software);
            pk_types.open_my_cursor(o_profile);
            pk_types.open_my_cursor(o_dep_clin_serv);
            pk_types.open_my_cursor(o_professional);
            pk_types.open_my_cursor(o_action);
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'get_edit_cdr_inst_exception',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_edit_cdr_inst_exception;

    /**********************************************************************************************
    * Cancel a instance exception
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_id_cdr_ins_config      ID rule definition
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/05/02
    **********************************************************************************************/

    FUNCTION cancel_cdr_inst_exception
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_ins_config cdr_inst_config.id_cdr_inst_config%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowsid table_varchar;
    BEGIN
    
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ' i_id_cdr_ins_config:' ||
                              i_id_cdr_ins_config || ']',
                              g_package,
                              'cancel_cdr_inst_exception');
    
        g_error := 'CALL ts_cdr_inst_config.del_CDRICF_UK';
        ts_cdr_inst_config.del_cdricf_uk(id_cdr_inst_config_in => i_id_cdr_ins_config, rows_out => l_rowsid);
        g_error := 'PROCESS_DELETE';
        t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'CDR_INST_CONFIG',
                                      i_rowids     => l_rowsid,
                                      o_error      => o_error);
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'CANCEL_CDR_INST_EXCEPTION',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
        
    END cancel_cdr_inst_exception;

    /**********************************************************************************************
    * Cancel a definition exception
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_id_cdr_def_config      ID rule definition exception 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/05/02
    **********************************************************************************************/

    FUNCTION cancel_cdr_def_exception
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_def_config cdr_def_config.id_cdr_def_config%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowsid table_varchar;
    BEGIN
    
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ' i_id_cdr_DEF_config:' ||
                              i_id_cdr_def_config || ']',
                              g_package,
                              'CANCEL_CDR_DEF_EXCEPTION');
    
        g_error := 'CALL ts_cdr_def_config.del_cdrdcf_uk';
        ts_cdr_def_config.del_cdrdcf_uk(id_cdr_def_config_in => i_id_cdr_def_config, rows_out => l_rowsid);
        g_error := 'PROCESS_DELETE';
        t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'CDR_DEF_CONFIG',
                                      i_rowids     => l_rowsid,
                                      o_error      => o_error);
        -- ADD TO HISTORY LOG TABLE                                  
        INSERT INTO cdr_def_config_hist
            (SELECT id_cdr_def_config,
                    id_cdr_def_severity,
                    id_cdr_param_action,
                    id_institution,
                    id_software,
                    id_profile_template,
                    id_dep_clin_serv,
                    id_professional,
                    i_prof.id,
                    SYSDATE,
                    i_prof.institution,
                    i_prof.id,
                    SYSDATE,
                    i_prof.institution,
                    'C'
               FROM cdr_def_config cdrdef
              WHERE cdrdef.id_cdr_def_config = i_id_cdr_def_config);
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'CANCEL_CDR_DEF_EXCEPTION',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END cancel_cdr_def_exception;

    /********************************************************************************************
     * Get list of actions for a specified subject and state.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_subject                Subject
     * @param i_from_state             State
     * @param o_actions                List of actions
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          Elisabete Bugalho
     * @version                         0.1
     * @since                           2011/05/03
    **********************************************************************************************/
    FUNCTION get_cdr_actions
    (
        i_lang      IN language.id_language%TYPE,
        i_subject   IN action.subject%TYPE,
        i_exception IN NUMBER,
        o_actions   OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN o_actions';
        OPEN o_actions FOR
            SELECT a.id_action,
                   a.id_parent,
                   LEVEL, --used to manage the shown' items by Flash
                   a.from_state,
                   a.to_state, --destination state flag
                   a.desc_action, --action's description
                   a.icon, --action's icon
                   decode(a.flg_default, 'D', 'Y', 'N') flg_default, --default action
                   decode(a.internal_name,
                          'CANCEL',
                          decode(i_exception, NULL, pk_alert_constant.g_inactive, a.flg_status),
                          a.flg_status) AS flg_active, --action's state
                   a.internal_name action
              FROM (SELECT a.id_action,
                           pk_message.get_message(i_lang, code_action) desc_action,
                           a.from_state,
                           a.to_state,
                           a.icon,
                           a.flg_status,
                           a.rank,
                           a.flg_default,
                           a.id_parent,
                           a.internal_name
                      FROM action a
                     WHERE a.subject = i_subject) a
            CONNECT BY PRIOR a.id_action = a.id_parent
             START WITH a.id_parent IS NULL
             ORDER BY LEVEL, a.rank, a.desc_action;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_CDR_ACTIONS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
    END get_cdr_actions;

    /**********************************************************************************************
    * Returns the expections defined for an instance
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_cdr_instance        Id cdr instance
    * @param i_software               list of software exceptions
    * @param i_profile                list of profile templates exceptions
    * @param i_dep_clin_serv          list of dep_clin_serv exceptions
    * @param i_professional           list of professionals exceptions
    * @param i_action                 list os distinct action of instance                  
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/05/06
    **********************************************************************************************/

    FUNCTION set_cdr_inst_exception
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_cdr_instance IN cdr_instance.id_cdr_instance%TYPE,
        i_software        IN table_number,
        i_profile         IN table_number,
        i_dep_clin_serv   IN table_number,
        i_professional    IN table_number,
        i_action          IN table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows                 table_varchar;
        l_t_rec_cdr_ins_config t_rec_cdr_ins_config;
        l_id_inst_par_action   table_number;
        l_id_cdr_inst_config   cdr_inst_config.id_cdr_inst_config%TYPE;
    BEGIN
    
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ' i_id_cdr_instance:' ||
                              i_id_cdr_instance || ']',
                              g_package,
                              'set_cdr_inst_exception');
    
        -- remove existing exceptions
        ts_cdr_inst_config.del_by(where_clause_in => 'id_institution = ' || i_prof.institution || '
   AND id_cdr_inst_par_action IN (SELECT cipa.id_cdr_inst_par_action
                                    FROM cdr_inst_par_action cipa
                                    JOIN cdr_inst_param cip
                                      ON cipa.id_cdr_inst_param = cip.id_cdr_inst_param
                                   WHERE cip.id_cdr_instance = ' ||
                                                     i_id_cdr_instance || ')',
                                  rows_out        => l_rows);
    
        SELECT cipa.id_cdr_inst_par_action
          BULK COLLECT
          INTO l_id_inst_par_action
          FROM cdr_inst_param cip
          JOIN cdr_inst_par_action cipa
            ON cip.id_cdr_inst_param = cipa.id_cdr_inst_param
         WHERE cip.id_cdr_instance = i_id_cdr_instance
           AND cipa.id_cdr_action IN (SELECT /*+dynamic_sampling(t 2)*/
                                       column_value id_action
                                        FROM TABLE(i_action));
    
        SELECT id_action, id_software, id_profile, id_dep_clin_serv, id_professional
          BULK COLLECT
          INTO l_t_rec_cdr_ins_config
          FROM (SELECT /*+dynamic_sampling(t 2)*/
                 column_value id_software
                  FROM TABLE(i_software)) soft,
               (SELECT /*+dynamic_sampling(t 2)*/
                 column_value id_profile
                  FROM TABLE(i_profile)) pt,
               (SELECT /*+dynamic_sampling(t 2)*/
                 column_value id_dep_clin_serv
                  FROM TABLE(i_dep_clin_serv)) dcs,
               (SELECT /*+dynamic_sampling(t 2)*/
                 column_value id_professional
                  FROM TABLE(i_professional)) prof,
               (SELECT /*+dynamic_sampling(t 2)*/
                 column_value id_action
                  FROM TABLE(l_id_inst_par_action)) ca;
    
        FOR i IN 1 .. l_t_rec_cdr_ins_config.count
        LOOP
            l_id_cdr_inst_config := seq_cdr_inst_config.nextval;
        
            ts_cdr_inst_config.ins(id_cdr_inst_par_action_in => l_t_rec_cdr_ins_config(i).id_cdr_inst_par_action,
                                   id_institution_in         => i_prof.institution,
                                   id_software_in            => l_t_rec_cdr_ins_config(i).id_software,
                                   id_profile_template_in    => l_t_rec_cdr_ins_config(i).id_profile_template,
                                   id_dep_clin_serv_in       => l_t_rec_cdr_ins_config(i).id_dep_clin_serv,
                                   id_professional_in        => l_t_rec_cdr_ins_config(i).id_professional,
                                   id_cdr_inst_config_in     => l_id_cdr_inst_config,
                                   rows_out                  => l_rows);
        END LOOP;
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'set_cdr_inst_exception',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_cdr_inst_exception;

    /**********************************************************************************************
    * Returns the list of action types available  for a instance
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_warning_type_list      list of action types
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/05/04
    **********************************************************************************************/
    FUNCTION get_cdr_inst_action_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_cdr_instance  IN cdr_instance.id_cdr_instance%TYPE,
        o_action_type_list OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ' i_id_cdr_instance:' ||
                              i_id_cdr_instance || ']',
                              g_package,
                              'GET_CDR_INST_ACTION_LIST');
        --
        g_error := 'OPEN CURSOR o_action_type_list';
        OPEN o_action_type_list FOR
            SELECT DISTINCT ca.id_cdr_action,
                            pk_translation.get_translation(i_lang, ca.code_cdr_action) desc_action,
                            ca.internal_name,
                            ca.rank
              FROM cdr_instance ci
              JOIN cdr_inst_param cip
                ON ci.id_cdr_instance = cip.id_cdr_instance
              JOIN cdr_inst_par_action cipa
                ON cip.id_cdr_inst_param = cipa.id_cdr_inst_param
              JOIN cdr_action ca
                ON cipa.id_cdr_action = ca.id_cdr_action
             WHERE ca.flg_available = pk_alert_constant.g_yes
               AND ci.id_cdr_instance = i_id_cdr_instance
             ORDER BY ca.rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_action_type_list);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_CDR_INST_ACTION_LIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_cdr_inst_action_list;

    /**********************************************************************************************
    * Returns the list of department filtered by a list of software
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_software               table with software 
    * @param o_dept_list              list of department available
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/05/04
    **********************************************************************************************/
    FUNCTION get_list_department
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_software  IN table_number,
        o_dept_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_LIST_DEPARTMENT';
        l_count PLS_INTEGER;
    BEGIN
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ' i_software:' ||
                              pk_utils.concat_table(i_tab => i_software) || ']',
                              g_package,
                              l_func_name);
    
        l_count := nvl(cardinality(i_software), 0);
    
        g_error := 'OPEN o_dept_list';
        OPEN o_dept_list FOR
            SELECT d.id_dept department_id, pk_translation.get_translation(i_lang, d.code_dept) department_name
              FROM dept d
              JOIN software_dept dd
                ON d.id_dept = dd.id_dept
              JOIN TABLE(i_software) tt
                ON (tt.column_value = dd.id_software)
             WHERE d.id_institution = i_prof.institution
               AND d.flg_available = pk_alert_constant.g_available
            UNION ALL
            SELECT d.id_dept department_id, pk_translation.get_translation(i_lang, d.code_dept) department_name
              FROM dept d
             WHERE d.id_institution = i_prof.institution
               AND d.flg_available = pk_alert_constant.g_available
               AND l_count = 0;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => l_func_name,
                                                     o_error    => o_error);
    END get_list_department;

    /**
    * Get list of services by department.
    *
    * @param i_lang         language identifier
    * @param i_dept         department identifier
    * @param o_list         list of services by department
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2011/10/24
    */
    FUNCTION get_list_service
    (
        i_lang  IN language.id_language%TYPE,
        i_dept  IN dept.id_dept%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_LIST_SERVICE';
    BEGIN
        pk_alertlog.log_debug(text => 'i_dept: ' || i_dept, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'OPEN o_list';
        OPEN o_list FOR
            SELECT d.id_department service_id, pk_translation.get_translation(i_lang, d.code_department) service_name
              FROM department d
             WHERE d.id_dept = i_dept
               AND d.flg_available = pk_alert_constant.g_yes
             ORDER BY 2;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => l_func_name,
                                                     o_error    => o_error);
    END get_list_service;

    /**********************************************************************************************
    * Get list of softwares.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_software               list of softwares
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/05/04
    **********************************************************************************************/
    FUNCTION get_list_software
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_software OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_LIST_SOFTWARE';
    BEGIN
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ']', g_package, l_func_name);
    
        g_error := 'OPEN o_software';
        OPEN o_software FOR
            SELECT s.id_software software_id,
                   pk_string_utils.strip_html_tags(pk_translation.get_translation(i_lang, s.code_software)) software_name
              FROM software s
              JOIN software_institution si
                ON s.id_software = si.id_software
             WHERE s.flg_mni = pk_alert_constant.g_available
               AND s.flg_viewer = pk_alert_constant.g_no
               AND s.id_software != pk_alert_constant.g_soft_backoffice
               AND si.id_institution = i_prof.institution
             ORDER BY software_name;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_software);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_list_software;

    /**********************************************************************************************
    * Get list of actions by definition.
    *
    * @param i_lang                   the id language
    * @param i_definition             ID Definition
    * @param o_list                   list of definition actions
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/05/24
    **********************************************************************************************/
    FUNCTION get_list_action_by_def
    (
        i_lang       IN language.id_language%TYPE,
        i_definition IN cdr_definition.id_cdr_definition%TYPE,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_LIST_ACTION_BY_DEF';
    BEGIN
        g_error := 'OPEN o_list';
        OPEN o_list FOR
            SELECT a.id_cdr_action action_id, pk_translation.get_translation(i_lang, a.code_cdr_action) action_name
              FROM (SELECT DISTINCT ca.id_cdr_action, ca.code_cdr_action
                      FROM cdr_def_cond cdc
                      JOIN cdr_parameter cp
                        ON cdc.id_cdr_def_cond = cp.id_cdr_def_cond
                      JOIN cdr_param_action cpa
                        ON cp.id_cdr_parameter = cpa.id_cdr_parameter
                      JOIN cdr_action ca
                        ON cpa.id_cdr_action = ca.id_cdr_action
                     WHERE cdc.id_cdr_definition = i_definition) a
             ORDER BY action_name;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => l_func_name,
                                                     o_error    => o_error);
    END get_list_action_by_def;

    /**
    * Get list of severities by definition.
    *
    * @param i_lang         language identifier
    * @param i_definition   rule definition identifier
    * @param o_list         list of severities by definition
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2011/10/18
    */
    FUNCTION get_list_severity_by_def
    (
        i_lang       IN language.id_language%TYPE,
        i_definition IN cdr_definition.id_cdr_definition%TYPE,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_LIST_SEVERITY_BY_DEF';
    BEGIN
        g_error := 'OPEN o_list';
        OPEN o_list FOR
            SELECT cdrds.id_cdr_def_severity severity_id,
                   pk_translation.get_translation(i_lang, cdrs.code_cdr_severity) severity_name
              FROM cdr_def_severity cdrds
              JOIN cdr_severity cdrs
                ON cdrds.id_cdr_severity = cdrs.id_cdr_severity
             WHERE cdrds.id_cdr_definition = i_definition
               AND cdrs.id_cdr_severity != pk_cdr_constant.g_cdrs_not_applicable
             ORDER BY cdrs.rank DESC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => l_func_name,
                                                     o_error    => o_error);
    END get_list_severity_by_def;

    /**********************************************************************************************
    * Set definition settings.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_definition             Id cdr definition
    * @param i_software               list of software exceptions
    * @param i_profile                list of profile templates exceptions
    * @param i_dep_clin_serv          list of dep_clin_serv exceptions
    * @param i_professional           list of professionals exceptions
    * @param i_severity               instance severity
    * @param i_action                 list os distinct action of instance                  
    * @param o_cdrdcf_ids             created setting identifiers                  
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/05/25
    **********************************************************************************************/
    FUNCTION set_setting_def
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_definition IN cdr_definition.id_cdr_definition%TYPE,
        
        i_software     IN table_number,
        i_specialty    IN table_number,
        i_profile      IN table_number,
        i_professional IN table_number,
        i_severity     IN table_number,
        i_action       IN table_number,
        
        o_cdrdcf_ids OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_SETTING_DEF';
        l_rows        table_varchar;
        l_cdrdcf_row  cdr_def_config%ROWTYPE;
        l_cdrdcf_rows ts_cdr_def_config.cdr_def_config_tc;
        l_cdrdcf_ids  table_number;
    
        CURSOR c_settings IS
            SELECT id_cdr_def_severity,
                   id_cdr_param_action,
                   id_software,
                   id_profile_template,
                   id_dep_clin_serv,
                   id_professional
              FROM (SELECT /*+dynamic_sampling(t 2)*/
                     t.column_value id_software, rownum rn
                      FROM TABLE(i_software) t) soft
              JOIN (SELECT /*+dynamic_sampling(t 2)*/
                     t.column_value id_profile_template, rownum rn
                      FROM TABLE(i_profile) t) pt
                ON soft.rn = pt.rn
              JOIN (SELECT /*+dynamic_sampling(t 2)*/
                     t.column_value id_dep_clin_serv, rownum rn
                      FROM TABLE(i_specialty) t) dcs
                ON soft.rn = dcs.rn
              JOIN (SELECT /*+dynamic_sampling(t 2)*/
                     t.column_value id_professional, rownum rn
                      FROM TABLE(i_professional) t) prof
                ON soft.rn = prof.rn
              JOIN (SELECT /*+dynamic_sampling(t 2)*/
                     t.column_value id_cdr_action, rownum rn
                      FROM TABLE(i_action) t) ca
                ON soft.rn = ca.rn
              JOIN (SELECT /*+dynamic_sampling(t 2)*/
                     t.column_value id_cdr_def_severity, rownum rn
                      FROM TABLE(i_severity) t) s
                ON soft.rn = s.rn
              JOIN cdr_param_action cdrpa
                ON ca.id_cdr_action = cdrpa.id_cdr_action
              JOIN cdr_parameter cdrp
                ON cdrpa.id_cdr_parameter = cdrp.id_cdr_parameter
              JOIN cdr_def_cond cdrdc
                ON cdrp.id_cdr_def_cond = cdrdc.id_cdr_def_cond
            
             WHERE cdrdc.id_cdr_definition = i_definition;
    
        TYPE t_coll_settings IS TABLE OF c_settings%ROWTYPE;
        l_settings t_coll_settings;
    BEGIN
    
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ' i_definition:' || i_definition || ']',
                              g_package,
                              l_func_name);
    
        -- ADD TO HISTORY LOG TABLE
    
        INSERT INTO cdr_def_config_hist
            (SELECT id_cdr_def_config,
                    id_cdr_def_severity,
                    id_cdr_param_action,
                    id_institution,
                    id_software,
                    id_profile_template,
                    id_dep_clin_serv,
                    id_professional,
                    i_prof.id,
                    SYSDATE,
                    i_prof.institution,
                    i_prof.id,
                    SYSDATE,
                    i_prof.institution,
                    'C' -- sys_domain 'ACTIVE_CANCEL'
               FROM cdr_def_config cdrdef
              WHERE cdrdef.id_institution = i_prof.institution
                AND cdrdef.id_cdr_param_action IN
                    (SELECT cdrpa.id_cdr_param_action
                       FROM cdr_param_action cdrpa
                       JOIN cdr_parameter cdrp
                         ON cdrpa.id_cdr_parameter = cdrp.id_cdr_parameter
                       JOIN cdr_def_cond cdrdc
                         ON cdrp.id_cdr_def_cond = cdrdc.id_cdr_def_cond
                      WHERE cdrdc.id_cdr_definition = i_definition)
             
             );
    
        -- remove existing exceptions
        g_error := 'CALL ts_cdr_def_config.del_by';
        ts_cdr_def_config.del_by(where_clause_in => 'id_institution = ' || i_prof.institution || '
   AND id_cdr_param_action IN (SELECT cdrpa.id_cdr_param_action
                                 FROM cdr_param_action cdrpa
                                 JOIN cdr_parameter cdrp
                                   ON cdrpa.id_cdr_parameter = cdrp.id_cdr_parameter
                                 JOIN cdr_def_cond cdrdc
                                   ON cdrp.id_cdr_def_cond = cdrdc.id_cdr_def_cond
                                WHERE cdrdc.id_cdr_definition = ' ||
                                                    i_definition || ')',
                                 rows_out        => l_rows);
    
        g_error := 'deleted ' || l_rows.count || ' settings';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_rows := table_varchar();
    
        -- get exceptions list
        g_error := 'OPEN c_settings';
        OPEN c_settings;
        FETCH c_settings BULK COLLECT
            INTO l_settings;
        CLOSE c_settings;
    
        l_cdrdcf_ids := table_number();
    
        l_cdrdcf_row.id_institution := i_prof.institution;
        FOR i IN 1 .. l_settings.count
        LOOP
            l_cdrdcf_row.id_cdr_def_config   := seq_cdr_def_config.nextval;
            l_cdrdcf_row.id_cdr_def_severity := l_settings(i).id_cdr_def_severity;
            l_cdrdcf_row.id_cdr_param_action := l_settings(i).id_cdr_param_action;
            l_cdrdcf_row.id_software         := l_settings(i).id_software;
            l_cdrdcf_row.id_profile_template := l_settings(i).id_profile_template;
            l_cdrdcf_row.id_dep_clin_serv    := l_settings(i).id_dep_clin_serv;
            l_cdrdcf_row.id_professional     := l_settings(i).id_professional;
        
            l_cdrdcf_rows(i) := l_cdrdcf_row;
        
            l_cdrdcf_ids.extend;
            l_cdrdcf_ids(l_cdrdcf_ids.last) := l_cdrdcf_row.id_cdr_def_config;
        END LOOP;
    
        g_error := 'CALL ts_cdr_def_config.ins';
        ts_cdr_def_config.ins(rows_in => l_cdrdcf_rows, rows_out => l_rows);
    
        -- ADD TO HISTORY LOG TABLE
    
        INSERT INTO cdr_def_config_hist
            (SELECT id_cdr_def_config,
                    id_cdr_def_severity,
                    id_cdr_param_action,
                    id_institution,
                    id_software,
                    id_profile_template,
                    id_dep_clin_serv,
                    id_professional,
                    i_prof.id,
                    SYSDATE,
                    i_prof.institution,
                    i_prof.id,
                    SYSDATE,
                    i_prof.institution,
                    'A'
               FROM cdr_def_config cdrdef
              WHERE cdrdef.id_cdr_def_config IN (SELECT /*+opt_estimate (table j rows=0.00000000001)*/
                                                  j.column_value
                                                   FROM TABLE(l_cdrdcf_ids) j));
    
        o_cdrdcf_ids := l_cdrdcf_ids;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => l_func_name,
                                                     o_error    => o_error);
    END set_setting_def;

    /**
    * Get context variables, for the filter framework.
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2011/11/03
    */
    PROCEDURE get_ctx_setting_grid_def
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        g_lang             CONSTANT PLS_INTEGER := 1;
        g_prof_id          CONSTANT PLS_INTEGER := 2;
        g_prof_institution CONSTANT PLS_INTEGER := 3;
        g_prof_software    CONSTANT PLS_INTEGER := 4;
        g_episode          CONSTANT PLS_INTEGER := 5;
        g_patient          CONSTANT PLS_INTEGER := 6;
        l_lang             CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof             CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                                 i_context_ids(g_prof_institution),
                                                                 i_context_ids(g_prof_software));
        l_patient          CONSTANT patient.id_patient%TYPE := i_context_ids(g_patient);
        l_episode          CONSTANT episode.id_episode%TYPE := i_context_ids(g_episode);
    BEGIN
        CASE i_name
            WHEN 'i_lang' THEN
                o_id := l_lang;
            WHEN 'i_prof_id' THEN
                o_id := l_prof.id;
            WHEN 'i_prof_institution' THEN
                o_id := l_prof.institution;
            WHEN 'i_prof_software' THEN
                o_id := l_prof.software;
            WHEN 'i_patient' THEN
                o_id := l_patient;
            WHEN 'i_episode' THEN
                o_id := l_episode;
            WHEN 'g_add' THEN
                o_vc2 := pk_cdr_constant.g_add;
            WHEN 'g_active' THEN
                o_vc2 := pk_alert_constant.g_active;
            WHEN 'g_edited' THEN
                o_vc2 := pk_cdr_constant.g_edited;
            WHEN 'g_rem' THEN
                o_vc2 := pk_cdr_constant.g_rem;
            WHEN 'g_yes' THEN
                o_vc2 := pk_alert_constant.g_yes;
            WHEN 'l_market' THEN
                o_num := pk_core.get_inst_mkt(i_id_institution => l_prof.institution);
        END CASE;
    END get_ctx_setting_grid_def;

    /**
    *  Check if a rule (id_cdr_definition) is active to this institution
    *
    * @author               Mário Mineiro
    * @version               2.6.4
    * @since                27-03/2014
    */
    FUNCTION check_rule_active
    (
        i_institution       IN institution.id_institution%TYPE,
        i_id_cdr_definition IN cdr_definition.id_cdr_definition%TYPE
    ) RETURN NUMBER IS
    
        l_count  NUMBER;
        l_market market.id_market%TYPE;
    BEGIN
        l_market := pk_core.get_inst_mkt(i_id_institution => i_institution);
        -- check if is active
        SELECT COUNT(*)
          INTO l_count
          FROM cdr_definition cdrd
         WHERE cdrd.id_institution IN (0, i_institution)
           AND cdrd.flg_status IN (pk_alert_constant.g_active, pk_cdr_constant.g_edited)
           AND cdrd.flg_available = pk_alert_constant.g_yes
           AND cdrd.id_cdr_definition = i_id_cdr_definition
           AND EXISTS (SELECT NULL
                  FROM cdr_def_mkt cdrdm
                 WHERE cdrdm.id_cdr_definition = cdrd.id_cdr_definition
                      --                       AND cdrdm.id_category IN (-1, l_prof_cat)
                      --                       AND cdrdm.id_software IN (0, i_prof.software)
                   AND cdrdm.id_market IN (0, l_market)
                UNION ALL
                SELECT NULL
                  FROM cdr_def_inst cdrdi
                 WHERE cdrdi.id_cdr_definition = cdrd.id_cdr_definition
                      --                       AND cdrdi.id_category IN (-1, l_prof_cat)
                      --                       AND cdrdi.id_software IN (0, i_prof.software)
                   AND cdrdi.id_institution = i_institution
                   AND cdrdi.flg_add_remove = pk_cdr_constant.g_add)
           AND NOT EXISTS (SELECT NULL
                  FROM cdr_def_inst cdrdi
                 WHERE cdrdi.id_cdr_definition = cdrd.id_cdr_definition
                      --                       AND cdrdi.id_category IN (-1, l_prof_cat)
                      --                       AND cdrdi.id_software IN (0, i_prof.software)
                   AND cdrdi.id_institution = i_institution
                   AND cdrdi.flg_add_remove = pk_cdr_constant.g_rem);
    
        IF l_count > 1
        THEN
            l_count := 1;
        END IF;
    
        RETURN l_count;
    END check_rule_active;
    /**
    *  Get the description status for a rule (id_cdr_definition)
    *
    * @author               Mário Mineiro
    * @version               2.6.4
    * @since                27-03/2014
    */
    FUNCTION get_rule_status_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_institution       IN institution.id_institution%TYPE,
        i_id_cdr_definition IN cdr_definition.id_cdr_definition%TYPE
    ) RETURN VARCHAR IS
    
        l_status_desc VARCHAR(300 CHAR);
    BEGIN
    
        IF check_rule_active(i_institution => i_institution, i_id_cdr_definition => i_id_cdr_definition) > 0
        THEN
            l_status_desc := pk_sysdomain.get_domain(i_code_dom => 'CDS_ACTIVE_INACTIVE',
                                                     i_val      => pk_cdr_constant.g_add,
                                                     i_lang     => i_lang);
        ELSE
            l_status_desc := pk_sysdomain.get_domain(i_code_dom => 'CDS_ACTIVE_INACTIVE',
                                                     i_val      => pk_cdr_constant.g_rem,
                                                     i_lang     => i_lang);
        END IF;
        RETURN l_status_desc;
    END get_rule_status_desc;
    /**
    *  Get the status flag for a rule (id_cdr_definition)
    *
    * @author               Mário Mineiro
    * @version               2.6.4
    * @since                27-03/2014
    */
    FUNCTION get_rule_status_flg(
                                 
                                 i_institution       IN institution.id_institution%TYPE,
                                 i_id_cdr_definition IN cdr_definition.id_cdr_definition%TYPE) RETURN VARCHAR IS
    
        l_status_desc VARCHAR(300 CHAR);
    BEGIN
    
        IF check_rule_active(i_institution => i_institution, i_id_cdr_definition => i_id_cdr_definition) > 0
        THEN
            l_status_desc := pk_cdr_constant.g_add;
        ELSE
            l_status_desc := pk_cdr_constant.g_rem;
        END IF;
    
        RETURN l_status_desc;
    END get_rule_status_flg;
    /**
    *  Get the description exception status for a rule (id_cdr_definition)
    *
    * @author               Mário Mineiro
    * @version               2.6.4
    * @since                27-03/2014
    */
    FUNCTION get_rule_exceptions_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_institution       IN institution.id_institution%TYPE,
        i_id_cdr_definition IN cdr_definition.id_cdr_definition%TYPE
    ) RETURN VARCHAR2 IS
    
        l_count       NUMBER;
        l_status_desc VARCHAR(300 CHAR);
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM cdr_def_config cdc
          JOIN cdr_param_action cpa
            ON cdc.id_cdr_param_action = cpa.id_cdr_param_action
          JOIN cdr_def_severity cds
            ON cdc.id_cdr_def_severity = cds.id_cdr_def_severity
          JOIN cdr_severity cs
            ON cds.id_cdr_severity = cs.id_cdr_severity
          JOIN cdr_action ca
            ON cpa.id_cdr_action = ca.id_cdr_action
          JOIN cdr_parameter cp
            ON cpa.id_cdr_parameter = cp.id_cdr_parameter
          JOIN cdr_def_cond cdcc
            ON cp.id_cdr_def_cond = cdcc.id_cdr_def_cond
          JOIN software s
            ON cdc.id_software = s.id_software
          JOIN profile_template pt
            ON cdc.id_profile_template = pt.id_profile_template
          JOIN dep_clin_serv dcs
            ON cdc.id_dep_clin_serv = dcs.id_dep_clin_serv
          JOIN clinical_service cse
            ON dcs.id_clinical_service = cse.id_clinical_service
         WHERE cdcc.id_cdr_definition = i_id_cdr_definition
           AND cdc.id_institution = i_institution;
    
        IF l_count > 0
        THEN
            l_status_desc := pk_sysdomain.get_domain(i_code_dom => 'YES_NO',
                                                     i_val      => pk_alert_constant.get_yes,
                                                     i_lang     => i_lang);
        ELSE
            l_status_desc := pk_sysdomain.get_domain(i_code_dom => 'YES_NO',
                                                     i_val      => pk_alert_constant.get_no,
                                                     i_lang     => i_lang);
        END IF;
    
        RETURN l_status_desc;
    
    END get_rule_exceptions_desc;

    /**
    *  Set the Status of a rule (id_Cdr_definition) on table cdr_def_inst by [A]dd or [R]emove
    *
    * @author               Mário Mineiro
    * @version               2.6.4
    * @since                27-03/2014
    */
    FUNCTION set_rule_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_definition IN table_number,
        i_flg_add_remove    IN cdr_def_inst.flg_add_remove%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_RULE_STATUS';
    
        l_count             NUMBER;
        l_rows_out          table_varchar;
        l_count_same_status NUMBER;
    
        l_old_flg_add_remove VARCHAR2(10 CHAR);
    BEGIN
    
        -- loop all the definitions to change status
        FOR i IN i_id_cdr_definition.first .. i_id_cdr_definition.last
        LOOP
            -- SET HISTORY RULE STATUS
            -- check if its same status
            l_old_flg_add_remove := get_rule_status_flg(i_institution       => i_prof.institution,
                                                        i_id_cdr_definition => i_id_cdr_definition(i));
            -- check if is already a configuration on this institution for this rule
            SELECT COUNT(*)
              INTO l_count
              FROM cdr_def_inst cdrdi
             WHERE cdrdi.id_cdr_definition = i_id_cdr_definition(i)
               AND id_institution = i_prof.institution
               AND id_category = -1
               AND id_software = 0;
        
            IF l_count = 0
            THEN
                -- not exists, create            
                INSERT INTO cdr_def_inst
                    (id_cdr_definition,
                     id_category,
                     id_software,
                     id_institution,
                     flg_add_remove,
                     create_user,
                     --                     create_time,
                     create_institution
                     --                     content_date_tstz
                     )
                VALUES
                    (i_id_cdr_definition(i),
                     -1,
                     0,
                     i_prof.institution,
                     i_flg_add_remove,
                     i_prof.id,
                     --                     SYSDATE,
                     i_prof.institution
                     --                     SYSDATE
                     );
            
            ELSE
                -- exists, update if the flg is different from actual            
                UPDATE cdr_def_inst cdrdi
                   SET cdrdi.flg_add_remove = i_flg_add_remove,
                       cdrdi.update_user    = i_prof.id,
                       --                       cdrdi.update_time        = SYSDATE,
                       cdrdi.update_institution = i_prof.institution
                 WHERE cdrdi.id_cdr_definition = i_id_cdr_definition(i)
                   AND id_institution = i_prof.institution
                   AND nvl(cdrdi.flg_add_remove, 'Z') != i_flg_add_remove;
            END IF;
        
            IF SQL%ROWCOUNT = 1
            THEN
            
                IF l_old_flg_add_remove != i_flg_add_remove
                THEN
                    ts_cdr_definition_hist.ins(id_cdr_definition_in => i_id_cdr_definition(i),
                                               status_new_in        => i_flg_add_remove,
                                               status_old_in        => l_old_flg_add_remove,
                                               
                                               create_user_in => i_prof.id,
                                               create_time_in => g_sysdate_tstz,
                                               
                                               create_institution_in => i_prof.institution,
                                               rows_out              => l_rows_out);
                
                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'CDR_DEFINITION_HIST',
                                                  i_rowids     => l_rows_out,
                                                  o_error      => o_error);
                END IF;
            
            END IF;
        
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => l_func_name,
                                                     o_error    => o_error);
    END set_rule_status;
    /**
    *  Get the rule (id_cdr_definition) data in bulk, definition, status, url info button
    *
    * @author               Mário Mineiro
    * @version               2.6.4
    * @since                27-03/2014
    */
    FUNCTION get_rule_bulk
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_definition IN table_number,
        i_sep               IN VARCHAR2 DEFAULT ' - ',
        i_sep_final         IN VARCHAR2 DEFAULT '; ',
        o_rule_info         OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_RULE_BULK';
    
        CURSOR c_definition IS
            SELECT pk_translation.get_translation(i_lang, cde.code_name) code,
                   pk_cdr_bo_core.get_desc_conditions(i_lang, cde.id_cdr_definition) description
              FROM cdr_definition cde
             WHERE cde.id_cdr_definition IN (SELECT /*+opt_estimate (table j rows=0.00000000001)*/
                                              j.column_value
                                               FROM TABLE(i_id_cdr_definition) j);
    
        CURSOR c_links IS
            SELECT cde.id_links, COUNT(*) thecount
              FROM cdr_definition cde
             WHERE cde.id_cdr_definition IN (SELECT /*+opt_estimate (table j rows=0.00000000001)*/
                                              j.column_value
                                               FROM TABLE(i_id_cdr_definition) j)
             GROUP BY id_links;
    
        l_definition_desc CLOB;
        l_active_count    PLS_INTEGER := 0;
        l_inactive_count  PLS_INTEGER := 0;
    
        l_status_desc VARCHAR(300 CHAR);
        l_url         VARCHAR(300 CHAR);
        l_id_links    links.id_links%TYPE;
    
        l_sep       VARCHAR2(10 CHAR) := ' - ';
        l_sep_final VARCHAR2(10 CHAR) := '; ';
        l_head      sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CDR_T124');
    
        l_multiple_links_count NUMBER := 0;
        l_flg_status           VARCHAR2(10 CHAR);
    
    BEGIN
    
        IF i_sep IS NOT NULL
        THEN
            l_sep := i_sep;
        END IF;
    
        IF i_sep_final IS NOT NULL
        THEN
            l_sep_final := i_sep_final;
        END IF;
    
        -- Get all the descriptions of a definition     
        FOR r_def IN c_definition
        LOOP
            l_definition_desc := l_definition_desc || r_def.code || l_sep || r_def.description || l_sep_final;
        END LOOP;
    
        -- add head to the field
        l_definition_desc := l_head || l_definition_desc;
    
        -- get Status
        FOR i IN i_id_cdr_definition.first .. i_id_cdr_definition.last
        LOOP
        
            IF check_rule_active(i_institution => i_prof.institution, i_id_cdr_definition => i_id_cdr_definition(i)) > 0
            THEN
                l_active_count := l_active_count + 1;
            ELSE
                l_inactive_count := l_inactive_count + 1;
            END IF;
        
        END LOOP;
    
        IF l_active_count >= 1
           AND l_inactive_count = 0
        THEN
            -- Active       
            l_status_desc := pk_sysdomain.get_domain(i_code_dom => 'ACTIVE_INACTIVE_MULTIPLE',
                                                     i_val      => pk_cdr_constant.g_add,
                                                     i_lang     => i_lang);
            l_flg_status  := pk_cdr_constant.g_add;
        ELSIF l_inactive_count >= 1
              AND l_active_count = 0
        THEN
            -- INACTIVE
            l_status_desc := pk_sysdomain.get_domain(i_code_dom => 'ACTIVE_INACTIVE_MULTIPLE',
                                                     i_val      => pk_cdr_constant.g_rem,
                                                     i_lang     => i_lang);
            l_flg_status  := pk_cdr_constant.g_rem;
        ELSE
            -- MULTIPLE       
            l_status_desc := pk_sysdomain.get_domain(i_code_dom => 'ACTIVE_INACTIVE_MULTIPLE',
                                                     i_val      => pk_cdr_constant.g_multiple,
                                                     i_lang     => i_lang);
            l_flg_status  := pk_cdr_constant.g_multiple;
        END IF;
    
        -- get URL INFO BUTTON
        FOR r_links IN c_links
        LOOP
            l_multiple_links_count := l_multiple_links_count + 1;
            l_id_links             := r_links.id_links;
        END LOOP;
    
        IF l_multiple_links_count != 1
        THEN
            l_id_links := NULL;
            -- if theres more than one link go MULTIPLE       
            l_url := pk_sysdomain.get_domain(i_code_dom => 'ACTIVE_INACTIVE_MULTIPLE',
                                             i_val      => pk_cdr_constant.g_multiple,
                                             i_lang     => i_lang);
        ELSE
            IF l_id_links IS NOT NULL
            THEN
                l_url := pk_links.get_links_label(i_lang => i_lang, i_prof => i_prof, i_id_links => l_id_links);
            END IF;
        END IF;
    
        OPEN o_rule_info FOR
            SELECT l_definition_desc definition_desc,
                   l_status_desc     status_desc,
                   l_flg_status      flg_status,
                   l_id_links        id_links,
                   l_url             url
              FROM dual;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => l_func_name,
                                                     o_error    => o_error);
    END get_rule_bulk;

    /**
    *  Return Y or N if have or not exceptions
    *
    * @author               Mário Mineiro
    * @version               2.6.4
    * @since                27-03/2014
    */
    FUNCTION get_have_exceptions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_definition IN cdr_definition.id_cdr_definition%TYPE,
        o_have_exceptions   OUT sys_domain.val%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_status_desc VARCHAR(300 CHAR);
    
    BEGIN
    
        l_status_desc     := get_rule_exceptions_desc(i_lang              => i_lang,
                                                      i_institution       => i_prof.institution,
                                                      i_id_cdr_definition => i_id_cdr_definition);
        o_have_exceptions := pk_sysdomain.get_value(i_lang     => i_lang,
                                                    i_code_dom => 'YES_NO',
                                                    i_desc     => l_status_desc,
                                                    o_error    => o_error);
    
        RETURN TRUE;
    
    END get_have_exceptions;
    /**
    *  set the rule data in bulk, links, status
    *
    * @author               Mário Mineiro
    * @version               2.6.4
    * @since                27-03/2014
    */
    FUNCTION set_rule_bulk
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_definition IN table_number,
        i_flg_add_remove    IN cdr_def_inst.flg_add_remove%TYPE,
        i_id_links          IN links.id_links%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_RULE_BULK';
    
        l_rows_out table_varchar;
        CURSOR c_definitions(c_id_cdr_definition cdr_definition.id_cdr_definition%TYPE) IS
            SELECT cdrd.id_links
              FROM cdr_definition cdrd
             WHERE cdrd.id_cdr_definition = c_id_cdr_definition;
    
    BEGIN
    
        IF i_flg_add_remove IS NOT NULL
        THEN
            IF NOT set_rule_status(i_lang              => i_lang,
                                   i_prof              => i_prof,
                                   i_id_cdr_definition => i_id_cdr_definition,
                                   i_flg_add_remove    => i_flg_add_remove,
                                   o_error             => o_error)
            
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        FOR i IN i_id_cdr_definition.first .. i_id_cdr_definition.last
        LOOP
            FOR r_def IN c_definitions(i_id_cdr_definition(i))
            LOOP
                -- update cdr_definition with link
                -- SET HISTORY RULE STATUS
                IF nvl(i_id_links, -9981337) != nvl(r_def.id_links, -9991337)
                THEN
                
                    ts_cdr_definition_hist.ins(id_cdr_definition_in => i_id_cdr_definition(i),
                                               id_links_new_in      => i_id_links,
                                               id_links_old_in      => r_def.id_links,
                                               
                                               create_user_in        => i_prof.id,
                                               create_institution_in => i_prof.institution,
                                               create_time_in        => g_sysdate_tstz,
                                               rows_out              => l_rows_out);
                
                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'CDR_DEFINITION_HIST',
                                                  i_rowids     => l_rows_out,
                                                  o_error      => o_error);
                
                    UPDATE cdr_definition cdrd
                       SET cdrd.id_links = i_id_links
                     WHERE cdrd.id_cdr_definition = i_id_cdr_definition(i);
                END IF;
            END LOOP;
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => l_func_name,
                                                     o_error    => o_error);
    END set_rule_bulk;

    /**
    *  get the rule detail
    *
    * @author               Mário Mineiro
    * @version               2.6.4
    * @since                27-03/2014
    */
    FUNCTION get_rule_detail
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_definition IN table_number,
        o_history           OUT pk_types.cursor_type,
        
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_RULE_DETAIL';
    
        l_none sys_message.desc_message%TYPE;
    
        CURSOR c_definition IS
            SELECT id_cdr_definition,
                   pk_translation.get_translation(i_lang, cde.code_name) code,
                   pk_cdr_bo_core.get_desc_conditions(i_lang, cde.id_cdr_definition) description,
                   get_rule_status_desc(i_lang              => i_lang,
                                        i_institution       => i_prof.institution,
                                        i_id_cdr_definition => cde.id_cdr_definition) status_desc,
                   get_rule_status_flg(i_institution       => i_prof.institution,
                                       i_id_cdr_definition => cde.id_cdr_definition) status_flg,
                   pk_links.get_links_label(i_lang     => i_lang,
                                            i_prof     => i_prof,
                                            i_id_links => cde.id_links,
                                            i_sep      => ' - ') links_desc,
                   cde.update_time,
                   nvl(cde.update_user, cde.create_user) x_user,
                   --     pk_prof_utils.get_name_signature(i_lang, i_prof, cde.update_user) update_user,
                   pk_date_utils.date_char_tsz(i_lang => i_lang,
                                               i_date => cde.update_time,
                                               i_inst => i_prof.institution,
                                               i_soft => i_prof.software) date_desc
              FROM cdr_definition cde
             WHERE cde.id_cdr_definition IN (SELECT /*+opt_estimate (table j rows=0.00000000001)*/
                                              j.column_value
                                               FROM TABLE(i_id_cdr_definition) j);
    
        CURSOR c_exceptions(l_id_cdr_definition cdr_definition.id_cdr_definition%TYPE) IS
            SELECT e.id_software software_id,
                   decode(e.id_software,
                          pk_alert_constant.g_soft_all,
                          l_none,
                          pk_string_utils.strip_html_tags(pk_translation.get_translation(i_lang, e.code_software))) software_name,
                   e.id_dep_clin_serv specialty_id,
                   decode(e.id_dep_clin_serv,
                          -1,
                          l_none,
                          pk_translation.get_translation(i_lang, e.code_clinical_service)) specialty_name,
                   e.id_profile_template profile_id,
                   decode(e.id_profile_template, 0, l_none, pk_message.get_message(i_lang, e.code_profile_template)) profile_name,
                   e.id_professional professional_id,
                   decode(e.id_professional,
                          -1,
                          l_none,
                          pk_prof_utils.get_name_signature(i_lang, i_prof, e.id_professional)) professional_name,
                   e.id_cdr_def_severity severity_id,
                   decode(e.id_cdr_severity,
                          pk_cdr_constant.g_cdrs_not_applicable,
                          l_none,
                          pk_translation.get_translation(i_lang, e.code_cdr_severity)) severity_name,
                   e.id_cdr_action action_id,
                   pk_translation.get_translation(i_lang, e.code_cdr_action) action_name,
                   pk_date_utils.date_char_tsz(i_lang => i_lang,
                                               i_date => e.update_time,
                                               i_inst => i_prof.institution,
                                               i_soft => i_prof.software) update_time,
                   nvl(update_user, create_user) x_user
            
              FROM (SELECT DISTINCT cdc.id_software,
                                    s.code_software,
                                    cdc.id_dep_clin_serv,
                                    cse.code_clinical_service,
                                    cdc.id_profile_template,
                                    pt.code_profile_template,
                                    cdc.id_professional,
                                    cds.id_cdr_def_severity,
                                    cds.id_cdr_severity,
                                    cs.code_cdr_severity,
                                    cpa.id_cdr_action,
                                    ca.code_cdr_action,
                                    cdc.update_time,
                                    cdc.update_user,
                                    cdc.create_user
                      FROM cdr_def_config cdc
                      JOIN cdr_param_action cpa
                        ON cdc.id_cdr_param_action = cpa.id_cdr_param_action
                      JOIN cdr_def_severity cds
                        ON cdc.id_cdr_def_severity = cds.id_cdr_def_severity
                      JOIN cdr_severity cs
                        ON cds.id_cdr_severity = cs.id_cdr_severity
                      JOIN cdr_action ca
                        ON cpa.id_cdr_action = ca.id_cdr_action
                      JOIN cdr_parameter cp
                        ON cpa.id_cdr_parameter = cp.id_cdr_parameter
                      JOIN cdr_def_cond cdcc
                        ON cp.id_cdr_def_cond = cdcc.id_cdr_def_cond
                      JOIN software s
                        ON cdc.id_software = s.id_software
                      JOIN profile_template pt
                        ON cdc.id_profile_template = pt.id_profile_template
                      JOIN dep_clin_serv dcs
                        ON cdc.id_dep_clin_serv = dcs.id_dep_clin_serv
                      JOIN clinical_service cse
                        ON dcs.id_clinical_service = cse.id_clinical_service
                     WHERE cdcc.id_cdr_definition = l_id_cdr_definition
                       AND cdc.id_institution = i_prof.institution) e
             ORDER BY e.update_time;
    
        CURSOR c_history(l_id_cdr_definition NUMBER) IS
        
            SELECT *
              FROM (SELECT create_user, create_time
                    
                      FROM cdr_definition_hist cde_hist
                     WHERE cde_hist.id_cdr_definition = l_id_cdr_definition
                    UNION ALL
                    SELECT
                    
                     create_user, create_time
                    
                      FROM (SELECT DISTINCT cdc.id_software,
                                            s.code_software,
                                            cdc.id_dep_clin_serv,
                                            cse.code_clinical_service,
                                            cdc.id_profile_template,
                                            pt.code_profile_template,
                                            cdc.id_professional,
                                            cds.id_cdr_def_severity,
                                            cds.id_cdr_severity,
                                            cs.code_cdr_severity,
                                            cpa.id_cdr_action,
                                            ca.code_cdr_action,
                                            cdc.create_user,
                                            cdc.create_time,
                                            cdc.status
                            
                              FROM cdr_def_config_hist cdc
                              JOIN cdr_param_action cpa
                                ON cdc.id_cdr_param_action = cpa.id_cdr_param_action
                              JOIN cdr_def_severity cds
                                ON cdc.id_cdr_def_severity = cds.id_cdr_def_severity
                              JOIN cdr_severity cs
                                ON cds.id_cdr_severity = cs.id_cdr_severity
                              JOIN cdr_action ca
                                ON cpa.id_cdr_action = ca.id_cdr_action
                              JOIN cdr_parameter cp
                                ON cpa.id_cdr_parameter = cp.id_cdr_parameter
                              JOIN cdr_def_cond cdcc
                                ON cp.id_cdr_def_cond = cdcc.id_cdr_def_cond
                              JOIN software s
                                ON cdc.id_software = s.id_software
                              JOIN profile_template pt
                                ON cdc.id_profile_template = pt.id_profile_template
                              JOIN dep_clin_serv dcs
                                ON cdc.id_dep_clin_serv = dcs.id_dep_clin_serv
                              JOIN clinical_service cse
                                ON dcs.id_clinical_service = cse.id_clinical_service
                             WHERE cdcc.id_cdr_definition = l_id_cdr_definition) e) t
             ORDER BY create_time DESC
            
            ;
    
        l_detail_full    CLOB;
        l_exceptions_det CLOB;
    
        l_documented CLOB;
    
        l_data_compare      VARCHAR2(10 CHAR);
        l_documented_exists BOOLEAN := FALSE;
    
        l_rule_exception   sys_message.desc_message%TYPE;
        l_status           sys_message.desc_message%TYPE;
        l_info_button      sys_message.desc_message%TYPE;
        l_action           sys_message.desc_message%TYPE;
        l_severity         sys_message.desc_message%TYPE;
        l_software         sys_message.desc_message%TYPE;
        l_clinical_service sys_message.desc_message%TYPE;
        l_user_profile     sys_message.desc_message%TYPE;
        l_professional     sys_message.desc_message%TYPE;
        l_updated          sys_message.desc_message%TYPE;
    
        l_space_format CONSTANT VARCHAR2(10 CHAR) := '   ';
    BEGIN
    
        g_error            := 'GET_MESSAGE';
        l_none             := pk_message.get_message(i_lang, i_prof, 'CDR_T127');
        l_rule_exception   := pk_message.get_message(i_lang, i_prof, 'CDR_T009');
        l_status           := pk_message.get_message(i_lang, i_prof, 'CDR_T020');
        l_info_button      := pk_message.get_message(i_lang, i_prof, 'CDR_T128');
        l_action           := pk_message.get_message(i_lang, i_prof, 'CDR_T090');
        l_severity         := pk_message.get_message(i_lang, i_prof, 'CDR_T049');
        l_software         := pk_message.get_message(i_lang, i_prof, 'CDR_T012');
        l_clinical_service := pk_message.get_message(i_lang, i_prof, 'CDR_T013');
        l_user_profile     := pk_message.get_message(i_lang, i_prof, 'CDR_T014');
        l_professional     := pk_message.get_message(i_lang, i_prof, 'CDR_T015');
        l_updated          := pk_message.get_message(i_lang, i_prof, 'PAST_HISTORY_M065');
    
        -- Initialize history table
        pk_edis_hist.init_vars;
    
        g_error := 'OPEN r_Def';
        -- Get all the descriptions of a definition     
        FOR r_def IN c_definition
        LOOP
            -- Create a new line in history table with current history record 
            pk_edis_hist.add_line(i_history        => r_def.id_cdr_definition,
                                  i_dt_hist        => r_def.update_time,
                                  i_record_state   => r_def.status_flg,
                                  i_desc_rec_state => r_def.status_desc);
        
            -- Add new value to history table
            pk_edis_hist.add_value(i_label => r_def.description,
                                   i_value => ' (' || r_def.status_desc || ')',
                                   i_type  => pk_edis_hist.g_type_title);
        
            pk_edis_hist.add_value(i_label => NULL, i_value => NULL, i_type => pk_edis_hist.g_type_empty_line);
        
            -- Add new value to history table
            pk_edis_hist.add_value_if_not_null(i_label => l_status,
                                               i_value => r_def.status_desc,
                                               i_type  => pk_edis_hist.g_type_content);
        
            -- Add new value to history table
            pk_edis_hist.add_value_if_not_null(i_label => l_info_button,
                                               i_value => r_def.links_desc,
                                               i_type  => pk_edis_hist.g_type_content);
            pk_edis_hist.add_value(i_label => NULL, i_value => NULL, i_type => pk_edis_hist.g_type_empty_line);
        
            -- EXCEPTIONS OF DEFINITION
            FOR r_exceptions IN c_exceptions(r_def.id_cdr_definition)
            LOOP
            
                -- Add new value to history table
                pk_edis_hist.add_value(i_label => l_rule_exception,
                                       i_value => ' ',
                                       i_type  => pk_edis_hist.g_type_subtitle);
                -- Add new value to history table
                pk_edis_hist.add_value_if_not_null(i_label => l_space_format || l_action,
                                                   i_value => r_exceptions.action_name,
                                                   i_type  => pk_edis_hist.g_type_content);
                -- Add new value to history table
                pk_edis_hist.add_value_if_not_null(i_label => l_space_format || l_severity,
                                                   i_value => r_exceptions.severity_name,
                                                   i_type  => pk_edis_hist.g_type_content);
                -- Add new value to history table
                pk_edis_hist.add_value_if_not_null(i_label => l_space_format || l_software,
                                                   i_value => r_exceptions.software_name,
                                                   i_type  => pk_edis_hist.g_type_content);
                -- Add new value to history table
                pk_edis_hist.add_value_if_not_null(i_label => l_space_format || l_clinical_service,
                                                   i_value => r_exceptions.specialty_name,
                                                   i_type  => pk_edis_hist.g_type_content);
                -- Add new value to history table
                pk_edis_hist.add_value_if_not_null(i_label => l_space_format || l_user_profile,
                                                   i_value => r_exceptions.profile_name,
                                                   i_type  => pk_edis_hist.g_type_content);
                -- Add new value to history table
                pk_edis_hist.add_value_if_not_null(i_label => l_space_format || l_professional,
                                                   i_value => r_exceptions.professional_name,
                                                   i_type  => pk_edis_hist.g_type_content);
            
                -- GET DOCUMENTED
                l_data_compare := pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                                  i_date1 => r_def.update_time,
                                                                  i_date2 => r_exceptions.update_time);
            
                pk_edis_hist.add_value(i_label => NULL, i_value => NULL, i_type => 'LT');
            
            END LOOP;
        
            -- docummented or updated
        
            FOR r_hist IN c_history(r_def.id_cdr_definition)
            LOOP
            
                pk_edis_hist.add_value(i_label => l_updated,
                                       i_value => pk_prof_utils.get_name_signature(i_lang, i_prof, r_hist.create_user) || '; ' ||
                                                  pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                                              i_date => r_hist.create_time,
                                                                              i_inst => i_prof.institution,
                                                                              i_soft => i_prof.software),
                                       i_type  => pk_edis_hist.g_type_signature);
                -- only 1 regist needed
                l_documented_exists := TRUE;
                EXIT;
            END LOOP;
        
        END LOOP;
    
        OPEN o_history FOR
            SELECT *
              FROM (SELECT t.id_history,
                           -- viewer fields
                           t.id_history viewer_category,
                           t.desc_cat_viewer viewer_category_desc,
                           t.id_professional viewer_id_prof,
                           t.id_episode viewer_id_epis,
                           pk_date_utils.date_send_tsz(i_lang, t.dt_history, i_prof) viewer_date,
                           --
                           t.dt_history,
                           t.tbl_labels,
                           t.tbl_values,
                           t.tbl_types,
                           t.tbl_info_labels,
                           t.tbl_info_values,
                           t.tbl_codes,
                           (SELECT COUNT(*)
                              FROM TABLE(t.tbl_types)) count_elems
                      FROM TABLE(pk_edis_hist.tf_hist) t);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => l_func_name,
                                                     o_error    => o_error);
    END get_rule_detail;
    /**
    *  get the rule detail history
    *
    * @author               Mário Mineiro
    * @version               2.6.4
    * @since                27-03/2014
    */
    FUNCTION get_rule_detail_hist
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_definition IN table_number,
        o_history           OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_RULE_DETAIL_HIST';
    
        l_none sys_message.desc_message%TYPE;
    
        CURSOR c_definition IS
            SELECT id_cdr_definition,
                   pk_translation.get_translation(i_lang, cde.code_name) code,
                   pk_cdr_bo_core.get_desc_conditions(i_lang, cde.id_cdr_definition) description,
                   get_rule_status_desc(i_lang              => i_lang,
                                        i_institution       => i_prof.institution,
                                        i_id_cdr_definition => cde.id_cdr_definition) status_desc,
                   get_rule_status_flg(i_institution       => i_prof.institution,
                                       i_id_cdr_definition => cde.id_cdr_definition) status_flg,
                   pk_links.get_links_label(i_lang     => i_lang,
                                            i_prof     => i_prof,
                                            i_id_links => cde.id_links,
                                            i_sep      => ' - ') links_desc,
                   
                   pk_date_utils.date_char_tsz(i_lang => i_lang,
                                               i_date => cde.create_time,
                                               i_inst => i_prof.institution,
                                               i_soft => i_prof.software) create_time,
                   cde.create_user,
                   pk_date_utils.date_char_tsz(i_lang => i_lang,
                                               i_date => cde.update_time,
                                               i_inst => i_prof.institution,
                                               i_soft => i_prof.software) date_desc
              FROM cdr_definition cde
             WHERE cde.id_cdr_definition IN (SELECT /*+opt_estimate (table j rows=0.00000000001)*/
                                              j.column_value
                                               FROM TABLE(i_id_cdr_definition) j);
    
        CURSOR c_history IS
        
            SELECT *
              FROM (
                    
                    SELECT 'DEFINITION' what,
                            NULL status,
                            pk_sysdomain.get_domain(i_code_dom => 'CDS_ACTIVE_INACTIVE',
                                                    i_val      => cde_hist.status_new,
                                                    i_lang     => i_lang) status_new_desc,
                            pk_sysdomain.get_domain(i_code_dom => 'CDS_ACTIVE_INACTIVE',
                                                    i_val      => cde_hist.status_old,
                                                    i_lang     => i_lang) status_old_desc,
                            pk_prof_utils.get_name_signature(i_lang, i_prof, cde_hist.create_user) create_user_desc,
                            create_time,
                            pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                        i_date => cde_hist.create_time,
                                                        i_inst => i_prof.institution,
                                                        i_soft => i_prof.software) data,
                            
                            NULL action_name,
                            NULL severity_name,
                            NULL software_name,
                            NULL specialty_name,
                            NULL profile_name,
                            NULL professional_name,
                            pk_links.get_links_label(i_lang     => i_lang,
                                                     i_prof     => i_prof,
                                                     i_id_links => cde_hist.id_links_new,
                                                     i_sep      => ' - ') links_new_desc,
                            pk_links.get_links_label(i_lang     => i_lang,
                                                     i_prof     => i_prof,
                                                     i_id_links => cde_hist.id_links_old,
                                                     i_sep      => ' - ') links_old_desc
                    
                      FROM cdr_definition_hist cde_hist
                     WHERE cde_hist.id_cdr_definition IN
                           (SELECT /*+opt_estimate (table j rows=0.00000000001)*/
                             j.column_value
                              FROM TABLE(i_id_cdr_definition) j)
                    
                    UNION ALL
                    SELECT 'EXCEPTIONS' what,
                            status,
                            NULL status_new_desc,
                            NULL status_old_desc,
                            pk_prof_utils.get_name_signature(i_lang, i_prof, create_user) create_user_desc,
                            create_time,
                            pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                        i_date => create_time,
                                                        i_inst => i_prof.institution,
                                                        i_soft => i_prof.software) data,
                            pk_translation.get_translation(i_lang, e.code_cdr_action) action_name,
                            decode(e.id_cdr_severity,
                                   pk_cdr_constant.g_cdrs_not_applicable,
                                   l_none,
                                   pk_translation.get_translation(i_lang, e.code_cdr_severity)) severity_name,
                            decode(e.id_software,
                                   pk_alert_constant.g_soft_all,
                                   l_none,
                                   pk_string_utils.strip_html_tags(pk_translation.get_translation(i_lang, e.code_software))) software_name,
                            decode(e.id_dep_clin_serv,
                                   -1,
                                   l_none,
                                   pk_translation.get_translation(i_lang, e.code_clinical_service)) specialty_name,
                            decode(e.id_profile_template,
                                   0,
                                   l_none,
                                   pk_message.get_message(i_lang, e.code_profile_template)) profile_name,
                            decode(e.id_professional,
                                   -1,
                                   l_none,
                                   pk_prof_utils.get_name_signature(i_lang, i_prof, e.id_professional)) professional_name,
                            NULL links_new_desc,
                            NULL links_old_desc
                    
                      FROM (SELECT DISTINCT cdc.id_software,
                                             s.code_software,
                                             cdc.id_dep_clin_serv,
                                             cse.code_clinical_service,
                                             cdc.id_profile_template,
                                             pt.code_profile_template,
                                             cdc.id_professional,
                                             cds.id_cdr_def_severity,
                                             cds.id_cdr_severity,
                                             cs.code_cdr_severity,
                                             cpa.id_cdr_action,
                                             ca.code_cdr_action,
                                             cdc.create_user,
                                             cdc.create_time,
                                             cdc.status
                             
                               FROM cdr_def_config_hist cdc
                               JOIN cdr_param_action cpa
                                 ON cdc.id_cdr_param_action = cpa.id_cdr_param_action
                               JOIN cdr_def_severity cds
                                 ON cdc.id_cdr_def_severity = cds.id_cdr_def_severity
                               JOIN cdr_severity cs
                                 ON cds.id_cdr_severity = cs.id_cdr_severity
                               JOIN cdr_action ca
                                 ON cpa.id_cdr_action = ca.id_cdr_action
                               JOIN cdr_parameter cp
                                 ON cpa.id_cdr_parameter = cp.id_cdr_parameter
                               JOIN cdr_def_cond cdcc
                                 ON cp.id_cdr_def_cond = cdcc.id_cdr_def_cond
                               JOIN software s
                                 ON cdc.id_software = s.id_software
                               JOIN profile_template pt
                                 ON cdc.id_profile_template = pt.id_profile_template
                               JOIN dep_clin_serv dcs
                                 ON cdc.id_dep_clin_serv = dcs.id_dep_clin_serv
                               JOIN clinical_service cse
                                 ON dcs.id_clinical_service = cse.id_clinical_service
                              WHERE cdcc.id_cdr_definition = i_id_cdr_definition(1)
                             --                       AND cdc.id_institution = i_prof.institution
                             ) e
                    -- ORDER BY e.update_time;                                                    
                    
                    --             ORDER BY create_time DESC
                    ) t
             ORDER BY create_time DESC
            
            ;
    
        l_creation          sys_message.desc_message%TYPE;
        l_documented        sys_message.desc_message%TYPE;
        l_edition           sys_message.desc_message%TYPE;
        l_status_new_record sys_message.desc_message%TYPE;
    
        l_rule_exception   sys_message.desc_message%TYPE;
        l_status           sys_message.desc_message%TYPE;
        l_info_button      sys_message.desc_message%TYPE;
        l_action           sys_message.desc_message%TYPE;
        l_severity         sys_message.desc_message%TYPE;
        l_software         sys_message.desc_message%TYPE;
        l_clinical_service sys_message.desc_message%TYPE;
        l_user_profile     sys_message.desc_message%TYPE;
        l_professional     sys_message.desc_message%TYPE;
        l_updated          sys_message.desc_message%TYPE;
        l_cancelled        sys_message.desc_message%TYPE;
        l_management       sys_message.desc_message%TYPE;
        l_canc_rule        sys_message.desc_message%TYPE;
        l_rule_new_record  sys_message.desc_message%TYPE;
    
        l_info_button_new_record sys_message.desc_message%TYPE;
    
        l_space_format CONSTANT VARCHAR2(10 CHAR) := '   ';
    
    BEGIN
    
        g_error      := 'GET_MESSAGE';
        l_creation   := pk_message.get_message(i_lang, i_prof, 'COMMON_T030');
        l_documented := pk_message.get_message(i_lang, i_prof, 'FUTURE_EVENTS_T024');
    
        -- for exceptions
        l_none              := pk_message.get_message(i_lang, i_prof, 'CDR_T127');
        l_rule_exception    := pk_message.get_message(i_lang, i_prof, 'CDR_T009');
        l_status            := pk_message.get_message(i_lang, i_prof, 'CDR_T020');
        l_info_button       := pk_message.get_message(i_lang, i_prof, 'CDR_T128');
        l_action            := pk_message.get_message(i_lang, i_prof, 'CDR_T090');
        l_severity          := pk_message.get_message(i_lang, i_prof, 'CDR_T049');
        l_software          := pk_message.get_message(i_lang, i_prof, 'CDR_T012');
        l_clinical_service  := pk_message.get_message(i_lang, i_prof, 'CDR_T013');
        l_user_profile      := pk_message.get_message(i_lang, i_prof, 'CDR_T014');
        l_professional      := pk_message.get_message(i_lang, i_prof, 'CDR_T015');
        l_updated           := pk_message.get_message(i_lang, i_prof, 'PAST_HISTORY_M065');
        l_cancelled         := pk_message.get_message(i_lang, i_prof, 'DETAIL_COMMON_M003');
        l_edition           := pk_message.get_message(i_lang, i_prof, 'COMMON_T029');
        l_status_new_record := pk_message.get_message(i_lang, i_prof, 'PN_M012');
    
        l_management             := pk_message.get_message(i_lang, i_prof, 'CDR_T129');
        l_canc_rule              := pk_message.get_message(i_lang, i_prof, 'CDR_T130');
        l_rule_new_record        := pk_message.get_message(i_lang, i_prof, 'CDR_T131');
        l_info_button_new_record := pk_message.get_message(i_lang, i_prof, 'CDR_T128') || ' ' ||
                                    pk_message.get_message(i_lang, i_prof, 'COMMON_T031');
        -- Initialize history table
        pk_edis_hist.init_vars;
    
        -- Create a new line in history table with current history record 
        pk_edis_hist.add_line(i_history        => i_id_cdr_definition(1),
                              i_dt_hist        => SYSDATE,
                              i_record_state   => 'A',
                              i_desc_rec_state => 'A');
    
        -- add history        
        -- history cdr_definition_hist and rule_exception....
    
        FOR r_history IN c_history
        LOOP
        
            IF r_history.what = 'DEFINITION'
            THEN
                pk_edis_hist.add_value(i_label => l_edition, i_value => ' ', i_type => pk_edis_hist.g_type_title);
            
                IF r_history.status_new_desc IS NOT NULL
                   OR r_history.status_old_desc IS NOT NULL
                THEN
                    pk_edis_hist.add_value(i_label => l_status_new_record,
                                           i_value => r_history.status_new_desc,
                                           i_type  => pk_edis_hist.g_type_new_content);
                    pk_edis_hist.add_value(i_label => l_status,
                                           i_value => r_history.status_old_desc,
                                           i_type  => pk_edis_hist.g_type_content);
                
                ELSIF r_history.links_new_desc IS NOT NULL
                      OR r_history.links_old_desc IS NOT NULL
                THEN
                    pk_edis_hist.add_value(i_label => l_info_button_new_record,
                                           i_value => nvl(r_history.links_new_desc, ' '),
                                           i_type  => pk_edis_hist.g_type_new_content);
                    pk_edis_hist.add_value(i_label => l_info_button,
                                           i_value => nvl(r_history.links_old_desc, ' '),
                                           i_type  => pk_edis_hist.g_type_content);
                END IF;
            
                pk_edis_hist.add_value(i_label => l_documented,
                                       i_value => r_history.create_user_desc || '; ' || r_history.data,
                                       i_type  => pk_edis_hist.g_type_signature);
            
            ELSIF r_history.what = 'EXCEPTIONS'
            THEN
                pk_edis_hist.add_value(i_label => l_management, i_value => ' ', i_type => pk_edis_hist.g_type_title);
            
                IF r_history.status = 'C'
                THEN
                
                    pk_edis_hist.add_value(i_label => l_canc_rule, i_value => ' ', i_type => 'STR');
                
                    pk_edis_hist.add_value_if_not_null(i_label => l_space_format || l_status_new_record,
                                                       i_value => l_cancelled,
                                                       i_type  => pk_edis_hist.g_type_new_content);
                
                ELSIF r_history.status = 'A'
                THEN
                    pk_edis_hist.add_value(i_label => l_rule_new_record,
                                           i_value => ' ',
                                           i_type  => pk_edis_hist.g_type_new_content);
                END IF;
            
                -- FALTA CENAS
            
                -- Add new value to history table
                pk_edis_hist.add_value_if_not_null(i_label => l_space_format || l_action,
                                                   i_value => r_history.action_name,
                                                   i_type  => pk_edis_hist.g_type_content);
                -- Add new value to history table
                pk_edis_hist.add_value_if_not_null(i_label => l_space_format || l_severity,
                                                   i_value => r_history.severity_name,
                                                   i_type  => pk_edis_hist.g_type_content);
                -- Add new value to history table
                pk_edis_hist.add_value_if_not_null(i_label => l_space_format || l_software,
                                                   i_value => r_history.software_name,
                                                   i_type  => pk_edis_hist.g_type_content);
                -- Add new value to history table
                pk_edis_hist.add_value_if_not_null(i_label => l_space_format || l_clinical_service,
                                                   i_value => r_history.specialty_name,
                                                   i_type  => pk_edis_hist.g_type_content);
                -- Add new value to history table
                pk_edis_hist.add_value_if_not_null(i_label => l_space_format || l_user_profile,
                                                   i_value => r_history.profile_name,
                                                   i_type  => pk_edis_hist.g_type_content);
                -- Add new value to history table
                pk_edis_hist.add_value_if_not_null(i_label => l_space_format || l_professional,
                                                   i_value => r_history.professional_name,
                                                   i_type  => pk_edis_hist.g_type_content);
            
                pk_edis_hist.add_value_if_not_null(i_label => l_documented,
                                                   i_value => r_history.create_user_desc || '; ' || r_history.data,
                                                   i_type  => pk_edis_hist.g_type_signature);
            END IF;
            pk_edis_hist.add_value(i_label => NULL, i_value => NULL, i_type => 'LT');
        END LOOP;
    
        --            pk_edis_hist.add_value(i_label => NULL, i_value => NULL, i_type => pk_edis_hist.g_type_empty_line);                               
    
        -- for the creation time        
        FOR r_def IN c_definition
        LOOP
        
            pk_edis_hist.add_value(i_label => l_creation, i_value => ' ', i_type => pk_edis_hist.g_type_title);
            pk_edis_hist.add_value_if_not_null(i_label => l_status,
                                               i_value => r_def.status_desc,
                                               i_type  => pk_edis_hist.g_type_content);
            pk_edis_hist.add_value_if_not_null(i_label => l_info_button,
                                               i_value => r_def.links_desc,
                                               i_type  => pk_edis_hist.g_type_content);
            pk_edis_hist.add_value_if_not_null(i_label => l_documented,
                                               i_value => r_def.create_user || '; ' || r_def.create_time,
                                               i_type  => pk_edis_hist.g_type_signature);
        END LOOP;
    
        OPEN o_history FOR
            SELECT *
              FROM (SELECT t.id_history,
                           -- viewer fields
                           t.id_history viewer_category,
                           t.desc_cat_viewer viewer_category_desc,
                           t.id_professional viewer_id_prof,
                           t.id_episode viewer_id_epis,
                           pk_date_utils.date_send_tsz(i_lang, t.dt_history, i_prof) viewer_date,
                           --
                           t.dt_history,
                           t.tbl_labels,
                           t.tbl_values,
                           t.tbl_types,
                           t.tbl_info_labels,
                           t.tbl_info_values,
                           t.tbl_codes,
                           (SELECT COUNT(*)
                              FROM TABLE(t.tbl_types)) count_elems
                      FROM TABLE(pk_edis_hist.tf_hist) t);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => l_func_name,
                                                     o_error    => o_error);
    END get_rule_detail_hist;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    pk_alertlog.log_init(object_name => g_package);

    g_sysdate_tstz := current_timestamp;
END pk_cdr_bo_core;
/
