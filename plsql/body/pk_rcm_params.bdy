/*-- Last Change Revision: $Rev: 1834646 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2018-04-09 14:55:51 +0100 (seg, 09 abr 2018) $*/

CREATE OR REPLACE PACKAGE BODY pk_rcm_params IS

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    g_retval BOOLEAN;
    g_exception_np EXCEPTION;
    g_exception EXCEPTION;

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
        WITH TIME ZONE IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'ADD_INTERVAL';
        l_timestamp TIMESTAMP
            WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        g_error := 'Init ' || l_func_name || ' / i_amount=' || i_amount || ' i_unit_measure=' || i_unit_measure;
    
        CASE i_unit_measure
            WHEN pk_rcm_constant.g_unit_measure_year THEN
                l_timestamp := pk_date_utils.add_to_ltstz(i_timestamp => i_timestamp,
                                                         i_amount    => i_amount,
                                                         i_unit      => pk_rcm_constant.g_unit_label_year);
            
            WHEN pk_rcm_constant.g_unit_measure_month THEN
                l_timestamp := pk_date_utils.add_to_ltstz(i_timestamp => i_timestamp,
                                                         i_amount    => i_amount,
                                                         i_unit      => pk_rcm_constant.g_unit_label_month);
            
            WHEN pk_rcm_constant.g_unit_measure_week THEN
            
                l_timestamp := pk_date_utils.add_to_ltstz(i_timestamp => i_timestamp,
                                                         i_amount    => i_amount * pk_rcm_constant.g_num_days_week,
                                                         i_unit      => pk_rcm_constant.g_unit_label_day);
            
            WHEN pk_rcm_constant.g_unit_measure_day THEN
                l_timestamp := pk_date_utils.add_to_ltstz(i_timestamp => i_timestamp,
                                                         i_amount    => i_amount,
                                                         i_unit      => pk_rcm_constant.g_unit_label_day);
        END CASE;
    
        RETURN l_timestamp;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => NULL,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            RETURN NULL;
    END add_interval;

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
        PIPELINED IS
    
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'GET_RULE_PARAMS_VAL';
        out_rec t_rec_rule_param_val := t_rec_rule_param_val();
        l_error t_error_out;
    
        CURSOR c_val IS
            SELECT v.id_rcm_rule,
                   v.id_rule_inst,
                   v.parameter_name,
                   v.id_param_seq,
                   nvl(i.chr_val, v.chr_val) chr_val,
                   nvl(i.num_val, v.num_val) num_val,
                   nvl(i.dte_val, v.dte_val) dte_val,
                   nvl(i.interval_val, v.interval_val) interval_val,
                   rrp.rank,
                   (SELECT rrpr.parameter_name
                      FROM rcm_rule_param_rel rrpr
                     WHERE rrpr.id_rcm_rule = rrp.id_rcm_rule
                       AND rrpr.parameter_name_rel = rrp.parameter_name) parameter_name_parent
              FROM rcm_inst_param_val v
              JOIN rcm_rule_inst_param rrip
                ON (v.id_rcm_rule = rrip.id_rcm_rule AND v.id_rule_inst = rrip.id_rule_inst AND
                   v.parameter_name = rrip.parameter_name)
              JOIN rcm_rule_param rrp
                ON (rrp.id_rcm_rule = v.id_rcm_rule AND rrp.parameter_name = v.parameter_name)
              LEFT JOIN rcm_inst_param_val_inst i
                ON (v.id_rcm_rule = i.id_rcm_rule AND v.id_rule_inst = i.id_rule_inst AND
                   v.parameter_name = i.parameter_name AND v.id_param_seq = i.id_param_seq)
             WHERE v.id_rcm_rule = i_id_rcm_rule
               AND v.id_rule_inst = i_id_rule_inst
               AND v.parameter_name = nvl(i_parameter_name, v.parameter_name)
               AND (i.id_institution IS NULL OR i.id_institution = i_id_institution);
    BEGIN
        OPEN c_val;
        LOOP
            FETCH c_val
                INTO out_rec.id_rcm_rule,
                     out_rec.id_rule_inst,
                     out_rec.parameter_name,
                     out_rec.id_param_seq,
                     out_rec.chr_val,
                     out_rec.num_val,
                     out_rec.dte_val,
                     out_rec.interval_val,
                     out_rec.rank,
                     out_rec.parameter_name_par;
        
            EXIT WHEN c_val%NOTFOUND;
        
            PIPE ROW(out_rec);
        
        END LOOP;
    
        CLOSE c_val;
    
        RETURN;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => NULL,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error);
    END get_rule_params_val;

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
    ) IS
    BEGIN
        pk_context_api.set_parameter('i_lang', i_lang);
        pk_context_api.set_parameter('i_prof_id', i_prof.id);
        pk_context_api.set_parameter('i_prof_institution', i_prof.institution);
        pk_context_api.set_parameter('i_prof_software', i_prof.software);
        pk_context_api.set_parameter('p_age_min_months', pk_rcm_constant.g_param_age_min_m);
        pk_context_api.set_parameter('p_age_max_months', pk_rcm_constant.g_param_age_max_m);
        pk_context_api.set_parameter('p_age_min_years', pk_rcm_constant.g_param_age_min_y);
        pk_context_api.set_parameter('p_age_max_years', pk_rcm_constant.g_param_age_max_y);
        pk_context_api.set_parameter('p_gender', pk_rcm_constant.g_param_gender);
        pk_context_api.set_parameter('p_medication', pk_rcm_constant.g_param_med);
        pk_context_api.set_parameter('p_not_medication', pk_rcm_constant.g_param_not_med);
        pk_context_api.set_parameter('p_lab_test_request', pk_rcm_constant.g_param_lab_test);
        pk_context_api.set_parameter('p_not_lab_test_request', pk_rcm_constant.g_param_not_lab_test);
        pk_context_api.set_parameter('p_problem', pk_rcm_constant.g_param_probl);
        pk_context_api.set_parameter('p_not_problem', pk_rcm_constant.g_param_not_probl);
        pk_context_api.set_parameter('p_sr_proc', pk_rcm_constant.g_param_sr_proc);
        pk_context_api.set_parameter('p_not_sr_proc', pk_rcm_constant.g_param_not_sr_proc);
        pk_context_api.set_parameter('l_temp_type_rules', pk_rcm_constant.g_temp_type_rules);
        pk_context_api.set_parameter('l_prop_epis_ndays', pk_rcm_constant.g_rcm_prop_epis_ndays);
        pk_context_api.set_parameter('l_prop_remind_ndays', pk_rcm_constant.g_rcm_prop_remind_ndays);
        pk_context_api.set_parameter('g_year_desc',
                                     pk_message.get_message(i_lang      => i_lang,
                                                            i_code_mess => pk_rcm_constant.g_sc_year_desc));
        pk_context_api.set_parameter('g_month_desc',
                                     pk_message.get_message(i_lang      => i_lang,
                                                            i_code_mess => pk_rcm_constant.g_sc_month_desc));
    
        FOR i IN 1 .. i_context_keys.count
        LOOP
            pk_context_api.set_parameter(i_context_keys(i), i_context_vals(i));
        END LOOP;
    
    END init_params;

    /**
    * Inserts into temporary table the values related to parameter AGE_MIN
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identifier and its context (institution and software)
    * @param   i_id_rcm_rule        Rule identifier    
    * @param   i_id_rule_inst       Rule instance identifier
    * @param   i_parameter_name     Parameter name
    * @param   i_id_param_seq       Parameter seq identifier
    * @param   i_value_c            Parameter value if varchar
    * @param   i_value_n            Parameter value if number
    * @param   i_value_d            Parameter value if timestamp
    * @param   i_value_i            Parameter value if interval
    * @param   i_parameter_name_par Parameter name to which this parameter is related (parent parameter)
    * @param   o_error              Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   11-04-2012
    */
    FUNCTION set_temp_param
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rcm_rule        IN rcm_inst_param_val.id_rcm_rule%TYPE,
        i_id_rule_inst       IN rcm_inst_param_val.id_rule_inst%TYPE,
        i_parameter_name     IN rcm_inst_param_val.parameter_name%TYPE,
        i_id_param_seq       IN rcm_inst_param_val.id_param_seq%TYPE,
        i_value_c            IN rcm_inst_param_val.chr_val%TYPE,
        i_value_n            IN rcm_inst_param_val.num_val%TYPE,
        i_value_d            IN rcm_inst_param_val.dte_val%TYPE,
        i_value_i            IN rcm_inst_param_val.interval_val%TYPE,
        i_parameter_name_par IN rcm_rule_param_rel.parameter_name_rel%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'SET_TEMP_PARAM';
    BEGIN
        g_error := 'Init ' || l_func_name || ' / i_id_rcm_rule=' || i_id_rcm_rule || ' i_id_rule_inst=' ||
                   i_id_rule_inst || ' i_parameter_name=' || i_parameter_name || ' i_id_param_seq=' || i_id_param_seq ||
                   ' i_value_c=' || i_value_c || ' i_value_n=' || i_value_n || ' i_value_d=' ||
                   to_char(i_value_d, pk_alert_constant.g_dt_yyyymmddhh24miss) || ' i_parameter_name_par=' ||
                   i_parameter_name_par;
    
        CASE
            WHEN i_parameter_name IN (pk_rcm_constant.g_param_age_min_y,
                                      pk_rcm_constant.g_param_age_max_y,
                                      pk_rcm_constant.g_param_age_min_m,
                                      pk_rcm_constant.g_param_age_max_m) THEN
            
                INSERT INTO tbl_temp
                    (vc_1, vc_2, num_1, num_2, num_3, num_4)
                VALUES
                    (pk_rcm_constant.g_temp_type_rules,
                     i_parameter_name,
                     i_id_rcm_rule,
                     i_id_rule_inst,
                     i_id_param_seq,
                     i_value_n);
            
            WHEN i_parameter_name = pk_rcm_constant.g_param_gender THEN
                INSERT INTO tbl_temp
                    (vc_1, vc_2, num_1, num_2, num_3, vc_4)
                VALUES
                    (pk_rcm_constant.g_temp_type_rules,
                     i_parameter_name,
                     i_id_rcm_rule,
                     i_id_rule_inst,
                     i_id_param_seq,
                     i_value_c);
            
            WHEN i_parameter_name IN (pk_rcm_constant.g_param_med, pk_rcm_constant.g_param_not_med) THEN
                INSERT INTO tbl_temp
                    (vc_1, vc_2, num_1, num_2, num_3, vc_4)
                VALUES
                    (pk_rcm_constant.g_temp_type_rules,
                     i_parameter_name,
                     i_id_rcm_rule,
                     i_id_rule_inst,
                     i_id_param_seq,
                     i_value_c);
            
            WHEN i_parameter_name IN (pk_rcm_constant.g_param_sr_proc, pk_rcm_constant.g_param_not_sr_proc) THEN
            
                INSERT INTO tbl_temp
                    (vc_1, vc_2, num_1, num_2, num_3, num_4)
                VALUES
                    (pk_rcm_constant.g_temp_type_rules,
                     i_parameter_name,
                     i_id_rcm_rule,
                     i_id_rule_inst,
                     i_id_param_seq,
                     i_value_n);
            
            WHEN i_parameter_name IN (pk_rcm_constant.g_param_probl, pk_rcm_constant.g_param_not_probl) THEN
            
                INSERT INTO tbl_temp
                    (vc_1, vc_2, num_1, num_2, num_3, num_4)
                VALUES
                    (pk_rcm_constant.g_temp_type_rules,
                     i_parameter_name,
                     i_id_rcm_rule,
                     i_id_rule_inst,
                     i_id_param_seq,
                     i_value_n);
            
            WHEN i_parameter_name IN (pk_rcm_constant.g_param_lab_test, pk_rcm_constant.g_param_not_lab_test) THEN
                INSERT INTO tbl_temp
                    (vc_1, vc_2, num_1, num_2, num_3, num_4)
                VALUES
                    (pk_rcm_constant.g_temp_type_rules,
                     i_parameter_name,
                     i_id_rcm_rule,
                     i_id_rule_inst,
                     i_id_param_seq,
                     i_value_n);
            
            WHEN i_parameter_name = pk_rcm_constant.g_param_intv_n_lab_test THEN
            
                UPDATE tbl_temp
                   SET num_5 = i_value_n
                 WHERE vc_1 = pk_rcm_constant.g_temp_type_rules
                   AND vc_2 = i_parameter_name_par -- updates parent parameter
                   AND num_1 = i_id_rcm_rule
                   AND num_2 = i_id_rule_inst
                   AND num_3 = i_id_param_seq;
            
            WHEN i_parameter_name = pk_rcm_constant.g_param_intvu_n_lab_test THEN
            
                UPDATE tbl_temp
                   SET num_6 = i_value_n
                 WHERE vc_1 = pk_rcm_constant.g_temp_type_rules
                   AND vc_2 = i_parameter_name_par -- updates parent parameter
                   AND num_1 = i_id_rcm_rule
                   AND num_2 = i_id_rule_inst
                   AND num_3 = i_id_param_seq;
            
            ELSE
                g_error := 'Parameter not found / PARAMETER_NAME=' || i_parameter_name;
        END CASE;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => NULL,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END set_temp_param;

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
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'LOAD_INSTANCE_DATA';
    BEGIN
        g_error := 'Init ' || l_func_name || ' / i_id_rcm_rule=' || i_id_rcm_rule || ' i_id_rule_inst=' ||
                   i_id_rule_inst;
        --pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        -- cleans temporary table
        DELETE FROM tbl_temp
         WHERE vc_1 = pk_rcm_constant.g_temp_type_rules;
    
        -- loads all parameters values of this instance rule 
        FOR rec_param_vals IN (SELECT *
                                 FROM TABLE(get_rule_params_val(i_id_rcm_rule    => i_id_rcm_rule,
                                                                i_id_rule_inst   => i_id_rule_inst,
                                                                i_id_institution => i_prof.institution))
                                ORDER BY parameter_name_par NULLS FIRST)
        LOOP
        
            -- FIRST: loads parameters that are not related with any other parameters (NULLS FIRST)
            -- SECOND: loads parameters that are related with other parameters
            g_error  := l_func_name || ': Call set_temp_param / i_id_rcm_rule=' || rec_param_vals.id_rcm_rule ||
                        ' i_parameter_name=' || rec_param_vals.parameter_name || ' id_rule_inst=' ||
                        rec_param_vals.id_rule_inst || ' i_id_param_seq=' || rec_param_vals.id_param_seq;
            g_retval := set_temp_param(i_lang               => i_lang,
                                       i_prof               => i_prof,
                                       i_id_rcm_rule        => rec_param_vals.id_rcm_rule,
                                       i_id_rule_inst       => rec_param_vals.id_rule_inst,
                                       i_parameter_name     => rec_param_vals.parameter_name,
                                       i_id_param_seq       => rec_param_vals.id_param_seq,
                                       i_value_c            => rec_param_vals.chr_val,
                                       i_value_n            => rec_param_vals.num_val,
                                       i_value_d            => rec_param_vals.dte_val,
                                       i_value_i            => rec_param_vals.interval_val,
                                       i_parameter_name_par => rec_param_vals.parameter_name_par,
                                       o_error              => o_error);
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
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
    END load_instance_data;

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
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'GET_RCM_RULES';
    BEGIN
        g_error := 'Init ' || l_func_name;
        --pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        OPEN o_rcm_rules FOR
            SELECT rrir.id_rcm, rrir.id_rcm_rule, rrir.id_rule_inst, rr.rule_query
              FROM rcm_rule_inst_rcm rrir
              JOIN rcm_rule_inst rri
                ON (rri.id_rcm_rule = rrir.id_rcm_rule AND rri.id_rule_inst = rrir.id_rule_inst)
              JOIN rcm_rule rr
                ON (rr.id_rcm_rule = rri.id_rcm_rule)
             WHERE rri.flg_available = pk_alert_constant.g_yes
             ORDER BY rrir.id_rcm_rule;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_rcm_rules);
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
            pk_types.open_my_cursor(o_rcm_rules);
            RETURN FALSE;
    END get_rcm_rules;

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
    ) RETURN CLOB IS
        l_func_name pk_rcm_constant.t_low_char := 'GET_PAT_TEXT_DET_VAL';
        l_ret       VARCHAR2(4000 CHAR);
        l_id_concept         concept.id_concept%TYPE;
        l_id_concept_term    concept_term.id_concept_term%TYPE;
        l_id_concept_version concept_version.id_concept_version%TYPE;
    
        CURSOR c_probl(x_id_concept IN concept.id_concept%TYPE) IS
            SELECT v.id_alert_diagnosis, v.id_diagnosis
              FROM v_check_diagnosis_in_ehr v
             WHERE v.id_patient = i_id_patient
               AND v.id_institution = i_prof.institution
               AND v.id_concept = x_id_concept;
    BEGIN
        g_error := g_error || ' Init ' || l_func_name || ' / i_parameter_name=' || i_parameter_name ||
                   ' i_parameter_value=' || i_parameter_value || ' i_id_patient=' || i_id_patient;
        CASE
            WHEN i_parameter_name IN (pk_rcm_constant.g_param_med, pk_rcm_constant.g_param_not_med) THEN
                l_ret := pk_api_pfh_in.get_product_desc(i_lang       => i_lang,
                                                        i_prof       => i_prof,
                                                        i_id_product => i_parameter_value);
            
            WHEN i_parameter_name IN (pk_rcm_constant.g_param_sr_proc, pk_rcm_constant.g_param_not_sr_proc) THEN
                l_ret := pk_api_oris.get_coded_surg_procedure_desc(i_lang               => i_lang,
                                                                   i_prof               => i_prof,
                                                                   i_id_sr_intervention => to_number(i_parameter_value));
            
            WHEN i_parameter_name IN (pk_rcm_constant.g_param_probl, pk_rcm_constant.g_param_not_probl) THEN
            
                l_id_concept := to_number(i_parameter_value);
            
                -- get ID_CONCEPT_TERM registered for this patient, for diagnosis ID_CONCEPT_VERSION
                g_error := g_error || ' / OPEN c_probl';
                OPEN c_probl(l_id_concept);
                FETCH c_probl
                    INTO l_id_concept_term, l_id_concept_version;
                CLOSE c_probl;
            
                g_error := l_func_name || ': Call pk_diagnosis.std_diag_desc / i_id_diagnosis=' || l_id_concept_version ||
                           ' i_id_alert_diagnosis=' || l_id_concept_term || ' i_id_task_type=' ||
                           pk_alert_constant.g_task_problems || ' ID_PATIENT=' || i_id_patient || ' ID_CONCEPT=' ||
                           i_parameter_value;
                l_ret := pk_diagnosis.std_diag_desc(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                      i_id_diagnosis       => l_id_concept_version,
                                                      i_id_alert_diagnosis => l_id_concept_term,
                                                    i_id_task_type => pk_alert_constant.g_task_problems,
                                                    i_code         => NULL,
                                                    i_flg_other    => NULL,
                                                    i_flg_std_diag => NULL);
            
            WHEN i_parameter_name IN (pk_rcm_constant.g_param_lab_test, pk_rcm_constant.g_param_not_lab_test) THEN
                l_ret := pk_lab_tests_api_db.get_alias_translation(i_lang             => i_lang,
                                                                   i_prof             => i_prof,
                                                                   i_code_translation => 'ANALYSIS.CODE_ANALYSIS.' ||
                                                                                         i_parameter_value,
                                                                   i_dep_clin_serv    => NULL);
            
            WHEN i_parameter_name = pk_rcm_constant.g_param_gender THEN
                l_ret := pk_sysdomain.get_domain(i_lang     => i_lang,
                                                 i_code_dom => 'PATIENT.GENDER',
                                                 i_val      => i_parameter_value);
            WHEN i_parameter_name = pk_rcm_constant.g_param_intv_n_lab_test THEN
                l_ret := abs(to_number(i_parameter_value));
            
            WHEN i_parameter_name = pk_rcm_constant.g_param_intvu_n_lab_test THEN
                l_ret := pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                      i_prof         => i_prof,
                                                                      i_unit_measure => i_parameter_value);
            
            WHEN i_parameter_name IN (pk_rcm_constant.g_param_age_min_y, pk_rcm_constant.g_param_age_max_y) THEN
                -- years
                l_ret := i_parameter_value || ' ' ||
                         pk_message.get_message(i_lang => i_lang, i_code_mess => pk_rcm_constant.g_sc_year_desc);
            
            WHEN i_parameter_name IN (pk_rcm_constant.g_param_age_min_m, pk_rcm_constant.g_param_age_max_m) THEN
                -- months
                l_ret := i_parameter_value || ' ' ||
                         pk_message.get_message(i_lang => i_lang, i_code_mess => pk_rcm_constant.g_sc_month_desc);
            
        /*WHEN i_parameter_name IN (pk_rcm_constant.g_param_age_min_y,
                                      pk_rcm_constant.g_param_age_max_y,
                                      pk_rcm_constant.g_param_age_min_m,
                                      pk_rcm_constant.g_param_age_max_m) THEN
                        l_ret := i_parameter_value;*/
            ELSE
                NULL;
        END CASE;
    
        RETURN to_clob(l_ret);
    
    END get_parameter_value_desc;

    /**
    * Gets parameter rule mask
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identifier and its context (institution and software)
    * @param   i_id_rcm_rule    Rule identifier
    * @param   i_parameter_name Parameter identifier
    * @param   o_mask           OUT rcm_rule_param.mask%TYPE,
    * @param   o_error          Parameter mask
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Joana Barroso 
    * @version 1.0
    * @since   27-04-2012
    */

    FUNCTION get_rule_param_mask
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_rcm_rule    IN rcm_rule_param.id_rcm_rule%TYPE,
        i_parameter_name IN rcm_rule_param.parameter_name%TYPE,
        o_mask           OUT rcm_rule_param.mask%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'GET_RULE_PARAM_MASK';
    
        CURSOR c_mask
        (
            x_id_rcm_rule    rcm_rule_param.id_rcm_rule%TYPE,
            x_parameter_name rcm_rule_param.parameter_name%TYPE
        ) IS
            SELECT mask
              FROM rcm_rule_param
             WHERE id_rcm_rule = x_id_rcm_rule
               AND parameter_name = x_parameter_name;
    
    BEGIN
    
        g_error := 'Init ' || l_func_name || ' / I_ID_RCM_RULE=' || i_id_rcm_rule || ' I_PARAMETER_NAME= ' ||
                   i_parameter_name;
    
        OPEN c_mask(i_id_rcm_rule, i_parameter_name);
        FETCH c_mask
            INTO o_mask;
        CLOSE c_mask;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
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
    END get_rule_param_mask;

    /**
    * Gets ibt with text of the rule
    *
    * @param   i_lang                 Professional preferred language
    * @param   i_prof                 Professional identifier and its context (institution and software)
    * @param   i_id_rcm_rule          Rule identifier
    * @param   i_id_rule_inst         Rule instance identifier
    * @param   i_id_patient           Patient identifie
    * @param   i_parameter_name       Parameter identifier
    * @param   i_parameter_name_par   Parent Parameter identifier
    * @param   i_label                Label identifier     
    * @param   i_parameter_value      Patient identifie
    * @param   io_desc_msg_ibt        Ibt with text of the rule
    * @param   o_error                Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Joana Barroso 
    * @version 1.0
    * @since   27-04-2012
    */

    FUNCTION get_rule_inst_param_text
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rcm_rule        IN rcm_rule_inst_rcm.id_rcm_rule%TYPE,
        i_id_rule_inst       IN rcm_rule_inst_rcm.id_rule_inst%TYPE,
        i_id_patient         IN pat_rcm_det.id_patient%TYPE,
        i_parameter_name     IN rcm_parameter.parameter_name%TYPE,
        i_parameter_name_par IN rcm_parameter.parameter_name%TYPE,
        i_label              IN rcm_parameter.label%TYPE,
        i_parameter_value    IN VARCHAR2,
        io_desc_msg_ibt      IN OUT pk_rcm_constant.t_ibt_large_desc_value,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'GET_RULE_INST_PARAM_TEXT';
    
        CURSOR c_tt IS
            SELECT *
              FROM tbl_temp tt
             WHERE tt.vc_1 = pk_rcm_constant.g_temp_type_pat
               AND tt.num_2 = i_id_rcm_rule
               AND tt.num_3 = i_id_rule_inst
               AND tt.num_4 = i_id_patient;
    
        c_tt_row c_tt%ROWTYPE;
    
        l_desc_message         sys_message.desc_message%TYPE;
        l_parameter_name       rcm_parameter.parameter_name%TYPE;
        l_parameter_value_desc VARCHAR2(4000);
        l_mask                 rcm_rule_param.mask%TYPE;
        l_value_desc           CLOB;
    BEGIN
        g_error := 'Init ' || l_func_name || ' / I_ID_RCM_RULE=' || i_id_rcm_rule || ' I_ID_RULE_INST=' ||
                   i_id_rule_inst || ' I_ID_PATIENT= ' || i_id_patient || ' I_PARAMETER_NAME=' || i_parameter_name ||
                   ' I_PARAMETER_NAME_PAR=' || i_parameter_name_par || ' I_LABEL=' || i_label || ' I_PARAMETER_VALUE=' ||
                   i_parameter_value;
    
        IF i_label IS NULL
        THEN
            l_desc_message := '';
        ELSE
            g_error        := l_func_name || ': Call pk_message.get_message i_code_mess=' || i_label;
            l_desc_message := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => i_label);
        END IF;
    
        g_error  := l_func_name || ': Call get_rule_param_mask / I_ID_RCM_RULE' || i_id_rcm_rule ||
                    ' I_PARAMETER_NAME=' || i_parameter_name;
        g_retval := get_rule_param_mask(i_lang           => i_lang,
                                        i_prof           => i_prof,
                                        i_id_rcm_rule    => i_id_rcm_rule,
                                        i_parameter_name => i_parameter_name,
                                        o_mask           => l_mask,
                                        o_error          => o_error);
    
        g_error := l_func_name || ': Replace @PARAM_LABEL and @PARAM_VAL / I_PARAMETER_NAME=' || i_parameter_name ||
                   'I_PARAMETER_NAME_PAR=' || i_parameter_name_par || ' I_ID_RCM_RULE=' || i_id_rcm_rule ||
                   ' I_ID_RULE_INST=' || i_id_rule_inst;
        IF i_parameter_name_par IS NOT NULL
        THEN
            g_error      := l_func_name || ': SON / I_PARAMETER_NAME_PAR=' || i_parameter_name_par ||
                            ' I_PARAMETER_NAME= ' || i_parameter_name || ' I_ID_RCM_RULE=' || i_id_rcm_rule ||
                            ' I_ID_RULE_INST=' || i_id_rule_inst;
            l_value_desc := get_parameter_value_desc(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_parameter_name  => i_parameter_name,
                                                     i_parameter_value => i_parameter_value,
                                                     i_id_patient      => i_id_patient);
        
            g_error := g_error || ' / i_parameter_name_par=' || i_parameter_name_par;
            l_mask  := REPLACE(REPLACE(l_mask, '@PARAM_LABEL', l_desc_message), '@PARAM_VAL', l_value_desc);
        
            IF io_desc_msg_ibt.exists(i_parameter_name_par)
            THEN
                io_desc_msg_ibt(i_parameter_name_par) := io_desc_msg_ibt(i_parameter_name_par) || ' ' ||
                                                         to_clob(l_mask);
            ELSE
                io_desc_msg_ibt(i_parameter_name_par) := to_clob(l_mask);
            END IF;
            l_parameter_name := i_parameter_name_par;
        
        ELSE
            g_error      := l_func_name || ': PARENT / I_PARAMETER_NAME=' || i_parameter_name || ' I_ID_RCM_RULE=' ||
                            i_id_rcm_rule || ' I_ID_RULE_INST=' || i_id_rule_inst;
            l_value_desc := get_parameter_value_desc(i_lang            => i_lang,
                                                       i_prof            => i_prof,
                                                       i_parameter_name  => i_parameter_name,
                                                     i_parameter_value => i_parameter_value,
                                                     i_id_patient      => i_id_patient);
        
            g_error := g_error || ' / I_PARAMETER_NAME=' || i_parameter_name;
            l_mask  := REPLACE(REPLACE(l_mask, '@PARAM_LABEL', l_desc_message), '@PARAM_VAL', l_value_desc);
        
            IF io_desc_msg_ibt.exists(i_parameter_name)
            THEN
                /* pk_alertlog.log_error(length(io_desc_msg_ibt(i_parameter_name)) || '|' || length(l_mask));
                pk_alertlog.log_error('I_ID_RCM_RULE=' || i_id_rcm_rule || ' I_ID_RULE_INST=' || i_id_rule_inst ||
                                      ' I_ID_PATIENT= ' || i_id_patient || ' I_PARAMETER_NAME=' || i_parameter_name ||
                                      ' I_PARAMETER_NAME_PAR=' || i_parameter_name_par || ' I_LABEL=' || i_label ||
                                      ' I_PARAMETER_VALUE=' || i_parameter_value);*/
                io_desc_msg_ibt(i_parameter_name) := io_desc_msg_ibt(i_parameter_name) || chr(10) || to_clob(l_mask);
            ELSE
                io_desc_msg_ibt(i_parameter_name) := to_clob(l_mask);
            END IF;
            l_parameter_name := i_parameter_name;
        END IF;
    
        g_error := l_func_name || ': IF i_parameter_name @PAT_VAL / I_PARAMETER_NAME=' || i_parameter_name ||
                   ' I_ID_RCM_RULE=' || i_id_rcm_rule || ' I_ID_RULE_INST=' || i_id_rule_inst;
        IF i_parameter_name IN (pk_rcm_constant.g_param_age_min_y,
                                pk_rcm_constant.g_param_age_max_y,
                                pk_rcm_constant.g_param_age_min_m,
                                pk_rcm_constant.g_param_age_max_m)
        THEN
            g_error := l_func_name || ': OPEN c_tt';
            OPEN c_tt;
            FETCH c_tt
                INTO c_tt_row;
            CLOSE c_tt;
        
            g_error := l_func_name || ': io_desc_msg_ibt.exists(' || l_parameter_name || ')';
            IF io_desc_msg_ibt.exists(l_parameter_name)
            THEN
                io_desc_msg_ibt(l_parameter_name) := REPLACE(io_desc_msg_ibt(l_parameter_name),
                                                             '@PAT_VAL',
                                                             c_tt_row.vc_3);
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
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
    END get_rule_inst_param_text;

    /**
    * Gets Sep_code text
    *
    * @param   i_lang          Professional preferred language
    * @param   i_prof          Professional identifier and its context (institution and software)
    * @param   i_id_rcm_rule   Rule identifier
    * @param   o_sep_code_desc text
    * @param   o_error         Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Joana Barroso 
    * @version 1.0
    * @since   27-04-2012
    */

    FUNCTION get_sep_code_desc
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_rcm_rule   IN rcm_rule_inst_rcm.id_rcm_rule%TYPE,
        o_sep_code_desc OUT sys_message.desc_message%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'GET_SEP_CODE_DESC';
    BEGIN
    
        g_error := 'Init ' || l_func_name || ' / I_ID_RCM_RULE=' || i_id_rcm_rule;
    
        SELECT pk_message.get_message(i_lang, code_sep)
          INTO o_sep_code_desc
          FROM rcm_rule
         WHERE id_rcm_rule = i_id_rcm_rule;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
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
    END get_sep_code_desc;

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
    * @author  Joana Barroso 
    * @version 1.0
    * @since   27-04-2012
    */
    FUNCTION get_rule_text
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_rcm_rule  IN rcm_rule_inst_rcm.id_rcm_rule%TYPE,
        i_id_rule_inst IN rcm_rule_inst_rcm.id_rule_inst%TYPE,
        i_id_patient   IN pat_rcm_det.id_patient%TYPE
    ) RETURN pat_rcm_det.rcm_text%TYPE IS
    
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'GET_RULE_TEXT';
        l_result pat_rcm_det.rcm_text%TYPE;
        l_error  t_error_out;
    
        l_desc_msg_ibt    pk_rcm_constant.t_ibt_large_desc_value;
        l_parameter_value VARCHAR2(4000);
    
        l_sep_code sys_message.desc_message%TYPE;
        l_array    table_varchar;
        i          PLS_INTEGER := 1;
    BEGIN
    
        g_error := 'Init ' || l_func_name || ' / I_ID_RCM_RULE=' || i_id_rcm_rule || ' I_ID_RULE_INST=' ||
                   i_id_rule_inst || ' I_ID_PATIENT= ' || i_id_patient;
        l_array := table_varchar();
    
        <<rec_param_vals>>
        FOR rec_param_vals IN (SELECT t.id_rcm_rule,
                                      t.id_rule_inst,
                                      t.parameter_name,
                                      p.label,
                                      t.id_param_seq,
                                      t.chr_val,
                                      t.num_val,
                                      t.dte_val,
                                      t.interval_val,
                                      t.rank,
                                      t.parameter_name_par
                                 FROM TABLE(get_rule_params_val(i_id_rcm_rule    => i_id_rcm_rule,
                                                                i_id_rule_inst   => i_id_rule_inst,
                                                                i_id_institution => i_prof.institution)) t
                                 JOIN rcm_parameter p
                                   ON (p.parameter_name = t.parameter_name)
                                ORDER BY t.parameter_name_par NULLS FIRST, t.rank)
        
        LOOP
        
            IF rec_param_vals.parameter_name_par IS NULL
               AND NOT l_desc_msg_ibt.exists(rec_param_vals.parameter_name)
            THEN
                -- Parent
                l_array.extend(1);
                l_array(i) := rec_param_vals.parameter_name;
            END IF;
        
            IF rec_param_vals.chr_val IS NOT NULL
            THEN
                l_parameter_value := rec_param_vals.chr_val;
            ELSIF rec_param_vals.num_val IS NOT NULL
            THEN
                l_parameter_value := to_char(rec_param_vals.num_val);
            ELSE
                l_parameter_value := NULL;
            END IF;
        
            g_error := l_func_name || ': Call get_rule_inst_param_text / I_ID_RCM_RULE' || i_id_rcm_rule ||
                       ' I_ID_RULE_INST=' || i_id_rule_inst || ' I_ID_PATIENT=' || i_id_patient || ' I_PARAMETER_NAME=' ||
                       rec_param_vals.parameter_name || ' I_PARAMETER_NAME_PAR=' || rec_param_vals.parameter_name_par ||
                       ' I_LABEL= ' || rec_param_vals.label || ' I_PARAMETER_VALUE=' || l_parameter_value;
        
            g_retval := get_rule_inst_param_text(i_lang               => i_lang,
                                                 i_prof               => i_prof,
                                                 i_id_rcm_rule        => i_id_rcm_rule,
                                                 i_id_rule_inst       => i_id_rule_inst,
                                                 i_id_patient         => i_id_patient,
                                                 i_parameter_name     => rec_param_vals.parameter_name,
                                                 i_parameter_name_par => rec_param_vals.parameter_name_par,
                                                 i_label              => rec_param_vals.label,
                                                 i_parameter_value    => l_parameter_value,
                                                 io_desc_msg_ibt      => l_desc_msg_ibt,
                                                 o_error              => l_error);
        
            IF NOT g_retval
            THEN
                pk_alertlog.log_error(g_error || ' / ' || l_error.ora_sqlcode || ' LOG=' || l_error.log_id);
            END IF;
            i := i + 1;
        END LOOP;
    
        g_error  := l_func_name || ': Call get_sep_code_desc / I_ID_RCM_RULE= ' || i_id_rcm_rule;
        g_retval := get_sep_code_desc(i_lang          => i_lang,
                                      i_prof          => i_prof,
                                      i_id_rcm_rule   => i_id_rcm_rule,
                                      o_sep_code_desc => l_sep_code,
                                      o_error         => l_error);
    
        IF NOT g_retval
        THEN
            pk_alertlog.log_error(g_error || ' / ' || l_error.ora_sqlcode || ' LOG=' || l_error.log_id);
        END IF;
    
        <<desc_msg_ibt_val>>
        FOR idx IN 1 .. l_array.count
        LOOP
            IF idx = 1
            THEN
                l_result := l_desc_msg_ibt(l_array(idx)) || chr(10);
            ELSE
                l_result := l_result || l_sep_code || chr(10) || l_desc_msg_ibt(l_array(idx)) || chr(10);
            END IF;
        
        END LOOP;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            RETURN NULL;
    END get_rule_text;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_rcm_params;
/
