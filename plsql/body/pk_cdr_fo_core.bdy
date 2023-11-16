/*-- Last Change Revision: $Rev: 2026859 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:13 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_cdr_fo_core IS

    k_uma_month CONSTANT NUMBER := 1127;
    k_uma_year  CONSTANT NUMBER := 10373;

    g_error         VARCHAR2(32000 CHAR);
    g_owner         VARCHAR2(30 CHAR);
    g_package       VARCHAR2(30 CHAR);
    g_function_name VARCHAR2(50 CHAR);
    g_found         BOOLEAN;
    g_debug_enable  BOOLEAN;
    g_sysdate_tstz  TIMESTAMP WITH LOCAL TIME ZONE;

    g_exception EXCEPTION;

    g_exception_control EXCEPTION;

    g_fault EXCEPTION;

    g_space CONSTANT VARCHAR2(1 CHAR) := ' ';

    -- rule condition applicability types
    g_usable    CONSTANT PLS_INTEGER := 1; -- input and condition parameters match concept and identifier
    g_supported CONSTANT PLS_INTEGER := 0; -- input and condition parameters match concept only
    g_unusable  CONSTANT PLS_INTEGER := -1; -- input and condition parameters do not match concept

    -- rule condition execution modes
    g_mode_concept  CONSTANT PLS_INTEGER := 1; -- checks condition applicability using concept types
    g_mode_instance CONSTANT PLS_INTEGER := 2; -- checks condition applicability using instantiated parameters
    g_mode_full     CONSTANT PLS_INTEGER := 3; -- checks condition validity

    g_cdrld_rows    t_coll_cdrld; -- rule engine call detail rows
    g_cdrc_diag_out t_coll_cdr_api_out; -- diagnosis ehr validation service output
    g_cdrc_alrg_out t_coll_cdr_api_out; -- allergy ehr validation service output
    g_cfg_user_elem sys_config.value%TYPE; -- fire rules within the same user element? Y/N

    g_alert_engine sys_config.value%TYPE;
    g_vidal_engine sys_config.value%TYPE;
    g_cdr_input    t_tbl_cdr_input;

    k_concept_isencao CONSTANT NUMBER(24) := 32;
    k_action_isencao  CONSTANT NUMBER(24) := 8;
    k_yes             CONSTANT VARCHAR(1 CHAR) := 'Y';
    --k_no              CONSTANT VARCHAR(1 CHAR) := 'N';

    -- TODO: store these constants elsewhere!
    --    g_tt_medication CONSTANT task_type.id_task_type%TYPE := 51;
    --    g_tt_allergy    CONSTANT task_type.id_task_type%TYPE := 59;

    -- shared cursors
    CURSOR c_cdrip IS
        SELECT /*+opt_estimate(table ti rows=1)*/
         t_rec_cdrip(cdrip.id_cdr_inst_param,
                     cdrip.id_cdr_instance,
                     cdrdc.id_cdr_condition,
                     cdrip.id_cdr_parameter,
                     cdrp.id_cdr_concept,
                     cdrcp.flg_identifiable,
                     cdrcp.flg_valuable,
                     cdrdc.flg_condition,
                     cdrdc.flg_deny,
                     cdrc.flg_dosage,
                     cdrip.id_element,
                     cdrip.validity,
                     cdrip.id_validity_umea,
                     cdrip.val_min,
                     cdrip.val_max,
                     cdrip.id_domain_umea,
                     cdrip.route_id,
                     (SELECT append_string(cdripv.value)
                        FROM cdr_inst_par_val cdripv
                       WHERE cdripv.id_cdr_inst_param = cdrip.id_cdr_inst_param),
                     COUNT(DISTINCT cdrp.id_cdr_def_cond) over(PARTITION BY cdrip.id_cdr_instance),
                     COUNT(*) over(PARTITION BY cdrip.id_cdr_instance, cdrp.id_cdr_def_cond)),
         COUNT(*) over(PARTITION BY cdrip.id_cdr_instance) inst_rec_count
          FROM tbl_temp ti
          JOIN cdr_inst_param cdrip
            ON ti.num_1 = cdrip.id_cdr_instance
          JOIN cdr_parameter cdrp
            ON cdrip.id_cdr_parameter = cdrp.id_cdr_parameter
          JOIN cdr_concept cdrcp
            ON cdrp.id_cdr_concept = cdrcp.id_cdr_concept
          JOIN cdr_def_cond cdrdc
            ON cdrp.id_cdr_def_cond = cdrdc.id_cdr_def_cond
          JOIN cdr_condition cdrc
            ON cdrdc.id_cdr_condition = cdrc.id_cdr_condition
         ORDER BY cdrip.id_cdr_instance, cdrdc.rank, cdrp.rank;

    CURSOR c_act_info(i_call IN cdr_call.id_cdr_call%TYPE) IS
        SELECT cdrip.id_cdr_instance,
               cdrp.id_cdr_concept,
               cdrip.id_element,
               cdre.flg_hidden,
               cdripa.id_cdr_action,
               cdra.service,
               (SELECT pharmacy_tbl_num(cdripav.value)
                  FROM cdr_inst_par_act_val cdripav
                 WHERE cdripav.id_cdr_inst_par_action = cdre.id_cdr_inst_par_action) val_list,
               cdre.id_cdr_event,
               cdre.id_cdr_inst_par_action
          FROM cdr_event cdre
          LEFT JOIN cdr_inst_par_action cdripa
            ON cdre.id_cdr_inst_par_action = cdripa.id_cdr_inst_par_action
          LEFT JOIN cdr_inst_param cdrip
            ON cdripa.id_cdr_inst_param = cdrip.id_cdr_inst_param
          LEFT JOIN cdr_parameter cdrp
            ON cdrip.id_cdr_parameter = cdrp.id_cdr_parameter
          LEFT JOIN cdr_action cdra
            ON cdripa.id_cdr_action = cdra.id_cdr_action
         WHERE cdre.id_cdr_call = i_call;

    TYPE t_act_info IS TABLE OF c_act_info%ROWTYPE;

    CURSOR c_simple_conv_tt IS -- task types and concept that are directly converted
        SELECT cdrctt.id_task_type, cdrctt.id_cdr_concept
          FROM cdr_concept_task_type cdrctt
         WHERE cdrctt.flg_conversion = pk_cdr_constant.g_conv_simple;
    /**
    * Logs a table_number's contents.
    *
    * @param i_tn           table_number
    * @param i_func_name    name of program unit
    *
    * @author               Mario Mineiro
    * @version              2.6.3.9
    * @since                2013/12/03
    */

    PROCEDURE log_me
    (
        i_log       IN VARCHAR2,
        i_func_name IN user_objects.object_name%TYPE DEFAULT NULL
    ) IS
    BEGIN
        IF (g_debug_enable)
        THEN
            pk_alertlog.log_debug(text => i_log, object_name => g_package, sub_object_name => i_func_name);
        END IF;
    END log_me;
    /**
    * Reset global package variables.
    *
    * @param i_prof         logged professional structure
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2011/01/06    */
    PROCEDURE reset_var(i_prof IN profissional) IS
    BEGIN
        log_me('[RESET_VAR] CARE YOU GOT RESETED');
        g_cdrld_rows    := NULL;
        g_cdrc_diag_out := NULL;
        g_cdrc_alrg_out := NULL;
        g_cfg_user_elem := nvl(pk_sysconfig.get_config(i_code_cf => 'CDS_FIRE_SAME_USER_ELEM', i_prof => i_prof),
                               pk_alert_constant.g_no);
        g_vidal_engine  := pk_sysconfig.get_config(i_code_cf => 'CDS_MED_EXTERN', i_prof => i_prof);
        g_alert_engine  := nvl(pk_sysconfig.get_config(i_code_cf => 'CDS_ALERT_ACTIVE', i_prof => i_prof),
                               pk_alert_constant.g_yes);
        log_me('[RESET_VAR] VIDAL ENGINE ACTIVE: ' || g_vidal_engine);
        log_me('[RESET_VAR] ALERT ENGINE ACTIVE: ' || g_alert_engine);
    END reset_var;

    PROCEDURE add_cdr_input
    (
        i_type         IN VARCHAR2, -- says if its a concept or task type
        i_concept_task IN table_number, -- concept types and task types
        i_elements     IN table_varchar, -- elements and task reqs
        i_dose         IN table_number,
        i_dose_um      IN table_number,
        i_route        IN table_varchar,
        i_id_task_type IN task_type.id_task_type%TYPE
    ) IS
    
        --l_func_name CONSTANT VARCHAR2(30 CHAR) := 'ADD_CDR_INPUT';
    BEGIN
        log_me('[ADD_CDR_INPUT] START');
        -- validate inputs all tables must be correct
        -- FALTA
        log_me('[ADD_CDR_INPUT] MISSING VALIDATIONS!!!!!!!!!!!!!!!!!!');
        -- FALTA
    
        IF g_cdr_input IS NULL
           OR g_cdr_input.count < 1
        THEN
            g_cdr_input := t_tbl_cdr_input();
        END IF;
    
        g_cdr_input.extend;
        g_cdr_input(g_cdr_input.last) := t_rec_cdr_input(i_type         => i_type,
                                                         i_concept_task => CASE
                                                                               WHEN i_id_task_type = pk_cdr_constant.g_tt_medication_by_detail THEN
                                                                                table_number(pk_cdr_constant.g_tt_medication,
                                                                                             pk_cdr_constant.g_tt_medication_by_prod)
                                                                               ELSE
                                                                                i_concept_task
                                                                           END,
                                                         i_elements     => i_elements,
                                                         i_dose         => i_dose,
                                                         i_dose_um      => i_dose_um,
                                                         i_route        => i_route,
                                                         i_id_task_type => i_id_task_type);
    
        IF g_debug_enable
        THEN
            --            FOR i IN g_cdr_input.first .. g_cdr_input.last            LOOP
            log_me('[ADD_CDR_INPUT] ' || 1 || '= i_type: ' || g_cdr_input(1).i_type);
        
            FOR x IN g_cdr_input(1).i_concept_task.first .. g_cdr_input(1).i_concept_task.last
            LOOP
                log_me('[ADD_CDR_INPUT] ' || 1 || '.' || x || '= i_concept_task: ' || g_cdr_input(1).i_concept_task(x));
            END LOOP;
        
            IF g_cdr_input(1).i_elements IS NOT NULL
                AND g_cdr_input(1).i_elements.count > 0
            THEN
                FOR x IN g_cdr_input(1).i_elements.first .. g_cdr_input(1).i_elements.last
                LOOP
                    log_me('[ADD_CDR_INPUT] ' || 1 || '.' || x || '= i_elements: ' || g_cdr_input(1).i_elements(x));
                END LOOP;
            END IF;
        
            IF g_cdr_input(1).i_dose IS NOT NULL
                AND g_cdr_input(1).i_dose.count > 0
            THEN
                FOR x IN g_cdr_input(1).i_dose.first .. g_cdr_input(1).i_dose.last
                LOOP
                    log_me('[ADD_CDR_INPUT] ' || 1 || '.' || x || '= i_dose: ' || g_cdr_input(1).i_dose(x));
                    log_me('[ADD_CDR_INPUT] ' || 1 || '.' || x || '= i_dose_um: ' || g_cdr_input(1).i_dose_um(x));
                    log_me('[ADD_CDR_INPUT] ' || 1 || '.' || x || '= i_route: ' || g_cdr_input(1).i_route(x));
                END LOOP;
            END IF;
            --    END LOOP;
        
        END IF;
    
    END add_cdr_input;

    /**
    * Logs a table_number's contents.
    *
    * @param i_tn           table_number
    * @param i_func_name    name of program unit
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.1
    * @since                2011/06/02
    */

    PROCEDURE log_tn
    (
        i_tn        IN table_number,
        i_func_name IN user_objects.object_name%TYPE
    ) IS
    BEGIN
        IF g_debug_enable
        THEN
            --  g_error := NULL;
        
            IF i_tn IS NULL
            THEN
                NULL;
            ELSIF i_tn.count IS NULL
            THEN
                NULL;
            ELSE
                FOR i IN 1 .. i_tn.count
                LOOP
                    g_error := g_error || i_tn(i) || '; ';
                    IF i = 35
                    THEN
                        -- to avoid buffer overflow errors,
                        -- never print more than 35 elements
                        g_error := g_error || '... (' || i_tn.count || ')';
                        EXIT;
                    END IF;
                END LOOP;
            END IF;
        
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => i_func_name);
        END IF;
    END log_tn;

    /**
    * Adds two condition applicability types.
    *
    * @param i_app_a        first applicability type
    * @param i_app_b        second applicability type
    *
    * @return               the "sum" of both applicability types
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/12
    */
    FUNCTION add_applicability
    (
        i_app_a IN PLS_INTEGER,
        i_app_b IN PLS_INTEGER
    ) RETURN PLS_INTEGER IS
        l_ret PLS_INTEGER;
    BEGIN
        IF i_app_a IS NULL
        THEN
            l_ret := i_app_b;
        ELSIF i_app_b IS NULL
        THEN
            l_ret := i_app_a;
        ELSIF i_app_a = g_usable
              OR i_app_b = g_usable
        THEN
            l_ret := g_usable;
        ELSIF i_app_a = g_supported
              OR i_app_b = g_supported
        THEN
            l_ret := g_supported;
        ELSE
            l_ret := g_unusable;
        END IF;
    
        RETURN l_ret;
    END add_applicability;

    /**
    * Get condition applicability (parameters not instantiated).
    * Will always be supported or unusable.
    *
    * @param i_input        input parameters list
    * @param i_param        condition parameters concepts list
    *
    * @return               condition applicability
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/12
    */
    FUNCTION get_cond_applicability
    (
        i_input IN t_coll_cdr_in,
        i_param IN table_number
    ) RETURN PLS_INTEGER IS
        l_ret      PLS_INTEGER;
        l_concepts table_number;
    BEGIN
        IF i_input IS NULL
           OR i_input.count < 1
        THEN
            -- no input parameters are specified
            l_ret := g_unusable;
        ELSE
            -- copy concepts of i_input into l_concepts
            l_concepts := table_number();
            l_concepts.extend(i_input.count);
            FOR i IN i_input.first .. i_input.last
            LOOP
                l_concepts(i) := i_input(i).id_cdr_concept;
            END LOOP;
            -- find common concepts and copy them into l_concepts
            l_concepts := i_param MULTISET INTERSECT DISTINCT l_concepts;
            IF l_concepts IS NULL
               OR l_concepts.count < 1
            THEN
                -- no common concepts exist
                l_ret := g_unusable;
            ELSE
                -- common concepts exist
                l_ret := g_supported;
            END IF;
        END IF;
    
        RETURN l_ret;
    END get_cond_applicability;

    /**
    * Get condition applicability (parameters instantiated).
    *
    * @param i_input        input parameters list
    * @param i_inst_par     condition instantiated parameters list
    *
    * @return               condition applicability
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/12
    */
    FUNCTION get_cond_applicability
    (
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip
    ) RETURN PLS_INTEGER IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_COND_APPLICABILITY';
        l_ret       PLS_INTEGER;
        l_curr_par  PLS_INTEGER;
        l_agg_par   PLS_INTEGER;
        l_usable    BOOLEAN;
        l_supported BOOLEAN;
    BEGIN
        IF i_inst_par IS NULL
           OR i_inst_par.count < 1
        THEN
            -- condition has no parameters instantiated
            g_error := 'this condition has no parameters instantiated!';
            pk_alertlog.log_warn(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        
            l_ret := g_unusable;
        ELSIF i_input IS NULL
              OR i_input.count < 1
        THEN
            -- no input parameters are specified
            l_ret := g_unusable;
        ELSE
            FOR i IN i_inst_par.first .. i_inst_par.last
            LOOP
                -- for each instantiated parameter...
                l_usable    := FALSE;
                l_supported := FALSE;
                l_curr_par  := g_unusable;
            
                -- for each input parameter...
                FOR j IN i_input.first .. i_input.last
                LOOP
                    IF i_input(j).id_cdr_concept = i_inst_par(i).id_cdr_concept
                    THEN
                        -- concepts match!
                        IF i_inst_par(i).flg_identifiable = pk_alert_constant.g_yes
                        THEN
                            -- elements must be identified
                            IF i_inst_par(i).id_element = i_input(j).id_element
                            THEN
                                -- concepts and elements match
                                IF i_inst_par(i).flg_dosage = pk_alert_constant.g_yes
                                THEN
                                    -- dosage is required
                                    IF i_input(j).dose IS NULL
                                    THEN
                                        -- dosage exists: parameter is usable
                                        l_usable := TRUE;
                                        EXIT;
                                    ELSE
                                        -- dosage not present: parameter is supported
                                        l_supported := TRUE;
                                    END IF;
                                ELSE
                                    -- dosage not required: parameter is usable
                                    l_usable := TRUE;
                                    EXIT;
                                END IF;
                            ELSE
                                -- only the concepts match: the parameter is merely supported
                                l_supported := TRUE;
                            END IF;
                        ELSE
                            -- elements need not identification
                            IF i_inst_par(i).flg_dosage = pk_alert_constant.g_yes
                            THEN
                                -- dosage is required
                                IF i_input(j).dose IS NULL
                                THEN
                                    -- dosage exists: parameter is usable
                                    l_usable := TRUE;
                                    EXIT;
                                ELSE
                                    -- dosage not present: parameter is supported
                                    l_supported := TRUE;
                                END IF;
                            ELSE
                                -- dosage not required: parameter is usable
                                l_usable := TRUE;
                                EXIT;
                            END IF;
                        END IF;
                    END IF;
                END LOOP;
            
                -- set current parameter applicability
                IF l_usable
                THEN
                    l_curr_par := g_usable;
                ELSIF l_supported
                THEN
                    l_curr_par := g_supported;
                ELSE
                    l_curr_par := g_unusable;
                END IF;
            
                -- set condition aggregated applicability
                l_agg_par := add_applicability(i_app_a => l_agg_par, i_app_b => l_curr_par);
            END LOOP;
        
            l_ret := l_agg_par;
        END IF;
    
        RETURN l_ret;
    END get_cond_applicability;

    /**
    * Get duration in days.
    *
    * @param i_span         duration identifier
    * @param i_tmu          time measurement unit identifier
    *
    * @return               duration in days
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/15
    */
    FUNCTION to_days
    (
        i_span IN cdr_inst_par_action.event_span%TYPE,
        i_tmu  IN cdr_inst_par_action.id_event_span_umea%TYPE
    ) RETURN cdr_inst_par_action.event_span%TYPE IS
        l_ret cdr_inst_par_action.event_span%TYPE;
    BEGIN
        IF i_span IS NULL
           OR i_tmu IS NULL
        THEN
            NULL;
        ELSIF i_tmu = pk_cdr_constant.g_tmu_year
        THEN
            l_ret := i_span * 365;
        ELSIF i_tmu = pk_cdr_constant.g_tmu_month
        THEN
            l_ret := i_span * 30;
        ELSIF i_tmu = pk_cdr_constant.g_tmu_week
        THEN
            l_ret := i_span * 7;
        ELSIF i_tmu = pk_cdr_constant.g_tmu_day
        THEN
            l_ret := i_span;
        ELSIF i_tmu = pk_cdr_constant.g_tmu_hour
        THEN
            l_ret := i_span / 24;
        ELSIF i_tmu = pk_cdr_constant.g_tmu_minute
        THEN
            l_ret := i_span / 24 / 60;
        ELSE
            g_error := 'Unrecognized time measurement unit!';
            RAISE g_fault;
        END IF;
    
        RETURN l_ret;
    END to_days;

    /**
    * Get the denied condition result.
    *
    * @param i_result       condition result (Y/N)
    * @param i_deny         is the condition denied? Y/N
    *
    * @return               condition result with applied deniability
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/19
    */
    FUNCTION get_denied
    (
        i_result IN VARCHAR2,
        i_deny   IN cdr_def_cond.flg_deny%TYPE
    ) RETURN VARCHAR2 IS
        l_ret VARCHAR2(1 CHAR);
    BEGIN
        IF i_deny = pk_alert_constant.g_yes
        THEN
            IF i_result = pk_alert_constant.g_yes
            THEN
                l_ret := pk_alert_constant.g_no;
            ELSIF i_result = pk_alert_constant.g_no
            THEN
                l_ret := pk_alert_constant.g_yes;
            END IF;
        ELSE
            l_ret := i_result;
        END IF;
    
        RETURN l_ret;
    END get_denied;

    /**
    * Check if a value is within a domain (lab test result, dose, etc.).
    *
    * @param i_result       value to compare
    * @param i_res_um       value to compare measurement unit
    * @param i_val_min      domain minimum value
    * @param i_val_max      domain maximum value
    * @param i_domain_um    domain measurement unit
    *
    * @return               value within the domain? Y/N
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/05/05
    */
    FUNCTION get_in_domain
    (
        i_result    IN NUMBER,
        i_res_um    IN unit_measure.id_unit_measure%TYPE,
        i_val_min   IN cdr_inst_param.val_min%TYPE,
        i_val_max   IN cdr_inst_param.val_max%TYPE,
        i_domain_um IN cdr_inst_param.id_domain_umea%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_IN_DOMAIN';
        l_ret      VARCHAR2(1 CHAR);
        l_res_conv cdr_inst_param.val_min%TYPE;
    BEGIN
        IF i_result IS NULL
           OR i_res_um IS NULL
        THEN
            -- no result found/unspecified
            l_ret := pk_alert_constant.g_no;
        ELSIF i_res_um = i_domain_um
        THEN
            -- measurement units match: compare the result with the domain
            IF (i_val_min IS NULL OR i_result >= i_val_min)
               AND (i_val_max IS NULL OR i_result <= i_val_max) -- ALERT-255254
            THEN
                l_ret := pk_alert_constant.g_yes;
            ELSE
                l_ret := pk_alert_constant.g_no;
            END IF;
        ELSIF i_res_um != i_domain_um
        THEN
            -- measurement units differ: convert the result
            g_error    := 'CALL pk_unit_measure.get_unit_mea_conversion';
            l_res_conv := pk_unit_measure.get_unit_mea_conversion(i_value         => i_result,
                                                                  i_unit_meas     => i_domain_um,
                                                                  i_unit_meas_def => i_res_um);
        
            IF l_res_conv IS NULL
            THEN
                -- converted result is null
                g_error := 'could not convert result (' || i_result || ') from ' || i_domain_um || ' to ' || i_res_um ||
                           ' measurement units!';
                pk_alertlog.log_warn(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            
                l_ret := pk_alert_constant.g_no;
            ELSE
                -- compare the converted result with the domain
                IF (i_val_min IS NULL OR l_res_conv >= i_val_min)
                   AND (i_val_max IS NULL OR l_res_conv < i_val_max)
                THEN
                    l_ret := pk_alert_constant.g_yes;
                ELSE
                    l_ret := pk_alert_constant.g_no;
                END IF;
            END IF;
        END IF;
    
        RETURN l_ret;
    END get_in_domain;

    /**
    * Executes an action.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_service      action service
    * @param i_values       action values list
    * @param i_trig_by      instance "triggered by"
    * @param i_cdripa       instance parameter action identifier
    * @param o_ids          created record identifiers list
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/13
    */
    PROCEDURE execute_action
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_service IN cdr_action.service%TYPE,
        i_values  IN table_number,
        i_trig_by IN table_clob,
        i_cdripa  IN cdr_inst_par_action.id_cdr_inst_par_action%TYPE,
        o_ids     OUT table_number
    ) IS
    BEGIN
        g_error := 'CALL ' || lower(i_service);
        EXECUTE IMMEDIATE 'declare begin ' || i_service ||
                          '(:i_lang, :i_prof, :i_patient, :i_episode, :i_values, :i_trig_by, :i_cdripa, :o_ids); end;'
            USING --
        IN i_lang, --
        IN i_prof, --
        IN i_patient, --
        IN i_episode, --
        IN i_values, --
        IN i_trig_by, --
        IN i_cdripa, --
        OUT o_ids;
    END execute_action;

    /**
    * Executes a condition.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_cdrc         condition identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/13
    */
    PROCEDURE execute_condition
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_cdrc     IN cdr_condition.id_cdr_condition%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    ) IS
    BEGIN
        -- condition execution was meant to be made dynamically, using execute immediate;
        -- this was changed, because the engine spent a lot of time doing repeated binds;
        -- so all conditions must be integrated here to get properly executed
        IF i_cdrc = 1
        THEN
            g_error := 'CALL check_allergy';
            log_me(g_error);
            check_allergy(i_lang     => i_lang,
                          i_prof     => i_prof,
                          i_patient  => i_patient,
                          i_episode  => i_episode,
                          i_mode     => i_mode,
                          i_input    => i_input,
                          i_inst_par => i_inst_par,
                          o_ret      => o_ret,
                          o_applic   => o_applic,
                          o_error    => o_error);
        ELSIF i_cdrc = 2
        THEN
            g_error := 'CALL check_lab_test_req';
            log_me(g_error);
            check_lab_test_req(i_lang     => i_lang,
                               i_prof     => i_prof,
                               i_patient  => i_patient,
                               i_episode  => i_episode,
                               i_mode     => i_mode,
                               i_input    => i_input,
                               i_inst_par => i_inst_par,
                               o_ret      => o_ret,
                               o_applic   => o_applic,
                               o_error    => o_error);
        ELSIF i_cdrc = 3
        THEN
            g_error := 'CALL check_diagnosis';
            log_me(g_error);
            check_diagnosis(i_lang     => i_lang,
                            i_prof     => i_prof,
                            i_patient  => i_patient,
                            i_episode  => i_episode,
                            i_mode     => i_mode,
                            i_input    => i_input,
                            i_inst_par => i_inst_par,
                            o_ret      => o_ret,
                            o_applic   => o_applic,
                            o_error    => o_error);
        ELSIF i_cdrc = 4
        THEN
            g_error := 'CALL check_exam_req';
            log_me(g_error);
            check_exam_req(i_lang     => i_lang,
                           i_prof     => i_prof,
                           i_patient  => i_patient,
                           i_episode  => i_episode,
                           i_mode     => i_mode,
                           i_input    => i_input,
                           i_inst_par => i_inst_par,
                           o_ret      => o_ret,
                           o_applic   => o_applic,
                           o_error    => o_error);
        ELSIF i_cdrc = 5
        THEN
            g_error := 'CALL check_exam_req_dup';
            log_me(g_error);
            check_exam_req_dup(i_lang     => i_lang,
                               i_prof     => i_prof,
                               i_patient  => i_patient,
                               i_episode  => i_episode,
                               i_mode     => i_mode,
                               i_input    => i_input,
                               i_inst_par => i_inst_par,
                               o_ret      => o_ret,
                               o_applic   => o_applic,
                               o_error    => o_error);
        ELSIF i_cdrc = 7
        THEN
            g_error := 'CALL check_pregnancy';
            log_me(g_error);
            check_pregnancy(i_lang     => i_lang,
                            i_prof     => i_prof,
                            i_patient  => i_patient,
                            i_episode  => i_episode,
                            i_mode     => i_mode,
                            i_input    => i_input,
                            i_inst_par => i_inst_par,
                            o_ret      => o_ret,
                            o_applic   => o_applic,
                            o_error    => o_error);
        ELSIF i_cdrc = 10
        THEN
            g_error := 'CALL check_age';
            log_me(g_error);
            check_age(i_lang     => i_lang,
                      i_prof     => i_prof,
                      i_patient  => i_patient,
                      i_episode  => i_episode,
                      i_mode     => i_mode,
                      i_input    => i_input,
                      i_inst_par => i_inst_par,
                      o_ret      => o_ret,
                      o_applic   => o_applic,
                      o_error    => o_error);
        ELSIF i_cdrc = 11
        THEN
            g_error := 'CALL check_gender';
            log_me(g_error);
            check_gender(i_lang     => i_lang,
                         i_prof     => i_prof,
                         i_patient  => i_patient,
                         i_episode  => i_episode,
                         i_mode     => i_mode,
                         i_input    => i_input,
                         i_inst_par => i_inst_par,
                         o_ret      => o_ret,
                         o_applic   => o_applic,
                         o_error    => o_error);
        ELSIF i_cdrc = 12
        THEN
            g_error := 'CALL check_sr_proc';
            log_me(g_error);
            check_sr_proc(i_lang     => i_lang,
                          i_prof     => i_prof,
                          i_patient  => i_patient,
                          i_episode  => i_episode,
                          i_mode     => i_mode,
                          i_input    => i_input,
                          i_inst_par => i_inst_par,
                          o_ret      => o_ret,
                          o_applic   => o_applic,
                          o_error    => o_error);
        ELSIF i_cdrc = 13
        THEN
            g_error := 'CALL check_lab_test_res';
            log_me(g_error);
            check_lab_test_res(i_lang     => i_lang,
                               i_prof     => i_prof,
                               i_patient  => i_patient,
                               i_episode  => i_episode,
                               i_mode     => i_mode,
                               i_input    => i_input,
                               i_inst_par => i_inst_par,
                               o_ret      => o_ret,
                               o_applic   => o_applic,
                               o_error    => o_error);
        ELSIF i_cdrc = 15
        THEN
            g_error := 'CALL check_procedure';
            log_me(g_error);
            check_procedure(i_lang     => i_lang,
                            i_prof     => i_prof,
                            i_patient  => i_patient,
                            i_episode  => i_episode,
                            i_mode     => i_mode,
                            i_input    => i_input,
                            i_inst_par => i_inst_par,
                            o_ret      => o_ret,
                            o_applic   => o_applic,
                            o_error    => o_error);
        ELSIF i_cdrc = 16
        THEN
            g_error := 'CALL check_lab_test_req_dup';
            log_me(g_error);
            check_lab_test_req_dup(i_lang     => i_lang,
                                   i_prof     => i_prof,
                                   i_patient  => i_patient,
                                   i_episode  => i_episode,
                                   i_mode     => i_mode,
                                   i_input    => i_input,
                                   i_inst_par => i_inst_par,
                                   o_ret      => o_ret,
                                   o_applic   => o_applic,
                                   o_error    => o_error);
        ELSIF i_cdrc = 20
        THEN
            g_error := 'CALL check_ingredient';
            log_me(g_error);
            check_ingredient(i_lang     => i_lang,
                             i_prof     => i_prof,
                             i_patient  => i_patient,
                             i_episode  => i_episode,
                             i_mode     => i_mode,
                             i_input    => i_input,
                             i_inst_par => i_inst_par,
                             o_ret      => o_ret,
                             o_applic   => o_applic,
                             o_error    => o_error);
        ELSIF i_cdrc = 21
        THEN
            g_error := 'CALL check_ingredient_group';
            log_me(g_error);
            check_ingredient_group(i_lang     => i_lang,
                                   i_prof     => i_prof,
                                   i_patient  => i_patient,
                                   i_episode  => i_episode,
                                   i_mode     => i_mode,
                                   i_input    => i_input,
                                   i_inst_par => i_inst_par,
                                   o_ret      => o_ret,
                                   o_applic   => o_applic,
                                   o_error    => o_error);
        ELSIF i_cdrc = 22
        THEN
            g_error := 'CALL check_product';
            log_me(g_error);
            check_product(i_lang     => i_lang,
                          i_prof     => i_prof,
                          i_patient  => i_patient,
                          i_episode  => i_episode,
                          i_mode     => i_mode,
                          i_input    => i_input,
                          i_inst_par => i_inst_par,
                          o_ret      => o_ret,
                          o_applic   => o_applic,
                          o_error    => o_error);
        ELSIF i_cdrc = 23
        THEN
            g_error := 'CALL check_ddi';
            log_me(g_error);
            check_ddi(i_lang     => i_lang,
                      i_prof     => i_prof,
                      i_patient  => i_patient,
                      i_episode  => i_episode,
                      i_mode     => i_mode,
                      i_input    => i_input,
                      i_inst_par => i_inst_par,
                      o_ret      => o_ret,
                      o_applic   => o_applic,
                      o_error    => o_error);
        ELSIF i_cdrc = 24
        THEN
            g_error := 'CALL check_pregnancy_time';
            log_me(g_error);
            check_pregnancy_time(i_lang     => i_lang,
                                 i_prof     => i_prof,
                                 i_patient  => i_patient,
                                 i_episode  => i_episode,
                                 i_mode     => i_mode,
                                 i_input    => i_input,
                                 i_inst_par => i_inst_par,
                                 o_ret      => o_ret,
                                 o_applic   => o_applic,
                                 o_error    => o_error);
        ELSIF i_cdrc = 25
        THEN
            g_error := 'CALL check_diag_synonym';
            check_diag_synonym(i_lang     => i_lang,
                               i_prof     => i_prof,
                               i_patient  => i_patient,
                               i_episode  => i_episode,
                               i_mode     => i_mode,
                               i_input    => i_input,
                               i_inst_par => i_inst_par,
                               o_ret      => o_ret,
                               o_applic   => o_applic,
                               o_error    => o_error);
        ELSIF i_cdrc = 26
        THEN
            g_error := 'CALL check_drug_group';
            log_me(g_error);
            check_drug_group(i_lang     => i_lang,
                             i_prof     => i_prof,
                             i_patient  => i_patient,
                             i_episode  => i_episode,
                             i_mode     => i_mode,
                             i_input    => i_input,
                             i_inst_par => i_inst_par,
                             o_ret      => o_ret,
                             o_applic   => o_applic,
                             o_error    => o_error);
        ELSIF i_cdrc = 27
        THEN
            g_error := 'CALL check_ltr_after_rcm_ack';
            log_me(g_error);
            check_ltr_after_rcm_ack(i_lang     => i_lang,
                                    i_prof     => i_prof,
                                    i_patient  => i_patient,
                                    i_episode  => i_episode,
                                    i_mode     => i_mode,
                                    i_input    => i_input,
                                    i_inst_par => i_inst_par,
                                    o_ret      => o_ret,
                                    o_applic   => o_applic,
                                    o_error    => o_error);
            -- Severity Scores
        ELSIF i_cdrc IN (28, 29)
        THEN
            g_error := 'CALL check_severity_scores';
            log_me(g_error);
            check_severity_scores(i_lang    => i_lang,
                                  i_prof    => i_prof,
                                  i_patient => i_patient,
                                  i_episode => i_episode,
                                  i_mode    => i_mode,
                                  
                                  i_input    => i_input,
                                  i_inst_par => i_inst_par,
                                  o_ret      => o_ret,
                                  o_applic   => o_applic,
                                  o_error    => o_error);
        
            -- EXTERN MEDICATION RULES (VIDAL)
        ELSIF i_cdrc IN (30)
        THEN
        
            IF g_vidal_engine = pk_alert_constant.g_yes
            THEN
                g_error := 'CALL EXTERN MEDICATION RULES ';
                log_me(g_error);
                check_med_extern(i_lang     => i_lang,
                                 i_prof     => i_prof,
                                 i_patient  => i_patient,
                                 i_episode  => i_episode,
                                 i_input    => i_input,
                                 i_inst_par => i_inst_par,
                                 o_ret      => o_ret,
                                 o_applic   => o_applic,
                                 o_error    => o_error);
            END IF;
            -- VITAL SIGNS
        ELSIF i_cdrc IN (31)
        THEN
            g_error := 'CALL VITAL SIGN RULES';
            log_me(g_error);
        
            g_error := 'CALL check_vs';
            check_vs(i_lang     => i_lang,
                     i_prof     => i_prof,
                     i_patient  => i_patient,
                     i_episode  => i_episode,
                     i_mode     => i_mode,
                     i_input    => i_input,
                     i_inst_par => i_inst_par,
                     o_ret      => o_ret,
                     o_applic   => o_applic,
                     o_error    => o_error);
        
        ELSIF i_cdrc IN (32)
        THEN
            g_error := 'CALL RES RULES';
            log_me(g_error);
        
            g_error := 'CALL check_res';
            check_ges(i_lang     => i_lang,
                      i_prof     => i_prof,
                      i_patient  => i_patient,
                      i_episode  => i_episode,
                      i_mode     => i_mode,
                      i_input    => i_input,
                      i_inst_par => i_inst_par,
                      o_ret      => o_ret,
                      o_applic   => o_applic,
                      o_error    => o_error);
        
        ELSIF i_cdrc IN (6, 8, 9, 14, 17, 18, 19)
        THEN
            -- conditions are no longer available
            -- ALERT-255254 - This had a bug if enter here had to do this all null
            o_ret := t_coll_cdr_out(t_rec_cdr_out(ret => NULL, info => NULL, id_user_elem => NULL));
        
        END IF;
    END execute_condition;

    /**
    * Formats the input parameters into a t_coll_cdr_in type.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_concepts     concepts list
    * @param i_elements     elements list
    * @param i_task_types   task type identifiers list
    * @param i_task_reqs    task request identifiers list
    * @param i_dose         dosage values list
    * @param i_dose_um      dosage measurement units list
    * @param i_route        administration routes list
    * @param o_error        error
    *
    * @return               merged t_coll_cdr_in collection
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/03/25
    */
    FUNCTION format_input
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_concepts   IN table_number,
        i_elements   IN table_varchar,
        i_task_types IN table_number,
        i_task_reqs  IN table_varchar,
        i_dose       IN table_number,
        i_dose_um    IN table_number,
        i_route      IN table_varchar,
        o_error      OUT t_error_out
    ) RETURN t_coll_cdr_in IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'FORMAT_INPUT';
        l_ielem_idx CONSTANT PLS_INTEGER := 1; -- element identifier index
        l_uelem_idx CONSTANT PLS_INTEGER := 2; -- user element identifier index
        l_ret              t_coll_cdr_in := t_coll_cdr_in();
        l_use_dose         BOOLEAN;
        l_simple_tt        table_number;
        l_simple_cdrcp     table_number;
        l_idx              PLS_INTEGER;
        l_products         table_table_varchar;
        l_products_temp    table_table_varchar;
        l_products_no_hier table_varchar;
        l_ddis             table_table_varchar;
        l_ingredients      table_table_varchar;
        l_ing_groups       table_table_varchar;
        l_drug_groups      table_table_varchar;
        l_allergies        table_number;
    
        l_str_null CONSTANT VARCHAR2(10) := 'null';
    
        l_content_element VARCHAR2(4000 CHAR);
    
    BEGIN
        -- debug input
        IF g_debug_enable
        THEN
            log_me('=====> PK_CDR_FO_CORE: DEBUG ENABLED');
            g_error := 'i_lang: ' || i_lang;
            g_error := g_error || ', i_prof: ' || pk_utils.to_string(i_input => i_prof);
            g_error := g_error || ', i_concepts: ' || pk_utils.to_string(i_input => i_concepts);
            g_error := g_error || ', i_elements: ' || pk_utils.to_string(i_input => i_elements);
            g_error := g_error || ', i_task_types: ' || pk_utils.to_string(i_input => i_task_types);
            g_error := g_error || ', i_task_reqs: ' || pk_utils.to_string(i_input => i_task_reqs);
            g_error := g_error || ', i_dose: ' || pk_utils.to_string(i_input => i_dose);
            g_error := g_error || ', i_dose_um: ' || pk_utils.to_string(i_input => i_dose_um);
            g_error := g_error || ', i_route: ' || pk_utils.to_string(i_input => i_route);
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        ELSE
            log_me('=====> PK_CDR_FO_CORE: DEBUG DISABLED');
        END IF;
    
        -- check if dosage input is specified
        IF i_dose IS NULL
           OR i_dose.count < 1
        THEN
            l_use_dose := FALSE;
        ELSIF i_dose_um IS NULL
              OR i_route IS NULL
              OR i_dose.count != i_dose_um.count
              OR i_dose.count != i_route.count
        THEN
            g_error := 'Dosage count mismatch!';
            RAISE g_fault;
        ELSE
            l_use_dose := TRUE;
        END IF;
    
        IF i_concepts IS NOT NULL
           AND i_concepts.count > 0
        THEN
            -- set user input using rule concepts:
            -- validate input
            IF i_elements IS NULL
               OR i_concepts.count != i_elements.count
            THEN
                g_error := 'Element count mismatch!';
                RAISE g_fault;
            END IF;
        
            -- set input
            l_ret.extend(i_concepts.count);
            log_me('==>CONCEPTS COUNT: ' || i_concepts.count);
        
            FOR i IN i_concepts.first .. i_concepts.last
            LOOP
                log_me('===>CONCEPTS INSERT: ' || i || ' elements: ' || i_elements(i));
            
                IF i_concepts(i) = pk_cdr_constant.g_cdrcp_lab_test
                THEN
                    log_me('======> GET CONCEPT ID_CONTENT: ' || i_concepts(i));
                    l_content_element := pk_lab_tests_external_api_db.get_lab_test_id_content(i_lang     => i_lang,
                                                                                              i_prof     => i_prof,
                                                                                              i_analysis => i_elements(i));
                    log_me('======> GET CONCEPT ID_CONTENT: ' || l_content_element);
                ELSIF i_concepts(i) = pk_cdr_constant.g_cdrcp_lab_test_par
                THEN
                    log_me('======> GET CONCEPT ID_CONTENT: ' || i_concepts(i));
                    l_content_element := pk_lab_tests_external_api_db.get_lab_test_param_id_content(i_lang,
                                                                                                    i_prof               => i_prof,
                                                                                                    i_analysis_parameter => i_elements(i));
                    log_me('======> GET CONCEPT ID_CONTENT: ' || l_content_element);
                
                ELSIF i_concepts(i) = pk_cdr_constant.g_cdrcp_exam
                THEN
                    log_me('======> GET CONCEPT ID_CONTENT: ' || i_concepts(i));
                    l_content_element := pk_exams_external_api_db.get_exam_id_content(i_lang,
                                                                                      i_prof => i_prof,
                                                                                      i_exam => i_elements(i));
                    log_me('======> GET CONCEPT ID_CONTENT: ' || l_content_element);
                
                ELSE
                    l_content_element := i_elements(i);
                END IF;
            
                IF l_use_dose
                THEN
                    l_ret(i) := t_rec_cdr_in(id_cdr_concept => i_concepts(i),
                                             id_element     => l_content_element,
                                             dose           => i_dose(i),
                                             id_dose_umea   => i_dose_um(i),
                                             route_id       => i_route(i),
                                             id_task_type   => NULL,
                                             id_task_req    => NULL,
                                             id_user_elem   => NULL);
                ELSE
                    l_ret(i) := t_rec_cdr_in(id_cdr_concept => i_concepts(i),
                                             id_element     => l_content_element,
                                             dose           => NULL,
                                             id_dose_umea   => NULL,
                                             route_id       => NULL,
                                             id_task_type   => NULL,
                                             id_task_req    => NULL,
                                             id_user_elem   => NULL);
                END IF;
            END LOOP;
        
        ELSIF i_task_types IS NOT NULL
              AND i_task_types.count > 0
        THEN
            -- set user input using task types:
            -- validate input
            IF i_task_reqs IS NULL
               OR i_task_types.count != i_task_reqs.count
            THEN
                g_error := 'Tasks count mismatch!';
                RAISE g_fault;
            END IF;
        
            log_me('=>recebi: task_types: ' || i_task_types.count);
            log_me('=>recebi: task_reqs: ' || i_task_reqs.count);
        
            FOR i IN i_task_types.first .. i_task_types.last
            LOOP
                IF i_task_types(i) IN (pk_cdr_constant.g_tt_medication, pk_cdr_constant.g_tt_medication_by_prod)
                THEN
                
                    log_me('=>TASK_REQ: ' || i_task_reqs(i));
                
                    IF i_task_types(i) = pk_cdr_constant.g_tt_medication
                    THEN
                        -- unfold prescription task types in concepts
                        g_error := 'CALL pk_api_pfh_clindoc_in.get_cdr_concepts_by_presc';
                        pk_api_pfh_clindoc_in.get_cdr_concepts_by_presc(i_lang                    => i_lang,
                                                                        i_prof                    => i_prof,
                                                                        i_id_presc                => i_task_reqs(i),
                                                                        o_products                => l_products_temp,
                                                                        o_id_products_no_hierarch => l_products_no_hier,
                                                                        o_ddis                    => l_ddis,
                                                                        o_ingreds                 => l_ingredients,
                                                                        o_ing_groups              => l_ing_groups,
                                                                        o_pharm_theraps           => l_drug_groups,
                                                                        o_error                   => o_error);
                    
                        l_products := table_table_varchar();
                        FOR k IN 1 .. l_products_no_hier.count
                        LOOP
                            l_products.extend;
                            l_products(l_products.last) := table_varchar(l_products_no_hier(k), l_products_no_hier(k));
                        END LOOP;
                    
                    ELSIF i_task_types(i) = pk_cdr_constant.g_tt_medication_by_prod
                    THEN
                        -- unfold prescription task types in concepts
                        g_error := 'CALL pk_api_pfh_clindoc_in.get_cdr_concepts_by_prod';
                        pk_api_pfh_clindoc_in.get_cdr_concepts_by_prod(i_lang           => i_lang,
                                                                       i_prof           => i_prof,
                                                                       i_id_product_sup => table_varchar(i_task_reqs(i)),
                                                                       o_products       => l_products,
                                                                       o_ddis           => l_ddis,
                                                                       o_ingreds        => l_ingredients,
                                                                       o_ing_groups     => l_ing_groups,
                                                                       o_pharm_theraps  => l_drug_groups,
                                                                       o_error          => o_error);
                    END IF;
                
                    log_me('===>  l_products: ' || l_products.count);
                    log_me('===> l_ddis: ' || l_ddis.count);
                    log_me('===>  l_ingredients: ' || l_ingredients.count);
                    log_me('===>  l_ing_groups: ' || l_ing_groups.count);
                    log_me('===>  l_drug_groups: ' || l_drug_groups.count);
                
                    FOR j IN 1 .. l_products.count
                    LOOP
                    
                        log_me('======> insert: products: ' || l_products(j)
                               (l_ielem_idx) || ' id_task_req    => ' || i_task_reqs(i));
                        l_ret.extend;
                        IF l_use_dose
                        THEN
                            l_ret(l_ret.last) := t_rec_cdr_in(id_cdr_concept => pk_cdr_constant.g_cdrcp_product,
                                                              id_element     => l_products(j) (l_ielem_idx),
                                                              dose           => i_dose(i),
                                                              id_dose_umea   => i_dose_um(i),
                                                              route_id       => i_route(i),
                                                              id_task_type   => i_task_types(i),
                                                              id_task_req    => i_task_reqs(i),
                                                              id_user_elem   => l_products(j) (l_uelem_idx));
                        ELSE
                            l_ret(l_ret.last) := t_rec_cdr_in(id_cdr_concept => pk_cdr_constant.g_cdrcp_product,
                                                              id_element     => l_products(j) (l_ielem_idx),
                                                              dose           => NULL,
                                                              id_dose_umea   => NULL,
                                                              route_id       => NULL,
                                                              id_task_type   => i_task_types(i),
                                                              id_task_req    => i_task_reqs(i),
                                                              id_user_elem   => l_products(j) (l_uelem_idx));
                        END IF;
                    END LOOP;
                    FOR j IN 1 .. l_ddis.count
                    LOOP
                        log_me('======> insert: l_ddis: ' || l_ddis(j)
                               (l_ielem_idx) || ' id_task_req    => ' || i_task_reqs(i));
                    
                        l_ret.extend;
                        IF l_use_dose
                        THEN
                            l_ret(l_ret.last) := t_rec_cdr_in(id_cdr_concept => pk_cdr_constant.g_cdrcp_ddi,
                                                              id_element     => l_ddis(j) (l_ielem_idx),
                                                              dose           => i_dose(i),
                                                              id_dose_umea   => i_dose_um(i),
                                                              route_id       => i_route(i),
                                                              id_task_type   => i_task_types(i),
                                                              id_task_req    => i_task_reqs(i),
                                                              id_user_elem   => l_ddis(j) (l_uelem_idx));
                        ELSE
                            l_ret(l_ret.last) := t_rec_cdr_in(id_cdr_concept => pk_cdr_constant.g_cdrcp_ddi,
                                                              id_element     => l_ddis(j) (l_ielem_idx),
                                                              dose           => NULL,
                                                              id_dose_umea   => NULL,
                                                              route_id       => NULL,
                                                              id_task_type   => i_task_types(i),
                                                              id_task_req    => i_task_reqs(i),
                                                              id_user_elem   => l_ddis(j) (l_uelem_idx));
                        END IF;
                    END LOOP;
                    FOR j IN 1 .. l_ingredients.count
                    LOOP
                    
                        log_me('======> insert: l_ingredients: ' || l_ingredients(j)
                               (l_ielem_idx) || ' id_task_req    => ' || i_task_reqs(i));
                        l_ret.extend;
                        IF l_use_dose
                        THEN
                            l_ret(l_ret.last) := t_rec_cdr_in(id_cdr_concept => pk_cdr_constant.g_cdrcp_ingredient,
                                                              id_element     => l_ingredients(j) (l_ielem_idx),
                                                              dose           => i_dose(i),
                                                              id_dose_umea   => i_dose_um(i),
                                                              route_id       => i_route(i),
                                                              id_task_type   => i_task_types(i),
                                                              id_task_req    => i_task_reqs(i),
                                                              id_user_elem   => l_ingredients(j) (l_uelem_idx));
                        ELSE
                            l_ret(l_ret.last) := t_rec_cdr_in(id_cdr_concept => pk_cdr_constant.g_cdrcp_ingredient,
                                                              id_element     => l_ingredients(j) (l_ielem_idx),
                                                              dose           => NULL,
                                                              id_dose_umea   => NULL,
                                                              route_id       => NULL,
                                                              id_task_type   => i_task_types(i),
                                                              id_task_req    => i_task_reqs(i),
                                                              id_user_elem   => l_ingredients(j) (l_uelem_idx));
                        END IF;
                    END LOOP;
                    FOR j IN 1 .. l_ing_groups.count
                    LOOP
                        log_me('======> insert: l_ing_groups: ' || l_ing_groups(j)
                               (l_ielem_idx) || ' id_task_req    => ' || i_task_reqs(i));
                        l_ret.extend;
                        IF l_use_dose
                        THEN
                            l_ret(l_ret.last) := t_rec_cdr_in(id_cdr_concept => pk_cdr_constant.g_cdrcp_ingr_group,
                                                              id_element     => l_ing_groups(j) (l_ielem_idx),
                                                              dose           => i_dose(i),
                                                              id_dose_umea   => i_dose_um(i),
                                                              route_id       => i_route(i),
                                                              id_task_type   => i_task_types(i),
                                                              id_task_req    => i_task_reqs(i),
                                                              id_user_elem   => l_ing_groups(j) (l_uelem_idx));
                        ELSE
                            l_ret(l_ret.last) := t_rec_cdr_in(id_cdr_concept => pk_cdr_constant.g_cdrcp_ingr_group,
                                                              id_element     => l_ing_groups(j) (l_ielem_idx),
                                                              dose           => NULL,
                                                              id_dose_umea   => NULL,
                                                              route_id       => NULL,
                                                              id_task_type   => i_task_types(i),
                                                              id_task_req    => i_task_reqs(i),
                                                              id_user_elem   => l_ing_groups(j) (l_uelem_idx));
                        END IF;
                    END LOOP;
                    FOR j IN 1 .. l_drug_groups.count
                    LOOP
                        log_me('======> insert: l_drug_groups: ' || l_drug_groups(j)
                               (l_ielem_idx) || ' id_task_req    => ' || i_task_reqs(i));
                        l_ret.extend;
                        IF l_use_dose
                        THEN
                            l_ret(l_ret.last) := t_rec_cdr_in(id_cdr_concept => pk_cdr_constant.g_cdrcp_drug_group,
                                                              id_element     => l_drug_groups(j) (l_ielem_idx),
                                                              dose           => i_dose(i),
                                                              id_dose_umea   => i_dose_um(i),
                                                              route_id       => i_route(i),
                                                              id_task_type   => i_task_types(i),
                                                              id_task_req    => i_task_reqs(i),
                                                              id_user_elem   => l_drug_groups(j) (l_uelem_idx));
                        ELSE
                            l_ret(l_ret.last) := t_rec_cdr_in(id_cdr_concept => pk_cdr_constant.g_cdrcp_drug_group,
                                                              id_element     => l_drug_groups(j) (l_ielem_idx),
                                                              dose           => NULL,
                                                              id_dose_umea   => NULL,
                                                              route_id       => NULL,
                                                              id_task_type   => i_task_types(i),
                                                              id_task_req    => i_task_reqs(i),
                                                              id_user_elem   => l_drug_groups(j) (l_uelem_idx));
                        END IF;
                    END LOOP;
                ELSIF i_task_types(i) = pk_cdr_constant.g_tt_allergy
                      AND nvl(i_task_reqs(i), l_str_null) <> l_str_null
                THEN
                    -- unfold allergy task types in concepts
                    g_error     := 'CALL pk_allergy.get_allergy_ingr_list';
                    l_allergies := pk_allergy.get_allergy_ingr_list(i_lang    => i_lang,
                                                                    i_prof    => i_prof,
                                                                    i_allergy => to_number(i_task_reqs(i)));
                
                    FOR j IN 1 .. l_allergies.count
                    LOOP
                        l_ret.extend;
                        IF l_use_dose
                        THEN
                            l_ret(l_ret.last) := t_rec_cdr_in(id_cdr_concept => pk_cdr_constant.g_cdrcp_allergy,
                                                              id_element     => l_allergies(j),
                                                              dose           => i_dose(i),
                                                              id_dose_umea   => i_dose_um(i),
                                                              route_id       => i_route(i),
                                                              id_task_type   => i_task_types(i),
                                                              id_task_req    => i_task_reqs(i),
                                                              id_user_elem   => NULL);
                        ELSE
                            l_ret(l_ret.last) := t_rec_cdr_in(id_cdr_concept => pk_cdr_constant.g_cdrcp_allergy,
                                                              id_element     => l_allergies(j),
                                                              dose           => NULL,
                                                              id_dose_umea   => NULL,
                                                              route_id       => NULL,
                                                              id_task_type   => i_task_types(i),
                                                              id_task_req    => i_task_reqs(i),
                                                              id_user_elem   => NULL);
                        END IF;
                    END LOOP;
                
                ELSE
                
                    -- get list of concepts whose conversion is "simple"
                    g_error := 'OPEN c_simple_conv_tt';
                    OPEN c_simple_conv_tt;
                    FETCH c_simple_conv_tt BULK COLLECT
                        INTO l_simple_tt, l_simple_cdrcp;
                    CLOSE c_simple_conv_tt;
                
                    log_me('======> SEARCH TASK TYPE IN SIMPLE CONVERSION LIST, AND DO A DIRECT CONVERSION');
                    -- search task type in simple conversion list, and do a direct conversion
                    l_idx := pk_utils.search_table_number(i_table => l_simple_tt, i_search => i_task_types(i));
                    IF l_idx > 0
                    THEN
                        l_ret.extend;
                        log_me('CONVERSION FOUND: ADDED: ' || i_task_types(i) || ' : ' || i_task_reqs(i));
                        IF l_use_dose
                        THEN
                            l_ret(l_ret.last) := t_rec_cdr_in(id_cdr_concept => l_simple_cdrcp(l_idx),
                                                              id_element     => i_task_reqs(i),
                                                              dose           => i_dose(i),
                                                              id_dose_umea   => i_dose_um(i),
                                                              route_id       => i_route(i),
                                                              id_task_type   => i_task_types(i),
                                                              id_task_req    => i_task_reqs(i),
                                                              id_user_elem   => NULL);
                        ELSE
                            l_ret(l_ret.last) := t_rec_cdr_in(id_cdr_concept => l_simple_cdrcp(l_idx),
                                                              id_element     => i_task_reqs(i),
                                                              dose           => NULL,
                                                              id_dose_umea   => NULL,
                                                              route_id       => NULL,
                                                              id_task_type   => i_task_types(i),
                                                              id_task_req    => i_task_reqs(i),
                                                              id_user_elem   => NULL);
                        
                        END IF;
                    END IF;
                END IF;
            END LOOP;
        ELSE
            l_ret := t_coll_cdr_in();
        END IF;
    
        -- debug output
        IF g_debug_enable
        THEN
            IF l_ret IS NULL
            THEN
                g_error := 'input is NULL!';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            ELSIF l_ret.count < 1
            THEN
                g_error := 'input is EMPTY!';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            ELSE
                FOR i IN l_ret.first .. l_ret.last
                LOOP
                    g_error := i || '= id_cdr_concept: ' || l_ret(i).id_cdr_concept;
                    g_error := g_error || ', id_element: ' || l_ret(i).id_element;
                    g_error := g_error || ', id_task_type: ' || l_ret(i).id_task_type;
                    g_error := g_error || ', id_task_req: ' || l_ret(i).id_task_req;
                    g_error := g_error || ', id_user_elem: ' || l_ret(i).id_user_elem;
                    g_error := g_error || ', dose: ' || l_ret(i).dose;
                    g_error := g_error || ', id_dose_umea: ' || l_ret(i).id_dose_umea;
                    g_error := g_error || ', route_id: ' || l_ret(i).route_id;
                    pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                END LOOP;
            END IF;
        END IF;
    
        RETURN l_ret;
    END format_input;

    /**
    * Add two validities, given a boolean operator
    * ('Y' is considered TRUE, everything else is FALSE).
    *
    * @param i_a            first validity
    * @param i_b            second validity
    * @param i_oper         operator: (A)nd, (O)r
    *
    * @return               resulting validity
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/03/25
    */
    FUNCTION add_validity
    (
        i_a    IN VARCHAR2,
        i_b    IN VARCHAR2,
        i_oper IN cdr_def_cond.flg_condition%TYPE
    ) RETURN VARCHAR2 IS
        l_ret  VARCHAR2(1 CHAR);
        l_oper cdr_def_cond.flg_condition%TYPE;
    BEGIN
        -- set operator
        IF i_oper IS NULL
        THEN
            l_oper := pk_cdr_constant.g_oper_or; -- defaults to "or"
        ELSE
            l_oper := i_oper;
        END IF;
    
        -- add validity
        IF l_oper = pk_cdr_constant.g_oper_and
        THEN
            IF i_a = pk_alert_constant.g_yes
            THEN
                l_ret := nvl(i_b, pk_alert_constant.g_no);
            ELSE
                l_ret := pk_alert_constant.g_no;
            END IF;
        ELSIF l_oper = pk_cdr_constant.g_oper_or
        THEN
            IF i_a = pk_alert_constant.g_yes
            THEN
                l_ret := pk_alert_constant.g_yes;
            ELSE
                l_ret := nvl(i_b, pk_alert_constant.g_no);
            END IF;
        END IF;
    
        RETURN l_ret;
    END add_validity;

    /**
    * Adds a call detail to the call details collection.
    *
    * @param i_cdrld        call detail
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.2
    * @since                2011/09/26
    */
    PROCEDURE add_cdrld(i_cdrld IN t_rec_cdrld) IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'ADD_CDRLD';
    BEGIN
        IF g_cdrld_rows IS NULL
           OR g_cdrld_rows.count < 1
        THEN
            g_cdrld_rows := t_coll_cdrld(i_cdrld);
        ELSE
            g_cdrld_rows.extend;
            g_cdrld_rows(g_cdrld_rows.last) := i_cdrld;
        END IF;
    
        IF g_debug_enable
        THEN
            g_error := 'id_cdr_inst_param: ' || i_cdrld.id_cdr_inst_param;
            g_error := g_error || ', id_cdr_instance: ' || i_cdrld.id_cdr_instance;
            g_error := g_error || ', id_task_type: ' || i_cdrld.id_task_type;
            g_error := g_error || ', id_task_request: ' || i_cdrld.id_task_request;
            g_error := g_error || ', param_value: ' || i_cdrld.param_value;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    END add_cdrld;

    /**
    * Get conditions to evaluate.
    * Checks which conditions are applicable by concept type.
    *
    * @param i_input        input parameters list
    *
    * @return               list of conditions
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/13
    */
    FUNCTION get_conditions
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_input   IN t_coll_cdr_in
    ) RETURN table_number IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_CONDITIONS';
        l_ret      table_number := table_number();
        l_cond     table_number;
        l_cond_ret t_coll_cdr_out;
        l_error    t_error_out;
        l_applic   PLS_INTEGER;
    
        CURSOR c_cond IS
            SELECT cdrc.id_cdr_condition
              FROM cdr_condition cdrc
             WHERE cdrc.flg_available = pk_alert_constant.g_yes;
    BEGIN
        g_error := 'OPEN c_cond';
        OPEN c_cond;
        FETCH c_cond BULK COLLECT
            INTO l_cond;
        CLOSE c_cond;
    
        FOR i IN 1 .. l_cond.count
        LOOP
            execute_condition(i_lang     => i_lang,
                              i_prof     => i_prof,
                              i_patient  => i_patient,
                              i_episode  => i_episode,
                              i_cdrc     => l_cond(i),
                              i_mode     => g_mode_concept,
                              i_input    => i_input,
                              i_inst_par => t_coll_cdrip(),
                              o_ret      => l_cond_ret,
                              o_applic   => l_applic,
                              o_error    => l_error);
        
            IF l_applic = g_supported
            THEN
                l_ret.extend;
                l_ret(l_ret.last) := l_cond(i);
            END IF;
        END LOOP;
    
        -- debug conditions to evaluate
        log_tn(i_tn => l_ret, i_func_name => l_func_name);
    
        RETURN l_ret;
    END get_conditions;

    /**
    * Get definitions to evaluate.
    * Returns the list of definitions whose conditions contain
    * at least one that belongs to the "i_cond" list.
    *
    * @param i_prof         logged professional structure
    * @param i_cond         list of conditions to evaluate
    *
    * @return               list of definitions
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/13
    */
    FUNCTION get_definitions_by_cond
    (
        i_prof        IN profissional,
        i_cond        IN table_number,
        i_screen_name IN VARCHAR2
    ) RETURN table_number IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_DEFINITIONS_BY_COND';
        l_ret         table_number := table_number();
        l_prof_cat    category.id_category%TYPE;
        l_market      market.id_market%TYPE;
        l_screen_name VARCHAR2(0200 CHAR) := i_screen_name;
    
        CURSOR c_def IS
            SELECT cdrd.id_cdr_definition
              FROM cdr_definition cdrd
             WHERE cdrd.id_institution IN (0, i_prof.institution)
               AND cdrd.flg_status IN (pk_alert_constant.g_active, pk_cdr_constant.g_edited)
               AND cdrd.flg_available = pk_alert_constant.g_yes
               AND cdrd.flg_generic = pk_alert_constant.g_yes
               AND cdrd.id_cdr_definition IN
                   (SELECT cdrdc.id_cdr_definition
                      FROM cdr_def_cond cdrdc
                     WHERE cdrdc.id_cdr_condition IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                       t.column_value id_cdr_condition
                                                        FROM TABLE(i_cond) t))
               AND EXISTS (SELECT NULL
                      FROM cdr_def_mkt cdrdm
                     WHERE cdrdm.id_cdr_definition = cdrd.id_cdr_definition
                       AND cdrdm.id_category IN (-1, l_prof_cat)
                       AND cdrdm.id_software IN (0, i_prof.software)
                       AND cdrdm.id_market IN (0, l_market)
                    UNION ALL
                    SELECT NULL
                      FROM cdr_def_inst cdrdi
                     WHERE cdrdi.id_cdr_definition = cdrd.id_cdr_definition
                       AND cdrdi.id_category IN (-1, l_prof_cat)
                       AND cdrdi.id_software IN (0, i_prof.software)
                       AND cdrdi.id_institution = i_prof.institution
                       AND cdrdi.flg_add_remove = pk_cdr_constant.g_add)
               AND NOT EXISTS (SELECT NULL
                      FROM cdr_def_inst cdrdi
                     WHERE cdrdi.id_cdr_definition = cdrd.id_cdr_definition
                       AND cdrdi.id_category IN (-1, l_prof_cat)
                       AND cdrdi.id_software IN (0, i_prof.software)
                       AND cdrdi.id_institution = i_prof.institution
                       AND cdrdi.flg_add_remove = pk_cdr_constant.g_rem)
                  -- Disable specific cdr_definition for a given screen_name
               AND NOT EXISTS (SELECT NULL
                      FROM cdr_scr_def_exception csde
                     WHERE csde.id_cdr_definition = cdrd.id_cdr_definition
                       AND csde.id_institution = i_prof.institution
                       AND csde.screen_name = l_screen_name);
    BEGIN
        l_prof_cat := pk_prof_utils.get_id_category(i_lang => NULL, i_prof => i_prof);
        l_market   := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
    
        g_error := 'OPEN c_def';
        OPEN c_def;
        FETCH c_def BULK COLLECT
            INTO l_ret;
        CLOSE c_def;
    
        -- debug definitions to evaluate
        log_tn(i_tn => l_ret, i_func_name => l_func_name);
    
        RETURN l_ret;
    END get_definitions_by_cond;

    /**
    * Get instances to evaluate, through condition execution.
    * Returns a list of applicable instances of the given definitions.
    *
    * @param i_prof         logged professional structure
    * @param i_input        input parameters list
    * @param i_def          list of definitions to evaluate
    *
    * @return               list of instances
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/13
    */
    FUNCTION get_instances_by_cond
    (
        i_prof  IN profissional,
        i_input IN t_coll_cdr_in,
        i_def   IN table_number
    ) RETURN table_number IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_INSTANCES_BY_COND';
        l_ret           table_number := table_number();
        l_inst          t_coll_cdrip; -- all instance parameters
        l_idx           PLS_INTEGER := 1; -- collection index
        l_cond_count    PLS_INTEGER; -- current instance condition count
        l_cdrc          cdr_condition.id_cdr_condition%TYPE; -- current instance condition identifier
        l_par_count     PLS_INTEGER; -- current instance condition parameter count
        l_curr_cond_par t_coll_cdrip; -- current instance condition parameters
        l_cond_ret      t_coll_cdr_out;
        l_error         t_error_out;
        l_cond_applic   PLS_INTEGER; -- current instance condition applicability
        l_inst_applic   PLS_INTEGER; -- current instance applicability
    
        CURSOR c_inst IS
            SELECT t_rec_cdrip(NULL,
                               cdri.id_cdr_instance,
                               cdrc.id_cdr_condition,
                               cdrip.id_cdr_parameter,
                               cdrp.id_cdr_concept,
                               NULL,
                               NULL,
                               NULL,
                               NULL,
                               cdrc.flg_dosage,
                               cdrip.id_element,
                               NULL,
                               NULL,
                               NULL,
                               NULL,
                               NULL,
                               NULL,
                               NULL,
                               COUNT(cdrc.id_cdr_condition) over(PARTITION BY cdri.id_cdr_instance),
                               COUNT(DISTINCT cdrp.id_cdr_parameter) over(PARTITION BY cdrp.id_cdr_def_cond))
              FROM cdr_instance cdri
              JOIN cdr_inst_param cdrip
                ON cdri.id_cdr_instance = cdrip.id_cdr_instance
              JOIN cdr_parameter cdrp
                ON cdrip.id_cdr_parameter = cdrp.id_cdr_parameter
              JOIN cdr_def_cond cdrdc
                ON cdrp.id_cdr_def_cond = cdrdc.id_cdr_def_cond
              JOIN cdr_condition cdrc
                ON cdrdc.id_cdr_condition = cdrc.id_cdr_condition
             WHERE cdri.id_cdr_definition IN (SELECT /*+opt_estimate(table t rows=1)*/
                                               t.column_value id_cdr_definition
                                                FROM TABLE(i_def) t)
               AND cdri.id_institution IN (0, i_prof.institution)
               AND cdri.flg_status IN (pk_alert_constant.g_active, pk_cdr_constant.g_edited)
               AND cdri.flg_available = pk_alert_constant.g_yes
             ORDER BY cdri.id_cdr_instance, cdrdc.rank, cdrp.rank;
    BEGIN
        -- fetch a list with all instantiated parameters
        g_error := 'OPEN c_inst';
        OPEN c_inst;
        FETCH c_inst BULK COLLECT
            INTO l_inst;
        CLOSE c_inst;
    
        -- TODO l_inst collection loop may need memory optimization!
    
        -- iterate over the entire list
        WHILE l_inst.count >= l_idx
        LOOP
            -- INSTANCE LOOP
            -- reset instance id, condition count, and instance applicability
            l_cond_count  := l_inst(l_idx).cond_count;
            l_inst_applic := NULL;
        
            FOR i IN 1 .. l_cond_count
            LOOP
                -- CONDITION LOOP
                -- reset parameter count, condition service,
                -- instantiated parameter list, and condition applicability
                l_par_count     := l_inst(l_idx).cond_par_count;
                l_cdrc          := l_inst(l_idx).id_cdr_condition;
                l_curr_cond_par := t_coll_cdrip();
                l_cond_applic   := NULL;
            
                FOR j IN 1 .. l_par_count
                LOOP
                    -- PARAMETER LOOP
                    -- append parameter to list of instantiated parameters, increment index
                    l_curr_cond_par.extend;
                    l_curr_cond_par(l_curr_cond_par.last) := l_inst(l_idx);
                    l_idx := l_idx + 1;
                END LOOP;
            
                IF l_inst_applic = g_usable
                THEN
                    -- performance improvement: if this instance is already usable,
                    -- there's no need to check the applicability of all other conditions,
                    -- just continue the loop and do nothing
                    NULL;
                ELSE
                    -- execute condition in instance mode
                    execute_condition(i_lang     => NULL,
                                      i_prof     => i_prof,
                                      i_patient  => NULL,
                                      i_episode  => NULL,
                                      i_cdrc     => l_cdrc,
                                      i_mode     => g_mode_instance,
                                      i_input    => i_input,
                                      i_inst_par => l_curr_cond_par,
                                      o_ret      => l_cond_ret,
                                      o_applic   => l_cond_applic,
                                      o_error    => l_error);
                
                    -- update instance applicability
                    l_inst_applic := add_applicability(i_app_a => l_inst_applic, i_app_b => l_cond_applic);
                END IF;
            END LOOP;
        
            IF l_inst_applic = g_usable
            THEN
                -- instance is usable: append it to the return list
                l_ret.extend;
                l_ret(l_ret.last) := l_inst(l_idx - 1).id_cdr_instance;
            END IF;
        END LOOP;
    
        -- debug instances to evaluate
        log_tn(i_tn => l_ret, i_func_name => l_func_name);
    
        RETURN l_ret;
    END get_instances_by_cond;

    /**
    * Get instances to evaluate, through SQL query.
    * Returns a list of applicable instances of the given definitions.
    *
    * @param i_prof         logged professional structure
    * @param i_input        input parameters list
    * @param i_def          list of definitions to evaluate
    *
    * @return               list of instances
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/13
    */
    FUNCTION get_instances_by_sql
    (
        i_prof  IN profissional,
        i_input IN t_coll_cdr_in,
        i_def   IN table_number
    ) RETURN table_number IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_INSTANCES_BY_SQL';
        l_ret table_number := table_number();
    
        CURSOR c_inst IS
            SELECT /*+opt_estimate(table ti rows=10) opt_estimate(table td rows=5) opt_param('_optimizer_use_feedback','false')*/
             cdri.id_cdr_instance
              FROM cdr_instance cdri
              JOIN cdr_inst_param cdrip
                ON cdri.id_cdr_instance = cdrip.id_cdr_instance
              JOIN cdr_parameter cdrp
                ON cdrip.id_cdr_parameter = cdrp.id_cdr_parameter
              JOIN tbl_temp ti
                ON cdrp.id_cdr_concept = ti.num_1
               AND cdrip.id_element = ti.vc_1
              JOIN tbl_temp td
                ON cdri.id_cdr_definition = td.num_2
             WHERE cdri.id_institution IN (0, i_prof.institution)
               AND cdri.flg_status IN (pk_alert_constant.g_active, pk_cdr_constant.g_edited)
               AND cdri.flg_available = pk_alert_constant.g_yes
             GROUP BY cdri.id_cdr_instance;
    BEGIN
        EXECUTE IMMEDIATE 'truncate table tbl_temp';
    
        INSERT INTO tbl_temp
            (num_1, vc_1)
            SELECT t.id_cdr_concept, t.id_element
              FROM TABLE(i_input) t;
    
        INSERT INTO tbl_temp
            (num_2)
            SELECT t.column_value id_cdr_definition
              FROM TABLE(i_def) t;
    
        g_error := 'OPEN c_inst';
        OPEN c_inst;
        FETCH c_inst BULK COLLECT
            INTO l_ret;
        CLOSE c_inst;
    
        -- debug instances to evaluate
        log_tn(i_tn => l_ret, i_func_name => l_func_name);
    
        RETURN l_ret;
    END get_instances_by_sql;

    /**
    * Get instances to evaluate, through its definitions.
    * Returns a list of applicable instances of the given definitions.
    *
    * @param i_prof         logged professional structure
    * @param i_def          list of definitions to evaluate
    *
    * @return               list of instances
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.3
    * @since                2011/10/07
    */
    FUNCTION get_instances_by_def
    (
        i_prof IN profissional,
        i_def  IN table_number
    ) RETURN table_number IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_INSTANCES_BY_DEF';
        l_ret table_number := table_number();
    
        CURSOR c_inst IS
            SELECT cdri.id_cdr_instance
              FROM cdr_instance cdri
             WHERE cdri.id_cdr_definition IN (SELECT /*+opt_estimate(table t rows=1)*/
                                               t.column_value id_cdr_definition
                                                FROM TABLE(i_def) t)
               AND cdri.id_institution IN (0, i_prof.institution)
               AND cdri.flg_status IN (pk_alert_constant.g_active, pk_cdr_constant.g_edited)
               AND cdri.flg_available = pk_alert_constant.g_yes;
    BEGIN
        -- fetch a list with all instantiated parameters
        g_error := 'OPEN c_inst';
        OPEN c_inst;
        FETCH c_inst BULK COLLECT
            INTO l_ret;
        CLOSE c_inst;
    
        -- debug instances to evaluate
        log_tn(i_tn => l_ret, i_func_name => l_func_name);
    
        RETURN l_ret;
    END get_instances_by_def;

    /**
    * Get instance validity, by assessing all conditions validity
    * and operators.
    *
    * @param i_val          condition validities
    * @param i_oper         condition operators
    *
    * @return               instance validity
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/05/03
    */
    FUNCTION get_inst_validity
    (
        i_val  IN table_varchar,
        i_oper IN table_varchar
    ) RETURN VARCHAR2 IS
        l_ret       VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_val       table_varchar := table_varchar(); -- internal condition validities
        l_oper      table_varchar := table_varchar(); -- internal condition operators (OR's only)
        l_have_prev BOOLEAN := FALSE; -- is previous condition validity available?
        l_prev_val  VARCHAR2(1 CHAR) := pk_alert_constant.g_yes; -- previous condition validity
    BEGIN
        IF i_val IS NULL
           OR i_oper IS NULL
           OR i_val.count != i_oper.count
           OR i_val.count < 1
        THEN
            NULL;
        ELSE
            FOR i IN 1 .. i_val.count
            LOOP
            
                IF i_oper(i) = pk_cdr_constant.g_oper_and
                THEN
                    IF l_have_prev
                    THEN
                        l_prev_val := add_validity(i_a    => l_prev_val,
                                                   i_b    => i_val(i),
                                                   i_oper => pk_cdr_constant.g_oper_and);
                    ELSE
                        l_prev_val  := i_val(i);
                        l_have_prev := TRUE;
                    END IF;
                
                ELSE
                    l_val.extend;
                    l_oper.extend;
                    l_oper(l_oper.last) := pk_cdr_constant.g_oper_or;
                
                    IF l_have_prev
                    THEN
                        l_val(l_val.last) := add_validity(i_a    => l_prev_val,
                                                          i_b    => i_val(i),
                                                          i_oper => pk_cdr_constant.g_oper_and);
                    
                        -- clear previous validity
                        l_have_prev := FALSE;
                    ELSE
                        l_val(l_val.last) := i_val(i);
                    END IF;
                END IF;
            END LOOP;
        
            -- loop "appended" validities:
            -- if one of them is true, the instance is true
            FOR i IN 1 .. l_val.count
            LOOP
                IF l_val(i) = pk_alert_constant.g_yes
                THEN
                    l_ret := pk_alert_constant.g_yes;
                    EXIT;
                END IF;
            END LOOP;
        END IF;
    
        RETURN l_ret;
    END get_inst_validity;

    /**
    * Get instance validity, by executing all of its conditions in full mode
    * (ie, against the EHR).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_input        input parameters list
    * @param i_inst         applicable instance identifiers list
    * @param o_error        error
    *
    * @return               instance validity
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/05/03
    */
    FUNCTION get_inst_validity
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_input   IN t_coll_cdr_in,
        i_inst    IN t_coll_cdrip,
        o_error   OUT t_error_out
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_INST_VALIDITY';
        l_idx           PLS_INTEGER := 1; -- collection index
        l_cond_count    PLS_INTEGER; -- current instance condition count
        l_cdrc          cdr_condition.id_cdr_condition%TYPE; -- current instance condition identifier
        l_par_count     PLS_INTEGER; -- current instance condition parameter count
        l_curr_cond_par t_coll_cdrip; -- current instance condition parameters
        l_cond_ret      t_coll_cdr_out;
        l_cond_applic   PLS_INTEGER;
        l_cond_val      VARCHAR2(1 CHAR); -- current condition validity
        l_vals          table_varchar := table_varchar();
        l_opers         table_varchar := table_varchar();
        l_user_elems    table_varchar := table_varchar();
    BEGIN
        l_cond_count := i_inst(l_idx).cond_count;
        l_vals.extend(l_cond_count);
        l_opers.extend(l_cond_count);
    
        FOR i IN 1 .. l_cond_count
        LOOP
            -- CONDITION LOOP
            -- reset parameter count, condition service,
            -- instantiated parameter list and condition validity
            l_par_count     := i_inst(l_idx).cond_par_count;
            l_cdrc          := i_inst(l_idx).id_cdr_condition;
            l_curr_cond_par := t_coll_cdrip();
            l_cond_val      := pk_alert_constant.g_yes;
        
            FOR j IN 1 .. l_par_count
            LOOP
                -- PARAMETER LOOP
                -- append parameter to list of instantiated parameters, increment index
                l_curr_cond_par.extend;
                l_curr_cond_par(l_curr_cond_par.last) := i_inst(l_idx);
                l_idx := l_idx + 1;
            END LOOP;
        
            -- execute condition in full mode
            execute_condition(i_lang     => i_lang,
                              i_prof     => i_prof,
                              i_patient  => i_patient,
                              i_episode  => i_episode,
                              i_cdrc     => l_cdrc,
                              i_mode     => g_mode_full,
                              i_input    => i_input,
                              i_inst_par => l_curr_cond_par,
                              o_ret      => l_cond_ret,
                              o_applic   => l_cond_applic,
                              o_error    => o_error);
        
            -- get condition validity
            FOR k IN 1 .. l_cond_ret.count
            LOOP
                l_cond_val := add_validity(i_a    => l_cond_val,
                                           i_b    => l_cond_ret(k).ret,
                                           i_oper => pk_cdr_constant.g_oper_and);
            
                -- append existent user elements
                l_user_elems.extend;
                l_user_elems(l_user_elems.last) := l_cond_ret(k).id_user_elem;
            END LOOP;
        
            -- update validities and operators lists
            l_vals(i) := l_cond_val;
            l_opers(i) := i_inst(l_idx - 1).flg_condition;
        END LOOP;
    
        -- fire rules within the same user element?
        IF g_cfg_user_elem = pk_alert_constant.g_no
        THEN
            -- get set of user elements used in this instance
            l_user_elems := l_user_elems MULTISET UNION DISTINCT table_varchar();
        
            IF l_user_elems.count < 2
               AND l_user_elems(l_user_elems.first) IS NOT NULL
            THEN
                -- instance is valid for one user element only
                -- do not fire!
                g_error := 'valid rule instance was holstered: ' || i_inst(1).id_cdr_instance;
                pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            
                RETURN pk_alert_constant.g_no;
            END IF;
        END IF;
    
        RETURN get_inst_validity(i_val => l_vals, i_oper => l_opers);
    END get_inst_validity;

    /**
    * Get valid instances.
    * Validates each instance, by executing all of its conditions in full mode
    * (ie, against the EHR).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_input        input parameters list
    * @param i_inst         applicable instance identifiers list
    * @param o_error        error
    *
    * @return               list of instances
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/13
    */
    FUNCTION get_valid_instances
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_input   IN t_coll_cdr_in,
        i_inst    IN table_number,
        o_error   OUT t_error_out
    ) RETURN table_number IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_VALID_INSTANCES';
        l_ret        table_number := table_number();
        l_inst       t_coll_cdrip; -- all instance parameters
        l_idx        PLS_INTEGER := 1; -- collection index
        l_inst_val   VARCHAR2(1 CHAR); -- current instance validity
        l_cnts       table_number; -- instance record counts
        l_inst_count PLS_INTEGER; -- current instance record count
        l_cdrips     t_coll_cdrip; -- current instance parameters
    BEGIN
        -- fetch a list with all instantiated parameters
        EXECUTE IMMEDIATE 'truncate table tbl_temp';
    
        INSERT INTO tbl_temp
            (num_1)
            SELECT t.column_value id_cdr_instance
              FROM TABLE(i_inst) t;
    
        g_error := 'OPEN c_cdrip';
        OPEN c_cdrip;
        FETCH c_cdrip BULK COLLECT
            INTO l_inst, l_cnts;
        CLOSE c_cdrip;
    
        -- TODO l_inst collection loop may need memory optimization!
    
        -- iterate over the entire list
        WHILE l_inst.count >= l_idx
        LOOP
            -- reset instance record count and current instance paramaters
            l_inst_count := l_cnts(l_idx);
            l_cdrips     := t_coll_cdrip();
            l_cdrips.extend(l_inst_count);
        
            FOR i IN 1 .. l_inst_count
            LOOP
                l_cdrips(i) := l_inst(l_idx);
                l_idx := l_idx + 1;
            END LOOP;
        
            g_error    := 'CALL get_inst_validity';
            l_inst_val := get_inst_validity(i_lang    => i_lang,
                                            i_prof    => i_prof,
                                            i_patient => i_patient,
                                            i_episode => i_episode,
                                            i_input   => i_input,
                                            i_inst    => l_cdrips,
                                            o_error   => o_error);
        
            IF l_inst_val = pk_alert_constant.g_yes
            THEN
                -- instance is valid: append it to the return list
                l_ret.extend;
                l_ret(l_ret.last) := l_inst(l_idx - 1).id_cdr_instance;
            END IF;
        END LOOP;
    
        -- debug valid instances
        log_tn(i_tn => l_ret, i_func_name => l_func_name);
    
        RETURN l_ret;
    END get_valid_instances;

    /**
    * Get enabled actions.
    * These are the actions to be executed afterwards.
    *
    * @param i_prof         logged professional structure
    * @param i_input        input parameters list
    * @param i_inst         applicable instance identifiers list
    *
    * @return               list of enabled actions
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/15
    */
    FUNCTION get_actions
    (
        i_prof  IN profissional,
        i_input IN t_coll_cdr_in,
        i_inst  IN table_number
    ) RETURN t_coll_cdre IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_ACTIONS';
        l_ret     t_coll_cdre;
        l_profile profile_template.id_profile_template%TYPE;
    
        CURSOR c_action_all IS
            SELECT t_rec_cdre(e.id_cdr_inst_par_action,
                              e.id_cdr_instance,
                              e.event_span,
                              e.id_event_span_umea,
                              e.flg_first_time)
              FROM (SELECT MIN(cdripa.id_cdr_inst_par_action) id_cdr_inst_par_action,
                           cdri.id_cdr_instance,
                           cdripa.event_span,
                           cdripa.id_event_span_umea,
                           cdripa.flg_first_time,
                           cdra.rank
                      FROM cdr_instance cdri
                      JOIN cdr_inst_param cdrip
                        ON cdri.id_cdr_instance = cdrip.id_cdr_instance
                      JOIN cdr_inst_par_action cdripa
                        ON cdrip.id_cdr_inst_param = cdripa.id_cdr_inst_param
                      JOIN cdr_action cdra
                        ON cdripa.id_cdr_action = cdra.id_cdr_action
                     WHERE cdri.id_cdr_instance IN (SELECT /*+opt_estimate(table i rows=1)*/
                                                     i.column_value id_cdr_instance
                                                      FROM TABLE(i_inst) i)
                       AND NOT EXISTS (SELECT 1 -- instance disablings
                              FROM cdr_inst_config cdricf
                             WHERE cdricf.id_cdr_inst_par_action = cdripa.id_cdr_inst_par_action
                               AND cdricf.id_institution = i_prof.institution
                               AND cdricf.id_software IN (0, i_prof.software)
                               AND cdricf.id_profile_template IN (0, l_profile)
                               AND (cdricf.id_dep_clin_serv = -1 OR
                                   cdricf.id_dep_clin_serv IN
                                   (SELECT pdcs.id_dep_clin_serv
                                       FROM prof_dep_clin_serv pdcs
                                      WHERE pdcs.id_professional = i_prof.id
                                        AND pdcs.flg_status = pk_alert_constant.g_status_selected))
                               AND cdricf.id_professional IN (-1, i_prof.id))
                       AND NOT EXISTS (SELECT 1 -- definition disablings
                              FROM cdr_def_config cdrdcf
                              JOIN cdr_def_severity cdrds
                                ON cdrdcf.id_cdr_def_severity = cdrds.id_cdr_def_severity
                              JOIN cdr_param_action cdrpa
                                ON cdrdcf.id_cdr_param_action = cdrpa.id_cdr_param_action
                             WHERE cdrdcf.id_institution = i_prof.institution
                               AND cdrdcf.id_software IN (0, i_prof.software)
                               AND cdrdcf.id_profile_template IN (0, l_profile)
                               AND (cdrdcf.id_dep_clin_serv = -1 OR
                                   cdrdcf.id_dep_clin_serv IN
                                   (SELECT pdcs.id_dep_clin_serv
                                       FROM prof_dep_clin_serv pdcs
                                      WHERE pdcs.id_professional = i_prof.id
                                        AND pdcs.flg_status = pk_alert_constant.g_status_selected))
                               AND cdrdcf.id_professional IN (-1, i_prof.id)
                               AND cdrds.id_cdr_definition = cdri.id_cdr_definition
                               AND cdrds.id_cdr_severity = cdri.id_cdr_severity
                               AND cdrpa.id_cdr_parameter = cdrip.id_cdr_parameter
                               AND cdrpa.id_cdr_action = cdripa.id_cdr_action)
                     GROUP BY cdri.id_cdr_instance,
                              cdripa.event_span,
                              cdripa.id_event_span_umea,
                              cdripa.flg_first_time,
                              cdra.rank) e
             ORDER BY e.id_cdr_instance, e.rank;
    
        CURSOR c_action IS
            SELECT t_rec_cdre(e.id_cdr_inst_par_action,
                              e.id_cdr_instance,
                              e.event_span,
                              e.id_event_span_umea,
                              e.flg_first_time)
              FROM (SELECT cdripa.id_cdr_inst_par_action,
                           cdri.id_cdr_instance,
                           cdripa.event_span,
                           cdripa.id_event_span_umea,
                           cdripa.flg_first_time,
                           cdra.rank
                      FROM cdr_instance cdri
                      JOIN cdr_inst_param cdrip
                        ON cdri.id_cdr_instance = cdrip.id_cdr_instance
                      JOIN cdr_inst_par_action cdripa
                        ON cdrip.id_cdr_inst_param = cdripa.id_cdr_inst_param
                      JOIN cdr_action cdra
                        ON cdripa.id_cdr_action = cdra.id_cdr_action
                      JOIN cdr_parameter cdrp
                        ON cdrip.id_cdr_parameter = cdrp.id_cdr_parameter
                      JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                            t.id_cdr_concept, t.id_element, t.id_task_type, t.id_task_req
                             FROM TABLE(i_input) t) input
                        ON cdrp.id_cdr_concept = input.id_cdr_concept
                     WHERE cdri.id_cdr_instance IN (SELECT /*+opt_estimate(table i rows=1)*/
                                                     i.column_value id_cdr_instance
                                                      FROM TABLE(i_inst) i)
                       AND (cdrip.id_element = input.id_element OR cdrip.id_element IS NULL)
                          
                       AND NOT EXISTS (SELECT 1 -- instance disablings
                              FROM cdr_inst_config cdricf
                             WHERE cdricf.id_cdr_inst_par_action = cdripa.id_cdr_inst_par_action
                               AND cdricf.id_institution = i_prof.institution
                               AND cdricf.id_software IN (0, i_prof.software)
                               AND cdricf.id_profile_template IN (0, l_profile)
                               AND (cdricf.id_dep_clin_serv = -1 OR
                                   cdricf.id_dep_clin_serv IN
                                   (SELECT pdcs.id_dep_clin_serv
                                       FROM prof_dep_clin_serv pdcs
                                      WHERE pdcs.id_professional = i_prof.id
                                        AND pdcs.flg_status = pk_alert_constant.g_status_selected))
                               AND cdricf.id_professional IN (-1, i_prof.id))
                       AND NOT EXISTS (SELECT 1 -- definition disablings
                              FROM cdr_def_config cdrdcf
                              JOIN cdr_def_severity cdrds
                                ON cdrdcf.id_cdr_def_severity = cdrds.id_cdr_def_severity
                              JOIN cdr_param_action cdrpa
                                ON cdrdcf.id_cdr_param_action = cdrpa.id_cdr_param_action
                             WHERE cdrdcf.id_institution = i_prof.institution
                               AND cdrdcf.id_software IN (0, i_prof.software)
                               AND cdrdcf.id_profile_template IN (0, l_profile)
                               AND (cdrdcf.id_dep_clin_serv = -1 OR
                                   cdrdcf.id_dep_clin_serv IN
                                   (SELECT pdcs.id_dep_clin_serv
                                       FROM prof_dep_clin_serv pdcs
                                      WHERE pdcs.id_professional = i_prof.id
                                        AND pdcs.flg_status = pk_alert_constant.g_status_selected))
                               AND cdrdcf.id_professional IN (-1, i_prof.id)
                               AND cdrds.id_cdr_definition = cdri.id_cdr_definition
                               AND cdrds.id_cdr_severity = cdri.id_cdr_severity
                               AND cdrpa.id_cdr_parameter = cdrip.id_cdr_parameter
                               AND cdrpa.id_cdr_action = cdripa.id_cdr_action)
                    
                     GROUP BY cdripa.id_cdr_inst_par_action,
                              cdri.id_cdr_instance,
                              cdripa.event_span,
                              cdripa.id_event_span_umea,
                              cdripa.flg_first_time,
                              cdra.rank
                    
                    ) e
            
             ORDER BY e.id_cdr_instance, e.rank;
    BEGIN
        l_profile := pk_tools.get_prof_profile_template(i_prof => i_prof);
        IF i_input IS NULL
        THEN
            g_error := 'OPEN c_action_all';
            OPEN c_action_all;
            FETCH c_action_all BULK COLLECT
                INTO l_ret;
            CLOSE c_action_all;
        ELSE
            g_error := 'OPEN c_action';
            OPEN c_action;
            FETCH c_action BULK COLLECT
                INTO l_ret;
            CLOSE c_action;
        END IF;
    
        -- debug list of actions
        IF g_debug_enable
        THEN
            g_error := NULL;
            FOR i IN 1 .. l_ret.count
            LOOP
                g_error := g_error || l_ret(i).id_cdr_inst_par_action || '; ';
            
                -- avoid buffer overflows
                IF i > 35
                THEN
                    g_error := g_error || '...';
                    EXIT;
                END IF;
            END LOOP;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        RETURN l_ret;
    END get_actions;

    /**
    * Get the action's hidden and session flags.
    * A hidden action is one that does not respect the minimum time between events,
    * or it isn't the first time that it was executed, in the user's session. The
    * latter case is indicated in the session flag.
    *
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_act          action enabled
    * @param o_hidden       is it hidden?
    * @param o_session      is it hidden by the user session?
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/15
    */
    PROCEDURE get_action_hidden
    (
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_act     IN t_rec_cdre,
        o_hidden  OUT cdr_event.flg_hidden%TYPE,
        o_session OUT cdr_event.flg_session%TYPE
    ) IS
        l_hidden  cdr_event.flg_hidden%TYPE;
        l_session cdr_event.flg_session%TYPE;
        l_span    cdr_call.dt_call%TYPE;
        --l_last_login cdr_call.dt_call%TYPE;
    
        CURSOR c_event(i_dt_call IN cdr_call.dt_call%TYPE) IS
            SELECT pk_alert_constant.g_yes
              FROM cdr_call cdrl
              JOIN cdr_event cdre
                ON cdrl.id_cdr_call = cdre.id_cdr_call
             WHERE cdrl.id_patient = i_patient
               AND cdrl.id_prof_call = i_prof.id
               AND cdrl.dt_call > i_dt_call
               AND cdre.id_cdr_inst_par_action = i_act.id_cdr_inst_par_action;
    BEGIN
        -- check if minimum time between events was set
        IF i_act.event_span IS NOT NULL
           AND i_act.id_event_span_umea IS NOT NULL
        THEN
            -- calculate the time span
            l_span := pk_date_utils.add_days_to_tstz(i_timestamp => g_sysdate_tstz,
                                                     i_days      => -to_days(i_span => i_act.event_span,
                                                                             i_tmu  => i_act.id_event_span_umea));
        
            -- check if action was fired within the time span
            g_error := 'OPEN c_event';
            OPEN c_event(i_dt_call => l_span);
            FETCH c_event
                INTO l_hidden;
            g_found := c_event%FOUND;
            CLOSE c_event;
        
            IF g_found
            THEN
                -- fired within the time span? hide the action
                l_hidden := pk_alert_constant.g_yes;
            ELSE
                -- otherwise, fire the action
                l_hidden := pk_alert_constant.g_no;
            END IF;
        ELSE
            -- no time span? fire the action
            l_hidden := pk_alert_constant.g_no;
        END IF;
    
        l_session := pk_alert_constant.g_no;
        --TODO: uncomment the following part to enable the session usage
    
        o_hidden  := l_hidden;
        o_session := l_session;
    END get_action_hidden;

    /**
    * Creates the engine events
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_call         previous call identifier
    * @param i_act          list of enabled actions
    * @param o_warnings     warnings list
    * @param o_call         call identifier
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/15
    */
    PROCEDURE set_events
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_call    IN cdr_call.id_cdr_call%TYPE,
        i_act     IN t_coll_cdre,
        o_call    OUT cdr_call.id_cdr_call%TYPE,
        o_error   OUT t_error_out
    ) IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_EVENTS';
        l_rowids    table_varchar;
        l_call      cdr_call.id_cdr_call%TYPE;
        l_cdre_rows ts_cdr_event.cdr_event_tc;
        l_cdre_row  cdr_event%ROWTYPE;
    
        l_cdrld_rows         ts_cdr_call_det.cdr_call_det_tc;
        l_cdrld_row          cdr_call_det%ROWTYPE;
        l_hidden             cdr_event.flg_hidden%TYPE;
        l_session            cdr_event.flg_session%TYPE;
        l_temp_cdr_instances table_number := table_number(); -- list of temp cdr_instances
        --l_valid_count        NUMBER;
        l_valid_cdr_instance table_number := table_number(); -- list of valid cdr_instances
        --l_cdre_idx           NUMBER;
        l_instances        table_number := table_number(); -- list of valid instances
        g_cdrld_rows_count NUMBER := 0;
    
        CURSOR c_prev_answer(i_cdripa IN cdr_event.id_cdr_inst_par_action%TYPE) IS
            SELECT cdre.id_prof_answer, cdre.dt_answer, cdre.id_cdr_answer, cdre.notes_answer
              FROM cdr_event cdre
             WHERE cdre.id_cdr_call = i_call
               AND cdre.id_cdr_inst_par_action = i_cdripa;
    
    BEGIN
        IF i_act IS NOT NULL
           AND i_act.count > 0
        THEN
            -- create engine call
            g_error := 'CALL ts_cdr_call.ins';
        
            IF g_id_cdr_call IS NULL
            THEN
            
                ts_cdr_call.ins(id_prof_call_in       => i_prof.id,
                                dt_call_in            => g_sysdate_tstz,
                                id_episode_in         => i_episode,
                                id_patient_in         => i_patient,
                                id_cdr_call_parent_in => i_call,
                                id_cdr_call_out       => l_call,
                                rows_out              => l_rowids);
                g_error := 'CALL t_data_gov_mnt.process_insert I';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'CDR_CALL',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
                g_id_cdr_call := l_call;
            
            END IF;
            l_rowids := table_varchar();
        
            l_cdre_row.id_cdr_call  := g_id_cdr_call;
            l_cdrld_row.id_cdr_call := g_id_cdr_call;
        
            g_error := 'Control the ORA-06531';
            -- control the ORA-06531: Referencia a uma recolha nao inicializada
            IF g_cdrld_rows IS NOT NULL
            THEN
                IF g_cdrld_rows.count > 0
                THEN
                    g_cdrld_rows_count := g_cdrld_rows.count;
                END IF;
            END IF;
        
            IF g_cdrld_rows_count > 0
            THEN
            
                -- get temporary cdr_instances
                FOR i IN i_act.first .. i_act.last
                LOOP
                    l_temp_cdr_instances.extend;
                    l_temp_cdr_instances(l_temp_cdr_instances.last) := i_act(i).id_cdr_instance;
                END LOOP;
            
                -- get valid cdr_instances
                SELECT id_cdr_instance
                  BULK COLLECT
                  INTO l_valid_cdr_instance
                  FROM (SELECT MIN(id_cdr_instance) id_cdr_instance, id_cdr_message, element
                          FROM (SELECT id_cdr_instance,
                                       cipa.id_cdr_message,
                                       listagg(id_cdr_instance, ',') within GROUP(ORDER BY id_cdr_instance DESC) element
                                  FROM (SELECT id_cdr_instance, id_cdr_inst_par_action
                                          FROM TABLE(i_act) t) inst
                                --ON cdrld.id_cdr_instance = inst.id_cdr_instance
                                  JOIN cdr_inst_par_action cipa
                                    ON cipa.id_cdr_inst_par_action = inst.id_cdr_inst_par_action
                                
                                 GROUP BY inst.id_cdr_instance, cipa.id_cdr_message)
                         GROUP BY id_cdr_message, element);
            
            END IF;
        
            -- a) prepare event rows
            FOR i IN i_act.first .. i_act.last
            LOOP
                -- if there is a valid count then create cdr_event structure
                IF g_cdrld_rows_count = 0
                   OR
                   pk_utils.search_table_number(i_table => l_valid_cdr_instance, i_search => i_act(i).id_cdr_instance) > 0
                THEN
                    g_error := 'CALL get_action_hidden';
                    get_action_hidden(i_prof    => i_prof,
                                      i_patient => i_patient,
                                      i_act     => i_act(i),
                                      o_hidden  => l_hidden,
                                      o_session => l_session);
                
                    -- set event
                    l_cdre_row.id_cdr_event           := ts_cdr_event.next_key;
                    l_cdre_row.id_cdr_inst_par_action := i_act(i).id_cdr_inst_par_action;
                    l_cdre_row.flg_hidden             := l_hidden;
                    l_cdre_row.flg_session            := l_session;
                
                    IF i_call IS NULL
                    THEN
                        -- no previous call was made: mark unanswered
                        l_cdre_row.id_prof_answer := NULL;
                        l_cdre_row.dt_answer      := NULL;
                        l_cdre_row.id_cdr_answer  := pk_cdr_constant.g_cdraw_no_answer;
                        l_cdre_row.notes_answer   := NULL;
                    ELSE
                        -- check if the event was generated previously,
                        -- and copy its answer
                        OPEN c_prev_answer(i_cdripa => i_act(i).id_cdr_inst_par_action);
                        FETCH c_prev_answer
                            INTO l_cdre_row.id_prof_answer,
                                 l_cdre_row.dt_answer,
                                 l_cdre_row.id_cdr_answer,
                                 l_cdre_row.notes_answer;
                        g_found := c_prev_answer%FOUND;
                        CLOSE c_prev_answer;
                    
                        IF NOT g_found
                        THEN
                            -- no such event was generated previously: mark unanswered
                            l_cdre_row.id_prof_answer := NULL;
                            l_cdre_row.dt_answer      := NULL;
                            l_cdre_row.id_cdr_answer  := pk_cdr_constant.g_cdraw_no_answer;
                            l_cdre_row.notes_answer   := NULL;
                        END IF;
                    END IF;
                    l_instances.extend;
                    l_instances(l_instances.last) := i_act(i).id_cdr_instance;
                    l_cdre_rows(l_cdre_rows.count + 1) := l_cdre_row;
                END IF;
            END LOOP;
        
            -- b) prepare call detail rows
            IF g_cdrld_rows IS NOT NULL
               AND g_cdrld_rows.count > 0
            THEN
                FOR i IN g_cdrld_rows.first .. g_cdrld_rows.last
                LOOP
                    IF pk_utils.search_table_number(i_table => l_instances, i_search => g_cdrld_rows(i).id_cdr_instance) > 0
                    THEN
                    
                        l_cdrld_row.id_cdr_inst_param := g_cdrld_rows(i).id_cdr_inst_param;
                        l_cdrld_row.id_task_type      := g_cdrld_rows(i).id_task_type;
                        l_cdrld_row.id_task_request   := g_cdrld_rows(i).id_task_request;
                        l_cdrld_row.param_value       := g_cdrld_rows(i).param_value;
                    
                        l_cdrld_rows(l_cdrld_rows.count + 1) := l_cdrld_row;
                    END IF;
                END LOOP;
            END IF;
        
            -- create event rows
            g_error := 'CALL ts_cdr_event.ins';
            ts_cdr_event.ins(rows_in => l_cdre_rows, rows_out => l_rowids);
            g_error := 'CALL t_data_gov_mnt.process_insert II';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'CDR_EVENT',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
            l_rowids := table_varchar();
            -- create call detail rows
            g_error := 'CALL ts_cdr_call_det.ins';
            ts_cdr_call_det.ins(rows_in => l_cdrld_rows, rows_out => l_rowids);
            g_error := 'CALL t_data_gov_mnt.process_insert III';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'CDR_CALL_DET',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            o_call := g_id_cdr_call;
        END IF;
    
        -- debug output
        IF g_debug_enable
        THEN
            g_error := 'o_call: ' || o_call;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    END set_events;

    /**
    * Checks the CDR engine for applicable rules.
    * Analyzes all rules within the framework, and retrieves events for the valid ones.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_call         previous call identifier
    * @param i_input        user input parameters
    * @param o_actions      resulting action events
    * @param o_error        error
    *
    * @author               Orlando Antunes
    * @version               2.6.1
    * @since                2011/02/10
    */
    PROCEDURE check_cdr
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_call        IN cdr_call.id_cdr_call%TYPE,
        i_input       IN t_coll_cdr_in,
        i_screen_name IN VARCHAR2,
        o_actions     OUT t_coll_cdre,
        o_error       OUT t_error_out
    ) IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CHECK_CDR';
        l_conditions  table_number; -- list of conditions to evaluate
        l_definitions table_number; -- list of definitions to evaluate
        l_instances   table_number; -- list of instances to evaluate
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        -- debug input
        IF g_debug_enable
        THEN
            g_error := 'i_patient: ' || i_patient;
            g_error := g_error || ', i_episode: ' || i_episode;
            g_error := g_error || ', i_call: ' || i_call;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- === HOW RULES ARE CHECKED - V2 model ===
        -- get list of conditions [c_list]
        -- for each condition in c_list:
        --   get condition concept applicability
        --   if condition is supported, then add it to the list of conditions to evaluate [ec_list]
        -- get list of definitions whose conditions include at least one condition in ec_list [ed_list]
        -- get list of instances of the definitions in ed_list [i_list]
        -- for each instance in i_list:
        --   get instance applicability (using instantiated parameters)
        --   if instance is usable, then add it to the list of instances to evaluate [ei_list]
        -- for each instance in ei_list
        --   if instance does not apply by recurrence pattern, then remove it from ei_list
        -- for each instance in ei_list:
        --   if instance is valid, then add it to the list of valid instance [vi_list]
        -- for each instance in vi_list:
        --   get list of instance actions [a_list]
        --     for each action on a_list:
        --       if action is disabled by definition configuration, then remove it from a_list
        --       if action is disabled by instance configuration, then remove it from a_list
        --     for each action on a_list:
        --       save action is data model of executed actions
        --       if action does not meet the minimum time between events, mark it as hidden
        --       if action does not meet the first time in session, mark it as hidden
        --       if action is not hidden, then perform action (to some, call a procedure; to others, add to cursor of warnings)
    
        -- === HOW RULES WERE CHECKED - V1 model ===
        -- get list of rules whose parameters include the ones passed as input
        -- filter list of rules, removing those whose recurrence pattern does not apply
        -- for each rule in list of rules:
        --   get list of conditions
        --   for each condition in list of rule conditions:
        --     get list of parameters
        --     for each parameter in list of condition parameters:
        --       validate parameter (consider input parameters; call procedure for others)
        --       update condition validity
        --     update rule validity
        --   if rule is valid, then add it to the list of valid rules
        -- for each rule in list of valid rules:
        --   get list of actions (consider the side from which the rule validates)
        --     for each action on list of actions:
        --       perform action (to some, call a procedure; to others, add to cursor of warnings)
        --       save rule in data model of valid rules
    
        -- get list of conditions to evaluate
        g_error      := 'CALL get_conditions';
        l_conditions := get_conditions(i_lang    => i_lang,
                                       i_prof    => i_prof,
                                       i_patient => i_patient,
                                       i_episode => i_episode,
                                       i_input   => i_input);
    
        -- get list of definitions to evaluate
        g_error       := 'CALL get_definitions_by_cond';
        l_definitions := get_definitions_by_cond(i_prof        => i_prof,
                                                 i_cond        => l_conditions,
                                                 i_screen_name => i_screen_name);
    
        -- get list of instances to evaluate
        -- (one could use either get_instances_by_cond or get_instances_by_sql here;
        -- sql is faster but less flexible; however, no examples that benefit from such flexibility
        -- have been specified to date, therefore this is hardcoded)
        g_error     := 'CALL get_instances_by_sql';
        l_instances := get_instances_by_sql(i_prof => i_prof, i_input => i_input, i_def => l_definitions);
    
        --APAGAR
        --        log_tn(i_tn => l_instances, i_func_name => l_func_name);
    
        -- get list of valid instances
        g_error     := 'CALL get_valid_instances';
        l_instances := get_valid_instances(i_lang    => i_lang,
                                           i_prof    => i_prof,
                                           i_patient => i_patient,
                                           i_episode => i_episode,
                                           i_input   => i_input,
                                           i_inst    => l_instances,
                                           o_error   => o_error);
        --APAGAR
        --    log_tn(i_tn => l_instances, i_func_name => l_func_name);
    
        -- get list of enabled actions
        g_error   := 'CALL get_actions';
        o_actions := get_actions(i_prof => i_prof, i_input => i_input, i_inst => l_instances);
    END check_cdr;

    /**
    * Checks the CDR engine for applicable rules, within the given definitions.
    * Analyzes all rules within the framework, and retrieves events for the valid ones.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_definitions  definition identifiers list
    * @param i_input        user input parameters
    * @param o_actions      resulting action events
    * @param o_error        error
    *
    * @author               Orlando Antunes
    * @version               2.6.1
    * @since                2011/02/10
    */
    PROCEDURE check_cdr_def
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_definitions IN table_number,
        o_actions     OUT t_coll_cdre,
        o_error       OUT t_error_out
    ) IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CHECK_CDR_DEF';
        l_instances table_number; -- list of instances to evaluate
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        -- debug input
        IF g_debug_enable
        THEN
            g_error := 'i_lang: ' || i_lang;
            g_error := g_error || ', i_prof: ' || pk_utils.to_string(i_input => i_prof);
            g_error := g_error || ', i_patient: ' || i_patient;
            g_error := g_error || ', i_episode: ' || i_episode;
            g_error := g_error || ', i_definitions: ' || pk_utils.to_string(i_input => i_definitions);
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- reset global variables
        reset_var(i_prof => i_prof);
    
        -- get list of instances to evaluate
        g_error     := 'CALL get_instances_by_sql';
        l_instances := get_instances_by_def(i_prof => i_prof, i_def => i_definitions);
    
        -- get list of valid instances
        g_error     := 'CALL get_valid_instances';
        l_instances := get_valid_instances(i_lang    => i_lang,
                                           i_prof    => i_prof,
                                           i_patient => i_patient,
                                           i_episode => i_episode,
                                           i_input   => NULL,
                                           i_inst    => l_instances,
                                           o_error   => o_error);
    
        -- get list of enabled actions
        g_error   := 'CALL get_actions';
        o_actions := get_actions(i_prof => i_prof, i_input => NULL, i_inst => l_instances);
    END check_cdr_def;

    /**
    * Common logic to set the user's answer to the warnings.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_call         call identifier
    * @param i_cdraw        answer identifier
    * @param i_notes        answer notes
    * @param i_act_info     action info
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/04/18
    */
    PROCEDURE set_answer_int
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_call             IN cdr_call.id_cdr_call%TYPE,
        i_cdraw            IN cdr_answer.id_cdr_answer%TYPE,
        i_notes            IN cdr_event.notes_answer%TYPE,
        i_act_info         IN c_act_info%ROWTYPE,
        i_domain_value     IN VARCHAR2 DEFAULT NULL,
        i_domain_free_text IN VARCHAR2 DEFAULT NULL,
        o_error            OUT t_error_out
    ) IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_ANSWER_INT';
        l_rowids    table_varchar;
        l_ids       table_number;
        l_trig_by   table_clob;
        l_wf_action cdr_answer.id_workflow_action%TYPE;
        l_wf_status cdr_answer.id_status_end%TYPE;
    
        CURSOR c_wf_data IS
            SELECT cdraw.id_workflow_action, cdraw.id_status_end
              FROM cdr_answer cdraw
             WHERE cdraw.id_cdr_answer = i_cdraw;
    BEGIN
        -- execute the action
        IF i_act_info.flg_hidden = pk_alert_constant.g_no
           AND i_act_info.service IS NOT NULL
        THEN
            l_trig_by := pk_utils.get_eq_val_coll(i_val => get_triggered_by(i_lang     => i_lang,
                                                                            i_prof     => i_prof,
                                                                            i_call     => i_call,
                                                                            i_instance => i_act_info.id_cdr_instance),
                                                  i_len => i_act_info.val_list.count);
        
            execute_action(i_lang    => i_lang,
                           i_prof    => i_prof,
                           i_patient => i_patient,
                           i_episode => i_episode,
                           i_service => i_act_info.service,
                           i_values  => i_act_info.val_list,
                           i_trig_by => l_trig_by,
                           i_cdripa  => i_act_info.id_cdr_inst_par_action,
                           o_ids     => l_ids);
        
            IF g_debug_enable
            THEN
                g_error := 'l_ids: ' || pk_utils.to_string(i_input => l_ids);
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            END IF;
        END IF;
    
        -- update recommendation status (postponable warning specific logic)
        IF i_act_info.id_cdr_action = pk_cdr_constant.g_cdra_postpone
        THEN
            OPEN c_wf_data;
            FETCH c_wf_data
                INTO l_wf_action, l_wf_status;
            CLOSE c_wf_data;
        
            FOR i IN 1 .. i_act_info.val_list.count
            LOOP
                g_error := 'CALL pk_api_rcm_out.set_pat_rcm_status';
                IF NOT pk_api_rcm_out.set_pat_rcm_status(i_lang               => i_lang,
                                                         i_prof               => i_prof,
                                                         i_id_patient         => i_patient,
                                                         i_id_episode         => i_episode,
                                                         i_id_rcm             => i_act_info.val_list(i),
                                                         i_id_rcm_det         => l_ids(i),
                                                         i_id_workflow_action => l_wf_action,
                                                         i_id_status_end      => l_wf_status,
                                                         i_rcm_notes          => i_notes,
                                                         o_error              => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END LOOP;
        END IF;
    
        -- set answers in events table
        g_error := 'CALL ts_cdr_event.upd';
    
        ts_cdr_event.upd( --id_cdr_call_in            => i_call,
                         id_cdr_event_in      => i_act_info.id_cdr_event,
                         id_prof_answer_in    => i_prof.id,
                         id_prof_answer_nin   => FALSE,
                         dt_answer_in         => g_sysdate_tstz,
                         dt_answer_nin        => FALSE,
                         id_cdr_answer_in     => i_cdraw,
                         id_cdr_answer_nin    => FALSE,
                         notes_answer_in      => i_notes,
                         notes_answer_nin     => FALSE,
                         domain_value_in      => i_domain_value,
                         domain_value_nin     => FALSE,
                         domain_free_text_in  => i_domain_free_text,
                         domain_free_text_nin => FALSE,
                         rows_out             => l_rowids);
    
        g_error := 'CALL t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'CDR_EVENT',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PROF_ANSWER',
                                                                      'DT_ANSWER',
                                                                      'ID_CDR_ANSWER',
                                                                      'NOTES_ANSWER'));
    
    END set_answer_int;

    /**
    * Condition procedure: check if the patient's age is within range.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/19
    */
    PROCEDURE check_age
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    ) IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CHECK_AGE';
        l_ret        VARCHAR2(1 CHAR);
        l_age        patient.age%TYPE;
        l_age_format VARCHAR2(6 CHAR);
        l_cdrld      t_rec_cdrld := t_rec_cdrld();
    BEGIN
        -- this condition has only one parameter, whose concept is age
        IF i_mode = g_mode_concept
        THEN
            -- check condition applicability using concept type
            o_applic := get_cond_applicability(i_input => i_input, i_param => table_number(pk_cdr_constant.g_cdrcp_age));
        ELSIF i_mode = g_mode_instance
        THEN
            -- check condition applicability using instantiated parameters
            o_applic := get_cond_applicability(i_input => i_input, i_inst_par => i_inst_par);
        ELSIF i_mode = g_mode_full
        THEN
            IF i_inst_par(1).val_min IS NULL
                AND i_inst_par(1).val_max IS NULL
            THEN
                -- no range is set
                g_error := 'age parameter ' || i_inst_par(1).id_cdr_inst_param || ' has no range set!';
                pk_alertlog.log_warn(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            
                -- condition is not considered valid when no range is set
                l_ret := pk_alert_constant.g_no;
            ELSE
                IF i_inst_par(1).id_domain_umea = pk_cdr_constant.g_tmu_year
                THEN
                    l_age_format := 'YEARS';
                ELSIF i_inst_par(1).id_domain_umea = pk_cdr_constant.g_tmu_month
                THEN
                    l_age_format := 'MONTHS';
                ELSIF i_inst_par(1).id_domain_umea = pk_cdr_constant.g_tmu_day
                THEN
                    l_age_format := 'DAYS';
                END IF;
            
                g_error := 'CALL pk_patient.get_pat_age';
                l_age   := pk_patient.get_pat_age(i_lang        => i_lang,
                                                  i_dt_birth    => NULL,
                                                  i_dt_deceased => NULL,
                                                  i_age         => NULL,
                                                  i_age_format  => l_age_format,
                                                  i_patient     => i_patient);
            
                IF (i_inst_par(1).val_min IS NULL OR l_age >= i_inst_par(1).val_min)
                   AND (i_inst_par(1).val_max IS NULL OR l_age < i_inst_par(1).val_max)
                THEN
                    l_ret := pk_alert_constant.g_yes;
                ELSE
                    l_ret := pk_alert_constant.g_no;
                END IF;
            
                -- store call detail row
                l_cdrld.id_cdr_inst_param := i_inst_par(1).id_cdr_inst_param;
                l_cdrld.id_cdr_instance   := i_inst_par(1).id_cdr_instance;
                l_cdrld.param_value       := l_age;
                add_cdrld(i_cdrld => l_cdrld);
            END IF;
        
            l_ret := get_denied(i_result => l_ret, i_deny => i_inst_par(1).flg_deny);
            o_ret := t_coll_cdr_out(t_rec_cdr_out(ret => l_ret, info => NULL, id_user_elem => NULL));
        ELSE
            g_error := 'Unrecognized execution mode!';
            RAISE g_fault;
        END IF;
    END check_age;

    /**
    * Condition procedure: check if an allergy is registered in the EHR.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/19
    */
    PROCEDURE check_allergy
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    ) IS
        l_no_sever CONSTANT cdr_inst_par_val.value%TYPE := '-1'; -- no allergy severity specified
        l_ret   VARCHAR2(1 CHAR);
        l_span  cdr_call.dt_call%TYPE;
        l_info  table_number;
        l_cdrld t_rec_cdrld;
    BEGIN
        -- this condition has only one parameter, whose concept is allergy
        IF i_mode = g_mode_concept
        THEN
            -- check condition applicability using concept type
            o_applic := get_cond_applicability(i_input => i_input,
                                               i_param => table_number(pk_cdr_constant.g_cdrcp_allergy));
        ELSIF i_mode = g_mode_instance
        THEN
            -- check condition applicability using instantiated parameters
            o_applic := get_cond_applicability(i_input => i_input, i_inst_par => i_inst_par);
        ELSIF i_mode = g_mode_full
        THEN
            -- check condition validity
            IF i_input IS NOT NULL
               AND i_input.count > 0
            THEN
                -- first, start by cross checking the input parameters
                FOR i IN i_input.first .. i_input.last
                LOOP
                    IF i_input(i).id_cdr_concept = pk_cdr_constant.g_cdrcp_allergy
                        AND i_input(i).id_element = i_inst_par(1).id_element
                    THEN
                        -- search element in list
                        IF pk_utils.search_table_varchar(i_table  => i_inst_par(1).val_list,
                                                         i_search => nvl(to_char(i_input(i).dose), l_no_sever)) > 0
                        THEN
                            l_ret := pk_alert_constant.g_yes;
                        
                            -- store call detail row
                            l_cdrld := t_rec_cdrld(id_cdr_inst_param => i_inst_par(1).id_cdr_inst_param,
                                                   id_cdr_instance   => i_inst_par(1).id_cdr_instance,
                                                   id_task_type      => i_input(i).id_task_type,
                                                   id_task_request   => i_input(i).id_task_req);
                            add_cdrld(i_cdrld => l_cdrld);
                        ELSE
                            l_ret := pk_alert_constant.g_no;
                        END IF;
                        EXIT;
                    END IF;
                END LOOP;
            END IF;
        
            IF l_ret IS NULL
            THEN
                -- then, check against the ehr
                IF i_inst_par(1).validity IS NOT NULL
                THEN
                    -- if validity is set, then calculate the date span
                    l_span := pk_date_utils.add_days_to_tstz(i_timestamp => g_sysdate_tstz,
                                                             i_days      => -to_days(i_span => i_inst_par(1).validity,
                                                                                     i_tmu  => i_inst_par(1).id_validity_umea));
                END IF;
            
                -- check if the allergy is registered within the date span
                IF g_cdrc_alrg_out IS NULL
                THEN
                    g_error         := 'CALL pk_allergy.get_allergy_sever';
                    g_cdrc_alrg_out := pk_allergy.get_allergy_sever(i_lang    => i_lang,
                                                                    i_prof    => i_prof,
                                                                    i_patient => i_patient);
                END IF;
            
                l_ret := pk_alert_constant.g_no;
            
                FOR i IN 1 .. g_cdrc_alrg_out.count
                LOOP
                    -- search element
                    IF g_cdrc_alrg_out(i).id_element = i_inst_par(1).id_element
                        AND (g_cdrc_alrg_out(i).dt_record > l_span OR l_span IS NULL)
                    THEN
                        -- search severity
                        IF pk_utils.search_table_varchar(i_table  => i_inst_par(1).val_list,
                                                         i_search => nvl(to_char(g_cdrc_alrg_out(i).id_allergy_severity),
                                                                         l_no_sever)) > 0
                        THEN
                            l_ret  := pk_alert_constant.g_yes;
                            l_info := table_number(g_cdrc_alrg_out(i).id_record);
                        
                            -- store call detail row
                            l_cdrld := t_rec_cdrld(id_cdr_inst_param => i_inst_par(1).id_cdr_inst_param,
                                                   id_cdr_instance   => i_inst_par(1).id_cdr_instance,
                                                   id_task_type      => pk_cdr_constant.g_tt_allergy,
                                                   id_task_request   => g_cdrc_alrg_out(i).id_task_request);
                            add_cdrld(i_cdrld => l_cdrld);
                        
                            EXIT;
                        END IF;
                    END IF;
                END LOOP;
            END IF;
        
            l_ret := get_denied(i_result => l_ret, i_deny => i_inst_par(1).flg_deny);
            o_ret := t_coll_cdr_out(t_rec_cdr_out(ret => l_ret, info => l_info, id_user_elem => NULL));
        ELSE
            g_error := 'Unrecognized execution mode!';
            RAISE g_fault;
        END IF;
    END check_allergy;

    /**
    * Condition procedure: check if a ddi is registered in the EHR.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.1
    * @since                2011/05/30
    */
    PROCEDURE check_ddi
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    ) IS
        l_ret       VARCHAR2(1 CHAR);
        l_span      cdr_call.dt_call%TYPE;
        l_info      table_number;
        l_cdrld     t_rec_cdrld;
        l_user_elem VARCHAR2(255 CHAR) := NULL;
    BEGIN
        -- this condition has only one parameter, whose concept is ddi
        IF i_mode = g_mode_concept
        THEN
            -- check condition applicability using concept type
            o_applic := get_cond_applicability(i_input => i_input, i_param => table_number(pk_cdr_constant.g_cdrcp_ddi));
        ELSIF i_mode = g_mode_instance
        THEN
            -- check condition applicability using instantiated parameters
            o_applic := get_cond_applicability(i_input => i_input, i_inst_par => i_inst_par);
        ELSIF i_mode = g_mode_full
        THEN
            -- check condition validity
            IF i_input IS NOT NULL
               AND i_input.count > 0
            THEN
                -- first, start by cross checking the input parameters
                FOR i IN i_input.first .. i_input.last
                LOOP
                    IF i_input(i).id_cdr_concept = pk_cdr_constant.g_cdrcp_ddi
                        AND i_input(i).id_element = i_inst_par(1).id_element
                    THEN
                        l_ret := pk_alert_constant.g_yes;
                    
                        -- store call detail row
                        l_cdrld := t_rec_cdrld(id_cdr_inst_param => i_inst_par(1).id_cdr_inst_param,
                                               id_cdr_instance   => i_inst_par(1).id_cdr_instance,
                                               id_task_type      => i_input(i).id_task_type,
                                               id_task_request   => i_input(i).id_task_req);
                        add_cdrld(i_cdrld => l_cdrld);
                    
                        l_user_elem := i_input(i).id_user_elem;
                    
                        EXIT;
                    END IF;
                END LOOP;
            END IF;
        
            IF l_ret IS NULL
            THEN
                -- then, check against the ehr
                IF i_inst_par(1).validity IS NOT NULL
                THEN
                    -- if validity is set, then calculate the date span
                    l_span := pk_date_utils.add_days_to_tstz(i_timestamp => g_sysdate_tstz,
                                                             i_days      => -to_days(i_span => i_inst_par(1).validity,
                                                                                     i_tmu  => i_inst_par(1).id_validity_umea));
                END IF;
            
                -- check if the ddi was registered within the date span
                g_error := 'CALL pk_api_pfh_clindoc_in.get_cdr_by_ddi';
                IF NOT pk_api_pfh_clindoc_in.get_cdr_by_ddi(i_lang       => i_lang,
                                                            i_prof       => i_prof,
                                                            i_id_patient => i_patient,
                                                            i_time       => l_span,
                                                            i_id_ddi     => i_inst_par(1).id_element,
                                                            o_presc      => l_info,
                                                            o_error      => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                IF l_info IS NULL
                   OR l_info.count < 1
                THEN
                    l_ret := pk_alert_constant.g_no;
                ELSE
                    l_ret := pk_alert_constant.g_yes;
                
                    -- store call detail row
                    l_cdrld := t_rec_cdrld(id_cdr_inst_param => i_inst_par(1).id_cdr_inst_param,
                                           id_cdr_instance   => i_inst_par(1).id_cdr_instance,
                                           id_task_type      => pk_cdr_constant.g_tt_medication,
                                           id_task_request   => l_info(l_info.first));
                    add_cdrld(i_cdrld => l_cdrld);
                END IF;
            END IF;
        
            l_ret := get_denied(i_result => l_ret, i_deny => i_inst_par(1).flg_deny);
            o_ret := t_coll_cdr_out(t_rec_cdr_out(ret => l_ret, info => l_info, id_user_elem => l_user_elem));
        ELSE
            g_error := 'Unrecognized execution mode!';
            RAISE g_fault;
        END IF;
    END check_ddi;

    /**
    * Condition procedure: check if a diagnosis synonym is registered in the EHR.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2011/11/22
    */
    PROCEDURE check_diag_synonym
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    ) IS
        l_ret  VARCHAR2(1 CHAR);
        l_span cdr_call.dt_call%TYPE;
        l_info table_number;
        l_type table_varchar;
    BEGIN
        -- this condition has only one parameter, whose concept is diagnosis synonym
        IF i_mode = g_mode_concept
        THEN
            -- check condition applicability using concept type
            o_applic := get_cond_applicability(i_input => i_input,
                                               i_param => table_number(pk_cdr_constant.g_cdrcp_diag_syn));
        ELSIF i_mode = g_mode_instance
        THEN
            -- check condition applicability using instantiated parameters
            o_applic := get_cond_applicability(i_input => i_input, i_inst_par => i_inst_par);
        ELSIF i_mode = g_mode_full
        THEN
            -- check condition validity
            IF i_input IS NOT NULL
               AND i_input.count > 0
            THEN
                -- first, start by cross checking the input parameters
                FOR i IN i_input.first .. i_input.last
                LOOP
                    IF i_input(i).id_cdr_concept = pk_cdr_constant.g_cdrcp_diag_syn
                        AND i_input(i).id_element = i_inst_par(1).id_element
                    THEN
                        l_ret := pk_alert_constant.g_yes;
                        EXIT;
                    END IF;
                END LOOP;
            END IF;
        
            IF l_ret IS NULL
            THEN
                -- then, check against the ehr
                IF i_inst_par(1).validity IS NOT NULL
                THEN
                    -- if validity is set, then calculate the date span
                    l_span := pk_date_utils.add_days_to_tstz(i_timestamp => g_sysdate_tstz,
                                                             i_days      => -to_days(i_span => i_inst_par(1).validity,
                                                                                     i_tmu  => i_inst_par(1).id_validity_umea));
                END IF;
            
                -- check if the diagnosis synonym was registered within the date span
                g_error := 'CALL pk_problems.check_synonym_diag_in_ehr';
                IF NOT pk_problems.check_synonym_diag_in_ehr(i_lang       => i_lang,
                                                             i_prof       => i_prof,
                                                             i_patient    => i_patient,
                                                             i_alert_diag => i_inst_par(1).id_element,
                                                             i_start_date => l_span,
                                                             o_is_present => l_ret,
                                                             o_diag_list  => l_info,
                                                             o_diag_type  => l_type,
                                                             o_error      => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        
            l_ret := get_denied(i_result => l_ret, i_deny => i_inst_par(1).flg_deny);
            o_ret := t_coll_cdr_out(t_rec_cdr_out(ret => l_ret, info => l_info, id_user_elem => NULL));
        ELSE
            g_error := 'Unrecognized execution mode!';
            RAISE g_fault;
        END IF;
    END check_diag_synonym;

    /**
    * Condition procedure: check if a diagnosis is registered in the EHR.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/19
    */
    PROCEDURE check_diagnosis
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    ) IS
        l_ret  VARCHAR2(1 CHAR);
        l_span cdr_call.dt_call%TYPE;
        l_info table_number;
    BEGIN
        -- this condition has only one parameter, whose concept is diagnosis
        IF i_mode = g_mode_concept
        THEN
            -- check condition applicability using concept type
            o_applic := get_cond_applicability(i_input => i_input,
                                               i_param => table_number(pk_cdr_constant.g_cdrcp_diagnosis));
        ELSIF i_mode = g_mode_instance
        THEN
            -- check condition applicability using instantiated parameters
            o_applic := get_cond_applicability(i_input => i_input, i_inst_par => i_inst_par);
        ELSIF i_mode = g_mode_full
        THEN
            -- check condition validity
            IF i_input IS NOT NULL
               AND i_input.count > 0
            THEN
                -- first, start by cross checking the input parameters
                FOR i IN i_input.first .. i_input.last
                LOOP
                    IF i_input(i).id_cdr_concept = pk_cdr_constant.g_cdrcp_diagnosis
                        AND i_input(i).id_element = i_inst_par(1).id_element
                    THEN
                        l_ret := pk_alert_constant.g_yes;
                        EXIT;
                    END IF;
                END LOOP;
            END IF;
        
            IF l_ret IS NULL
            THEN
                -- then, check against the ehr
                IF i_inst_par(1).validity IS NOT NULL
                THEN
                    -- if validity is set, then calculate the date span
                    l_span := pk_date_utils.add_days_to_tstz(i_timestamp => g_sysdate_tstz,
                                                             i_days      => -to_days(i_span => i_inst_par(1).validity,
                                                                                     i_tmu  => i_inst_par(1).id_validity_umea));
                END IF;
            
                -- check if the diagnosis was registered within the date span
                IF g_cdrc_diag_out IS NULL
                THEN
                    g_error         := 'CALL pk_problems.check_diagnosis_in_ehr';
                    g_cdrc_diag_out := pk_problems.check_diagnosis_in_ehr(i_lang    => i_lang,
                                                                          i_prof    => i_prof,
                                                                          i_patient => i_patient);
                END IF;
            
                l_ret := pk_alert_constant.g_no;
            
                FOR i IN 1 .. g_cdrc_diag_out.count
                LOOP
                    IF g_cdrc_diag_out(i).id_element = i_inst_par(1).id_element
                        AND (g_cdrc_diag_out(i).dt_record > l_span OR l_span IS NULL)
                    THEN
                        l_ret  := pk_alert_constant.g_yes;
                        l_info := table_number(g_cdrc_diag_out(i).id_record);
                        EXIT;
                    END IF;
                END LOOP;
            END IF;
        
            l_ret := get_denied(i_result => l_ret, i_deny => i_inst_par(1).flg_deny);
            o_ret := t_coll_cdr_out(t_rec_cdr_out(ret => l_ret, info => l_info, id_user_elem => NULL));
        ELSE
            g_error := 'Unrecognized execution mode!';
            RAISE g_fault;
        END IF;
    END check_diagnosis;

    /**
    * Condition procedure: check if an drug group is registered in the EHR.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.1
    * @since                2012/02/24
    */
    PROCEDURE check_drug_group
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    ) IS
        l_ret       VARCHAR2(1 CHAR);
        l_span      cdr_call.dt_call%TYPE;
        l_info      table_number;
        l_cdrld     t_rec_cdrld;
        l_user_elem VARCHAR2(255 CHAR) := NULL;
    BEGIN
        -- this condition has only one parameter, whose concept is drug group
        IF i_mode = g_mode_concept
        THEN
            -- check condition applicability using concept type
            o_applic := get_cond_applicability(i_input => i_input,
                                               i_param => table_number(pk_cdr_constant.g_cdrcp_drug_group));
        ELSIF i_mode = g_mode_instance
        THEN
            -- check condition applicability using instantiated parameters
            o_applic := get_cond_applicability(i_input => i_input, i_inst_par => i_inst_par);
        ELSIF i_mode = g_mode_full
        THEN
            -- check condition validity
            IF i_input IS NOT NULL
               AND i_input.count > 0
            THEN
                -- first, start by cross checking the input parameters
                FOR i IN i_input.first .. i_input.last
                LOOP
                    IF i_input(i).id_cdr_concept = pk_cdr_constant.g_cdrcp_drug_group
                        AND i_input(i).id_element = i_inst_par(1).id_element
                    THEN
                        l_ret := pk_alert_constant.g_yes;
                    
                        -- store call detail row
                        l_cdrld := t_rec_cdrld(id_cdr_inst_param => i_inst_par(1).id_cdr_inst_param,
                                               id_cdr_instance   => i_inst_par(1).id_cdr_instance,
                                               id_task_type      => i_input(i).id_task_type,
                                               id_task_request   => i_input(i).id_task_req);
                        add_cdrld(i_cdrld => l_cdrld);
                    
                        l_user_elem := i_input(i).id_user_elem;
                    
                        EXIT;
                    END IF;
                END LOOP;
            END IF;
        
            IF l_ret IS NULL
            THEN
                -- then, check against the ehr
                IF i_inst_par(1).validity IS NOT NULL
                THEN
                    -- if validity is set, then calculate the date span
                    l_span := pk_date_utils.add_days_to_tstz(i_timestamp => g_sysdate_tstz,
                                                             i_days      => -to_days(i_span => i_inst_par(1).validity,
                                                                                     i_tmu  => i_inst_par(1).id_validity_umea));
                END IF;
            
                -- check if the drug group was registered within the date span
                g_error := 'CALL pk_api_pfh_clindoc_in.get_cdr_by_pharm_theraps';
                IF NOT pk_api_pfh_clindoc_in.get_cdr_by_pharm_theraps(i_lang             => i_lang,
                                                                      i_prof             => i_prof,
                                                                      i_id_patient       => i_patient,
                                                                      i_time             => l_span,
                                                                      i_id_pharm_theraps => i_inst_par(1).id_element,
                                                                      o_presc            => l_info,
                                                                      o_error            => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                IF l_info IS NULL
                   OR l_info.count < 1
                THEN
                    l_ret := pk_alert_constant.g_no;
                ELSE
                    l_ret := pk_alert_constant.g_yes;
                
                    -- store call detail row
                    l_cdrld := t_rec_cdrld(id_cdr_inst_param => i_inst_par(1).id_cdr_inst_param,
                                           id_cdr_instance   => i_inst_par(1).id_cdr_instance,
                                           id_task_type      => pk_cdr_constant.g_tt_medication,
                                           id_task_request   => l_info(l_info.first));
                    add_cdrld(i_cdrld => l_cdrld);
                END IF;
            END IF;
        
            l_ret := get_denied(i_result => l_ret, i_deny => i_inst_par(1).flg_deny);
            o_ret := t_coll_cdr_out(t_rec_cdr_out(ret => l_ret, info => l_info, id_user_elem => l_user_elem));
        ELSE
            g_error := 'Unrecognized execution mode!';
            RAISE g_fault;
        END IF;
    END check_drug_group;

    /**
    * Condition procedure: check if an exam is requested in the EHR.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/19
    */
    PROCEDURE check_exam_req
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    ) IS
        l_ret  VARCHAR2(1 CHAR);
        l_span cdr_call.dt_call%TYPE;
        l_info table_number;
    BEGIN
        -- this condition has only one parameter, whose concept is exam
        IF i_mode = g_mode_concept
        THEN
            -- check condition applicability using concept type
            o_applic := get_cond_applicability(i_input => i_input,
                                               i_param => table_number(pk_cdr_constant.g_cdrcp_exam));
        ELSIF i_mode = g_mode_instance
        THEN
            -- check condition applicability using instantiated parameters
            o_applic := get_cond_applicability(i_input => i_input, i_inst_par => i_inst_par);
        ELSIF i_mode = g_mode_full
        THEN
            -- check condition validity
            IF i_input IS NOT NULL
               AND i_input.count > 0
            THEN
                -- first, start by cross checking the input parameters
                FOR i IN i_input.first .. i_input.last
                LOOP
                    IF i_input(i).id_cdr_concept = pk_cdr_constant.g_cdrcp_exam
                        AND i_input(i).id_element = i_inst_par(1).id_element
                    THEN
                        l_ret := pk_alert_constant.g_yes;
                        EXIT;
                    END IF;
                END LOOP;
            END IF;
        
            IF l_ret IS NULL
            THEN
                -- then, check against the ehr
                IF i_inst_par(1).validity IS NOT NULL
                THEN
                    -- if validity is set, then calculate the date span
                    l_span := pk_date_utils.add_days_to_tstz(i_timestamp => g_sysdate_tstz,
                                                             i_days      => -to_days(i_span => i_inst_par(1).validity,
                                                                                     i_tmu  => i_inst_par(1).id_validity_umea));
                END IF;
            
                -- check if the exam was requested within the date span
                g_error := 'CALL pk_exams_external_api_db.check_exam_cdr';
                IF NOT pk_exams_external_api_db.check_exam_cdr(i_lang         => i_lang,
                                                               i_prof         => i_prof,
                                                               i_patient      => i_patient,
                                                               i_exam         => i_inst_par(1).id_element,
                                                               i_date         => l_span,
                                                               o_exam_req_det => l_info,
                                                               o_error        => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                IF l_info IS NULL
                   OR l_info.count < 1
                THEN
                    l_ret := pk_alert_constant.g_no;
                ELSE
                    l_ret := pk_alert_constant.g_yes;
                END IF;
            END IF;
        
            l_ret := get_denied(i_result => l_ret, i_deny => i_inst_par(1).flg_deny);
            o_ret := t_coll_cdr_out(t_rec_cdr_out(ret => l_ret, info => l_info, id_user_elem => NULL));
        ELSE
            g_error := 'Unrecognized execution mode!';
            RAISE g_fault;
        END IF;
    END check_exam_req;

    /**
    * Condition procedure: check if an exam request is duplicate in the EHR.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/19
    */
    PROCEDURE check_exam_req_dup
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    ) IS
        l_ret  VARCHAR2(1 CHAR);
        l_span cdr_call.dt_call%TYPE;
        l_info table_number;
    BEGIN
        -- this condition has only one parameter, whose concept is exam
        IF i_mode = g_mode_concept
        THEN
            -- check condition applicability using concept type
            o_applic := get_cond_applicability(i_input => i_input,
                                               i_param => table_number(pk_cdr_constant.g_cdrcp_exam));
        ELSIF i_mode = g_mode_instance
        THEN
            -- check condition applicability using instantiated parameters
            o_applic := get_cond_applicability(i_input => i_input, i_inst_par => i_inst_par);
        ELSIF i_mode = g_mode_full
        THEN
            -- check promptly against the ehr
            IF i_inst_par(1).validity IS NOT NULL
            THEN
                -- if validity is set, then calculate the date span
                l_span := pk_date_utils.add_days_to_tstz(i_timestamp => g_sysdate_tstz,
                                                         i_days      => -to_days(i_span => i_inst_par(1).validity,
                                                                                 i_tmu  => i_inst_par(1).id_validity_umea));
            END IF;
        
            -- check if the exam was requested within the date span
            g_error := 'CALL pk_exams_external_api_db.check_exam_cdr';
            IF NOT pk_exams_external_api_db.check_exam_cdr(i_lang         => i_lang,
                                                           i_prof         => i_prof,
                                                           i_patient      => i_patient,
                                                           i_exam         => i_inst_par(1).id_element,
                                                           i_date         => l_span,
                                                           o_exam_req_det => l_info,
                                                           o_error        => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            IF l_info IS NULL
               OR l_info.count < 1
            THEN
                l_ret := pk_alert_constant.g_no;
            ELSE
                l_ret := pk_alert_constant.g_yes;
            END IF;
        
            l_ret := get_denied(i_result => l_ret, i_deny => i_inst_par(1).flg_deny);
            o_ret := t_coll_cdr_out(t_rec_cdr_out(ret => l_ret, info => l_info, id_user_elem => NULL));
        ELSE
            g_error := 'Unrecognized execution mode!';
            RAISE g_fault;
        END IF;
    END check_exam_req_dup;

    /**
    * Condition procedure: check if the patient is of a given gender.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/19
    */
    PROCEDURE check_gender
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    ) IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CHECK_GENDER';
        l_ret    VARCHAR2(1 CHAR);
        l_gender patient.gender%TYPE;
        l_cdrld  t_rec_cdrld := t_rec_cdrld();
    BEGIN
        -- this condition has only one parameter, whose concept is gender
        IF i_mode = g_mode_concept
        THEN
            -- check condition applicability using concept type
            o_applic := get_cond_applicability(i_input => i_input,
                                               i_param => table_number(pk_cdr_constant.g_cdrcp_gender));
        ELSIF i_mode = g_mode_instance
        THEN
            -- check condition applicability using instantiated parameters
            o_applic := get_cond_applicability(i_input => i_input, i_inst_par => i_inst_par);
        ELSIF i_mode = g_mode_full
        THEN
            IF i_inst_par(1).val_list IS NULL
                AND i_inst_par(1).val_list.count < 1
            THEN
                -- no values are listed
                g_error := 'gender parameter ' || i_inst_par(1).id_cdr_inst_param || ' has no values listed!';
                pk_alertlog.log_warn(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            
                -- condition is not considered valid when no values are listed
                l_ret := pk_alert_constant.g_no;
            ELSE
                g_error  := 'CALL pk_patient.get_pat_gender';
                l_gender := pk_patient.get_pat_gender(i_id_patient => i_patient);
            
                IF pk_utils.search_table_varchar(i_table => i_inst_par(1).val_list, i_search => l_gender) > 0
                THEN
                    l_ret := pk_alert_constant.g_yes;
                ELSE
                    l_ret := pk_alert_constant.g_no;
                END IF;
            
                -- store call detail row
                l_cdrld.id_cdr_inst_param := i_inst_par(1).id_cdr_inst_param;
                l_cdrld.id_cdr_instance   := i_inst_par(1).id_cdr_instance;
                l_cdrld.param_value       := pk_sysdomain.get_domain(i_code_dom => 'PATIENT.GENDER',
                                                                     i_val      => l_gender,
                                                                     i_lang     => i_lang);
                add_cdrld(i_cdrld => l_cdrld);
            END IF;
        
            l_ret := get_denied(i_result => l_ret, i_deny => i_inst_par(1).flg_deny);
            o_ret := t_coll_cdr_out(t_rec_cdr_out(ret => l_ret, info => NULL, id_user_elem => NULL));
        ELSE
            g_error := 'Unrecognized execution mode!';
            RAISE g_fault;
        END IF;
    END check_gender;

    /**
    * Condition procedure: check if an ingredient is registered in the EHR.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.1
    * @since                2011/05/30
    */
    PROCEDURE check_ingredient
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    ) IS
        l_ret       VARCHAR2(1 CHAR);
        l_span      cdr_call.dt_call%TYPE;
        l_info      table_number;
        l_cdrld     t_rec_cdrld;
        l_user_elem VARCHAR2(255 CHAR) := NULL;
    BEGIN
        -- this condition has only one parameter, whose concept is ingredient
        IF i_mode = g_mode_concept
        THEN
            -- check condition applicability using concept type
            o_applic := get_cond_applicability(i_input => i_input,
                                               i_param => table_number(pk_cdr_constant.g_cdrcp_ingredient));
        ELSIF i_mode = g_mode_instance
        THEN
            -- check condition applicability using instantiated parameters
            o_applic := get_cond_applicability(i_input => i_input, i_inst_par => i_inst_par);
        ELSIF i_mode = g_mode_full
        THEN
            -- check condition validity
            IF i_input IS NOT NULL
               AND i_input.count > 0
            THEN
                -- first, start by cross checking the input parameters
                FOR i IN i_input.first .. i_input.last
                LOOP
                    IF i_input(i).id_cdr_concept = pk_cdr_constant.g_cdrcp_ingredient
                        AND i_input(i).id_element = i_inst_par(1).id_element
                    THEN
                        l_ret := pk_alert_constant.g_yes;
                    
                        -- store call detail row
                        l_cdrld := t_rec_cdrld(id_cdr_inst_param => i_inst_par(1).id_cdr_inst_param,
                                               id_cdr_instance   => i_inst_par(1).id_cdr_instance,
                                               id_task_type      => i_input(i).id_task_type,
                                               id_task_request   => i_input(i).id_task_req);
                        add_cdrld(i_cdrld => l_cdrld);
                    
                        l_user_elem := i_input(i).id_user_elem;
                    
                        EXIT;
                    END IF;
                END LOOP;
            END IF;
        
            IF l_ret IS NULL
            THEN
                -- then, check against the ehr
                IF i_inst_par(1).validity IS NOT NULL
                THEN
                    -- if validity is set, then calculate the date span
                    l_span := pk_date_utils.add_days_to_tstz(i_timestamp => g_sysdate_tstz,
                                                             i_days      => -to_days(i_span => i_inst_par(1).validity,
                                                                                     i_tmu  => i_inst_par(1).id_validity_umea));
                END IF;
            
                -- check if the ingredient was registered within the date span
                g_error := 'CALL pk_api_pfh_clindoc_in.get_cdr_by_ingred';
                IF NOT pk_api_pfh_clindoc_in.get_cdr_by_ingred(i_lang          => i_lang,
                                                               i_prof          => i_prof,
                                                               i_id_patient    => i_patient,
                                                               i_time          => l_span,
                                                               i_id_ingredient => i_inst_par(1).id_element,
                                                               o_presc         => l_info,
                                                               o_error         => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                IF l_info IS NULL
                   OR l_info.count < 1
                THEN
                    l_ret := pk_alert_constant.g_no;
                ELSE
                    l_ret := pk_alert_constant.g_yes;
                
                    -- store call detail row
                    l_cdrld := t_rec_cdrld(id_cdr_inst_param => i_inst_par(1).id_cdr_inst_param,
                                           id_cdr_instance   => i_inst_par(1).id_cdr_instance,
                                           id_task_type      => pk_cdr_constant.g_tt_medication,
                                           id_task_request   => l_info(l_info.first));
                    add_cdrld(i_cdrld => l_cdrld);
                END IF;
            END IF;
        
            l_ret := get_denied(i_result => l_ret, i_deny => i_inst_par(1).flg_deny);
            o_ret := t_coll_cdr_out(t_rec_cdr_out(ret => l_ret, info => l_info, id_user_elem => l_user_elem));
        ELSE
            g_error := 'Unrecognized execution mode!';
            RAISE g_fault;
        END IF;
    END check_ingredient;

    /**
    * Condition procedure: check if an ingredient group is registered in the EHR.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.1
    * @since                2011/05/30
    */
    PROCEDURE check_ingredient_group
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    ) IS
        l_ret       VARCHAR2(1 CHAR);
        l_span      cdr_call.dt_call%TYPE;
        l_info      table_number;
        l_cdrld     t_rec_cdrld;
        l_user_elem VARCHAR2(255 CHAR) := NULL;
    BEGIN
        -- this condition has only one parameter, whose concept is ingredient group
        IF i_mode = g_mode_concept
        THEN
            -- check condition applicability using concept type
            o_applic := get_cond_applicability(i_input => i_input,
                                               i_param => table_number(pk_cdr_constant.g_cdrcp_ingr_group));
        ELSIF i_mode = g_mode_instance
        THEN
            -- check condition applicability using instantiated parameters
            o_applic := get_cond_applicability(i_input => i_input, i_inst_par => i_inst_par);
        ELSIF i_mode = g_mode_full
        THEN
            -- check condition validity
            IF i_input IS NOT NULL
               AND i_input.count > 0
            THEN
                -- first, start by cross checking the input parameters
                FOR i IN i_input.first .. i_input.last
                LOOP
                    IF i_input(i).id_cdr_concept = pk_cdr_constant.g_cdrcp_ingr_group
                        AND i_input(i).id_element = i_inst_par(1).id_element
                    THEN
                        l_ret := pk_alert_constant.g_yes;
                    
                        -- store call detail row
                        l_cdrld := t_rec_cdrld(id_cdr_inst_param => i_inst_par(1).id_cdr_inst_param,
                                               id_cdr_instance   => i_inst_par(1).id_cdr_instance,
                                               id_task_type      => i_input(i).id_task_type,
                                               id_task_request   => i_input(i).id_task_req);
                        add_cdrld(i_cdrld => l_cdrld);
                    
                        l_user_elem := i_input(i).id_user_elem;
                    
                        EXIT;
                    END IF;
                END LOOP;
            END IF;
        
            IF l_ret IS NULL
            THEN
                -- then, check against the ehr
                IF i_inst_par(1).validity IS NOT NULL
                THEN
                    -- if validity is set, then calculate the date span
                    l_span := pk_date_utils.add_days_to_tstz(i_timestamp => g_sysdate_tstz,
                                                             i_days      => -to_days(i_span => i_inst_par(1).validity,
                                                                                     i_tmu  => i_inst_par(1).id_validity_umea));
                END IF;
            
                -- check if the ingredient group was registered within the date span
                g_error := 'CALL pk_api_pfh_clindoc_in.get_cdr_by_ingred_grp';
                IF NOT pk_api_pfh_clindoc_in.get_cdr_by_ingred_grp(i_lang       => i_lang,
                                                                   i_prof       => i_prof,
                                                                   i_id_patient => i_patient,
                                                                   i_time       => l_span,
                                                                   i_ing_group  => i_inst_par(1).id_element,
                                                                   o_presc      => l_info,
                                                                   o_error      => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                IF l_info IS NULL
                   OR l_info.count < 1
                THEN
                    l_ret := pk_alert_constant.g_no;
                ELSE
                    l_ret := pk_alert_constant.g_yes;
                
                    -- store call detail row
                    l_cdrld := t_rec_cdrld(id_cdr_inst_param => i_inst_par(1).id_cdr_inst_param,
                                           id_cdr_instance   => i_inst_par(1).id_cdr_instance,
                                           id_task_type      => pk_cdr_constant.g_tt_medication,
                                           id_task_request   => l_info(l_info.first));
                    add_cdrld(i_cdrld => l_cdrld);
                END IF;
            END IF;
        
            l_ret := get_denied(i_result => l_ret, i_deny => i_inst_par(1).flg_deny);
            o_ret := t_coll_cdr_out(t_rec_cdr_out(ret => l_ret, info => l_info, id_user_elem => l_user_elem));
        ELSE
            g_error := 'Unrecognized execution mode!';
            RAISE g_fault;
        END IF;
    END check_ingredient_group;

    /**
    * Condition procedure: check if a lab test is requested in the EHR.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/19
    */
    PROCEDURE check_lab_test_req
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    ) IS
        l_ret  VARCHAR2(1 CHAR);
        l_span cdr_call.dt_call%TYPE;
        l_info table_number;
    BEGIN
        -- this condition has only one parameter, whose concept is lab test
        IF i_mode = g_mode_concept
        THEN
            -- check condition applicability using concept type
            o_applic := get_cond_applicability(i_input => i_input,
                                               i_param => table_number(pk_cdr_constant.g_cdrcp_lab_test));
        ELSIF i_mode = g_mode_instance
        THEN
            -- check condition applicability using instantiated parameters
            o_applic := get_cond_applicability(i_input => i_input, i_inst_par => i_inst_par);
        ELSIF i_mode = g_mode_full
        THEN
            -- check condition validity
            IF i_input IS NOT NULL
               AND i_input.count > 0
            THEN
                -- first, start by cross checking the input parameters
                FOR i IN i_input.first .. i_input.last
                LOOP
                    IF i_input(i).id_cdr_concept = pk_cdr_constant.g_cdrcp_lab_test
                        AND i_input(i).id_element = i_inst_par(1).id_element
                    THEN
                        l_ret := pk_alert_constant.g_yes;
                        EXIT;
                    END IF;
                END LOOP;
            END IF;
        
            IF l_ret IS NULL
            THEN
                -- then, check against the ehr
                IF i_inst_par(1).validity IS NOT NULL
                THEN
                    -- if validity is set, then calculate the date span
                    l_span := pk_date_utils.add_days_to_tstz(i_timestamp => g_sysdate_tstz,
                                                             i_days      => -to_days(i_span => i_inst_par(1).validity,
                                                                                     i_tmu  => i_inst_par(1).id_validity_umea));
                END IF;
            
                -- check if the lab test was requested within the date span
                g_error := 'CALL pk_lab_tests_external_api_db.check_lab_test_cdr';
                IF NOT pk_lab_tests_external_api_db.check_lab_test_cdr(i_lang             => i_lang,
                                                                       i_prof             => i_prof,
                                                                       i_patient          => i_patient,
                                                                       i_analysis         => i_inst_par(1).id_element,
                                                                       i_date             => l_span,
                                                                       o_analysis_req_det => l_info,
                                                                       o_error            => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                IF l_info IS NULL
                   OR l_info.count < 1
                THEN
                    l_ret := pk_alert_constant.g_no;
                ELSE
                    l_ret := pk_alert_constant.g_yes;
                END IF;
            END IF;
        
            l_ret := get_denied(i_result => l_ret, i_deny => i_inst_par(1).flg_deny);
            o_ret := t_coll_cdr_out(t_rec_cdr_out(ret => l_ret, info => l_info, id_user_elem => NULL));
        ELSE
            g_error := 'Unrecognized execution mode!';
            RAISE g_fault;
        END IF;
    END check_lab_test_req;

    /**
    * Condition procedure: check if an lab test request is duplicate in the EHR.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/19
    */
    PROCEDURE check_lab_test_req_dup
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    ) IS
        l_ret  VARCHAR2(1 CHAR);
        l_span cdr_call.dt_call%TYPE;
        l_info table_number;
    BEGIN
        -- this condition has only one parameter, whose concept is lab test
        IF i_mode = g_mode_concept
        THEN
            -- check condition applicability using concept type
            o_applic := get_cond_applicability(i_input => i_input,
                                               i_param => table_number(pk_cdr_constant.g_cdrcp_lab_test));
        ELSIF i_mode = g_mode_instance
        THEN
            -- check condition applicability using instantiated parameters
            o_applic := get_cond_applicability(i_input => i_input, i_inst_par => i_inst_par);
        ELSIF i_mode = g_mode_full
        THEN
            -- check promptly against the ehr
            IF i_inst_par(1).validity IS NOT NULL
            THEN
                -- if validity is set, then calculate the date span
                l_span := pk_date_utils.add_days_to_tstz(i_timestamp => g_sysdate_tstz,
                                                         i_days      => -to_days(i_span => i_inst_par(1).validity,
                                                                                 i_tmu  => i_inst_par(1).id_validity_umea));
            END IF;
        
            -- check if the lab was requested within the date span
            g_error := 'CALL pk_lab_tests_external_api_db.check_lab_test_cdr';
            IF NOT pk_lab_tests_external_api_db.check_lab_test_cdr(i_lang             => i_lang,
                                                                   i_prof             => i_prof,
                                                                   i_patient          => i_patient,
                                                                   i_analysis         => i_inst_par(1).id_element,
                                                                   i_date             => l_span,
                                                                   o_analysis_req_det => l_info,
                                                                   o_error            => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            IF l_info IS NULL
               OR l_info.count < 1
            THEN
                l_ret := pk_alert_constant.g_no;
            ELSE
                l_ret := pk_alert_constant.g_yes;
            END IF;
        
            l_ret := get_denied(i_result => l_ret, i_deny => i_inst_par(1).flg_deny);
            o_ret := t_coll_cdr_out(t_rec_cdr_out(ret => l_ret, info => l_info, id_user_elem => NULL));
        ELSE
            g_error := 'Unrecognized execution mode!';
            RAISE g_fault;
        END IF;
    END check_lab_test_req_dup;

    /**
    * Condition procedure: check if a lab test result is within range.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/19
    */
    PROCEDURE check_lab_test_res
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    ) IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CHECK_LAB_TEST_RES';
        l_ret    VARCHAR2(1 CHAR);
        l_span   cdr_call.dt_call%TYPE;
        l_cursor pk_types.cursor_type;
    
        l_result analysis_result_par.analysis_result_value%TYPE;
        l_um     unit_measure.id_unit_measure%TYPE;
        l_opt    analysis_desc.id_analysis_desc%TYPE;
        l_domain BOOLEAN; -- should the validation be made using domain?
        l_dt_ltr analysis_result_par.dt_analysis_result_par_tstz%TYPE;
    BEGIN
        -- this condition has only one parameter, whose concept is lab test parameter
        IF i_mode = g_mode_concept
        THEN
            -- check condition applicability using concept type
            o_applic := get_cond_applicability(i_input => i_input,
                                               i_param => table_number(pk_cdr_constant.g_cdrcp_lab_test_par));
        ELSIF i_mode = g_mode_instance
        THEN
            -- check condition applicability using instantiated parameters
            o_applic := get_cond_applicability(i_input => i_input, i_inst_par => i_inst_par);
        
        ELSIF i_mode = g_mode_full
        THEN
            -- check if the validation is made using domain
            IF i_inst_par(1).val_list IS NULL
                OR i_inst_par(1).val_list.count < 1
            THEN
                l_domain := TRUE;
            ELSE
                l_domain := FALSE;
            END IF;
        
            -- validate condition attributes
            IF l_domain
            THEN
                IF i_inst_par(1).id_domain_umea IS NULL
                THEN
                    -- values list is empty and no domain measurement unit is set
                    g_error := 'lab test parameter ' || i_inst_par(1).id_cdr_inst_param ||
                               ' has no domain measurement unit set!';
                    pk_alertlog.log_warn(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                
                    -- condition is not considered valid
                    l_ret := pk_alert_constant.g_no;
                ELSIF i_inst_par(1).val_min IS NULL
                       AND i_inst_par(1).val_max IS NULL
                THEN
                    -- values list is empty and no range is set
                    g_error := 'lab test parameter ' || i_inst_par(1).id_cdr_inst_param || ' has no range set!';
                    pk_alertlog.log_warn(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                
                    -- condition is not considered valid
                    l_ret := pk_alert_constant.g_no;
                END IF;
            END IF;
        
            IF l_ret IS NULL
            THEN
                -- check condition validity
                IF i_input IS NOT NULL
                   AND i_input.count > 0
                THEN
                    -- first, start by cross checking the input parameters
                    FOR i IN i_input.first .. i_input.last
                    LOOP
                        IF i_input(i).id_cdr_concept = pk_cdr_constant.g_cdrcp_lab_test_par
                            AND i_input(i).id_element = i_inst_par(1).id_element
                        THEN
                            IF l_domain
                            THEN
                                -- check if element is within domain
                                g_error := 'CALL get_in_domain';
                                l_ret   := get_in_domain(i_result    => i_input(i).dose,
                                                         i_res_um    => i_input(i).id_dose_umea,
                                                         i_val_min   => i_inst_par(1).val_min,
                                                         i_val_max   => i_inst_par(1).val_max,
                                                         i_domain_um => i_inst_par(1).id_domain_umea);
                            ELSE
                                -- search element in list
                                IF pk_utils.search_table_varchar(i_table  => i_inst_par(1).val_list,
                                                                 i_search => to_char(i_input(i).dose)) > 0
                                THEN
                                    l_ret := pk_alert_constant.g_yes;
                                ELSE
                                    l_ret := pk_alert_constant.g_no;
                                END IF;
                            END IF;
                            EXIT;
                        END IF;
                    END LOOP;
                END IF;
            
                IF l_ret IS NULL
                THEN
                    -- then, check against the ehr
                    IF i_inst_par(1).validity IS NOT NULL
                    THEN
                        -- if validity is set, then calculate the date span
                        l_span := pk_date_utils.add_days_to_tstz(i_timestamp => g_sysdate_tstz,
                                                                 i_days      => -to_days(i_span => i_inst_par(1).validity,
                                                                                         i_tmu  => i_inst_par(1).id_validity_umea));
                    END IF;
                
                    -- check if the lab test parameter has a result within the date span
                    g_error := 'CALL pk_lab_tests_external_api_db.get_lab_test_cdr';
                    IF NOT pk_lab_tests_external_api_db.get_lab_test_cdr(i_lang               => i_lang,
                                                                         i_prof               => i_prof,
                                                                         i_patient            => i_patient,
                                                                         i_analysis_parameter => i_inst_par(1).id_element,
                                                                         i_date               => l_span,
                                                                         o_list               => l_cursor,
                                                                         o_error              => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                    g_error := 'FETCH l_cursor';
                    FETCH l_cursor
                        INTO l_result, l_um, l_opt, l_dt_ltr;
                    g_found := l_cursor%FOUND;
                    CLOSE l_cursor;
                
                    IF g_found
                    THEN
                        IF l_domain
                        THEN
                            -- check if element is within domain
                            g_error := 'CALL get_in_domain';
                            l_ret   := get_in_domain(i_result    => l_result,
                                                     i_res_um    => l_um,
                                                     i_val_min   => i_inst_par(1).val_min,
                                                     i_val_max   => i_inst_par(1).val_max,
                                                     i_domain_um => i_inst_par(1).id_domain_umea);
                        
                        ELSE
                            -- search element in list
                            IF pk_utils.search_table_varchar(i_table  => i_inst_par(1).val_list,
                                                             i_search => to_char(l_opt)) > 0
                            THEN
                                l_ret := pk_alert_constant.g_yes;
                            ELSE
                                l_ret := pk_alert_constant.g_no;
                            END IF;
                        END IF;
                    ELSE
                        l_ret := pk_alert_constant.g_no;
                    END IF;
                END IF;
            END IF;
        
            l_ret := get_denied(i_result => l_ret, i_deny => i_inst_par(1).flg_deny);
            o_ret := t_coll_cdr_out(t_rec_cdr_out(ret => l_ret, info => NULL, id_user_elem => NULL));
        ELSE
            g_error := 'Unrecognized execution mode!';
            RAISE g_fault;
        END IF;
    END check_lab_test_res;

    /**
    * Condition procedure: check if a lab test result was registered after
    * the last acknowledgment of a recommendation.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/06/08
    */
    PROCEDURE check_ltr_after_rcm_ack
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    ) IS
        l_ret    VARCHAR2(1 CHAR);
        l_span   cdr_call.dt_call%TYPE;
        l_cursor pk_types.cursor_type;
        l_result analysis_result_par.analysis_result_value%TYPE;
        l_um     unit_measure.id_unit_measure%TYPE;
        l_opt    analysis_desc.id_analysis_desc%TYPE;
        l_dt_ltr analysis_result.dt_analysis_result_tstz%TYPE;
        l_dt_rcm v_pat_rcm_last_status.dt_status%TYPE;
    
        CURSOR c_last_rcm_ack IS
            SELECT prls.dt_status
              FROM v_pat_rcm_last_status prls
             WHERE prls.id_patient = i_patient
               AND prls.id_rcm = to_number(i_inst_par(2).id_element)
               AND prls.id_institution = i_prof.institution
             ORDER BY prls.dt_status DESC;
    BEGIN
        -- this condition has two parameters,
        -- whose concepts are lab test parameter and recommendation
        IF i_mode = g_mode_concept
        THEN
            -- check condition applicability using concept types
            o_applic := get_cond_applicability(i_input => i_input,
                                               i_param => table_number(pk_cdr_constant.g_cdrcp_lab_test_par,
                                                                       pk_cdr_constant.g_cdrcp_rcm));
        ELSIF i_mode = g_mode_instance
        THEN
            -- check condition applicability using instantiated parameters
            o_applic := get_cond_applicability(i_input => i_input, i_inst_par => i_inst_par);
        ELSIF i_mode = g_mode_full
        THEN
            -- check condition validity
            IF i_inst_par(1).validity IS NOT NULL
            THEN
                -- if validity is set, then calculate the date span
                l_span := pk_date_utils.add_days_to_tstz(i_timestamp => g_sysdate_tstz,
                                                         i_days      => -to_days(i_span => i_inst_par(1).validity,
                                                                                 i_tmu  => i_inst_par(1).id_validity_umea));
            END IF;
        
            -- check if the lab test parameter has a result within the date span
            g_error := 'CALL pk_lab_tests_external_api_db.get_lab_test_cdr';
            IF NOT pk_lab_tests_external_api_db.get_lab_test_cdr(i_lang               => i_lang,
                                                                 i_prof               => i_prof,
                                                                 i_patient            => i_patient,
                                                                 i_analysis_parameter => i_inst_par(1).id_element,
                                                                 i_date               => l_span,
                                                                 o_list               => l_cursor,
                                                                 o_error              => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'FETCH l_cursor';
            FETCH l_cursor
                INTO l_result, l_um, l_opt, l_dt_ltr;
            g_found := l_cursor%FOUND;
            CLOSE l_cursor;
        
            IF g_found
            THEN
                -- get last rcm acknowledgment date
                g_error := 'OPEN c_last_rcm_ack';
                OPEN c_last_rcm_ack;
                FETCH c_last_rcm_ack
                    INTO l_dt_rcm;
                g_found := c_last_rcm_ack%FOUND;
                CLOSE c_last_rcm_ack;
            
                IF g_found
                THEN
                    IF l_dt_ltr > l_dt_rcm
                    THEN
                        l_ret := pk_alert_constant.g_yes;
                    ELSE
                        l_ret := pk_alert_constant.g_no;
                    END IF;
                ELSE
                    l_ret := pk_alert_constant.g_yes;
                END IF;
            ELSE
                l_ret := pk_alert_constant.g_no;
            END IF;
        
            -- both parameters must be denied, to deny this condition
            l_ret := get_denied(i_result => l_ret,
                                i_deny   => add_validity(i_a    => i_inst_par(1).flg_deny,
                                                         i_b    => i_inst_par(2).flg_deny,
                                                         i_oper => pk_cdr_constant.g_oper_and));
            o_ret := t_coll_cdr_out(t_rec_cdr_out(ret => l_ret, info => NULL, id_user_elem => NULL));
        ELSE
            g_error := 'Unrecognized execution mode!';
            RAISE g_fault;
        END IF;
    END check_ltr_after_rcm_ack;

    /**
    * Condition procedure: check if the patient is pregnant.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/19
    */
    PROCEDURE check_pregnancy
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    ) IS
        l_ret VARCHAR2(1 CHAR);
    BEGIN
        -- this condition has only one parameter, whose concept is pregnancy
        IF i_mode = g_mode_concept
        THEN
            -- check condition applicability using concept type
            o_applic := get_cond_applicability(i_input => i_input,
                                               i_param => table_number(pk_cdr_constant.g_cdrcp_pregnancy));
        ELSIF i_mode = g_mode_instance
        THEN
            -- check condition applicability using instantiated parameters
            o_applic := get_cond_applicability(i_input => i_input, i_inst_par => i_inst_par);
        ELSIF i_mode = g_mode_full
        THEN
            -- check condition validity
            IF i_input IS NOT NULL
               AND i_input.count > 0
            THEN
                -- first, start by cross checking the input parameters
                FOR i IN i_input.first .. i_input.last
                LOOP
                    IF i_input(i).id_cdr_concept = pk_cdr_constant.g_cdrcp_pregnancy
                    THEN
                        l_ret := pk_alert_constant.g_yes;
                        EXIT;
                    END IF;
                END LOOP;
            END IF;
        
            IF l_ret IS NULL
            THEN
                -- check if the pregnancy is ongoing
                g_error := 'CALL pk_woman_health.is_woman_pregnant';
                IF NOT pk_woman_health.is_woman_pregnant(i_lang         => i_lang,
                                                         i_prof         => i_prof,
                                                         i_patient      => i_patient,
                                                         o_flg_pregnant => l_ret,
                                                         o_error        => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        
            l_ret := get_denied(i_result => l_ret, i_deny => i_inst_par(1).flg_deny);
            o_ret := t_coll_cdr_out(t_rec_cdr_out(ret => l_ret, info => NULL, id_user_elem => NULL));
        ELSE
            g_error := 'Unrecognized execution mode!';
            RAISE g_fault;
        END IF;
    END check_pregnancy;

    /**
    * Condition procedure: check if a pregnancy is within a time range.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.2
    * @since                2011/09/08
    */
    PROCEDURE check_pregnancy_time
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    ) IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CHECK_PREGNANCY_TIME';
        l_ret   VARCHAR2(1 CHAR);
        l_weeks NUMBER;
        l_cdrld t_rec_cdrld := t_rec_cdrld();
    BEGIN
        -- this condition has only one parameter, whose concept is pregnancy
        IF i_mode = g_mode_concept
        THEN
            -- check condition applicability using concept type
            o_applic := get_cond_applicability(i_input => i_input,
                                               i_param => table_number(pk_cdr_constant.g_cdrcp_pregnancy));
        ELSIF i_mode = g_mode_instance
        THEN
            -- check condition applicability using instantiated parameters
            o_applic := get_cond_applicability(i_input => i_input, i_inst_par => i_inst_par);
        ELSIF i_mode = g_mode_full
        THEN
            -- validate condition attributes
            IF i_inst_par(1).id_domain_umea IS NULL
            THEN
                -- no domain measurement unit is set
                g_error := 'pregnancy ' || i_inst_par(1).id_cdr_inst_param || ' has no domain measurement unit set!';
                pk_alertlog.log_warn(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            
                -- condition is not considered valid
                l_ret := pk_alert_constant.g_no;
            ELSIF i_inst_par(1).val_min IS NULL
                   AND i_inst_par(1).val_max IS NULL
            THEN
                -- no range is set
                g_error := 'pregnancy ' || i_inst_par(1).id_cdr_inst_param || ' has no range set!';
                pk_alertlog.log_warn(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            
                -- condition is not considered valid
                l_ret := pk_alert_constant.g_no;
            END IF;
        
            IF l_ret IS NULL
            THEN
                -- check condition validity
                IF i_input IS NOT NULL
                   AND i_input.count > 0
                THEN
                    -- first, start by cross checking the input parameters
                    FOR i IN i_input.first .. i_input.last
                    LOOP
                        IF i_input(i).id_cdr_concept = pk_cdr_constant.g_cdrcp_pregnancy
                            AND i_input(i).id_element IS NULL
                            AND i_inst_par(1).id_element IS NULL
                        THEN
                            -- check if element is within domain
                            g_error := 'CALL get_in_domain';
                            l_ret   := get_in_domain(i_result    => i_input(i).dose,
                                                     i_res_um    => i_input(i).id_dose_umea,
                                                     i_val_min   => i_inst_par(1).val_min,
                                                     i_val_max   => i_inst_par(1).val_max,
                                                     i_domain_um => i_inst_par(1).id_domain_umea);
                        
                            -- store call detail row
                            l_cdrld.id_cdr_inst_param := i_inst_par(1).id_cdr_inst_param;
                            l_cdrld.id_cdr_instance   := i_inst_par(1).id_cdr_instance;
                            l_cdrld.param_value       := i_input(i).dose;
                            add_cdrld(i_cdrld => l_cdrld);
                        
                            EXIT;
                        END IF;
                    END LOOP;
                END IF;
            
                IF l_ret IS NULL
                THEN
                    -- then, check against the ehr
                    -- check if the pregnancy is within the time range
                    g_error := 'CALL pk_pregnancy.get_pregnancy_num_weeks';
                    l_weeks := pk_pregnancy.get_pregnancy_num_weeks(i_lang => i_lang,
                                                                    i_prof => i_prof,
                                                                    i_pat  => i_patient);
                
                    IF l_weeks IS NULL
                    THEN
                        l_ret := pk_alert_constant.g_no;
                    ELSE
                        -- check if element is within domain
                        g_error := 'CALL get_in_domain';
                        l_ret   := get_in_domain(i_result    => l_weeks,
                                                 i_res_um    => pk_cdr_constant.g_tmu_week,
                                                 i_val_min   => i_inst_par(1).val_min,
                                                 i_val_max   => i_inst_par(1).val_max,
                                                 i_domain_um => i_inst_par(1).id_domain_umea);
                    
                        -- store call detail row
                        l_cdrld.id_cdr_inst_param := i_inst_par(1).id_cdr_inst_param;
                        l_cdrld.id_cdr_instance   := i_inst_par(1).id_cdr_instance;
                        l_cdrld.param_value       := l_weeks;
                        add_cdrld(i_cdrld => l_cdrld);
                    END IF;
                END IF;
            END IF;
        
            l_ret := get_denied(i_result => l_ret, i_deny => i_inst_par(1).flg_deny);
            o_ret := t_coll_cdr_out(t_rec_cdr_out(ret => l_ret, info => NULL, id_user_elem => NULL));
        ELSE
            g_error := 'Unrecognized execution mode!';
            RAISE g_fault;
        END IF;
    END check_pregnancy_time;

    /**
    * Condition procedure: check if a product is registered in the EHR.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.1
    * @since                2011/05/30
    */
    PROCEDURE check_product
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    ) IS
        l_ret       VARCHAR2(1 CHAR);
        l_span      cdr_call.dt_call%TYPE;
        l_info      table_number;
        l_cdrld     t_rec_cdrld;
        l_user_elem VARCHAR2(255 CHAR) := NULL;
    BEGIN
        -- this condition has only one parameter, whose concept is product
        IF i_mode = g_mode_concept
        THEN
            -- check condition applicability using concept type
            o_applic := get_cond_applicability(i_input => i_input,
                                               i_param => table_number(pk_cdr_constant.g_cdrcp_product));
        ELSIF i_mode = g_mode_instance
        THEN
            -- check condition applicability using instantiated parameters
            o_applic := get_cond_applicability(i_input => i_input, i_inst_par => i_inst_par);
        ELSIF i_mode = g_mode_full
        THEN
            -- check condition validity
            IF i_input IS NOT NULL
               AND i_input.count > 0
            THEN
                -- first, start by cross checking the input parameters
                FOR i IN i_input.first .. i_input.last
                LOOP
                    IF i_input(i).id_cdr_concept = pk_cdr_constant.g_cdrcp_product
                        AND i_input(i).id_element = i_inst_par(1).id_element
                    THEN
                        l_ret := pk_alert_constant.g_yes;
                    
                        -- store call detail row
                        l_cdrld := t_rec_cdrld(id_cdr_inst_param => i_inst_par(1).id_cdr_inst_param,
                                               id_cdr_instance   => i_inst_par(1).id_cdr_instance,
                                               id_task_type      => i_input(i).id_task_type,
                                               id_task_request   => i_input(i).id_task_req);
                        add_cdrld(i_cdrld => l_cdrld);
                    
                        l_user_elem := i_input(i).id_user_elem;
                    
                        EXIT;
                    END IF;
                END LOOP;
            END IF;
        
            IF l_ret IS NULL
            THEN
                -- then, check against the ehr
                IF i_inst_par(1).validity IS NOT NULL
                THEN
                    -- if validity is set, then calculate the date span
                    l_span := pk_date_utils.add_days_to_tstz(i_timestamp => g_sysdate_tstz,
                                                             i_days      => -to_days(i_span => i_inst_par(1).validity,
                                                                                     i_tmu  => i_inst_par(1).id_validity_umea));
                END IF;
            
                -- check if the product was registered within the date span
                g_error := 'CALL pk_api_pfh_clindoc_in.get_cdr_presc_by_product';
                IF NOT pk_api_pfh_clindoc_in.get_cdr_presc_by_product(i_lang       => i_lang,
                                                                      i_prof       => i_prof,
                                                                      i_id_patient => i_patient,
                                                                      i_time       => l_span,
                                                                      i_id_product => table_varchar(i_inst_par(1).id_element),
                                                                      o_presc      => l_info,
                                                                      o_error      => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                IF l_info IS NULL
                   OR l_info.count < 1
                THEN
                    l_ret := pk_alert_constant.g_no;
                ELSE
                    l_ret := pk_alert_constant.g_yes;
                
                    -- store call detail row
                    l_cdrld := t_rec_cdrld(id_cdr_inst_param => i_inst_par(1).id_cdr_inst_param,
                                           id_cdr_instance   => i_inst_par(1).id_cdr_instance,
                                           id_task_type      => pk_cdr_constant.g_tt_medication,
                                           id_task_request   => l_info(l_info.first));
                    add_cdrld(i_cdrld => l_cdrld);
                END IF;
            END IF;
        
            l_ret := get_denied(i_result => l_ret, i_deny => i_inst_par(1).flg_deny);
            o_ret := t_coll_cdr_out(t_rec_cdr_out(ret => l_ret, info => l_info, id_user_elem => l_user_elem));
        ELSE
            g_error := 'Unrecognized execution mode!';
            RAISE g_fault;
        END IF;
    END check_product;

    /**
    * Condition procedure: check if a surgical procedure is registered in the EHR.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/19
    */
    PROCEDURE check_sr_proc
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    ) IS
        l_ret  VARCHAR2(1 CHAR);
        l_span cdr_call.dt_call%TYPE;
        l_info table_number;
    BEGIN
        -- this condition has only one parameter, whose concept is surgical procedure
        IF i_mode = g_mode_concept
        THEN
            -- check condition applicability using concept type
            o_applic := get_cond_applicability(i_input => i_input,
                                               i_param => table_number(pk_cdr_constant.g_cdrcp_sr_proc));
        ELSIF i_mode = g_mode_instance
        THEN
            -- check condition applicability using instantiated parameters
            o_applic := get_cond_applicability(i_input => i_input, i_inst_par => i_inst_par);
        ELSIF i_mode = g_mode_full
        THEN
            -- check condition validity
            IF i_input IS NOT NULL
               AND i_input.count > 0
            THEN
                -- first, start by cross checking the input parameters
                FOR i IN i_input.first .. i_input.last
                LOOP
                    IF i_input(i).id_cdr_concept = pk_cdr_constant.g_cdrcp_sr_proc
                        AND i_input(i).id_element = i_inst_par(1).id_element
                    THEN
                        l_ret := pk_alert_constant.g_yes;
                        EXIT;
                    END IF;
                END LOOP;
            END IF;
        
            IF l_ret IS NULL
            THEN
                -- then, check against the ehr
                IF i_inst_par(1).validity IS NOT NULL
                THEN
                    -- if validity is set, then calculate the date span
                    l_span := pk_date_utils.add_days_to_tstz(i_timestamp => g_sysdate_tstz,
                                                             i_days      => -to_days(i_span => i_inst_par(1).validity,
                                                                                     i_tmu  => i_inst_par(1).id_validity_umea));
                END IF;
            
                -- check if the surgical procedure was registered within the date span
                g_error := 'CALL pk_api_oris.check_surg_procedure';
                IF NOT pk_api_oris.check_surg_procedure(i_lang                  => i_lang,
                                                        i_prof                  => i_prof,
                                                        i_id_patiet             => i_patient,
                                                        i_id_sr_intervention    => i_inst_par(1).id_element,
                                                        i_start_date            => l_span,
                                                        o_flg_started_procedure => l_ret,
                                                        o_id_epis_sr_interv     => l_info,
                                                        o_error                 => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        
            l_ret := get_denied(i_result => l_ret, i_deny => i_inst_par(1).flg_deny);
            o_ret := t_coll_cdr_out(t_rec_cdr_out(ret => l_ret, info => l_info, id_user_elem => NULL));
        ELSE
            g_error := 'Unrecognized execution mode!';
            RAISE g_fault;
        END IF;
    END check_sr_proc;

    /**
    * Condition procedure: check if a procedure is registered in the EHR.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/19
    */
    PROCEDURE check_procedure
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    ) IS
        l_ret  VARCHAR2(1 CHAR);
        l_span cdr_call.dt_call%TYPE;
        l_info table_number;
    BEGIN
        -- this condition has only one parameter, whose concept is procedure
        IF i_mode = g_mode_concept
        THEN
            -- check condition applicability using concept type
            o_applic := get_cond_applicability(i_input => i_input,
                                               i_param => table_number(pk_cdr_constant.g_cdrcp_procedure));
        ELSIF i_mode = g_mode_instance
        THEN
            -- check condition applicability using instantiated parameters
            o_applic := get_cond_applicability(i_input => i_input, i_inst_par => i_inst_par);
        ELSIF i_mode = g_mode_full
        THEN
            -- check condition validity
            IF i_input IS NOT NULL
               AND i_input.count > 0
            THEN
                -- first, start by cross checking the input parameters
                FOR i IN i_input.first .. i_input.last
                LOOP
                    IF i_input(i).id_cdr_concept = pk_cdr_constant.g_cdrcp_procedure
                        AND i_input(i).id_element = i_inst_par(1).id_element
                    THEN
                        l_ret := pk_alert_constant.g_yes;
                        EXIT;
                    END IF;
                END LOOP;
            END IF;
        
            IF l_ret IS NULL
            THEN
                -- then, check against the ehr
                IF i_inst_par(1).validity IS NOT NULL
                THEN
                    -- if validity is set, then calculate the date span
                    l_span := pk_date_utils.add_days_to_tstz(i_timestamp => g_sysdate_tstz,
                                                             i_days      => -to_days(i_span => i_inst_par(1).validity,
                                                                                     i_tmu  => i_inst_par(1).id_validity_umea));
                END IF;
            
                -- check if the procedure was registered within the date span
                g_error := 'CALL PK_PROCEDURES_EXTERNAL_API_DB.CHECK_PROCEDURE_CDR';
                IF NOT pk_procedures_external_api_db.check_procedure_cdr(i_lang             => i_lang,
                                                                         i_prof             => i_prof,
                                                                         i_patient          => i_patient,
                                                                         i_intervention     => i_inst_par(1).id_element,
                                                                         i_date             => l_span,
                                                                         o_interv_presc_det => l_info,
                                                                         o_error            => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                IF l_info IS NULL
                   OR l_info.count < 1
                THEN
                    l_ret := pk_alert_constant.g_no;
                ELSE
                    l_ret := pk_alert_constant.g_yes;
                END IF;
            END IF;
        
            l_ret := get_denied(i_result => l_ret, i_deny => i_inst_par(1).flg_deny);
            o_ret := t_coll_cdr_out(t_rec_cdr_out(ret => l_ret, info => l_info, id_user_elem => NULL));
        ELSE
            g_error := 'Unrecognized execution mode!';
            RAISE g_fault;
        END IF;
    END check_procedure;

    /**
    * Condition procedure: check if an vs is registered in the EHR.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Mario Mineiro
    * @version               2.6.4
    * @since                18/03/2014
    */
    PROCEDURE check_vs
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    ) IS
        --l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CHECK_VS';
        --l_no_sever  CONSTANT cdr_inst_par_val.value%TYPE := '-1'; -- no allergy severity specified
        l_ret  VARCHAR2(1 CHAR);
        l_span cdr_call.dt_call%TYPE;
        --l_info  table_number;
        l_cdrld t_rec_cdrld := t_rec_cdrld();
    
        l_domain BOOLEAN; -- should the validation be made using domain?
        l_cursor pk_types.cursor_type;
    
        l_result vital_sign_read.value%TYPE;
        l_um     unit_measure.id_unit_measure%TYPE;
        l_opt    pk_core_translation.t_big_byte;
    
        l_dt_ltr vital_sign_read.dt_vital_sign_read_tstz%TYPE;
    
    BEGIN
        -- this condition has only one parameter, whose concept is allergy
        IF i_mode = g_mode_concept
        THEN
            -- check condition applicability using concept type
            o_applic := get_cond_applicability(i_input => i_input, i_param => table_number(pk_cdr_constant.g_cdrcp_vs));
        ELSIF i_mode = g_mode_instance
        THEN
            -- check condition applicability using instantiated parameters
            o_applic := get_cond_applicability(i_input => i_input, i_inst_par => i_inst_par);
        ELSIF i_mode = g_mode_full
        THEN
        
            -- check if the validation is made using domain
            IF i_inst_par(1).val_list IS NULL
                OR i_inst_par(1).val_list.count < 1
            THEN
                l_domain := TRUE;
            ELSE
                l_domain := FALSE;
            END IF;
        
            -- check condition validity
            IF i_input IS NOT NULL
               AND i_input.count > 0
            THEN
                -- first, start by cross checking the input parameters
                FOR i IN i_input.first .. i_input.last
                LOOP
                    --ALERT-255254
                
                    IF i_input(i).id_cdr_concept IN (pk_cdr_constant.g_cdrcp_vs)
                        AND i_input(i).id_element = i_inst_par(1).id_element
                    THEN
                        l_ret := pk_alert_constant.g_yes;
                    
                        -- store call detail row
                        l_cdrld.id_cdr_inst_param := i_inst_par(1).id_cdr_inst_param;
                        l_cdrld.id_cdr_instance   := i_inst_par(1).id_cdr_instance;
                    
                        l_cdrld.param_value := i_inst_par(1).id_element;
                        add_cdrld(i_cdrld => l_cdrld);
                        IF l_domain
                        THEN
                            -- check if element is within domain
                            g_error := 'CALL get_in_domain';
                            l_ret   := get_in_domain(i_result    => i_input(i).dose,
                                                     i_res_um    => nvl(i_input(i).id_dose_umea, -1),
                                                     i_val_min   => i_inst_par(1).val_min,
                                                     i_val_max   => i_inst_par(1).val_max,
                                                     i_domain_um => nvl(i_inst_par(1).id_domain_umea, -1));
                        
                        ELSE
                        
                            l_ret := pk_alert_constant.g_no;
                        
                        END IF;
                    
                        EXIT;
                    END IF;
                
                END LOOP;
            END IF;
        
            --
        
            IF l_ret IS NULL
            THEN
            
                -- check condition validity
                IF i_inst_par(1).validity IS NOT NULL
                THEN
                    -- if validity is set, then calculate the date span
                    l_span := pk_date_utils.add_days_to_tstz(i_timestamp => g_sysdate_tstz,
                                                             i_days      => -to_days(i_span => i_inst_par(1).validity,
                                                                                     i_tmu  => i_inst_par(1).id_validity_umea));
                END IF;
            
                l_ret := pk_alert_constant.g_no;
            
                -- check if the VS parameter has a result within the date span
                g_error := 'CALL pk_vital_sign_pbl.get_last_vital_sign';
                IF NOT pk_vital_sign_pbl.get_last_vital_sign(i_lang          => i_lang,
                                                             i_prof          => i_prof,
                                                             i_id_patient    => i_patient,
                                                             i_id_vital_sign => i_inst_par(1).id_element,
                                                             i_date          => l_span,
                                                             o_info          => l_cursor,
                                                             o_error         => o_error)
                
                THEN
                    RAISE g_exception;
                END IF;
            
                g_error := 'FETCH l_cursor';
                FETCH l_cursor
                    INTO l_result, l_um, l_opt, l_dt_ltr;
                g_found := l_cursor%FOUND;
                CLOSE l_cursor;
            
                IF g_found
                THEN
                    IF l_domain
                    THEN
                        -- check if element is within domain
                        g_error := 'CALL get_in_domain';
                        l_ret   := get_in_domain(i_result    => l_result,
                                                 i_res_um    => l_um,
                                                 i_val_min   => i_inst_par(1).val_min,
                                                 i_val_max   => i_inst_par(1).val_max,
                                                 i_domain_um => nvl(i_inst_par(1).id_domain_umea, -1));
                    
                    ELSE
                        -- search element in list
                        IF pk_utils.search_table_varchar(i_table => i_inst_par(1).val_list, i_search => to_char(l_opt)) > 0
                        THEN
                            l_ret := pk_alert_constant.g_yes;
                        ELSE
                            l_ret := pk_alert_constant.g_no;
                        END IF;
                    END IF;
                ELSE
                    l_ret := pk_alert_constant.g_no;
                END IF;
            END IF;
        
            --
        
            l_ret := get_denied(i_result => l_ret, i_deny => i_inst_par(1).flg_deny);
            o_ret := t_coll_cdr_out(t_rec_cdr_out(ret => l_ret, info => NULL, id_user_elem => NULL));
        
        ELSE
            g_error := 'Unrecognized execution mode!';
            RAISE g_fault;
        END IF;
    END check_vs;

    /**
    * Get condition description, when it uses validation domain.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_concept      concept identifier
    * @param i_val_min      minimum value
    * @param i_val_max      maximum value
    * @param i_domain_um    domain measurement unit
    *
    * @return               condition description
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/04/05
    */
    FUNCTION get_val_cond_desc
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_concept   IN cdr_concept.id_cdr_concept%TYPE,
        i_val_min   IN cdr_inst_param.val_min%TYPE,
        i_val_max   IN cdr_inst_param.val_max%TYPE,
        i_domain_um IN cdr_inst_param.id_domain_umea%TYPE
    ) RETURN pk_translation.t_desc_translation IS
        l_tag1 CONSTANT VARCHAR2(2 CHAR) := '@1';
        l_tag2 CONSTANT VARCHAR2(2 CHAR) := '@2';
        l_ret      pk_translation.t_desc_translation;
        l_code     sys_message.code_message%TYPE;
        l_tag1_val pk_translation.t_desc_translation;
        l_tag2_val pk_translation.t_desc_translation;
        l_um       pk_translation.t_desc_translation;
        l_val_tmp  VARCHAR2(0100 CHAR);
    
        FUNCTION calc_val
        (
            i_concept   IN NUMBER,
            i_num       IN NUMBER,
            i_domain_um IN NUMBER,
            i_abrev     IN VARCHAR2,
            i_concat    IN VARCHAR2
        ) RETURN VARCHAR2 IS
            l_return VARCHAR2(0500 CHAR);
            l_um     VARCHAR2(0500 CHAR);
        BEGIN
        
            IF i_concept = pk_cdr_constant.g_cdrcp_age
            THEN
                IF i_domain_um = k_uma_month
                   AND i_num >= 12
                THEN
                    l_return := trunc(i_num / 12);
                    l_um     := pk_unit_measure.get_uom_abbreviation(i_lang         => i_lang,
                                                                     i_prof         => i_prof,
                                                                     i_unit_measure => k_uma_year);
                ELSE
                    l_return := i_num;
                    l_um     := i_abrev;
                END IF;
            ELSE
                l_return := i_num;
                l_um     := i_abrev;
            END IF;
            IF i_concat = 'Y'
            THEN
                l_return := l_return || g_space || l_um;
            END IF;
        
            RETURN l_return;
        
        END calc_val;
    
    BEGIN
        IF (i_val_min IS NULL AND i_val_max IS NULL)
           OR i_domain_um IS NULL
           OR i_concept IS NULL
        THEN
            l_ret := NULL;
        ELSE
            -- get measurement unit description
            l_um := pk_unit_measure.get_uom_abbreviation(i_lang         => i_lang,
                                                         i_prof         => i_prof,
                                                         i_unit_measure => i_domain_um);
        
            IF i_val_min IS NULL
            THEN
                -- only max value set
                IF i_concept = pk_cdr_constant.g_cdrcp_age
                THEN
                    l_code := 'CDR_T093';
                ELSIF i_concept = pk_cdr_constant.g_cdrcp_lab_test_par
                THEN
                    l_code := 'CDR_T096';
                ELSIF i_concept = pk_cdr_constant.g_cdrcp_pregnancy
                THEN
                    l_code := 'CDR_T099';
                END IF;
            
                --l_tag1_val := i_val_max || g_space || l_um;
                l_tag1_val := calc_val(i_concept   => i_concept,
                                       i_num       => i_val_max,
                                       i_domain_um => i_domain_um,
                                       i_abrev     => l_um,
                                       i_concat    => 'Y');
            
            ELSIF i_val_max IS NULL
            THEN
                -- only min value set
                IF i_concept = pk_cdr_constant.g_cdrcp_age
                THEN
                    l_code := 'CDR_T092';
                ELSIF i_concept = pk_cdr_constant.g_cdrcp_lab_test_par
                THEN
                    l_code := 'CDR_T095';
                ELSIF i_concept = pk_cdr_constant.g_cdrcp_pregnancy
                THEN
                    l_code := 'CDR_T098';
                END IF;
            
                --l_tag1_val := i_val_min || g_space || l_um;
                l_tag1_val := calc_val(i_concept   => i_concept,
                                       i_num       => i_val_min,
                                       i_domain_um => i_domain_um,
                                       i_abrev     => l_um,
                                       i_concat    => 'Y');
            ELSE
                -- min and max values set
                IF i_concept = pk_cdr_constant.g_cdrcp_age
                THEN
                    l_code := 'CDR_T094';
                ELSIF i_concept = pk_cdr_constant.g_cdrcp_lab_test_par
                THEN
                    l_code := 'CDR_T097';
                ELSIF i_concept = pk_cdr_constant.g_cdrcp_pregnancy
                THEN
                    l_code := 'CDR_T100';
                END IF;
            
                --l_tag2_val := i_val_max || g_space || l_um;
                l_tag1_val := calc_val(i_concept   => i_concept,
                                       i_num       => i_val_min,
                                       i_domain_um => i_domain_um,
                                       i_abrev     => l_um,
                                       i_concat    => 'N');
                l_tag2_val := calc_val(i_concept   => i_concept,
                                       i_num       => i_val_max,
                                       i_domain_um => i_domain_um,
                                       i_abrev     => l_um,
                                       i_concat    => 'Y');
                END IF;
        
            l_ret := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => l_code);
            l_ret := REPLACE(REPLACE(l_ret, l_tag1, l_tag1_val), l_tag2, l_tag2_val);
        
            IF (i_concept = pk_cdr_constant.g_cdrcp_age)
            THEN
                l_ret := l_ret || g_space || '/' || g_space ||
                         pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'CDR_T117');
            END IF;
        END IF;
    
        RETURN l_ret;
    END get_val_cond_desc;

    /**
    * Get a parameter's validity description.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_val          validity value
    * @param i_val_um       validity time measurement unit
    *
    * @return               validity description
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/04/05
    */
    FUNCTION get_validity_desc
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_concept IN NUMBER,
        i_val    IN cdr_inst_param.validity%TYPE,
        i_val_um IN cdr_inst_param.id_validity_umea%TYPE
    ) RETURN pk_translation.t_desc_translation IS
        l_ret pk_translation.t_desc_translation;
    
    BEGIN
        IF i_val IS NULL
           OR i_val_um IS NULL
        THEN
            l_ret := NULL;
        ELSE
            l_ret := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'CDR_T101');
        
            l_ret := l_ret || g_space || i_val || g_space;
            l_ret := l_ret || pk_unit_measure.get_uom_abbreviation(i_lang         => i_lang,
                                                                   i_prof         => i_prof,
                                                                   i_unit_measure => i_val_um);
        END IF;
    
        RETURN l_ret;
    END get_validity_desc;

    /**
    * Get values domain description.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_val_min      minimum value
    * @param i_val_max      maximum value
    * @param i_domain_um    domain measurement unit
    *
    * @return               values domain description
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/05/09
    */
    FUNCTION get_val_domain_desc
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_val_min   IN cdr_inst_param.val_min%TYPE,
        i_val_max   IN cdr_inst_param.val_max%TYPE,
        i_domain_um IN cdr_inst_param.id_domain_umea%TYPE
    ) RETURN pk_translation.t_desc_translation IS
        l_ret pk_translation.t_desc_translation;
        l_um  pk_translation.t_desc_translation;
    BEGIN
        IF i_val_min IS NULL
           AND i_val_max IS NULL
        THEN
            l_ret := NULL;
        ELSE
            -- get measurement unit description
            g_error := 'CALL pk_unit_measure.get_uom_abbreviation';
            l_um    := pk_unit_measure.get_uom_abbreviation(i_lang         => i_lang,
                                                            i_prof         => i_prof,
                                                            i_unit_measure => i_domain_um);
            IF l_um IS NOT NULL
            THEN
                l_um := g_space || l_um;
            END IF;
        
            IF i_val_min IS NOT NULL
            THEN
                -- get minimum value
                l_ret := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'CDR_T066') ||
                         g_space || i_val_min || l_um;
            END IF;
            IF i_val_max IS NOT NULL
            THEN
                IF l_ret IS NOT NULL
                THEN
                    l_ret := l_ret || ', ';
                END IF;
            
                -- get maximum value
                l_ret := l_ret || pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'CDR_T067') ||
                         g_space || i_val_max || l_um;
            END IF;
        END IF;
    
        RETURN l_ret;
    END get_val_domain_desc;

    /**
    * Get element translation.
    * TODO: this function is temporary. Should be replaced by
    * the calls to CDR_CONCEPT.SERVICE_DESC.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_concept      rule concept identifier
    * @param i_element      element identifier
    * @param i_task_req     task request identifier
    *
    * @return               element description
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/05/10
    */
    FUNCTION get_elem_translation
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_concept  IN cdr_concept.id_cdr_concept%TYPE,
        i_element  IN cdr_inst_param.id_element%TYPE,
        i_task_req IN cdr_call_det.id_task_request%TYPE := NULL,
        i_call     IN cdr_call.id_cdr_call%TYPE := NULL
    ) RETURN pk_translation.t_desc_translation IS
        l_ret  pk_translation.t_desc_translation;
        l_code translation.code_translation%TYPE;
    
        l_id_episode         cdr_call.id_episode%TYPE;
        l_id_vital_sign_read vital_sign_read.id_vital_sign_read%TYPE;
        l_score_value        epis_mtos_param.registered_value%TYPE;
        l_internal_name      mtos_param.internal_name%TYPE;
        l_id                 NUMBER(24);
    
    BEGIN
        CASE
        
            WHEN i_concept = pk_cdr_constant.g_cdrcp_lab_test THEN
                l_ret := pk_lab_tests_external_api_db.get_alias_translation(i_lang          => i_lang,
                                                                            i_prof          => i_prof,
                                                                            i_flg_type      => pk_lab_tests_constant.g_analysis_alias,
                                                                            i_content       => i_element,
                                                                            i_dep_clin_serv => NULL);
            
            WHEN i_concept = pk_cdr_constant.g_cdrcp_lab_test_par THEN
                l_ret := pk_lab_tests_external_api_db.get_alias_translation(i_lang          => i_lang,
                                                                            i_prof          => i_prof,
                                                                            i_flg_type      => pk_lab_tests_constant.g_analysis_parameter_alias,
                                                                            i_content       => i_element,
                                                                            i_dep_clin_serv => NULL);
            
            WHEN i_concept = k_concept_isencao THEN
                l_id  := get_id_isencao(i_id_content => i_element);
                l_ret := pk_translation.get_translation(i_lang      => i_lang,
                                                        i_code_mess => 'ISENCAO.CODE_ISENCAO.' || to_char(l_id));
            
            WHEN i_concept = pk_cdr_constant.g_cdrcp_exam THEN
                l_ret := pk_exams_external_api_db.get_alias_translation(i_lang          => i_lang,
                                                                        i_prof          => i_prof,
                                                                        i_content       => i_element,
                                                                        i_dep_clin_serv => NULL);
            WHEN i_concept = pk_cdr_constant.g_cdrcp_diagnosis THEN
                BEGIN
                    SELECT pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_id_alert_diagnosis => NULL,
                                                      i_id_diagnosis       => d.id_diagnosis,
                                                      i_code               => d.code_icd,
                                                      i_flg_other          => d.flg_other,
                                                      i_flg_std_diag       => pk_alert_constant.g_yes) diag_desc
                      INTO l_ret
                      FROM diagnosis d
                     WHERE d.id_diagnosis = to_number(i_element);
                EXCEPTION
                    WHEN no_data_found THEN
                        l_ret := NULL;
                END;
            WHEN i_concept = pk_cdr_constant.g_cdrcp_allergy THEN
                l_code := 'ALLERGY.CODE_ALLERGY.' || i_task_req;
                l_ret  := pk_translation.get_translation(i_lang => i_lang, i_code_mess => l_code);
            WHEN i_concept = pk_cdr_constant.g_cdrcp_sr_proc THEN
                l_code := 'INTERVENTION.CODE_INTERVENTION.' || i_element;
                l_ret  := pk_procedures_api_db.get_alias_translation(i_lang          => i_lang,
                                                                     i_prof          => i_prof,
                                                                     i_code_interv   => l_code,
                                                                     i_dep_clin_serv => NULL);
            WHEN i_concept = pk_cdr_constant.g_cdrcp_procedure THEN
                l_code := 'INTERVENTION.CODE_INTERVENTION.' || i_element;
                l_ret  := pk_procedures_api_db.get_alias_translation(i_lang          => i_lang,
                                                                     i_prof          => i_prof,
                                                                     i_code_interv   => l_code,
                                                                     i_dep_clin_serv => NULL);
            WHEN i_concept IN (pk_cdr_constant.g_cdrcp_ddi,
                               pk_cdr_constant.g_cdrcp_ingredient,
                               pk_cdr_constant.g_cdrcp_ingr_group,
                               pk_cdr_constant.g_cdrcp_product,
                               pk_cdr_constant.g_cdrcp_drug_group) THEN
            
                log_me('[GET_MED_DESCRIPTION]: get description by ' || i_task_req || '*' || i_element);
                -- DECIDE IF GO BY PRESCRIPTION OR GO BY ID_PRODUCT
                IF pk_utils.is_number(char_in => i_task_req) = pk_alert_constant.g_yes
                THEN
                
                    l_ret := pk_api_pfh_ordertools_in.get_medication_description(i_lang     => i_lang,
                                                                                 i_prof     => i_prof,
                                                                                 i_id_presc => i_task_req);
                
                    log_me('[GET_MED_DESCRIPTION]: GO BY NORMAL' || l_ret);
                ELSE
                
                    l_ret := pk_api_pfh_in.get_product_desc(i_lang       => i_lang,
                                                            i_prof       => i_prof,
                                                            i_id_product => i_task_req);
                    log_me('[GET_MED_DESCRIPTION]: GO BY PROD' || l_ret);
                END IF;
            
            WHEN i_concept = pk_cdr_constant.g_cdrcp_rcm THEN
                l_code := 'RCM.CODE_RCM_SUMM.' || i_element;
                l_ret  := pk_translation.get_translation(i_lang => i_lang, i_code_mess => l_code);
            WHEN i_concept IN (pk_cdr_constant.g_cdrcp_rcm_sev_score, pk_cdr_constant.g_cdrcp_war_sev_score) THEN
            
                -- Get episode from CDR_CALL
                BEGIN
                
                    SELECT cdr_call.id_episode
                      INTO l_id_episode
                      FROM cdr_call cdr_call
                     WHERE cdr_call.id_cdr_call = i_call;
                
                EXCEPTION
                    WHEN OTHERS THEN
                        NULL;
                END;
            
                -- GET Vital Sign Read from episode and vital sign
                BEGIN
                    SELECT MAX(vsr.id_vital_sign_read)
                      INTO l_id_vital_sign_read
                      FROM vital_sign_read vsr
                     WHERE vsr.id_vital_sign = i_element
                       AND vsr.id_episode = l_id_episode;
                
                EXCEPTION
                    WHEN OTHERS THEN
                        NULL;
                END;
            
                -- Get registered value on scores by vital sign read
                BEGIN
                
                    SELECT emp.registered_value, mpm.internal_name
                      INTO l_score_value, l_internal_name
                      FROM epis_mtos_param emp, mtos_param mpm
                     WHERE decode(emp.flg_param_task_type,
                                  pk_sev_scores_constant.g_flg_param_task_vital_sign,
                                  emp.id_task_refid,
                                  NULL) = l_id_vital_sign_read
                       AND emp.id_mtos_param = mpm.id_mtos_param;
                
                    -- 1.1 SPECIFY RULE FOR TOTAL NEWS SCORE PARAM RED SCORE
                    IF l_internal_name = pk_sev_scores_constant.g_param_type_news
                       AND l_score_value = -1
                    THEN
                        l_score_value := 3;
                    END IF;
                EXCEPTION
                    WHEN OTHERS THEN
                        NULL;
                END;
            
                l_ret := pk_message.get_message(i_lang      => i_lang,
                                                i_prof      => i_prof,
                                                i_code_mess => 'RECOMMENDATION_T034');
                l_ret := l_ret || l_score_value;
            
            WHEN i_concept = pk_cdr_constant.g_cdrcp_vs THEN
                l_code := 'VITAL_SIGN.CODE_VITAL_SIGN.' || i_element;
                l_ret  := pk_translation.get_translation(i_lang => i_lang, i_code_mess => l_code);
            
            ELSE
                l_ret := NULL;
        END CASE;
    
        RETURN l_ret;
    END get_elem_translation;

    /**
    * Get "Triggered by" field description.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_call         call identifier
    * @param i_instance     rule instance identifier
    *
    * @return               "triggered by" description
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/05/10
    */
    FUNCTION get_triggered_by
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_call     IN cdr_call.id_cdr_call%TYPE,
        i_instance IN cdr_instance.id_cdr_instance%TYPE
    ) RETURN CLOB IS
        l_colon CONSTANT VARCHAR2(1 CHAR) := ':';
        l_um       VARCHAR2(0500 CHAR);
        l_ret      CLOB;
        l_buf      VARCHAR2(2000 CHAR);
        l_idx      PLS_INTEGER := 1;
        l_par_cnt  PLS_INTEGER;
        l_val_desc pk_translation.t_desc_translation;
        l_lbl_deny sys_message.desc_message%TYPE;
    
        CURSOR c_trig IS
            SELECT cdrdc.flg_deny,
                   pk_translation.get_translation(i_lang, cdrc.code_cdr_cond_fo) desc_condition,
                   (SELECT pk_sysdomain.get_domain(pk_cdr_constant.g_domain_operator, cdrdc.flg_condition, i_lang)
                      FROM dual) desc_oper,
                   cdrdc.flg_condition,
                   cdrp.id_cdr_concept,
                   cdrip.id_element,
                   cdrcp.flg_identifiable,
                   cdrip.validity,
                   cdrip.id_validity_umea,
                   cdrip.val_min,
                   cdrip.val_max,
                   cdrip.id_domain_umea,
                   cdrld.id_task_request,
                   cdrld.param_value,
                   COUNT(*) over(PARTITION BY cdrip.id_cdr_instance, cdrp.id_cdr_def_cond) cond_par_count
              FROM cdr_inst_param cdrip
              JOIN cdr_parameter cdrp
                ON cdrip.id_cdr_parameter = cdrp.id_cdr_parameter
              JOIN cdr_concept cdrcp
                ON cdrp.id_cdr_concept = cdrcp.id_cdr_concept
              JOIN cdr_def_cond cdrdc
                ON cdrp.id_cdr_def_cond = cdrdc.id_cdr_def_cond
              JOIN cdr_condition cdrc
                ON cdrdc.id_cdr_condition = cdrc.id_cdr_condition
              LEFT JOIN cdr_call_det cdrld
                ON cdrip.id_cdr_inst_param = cdrld.id_cdr_inst_param
               AND cdrld.id_cdr_call = i_call
             WHERE cdrip.id_cdr_instance = i_instance
             ORDER BY cdrdc.rank, cdrp.rank;
    
        TYPE t_coll_trig IS TABLE OF c_trig%ROWTYPE;
        l_trig t_coll_trig;
        
        FUNCTION calc_val
        (
            i_num       IN NUMBER,
            i_domain_um IN NUMBER
        ) RETURN VARCHAR2 IS
            l_age    NUMBER;
            l_id_mea NUMBER;
            l_return VARCHAR2(0500 CHAR);
            l_um     VARCHAR2(0500 CHAR);
            k_months constant number := 12;
        BEGIN
        
            -- calc_val( i_concept => , i_num => i_val, i_domain_um => i_val_um)
            IF i_domain_um = k_uma_month
               AND i_num >= k_months
            THEN
                l_age    := trunc(i_num / k_months);
                l_id_mea := k_uma_year;
            ELSE
                l_age    := i_num;
                l_id_mea := i_domain_um;
            END IF;
        
            l_um := pk_unit_measure.get_uom_abbreviation(i_lang => i_lang, i_prof => i_prof, i_unit_measure => l_id_mea);
        
            l_return := l_return || l_age || g_space || l_um;
        
            RETURN l_return;
        
        END calc_val;

        
        
        
    BEGIN
        IF i_instance IS NULL
        THEN
            NULL;
        ELSE
            -- retrieve instance data
            g_error := 'OPEN c_trig';
            OPEN c_trig;
            FETCH c_trig BULK COLLECT
                INTO l_trig;
            CLOSE c_trig;
        
            IF l_trig IS NULL
               OR l_trig.count < 1
            THEN
                NULL;
            ELSE
                dbms_lob.createtemporary(l_ret, TRUE);
                l_lbl_deny := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'CDR_T102');
            
                WHILE l_trig.count >= l_idx
                LOOP
                    -- current condition parameter count
                    l_par_cnt := l_trig(l_idx).cond_par_count;
                
                    -- add deniability
                    IF l_trig(l_idx).flg_deny = pk_alert_constant.g_yes
                    THEN
                        l_buf := l_lbl_deny || g_space;
                    ELSE
                        l_buf := NULL;
                    END IF;
                    -- add condition
                    IF l_trig(l_idx).id_domain_umea IS NULL
                    THEN
                        -- condition uses no validation domain
                        l_buf := l_buf || l_trig(l_idx).desc_condition;
                    ELSE
                        -- condition uses validation domain
                        l_buf := l_buf || get_val_cond_desc(i_lang      => i_lang,
                                                            i_prof      => i_prof,
                                                            i_concept   => l_trig(l_idx).id_cdr_concept,
                                                            i_val_min   => l_trig(l_idx).val_min,
                                                            i_val_max   => l_trig(l_idx).val_max,
                                                            i_domain_um => l_trig(l_idx).id_domain_umea);
                    END IF;
                    -- add elements
                    FOR i IN 1 .. l_par_cnt
                    LOOP
                        -- add validity
                        l_val_desc := TRIM(get_validity_desc(i_lang   => i_lang,
                                                             i_prof   => i_prof,
                                                             i_concept => l_trig(l_idx).id_cdr_concept,
                                                             i_val    => l_trig(l_idx).validity,
                                                             i_val_um => l_trig(l_idx).id_validity_umea));
                        IF l_val_desc IS NOT NULL
                        THEN
                            l_buf := l_buf || g_space || l_val_desc;
                        
                            IF i = 1
                            THEN
                                l_buf := l_buf || l_colon;
                            END IF;
                        
                        END IF;
                    
                        -- add element translation
                        IF l_trig(l_idx).flg_identifiable = pk_alert_constant.g_yes
                        THEN
                            l_buf := l_buf || g_space || get_elem_translation(i_lang     => i_lang,
                                                                              i_prof     => i_prof,
                                                                              i_concept  => l_trig(l_idx).id_cdr_concept,
                                                                              i_element  => l_trig(l_idx).id_element,
                                                                              i_task_req => l_trig(l_idx).id_task_request,
                                                                              i_call     => i_call);
                        ELSIF l_trig(l_idx).param_value IS NOT NULL
                        THEN
                        
                            IF l_trig(l_idx).id_cdr_concept = pk_cdr_constant.g_cdrcp_age
                            THEN
                              /*
                                l_um  := pk_unit_measure.get_uom_abbreviation(i_lang         => i_lang,
                                                                              i_prof         => i_prof,
                                                                              i_unit_measure => l_trig(l_idx).id_domain_umea);
                                l_buf := l_buf || g_space || l_trig(l_idx).param_value || g_space || l_um;
                             */   
                                l_buf := l_buf || g_space || calc_val( l_trig(l_idx).param_value, l_trig(l_idx).id_domain_umea) ;
                                
                                
                            ELSE
                            l_buf := l_buf || g_space || l_trig(l_idx).param_value;
                        END IF;
                        END IF;
                        -- trail element translation
                        IF i = l_par_cnt
                        THEN
                            l_buf := l_buf || pk_string_utils.g_new_line;
                        ELSE
                            l_buf := l_buf || ',' || g_space;
                            l_idx := l_idx + 1;
                        END IF;
                    END LOOP;
                    -- add operator
                    IF l_idx != l_trig.last
                    THEN
                        l_buf := l_buf || l_trig(l_idx).desc_oper || pk_string_utils.g_new_line;
                    END IF;
                
                    dbms_lob.writeappend(l_ret, length(l_buf), l_buf);
                    l_idx := l_idx + 1;
                END LOOP;
            END IF;
        END IF;
    
        RETURN l_ret;
    END get_triggered_by;

    /**
    * Is the notes field mandatory? Y/N
    *
    * @param i_answer       answer identifier
    * @param i_cdrs         rule severity identifier
    * @param i_institution  institution identifier
    *
    * @return               'Y', if notes are mandatory, 'N' otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/03/09
    */
    FUNCTION get_notes_mandatory
    (
        i_answer      IN cdr_answer.id_cdr_answer%TYPE,
        i_cdrs        IN cdr_severity.id_cdr_severity%TYPE,
        i_institution IN institution.id_institution%TYPE
    ) RETURN cdr_answer.flg_req_notes%TYPE IS
        l_ret cdr_answer.flg_req_notes%TYPE;
    
        CURSOR c_notes IS
            SELECT pk_alert_constant.g_no flg_mandatory
              FROM cdr_ans_sev_inst cdrasi
             WHERE cdrasi.id_cdr_answer = i_answer
               AND cdrasi.id_cdr_severity = i_cdrs
               AND cdrasi.id_institution = i_institution;
    BEGIN
        IF i_cdrs IS NULL
           OR i_institution IS NULL
        THEN
            l_ret := NULL;
        ELSE
            OPEN c_notes;
            FETCH c_notes
                INTO l_ret;
            g_found := c_notes%FOUND;
            CLOSE c_notes;
        
            IF g_found
            THEN
                l_ret := pk_alert_constant.g_no;
            ELSE
                l_ret := pk_alert_constant.g_yes;
            END IF;
        END IF;
    
        RETURN l_ret;
    END get_notes_mandatory;

    /**
    * Get the description of all instance elements.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_instance     rule instance identifiers list
    * @param o_msg          element descriptions cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/05/09
    */
    FUNCTION get_inst_elems
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_instances IN table_number,
        o_element   OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_INST_ELEMS';
        l_inst  t_coll_cdrip;
        l_dummy table_number;
    BEGIN
        EXECUTE IMMEDIATE 'truncate table tbl_temp';
    
        INSERT INTO tbl_temp
            (num_1)
            SELECT t.column_value id_cdr_instance
              FROM TABLE(i_instances) t;
    
        g_error := 'OPEN c_cdrip';
        OPEN c_cdrip;
        FETCH c_cdrip BULK COLLECT
            INTO l_inst, l_dummy;
        CLOSE c_cdrip;
    
        -- TODO: optimize - there's no need to have this select
        g_error := 'OPEN o_element';
        OPEN o_element FOR
            SELECT id_cdr_instance,
                   desc_concept,
                   decode(flg_identifiable,
                          pk_alert_constant.g_yes,
                          desc_element || decode(desc_val_domain, NULL, NULL, ' (' || desc_val_domain || ')'),
                          desc_val_domain) desc_element
              FROM (SELECT cdrip.id_cdr_instance,
                           cdrip.flg_identifiable,
                           (SELECT pk_translation.get_translation(i_lang, cdrcp.code_cdr_concept)
                              FROM dual) desc_concept,
                           (SELECT get_elem_translation(i_lang, i_prof, cdrip.id_cdr_concept, cdrip.id_element)
                              FROM dual) desc_element,
                           get_val_domain_desc(i_lang, i_prof, cdrip.val_min, cdrip.val_max, cdrip.id_domain_umea) desc_val_domain
                      FROM (SELECT /*+opt_estimate(table t rows=1)*/
                             rownum rn,
                             t.id_cdr_inst_param,
                             t.id_cdr_instance,
                             t.id_cdr_concept,
                             t.flg_identifiable,
                             t.id_element,
                             t.val_min,
                             t.val_max,
                             t.id_domain_umea
                              FROM TABLE(l_inst) t) cdrip
                      JOIN cdr_concept cdrcp
                        ON cdrip.id_cdr_concept = cdrcp.id_cdr_concept
                     ORDER BY cdrip.rn);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_element);
            RETURN FALSE;
    END get_inst_elems;

    /**
    * Checks the CDR engine for applicable rules.
    * Analyzes all rules within the framework, and creates events for the valid ones.
    * Outputs a list of rules that must be seen as warnings.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_call         previous call identifier
    * @param i_concepts     rule concept identifiers list
    * @param i_elements     element identifiers list
    * @param i_dose         dosage values list
    * @param i_dose_um      dosage measurement units list
    * @param i_route        administration routes list
    * @param o_sect1        popup section 1 cursor
    * @param o_sect2        popup section 2 cursor
    * @param o_sect3        popup section 3 cursor
    * @param o_sect4        popup section 4 cursor
    * @param o_call         call identifier
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Orlando Antunes
    * @version               2.6.1
    * @since                2011/02/10
    */
    FUNCTION check_rules
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_call        IN cdr_call.id_cdr_call%TYPE := NULL,
        i_concepts    IN table_number,
        i_elements    IN table_varchar,
        i_dose        IN table_number,
        i_dose_um     IN table_number,
        i_route       IN table_varchar,
        i_screen_name IN VARCHAR2,
        o_sect1       OUT pk_types.cursor_type,
        o_sect2       OUT pk_types.cursor_type,
        o_sect3       OUT pk_types.cursor_type,
        o_sect4       OUT pk_types.cursor_type,
        o_call        OUT cdr_call.id_cdr_call%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CHECK_RULES';
        l_input   t_coll_cdr_in;
        l_actions t_coll_cdre;
    
    BEGIN
    
        log_me('[START_TRACE CHECK_RULES]' || i_call);
        log_me('= GOT I_CALL ' || i_call);
        -- reset global variables
        g_error := 'RESET GLOBAL VARIABLES';
        reset_var(i_prof => i_prof);
        IF g_alert_engine = pk_alert_constant.g_yes
        THEN
            g_error := 'CALL format_input';
            l_input := format_input(i_lang       => i_lang,
                                    i_prof       => i_prof,
                                    i_concepts   => i_concepts,
                                    i_elements   => i_elements,
                                    i_task_types => NULL,
                                    i_task_reqs  => NULL,
                                    i_dose       => i_dose,
                                    i_dose_um    => i_dose_um,
                                    i_route      => i_route,
                                    o_error      => o_error);
        END IF;
        IF g_vidal_engine = pk_alert_constant.g_yes
        THEN
            g_error := 'CALL ADD_CDR_INPUT';
            log_me(g_error);
            add_cdr_input(i_type         => 'CONCEPTS',
                          i_concept_task => i_concepts,
                          i_elements     => i_elements,
                          i_dose         => i_dose,
                          i_dose_um      => i_dose_um,
                          i_route        => i_route,
                          i_id_task_type => NULL);
        END IF;
        g_error := 'CALL check_cdr';
        check_cdr(i_lang        => i_lang,
                  i_prof        => i_prof,
                  i_patient     => i_patient,
                  i_episode     => i_episode,
                  i_call        => i_call,
                  i_input       => l_input,
                  i_screen_name => i_screen_name,
                  o_actions     => l_actions,
                  o_error       => o_error);
    
        g_error := 'CALL set_events';
        set_events(i_lang    => i_lang,
                   i_prof    => i_prof,
                   i_episode => i_episode,
                   i_patient => i_patient,
                   i_call    => g_id_cdr_call,
                   i_act     => l_actions,
                   o_call    => o_call,
                   o_error   => o_error);
    
        o_call := nvl(o_call, g_id_cdr_call);
    
        g_error := 'CALL get_popup_sections';
        get_popup_sections(i_lang      => i_lang,
                           i_prof      => i_prof,
                           i_call      => o_call,
                           i_use_input => pk_alert_constant.g_yes,
                           o_sect1     => o_sect1,
                           o_sect2     => o_sect2,
                           o_sect3     => o_sect3,
                           o_sect4     => o_sect4);
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN g_exception_control THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
            
                l_error_in.set_all(
                                   
                                   i_id_lang       => i_lang,
                                   i_sqlcode       => NULL,
                                   i_sqlerrm       => g_error,
                                   i_user_err      => NULL,
                                   i_owner         => g_owner,
                                   i_pck_name      => g_package,
                                   i_function_name => g_function_name,
                                   i_action        => NULL,
                                   i_flg_action    => 'U',
                                   i_msg_title     => NULL,
                                   i_msg_type      => 'E');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
            END;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END check_rules;

    /**
    * Checks the CDR engine for applicable rules, using task types.
    * Analyzes all rules within the framework, and creates events for the valid ones.
    * Outputs a list of rules that must be seen as warnings.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_call         previous call identifier
    * @param i_task_types   task type identifiers list
    * @param i_task_reqs    task request identifiers list
    * @param i_dose         dosage values list
    * @param i_dose_um      dosage measurement units list
    * @param i_route        administration routes list
    * @param o_sect1        popup section 1 cursor
    * @param o_sect2        popup section 2 cursor
    * @param o_sect3        popup section 3 cursor
    * @param o_sect4        popup section 4 cursor
    * @param o_btn_config   popup buttons config
    * @param o_call         call identifier
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Orlando Antunes
    * @version               2.6.1
    * @since                2011/02/10
    */
    FUNCTION check_rules_tt
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_call         IN cdr_call.id_cdr_call%TYPE := NULL,
        i_task_types   IN table_number,
        i_task_reqs    IN table_varchar,
        i_dose         IN table_number,
        i_dose_um      IN table_number,
        i_route        IN table_varchar,
        i_id_task_type IN task_type.id_task_type%TYPE, -- the area where check_rules is called
        i_screen_name  IN VARCHAR2,
        o_sect1        OUT pk_types.cursor_type,
        o_sect2        OUT pk_types.cursor_type,
        o_sect3        OUT pk_types.cursor_type,
        o_sect4        OUT pk_types.cursor_type,
        o_btn_config   OUT pk_types.cursor_type,
        o_call         OUT cdr_call.id_cdr_call%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CHECK_RULES_TT';
        l_input   t_coll_cdr_in;
        l_actions t_coll_cdre;
    
    BEGIN
    
        g_function_name := l_func_name;
    
        log_me('[START_TRACE CHECK_RULES_TT]' || i_call);
        log_me('= GOT I_CALL ' || i_call);
        -- reset global variables
        g_error := 'RESET GLOBAL VARIABLES';
        reset_var(i_prof => i_prof);
    
        IF g_alert_engine = pk_alert_constant.g_yes
        THEN
            g_error := 'CALL format_input';
            l_input := format_input(i_lang       => i_lang,
                                    i_prof       => i_prof,
                                    i_concepts   => NULL,
                                    i_elements   => NULL,
                                    i_task_types => i_task_types,
                                    i_task_reqs  => i_task_reqs,
                                    i_dose       => i_dose,
                                    i_dose_um    => i_dose_um,
                                    i_route      => i_route,
                                    o_error      => o_error);
        END IF;
    
        IF g_vidal_engine = pk_alert_constant.g_yes
        THEN
            g_error := 'CALL ADD_CDR_INPUT TASK_TYPE: ' || i_id_task_type;
            log_me(g_error);
            add_cdr_input(i_type         => 'TASK_TYPES',
                          i_concept_task => i_task_types,
                          i_elements     => i_task_reqs,
                          i_dose         => i_dose,
                          i_dose_um      => i_dose_um,
                          i_route        => i_route,
                          i_id_task_type => i_id_task_type);
        END IF;
    
        g_error := 'CALL check_cdr';
        check_cdr(i_lang        => i_lang,
                  i_prof        => i_prof,
                  i_patient     => i_patient,
                  i_episode     => i_episode,
                  i_call        => i_call,
                  i_input       => l_input,
                  i_screen_name => i_screen_name,
                  o_actions     => l_actions,
                  o_error       => o_error);
    
        g_error := 'CALL SET_EVENTS';
        set_events(i_lang    => i_lang,
                   i_prof    => i_prof,
                   i_episode => i_episode,
                   i_patient => i_patient,
                   i_call    => g_id_cdr_call,
                   i_act     => l_actions,
                   o_call    => o_call,
                   o_error   => o_error);
    
        o_call := nvl(o_call, g_id_cdr_call);
    
        g_error := 'CALL get_popup_sections';
        get_popup_sections(i_lang         => i_lang,
                           i_prof         => i_prof,
                           i_call         => o_call,
                           i_use_input    => pk_alert_constant.g_yes,
                           i_id_task_type => i_id_task_type,
                           o_sect1        => o_sect1,
                           o_sect2        => o_sect2,
                           o_sect3        => o_sect3,
                           o_sect4        => o_sect4);
    
        g_error := 'OPEN o_btn_config';
        OPEN o_btn_config FOR
            SELECT CASE
                        WHEN t.cnt > 0 THEN
                         pk_alert_constant.g_yes
                        ELSE
                         pk_alert_constant.g_no
                    END flg_read
              FROM (SELECT COUNT(1) cnt
                      FROM task_type_actions tta
                     WHERE tta.id_task_type = i_id_task_type) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN g_exception_control THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
            
                l_error_in.set_all(
                                   
                                   i_id_lang       => i_lang,
                                   i_sqlcode       => NULL,
                                   i_sqlerrm       => g_error,
                                   i_user_err      => NULL,
                                   i_owner         => g_owner,
                                   i_pck_name      => g_package,
                                   i_function_name => g_function_name,
                                   i_action        => NULL,
                                   i_flg_action    => 'U',
                                   i_msg_title     => NULL,
                                   i_msg_type      => 'E');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
            END;
            RETURN FALSE;
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END check_rules_tt;

    FUNCTION is_patient_dead(i_id_patient IN NUMBER) RETURN BOOLEAN IS
        l_count NUMBER;
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM patient x
         WHERE x.id_patient = i_id_patient
           AND x.dt_deceased IS NOT NULL;
    
        RETURN(l_count > 0);
    
    END is_patient_dead;

    /**
    * Checks the CDR engine for applicable rules in the given areas.
    * Analyzes all rules within the framework, and creates events for the valid ones.
    * Outputs a list of rules that must be seen as warnings.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_area         area identifiers list
    * @param o_sect1        popup section 1 cursor
    * @param o_sect2        popup section 2 cursor
    * @param o_sect3        popup section 3 cursor
    * @param o_sect4        popup section 4 cursor
    * @param o_call         call identifier
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.3
    * @since                2011/10/07
    */
    FUNCTION check_rules_area
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_area    IN table_number,
        o_sect1   OUT pk_types.cursor_type,
        o_sect2   OUT pk_types.cursor_type,
        o_sect3   OUT pk_types.cursor_type,
        o_sect4   OUT pk_types.cursor_type,
        o_call    OUT cdr_call.id_cdr_call%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CHECK_RULES_AREA';
        l_definitions table_number := table_number();
        l_actions     t_coll_cdre;
        l_prof_cat    category.id_category%TYPE;
        l_market      market.id_market%TYPE;
    
        CURSOR c_def IS
            SELECT cdrd.id_cdr_definition
              FROM cdr_definition cdrd
             WHERE cdrd.id_institution IN (0, i_prof.institution)
               AND cdrd.flg_status IN (pk_alert_constant.g_active, pk_cdr_constant.g_edited)
               AND cdrd.flg_available = pk_alert_constant.g_yes
               AND cdrd.flg_generic = pk_alert_constant.g_no
                  
               AND EXISTS (SELECT NULL
                      FROM cdr_def_mkt cdrdm
                     WHERE cdrdm.id_cdr_definition = cdrd.id_cdr_definition
                       AND cdrdm.id_category IN (-1, l_prof_cat)
                       AND cdrdm.id_software IN (0, i_prof.software)
                       AND cdrdm.id_market IN (0, l_market)
                    UNION ALL
                    SELECT NULL
                      FROM cdr_def_inst cdrdi
                     WHERE cdrdi.id_cdr_definition = cdrd.id_cdr_definition
                       AND cdrdi.id_category IN (-1, l_prof_cat)
                       AND cdrdi.id_software IN (0, i_prof.software)
                       AND cdrdi.id_institution = i_prof.institution
                       AND cdrdi.flg_add_remove = pk_cdr_constant.g_add)
               AND NOT EXISTS (SELECT NULL
                      FROM cdr_def_inst cdrdi
                     WHERE cdrdi.id_cdr_definition = cdrd.id_cdr_definition
                       AND cdrdi.id_category IN (-1, l_prof_cat)
                       AND cdrdi.id_software IN (0, i_prof.software)
                       AND cdrdi.id_institution = i_prof.institution
                       AND cdrdi.flg_add_remove = pk_cdr_constant.g_rem)
            
            ;
    BEGIN
        -- TODO: the areas list is meant to set
        -- which definitions will be used to check rules against
    
        IF NOT is_patient_dead(i_patient)
        THEN
        
        log_me('[START_TRACE CHECK_RULES_AREA]');
    
        l_prof_cat := pk_prof_utils.get_id_category(i_lang => NULL, i_prof => i_prof);
        l_market   := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
    
        g_error := 'OPEN c_def';
        OPEN c_def;
        FETCH c_def BULK COLLECT
            INTO l_definitions;
        CLOSE c_def;
    
        -- debug definitions to evaluate
        log_tn(i_tn => l_definitions, i_func_name => l_func_name);
    
        g_error := 'CALL check_cdr_def';
        check_cdr_def(i_lang        => i_lang,
                      i_prof        => i_prof,
                      i_patient     => i_patient,
                      i_episode     => i_episode,
                      i_definitions => l_definitions,
                      o_actions     => l_actions,
                      o_error       => o_error);
    
        g_error := 'CALL set_events';
        set_events(i_lang    => i_lang,
                   i_prof    => i_prof,
                   i_episode => i_episode,
                   i_patient => i_patient,
                   i_call    => NULL,
                   i_act     => l_actions,
                   o_call    => o_call,
                   o_error   => o_error);
    
        g_error := 'CALL get_popup_sections';
        get_popup_sections(i_lang      => i_lang,
                           i_prof      => i_prof,
                           i_call      => o_call,
                           i_use_input => pk_alert_constant.g_no,
                           o_sect1     => o_sect1,
                           o_sect2     => o_sect2,
                           o_sect3     => o_sect3,
                           o_sect4     => o_sect4);
        else
            pk_types.open_my_cursor(o_sect1);
            pk_types.open_my_cursor(o_sect2);
            pk_types.open_my_cursor(o_sect3);
            pk_types.open_my_cursor(o_sect4);
        END IF; -- patient is dead?
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END check_rules_area;

    /**
    * Set the user's answer to the warnings.
    * Outputs the list of elements that were chosen to proceed.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_concepts     rule concept identifiers list (user input)
    * @param i_elements     element identifiers list (user input)
    * @param i_call         call identifier
    * @param i_cdripas      rule instance parameter action identifiers list
    * @param i_answers      answer identifiers list
    * @param i_ans_notes    answer notes list
    * @param o_concepts     rule concept identifiers list (filtered)
    * @param o_elements     element identifiers list (filtered)
    * @param o_call         call identifier
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/26
    */
    FUNCTION set_answer
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_concepts         IN table_number,
        i_elements         IN table_varchar,
        i_call             IN cdr_call.id_cdr_call%TYPE,
        i_cdripas          IN table_number,
        i_answers          IN table_number,
        i_ans_notes        IN table_clob,
        i_domain_value     IN table_varchar DEFAULT table_varchar(),
        i_domain_free_text IN table_varchar DEFAULT table_varchar(),
        o_concepts         OUT table_number,
        o_elements         OUT table_varchar,
        o_call             OUT cdr_call.id_cdr_call%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_ANSWER';
        l_concepts     table_number; -- filtered rule concepts
        l_elements     table_varchar; -- filtered elements
        l_heeded_cdrcp table_number := table_number(); -- heeded rule concepts
        l_heeded_elem  table_varchar := table_varchar(); -- heeded elements
        l_act_info     t_act_info;
        l_idx          PLS_INTEGER;
        ------
        l_domain_value     table_varchar := table_varchar();
        l_domain_free_text table_varchar := table_varchar();
        l_content_elements table_varchar := table_varchar();
        l_content          VARCHAR2(4000 CHAR);
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        IF i_domain_value.count = 0
        THEN
            l_domain_value.extend(i_answers.count);
        ELSE
            l_domain_value := i_domain_value;
        END IF;
    
        IF i_domain_value.count = 0
        THEN
            l_domain_free_text.extend(i_answers.count);
        ELSE
            l_domain_free_text := i_domain_free_text;
        END IF;
    
        -- debug input
        IF g_debug_enable
        THEN
            g_error := 'i_lang: ' || i_lang;
            g_error := g_error || ', i_prof: ' || pk_utils.to_string(i_input => i_prof);
            g_error := g_error || ', i_concepts: ' || pk_utils.to_string(i_input => i_concepts);
            g_error := g_error || ', i_elements: ' || pk_utils.to_string(i_input => i_elements);
            g_error := g_error || ', i_call: ' || i_call;
            g_error := g_error || ', i_cdripas: ' || pk_utils.to_string(i_input => i_cdripas);
            g_error := g_error || ', i_answers: ' || pk_utils.to_string(i_input => i_answers);
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error := 'OPEN c_act_info';
        OPEN c_act_info(i_call => i_call);
        FETCH c_act_info BULK COLLECT
            INTO l_act_info;
        CLOSE c_act_info;
    
        IF l_act_info IS NULL
           OR l_act_info.count < 1
        THEN
            NULL;
        ELSE
            FOR i IN l_act_info.first .. l_act_info.last
            LOOP
                -- vidal change
                l_idx := pk_utils.search_table_number(i_table => i_cdripas, i_search => l_act_info(i).id_cdr_event);
            
                <<blk_save_answer>>
                DECLARE
                    l_cdraw         NUMBER(24);
                    l_notes         CLOB;
                    l_dmn_flag      VARCHAR2(0200 CHAR);
                    l_dmn_free_text VARCHAR2(4000 CHAR);
                BEGIN
                
                    IF l_idx > 0
                    THEN
                        IF i_answers(l_idx) = pk_cdr_constant.g_cdraw_cancel
                        THEN
                            -- the user heeded the warning:
                            -- add the element used to directly fire this warning!
                            l_heeded_cdrcp.extend;
                            l_heeded_cdrcp(l_heeded_cdrcp.last) := l_act_info(i).id_cdr_concept;
                            l_heeded_elem.extend;
                            l_heeded_elem(l_heeded_elem.last) := l_act_info(i).id_element;
                        END IF;
                    
                        l_cdraw         := i_answers(l_idx);
                        l_notes         := i_ans_notes(l_idx);
                        l_dmn_flag      := l_domain_value(l_idx);
                        l_dmn_free_text := l_domain_free_text(l_idx);
                    
                    ELSE
                        l_cdraw         := pk_cdr_constant.g_cdraw_no_answer;
                        l_notes         := NULL;
                        l_dmn_flag      := NULL;
                        l_dmn_free_text := NULL;
                    
                    END IF;
                
                    set_answer_int(i_lang             => i_lang,
                                   i_prof             => i_prof,
                                   i_patient          => i_patient,
                                   i_episode          => i_episode,
                                   i_call             => i_call,
                                   i_cdraw            => l_cdraw,
                                   i_notes            => l_notes, --NULL,
                                   i_act_info         => l_act_info(i),
                                   i_domain_value     => l_dmn_flag,
                                   i_domain_free_text => l_dmn_free_text,
                                   o_error            => o_error);
                
                END blk_save_answer;
            
            END LOOP;
        END IF;
    
        -- debug list of heeded rule concepts
        IF g_debug_enable
        THEN
            g_error := 'l_heeded_cdrcp: ' || pk_utils.to_string(i_input => l_heeded_cdrcp);
            g_error := g_error || ', l_heeded_elem: ' || pk_utils.to_string(i_input => l_heeded_elem);
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- get filtered rule concepts
        IF i_concepts IS NULL
           OR i_concepts.count < 1
        THEN
            l_concepts := table_number();
            l_elements := table_varchar();
        ELSIF l_heeded_cdrcp IS NULL
              OR l_heeded_cdrcp.count < 1
        THEN
            l_concepts := i_concepts;
            l_elements := i_elements;
        ELSE
            --Get element id_content
            FOR i IN i_concepts.first .. i_concepts.last
            LOOP
                IF i_concepts(i) = pk_cdr_constant.g_cdrcp_lab_test
                THEN
                    g_error := 'GET ID_CONTENT CONCEPT: ' || i_concepts(i) || ' ELEMENT: ' || i_elements(i);
                    pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                    l_content := pk_lab_tests_external_api_db.get_lab_test_id_content(i_lang     => i_lang,
                                                                                      i_prof     => i_prof,
                                                                                      i_analysis => i_elements(i));
                
                    l_content_elements.extend;
                    l_content_elements(l_content_elements.last) := l_content;
                
                ELSIF i_concepts(i) = pk_cdr_constant.g_cdrcp_lab_test_par
                THEN
                    g_error := 'GET ID_CONTENT CONCEPT: ' || i_concepts(i) || ' ELEMENT: ' || i_elements(i);
                    pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                    l_content := pk_lab_tests_external_api_db.get_lab_test_param_id_content(i_lang,
                                                                                            i_prof               => i_prof,
                                                                                            i_analysis_parameter => i_elements(i));
                
                    l_content_elements.extend;
                    l_content_elements(l_content_elements.last) := l_content;
                
                ELSIF i_concepts(i) = pk_cdr_constant.g_cdrcp_exam
                THEN
                    g_error := 'GET ID_CONTENT CONCEPT: ' || i_concepts(i) || ' ELEMENT: ' || i_elements(i);
                    pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                    l_content := pk_exams_external_api_db.get_exam_id_content(i_lang,
                                                                              i_prof => i_prof,
                                                                              i_exam => i_elements(i));
                
                    l_content_elements.extend;
                    l_content_elements(l_content_elements.last) := l_content;
                ELSE
                    l_content_elements.extend;
                    l_content_elements(l_content_elements.last) := i_elements(i);
                END IF;
            END LOOP;
        
            g_error := 'SELECT l_concepts, l_elements';
            SELECT t.id_cdr_concept, t.id_element
              BULK COLLECT
              INTO l_concepts, l_elements
              FROM (SELECT id_cdr_concept, id_element, id_element_content
                      FROM (SELECT t.column_value id_cdr_concept, rownum rn
                              FROM TABLE(i_concepts) t) cpt,
                           (SELECT t.column_value id_element, rownum rn
                              FROM TABLE(i_elements) t) elm,
                           (SELECT t.column_value id_element_content, rownum rn
                              FROM TABLE(l_content_elements) t) cnt
                     WHERE cpt.rn = elm.rn
                       AND elm.rn = cnt.rn) t
             WHERE NOT EXISTS (SELECT id_element_content
                      FROM (SELECT t.column_value id_cdr_concept, rownum rn
                              FROM TABLE(l_heeded_cdrcp) t) hc,
                           (SELECT t.column_value id_element_content, rownum rn
                              FROM TABLE(l_heeded_elem) t) he
                     WHERE hc.rn = he.rn
                       AND he.id_element_content = t.id_element_content
                       AND hc.id_cdr_concept = t.id_cdr_concept);
        END IF;
    
        o_concepts := l_concepts;
        o_elements := l_elements;
        o_call     := i_call;
    
        -- debug output
        IF g_debug_enable
        THEN
            g_error := 'o_concepts: ' || pk_utils.to_string(i_input => o_concepts);
            g_error := g_error || ', o_elements: ' || pk_utils.to_string(i_input => o_elements);
            g_error := g_error || ', o_call: ' || o_call;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END set_answer;

    /**
    * Set the user's answer to the warnings, using task types.
    * Outputs the list of task types that were chosen to proceed.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_task_types   task type identifiers list (user input)
    * @param i_task_reqs    task request identifiers list (user input)
    * @param i_call         call identifier
    * @param i_cdripas      rule instance parameter action identifiers list
    * @param i_answers      answer identifiers list
    * @param i_ans_notes    answer notes list
    * @param o_task_types   task type identifiers list (filtered)
    * @param o_task_reqs    task request identifiers list (filtered)
    * @param o_call         call identifier
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.2
    * @since                2011/09/06
    */
    FUNCTION set_answer_tt
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_task_types       IN table_number,
        i_task_reqs        IN table_varchar,
        i_call             IN cdr_call.id_cdr_call%TYPE,
        i_cdripas          IN table_number,
        i_answers          IN table_number,
        i_ans_notes        IN table_clob,
        i_domain_value     IN table_varchar DEFAULT table_varchar(),
        i_domain_free_text IN table_varchar DEFAULT table_varchar(),
        o_task_types       OUT table_number,
        o_task_reqs        OUT table_varchar,
        o_call             OUT cdr_call.id_cdr_call%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_ANSWER_TT';
        l_input      t_coll_cdr_in;
        l_task_types table_number; -- filtered task types
        l_task_reqs  table_varchar; -- filtered task requests
        l_heeded_tt  table_number := table_number(); -- heeded task types
        l_heeded_tr  table_varchar := table_varchar(); -- heeded task requests
        l_act_info   t_act_info;
        l_idx        PLS_INTEGER;
        ------
        l_domain_value     table_varchar := table_varchar();
        l_domain_free_text table_varchar := table_varchar();
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        IF i_domain_value.count = 0
        THEN
            l_domain_value.extend(i_answers.count);
        ELSE
            l_domain_value := i_domain_value;
        END IF;
    
        IF i_domain_value.count = 0
        THEN
            l_domain_free_text.extend(i_answers.count);
        ELSE
            l_domain_free_text := i_domain_free_text;
        END IF;
    
        g_error := 'CALL format_input';
        l_input := format_input(i_lang       => i_lang,
                                i_prof       => i_prof,
                                i_concepts   => NULL,
                                i_elements   => NULL,
                                i_task_types => i_task_types,
                                i_task_reqs  => i_task_reqs,
                                i_dose       => NULL,
                                i_dose_um    => NULL,
                                i_route      => NULL,
                                o_error      => o_error);
    
        g_error := 'OPEN c_act_info';
        OPEN c_act_info(i_call => i_call);
        FETCH c_act_info BULK COLLECT
            INTO l_act_info;
        CLOSE c_act_info;
    
        IF l_act_info IS NULL
           OR l_act_info.count < 1
        THEN
            NULL;
        ELSE
            FOR i IN l_act_info.first .. l_act_info.last
            LOOP
                l_idx := pk_utils.search_table_number(i_table => i_cdripas, i_search => l_act_info(i).id_cdr_event);
            
                <<blk_save_answer>>
                DECLARE
                    l_cdraw         NUMBER(24);
                    l_notes         CLOB;
                    l_dmn_flag      VARCHAR2(0200 CHAR);
                    l_dmn_free_text VARCHAR2(4000);
                BEGIN
                
                    IF l_idx > 0
                    THEN
                        IF i_answers(l_idx) = pk_cdr_constant.g_cdraw_cancel
                        THEN
                            -- the user heeded the warning:
                            -- add the element used to directly fire this warning!
                            FOR j IN 1 .. l_input.count
                            LOOP
                                IF l_input(j).id_cdr_concept = l_act_info(i).id_cdr_concept
                                    AND l_input(j).id_element = l_act_info(i).id_element
                                THEN
                                    l_heeded_tt.extend;
                                    l_heeded_tt(l_heeded_tt.last) := l_input(j).id_task_type;
                                    l_heeded_tr.extend;
                                    l_heeded_tr(l_heeded_tr.last) := l_input(j).id_task_req;
                                END IF;
                            END LOOP;
                        END IF;
                    
                        l_cdraw         := i_answers(l_idx);
                        l_notes         := i_ans_notes(l_idx);
                        l_dmn_flag      := l_domain_value(l_idx);
                        l_dmn_free_text := l_domain_free_text(l_idx);
                    
                    ELSE
                        l_cdraw         := pk_cdr_constant.g_cdraw_no_answer;
                        l_notes         := NULL;
                        l_dmn_flag      := NULL;
                        l_dmn_free_text := NULL;
                    
                    END IF;
                
                    set_answer_int(i_lang     => i_lang,
                                   i_prof     => i_prof,
                                   i_patient  => i_patient,
                                   i_episode  => i_episode,
                                   i_call     => i_call,
                                   i_cdraw    => l_cdraw,
                                   i_notes    => l_notes,
                                   i_act_info => l_act_info(i),
                                   o_error    => o_error);
                
                END blk_save_answer;
            
            END LOOP;
        END IF;
    
        -- debug list of heeded task types
        IF g_debug_enable
        THEN
            g_error := 'l_heeded_tt: ' || pk_utils.to_string(i_input => l_heeded_tt);
            g_error := g_error || ', l_heeded_tr: ' || pk_utils.to_string(i_input => l_heeded_tr);
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- get filtered task types
        IF i_task_types IS NULL
           OR i_task_types.count < 1
        THEN
            l_task_types := table_number();
            l_task_reqs  := table_varchar();
        ELSIF l_heeded_tt IS NULL
              OR l_heeded_tt.count < 1
        THEN
            l_task_types := i_task_types;
            l_task_reqs  := i_task_reqs;
        ELSE
            g_error := 'SELECT l_task_types, l_task_reqs';
            SELECT id_task_type, id_task_req
              BULK COLLECT
              INTO l_task_types, l_task_reqs
              FROM (SELECT it.id_task_type, ir.id_task_req
                      FROM (SELECT t.column_value id_task_type, rownum rn
                              FROM TABLE(i_task_types) t) it,
                           (SELECT t.column_value id_task_req, rownum rn
                              FROM TABLE(i_task_reqs) t) ir
                     WHERE it.rn = ir.rn
                    MINUS
                    SELECT tt.id_task_type, tr.id_task_req
                      FROM (SELECT t.column_value id_task_type, rownum rn
                              FROM TABLE(l_heeded_tt) t) tt,
                           (SELECT t.column_value id_task_req, rownum rn
                              FROM TABLE(l_heeded_tr) t) tr
                     WHERE tt.rn = tr.rn);
        END IF;
    
        o_call       := i_call;
        o_task_types := l_task_types;
        o_task_reqs  := l_task_reqs;
    
        -- debug output
        IF g_debug_enable
        THEN
            g_error := 'o_task_types: ' || pk_utils.to_string(i_input => o_task_types);
            g_error := g_error || ', o_task_reqs: ' || pk_utils.to_string(i_input => o_task_reqs);
            g_error := g_error || ', o_call: ' || o_call;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END set_answer_tt;

    /**
    * Set the user's answer to the warnings.
    * Does not interact with user input.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_call         call identifier
    * @param i_cdripas      rule instance parameter action identifiers list
    * @param i_answers      answer identifiers list
    * @param i_ans_notes    answer notes list
    * @param o_call         call identifier
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.3
    * @since                2011/10/07
    */
    FUNCTION set_answer
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_call             IN cdr_call.id_cdr_call%TYPE,
        i_cdripas          IN table_number,
        i_answers          IN table_number,
        i_ans_notes        IN table_clob,
        i_domain_value     IN table_varchar DEFAULT table_varchar(),
        i_domain_free_text IN table_varchar DEFAULT table_varchar(),
        o_call             OUT cdr_call.id_cdr_call%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_concepts table_number;
        l_elements table_varchar;
    BEGIN
        RETURN set_answer(i_lang             => i_lang,
                          i_prof             => i_prof,
                          i_patient          => i_patient,
                          i_episode          => i_episode,
                          i_concepts         => NULL,
                          i_elements         => NULL,
                          i_call             => i_call,
                          i_cdripas          => i_cdripas,
                          i_answers          => i_answers,
                          i_ans_notes        => i_ans_notes,
                          i_domain_value     => i_domain_value,
                          i_domain_free_text => i_domain_free_text,
                          o_concepts         => l_concepts,
                          o_elements         => l_elements,
                          o_call             => o_call,
                          o_error            => o_error);
    END set_answer;

    /**
    * Get warning answers.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param o_actions      actions cursor
    * @param o_answers      answers cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/03/14
    */
    FUNCTION get_warning_answers
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_actions OUT pk_types.cursor_type,
        o_answers OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_api_cdr_in.get_warning_answers(i_lang    => i_lang,
                                                 i_prof    => i_prof,
                                                 o_actions => o_actions,
                                                 o_answers => o_answers,
                                                 o_error   => o_error);
    END get_warning_answers;

    /**
    * Get information on a CDR engine call.
    * The call events are filtered by the input task types.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_call         call identifier
    * @param i_task_types   task type identifiers list
    * @param i_task_reqs    task request identifiers list
    * @param o_icon         cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2011/12/13
    */
    FUNCTION get_call_info
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_call       IN cdr_call.id_cdr_call%TYPE,
        i_task_types IN table_number,
        i_task_reqs  IN table_varchar,
        o_info       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_CALL_INFO';
        l_input t_coll_cdr_in;
        l_na    sys_message.desc_message%TYPE;
    
        --o_id_product          table_varchar;
        --o_id_product_supplier table_varchar;
        l_market market.id_market%TYPE;
    BEGIN
        -- Call the procedure
        l_na := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'CDR_T017');
        -- institution id_market
        l_market := pk_utils.get_institution_market(i_lang => i_lang, i_id_institution => i_prof.institution);
    
        IF i_call IS NOT NULL
        THEN
            g_error := 'CALL format_input';
            l_input := format_input(i_lang       => i_lang,
                                    i_prof       => i_prof,
                                    i_concepts   => NULL,
                                    i_elements   => NULL,
                                    i_task_types => i_task_types,
                                    i_task_reqs  => i_task_reqs,
                                    i_dose       => NULL,
                                    i_dose_um    => NULL,
                                    i_route      => NULL,
                                    o_error      => o_error);
        
            g_error := 'OPEN o_info';
            OPEN o_info FOR
                SELECT t.id_cdr_inst_par_action, -- ALERT-268941 (its decide this way because no flash resources to change) replaced by id cdr event new primary key
                       t.icon_cdr_type,
                       t.color_icon_cdr_type,
                       t.desc_cdr_type,
                       t.desc_cdr_severity,
                       t.desc_cdr_message,
                       t.notes,
                       t.desc_triggered_by
                  FROM (SELECT cdre.id_cdr_event id_cdr_inst_par_action, -- ALERT-268941 (its decide this way because no flash resources to change) replaced by id cdr event new primary key
                               cdrt.icon icon_cdr_type,
                               cdrt.icon_color color_icon_cdr_type,
                               (SELECT pk_translation.get_translation(i_lang, cdrt.code_cdr_type)
                                  FROM dual) desc_cdr_type,
                               (SELECT pk_translation.get_translation(i_lang, cdrs.code_cdr_severity)
                                  FROM dual) || (SELECT get_type_severity_desc(i_lang,
                                                                               i_prof,
                                                                               l_market,
                                                                               cdrd.id_cdr_type,
                                                                               cdri.id_cdr_severity)
                                                   FROM dual) desc_cdr_severity,
                               (SELECT pk_translation.get_translation(i_lang, cdrm.code_cdr_message)
                                  FROM dual) desc_cdr_message,
                               cdre.notes_answer notes,
                               pk_string_utils.clob_to_sqlvarchar2((SELECT get_triggered_by(i_lang,
                                                                                           i_prof,
                                                                                           cdre.id_cdr_call,
                                                                                           cdri.id_cdr_instance)
                                                                     FROM dual)) desc_triggered_by,
                               cdrs.rank rank1,
                               cdrt.rank rank2
                          FROM cdr_event cdre
                          JOIN cdr_inst_par_action cdripa
                            ON cdre.id_cdr_inst_par_action = cdripa.id_cdr_inst_par_action
                          JOIN cdr_inst_param cdrip
                            ON cdripa.id_cdr_inst_param = cdrip.id_cdr_inst_param
                          JOIN cdr_parameter cdrp
                            ON cdrip.id_cdr_parameter = cdrp.id_cdr_parameter
                          JOIN cdr_instance cdri
                            ON cdrip.id_cdr_instance = cdri.id_cdr_instance
                          JOIN cdr_definition cdrd
                            ON cdri.id_cdr_definition = cdrd.id_cdr_definition
                          JOIN cdr_type cdrt
                            ON cdrd.id_cdr_type = cdrt.id_cdr_type
                          JOIN cdr_severity cdrs
                            ON cdri.id_cdr_severity = cdrs.id_cdr_severity
                          LEFT JOIN cdr_message cdrm
                            ON cdripa.id_cdr_message = cdrm.id_cdr_message
                         WHERE cdre.id_cdr_call = i_call
                           AND (cdrp.id_cdr_concept, cdrip.id_element) IN
                               (SELECT t.id_cdr_concept, t.id_element
                                  FROM TABLE(l_input) t)
                        -- ALERT-268941 - For external cases like VIDAL.
                        UNION ALL
                        
                        SELECT cdre.id_cdr_event id_cdr_inst_par_action, -- ALERT-268941 (its decide this way because no flash resources to change) replaced by id cdr event new primary key
                               cdrt.icon icon_cdr_type,
                               cdrt.icon_color color_icon_cdr_type,
                               (SELECT pk_translation.get_translation(i_lang, cdrt.code_cdr_type)
                                  FROM dual) desc_cdr_type,
                               nvl((SELECT pk_translation.get_translation(i_lang, cdrs.code_cdr_severity)
                                     FROM dual),
                                   l_na) || (SELECT get_type_severity_desc(i_lang,
                                                                           i_prof,
                                                                           l_market,
                                                                           cdrex.id_cdr_type,
                                                                           cdrex.id_cdr_severity)
                                               FROM dual) desc_cdr_severity,
                               pk_string_utils.clob_to_plsqlvarchar2(cdrex.comment_desc) desc_cdr_message,
                               cdre.notes_answer notes,
                               pk_string_utils.clob_to_sqlvarchar2((SELECT pk_api_pfh_in.get_product_desc(i_lang                => i_lang,
                                                                                                          i_prof                => i_prof,
                                                                                                          i_id_product          => cdrex.id_product,
                                                                                                          i_id_product_supplier => cdrex.id_product_supplier)
                                                                      FROM dual) || chr(10) ||
                                                                   (SELECT get_triggered_by_external(i_lang,
                                                                                                     i_prof,
                                                                                                     i_call,
                                                                                                     cdrex.id_cdr_external)
                                                                      FROM dual)) desc_triggered_by,
                               cdrs.rank rank1,
                               cdrt.rank rank2
                          FROM cdr_event cdre
                          JOIN cdr_external cdrex
                            ON cdre.id_cdr_external = cdrex.id_cdr_external
                          JOIN cdr_type cdrt
                            ON cdrex.id_cdr_type = cdrt.id_cdr_type
                          LEFT JOIN cdr_severity cdrs
                            ON cdrex.id_cdr_severity = cdrs.id_cdr_severity
                         WHERE cdre.id_cdr_call = i_call
                           AND cdre.id_cdr_external IS NOT NULL -- only external cases
                        ) t
                 ORDER BY t.rank1, t.rank2;
        
        ELSE
            pk_types.open_my_cursor(i_cursor => o_info);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_info);
            RETURN FALSE;
    END get_call_info;

    /**
    * Updates the prescription identifier.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_presc_old    outdated prescription identifier
    * @param i_presc_new    updated prescription identifier
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.2?
    * @since                2011/09/28
    */
    PROCEDURE set_prescription
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_presc_old IN cdr_call_det.id_task_request%TYPE,
        i_presc_new IN cdr_call_det.id_task_request%TYPE,
        o_error     OUT t_error_out
    ) IS
        l_rowids table_varchar;
    BEGIN
        ts_cdr_call_det.upd(id_task_request_in  => i_presc_new,
                            id_task_request_nin => FALSE,
                            where_in            => 'ID_TASK_TYPE = ' || pk_cdr_constant.g_tt_medication ||
                                                   ' AND ID_TASK_REQUEST = ''' || i_presc_old || '''',
                            rows_out            => l_rowids);
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'CDR_CALL_DET',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_TASK_REQUEST'));
    END set_prescription;

    /**
    * check if given task type is being considered in cdr processing
    *
    * @param i_task_type    task type id
    *
    * @return  varchar2     flag that indicates if task type is supported or not within cdr
    *
    * @value   i_filter     {*} 'Y' given task type is supported in cdr
    *                       {*} 'N' given task type is not supported in cdr
    *
    * @author               Carlos Loureiro
    * @since                2011/10/20
    */
    FUNCTION check_cdr_support(i_task_type IN cdr_concept_task_type.id_task_type%TYPE) RETURN VARCHAR2 IS
        l_ret VARCHAR2(1);
    BEGIN
        SELECT pk_alert_constant.g_yes
          INTO l_ret
          FROM dual
         WHERE EXISTS (SELECT 1
                  FROM cdr_concept_task_type tt
                 WHERE tt.id_task_type = i_task_type);
        RETURN l_ret;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN pk_alert_constant.g_no;
    END check_cdr_support;
    /**
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Mario Mineiro
    * @version              2.6.3.8.5
    * @since                11-11-2013
    */
    PROCEDURE check_med_extern
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    ) IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CHECK_MED_EXTERN';
        l_rowids table_varchar;
    
        -- DATE CONVERTION TO SEND
        l_date_convert_pattern VARCHAR2(20 CHAR) := 'YYYY-MM-DD';
    
        -- FOR JSON structure
        i_table_table_ws pk_webservices.table_ws_attr;
    
        -- FOR JSON QUESTION
        l_json_list            json_array_t;
        l_json                 json_object_t;
        l_json_alerts          json_array_t;
        l_json_relatedelements json_array_t;
    
        l_json_drug_obj     json_object_t;
        l_json_alert_obj    json_object_t;
        l_json_rel_elem_obj json_object_t;
    
        l_related_id       VARCHAR2(1000 CHAR);
        l_related_type     VARCHAR2(1000 CHAR);
        l_related_supplier VARCHAR2(1000 CHAR);
    
        l_allergy_related BOOLEAN;
        l_problem_related BOOLEAN;
    
        l_dia_code_icd VARCHAR2(200 CHAR);
        l_json_string  CLOB;
    
        l_tag_patient       VARCHAR2(200 CHAR) := 'PATIENT';
        l_tag_allergies     VARCHAR2(200 CHAR) := 'ALLERGIES';
        l_count_allergies   PLS_INTEGER := 0;
        l_tag_pathologies   VARCHAR2(200 CHAR) := 'PATHOLOGIES';
        l_count_pathologies PLS_INTEGER := 0;
        l_tag_drugs         VARCHAR2(200 CHAR) := 'DRUGS';
        l_count_drugs       PLS_INTEGER := 0;
    
        -- FOR JSON ANWSER
        l_json_type     NUMBER(24);
        l_json_severity NUMBER(24);
        l_json_title    VARCHAR2(2000 CHAR);
        l_json_comment  CLOB;
        l_json_status   VARCHAR2(10 CHAR);
    
        -- Define internal_name of webservice ALERT_CORE_DATA.WS_CONFIG that should be used
        g_cfg_cds_external VARCHAR2(1000 CHAR) := nvl(pk_sysconfig.get_config(i_code_cf => 'CDS_EXTERNAL',
                                                                              i_prof    => i_prof),
                                                      'CDS_EXTERNAL');
    
        -- PATIENT
        function_user_exeception EXCEPTION;
        l_name        patient.name%TYPE;
        l_nick_name   patient.nick_name%TYPE;
        l_gender      patient.gender%TYPE;
        l_desc_gender VARCHAR2(200 CHAR);
        l_dt_birth    VARCHAR2(200 CHAR);
    
        l_dt_init_preg pat_pregnancy.dt_init_pregnancy%TYPE;
        l_weeks        NUMBER;
    
        l_vsd_content vital_sign_desc.id_content%TYPE;
    
        -- Vital signs (height and WEIGHT)
        l_lst_imc              pk_types.cursor_type;
        l_vital_sign_desc      VARCHAR2(1000 CHAR);
        l_id_vital_sign        vital_sign.id_vital_sign%TYPE;
        l_vital_sign_value     VARCHAR2(1000 CHAR);
        l_id_vital_sign_weight vital_sign.id_vital_sign%TYPE := pk_sysconfig.get_config(i_code_cf => 'VITAL_SIGN_WEIGHT',
                                                                                        i_prof    => i_prof);
        l_id_vital_sign_height vital_sign.id_vital_sign%TYPE := pk_sysconfig.get_config(i_code_cf => 'VITAL_SIGN_HEIGHT',
                                                                                        i_prof    => i_prof);
    
        l_dummy_s VARCHAR2(1000 CHAR);
        l_dummy_n NUMBER;
    
        -- ALLERGY
        l_alergy t_coll_cdr_api_out;
        -- Problems/diagnosis
        l_diagnosis t_coll_cdr_api_out;
        -- DRUGS
    
        l_products pk_types.cursor_type;
        l_doses    pk_types.cursor_type;
    
        l_id_presc NUMBER(24);
    
        l_id_product           VARCHAR2(200 CHAR);
        l_id_product_supplier  VARCHAR2(200 CHAR);
        l_id_product_level     VARCHAR2(200 CHAR);
        l_id_product_level_sup VARCHAR2(200 CHAR);
        l_prod_level_desc      VARCHAR2(1000 CHAR);
    
        -- Store all id products finals to send to vidal
        w_count_id_products NUMBER := 0;
        l_id_products       table_varchar := table_varchar();
        -- store all prescs received
        l_id_presc_tt table_number := table_number();
        -- store all products received
        l_id_prod_tt table_varchar := table_varchar();
        -- store all allergies
        w_count_id_allergies NUMBER := 0;
        l_id_allergies       table_varchar := table_varchar();
    
        w_count_id_problems NUMBER := 0;
        l_id_problems       table_varchar := table_varchar();
    
        l_other_diagnosis_count NUMBER := 0;
    
        -- CDRS
        l_cdre_rows ts_cdr_event.cdr_event_tc;
        l_cdre_row  cdr_event%ROWTYPE;
    
        l_id_cdr_external cdr_external.id_cdr_external%TYPE;
    
        l_count_external_rules NUMBER := 0;
    
        l_tt_allergy_area    NUMBER := 0;
        l_tt_problem_area    NUMBER := 0;
        l_tt_medication_area NUMBER := 0;
    
        validate_this_product BOOLEAN := FALSE;
    
        l_count_id_product_warnings NUMBER;
        l_id_product_warnings       table_varchar := table_varchar();
    
        l_count_alert_types NUMBER := 0;
        l_flg_alert_type    table_varchar := table_varchar();
    
        -- DOSES
        l_d_id_product           table_varchar := table_varchar();
        l_d_id_product_supplier  table_varchar := table_varchar();
        l_d_duration             table_varchar := table_varchar();
        l_d_duration_type        table_varchar := table_varchar();
        l_d_frequency_type       table_varchar := table_varchar();
        l_d_id_presc             table_table_number := table_table_number();
        l_d_id_route             table_table_varchar := table_table_varchar();
        l_d_id_route_supplier    table_table_varchar := table_table_varchar();
        l_d_qty                  table_varchar := table_varchar();
        l_d_dose_unit            table_varchar := table_varchar();
        l_d_id_product_level     table_varchar := table_varchar();
        l_d_id_product_level_sup table_varchar := table_varchar();
        l_d_dummy                table_varchar := table_varchar();
    
        l_validate_medication   BOOLEAN := FALSE;
        l_has_presc             BOOLEAN := FALSE;
        l_has_prod              BOOLEAN := FALSE;
        l_arr_presc             table_number := table_number();
        l_count_id_presc        NUMBER := 0;
        l_drugs_interaction     table_varchar := table_varchar();
        l_has_drugs_interaction BOOLEAN := FALSE;
        l_insert_on_table       BOOLEAN := TRUE;
        l_alert_severity        table_number := table_number();
        l_coll_cdr_related      t_coll_cdr_related := t_coll_cdr_related();
        l_cdr_external_det_tc   ts_cdr_external_det.cdr_external_det_tc;
        l_flg_duplicated        VARCHAR2(1 CHAR);
    
    BEGIN
        log_me('CHECK_MED_EXTERN FOR:');
        log_me('>PATIENT: ' || i_patient);
        log_me('>i_episode: ' || i_episode);
        IF g_cdr_input IS NOT NULL
        THEN
        
            FOR i IN g_cdr_input(1).i_concept_task.first .. g_cdr_input(1).i_concept_task.last
            LOOP
            
                -- decide if goes by concepts or task types
                IF g_cdr_input(1).i_type = 'CONCEPTS' -- FALTA GLOBAIS
                THEN
                    g_error := 'Run concepts';
                    log_me('Run concepts count: ' || g_cdr_input(1).i_concept_task.count);
                    log_me('Run elements count: ' || g_cdr_input(1).i_elements.count);
                
                    l_dia_code_icd := NULL;
                    log_me('Verify concept:  ' || g_cdr_input(1).i_concept_task(i));
                
                    IF g_cdr_input(1)
                     .i_concept_task(i) IN --
                        (pk_cdr_constant.g_tt_allergy, pk_cdr_constant.g_tt_problem, pk_cdr_constant.g_tt_medication)
                    THEN
                    
                        IF g_cdr_input(1).i_concept_task(i) = pk_cdr_constant.g_tt_problem
                            AND g_cdr_input(1).i_elements.count = 0
                        THEN
                            NULL; -- if its a simple text problem does nothing
                        ELSE
                            SELECT COUNT(*)
                              INTO l_other_diagnosis_count
                              FROM diagnosis d
                             WHERE d.id_diagnosis = to_number(g_cdr_input(1).i_elements(i))
                               AND d.flg_other = pk_alert_constant.get_no;
                            IF l_other_diagnosis_count = 1
                            THEN
                                l_count_external_rules := l_count_external_rules + 1;
                            END IF;
                        
                        END IF;
                    
                        IF g_cdr_input(1).i_concept_task(i) = pk_cdr_constant.g_tt_allergy --
                        THEN
                            l_tt_allergy_area := l_tt_allergy_area + 1;
                        
                            IF g_cdr_input(1).i_elements(i) IS NOT NULL
                            THEN
                                log_me('ADD CURSOR [ALLERGY]: ' || g_cdr_input(1).i_elements(i));
                                l_id_allergies.extend;
                                w_count_id_allergies := w_count_id_allergies + 1;
                                l_id_allergies(w_count_id_allergies) := g_cdr_input(1).i_elements(i);
                            END IF;
                        
                        END IF;
                    
                        IF g_cdr_input(1).i_concept_task(i) = pk_cdr_constant.g_tt_problem
                        THEN
                            l_tt_problem_area := l_tt_problem_area + 1;
                            IF g_cdr_input(1).i_elements(i) IS NOT NULL
                            THEN
                                log_me('Got problem: ' || g_cdr_input(1).i_elements(i));
                                l_count_pathologies := l_count_pathologies + 1;
                                i_table_table_ws(l_tag_pathologies || '[' || l_count_pathologies || '].ID') := anydata.convertvarchar2(g_cdr_input(1).i_elements(i));
                                -- can only register 1
                            
                                l_id_problems.extend;
                                w_count_id_problems := w_count_id_problems + 1;
                                l_id_problems(w_count_id_problems) := g_cdr_input(1).i_elements(i);
                                BEGIN
                                    SELECT dia.code_icd
                                      INTO l_dia_code_icd
                                      FROM diagnosis dia
                                     WHERE dia.id_diagnosis = to_number(g_cdr_input(1).i_elements(i));
                                
                                EXCEPTION
                                    WHEN OTHERS THEN
                                        NULL;
                                END;
                                i_table_table_ws(l_tag_pathologies || '[' || l_count_pathologies || '].CODE') := anydata.convertvarchar2(l_dia_code_icd);
                            END IF;
                        END IF;
                    
                    END IF;
                
                ELSIF g_cdr_input(1).i_type = 'TASK_TYPES' -- FALTA GLOBAIS
                THEN
                
                    log_me('Run task_types count: ' || g_cdr_input(1).i_concept_task.count);
                    log_me('Run task_reqs count: ' || g_cdr_input(1).i_elements.count);
                    l_dia_code_icd := NULL;
                    log_me('Verify task_type:  ' || g_cdr_input(1).i_concept_task(i));
                
                    IF g_cdr_input(1).i_concept_task(i) = pk_cdr_constant.g_tt_allergy
                    THEN
                        l_tt_allergy_area := l_tt_allergy_area + 1;
                        IF g_cdr_input(1).i_elements.exists(i)
                        THEN
                            -- check if allergy is from medication
                            IF pk_allergy.check_allergy_med_cds(i_lang       => i_lang,
                                                                i_prof       => i_prof,
                                                                i_id_allergy => g_cdr_input(1).i_elements(i)) > 0
                            THEN
                            
                                log_me('ADD CURSOR [ALLERGY]: ' || g_cdr_input(1).i_elements(i));
                                l_id_allergies.extend;
                                w_count_id_allergies := w_count_id_allergies + 1;
                                l_id_allergies(w_count_id_allergies) := g_cdr_input(1).i_elements(i);
                            END IF;
                        END IF;
                    
                    END IF;
                
                    -- medication
                    IF g_cdr_input(1).i_concept_task(i) = pk_cdr_constant.g_tt_medication
                    THEN
                        IF g_cdr_input(1).i_elements.exists(i)
                        THEN
                            l_tt_medication_area := l_tt_medication_area + 1;
                            l_id_presc_tt.extend;
                            l_id_presc_tt(l_id_presc_tt.last) := g_cdr_input(1).i_elements(i);
                        END IF;
                    
                    ELSIF g_cdr_input(1).i_concept_task(i) = pk_cdr_constant.g_tt_medication_by_prod
                    THEN
                        IF g_cdr_input(1).i_elements.exists(i)
                        THEN
                            l_tt_medication_area := l_tt_medication_area + 1;
                            l_id_prod_tt.extend;
                            l_id_prod_tt(l_id_prod_tt.last) := g_cdr_input(1).i_elements(i);
                        END IF;
                    END IF;
                
                    -- lab tests , age , gender, pregnancy, ingredient
                    IF g_cdr_input(1)
                     .i_concept_task(i) IN (pk_cdr_constant.g_tt_allergy,
                                              pk_cdr_constant.g_tt_problem,
                                              pk_cdr_constant.g_tt_medication,
                                              pk_cdr_constant.g_tt_medication_by_prod) --
                    THEN
                        l_count_external_rules := l_count_external_rules + 1;
                    END IF;
                END IF;
            
                -- chamada ao get das configs
                IF NOT get_cdr_task_type_filter(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_id_task_type => g_cdr_input(1).i_id_task_type,
                                                o_flg_filter   => l_flg_alert_type,
                                                o_severity     => l_alert_severity,
                                                o_error        => o_error)
                THEN
                    g_error := 'ERRO PK_CDR_FO_CORE.get_CDR_TASK_TYPE_FILTER';
                    RAISE function_user_exeception;
                END IF;
            
            END LOOP;
        
        END IF;
    
        --ALERT-321701 FOR VALIDATE ALERTS ON MEDICATION DETAILS
        IF g_cdr_input(1).i_id_task_type IN (pk_cdr_constant.g_tt_medication_by_detail)
            OR g_cdr_input(1).i_id_task_type IS NULL
        THEN
            l_tt_medication_area  := l_tt_medication_area + 1;
            l_validate_medication := TRUE;
        END IF;
    
        log_me('[PRESCRIBED_INFO] allergy area ' || l_tt_allergy_area);
        log_me('[PRESCRIBED_INFO] problem area ' || l_tt_problem_area);
        log_me('[PRESCRIBED_INFO] medication area ' || l_tt_medication_area);
        -- if theres any concept or task called that match the requirements we call the external rules
        IF l_count_external_rules > 0
        THEN
        
            g_error := 'ADD ALLERGIES';
            -- Remove allergies id duplicated only on allergy area.
            IF l_id_allergies.count > 0
            THEN
                g_error        := 'MULTI SET DUPLICATE ALLERGIES';
                l_id_allergies := l_id_allergies MULTISET UNION DISTINCT l_id_allergies;
            
                -- add allergies
                FOR i IN l_id_allergies.first .. l_id_allergies.last
                LOOP
                
                    log_me('ADD [ALLERGY]: ' || l_id_allergies(i));
                    l_count_allergies := l_count_allergies + 1;
                    i_table_table_ws(l_tag_allergies || '[' || l_count_allergies || '].ID') := anydata.convertvarchar2(l_id_allergies(i));
                END LOOP;
            END IF;
        
            -- Vidal is based on medication so check that on begin
            g_error             := 'CALL pk_api_pfh_in.get_patient_presc_prods';
            w_count_id_products := 0;
            /************************************************************************************************************************/
            /* GET_PATIENT_PRESC_PRODS */
            /************************************************************************************************************************/
            IF g_cdr_input(1)
             .i_id_task_type IS NULL
                OR (g_cdr_input(1).i_id_task_type IN
                     (pk_cdr_constant.g_tt_medication_by_prod, pk_cdr_constant.g_tt_medication_by_detail))
            THEN
                log_me('GO BY GET_PATIENT_PRESC_PRODS');
            
                IF NOT pk_api_pfh_in.get_patient_presc_prods(i_lang           => i_lang,
                                                             i_prof           => i_prof,
                                                             i_id_patient     => i_patient,
                                                             i_id_presc       => l_id_presc_tt,
                                                             i_id_product_sup => l_id_prod_tt,
                                                             o_products       => l_products,
                                                             o_error          => o_error)
                THEN
                    g_error := 'ERRO pk_api_pfh_in.get_patient_presc_prods';
                    RAISE function_user_exeception;
                END IF;
            
                g_error := 'CALL FETCH l_products';
            
                LOOP
                    FETCH l_products
                        INTO l_id_presc,
                             l_id_product,
                             l_id_product_supplier,
                             l_id_product_level,
                             l_id_product_level_sup,
                             l_prod_level_desc,
                             l_flg_duplicated;
                    EXIT WHEN l_products%NOTFOUND;
                
                    -- Get the current products to a table_number
                    IF l_id_presc_tt.count > 0
                    THEN
                        log_me('[PRESCRIBED_INFO] : Check presc: ' || l_id_presc);
                        IF pk_utils.search_table_number(i_table => l_id_presc_tt, i_search => l_id_presc) > 0
                        THEN
                            l_has_presc := TRUE;
                        ELSE
                            l_has_presc := FALSE;
                        END IF;
                    END IF;
                
                    IF l_validate_medication
                       OR l_has_presc
                    THEN
                        l_id_products.extend;
                        w_count_id_products := w_count_id_products + 1;
                        l_id_products(w_count_id_products) := l_id_product;
                        log_me('[PRESCRIBED_INFO] : add to l_id_products(' || w_count_id_products || ') com: ' ||
                               l_id_product);
                        NULL;
                    
                        l_arr_presc.extend;
                        l_count_id_presc := l_count_id_presc + 1;
                        l_arr_presc(l_count_id_presc) := l_id_presc;
                    END IF;
                
                    -- Get the current products to a table_number
                    IF l_id_prod_tt.count > 0
                    THEN
                        log_me('[PRESCRIBED_INFO] : Check product: ' || l_id_product);
                        IF pk_utils.search_table_varchar(i_table => l_id_prod_tt, i_search => l_id_product) > 0
                        THEN
                            l_has_prod := TRUE;
                        ELSE
                            l_has_prod := FALSE;
                        END IF;
                    END IF;
                
                    IF l_validate_medication
                       OR l_has_prod
                    THEN
                        l_id_products.extend;
                        w_count_id_products := w_count_id_products + 1;
                        l_id_products(w_count_id_products) := l_id_product;
                        log_me('[PRESCRIBED_INFO] : add to l_id_products(' || w_count_id_products || ') com: ' ||
                               l_id_product);
                        NULL;
                    END IF;
                
                    -- Remove all letters from id
                    l_id_product := pk_api_pfh_in.remove_product_level_tag(l_id_product, l_id_product_supplier);
                
                    log_me('===>drugs: ' || l_id_product);
                
                    IF (g_cdr_input(1).i_id_task_type IS NULL)
                       OR (g_cdr_input(1).i_id_task_type = pk_cdr_constant.g_tt_medication_by_prod)
                       OR (g_cdr_input(1).i_id_task_type = pk_cdr_constant.g_tt_medication_by_detail AND
                        l_flg_duplicated = pk_alert_constant.g_yes)
                    THEN
                        l_count_drugs := l_count_drugs + 1;
                    
                        i_table_table_ws(l_tag_drugs || '[' || l_count_drugs || '].ID') := anydata.convertvarchar2(l_id_product);
                        i_table_table_ws(l_tag_drugs || '[' || l_count_drugs || '].TYPE') := anydata.convertvarchar2(l_id_product_supplier);
                        i_table_table_ws(l_tag_drugs || '[' || l_count_drugs || '].ID_PRODUCT_SUPPLIER') := anydata.convertvarchar2(l_id_product_supplier);
                        i_table_table_ws(l_tag_drugs || '[' || l_count_drugs || '].ID_PRODUCT_LEVEL') := anydata.convertvarchar2(l_id_product_level);
                        i_table_table_ws(l_tag_drugs || '[' || l_count_drugs || '].ID_PRODUCT_LEVEL_SUP') := anydata.convertvarchar2(l_id_product_level_sup);
                    END IF;
                END LOOP;
            
            END IF; -- if only products when picking
        
            /************************************************************************************************************************/
            /* GET_PRESC_DOSES_INFO */
            /************************************************************************************************************************/
        
            IF g_cdr_input(1)
             .i_id_task_type IN (pk_cdr_constant.g_tt_medication, pk_cdr_constant.g_tt_medication_by_detail)
            THEN
                log_me('[GET_PRESC_DOSES_INFO] GO BY GET_PRESC_DOSES_INFO');
                -- falta global
                IF g_cdr_input(1).i_id_task_type = pk_cdr_constant.g_tt_medication
                THEN
                    -- EMR-2452 use g_xml in the parameter
                    IF NOT pk_api_pfh_in.get_presc_doses_info(i_lang       => i_lang,
                                                         i_prof       => i_prof,
                                                         i_id_patient => i_patient,
                                                         i_id_presc   => CASE
                                                                             WHEN g_cdr_input(1)
                                                                              .i_id_task_type = pk_cdr_constant.g_tt_medication_by_detail THEN
                                                                              l_arr_presc
                                                                             ELSE
                                                                              l_id_presc_tt
                                                                         END,
                                                         --i_hours_interval => 24,
                                                         i_id_task_type => g_cdr_input(1).i_id_task_type,
                                                         i_tbl_xml      => g_xml,
                                                         o_doses_info   => l_doses,
                                                         o_error        => o_error)
                    
                    THEN
                        g_error := 'ERROR CALLING PK_API_PFH_IN.GET_PRESC_DOSES_INFO WITH:';
                        g_error := g_error || ' i_lang => ' || i_lang;
                        g_error := g_error || ' ,i_prof => profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                                   i_prof.software || ')';
                        g_error := g_error || ' ,i_id_patient => ' || i_patient;
                        g_error := g_error || ' ,i_id_presc => table_number(';
                        log_me('ERROR NA FUNCAO PK_API_PFH_IN.GET_PRESC_DOSES_INFO');
                        log_tn(i_tn => l_id_presc_tt, i_func_name => l_func_name);
                        RAISE function_user_exeception;
                    END IF;
                ELSE
                
                    IF NOT pk_api_pfh_in.get_presc_doses_info(i_lang       => i_lang,
                                                         i_prof       => i_prof,
                                                         i_id_patient => i_patient,
                                                         i_id_presc   => CASE
                                                                             WHEN g_cdr_input(1)
                                                                              .i_id_task_type = pk_cdr_constant.g_tt_medication_by_detail THEN
                                                                              l_arr_presc
                                                                             ELSE
                                                                              l_id_presc_tt
                                                                         END,
                                                         --i_hours_interval => 24,
                                                         i_id_task_type => g_cdr_input(1).i_id_task_type,
                                                         o_doses_info   => l_doses,
                                                         o_error        => o_error)
                    
                    THEN
                        g_error := 'ERROR CALLING PK_API_PFH_IN.GET_PRESC_DOSES_INFO WITH:';
                        g_error := g_error || ' i_lang => ' || i_lang;
                        g_error := g_error || ' ,i_prof => profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                                   i_prof.software || ')';
                        g_error := g_error || ' ,i_id_patient => ' || i_patient;
                        g_error := g_error || ' ,i_id_presc => table_number(';
                        log_me('ERROR NA FUNCAO PK_API_PFH_IN.GET_PRESC_DOSES_INFO');
                        log_tn(i_tn => l_id_presc_tt, i_func_name => l_func_name);
                        RAISE function_user_exeception;
                    END IF;
                END IF;
                log_me('[GET_PRESC_DOSES_INFO] AFTER ');
            
                g_error := 'CALL FETCH l_doses';
                -- w_count_id_products := 0;
                BEGIN
                    LOOP
                        FETCH l_doses BULK COLLECT
                            INTO l_d_id_product,
                                 l_d_id_product_supplier,
                                 l_d_duration,
                                 l_d_duration_type,
                                 l_d_frequency_type,
                                 l_d_id_presc, -- table_number
                                 l_d_id_route,
                                 l_d_id_route_supplier, -- table_varchar
                                 l_d_qty, -- number
                                 l_d_dose_unit,
                                 l_d_id_product_level,
                                 l_d_id_product_level_sup,
                                 l_d_dummy;
                        EXIT WHEN l_doses%NOTFOUND;
                    END LOOP;
                EXCEPTION
                    WHEN OTHERS THEN
                        NULL; -- if cursor dont have stucture...
                END;
            
                FOR i IN 1 .. l_d_id_product.count
                LOOP
                    IF l_d_id_product(i) IS NOT NULL
                    THEN
                    
                        l_count_drugs := l_count_drugs + 1;
                        g_error       := 'GET CURRENT PRODUCTS';
                    
                        -- Get the current products to a table_number
                        log_me('[PRESCRIBED_INFO] : Check presc: ' || l_d_id_presc(i) (1));
                    
                        l_id_products.extend;
                        w_count_id_products := w_count_id_products + 1;
                        l_id_products(w_count_id_products) := l_d_id_product(i);
                        log_me('[PRESCRIBED_INFO] : add to l_id_products(' || w_count_id_products || ') com: ' ||
                               l_d_id_product(i));
                    
                        -- Get the current products to a table_number
                    
                        -- Remove all letters from id
                        l_d_id_product(i) := pk_api_pfh_in.remove_product_level_tag(l_d_id_product(i),
                                                                                    l_d_id_product_supplier(i));
                    
                        log_me('===>drugs: ' || l_d_id_product(1));
                    
                        i_table_table_ws(l_tag_drugs || '[' || l_count_drugs || '].ID') := anydata.convertvarchar2(l_d_id_product(i));
                        i_table_table_ws(l_tag_drugs || '[' || l_count_drugs || '].TYPE') := anydata.convertvarchar2(l_d_id_product_supplier(i));
                        i_table_table_ws(l_tag_drugs || '[' || l_count_drugs || '].ID_PRODUCT_SUPPLIER') := anydata.convertvarchar2(l_d_id_product_supplier(i));
                        i_table_table_ws(l_tag_drugs || '[' || l_count_drugs || '].ID_PRODUCT_LEVEL') := anydata.convertvarchar2(l_d_id_product_level(i));
                        i_table_table_ws(l_tag_drugs || '[' || l_count_drugs || '].ID_PRODUCT_LEVEL_SUP') := anydata.convertvarchar2(l_d_id_product_level_sup(i));
                        i_table_table_ws(l_tag_drugs || '[' || l_count_drugs || '].DOSE') := anydata.convertvarchar2(l_d_qty(i));
                        i_table_table_ws(l_tag_drugs || '[' || l_count_drugs || '].DOSE_UNIT') := anydata.convertvarchar2(to_number(substr(l_d_dose_unit(i),
                                                                                                                                           4)));
                        i_table_table_ws(l_tag_drugs || '[' || l_count_drugs || '].DURATION') := anydata.convertvarchar2(l_d_duration(i));
                        i_table_table_ws(l_tag_drugs || '[' || l_count_drugs || '].DURATION_TYPE') := anydata.convertvarchar2(l_d_duration_type(i));
                        i_table_table_ws(l_tag_drugs || '[' || l_count_drugs || '].FREQUENCY_TYPE') := anydata.convertvarchar2(l_d_frequency_type(i));
                    
                        -- As route tem de ir apenas o ID porque e numerico....
                        FOR r_route IN 1 .. l_d_id_route(i).count
                        LOOP
                            i_table_table_ws(l_tag_drugs || '[' || l_count_drugs || '].ROUTE_LIST[' || r_route || ']') := anydata.convertvarchar2(l_d_id_route(i)
                                                                                                                                                  (r_route));
                        END LOOP;
                    
                    END IF;
                END LOOP;
            
            END IF; -- if  dosagens when picking
        
            -- No drugs by pass this rule
            IF l_count_drugs != 0
            THEN
                g_error := 'CALL  pk_patient.get_pat_info';
                BEGIN
                    SELECT p.name,
                           p.nick_name,
                           p.gender,
                           pk_sysdomain.get_domain('PATIENT.GENDER', p.gender, i_lang) desc_gender,
                           to_char(dt_birth, l_date_convert_pattern)
                      INTO l_name, l_nick_name, l_gender, l_desc_gender, l_dt_birth
                      FROM patient p
                     WHERE p.id_patient = i_patient;
                EXCEPTION
                    WHEN OTHERS THEN
                        RAISE function_user_exeception;
                END;
            
                g_error := 'GET PREGNANCY WEEKS';
                BEGIN
                    SELECT pp.dt_init_pregnancy
                      INTO l_dt_init_preg
                      FROM pat_pregnancy pp
                     WHERE id_patient = i_patient
                       AND flg_status = 'A';
                
                    l_weeks := pk_pregnancy_api.get_pregnancy_weeks(i_prof, l_dt_init_preg, NULL, NULL);
                
                EXCEPTION
                    WHEN OTHERS THEN
                        NULL;
                END;
            
                g_error := 'GET BREASTFEEDING VS';
                -- BREASTFEEDING
                BEGIN
                    SELECT t.id_content
                      INTO l_vsd_content
                      FROM (SELECT vsd.id_content
                              FROM vital_signs_ea v, vital_sign_desc vsd
                             WHERE v.id_vital_sign_desc = vsd.id_vital_sign_desc
                               AND v.id_institution_read = i_prof.institution
                               AND v.id_vital_sign IN (SELECT v.id_vital_sign
                                                         FROM vital_sign v
                                                        WHERE v.id_content = 'TMP33.778')
                               AND v.id_patient = i_patient
                               AND v.flg_state = pk_vital_sign.c_flg_status_active
                             ORDER BY dt_vital_sign_read DESC NULLS LAST) t
                     WHERE rownum = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_vsd_content := NULL;
                END;
            
                i_table_table_ws(l_tag_patient || '.ID') := anydata.convertvarchar2(i_patient);
                i_table_table_ws(l_tag_patient || '.NICK_NAME') := anydata.convertvarchar2(l_nick_name);
                i_table_table_ws(l_tag_patient || '.GENDER') := anydata.convertvarchar2(l_gender);
            
                i_table_table_ws(l_tag_patient || '.DT_BIRTH') := anydata.convertvarchar2(l_dt_birth);
                i_table_table_ws(l_tag_patient || '.WEEKSOFAMENORRHEA') := anydata.convertvarchar2(l_weeks);
                i_table_table_ws(l_tag_patient || '.BREASTFEEDING') := anydata.convertvarchar2(l_vsd_content);
            
                g_error := 'CALL pk_vital_sign.get_vs_value';
                IF NOT pk_vital_sign.get_pat_lst_imc_values(i_lang    => i_lang,
                                                            i_prof    => i_prof,
                                                            i_patient => i_patient,
                                                            o_lst_imc => l_lst_imc,
                                                            o_error   => o_error)
                THEN
                    RAISE function_user_exeception;
                END IF;
            
                g_error := 'FETCH l_lst_imc';
                LOOP
                    FETCH l_lst_imc
                        INTO l_dummy_n, --id_episode
                             l_dummy_n, --id_patient
                             l_dummy_n, --id_visit
                             l_id_vital_sign, --id_vital_sign
                             l_vital_sign_desc, --    vital_sign_desc
                             l_dummy_s, --    unit_measure_desc
                             l_dummy_s, --dt_vital_sign_read_str
                             l_vital_sign_value, --vital_sign_value
                             l_dummy_n, --    id_prof_read
                             l_dummy_s; --intern_name_vital_sign
                    EXIT WHEN l_lst_imc%NOTFOUND;
                    IF l_id_vital_sign = l_id_vital_sign_weight
                    THEN
                        i_table_table_ws(l_tag_patient || '.WEIGHT') := anydata.convertvarchar2(l_vital_sign_value);
                    ELSIF l_id_vital_sign = l_id_vital_sign_height
                    THEN
                        i_table_table_ws(l_tag_patient || '.HEIGHT') := anydata.convertvarchar2(l_vital_sign_value);
                    END IF;
                
                END LOOP;
            
                -- GET PATIENT ALLERGYS
                g_error := 'CALL pk_allergy.get_allergy_sever';
            
                l_alergy := pk_allergy.get_allergy_cds(i_lang => i_lang, i_prof => i_prof, i_patient => i_patient);
            
                g_error := 'RUN ALLERGIES l_alergy ';
            
                FOR i IN 1 .. l_alergy.count
                LOOP
                
                    l_count_allergies := l_count_allergies + 1;
                    i_table_table_ws(l_tag_allergies || '[' || l_count_allergies || '].ID') := anydata.convertvarchar2(l_alergy(i).id_element);
                    l_id_allergies.extend;
                    w_count_id_allergies := w_count_id_allergies + 1;
                    l_id_allergies(w_count_id_allergies) := l_alergy(i).id_element;
                    log_me('ADD CURSOR [ALLERGY]: ' || l_alergy(i).id_element);
                
                END LOOP;
            
                -- GET PATIENT DIAGNOSIS
                g_error     := 'CALL pk_problems.check_diagnosis_in_ehr';
                l_diagnosis := pk_problems.check_diagnosis_in_ehr(i_lang    => i_lang,
                                                                  i_prof    => i_prof,
                                                                  i_patient => i_patient);
            
                g_error := 'Run l_diagnosis.count';
                FOR i IN 1 .. l_diagnosis.count
                LOOP
                    l_count_pathologies := l_count_pathologies + 1;
                    i_table_table_ws(l_tag_pathologies || '[' || l_count_pathologies || '].ID') := anydata.convertvarchar2(l_diagnosis(i).id_element);
                    -- SEND CODE ICD
                    i_table_table_ws(l_tag_pathologies || '[' || l_count_pathologies || '].CODE') := anydata.convertvarchar2(l_diagnosis(i).code_icd);
                
                    l_id_problems.extend;
                    w_count_id_problems := w_count_id_problems + 1;
                    l_id_problems(w_count_id_problems) := l_diagnosis(i).id_element;
                    log_me('ADD [PATHOLOGY]: ' || l_diagnosis(i).id_element || ' code: ' || l_diagnosis(i).code_icd);
                
                END LOOP;
            
                log_me('ALERT_TYPE FLG STARTER');
            
                FOR i IN (SELECT /*+opt_estimate(table t rows=1)*/
                           t.column_value flg
                            FROM TABLE(l_flg_alert_type) t)
                LOOP
                    l_count_alert_types := l_count_alert_types + 1;
                    i_table_table_ws('ALERT_TYPE[' || l_count_alert_types || ']') := anydata.convertvarchar2(i.flg);
                
                    log_me('ADD ALERT_TYPE[' || l_count_alert_types || ']' || i.flg);
                END LOOP;
                -- reset variable
                l_id_product := NULL;
            
                g_error := '=== GOT DRUGS' || l_count_drugs;
            
                -- INSTITUTION / PROFISSIONAL / SOFTWARE
                i_table_table_ws('CONTEXT.ID_INSTITUTION') := anydata.convertvarchar2(i_prof.institution);
                i_table_table_ws('CONTEXT.ID_PROFESSIONAL') := anydata.convertvarchar2(i_prof.id);
                i_table_table_ws('CONTEXT.ID_SOFTWARE') := anydata.convertvarchar2(i_prof.software);
            
                -- LOG JSON SENT
                g_error := 'LOG JSON SENT';
                IF (g_debug_enable)
                THEN
                    pk_alertlog.log_debug(lob_text        => to_clob('JSON SENT: ' ||
                                                                     pk_webservices.to_json(i_table_table_ws)),
                                          object_name     => g_package,
                                          sub_object_name => l_func_name,
                                          owner           => g_owner);
                END IF;
                -- CALL API WEBSERVICE
                g_error := 'CALL pk_webservices.call_ws';
                BEGIN
                    l_json_string := pk_webservices.call_ws(i_ws_int_name    => g_cfg_cds_external,
                                                            i_table_table_ws => i_table_table_ws);
                
                EXCEPTION
                    WHEN OTHERS THEN
                        log_me('======>>> ERRRO API DOWN: ======>>>' || SQLERRM || SQLCODE);
                        g_error := 'ERRO API DOWN pk_webservices.call_ws';
                        g_error := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'CDR_T110') ||
                                   chr(10) || chr(10) || SQLERRM;
                        RAISE g_exception_control;
                END;
                g_error := 'pk_webservices.call_ws PASSED';
                l_json  := json_object_t(l_json_string);
                -- LOG JSON RECEIVED
                g_error := 'LOG JSON RECEIVED';
                IF (g_debug_enable)
                THEN
                    pk_alertlog.log_debug(lob_text        => to_clob('JSON RECEIVED: ' || l_json_string),
                                          object_name     => g_package,
                                          sub_object_name => l_func_name,
                                          owner           => g_owner);
                END IF;
            
                g_error := 'ERRO A TRATAR JASON1';
            
                -- get status
                l_json_status := l_json.get_string('STATUS');
            
                log_me('ERRO A TRATAR JASON2 : ' || l_json_status);
            
                -- error handling
                IF l_json_status != 'OK'
                THEN
                    BEGIN
                        log_me('NOT ' || l_json_status);
                        g_error := l_json.get_string('MESSAGE.CODE');
                        g_error := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => g_error);
                    EXCEPTION
                        WHEN OTHERS THEN
                            NULL;
                    END;
                    IF g_error IS NULL
                    THEN
                        g_error := 'UNEXPECTED ERROR WHEN OBTAINING JSON FROM INTERFACES';
                    END IF;
                    RAISE g_exception_control;
                END IF;
            
                g_error                     := 'ERRO A TRATAR JASON3';
                l_json_list                 := l_json.get_array('CONTENT');
                l_count_id_product_warnings := 0;
            
                -- Get all objects
                FOR i IN 0 .. l_json_list.get_size() - 1
                LOOP
                    validate_this_product   := TRUE;
                    l_has_drugs_interaction := FALSE;
                
                    l_json_drug_obj := json_object_t(l_json_list.get(i)).get_object('DRUG');
                
                    l_id_product          := l_json_drug_obj.get_string('ID');
                    l_id_product_level    := l_json_drug_obj.get_string('PRODUCT_LEVEL');
                    l_id_product_supplier := l_json_drug_obj.get_string('SUPPLIER');
                
                    log_me('=== GET DRUG ID: == ' || l_id_product);
                    log_me('[PRESCRIBED_INFO] GOT l_id_product: ' || l_id_product);
                
                    -- get the product_level_tag to add on product
                    l_id_product := pk_api_pfh_in.get_product_level_tag(l_id_product,
                                                                        l_id_product_level,
                                                                        l_id_product_supplier) || l_id_product;
                
                    log_me('[PRESCRIBED_INFO] validate_this_product = ' || CASE WHEN validate_this_product THEN 'TRUE' WHEN
                           validate_this_product IS NULL THEN 'NULL' ELSE 'FALSE' END || ' for ' || l_id_product);
                
                    IF validate_this_product = TRUE
                    THEN
                        log_me('[PRESCRIBED_INFO] Verify if the alert is for drug prescribed:  ' || l_id_product);
                    
                        l_json_alerts := json_object_t(l_json_list.get(i)).get_array('ALERTS');
                    
                        IF l_json_alerts IS NOT NULL
                        THEN
                            -- CREATE ENGINE CALL
                            IF g_id_cdr_call IS NULL
                            THEN
                                g_error := 'CALL ts_cdr_call.ins';
                                ts_cdr_call.ins(id_prof_call_in       => i_prof.id,
                                                dt_call_in            => g_sysdate_tstz,
                                                id_episode_in         => i_episode,
                                                id_patient_in         => i_patient,
                                                id_cdr_call_parent_in => NULL,
                                                id_cdr_call_out       => g_id_cdr_call,
                                                rows_out              => l_rowids);
                            
                                g_error := 'CALL t_data_gov_mnt.process_insert';
                                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                              i_prof       => i_prof,
                                                              i_table_name => 'CDR_CALL',
                                                              i_rowids     => l_rowids,
                                                              o_error      => o_error);
                            END IF;
                        
                            FOR r IN 0 .. l_json_alerts.get_size() - 1
                            LOOP
                                --Restart the related list
                                l_drugs_interaction := table_varchar();
                                l_coll_cdr_related  := t_coll_cdr_related();
                            
                                l_json_alert_obj := json_object_t(l_json_alerts.get(r));
                            
                                l_json_title    := l_json_alert_obj.get_string('TITLE');
                                l_json_type     := l_json_alert_obj.get_number('TYPE');
                                l_json_comment  := l_json_alert_obj.get_string('COMMENT');
                                l_json_severity := l_json_alert_obj.get_string('SEVERITY');
                            
                                l_problem_related := FALSE;
                                l_allergy_related := FALSE;
                            
                                log_me('[RELATEDELEMENTS-VALIDATE]');
                                BEGIN
                                    l_related_id           := NULL;
                                    l_related_type         := NULL;
                                    l_related_supplier     := NULL;
                                    l_json_relatedelements := json_object_t(l_json_alerts.get(r)).get_array('RELATEDELEMENTS');
                                
                                    log_me('[RELATEDELEMENTS-VALIDATE] count: ' || l_json_relatedelements.get_size());
                                    FOR k IN 0 .. l_json_relatedelements.get_size() - 1
                                    LOOP
                                        l_json_rel_elem_obj := json_object_t(l_json_relatedelements.get(k));
                                    
                                        l_related_id       := l_json_rel_elem_obj.get_string('ID');
                                        l_related_type     := l_json_rel_elem_obj.get_string('TYPE');
                                        l_related_supplier := l_json_rel_elem_obj.get_string('ID_PRODUCT_LEVEL_SUP');
                                    
                                        -- check if related product already check before
                                        -- solve duplicate warnings [a to b] [b to a]
                                        IF l_related_type IN (pk_cdr_constant.g_ced_product, -- 1
                                                              pk_cdr_constant.g_ced_ucd, -- 2
                                                              pk_cdr_constant.g_ced_pk, --3
                                                              pk_cdr_constant.g_ced_cng -- 4
                                                              )
                                        THEN
                                            -- 1,2,3,4
                                            l_related_id := pk_api_pfh_in.get_product_level_tag(l_related_id,
                                                                                                get_map_vidal_types(l_related_type),
                                                                                                l_related_supplier) ||
                                                            l_related_id;
                                        
                                            --verify if the related elements sended by VIDAL
                                            --are related to the products on prescription
                                            IF (pk_utils.search_table_varchar(i_table  => l_id_products,
                                                                              i_search => l_id_product) > 0)
                                               OR (l_related_id IS NOT NULL AND
                                               pk_utils.search_table_varchar(i_table  => l_id_products,
                                                                                 i_search => l_related_id) > 0)
                                            THEN
                                                IF pk_utils.search_table_varchar(i_table  => l_drugs_interaction,
                                                                                 i_search => l_id_product) = -1
                                                THEN
                                                    l_drugs_interaction.extend();
                                                    l_drugs_interaction(l_drugs_interaction.last) := l_id_product;
                                                END IF;
                                            
                                                IF l_related_id IS NOT NULL
                                                THEN
                                                    IF pk_utils.search_table_varchar(i_table  => l_drugs_interaction,
                                                                                     i_search => l_related_id) = -1
                                                    THEN
                                                        l_has_drugs_interaction := TRUE;
                                                    
                                                        l_drugs_interaction.extend();
                                                        l_drugs_interaction(l_drugs_interaction.last) := l_related_id;
                                                    
                                                        l_coll_cdr_related.extend();
                                                        l_coll_cdr_related(l_coll_cdr_related.last) := t_rec_cdr_related(product_id       => l_id_product,
                                                                                                                         related_id       => l_related_id,
                                                                                                                         related_type     => l_related_type,
                                                                                                                         related_supplier => l_related_supplier);
                                                    
                                                    END IF;
                                                END IF;
                                            END IF;
                                        
                                        END IF;
                                    
                                        IF l_related_type = pk_cdr_constant.g_ced_diagnosis
                                        THEN
                                            -- 70
                                            IF pk_utils.search_table_varchar(i_table  => l_id_problems,
                                                                             i_search => l_related_id) > 0
                                            THEN
                                                l_problem_related := TRUE;
                                                log_me('[RELATEDELEMENTS-VALIDATE] GOT TYPE 70: TRUE ');
                                            
                                                l_coll_cdr_related.extend();
                                                l_coll_cdr_related(l_coll_cdr_related.last) := t_rec_cdr_related(product_id       => l_id_product,
                                                                                                                 related_id       => l_related_id,
                                                                                                                 related_type     => l_related_type,
                                                                                                                 related_supplier => l_related_supplier);
                                            END IF;
                                        
                                        ELSIF l_related_type = pk_cdr_constant.g_ced_allergy
                                        THEN
                                            -- 80
                                            IF pk_utils.search_table_varchar(i_table  => l_id_allergies,
                                                                             i_search => l_related_id) > 0
                                            THEN
                                                l_allergy_related := TRUE;
                                                log_me('[RELATEDELEMENTS-VALIDATE] GOT TYPE 80: TRUE');
                                                l_coll_cdr_related.extend();
                                                l_coll_cdr_related(l_coll_cdr_related.last) := t_rec_cdr_related(product_id       => l_id_product,
                                                                                                                 related_id       => l_related_id,
                                                                                                                 related_type     => l_related_type,
                                                                                                                 related_supplier => l_related_supplier);
                                            END IF;
                                        END IF;
                                    
                                    END LOOP; -- end loop RELATEDELEMENTS
                                EXCEPTION
                                    WHEN OTHERS THEN
                                        NULL; -- when theres no relatedelements jason list gives error so do nothing
                                END;
                            
                                IF (l_tt_medication_area > 0 AND validate_this_product = TRUE)
                                   OR (l_tt_allergy_area > 0 AND l_allergy_related = TRUE)
                                   OR (l_tt_problem_area > 0 AND l_problem_related = TRUE)
                                THEN
                                
                                    log_me('THE_CONDITION PASSED');
                                
                                    -- hardcoded by interfaces (this is an error type)
                                    IF l_json_type = 11 -- error type
                                    THEN
                                        l_json_title   := pk_message.get_message(i_lang      => i_lang,
                                                                                 i_prof      => i_prof,
                                                                                 i_code_mess => l_json_title);
                                        l_json_comment := pk_message.get_message(i_lang      => i_lang,
                                                                                 i_prof      => i_prof,
                                                                                 i_code_mess => l_json_comment);
                                    END IF;
                                
                                    l_insert_on_table := TRUE;
                                    IF l_json_type = pk_cdr_constant.g_warn_drug_interaction
                                       OR l_has_drugs_interaction
                                    THEN
                                        IF pk_utils.search_table_varchar(i_table  => l_drugs_interaction,
                                                                         i_search => l_id_product) = -1
                                        THEN
                                            l_insert_on_table := FALSE;
                                        END IF;
                                    ELSE
                                        IF pk_utils.search_table_varchar(i_table  => l_id_products,
                                                                         i_search => l_id_product) = -1
                                        THEN
                                            l_insert_on_table := FALSE;
                                        END IF;
                                    END IF;
                                
                                    --CHECK SEVERITY
                                    IF l_insert_on_table
                                    THEN
                                        IF l_alert_severity.exists(1)
                                        THEN
                                            IF pk_utils.search_table_number(i_table  => l_alert_severity,
                                                                            i_search => l_json_severity) = -1
                                            THEN
                                                l_insert_on_table := FALSE;
                                            END IF;
                                        END IF;
                                    END IF;
                                
                                    IF l_insert_on_table
                                    THEN
                                        -- create event rows
                                        g_error := 'CALL ts_cdr_exernal.ins';
                                        ts_cdr_external.ins(id_cdr_call_in         => g_id_cdr_call,
                                                            id_cdr_type_in         => l_json_type,
                                                            id_cdr_severity_in     => l_json_severity,
                                                            id_product_in          => l_id_product,
                                                            id_product_supplier_in => l_id_product_supplier,
                                                            id_product_level_in    => l_id_product_level,
                                                            title_in               => l_json_title,
                                                            comment_desc_in        => l_json_comment,
                                                            
                                                            rows_out            => l_rowids,
                                                            id_cdr_external_out => l_id_cdr_external);
                                    
                                        l_cdre_row.id_cdr_event := ts_cdr_event.next_key;
                                        l_cdre_row.id_cdr_call  := g_id_cdr_call;
                                    
                                        -- set event
                                        l_cdre_row.id_cdr_inst_par_action := NULL;
                                        l_cdre_row.flg_hidden             := 'N';
                                        l_cdre_row.flg_session            := 'N';
                                    
                                        -- no such event was generated previously: mark unanswered
                                        l_cdre_row.id_prof_answer := NULL;
                                        l_cdre_row.dt_answer := NULL;
                                        l_cdre_row.id_cdr_answer := pk_cdr_constant.g_cdraw_no_answer;
                                        l_cdre_row.notes_answer := NULL;
                                        l_cdre_row.id_cdr_external := l_id_cdr_external;
                                        l_cdre_rows(l_cdre_rows.count + 1) := l_cdre_row;
                                    
                                        g_error := 'CALL t_data_gov_mnt.process_insert ts_cdr_exernal';
                                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                                      i_prof       => i_prof,
                                                                      i_table_name => 'CDR_EXTERNAL',
                                                                      i_rowids     => l_rowids,
                                                                      o_error      => o_error);
                                    
                                        IF l_coll_cdr_related.exists(1)
                                        THEN
                                            IF l_coll_cdr_related.count > 0
                                            THEN
                                                SELECT /*+opt_estimate (table t rows=1)*/
                                                 seq_cdr_external_det.nextval,
                                                 l_id_cdr_external,
                                                 g_id_cdr_call,
                                                 t.related_id,
                                                 t.related_type,
                                                 t.related_supplier,
                                                 NULL,
                                                 NULL,
                                                 NULL,
                                                 NULL,
                                                 NULL,
                                                 NULL
                                                  BULK COLLECT
                                                  INTO l_cdr_external_det_tc
                                                  FROM TABLE(l_coll_cdr_related) t
                                                 WHERE t.product_id = l_id_product;
                                            
                                                ts_cdr_external_det.ins(rows_in => l_cdr_external_det_tc);
                                            
                                            END IF;
                                        END IF;
                                    END IF;
                                END IF; -- validation by area
                            END LOOP; -- end loop ALERTS
                        
                        END IF; -- end if l_json_alerts IS NOT NULL
                    END IF; -- end validate_this_product = true
                END LOOP; -- end 1st looop
            
                log_me('CALL ts_cdr_event.ins' || l_cdre_rows.count);
                -- create event rows
                g_error := 'CALL ts_cdr_event.ins';
                ts_cdr_event.ins(rows_in => l_cdre_rows, rows_out => l_rowids);
                g_error := 'CALL t_data_gov_mnt.process_insert II';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'CDR_EVENT',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
            END IF;
        
        END IF;
    
    EXCEPTION
    
        WHEN function_user_exeception THEN
        
            log_me('erro ' || SQLERRM || SQLCODE || ' ' || g_error);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CHECK_MED_EXTERN',
                                              o_error    => o_error);
            RAISE;
        
        WHEN OTHERS THEN
            log_me('erro: ' || SQLERRM || SQLCODE || ' ' || g_error);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CHECK_MED_EXTERN',
                                              o_error    => o_error);
        
            RAISE;
        
    END check_med_extern;

    /**
    *
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Mario Mineiro
    * @version              2.6.3.8.4
    * @since                11-08-2013
    */
    PROCEDURE check_severity_scores
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    ) IS
    
        l_ret VARCHAR2(1 CHAR);
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CHECK_SEVERITY_SCORES';
    
        l_cdrld  t_rec_cdrld := t_rec_cdrld();
        l_domain BOOLEAN; -- should the validation be made using domain?
        --l_cursor pk_types.cursor_type;
        --l_result vital_sign_read.value%TYPE;
        l_span epis_mtos_param.dt_create%TYPE;
    
        CURSOR c_reg_values
        (
            l_span    epis_mtos_param.dt_create%TYPE,
            l_element cdr_inst_param.id_element%TYPE
        ) IS
        
            SELECT emp.registered_value, mpm.internal_name, vsr.id_vital_sign
              FROM epis_mtos_param emp, mtos_param mpm, vital_sign_read vsr
             WHERE decode(emp.flg_param_task_type,
                          pk_sev_scores_constant.g_flg_param_task_vital_sign,
                          emp.id_task_refid,
                          NULL) IN (SELECT MAX(vsr2.id_vital_sign_read)
                                      FROM vital_sign_read vsr2
                                     WHERE vsr2.id_episode = i_episode
                                     GROUP BY vsr2.id_vital_sign)
               AND emp.id_mtos_param = mpm.id_mtos_param
               AND vsr.id_vital_sign_read = decode(emp.flg_param_task_type,
                                                   pk_sev_scores_constant.g_flg_param_task_vital_sign,
                                                   emp.id_task_refid,
                                                   NULL)
               AND vsr.id_vital_sign = to_number(l_element)
               AND (l_span IS NULL OR (emp.dt_create >= l_span));
    
    BEGIN
    
        -- this condition has only one parameter, whose concept
        IF i_mode = g_mode_concept
        THEN
            -- check condition applicability using concept type
            --ALERT-255254
        
            o_applic := get_cond_applicability(i_input => i_input,
                                               i_param => table_number(pk_cdr_constant.g_cdrcp_rcm_sev_score,
                                                                       pk_cdr_constant.g_cdrcp_war_sev_score));
        ELSIF i_mode = g_mode_instance
        THEN
            -- check condition applicability using instantiated parameters
            o_applic := get_cond_applicability(i_input => i_input, i_inst_par => i_inst_par);
        ELSIF i_mode = g_mode_full
        THEN
        
            -- check if the validation is made using domain
            IF i_inst_par(1).val_list IS NULL
                OR i_inst_par(1).val_list.count < 1
            THEN
                l_domain := TRUE;
            ELSE
                l_domain := FALSE;
            END IF;
        
            -- check condition validity
            IF i_input IS NOT NULL
               AND i_input.count > 0
            THEN
                -- first, start by cross checking the input parameters
                FOR i IN i_input.first .. i_input.last
                LOOP
                    --ALERT-255254
                
                    IF i_input(i)
                     .id_cdr_concept IN (pk_cdr_constant.g_cdrcp_rcm_sev_score, pk_cdr_constant.g_cdrcp_war_sev_score)
                        AND i_input(i).id_element = i_inst_par(1).id_element
                    THEN
                        l_ret := pk_alert_constant.g_yes;
                    
                        -- store call detail row
                        l_cdrld.id_cdr_inst_param := i_inst_par(1).id_cdr_inst_param;
                        l_cdrld.id_cdr_instance   := i_inst_par(1).id_cdr_instance;
                    
                        l_cdrld.param_value := i_inst_par(i).id_element;
                        add_cdrld(i_cdrld => l_cdrld);
                        IF l_domain
                        THEN
                            -- check if element is within domain
                            g_error := 'CALL get_in_domain';
                            l_ret   := get_in_domain(i_result    => i_input(i).dose,
                                                     i_res_um    => -1,
                                                     i_val_min   => i_inst_par(1).val_min,
                                                     i_val_max   => i_inst_par(1).val_max,
                                                     i_domain_um => -1);
                        
                        ELSE
                        
                            l_ret := pk_alert_constant.g_no;
                        
                        END IF;
                    
                        EXIT;
                    END IF;
                
                END LOOP;
            END IF;
        
            --
        
            IF l_ret IS NULL
            THEN
            
                -- check condition validity
                IF i_inst_par(1).validity IS NOT NULL
                THEN
                    -- if validity is set, then calculate the date span
                    l_span := pk_date_utils.add_days_to_tstz(i_timestamp => g_sysdate_tstz,
                                                             i_days      => -to_days(i_span => i_inst_par(1).validity,
                                                                                     i_tmu  => i_inst_par(1).id_validity_umea));
                END IF;
            
                l_ret := pk_alert_constant.g_no;
            
                FOR r IN c_reg_values(l_span, i_inst_par(1).id_element)
                LOOP
                
                    IF l_domain
                    THEN
                    
                        -- check if element is within domain
                        g_error := 'CALL get_in_domain';
                        l_ret   := get_in_domain(i_result    => r.registered_value,
                                                 i_res_um    => -1,
                                                 i_val_min   => i_inst_par(1).val_min,
                                                 i_val_max   => i_inst_par(1).val_max,
                                                 i_domain_um => -1);
                    
                        -- debug input
                        IF g_debug_enable
                           AND l_ret = 'Y'
                           AND r.id_vital_sign IN (5141, 5142)
                        THEN
                            g_error := '[' || l_ret || '.' || to_char(r.id_vital_sign) || ']';
                            g_error := g_error || '->' || r.registered_value;
                            g_error := g_error || ' VAL_MIN: ' || i_inst_par(1).val_min;
                            g_error := g_error || ' VAL_MAX: ' || i_inst_par(1).val_max;
                            g_error := g_error || ' ID_CDR_INST_PARAM: ' || i_inst_par(1).id_cdr_inst_param;
                            g_error := g_error || ' ID_CDR_INSTANCE: ' || i_inst_par(1).id_cdr_instance;
                            g_error := g_error || ' ID_CDR_CONDITION: ' || i_inst_par(1).id_cdr_condition;
                            g_error := g_error || ' ID_CDR_PARAMETER: ' || i_inst_par(1).id_cdr_parameter;
                            g_error := g_error || ' ID_CDR_CONCEPT: ' || i_inst_par(1).id_cdr_concept;
                        
                            pk_alertlog.log_debug(text            => g_error,
                                                  object_name     => g_package,
                                                  sub_object_name => l_func_name);
                        END IF;
                    
                    ELSE
                        -- search element in list
                        IF pk_utils.search_table_varchar(i_table  => i_inst_par(1).val_list,
                                                         i_search => to_char(r.id_vital_sign)) > 0
                        THEN
                            l_ret := pk_alert_constant.g_yes;
                        ELSE
                            l_ret := pk_alert_constant.g_no;
                        END IF;
                    END IF;
                
                END LOOP;
            END IF;
        
            --
        
            l_ret := get_denied(i_result => l_ret, i_deny => i_inst_par(1).flg_deny);
            o_ret := t_coll_cdr_out(t_rec_cdr_out(ret => l_ret, info => NULL, id_user_elem => NULL));
        
        ELSE
            g_error := 'Unrecognized execution mode!';
            RAISE g_fault;
        END IF;
    
    END check_severity_scores;

    /** NO LONGUER USED
    * Verifies if the selected CDR_INSTANCES have products related by hierarchy (duplicated warnings)
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param io_actions     list of enabled actions
    * @param o_error        error
    *
    * @author               Pedro Teixeira
    * @version              2.6.3
    * @since                2013/09/27
    */
    PROCEDURE check_duplicate_prod_inst
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        io_actions IN OUT t_coll_cdre,
        o_error    OUT t_error_out
    ) IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CHECK_DUPLICATE_PROD_INST';
        l_cdr_instance_list table_number := table_number();
    
        l_id_cdr_message    table_number := table_number();
        l_other_elem        table_varchar := table_varchar();
        l_compact_prod_elem table_varchar := table_varchar();
        l_id_cdr_instance   table_varchar := table_varchar();
        l_id_element        table_varchar := table_varchar();
    
        l_id_cdr_inst_to_delete table_number := table_number();
        l_delete_count          NUMBER := 0;
        l_dummy_actions         t_coll_cdre := t_coll_cdre();
        l_idx                   NUMBER;
    
    BEGIN
        -- obtain the cdr_instance of the i_actions
        FOR i IN io_actions.first .. io_actions.last
        LOOP
            IF io_actions(i).id_cdr_instance IS NOT NULL
            THEN
                l_cdr_instance_list.extend;
                l_cdr_instance_list(l_cdr_instance_list.last) := io_actions(i).id_cdr_instance;
            END IF;
        END LOOP;
    
        -- get prod elements grouped by cdr_message
        IF l_cdr_instance_list.count != 0
        THEN
            BEGIN
                SELECT id_cdr_message,
                       other_elem,
                       listagg(prod_elem, ',') within GROUP(ORDER BY id_cdr_instance),
                       MIN(id_cdr_instance) id_cdr_instance
                  BULK COLLECT
                  INTO l_id_cdr_message, l_other_elem, l_compact_prod_elem, l_id_cdr_instance
                  FROM (SELECT cip.id_cdr_instance, cipa.id_cdr_message, cip2.prod_elem, cip2.other_elem
                          FROM cdr_inst_param cip
                          JOIN (SELECT id_cdr_instance,
                                      listagg(prod_elem, ',') within GROUP(ORDER BY id_cdr_concept DESC) prod_elem,
                                      listagg(other_elem, ',') within GROUP(ORDER BY id_cdr_concept DESC) other_elem
                                 FROM (SELECT cip.id_cdr_instance,
                                              decode(cp.id_cdr_concept,
                                                     pk_cdr_constant.g_cdrcp_product,
                                                     cip.id_element,
                                                     NULL) prod_elem,
                                              decode(cp.id_cdr_concept,
                                                     pk_cdr_constant.g_cdrcp_age,
                                                     abs(cip.val_min) || '.' || abs(cip.val_max) || '.' ||
                                                     cip.id_domain_umea,
                                                     pk_cdr_constant.g_cdrcp_product,
                                                     NULL,
                                                     nvl(cip.id_element, cp.id_cdr_concept)) other_elem,
                                              cp.id_cdr_concept
                                         FROM cdr_inst_param cip
                                         JOIN cdr_parameter cp
                                           ON cp.id_cdr_parameter = cip.id_cdr_parameter
                                         JOIN (SELECT column_value id_cdr_instance
                                                FROM TABLE(l_cdr_instance_list) t) cipl
                                           ON cipl.id_cdr_instance = cip.id_cdr_instance)
                                GROUP BY id_cdr_instance) cip2
                            ON cip.id_cdr_instance = cip2.id_cdr_instance
                          JOIN cdr_inst_par_action cipa
                            ON cipa.id_cdr_inst_param = cip.id_cdr_inst_param
                         GROUP BY cip.id_cdr_instance, cipa.id_cdr_message, cip2.prod_elem, cip2.other_elem)
                 WHERE prod_elem IS NOT NULL
                 GROUP BY id_cdr_message, other_elem
                HAVING COUNT(1) > 1;
            
            EXCEPTION
                WHEN OTHERS THEN
                    RETURN;
            END;
        END IF;
    
        -- id_cdr_message, other_elem, compact_prod_elem, id_cdr_instance
        -- determine if product elements are hierarchicaly related
        IF l_id_cdr_message.count != 0
        THEN
            FOR i IN l_id_cdr_message.first .. l_id_cdr_message.last
            LOOP
                l_id_element := pk_string_utils.str_split(i_list => l_compact_prod_elem(i));
            
                -- call medication function to see if products are hierarchical
                IF pk_rt_med_pfh.check_if_prod_hierarchical(i_unique_id => l_id_element) = pk_alert_constant.g_yes
                THEN
                    -- add one record to the list of cdr_instances to delete
                    l_id_cdr_inst_to_delete.extend;
                    l_id_cdr_inst_to_delete(l_id_cdr_inst_to_delete.last) := l_id_cdr_instance(i);
                END IF;
            END LOOP;
        ELSE
            RETURN;
        END IF;
    
        -- delete MIN(id_cdr_instance) of io_actions for related products
        --l_dummy_actions
        IF l_id_cdr_inst_to_delete.count != 0
        THEN
            FOR i IN io_actions.first .. io_actions.last
            LOOP
                FOR j IN l_id_cdr_inst_to_delete.first .. l_id_cdr_inst_to_delete.last
                LOOP
                    IF io_actions(i).id_cdr_instance = l_id_cdr_inst_to_delete(j)
                    THEN
                        io_actions.delete(i);
                        l_delete_count := l_delete_count + 1;
                    END IF;
                END LOOP;
            END LOOP;
        END IF;
    
        -- if recods where deleted then re-index the array
        IF l_delete_count > 0
        THEN
            l_idx := io_actions.first;
            WHILE l_idx IS NOT NULL
            LOOP
                l_dummy_actions.extend;
                l_dummy_actions(l_dummy_actions.last) := io_actions(l_idx);
                l_idx := io_actions.next(l_idx);
            END LOOP;
        
            io_actions := l_dummy_actions;
        ELSE
            NULL;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN;
    END check_duplicate_prod_inst;

    /**
    * Get "Triggered by" field description EXTERNAL.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_call         call identifier
    * @param i_instance     rule instance identifier
    *
    * @return               "triggered by" description
    *
    * @author               Mario Mineiro
    * @version               2.6.3
    * @since                2014/01/14
    */
    FUNCTION get_triggered_by_external
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_call         IN cdr_call.id_cdr_call%TYPE,
        i_cdr_external IN cdr_external.id_cdr_external%TYPE
    ) RETURN CLOB IS
    
        CURSOR c_ced IS
            SELECT ced.*
              FROM cdr_external_det ced
             WHERE ced.id_cdr_external = i_cdr_external;
    
        l_ret CLOB;
    
        l_separator     sys_domain.desc_val%TYPE;
        l_allergy_trans translation.code_translation%TYPE;
    BEGIN
    
        -- its always and so this is fixed here
        l_separator := pk_sysdomain.get_domain(pk_cdr_constant.g_domain_operator, pk_cdr_constant.g_oper_and, i_lang) ||
                       chr(10);
    
        log_me('[TRIGGERED_BY_EXTERNAL] COLLECT ID_CDR_EXTERNAL_DET LOOP: ' || i_cdr_external);
        g_error := 'COLLECT ID_CDR_EXTERNAL_DET';
        FOR i IN c_ced
        LOOP
            log_me('[TRIGGERED_BY_EXTERNAL] GOT TYPE: ' || i.ced_type);
            log_me('[TRIGGERED_BY_EXTERNAL] GOT ID: ' || i.ced_id);
        
            IF i.ced_type IN (pk_cdr_constant.g_ced_product, pk_cdr_constant.g_ced_ucd, pk_cdr_constant.g_ced_pk) -- 1,2,3
            THEN
                -- medication
                l_ret := l_ret || l_separator;
            
                l_ret := l_ret ||
                         pk_api_pfh_in.get_product_desc(i_lang                => i_lang,
                                                        i_prof                => i_prof,
                                                        i_id_product          => i.ced_id,
                                                        i_id_product_supplier => i.id_product_supplier);
            
            ELSIF i.ced_type = pk_cdr_constant.g_ced_age -- 10
            THEN
                -- AGE
                l_ret := l_ret || l_separator;
                l_ret := l_ret || pk_message.get_message(i_lang => i_lang, i_code_mess => 'CDR_T117') || chr(10);
            
            ELSIF i.ced_type = pk_cdr_constant.g_ced_weight -- 20
            THEN
                -- WEIGHT
                l_ret := l_ret || l_separator;
                l_ret := l_ret || pk_message.get_message(i_lang => i_lang, i_code_mess => 'CDR_T118') || chr(10);
            
            ELSIF i.ced_type = pk_cdr_constant.g_ced_pregnant --30
            THEN
                -- PREGNANT
                l_ret := l_ret || l_separator;
                l_ret := l_ret || pk_message.get_message(i_lang => i_lang, i_code_mess => 'CDR_T119') || chr(10);
            
            ELSIF i.ced_type = pk_cdr_constant.g_ced_breast_feeding --40
            THEN
                -- BREAST_FEEDING
                l_ret := l_ret || l_separator;
                l_ret := l_ret || pk_message.get_message(i_lang => i_lang, i_code_mess => 'CDR_T120') || chr(10);
            
            ELSIF i.ced_type = pk_cdr_constant.g_ced_creatin_clearance --50
            THEN
                -- CREATIN_CLEARANCE
            
                l_ret := l_ret || l_separator;
                l_ret := l_ret || pk_message.get_message(i_lang => i_lang, i_code_mess => 'CDR_T121') || chr(10);
            
            ELSIF i.ced_type = pk_cdr_constant.g_ced_gender -- 60
            THEN
                -- GENDER
                l_ret := l_ret || l_separator;
                l_ret := l_ret || pk_message.get_message(i_lang => i_lang, i_code_mess => 'CDR_T122') || chr(10);
            
            ELSIF i.ced_type = pk_cdr_constant.g_ced_diagnosis --70
            THEN
                -- CIM10
                l_ret := l_ret || l_separator;
                l_ret := l_ret || pk_diagnosis.std_diag_desc(i_lang            => i_lang,
                                                             i_prof            => i_prof,
                                                             i_id_diagnosis    => i.ced_id,
                                                             i_code            => NULL,
                                                             i_flg_other       => pk_alert_constant.g_no,
                                                             i_flg_std_diag    => pk_alert_constant.g_yes,
                                                             i_flg_search_mode => pk_alert_constant.g_yes) || chr(10);
            ELSIF i.ced_type = pk_cdr_constant.g_ced_allergy --80
            THEN
                -- ALLERGY
                BEGIN
                    SELECT pk_translation.get_translation(i_lang, a.code_allergy)
                      INTO l_allergy_trans
                      FROM allergy a
                     WHERE a.id_allergy = i.ced_id;
                
                    l_ret := l_ret || l_separator;
                    l_ret := l_ret || l_allergy_trans || chr(10);
                
                EXCEPTION
                    WHEN OTHERS THEN
                        log_me('[TRIGGERED_BY_EXTERNAL] ALLERGY ERROR ID: ' || i.ced_id);
                END;
            END IF;
            ---_ret := chr(10) || chr(10) || chr(10) || l_ret || ' TESTE FIM ' || i_cdr_external;
        END LOOP;
    
        RETURN l_ret;
    
    END get_triggered_by_external;

    FUNCTION get_cdr_doc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_cdr_doc_instance IN cdr_doc.id_cdr_doc_instance%TYPE,
        o_title               OUT VARCHAR2,
        o_info                OUT CLOB,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_CDR_CONTEXT_INFO';
    
        -- get doc info
        CURSOR c_cdr_doc IS
            SELECT cdoc.code_name, cdit.code_title
              FROM cdr_doc cdoc
              JOIN cdr_doc_item_type cdit
                ON cdoc.id_cdr_doc_item_type = cdit.id_cdr_doc_item_type
             WHERE cdoc.id_cdr_doc_instance = i_id_cdr_doc_instance
               AND cdoc.flg_available = pk_alert_constant.g_yes
             ORDER BY cdoc.rank;
    
    BEGIN
    
        -- get title
        SELECT nvl(pk_translation.get_translation(i_lang, cdoct.code_title),
                   pk_translation.get_translation(i_lang, cdoct.code_name))
          INTO o_title
          FROM cdr_doc_type cdoct
         WHERE cdoct.id_cdr_doc_type IN
               (SELECT MAX(id_cdr_doc_type)
                  FROM cdr_doc cdoc
                 WHERE cdoc.id_cdr_doc_instance = i_id_cdr_doc_instance);
    
        FOR c_doc IN c_cdr_doc
        LOOP
            o_info := o_info || '<b>' ||
                      pk_translation.get_translation(i_lang => i_lang, i_code_mess => c_doc.code_title) || '</b>' ||
                      chr(10);
            o_info := o_info || pk_translation_lob.get_translation(i_lang => i_lang, i_code_mess => c_doc.code_name) ||
                      chr(10) || chr(10);
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_cdr_doc;

    FUNCTION get_cdr_task_type_filter
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_task_type IN task_type.id_task_type%TYPE,
        o_flg_filter   OUT table_varchar,
        o_severity     OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_CDR_TASK_TYPE_FILTER';
        l_market market.id_market%TYPE := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
    BEGIN
        -- FIELD_01 = ID_TASK_TYPE
        -- FIELD_02 = FLAGS CONFIGURED
        -- FIELD_03 = ID_MARKET
        o_flg_filter := table_varchar();
        o_severity   := table_number();
    
        log_me('[GET_CDR_TASK_TYPE_FILTER] FOR TASK_TYPE: ' || i_id_task_type);
        SELECT t.field_02
          BULK COLLECT
          INTO o_flg_filter
          FROM TABLE(pk_core_config.get_values_by_mkt_inst_sw(i_lang => i_lang,
                                                              i_prof => i_prof,
                                                              i_area => pk_cdr_constant.g_task_type_filter)) t
         WHERE t.field_01 = i_id_task_type
           AND t.field_03 = l_market
         ORDER BY id_record;
    
        -- FIELD_01 = ID_TASK_TYPE
        -- FIELD_02 = FLAGS CONFIGURED
        -- FIELD_03 = MARKET
        log_me('[GET_CDR_TASK_TYPE_SEVERITY] FOR TASK_TYPE: ' || i_id_task_type);
        SELECT t.field_02
          BULK COLLECT
          INTO o_severity
          FROM TABLE(pk_core_config.get_values_by_mkt_inst_sw(i_lang => i_lang,
                                                              i_prof => i_prof,
                                                              i_area => pk_cdr_constant.g_task_type_severity)) t
         WHERE t.field_01 = i_id_task_type
           AND t.field_03 = l_market;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_cdr_task_type_filter;

    /********************************************************************************************
    * Gets a a description for a given cdr type and cdr severity
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_market         institution market
    * @param i_cdr_type       type of cdr
    * @param i_cdr_severity   type of severity
    *
    * @return                 translation code
    *
    * @author                 Elisabete Bugalho
    * @version                2.6.5
    * @since                  2015/03/11
    **********************************************************************************************/

    FUNCTION get_type_severity_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_market       IN market.id_market%TYPE,
        i_cdr_type     IN cdr_type.id_cdr_type%TYPE,
        i_cdr_severity IN cdr_severity.id_cdr_severity%TYPE
    ) RETURN VARCHAR2 IS
        l_severity_desc VARCHAR2(2000 CHAR);
    BEGIN
    
        SELECT pk_translation.get_translation(i_lang, code_cdr_type_sev_desc)
          INTO l_severity_desc
          FROM (SELECT code_cdr_type_sev_desc, row_number() over(ORDER BY ctsdm.id_market DESC) line_number --
                  FROM cdr_type_severity_desc ctsd
                  JOIN cdr_type_sev_desc_mkt ctsdm
                    ON ctsd.id_cdr_type_sev_desc = ctsdm.id_cdr_type_sev_desc
                 WHERE ctsd.id_cdr_type = i_cdr_type
                   AND ctsd.id_cdr_severity = i_cdr_severity
                   AND ctsdm.id_market IN (i_market, 0)
                   AND ctsd.flg_available = pk_alert_constant.g_yes
                   AND ctsdm.flg_available = pk_alert_constant.g_yes)
         WHERE line_number = 1;
        IF l_severity_desc IS NOT NULL
        THEN
            RETURN ' : ' || l_severity_desc;
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_type_severity_desc;

    /**
    * Condition procedure: check ges
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Carlos El Ferreira
    * @version               2.6.5.0
    * @since                2015 e pozinhos...
    */
    PROCEDURE check_ges
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    ) IS
        --k_func_name CONSTANT VARCHAR2(30 CHAR) := 'CHECK_GES';
        l_ret VARCHAR2(1 CHAR);
        --l_cdrld t_rec_cdrld := t_rec_cdrld();
        k_ges_concept CONSTANT NUMBER(24) := 32;
        l_id NUMBER(24);
    BEGIN
        -- this condition has only one parameter, whose concept is gender
        IF i_mode = g_mode_concept
        THEN
            -- check condition applicability using concept type
            o_applic := get_cond_applicability(i_input => i_input,
                                               i_param => table_number(pk_cdr_constant.g_cdrcp_diagnosis, k_ges_concept));
        
        ELSIF i_mode = g_mode_instance
        THEN
            -- check condition applicability using instantiated parameters
            o_applic := get_cond_applicability(i_input => i_input, i_inst_par => i_inst_par);
        ELSIF i_mode = g_mode_full
        THEN
        
            IF i_inst_par(1).id_element IS NOT NULL
            THEN
                l_id := get_id_isencao(i_id_content => i_inst_par(1).id_element);
                IF pk_adt.check_exemption_availability(l_id)
                THEN
                
                    l_ret := pk_alert_constant.g_yes;
                    IF pk_adt.get_pat_exemption(i_lang       => i_lang,
                                                i_prof       => i_prof,
                                                i_id_patient => i_patient,
                                                i_id_isencao => l_id,
                                                o_error      => o_error)
                    THEN
                        -- condition is not considered valid when no values are listed
                        l_ret := pk_alert_constant.g_no;
                    END IF;
                ELSE
                    l_ret := pk_alert_constant.g_no;
                END IF;
            
            END IF;
        
            l_ret := get_denied(i_result => l_ret, i_deny => i_inst_par(1).flg_deny);
            o_ret := t_coll_cdr_out(t_rec_cdr_out(ret => l_ret, info => NULL, id_user_elem => NULL));
        ELSE
            g_error := 'Unrecognized execution mode!';
            RAISE g_fault;
        END IF;
    END check_ges;

    --***********************************************************************************************
    --***********************************************************************************************
    PROCEDURE get_popup_sections
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_call         IN cdr_call.id_cdr_call%TYPE,
        i_use_input    IN VARCHAR2,
        i_id_task_type IN task_type.id_task_type%TYPE DEFAULT NULL,
        o_sect1        OUT pk_types.cursor_type,
        o_sect2        OUT pk_types.cursor_type,
        o_sect3        OUT pk_types.cursor_type,
        o_sect4        OUT pk_types.cursor_type
    ) IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_POPUP_SECTIONS';
        l_use_input VARCHAR2(1 CHAR);
        l_na        sys_message.desc_message%TYPE;
        l_warn_data t_coll_cdr_warning;
        l_market    market.id_market%TYPE;
        k_concept_vs constant number := 31;
    
        CURSOR c_warn_data IS
            SELECT t_rec_cdr_warning(section_1_id            => wd.section_1_id,
                                     desc_concept            => wd.desc_concept,
                                     --                                     section_2_id            => wd.section_2_id,
                                     section_2_id => decode(wd.id_cdr_concept, k_concept_vs, 0, wd.section_2_id_base),
                                     --desc_element            => wd.desc_element,
                                     desc_element     => decode(wd.id_cdr_concept,
                                                                k_concept_vs,
                                                                wd.desc_concept,
                                                                wd.desc_element),
                                     icon_cdr_concept        => wd.icon_cdr_concept,
                                     --                                     section_3_id            => wd.section_3_id,
                                     section_3_id        => decode(wd.id_cdr_concept, k_concept_vs, 0, wd.section_3_id),
                                     id_cdr_action           => wd.id_cdr_action,
                                     id_cdr_answer           => wd.id_cdr_answer,
                                     notes_answer            => wd.notes_answer,
                                     flg_req_notes           => wd.flg_req_notes,
                                     show_line_flg           => decode(lead(wd.section_1_id, 1, 0) over(ORDER BY wd.rank),
                                                                       wd.section_1_id,
                                                                       pk_alert_constant.g_no,
                                                                       pk_alert_constant.g_yes),
                                     id_cdr_event            => wd.id_cdr_event,
                                     type_desc               => wd.type_desc,
                                     type_icon               => wd.type_icon,
                                     type_icon_color         => wd.type_icon_color,
                                     type_message            => wd.type_message,
                                     severity_desc           => wd.severity_desc,
                                     severity_color          => wd.severity_color,
                                     severity_text_style     => wd.severity_text_style,
                                     triggered_by_desc       => wd.triggered_by_desc,
                                     triggered_by_color      => wd.triggered_by_color,
                                     id_links                => wd.id_links,
                                     id_cdr_definition       => wd.id_cdr_definition,
                                     id_cdr_doc_instance     => wd.id_cdr_doc_instance,
                                     
                                     section_4_last_item_flg => decode(lead(wd.section_3_id, 1, 0) over(ORDER BY wd.rank),
                                                                       wd.section_3_id,
                                                                       pk_alert_constant.g_no,
                                                                       pk_alert_constant.g_yes),
                                     rank                    => wd.rank)
            
              FROM (SELECT w1.desc_concept,
                           w1.desc_element,
                           w1.icon_cdr_concept,
                           w1.id_cdr_action,
                           w1.id_cdr_answer,
                           w1.notes_answer,
                           w1.id_cdr_event,
                           w1.type_desc,
                           w1.type_icon,
                           w1.type_icon_color,
                           w1.type_message,
                           w1.severity_desc,
                           w1.severity_color,
                           w1.severity_text_style,
                           w1.triggered_by_desc,
                           w1.triggered_by_color,
                           w1.id_links,
                           w1.id_cdr_definition,
                           w1.id_cdr_doc_instance,
                           w1.id_cdr_concept,
                           dense_rank() over(ORDER BY w1.desc_concept) section_1_id,
                           dense_rank() over(ORDER BY w1.desc_concept, w1.desc_element) section_2_id_BASE,
                           dense_rank() over(ORDER BY w1.desc_concept, w1.desc_element, w1.action_rank) section_3_id,
                           MAX(w1.flg_req_notes) over(PARTITION BY w1.desc_concept, w1.desc_element, w1.action_rank) flg_req_notes,
                           decode(i_id_task_type,
                                  pk_cdr_constant.g_tt_medication_by_detail,
                                  row_number() over(ORDER BY w1.sever_rank,
                                       nvl(w1.type_mkt_rank, w1.type_rank),
                                       w1.desc_concept,
                                       w1.desc_element),
                                  row_number() over(ORDER BY w1.desc_concept,
                                       w1.desc_element,
                                       w1.action_rank,
                                       w1.sever_rank,
                                       w1.type_rank)) rank
                      FROM (SELECT pk_translation.get_translation(i_lang, nvl(tt.code_task_type, cdrcp.code_cdr_concept)) desc_concept,
                                   decode(l_use_input,
                                          pk_alert_constant.g_yes,
                                          get_elem_translation(i_lang,
                                                               i_prof,
                                                               cdrcp.id_cdr_concept,
                                                               cdrip.id_element,
                                                               cdrld.id_task_request),
                                          pk_translation.get_translation(i_lang, cdri.code_description)) desc_element,
                                   cdrcp.icon icon_cdr_concept,
                                   cdripa.id_cdr_action,
                                   decode(cdre.id_cdr_answer, pk_cdr_constant.g_cdraw_no_answer, NULL, cdre.id_cdr_answer) id_cdr_answer,
                                   cdre.notes_answer notes_answer,
                                   decode(cdripa.id_cdr_action,
                                          pk_cdr_constant.g_cdra_override,
                                          get_notes_mandatory(pk_cdr_constant.g_cdraw_cancel,
                                                              cdri.id_cdr_severity,
                                                              i_prof.institution),
                                          pk_alert_constant.g_no) flg_req_notes,
                                   --  cdripa.id_cdr_inst_par_action,  -- ALERT-268941 (its decide this way because no flash resources to change) replaced by id cdr event new primary key
                                   cdre.id_cdr_event,
                                   pk_translation.get_translation(i_lang, cdrt.code_cdr_type) type_desc,
                                   cdrt.icon type_icon,
                                   cdrt.icon_color type_icon_color,
                                   pk_translation.get_translation(i_lang, cdrm.code_cdr_message) type_message,
                                   nvl(pk_translation.get_translation(i_lang, cdrs.code_cdr_severity), l_na) ||
                                   get_type_severity_desc(i_lang,
                                                          i_prof,
                                                          l_market,
                                                          cdrd.id_cdr_type,
                                                          cdri.id_cdr_severity) severity_desc,
                                   cdrs.color severity_color,
                                   cdrs.flg_text_style severity_text_style,
                                   get_triggered_by(i_lang, i_prof, i_call, cdri.id_cdr_instance) triggered_by_desc,
                                   cdrip.triggered_by_color,
                                   cdra.rank action_rank,
                                   cdrs.rank sever_rank,
                                   cdrt.rank type_rank,
                                   NULL type_mkt_rank,
                                   cdrd.id_links id_links,
                                   cdrd.id_cdr_definition,
                                   cdripa.id_cdr_doc_instance,
                                   -- cmf
                                   cdrcp.id_cdr_concept
                              FROM cdr_event cdre
                              JOIN cdr_inst_par_action cdripa
                                ON cdre.id_cdr_inst_par_action = cdripa.id_cdr_inst_par_action
                              LEFT JOIN cdr_message cdrm
                                ON cdripa.id_cdr_message = cdrm.id_cdr_message
                              JOIN cdr_inst_param cdrip
                                ON cdripa.id_cdr_inst_param = cdrip.id_cdr_inst_param
                              JOIN cdr_parameter cdrp
                                ON cdrip.id_cdr_parameter = cdrp.id_cdr_parameter
                              JOIN cdr_concept cdrcp
                                ON cdrp.id_cdr_concept = cdrcp.id_cdr_concept
                              JOIN cdr_instance cdri
                                ON cdrip.id_cdr_instance = cdri.id_cdr_instance
                              JOIN cdr_definition cdrd
                                ON cdri.id_cdr_definition = cdrd.id_cdr_definition
                              JOIN cdr_type cdrt
                                ON cdrd.id_cdr_type = cdrt.id_cdr_type
                              LEFT JOIN cdr_severity cdrs
                                ON cdri.id_cdr_severity = cdrs.id_cdr_severity
                              LEFT JOIN cdr_call_det cdrld
                                ON cdre.id_cdr_call = cdrld.id_cdr_call
                               AND cdrip.id_cdr_inst_param = cdrld.id_cdr_inst_param
                              LEFT JOIN task_type tt
                                ON cdrld.id_task_type = tt.id_task_type
                              JOIN cdr_action cdra
                                ON cdripa.id_cdr_action = cdra.id_cdr_action
                             WHERE cdre.id_cdr_call = i_call
                               AND cdra.flg_warning = pk_alert_constant.g_yes
                               AND cdre.id_cdr_external IS NULL -- for only internal cases
                               AND cdrcp.id_cdr_concept != k_concept_isencao
                               AND cdripa.id_cdr_action != k_action_isencao
                            -- ALERT-268941 - For external cases like VIDAL.
                            UNION ALL
                            SELECT pk_translation.get_translation(i_lang, cc.code_cdr_concept) desc_concept,
                                   decode('Y',
                                          'Y',
                                          pk_cdr_fo_core.get_elem_translation(i_lang,
                                                                              i_prof,
                                                                              --                             cdrcp.id_cdr_concept,
                                                                              cc.id_cdr_concept,
                                                                              --                             cdrip.id_element,
                                                                              cip2.id_element,
                                                                              NULL),
                                          pk_translation.get_translation(i_lang, cdri.code_description)) desc_element,
                                   --                             cdrip.id_element,
                                   -- cdrcp.icon icon_cdr_concept,
                                   cc.icon icon_cdr_concept,
                                   cdripa.id_cdr_action,
                                   decode(cdre.id_cdr_answer, -1, NULL, cdre.id_cdr_answer) id_cdr_answer,
                                   cdre.notes_answer notes_answer,
                                   decode(cdripa.id_cdr_action,
                                          1,
                                          pk_cdr_fo_core.get_notes_mandatory(pk_cdr_constant.g_cdraw_cancel,
                                                                             cdri.id_cdr_severity,
                                                                             i_prof.institution),
                                          'N') flg_req_notes,
                                   --  cdripa.id_cdr_inst_par_action,  -- ALERT-268941 (its decide this way because no flash resources to change) replaced by id cdr event new primary key
                                   cdre.id_cdr_event,
                                   pk_translation.get_translation(i_lang, cdrt.code_cdr_type) type_desc,
                                   cdrt.icon type_icon,
                                   cdrt.icon_color type_icon_color,
                                   pk_translation.get_translation(i_lang, cdrm.code_cdr_message) type_message,
                                   nvl(pk_translation.get_translation(i_lang, cdrs.code_cdr_severity), 'N.A') ||
                                   pk_cdr_fo_core.get_type_severity_desc(i_lang,
                                                                         i_prof,
                                                                         l_market,
                                                                         cdrd.id_cdr_type,
                                                                         cdri.id_cdr_severity) severity_desc,
                                   cdrs.color severity_color,
                                   cdrs.flg_text_style severity_text_style,
                                   pk_cdr_fo_core.get_triggered_by(i_lang, i_prof, i_call, cdri.id_cdr_instance) triggered_by_desc,
                                   cdrip.triggered_by_color,
                                   cdra.rank action_rank,
                                   cdrs.rank sever_rank,
                                   cdrt.rank type_rank,
                                   NULL type_mkt_rank,
                                   cdrd.id_links id_links,
                                   cdrd.id_cdr_definition,
                                   cdripa.id_cdr_doc_instance
                                   -- cmf
                                  ,
                                   cc.id_cdr_concept
                              FROM cdr_event cdre
                              JOIN cdr_inst_par_action cdripa
                                ON cdre.id_cdr_inst_par_action = cdripa.id_cdr_inst_par_action
                              JOIN cdr_inst_param cdrip
                                ON cdripa.id_cdr_inst_param = cdrip.id_cdr_inst_param
                              JOIN cdr_inst_param cip2
                                ON cip2.id_cdr_instance = cdrip.id_cdr_instance
                              JOIN cdr_parameter cdrp
                                ON cdrip.id_cdr_parameter = cdrp.id_cdr_parameter
                              JOIN cdr_parameter cp2
                                ON cp2.id_cdr_parameter = cip2.id_cdr_parameter
                            --  JOIN cdr_concept cdrcp            ON cdrp.id_cdr_concept = cdrcp.id_cdr_concept
                              JOIN cdr_concept cc
                                ON cc.id_cdr_concept = cp2.id_cdr_concept
                              JOIN cdr_instance cdri
                                ON cdrip.id_cdr_instance = cdri.id_cdr_instance
                              JOIN cdr_definition cdrd
                                ON cdri.id_cdr_definition = cdrd.id_cdr_definition
                              JOIN cdr_type cdrt
                                ON cdrd.id_cdr_type = cdrt.id_cdr_type
                              LEFT JOIN cdr_message cdrm
                                ON cdripa.id_cdr_message = cdrm.id_cdr_message
                              LEFT JOIN cdr_severity cdrs
                                ON cdri.id_cdr_severity = cdrs.id_cdr_severity
                              LEFT JOIN cdr_call_det cdrld
                                ON cdre.id_cdr_call = cdrld.id_cdr_call
                               AND cdrip.id_cdr_inst_param = cdrld.id_cdr_inst_param
                              JOIN cdr_action cdra
                                ON cdripa.id_cdr_action = cdra.id_cdr_action
                             WHERE cdre.id_cdr_call = i_call
                               AND cdra.flg_warning = k_yes
                               AND cp2.id_cdr_concept = k_concept_isencao --k_id_cdr_concept_ges
                               AND cdripa.id_cdr_action = k_action_isencao
                               AND cdre.id_cdr_external IS NULL -- for only internal cases
                            UNION ALL
                            SELECT NULL desc_concept,
                                   --  nvl(cdrex.title, cdrex.comment_desc) desc_element,
                                   cdrex.title desc_element,
                                   'TherapeuticIcon' icon_cdr_concept,
                                   decode(i_id_task_type,
                                          pk_cdr_constant.g_tt_medication_by_detail,
                                          pk_cdr_constant.g_cdra_no_action,
                                          pk_cdr_constant.g_cdra_external) id_cdr_action,
                                   '-1' id_cdr_answer,
                                   cdre.notes_answer notes_answer,
                                   decode(i_id_task_type,
                                          pk_cdr_constant.g_tt_medication_by_detail,
                                          pk_alert_constant.g_no,
                                          pk_alert_constant.g_yes) flg_req_notes,
                                   cdre.id_cdr_event, -- ALERT-268941 (its decide this way because no flash resources to change) replaced by id cdr event new primary key
                                   pk_translation.get_translation(i_lang, cdrt.code_cdr_type) type_desc,
                                   cdrt.icon type_icon,
                                   cdrt.icon_color type_icon_color,
                                   pk_string_utils.clob_to_plsqlvarchar2(cdrex.comment_desc) type_message,
                                   nvl(pk_translation.get_translation(i_lang, cdrs.code_cdr_severity), l_na) ||
                                   get_type_severity_desc(i_lang,
                                                          i_prof,
                                                          l_market,
                                                          cdrex.id_cdr_type,
                                                          cdrex.id_cdr_severity) severity_desc,
                                   cdrs.color severity_color,
                                   cdrs.flg_text_style severity_text_style,
                                   pk_api_pfh_in.get_product_desc(i_lang                => i_lang,
                                                                  i_prof                => i_prof,
                                                                  i_id_product          => cdrex.id_product,
                                                                  i_id_product_supplier => cdrex.id_product_supplier) ||
                                   chr(10) || get_triggered_by_external(i_lang, i_prof, i_call, cdrex.id_cdr_external) triggered_by_desc,
                                   NULL triggered_by_color,
                                   1 action_rank,
                                   cdrs.rank sever_rank,
                                   cdrt.rank type_rank,
                                   cdrtm.rank type_mkt_rank,
                                   NULL id_links,
                                   NULL id_cdr_definition,
                                   NULL id_cdr_doc_instance,
                                   NULL id_cdr_concept
                              FROM cdr_event cdre
                              JOIN cdr_external cdrex
                                ON cdre.id_cdr_external = cdrex.id_cdr_external
                              JOIN cdr_type cdrt
                                ON cdrex.id_cdr_type = cdrt.id_cdr_type
                              LEFT JOIN cdr_type_rank_mkt cdrtm
                                ON cdrtm.id_cdr_type = cdrt.id_cdr_type
                               AND cdrtm.id_cdr_task_type = i_id_task_type
                               AND cdrtm.id_market = l_market
                              LEFT JOIN cdr_severity cdrs
                                ON cdrex.id_cdr_severity = cdrs.id_cdr_severity
                             WHERE cdre.id_cdr_call = i_call
                               AND cdre.id_cdr_external IS NOT NULL -- only external cases
                            ) w1) wd
             ORDER BY wd.rank;
    BEGIN
        -- set user input usage
        IF i_use_input = pk_alert_constant.g_yes
        THEN
            l_use_input := pk_alert_constant.g_yes;
        ELSE
            l_use_input := pk_alert_constant.g_no;
        END IF;
    
        -- debug input
        IF g_debug_enable
        THEN
            g_error := 'i_call: ' || i_call;
            g_error := g_error || ', l_use_input: ' || l_use_input;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        IF i_call IS NULL
        THEN
            pk_types.open_my_cursor(i_cursor => o_sect1);
            pk_types.open_my_cursor(i_cursor => o_sect2);
            pk_types.open_my_cursor(i_cursor => o_sect3);
            pk_types.open_my_cursor(i_cursor => o_sect4);
        ELSE
            l_na := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'CDR_T017');
            -- institution id_market
            l_market := pk_utils.get_institution_market(i_lang => i_lang, i_id_institution => i_prof.institution);
        
            g_error := 'OPEN c_warn_data';
            OPEN c_warn_data;
            FETCH c_warn_data BULK COLLECT
                INTO l_warn_data;
            CLOSE c_warn_data;
        
            g_error := 'OPEN o_sect1';
            OPEN o_sect1 FOR
                SELECT t.section_1_id, decode(t.cnt, 1, NULL, t.desc_concept) /* t.desc_concept*/ section_1_desc
                  FROM (SELECT wd.section_1_id, wd.desc_concept, MIN(wd.rank) rank, COUNT(*) over() cnt
                          FROM TABLE(l_warn_data) wd
                         GROUP BY wd.section_1_id, wd.desc_concept) t
                 ORDER BY t.rank;
        
            g_error := 'OPEN o_sect2';
            OPEN o_sect2 FOR
                SELECT t.section_1_id, t.section_2_id, t.desc_element section_2_desc, t.icon_cdr_concept section_2_icon
                  FROM (SELECT wd.section_1_id, wd.section_2_id, wd.desc_element, wd.icon_cdr_concept, MIN(wd.rank) rank
                          FROM TABLE(l_warn_data) wd
                         GROUP BY wd.section_1_id, wd.section_2_id, wd.desc_element, wd.icon_cdr_concept) t
                 ORDER BY t.rank;
        
            g_error := 'OPEN o_sect3';
            OPEN o_sect3 FOR
                SELECT t.section_2_id,
                       t.section_3_id,
                       t.id_cdr_action cdr_action_id,
                       t.id_cdr_answer answer_id,
                       t.notes_answer answer_notes,
                       t.flg_req_notes answer_requires_notes,
                       t.show_line_flg,
                       decode(t.id_cdr_action,
                              pk_cdr_constant.g_cdra_postpone,
                              pk_alert_constant.g_no,
                              pk_alert_constant.g_yes) show_severity_flg
                  FROM (SELECT wd.section_2_id,
                               wd.section_3_id,
                               wd.id_cdr_action,
                               wd.id_cdr_answer,
                               wd.notes_answer,
                               wd.flg_req_notes,
                               wd.show_line_flg,
                               wd.rank
                          FROM TABLE(l_warn_data) wd
                         WHERE wd.rank IN (SELECT MAX(wd.rank) rank
                                             FROM TABLE(l_warn_data) wd
                                            GROUP BY wd.section_2_id, wd.section_3_id)) t
                 ORDER BY t.rank;
        
            g_error := 'OPEN o_sect4';
            OPEN o_sect4 FOR
                SELECT wd.section_3_id,
                       wd.id_cdr_event,
                       wd.type_desc,
                       wd.type_icon,
                       wd.type_icon_color,
                       wd.type_message,
                       wd.severity_desc,
                       wd.severity_color,
                       wd.severity_text_style,
                       wd.section_4_last_item_flg,
                       wd.triggered_by_desc,
                       wd.triggered_by_color,
                       wd.id_links,
                       wd.id_cdr_definition,
                       wd.id_cdr_doc_instance
                  FROM TABLE(l_warn_data) wd
                 ORDER BY wd.rank;
        END IF;
    END get_popup_sections;

    FUNCTION get_all_ges
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_call  IN NUMBER,
        o_ges   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_ges_cdr_action  CONSTANT NUMBER(24) := k_action_isencao;
        k_ges_cdr_concept CONSTANT NUMBER(24) := k_concept_isencao;
        k_value_type      CONSTANT VARCHAR2(0200 CHAR) := 'CDS_INITIAL';
        l_market NUMBER(24);
    
    BEGIN
    
        l_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
    
        OPEN o_ges FOR
            SELECT ce.notes_answer,
                   ca.id_workflow_action,
                   pk_adt.map_value(i_id_market      => l_market,
                                    i_value_type     => k_value_type,
                                    i_original_value => ca.id_workflow_action) flg_workflow,
                   pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => wa.code_action) desc_answer,
                   ce.domain_value,
                   ce.domain_free_text,
                   pk_cdr_fo_core.get_id_isencao(i_id_content => cip2.id_element) id_exemption
              FROM cdr_event ce
              JOIN cdr_inst_par_action cipa
                ON cipa.id_cdr_inst_par_action = ce.id_cdr_inst_par_action
              JOIN cdr_inst_param cip
                ON cip.id_cdr_inst_param = cipa.id_cdr_inst_param
              JOIN cdr_inst_param cip2
                ON cip2.id_cdr_instance = cip.id_cdr_instance
              JOIN cdr_parameter cp
                ON cp.id_cdr_parameter = cip2.id_cdr_parameter
              JOIN cdr_answer ca
                ON ca.id_cdr_answer = ce.id_cdr_answer
              JOIN wf_workflow_action wa
                ON wa.id_workflow_action = ca.id_workflow_action
             WHERE 0 = 0
               AND ce.id_cdr_call = i_call
               AND cp.id_cdr_concept = k_ges_cdr_concept
               AND cipa.id_cdr_action = k_ges_cdr_action;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => SQLERRM,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_ALL_GES',
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(o_ges);
            RETURN FALSE;
    END get_all_ges;

    FUNCTION get_id_isencao(i_id_content IN VARCHAR2) RETURN NUMBER IS
        k_yes CONSTANT VARCHAR2(0001 CHAR) := 'Y';
        l_id_isencao NUMBER(24);
        l_tbl        table_varchar;
    BEGIN
    
        SELECT id_isencao
          BULK COLLECT
          INTO l_tbl
          FROM isencao
         WHERE id_content = i_id_content
           AND flg_available = k_yes;
    
        IF l_tbl.count > 0
        THEN
            l_id_isencao := l_tbl(1);
        END IF;
    
        RETURN l_id_isencao;
    
    END get_id_isencao;

    -- **********************************************************************************
    PROCEDURE ins_cdr_screen
    (
        i_tbl_screen_name IN table_varchar,
        i_tbl_desc        IN table_varchar
    ) IS
    BEGIN
    
        FORALL i IN 1 .. i_tbl_screen_name.count
            INSERT /*+ ignore_row_on_dupkey_index( cdr_screens, CDR_SCR_NAME_PK ) */
            INTO cdr_screens
                (screen_name, scr_description)
            VALUES
                (i_tbl_screen_name(i), i_tbl_desc(i));
    
    END ins_cdr_screen;

    -- **********************************************************************************
    PROCEDURE ins_cdr_screen
    (
        i_screen_name IN VARCHAR2,
        i_desc        IN VARCHAR2
    ) IS
    BEGIN
    
        ins_cdr_screen(i_tbl_screen_name => table_varchar(i_screen_name), i_tbl_desc => table_varchar(i_desc));
    
    END ins_cdr_screen;

    -- **********************************************************************************
    PROCEDURE ins_cdr_def_exception
    (
        i_tbl_cdr_definition IN table_number,
        i_screen_name        IN VARCHAR2,
        i_id_institution     IN NUMBER
    ) IS
    BEGIN
    
        FORALL i IN 1 .. i_tbl_cdr_definition.count
            INSERT /*+ ignore_row_on_dupkey_index( cdr_scr_def_exception, CDR_SCR_DEF_NAME_PK ) */
            INTO cdr_scr_def_exception
                (id_cdr_definition, screen_name, id_institution)
            VALUES
                (i_tbl_cdr_definition(i), i_screen_name, i_id_institution);
    
    END ins_cdr_def_exception;

    -- **********************************************************************************
    PROCEDURE ins_cdr_def_exception
    (
        i_id_cdr_definition IN NUMBER,
        i_screen_name       IN VARCHAR2,
        i_id_institution    IN NUMBER
    ) IS
    BEGIN
    
        ins_cdr_def_exception(i_tbl_cdr_definition => table_number(i_id_cdr_definition),
                              i_screen_name        => i_screen_name,
                              i_id_institution     => i_id_institution);
    
    END ins_cdr_def_exception;

    -- ******************************************************************************
    PROCEDURE del_cdr_def_exception
    (
        i_id_cdr_definition IN NUMBER,
        i_screen_name       IN VARCHAR2,
        i_id_institution    IN NUMBER
    ) IS
    BEGIN
    
        DELETE cdr_scr_def_exception
         WHERE id_cdr_definition = i_id_cdr_definition
           AND screen_name = i_screen_name
           AND id_institution = i_id_institution;
    
    END del_cdr_def_exception;

    /********************************************************************************************
    * Get the respective ALERT cdr external type from VIDAL
    *
    * @param i_cdr_type       type of cdr
    *
    * @return                 ALERT CDR type
    *
    * @author                 Vanessa Barsottelli
    * @version                2.6.5
    * @since                  20-06-2016
    **********************************************************************************************/
    FUNCTION get_map_vidal_types(i_type cdr_external.id_cdr_type%TYPE) RETURN NUMBER IS
        l_ret cdr_external.id_cdr_type%TYPE;
    BEGIN
        --THIS ONLY WORKS FOR FR SUPPLIERS
        CASE
            WHEN i_type = pk_cdr_constant.g_ced_product THEN
                l_ret := 1;
            WHEN i_type = pk_cdr_constant.g_ced_ucd THEN
                l_ret := 2;
            WHEN i_type = pk_cdr_constant.g_ced_pk THEN
                l_ret := 3;
            WHEN i_type = pk_cdr_constant.g_ced_cng THEN
                l_ret := 0;
            ELSE
                l_ret := NULL;
        END CASE;
    
        RETURN l_ret;
    END get_map_vidal_types;

    /**
    * Checks the CDR engine for applicable rules, using task types. -- EMR-2452
    * Analyzes all rules within the framework, and creates events for the valid ones.
    * Outputs a list of rules that must be seen as warnings.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_call         previous call identifier
    * @param i_task_types   task type identifiers list
    * @param i_task_reqs    task request identifiers list
    * @param i_dose         dosage values list
    * @param i_dose_um      dosage measurement units list
    * @param i_route        administration routes list
    * @param i_xml          Array of XML
    * @param i_id_task_type Area for check rules (51)
    * @param o_sect1        popup section 1 cursor
    * @param o_sect2        popup section 2 cursor
    * @param o_sect3        popup section 3 cursor
    * @param o_sect4        popup section 4 cursor
    * @param o_btn_config   popup buttons config
    * @param o_call         call identifier
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Alexander Camilo
    * @version              2.7.3
    * @since                2018/04/04
    */
    FUNCTION check_rules_tt
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_call         IN cdr_call.id_cdr_call%TYPE := NULL,
        i_task_types   IN table_number,
        i_task_reqs    IN table_varchar,
        i_dose         IN table_number := NULL,
        i_dose_um      IN table_number := NULL,
        i_route        IN table_varchar := NULL,
        i_xml          IN table_varchar,
        i_id_task_type IN task_type.id_task_type%TYPE, -- the area where check_rules is called
        i_screen_name  IN VARCHAR2,
        o_sect1        OUT pk_types.cursor_type,
        o_sect2        OUT pk_types.cursor_type,
        o_sect3        OUT pk_types.cursor_type,
        o_sect4        OUT pk_types.cursor_type,
        o_btn_config   OUT pk_types.cursor_type,
        o_call         OUT cdr_call.id_cdr_call%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CHECK_RULES_TT';
    BEGIN
        g_xml   := i_xml;
        g_error := 'CALL pk_cdr_fo_core.check_rules_tt';
        IF NOT pk_cdr_fo_core.check_rules_tt(i_lang         => i_lang,
                                             i_prof         => i_prof,
                                             i_patient      => i_patient,
                                             i_episode      => i_episode,
                                             i_task_types   => i_task_types,
                                             i_task_reqs    => i_task_reqs,
                                             i_dose         => i_dose,
                                             i_dose_um      => i_dose_um,
                                             i_route        => i_route,
                                             i_id_task_type => i_id_task_type,
                                             i_screen_name  => i_screen_name,
                                             o_sect1        => o_sect1,
                                             o_sect2        => o_sect2,
                                             o_sect3        => o_sect3,
                                             o_sect4        => o_sect4,
                                             o_btn_config   => o_btn_config,
                                             o_call         => o_call,
                                             o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_sect1);
            pk_types.open_my_cursor(o_sect2);
            pk_types.open_my_cursor(o_sect3);
            pk_types.open_my_cursor(o_sect4);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_sect1);
            pk_types.open_my_cursor(o_sect2);
            pk_types.open_my_cursor(o_sect3);
            pk_types.open_my_cursor(o_sect4);
            RETURN FALSE;
    END check_rules_tt;
BEGIN
    -- log initialization
    pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    pk_alertlog.log_init(object_name => g_package);
    g_debug_enable := pk_alertlog.is_debug_enabled(i_object_name => g_package);

END pk_cdr_fo_core;
/
