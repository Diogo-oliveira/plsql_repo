/*-- Last Change Revision: $Rev: 2027575 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:38 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ref_core_internal AS

    g_error         VARCHAR2(1000 CHAR);
    g_package_name  VARCHAR2(50 CHAR);
    g_package_owner VARCHAR2(50 CHAR);
    g_exception_np EXCEPTION;
    g_exception    EXCEPTION;
    g_retval BOOLEAN;

    TYPE t_wf_action_cur IS REF CURSOR RETURN wf_action%ROWTYPE;

    g_leading_table_ref   CONSTANT VARCHAR2(50 CHAR) := 'REFERRAL';
    g_leading_table_pat   CONSTANT VARCHAR2(50 CHAR) := 'PATIENT';
    g_leading_table_other CONSTANT VARCHAR2(50 CHAR) := 'OTHER';

    /**
    * Gets the query for the profiles grid
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF professional id, institution and software
    * @param   i_var_desc    Variables description
    * @param   i_var_val     Variables values
    * @param   i_filter Filter to apply. Depends on button selected.
    * @param   i_view        View to get data. v_p1_grid by default
    * @param   o_sql sql text
    * @param   o_error error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   08-11-2007
    */
    FUNCTION get_grid_sql
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_var_desc IN table_varchar,
        i_var_val  IN table_varchar,
        i_filter   IN p1_grid_config.filter%TYPE,
        i_view     IN VARCHAR2 DEFAULT pk_ref_constant.g_view_p1_grid,
        o_sql      OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_count
        (
            x_pt profile_template.id_profile_template%TYPE,
            x_i  institution.id_institution%TYPE
        ) IS
            SELECT id_profile_template, id_institution, COUNT(1)
              FROM (SELECT g.id_profile_template, g.id_institution
                      FROM p1_grid_config g
                     WHERE g.id_profile_template IN (x_pt, 0)
                       AND g.id_institution IN (x_i, 0)
                       AND g.flg_type = 'A'
                       AND nvl(g.filter, i_filter) = i_filter
                    UNION
                    SELECT id_parent id_profile_template, id_institution
                      FROM (SELECT pt.id_parent, g.id_institution
                              FROM p1_grid_config g
                              JOIN profile_template pt
                                ON pt.id_parent = g.id_profile_template
                             WHERE pt.id_profile_template IN (x_pt, 0)
                               AND g.id_institution IN (x_i, 0)
                               AND g.flg_type = 'A'
                               AND nvl(g.filter, i_filter) = i_filter))
             GROUP BY id_profile_template, id_institution
             ORDER BY id_profile_template DESC, id_institution DESC;
    
        CURSOR c_condition
        (
            x_pt profile_template.id_profile_template%TYPE,
            x_i  institution.id_institution%TYPE
        ) IS
            SELECT sql_text
              FROM (SELECT g.sql_text, g.id_profile_template, g.id_institution
                      FROM p1_grid_config g
                     WHERE g.id_profile_template = x_pt
                       AND g.id_institution = x_i
                       AND g.flg_type = 'A'
                       AND nvl(g.filter, i_filter) = i_filter
                    UNION
                    -- ALERT-212546
                    SELECT sql_text, id_parent id_profile_template, id_institution
                      FROM (SELECT g.sql_text, pt.id_parent, g.id_institution
                              FROM p1_grid_config g
                              JOIN profile_template pt
                                ON pt.id_parent = g.id_profile_template
                             WHERE g.id_institution = x_i
                               AND g.flg_type = 'A'
                               AND nvl(g.filter, i_filter) = i_filter
                               AND pt.id_profile_template = x_pt)
                     ORDER BY id_profile_template DESC, id_institution DESC);
    
        l_sql p1_grid_config.sql_text%TYPE;
    
        l_pt    profile_template.id_profile_template%TYPE;
        l_inst  institution.id_institution%TYPE;
        l_count PLS_INTEGER DEFAULT 0;
    
        l_ref_schedule_limit  sys_config.value%TYPE;
        l_ref_missed_limit    sys_config.value%TYPE;
        l_ref_refused_x_limit sys_config.value%TYPE;
    BEGIN
    
        g_error := 'CALL pk_tools.get_prof_profile_template';
        l_pt    := pk_tools.get_prof_profile_template(i_prof);
    
        IF l_pt IS NULL
        THEN
            pk_alertlog.log_debug('pk_tools.get_prof_profile_template returned null');
        END IF;
    
        -- init context vars
        l_ref_schedule_limit  := pk_sysconfig.get_config('REF_FILTER_SCHEDULED_LIMIT', i_prof);
        l_ref_missed_limit    := pk_sysconfig.get_config('REF_FILTER_MISSED_LIMIT', i_prof);
        l_ref_refused_x_limit := pk_sysconfig.get_config('REF_FILTER_REFUSED_X_LIMIT', i_prof);
    
        pk_context_api.set_parameter('REF_SCHEDULED_LIMIT', l_ref_schedule_limit);
        pk_context_api.set_parameter('REF_MISSED_LIMIT', l_ref_missed_limit);
        pk_context_api.set_parameter('REF_REFUSED_X_LIMIT', l_ref_refused_x_limit);
    
        -- Calculate which pair profile/institution to use;
        g_error := 'Open c_count';
        OPEN c_count(l_pt, i_prof.institution);
        FETCH c_count
            INTO l_pt, l_inst, l_count;
        CLOSE c_count;
    
        IF l_count = 0
        THEN
            -- No where condition found
            o_sql := 'SELECT * FROM ' || i_view || ' v where 1=0';
            RETURN TRUE;
        END IF;
    
        -- Get data
        g_error := 'Open c_condition';
        l_count := 1;
        OPEN c_condition(l_pt, l_inst);
        LOOP
            FETCH c_condition
                INTO l_sql;
            EXIT WHEN c_condition%NOTFOUND;
        
            g_error := 'fetch c_condition (' || l_pt || ',' || l_inst || ') with i_filter=' || i_filter;
        
            g_error := g_error || ' / loop / ' || i_var_desc.count;
            FOR i IN 1 .. i_var_desc.count
            LOOP
                l_sql := REPLACE(l_sql, i_var_desc(i), i_var_val(i));
            END LOOP;
        
            g_error := 'count=' || l_count;
            IF l_count = 1
            THEN
                o_sql := o_sql || 'SELECT * FROM ' || i_view || ' v where ' || l_sql;
            ELSE
                o_sql := o_sql || chr(10) || 'union ' || chr(10) || 'SELECT * FROM ' || i_view || ' v where ' || l_sql;
            END IF;
        
            l_count := l_count + 1;
        END LOOP;
        CLOSE c_condition;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_GRID_SQL',
                                                     o_error    => o_error);
    END get_grid_sql;

    /**
    * Get P1 list - Return grid data depending on professional profile
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF professional id, institution and software
    * @param   i_filter Filter to apply. Depends on button selected.
    *
    * @RETURN  Return table (t_coll_p1_request) pipelined
    * @author  Joao Sa
    * @version 1.0
    * @since   08-11-2007
    */
    FUNCTION get_grid_data(i_sql IN VARCHAR2) RETURN t_coll_p1_request
        PIPELINED IS
    
        i_cursor pk_types.cursor_type;
        l_res    v_p1_grid%ROWTYPE;
        out_rec  t_rec_p1_request := t_rec_p1_request();
    BEGIN
        OPEN i_cursor FOR i_sql;
        LOOP
            FETCH i_cursor
                INTO l_res;
            EXIT WHEN i_cursor%NOTFOUND;
        
            out_rec.id_external_request      := l_res.id_external_request;
            out_rec.num_req                  := l_res.num_req;
            out_rec.flg_type                 := l_res.flg_type;
            out_rec.dt_requested             := l_res.dt_requested;
            out_rec.flg_status               := l_res.flg_status;
            out_rec.dt_status_tstz           := l_res.dt_status_tstz;
            out_rec.flg_priority             := l_res.flg_priority;
            out_rec.id_speciality            := l_res.id_speciality;
            out_rec.code_speciality          := l_res.code_speciality;
            out_rec.decision_urg_level       := l_res.decision_urg_level;
            out_rec.id_prof_requested        := l_res.id_prof_requested;
            out_rec.id_inst_orig             := l_res.id_inst_orig;
            out_rec.code_inst_orig           := l_res.code_inst_orig;
            out_rec.id_inst_dest             := l_res.id_inst_dest;
            out_rec.inst_dest_abbrev         := l_res.inst_dest_abbrev;
            out_rec.code_inst_dest           := l_res.code_inst_dest;
            out_rec.id_dep_clin_serv         := l_res.id_dep_clin_serv;
            out_rec.id_prof_redirected       := l_res.id_prof_redirected;
            out_rec.id_schedule              := l_res.id_schedule;
            out_rec.id_prof_schedule         := l_res.id_prof_schedule;
            out_rec.dt_schedule_tstz         := l_res.dt_schedule_tstz;
            out_rec.dt_efectiv_tstz          := l_res.dt_efectiv_tstz;
            out_rec.id_patient               := l_res.id_patient;
            out_rec.pat_name                 := l_res.pat_name;
            out_rec.pat_gender               := l_res.pat_gender;
            out_rec.dep_abbreviation         := l_res.dep_abbreviation;
            out_rec.code_department          := l_res.code_department;
            out_rec.code_clinical_service    := l_res.code_clinical_service;
            out_rec.id_match                 := l_res.id_match;
            out_rec.id_prof_status           := l_res.id_prof_status;
            out_rec.dt_issued                := l_res.dt_issued;
            out_rec.id_prof_triage           := l_res.id_prof_triage;
            out_rec.dt_triage                := l_res.dt_triage;
            out_rec.dt_forwarded             := l_res.dt_forwarded;
            out_rec.dt_acknowledge           := l_res.dt_acknowledge;
            out_rec.dt_new                   := l_res.dt_new;
            out_rec.dt_last_interaction_tstz := l_res.dt_last_interaction_tstz;
            out_rec.id_workflow              := l_res.id_workflow;
            out_rec.abbrev_inst_orig         := l_res.abbrev_inst_orig;
            out_rec.institution_name_roda    := l_res.institution_name_roda;
            out_rec.tr_dt_update             := l_res.tr_dt_update;
            out_rec.tr_id_prof_dest          := l_res.tr_id_prof_dest;
            out_rec.tr_id_prof_transf_owner  := l_res.tr_id_prof_transf_owner;
            out_rec.tr_id_status             := l_res.tr_id_status;
            out_rec.tr_id_trans_resp         := l_res.tr_id_trans_resp;
            out_rec.tr_id_workflow           := l_res.tr_id_workflow;
            out_rec.id_prof_orig             := l_res.id_prof_orig;
            out_rec.flg_migrated             := l_res.flg_migrated;
        
            PIPE ROW(out_rec);
        END LOOP;
    
        CLOSE i_cursor;
        RETURN;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_err_id PLS_INTEGER;
            BEGIN
                pk_alert_exceptions.register_error(error_name_in       => SQLERRM,
                                                   err_instance_id_out => l_err_id,
                                                   text_in             => g_error,
                                                   name1_in            => 'OWNER',
                                                   value1_in           => g_package_owner,
                                                   name2_in            => 'PACKAGE',
                                                   value2_in           => g_package_name,
                                                   name3_in            => 'FUNCTION',
                                                   value3_in           => 'GET_GRID_DATA');
                RETURN;
            END;
    END get_grid_data;

    /**
    * Gets the query for patient search
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   i_id_sys_btn_crit list of search criteria ids
    * @param   i_crit_val list of values for the criteria in  i_id_sys_btn_crit    
    * @param   i_condition query condition to add to the returned query        
    * @param   o_sql sql text
    * @param   o_error error message    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   27-05-2008
    */
    FUNCTION get_search_pat_sql
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        o_sql             OUT CLOB,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_limit           sys_config.value%TYPE;
        l_where           VARCHAR2(4000);
        l_from            VARCHAR2(4000);
        l_where_cond      VARCHAR2(4000);
        l_where_from      VARCHAR2(4000 CHAR);
        l_from_cond       VARCHAR2(4000);
        l_sns_id          health_plan.id_health_plan%TYPE;
        l_sc_multi_instit VARCHAR2(1 CHAR);
        l_inst_mk         market.id_market%TYPE;
        l_sql_int         CLOB;
    BEGIN
        ----------------------
        -- CONFIG
        ----------------------
        l_where  := NULL;
        l_from   := NULL;
        l_limit  := pk_ref_utils.get_sys_config(i_prof          => i_prof,
                                                i_id_sys_config => pk_ref_constant.g_sc_num_record_search);
        l_sns_id := pk_ref_utils.get_default_health_plan(i_prof => i_prof);
    
        l_sc_multi_instit := pk_ref_utils.get_sys_config(i_prof          => i_prof,
                                                         i_id_sys_config => pk_ref_constant.g_sc_multi_institution);
        l_inst_mk         := pk_utils.get_institution_market(i_lang => i_lang, i_id_institution => i_prof.institution);
    
        pk_context_api.set_parameter('i_lang', i_lang);
        pk_context_api.set_parameter('i_prof_id', i_prof.id);
        pk_context_api.set_parameter('i_prof_software', i_prof.software);
        pk_context_api.set_parameter('i_prof_institution', i_prof.institution);
        pk_context_api.set_parameter('i_sns_id', l_sns_id);
        pk_context_api.set_parameter('i_mk_id', l_inst_mk);
    
        ----------------------
        -- FUNC
        ----------------------
        FOR i IN 1 .. i_id_sys_btn_crit.count
        LOOP
        
            -- reads search criteria and fills where clause
            g_error      := 'SET WHERE';
            l_where_cond := NULL;
            l_from_cond  := NULL;
        
            IF i_id_sys_btn_crit(i) IS NOT NULL
            THEN
                pk_context_api.set_parameter('search_value', i_crit_val(i));
            
                IF i_id_sys_btn_crit(i) = pk_ref_constant.g_crit_pat_name_w
                THEN
                    pk_context_api.set_parameter('SEARCH_P236', i_crit_val(i));
                END IF;
            
                g_error  := 'Call pk_search.get_criteria_condition / i_id_sys_btn_crit(' || i || ')=' ||
                            i_id_sys_btn_crit(i);
                g_retval := pk_search.get_criteria_condition(i_lang           => i_lang,
                                                             i_prof           => i_prof,
                                                             i_id_criteria    => i_id_sys_btn_crit(i),
                                                             i_criteria_value => i_crit_val(i),
                                                             o_crit_condition => l_where_cond,
                                                             o_error          => o_error);
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                g_error  := 'Call pk_search.get_from_condition / i_id_sys_btn_crit(' || i || ')=' ||
                            i_id_sys_btn_crit(i);
                g_retval := pk_search.get_from_condition(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_id_criteria    => i_id_sys_btn_crit(i),
                                                         i_criteria_value => i_crit_val(i),
                                                         o_from_condition => l_from_cond,
                                                         o_error          => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                l_from := l_from || l_from_cond;
                IF l_from_cond IS NULL
                THEN
                    l_where := l_where || l_where_cond; -- to be applied directly in view
                ELSE
                    l_where_from := l_where_from || l_where_cond; -- to be applied outside the view (to the from tables)
                END IF;
            
            END IF;
        
        END LOOP;
    
        g_error := 'l_inst_mk=' || l_inst_mk;
        IF l_inst_mk = pk_ref_constant.g_market_pt -- PT ACSS
        THEN
        
            -- INTERNAL query
            l_sql_int := to_clob('SELECT  pat.id_patient');
            l_sql_int := l_sql_int || to_clob(',pat.gender');
            l_sql_int := l_sql_int || to_clob(',pat.dt_birth');
            l_sql_int := l_sql_int || to_clob(',php.num_health_plan');
        
            -- from tables
            l_sql_int := l_sql_int || to_clob(' FROM patient pat');
        
            -- pat_health_plan
            l_sql_int := l_sql_int || to_clob(' LEFT JOIN pat_health_plan php ON (pat.id_patient = php.id_patient AND php.id_health_plan =  sys_context(''ALERT_CONTEXT'', ''i_sns_id'') AND php.flg_status = ''' ||
                                              pk_ref_constant.g_active || ''' AND ');
            IF l_sc_multi_instit = pk_ref_constant.g_yes
            THEN
                l_sql_int := l_sql_int || to_clob(' php.id_institution = 0) ');
            ELSE
                l_sql_int := l_sql_int ||
                             to_clob(' php.id_institution  =  sys_context(''ALERT_CONTEXT'', ''i_prof_institution'')) ');
            END IF;
        
            -- applying where clauses to the internal query
            l_sql_int := to_clob('SELECT t.* FROM (' || l_sql_int || ' WHERE 1=1 ' || l_where || ' ) t ' || l_from ||
                                 ' WHERE rownum <=  ' || l_limit || ' +1 ' || l_where_from || ' ');
        
            -- EXTERNAL query
            -- joining all other tables (to return additional information)
            o_sql := to_clob('SELECT t.id_patient');
            o_sql := o_sql || to_clob(',t.gender');
            o_sql := o_sql || to_clob(',t.dt_birth');
            o_sql := o_sql || to_clob(',psa.address');
            o_sql := o_sql || to_clob(',psa.zip_code');
            o_sql := o_sql || to_clob(',psa.location');
            o_sql := o_sql || to_clob(',t.num_health_plan');
            o_sql := o_sql || to_clob(',cr.num_clin_record');
            o_sql := o_sql || to_clob(',NULL run_number');
        
            -- from tables
            o_sql := o_sql || to_clob(' FROM (' || l_sql_int || ') t');
            -- v_pat_soc_attributes
            o_sql := o_sql || to_clob(' LEFT JOIN v_pat_soc_attributes psa ON (t.id_patient = psa.id_patient AND ');
            IF l_sc_multi_instit = pk_ref_constant.g_yes
            THEN
                o_sql := o_sql || to_clob(' psa.id_institution = 0) ');
            ELSE
                o_sql := o_sql ||
                         to_clob(' psa.id_institution =  sys_context(''ALERT_CONTEXT'', ''i_prof_institution'')) ');
            END IF;
        
            -- clin_record
            o_sql := o_sql || to_clob(' LEFT JOIN clin_record cr ON (t.id_patient = cr.id_patient AND cr.id_institution = 
				sys_context(''ALERT_CONTEXT'', ''i_prof_institution'') AND cr.id_institution = cr.id_instit_enroled AND cr.flg_status = ''' ||
                                      pk_ref_constant.g_active || ''') ');
        
        ELSIF l_inst_mk = pk_ref_constant.g_market_cl
        THEN
        
            -- INTERNAL query
            l_sql_int := to_clob('SELECT  pat.id_patient');
            l_sql_int := l_sql_int || to_clob(',pat.gender');
            l_sql_int := l_sql_int || to_clob(',pat.dt_birth');
            l_sql_int := l_sql_int || to_clob(',pat.id_person');
            l_sql_int := l_sql_int || to_clob(',per.run_number');
        
            -- from tables
            l_sql_int := l_sql_int || to_clob(' FROM patient pat');
            --l_sql_int := l_sql_int || to_clob(' JOIN v_patient_cl pat_cl ON (pat.id_patient = pat_cl.id_patient_cl)');
            l_sql_int := l_sql_int || to_clob(' JOIN v_person per ON (pat.id_person = per.id_person)');
            -- applying where clauses to the internal query
            l_sql_int := to_clob('SELECT t.* FROM (' || l_sql_int || ' WHERE 1=1 ' || l_where || ' ) t ' || l_from ||
                                 ' WHERE rownum <=  ' || l_limit || ' +1 ' || l_where_from || ' ');
        
            -- EXTERNAL query
            -- joining all other tables (to return additional information)
            o_sql := to_clob('SELECT t.id_patient');
            o_sql := o_sql || to_clob(',t.gender');
            o_sql := o_sql || to_clob(',t.dt_birth');
            o_sql := o_sql || to_clob(',v_cl.address_line1 address');
            o_sql := o_sql || to_clob(',v_cl.postal_code zip_code');
            o_sql := o_sql || to_clob(',v_cl.code_city location');
            o_sql := o_sql || to_clob(',NULL num_health_plan');
            o_sql := o_sql || to_clob(',cr.num_clin_record');
            o_sql := o_sql || to_clob(',t.run_number');
        
            -- from tables
            o_sql := o_sql || to_clob(' FROM (' || l_sql_int || ') t');
            -- v_contact_address_cl
            o_sql := o_sql || to_clob(' LEFT JOIN v_contact_address_cl v_cl ON (t.id_person = v_cl.id_contact_entity and  v_cl.flg_main_address = ''' ||
                                      pk_ref_constant.g_yes || ''')');
            -- clin_record
            o_sql := o_sql || to_clob(' LEFT JOIN clin_record cr ON (t.id_patient = cr.id_patient AND cr.id_institution = 
				sys_context(''ALERT_CONTEXT'', ''i_prof_institution'') AND cr.id_institution = cr.id_instit_enroled AND cr.flg_status = ''' ||
                                      pk_ref_constant.g_active || ''') ');
        
        ELSIF l_inst_mk = pk_ref_constant.g_market_mx
        THEN
        
            -- INTERNAL query
            l_sql_int := to_clob('SELECT  pat.id_patient');
            l_sql_int := l_sql_int || to_clob(',pat.gender');
            l_sql_int := l_sql_int || to_clob(',pat.dt_birth');
            l_sql_int := l_sql_int || to_clob(',pat.id_person');
            l_sql_int := l_sql_int || to_clob(',per.social_security_number run_number');
        
            -- from tables
            l_sql_int := l_sql_int || to_clob(' FROM patient pat');
            --l_sql_int := l_sql_int || to_clob(' JOIN v_patient_cl pat_cl ON (pat.id_patient = pat_cl.id_patient_cl)');
            l_sql_int := l_sql_int || to_clob(' JOIN v_person per ON (pat.id_person = per.id_person)');
            -- applying where clauses to the internal query
            l_sql_int := to_clob('SELECT pat.* FROM (' || l_sql_int || ' WHERE 1=1 ' || l_where || ' ) pat ' || l_from ||
                                 ' WHERE rownum <=  ' || l_limit || ' +1 ' || l_where_from || ' ');
        
            -- EXTERNAL query
            -- joining all other tables (to return additional information)
            o_sql := to_clob('SELECT t.id_patient');
            o_sql := o_sql || to_clob(',t.gender');
            o_sql := o_sql || to_clob(',t.dt_birth');
            o_sql := o_sql || to_clob(',null address');
            o_sql := o_sql || to_clob(',null zip_code');
            o_sql := o_sql || to_clob(',null location');
            o_sql := o_sql || to_clob(',NULL num_health_plan');
            o_sql := o_sql || to_clob(',cr.num_clin_record');
            o_sql := o_sql || to_clob(',t.run_number');
        
            -- from tables
            o_sql := o_sql || to_clob(' FROM (' || l_sql_int || ') t');
        
            -- v_contact_address
            --o_sql := o_sql || to_clob(' LEFT JOIN v_contact_address v_mx ON (t.id_person = v_mx.id_contact_entity and  v_mx.flg_main_address = ''' ||
            --                          pk_ref_constant.g_yes || ''')');
        
            -- clin_record
            o_sql := o_sql || to_clob(' LEFT JOIN clin_record cr ON (t.id_patient = cr.id_patient AND cr.id_institution = 
				sys_context(''ALERT_CONTEXT'', ''i_prof_institution'') AND cr.id_institution = cr.id_instit_enroled AND cr.flg_status = ''' ||
                                      pk_ref_constant.g_active || ''') ');
        ELSE
            -- Demos
        
            -- INTERNAL query               
            l_sql_int := to_clob('SELECT /**/ pat.id_patient');
            l_sql_int := l_sql_int || to_clob(',pat.gender');
            l_sql_int := l_sql_int || to_clob(',pat.dt_birth');
            l_sql_int := l_sql_int || to_clob(',pat.id_person');
            l_sql_int := l_sql_int || to_clob(',php.num_health_plan');
            l_sql_int := l_sql_int || to_clob(',per.social_security_number run_number');
        
            -- from tables
            l_sql_int := l_sql_int || to_clob(' FROM patient pat');
            -- l_sql_int := l_sql_int || to_clob(' JOIN patient_us pat_us ON (pat.id_patient = pat_us.id_patient_us)');
            l_sql_int := l_sql_int || to_clob(' JOIN v_person per ON (pat.id_person = per.id_person) ');
        
            -- pat_health_plan
            l_sql_int := l_sql_int || to_clob(' LEFT JOIN pat_health_plan php ON (pat.id_patient = php.id_patient AND php.id_health_plan =  sys_context(''ALERT_CONTEXT'', ''i_sns_id'') AND php.flg_status = ''' ||
                                              pk_ref_constant.g_active || ''' AND ');
        
            IF l_sc_multi_instit = pk_ref_constant.g_yes
            THEN
                l_sql_int := l_sql_int || to_clob(' php.id_institution = 0) ');
            ELSE
                l_sql_int := l_sql_int ||
                             to_clob(' php.id_institution  =  sys_context(''ALERT_CONTEXT'', ''i_prof_institution'')) ');
            END IF;
        
            -- applying where clauses to the internal query
            l_sql_int := to_clob('SELECT pat.* FROM (' || l_sql_int ||
                                 ' WHERE 1=1 AND pat.institution_key IN (SELECT ig.id_institution
                                         FROM institution_group ig
                                        WHERE ig.flg_relation = ''ADT''
                                          AND id_group IN (SELECT id_group
                                                             FROM institution_group igi
                                                            WHERE igi.flg_relation = ''ADT''
                                                              AND igi.id_institution = sys_context(''ALERT_CONTEXT'', ''i_prof_institution''))) ' ||
                                 l_where || ' ) pat ' || l_from || ' WHERE rownum <=  ' || l_limit || ' +1 ' ||
                                 l_where_from || ' ');
            pk_alertlog.log_error('l_sql_int: ' || l_sql_int);
        
            -- EXTERNAL query
            -- joining all other tables (to return additional information)
            o_sql := to_clob('SELECT t.id_patient');
            o_sql := o_sql || to_clob(',t.gender');
            o_sql := o_sql || to_clob(',t.dt_birth');
            o_sql := o_sql || to_clob(',v_us.address_line1 address');
            o_sql := o_sql || to_clob(',v_us.postal_code  zip_code');
            o_sql := o_sql || to_clob(',v_us.city_us location');
            o_sql := o_sql || to_clob(',t.num_health_plan');
            o_sql := o_sql || to_clob(',cr.num_clin_record');
            o_sql := o_sql || to_clob(',t.run_number');
        
            -- from tables
            o_sql := o_sql || to_clob(' FROM (' || l_sql_int || ') t');
            o_sql := o_sql || to_clob(' LEFT JOIN v_contact_address_us v_us ON (t.id_person = v_us.id_contact_entity)');
            o_sql := o_sql || to_clob(' LEFT JOIN clin_record cr ON (t.id_patient = cr.id_patient AND cr.id_institution = 
				sys_context(''ALERT_CONTEXT'', ''i_prof_institution'') AND cr.id_institution = cr.id_instit_enroled AND cr.flg_status = ''' ||
                                      pk_ref_constant.g_active || ''') ');
        
        END IF;
    
        pk_ref_utils.log_clob(o_sql);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_SEARCH_PAT_SQL',
                                                     o_error    => o_error);
    END get_search_pat_sql;

    /**
    * Pipelined function to return the data for the query provided
    *
    * @param   i_sql sql code (as returned by get_req_search_sql)
    *
    * @RETURN  t_coll_ref_search record
    * @author  Joao Sa
    * @version 1.0
    * @since   27-05-2008
    */
    FUNCTION get_search_pat_data(i_sql CLOB) RETURN t_coll_ref_search
        PIPELINED IS
        out_rec  t_rec_ref_search := t_rec_ref_search();
        l_cursor pk_types.cursor_type;
    BEGIN
    
        OPEN l_cursor FOR i_sql;
        LOOP
            FETCH l_cursor
                INTO out_rec.id_patient,
                     out_rec.pat_gender,
                     out_rec.pat_dt_birth,
                     out_rec.pat_address,
                     out_rec.pat_zip_code,
                     out_rec.pat_location,
                     out_rec.pat_num_sns,
                     out_rec.pat_num_clin_record,
                     out_rec.run_number;
            EXIT WHEN l_cursor%NOTFOUND;
            PIPE ROW(out_rec);
        END LOOP;
        CLOSE l_cursor;
        RETURN;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_err_id PLS_INTEGER;
            BEGIN
                pk_alert_exceptions.register_error(error_name_in       => SQLERRM,
                                                   err_instance_id_out => l_err_id,
                                                   text_in             => g_error,
                                                   name1_in            => 'OWNER',
                                                   value1_in           => g_package_owner,
                                                   name2_in            => 'PACKAGE',
                                                   value2_in           => g_package_name,
                                                   name3_in            => 'FUNCTION',
                                                   value3_in           => 'GET_SEARCH_PAT_DATA');
                RETURN;
            END;
    END get_search_pat_data;

    /**
    * Gets the query for requests search
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof            Professional, institution and software ids
    * @param   i_crit_id_tab     List of search criteria identifiers
    * @param   i_crit_val_tab    List of values for the criteria in i_crit_id_tab            
    * @param   i_pt profile template id for the user    
    * @param   o_sql sql text
    * @param   o_error error message    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   27-05-2008
    */
    FUNCTION get_search_ref_sql
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_crit_id_tab  IN table_number,
        i_crit_val_tab IN table_varchar,
        i_pt           IN profile_template.id_profile_template%TYPE,
        o_sql          OUT CLOB,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_crit_id_tab     table_number;
        l_crit_val_tab    table_varchar;
        l_leading_tab_exp VARCHAR2(1000 CHAR);
    BEGIN
        ----------------------
        -- FUNC
        ----------------------
        l_crit_id_tab  := i_crit_id_tab;
        l_crit_val_tab := i_crit_val_tab;
    
        CASE
        --PT
            WHEN i_pt IN (pk_ref_constant.g_profile_med_cs,
                          pk_ref_constant.g_profile_med_cs_br,
                          pk_ref_constant.g_profile_med_cs_cl) THEN
            
                -- performance issues (ALERT-278126)
                -- instead of using criteria pk_ref_constant.g_crit_ref_orig_req, set this conditions in the leading table
            
                -- All of my institution                
                l_leading_tab_exp := 'SELECT exr1.* FROM referral_ea exr1 WHERE EXISTS';
                l_leading_tab_exp := l_leading_tab_exp ||
                                     ' (SELECT 1 FROM referral_ea exr1a WHERE exr1a.id_patient = exr1.id_patient AND exr1a.id_prof_requested = ' ||
                                     i_prof.institution || ')';
                --l_leading_tab_exp := l_leading_tab_exp || ' AND rownum > 0';
            
                -- or all of my patients
                l_leading_tab_exp := l_leading_tab_exp || ' UNION';
                l_leading_tab_exp := l_leading_tab_exp || ' SELECT exr2.* FROM referral_ea exr2 WHERE ';
                l_leading_tab_exp := l_leading_tab_exp || ' exr2.id_inst_orig =' || i_prof.institution;
                l_leading_tab_exp := l_leading_tab_exp || ' AND (exr2.id_workflow IS NULL OR exr2.id_workflow != 4) ';
                --l_leading_tab_exp := l_leading_tab_exp || ' AND rownum > 0';
        
        --l_crit_id_tab.extend;
        --l_crit_val_tab.extend;
        --l_crit_id_tab(l_crit_id_tab.last) := pk_ref_constant.g_crit_ref_orig_req;
        --l_crit_val_tab(l_crit_val_tab.last) := i_prof.institution;
        
            WHEN i_pt IN (pk_ref_constant.g_profile_adm_cs,
                          pk_ref_constant.g_profile_adm_cs_vo,
                          pk_ref_constant.g_profile_adm_cs_br,
                          pk_ref_constant.g_profile_adm_cs_cl) THEN
            
                -- All of my institution                
                l_crit_id_tab.extend;
                l_crit_val_tab.extend;
                l_crit_id_tab(l_crit_id_tab.last) := pk_ref_constant.g_crit_id_inst_orig;
                l_crit_val_tab(l_crit_val_tab.last) := i_prof.institution;
            
            WHEN i_pt IN (pk_ref_constant.g_profile_adm_hs,
                          pk_ref_constant.g_profile_adm_hs_vo,
                          pk_ref_constant.g_profile_adm_hs_cl) THEN
            
                -- workflows: dest or orig
                l_crit_id_tab.extend;
                l_crit_val_tab.extend;
                l_crit_id_tab(l_crit_id_tab.last) := pk_ref_constant.g_crit_id_inst_orig_dest;
                l_crit_val_tab(l_crit_val_tab.last) := i_prof.institution;
            
            WHEN i_pt IN (pk_ref_constant.g_profile_med_hs, pk_ref_constant.g_profile_med_hs_cl) THEN
            
                -- performance issues (ALERT-278126)
                -- instead of using criteria pk_ref_constant.g_crit_id_inst_group, set this conditions in the leading table
            
                -- Origin institution within the same institution group
                l_leading_tab_exp := 'SELECT exr1.* FROM referral_ea exr1 WHERE exr1.id_inst_dest IN ';
                l_leading_tab_exp := l_leading_tab_exp ||
                                     ' (SELECT /*+opt_estimate(table tbl rows=1)*/ tbl.column_value FROM TABLE(CAST(pk_ref_core.get_sibling_inst(' ||
                                     i_prof.institution || ', ''' || pk_ref_constant.g_yes ||
                                     ''') AS table_number)) tbl)';
                --l_leading_tab_exp := l_leading_tab_exp || ' AND rownum > 0';
            
                -- or dest institution within the same institution group
                l_leading_tab_exp := l_leading_tab_exp || ' UNION';
                l_leading_tab_exp := l_leading_tab_exp ||
                                     ' SELECT exr2.* FROM referral_ea exr2 WHERE exr2.id_inst_orig IN ';
                l_leading_tab_exp := l_leading_tab_exp ||
                                     ' (SELECT /*+opt_estimate(table tbl rows=1)*/ tbl.column_value FROM TABLE(CAST(pk_ref_core.get_sibling_inst(' ||
                                     i_prof.institution || ', ''' || pk_ref_constant.g_yes ||
                                     ''') AS table_number)) tbl)';
                --l_leading_tab_exp := l_leading_tab_exp || ' AND rownum > 0';
        
        --l_crit_id_tab.extend;
        --l_crit_val_tab.extend;
        --l_crit_id_tab(l_crit_id_tab.last) := pk_ref_constant.g_crit_id_inst_group;
        --l_crit_val_tab(l_crit_val_tab.last) := i_prof.institution;
        
            WHEN i_pt = pk_ref_constant.g_profile_planner THEN
            
                -- Circle UK
                l_crit_id_tab.extend;
                l_crit_val_tab.extend;
                l_crit_id_tab(l_crit_id_tab.last) := pk_ref_constant.g_crit_id_inst_dest;
                l_crit_val_tab(l_crit_val_tab.last) := i_prof.institution;
            
            ELSE
                g_error := 'CASE ' || i_pt || ' / i_prof=' || pk_utils.to_string(i_prof);
                RAISE g_exception;
        END CASE;
    
        -- search with all criterias specified
        g_error  := 'Call get_search_ref_sql_base / i_crit_id_tab=' || pk_utils.to_string(l_crit_id_tab);
        g_retval := get_search_ref_sql_base(i_lang            => i_lang,
                                            i_prof            => i_prof,
                                            i_crit_id_tab     => l_crit_id_tab,
                                            i_crit_val_tab    => l_crit_val_tab,
                                            i_leading_tab_exp => l_leading_tab_exp,
                                            o_sql             => o_sql,
                                            o_error           => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        --pk_ref_utils.log_clob(o_sql);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_SEARCH_REF_SQL',
                                                     o_error    => o_error);
    END get_search_ref_sql;

    /**
    * Gets the query source to search for referrals
    *
    * @param   i_lang             Language associated to the professional executing the request
    * @param   i_prof             Professional id, institution and software
    * @param   i_id_market        Market identifier
    * @param   i_leading_tab_exp  Leading table expression to be used (because of performance issues)
    * @param   i_leading_table    Leading table to be used (because of performance issues). Used only if i_leading_tab_exp is null    
    * @param   l_where            Where clause to be set if i_leading_table is used
    
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   i_id_sys_btn_crit list of search criteria ids
    * @param   i_crit_val list of values for the criteria in  i_id_sys_btn_crit    
    * @param   i_condition query condition to add to the returned query        
    * @param   i_pt profile template id for the user    
    
    
    * @param   o_sql sql text
    * @param   o_error error message    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   30-01-2013
    */
    FUNCTION get_search_ref_int_query
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_market       IN market.id_market%TYPE,
        i_leading_tab_exp IN VARCHAR2 DEFAULT NULL,
        i_leading_table   IN VARCHAR2,
        i_where           IN VARCHAR2
    ) RETURN CLOB IS
        l_result          CLOB;
        l_sc_multi_instit VARCHAR2(1 CHAR);
        l_params          VARCHAR2(1000 CHAR);
    BEGIN
        l_params          := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_market=' || i_id_market ||
                             ' substr(i_leading_tab_exp,1,200)=' || substr(i_leading_tab_exp, 1, 200) ||
                             ' i_leading_table=' || i_leading_table;
        g_error           := 'Init get_search_ref_int_query / ' || l_params;
        l_sc_multi_instit := pk_ref_utils.get_sys_config(i_prof          => i_prof,
                                                         i_id_sys_config => pk_ref_constant.g_sc_multi_institution);
    
        -- columns applicable to all markets
        l_result := to_clob('SELECT exr.id_external_request');
        l_result := l_result || to_clob(',exr.num_req');
        l_result := l_result || to_clob(',exr.flg_type');
        l_result := l_result || to_clob(',exr.id_speciality');
        l_result := l_result ||
                    to_clob(',''P1_SPECIALITY.CODE_SPECIALITY.'' || to_char(exr.id_speciality) code_speciality');
        l_result := l_result || to_clob(',exr.id_inst_orig');
        l_result := l_result || to_clob(',exr.id_inst_dest');
        l_result := l_result || to_clob(',exr.id_prof_redirected');
        l_result := l_result || to_clob(',exr.id_prof_status');
        l_result := l_result || to_clob(',exr.flg_status');
        l_result := l_result || to_clob(',exr.dt_status');
        l_result := l_result || to_clob(',exr.flg_priority');
        l_result := l_result || to_clob(',exr.decision_urg_level');
        l_result := l_result || to_clob(',exr.id_schedule');
        l_result := l_result || to_clob(',exr.dt_schedule');
        l_result := l_result || to_clob(',pat.id_patient');
        l_result := l_result || to_clob(',pat.gender');
        l_result := l_result || to_clob(',cr.num_clin_record');
        l_result := l_result || to_clob(',exr.id_prof_requested');
        l_result := l_result || to_clob(',exr.id_prof_orig');
        l_result := l_result || to_clob(',exr.institution_name_roda');
        l_result := l_result || to_clob(',exr.id_workflow');
        l_result := l_result || to_clob(',exr.id_external_sys');
        l_result := l_result || to_clob(',exr.id_prof_triage');
        l_result := l_result || to_clob(',exr.id_dep_clin_serv');
        l_result := l_result || to_clob(',exr.id_prof_sch_sugg');
    
        g_error := 'CASE i_id_market / ' || l_params;
        CASE i_id_market
            WHEN pk_ref_constant.g_market_cl THEN
            
                l_result := l_result || to_clob(',per.run_number');
            WHEN pk_ref_constant.g_market_mx THEN
            
                l_result := l_result || to_clob(',per.social_security_number run_number');
            ELSE
                -- PT ACSS and others
                l_result := l_result || to_clob(',null run_number');
        END CASE;
    
        -- from tables applicable to all markets
        IF i_leading_tab_exp IS NOT NULL
        THEN
            -- this leading expression is related to referral_ea only
            l_result := l_result || to_clob(' FROM (' || i_leading_tab_exp || ') exr');
            l_result := l_result || to_clob(' JOIN patient pat ON (pat.id_patient = exr.id_patient)');
        ELSE
            g_error := 'CASE i_leading_table / ' || l_params;
            CASE i_leading_table
                WHEN g_leading_table_ref THEN
                    l_result := l_result || to_clob(' FROM (SELECT * FROM REFERRAL_EA exr WHERE 1=1 ' || i_where ||
                                                    ' AND ROWNUM > 0) exr');
                    l_result := l_result || to_clob(' JOIN patient pat ON (pat.id_patient = exr.id_patient)');
                WHEN g_leading_table_pat THEN
                    l_result := l_result || to_clob(' FROM (SELECT * FROM patient pat WHERE 1=1 ' || i_where ||
                                                    ' AND ROWNUM > 0) pat');
                    l_result := l_result || to_clob(' JOIN referral_ea exr ON (pat.id_patient = exr.id_patient)');
                ELSE
                    l_result := l_result || to_clob(' FROM patient pat');
                    l_result := l_result || to_clob(' JOIN referral_ea exr ON (pat.id_patient = exr.id_patient)');
            END CASE;
        END IF;
    
        l_result := l_result || to_clob(' LEFT JOIN clin_record cr ON (pat.id_patient = cr.id_patient AND cr.id_institution = sys_context(''ALERT_CONTEXT'', ''i_prof_institution'') AND cr.id_institution = cr.id_instit_enroled AND cr.flg_status = ''' ||
                                        pk_ref_constant.g_active || ''')');
    
        g_error := 'CASE i_id_market 2 / ' || l_params;
        CASE i_id_market
            WHEN pk_ref_constant.g_market_cl THEN
                -- l_result := l_result || to_clob(' JOIN v_patient_cl pat_cl ON (pat.id_patient = pat_cl.id_patient_cl)');
                l_result := l_result || to_clob(' JOIN v_person per ON (pat.id_person = per.id_person)');
            
            WHEN pk_ref_constant.g_market_mx THEN
                l_result := l_result || to_clob(' JOIN v_person per ON (pat.id_person = per.id_person)');
            
            ELSE
            
                -- pat_health_plan
                l_result := l_result || to_clob(' LEFT JOIN pat_health_plan php ON (pat.id_patient = php.id_patient AND
                                   php.id_health_plan =  sys_context(''ALERT_CONTEXT'', ''i_sns_id'')
                              AND PHP.FLG_STATUS = ''' ||
                                                pk_ref_constant.g_active || ''' AND ');
            
                IF l_sc_multi_instit = pk_ref_constant.g_yes
                THEN
                    l_result := l_result || to_clob(' php.id_institution = 0) ');
                ELSE
                    l_result := l_result ||
                                to_clob(' php.id_institution  = sys_context(''ALERT_CONTEXT'', ''i_prof_institution'')) ');
                END IF;
        END CASE;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error);
            RETURN NULL;
    END get_search_ref_int_query;

    /**
    * Gets the query for referral search (no criteria hard coded)
    *
    * @param   i_lang             Language associated to the professional executing the request
    * @param   i_prof             Professional id, institution and software
    * @param   i_crit_id_tab      List of search criteria identifiers
    * @param   i_crit_val_tab     List of values for the criteria in i_crit_id_tab                
    * @param   i_leading_tab_exp  Leading table expression to be used (because of performance issues)
    * @param   o_sql              Sql text
    * @param   o_error            Error message    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   29-01-2013
    */
    FUNCTION get_search_ref_sql_base
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_crit_id_tab     IN table_number,
        i_crit_val_tab    IN table_varchar,
        i_leading_tab_exp IN VARCHAR2 DEFAULT NULL,
        o_sql             OUT CLOB,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_limit          sys_config.value%TYPE;
        l_leading_table  VARCHAR2(10 CHAR);
        l_where_ref      VARCHAR2(4000 CHAR);
        l_where_pat      VARCHAR2(4000 CHAR);
        l_where_other    VARCHAR2(4000 CHAR);
        l_where_from     VARCHAR2(4000 CHAR);
        l_where_cond     VARCHAR2(4000 CHAR);
        l_from           VARCHAR2(4000 CHAR);
        l_from_cond      VARCHAR2(2000 CHAR);
        l_sns_id         health_plan.id_health_plan%TYPE;
        l_sns_content_id health_plan.id_content%TYPE;
        l_inst_mk        market.id_market%TYPE;
        l_params         VARCHAR2(1000 CHAR);
        l_src_view       CLOB;
        l_sql_int        CLOB;
        l_crit_type      VARCHAR2(50 CHAR);
    
        FUNCTION get_criteria_type(i_id_criteria IN criteria.id_criteria%TYPE) RETURN VARCHAR2 IS
            l_result VARCHAR2(50 CHAR); -- PATIENT/REFERRAL/OTHER
        BEGIN
        
            IF i_id_criteria IN (pk_ref_constant.g_crit_flg_status,
                                 pk_ref_constant.g_crit_id_ref,
                                 pk_ref_constant.g_crit_id_spec,
                                 pk_ref_constant.g_crit_dt_requested,
                                 pk_ref_constant.g_crit_dt_requested_sup,
                                 pk_ref_constant.g_crit_dt_requested_inf,
                                 pk_ref_constant.g_crit_id_inst,
                                 pk_ref_constant.g_crit_ref_flg_type,
                                 pk_ref_constant.g_crit_id_prof_req,
                                 pk_ref_constant.g_crit_ref_orig_req,
                                 pk_ref_constant.g_crit_id_inst_orig,
                                 pk_ref_constant.g_crit_id_inst_orig_dest,
                                 pk_ref_constant.g_crit_id_inst_group,
                                 pk_ref_constant.g_crit_id_inst_dest,
                                 pk_ref_constant.g_crit_dt_requested_tstz_sup,
                                 pk_ref_constant.g_crit_dt_requested_tstz_inf)
            THEN
                l_result := g_leading_table_ref;
            ELSIF i_id_criteria IN (pk_ref_constant.g_crit_pat_dt_birth,
                                    pk_ref_constant.g_crit_pat_gender,
                                    pk_ref_constant.g_crit_pat_sns)
            THEN
                l_result := g_leading_table_pat;
            ELSE
                l_result := g_leading_table_other;
            END IF;
        
            RETURN l_result;
        END get_criteria_type;
    
    BEGIN
        l_params      := 'i_prof=' || pk_utils.to_string(i_prof);
        g_error       := 'Init get_search_ref_sql_base / ' || l_params;
        l_where_from  := NULL;
        l_from        := NULL;
        l_where_ref   := NULL;
        l_where_pat   := NULL;
        l_where_other := NULL;
    
        ----------------------
        -- CONFIG
        ----------------------
        l_limit   := pk_ref_utils.get_sys_config(i_prof          => i_prof,
                                                 i_id_sys_config => pk_ref_constant.g_sc_num_record_search);
        l_sns_id  := pk_ref_utils.get_default_health_plan(i_prof => i_prof);
        l_inst_mk := pk_utils.get_institution_market(i_lang => i_lang, i_id_institution => i_prof.institution);
    
        pk_context_api.set_parameter('i_lang', i_lang);
        pk_context_api.set_parameter('i_prof_id', i_prof.id);
        pk_context_api.set_parameter('i_prof_software', i_prof.software);
        pk_context_api.set_parameter('i_prof_institution', i_prof.institution);
        pk_context_api.set_parameter('i_prof_mk', l_inst_mk);
        pk_context_api.set_parameter('i_mk_id', l_inst_mk);
        pk_context_api.set_parameter('i_sns_id', l_sns_id);
        l_params := l_params || ' l_sns_id=' || l_sns_id || ' l_inst_mk=' || l_inst_mk;
    
        ----------------------
        -- FUNC
        ---------------------- 
        FOR i IN 1 .. i_crit_id_tab.count
        LOOP
            l_where_cond := NULL;
        
            IF i_crit_id_tab(i) IS NOT NULL
            THEN
                pk_context_api.set_parameter('search_value', i_crit_val_tab(i));
            
                IF i_crit_id_tab(i) = pk_ref_constant.g_crit_pat_name_w
                THEN
                    pk_context_api.set_parameter('SEARCH_P236', i_crit_val_tab(i));
                END IF;
            
                g_error  := 'Call pk_search.get_criteria_condition / i_crit_id_tab(' || i || ')=' || i_crit_id_tab(i);
                g_retval := pk_search.get_criteria_condition(i_lang           => i_lang,
                                                             i_prof           => i_prof,
                                                             i_id_criteria    => i_crit_id_tab(i),
                                                             i_criteria_value => i_crit_val_tab(i),
                                                             o_crit_condition => l_where_cond,
                                                             o_error          => o_error);
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                g_error  := 'Call pk_search.get_from_condition / i_crit_id_tab(' || i || ')=' || i_crit_id_tab(i) ||
                            ' / ' || l_params;
                g_retval := pk_search.get_from_condition(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_id_criteria    => i_crit_id_tab(i),
                                                         i_criteria_value => i_crit_val_tab(i),
                                                         o_from_condition => l_from_cond,
                                                         o_error          => o_error);
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                l_from := l_from || l_from_cond;
                IF l_from_cond IS NULL -- to be applied directly in view
                THEN
                    -- check type of criteria (referral, patient or other) IF i_leading_tab_exp is not used                   
                    IF i_leading_tab_exp IS NULL
                    THEN
                        g_error     := 'Call get_criteria_type / i_crit_id_tab(' || i || ')=' || i_crit_id_tab(i) ||
                                       ' / ' || l_params;
                        l_crit_type := get_criteria_type(i_id_criteria => i_crit_id_tab(i));
                    END IF;
                
                    g_error := 'CASE l_crit_type / l_crit_type=' || l_crit_type || ' i_crit_id_tab(' || i || ')=' ||
                               i_crit_id_tab(i) || ' / ' || l_params;
                    CASE l_crit_type
                        WHEN g_leading_table_ref THEN
                            -- referral criteria
                            l_where_ref := l_where_ref || l_where_cond;
                        WHEN g_leading_table_pat THEN
                            -- patient criteria
                            l_where_pat := l_where_pat || l_where_cond;
                        ELSE
                            l_where_other := l_where_other || l_where_cond;
                    END CASE;
                
                ELSE
                    l_where_from := l_where_from || l_where_cond; -- to be applied outside the view (to the from tables)
                END IF;
            
                g_error := 'Leading table / i_crit_id_tab(' || i || ')=' || i_crit_id_tab(i) || ' / ' || l_params;
                IF i_crit_id_tab(i) = pk_ref_constant.g_crit_pat_sns
                THEN
                    l_leading_table := g_leading_table_pat;
                ELSE
                    l_leading_table := g_leading_table_ref;
                END IF;
            
            END IF;
        END LOOP;
    
        g_error := 'l_leading_table / ' || l_params;
        CASE l_leading_table
            WHEN g_leading_table_ref THEN
                -- getting query source depending on market
                g_error    := 'l_src_view / ' || l_params;
                l_src_view := get_search_ref_int_query(i_lang            => i_lang,
                                                       i_prof            => i_prof,
                                                       i_id_market       => l_inst_mk,
                                                       i_leading_tab_exp => i_leading_tab_exp,
                                                       i_leading_table   => l_leading_table,
                                                       i_where           => l_where_ref);
            
                -- l_src_view already has 'l_where_ref' where clauses
                l_sql_int := to_clob('SELECT pat.* FROM (' || l_src_view || ' WHERE 1=1 ' || l_where_pat ||
                                     l_where_other || ' ) pat ' || l_from || ' WHERE rownum <=  ' || l_limit || ' +1 ' ||
                                     l_where_from || ' ');
            
            WHEN g_leading_table_pat THEN
            
                -- getting query source depending on market
                g_error    := 'l_src_view / ' || l_params;
                l_src_view := get_search_ref_int_query(i_lang            => i_lang,
                                                       i_prof            => i_prof,
                                                       i_id_market       => l_inst_mk,
                                                       i_leading_tab_exp => i_leading_tab_exp,
                                                       i_leading_table   => l_leading_table,
                                                       i_where           => l_where_pat);
            
                -- l_src_view already has 'l_where_pat' where clauses
                l_sql_int := to_clob('SELECT t.* FROM (' || l_src_view || ' WHERE 1=1 ' || l_where_ref || l_where_other ||
                                     ' ) t ' || l_from || ' WHERE rownum <=  ' || l_limit || ' +1 ' || l_where_from || ' ');
            
            ELSE
                -- getting query source depending on market
                g_error    := 'l_src_view / ' || l_params;
                l_src_view := get_search_ref_int_query(i_lang            => i_lang,
                                                       i_prof            => i_prof,
                                                       i_id_market       => l_inst_mk,
                                                       i_leading_tab_exp => i_leading_tab_exp,
                                                       i_leading_table   => l_leading_table,
                                                       i_where           => NULL);
            
                l_sql_int := to_clob('SELECT t.* FROM (' || l_src_view || ' WHERE 1=1 ' || l_where_ref || l_where_pat ||
                                     l_where_other || ' ) t ' || l_from || ' WHERE rownum <=  ' || l_limit || ' +1 ' ||
                                     l_where_from || ' ');
            
        END CASE;
    
        -- adding other referral/patient data
        o_sql := to_clob('SELECT te.id_external_request');
        o_sql := o_sql || to_clob(',te.num_req');
        o_sql := o_sql || to_clob(',te.flg_type');
        o_sql := o_sql || to_clob(',te.id_speciality');
        o_sql := o_sql || to_clob(',te.code_speciality');
        o_sql := o_sql || to_clob(',te.id_inst_orig');
        o_sql := o_sql || to_clob(',ist_orig.code_institution code_inst_orig');
        o_sql := o_sql || to_clob(',ist_orig.abbreviation abbrev_inst_orig');
        o_sql := o_sql || to_clob(',te.institution_name_roda');
        o_sql := o_sql || to_clob(',te.id_inst_dest');
        o_sql := o_sql || to_clob(',ist_dest.code_institution code_inst_dest');
        o_sql := o_sql || to_clob(',ist_dest.abbreviation inst_dest_abbrev');
        o_sql := o_sql || to_clob(',''DEPARTMENT.CODE_DEPARTMENT.'' || to_char(dcs.id_department) code_department');
        o_sql := o_sql ||
                 to_clob(',''CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.'' || to_char(dcs.id_clinical_service) code_clinical_service');
        o_sql := o_sql || to_clob(',dcs.id_dep_clin_serv');
        o_sql := o_sql || to_clob(',te.id_prof_redirected');
        o_sql := o_sql || to_clob(',te.id_prof_status');
        o_sql := o_sql || to_clob(',te.flg_status');
        o_sql := o_sql || to_clob(',te.dt_status dt_status_tstz');
        o_sql := o_sql || to_clob(',te.flg_priority');
        o_sql := o_sql || to_clob(',te.decision_urg_level');
        o_sql := o_sql || to_clob(',sch.id_schedule');
        o_sql := o_sql || to_clob(',sch.dt_begin_tstz dt_schedule_tstz');
        o_sql := o_sql || to_clob(',te.id_patient');
        o_sql := o_sql || to_clob(',te.gender pat_gender');
        o_sql := o_sql || to_clob(',m.sequential_number');
        o_sql := o_sql || to_clob(',te.id_prof_requested');
        o_sql := o_sql || to_clob(',te.id_prof_orig'); -- id_prof_roda
        o_sql := o_sql || to_clob(',te.id_workflow');
        o_sql := o_sql || to_clob(',m.id_match');
        o_sql := o_sql || to_clob(',te.id_external_sys');
        o_sql := o_sql || to_clob(',NULL rut');
        o_sql := o_sql || to_clob(',te.run_number');
        o_sql := o_sql || to_clob(',te.id_prof_triage');
        o_sql := o_sql || to_clob(',te.id_prof_sch_sugg');
    
        o_sql := o_sql || to_clob(' FROM (' || l_sql_int || ') te');
        o_sql := o_sql || to_clob(' JOIN institution ist_orig ON (te.id_inst_orig = ist_orig.id_institution)');
        o_sql := o_sql || to_clob(' LEFT JOIN institution ist_dest ON (te.id_inst_dest = ist_dest.id_institution)');
        o_sql := o_sql || to_clob(' LEFT JOIN dep_clin_serv dcs ON (te.id_dep_clin_serv = dcs.id_dep_clin_serv)');
        --AND EXR.DT_SCHEDULE IS NOT NULL
        --This addition to the where clause because when removing the association between a referral and it's
        --appointment the dt_schedule from EXR is not cleared. works has coded       
        o_sql := o_sql || to_clob(' LEFT JOIN schedule sch ON (te.id_schedule = sch.id_schedule AND SCH.FLG_STATUS = ''' ||
                                  pk_ref_constant.g_active || ''' AND te.DT_SCHEDULE IS NOT NULL)');
        o_sql := o_sql ||
                 to_clob(' LEFT JOIN p1_match m ON (te.id_patient = m.id_patient AND 
                                    m.id_institution = sys_context(''ALERT_CONTEXT'', ''i_prof_institution'') 
                                    AND m.flg_status = ''' || pk_ref_constant.g_active || ''')');
    
        pk_ref_utils.log_clob(o_sql);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_SEARCH_REF_SQL_BASE',
                                                     o_error    => o_error);
    END get_search_ref_sql_base;

    /**
    * Get P1 list - Return grid data depending on professional profile
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF professional id, institution and software
    * @param   i_filter Filter to apply. Depends on button selected.
    *
    * @RETURN  Return table (t_coll_ref_search) pipelined
    * @author  Joao Sa
    * @version 1.0
    * @since   08-11-2007
    */
    FUNCTION get_search_ref_data(i_sql IN CLOB) RETURN t_coll_ref_search
        PIPELINED IS
        out_rec  t_rec_ref_search := t_rec_ref_search();
        l_cursor pk_types.cursor_type;
    BEGIN
    
        g_error := 'get_search_ref_data / OPEN l_cursor FOR i_sql';
        OPEN l_cursor FOR i_sql;
        LOOP
        
            FETCH l_cursor
                INTO out_rec.id_external_request,
                     out_rec.num_req,
                     out_rec.flg_type,
                     out_rec.id_speciality,
                     out_rec.code_speciality,
                     out_rec.id_inst_orig,
                     out_rec.code_inst_orig,
                     out_rec.abbrev_inst_orig,
                     out_rec.institution_name_roda,
                     out_rec.id_inst_dest,
                     out_rec.code_inst_dest,
                     out_rec.inst_dest_abbrev,
                     out_rec.code_department,
                     out_rec.code_clinical_service,
                     out_rec.id_dep_clin_serv,
                     out_rec.id_prof_redirected,
                     out_rec.id_prof_status,
                     out_rec.flg_status,
                     out_rec.dt_status_tstz,
                     out_rec.flg_priority,
                     out_rec.decision_urg_level,
                     out_rec.id_schedule,
                     out_rec.dt_schedule_tstz,
                     out_rec.id_patient,
                     out_rec.pat_gender,
                     out_rec.sequential_number,
                     out_rec.id_prof_requested,
                     out_rec.id_prof_roda,
                     out_rec.id_workflow,
                     out_rec.id_match,
                     out_rec.id_external_sys,
                     out_rec.rut,
                     out_rec.run_number,
                     out_rec.id_prof_triage,
                     out_rec.id_prof_sch_sugg;
        
            EXIT WHEN l_cursor%NOTFOUND;
        
            PIPE ROW(out_rec);
        END LOOP;
    
        CLOSE l_cursor;
        RETURN;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_err_id PLS_INTEGER;
            BEGIN
                pk_alert_exceptions.register_error(error_name_in       => SQLERRM,
                                                   err_instance_id_out => l_err_id,
                                                   text_in             => g_error,
                                                   name1_in            => 'OWNER',
                                                   value1_in           => g_package_owner,
                                                   name2_in            => 'PACKAGE',
                                                   value2_in           => g_package_name,
                                                   name3_in            => 'FUNCTION',
                                                   value3_in           => 'GET_SEARCH_REF_DATA');
                RETURN;
            END;
    END get_search_ref_data;

    /**
    * Returns the domain of referral status filtered by id_market
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF professional id, institution and software
    *
    * @RETURN  Return table (t_coll_wf_status_info_def) pipelined
    * @author  Ana Monteiro
    * @version 1.0
    * @since   27-10-2009
    */
    FUNCTION get_search_ref_status
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN t_coll_wf_status_info_def
        PIPELINED IS
    
        l_rec       t_rec_wf_status_info_def;
        l_id_market institution.id_market%TYPE;
    
        CURSOR c_wf_software IS
            SELECT *
              FROM TABLE(CAST(pk_workflow.get_status_software(i_lang, i_prof, l_id_market) AS t_coll_wf_status_info_def));
    BEGIN
        g_error     := 'Init get_search_ref_status / ' || pk_utils.to_string(i_prof);
        l_id_market := pk_utils.get_institution_market(i_lang, i_prof.institution);
    
        FOR l_row IN c_wf_software
        LOOP
        
            g_error           := 't_rec_wf_status_info_def()';
            l_rec             := t_rec_wf_status_info_def();
            l_rec.id_status   := l_row.id_status;
            l_rec.desc_status := l_row.desc_status;
            l_rec.icon        := l_row.icon;
            l_rec.color       := l_row.color;
            l_rec.rank        := l_row.rank;
            l_rec.code_status := l_row.code_status;
        
            PIPE ROW(l_rec);
        END LOOP;
    
        RETURN;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_err_id PLS_INTEGER;
            BEGIN
                pk_alert_exceptions.register_error(error_name_in       => SQLERRM,
                                                   err_instance_id_out => l_err_id,
                                                   text_in             => g_error,
                                                   name1_in            => 'OWNER',
                                                   value1_in           => g_package_owner,
                                                   name2_in            => 'PACKAGE',
                                                   value2_in           => g_package_name,
                                                   name3_in            => 'FUNCTION',
                                                   value3_in           => 'GET_SEARCH_REF_STATUS');
                RETURN;
            END;
    END get_search_ref_status;

    /**
    * Getting patient social attributes (Used by match screen)
    * As ADT is integrated, this function should not be used.
    * Same as PK_PATIENT.get_pat_soc_att, but filtering PAT_SOC_ATTRIBUTES.id_institution.
    *
    * @param   i_lang        Language associated to the professional executing the request
    * @param   i_id_pat      Patient identifier   
    * @param   i_prof        Professional id, institution and software
    * @param   o_pat         Patient social attributes
    * @param   o_error       An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   15-06-2010
    */
    FUNCTION get_pat_soc_att
    (
        i_lang   IN language.id_language%TYPE,
        i_id_pat IN patient.id_patient%TYPE,
        i_prof   IN profissional,
        o_pat    OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sc_multi_instit VARCHAR2(1 CHAR);
    BEGIN
        g_error           := 'Init get_pat_soc_att / ID_PAT=' || i_id_pat;
        l_sc_multi_instit := pk_sysconfig.get_config(pk_ref_constant.g_sc_multi_institution, i_prof);
    
        OPEN o_pat FOR
            SELECT pk_sysdomain.get_domain('PAT_SOC_ATTRIBUTES.MARITAL_STATUS', t.marital_status, i_lang) desc_marital_status,
                   t.marital_status,
                   t.address,
                   t.location,
                   t.district,
                   t.zip_code,
                   pk_translation.get_translation(i_lang, 'ISENCAO.CODE_ISENCAO.' || t.id_isencao) desc_isencao,
                   t.id_isencao,
                   pk_translation.get_translation(i_lang, 'COUNTRY.CODE_COUNTRY.' || t.id_country_nation) country_nation,
                   pk_translation.get_translation(i_lang, 'COUNTRY.CODE_COUNTRY.' || t.id_country_address) country_address,
                   pk_translation.get_translation(i_lang, 'SCHOLARSHIP.CODE_SCHOLARSHIP.' || t.id_scholarship) schol,
                   pk_translation.get_translation(i_lang, 'RELIGION.CODE_RELIGION.' || t.id_religion) relig,
                   t.num_main_contact,
                   t.num_contact,
                   t.flg_job_status,
                   t.id_scholarship,
                   t.id_religion,
                   pk_sysdomain.get_domain_no_avail('PAT_SOC_ATTRIBUTES.FLG_JOB_STATUS', t.flg_job_status, i_lang) job_status,
                   pk_sysdomain.get_domain(pk_ref_constant.g_domain_gender, t.gender, i_lang) gend,
                   t.father_name,
                   t.mother_name,
                   t.id_patient,
                   t.id_country_nation,
                   t.id_country_address,
                   pk_translation.get_translation(i_lang, 'OCCUPATION.CODE_OCCUPATION.' || t.id_occupation) occup,
                   t.id_occupation,
                   t.name,
                   t.nick_name,
                   t.gender,
                   pk_date_utils.dt_chr(i_lang, t.dt_birth, i_prof) dt_birth_string,
                   pk_date_utils.date_send(i_lang, t.dt_birth, i_prof) dt_birth,
                   t.dt_birth dt_birth_dt, -- JS: 2007-05-14, necário para interface de registo de utentes no sonho
                   pk_date_utils.dt_chr(i_lang, t.dt_deceased, i_prof) dt_deceased,
                   pk_patient.get_pat_age(i_lang, i_id_pat, i_prof) age,
                   t.num_clin_record num_prc_clin,
                   t.flg_recm,
                   t.id_recm
              FROM (SELECT p.marital_status,
                           p.address,
                           p.location,
                           p.district,
                           p.zip_code,
                           p.id_isencao,
                           p.id_country_nation,
                           p.id_country_address,
                           p.id_scholarship,
                           p.id_religion,
                           p.num_main_contact,
                           p.num_contact,
                           p.father_name,
                           p.mother_name,
                           p.id_patient,
                           p.flg_job_status,
                           pj.id_occupation,
                           pat.name,
                           pat.gender,
                           pat.nick_name,
                           pat.dt_birth,
                           pat.dt_deceased,
                           cr.num_clin_record,
                           rm.flg_recm,
                           rm.id_recm
                      FROM patient pat
                      LEFT JOIN pat_soc_attributes p
                        ON (p.id_patient = pat.id_patient AND
                           (p.id_institution = 0 AND l_sc_multi_instit = pk_ref_constant.g_yes) OR
                           (p.id_institution = i_prof.institution AND l_sc_multi_instit = pk_ref_constant.g_no))
                      LEFT JOIN clin_record cr
                        ON (cr.id_patient = pat.id_patient AND cr.id_institution = i_prof.institution AND
                           cr.flg_status = pk_ref_constant.g_active)
                      LEFT JOIN pat_cli_attributes pca
                        ON (pca.id_patient = pat.id_patient AND pca.id_institution = i_prof.institution)
                      LEFT JOIN recm rm
                        ON (rm.id_recm = pca.id_recm)
                      LEFT JOIN (SELECT *
                                  FROM pat_job
                                 WHERE dt_pat_job_tstz = (SELECT MAX(p1.dt_pat_job_tstz)
                                                            FROM pat_job p1
                                                           WHERE p1.id_patient = i_id_pat)) pj
                        ON (pj.id_patient = p.id_patient)
                     WHERE pat.id_patient = i_id_pat) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_SOC_ATT',
                                              o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
    END get_pat_soc_att;

    /**
    * Getting transitions for one action/workflow/status_begin
    *
    * @param   I_LANG            Language associated to the professional executing the request
    * @param   I_PROF            Professional, institution and software ids
    * @param   I_ACTION          Action identifier. Mandatory.   
    * @param   I_ID_WORKFLOW     Workflow identifier. Optional.     
    * @param   I_ID_STATUS_BEGIN Begin status identifier. Optional.
    * @param   O_TRANS_DATA      Transitions data
    * @param   O_ERROR           An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   23-09-2010
    */
    FUNCTION get_wf_action_trans
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_action          IN wf_action.id_action%TYPE,
        i_id_workflow     IN wf_action.id_workflow%TYPE,
        i_id_status_begin IN wf_action.id_status_begin%TYPE,
        o_trans_data      OUT t_wf_action_cur,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'Init get_wf_action_trans / i_prof=' || pk_utils.to_string(i_prof) || ' i_action=' || i_action ||
                   ' i_id_workflow=' || i_id_workflow || ' i_id_status_begin=' || i_id_status_begin;
        OPEN o_trans_data FOR
            SELECT wa.*
              FROM wf_action wa
             WHERE wa.id_action = i_action
               AND (wa.id_workflow = i_id_workflow OR i_id_workflow IS NULL)
               AND (wa.id_status_begin = i_id_status_begin OR i_id_status_begin IS NULL);
    
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
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_WF_ACTION_TRANS',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_wf_action_trans;

    /**
    * Returns information about valid transitions associated to one action
    *
    * @param   I_LANG                  Language associated to the professional executing the request
    * @param   I_PROF                  Professional, institution and software ids
    * @param   I_ID_ACTION             Action identifier
    * @param   I_ID_WORKFLOW           Workflow identifier
    * @param   I_ID_STATUS_BEGIN       Begin status identifier
    * @param   I_ID_CATEGORY           Professional category
    * @param   I_ID_PROFILE_TEMPLATE   Professional profile template identifier
    * @param   I_ID_FUNCTIONALITY      Professional functionality
    * @param   I_PARAM                 Parameter for workflow framework
    * @param   I_BEHAVIOUR             Function behaviour: {*} 1- returns after having verified that the first transition is enabled    
                                                           {*} 0- returns after having verified all (default)
    * @param   O_EXISTS_TRANSITION     Flag indicating if there is a transition associated to this action (ID_ACTION)
    * @param   O_ENABLED               Flag indicating if this action/workflow/begin status is enabled      
    * @param   O_ERROR                 An error message, set when return=false
    *
    * @value   O_EXISTS_TRANSITION     {*} 'Y' - there is a transition associated to this action {*} 'N' - otherwise
    * @value   O_ENABLED               {*} 'Y' - this action/workflow/begin status is enabled {*} 'N' - otherwise 
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   23-09-2010
    */
    FUNCTION get_action_trans_valid
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_action           IN action.id_action%TYPE,
        i_id_workflow         IN wf_transition_config.id_workflow%TYPE,
        i_id_status_begin     IN wf_transition_config.id_status_begin%TYPE,
        i_id_category         IN wf_transition_config.id_category%TYPE,
        i_id_profile_template IN wf_transition_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_transition_config.id_functionality%TYPE,
        i_param               IN table_varchar,
        i_behaviour           IN PLS_INTEGER DEFAULT 0,
        o_exists_transition   OUT VARCHAR2,
        o_enabled             OUT VARCHAR2,
        o_transition_info     OUT t_coll_wf_transition,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_wf_action_cur t_wf_action_cur;
    
        TYPE t_wf_action IS TABLE OF wf_action%ROWTYPE;
        l_wf_action_tab t_wf_action;
    
        l_transition_info pk_workflow.t_rec_wf_trans_config;
        l_params          VARCHAR2(1000 CHAR);
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        l_params            := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_action=' || i_id_action ||
                               ' i_id_workflow=' || i_id_workflow || ' i_id_status_begin=' || i_id_status_begin ||
                               ' i_id_category=' || i_id_category || ' i_id_profile_template=' || i_id_profile_template ||
                               ' i_id_functionality=' || i_id_functionality || ' i_param=' ||
                               pk_utils.to_string(i_param) || ' i_behaviour=' || i_behaviour;
        g_error             := 'Init get_action_trans_valid / ' || l_params;
        o_exists_transition := pk_ref_constant.g_no;
        o_enabled           := pk_ref_constant.g_no;
        o_transition_info   := t_coll_wf_transition();
    
        ----------------------
        -- FUNC
        ----------------------                
    
        -- getting all transitions related to this action
        g_error  := 'Call get_wf_action_trans / ' || l_params;
        g_retval := get_wf_action_trans(i_lang            => i_lang,
                                        i_prof            => i_prof,
                                        i_action          => i_id_action,
                                        i_id_workflow     => i_id_workflow,
                                        i_id_status_begin => i_id_status_begin,
                                        o_trans_data      => l_wf_action_cur,
                                        o_error           => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'FETCH l_wf_action_cur / ' || l_params;
        FETCH l_wf_action_cur BULK COLLECT
            INTO l_wf_action_tab;
        CLOSE l_wf_action_cur;
    
        <<transition_loop>>
        FOR idx_trans IN 1 .. l_wf_action_tab.count
        LOOP
        
            -- check if at least one transition is valid
            g_error := 'Call pk_workflow.check_transition / ' || l_params;
            IF i_id_workflow = l_wf_action_tab(idx_trans).id_workflow
               AND i_id_status_begin = l_wf_action_tab(idx_trans).id_status_begin
            THEN
                o_exists_transition := pk_ref_constant.g_yes;
                g_retval            := pk_workflow.check_transition(i_lang                => i_lang,
                                                                    i_prof                => i_prof,
                                                                    i_id_workflow         => l_wf_action_tab(idx_trans)
                                                                                             .id_workflow,
                                                                    i_id_status_begin     => l_wf_action_tab(idx_trans)
                                                                                             .id_status_begin,
                                                                    i_id_status_end       => l_wf_action_tab(idx_trans)
                                                                                             .id_status_end,
                                                                    i_id_workflow_action  => l_wf_action_tab(idx_trans)
                                                                                             .id_workflow_action,
                                                                    i_id_category         => i_id_category,
                                                                    i_id_profile_template => i_id_profile_template,
                                                                    i_id_functionality    => i_id_functionality,
                                                                    i_param               => i_param,
                                                                    o_flg_available       => o_enabled,
                                                                    o_transition_info     => l_transition_info,
                                                                    o_error               => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                g_error := 'enabled=' || o_enabled || '  / ' || l_params;
                IF o_enabled = pk_ref_constant.g_yes
                THEN
                
                    o_transition_info.extend;
                    o_transition_info(o_transition_info.last) := t_rec_wf_transition();
                    o_transition_info(o_transition_info.last).id_workflow := l_transition_info.id_workflow;
                    o_transition_info(o_transition_info.last).id_status_begin := l_transition_info.id_status_begin;
                    o_transition_info(o_transition_info.last).id_status_end := l_transition_info.id_status_end;
                    o_transition_info(o_transition_info.last).id_workflow_action := l_transition_info.id_workflow_action;
                    o_transition_info(o_transition_info.last).desc_transition := pk_translation.get_translation(i_lang      => i_lang,
                                                                                                                i_code_mess => l_wf_action_tab(idx_trans)
                                                                                                                               .code_wf_action);
                    o_transition_info(o_transition_info.last).rank := l_transition_info.rank;
                
                    IF i_behaviour = 1
                    THEN
                        EXIT transition_loop;
                    END IF;
                END IF;
            END IF;
        
        END LOOP transition_loop;
    
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
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_ACTION_TRANS_VALID',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_action_trans_valid;

    /**
    * Gets referral actions available for a subject
    * Note: If action needs to access workflows, then configure ACTION.FLG_STATSUS='I' (will be replaced by transition availability)
    * If action does not need to access workflows, then configure ACTION.FLG_STATSUS='A' (will always be shown)
    *
    * @param   I_LANG         Language associated to the professional executing the request
    * @param   I_PROF         Professional, institution and software ids
    * @param   I_ID_REF       Referral identifier
    * @param   I_SUBJECT      Subject for grouping of actions   
    * @param   I_FROM_STATE   Begin action state     
    * @param   O_ACTIONS      Referral actions
    * @param   O_ERROR        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.6
    * @since   23-09-2010
    */
    FUNCTION get_ref_actions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_ref     IN p1_external_request.id_external_request%TYPE,
        i_subject    IN action.subject%TYPE,
        i_from_state IN action.from_state%TYPE,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_action_cur pk_action.p_action_cur;
    
        TYPE t_tab_action IS TABLE OF pk_action.p_action_rec;
        l_action_tab t_tab_action;
    
        l_ref_row     p1_external_request%ROWTYPE;
        l_prof_data   t_rec_prof_data;
        l_flg_enabled VARCHAR2(1 CHAR);
    
        l_id_workflow p1_external_request.id_workflow%TYPE;
        l_status_n    wf_status.id_status%TYPE;
        i_param       table_varchar;
    
        l_tab_action t_coll_action;
        l_rec_action t_rec_action;
    
        l_transition_info   t_coll_wf_transition;
        l_exists_transition VARCHAR2(1 CHAR);
        l_params            VARCHAR2(1000 CHAR);
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_ref=' || i_id_ref || ' i_subject=' || i_subject ||
                    ' i_from_state=' || i_from_state;
        g_error  := 'Init get_ref_actions / ' || l_params;
        pk_alertlog.log_debug(g_error);
    
        l_tab_action := t_coll_action();
        l_rec_action := t_rec_action();
    
        ----------------------
        -- FUNC
        ----------------------                
        g_error  := 'Call pk_p1_external_request.get_ref_row / ' || l_params;
        g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                       i_prof   => i_prof,
                                                       i_id_ref => i_id_ref,
                                                       o_rec    => l_ref_row,
                                                       o_error  => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        l_params := l_params || ' FLG_STATUS=' || l_ref_row.flg_status || ' ID_WF=' || l_ref_row.id_workflow ||
                    ' I_DCS=' || l_ref_row.id_dep_clin_serv;
    
        g_error  := 'Call pk_ref_core.get_prof_data / ' || l_params;
        g_retval := pk_ref_core.get_prof_data(i_lang      => i_lang,
                                              i_prof      => i_prof,
                                              i_dcs       => l_ref_row.id_dep_clin_serv,
                                              o_prof_data => l_prof_data,
                                              o_error     => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        l_params := l_params || ' PRF_TEMPL=' || l_prof_data.id_profile_template || ' ID_FUNCT=' ||
                    l_prof_data.id_functionality || ' CAT=' || l_prof_data.id_category;
    
        l_id_workflow := nvl(l_ref_row.id_workflow, pk_ref_constant.g_wf_pcc_hosp);
        l_status_n    := pk_ref_status.convert_status_n(i_status => l_ref_row.flg_status);
    
        g_error := 'Calling pk_ref_core.init_param_tab / ' || l_params;
        i_param := pk_ref_core.init_param_tab(i_lang               => i_lang,
                                              i_prof               => i_prof,
                                              i_ext_req            => l_ref_row.id_external_request,
                                              i_id_patient         => l_ref_row.id_patient,
                                              i_id_inst_orig       => l_ref_row.id_inst_orig,
                                              i_id_inst_dest       => l_ref_row.id_inst_dest,
                                              i_id_dep_clin_serv   => l_ref_row.id_dep_clin_serv,
                                              i_id_speciality      => l_ref_row.id_speciality,
                                              i_flg_type           => l_ref_row.flg_type,
                                              i_decision_urg_level => l_ref_row.decision_urg_level,
                                              i_id_prof_requested  => l_ref_row.id_prof_requested,
                                              i_id_prof_redirected => l_ref_row.id_prof_redirected,
                                              i_id_prof_status     => l_ref_row.id_prof_status,
                                              i_external_sys       => l_ref_row.id_external_sys,
                                              i_flg_status         => l_ref_row.flg_status);
    
        -- 1- getting actions available in table ACTION
        g_error  := 'Call pk_actions.get_actions / ' || l_params;
        g_retval := pk_action.get_actions(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_subject    => i_subject,
                                          i_from_state => i_from_state,
                                          o_actions    => l_action_cur,
                                          o_error      => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error := 'FETCH l_action_cur / ' || l_params;
        FETCH l_action_cur BULK COLLECT
            INTO l_action_tab;
        CLOSE l_action_cur;
    
        <<action_loop>>
        FOR idx_action IN 1 .. l_action_tab.count
        LOOP
        
            -- 2- check if this action is associated to any workflow transition, and if so, if is valid (at least one transition available)
            g_error  := 'Call get_action_trans_valid / ID_ACTION=' || l_action_tab(idx_action).id_action || ' WF=' ||
                        l_id_workflow || ' STS_ID_BEG=' || l_status_n || ' ID_CAT=' || l_prof_data.id_category ||
                        ' PRF_TEMPL=' || l_prof_data.id_profile_template || ' FUNC=' || l_prof_data.id_functionality ||
                        ' I_PARAM=' || pk_utils.to_string(i_param);
            g_retval := get_action_trans_valid(i_lang                => i_lang,
                                               i_prof                => i_prof,
                                               i_id_action           => l_action_tab(idx_action).id_action,
                                               i_id_workflow         => l_id_workflow,
                                               i_id_status_begin     => l_status_n,
                                               i_id_category         => l_prof_data.id_category,
                                               i_id_profile_template => l_prof_data.id_profile_template,
                                               i_id_functionality    => l_prof_data.id_functionality,
                                               i_param               => i_param,
                                               i_behaviour           => 1, -- returns if the first transition is enabled
                                               o_exists_transition   => l_exists_transition,
                                               o_enabled             => l_flg_enabled,
                                               o_transition_info     => l_transition_info,
                                               o_error               => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            g_error := 'l_exists_transition=' || l_exists_transition || ' / ' || l_params;
            IF l_exists_transition = pk_ref_constant.g_yes
            THEN
                -- this action is associated to at least one workflow transition
            
                -- fill l_tab_action array        
                g_error := 'EXISTS_TRANSITION=' || l_exists_transition || ' ID_ACTION=' || l_action_tab(idx_action)
                          .id_action || ' ID_PARENT=' || l_action_tab(idx_action).id_parent || ' LEVEL=' || l_action_tab(idx_action)
                          .level || ' FROM_STATE=' || l_action_tab(idx_action).to_state || ' TO_STATE=' || l_action_tab(idx_action)
                          .to_state || ' ICON=' || l_action_tab(idx_action).icon || ' FLG_DEFAULT=' || l_action_tab(idx_action)
                          .flg_default || ' FLG_STATUS=' || l_action_tab(idx_action).flg_status || ' INTERNAL_NAME=' || l_action_tab(idx_action)
                          .internal_name || ' FLG_ACTIVE=' || l_flg_enabled;
            
                l_rec_action.id_action   := l_action_tab(idx_action).id_action;
                l_rec_action.id_parent   := l_action_tab(idx_action).id_parent;
                l_rec_action.level_nr    := l_action_tab(idx_action).level;
                l_rec_action.from_state  := l_action_tab(idx_action).from_state;
                l_rec_action.to_state    := l_action_tab(idx_action).to_state;
                l_rec_action.desc_action := l_action_tab(idx_action).desc_action;
                l_rec_action.icon        := l_action_tab(idx_action).icon;
                l_rec_action.flg_default := l_action_tab(idx_action).flg_default;
                --l_rec_action.flg_status    := l_action_tab(idx_action).flg_status;
                l_rec_action.action := l_action_tab(idx_action).internal_name;
            
                IF l_flg_enabled = pk_ref_constant.g_yes
                THEN
                    l_rec_action.flg_active := pk_ref_constant.g_active;
                ELSE
                    l_rec_action.flg_active := pk_ref_constant.g_inactive;
                END IF;
            
                l_tab_action.extend;
                l_tab_action(l_tab_action.last) := l_rec_action;
            
            ELSE
            
                -- this action is NOT associated to any workflow transition, return directly from PK_ACTION
                g_error                  := 'EXISTS_TRANSITION=' || l_exists_transition || ' / ' || l_params;
                l_rec_action.id_action   := l_action_tab(idx_action).id_action;
                l_rec_action.id_parent   := l_action_tab(idx_action).id_parent;
                l_rec_action.level_nr    := l_action_tab(idx_action).level;
                l_rec_action.from_state  := l_action_tab(idx_action).from_state;
                l_rec_action.to_state    := l_action_tab(idx_action).to_state;
                l_rec_action.desc_action := l_action_tab(idx_action).desc_action;
                l_rec_action.icon        := l_action_tab(idx_action).icon;
                l_rec_action.flg_default := l_action_tab(idx_action).flg_default;
                --l_rec_action.flg_status    := l_action_tab(idx_action).flg_status;
                l_rec_action.action     := l_action_tab(idx_action).internal_name;
                l_rec_action.flg_active := l_action_tab(idx_action).flg_status;
            
                l_tab_action.extend;
                l_tab_action(l_tab_action.last) := l_rec_action;
            END IF;
        
        END LOOP action_loop;
    
        -- 3- Returns action data, indicating a new column: FLG_ENABLED        
        g_error := 'OPEN o_actions / ' || l_params;
        OPEN o_actions FOR
            SELECT *
              FROM TABLE(CAST(l_tab_action AS t_coll_action));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_actions);
            IF l_action_cur%ISOPEN
            THEN
                CLOSE l_action_cur;
            END IF;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REF_ACTIONS',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_actions);
            IF l_action_cur%ISOPEN
            THEN
                CLOSE l_action_cur;
            END IF;
            RETURN FALSE;
    END get_ref_actions;

    -------------------------------------------------------------------------
    /**
    * Returns sql query to calculate the column names
    *
    * @param   I_LANG            Language associated to the professional executing the request
    * @param   I_PROF            Professional, institution and software ids
    * @param   i_prof_data       Professional category, profile template and functionality
    * @param   i_column_name_tab Array of column names
    * @param   i_flg_alias       Return alias columns? Y- yes, N- no
    * @param   o_query_column    Query to calculate the column names defined
    * @param   O_ERROR           An error message, set when return=false    
    *
    * @value   i_flg_alias       {*} Y- yes {*} N- no
    *
    * @RETURN  Query to calculate the column names defined
    * @author  Ana Monteiro
    * @version 1.0
    * @since   27-09-2012
    */
    FUNCTION get_column_sql
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_prof_data       IN t_rec_prof_data,
        i_column_name_tab IN table_varchar,
        i_flg_alias       IN VARCHAR2 DEFAULT pk_ref_constant.g_yes
    ) RETURN CLOB IS
        l_params    VARCHAR2(1000 CHAR);
        l_col_query VARCHAR2(1000 CHAR);
        l_prof_v    VARCHAR2(100 CHAR);
        l_return    CLOB;
        l_prof_data t_rec_prof_data;
        l_error     t_error_out;
    
        l_bdnp_available sys_config.value%TYPE;
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_flg_alias=' || i_flg_alias || ' count=' ||
                    i_column_name_tab.count;
        g_error  := 'Init get_column_sql / ' || l_params;
    
        ----------------------
        -- FUNC
        ----------------------
        l_return := empty_clob();
        l_prof_v := 'profissional(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || ')';
    
        IF i_prof_data.id_profile_template IS NULL
        THEN
            g_error  := 'Calling get_prof_data / ' || l_params;
            g_retval := pk_ref_core.get_prof_data(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_dcs       => NULL,
                                                  o_prof_data => l_prof_data,
                                                  o_error     => l_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            l_prof_data := i_prof_data;
        END IF;
    
        <<column_loop>>
        FOR i IN 1 .. i_column_name_tab.count
        LOOP
            g_error := 'CASE ' || i_column_name_tab(i) || ' / ' || l_params;
            CASE i_column_name_tab(i)
            
                WHEN pk_ref_constant.g_col_dt_p1 THEN
                    l_col_query := 'pk_date_utils.dt_chr_tsz(' || i_lang || ',  pk_ref_utils.get_ref_detail_date(' ||
                                   i_lang || ', t.id_external_request, t.flg_status, t.id_workflow), ' || l_prof_v || ')';
                
                WHEN pk_ref_constant.g_col_pat_name THEN
                    l_col_query := 'pk_adt.get_patient_name(' || i_lang || ', ' || l_prof_v ||
                                   ', t.id_patient, pk_p1_external_request.check_prof_resp(' || i_lang || ', ' ||
                                   l_prof_v || ', t.id_external_request))';
                
                WHEN pk_ref_constant.g_col_pat_ndo THEN
                    l_col_query := 'pk_adt.get_pat_non_disc_options(' || i_lang || ', ' || l_prof_v ||
                                   ', t.id_patient)';
                
                WHEN pk_ref_constant.g_col_pat_nd_icon THEN
                    l_col_query := 'pk_adt.get_pat_non_disclosure_icon(' || i_lang || ', ' || l_prof_v ||
                                   ', t.id_patient)';
                
                WHEN pk_ref_constant.g_col_pat_gender THEN
                    l_col_query := '(SELECT pk_sysdomain.get_domain(''PATIENT.GENDER.ABBR'', t.pat_gender, ' || i_lang ||
                                   ') from dual)';
                
                WHEN pk_ref_constant.g_col_pat_age THEN
                    l_col_query := '(SELECT pk_patient.get_pat_age(' || i_lang || ', t.id_patient, ' || l_prof_v ||
                                   ') from dual)';
                
                WHEN pk_ref_constant.g_col_pat_photo THEN
                    l_col_query := 'pk_ref_utils.get_pat_photo(' || i_lang || ', ' || l_prof_v ||
                                   ', t.id_patient, t.id_external_request)';
                
                WHEN pk_ref_constant.g_col_id_prof_req THEN
                    l_col_query := 't.id_prof_requested ';
                
                WHEN pk_ref_constant.g_col_prof_req_name THEN
                    l_col_query := 'pk_p1_external_request.get_prof_req_name(' || i_lang || ', ' || l_prof_v ||
                                   ', t.id_prof_requested, t.id_prof_orig)';
                
                WHEN pk_ref_constant.g_col_priority_info THEN
                    l_col_query := 'pk_ref_core.get_ref_priority_info(' || i_lang || ', ' || l_prof_v ||
                                   ', t.flg_priority)';
                
                WHEN pk_ref_constant.g_col_priority_desc THEN
                    l_col_query := 'pk_ref_core.get_ref_priority_desc(' || i_lang || ', ' || l_prof_v ||
                                   ', t.flg_priority)';
                
                WHEN pk_ref_constant.g_col_priority_icon THEN
                    l_col_query := 'pk_ref_utils.get_domain_cached_img_name(' || i_lang || ', ' || l_prof_v || ', ''' ||
                                   pk_ref_constant.g_ref_prio || ''', t.flg_priority)';
                
                WHEN pk_ref_constant.g_col_priority_sort THEN
                    l_col_query := 'pk_ref_utils.get_domain_cached_rank(' || i_lang || ', ' || l_prof_v || ', ''' ||
                                   pk_ref_constant.g_ref_prio || ''', t.flg_priority)';
                
                WHEN pk_ref_constant.g_col_type_icon THEN
                    l_col_query := 'nvl2((SELECT img_name FROM sys_domain WHERE id_language = ' || i_lang ||
                                   ' AND domain_owner = ' || '''' || pk_sysdomain.k_default_schema || '''' ||
                                   ' AND code_domain = ''' || pk_ref_constant.g_p1_exr_flg_type ||
                                   ''' AND val = t.flg_type), lpad(
                                (SELECT rank FROM sys_domain WHERE id_language = ' ||
                                   i_lang || ' AND domain_owner = ' || '''' || pk_sysdomain.k_default_schema || '''' ||
                                   ' AND code_domain = ''' || pk_ref_constant.g_p1_exr_flg_type || '''
                                    AND val = t.flg_type),6,''0'') ||(SELECT img_name FROM sys_domain WHERE id_language = ' ||
                                   i_lang || ' AND domain_owner = ' || '''' || pk_sysdomain.k_default_schema || '''' ||
                                   ' AND code_domain = ''' || pk_ref_constant.g_p1_exr_flg_type ||
                                   ''' AND val = t.flg_type), NULL)';
                
                WHEN pk_ref_constant.g_col_inst_orig_name THEN
                    l_col_query := 'pk_ref_core.get_inst_orig_name(' || i_lang || ', ' || l_prof_v ||
                                   ', t.id_inst_orig,t.institution_name_roda)';
                
                WHEN pk_ref_constant.g_col_inst_dest_name THEN
                    l_col_query := '(SELECT pk_ref_core.get_inst_name(' || i_lang || ',' || l_prof_v ||
                                   ',t.flg_status, t.id_inst_dest, t.code_inst_dest, t.inst_dest_abbrev) FROM dual)';
                
                WHEN pk_ref_constant.g_col_p1_spec_name THEN
                    l_col_query := 'decode(t.id_workflow,
                            ' || pk_ref_constant.g_wf_srv_srv ||
                                  -- if is internal workflow, than shows the value of column clin_srv_name
                                   ',pk_translation.get_translation(' || i_lang || ', t.code_clinical_service),'
                                  -- else (other than internal workflow)
                                   || ' nvl2(t.code_speciality, pk_translation.get_translation(' || i_lang ||
                                   ', t.code_speciality), (SELECT desc_val FROM sys_domain WHERE id_language = ' ||
                                   i_lang || ' and domain_owner = ' || '''' || pk_sysdomain.k_default_schema || '''' ||
                                   ' AND code_domain = ''' || pk_ref_constant.g_p1_exr_flg_type ||
                                   ''' AND val = t.flg_type)))';
                
                WHEN pk_ref_constant.g_col_clin_srv_name THEN
                    l_col_query := 'decode(t.id_inst_dest, NULL, NULL, decode(t.id_dep_clin_serv, NULL, pk_translation.get_translation(' ||
                                   i_lang || ', t.code_speciality), pk_translation.get_translation(' || i_lang ||
                                   ', t.code_clinical_service)))';
                
                WHEN pk_ref_constant.g_col_id_prof_schedule THEN
                    l_col_query := 'CASE t.flg_status WHEN ''' || pk_ref_constant.g_p1_status_a ||
                                   ''' THEN pk_ref_core.get_prof_status(' || i_lang || ', ' || l_prof_v ||
                                   ', t.id_external_request, t.flg_status) ELSE t.id_prof_schedule END';
                
                WHEN pk_ref_constant.g_col_dt_schedule THEN
                    l_col_query := 'pk_date_utils.dt_chr_tsz(' || i_lang || ', t.dt_schedule_tstz, ' || l_prof_v || ')';
                
                WHEN pk_ref_constant.g_col_hour_schedule THEN
                    l_col_query := 'pk_date_utils.dt_chr_hour_tsz(' || i_lang || ', t.dt_schedule_tstz, ' || l_prof_v || ')';
                
                WHEN pk_ref_constant.g_col_dt_sch_millis THEN
                    l_col_query := 'pk_date_utils.date_send_tsz(' || i_lang || ', t.dt_schedule_tstz, ' || l_prof_v || ')';
                
                WHEN pk_ref_constant.g_col_prof_triage_name THEN
                    l_col_query := '(SELECT pk_prof_utils.get_name_signature(' || i_lang || ', ' || l_prof_v ||
                                   ', t.id_prof_triage) FROM dual)';
                
                WHEN pk_ref_constant.g_col_flg_task_editable THEN
                    l_col_query := 'decode(instr(''' || pk_ref_constant.g_p1_status_n || pk_ref_constant.g_p1_status_o ||
                                   pk_ref_constant.g_p1_status_d || pk_ref_constant.g_p1_status_j ||
                                   ''', t.flg_status), 0, ''' || pk_ref_constant.g_no ||
                                   ''', decode(t.id_prof_requested, ' || i_prof.id || ', ''' || pk_ref_constant.g_yes ||
                                   ''', ''' || pk_ref_constant.g_no || '''))';
                
                WHEN pk_ref_constant.g_col_flg_attach THEN
                    l_col_query := 't.nr_clinical_doc';
                
                WHEN pk_ref_constant.g_col_dt_last_interaction THEN
                    l_col_query := 'pk_date_utils.date_send_tsz(' || i_lang || ', t.dt_last_interaction_tstz, ' ||
                                   l_prof_v || ')';
                
                WHEN pk_ref_constant.g_col_status_info THEN
                    -- STATUS_INFO [icon|color|rank|flg_editable|order_by_field]
                    l_col_query := 'pk_ref_status.get_flash_status_info(' || i_lang || ',' || l_prof_v ||
                                   ',t.sts_info.icon,t.sts_info.color,t.sts_info.rank,t.sts_info.flg_update,t.dt_status_tstz)';
                
                WHEN pk_ref_constant.g_col_tr_status_info THEN
                    -- TR_STATUS_INFO [icon|color|rank|flg_editable|order_by_field]
                    l_col_query := 'pk_ref_status.get_flash_status_info(' || i_lang || ',' || l_prof_v ||
                                   ',t.tr_sts_info.icon,t.tr_sts_info.color,t.tr_sts_info.rank,t.tr_sts_info.flg_update,t.tr_dt_update)';
                
                WHEN pk_ref_constant.g_col_can_cancel THEN
                    l_col_query := 'pk_ref_core.can_cancel(' || i_lang || ',' || l_prof_v || ',' ||
                                   't.id_external_request, t.flg_status, t.id_workflow,' ||
                                   l_prof_data.id_profile_template || ',(SELECT pk_ref_core.get_prof_func(' || i_lang || ', ' ||
                                   l_prof_v || ', t.id_dep_clin_serv) FROM dual),' || l_prof_data.id_category ||
                                   ',t.id_patient, t.id_inst_orig, t.id_inst_dest, t.id_dep_clin_serv,' ||
                                   't.id_speciality, t.flg_type, t.id_prof_requested,' ||
                                   't.id_prof_redirected, t.id_prof_status, t.id_external_sys, t.decision_urg_level)';
                
                WHEN pk_ref_constant.g_col_can_approve THEN
                    l_col_query := 'pk_ref_core.can_approve(' || i_lang || ',' || l_prof_v ||
                                   ', t.id_external_request,t.flg_status, t.id_workflow,' ||
                                   l_prof_data.id_profile_template || ',(SELECT pk_ref_core.get_prof_func(' || i_lang || ',' ||
                                   l_prof_v || ',t.id_dep_clin_serv) FROM dual),' || l_prof_data.id_category ||
                                   ',t.id_patient, t.id_inst_orig, t.id_inst_dest, t.id_dep_clin_serv, t.id_speciality, t.flg_type,' ||
                                   't.id_prof_requested, t.id_prof_redirected, t.id_prof_status, t.id_external_sys, t.decision_urg_level)';
                
                WHEN pk_ref_constant.g_col_desc_dec_urg_level THEN
                    l_col_query := 'pk_sysdomain.get_domain(''' || pk_ref_constant.g_decision_urg_level ||
                                   ''' || t.decision_urg_level, t.decision_urg_level,' || i_lang || ')';
                
                WHEN pk_ref_constant.g_col_id_schedule_ext THEN
                    l_col_query := 'decode(t.id_schedule, NULL, NULL, (SELECT id_schedule_ext FROM sch_api_map_ids WHERE id_schedule_pfh = t.id_schedule AND rownum = 1))';
                
                WHEN pk_ref_constant.g_col_observations THEN
                    l_col_query := 'pk_ref_core.get_ref_observations (' || i_lang || ',' || l_prof_v || ',' ||
                                   l_prof_data.id_profile_template || ',
                                t.id_external_request,
                                t.flg_status,
                                t.id_prof_status,
                                t.dt_schedule_tstz,
                                (SELECT pk_ref_utils.can_view_clinical_data(' ||
                                   i_lang || ', ' || l_prof_v || ', ''' || l_prof_data.flg_category || ''',' ||
                                   l_prof_data.id_profile_template ||
                                   ',t.id_prof_requested, t.id_workflow) from dual), t.id_prof_triage, t.id_prof_sch_sugg)';
                
                WHEN pk_ref_constant.g_col_id_content THEN
                    l_col_query := 'decode(t.flg_type, ''' || pk_ref_constant.g_p1_type_c || ''',
                            pk_ref_core.get_content(' || i_lang || ', ' || l_prof_v ||
                                   ', t.id_dep_clin_serv, t.id_prof_schedule), NULL)';
                
                WHEN pk_ref_constant.g_col_reason_desc THEN
                    l_col_query := 'decode(instr(''' || pk_ref_constant.g_p1_status_d || pk_ref_constant.g_p1_status_x ||
                                   ''', t.flg_status), 0, NULL,
                            pk_ref_core.get_referral_obs(' || i_lang || ', ' ||
                                   l_prof_v || ', t.id_external_request, t.flg_status, 
																		(SELECT pk_ref_utils.can_view_clinical_data(' || i_lang || ', ' ||
                                   l_prof_v || ', ''' || l_prof_data.flg_category || ''',' ||
                                   l_prof_data.id_profile_template ||
                                   ',t.id_prof_requested, t.id_workflow) from dual)))';
                
                WHEN pk_ref_constant.g_col_is_task_complet THEN
                
                    l_col_query := 'decode(nvl((SELECT COUNT(id_task_done)
                                  FROM p1_task_done ptd
                                 WHERE ptd.id_external_request = t.id_external_request
                                   AND ptd.flg_task_done = ''' ||
                                   pk_ref_constant.g_no || '''
                                   AND ptd.flg_status = ''' ||
                                   pk_ref_constant.g_active || '''),
                                0),
                            0,
                            ''' || pk_ref_constant.g_yes || ''',
                            ''' || pk_ref_constant.g_no || ''')';
                
                WHEN pk_ref_constant.g_col_flg_match_redirect THEN
                
                    IF i_prof_data.id_category = pk_ref_constant.g_cat_id_adm
                       AND i_prof_data.id_profile_template != pk_ref_constant.g_profile_adm_hs_vo
                    THEN
                        -- getting p1_workflow_config to send this referral
                        l_col_query := 'CASE';
                        l_col_query := l_col_query || ' WHEN (SELECT pk_ref_core.get_workflow_config(' || l_prof_v ||
                                       ',''' || pk_ref_constant.g_adm_required ||
                                       ''',t.id_speciality,t.id_inst_dest,t.id_inst_orig,t.id_workflow) from dual) = ''' ||
                                       pk_ref_constant.g_adm_required_match || ''' THEN ''' || pk_ref_constant.g_yes || '''';
                        l_col_query := l_col_query || ' WHEN t.id_match is null THEN ''' || pk_ref_constant.g_yes || '''';
                        l_col_query := l_col_query || ' ELSE ''' || pk_ref_constant.g_no || '''';
                        l_col_query := l_col_query || ' END';
                    ELSE
                        l_col_query := '''N'' ';
                        --l_col_query := 'NULL '; -- do not do this when it is not the registrar (because of performance)
                    END IF;
                WHEN pk_ref_constant.g_col_can_sent THEN
                
                    l_bdnp_available := nvl(pk_sysconfig.get_config(i_prof    => i_prof,
                                                                    i_code_cf => pk_ref_constant.g_ref_mcdt_bdnp),
                                            pk_ref_constant.g_no);
                
                    l_col_query := ' pk_ref_core.can_sent(' || i_lang || ', ' || l_prof_v ||
                                   ', t.id_external_request, t.flg_status, t.flg_migrated,''' || l_bdnp_available ||
                                   ''') ';
                
                ELSE
                    g_error := 'Column not recognized / column_name=' || i_column_name_tab(i);
                    RAISE g_exception;
            END CASE;
        
            -- add separator            
            IF i != 1
            THEN
                l_return := l_return || to_clob(',');
            END IF;
        
            -- add column value
            g_error  := 'add column value / ' || i_column_name_tab(i) || ' / ' || l_params;
            l_return := l_return || to_clob(l_col_query);
        
            -- add column alias
            g_error := 'add column alias / ' || i_column_name_tab(i) || ' / ' || l_params;
            IF i_flg_alias = pk_ref_constant.g_yes
            THEN
                l_return := l_return || to_clob(' ' || i_column_name_tab(i));
            ELSE
                l_return := l_return || to_clob(' ');
            END IF;
        
        END LOOP column_loop;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alertlog.log_error(SQLERRM || ' / ' || g_error);
            RETURN NULL;
    END get_column_sql;

    /**
    * Set referrals sys_alerts
    *
    * @param   i_lang                  Language associated to the professional executing the request
    * @param   i_prof                  Professional, institution and software ids
    * @param   i_ref_row               P1_external_request ROWTYPE
    * @param   i_pat                   Patient id
    * @param   i_track_row             p1_tracking ROWTYPE
    * @param   i_dt_create             Operation date
    * @param   o_error                 An error message, set when return=false
    *
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   22-05-2013
    */

    FUNCTION set_referral_alerts
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_ref_row   IN p1_external_request%ROWTYPE,
        i_pat       IN p1_external_request.id_patient%TYPE,
        i_track_row IN p1_tracking%ROWTYPE,
        i_dt_create p1_tracking.dt_create%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_sys_alert_event sys_alert_event%ROWTYPE;
        l_sys_alert       sys_alert.id_sys_alert%TYPE;
        l_replace1        sys_alert_event.replace1%TYPE;
        l_sys_alert_tab   table_number;
    BEGIN
    
        -- Create sys_alert_events (with status validation) only if is a status change.
        -- Remove old sys_alert_events (with status validation) before create new one
        IF i_track_row.flg_type = pk_ref_constant.g_tracking_type_s
        THEN
            l_sys_alert_tab := table_number(pk_ref_constant.g_sa_refused_epis,
                                            pk_ref_constant.g_sa_refused_no_epis,
                                            pk_ref_constant.g_sa_sent_back_epis,
                                            pk_ref_constant.g_sa_sent_back_no_epis,
                                            pk_ref_constant.g_sa_sch_ref,
                                            pk_ref_constant.g_sa_sent_back_bur_no_epis);
        
            FOR i IN 1 .. l_sys_alert_tab.count
            LOOP
                g_error  := 'cALL pk_alerts.delete_sys_alert_event / I_ID_RECORD=' || i_track_row.id_external_request ||
                            ' I_ID_SYS_ALERT=' || l_sys_alert_tab(i);
                g_retval := pk_alerts.delete_sys_alert_event(i_lang         => i_lang,
                                                             i_prof         => i_prof,
                                                             i_id_sys_alert => l_sys_alert_tab(i),
                                                             i_id_record    => i_track_row.id_external_request,
                                                             o_error        => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
            END LOOP;
            IF i_ref_row.flg_status IN (pk_ref_constant.g_p1_status_x,
                                        pk_ref_constant.g_p1_status_d,
                                        pk_ref_constant.g_p1_status_y,
                                        pk_ref_constant.g_p1_status_h,
                                        pk_ref_constant.g_p1_status_b)
            THEN
                CASE
                    WHEN i_ref_row.flg_status IN (pk_ref_constant.g_p1_status_x, pk_ref_constant.g_p1_status_h) THEN
                        IF i_ref_row.id_workflow = pk_ref_constant.g_wf_ref_but
                        THEN
                            l_sys_alert := pk_ref_constant.g_sa_refused_epis;
                        ELSE
                            l_sys_alert := pk_ref_constant.g_sa_refused_no_epis;
                            l_replace1  := pk_ref_constant.g_sm_ref_detail_t065;
                        END IF;
                    
                    WHEN i_ref_row.flg_status IN (pk_ref_constant.g_p1_status_d, pk_ref_constant.g_p1_status_y) THEN
                        IF i_ref_row.id_workflow = pk_ref_constant.g_wf_ref_but
                        THEN
                            l_sys_alert := pk_ref_constant.g_sa_sent_back_epis;
                        ELSE
                            l_sys_alert := pk_ref_constant.g_sa_sent_back_no_epis;
                            l_replace1  := pk_ref_constant.g_sm_ref_detail_t066;
                        END IF;
                    
                    WHEN i_ref_row.flg_status = pk_ref_constant.g_p1_status_b THEN
                        -- todo: substituir pela configuracao da tabela de alertas
                        l_replace1  := '@SM[' || pk_ref_constant.g_sm_ref_detail_t087 || ']: ' || i_ref_row.num_req;
                        l_sys_alert := pk_ref_constant.g_sa_sent_back_bur_no_epis;
                        -- todo: substituir pela configuracao da tabela de alertas
                END CASE;
            
                l_sys_alert_event.id_sys_alert     := l_sys_alert;
                l_sys_alert_event.id_software      := i_prof.software;
                l_sys_alert_event.id_institution   := i_prof.institution;
                l_sys_alert_event.id_patient       := i_pat;
                l_sys_alert_event.id_record        := i_track_row.id_external_request;
                l_sys_alert_event.dt_record        := i_dt_create;
                l_sys_alert_event.id_professional  := i_prof.id;
                l_sys_alert_event.id_dep_clin_serv := i_track_row.id_dep_clin_serv;
                l_sys_alert_event.id_episode       := nvl(i_ref_row.id_episode, -1);
                l_sys_alert_event.id_visit         := pk_episode.get_id_visit(l_sys_alert_event.id_episode);
                l_sys_alert_event.flg_visible      := pk_ref_constant.g_yes;
                l_sys_alert_event.replace1         := l_replace1;
            
                IF i_ref_row.num_req IS NOT NULL
                THEN
                    l_sys_alert_event.replace2 := '@1: ' || i_ref_row.num_req;
                END IF;
            
                g_error := 'Call pk_alerts.insert_sys_alert_event / ID_REF=' || i_track_row.id_external_request ||
                           ' id_sys_alert=' || l_sys_alert || ' id_professional=' || i_prof.id;
            
                g_retval := pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                             i_prof            => i_prof,
                                                             i_sys_alert_event => l_sys_alert_event,
                                                             o_error           => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
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
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_REFERRAL_ALERTS',
                                              o_error    => o_error);
            RETURN FALSE;
        
    END set_referral_alerts;

    /**
    * Returns the message to visible to the professional, in alerts area
    * Used in sys_alert.sql_alert for referral alerts
    *
    * @param   i_expression       Expression to evaluate
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   21-06-2013
    */
    FUNCTION get_alerts_message(i_expression IN sys_alert_event.replace1%TYPE) RETURN VARCHAR2 IS
        l_result VARCHAR2(1000 CHAR);
    
        -- patterns to find       
        l_sm_pattern CONSTANT VARCHAR2(1000 CHAR) := '@SM\[([^]]+)\]';
        l_tr_pattern CONSTANT VARCHAR2(1000 CHAR) := '@TR\[([^]]+)\]';
    
        -- patterns to replace
        l_sm_pattern_replace CONSTANT VARCHAR2(1000 CHAR) := 'pk_message.get_message(' ||
                                                             sys_context('ALERT_CONTEXT', 'i_lang') || ',''' || '\1' ||
                                                             ''')';
        l_tr_pattern_replace CONSTANT VARCHAR2(1000 CHAR) := 'pk_translation.get_translation(' ||
                                                             sys_context('ALERT_CONTEXT', 'i_lang') || ',''' || '\1' ||
                                                             ''')';
    
        -- function to replace and evaluate a pattern
        PROCEDURE replace_pattern
        (
            i_pattern         IN VARCHAR2,
            i_pattern_replace IN VARCHAR2,
            io_expr           IN OUT VARCHAR2
        ) IS
            l_count       PLS_INTEGER := 0;
            l_substr      VARCHAR2(1000 CHAR);
            l_substr_eval VARCHAR2(1000 CHAR);
        BEGIN
            LOOP
                l_count  := l_count + 1;
                l_substr := regexp_substr(io_expr, i_pattern);
            
                EXIT WHEN l_substr IS NULL OR l_count = 20;
            
                l_substr_eval := pk_ref_utils.eval(regexp_replace(l_substr, i_pattern, i_pattern_replace));
            
                io_expr := REPLACE(io_expr, l_substr, l_substr_eval);
            END LOOP;
        END replace_pattern;
    BEGIN
        g_error  := 'Init get_alerts_message / i_expression=' || i_expression;
        l_result := i_expression;
    
        IF l_result IS NOT NULL
        THEN
            -- replace sys_message
            replace_pattern(i_pattern => l_sm_pattern, i_pattern_replace => l_sm_pattern_replace, io_expr => l_result);
        
            -- replace translation
            replace_pattern(i_pattern => l_tr_pattern, i_pattern_replace => l_tr_pattern_replace, io_expr => l_result);
        
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error);
            RETURN NULL;
    END get_alerts_message;

    FUNCTION get_code_ref_comments(i_id_ref_comment NUMBER) RETURN VARCHAR2 DETERMINISTIC IS
    BEGIN
        RETURN pk_ref_constant.g_ref_comments_code || to_char(i_id_ref_comment);
    END get_code_ref_comments;

BEGIN
    -- Log initialization.    
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_ref_core_internal;
/
